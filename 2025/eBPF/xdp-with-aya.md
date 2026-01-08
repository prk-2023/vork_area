# XDP with Aya:


# 1. start with the examples at 
https://github.com/aya-rs/book/tree/main/examples

xdp-log: 

This code is a high-performance **eBPF program** written in Rust using the **Aya** framework and the `network-types` crate. It is designed to run at the **XDP (Express Data Path)** layer, which is the earliest possible point in the Linux networking stack.

Its primary purpose is to inspect incoming IPv4 and IPv6 packets and log their source IP addresses and source ports (for TCP and UDP).

---

## 1. Core Logic Flow

The program follows a standard "onion-peeling" approach to network packets:

1. **Ethernet Layer:** Inspect the MAC header to see if the payload is IPv4 or IPv6.
2. **IP Layer:** Inspect the IP header to find the source address and determine if the protocol is TCP or UDP.
3. **Transport Layer:** Peek into the TCP/UDP header to extract the source port.
4. **Logging:** Output the findings to the kernel trace pipe using `aya_log`.

---

## 2. Key Components Breakdown

### The Memory Safety Guard (`ptr_at`)

In eBPF, you cannot simply access memory. The **eBPF Verifier** strictly enforces that you check packet boundaries before reading.

```rust
unsafe fn ptr_at<T>(ctx: &XdpContext, offset: usize) -> Result<*const T, ()> {
    let start = ctx.data();
    let end = ctx.data_end();
    let len = mem::size_of::<T>();

    if start + offset + len > end {
        return Err(()); // Verifier requirement: prevent out-of-bounds access
    }
    Ok((start + offset) as *const T)
}

```

This function ensures that the data we want to read (of size `T`) actually exists within the packet's memory range (`start` to `end`).

### Handling IPv4 and IPv6

The `try_xdp_firewall` function handles the logic for both protocols. It uses `EthHdr::LEN` (usually 14 bytes) as the starting offset to jump past the Ethernet header to find the IP header.

* **IPv4:** It reads the `Ipv4Hdr` and then checks `ipv4hdr.proto`.
* **IPv6:** It reads the `Ipv6Hdr` and checks `ipv6hdr.next_hdr`.

### Extracting Ports (TCP vs. UDP)

The code calculates the offset for the transport layer by adding the sizes of the previous headers:

* **Offset:** `EthHdr::LEN + Ipv4Hdr::LEN` (or `Ipv6Hdr::LEN`).

Notice how it handles the data slightly differently for TCP and UDP based on the `network-types` API:

* **TCP:** Uses `u16::from_be_bytes(unsafe { (*tcphdr).source })` to convert Big-Endian network bytes to a native Rust integer.
* **UDP:** Uses the helper method `.src_port()`.

---

## 3. Critical Concepts for Aya/eBPF

### `#![no_std]`

Because this code runs inside the Linux kernel, it cannot use the Rust standard library (`std`). It relies on `core` and specialized crates like `network-types` that are designed for restricted environments.

### The Entry Point (`#[xdp]`)

The `xdp_firewall` function is the actual entry point. It wraps `try_xdp_firewall` in a `match` statement. If anything fails (like a packet being too short), it returns `XDP_PASS`. This is a safety measure to ensure you don't accidentally drop traffic if your parser encounters a malformed packet.

### Endianness

Network data is **Big-Endian**. The `network-types` crate and the manual `from_be_bytes` calls ensure that the IP addresses and ports are converted correctly so that they look "normal" in the logs.

---

## Summary Table of Offsets

| Layer | Offset Calculation | Type Used |
| --- | --- | --- |
| **Ethernet** | `0` | `EthHdr` |
| **IP (v4/v6)** | `EthHdr::LEN` | `Ipv4Hdr` / `Ipv6Hdr` |
| **Transport** | `EthHdr::LEN + IpHdr::LEN` | `TcpHdr` / `UdpHdr` |

**Note:** This specific code assumes there are no **VLAN tags** (which would shift the IP header by 4 bytes) and no **IP Options** (which would make the IP header longer than the standard length).

Would you like me to show you how to modify this code to drop specific IP addresses instead of just logging them?
--------------------------------------------------------------

# xdp-drop:
2. https://github.com/aya-rs/book/tree/main/examples/xdp-drop

This program expands on the previous logging example by introducing **eBPF Maps**, which allow communication between the Linux kernel and user space. This is a functional IP firewall that can be dynamically updated without re-loading the eBPF program.

---

## 1. How the Firewall Mechanism Works

The core of this program is the interaction between the kernel-side logic and a shared data structure.

### The Blocklist (eBPF Map)

```rust
#[map]
static BLOCKLIST: HashMap<u32, u32> = HashMap::<u32, u32>::with_max_entries(1024, 0);

```

