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


# InfiniBand Concept:

Understanding InifiniBand (IB) requires shifting your mind away from traditional "Ethernet thinking". 

- Ethernet is designed for broad compatibility and "best-effort" delivery, InfiniBand is a *switched fabric*
  designed for one thing: getting data from Application A's memory to Application B's memory with zero CPU
  intervention.

- The magic of InfiniBand lies in RDMA (Remote Direct Memory Access) and its Lossless Fabric architecture.
    - Kernel Bypass: InfiniBand allows the apps to talk directly to the HCA (Host Channel Adapter), skipping
      the Linux kernel entire
    - Zero-Copy: Data is moved directly between the RAM of two different computers. CPU on both sides is
      barely aware the transfer is happening.
    - Credit-Based Flow Control: Unlike Ethernet, which drops packets when congested (lossy), IB uses a
      "credit" system. A sender won't transmit a packet unless the receiver confirms it has the buffer 
      space to hold it. This makes it lossless.
    - The Subnet Manager (SM): An IB network cannot function without an SM. It is a software (or hardware)
      entity that "discovers" the network, assigns LIDs (Local Identifiers) to every port, and calculates 
      the routing tables.

## Setup Scope: Connecting Two Linux computers

To connect two nodes directly (Back-to-Back) or through a switch, follow this workflow:
- Two InfiniBand HCAs (e.g., Mellanox/NVIDIA ConnectX-4/5/6).
- A compatible cable (QSFP/SFP depending on the generation).

- Software Installation:
```bash 
sudo apt update
sudo apt install rdma-core ibverbs-utils perl opensm ibutils 
```
- The "Crucial" Step: Start the Subnet Manager: If you don't have a managed IB switch, one of your Linux
  computers must act as the Subnet Manager.
```bash 
sudo systemctl enable opensm
sudo systemctl start opensm
```

