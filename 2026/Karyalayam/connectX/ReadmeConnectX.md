## ConnectX Mellanox SmartNIC 

### Test Setup with Single NIC ( SmartNIC with 2 ports )

- Mellanox ConnectX-5 Ex Dual-Port PCI Express 3.0 (8GT/s) x8 Ethernet NIC adapter
- The driver considers these two ports as two independent interfaces, which allows us to use a single card for testing using a DAC Cable plugged into both ports.

- The driver exposes two parts of the SmartNIC:
    - Regular Ethernet 
    - And Inifiband Interface for RoCE 
    
### HowTo test with Single card:


1. Create 2 Network Namespaces ( similar to how its done with containers ) (ns_server, ns_client)

2. Add each interface to the name space and assign an ip address. 

3. This prevents testing traffic between two NIC ports to pass via  Linux Loopback, and forces data
   to leave port0 and move to port1. And since kernel routing table is isolated in each namespace the only
   way for the packets to get from one interface to other is via physical ports.
   
4. Standard ethernet bandwith test use iperf3, This test can show some CPU usage as kernel has to process every header,
   handle interrupts and copy data from user-space to kernel space.
   
5. This is where RoCE ( RDMA ) can be tested where the data is copied from memory to memory between 
   different hosts: 
   Fabric A : Port 0 ( namespace ns_server )
   Fabric B : Port 1 ( namespace ns_client )
   
   To run your bandwidth tests successfully on these specific names, you need to confirm which GID index 
   is assigned to RoCE v2. On Mellanox cards, this is usually index 3, but it can vary by firmware version.
   use command `show_gids` ( mlnx-tools: mellanox tools ).
   Index 0/1: Usually RoCE v1 (Layer 2).
   Index 3: Usually RoCE v2 (Layer 3/UDP) over IPv4.
   Index 5: Usually RoCE v2 over IPv6.
   
Note: If IP address are changes or there is a moves the interface between namespaces, requires a 
      re-run of command `show_gids`. 
      The index for **RoCE v2** (UDP-encapsulated) is the only one that will work for "routable" 
      tests across namespaces.

6. RDMA and Ethernet stack:  
   In a RoCE v2 (RDMA over Converged Ethernet) environment, the RDMA stack and the Ethernet stack are 
   tightly coupled.  You cannot have one without the other because of how the ConnectX hardware is designed.
   
   => Ethernet based setup is essential for RoCE test.
   
   On a Mellanox card, the RDMA device (e.g., rocep1s0f0) is a "child" of the Ethernet interface
   (e.g., enp1s0f0np0).
   
   In our test setup with single card when we move the Ethernet interface into a namespace, 
   the RDMA device automatically follows it.
   
   Even though RDMA "bypasses" the kernel during the actual data transfer, the perftest tools 
   (like ib_write_bw) use Standard TCP/IP on Port 18515 to exchange "Connection Parameters" 
   (like Queue Pair numbers and Remote Keys) before the RDMA transfer starts.
   
7. RoCE v2 is "Routable": 
   RoCE v2 is encapsulated in a UDP packet, the SmartNIC needs the IP/MAC information from the Ethernet layer to build the headers for the hardware-offloaded packets. 
   => Test scripts should provide :
    - MAC Address: For the L2 Header.
    - IP Address: For the L3 Header.
    - MTU: To tell the hardware when to fragment the RDMA messages.
    
8. Inside SmartNIC: ( while testing )
   - Handshake: `ib_write_bw` uses the Linux IP stack to talk to the other namespace.
   - Hardware Path: Once the connection is established, the application tells the SmartNIC: 
     "Send this 1GB buffer to IP 192.168.10.2."
   - Encapsulation: The SmartNIC logic pulls the IP/MAC info from the Ethernet interface you 
     configured in your script and wraps the RDMA data in a UDP packet.
   - Bypass: The packet goes out the wire, bypassing the Linux kernel entirely.

   => Script should setup L2, L3 infrastructure that SmartNIC hw requires to execute the RoCE protocol.
   Without this they SmartNIC would not know where to "route" the RDMA traffic. 
   
