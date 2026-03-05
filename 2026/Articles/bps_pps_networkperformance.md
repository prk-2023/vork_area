# Networking Metrics: PPS vs. BPS Conversion Guide

In network performance testing, understanding the relationship between **Bits per Second (bps)** and 
**Packets per Second (pps)** is critical. 

- bps measures raw throughput, 
- pps measures the workload on the network processor.

---

## 1. The Conversion Logic

To convert between these two metrics, you must account for the **Total Frame Size**, which includes the 
data payload plus the physical layer overhead.

Think of it like transporting goods: 
- bps (bits per second) is the total weight of the cargo you're moving, while 
- pps (packets per second) is the number of boxes you're carrying. 
To convert between them, you need to know how much "weight" is in each "box."
Which depends entirely on the size of the packets.

### The Variables

To convert between the two, you need three pieces of information:


* **Packet Size:** 
    The size of the frame (e.g., 64, 512, or 1500 bytes).( the size of the payload )

* **Ethernet Overhead:** ( L1 Overhead: )
    On standard Ethernet, each frame ( or every packet ) requires a **20-byte** overhead:
    - 8-byte Preamble/Start Frame Delimiter and 
    - 12-byte Inter-Packet Gap 
    So overhead = (8-byte Preamble/Start Frame Delimiter + 12-byte Inter-Packet Gap)

* **Conversion Factor:** ( networking rates are in bits but packet sizes are in bytes )
    - 8 bits = 1 byte.


### The Formulas

**To find Throughput (bps):**


$$\text{bps} = \text{pps} \times (\text{Packet Size} + 20) \times 8$$

**To find Packet Rate (pps):**


$$\text{pps} = \frac{\text{Line Rate in bps}}{(\text{Packet Size} + 20) \times 8}$$

---

## 2. Reference Table (1 Gbps & 10 Gbps)

The table below shows how the required PPS drops significantly as packet size increases, even though the total bandwidth remains the same.

| Packet Size (Bytes) | Total Wire Size | PPS @ 1 Gbps | PPS @ 10 Gbps |
| --- | --- | --- | --- |
| **64** (Smallest) | 84 Bytes | 1,488,095 | 14,880,952 |
| **128** | 148 Bytes | 844,594 | 8,445,945 |
| **512** | 532 Bytes | 234,962 | 2,349,624 |
| **1500** (MTU) | 1520 Bytes | 82,236 | 822,368 |
| **9000** (Jumbo) | 9020 Bytes | 13,858 | 138,580 |

---

## 3. How to Calculate PPS in Linux

Linux doesn't usually show PPS in standard tools like `top` or `ifconfig`. Here are the three best ways to find it:

### Method A: Using `sar` (System Activity Reporter)

The `sysstat` package provides the most readable output.

```bash
# Display statistics for the 'eth0' interface every 1 second
sar -n DEV 1 | grep eth0

```

* **rxpck/s:** Received packets per second.
* **txpck/s:** Transmitted packets per second.

### Method B: The Manual Calculation (Using `sysfs` ) 

You can pull raw numbers directly from the kernel and calculate the difference over one second.

```bash
interval=1
interface="eth0"
before=$(cat /sys/class/net/$interface/statistics/rx_packets)
sleep $interval
after=$(cat /sys/class/net/$interface/statistics/rx_packets)
pps=$(( (after - before) / interval ))
echo "$interface PPS: $pps"

```

### Method C: Using `ethtool` (For Hardware Stats)

For high-performance debugging, `ethtool` shows statistics directly from the Network Interface Card (NIC).

```bash
# This provides a snapshot; run twice to calculate the delta
ethtool -S eth0 | grep packets

```

---

## 4. Why PPS Matters in Testing

If you are testing a firewall or a load balancer, **always test with 64-byte packets.** * 
A 10Gbps link can be saturated by only **822k pps** of large MTU packets.

* The same link requires **14.8 million pps** of small packets.
* Most "10Gbps" devices will fail at the CPU level long before they hit the 10Gbps bandwidth limit if the 
  PPS is high enough.


5. Testing PPS performance with XDP:

`xdp-trafficgen` is an excellent choice for testing PPS (Packets Per Second) performance, but there is a 
small catch: it is technically part of the **`xdp-tools`** suite and is designed to test how fast the XDP 
path can "echo" or "generate" traffic, rather than being a traditional packet generator like `pktgen`.

If you want to test the upper limits of your NIC and driver using XDP, here is how you use it and what it 
tells you.

---

### 1. How `xdp-trafficgen` Works

