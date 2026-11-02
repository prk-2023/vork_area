# OVS:


## Introduction:

Opensource, multi-layer SW switch, Its designed to operate as a virtual switch within Hypervisor and
conatiner environments such as KVM, Xen and proxmox, to handle traffic between virtual machines (VMs) and
external physical networks.

Because Hypervisors (KVM) and containers ( docker ) are built on top of standard linux networking, OVS
runs as native system daemon directly on the host OS.

You can use Open vSwitch on a standard Linux bare-metal server or desktop to replace or augment the
traditional Linux bridge (bridge-utils / ip link add br0 type bridge).

### Where OpenVswitch can run:

- Standard Linux Bare-Metal: Runs as regular system services (`ovs-vswitchd` and `ovsdb-server`) on
  distributions like Ubuntu, Debian, RHEL, and CentOS.

- Other Operating Systems: It has been ported to FreeBSD and Microsoft Windows (Hyper-V).

- **SmartNICs / Hardware Switches**: Runs on hardware acceleration platforms and smart network interface
  cards (SmartNICs) using DPDK (Data Plane Development Kit) or hardware offloading.

### Why use openvSwitch over Linux Bridge:

Default Linux bridge is simple and lightweight and excellent for simple setups but choose OVS when you need:

- **Progammatic Control**: If you want to use a SDN controller to inject OpenFlow rules directly into host
  networking.

- **Advanced tunneling**: If the host needs to act as gateway terminating VXLAN or GRE tunnels from other
  parts of the data center. 

- **Enhanced Monitoring**: if You require fine-grained traffic analytics via sFlow or NetFlow directly from the host interfaces.

### Key Features

- **L2/L3 Switching**: Supports standard bridging, MAC address learning, 802.1Q VLAN tagging, and trunking

- **Tunneling Protocols**: Built-in support for overlay networks using VXLAN, GRE, Geneve, and ERSPAN to connect VMs across different physical hosts. 

- OpenFlow Support: Exposes programmatic control interfaces, allowing an SDN (Software-Defined Networking) controller to dynamically manage and modify packet-forwarding rules

( 
OpenFlow: A vendor-neutral, southbound communication standard in SDN that separates the control plane from
the data plane. It lets a centralized controller program the forwarding and flow tables of physical or
virtual switches.
)

- Network Visibility & QoS: Integrates monitoring tools like NetFlow, sFlow, and RSPAN, alongside
  per-interface traffic policing and Quality of Service (QoS) controls


### Core Architecture

OVS separates its components across the kernel and user space for performance and flexibility:

- `ovs-vswitchd`: The core user-space daemon that implements the switch logic and communicates with
  OpenFlow controllers.
- `ovsdb-server`: A lightweight JSON database daemon that stores configuration data persistently across
  system reboots.
- `Kernel Module`: Caches packet matches and actions for high-speed "fast path" forwarding, punting
  unmatched "slow path" packets up to user space (ovs-vswitchd).

### Basic management commands:

You can manage OVS bridges and ports via the command line using tools like `ovs-vsctl`:
- Create a bridge: `ovs-vsctl add-br br0`
- Add a port to a bridge: `ovs-vsctl add-port br0 eth0`

## OVS Overview :

Open vSwitch  consists of **three main components** that work together to move packets:

---

### **3 Main parts of OVS**

1. **The Ports (The Doors):**
* These are the connection points where packets enter and leave. They can be physical network cards on
  your server, or virtual ports connected to individual virtual machines (VMs) or containers.


2. **The Kernel Datapath (The Fast Gate / Worker):**
* This lives inside the Linux kernel and handles the heavy lifting. Its job is to move packets as fast as
  possible using a quick-reference list (the Megaflow cache we talked about). Most packets never leave
  this department.


3. **The Userspace Daemon / `ovs-vswitchd` (The Brain / Main Office):**
* This runs in userspace (outside the kernel). It holds the big, complex rulebook called **OpenFlow
  tables**. The datapath only talks to this department when it doesn't know what to do with a new kind of
  packet.



---

### **The Full Journey of a Packet**

When a packet flows through OVS from input to output, it takes this exact path:

1. **Arrival:** A packet arrives at an **Input Port** (e.g., from a VM or physical cable).
2. **The Fast Check:** The **Kernel Datapath** immediately checks its quick-reference list.
* **If it knows the rule:** It instantly applies the action (like modifying headers or forwarding) and
  shoots the packet out the **Output Port**. *Journey ends here for 99% of normal traffic.*


3. **The Unknown Packet (The Upcall):**
* **If it doesn't know the rule:** The datapath pauses, packages up the packet header, and sends an
  "upcall" message up to the **Userspace Daemon (`ovs-vswitchd`)**.


4. **The Brain Decides:**
* The userspace daemon looks at the packet, runs it through its complex **OpenFlow tables**, and figures
  out the master policy for where this packet should go.


5. **Learning for Next Time:**
* The daemon tells the kernel datapath: *"Send this packet to Port B, and remember this rule for next time
  so you don't have to call me again."*


6. **Departure:** The packet is sent out through the designated **Output Port**.

---

## Core components of Open vSwitch (OVS):

---

### **1. Ports and Interfaces (The Entry and Exit Points)**

* **What they are:** These are the physical or virtual connection points where packets enter and leave the
  switch.
* **Types:**
* **Physical Ports:** Real network interface cards (NICs) on the host machine (e.g., `eth0`).
* **Virtual Ports (VIFs / TAP devices):** Interfaces connected to virtual machines, containers, or
  namespaces.
* **Tunnel Ports:** Virtual ports used to encapsulate traffic (like VXLAN or GRE) to send packets across
  physical networks to other servers.

---

### **2. `ovsdb-server` (The Configuration Database)**

* **What it is:** The persistent storage system for OVS. It holds all the configuration data—such as what
  bridges exist, which ports belong to which bridge, and what controllers are connected.
* **How it works:** When you run commands like `ovs-vsctl add-br br0`, you are talking directly to
  `ovsdb-server`. The OVS daemon (`ovs-vswitchd`) reads this database to know how the switch is supposed
  to be structured.

---

### **3. `ovs-vswitchd` (The Userspace Daemon / The Brain)**

* **What it is:** The main software daemon that runs in userspace (standard operating system space,
  outside the Linux kernel).
* **How it works:** It acts as the manager and bridge controller. It implements the standard **OpenFlow
  protocol**, talks to external SDN controllers if configured, and computes packet paths when the kernel
  doesn't know what to do with a packet.

---

### **4. OpenFlow Flow Tables (The Master Rulebook)**

* **What they are:** A set of structured, prioritized tables managed inside the `ovs-vswitchd` daemon.
* **How they works:** Unlike simple switches, OpenFlow allows deep, programmable control. A table contains
  rules that say: *"If a packet matches criteria X, perform actions Y (like rewrite headers, send to port
  Z, or pass to table 2)."* This is where complex networking policies live.

---

### **5. The Kernel Datapath (`ovs_kernel` module or Userspace `netdev` / DPDK)**

* **What it is:** The high-performance packet-processing engine. In standard Linux deployments, it runs
  directly inside the **Linux kernel** to process packets as fast as possible without context-switching to
  userspace. (If using DPDK, it runs in userspace but bypasses the OS kernel for extreme speed).
* **How it works:** It acts as the fast-path forwarding engine. It checks incoming packets against active
  rules and forwards them instantly.

---

### **6. The Megaflow Cache (The Fast-Reference List)**

* **What it is:** A temporary, wildcarded cache maintained inside the kernel Datapath.
* **How it works:** Instead of sending every single packet up to the heavy OpenFlow pipeline
  (`ovs-vswitchd`), the datapath checks this cache. If a packet matches an active entry, it is forwarded
  instantly in microseconds.

---

## Components that make up Open vSwitch (OVS)

---

### **The Complete Component Checklist**

#### **1. Ports and Interfaces (The Entry/Exit Gates)**

* **Physical NICs, TAP devices, veth pairs, or VIFs:** Where packets physically or virtually enter and
  leave the switch.

#### **2. Alternative Datapaths (How Packets Are Handled at the Lowest Level)**

* **The Kernel Datapath (`ovs_kernel`):** The default module running inside the Linux kernel, using
  standard kernel packet buffers.
