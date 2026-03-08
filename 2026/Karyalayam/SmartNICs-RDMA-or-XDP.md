# RDMA ( Remote Direct Access Memory )

- DMA: Trick where HW moves data without bothering the CPU. 
- RDMA: Stretches this concept over to network. Essentially allowing one computer to access the memory of
  another computer directly bypassing the operating system and CPUs of both machines. 


## RDMA: The "Hardware-First" Approach

RDMA is a **hardware-defined transport**. 

The logic for moving data, checking for errors, and acknowledging packets is "burned" into the NIC’s ASIC or 
firmware. ( unlike XDP where the logic can be loaded by eBPF program )

## How it works:

- Traditionally network transfer (like TCP/IP) data has to be copied multiple times from the application to
  the OS Kernel, then to the network card, then back up through the layers on the receiving end. This
  creates *latency* and consumes *CPU cycles*.

- **RDMA**: Removes the above mentioned middle steps in 3 core mechanisms:
    1. **Zero-Copy**: 
        DATA is directly passed from application memory to the network adapter and then straight into the
        destination's application memory. 

    2. **kernel bypass**:
        Application communicates directly with the Hardware. The OS stays out of the way, which eliminates
        "Context Switching". ( overhead of the CPU jumping between tasks )

    3. **No CPU Involvement**: 
        Once the transfer is setup the network adapter handle the heavy lifting. The CPUs on both ends can
        go back doing actual work.


### Compare it with XDP:

RDMA is hardware-defined transport. The logic of moving data, checking for errors and acknowledging packet
is "burned" into the NIC's ASIC or firmware.

- **The CPU is invisible**: CPU tells NIC, "Hay take this 1GB of data and put it in the RAM of Server B,"
  and then the CPU literally goes to sleep or does other work. 

- **Protocol Dependent**: Requires specific headers ( like RoCE v2 or InfiniBand ).

### RDMA and XDP:

RDMA and XDP are two different but are related to SmartNIC:

- Both use *Zero-Copy*
- RDMA uses "memory Registration" and XDP Uses "UMEM". Both of these involve HW writing directly to a memory
  address that the user-space application can use. 

#### Choice between RDMA and XDP:

Generally in Data Centers:

- RDMA: Developer may use RDMA if they want the absolutely lowest CPU usage for storage.
- XDP: If there need to process custom web traffic or complex firewall rules that RDMA can't handle. 

### Why Use it?

RDMA is the backbone of modern high-performance infrastructure because it solves the bottleneck problem. 

---
|Feature   | Standard Networking (TCP/IP)|RDMA |
| :---     | :---:                       | ---: |
|Latency   |High (Milliseconds/Microseconds)|Ultra-Low (Nanoseconds)|
|CPU Usage |High (Processing packets)|Near Zero|
|Throughput|Limited by CPU speed|Limited only by wire speed|
---

Generally used in :

- HPC: Super computing for massive calculations where nodes need to share data instantly.
- AI Training: Training large models, GPUs use RDMA ( often via NVIDIA GPUDIRECT) to talk to each other
  across servers.
- Flash Storage: NVMe-over-Fabric (NVMe-oF) uses RDMA to make remote storage feel as fast as local hard
  drive. 

## Common Protocols:

To use RDMA you need specific hardware and protocols:

- InfiniBank: The golden standard purpose-built for RDMA.

- RoCE ( RDMA over Converged Ethernet ) Allos RDMA to run over standard Ethernet cables.

- iWARP: Runs RDMA over the standard TCP protocol.


## SmartNIC Development:

If you are building a SmartNIC, you have to decide which "engine" your hardware supports:

- If You Support RDMA:  NIC HW must understand *Queue Pairs (QP)*, It needs a **"state machine"** to handle
  retries and sequence numbers without the help from any software. 

- Is You support XDP Offloading: NIC needs an **eBPF Execution Engine**. It needs to be able to take a
  compiled C/Rust Program from the user-space and run it on the NIC's own silicon. 

| Feature | RDMA | XDP (AF_XDP) |
| --- | --- | --- |
| **Who moves the data?** | The NIC Hardware (DMA Engine). | The CPU (via XDP program). |
| **Who defines the rules?** | Networking Standards (IBTA). | The Developer (C/eBPF code). |
| **Main Benefit** | Zero CPU overhead. | Extreme flexibility + Speed. |
| **SmartNIC Role** | Fixed-function offload. | Programmable execution offload. |

---

# Mellanox: 