- Verify Physical Connectivity: Run `ibstat` or `ibv_devinfo`. You are looking for:
    - State: Active (If it says Initializing, your Subnet Manager isn't working).
    - Physical state: LinkUp.
    - Rate: e.g., 100 Gb/sec (4X EDR).

- Test Scope: Performance Benchmarking: 
    - Once the link is Active, you must test the two primary ways IB is used: 
        - Verbs (Native RDMA) and IPoIB (IP over InfiniBand).

- Test 1: Native RDMA Bandwidth (The "Real" Speed): Use the `perftest` package to measure raw mem-2-mem
  speed.
  - On Node A (Server): `ib_write_bw`
  - On Node B (Client): ib_write_bw <IP_or_LID_of_Node_A>

- Test 2: RDMA Latency:
  - On Node A: `ib_write_lat`
  - On Node B: `ib_write_lat <Node_A>`

- Test 3: IPoIB (Legacy Compatibility):
  - InfiniBand can "pretend" to be an Ethernet card so you can use standard tools like ssh or `iperf`.
  - Assign IPs to the ib0 interface on both machines (e.g., 192.168.10.1 and 192.168.10.2).
  - Run iperf3 between them.

## GID: 

- GIDs (Global Identifiers) are essentially the "IP addresses" of the RDMA fabric. While IB uses LIDs 
  (Local IDs) to move traffic within a single local subnet, it uses GIDs to identify ports across routers
  or when using RoCE (RDMA over Converged Ethernet).

- A GID is a 128-bit identifier used to identify a specific port on an HCA (Host Channel Adapter) or a router interface

- To configure and verify GIDs for RoCE :
    - **GIDs are derived from the IP configuration of the NIC**. You don’t configure GIDs directly 
    - you configure **IP addresses**, and the system generates the corresponding GIDs.

---

### 1. Configure IP address (this is the key step)

#### For RoCE v2 (most common case)

You should assign a **real IP address** to the interface:

```bash
ip addr add 192.168.100.10/24 dev enp1s0f0np0
ip link set enp1s0f0np0 up
```

Or for IPv6:

```bash
ip -6 addr add 2001:db8::10/64 dev enp1s0f0np0
```

---

### 2. Check IP is applied

```bash
ip addr show enp1s0f0np0
```

You should now see:

* `inet 192.168.100.10` (IPv4), or
* global IPv6 (not just `fe80::`)

---

# 📊 3. View GIDs again

Run:

$ show_gids
| DEV | PORT | INDEX   | GID | IPv4 | VER | DEV |
| --- | --- | --- | --- | --- | --- | --- |
| rocep1s0f0 | 1 | 0 | fe80:0000:0000:0000:6eb3:11ff:fe88:55b4 |  | v1 | enp1s0f0np0 |
|rocep1s0f0      |1   |1       |fe80:0000:0000:0000:6eb3:11ff:fe88:55b4 |                |v2      |enp1s0f0np0|
|rocep1s0f0      |1   |2       |0000:0000:0000:0000:0000:ffff:c0a8:640a |192.168.100.10          |v1      |enp1s0f0np0|
|rocep1s0f0      |1   |3       |0000:0000:0000:0000:0000:ffff:c0a8:640a |192.168.100.10          |v2      |enp1s0f0np0|
|rocep1s0f1      |1   |0       |fe80:0000:0000:0000:6eb3:11ff:fe88:55b5  |               |v1      |enp1s0f1np1|
|rocep1s0f1      |1   |1       |fe80:0000:0000:0000:6eb3:11ff:fe88:55b5  |               |v2      |enp1s0f1np1|
n_gids_found=6 

for example:

```
GID                                   IPv4
-----------------------------------    ------------
::ffff:192.168.100.10                 192.168.100.10
```

---

### How it works (important)

* No IP → only **link-local GID (fe80::)**
* IPv4 assigned → **IPv4-mapped GID (::ffff:x.x.x.x)** appears
* IPv6 assigned → **global IPv6 GID** appears

---

### 4. (Optional) Ensure RoCE v2 is enabled

Check:

```bash
cat /sys/class/infiniband/*/ports/1/gid_attrs/types/*
```

You should see `RoCE v2`.

---
### Extra: test mapping directly

You can inspect GIDs manually:

```bash
cat /sys/class/infiniband/mlx5_0/ports/1/gids/0
```

---

### Summary

* You **don’t configure GIDs directly**
* You **configure IP addresses**
* GIDs are automatically generated from them

---

## tuning (MTU 9000, PFC, ECN) ( Key for Performance )

-  If MTU/PFC/ECN aren’t tuned, you’ll get packet loss → retransmissions → terrible latency.

- A practical, working baseline for RoCE v2.
    1. Set MTU 9000 on NIC
    ```bash 
    ip link set dev enp1s0f0np0 mtu 9000
    ip link show enp1s0f0np0   <- verify the changed mtu is set.
    ```
    2. Enable PFC (Priority Flow Control) : RoCE cannot tolerate packet loss → PFC pauses traffic instead of
       dropping it. TO Enable flow control on NIC
    ```bash 
    #ethtool -A enp1s0f0np0 rx on tx on    
    ```
    3. Enable PFC with DCB:
    ```bash 
    $sudo  apt install lldpad   # or yum install lldpad
    $systemctl start lldpad
    ```
    4. Configure PFC (example: priority 3): This will enable PFC on priority 3
    ```bash 
    dcbtool sc enp1s0f0np0 pfc e:1 a:1 w:1 
    dcbtool sc enp1s0f0np0 pfcup:0 0 0 1 0 0 0 0
    ```
    5. Map RoCE traffic to that priority: 
    ```bash 
    mlnx_qos -i enp1s0f0np0 --pfc 0,0,0,1,0,0,0,0
    ```
- ECN (Explicit Congestion Notification):
    - PFC alone can cause:
        - Head-of-line blocking
        - Congestion spreading

  ECN helps avoid that by marking packets instead of pausing immediately.

- On NIC (RoCE ECN enable):
```bash 
echo 1 > /sys/class/net/enp1s0f0np0/ecn/roce_np/enable
echo 1 > /sys/class/net/enp1s0f0np0/ecn/roce_rp/enable 
## On Linux (IP Stack ECN)
sysctl -w net.ipv4.tcp_ecn=1
```

- Verify everything
    - Mtu : ip link show | grep mtu  
    - PFC counters: `ethtool -S enp1s0f0np0 | grep pfc`
    - Check loss: `ethtool -S enp1s0f0np0 | grep -i drop`

- Test RDMA performance:

- For latency `ibv_rc_pingpong`
- For bandwidth: `ib_write_bw`

## `perftest`: 

- `perftest` is the industry-standard benchmark suite for both InfiniBand and RoCE, developed by Mellanox
  and is part of the rdma-core ecosystem.

- `perftest`: it’s a collection of specialized micro-benchmarks. The names tell you exactly what they do:
    - `ib_write_bw` / `ib_read_bw`: Measures Bandwidth (How many Gbps can I push?). "Write" is generally 
      faster than "Read" in RDMA because it's a one-way operation.
    - `ib_write_lat` / `ib_read_lat`: Measures Latency (How many microseconds does a round-trip take?).
    - `ib_send_bw`: Uses the "Send/Receive" queue pair type (slightly more CPU overhead than Write/Read).
    - `ib_atomic_bw`: Tests atomic operations (Remote fetch-and-add), used in advanced distributed computing.

    