* **DPDK (Data Plane Development Kit):** A userspace datapath framework that bypasses the OS kernel
  entirely, polling NICs directly via PMD (Poll Mode Driver) threads for extreme raw performance.
* **AF_XDP (Address Family eXpress Data Path) — *(The High-Performance Linux Alternative)*:**
* *What it is:* A modern Linux socket-based mechanism built on eBPF (Extended Berkeley Packet Filter).
* *Where it fits:* It acts as a specialized netdev datapath type (`type=afxdp`) that hooks directly into
  an XDP program on the network card driver.
* *Why it’s used:* It provides ultra-fast packet movement between the driver/kernel and userspace with
  zero-copy options, matching much of DPDK's high throughput while still allowing you to use standard
  Linux networking tools (like `ip` commands).



#### **3. The Megaflow Cache (The Fast-Reference List)**

* A wildcarded cache kept right at the datapath layer. If a packet matches an entry here, it is forwarded
  instantly without waking up the main userspace brain.

#### **4. `ovsdb-server` (The Configuration Database)**

* The persistent backend database holding the structural blueprint of your switch (bridges, ports,
  configurations, controller IPs).

#### **5. `ovs-vswitchd` (The Userspace Daemon / The Brain)**

* The core management daemon running in userspace. It processes "flow misses" sent up from the datapath
  and drives the control plane.

#### **6. OpenFlow Flow Tables (The Master Rulebook)**

* Structured, prioritized rule sets housed inside `ovs-vswitchd` that handle complex matching criteria,
  tunneling, and forwarding policies.

---

### **The Full End-to-End Packet Journey**

When you combine every piece into a single timeline, a packet moves through the system like this:

1. **Arrival at the Port:** A packet hits a physical card, a virtual container interface, or an **AF_XDP /
   DPDK** accelerated queue.
2. **The Fast Check:** The low-level datapath checks its active **Megaflow Cache**.
* *If found:* The action executes instantly, and the packet leaves through the output port. (Fast path
  complete).
* *If missing:* A **Flow Miss Upcall** is triggered.


3. **The Upcall to Userspace:** The packet header is sent up to the **`ovs-vswitchd`** daemon.
4. **OpenFlow Pipeline Evaluation:** The daemon evaluates the packet against the master **OpenFlow Flow
Tables** to determine the exact policy.
5. **Caching for the Future:** `ovs-vswitchd` translates that policy into a generalized wildcard rule and
pushes it down into the **Megaflow Cache**.
6. **Departure:** The packet is sent out through the designated **Output Port**.


---

## Megaflow cache:

The **Megaflow Cache** (also known as the Datapath classifier cache) is the core mechanism that allows
Open vSwitch to achieve high-speed, kernel-level packet forwarding without constantly interrupting the
userspace CPU.

To understand why it exists, you have to look at the two extremes of packet processing in OVS:

1. **Exact-Match (Microflow) Cache:** Historically, OVS used an exact-match cache where *every single
   unique field* of a packet (source IP, destination IP, source port, destination port, transport
   protocol, MAC addresses, VLAN tags, etc.) had to match an entry. While fast, this resulted in massive
   cache pollution and poor hit rates because a new flow (like a short HTTP request or a distinct DNS
   lookup) created a brand-new cache entry, causing frequent cache misses.
2. **OpenFlow Pipeline:** This is handled in userspace (`ovs-vswitchd`). It is fully featured and supports
   wildcards, but running every single packet through userspace introduces massive latency and high CPU
   overhead.

### **How the Megaflow Cache Works**

The Megaflow cache bridges this gap by introducing **wildcarded flow entries** at the kernel datapath
level. Instead of requiring an exact match on *every* header field, a megaflow entry matches *only the
fields that matter* for a specific traffic flow, while ignoring (wildcarding) the rest.

* **Example:** If two virtual machines are communicating, the OpenFlow controller might care about the
  source and destination IP addresses, but it might not care about the IP TTL or the TCP sequence numbers
  for routing purposes.
* A Megaflow entry groups packets by those relevant fields. Any packet belonging to that same IP pair hits
  the same megaflow rule in the kernel, regardless of its changing TCP windows or packet lengths.

### **Why It Processes Packets Quickly**