Mellanox ConnectX series are generally classified as **Foundational NICs** or "High-Performance NICs" rather
than "SmartNICs," and their claim to fame is **RDMA**, not XDP.

Here is the breakdown of why that distinction matters for your development work:

---

## 1. ConnectX: The RDMA Kings

Mellanox (now NVIDIA) designed the ConnectX-3/4/5 primarily as **RDMA engines**.

* They have "Hard-Wired" logic for **RoCE** and **InfiniBand**.
* When you use RDMA on a ConnectX card, the hardware handles the entire transport layer.
* **XDP Support:** While they *do* support XDP (you can run XDP programs on them), they usually do it in 
  **Native Mode** (running on the host CPU) rather than **Offloaded Mode** (running on the card itself).

## 2. What makes a "SmartNIC" different?

In the industry, a "True" SmartNIC like the 
    **Mellanox BlueField**, 
    **AMD/Pensando**, or 
    **Intel Mount Evans**) 
contains extra "brains" that a standard ConnectX card doesn't have.

| Feature | Standard NIC (ConnectX-5) | True SmartNIC (BlueField-3 / Pensando) |
| --- | --- | --- |
| **Main Engine** | Fixed-function ASIC (RDMA/RSS/Checksum). | **General Purpose Cores** (ARM/MIPS) or **FPGA**. |
| **XDP Role** | Usually passes packets to the Host CPU. | Can **fully offload** and execute the XDP/eBPF code on the card. |
| **OS** | Runs a simple firmware. | Often runs its own **complete Linux OS** (on the card!). |
| **Memory** | Small internal cache. | GBs of dedicated onboard DDR4/5 RAM. |

---

## 3. The XDP "Offload" Catch

While working on SmartNIC development, this is the most important technical detail:

* **XDP-Native:** 
    - Supported by almost all modern Mellanox/Intel cards. 
    - The XDP program runs on the **Host CPU** just before the kernel stack. It's fast, but it still eats
      your main CPU cycles.

* **XDP-Offload:** 
    - This is what makes a NIC "Smart."
    - The NIC hardware must have a translator that takes the eBPF instructions and runs them on the 
      **NIC's internal processors**.

> **The Reality Check:** Even though Mellanox ConnectX cards are amazing, they aren't typically used for
> *XDP Offload*. 
> If you want to offload XDP, you usually look at **Netronome Agilio** cards or **FPGA-based** NICs.

---

## Where do you fit in?

If you are developing a SmartNIC, you are likely working on one of two things:

1. **The eBPF JIT/Offload Engine:** 
    Making it so the user's XDP code can run on your NIC's silicon.

2. **The Data Plane:** 
    Making sure your NIC can move data as fast as RDMA (Zero-copy) while still allowing the flexibility of 
    XDP.


### BlueField DPU:

This is where things get interesting for a SmartNIC developer. 

The **BlueField DPU** (Data Processing Unit) is essentially a **ConnectX NIC and an ARM-based computer** 
smashed into a single piece of silicon.

Because they share the same DNA, both use the `mlx5` driver, but they use it very differently.

---

#### 1. The "Split" Personality of BlueField:

A BlueField card has two main "worlds." As a developer, you need to know which world your code is running in:

* **The ARM World (The "Smart" Side):** 
    - The card runs its own OS (usually Ubuntu) on its internal ARM cores. 
    - In this world, the `mlx5` driver sees the "physical" network ports. 
    - This is where the real "Smart" logic lives.

* **The x86 World (The Host Side):** 
    - Your server sees a regular network card. 
    - The `mlx5` driver on the server thinks it's talking to a standard NIC, but it's actually talking to
      the BlueField's internal switch.

##### How XDP fits in

Even on a BlueField, **"XDP Offload"** (running your eBPF code directly on the network ASIC) is not the 
standard way things work.

1. **XDP-Native (Host):** 
    - If you load an XDP program on your server, it runs on the **x86 CPU**. 
    - The BlueField just hands the packets over.

2. **XDP-Native (ARM):** 
    - You can log into the BlueField via SSH and load an XDP program *on the ARM cores*. 
    - This is technically "offloading" the work from your server's CPU, but the ARM cores on the NIC are now
      doing the work.

3. **Hardware Offload:** 
    - Most BlueField users don't use XDP for the fastest path
    - They use **ASAP (Accelerated Switch and Packet Processing)**. 

    This uses the `mlx5` driver to "offload" rules into the hardware eSwitch using Open vSwitch (OVS) or 
    TC (Traffic Control).

---

### 2. RDMA on BlueField

RDMA is the "native language" of the `mlx5` hardware.

