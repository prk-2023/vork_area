# Network Flows and OVS

This is a very interesting topic, particularly when working with Open vSwitch (OVS), Linux networking, and
hardware offloading.

A **Flow** is a sequence of related network packets that share common characteristics ( like SRC/DST IP Addr's,
ports, or protocol type), treated as a single traffic session rather than isolated packets. 

( 
    Instead of looking at every single TCP pkt as a brand new event an entire web browsing session or a 
    video stream can be identified as a single **flow** 
)

A **Flow Table** is a data structure inside a programmable network switch ( commonly used in SDN ) that
stores a set of **flow entries** to decide how to process and forward those packets. 

Flow tables replaces or extends traditional static switching/routing tables with programmable database
rules. When a pkt arrives at a switch, the switch inspects the pkt against the flow table. 

Each **Flow entry** inside a flow table typically contains:

- **Match Field**: Criteria to identify specific packets ( ex: Specific destination IP and TCP port)

- **Priority**: Determines the order of evaluation if a packet matches multiple rules.

- **Counters**: Track statistics like the total number of matching packets and bytes.

- **Instructions** / **Actions**: What to do with the matching packet (ex: forward out a specific port,
  drop the packet, modify VLAN/IP headers, or send the packet to an SDN controller).

- **Timeouts**: Idle or hard timers that remove old or unused flow entries automatically

**How does all this work:**

- **Packet arrival**: A pkt enters an **openFlow** enabled switch.
- **Table lookup**: switch compares the packet against the **flow table**.
- **Action execution**: If a match is found, the switch performs the defined action ( such as forwarding or
  altering the packet), for more advanced switched, pkts can pass through a **pipeline** of multiple
  sequential flow tables using `Goto-Table` instructions.
- **Table-Miss**:  If no rule matches the packet, a fallback rule (the table-miss entry) dictates whether to
  drop the packet, flood it, or forward it up to a centralized software controller for instructions

## OVS: Open vSwitch (OVS) 

It is the most prominent production-grade virtual switch that implements this flow-based architecture in
Linux.  

In OVS, instead of treating packet forwarding like a traditional hardware bridge (which relies strictly on
learning MAC addresses), everything is treated as a programmable flow.

Here is how OVS uses and optimizes flows to keep up with intense Linux virtualization traffic:

### How OVS Implements Flows

OVS operates in both **user space** (where complex decisions and SDN protocol handling happen) and **kernel
space** (where packets are forwarded at blazing fast speeds). To achieve high performance, OVS splits its
flow processing into two distinct parts:

**1. OpenFlow Flow Tables (user-space: _ovs-vswitchd_ )**

- This is where your actual SDN controller (like OpenDaylight or ONOS) or manual configuration scripts inject routing logic.

- It supports multiple pipeline tables, wildcard matching, priorities, and intricate routing logic.

- Because matching packets against deep, complex rules takes time, running every single packet through these user-space tables would severely bottleneck network performance.

**2. The Datapath (Kernel Space / openvswitch.ko)**

- To solve the speed issue, OVS utilizes a kernel-space cache called the Datapath.

- When a packet first arrives, if the kernel datapath doesn't recognize it, it sends it up to the user space ("upcall").

- The user-space daemon checks its multi-table OpenFlow rules, decides what to do, and then installs an incredibly simple, exact-match rule directly into the kernel datapath.

- Subsequent packets in that exact same stream match the kernel cache immediately and never leave the kernel space, resulting in near-line-rate forwarding speeds.

### The Evolution of OVS Flow Tables

As networks grew larger, exact-match caching wasn't enough because any slight variation in a packet (like a
changing port number) triggered a slow user-space upcall. OVS engineered two primary technologies to make
flow tables even smarter:

| Flow Technology | How it Works | Primary Benefit |
| :--- | :--- | :--- |
| Microflow Caching	| Matches packets on an exact 1:1 basis across all header fields. | Super fast, but handles wildcards poorly; easily flooded by new connections. |
| Megaflow Caching | Group-based classifier that allows wildcarding in the kernel datapath (e.g., matching a whole subnet instead of one IP). | Drastically reduces upcalls to user space for varied traffic.|


---

The first thing to understand is that a Flow is essentially a set of rules that tells a switch what to do
with a packet based on its characteristics.

## 1. What is a Flow?

Imagine an Ethernet switch receiving a packet.

Normally, a traditional switch looks at the destination MAC address and decides which port should receive
the packet.

OVS is more sophisticated. It can inspect multiple packet fields and make forwarding decisions based on them.

For example, a flow might say:

```text 
Match:
    Source MAC       = AA:BB:CC:DD:EE:FF
    Destination MAC  = 11:22:33:44:55:66
    VLAN ID          = 100
    Source IP        = 192.168.1.10
    Destination IP   = 192.168.2.20
    Protocol         = TCP
    Destination Port = 443

Action:
    Output to port 5
```

This combination of:

- Match criteria
- Actions

is called a **Flow**.

In OVS, flows are stored in flow tables and evaluated against incoming packets.

## 2. How OVS processes packets

Let's look at the general architecture.

Discover Open vSwitch (OVS): What Is It and How Does It Work?

