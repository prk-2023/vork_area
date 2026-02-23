# InifiniBand Network Adapters:

*InifiniBand* network adapters are often called as *HCA* ( Host Channel Adapter ) its a PCI-Express card
that connects a computer to an InifiniBand fabric, Which is a high-performance, low-latency networking
technology mainly used with:
- Super Computers
- HPC 
- AI/ML clusters 
- Financial Trading systems 

This is not a regular Ethernet. 

*InifiniBand* is a high throughput, very low-latency interconnect designed for server-to-server
communication.

- Compared to Ethernet:

| Feature            | Ethernet        | InfiniBand              |
| ------------------ | --------------- | ----------------------- |
| Typical Use        | LAN / Internet  | HPC / Datacenter fabric |
| Latency            | Microseconds    | Sub-microsecond         |
| CPU Overhead       | Higher          | Very low                |
| RDMA Support       | Optional (RoCE) | Native                  |
| Switch Requirement | Ethernet switch | InfiniBand switch       |


- What do InifiniBand adapters do:

* Plugs into a **PCIe slot**
* Connects via **QSFP/QSFP28 cables**
* Communicates using the InfiniBand protocol
* Offloads communication from the CPU
* Supports **RDMA (Remote Direct Memory Access)**


## RDMA is the key feature:

It allows one computer to directly access another computer’s memory **without involving the remote CPU**:
this is extremely fast and efficient.

- A regular Ethernet NIC:
    * Speaks TCP/IP
    * Connects to routers/switches
    * Works with standard network infrastructure

- An InfiniBand adapter:
    * Speaks the InfiniBand protocol
    * Requires InfiniBand switches
    * Uses different drivers and software stack

- Example Vendors: Common InfiniBand adapter vendors include:
    * NVIDIA (formerly Mellanox)
    * Intel (older generations)
    * IBM (enterprise systems)

E.g: Mellanox ConnectX-3 are dual-mode:
    * Can run as InfiniBand
    * Or flash firmware to run as Ethernet (depending on model)

Note: Old InfiniBand cards (like ConnectX-3) are often:
    * 40Gb/s or 56Gb/s
    * Very cheap on the used market
    * But require special switches/cables
    * Not plug-and-play for home Ethernet

That’s why they’re inexpensive — they’re enterprise gear.

=> Note: 
    InifiniBand are useless for XDP as they use different stack not standard `netdev` path, and XDP,
    works with Ethernet driver. 

- **InfiniBand network adapter = PCIe card for ultra-fast data-center interconnect, not regular Ethernet networking.**

- And *RDMA* is also not for XDP as they live in different parts of the networking stack and solve
  different problems. 

- XDP: 
    * runs in Linux kernel.
    * At the earliest point in the Etnernet receive path. 
    * Attached to `net_device` ( normal NIC interface )
    * Inside standard networking stack 

- XDP is used for : (typical use cases)
    * Packet filtering
    * Load balancing 
    * DDoS mitigation 
    * Forwarding 
    * Statistics 
    * Fast drop/redirect 

- RDMA is completely different:
    * Bypasses Normal Networking stack 
    * bypasses TCP/IP 
    * Often bypass kernel data-path 
    * Allows direct memory transfer between machines 
    * Uses specialized NIC queues and verbs API. 
    * traffic does not go through Netfilter,TC,XDP, Normal IP stack.