Inside a BlueField, the ARM cores and the Host x86 CPU can **both** use RDMA to talk to each other or to the
network.

* **Snap/VirtIO:** 
    - BlueField can use RDMA to "pretend" to be a local NVMe drive. 
    - The host thinks it's writing to a disk, but the BlueField is secretly using **RDMA** to send that data
      to a storage server across the room.
---

### 3. For Developing  SmartNIC Work:

Since you are developing a SmartNIC, here is how you should categorize the BlueField/mlx5 setup:

| Component | Role in BlueField | Connection to RDMA |
| --- | --- | --- |
| **ConnectX ASIC** | The "Mover." | Handles the actual RDMA Verbs and packet DMA. |
| **ARM Cores** | The "Brain." | Can run XDP programs or control where RDMA traffic goes. |
| **mlx5 Driver** | The "Translator." | Manages both the RDMA resources and the XDP hooks. |

**The Developer's Reality:**

If your goal is to make a "BlueField-killer," you are likely looking at how to make that :
**ARM/SoC → Network ASIC** path faster.

--- 

# True XDP SmartNICs

Mellanox (NVIDIA) is so dominant in the **RDMA** space, they have doubled down on their proprietary hardware
offload engines (ASAP) rather than implementing a generic eBPF/XDP offload engine.

For cards that support XDP hardware offload mode, but it is a niche market are different and listed below.

---

## 1. The XDP Offload "Unicorns"

As of 2026, finding a card that supports `XDP_FLAGS_HW_MODE` (full offload to the NIC silicon) usually 
leads you to these specific players:

### **Netronome Agilio (The Gold Standard for XDP Offload)**

* **Status:** 
    - This is the most famous example in the Linux community.

* **How it works:** 
    - Netronome cards use a many-core NPU (Network Processing Unit). 
    - When you load an XDP program, the `nfp` driver actually JIT-compiles your eBPF code into the NPU's 
      machine code.

* **The Benefit:** 
    - The packet is dropped or redirected *inside* the NIC hardware. 
    - It never touches the PCIe bus, and the host CPU usage is **0%**.

### **Intel IPUs (Mount Evans / E2000)**

* **Status:** 
    - Intel is pushing the "IPU" (Infrastructure Processing Unit) concept hard.

* **How it works:** 
    - These cards have a P4-programmable pipeline. 
    - While they don't always "run" raw eBPF natively, Intel provides tools to map XDP logic into their 
      hardware pipeline (often via the `idpf` driver).

### **FPGA-based SmartNICs (AMD/Xilinx Alveo)**

* **Status:** 
    - High-end, custom-built.

* **How it works:** 
    - Since it's an FPGA, you can literally "burn" an eBPF executor into the gates. 
    - There are open-source projects (like **hXDP**) that allow you to run XDP programs on FPGA NICs at line
      rate.

---

## 2. Why doesn't Mellanox (NVIDIA) do this?

For  SmartNIC development, this is a critical design lesson. 

NVIDIA chose a different path called **ASAP (Accelerated Switching and Packet Processing)**:

1. **Fixed-Function Speed:** 
    - NVIDIA believes hardware state machines (ASIC) are always faster and more power-efficient than
      programmable once (eBPF).

2. **The "TC" Path:** 
    - Instead of XDP, they focus on offloading **TC (Traffic Control)** rules. 
    - If you use `tc filter add ... skip_sw`, the `mlx5` driver takes that rule and puts it in the NIC's 
      hardware eSwitch.

3. **Competition:** 
    - XDP is a Linux-specific standard. 
    - NVIDIA prefers their own technologies (like DOCA) that can work across different operating systems.
---

## 3. The Current "State of the Art" (2026)

If you are building a SmartNIC today and want to stand out, you have a choice:

| Strategy | Path | Difficulty |
| --- | --- | --- |
| **The "Mellanox" Way** | Build a killer RDMA engine and use **Native XDP** (on host) for flexibility. | **High** (RDMA is complex to build in HW). |
| **The "Netronome" Way** | Build an eBPF-to-Silicon compiler for true **XDP Offload**. | **Very High** (Compiler/JIT work is brutal). |
| **The "DPU" Way** | Put an ARM/RISC-V cluster on the NIC and run **Native XDP on the NIC's CPU**. | **Medium** (Standard SoC design). |

### Where you likely sit:

If you are developing for a card that uses the `mlx5` driver, you are likely working with a **ConnectX or
BlueField** architecture. 

In that world, the "offload" isn't usually the XDP code itself—it's the **flow rules** created *by* the code.
---