* **Purpose:** This is a hash table stored in kernel memory.
* **Key:** A `u32` representing an IPv4 address.
* **Value:** A `u32` (unused here, essentially acting as a boolean flag).
* **Persistence:** The map lives as long as the eBPF program is loaded. Your user-space program (Rust/Go/C) can write to this map to add or remove IPs in real-time.

### The Lookup Logic

```rust
fn block_ip(address: u32) -> bool {
    unsafe { BLOCKLIST.get(&address).is_some() }
}

```

For every incoming packet, the program takes the source IP and checks if it exists as a key in the `BLOCKLIST`. If `get()` returns `Some`, the IP is "on the list."

---

## 2. Decision Making in XDP

Once the source IP is extracted from the IPv4 header, the program decides the packet's fate:

| Action | Result |
| --- | --- |
| `xdp_action::XDP_DROP` | The packet is deleted immediately at the NIC driver level. It never reaches the Linux networking stack or the CPU's higher-level processing. |
| `xdp_action::XDP_PASS` | The packet continues its normal path to the kernel and eventually to the application. |
| `xdp_action::XDP_ABORTED` | Used here in the `Err` case; it drops the packet and raises a tracepoint for debugging (indicating a program error). |

---

## 3. Comparison with the Previous Program

| Feature | Logging Program (Previous) | Firewall Program (Current) |
| --- | --- | --- |
| **Primary Goal** | Observability (What's happening?) | Enforcement (Who is allowed?) |
| **Data Flow** | Kernel  User (Logs) | User  Kernel (Map updates) |
| **Efficiency** | High | Extremely High (Drops unwanted traffic early) |
| **State** | Stateless | Stateful (Uses `BLOCKLIST` map) |

---

## 4. Key Implementation Details

* **`u32::from_be_bytes(...)`**: This converts the raw bytes from the packet (which are in Network Byte Order/Big-Endian) into a Host Byte Order integer that matches how your user-space program likely stores the IP addresses in the map.
* **`ptr_at` Safety**: The code still uses the safety check to ensure the packet is long enough to contain an IPv4 header before attempting to read the source address.
* **`info!` Logging**: Even though it's a firewall, it still logs the action. In a production environment, you might remove this to maximize performance, as logging every single packet can be expensive.

---

### How to use this from User Space

To make this work, your **User Space** code (the part that runs in your terminal) would look something like this:

1. Load the eBPF object file.
2. Get a reference to the `BLOCKLIST` map.
3. Insert an IP: `blocklist.insert(u32_ip_address, 1, 0);`
4. The kernel-side program immediately starts dropping packets from that IP.

**Would you like me to provide the User-Space Rust code that populates this `BLOCKLIST` map?**


--------------------------------------------------------------
# 3. Promiscus mode to inspect packets on LAN.

Yes, you can certainly do this. However, to achieve this using Aya and eBPF, you need to change how you think about the "destination."

In an XDP program, **promiscuous mode** is a setting on the Network Interface Card (NIC) itself, while the eBPF program acts as the logic that filters that stream.

### 1. Enabling Promiscuous Mode

Promiscuous mode is usually enabled at the OS/Driver level, not inside the eBPF code itself. You would use a command like `ip link set dev eth0 promisc on` or set the flag via a netlink socket in your user-space Rust code.

Once enabled, the NIC will pass **all** frames it sees on the wire to your XDP program, even if the destination MAC address doesn't match your PC.

### 2. Identifying "Local" vs "LAN" Traffic

To log packets from the LAN destined for your local PC, your eBPF program needs to check the **Destination IP**.

Here is how you would modify the logic:

```rust
fn try_xdp_firewall(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = unsafe { ptr_at(&ctx, 0)? };
    
    // Only process IPv4
    if unsafe { (*ethhdr).ether_type() } != Ok(EtherType::Ipv4) {
        return Ok(xdp_action::XDP_PASS);
    }

    let ipv4hdr: *const Ipv4Hdr = unsafe { ptr_at(&ctx, EthHdr::LEN)? };
    
    let src_ip = u32::from_be_bytes(unsafe { (*ipv4hdr).src_addr });
    let dst_ip = u32::from_be_bytes(unsafe { (*ipv4hdr).dst_addr });

    // YOUR LOCAL PC IP (e.g., 192.168.1.10)
    // In a real app, you might pass this via a Map or Global Variable
    const LOCAL_IP: u32 = 0xC0A8010A; 

    if dst_ip == LOCAL_IP {
        info!(&ctx, "LOCAL TRAFFIC: SRC {:i} -> DST {:i}", src_ip, dst_ip);
    } else {
        // This packet was seen because of Promiscuous mode but isn't for us
        info!(&ctx, "SNOOPED TRAFFIC: SRC {:i} -> DST {:i}", src_ip, dst_ip);
    }

    Ok(xdp_action::XDP_PASS)
}

```

---

### 3. Key Considerations for Logging LAN Traffic

#### The "Mirroring" Problem

XDP is highly efficient, but `aya_log` (which uses a Perf Event Array) has overhead. If you are in a busy LAN and logging **every** packet you see in promiscuous mode, you might drop logs or hit a CPU bottleneck.

* **Recommendation:** Use a Map to count packets per IP instead of logging every individual packet, or use a "Sampling" logic (e.g., log every 100th packet).

#### Layer 2 vs. Layer 3

In promiscuous mode, you will see traffic meant for other MAC addresses.

* If you want to log traffic meant for your **PC**, you check the `dst_addr` in the `Ipv4Hdr`.
* If you want to log traffic meant for **other devices** on the LAN (Snooping), you check if the `dst_addr` is *not* your IP.

#### XDP_PASS vs XDP_DROP

Even in promiscuous mode:

* If the packet is for your PC: Return `XDP_PASS` so the Linux stack can process it.
* If the packet is for someone else: You should generally return `XDP_PASS` (the kernel will see the MAC doesn't match and discard it anyway) or `XDP_DROP` if you want to be totally silent.

---

### Next Step

Would you like me to show you how to use a **Bounded Array** or a **HashMap** to count traffic per IP address so you can see "Top Talkers" on your LAN without flooding your logs?

--------------------------------------------------------------

# 4. Top Talkers: 

 use a **Bounded Array** or a **HashMap** to count traffic per IP address so you can see "Top Talkers" on your LAN without flooding your logs
 
 To implement a "Top Talkers" or traffic monitor, we will use an **eBPF HashMap**. This allows us to track how many packets or bytes are coming from each unique IP in the LAN without the performance penalty of logging every single packet to the console.

### 1. Updated eBPF Program (Kernel Space)

In this version, we store the packet count for each source IP address.

```rust
#[map]
static COUNTERS: HashMap<u32, u64> = HashMap::with_max_entries(1024, 0);

fn try_xdp_traffic_monitor(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = unsafe { ptr_at(&ctx, 0)? };
    if unsafe { (*ethhdr).ether_type() } != Ok(EtherType::Ipv4) {
        return Ok(xdp_action::XDP_PASS);
    }

    let ipv4hdr: *const Ipv4Hdr = unsafe { ptr_at(&ctx, EthHdr::LEN)? };
    let src_addr = u32::from_be_bytes(unsafe { (*ipv4hdr).src_addr });

    // Lookup the current count for this IP
    let mut count = unsafe { COUNTERS.get(&src_addr).copied().unwrap_or(0) };
    
    // Increment and update the map
    count += 1;
    let _ = COUNTERS.insert(&src_addr, &count, 0);

    // We still pass the packet so the PC can actually use the network!
    Ok(xdp_action::XDP_PASS)
}

```

### 2. How the Map Stores Data

Instead of a stream of logs, your kernel memory now looks like a structured table. This is significantly more efficient for high-speed LAN traffic.

---

### 3. User-Space Program (Reading the Data)

Your user-space Rust application (the one you run with `cargo xtask run`) needs to read this map periodically and print the results. Using Aya, it looks like this:

```rust
use aya::maps::HashMap;
use std::convert::TryFrom;
use std::time::Duration;
use tokio::time;

// Inside your main function:
let mut counters: HashMap<_, u32, u64> = HashMap::try_from(bpf.map_mut("COUNTERS").unwrap())?;

let mut interval = time::interval(Duration::from_secs(5));

loop {
    interval.tick().await;
    println!("--- LAN Traffic Report ---");
    
    for item in counters.iter() {
        let (ip_u32, count) = item?;
        let ip = std::net::Ipv4Addr::from(ip_u32);
        println!("IP: {:15} | Packets Seen: {}", ip, count);
    }
}

```

---

### 4. Important Considerations for Promiscuous Mode

When you put your interface into promiscuous mode, the behavior of your eBPF program changes in two major ways:

* **Non-Local Traffic:** You will see packets where the `EthHdr` destination MAC is **not** yours. If you only want to monitor traffic *intended* for your local PC, you must verify the destination MAC or destination IP.
* **CPU Impact:** In a busy LAN (like a corporate office), an XDP program in promiscuous mode will be triggered millions of times per second. By using the `COUNTERS` map instead of `info!` logging, you prevent the CPU from choking on "print" statements.

### Next Step

To get this running, you'll need to enable promiscuous mode on your interface. Would you like the specific **User-Space Rust code** using the `netlink` or `nix` crate to automatically toggle "promisc" mode when your program starts?


---------------------------------------------------------------------------------------

# 5. Auto Promisc mode  toggling:
To toggle promiscuous mode programmatically in Rust, the most robust way is using the `nix` crate to make a `socket` call and an `ioctl` (Input/Output Control) request. This is the same underlying mechanism used by the `ip link` command.

### 1. User-Space Code to Toggle Promiscuous Mode

Add `nix = { version = "0.27", features = ["net"] }` to your `Cargo.toml`.

```rust
use nix::libc;
use std::os::unix::io::AsRawFd;
use std::net::UdpSocket;

fn set_promisc(iface: &str, enable: bool) -> Result<(), Box<dyn std::error::Error>> {
    // We need a socket file descriptor to perform ioctl
    let socket = UdpSocket::bind("0.0.0.0:0")?;
    let fd = socket.as_raw_fd();

    // Create an ifreq structure for ioctl
    let mut ifr: libc::ifreq = unsafe { std::mem::zeroed() };
    
    // Copy interface name to ifr_name
    for (i, byte) in iface.as_bytes().iter().enumerate().take(libc::IFNAMSIZ - 1) {
        ifr.ifr_name[i] = *byte as i8;
    }

    // 1. Get current flags
    if unsafe { libc::ioctl(fd, libc::SIOCGIFFLAGS, &mut ifr) } < 0 {
        return Err("Failed to get interface flags".into());
    }

    // 2. Modify IFF_PROMISC bit
    if enable {
        ifr.ifr_ifru.ifru_flags |= libc::IFF_PROMISC as i16;
    } else {
        ifr.ifr_ifru.ifru_flags &= !(libc::IFF_PROMISC as i16);
    }

    // 3. Set modified flags back
    if unsafe { libc::ioctl(fd, libc::SIOCSIFFLAGS, &ifr) } < 0 {
        return Err("Failed to set interface flags".into());
    }

    println!("Promiscuous mode {} for {}", if enable { "enabled" } else { "disabled" }, iface);
    Ok(())
}

```

---

### 2. Putting It All Together (The Workflow)

When you run your Aya application, your `main.rs` logic should follow this sequence:

1. **Initialize:** Call `set_promisc("eth0", true)`.
2. **Load eBPF:** Load your XDP program and attach it to the interface.
3. **Monitor:** Enter the `loop` to read the `COUNTERS` map every few seconds.
4. **Cleanup:** Use a signal handler (like `ctrl-c`) to call `set_promisc("eth0", false)` before exiting. If you don't do this, the interface will stay in promiscuous mode until a reboot or manual reset.

---

### 3. Understanding the "Snooped" Traffic

Because you are now in promiscuous mode, your `COUNTERS` map will start populating with IP addresses that aren't even talking to your PC.

| Packet Type | Dest MAC | Dest IP | Action in XDP |
| --- | --- | --- | --- |
| **Normal** | Your MAC | Your IP | Recorded in Map & `XDP_PASS` |
| **Broadcast** | `FF:FF:FF...` | `255.255.255.255` | Recorded in Map & `XDP_PASS` |
| **Snooped** | **Someone else's** | **Someone else's** | Recorded in Map & `XDP_PASS` |

### 4. Safety Note: Raw Pointers vs. Ref

In your kernel code, you'll notice we changed:
`Ok(unsafe { &*ptr })`
to
`Ok(ptr)`
Aya's verifier is very sensitive to how you handle these pointers. Using `ptr_at` to return a `*const T` and then dereferencing it inside an `unsafe` block only when you need the value is the most stable way to pass the eBPF verifier.

---

**Would you like me to show you how to filter out "Internal" vs "External" traffic by checking if the Source IP belongs to a private subnet (like 192.168.x.x)?**



----------------------------------------------------------------------------
# 6. Filter Internal and External traffic using SRC IP Address:

To filter internal vs. external traffic, we can use **bitmasking**. In a standard home or office network (typically a `/24` subnet), the first 24 bits (the first three octets) of the IP address remain the same for all internal devices.

### 1. The Kernel Logic: Subnet Filtering

We can define our local subnet and compare it against the source IP. In eBPF, this is done using a bitwise AND operation.

```rust
// Example: Subnet 192.168.1.0/24
// 192.168.1.0 in Hex is 0xC0A80100
const SUBNET_MASK: u32 = 0xFFFFFF00; 
const TARGET_SUBNET: u32 = 0xC0A80100;

fn is_internal(ip: u32) -> bool {
    // We convert the IP to Host Endian for easier math
    let host_ip = u32::from_be(ip);
    (host_ip & SUBNET_MASK) == TARGET_SUBNET
}

// Inside your try_xdp_traffic_monitor:
let src_addr_raw = unsafe { (*ipv4hdr).src_addr };
let src_addr_u32 = u32::from_be_bytes(src_addr_raw);

if is_internal(src_addr_u32) {
    // Logic for internal LAN traffic
    let mut count = unsafe { INTERNAL_COUNTERS.get(&src_addr_u32).copied().unwrap_or(0) };
    let _ = INTERNAL_COUNTERS.insert(&src_addr_u32, &(count + 1), 0);
} else {
    // Logic for external/internet traffic
    let mut count = unsafe { EXTERNAL_COUNTERS.get(&src_addr_u32).copied().unwrap_or(0) };
    let _ = EXTERNAL_COUNTERS.insert(&src_addr_u32, &(count + 1), 0);
}

```

---

### 2. Organizing Data with Multiple Maps

Instead of one giant list, it is often cleaner to use two separate maps. This allows your user-space program to display two distinct tables: **"Local Neighbors"** and **"External Connections."**

| Map Name | Key | Value | Description |
| --- | --- | --- | --- |
| `INTERNAL_COUNTERS` | `u32` (IP) | `u64` (Packets) | Traffic originating from your own LAN. |
| `EXTERNAL_COUNTERS` | `u32` (IP) | `u64` (Packets) | Traffic from the Internet or other subnets. |

---

### 3. Visualizing the Traffic Flow

By combining **Promiscuous Mode** with **Subnet Filtering**, your PC acts like a "Silent Sentry." Even if a packet isn't addressed to you, the NIC captures it, and the eBPF program categorizes it.

### 4. Implementation Tip: The Endianness Trap

When dealing with IP addresses in eBPF:

* `network-types` gives you bytes in **Network Order** (Big-Endian).
* `192.168.1.5` on the wire is `[192, 168, 1, 5]`.
* When you convert that to a `u32` using `from_be_bytes`, it becomes `0xC0A80105`.
* **Always** ensure your `TARGET_SUBNET` constant in the code matches the byte order you are using for comparison, or your filter will fail to catch anything.

---

### Summary of the Final System

1. **User Space** starts and sets the NIC to **Promiscuous Mode**.
2. **eBPF Program** sits at the XDP hook, seeing every single frame on the wire.
3. The program **peels the headers** (Ethernet -> IPv4).
4. It **compares the Source IP** against your subnet mask.
5. It **updates a Counter Map** based on whether the source is a "neighbor" or an "outsider."
6. **User Space** reads those maps and prints a live dashboard.

**Would you like to see how to add "Byte Counting" to this so you can see which IP is consuming the most bandwidth (MBs) instead of just packet counts?**
--------------------------------------------------------------

# 7.  "Byte Counting" Extension to above topic with 

To track bandwidth (throughput) instead of just packet counts, we need to capture the **total length** of each packet. In XDP, the packet length is calculated by subtracting the memory address of the start of the packet from the end: `ctx.data_end() - ctx.data()`.

### 1. Updated Kernel Logic (Byte Counting)

We will change the map value from a simple counter to a struct that holds both **packet count** and **total bytes**.

```rust
#[repr(C)]
#[derive(Clone, Copy)]
pub struct TrafficStats {
    pub packets: u64,
    pub bytes: u64,
}

#[map]
static STATS: HashMap<u32, TrafficStats> = HashMap::with_max_entries(1024, 0);

fn try_xdp_bandwidth_monitor(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = unsafe { ptr_at(&ctx, 0)? };
    if unsafe { (*ethhdr).ether_type() } != Ok(EtherType::Ipv4) {
        return Ok(xdp_action::XDP_PASS);
    }

    let ipv4hdr: *const Ipv4Hdr = unsafe { ptr_at(&ctx, EthHdr::LEN)? };
    let src_addr = u32::from_be_bytes(unsafe { (*ipv4hdr).src_addr });

    // Calculate packet size in bytes
    let pkt_size = (ctx.data_end() - ctx.data()) as u64;

    // Update stats in the map
    let mut stats = unsafe { STATS.get(&src_addr).copied().unwrap_or(TrafficStats { packets: 0, bytes: 0 }) };
    
    stats.packets += 1;
    stats.bytes += pkt_size;
    
    let _ = STATS.insert(&src_addr, &stats, 0);

    Ok(xdp_action::XDP_PASS)
}

```

---

### 2. User-Space: Calculating Bitrate (Mbps)

To turn "Total Bytes" into something useful like **Megabits per second (Mbps)**, your user-space program needs to track the difference in bytes over a specific time interval.

```rust
// In your user-space loop (every 1 second)
let mut last_stats: std::collections::HashMap<u32, u64> = std::collections::HashMap::new();

loop {
    time::sleep(Duration::from_secs(1)).await;
    
    for item in stats_map.iter() {
        let (ip_u32, stats) = item?;
        let ip = std::net::Ipv4Addr::from(ip_u32);
        
        // Calculate bytes since last check
        let prev_bytes = last_stats.get(&ip_u32).unwrap_or(&0);
        let delta_bytes = stats.bytes - prev_bytes;
        
        // Convert to Mbps: (Bytes * 8 bits) / 1,000,000
        let mbps = (delta_bytes as f64 * 8.0) / 1_000_000.0;
        
        println!("IP: {:15} | Speed: {:.2} Mbps | Total: {} MB", 
                 ip, mbps, stats.bytes / 1_000_000);
        
        last_stats.insert(ip_u32, stats.bytes);
    }
}

```

---

### 3. Why this is powerful for "Snooping"

When combined with **Promiscuous Mode**, this program becomes a high-performance network analyzer similar to a "headless Wireshark."

* **Zero-Copy:** The packet data stays in the NIC/Kernel buffer. We only increment numbers in a table.
* **Early Drop/Pass:** Since this happens at the XDP layer, the CPU doesn't have to parse the packet in the higher-level networking stack unless it’s actually meant for your PC.
* **Identification:** You can quickly see if a device on your LAN is performing a large backup or if an unknown external IP is scanning your network.

### 4. Summary of the Architecture

| Component | Responsibility |
| --- | --- |
| **NIC (Promisc)** | Grabs every electrical signal on the wire and turns it into a frame. |
| **XDP Program** | Inspects the frame, checks the IP, and updates the `STATS` map. |
| **eBPF Map** | Stores the running totals (Packets and Bytes) in shared memory. |
| **User-Space App** | Calculates the "Delta" (change over time) to display real-time speed. |

---

### Final Next Step

You now have a full-featured LAN monitor. Would you like me to help you write a **Signal Handler** in the user-space Rust code so that when you press `Ctrl+C`, the program gracefully disables Promiscuous mode and cleans up the eBPF links?


-------------------------------------------------------------------------------

#  8. User-space Signal Handler:

To ensure your program leaves the system in a clean state, you need to handle signals (like `Ctrl+C`). If you don't, the network interface might stay in **Promiscuous Mode**, and the eBPF program might remain attached, wasting CPU cycles.

We will use the `tokio::signal` module for an asynchronous cleanup.

### 1. The Graceful Cleanup Logic

Here is how you structure your user-space `main.rs` to handle the lifecycle of the monitor.

```rust
use aya::programs::Xdp;
use tokio::signal;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let iface = "eth0";

    // 1. Enable Promiscuous Mode
    set_promisc(iface, true)?;

    // 2. Load and Attach eBPF
    let mut bpf = aya::Bpf::load(aya::include_bytes_aligned!(
        "../../target/bpfel-unknown-none/release/lan-monitor"
    ))?;
    let program: &mut Xdp = bpf.program_mut("xdp_bandwidth_monitor").unwrap().try_into()?;
    program.load()?;
    program.attach(iface, aya::programs::XdpFlags::default())?;

    println!("Monitoring started on {}. Press Ctrl+C to stop...", iface);

    // 3. Spawn the reporting loop in the background
    let stats_task = tokio::spawn(async move {
        // ... (The loop logic from the previous step goes here) ...
    });

    // 4. Wait for termination signal
    signal::ctrl_c().await?;
    
    println!("\nShutting down...");

    // 5. Cleanup
    stats_task.abort();
    set_promisc(iface, false)?; 

    println!("Promiscuous mode disabled. Goodbye!");
    Ok(())
}

```

---

### 2. Why Signal Handling Matters in eBPF

In Linux, eBPF programs and maps are managed by **file descriptors**. However, XDP programs are "pinned" to the network interface.

* **Without Cleanup:** If the process crashes or is killed with `kill -9`, the XDP program might stay in the kernel. You would have to manually run `ip link set dev eth0 xdp off`.
* **With Cleanup:** By catching `SIGINT` (Ctrl+C), your code explicitly tells the NIC to stop the XDP program and returns the interface flags to normal.

---

### 3. Reviewing the Full Stack Architecture

You have now designed a professional-grade network tool. Here is the data journey:

1. **Wire:** A packet travels across the LAN (even if it's not for you).
2. **NIC:** Because of **Promiscuous Mode**, the NIC accepts the packet.
3. **XDP (eBPF):** Before the kernel even allocates a socket buffer (`sk_buff`), your Rust code reads the IP and size.
4. **Map:** Your `TrafficStats` struct is updated in atomic kernel memory.
5. **User Space:** Your async Rust task pulls that data, calculates **Mbps**, and displays it.
6. **Shutdown:** Your signal handler restores the system state.

### 4. Hardware Acceleration Note

Most modern NICs support "Generic XDP" (which works on any driver) and "Native XDP" (which is much faster). When you call `program.attach`, Aya tries to use the best available mode. In Native mode, your byte counting is happening almost at the hardware level!

---

**Would you like me to generate a complete `Cargo.toml` and a consolidated `main.rs` file that combines all these features (Promisc, Subnet Filter, Byte Counting, and Cleanup) into one copy-pasteable project?**


-----------------------------------------------------------------------------------

# 9. Complete proj ( Promisc, Subnet Filter, Byte Counting, Cleanup )

Here is the consolidated project structure. This setup provides a complete, high-performance LAN monitor that handles everything from the low-level NIC settings to the high-level data visualization.

### 1. The Project Structure

```text
lan_monitor/
├── lan-monitor-ebpf/      # The Kernel-side code
│   ├── Cargo.toml
│   └── src/main.rs
├── lan-monitor/           # The User-side code
│   ├── Cargo.toml
│   └── src/main.rs
└── Cargo.toml             # Workspace file

```

---

### 2. Kernel-Side eBPF (`lan-monitor-ebpf/src/main.rs`)

```rust
#![no_std]
#![no_main]

use aya_ebpf::{
    macros::{map, xdp},
    maps::HashMap,
    programs::XdpContext,
};
use core::mem;
use network_types::{
    eth::{EthHdr, EtherType},
    ip::Ipv4Hdr,
};

#[repr(C)]
#[derive(Clone, Copy)]
pub struct TrafficStats {
    pub packets: u64,
    pub bytes: u64,
}

#[map]
static STATS: HashMap<u32, TrafficStats> = HashMap::with_max_entries(1024, 0);

#[xdp]
pub fn xdp_monitor(ctx: XdpContext) -> u32 {
    match try_xdp_monitor(ctx) {
        Ok(ret) => ret,
        Err(_) => 0, // XDP_ABORTED
    }
}

#[inline(always)]
unsafe fn ptr_at<T>(ctx: &XdpContext, offset: usize) -> Result<*const T, ()> {
    let start = ctx.data();
    let end = ctx.data_end();
    let len = mem::size_of::<T>();
    if start + offset + len > end {
        return Err(());
    }
    Ok((start + offset) as *const T)
}

fn try_xdp_monitor(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = unsafe { ptr_at(&ctx, 0)? };
    if unsafe { (*ethhdr).ether_type() } != Ok(EtherType::Ipv4) {
        return Ok(2); // XDP_PASS
    }

    let ipv4hdr: *const Ipv4Hdr = unsafe { ptr_at(&ctx, EthHdr::LEN)? };
    let src_addr = u32::from_be_bytes(unsafe { (*ipv4hdr).src_addr });
    let pkt_size = (ctx.data_end() - ctx.data()) as u64;

    let mut stats = unsafe { 
        STATS.get(&src_addr).copied().unwrap_or(TrafficStats { packets: 0, bytes: 0 }) 
    };
    
    stats.packets += 1;
    stats.bytes += pkt_size;
    let _ = STATS.insert(&src_addr, &stats, 0);

    Ok(2) // XDP_PASS
}

```

---

### 3. User-Side Application (`lan-monitor/src/main.rs`)

```rust
use aya::maps::HashMap as BpfHashMap;
use aya::programs::{Xdp, XdpFlags};
use aya::Bpf;
use nix::libc;
use std::net::Ipv4Addr;
use std::os::unix::io::AsRawFd;
use tokio::{signal, time};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let iface = "eth0"; // Change to your interface name

    // 1. Enable Promiscuous Mode
    set_promisc(iface, true)?;

    // 2. Load eBPF
    let mut bpf = Bpf::load(aya::include_bytes_aligned!(
        "../../target/bpfel-unknown-none/release/lan-monitor"
    ))?;
    let program: &mut Xdp = bpf.program_mut("xdp_monitor").unwrap().try_into()?;
    program.load()?;
    program.attach(iface, XdpFlags::default())?;

    println!("Monitoring {}... Press Ctrl+C to stop.", iface);

    let mut stats_map: BpfHashMap<_, u32, TrafficStats> = BpfHashMap::try_from(bpf.map_mut("STATS")?)?;
    let mut last_bytes = std::collections::HashMap::new();

    loop {
        tokio::select! {
            _ = time::sleep(time::Duration::from_secs(1)) => {
                println!("\x1B[2J\x1B[H--- LAN Bandwidth Monitor ---");
                for item in stats_map.iter() {
                    let (ip_u32, stats) = item?;
                    let ip = Ipv4Addr::from(ip_u32);
                    let prev = last_bytes.get(&ip_u32).unwrap_or(&0);
                    let mbps = ((stats.bytes - prev) as f64 * 8.0) / 1_000_000.0;
                    
                    println!("IP: {:15} | {:>6.2} Mbps | Total: {:>8} MB", 
                             ip, mbps, stats.bytes / 1_000_000);
                    last_bytes.insert(ip_u32, stats.bytes);
                }
            }
            _ = signal::ctrl_c() => {
                println!("\nShutting down...");
                set_promisc(iface, false)?;
                break;
            }
        }
    }
    Ok(())
}

fn set_promisc(iface: &str, enable: bool) -> Result<(), Box<dyn std::error::Error>> {
    let socket = std::net::UdpSocket::bind("0.0.0.0:0")?;
    let fd = socket.as_raw_fd();
    let mut ifr: libc::ifreq = unsafe { std::mem::zeroed() };
    for (i, byte) in iface.as_bytes().iter().enumerate().take(libc::IFNAMSIZ - 1) {
        ifr.ifr_name[i] = *byte as i8;
    }
    unsafe {
        libc::ioctl(fd, libc::SIOCGIFFLAGS, &mut ifr);
        if enable { ifr.ifr_ifru.ifru_flags |= libc::IFF_PROMISC as i16; }
        else { ifr.ifr_ifru.ifru_flags &= !(libc::IFF_PROMISC as i16); }
        libc::ioctl(fd, libc::SIOCSIFFLAGS, &ifr);
    }
    Ok(())
}

#[repr(C)]
#[derive(Clone, Copy)]
struct TrafficStats { packets: u64, bytes: u64 }

```

---

### 4. Running the Monitor

1. **Build:** Run `cargo xtask build-ebpf` then `cargo build`.
2. **Execute:** Run with root privileges: `sudo ./target/debug/lan-monitor`.
3. **Result:** You will see a live-updating table of every IP active on your LAN segment.

**Would you like me to explain how to add an "Age-out" logic so that IPs that stop sending traffic eventually disappear from your dashboard?**

- No - 

Next topic:

--------------------------------------------------------------------------
11.  Integration with webserver:

Yes, we can absolutely extend this! By integrating an asynchronous web server like **Axum** into your user-space Rust program, you can expose the eBPF map data as a JSON API or a live-streaming dashboard.

Since your program is already using `tokio`, adding a web server is very efficient because it can share the same runtime as the eBPF management logic.

### 1. Updated Project Architecture

Instead of just printing to the console, the user-space program will now act as a "Data Bridge."

---

### 2. User-Space Web Server Implementation

You will need to add `axum` and `serde` (for JSON) to your `lan-monitor/Cargo.toml`.

```rust
use axum::{routing::get, Json, Router, extract::State};
use serde::Serialize;
use std::sync::Arc;

#[derive(Serialize)]
struct IpStat {
    ip: String,
    bps: f64,
    total_mb: u64,
}

// We wrap the BPF maps in an Arc so the web server can access them safely
struct AppState {
    // In a real app, you'd use a Mutex or a separate storage 
    // to keep track of the calculated bitrates
    pub stats: tokio::sync::RwLock<Vec<IpStat>>,
}

async fn get_stats(State(state): State<Arc<AppState>>) -> Json<Vec<IpStat>> {
    let stats = state.stats.read().await;
    Json(stats.clone())
}

```

### 3. Integrating the Web Loop with the BPF Loop

We modify the `main.rs` to run the web server and the eBPF poller concurrently.

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // ... (eBPF and Promisc setup as before) ...

    let shared_state = Arc::new(AppState {
        stats: tokio::sync::RwLock::new(Vec::new()),
    });

    // 1. Define the Web Server
    let app = Router::new()
        .route("/api/stats", get(get_stats))
        .with_state(shared_state.clone());

    // 2. Start Web Server in the background
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    // 3. Main Logic Loop (Update the shared state)
    let mut last_bytes = std::collections::HashMap::new();
    loop {
        time::sleep(time::Duration::from_secs(1)).await;
        
        let mut current_snapshot = Vec::new();
        for item in stats_map.iter() {
            let (ip_u32, stats) = item?;
            let prev = last_bytes.get(&ip_u32).unwrap_or(&0);
            let bps = (stats.bytes - prev) as f64 * 8.0;
            
            current_snapshot.push(IpStat {
                ip: Ipv4Addr::from(ip_u32).to_string(),
                bps,
                total_mb: stats.bytes / 1_000_000,
            });
            last_bytes.insert(ip_u32, stats.bytes);
        }

        // Update the state for the web server
        let mut s = shared_state.stats.write().await;
        *s = current_snapshot;
    }
}

```

### 4. Viewing the Live Data

Once running, you can access your live network data from any device on your LAN:

* **API Access:** Visit `http://<your-pc-ip>:3000/api/stats` to see the raw JSON.
* **Frontend:** You could serve a simple `index.html` that uses `fetch()` and Chart.js to draw real-time graphs of your LAN traffic.

---

### Why this is better than standard tools

1. **Lower Overhead:** Unlike running `ntopng` or heavy scanners, this uses eBPF to do the heavy lifting in the kernel. The web server only wakes up once per second to read the summary.
2. **Snooping Capability:** Because you are in promiscuous mode, this web dashboard will show you traffic from *other* devices on your network that normally wouldn't show up on your PC's standard monitors.

### Next Step

This setup currently shows a "snapshot." Would you like me to show you how to use **WebSockets** or **Server-Sent Events (SSE)** so the web page updates instantly without the browser having to refresh or poll the API?

----------------------------------------------------------------------------------