Unlike a standard generator that sends packets out to a different machine, `xdp-trafficgen` is often used 
to test the **XDP_TX** (hairpin) path. 

It receives a packet and immediately sends it back out the same interface.

### Basic Command

To start a test on a specific interface:

```bash
sudo xdp-trafficgen <interface_name>

```

**What it measures:**

* **Throughput:** 
    How many Millions of Packets Per Second (Mpps) the CPU/NIC can swap and resend.

* **CPU Efficiency:** 
    Since XDP bypasses the heavy `sk_buff` allocation, you should see much higher PPS than with standard 
    `ping` or `iperf`.

---

### 2. Testing the Three Modes

You can explicitly tell `xdp-trafficgen` (and related xdp-tools) which mode to use to compare performance:

* **To test Native (Driver) Support:**
```bash
sudo xdp-trafficgen -N <interface_name>

```

*If this fails, your driver/hardware does not support native XDP.*
* **To test Generic (SKB) Support:**
```bash
sudo xdp-trafficgen -S <interface_name>

```

*Expect significantly lower PPS here as the kernel stack gets involved.*

---

### 3. Alternative: The "Gold Standard" (pktgen)

While `xdp-trafficgen` is great for XDP-specific testing, if you want to saturate a 10Gbps or 40Gbps link 
to see how much XDP can **drop** or **process**, most engineers use the kernel's built-in **`pktgen`**.

`pktgen` lives in the kernel and can blast packets at the line rate. 
You can then monitor the PPS on the *receiving* side using the methods we discussed:

1. **Sender:** Runs `pktgen` (Kernel module).
2. **Receiver:** Runs `xdp-monitor` or `ethtool -S` to see how many packets the XDP program is handling per 
   second.

---

### 4. Why use `xdp-trafficgen` over `iperf`?

If you are testing XDP, **do not use `iperf**`.

* `iperf` uses standard TCP/UDP sockets.

* By the time a packet reaches an `iperf` socket, it has already passed through the entire Networking Stack.

* XDP happens *before* that stack. Using `iperf` to test XDP is like trying to measure the speed of a 
  Formula 1 car while it's stuck behind a tractor in traffic.

#### Summary of Tools

| Tool | Best Used For |
| --- | --- |
| **xdp-trafficgen** | Testing XDP_TX (echo) performance and driver compatibility. |
| **pktgen** | Blasting raw hardware-level PPS to a remote target. |
| **xdp-monitor** | Viewing the real-time PPS of an active XDP program. |
| **bpftool** | Inspecting the BPF instructions of the running program. |

## 6. `pktgen`: Standard Torture testing for high performance networking:

To test your NIC's limits, we will use the Linux kernel's built-in **`pktgen`** (the sender) 
and **`xdp-monitor`** (the receiver). 

This is the standard "torture test" for high-performance networking.

---

### 1. The Sender: Setting up `pktgen`

`pktgen` is a kernel module, so it is much faster than any user-space tool. 
We will configure it to blast the smallest possible packets (64 bytes) to maximize the **PPS**.

#### Step A: Load the module

```bash
sudo modprobe pktgen
```

#### Step B: Run a high-speed blast script

You can use this quick bash script to saturate a 10Gbps+ link. 
Replace `eth0` with your interface and `192.168.1.2` with a dummy destination IP.

```bash
#!/bin/bash
# Configuration
IF="eth0"
DEST_IP="192.168.1.2"
DEST_MAC="00:11:22:33:44:55" # Use the receiver's MAC

# Setup thread 0 (CPU 0)
pgset "add_device $IF"
pgset "device_config $IF"
pgset "pkt_size 64"
pgset "dst $DEST_IP"
pgset "dst_mac $DEST_MAC"
pgset "count 0" # 0 means send forever

# Start the blast
pgset "start"

```

*(Note: `pgset` is a common alias for writing to `/proc/net/pktgen/...` files.)*

---

### 2. The Receiver: Monitoring the XDP Impact

On the receiving machine, you want to see how the NIC handles this flood. 
This is where we compare the "XDP Modes" we discussed earlier.

#### Step A: Install the XDP monitor

If you don't have it, install the `xdp-tools` package (Ubuntu: `sudo apt install xdp-tools`).

#### Step B: Run the monitor

```bash
sudo xdp-monitor <interface_name>

```

**What the logs will tell you:**

1. **XDP_PASS:** 
    The PPS getting through to the Linux kernel stack.

2. **XDP_DROP:** 
    How many millions of packets per second the hardware/driver is discarding before they touch the CPU.

