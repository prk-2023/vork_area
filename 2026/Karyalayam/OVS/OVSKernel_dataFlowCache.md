# OVS Kernel datapath flow cache:


## Introduction:

**OVS uses kernel datapath flow control to avoid sending every pkt to the userspace `ovs-vswitchd` daemon**. 

The cache is a collection of **datapath flow entries** maintained by the OVS kernel datapath. Its a
**software network cache**, specifically an in-memory lookup table maintained inside the Kernel Memory.
This table caches **routing and switching decisions**. Or in Short it is a cache of **network forwarding
rules**.

This cache plays a critical role in OVS performance by preventing the system from having to send every
single packet up to the user-space daemon (`ovs-vswitchd`) for a routing decision.

i.e: The key extracts specific header fields from an incoming packet (such as src/dst MAC addrs, IP addrs, 
TCP/UDP ports, and VLAN tags).

- In older versions of OVS, this was a strict **Exact Match Cache** (EMC), meaning every single variation in
  a packet header required a unique entry. 

- Modern OVS uses a **Megaflow** cache, which allows wildcard matching  (using masks) to consolidate multiple
  similar packet flows into a single cache entry, drastically saving memory and lookup time.
1
Once a packet's key matches an entry in the kernel cache, kernel executes a pre-compiled list of actions
instantly without consulting the user-space, the common actions are:
    - `output`: forward the pkt to a specific physical or virtual port. 
    - `push_vlan`/`pop_vlan`: Modify VLAN tags. 
    - `set`: Rewrite pkt headers (ex: modifying MAC or IP addrs for NAT or routing )
    - `drop`: Discard pkt entirely. 

### Fast path Vs Slow Path Flow:
- **Fast Path ( Cache Hit )**:  A packet arrives → Kernel matches its Key in the datapath cache →  Kernel
  executes the Action list. This happens entirely in kernel space at near-line speed.

- **Slow Path ( Cache Miss )**: A packet arrives → No matching key is found → The kernel sends the packet up
  to user-space (ovs-vswitchd) via a netlink channel → User-space looks up the complex OpenFlow rules,
  generates a new datapath entry (Key + Action), inserts it into the kernel cache, and handles the packet.
  Subsequent matching packets will now hit the Fast Path.

### Hardware Offloading: 

Hardware Offloading is achieved by moving the SW cache and move it out of Linux kernel entirely and
pushing  it directly onto the NIC Hardware. 

In a standard OVS setup, even when a packet hits the kernel cache (the Fast Path), the CPU still has to spend 
cycles processing the packet, parsing headers, and executing the action list. When handling millions of
packets per second, this burns massive amounts of CPU power.

With hardware offloading (specifically using a framework like TC-Flower/ASAP² or DPDK with SmartNICs/ASICs):

1. **The First Packet (Slow Path)**: A new packet arrives. The hardware NIC doesn't know what to do with it,
   so it passes it up to the Linux Kernel, which passes it to the user-space daemon (`ovs-vswitchd`).

2. **The Rule Generation**: User-space determines the path and actions, just like before.

3. **The Offload**: Instead of only programming the rule into the Linux kernel datapath cache, **OVS uses a
   driver layer to translate that Key and Action list into a hardware-readable format**.

4. **The Hardware Programming**: The rule is written directly into the entry table of a SmartNIC or an ASIC
   chip on the network card (often using TCAM memory).

### The "Hardware Path" (The Ultimate Fast Path)

Once the rule is offloaded, subsequent packets in that flow follow the **Hardware Path**:

- A packet hits the physical port of the NIC.
- The NIC's onboard processor checks its hardware table (the offloaded Key).
- It finds a match and executes the action (the offloaded Action like modifying a VLAN tag or forwarding it
  directly to a virtual machine's virtual port).
- The CPU and the Linux Kernel never see the packet.

**Trade-offs**:

- **Performance**: Packets are processed at true line rate (e.g., 25Gbps, 100Gbps) with near-zero latency.
- **CPU Savings**: Your server's CPU utilization drops drastically because it no longer has to handle 
  network switching in software. You get those CPU cores back to run actual applications or VMs.

- **The Catch**: Hardware memory (TCAM) on network cards is much smaller and more expensive than system RAM.
  While the Linux kernel can hold millions of software cache entries, a hardware NIC might only be able to
  hold tens of thousands of offloaded rules.


## HW offloading :

For hardware offloading to work, there must be a tightly coupled three-way handshake between the 
**hardware capabilities**, the **kernel/driver translation layer**, and the **OVS software framework**.

### 1. The NIC HW & Driver Requirement:

- **The Hardware**: The NIC cannot just be a standard "dumb" network card. It must possess an onboard
  programmable pipeline (an ASIC, FPGA, or Network Processing Unit) and dedicated high-speed hardware memory
  (typically TCAM — Ternary Content-Addressable Memory) capable of storing and executing flow rules at line
  rate.

- **The Driver**: The vendor's proprietary kernel driver must implement the necessary APIs to talk to the
  Linux network subsystem. It is responsible for taking generic Linux commands and translating them into the
  exact register writes or binary instructions that its specific hardware ASIC understands.


### 2. The OVS Hook (The TC / Netlink Binding):

In the standard Linux architecture, OVS achieves this binding primarily through a **TC Flower**:

- **The Architecture**: Modern OVS doesn't actually talk directly to the NIC driver. Instead, `ovs-vswitchd`
  uses a standard Linux subsystem `tc` (specifically the `cls_flower` classifier) via Netlink messages.

- **The Hook**: When `ovs-vswitchd` determines a flow decision, it passes the Key and Action list down to
  the kernel using TC Flower, passing a special flag: `skip_sw` (skip software) or `in_hw` (if available, 
  put in hardware).

- **The Handshake**: The Linux kernel's TC layer catches this request and asks the NIC driver: "Hey, do you
  support offloading this specific rule?" If the driver says yes, it programs the NIC hardware.
 
### The Rule Translation Pipeline

Visually, the translation and binding flow looks like this:

```mermaid
graph LR
    A[OVS OpenFlow Rule] -->|ovs-vswitchd| B[TC Flower Netlink]
    B -->|Kernel API| C[NIC Driver Layer]
    C -->|Firmware| D[NIC Hardware TCAM]
```


If any single link in this chain fails—for instance, if the NIC driver doesn't support a specific action
(like an advanced encapsulation or NAT rewrite) the rule fallback mechanism triggers, and the rule is safely
handled back in the Linux kernel software datapath instead.


## How to enable HW Offloading and verify the Flow are Running on NIC HW.

Here is how you enable hardware offloading and verify that your flows are successfully running on the NIC
hardware.

1. Enabling Hardware Offloading

To turn on hardware offloading, modify the Open vSwitch global configuration database (`ovs-vswitchd` 
configuration) using the `ovs-vsctl` command.

```bash 
$ sudo ovs-vsctl set Open_vSwitch . other_config:hw-offload=true
```

- **Restart Required**: For the changed configuration to take effect, restart the OVS daemon. 


```bash
$ sudo systemctl restart openvswitch-switch
```

- Dependency: Make sure the NIC interfaces are configured to support hardware offloading features (like
  hw-tc-offload) via `ethtool` before enabling this in OVS:

```bash
$ sudo ethtool -K eth0 hw-tc-offload on
``` 

2. Verifying Hardware Flows Using ovs-appctl

To check if the flows are actually bypassed to the hardware, you dump the datapath flows using `ovs-appctl`.

Run the following command to view the active kernel datapath cache rules:
```bash
$ sudo ovs-appctl dpctl/dump-flows -m
```

( The -m or --more flag is crucial here because it instructs OVS to output extra metadata, including the
offload status ).

What to look for:

When looking at a specific flow line, look at the very end of the rule string for the offloaded status tag:
- **Successful Hardware Offload**: You will see `offloaded:yes` or `dp:tc` (indicating it went through the
  TC Flower hardware layer).

```text
recirc_id(0),in_port(2),eth(src=00:11:22:33:44:55,dst=66:77:88:99:aa:bb),eth_type(0x0800), packets:1042, bytes:15124, used:0.010s, actions:3, offloaded:yes
```

- Fallback to Software (Not Offloaded): You will see `offloaded:no` or `dp:ovs` (indicating it is still 
  being processed by the OVS kernel module software cache).

```text
recirc_id(0),in_port(2),eth(src=00:11:22:33:44:55,dst=66:77:88:99:aa:bb),eth_type(0x0800), packets:25, bytes:2100, used:0.420s, actions:3, offloaded:no
```

Alternatively, if you strictly want to count how many flows successfully made it to the hardware path versus
software, you can use:

```bash
$ sudo ovs-appctl dpctl/dump-flows -m | grep -c "offloaded:yes"
```

---

## what is required to support OVS HW offloading:


To support Open vSwitch (OVS) hardware offloading, the SmartNIC must support hardware pipeline and SW driver
that natively integrates Kernel TC Flower subsystem.

And for a SmartNIC development the architecture must build a hardware pipeline and a software driver
architecture that can integrate natively with the Linux kernel's TC (Traffic Control) Flower subsystem.

From a silicon and firmware architecture perspective, developing a SmartNIC to support this feature requires
several key components:

1. Hardware Architecture Requirements
---

SmartNIC ASIC or FPGA must be designed to parse packets and execute forwarding logic entirely on-card.
- **Programmable Parser & Pipeline**: The hardware must feature a parser capable of decoding headers (L2,L3,
  L4, and tunnel encapsulations like VXLAN, Geneve, or NVGRE) at line rate (e.g., 100Gbps+) within the
  network processing unit (NPU).

- **TCAM / Memory Tables**: hardware memory (typically TCAM for masked/wildcard matches like Megaflows, and
  SRAM for exact matches) to store the offloaded rule keys, masks, and associated action IDs.

- **Action Engine**: The silicon must contain hardware logic blocks to execute OVS actions autonomously
  without host CPU interaction. This includes modifying headers (NAT/routing), pushing/popping VLAN or MPLS
  tags, duplicating packets (mirroring), and updating packet/byte counters.

2. Software Driver Layer (The Linux Upstream Model)
--- 

OVS relies on standard Linux kernel frameworks to push rules to hardware. The software team must implement 
specific hooks inside your proprietary Linux network driver (ndev). 
The standard architecture uses TC Flower Offload:

```text 
[ ovs-vswitchd ]
       │  (Netlink Messages)
       ▼
[ Linux Kernel TC Layer ]
       │  (NDO Ops: ndo_setup_tc)
       ▼
[ Your SmartNIC Driver ]  <-- Your team develops this
       │  (Translates flower match/actions to HW registers)
       ▼
[ SmartNIC Firmware / HW ]
```

To integrate with this pipeline, SmartNIC Linux driver must implement the following:

- **The NDO Hook (`ndo_setup_tc`)**: Driver must register the Network Device Operation (`ndo`) function
called `ndo_setup_tc`. When OVS injects a rule via Netlink into `TC`, the kernel calls your driver's hook:

```c
static const struct net_device_ops your_nic_netdev_ops = {
    .ndo_setup_tc = your_nic_setup_tc,
    // ... other standard network ops
};
```

- B. Flow Classifier Parsing (TC_SETUP_CLSFLOWER)

Inside the `ndo_setup_tc` implementation, driver must handle the `TC_SETUP_CLSFLOWER` call. 

This code parses the generic Linux structure (`flow_cls_offload`) into your hardware's native format:

- **Extract the Key and Mask**: Read the packet fields OVS wants to match against (ex:source IP, dest port)
   and their corresponding wildcards.

- **Extract the Actions**: Loop through the action chain (ex: `FLOW_ACTION_REDIRECT`,
   `FLOW_ACTION_VLAN_PUSH`, `FLOW_ACTION_MANGLE` for header rewrites).

- **Program the Hardware**: Write these values into the SmartNIC’s onboarding tables using internal
   firmware commands or ring buffers.

- Continuous Statistics Feedback:

OVS needs to know if hardware rules are actively hitting so it can handle aging and flow deletion. The
driver must query the SmartNIC hardware counters and report packet/byte increments back to the kernel when
requested by a TC stats query.

3. Alternative Path: The DPDK Model (RTE Flow)
--- 

If SmartNIC targets high-performance user-space networking rather than the standard Linux kernel datapath, 
you must write a DPDK Poll Mode Driver (PMD).

- Instead of TC Flower, your driver must implement the rte_flow API standard.

- OVS-DPDK will call `rte_flow_create()` directly to pass the flow attributes, patterns (matching keys), and
  actions to your user-space PMD, which then directly programs your SmartNIC hardware via PCIe bars.


4. New path AF_XDP :

`AF_XDP`, is a highly disruptive paradigm shift in how high-performance networking and SmartNIC development 
are approached in modern Linux systems.

`AF_XDP` fundamentally redefines the relationship between OVS and a SmartNIC.

- Where AF_XDP Fits in the Architecture: ( data path spectrum )
    - **Standard OVS**: Kernel-space path (`Skb` buffer overhead, context switching).
    - **OVS-DPDK**: Pure user-space path (Completely bypasses the kernel, requires dedicated CPU cores
      polling the NIC via proprietary PMD drivers).
    - **OVS with `AF_XDP`**: Its the Best of Both Worlds. It allows `OVS` user-space (`ovs-vswitchd`) to
      read and write packet buffers directly out of the NIC’s DMA rings into user-space memory (`UMEM`) via
      zero-copy, without giving up the Linux kernel control plane, standard `netdev` drivers, or security
      policies

- How Hardware Offloading Works in the `AF_XDP` Path

When integrate OVS with AF_XDP: packet processing is driven by eBPF programs loaded onto NIC interface. For
a SmartNIC, hardware offloading in this realm is achieved through eBPF Hardware Offloading.

Instead of translating TC Flower rules into hardware configurations, SmartNIC driver must support native XDP support

```text 
[ eBPF C Code ] ──(Clang/LLVM)──> [ eBPF Bytecode ]
                                         │
                                   [ OVS Layer ]
                                         │
                                 (Netlink / libbpf)
                                         │
                                         ▼
                             [ Linux Kernel XDP Layer ]
                                         │
                                  (ndo_bpf Hook)
                                         │
                                         ▼
                             [ Your SmartNIC Driver ]
                                         │
                                         ▼
                             [ SmartNIC JIT / ASIC ]
``` 

- The JIT Compiler in Silicon/Firmware: SmartNIC hardware (or its management processor/firmware) must
  include an eBPF Just-In-Time (JIT) translator. It takes generic eBPF bytecode sent down by the host kernel
  and translates it directly into your SmartNIC’s native machine instructions.

- The Fast/Redirect Path: The offloaded eBPF code runs on the NIC the microsecond a packet hits the physical
  port. If the eBPF program returns XDP_REDIRECT toward an AF_XDP socket (XSK), the SmartNIC DMA engine
  directly drops that packet into the OVS user-space ring buffer (UMEM).

**SmartNIC to support AF_XDP**

To support the `OVS` `AF_XDP` path seamlessly, hardware and software must meet these explicit requirements:

A. Driver Support for Zero-Copy (XDP_REDIRECT)

To get competitive performance, your driver must implement the zero-copy mode of AF_XDP. This means your
Linux network driver needs to support rewriting its RX/TX ring descriptors on the fly to point to the host
memory pages allocated by OVS (UMEM), bypassing standard kernel sk_buff allocation.

B. The Driver Hook (ndo_bpf)

Just like TC Flower uses `ndo_setup_tc`, eBPF/XDP hardware offloading uses a network device operation hook 
called `ndo_bpf`.

Linux driver must implement this to intercept the eBPF program loading requests from libbpf:
```c
static const struct net_device_ops your_nic_netdev_ops = {
    .ndo_bpf = your_nic_ndo_bpf, // Intercepts XDP program loads
};
```

Inside this function, driver verifies the eBPF instructions, ensures hardware instruction set can execute
them, and passes the bytecode down to the card's processing unit.

C. SmartNIC Memory Architecture

Hardware must be capable of processing highly flexible, programmatic instruction execution (eBPF loops,
helper functions, maps) rather than just static match/action tables (TCAM). This is why `AF_XDP` hardware
offloading is almost exclusively found on FPGA-based SmartNICs or NPU-based SmartNICs (like AMD/Pensando,
NVIDIA BlueField, or Intel IPU) rather than pure basic switching ASICs.

TC Flower vs. AF_XDP Offload for SmartNIC Development
|Requirement | TC Flower Offload | AF_XDP / eBPF Offload |
| :--- | :--- | :--- |
| Hardware Core	| Match/Action Engine (TCAM/SRAM) | Programmable Core (NPU, FPGA, RISC-V) |
| Driver Interface | `ndo_setup_tc` | `ndo_bpf` |
| What is Transformed | Network header fields & explicit action lists | Compiled eBPF Execution Bytecode |
| Flexibility | Rigid (Limited to actions the ASIC physically supports) | Extremely High (Can execute custom C-like logic on the NIC) |


Summary:

1. Silicon/FPGA: Line-rate parser, TCAM for megaflow masks, and an action engine for rewriting headers.
2. Firmware: Control plane APIs to dynamically update hardware tables from the host OS.
3. Linux Kernel Driver: Strict adherence to upstream cls_flower offloading using ndo_setup_tc.
4. Validation: Testing infrastructure to verify ethtool -K <interface> hw-tc-offload on properly passes
   OVS-generated rules without falling back to the software datapath.
5. For modern SmartNIC, supporting `AF_XDP` with zero-copy in your driver is considered standard
   best-practice today. However, offloading the actual eBPF execution code onto the NIC hardware is a
   massive engineering undertaking that requires a highly capable programmable pipeline.

---

# ENGINEERING SPECIFICATION

## Project: High-Performance SmartNIC Data Plane Offloading

**Target Use Case:** Open vSwitch (OVS) Acceleration & AF_XDP Engine Support
**Document Classification:** 

Internal R&D Specification 

## 1. Introduction & Architecture Overview

This specification defines the hardware, firmware, and software driver requirements for the development of our next-generation SmartNIC. The primary objective is to offload network packet processing from the host CPU to the SmartNIC silicon, accelerating Open vSwitch (OVS) deployments via two separate, high-performance data paths: 

1. **The Kernel Control Path:** Accelerated using Linux Traffic Control (TC) Flower.
2. **The Programmable Zero-Copy Path:** Accelerated using Express Data Path (XDP) and AF_XDP sockets.

       [ OVS User-Space / ovs-vswitchd ]
         │                           │
         │ (Netlink TC Flower)       │ (AF_XDP UMEM Ring)
         ▼                           ▼
   [ Linux Kernel TC ]         [ AF_XDP Socket (XSK) ]
         │ (ndo_setup_tc)            │ (ndo_bpf / Zero-Copy DMA)
         └─────────────┬─────────────┘
                       ▼
            [ SmartNIC Linux Driver ]
                       │
                       ▼
            [ SmartNIC Firmware / PCIe ]
                       │
                       ▼
         [ SmartNIC Processing Core / ASIC ]

#### 2. Linux Kernel Control Path Offloading (TC Flower)

To integrate natively with standard Linux distributions running OVS, the SmartNIC must support upstream kernel hardware offloading utilizing the cls_flower classifier. 

#### 2.1 Hardware Parsing & Pipeline Requirements

* **Line-Rate Parser:** The Network Processing Unit (NPU) or ASIC pipeline must parse incoming packet headers up to layer 4 (L2/L3/L4) at true physical line rate (e.g., 25/50/100 Gbps).
* **Tunnel De-encapsulation:** The parser must natively support the encapsulation and de-encapsulation of overlay tunneling protocols, specifically **VXLAN**, **Geneve**, and **NVGRE**.
* **Memory Architecture (TCAM/SRAM):** 

  * **TCAM (Ternary Content-Addressable Memory):** Dedicated to wildcard/masked rule lookups (emulating OVS Megaflows).
  * **SRAM (Static RAM):** Dedicated to exact-match rule lookups (emulating OVS Exact Match Cache).

#### 2.2 Host Driver Requirements (ndo_setup_tc)

The SmartNIC Linux network device driver must implement the core kernel network device operation hooks: 

* **Interface Binding:** The driver must expose the .ndo_setup_tc operation inside its net_device_ops structure.
* **Classifier Handling:** The driver must intercept the TC_SETUP_CLSFLOWER call from the kernel and unpack the flow_cls_offload structure.
* **Rule Translation:** The driver must convert generic flow_cls_offload match keys, masks, and action vectors into hardware-specific register writes or firmware commands.
* **Fallback Protocol:** If the driver encounters an action or protocol mask not natively supported by the hardware, it must gracefully reject the offload request, forcing the kernel to handle the flow in software via the fallback path (offloaded:no).

#### 2.3 Required Actions in Hardware

The on-card Action Engine must execute the following operations directly in silicon: 

* **Drop:** Instantly discard matching packets.
* **Redirect / Output:** Forward the packet to a designated physical port, virtual function (VF), or sub-interface.
* **VLAN Manipulation:** Support push_vlan and pop_vlan operations.
* **Header Modification (Mangle):** Rewrite L3/L4 header fields to support stateless Network Address Translation (NAT) and routing rewrites.

#### 3. High-Performance Programmable Path (AF_XDP & eBPF)

To address cloud-native and highly flexible environments, the SmartNIC must support zero-copy data transfer to user-space applications via AF_XDP. 

#### 3.1 Zero-Copy DMA Driver Requirements

* **UMEM Ring Mapping:** The SmartNIC driver must implement AF_XDP zero-copy mode. It must dynamically remap its RX and TX ring buffers to point directly to the host-allocated user-space memory blocks (UMEM).
* **SKB Bypass:** Packets destined for an active AF_XDP socket (XSK) must be pushed via Direct Memory Access (DMA) into host RAM without creating standard kernel sk_buff allocations or triggering host network stack context switches.

#### 3.2 eBPF Hardware Offloading (ndo_bpf)

* **Driver Hook:** The driver must implement the .ndo_bpf function pointer inside net_device_ops to capture XDP_SETUP_PROG requests from libbpf.
* **On-Card Execution Engine:** The SmartNIC firmware or programmable processing cores (e.g., RISC-V, ARM, or FPGA fabrics) must feature a Just-In-Time (JIT) compiler or interpreter capable of executing eBPF bytecode.
* **Program Translation:** The driver must verify the loaded eBPF instructions, ensure they adhere to hardware constraints (e.g., instruction limit, loop restrictions), and flash the resulting binary array to the hardware execution pipeline.
* **XDP Action Support:** The hardware execution engine must natively return and handle the following actions: 

  * XDP_DROP (Silicon drop)
  * XDP_TX (Bounce back out the same port)
  * XDP_REDIRECT (Direct DMA transfer to an AF_XDP socket memory space)

#### 4. Hardware–Software Co-Design Architecture

SmartNIC efficiency relies on balancing host CPU performance against the physical resource constraints of the network card. 

#### 4.1 Memory Allocation & Table Management

* **TCAM Scarcity Mitigation:** Hardware TCAM is constrained. The SmartNIC software agent must dynamically prioritize heavy or long-lived flows for full hardware offloading. Short-lived or ephemeral flows (e.g., DNS queries) should remain in the host kernel's OVS software cache.
* **Eviction Policies:** The SmartNIC driver must continuous track hardware flow aging. If a rule has not registered packet hits within a configurable timeout window, the hardware entry must be purged, and the allocation must be returned to the free table pool.

#### 4.2 Telemetry and Counters Sync

* **Hardware Counters:** For every offloaded flow entry (TC Flower or eBPF Map), the hardware must maintain dedicated 64-bit packet and byte counters.
* **Asynchronous Polling:** The host driver must implement a lockless, asynchronous DMA polling routine to pull statistics from the card at deterministic intervals (e.g., every 100ms) to satisfy OVS stats tracking requests without blocking the control plane.

#### 4.3 Control Plane Isolation

* **Asymmetric Processing:** The SmartNIC's internal CPU/management cores must manage rule compilation, table insertion, and telemetry reporting asynchronously. The high-speed network ASIC pipeline must run independently of these management tasks to guarantee zero packet jitter during rule-update storms.

#### 5. Verification, Debugging, and Compliance

* **Feature Flags:** The driver must expose offload capabilities through standard ethtool features. Users must be able to toggle functionality via:
ethtool -K <interface> hw-tc-offload on/off
* **Visibility Matrix:** The driver must append hardware-specific telemetry markers so that debugging utilities like ovs-appctl dpctl/dump-flows -m correctly append the string offloaded:yes along with the appropriate datapath tag (dp:tc).
* **Hardware Error Reporting:** The driver must implement robust error logging via dmesg. If a hardware resource limit is reached (e.g., TCAM overflow), the driver must throw an explicit kernel log indicating table exhaustion to allow upper-layer orchestration software to adjust traffic routing policies.