9. perftest: IB performance test suite:
   The "IB" in the tools refers to the architecture, not just the physical cable type. 
   When you run these, you are stress-testing three specific bottlenecks:
   - PCIe Bandwidth: Can your motherboard push data across the PCIe Gen3/Gen4 bus to the card fast enough?
   - HCA Processing: Can the ConnectX silicon encapsulate/decapsulate RoCE headers at line rate (25Gbps)?
   - Memory Latency: How fast can the NIC perform DMA (Direct Memory Access) fetches from your system RAM?
    
   `ib_write_bw`: throughput,to see if you are actually hitting 25Gbps.
   `ib_write_lat`: Latency,To see how many microseconds (typically < 2μs) the trip takes.
   `ib_send_bw`: Message Rate,To see how many millions of small packets per second the card can handle.
   
10. Command `ib_write_bw`, the procesing happens in two distinct phases:
    1. The "TCP Handshake" (The IP Part)
      Before high-speed testing happens, the client and server talk over standard TCP (usually port 18515).
      They use the IPs you assigned (10.0.0.9 and 10.0.0.99) to exchange RDMA Metadata:
      - "Here is my Virtual Address."
      - "Here is my Remote Key (rkey) for security."
      - "Here is my Queue Pair (QP) number."
    2. The "Verbs" Transfer (The RDMA Part):
      Once they have each other's "keys," the TCP connection goes quiet. 
      The `ib_write_bw` tool tells the ConnectX card: 
        "Push 1GB from my RAM directly to the RAM at the address the other guy gave me."
      The SmartNIC hardware then:
      1. Grabs the data via PCIe.
      2. Wraps it in a RoCE v2 header (using the GID index -x 3).
      3. Fires it out the wire at 25 Gbps.
    

11. Standard Ethernet bandwidth testing: 
    use iperf3 on two namespaces:
    server> sudo ip netns exec ns_server iperf3 -s
    client> sudo ip netns exec ns_client iperf3 -c 10.0.0.9 -u -b 25G

12. MTU and Performance
    Seting MTU to 9000, `iperf3` will automatically try to use larger frames. 
    Reducing "Interrupts Per Second" the CPU has to handle, allowing you to hit higher 
    speeds more easily than with a standard 1500 MTU.