3. **XDP_REDIRECT:** 
    PPS being sent to another NIC or a specialized AF_XDP socket.
    
---

### 3. How to Compare NIC Modes

To truly test your hardware's XDP capabilities, run the blast while toggling these modes on the receiver:

| Mode | Command to Load | Expected Log Result |
| --- | --- | --- |
| **Native** | `xdp-loader load -m native <if> prog.o` | High PPS (e.g., 10M+), low CPU usage. |
| **Generic** | `xdp-loader load -m skb <if> prog.o` | Lower PPS, one CPU core will hit 100% (ksoftirqd). |
| **Offloaded** | `xdp-loader load -m offload <if> prog.o` | Highest PPS, 0% CPU usage on the host. |

---

### 4. Troubleshooting "Low" PPS

If you aren't hitting the numbers you expect (e.g., less than 1M PPS on a 10G card), check the following 
via `ethtool`:

* **Combined Queues:** Ensure the NIC is using multiple queues so the load is spread across CPU cores.
* `sudo ethtool -l <interface>`


* **Ring Buffer Size:** If the buffer is too small, the hardware will drop packets before XDP even sees them.
* `sudo ethtool -g <interface>` (Check "Current Hardware Settings")



## 7. Example code for an **XDP_DROP** program:

Using **Aya** (a pure Rust library for eBPF) is the modern way to handle XDP. 
The version **0.13+**, is updated `aya` and `aya-obj` crates which have streamlined how we load programs 
and attach them to interfaces.

Here is a minimal "Drop All" XDP program and the userspace loader to test your NIC's PPS limits.

---

### 1. The eBPF Program (The "Kernel" Side)

This code runs inside the NIC driver. Its only job is to return `XDP_DROP` as fast as possible.

**File:** `myapp-ebpf/src/main.rs`

```rust
#![no_std]
#![no_main]

use aya_ebpf::{bindings::xdp_action, macros::xdp, programs::XdpContext};

#[xdp]
pub fn xdp_drop_all(_ctx: XdpContext) -> u32 {
    // This is where the hardware/driver stops the packet
    xdp_action::XDP_DROP
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}

```

---

### 2. The Userspace Loader (The "Control" Side)

This Rust code loads the bytecode and attaches it to your NIC. 
In Aya 0.13+, we use the `Xdp` program type and specify the `XdpFlags`.

**File:** `myapp/src/main.rs`

```rust
use aya::programs::{Xdp, XdpFlags};
use aya::{include_bytes_aligned, Ebpf};

fn main() -> Result<(), anyhow::Error> {
    // Load the compiled eBPF bytecode
    let mut bpf = Ebpf::load(include_bytes_aligned!("../../target/bpfel-unknown-none/release/myapp"))?;
    
    // Get the program by name
    let program: &mut Xdp = bpf.program_mut("xdp_drop_all").unwrap().try_into()?;
    
    // Load into the kernel
    program.load()?;

    // ATTACHMENT STRATEGY:
    // Use XdpFlags::default() for Native (Driver) mode
    // Use XdpFlags::SKB_MODE for Generic mode
    program.attach("eth0", XdpFlags::default())?; 

    println!("XDP program loaded. Press Ctrl-C to stop and detach.");
    // Keep the process alive so the program stays attached
    std::thread::park();

    Ok(())
}

```

---

### 3. Testing PPS with Aya

Once you have your Aya program running, you can use the tools we discussed to see if your driver is actually
hitting the "Native" path.

### The "Log" of Truth

Run your Aya loader, then in a separate terminal, check the interface flags:

```bash
ip link show dev eth0

```

* **Native Mode:** You will see `xdp` or `prog/xdp`.
* **Generic Mode:** You will see `xdpgeneric`.

#### Measuring the PPS

While your `pktgen` script is blasting the interface, use `ethtool` to see the drop rate. 
If Aya is working in Native mode, the CPU usage (check `htop`) should remain relatively low even at 
millions of packets per second because the kernel stack is never touched.

```bash
# Watch the drops in real-time
watch -n 1 "sudo ethtool -S eth0 | grep xdp_drop"
```

---

## 4. Why Aya 0.13+ is better for this

* **Type Safety:** You get compile-time checks that you aren't passing a Socket program to an XDP hook.

* **No C Toolchain:** Unlike `libbpf`, you don't need `clang` or `llvm` installed on your target production
  machine; the Rust binary is self-contained.

* **BTF Support:** Aya automatically handles BTF (BPF Type Format), meaning your XDP program is portable 
  across different kernel versions without recompiling.