[open vSwitch Arch](https://cloudification.io/cloud-blog/open-vswitch-ovs-what-is-it-and-how-does-open-virtual-switch-work)

![](https://cloudification.io/wp-content/uploads/2025/02/Open_vSwitch_Architecture.webp =360x)


**OVS** has two important components:

1. **Control plane**: `ovs-vswitchd` (userspace daemon).
2. **Data plane**: Kernel datapath or a userspace datapath such as DPDK.

Consider what happens when a packet arrives.

**Packet processing in OVS**

```text 
           Incoming Packet ( physical NIC / Virtual NIC )
                 |
                 v
        +-------------------+
        | Datapath Flow     |( Is there an existing matching flow? )
        | Lookup            | 
        +-------------------+
                 |
         +-------+-------+
         |               |
        HIT             MISS
         |               |
         v               v
  +-------------+  +---------------------------+
  | Execute     |  | Upcall to                 |
  | Flow Actions|  | ovs-vswitchd              |
  | (fast path )|  |ovs-vswitchd processes pkt |
  +-------------+  +---------------------------+
         |               |
         |               v
         |        +-----------------+
         |        | Flow Processing | ( Subsequent matching packets can use the fast path )
         |        | and Installation|
         |        +-----------------+
         |               |
         +-------+-------+
                 |
                 v
          Packet Forwarding
```

This brings us to the different types of flows.

## 3. SW Flows (Software Flows)

These flows are processed by software rather than directly by NIC hardware.

For example, with the Linux kernel datapath:

- Packet arrives at the NIC.
- Linux receives the packet.
- OVS kernel datapath looks up a matching flow.
- If a matching flow exists, its actions are executed.
- The packet is forwarded without requiring userspace processing for every packet.

The important distinction:

**A software flow does not necessarily mean that every packet is processed by the OVS userspace daemon.**

The Linux kernel can process packets very efficiently using its datapath flow cache.

You can inspect software datapath flows using:

```bash
sudo ovs-appctl dpctl/dump-flows
```

Example output:

```text
recirc_id(0),in_port(1),eth_type(0x0800),
ipv4(src=192.168.1.10,dst=192.168.2.20),
tcp(dst=443), packets:100, bytes:12000,
used:0.5s, actions:output(2)
```

This is a software datapath flow.

## 4. HW Flows (Hardware Offloaded Flows)

Modern NICs have hardware packet-processing capabilities.

Instead of asking the CPU to process every packet, OVS can offload flow rules into the NIC.

For example:

```text
Match:
    Source IP      = 192.168.1.10
    Destination IP = 192.168.2.20
    Protocol       = TCP
    Destination Port = 443

Action:
    Forward to physical port
```

OVS communicates this rule to the NIC driver, which programs the NIC's hardware flow tables.

Now the NIC itself can:

1. Receive the packet.
2. Match its headers against the hardware flow rule.
3. Execute the configured forwarding action.
4. Forward the packet without normal host CPU packet processing.

Link-Inline™ Software - Napatech

[stateful flow mgmt and offloading napatech.com](https://www.napatech.com/products/link-inline-software)

![napatech.com](https://www.napatech.com/wp-content/uploads/2026/10/Stateful-Flow-Management-Diagram-768x741.png =240x)

This is called Hardware Flow Offloading.

Some examples of hardware technologies involved:

- Intel Ethernet Flow Director
- Intel ADQ (Application Device Queues)
- Mellanox/NVIDIA ConnectX hardware steering
- TC flower hardware offload
- NIC embedded switching (eSwitch)

Not every NIC supports all flow matching and action combinations.

```bash 
# Look for `harware-tc-offload` to check if the driver supports HW flow offloading.
ethtool -k <interface_name> | grep "hw-tc-offload"

# or for connectx NICs ( make sure the driver exposes representor device and supports `switchdev` mode
# rather than `legacy` mode)
# `devlink dev eswitch show pci/<bus_address>`

# or check OVS kernel and Flow offload status ( return true )
sudo ovs-vsctl get Open_vSwitch . other_config:hw-offload
```

## 5. SW Flow vs HW Flow

| Feature | SW Flow | HW Flow |
| --- | --- | --- |
| Processing | CPU / software datapath | NIC hardware |
| Flow storage | Kernel or userspace datapath | NIC hardware tables |
| CPU utilization | Uses host CPU | Reduces host CPU usage |
| Throughput | Depends on CPU and datapath | Can achieve high throughput |
| Latency | Depends on software path | Can reduce processing latency |
| Limitations | Software-supported actions | Hardware-supported match/actions |
| Capacity | System memory / datapath limits | NIC hardware flow-table limits |

One important detail: hardware offloading is not simply a matter of copying every OVS flow into the NIC. 
The NIC must support the required match fields and actions.

## 6. How to inspect SW and HW flows in Linux

This is where the practical OVS commands become useful.

A. Check the OVS datapath type

```bash
ovs-vsctl get Bridge br0 datapath_type
```

Typical results:

- Empty string: Linux kernel datapath.
- `netdev`: Userspace datapath (often DPDK).

B. Dump datapath flows

```bash
sudo ovs-appctl dpctl/dump-flows
```

C. Check hardware offloading configuration

```bash
ovs-vsctl get Open_vSwitch . other_config
```

Look for:

```text
hw-offload=true
```

You can also check:

```bash
ovs-vsctl get Open_vSwitch . other_config:hw-offload
```

D. Inspect TC hardware-offloaded rules

```bash
sudo tc -s filter show dev eth0 ingress
```

Look for:


```text
in_hw
```

This indicates that a rule has been installed in hardware.

You may also see:


```text 
not_in_hw
```

This means the rule is not currently offloaded.

## 7. One more important distinction: OpenFlow vs Datapath Flows

These two terms are often confused.

OVS actually has two different flow concepts:

| OpenFlow flows | Datapath flows |
| --- | --- |
| Managed by OVS control plane | Used by packet-processing datapath |
| Configured using `ovs-ofctl` | Inspected using `ovs-appctl dpctl` |
| Logical switching rules | Optimized packet-processing rules |
| Can contain multiple tables and complex logic | Usually represent specific packet-processing paths |

For example:

An OpenFlow rule might say:

```bash
ovs-ofctl add-flow br0 \
"priority=100,in_port=1,ip,actions=output:2"
```

OVS translates the logical processing decision into datapath operations.

The datapath may then install a more specific flow to accelerate subsequent packets.

## 8. The bigger picture

There are actually three levels worth understanding:

```text 

    +--------------------------------------------------------------+
    | Level 1                                                      |
    | **OpenFlow**                                                 |
    | Logical forwarding policy. What should happen to packets?    |
    +--------------------------------------------------------------+
    | Level 2                                                      |
    | **Software Datapath Flows**                                  |
    | Kernel or userspace implementation of forwarding decisions.  |
    +--------------------------------------------------------------+
    | Level 3                                                      |
    | Hardware Offloaded Flows                                     |
    | NIC implements supported forwarding decisions directly in hw.|
    +--------------------------------------------------------------+

```

---

# Understanding Flow, SW Flow, HW Flow, and what OVS does

The easiest way to understand OVS hardware offloading is to start with one concept:

A flow is a group of packets that share the same identifying characteristics and should receive the same packet-processing treatment.

Think of a flow as a rule for handling a particular type of network traffic.

For example, imagine a server receiving traffic from a client:

- Source IP: `192.168.1.10`
- Destination IP: `10.0.0.20`
- Source TCP port: `50000`
- Destination TCP port: `443`
- Protocol: TCP

These fields identify a particular traffic flow.

OVS can recognize this flow and decide what to do with its packets, such as forwarding them to another port, dropping them, or modifying their headers.

Let's connect this concept to software flow and hardware flow.

## 1. What exactly is a flow?

Consider this network traffic:

+----------------------------------------------|+
| Example: Three TCP connections                |
|                                               |
| Connection A:                        Flow A   |
| 192.168.1.10:50000 → 10.0.0.20:443            |
+---------------------------------------------- +
| Connection B                         Flow B   |
| 192.168.1.11:50001 → 10.0.0.20:443            |
+---------------------------------------------- +
| Connection C                         Flow C   |
| 192.168.1.10:50002 → 10.0.0.30:80             |
+---------------------------------------------- |+

Although all three connections use TCP, they have different identifying fields.

A flow is typically identified by a combination of packet-header fields, commonly called a 5-tuple:

| Field | Example |
| --- | --- |
| Source IP | 192.168.1.10 |
| Destination IP | 10.0.0.20 |
| Source port | 50000 |
| Destination port | 443 |
| Protocol | TCP |

This combination identifies Flow A.

However, a flow does not always have to use all five fields. Depending on the flow definition, it might match only:

- Source and destination MAC addresses.
- Source and destination IP addresses.
- VLAN ID.
- IP protocol.
- TCP/UDP ports.
- Tunnel ID or other metadata.

Important: A flow is not necessarily the same as a TCP connection. It is a packet-classification concept. Its exact definition depends on the networking system.

## 2. What does OVS do with a flow?

OVS is essentially a programmable virtual switch.

Its job is to:

1. Receive packets.
2. Identify which flow the packets belong to.
3. Determine the actions associated with that flow.
4. Forward, modify, or drop the packets.

For example, suppose OVS receives the following packet:
```text 
Incoming packet
+------------------------------+
Packet headers
Src IP: 192.168.1.10
Dst IP: 10.0.0.20
+------------------------------+
TCP dst port: 443
OVS flow lookup
Find a matching flow rule
+------------------------------+
Matched action
**# Output: Port 2**
Fwd pkt to the destination port
+------------------------------+
```
An example OVS flow rule might look like this:

```bash
ovs-ofctl add-flow br0 \
"priority=100,ip,nw_dst=10.0.0.20,tp_dst=443,actions=output:2"
```

This means:

- Match IP packets.
- Match destination IP `10.0.0.20`.
- Match destination TCP/UDP port 443 (with protocol-specific interpretation).
- Forward matching packets to port 2.

The flow rule contains two important parts:

- Match: Which packets belong to this flow?
- Action: What should happen to those packets?

This match/action model is the foundation of OVS forwarding.

## 3. What is a software flow (SW flow)?

A software flow is a flow rule that is processed by the CPU rather than directly by the NIC's hardware forwarding engine.

For OVS, there are two important software components:

- OpenFlow rules: The logical forwarding policy configured by the controller or administrator.
- Datapath flows: Optimized forwarding entries installed in the OVS kernel or userspace datapath to process packets efficiently.

These are related, but they are not exactly the same thing.

### Example: OVS software flow processing

Imagine that the first packet of Flow A arrives at OVS.

```text
+-----------------------------------------------------+
Incoming packet
+-----------------------------------------------------+
OVS datapath lookup
Does a matching datapath flow exist?
+----------------------+     +----------------------------------+
Cache hit                    Cache miss
SW flow found                Upcall to ovs-vswitchd
=>Execute cached actions     =>Process through OpenFlow pipeline
+----------------------+     +----------------------------------+
+---------------------------------------------------------------+
Install datapath flow
Subsequent packets can use the cached rule
+---------------------------------------------------------------+
```

The important mechanism is:

1. The first packet might not have a matching datapath flow.
2. OVS sends an upcall to `ovs-vswitchd`.
3. `ovs-vswitchd` processes the packet through its OpenFlow pipeline.
4. OVS determines the forwarding actions.
5. A datapath flow is installed.
6. Subsequent matching packets can be processed directly by the datapath without repeating the full OpenFlow pipeline.

This is why OVS can process packets efficiently even when forwarding is performed entirely in software.

For example, in kernel datapath mode, the kernel module `openvswitch.ko` performs packet processing using its datapath flow table.

In DPDK mode, OVS performs packet processing in userspace using PMD threads.

## 4. What is a hardware flow (HW flow)?

A hardware flow is a flow rule installed directly into the NIC's hardware flow table.

Instead of asking the CPU to look up every packet and execute forwarding actions, the NIC performs these operations itself.

For example, imagine your NIC supports an embedded switch (eSwitch).

OVS can program a hardware rule:

```text
Match:
    Source IP      = 192.168.1.10
    Destination IP = 10.0.0.20
    Protocol       = TCP
    Destination port = 443

Action:
    Forward to representor port 2
```

The NIC stores this rule in its hardware flow table.

DOCA Switching - NVIDIA Docs

[docs.nvidia.com](https://docs.nvidia.com/doca/archive/3-2-2/doca-switching/index.html)
![CX Switchdev mode](https://networking-docs.nvidia.com/doca/__attachments/a_2835fb4c37583a1f8ad5c8cb4a38d215783c206c4bcd591e620a626e9828f592/Kernel_Representors_Model_Host.png =360x)

Now, when another packet arrives with matching fields:

1. The NIC examines the packet headers.
2. It searches its hardware flow table.
3. It finds the matching rule.
4. It executes the forwarding action.
5. The packet is forwarded without requiring the host CPU to perform the normal software datapath lookup.

Hardware forwarding The NIC handles the packet processing itself.

The benefit is that the CPU does not need to process every packet.

This can significantly reduce CPU utilization and improve forwarding throughput.

## 5. How SW flow and HW flow relate to each other in OVS

This is the most important part to understand.

OVS can maintain software datapath flows while also programming corresponding hardware flows.

Think of it this way:

- SW flow = forwarding rule implemented in software.
- HW flow = forwarding rule implemented in NIC hardware.
- OVS = control and management logic that determines forwarding behavior and coordinates the datapath and offloading.

## OVS hardware offloading architecture

```text 

+-----------------------------------------------------+
OpenFlow control plane
Defines forwarding policy
+-----------------------------------------------------+
ovs-vswitchd
Translates policy into datapath flows
+-----------------------------------------------------+
Datapath flow
+------------------+      +---------------------------+
   SW flow                   HW flow
   CPU datapath              NIC hardware
+-----------------------------------------------------+
    Packet forwarding
In a typical OVS hardware-offload implementation:
+-----------------------------------------------------+
```

1. OVS creates a datapath flow.
2. The hardware-offload provider attempts to translate the flow into hardware rules.
3. The NIC driver programs the NIC hardware.
4. If successful, matching traffic can be processed by the hardware.
5. If hardware offloading is unavailable or unsupported, the software datapath continues to handle the traffic.

One subtle but important point: a successful hardware offload does not necessarily mean the software flow disappears. OVS can retain software-side flow state for management, statistics, and synchronization.

## 6. A concrete example: What happens to 1,000,000 packets?

Suppose a client sends 1 million packets belonging to the same flow.

```text 

Without hardware offloading:

+---------------------------------------------------+
Software forwardingNIC receives packets
+---------------------------------------------------+
Host CPU processes packets
Datapath lookup + forwarding actions
+---------------------------------------------------+
NIC transmits packets
The CPU participates in processing the packet stream.
+---------------------------------------------------+
```

```text 
With hardware offloading:

Hardware forwarding
+---------------------------------------------------+
NIC receives packets
+---------------------------------------------------+
NIC hardware flow lookup
Match the installed HW flow rule
+---------------------------------------------------+
NIC executes forwarding action
NIC transmits packets
+---------------------------------------------------+
The CPU does not need to process every packet individually.
```

OVS still manages the rules, but the NIC handles the packet forwarding.

This is the fundamental idea behind hardware offloading.

## 7. Summary: Understand these four terms

| Term | Meaning | Where it happens |
| --- | --- | --- |
| Flow | A classification of packets with matching characteristics | Concept |
| OpenFlow rule | Logical match/action forwarding policy | OVS control plane |
| SW flow | Optimized forwarding entry executed by software datapath | CPU |
| HW flow | Forwarding entry executed by NIC hardware | NIC |

The relationship can be remembered as:

## The complete picture
```text 
    +--------------------------------------------+
    OpenFlow rule
    What should happen to the packets?
    +--------------------------------------------+
    OVS translates the policy
    +--------------------+ +---------------------+
    SW flow                 HW flow 
    CPU executes the rule   NIC executes the rules 
    +--------------------------------------------+
    Both implement forwarding behavior defined by 
    the OVS policy, subject to supported actions and 
    offload configuration.
```

## 8. How to see this in a real OVS system

If you have an OVS machine, these commands are useful:

1. View OpenFlow rules

```bash
ovs-ofctl dump-flows br0
```

Shows the logical forwarding rules configured in OVS.

2. View software datapath flows

```bash
ovs-appctl dpctl/dump-flows
```

Shows datapath flow entries maintained by OVS.

3. Check hardware offloading configuration

```bash
ovs-vsctl get Open_vSwitch . other_config
```

Look for:

```text 
hw-offload=true
```

4. Inspect TC hardware flow rules

```bash
tc -s filter show dev eth0 ingress
```

On a supported TC/switchdev offload setup, this can show hardware-offloaded rules and their statistics.

My suggestion: The next concept worth understanding is the relationship between an OVS datapath flow, `tc flower`, `rte_flow`, and the NIC's hardware flow table.

That is where you will see exactly how OVS converts a software forwarding rule into a hardware forwarding rule, which is the core mechanism behind OVS hardware offloading.


---------------------------

# NVIDIA Mellanox ConnectX-5: Hardware flow offloading with OVS

The Mellanox ConnectX-5 (CX-5) is a good example for understanding how software-defined flows become hardware flows.

ConnectX-5 has an embedded hardware switching and packet-processing engine called the eSwitch (embedded switch). Its `mlx5` Linux driver exposes hardware flow-offloading capabilities through Linux networking interfaces and, separately, through DPDK APIs.

OVS can use these interfaces to program the ConnectX-5 hardware so that packets are forwarded, matched, and modified without going through the normal host CPU packet-processing path.

Let's break this down into four layers:

1. ConnectX-5 hardware capabilities.
2. Linux `mlx5` driver and its flow interfaces.
3. How OVS uses those interfaces.
4. How to configure and verify packet-processing offload.

## 1. ConnectX-5 hardware architecture

DOCA Switching - NVIDIA Docs

[docs.nvidia.com](https://docs.nvidia.com/doca/archive/3-2-2/doca-switching/index.html)

![cx5 hw arch](https://networking-docs.nvidia.com/doca/__attachments/a_2835fb4c37583a1f8ad5c8cb4a38d215783c206c4bcd591e620a626e9828f592/Kernel_Representors_Model_Host.png =240x)

A useful way to understand CX-5 is to distinguish its normal NIC datapath from its embedded switch datapath.

### 1.1 Embedded switch (eSwitch)

ConnectX-5 has an embedded switch that can forward packets between:

- Physical network ports (wire).
- Physical Function (PF).
- Virtual Functions (VF).
- Representor ports associated with virtual functions.

For example, imagine this configuration:

- PF0: Host physical function.
- VF0: Assigned to VM0.
- VF1: Assigned to VM1.
- Physical port: Connected to an external network.

The eSwitch can forward traffic between these endpoints without requiring the host CPU to process every packet.

An example:

text

```
             External Network
                    |
                    |
             Physical Port
                    |
          +-------------------+
          | ConnectX-5 eSwitch|
          |                   |
          | Hardware Flow     |
          | Tables             |
          |                   |
          +-------------------+
             |       |      |
             |       |      |
            PF0     VF0    VF1
                    |      |
                   VM0    VM1
```

Suppose VM0 sends packets to VM1.

Without hardware offloading, packets may travel through the host's software virtual switch.

With eSwitch hardware offloading, the NIC can forward packets directly from VF0 to VF1.

The host CPU does not need to perform the normal per-packet OVS forwarding operations.

### 1.2 Hardware flow tables

The eSwitch uses hardware flow tables to classify packets and execute actions.

A conceptual flow entry looks like:

text

```
MATCH:
    Source MAC       = 00:11:22:33:44:55
    Destination MAC  = 00:aa:bb:cc:dd:ee
    VLAN ID          = 100
    Destination IP   = 192.168.10.20

ACTION:
    Forward to VF1
```

The NIC hardware performs:

1. Packet parsing.
2. Header matching.
3. Flow-table lookup.
4. Action execution.
5. Forwarding.

The hardware implementation has multiple flow-table stages and additional metadata, so this is a conceptual representation rather than the actual internal hardware layout.

## 2. Linux `mlx5` driver: How hardware flows are exposed

The Linux driver for ConnectX-5 is primarily:

- `mlx5_core`: PCI device, firmware communication, and core device management.
- `mlx5e`: Ethernet network interface functionality.
- `mlx5_ib`: InfiniBand/RDMA functionality, when applicable.

For OVS offloading, the important components are `mlx5_core` and `mlx5e`.

There are two major ways to expose hardware flow processing to software.

Path A: Linux kernel networking

OVS kernel datapath

TC-flower / switchdev

`mlx5_core` / `mlx5e`

ConnectX-5 eSwitch hardware

Path B: DPDK userspace networking

OVS-DPDK

DPDK `rte_flow` API

`mlx5` DPDK PMD

ConnectX-5 eSwitch hardware

These are two distinct integration paths. You generally choose one based on the OVS datapath architecture.

### 2.1 Path A: TC-flower and switchdev

This is the conventional OVS kernel datapath hardware-offload path.

The relevant Linux concepts are:

Switchdev

Switchdev exposes the NIC's embedded switch to the Linux networking subsystem.

It allows Linux to manage physical ports, virtual ports, and hardware forwarding through standard networking abstractions.

Representor

A representor is a Linux network interface representing a hardware-managed virtual or physical port.

For example:

text

```
ConnectX-5
   |
   +-- Physical port: enp5s0f0
   |
   +-- VF0 representor: enp5s0f0_0
   |
   +-- VF1 representor: enp5s0f0_1
```

The representor allows OVS to manage the corresponding virtual port.

TC-flower

TC-flower is a Linux traffic-control classifier that supports match/action rules.

For example:

bash

```
tc filter add dev enp5s0f0_0 ingress \
    protocol ip flower \
    dst_ip 192.168.10.20 \
    action mirred egress redirect dev enp5s0f0_1
```

Conceptually, this asks the driver to install a rule that:

- Matches packets destined for `192.168.10.20`.
- Redirects matching packets to the VF1 representor's corresponding hardware port.

When the driver and hardware support the rule, it is installed in the eSwitch.

The Linux TC interface can also indicate whether a rule was offloaded using the `in_hw` flag.

For example:

bash

```
tc -s filter show dev enp5s0f0_0 ingress
```

Look for:

text

```
in_hw
```

This is an important distinction: successfully adding a TC rule does not necessarily mean it was installed in hardware.

### 2.2 Path B: DPDK and `rte_flow`

The second approach is particularly relevant if you want OVS-DPDK.

DPDK provides a common API called `rte_flow` for programming hardware flow rules.

For example, a conceptual `rte_flow` rule looks like:

c

```
struct rte_flow_attr attr = {
    .ingress = 1,
    .transfer = 1,
};

struct rte_flow_item pattern[] = {
    {
        .type = RTE_FLOW_ITEM_TYPE_ETH,
    },
    {
        .type = RTE_FLOW_ITEM_TYPE_IPV4,
    },
    {
        .type = RTE_FLOW_ITEM_TYPE_TCP,
    },
    {
        .type = RTE_FLOW_ITEM_TYPE_END,
    },
};

struct rte_flow_action actions[] = {
    {
        .type = RTE_FLOW_ACTION_TYPE_PORT_ID,
    },
    {
        .type = RTE_FLOW_ACTION_TYPE_END,
    },
};
```

This is an illustrative structure, not a complete executable rule: actual item masks, specifications, action configuration, and destination port must be supplied.

The important point is that `rte_flow` describes:

- Packet match criteria.
- Processing actions.
- Which hardware domain should process the flow.

For ConnectX-5, the `mlx5` DPDK PMD implements this interface and translates supported rules into hardware steering operations.

The `transfer` attribute is especially important: it indicates a flow in the embedded-switch domain rather than simply a flow for the NIC's own receive or transmit path.

NVIDIA's DPDK documentation describes the ConnectX-5 eSwitch flow-steering support and the distinction between NIC and eSwitch flow domains.

Data Plane Development Kit 26.07.0 documentation

+1

## 3. How OVS uses ConnectX-5 hardware flows

NVIDIA calls its OVS hardware-offloading technology ASAP² (Accelerated Switching and Packet Processing).

The central idea is:

Keep the OVS control plane, but move the OVS data plane into the ConnectX-5 eSwitch.

This is particularly useful in virtualization environments.

MLNX\_OFED Software

### 3.1 Example topology

Let's assume the following setup:

[cnblogs.com](https://www.cnblogs.com/dream397/p/14430927.html)

![representor](https://img2020.cnblogs.com/blog/665372/202103/665372-20210301193226743-1145921747.png =240x)



| Interface | Description |
| --- | --- |
| `enp4s0f0` | Physical NIC port / PF |
| `enp4s0f0_0` | VF0 representor |
| `enp4s0f0_1` | VF1 representor |
| `VF0` | Passed through to VM0 |
| `VF1` | Passed through to VM1 |

OVS creates a bridge:

```text
             OVS Bridge: br0
                    |
          +---------+---------+
          |         |         |
         PF        VF0       VF1
          |         |         |
        Uplink     VM0       VM1
                    |
              ConnectX-5
                eSwitch
```

Suppose VM0 communicates with VM1.

OVS receives a forwarding policy:

```text 
Match:
    in_port = VF0
    dst_mac = MAC_VM1

Action:
    output = VF1
```

OVS translates the forwarding policy into a datapath flow.

The hardware-offload provider then attempts to program the equivalent rule in the NIC.

Conceptually:

```text 
             OVS control plane
                    |
                    |
              OpenFlow rule
                    |
                    |
             OVS datapath flow
                    |
                    |
             Hardware offload
                    |
                    |
           TC-flower / mlx5 driver
                    |
                    |
          ConnectX-5 eSwitch FDB
                    |
                    |
              HW flow entry
                    |
                    |
              VF0 -> VF1
```

Here, FDB means Forwarding Database, the switching flow domain inside the embedded switch.

### 3.2 What happens when packets arrive?

Consider two scenarios.

Scenario A: First packet

1. VM0 sends a packet.
2. The NIC receives it through VF0.
3. The packet is processed through the OVS miss/control path if no suitable forwarding entry exists.
4. OVS determines that it should go to VF1.
5. OVS installs the software datapath flow.
6. OVS attempts hardware offloading.
7. The `mlx5` driver programs the eSwitch flow table.

Scenario B: Subsequent packets

1. VM0 sends another packet belonging to the same flow.
2. The NIC receives the packet.
3. The eSwitch matches the packet against the installed hardware flow.
4. The NIC forwards it directly to VF1.

The host CPU no longer needs to perform the normal OVS packet-forwarding operation for those packets.

This is the essential ASAP² architecture.

## 4. How to configure ConnectX-5 for OVS hardware offloading

Let's look at a practical OVS-Kernel configuration.

Recommended starting pointI would start with the kernel datapath and TC-flower before trying OVS-DPDK. This makes the relationship between Linux, the driver, and hardware easier to understand.

The following is an illustrative setup based on NVIDIA's ASAP² documentation. Adapt the PCI addresses and interface names to your machine.

### Step 1: Check the NIC and driver

```bash
lspci -nn | grep -i mellanox
```

Check the network driver:

```bash
ethtool -i enp4s0f0
```

Expected information includes:

```text
driver: mlx5_core
version: ...
firmware-version: ...
bus-info: 0000:04:00.0
```

Check the NIC's SR-IOV capabilities:

```bash
cat /sys/class/net/enp4s0f0/device/sriov_totalvfs
```

Check the current eSwitch mode:

```bash
devlink dev eswitch show pci/0000:04:00.0
```

You want to identify whether it is in:

- `legacy` mode
- `switchdev` mode

For this OVS hardware-offload example, we want `switchdev`.

### Step 2: Enable SR-IOV and create VFs

First, make sure SR-IOV is enabled in the server BIOS and NIC firmware.

Create two VFs:

```bash
echo 2 > \
/sys/class/net/enp4s0f0/device/sriov_numvfs
```

Verify:

```bash
ip link show enp4s0f0
```

You should see two VFs.

### Step 3: Change the eSwitch to switchdev mode

This operation is disruptive. Make sure the VFs are not assigned to running VMs and that you have alternative management access before proceeding.

Unbind the VFs:

```bash
echo 0000:04:00.2 > \
/sys/bus/pci/drivers/mlx5_core/unbind

echo 0000:04:00.3 > \
/sys/bus/pci/drivers/mlx5_core/unbind
```

Change the eSwitch mode:

```bash
devlink dev eswitch set \
pci/0000:04:00.0 mode switchdev
```

Bind the VFs again if required by your platform's setup:

```bash
echo 0000:04:00.2 > \
/sys/bus/pci/drivers/mlx5_core/bind

echo 0000:04:00.3 > \
/sys/bus/pci/drivers/mlx5_core/bind
```

Check:

```bash
devlink dev eswitch show pci/0000:04:00.0
```

Expected:

```text
mode switchdev
```

You should now have VF representor interfaces in the host.

For example:

```bash
ip link show
```

Look for interfaces similar to:

```text
enp4s0f0
enp4s0f0_0
enp4s0f0_1
```

The exact names depend on the system.

NVIDIA documents the SR-IOV and switchdev setup, including the VF unbinding requirement, in its ASAP² guide.

MLNX\_OFED Software

### Step 4: Enable OVS hardware offloading

Create an OVS bridge:

```bash
ovs-vsctl add-br br0
```

Enable hardware offloading:

```bash
ovs-vsctl set Open_vSwitch . \
    other_config:hw-offload=true
```

Restart OVS so the setting takes effect:

```bash
systemctl restart openvswitch
```

Add the physical interface and representors:

```bash
ovs-vsctl add-port br0 enp4s0f0

ovs-vsctl add-port br0 enp4s0f0_0

ovs-vsctl add-port br0 enp4s0f0_1
```

Bring them up:

```bash
ip link set enp4s0f0 up

ip link set enp4s0f0_0 up

ip link set enp4s0f0_1 up
```

At this point, OVS has been configured to attempt hardware offloading.

This does not yet prove that a hardware flow has been installed.

### Step 5: Configure a forwarding flow

Let's create a simple forwarding policy.

Assume VM0 is connected to VF0 and VM1 is connected to VF1.

First, inspect the OpenFlow port numbers:

```bash
ovs-ofctl show br0
```

Suppose the port numbers are:

```text
VF0 representor = 2
VF1 representor = 3
```

Install an OpenFlow rule:

```bash
ovs-ofctl add-flow br0 \
"priority=100,in_port=2,ip,actions=output:3"
```

This means:

```text
MATCH:
    Incoming port = VF0
    Ethertype = IPv4

ACTION:
    Forward to VF1
```

When packets matching this rule arrive, OVS can create a datapath flow and attempt to offload it to the ConnectX-5 eSwitch.

For production, you would normally configure bidirectional forwarding, MAC learning or explicit MAC rules, VLAN handling, and appropriate security policies.

## 5. How to verify that packets are actually offloaded

This is probably the most important part when experimenting with hardware offloading.

You need to distinguish three things:

1. OVS has a logical OpenFlow rule.
2. OVS has installed a software datapath flow.
3. The NIC has successfully installed a hardware flow.

These are not equivalent.

### 5.1 Check OpenFlow rules

```bash
ovs-ofctl dump-flows br0
```

This shows the logical forwarding policies.

### 5.2 Check OVS datapath flows

```bash
ovs-appctl dpctl/dump-flows -m
```

For a TC-offloaded flow, you may see an entry containing:

```text
in_port(...)
eth(...)
ipv4(...)
packets:1000
bytes:64000
dp:tc
actions:...
```

The `dp:tc` indication is useful evidence that the flow is using the TC offload datapath.

### 5.3 Check TC hardware rules

Inspect the representor:

```bash
tc -s filter show dev enp4s0f0_0 ingress
```

Look for:

```text 
in_hw
```

This indicates that the rule has been offloaded to hardware.

You can also inspect counters:

```text 
Sent 64000 bytes 1000 pkt
```

Compare the counters before and after sending traffic.

### 5.4 Check hardware counters

For more detailed debugging, NVIDIA provides driver and hardware flow-steering diagnostics. Available tools and debug interfaces depend on the installed driver and firmware.

The important thing is to correlate:

- OVS datapath flow counters.
- TC flow counters.
- Actual packet forwarding.
- NIC hardware counters.

OVS's TC documentation also explains hardware-offload limitations and statistics differences.

Open vSwitch 4.0.90 documentation

## 6. What types of packet processing can ConnectX-5 offload?

The NIC can do more than simply forward packets.

The following is a useful overview of operations exposed through the mlx5 offload infrastructure.

| Processing operation | Example | ConnectX-5 |
| --- | --- | --- |
| L2 matching | Source/destination MAC | Supported |
| VLAN matching | VLAN ID | Supported |
| IPv4 matching | Source/destination IP | Supported |
| IPv6 matching | IPv6 addresses | Supported |
| TCP/UDP matching | Source/destination ports | Supported |
| Forwarding | VF0 → VF1 | Supported |
| Drop | Firewall filtering | Supported |
| VLAN modification | Push/pop VLAN | Supported |
| Header modification | MAC/IP rewrite | Supported |
| VXLAN | Tunnel encapsulation/decapsulation | Supported with constraints |
| Connection tracking | Stateful firewall | Supported with platform/version constraints |
| NAT | Source/destination NAT | Supported with constraints |

These are not unconditional guarantees for every OVS flow. The actual supported combinations depend on the ConnectX-5 firmware, driver, kernel, and offload path.

For example, NVIDIA documents support for various L2/L3/L4 matching fields, forwarding, dropping, VLAN operations, tunnel operations, and connection tracking in its ASAP² documentation.

MLNX_OFED Software

## 7. What about OVS-DPDK?

There is another way to use ConnectX-5 hardware offloading.

Instead of:

```text
OVS Kernel
    |
TC-flower
    |
mlx5 Linux driver
    |
ConnectX-5
```

You can use:

```text
OVS-DPDK
    |
DPDK rte_flow
    |
mlx5 DPDK PMD
    |
ConnectX-5
```

The important distinction:

| Feature | OVS-Kernel | OVS-DPDK |
| --- | --- | --- |
| Datapath | Kernel | Userspace |
| Packet I/O | Linux networking | DPDK PMD |
| Hardware flow API | TC-flower | rte\_flow |
| NIC driver integration | mlx5 kernel driver | mlx5 DPDK PMD |
| Hardware offload | Yes | Yes |
| Software fallback | Kernel datapath | Userspace datapath |

For OVS-DPDK, the general hardware-offload configuration is:

```bash
ovs-vsctl set Open_vSwitch . \
    other_config:dpdk-init=true

ovs-vsctl set Open_vSwitch . \
    other_config:hw-offload=true
```

The ConnectX-5 DPDK device also needs the appropriate eSwitch and flow-steering configuration.

For example, NVIDIA documents parameters such as:

```text
dv_flow_en=1
dv_esw_en=1
dv_xmeta_en=1
```

These enable the relevant mlx5 Direct Verbs flow and eSwitch functionality for the documented DPDK configuration. They are not universal settings for every driver version.

See NVIDIA's [ASAP² OVS offload guide](<https://networking-docs.nvidia.com/mlnxofedswum/542413/ovs-offload-using-asap2-direct?utm_source=chatgpt.com>) and the [DPDK mlx5 driver documentation](<https://doc.dpdk.org/guides/nics/mlx5.html?utm_source=chatgpt.com>).

MLNX_OFED Software

## 8. The complete architecture to remember

Here is how I would mentally organize the entire ConnectX-5 OVS offloading system:

Understanding OpenVswitch Hardware Offloading | kp0zhiqian's

[kp0zhiqian.github.io](https://kp0zhiqian.github.io/posts/hardware_offload)

![kp0zhiqian.github.io](https://kp0zhiqian.github.io/post-image/hw-ol/ovs-overview.png =360x)


| Component | Responsibility |
| --- | --- |
| OVS OpenFlow | Defines packet-processing policy |
| OVS datapath | Implements software forwarding and maintains flow state |
| TC-flower / rte\_flow | Describes hardware match/action rules |
| mlx5 driver | Translates requests into NIC hardware programming |
| ConnectX-5 eSwitch | Stores and executes hardware flow rules |
| Representors | Allow OVS/Linux to manage eSwitch ports |

The key idea is:

OVS decides WHAT should happen to packets. The mlx5 driver figures out HOW to program the ConnectX-5 hardware to perform that processing. The eSwitch actually executes it.

## 9. Suggested hands-on learning sequence

Experiment in this order:

1. Understand the eSwitch
   Create two VFs, enable switchdev mode, and identify their representors.
2. Understand TC-flower
   Manually create a TC rule using `tc filter add` and verify that it reports `in_hw`.
3. Understand OVS software flows
   Create an OVS bridge and install OpenFlow rules. Inspect the resulting datapath flows.
4. Enable OVS hardware offloading
   Set `hw-offload=true` and verify that the corresponding TC rules appear in hardware.
5. Experiment with packet-processing actions
   Try forwarding, dropping, VLAN modification, and VXLAN encapsulation.
6. Compare performance
   Measure throughput, latency, CPU utilization, and hardware flow counters with and without offloading.

One distinction worth keeping in mind: ConnectX-5's eSwitch flow offloading is not the same as ordinary NIC checksum offloading, TSO, or RSS. Those are other hardware acceleration mechanisms. Here, we are specifically discussing programming match/action forwarding rules into the eSwitch.

For further exploration, the two most useful references are:

- [NVIDIA ASAP² – OVS Offload Using ASAP² Direct](https://networking-docs.nvidia.com/mlnxofedswum/542413/ovs-offload-using-asap2-direct)
- [DPDK – NVIDIA mlx5 Ethernet Driver](https://doc.dpdk.org/guides/nics/mlx5.html?highlight=mlx5)

These explain the actual hardware interfaces and their limitations in considerably more detail.