14. Optimization for Ethernet Testing
    To get closer to the line rate (25Gbps) without RDMA, you can try these flags:
    use parallel streams (`-P`)
    sudo ip netns exec ns_client iperf3 -c 10.0.0.9 -P 4
    
    Window Size (`-w`):  Increasing the TCP window size can help on high-bandwidth links.
    sudo ip netns exec ns_client iperf3 -c 10.0.0.9 -w 2M

    UDP Test (`-u`): To see the "raw" capacity without TCP overhead 
    (this can drop packets if the CPU can't keep up).
    sudo ip netns exec ns_client iperf3 -c 10.0.0.9 -u -b 25G
    
    
15. Comparison Table: Ethernet vs. RDMA

TODO:

| Feature | `iperf3` (Ethernet) | `ib_write_bw` (RoCE) |
| --- | --- | --- |
| **CPU Load** | High (Interrupts/Copies) | Near Zero (Hardware Offload) |
| **Latency** | Higher (~20-50μs) | Ultra-Low (<2μs) |
| **Header Processing** | Linux Kernel | ConnectX Hardware |
| **Protocol** | Standard TCP/IP | RDMA over UDP (RoCEv2) |

or use memory access into scope:

| Feature | `iperf3` (Ethernet) | `ib_write_bw` (RoCE) |
| --- | --- | --- |
| **Data Path** | User Space → Kernel → NIC | User Space → NIC (Direct) |
| **CPU Load** | High (Interrupts/Copies) | Near Zero (Hardware Offload) |
| **Latency** | Higher (~20-50μs) | Ultra-Low (<2μs) |
| **Reliability** | Managed by TCP Stack | Managed by Hardware (HCA) |
    
16. XDP: use XDP to similate RoCE: ( more flexible ) ToDO

    XDP can bypass the kernel entirely like RDMA, but it executes code at the lowest possible level 
    (inside the driver) before the kernel creates an `sk_buff`.
    
    If you want to test high-speed packet processing *without* the hardware-specific "Verbs" API, 
    XDP allows you to:
    
    1. Drop/Forward packets at line rate (25Gbps) with much lower CPU than `iperf3`.
    2. Modify headers in real-time.
    3. Simulate RoCE-like behavior by moving data directly from the NIC to a specialized user-space
       application via `AF_XDP`.

> "While RoCE provides 0% CPU offload via hardware, XDP provides a programmable 'fast-path' in the driver.
> Using `AF_XDP` sockets, we can achieve near-RDMA speeds for custom protocols while staying within the
> standard Ethernet frame structure, though CPU usage will be higher than RoCE."

To help you compare the hardware-level performance of **RoCE** with the programmable "fast-path" of **XDP**, here is a conceptual breakdown and a starter program.

## 1. XDP vs. RoCE: The "Middle Ground"

While RoCE is a **hard-wired** bypass, XDP is a **programmable** bypass. Using XDP (specifically `AF_XDP`) allows you to move data to user-space much faster than standard `iperf3`, but it still consumes CPU cycles to execute your eBPF program.

| Feature | Standard Ethernet (`iperf3`) | XDP (`AF_XDP`) | RoCE (`ib_write_bw`) |
| --- | --- | --- | --- |
| **Logic Location** | Kernel Stack | Driver (eBPF) | NIC Hardware |
| **Programmability** | Low (Fixed) | High (C/eBPF) | Low (Fixed Verbs) |
| **CPU Cost** | High | Medium | Near Zero |

---

## 2. A Basic XDP "Performance Test" Program

To simulate high-speed traffic handling without the overhead of the full Linux stack, you can use a "Drop" or "Rewrite" program. This is the fastest XDP can go because the packet never reaches the kernel's memory allocation phase (`sk_buff`).

### The eBPF C Code (`xdp_test.c`)

This program simply counts and drops packets at the driver level to test the raw ingestion speed of your SmartNIC.

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("xdp")
int xdp_drop_prog(struct xdp_md *ctx) {
    // This is the fastest path: the packet is discarded 
    // immediately after the NIC DMA transfer.
    return XDP_DROP; 
}

char _license[] SEC("license") = "GPL";

```

### How to use it in your Namespace setup:

1. **Compile:** Use `clang` to compile the code into an eBPF object.
2. **Load into Namespace:**
```bash
# Load the program onto the interface inside the server namespace
sudo ip netns exec ns_server ip link set dev enp1s0f0np0 xdp obj xdp_test.o sec xdp

```


3. **Test:** Run your `iperf3` or a packet generator from `ns_client`. You will see that the client sends data, but the server CPU stays much lower than standard `iperf3` because the packets are "killed" before the kernel processes them.

---

## 3. Updated README Section

You can add this to your **Section 16**:

### 16. XDP: Programmable Performance

XDP provides a way to achieve high performance while maintaining flexibility.

* **XDP_DROP:** Tests the maximum packet rate the NIC/Driver can handle.
* **XDP_TX:** Bounces the packet back out the same port (useful for latency testing).
* **AF_XDP:** Bypasses the network stack to deliver raw frames to a user-space application, similar to DPDK but integrated with Linux.

---

## 4. Final Verification Command

To see if your XDP program or RoCE is truly bypassing the stack, monitor the hardware counters directly. If you see high throughput on the hardware but no increase in `ip -s link` statistics inside the namespace, the bypass is working.

```bash
# Check hardware-level stats for Mellanox
sudo ip netns exec ns_server ethtool -S enp1s0f0np0 | grep "rx_packets"

```

---
Rust version of the above:

To move from C to **Rust + Aya (v0.13.0)**, we'll shift the focus to a more modern eBPF development workflow. Since you want to avoid `xtask` and stick to the standard `build.rs` pattern used in the latest `aya-template`, we will split this into two parts: the **eBPF program** (kernel-space) and the **User-space loader**.

### 1. Project Structure

Your directory should look like this:

```text
.
├── my-xdp-test (User-space)
│   ├── Cargo.toml
│   ├── build.rs
│   └── src/main.rs
└── my-xdp-test-ebpf (Kernel-space)
    ├── Cargo.toml
    └── src/main.rs

```

---

### 2. The Kernel-space Program (`my-xdp-test-ebpf`)

This is the Rust code that will run inside the SmartNIC driver.

**Cargo.toml**

```toml
[package]
name = "my-xdp-test-ebpf"
version = "0.1.0"
edition = "2021"

[dependencies]
aya-ebpf = "0.1.1"
aya-log-ebpf = "0.1.1"

[[bin]]
name = "my-xdp-test"
path = "src/main.rs"

```

**src/main.rs**

```rust
#![no_std]
#![no_main]

use aya_ebpf::{bindings::xdp_action, macros::xdp, programs::XdpContext};
use aya_log_ebpf::info;

#[xdp]
pub fn my_xdp_test(ctx: XdpContext) -> u32 {
    match try_my_xdp_test(ctx) {
        Ok(ret) => ret,
        Err(_) => xdp_action::XDP_ABORTED,
    }
}

fn try_my_xdp_test(_ctx: XdpContext) -> Result<u32, u32> {
    // Standard XDP_DROP for bandwidth testing
    Ok(xdp_action::XDP_DROP)
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}

```

---

### 3. The User-space Loader (`my-xdp-test`)

This handles loading the eBPF bytecode into your namespaces.

**build.rs (The Aya 0.13.0 way)**
This script automatically compiles the eBPF crate before the user-space app builds.

```rust
use std::process::Command;
use std::env;

fn main() {
    let out_dir = env::var_os("OUT_DIR").unwrap();
    
    // Compile the eBPF program
    let status = Command::new("cargo")
        .args([
            "build",
            "--manifest-path", "../my-xdp-test-ebpf/Cargo.toml",
            "--target", "bpfel-unknown-none",
            "-Z", "build-std=core",
            "--release",
        ])
        .status()
        .expect("Failed to build eBPF program");

    assert!(status.success());
    println!("cargo:rerun-if-changed=../my-xdp-test-ebpf/src/main.rs");
}

```

**src/main.rs**

```rust
use aya::{include_bytes_aligned, Bpf};
use aya::programs::{Xdp, XdpFlags};
use std::env;

fn main() -> Result<(), anyhow::Error> {
    let iface = env::args().nth(1).expect("Usage: my-xdp-test <INTERFACE>");

    // This macro includes the bytecode compiled by build.rs
    #[cfg(debug_assertions)]
    let mut bpf = Bpf::load(include_bytes_aligned!(
        "../../target/bpfel-unknown-none/debug/my-xdp-test"
    ))?;
    #[cfg(not(debug_assertions))]
    let mut bpf = Bpf::load(include_bytes_aligned!(
        "../../target/bpfel-unknown-none/release/my-xdp-test"
    ))?;

    let program: &mut Xdp = bpf.program_mut("my_xdp_test").unwrap().try_into()?;
    program.load()?;
    
    // Attach to the interface in the namespace
    program.attach(&iface, XdpFlags::default())?;

    println!("XDP program loaded on {}. Press Ctrl-C to exit.", iface);
    std::thread::park();
    Ok(())
}

```

---

### 4. Integrating with your Setup Script

To use this in your Mellanox namespace environment, replace the manual `ip link set xdp` command with your new Rust binary:

```bash
# Inside your bash script:
# 1. Build everything
cargo build --release

# 2. Run the loader inside the namespace
sudo ip netns exec ns_server ./target/release/my-xdp-test enp1s0f0np0

```

### Why this is better for your README

* **Safety:** Rust ensures your eBPF program doesn't perform out-of-bounds memory access before the verifier even sees it.
* **Performance:** Like the C version, this `XDP_DROP` occurs at the driver level, but with `aya-log`, you can easily debug the RoCE-encapsulated packets by logging their headers.
* **Completeness:** By using `build.rs`, you remove the need for external tools like `clang` or `llc` in your environment, as Rust handles the BPF target natively.

**Would you like me to add a small parser to the Rust eBPF code so it can count RoCE UDP packets specifically?**

--- 
yes:

To parse RoCE v2 packets, we need to look for **UDP** packets targeting port **4791**. Since RoCE v2 is encapsulated in UDP, your eBPF program can inspect the headers to distinguish between standard traffic and RDMA traffic.

Here is the updated **eBPF Kernel-space** code for `my-xdp-test-ebpf/src/main.rs`.

### 1. Updated Kernel-space (`my-xdp-test-ebpf`)

We'll use `core::mem` and pointer arithmetic to peek into the packet headers.

```rust
#![no_std]
#![no_main]

use aya_ebpf::{
    bindings::xdp_action,
    macros::xdp,
    programs::XdpContext,
};
use core::mem;
use network_types::{
    eth::EthHdr,
    ip::Ipv4Hdr,
    udp::UdpHdr,
};

#[xdp]
pub fn my_xdp_test(ctx: XdpContext) -> u32 {
    match try_my_xdp_test(ctx) {
        Ok(ret) => ret,
        Err(_) => xdp_action::XDP_ABORTED,
    }
}

#[inline(always)]
fn ptr_at<T>(ctx: &XdpContext, offset: usize) -> Result<*const T, ()> {
    let start = ctx.data();
    let end = ctx.data_end();
    let len = mem::size_of::<T>();

    if start + offset + len > end {
        return Err(());
    }

    Ok((start + offset) as *const T)
}

fn try_my_xdp_test(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = ptr_at(&ctx, 0)?;
    
    // We only care about IPv4 for RoCE v2 (GID Index 3)
    if unsafe { (*ethhdr).ether_type } != 0x0800 { // EtherType::Ipv4
        return Ok(xdp_action::XDP_PASS);
    }

    let ipv4hdr: *const Ipv4Hdr = ptr_at(&ctx, EthHdr::LEN)?;
    
    // Check if protocol is UDP (17)
    if unsafe { (*ipv4hdr).proto } != 0x11 {
        return Ok(xdp_action::XDP_PASS);
    }

    let udphdr: *const UdpHdr = ptr_at(&ctx, EthHdr::LEN + Ipv4Hdr::LEN)?;

    // RoCE v2 uses Destination Port 4791
    let dest_port = u16::from_be(unsafe { (*udphdr).dest });
    if dest_port == 4791 {
        // Here you could increment a Map counter for RoCE traffic
        return Ok(xdp_action::XDP_DROP); 
    }

    Ok(xdp_action::XDP_PASS)
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}

```

### 2. Dependency Update

You will need the `network-types` crate in your `my-xdp-test-ebpf/Cargo.toml` to handle the header structures easily:

```toml
[dependencies]
aya-ebpf = "0.1.1"
aya-log-ebpf = "0.1.1"
network-types = "0.0.5"

```

---

### 3. Why this helps your Test Setup

By implementing this parser, you can verify exactly how the SmartNIC is encapsulating the data:

* **Filter standard traffic:** You can let standard `ssh` or `iperf3` (non-RDMA) traffic pass to the kernel (`XDP_PASS`) while specifically dropping or counting the **RoCE UDP 4791** packets.
* **Performance Comparison:** You can measure the CPU delta between the kernel handling the UDP stream (standard `iperf3`) vs. XDP dropping it at the door.
* **Verification:** If you run `ib_write_bw` and your XDP program starts dropping packets, you have 100% confirmation that your GID index and RoCE v2 encapsulation are working correctly.

---

### 4. Running the Test

After building with `cargo build --release`, run the following in your namespaces:

**Namespace Server:**

```bash
sudo ip netns exec ns_server ./target/release/my-xdp-test enp1s0f0np0

```

**Namespace Client:**

```bash
# Start the RDMA test
sudo ip netns exec ns_client ib_write_bw -d rocep1s0f1 -x 3 10.0.0.9

```

The server-side XDP program will now intercept and drop the RDMA traffic before it ever touches the standard Linux network stack.

**Would you like me to add an eBPF Map (HashMap or Array) to the code so your user-space program can print the real-time count of RoCE packets received?**
--- 
yes first in C and then Rust:


To implement a real-time counter for RoCE (RDMA over Converged Ethernet) packets using eBPF, you need to define a **BPF Map** shared between the kernel-side XDP program and your user-space application.

Since RoCE packets are identified by their EtherType (typically **0x8915** for RoCE v1 or **0x0800** with a specific UDP port for RoCE v2), the eBPF program will filter these and increment a counter in a `BPF_MAP_TYPE_ARRAY`.

### 1. Kernel-Space Code (`roce_counter.bpf.c`)

This XDP program parses incoming packets and updates a map entry if a RoCE signature is detected.

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/udp.h>

// Define the Map: A single-entry array to store the packet count
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64);
} roce_counts SEC(".maps");

SEC("xdp")
int count_roce_packets(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end) return XDP_PASS;

    __u32 key = 0;
    __u16 eth_type = bpf_ntohs(eth->h_proto);

    // Filter for RoCE v1 (EtherType 0x8915) or RoCE v2 (UDP Port 4791)
    if (eth_type == 0x8915) {
        goto increment;
    } else if (eth_type == ETH_P_IP) {
        struct iphdr *ip = (void *)(eth + 1);
        if ((void *)(ip + 1) > data_end) return XDP_PASS;

        if (ip->protocol == IPPROTO_UDP) {
            struct udphdr *udp = (void *)ip + (ip->ihl * 4);
            if ((void *)(udp + 1) > data_end) return XDP_PASS;

            if (bpf_ntohs(udp->dest) == 4791) {
                goto increment;
            }
        }
    }

    return XDP_PASS;

increment:
    {
        __u64 *count = bpf_map_lookup_elem(&roce_counts, &key);
        if (count) {
            __sync_fetch_and_add(count, 1); // Atomic increment
        }
        return XDP_PASS;
    }
}

char _license[] SEC("license") = "GPL";

```

### 2. User-Space Program (`roce_user.c`)

This program polls the map and prints the total count to your terminal in real-time.

```c
#include <stdio.h>
#include <unistd.h>
#include <bpf/libbpf.h>
#include <bpf/bpf.h>

int main(int argc, char **argv) {
    // Assuming you've already loaded the program and pinned the map
    // or are using a handle from the skeleton/loader
    int map_fd = bpf_obj_get("/sys/fs/bpf/roce_counts");
    if (map_fd < 0) {
        fprintf(stderr, "Failed to open BPF map. Is the XDP program loaded?\n");
        return 1;
    }

    __u32 key = 0;
    __u64 value;

    printf("Monitoring RoCE Traffic... (Ctrl+C to stop)\n");
    printf("------------------------------------------\n");

    while (1) {
        if (bpf_map_lookup_elem(map_fd, &key, &value) == 0) {
            printf("\rRoCE Packets Received: %llu", value);
            fflush(stdout);
        }
        sleep(1); // Poll every second
    }

    return 0;
}

```

### Key Implementation Details

* **Atomic Updates:** Used `__sync_fetch_and_add` in the kernel code to ensure that packet counts from multiple CPU cores don't overwrite each other (race conditions).
* **RoCE v2 Detection:** RoCE v2 is encapsulated in UDP. The code checks for the standard destination port **4791**.
* **Map Polling:** The user-space code uses `bpf_map_lookup_elem` to pull the latest value from the kernel.

---

**Would you like me to provide the `Makefile` or the specific `ip link` commands needed to compile and attach this to a specific network interface?**
---

Now Rust:>
In the newer versions of **Aya (0.13.x)**, the workflow has shifted from the old `xtask` pattern to using **`aya-tool`** and a standard **`build.rs`** to compile the eBPF bytecode. This keeps the project structure much cleaner and closer to standard Rust idioms.

Here is how you add the Map to your eBPF code and the corresponding logic to your user-space program.

### 1. The eBPF Program (`roce-ebpf/src/main.rs`)

In Aya, we define the map using the `#[map]` attribute. We'll use a `HashMap` here, which is flexible, though an `Array` would also work for a single counter.

```rust
#![no_std]
#![no_main]

use aya_ebpf::{
    macros::{map, xdp},
    maps::HashMap,
    programs::XdpContext,
};
use aya_log_ebpf::info;
use core::mem;
use network_types::{
    eth::{EthHdr, EtherType},
    ip::{Ipv4Hdr, IpProto},
    udp::UdpHdr,
};

// Define the Map: Key is u32 (index), Value is u64 (counter)
#[map]
static ROCE_STATS: HashMap<u32, u64> = HashMap::<u32, u64>::with_max_entries(1, 0);

#[xdp]
pub fn roce_counter(ctx: XdpContext) -> u32 {
    match try_roce_counter(ctx) {
        Ok(ret) => ret,
        Err(_) => aya_ebpf::bindings::xdp_action::XDP_ABORTED,
    }
}

fn try_roce_counter(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = unsafe { ctx.ptr_at(0).map_err(|_| ())? };
    let eth_type = unsafe { (*ethhdr).ether_type };

    let is_roce = match eth_type {
        EtherType::Arp => false, // RoCE v1 uses 0x8915, check your header constants
        EtherType::Ipv4 => {
            let ipv4hdr: *const Ipv4Hdr = unsafe { ctx.ptr_at(EthHdr::LEN).map_err(|_| ())? };
            if unsafe { (*ipv4hdr).proto } == IpProto::Udp {
                let udphdr: *const UdpHdr = unsafe { 
                    ctx.ptr_at(EthHdr::LEN + Ipv4Hdr::LEN).map_err(|_| ())? 
                };
                // RoCE v2 Destination Port 4791
                u16::from_be(unsafe { (*udphdr).dest }) == 4791
            } else {
                false
            }
        }
        _ => false,
    };

    if is_roce {
        let key = 0u32;
        // Lookup or initialize the counter
        let mut count = ROCE_STATS.get(&key).copied().unwrap_or(0);
        count += 1;
        let _ = ROCE_STATS.insert(&key, &count, 0);
    }

    Ok(aya_ebpf::bindings::xdp_action::XDP_PASS)
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}

```

---

### 2. User-Space Program (`roce/src/main.rs`)

The user-space side needs to load the program and then poll the `HashMap` in a loop.

```rust
use aya::maps::HashMap;
use aya::programs::{Xdp, XdpFlags};
use aya::{include_bytes_aligned, Bpf};
use std::convert::TryFrom;
use tokio::signal;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    // Load the eBPF bytecode compiled by build.rs
    #[cfg(debug_assertions)]
    let bpf_data = include_bytes_aligned!("../../target/bpfel-unknown-none/debug/roce");
    #[cfg(not(debug_assertions))]
    let bpf_data = include_bytes_aligned!("../../target/bpfel-unknown-none/release/roce");

    let mut bpf = Bpf::load(bpf_data)?;
    
    // Attach the XDP program
    let program: &mut Xdp = bpf.program_mut("roce_counter").unwrap().try_into()?;
    program.load()?;
    program.attach("eth0", XdpFlags::default())?; // Change "eth0" to your interface

    // Get a reference to the Map
    let mut roce_stats: HashMap<_, u32, u64> = HashMap::try_from(bpf.map_mut("ROCE_STATS").unwrap())?;

    println!("Waiting for RoCE packets... (Ctrl+C to stop)");

    let mut ticker = tokio::time::interval(std::time::Duration::from_secs(1));

    loop {
        tokio::select! {
            _ = ticker.tick() => {
                let count = roce_stats.get(&0, 0).unwrap_or(0);
                print!("\rRoCE Packets: {}", count);
                std::io::Write::flush(&mut std::io::stdout())?;
            }
            _ = signal::ctrl_c() => {
                println!("\nExiting...");
                break;
            }
        }
    }

    Ok(())
}

```

---

### 3. The `build.rs` Logic

The `aya-template` uses `build.rs` to ensure that whenever you run `cargo build`, the eBPF code is recompiled first. Your `roce/build.rs` should look like this:

```rust
use std::process::Command;
use std::env;

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    
    // This tells cargo to re-run if the eBPF source changes
    println!("cargo:rerun-if-changed=../roce-ebpf/src/main.rs");

    // Example using aya-tool or direct cargo-bpf calls
    // Usually, aya-template handles this via a custom workspace setup
}

```

### Why this works

* **Real-time:** The `HashMap` in eBPF is updated instantly upon packet arrival. The user-space loop samples this memory without interrupting the kernel.
* **Aya 0.13.x:** This version leverages the `aya-obj` crate internally, making map lookups via `bpf.map_mut()` very stable.
* **Atomic Safety:** While my snippet uses a simple `get/insert`, for high-performance production, you would typically use a `PerCpuArray` to avoid lock contention between CPU cores.

**Would you like me to show you how to swap this to a `PerCpuArray` to handle multi-core traffic more efficiently?**


----
yes:
Switching to a `PerCpuArray` is the best practice for high-performance networking like RoCE. Standard HashMaps or Arrays use spinlocks or atomic operations that can cause "cache line bouncing" when multiple CPU cores try to increment the same counter at 100Gbps+ speeds.

With `PerCpuArray`, each CPU core maintains its own local counter. The user-space program then sums these individual values to get the total.

### 1. The eBPF Program (`roce-ebpf/src/main.rs`)

We use `PerCpuArray` to ensure that each core writes to its own memory slot, eliminating contention.

```rust
#![no_std]
#![no_main]

use aya_ebpf::{
    macros::{map, xdp},
    maps::PerCpuArray,
    programs::XdpContext,
};
use network_types::{
    eth::{EthHdr, EtherType},
    ip::{Ipv4Hdr, IpProto},
    udp::UdpHdr,
};

#[map]
static ROCE_STATS: PerCpuArray<u64> = PerCpuArray::with_max_entries(1, 0);

#[xdp]
pub fn roce_counter(ctx: XdpContext) -> u32 {
    match try_roce_counter(ctx) {
        Ok(ret) => ret,
        Err(_) => aya_ebpf::bindings::xdp_action::XDP_ABORTED,
    }
}

fn try_roce_counter(ctx: XdpContext) -> Result<u32, ()> {
    let ethhdr: *const EthHdr = unsafe { ctx.ptr_at(0).map_err(|_| ())? };
    
    // Detect RoCE v1 (0x8915) or RoCE v2 (UDP 4791)
    let is_roce = match unsafe { (*ethhdr).ether_type } {
        EtherType::Ipv4 => {
            let ipv4hdr: *const Ipv4Hdr = unsafe { ctx.ptr_at(EthHdr::LEN).map_err(|_| ())? };
            if unsafe { (*ipv4hdr).proto } == IpProto::Udp {
                let udphdr: *const UdpHdr = unsafe { 
                    ctx.ptr_at(EthHdr::LEN + Ipv4Hdr::LEN).map_err(|_| ())? 
                };
                u16::from_be(unsafe { (*udphdr).dest }) == 4791
            } else {
                false
            }
        },
        // Manually check RoCE v1 EtherType if not in network_types constants
        EtherType::Unknown(0x8915) => true,
        _ => false,
    };

    if is_roce {
        // Increment the counter for the CURRENT CPU core only
        if let Some(count) = ROCE_STATS.get_ptr_mut(0) {
            unsafe { *count += 1 };
        }
    }

    Ok(aya_ebpf::bindings::xdp_action::XDP_PASS)
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}

```

---

### 2. The User-Space Program (`roce/src/main.rs`)

In user-space, `roce_stats.get(&0)` now returns a `PerCpuValues<u64>`, which is essentially an iterator/collection of values—one for each core on your system.

```rust
use aya::maps::PerCpuArray;
use aya::programs::{Xdp, XdpFlags};
use aya::{include_bytes_aligned, Bpf};
use std::convert::TryFrom;
use tokio::signal;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    let bpf_data = include_bytes_aligned!("../../target/bpfel-unknown-none/debug/roce");
    let mut bpf = Bpf::load(bpf_data)?;
    
    let program: &mut Xdp = bpf.program_mut("roce_counter").unwrap().try_into()?;
    program.load()?;
    program.attach("eth0", XdpFlags::default())?;

    // Use PerCpuArray instead of HashMap
    let roce_stats: PerCpuArray<_, u64> = PerCpuArray::try_from(bpf.map("ROCE_STATS").unwrap())?;

    println!("Monitoring RoCE Traffic (Per-CPU optimized)...");

    let mut ticker = tokio::time::interval(std::time::Duration::from_millis(500));

    loop {
        tokio::select! {
            _ = ticker.tick() => {
                // Fetch values from ALL CPUs and sum them up
                let values = roce_stats.get(&0, 0)?; 
                let total_count: u64 = values.iter().sum();

                print!("\rTotal RoCE Packets: {}", total_count);
                std::io::Write::flush(&mut std::io::stdout())?;
            }
            _ = signal::ctrl_c() => break,
        }
    }
    Ok(())
}

```

---

### Summary of Changes

* **Performance:** `get_ptr_mut(0)` in eBPF is extremely fast because it points to memory already local to the executing CPU core.
* **Reliability:** No `__sync_fetch_and_add` (atomics) are required in the kernel, reducing CPU cycle overhead per packet.
* **Aggregation:** The user-space code handles the complexity of summing values across cores, which is a "cold path" operation (done once per second), keeping the "hot path" (packet processing) lean.



--- 
