# RoCE, RDMA, SmartNIC' 


## Introduction:

Standard TCP/IP networking is a "best effort" networking, this model presents many challenges when we move
into the world of high-throughput, sub-microsecond latency environments like HPC, AI Clustering and High
Freq trading. 

In standard Linux network stack, the CPU spends its life copying data from NIC to the kernel and then kernel
to the user-space application. So Every packet that hits a normal NIC triggers an interrupt, forcing the 
CPU to stop what it's doing, copy data from the NIC to kerenl-space and then over to user-space.
This model works but fails to meet the demands of HPC, AI Clustering or High freq trading ... 
To solve this latency or fast processing, is the need for Zero-Copy technology that bypasses CPU entirely. 

### 1. The Core Hardware: SmartNICs & DPUs

- SmartNICs: NICs that has his own onboard processing engine ( ASIC, ARM Cores or FPGA's )
  these handle data by offloading tasks like ( Encryption or Firewalling ) so your main CPU does not have to
  touch them. 

  High speed networking ( 100GbE+ ) can consume up to 30% of a server's CPU just processing header and
  moving data. SmartNICs can handle tasks like encryption ( IPSec/TLS ), firewalls, and storage logic to the
  NIC. 

- DPU ( Data Processing Unit ): These are Super SmartNICs that can run its own mini Linux OS independently
  of the host server. 

- SmartNICs reach high speeds (100G, 400G, 800G) and standard ethernet cable supports a single data lane, to
  reach high data rates, SmartNICs use QSFP (Quad Small Form-factor Pluggable) and OSFP (Octal Small Form-
  factor Pluggable) ports for one primary reason: Density and Bandwidth.
  - QSFP (Quad): port combines 4 independent tx/rx lanes into a single plug. If each lane runs at 25Gbps,
    you get a 100G port. If they run at 50Gbps, you get 200G.
  - OSFP (Octal): Newer, port combines 8 lanes. With 100Gbps per lane (using PAM4 signaling), a single OSFP
    port delivers 800G of bandwidth.

- A PCIe Gen4 x16 slot can move roughly 256Gbps. ( each PCIe lane about 920+ Mbps for pcie 3.0 )

- A QSFP56 port (200G) or QSFP-DD/OSFP (400G+) ensures that the network connection isn't the bottleneck for
  the RDMA traffic coming off the motherboard.

At High speeds of 100 Gbps electricity does not behave like on-off switch but its rather like a radio wave 

### 2. The Protocols: RDMA (The "How")

RDMA (Remote Direct Memory Access) is the ability to access memory on a remote machine without involving 
that machine’s CPU or Operating System.

#### The Three Flavors of RDMA:

1. InfiniBand (IB): Its a completely different hardware ecosystem from Ethernet. Its a proprietary
   networking architecture designed from the groundup for HPC. It does not use Ethernet at all.

- *Fabric Control*: It uses *Subnet Manager* to handle routing and traffic, making it "lossless" by design
  at the HW level. 

- *Latency*: Offers lowest possible latency (sub-microsecond ) as HW handles flow control natively. 
- *Design*: Lossless by design using hardware-level flow control (credits).
- *Components*: Requires InfiniBand Switches and a **Subnet Manager (SM)** to assign LIDs (Local IDs).

2. RoCE (RDMA over Converged Ethernet):

- The Hybrid:  Runs RDMA over standard Ethernet cables/switches.
- RoCE v1: Layer 2 only (can't cross routers).
- RoCE v2: Wraps RDMA in UDP/IP (routable).

3. iWARP:

- The Legacy:  RDMA over TCP. It's more complex and has higher latency than RoCE, so it is rarely used in
  modern AI/HPC clusters.

---

## 3. The Linux Implementation (The "Where")

On Linux, everything RDMA-related lives in the `rdma-core` user-space and the `ib_verbs` kernel subsystem.

### Key Linux Tools:

| Tool | Purpose |
| --- | --- |
| `ibv_devices` | Lists available RDMA-capable hardware. |
| `rdma link` | The modern `iproute2` command to manage RDMA interfaces. |
| `ibstat` / `ibstatus` | Checks if the InfiniBand link is "Active" and has a LID. |
| `opensm` | The daemon that acts as the Subnet Manager (required for InfiniBand). |
| `perftest` | A suite of tools (`ib_send_bw`, `ib_write_lat`) to benchmark RDMA. |

---

## 4. The "Missing" Piece: Lossless Ethernet (PFC)

If you choose **RoCE** instead of **InfiniBand**, you must configure your Linux host and your Network Switch 
for **PFC (Priority Flow Control)**.

* Standard Ethernet drops packets when congested.
* RDMA **fails** if a packet is dropped (it doesn't have the "retry" logic of TCP).
* PFC tells the sender to "pause" so the buffer doesn't overflow, making Ethernet behave like InfiniBand.

## 5. Verbs:

They are standardized API (Application Programming Interface) used to manage those high-speed data 
transfers without bothering the CPU.

"Verbs" are like grammar of RDMA: they are the specific actions to tell the network card exactly what to do.

---

### How Verbs Work

In traditional TCP/IP, the operating system handles the heavy lifting.

With RDMA Verbs allow an application to talk directly to the **HCA (Host Channel Adapter)**. 

This bypasses the kernel, reducing latency and CPU overhead.

The architecture relies on a **Queue Pair (QP)** mechanism, consisting of two queues:

1. Send Queue: Where the application posts instructions for data to be sent.
2. Receive Queue: Where the application posts instructions for where incoming data should be placed.

---

### Core Categories of Verbs

The RDMA ecosystem typically categorizes these operations into two main types:

#### 1. One-Sided Operations (The "True" RDMA)

The local CPU specifies the memory address on the *remote* machine. 
The remote CPU doesn't even know the transfer is happening.

* RDMA Write: Push data from local memory to remote memory.
* RDMA Read: Pull data from remote memory to local memory.
* Atomic Operations: Perform "fetch-and-add" or "compare-and-swap" on remote memory addresses.

#### 2. Two-Sided Operations (Channel Semantics)

Both the sender and the receiver are involved, similar to traditional networking but much faster.

* Send: The local side sends data.
* Receive: The remote side must have a "receive request" waiting in its queue to accept that data.

---

### The Lifecycle of a Verb Call

To execute a transfer, an application follows a specific workflow:

| Step | Action | Description |
| --- | --- | --- |
| 1. | Registration | Register a memory region with the HCA so the hardware can access it safely. |
| 2. | Post Send/Receive | Place a **Work Request (WR)** into the Queue Pair. |
| 3. | Processing | The HCA hardware executes the request independently of the CPU. |
| 4. | Completion | The HCA places a **Completion Queue Entry (CQE)** into a Completion Queue (CQ) to let the app know it's done. |

---

Using Verbs is significantly more complex than standard socket programming, but the payoff is massive:

* *Zero-Copy:* Data goes straight from application memory to the wire.
* *Kernel Bypass:* No context switching between user mode and kernel mode.
* *Low Latency:* Microsecond-level transfers, essential for AI training clusters and high-frequency trading.


Registering a Memory Region (MR) is a critical step: 
It "pins" the memory (prevents the OS from swapping it to disk) and gives the HCA a translation table so 
it can find the physical RAM addresses without asking the CPU.

#### 1. C Code Example (`libibverbs`)

In C, you use the `ibv_reg_mr` function. 

You must already have an open "Protection Domain" (`pd`), which is a container that groups your resources.

```c
#include <infiniband/verbs.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    // 1. Allocate a standard buffer in user-space
    size_t length = 4096;
    void *buffer = malloc(length);

    // 2. Assume 'pd' is a previously initialized struct ibv_pd*
    struct ibv_pd *pd; 
    // ... (Device opening and PD creation code would go here)

    // 3. Register the memory region
    // Access flags: Local Write, Remote Read, Remote Write
    int access_flags = IBV_ACCESS_LOCAL_WRITE | 
                       IBV_ACCESS_REMOTE_READ | 
                       IBV_ACCESS_REMOTE_WRITE;

    struct ibv_mr *mr = ibv_reg_mr(pd, buffer, length, access_flags);

    if (!mr) {
        fprintf(stderr, "Error: Could not register MR\n");
        return 1;
    }

    printf("MR registered! Remote Key (R_Key): %u\n", mr->r_key);

    // Clean up
    ibv_dereg_mr(mr);
    free(buffer);
    return 0;
}

```

---

#### 2. Can this be done in Rust?

High-performance networking in Rust is a growing field. But it requires  `unsafe {}` blocks.

1. Raw Pointers: You are passing a raw memory address to a C library (`ibverbs` via FFI).

2. Lifetime Ambiguity: The Rust compiler cannot track what the **HCA (Hardware)** is doing. 
   If you drop the buffer in Rust while the hardware is still writing to it, you get a "Use-After-Free" 
   at the hardware level, which leads to silent data corruption or a system crash.

3. External Modification: 
   RDMA allows a *remote* computer to change your local memory. 
   This violates Rust's core rule that only one thing should have a mutable reference to data at a time.

#### The Rust Approach (using `rdma-core` or `ibverbs` crates)

Usually, you would use a crate like `ibverbs-rs`. 

It wraps the C calls, but the registration remains unsafe because you are promising the compiler that the
memory will stay valid.

```rust
use ibverbs;

fn main() {
    // ... setup device and protection domain (pd) ...

    let mut data: Vec<u8> = vec![0; 4096];
    
    // Memory registration is inherently unsafe
    unsafe {
        let mr = pd.reg_mr(
            data.as_mut_ptr() as *mut _, 
            data.len(), 
            ibverbs::ibv_access_flags::IBV_ACCESS_LOCAL_WRITE |
            ibverbs::ibv_access_flags::IBV_ACCESS_REMOTE_WRITE
        ).expect("Failed to register MR");

        println!("Registered MR with r_key: {}", mr.r_key());
        
        // CRITICAL: You must ensure 'data' outlives 'mr' 
        // and that no one touches 'data' while the HCA is busy.
    }
}

```

---

Whether in C or Rust, the **L_Key** (Local Key) and **R_Key** (Remote Key) generated during this step are 
the "passports" for your data.

* Use the *L_Key* for your local `ibv_post_send` calls.
* Send the *R_Key* and the **Virtual Address** to the remote machine so it knows where it's allowed to write.

---

## 6. Summary Cheat Sheet

* **InfiniBand:**
    Best performance, easiest to set up (software-wise), but requires buying all-new proprietary hardware.

* **RoCE v2:** 
    Great performance on existing Ethernet hardware, but requires a nightmare-level configuration of 
    "Lossless Ethernet" on your switches.

* **SmartNIC:** The physical card that makes either of the above possible while freeing up your CPU to 
  actually run your apps.

* **Verbs:** The API (programming language) Linux apps use to talk to these cards.

---

# RoCE: 

**RoCE** (RDMA over Converged Ethernet) with a ConnectX SmartNIC is the "gold standard" for understanding 
how modern data centers handle massive traffic with near-zero CPU overhead.

To understand how RDMA over Converged Ethernet (RoCE) and SmartNICs function, it helps to look at them as a
specialized HW-SW sandwich designed to eliminate the "middleman" ( The CPU ).

---

### 1. What is RDMA?

To understand RoCE, you first need to understand **RDMA (Remote Direct Memory Access)**.

In a "Normal" network (TCP/IP), the CPU is heavily involved. 

Every packet that arrives must be processed by the Kernel, copied from the NIC to a kernel buffer, and then
copied again into the Application's memory. This creates **Latency** and **CPU Overhead**.

**RDMA** allows one computer to read or write directly into the memory of another computer **without 
involving either system's CPU or Operating System kernel.**

---

### 2. Enter RoCE: InfiniBand meets Ethernet

Historically, RDMA only worked on **InfiniBand** hardware (special cables, special switches). **RoCE** was 
invented to allow these high-speed RDMA benefits to run over standard, cheap **Ethernet** infrastructure.

There are two versions you need to know:

* **RoCE v1:** An Ethernet layer-2 protocol. It is not routable (it stays within one switch/subnet).

* **RoCE v2:** Encapsulates the RDMA data inside a **UDP/IP packet**. This is what your ConnectX card uses.
  Because it has an IP header, it can be routed across different networks and works perfectly with standard 
  IP logic.

---

### 3. The "Secret Sauce": Zero-Copy and Kernel Bypass

When you use RoCE on your ConnectX card, three magic things happen:

1. **Kernel Bypass:** 
    The application talks directly to the NIC hardware. It "skips" the Linux networking stack entirely.
    
2. **Zero-Copy:** 
    The NIC pulls data directly from your RAM. There are no intermediate copies.

3. **Hardware Offload:** 
    The ConnectX card handles the "Retransmission" and "Acknowledge" logic that the CPU usually handles for
    TCP.

---

### Essential components that make up High performance EcoSystem:

Breakdown of the essential components that make this high performance ecosystem work:

#### 1. RDMA/RoCE SW Stack:

This layer allows your application to "talk" to the HW without the need to wait for the OS permission for
every packet. 

- *User-Space Library*: ( `libibverbs` ): Linux library that provides "Verbs" API. It allows to bypass the
  kernel. 

- 

### 4. Key Concepts for your Testing

| Term | What it is | Why it matters for your script |
| --- | --- | --- |
| **HCA** | Host Channel Adapter | This is your ConnectX card. |
| **GID** | Global Identifier | The "RDMA Address." In RoCEv2, this is essentially your IP address. |
| **Verbs** | The API | You don't "send sockets"; you "post verbs" (Send, Receive, Read, Write). |
| **Queue Pair (QP)** | The Connection | Instead of a TCP Port, RDMA uses a pair of queues to send/receive data. |

---

### 5. "Single Card, Two Namespace" test for exploring RDMA and RoCE. 

By putting Port 0 in `ns1` and Port 1 in `ns2`, you are forcing the data to:

1. Leave the RAM of the system.
2. Go through the **ConnectX Silicon**.
3. Exit the physical **Port 0**.
4. Travel through the **DAC Cable**.
5. Enter physical **Port 1**.
6. Return to RAM.

This confirms that your **Offload Engines** are working. 

If you just did a normal "Ping" between two local IPs, the Linux Kernel would shortcut the traffic internally
and never actually use the 25G wire!

---

# Address Table: 

### Next Step: Looking at the "Address Table"

Before we move to the next test, would you like to see how to use the `ibv_devinfo` or `rdma res` commands 
to see the **GID Table**? 
This will show you exactly which "ID" your card has assigned to its RoCE v2 (UDP) personality.

To see how RoCE is actually addressed, we look at the **GID (Global Identifier) Table**. 

In RoCE v2, the GID is essentially your IPv4 address mapped into a 128-bit IPv6-style format so the RDMA 
hardware can understand it.


### 1. The "Traditional" View: `show_gids`

Mellanox (NVIDIA) provides a specific script to make this table human-readable. 

Since your interfaces are inside namespaces, you must execute it there:

```bash
sudo ip netns exec ns1 show_gids

```

**What to look for in the output:**

* **Index:** This is the number (e.g., `0, 1, 2`) you pass to testing tools using the `-x` flag.
* **GID:** You should see your IP (`10.0.0.9`) embedded at the end of the GID string.
* **Type:** It should clearly state **RoCE v2**.
* **Device/Port:** It will confirm it's tied to `enp1s0f0np0`.

---

### 2. The "Modern" View: `rdma addr`

If you want to use the standard Linux `rdma-tool` (part of `iproute2`), run:

```bash
sudo ip netns exec ns1 rdma res show 
# or
sudo ip netns exec ns1 rdma res show path

```

Or to see the hardware devices currently mapped:

```bash
sudo ip netns exec ns1 rdma dev

```

---

### 3. Deep Hardware Info: `ibv_devinfo`

To see the "Health" of the RDMA port (MTU size, Max Queue Pairs, and the "Active" state), use:

```bash
sudo ip netns exec ns1 ibv_devinfo -d rocepl1s0f0
# or 
sudo ip netns exec ns1 ibv_devinfo -d mlx5_0 -p 1

```

> **Key Fields to Verify:**
> * **transport:** Should be `InfiniBand` (this is normal for RoCE).
> * **active_mtu:** For 25GbE, this is usually `1024` or `2048`. If it's too small, performance will drop.
> * **state:** Must be `PORT_ACTIVE`.
> 
> 

---

### 4. Why the GID Index Matters

When you eventually run your performance test (like `ib_send_bw`), the tool needs to know which "personality"
of the card to use.

* **Index 0/1:** Usually RoCE v1 (Legacy).
* **Index 2/3:** Usually **RoCE v2** (The one that uses UDP and IP).

If you pick the wrong index, your `ping` will work, but your RDMA test will fail with a "Connection Refused" 
or "Timeout" because the hardware is looking for a different packet header.

---

### Summary Table for your Namespaces

| Tool | Purpose |
| --- | --- |
| `show_gids` | Shows the IP-to-RDMA mapping and the **Index** number. |
| `ibv_devinfo` | Checks if the hardware port is "Active" and its Max MTU. |
| `rdma dev` | Confirms the `mlx5` device is actually inside your namespace. |


---

# XDP Scope:


Because RDMA bypasses the CPU and the kernel, the CPU has no idea what’s inside the packets as they fly by.
The data goes straight from the wire to RAM. 

If you want to inspect that data to make a routing decision or filter a malicious packet, you're usually 
out of luck until the transfer is already finished.

**XDP (eXpress Data Path)** can indeed help, but there is a major architectural "catch" regarding how it 
interacts with RDMA.

---

### 1. The Conflict: Bypass vs. Inspection

The reason RDMA is so fast is **Kernel Bypass**. 

The reason XDP is so fast is **Early Kernel Intervention**.

* RDMA/RoCE: The packet goes from the NIC hardware directly to the application memory. The Linux networking
  stack never sees it.

* XDP: BPF program runs in the NIC driver *within the kernel* (or offloaded to the hardware) the moment a
  packet arrives.

The Reality: In standard implementations, **XDP cannot see RDMA (RoCE) traffic.** 

When the NIC is in "RDMA mode" for a specific Queue Pair, those packets take a "fast path" that skips the 
driver's XDP hook entirely.

---

### 2. Can XDP offer a solution?

While XDP can't inspect an active RDMA write mid-stream, it can be used for the **Control Plane** or for 
**Hybrid Traffic**:

* Filtering the Setup: 
  - You can use XDP to filter the connection setup (CM) packets. 
  - Since RDMA connections often start with standard IP/UDP handshakes, XDP can drop unauthorized connection 
    attempts before they ever establish a "Verbs" session.

* Side-car Processing:
  - Some advanced architectures use XDP to handle small, logic-heavy packets (metadata) while leaving the
    heavy data lifting to RDMA.

* Programmable SmartNICs (The Real Solution):
  - If you need "Smart Logic" on the data plane without losing RDMA performance, you don't look at XDP in
    the kernel; you look at **P4** or **DPDK** running *inside* the SmartNIC.

---

### 3. XDP vs. RDMA: A Trade-off Comparison

| Feature | RDMA (RoCE) | XDP |
| --- | --- | --- |
| **Logic** | Fixed (Hardcoded in ASIC) | Highly Programmable (eBPF) |
| **CPU Load** | Near Zero | Low (but non-zero) |
| **Throughput** | Maximum (Wire speed) | High (but limited by CPU per-packet) |
| **Visibility** | Opaque (Hardware to RAM) | Transparent (Can parse headers) |

---

### 4. The "Middle Ground": SmartNIC Offloads

If your goal is to implement logic (like a load balancer or a firewall) but you want to keep the "Low Load"
of RDMA, you generally move the logic to the **SmartNIC hardware** itself.

Modern SmartNICs (like the BlueField-3) allow you to:

1. Run a tiny Linux OS on ARM cores inside the NIC.
2. Use **DOCA** or **P4** to inspect packets.
3. Direct the hardware to perform an RDMA write *only after* the logic checks out.

### Summary

XDP is the king of the **programmable software data plane**, but it operates in the "Kernel Space" world. 

RDMA operates in the "Hardware Space" world. 

If you need smart logic *and* RDMA, you usually have to implement that logic in the **SmartNIC firmware** 
or use a hybrid model where XDP handles the "Decision" and RDMA handles the "Delivery."

You generally cannot intercept active RDMA data transfers with XDP, hardware architecture prevents this and
where the "short path" actually happens. 

### by-pass is physical and not Logical. 

In a standard RoCE v2 flow, the "interception point" where XDP lives (the NIC driver's receive ring) is 
physically bypassed by the ASIC.

* The Hardware Path:
    - When an Ethernet frame arrives, the SmartNIC ASIC parses the headers. 
    - If it sees **UDP Port 4791** (the RoCE v2 port) and a valid **Queue Pair (QP)** number, the HW's DMA
      engine takes over immediately.

* Zero-Copy Magic:
    - The ASIC looks at its internal translation table (the one you created during `ibv_reg_mr`), finds the
      physical RAM address, and pushes the data there via the PCIe bus.

* The XDP Skip:
    - The driver—and by extension, the Linux kernel and XDP—never sees the packet. 
    - The CPU is never interrupted. 
    - If XDP were to intercept it, the "Zero-Copy" benefit would be lost because the CPU would have to touch
      the packet.
---

# Scope of XDP

* *XDP* when you want the **CPU** to be a "smart gatekeeper" for the Linux networking stack.
* *RoCE* is for when you want the **Network Card** to be a "silent mover" of data directly to RAM.

---

### Where XDP "Lives" vs. Where RoCE "Lives"

To visualize why they don't mix, think of the incoming packet's journey:

1. *The Physical Wire:* The packet arrives at the SmartNIC.

2. *The ASIC Decision (The Split):* 
  - **Is it RoCE?** The ASIC sees the UDP 4791 port and the RDMA header. 
  - It "steals" the packet and uses **DMA** to write it straight to the application's memory. 
  - The CPU never sees it.
  - Is it Standard Traffic (HTTP, SSH, DNS)? The ASIC passes it to the driver.

3. The XDP Hook:
   - This is the *first* piece of code that runs in the driver. 
   - Since the RoCE packet was already "stolen" in step 2, it never reaches this hook.

---

### When to use XDP (The "Smart" Data Plane)

When you require a logic-based data plane, XDP is your best friend for:

* **DDoS Protection:** Dropping millions of "bad" packets per second before they hit the heavy Linux kernel.
* **Load Balancing:** Rewriting packet headers (IP/Port) at wire speed to distribute traffic.
* **Custom Protocols:** If you invented your own protocol and need the CPU to parse it instantly.

### When to use RoCE (The "Fast" Data Plane)

You use RoCE when the "logic" is already decided. 

You know exactly which server needs which data, and you just want it moved with:

* **Zero CPU overhead.**
* **Minimum Latency** (sub-2 microseconds).

---

### Can you have both? (The "Hybrid" Architecture)

In high-end systems (like those built with **NVIDIA BlueField** SmartNICs), engineers use a hybrid approach:

1. The Control Plane (XDP/Slow Path): 
    - Use XDP or standard sockets to negotiate. 
    - "Hey Server B, I’m about to send you 10GB of AI training data. Here is my Memory Key."

2. The Data Plane (RoCE/Fast Path):
    - Once the "handshake" is done, the data moves via RDMA Verbs. No logic is needed anymore; it's just 
      raw speed.

---

### Summary Table: Choosing Your Tool

| If you need... | Use **XDP** | Use **RoCE** |
| --- | --- | --- |
| To inspect every packet | Yes | No (Hardware bypasses inspection) |
| Lowest possible latency | Very Low | The Lowest (Hardware speed) |
| To run custom C/Rust logic | Yes (via eBPF) | No (Logic must be in SmartNIC) |
| To bypass the CPU | No (Uses CPU cycles) | **Yes** (0% CPU for data movement) |