* **Stays in Kernel Space:** Packets that hit the Megaflow cache are processed entirely within the Linux
  kernel (or user-space datapath driver if using DPDK), avoiding the expensive context switch up to the
  `ovs-vswitchd` userspace daemon.
* **Reduces Upcalls:** By using wildcarding, a single Megaflow entry can handle millions of unique packets
  (e.g., thousands of different TCP connections between the same two subnets), drastically reducing the
  number of "Flow Miss Upcalls" sent to userspace.
* **Efficient Lookup Structure:** OVS uses a tuple-space search mechanism (or specialized classifiers) to
  scan these wildcarded rules rapidly, ensuring forwarding decisions happen in microsecond timeframes.


---

## Summary:

Open vSwitch (OVS) processes packets using a hybrid architecture split between the **Kernel Space (Fast
Path)** for performance and the **Userspace (Slow Path / Control Plane)** for flexibility and
decision-making.

Here is a comprehensive breakdown of all the components involved and the step-by-step journey of a packet
from input to output.

---

### **Key Components Involved**

1. **Ports and Interfaces:**
* The entry and exit points of the switch (e.g., physical NICs, virtual interfaces like `veth` pairs, TAP
  devices, or DPDK ports).


2. **OVS Datapath (`ovs_kernel` module or Userspace `netdev` / DPDK):**
* The high-performance packet-forwarding engine. It maintains a **megaflow cache** (wildcarded flow
  entries) to process packets quickly without troubling the userspace.


3. **`ovs-vswitchd` (Userspace Daemon):**
* The core OVS daemon that manages the switch configuration, handles flow misses, and implements the
  **OpenFlow pipeline**.


4. **OpenFlow Flow Tables:**
* Multi-table pipeline managed by `ovs-vswitchd` where complex matching rules and actions reside.


5. **`ovsdb-server` (Configuration Database):**
* Stores the persistent configuration of OVS (bridges, ports, controllers, configurations), queried by
  `ovs-vswitchd` upon startup and updates.



---

### **Step-by-Step Packet Journey: Input to Output**

#### **Step 1: Packet Arrival (Input Port)**

* A packet arrives at an OVS interface (e.g., a VM's virtual port or a physical NIC port).
* The underlying host kernel driver hands the packet over to the **OVS Datapath**.

#### **Step 2: Datapath Lookup (The "Fast Path")**

* The datapath checks its internal **Megaflow Cache** (exact-match and wildcarded flow entries) using the
  packet's headers (MAC addresses, IPs, ports, VLAN tags, etc.).
* **Scenario A (Cache Hit):** If a matching rule exists, the datapath instantly executes the associated
  actions (e.g., modifying headers, decrementing TTL, and forwarding to the output port) and the packet
  exits OVS. *Processing stops here for this packet.*
* **Scenario B (Cache Miss):** If no matching rule is found in the datapath, the packet triggers a **Flow
  Miss Upcall** and is sent up to userspace.

#### **Step 3: Upcall to Userspace (`ovs-vswitchd`)**

* The packet (or a copy of its header) is sent via a Netlink socket from the kernel datapath to the
  **`ovs-vswitchd`** daemon.
* `ovs-vswitchd` receives the packet and prepares to run it through the OpenFlow pipeline.

#### **Step 4: OpenFlow Pipeline Evaluation**

* `ovs-vswitchd` passes the packet through its configured **OpenFlow Flow Tables** (often multiple tables
  linked via `goto` instructions).
* It evaluates the packet against the defined OpenFlow rules sequentially until it finds a match.
* Once a matching OpenFlow rule is found, the corresponding **OpenFlow Actions** (e.g., normal switching,
  tunneling encapsulation, dropping, or outputting to a specific port) are determined.

#### **Step 5: Flow Installation (Caching for the Future)**

* To prevent future packets of the same flow from hitting userspace again (which is CPU-intensive),
  `ovs-vswitchd` translates the OpenFlow rule into a generalized **Megaflow rule**.
* It pushes this new flow entry down into the kernel **Datapath Cache**.

#### **Step 6: Packet Output (Transmission)**

* The packet is sent back down to the datapath (or processed directly if retained in userspace), which
  executes the final actions.
* The packet is transmitted out through the designated **Output Port** (e.g., another VM, a physical
  interface, or encapsulated into a tunnel like VXLAN/GRE).
