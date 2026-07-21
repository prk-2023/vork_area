        # SmartNIC ( mlx 5 )

RDMA is the deepest architecture break from standard net on this NIC.

Standard networking path for every byte:

```
   app 
    → syscall 
        → socket buffer copy 
            → TCP/IP stack 
                → driver 
                    → NIC 
                        → driver 
                            → TCP/IP Stack 
                                → socket buffer copy 
                                    →  app 
```


Every one of the above step copies and context switches costs CPU cycles and latency.
At 100Gbps that overhead alone can saturate a CPU core before doing any other real work. 

RDMA proposition: 
- Let the NIC read/write directly into a remote application memory, with the CPU on both ends completely
  uninvolved in the data movement.  This means there are no kernel stack, no copies, no interrupt per
  byte. 
- There is a trade off with this approach that this requires a much stricter contract with the network
  than TCP ever needed.


**Queue Pairs (QPs) - the RDMA execution unit.

In place of sockets for standard TCP/IP networking, the `RDMA` unit for work is a **`Queue Pair`**:
`**a senf queue + receive queue**`, its always used together, backed by a Completion Queue (**CQ**) that
reports when work is finished. 

```mermaid 
flowchart LR
    %% Styles
    classDef host fill:#eef0ff,stroke:#5b5bd6,stroke-width:2,color:#333;
    classDef queue fill:#ffffff,stroke:#5b5bd6,stroke-width:1.5,color:#333;
    classDef hostB fill:#e9f7f2,stroke:#2d9c7a,stroke-width:2,color:#333;
    classDef queueB fill:#ffffff,stroke:#2d9c7a,stroke-width:1.5,color:#333;
    classDef note fill:#f5f3ef,stroke:#999,color:#333;

    subgraph A["Host A (app memory)"]
        direction LR
        SQ["**Send queue**<br/>Work request posted"]
        CQ["**Completion Queue (CQ)**<br/>Notifies app"]
    end

    subgraph B["Host B (app memory)"]
        direction LR
        RQ["**Receive queue**<br/>HW writes directly"]
    end

    N["**No CPU, no kernel**<br/>stack on either side"]

    SQ -- "RDMA (RoCE / InfiniBand / iWARP)" --> RQ

    A --> N
    B --> N

    class A host;
    class SQ,CQ queue;
    class B hostB;
    class RQ queueB;
    class N note;
```

The above mermaid flow chart captures the core concept of **RDMA Queue Pairs** (QPs) and zero copy transfer.

For a complete picture:

- **Queue Pairs are Paired**: An `RDMA QP` consists of **`Send Queue (SQ)` and a `**Receive Queue (RQ)` on
  **both** sides. 

  - Host A has a `SQ` and `RQ`
  - Host B also has a `SQ` and `RQ` 
  - Host A and B also have a completion Queue, especially if send/receive semantics or completions with
    immediate data are used. 

- **RDMA Read/Write** vs **send/receive**:

    - For RDMA write/read data transfers directly into/out of pre-registered memory regions without
      requiring a Work Request in Host B's Receive queue. 
    - For RDMA Send, a work Request must be posted to Host B's Receive Queue (RQ) ahead of time. 

A complete flow diagram: (with two-way asynchronous notification )
```mermaid 
flowchart LR
    %% Styles
    classDef host fill:#eef0ff,stroke:#5b5bd6,stroke-width:2,color:#333;
    classDef queue fill:#ffffff,stroke:#5b5bd6,stroke-width:1.5,color:#333;
    classDef hostB fill:#e9f7f2,stroke:#2d9c7a,stroke-width:2,color:#333;
    classDef queueB fill:#ffffff,stroke:#2d9c7a,stroke-width:1.5,color:#333;
    classDef note fill:#f5f3ef,stroke:#999,stroke-dasharray: 5 5,color:#333;

    subgraph HostA["Host A (Initiator)"]
        direction TB
        subgraph QPA["Queue Pair (QP A)"]
            SQ_A["**Send Queue (SQ)**<br/>Post Work Requests"]
            RQ_A["**Receive Queue (RQ)**"]
        end
        CQ_A["**Completion Queue (CQ A)**<br/>Notifies App A"]
    end

    subgraph HostB["Host B (Responder)"]
        direction TB
        subgraph QPB["Queue Pair (QP B)"]
            SQ_B["**Send Queue (SQ)**"]
            RQ_B["**Receive Queue (RQ)**<br/>Buffer for incoming Send"]
        end
        CQ_B["**Completion Queue (CQ B)**<br/>Notifies App B"]
    end

    N["**Kernel Bypass & Zero-Copy**<br/>NIC accesses registered app memory directly"]

    %% Network Connections
    SQ_A == "RDMA Write / Read<br/>(Direct Memory Access)" ==> HostB
    SQ_A == "RDMA Send" ==> RQ_B

    %% Internal associations
    SQ_A -. Completion .-> CQ_A
    RQ_B -. Completion .-> CQ_B

    class HostA host;
    class SQ_A,RQ_A,CQ_A queue;
    class HostB hostB;
    class SQ_B,RQ_B,CQ_B queueB;
    class N note;
```

**What is inside Queue Pairs**:

Each Queue Pair has:

- **Send Queue (SQ)**: Work requests: "read this memory", "write to remote memory", "send this message",
  each entry is a work queue element (**WQE**)

- **Receive Queue (RQ)**: buffers pre-posted so incoming data has somewhere to land.

- **Completion Queue(CQ)**: Where the app polls ( or gets interrupted ) to know a WQE finished.

**Three transport modes matter**:

- **RC (reliable connected)**: Like TCP's reliability guarantee, but HW enforced: Ordering, ACKs,
  retransmission, all in silicon. Used for most storage/ML traffic. 

- **UC (un-reliable connected)**: no retransmission lower overhead. 

- **UD ( Unreliable Datagram )**: Connectionless, used for things like milticast. 


**Memory Registration**: This is the other half:

Before any RDMA operation, a memory region must be registered with the NIC, which pins it and returns keys
(`lkey` for local access, `rkey` for a remote peer to reference ). 
The NIC's Memory Translation Unit (from your original map(below)) is what makes "remote peer writes into my
virtual address space" safe it translates and validates that access in HW, per operation, without a
CPU-mediated page fault... unless ODP (On-Demand Paging) is in play, which lets registered memory be
swappable and let the NIC fault it in.

**This forces "lossless Ethernet"**: 

- TCP survives packet loss because retransmission is cheap relative to total flow duration and the CPU is
  already already in the loop managing state per-connection. i.e TCP uses CPU cycles to manage complex
  retransmission windows; RDMA offloads this to NIC silicon, making packet loss recovery expensive.

- In std RoCEv2 hardware transport historically uses *Go-Back-N* retransmission. If a single packet drops,
  the entire transmission window is thrown out and retransmitted from that sequence number onward. In a
  high-throughput cluster, a tiny drop rate causes throughput to collapse instantly.

- RDMA's whole value proposition is removing the CPU from that loop  which means loss recovery in hardware
  is either very limited (drop the whole connection) or very expensive (large retransmission windows
  implemented in silicon). So instead, RoCE (RDMA over Converged Ethernet) leans on the network itself not
  dropping packets:

**Lossless Mechanisms (PFC, ECN, DCQCN)**

  * **PFC (Priority Flow Control, 802.1Qbb)**: works are L2 by sending pause frames on specific Priority
    queues (DSC/CoS mapped). It prevents queue overflows, but trades packet drops for link-level delay.
    A switch can pause a specific traffic class on a link before its buffer overflows, instead of dropping.

  * **ECN and DCQCN**: Serves as the proactive congestion manager before PFC reactively slams the breaks.
    - Switch marks **CE (Congestion Experienced)** bit in IP header when queues build up.
    - Receiver NIC detects CE and sends a CNP (Congestion Notification Packet) back to the sender NIC.
    - Sender NIC’s hardware rate-limiter throttles the specific Queue Pair (QP).

  * So **ECN (Explicit Congestion Notification)**: marks pkts approaching congestion rather than dropping
    them.
  * DCQCN (Data central quantized congestion Notification) the end-to-end congestion control loop: NIC sees ECN marks on received packets → tells the sender via CNP (Congestion Notification Packets) → sender's rate limiter throttles that flow, then slowly ramps back up. This runs in the NIC's hardware/firmware, not in TCP's software congestion window.

**RoCEv1 vs. RoCEv2** 

- **RoCEv1**: `EtherType` `0x8915`. L2-only, requires hosts to be in the same Layer 2 broadcast domain. 
  Practically obsolete in scale-out data-centers.

- RoCEv2: Encapsulates RDMA over UDP/IP (UDP Port 4791). Uses the outer IP header for Layer 3 routing and
  the outer UDP source port (computed as a hash of the QP) to allow switch ECMP (Equal-Cost Multi-Path) load
  balancing.

The catch: and this is a known operational headache, is that PFC operates per-priority-class on a link, so a
slow receiver can cause head-of-line blocking or even PFC deadlocks cascading backward through a fabric.
This is why RoCE deployments need carefully tuned lossless fabrics (DCB configuration end to end), unlike
standard Ethernet where you just let TCP handle loss.

One more distinction worth locking in: RoCEv1 is Ethernet-layer only (not routable), RoCEv2 wraps RDMA in
UDP/IP (routable across L3, which is why it's what's actually deployed today).

**Mental Model**: 

- `RoCE architecture`: 
        RDMA Transport Layer ( Go Go-Back-in HW )
             + RoCEv2 Encapsulation ( UDP/IP for L3 Routing )
             + PFC ( Lossless network Assurance )


**RoCE**:

RDMA over Converged Ethernet, this is a network protocol that enabled RDMA over standard Ethernet and IP
network. ( this is the key component that allows servers and GPUs to directly read and write to each
others memory without the involving the CPU or the OS kernel, it delivers sub-micro second latency and
massive throughput crucial for modern AI training and HPC).

Looking at the actual bytes on the wire will clarify why RoCEv2 exists at all.

**Core Problem: IB Transport header didn't originally know about Ethernet or IP** 

- RDMA's transport semantics (QP numbers, seq numbers, ACKs, opcodes) come from Infiniband. IB was its
  own fabric with its own L2/L3. RoCE is taking that IB transport layer and carrying it over Ethernet
  instead. 

- The two RoCE versions differ in how much of the IB/Ethernet/IP stack sits underneath that transport hdr.

- 
```txt 
RoCEv1 frame:

    [  Ethernet hdr  ][  Ethertype 0x891  ][  IB transport (BTH) ][  Payload  ][  CRC ]
    No IP layer: link-local only, not routable across L3.

RoCEv2 frame:
    [  Ethernet hdr  ]  [  IPv4/IPv6   ][     UDP (4791)     ][   Payload  ][  CRC ]
                          |                       |
                   ECN bits here              Src port varies 
                ( routable, DCQCN marking )   per flow (ECMP hash)

    Same IB transport header and QP semantics in both, only the underlay changed. 
```
```mermaid 
flowchart LR
    A["Ethernet Header<br/>14 bytes<br/>Dst MAC | Src MAC | EtherType"]
    B["Optional VLAN Tag<br/>4 bytes<br/>802.1Q PCP/VID"]
    C["IP Header<br/>20/40 bytes<br/>IPv4 or IPv6<br/>Protocol = UDP"]
    D["UDP Header<br/>8 bytes<br/>Dst Port = 4791"]
    E["RoCEv2 BTH<br/>12 bytes<br/>Opcode | P_Key | Dest QP | PSN"]
    F["Optional RDMA Headers<br/>RETH / AETH / DETH / Atomic ETH"]
    G["RDMA Payload<br/>Application Data"]
    H["ICRC<br/>4 bytes"]
    I["Ethernet FCS<br/>4 bytes"]

    A --> B --> C --> D --> E --> F --> G --> H --> I
```

The Encapsulation looks as below:
The RoCEv2 pkt is an ethernet/ip/udp wrapper carrying IB transport-layer semantics. 
The Encapsulation looks as below: 

```txt 
+------------------------------------------------+
| Ethernet Header                                |
|  Dst MAC | Src MAC | EtherType                 |
+------------------------------------------------+
| IP Header                                      |
|  Src IP | Dst IP | ECN bits                    |
+------------------------------------------------+
| UDP Header                                     |
|  Src Port | Dst Port = 4791                    |
+------------------------------------------------+
| InfiniBand Transport Headers (RoCEv2)          |
|  BTH + optional RETH/AETH/DETH/etc.             |
+------------------------------------------------+
| RDMA Payload                                   |
|  Data being transferred                        |
+------------------------------------------------+
| ICRC                                           |
+------------------------------------------------+
| Ethernet FCS                                   |
+------------------------------------------------+
```
the key difference with native IB is the network layer transport:

| Native InfiniBand    | RoCEv2                    |
| -------------------- | ------------------------- |
| IB Link Layer        | Ethernet                  |
| IB LID addressing    | IP addressing             |
| IB routing           | IP routing                |
| IB link packets      | UDP/IP packets            |
| IB transport headers | Same IB transport headers |

RDMA operations themselves are still based on IB protocols:
- QP 
- Work Requests/ Work completions 
- BTH  ( base transport header )
- RETH ( Remote extended transport header )
- AETH ( Ack extended transport header )
- PSN  ( packet seq number )
- R_Key / Remote Virtual Address 

**Routability**: 
RoCEv1 rides straight on Ethertype `0x8915` No IP header at all. Which means it can not cross a router,
works only within a single L2 broadcast domain. ( not useful for data center fabric spanning leaf-spine
switches.)

RoCEv2 wraps the exact same IB transport header inside a UDP/IP pkt, so std L3 routing and ECMP work on it
like any other IP traffic. This is why essentially no one deploys v1 in production anymore. 

**Why UDP and not raw IP?** 
- UDP source port is used purely as flow entropy: RoCEv2 doesn't use ports for multiplexing services like
  normal UDP does. It's varied per-QP/per-flow so that ECMP hashing across multiple equal-cost paths spreads
  different RDMA flow across different links, the same way it would for any other L4 flow. 

- Destination port is fixed at 4791 that's how a receiving NIC recognizes "this UDP packet is actually
  RoCEv2," and hands it to the RDMA transport logic instead of a normal socket.

Where DCQCN's ECN marking actually lives:

Your earlier question about the congestion loop the ECN bits it depends on are literally the IP header's 
ECN field. 
RoCEv1 has no IP header, so it has no ECN field, so DCQCN as commonly deployed is a RoCEv2-only mechanism. 

That's a hard architectural reason v2 won, not just a preference.

Addressing model: GIDs. 
RDMA doesn't address peers directly by IP; it uses a GID (Global Identifier), a holdover from InfiniBand's 
addressing. The difference between v1 and v2 is what the GID is derived from: in
v1 it's built from the MAC address (link-local); in v2 it's an IPv4-mapped or native IPv6 address. So when
your application does address resolution (via rdma_resolve_addr in the verbs API), what's actually happening
under the hood is: IP address → ARP/neighbor discovery → GID → which RoCE version's semantics apply.

Note : because the QP/transport logic is identical in both, a CX-5 doing RoCEv2 isn't running fundamentally
different silicon for the RDMA half, it's the same match/parse/steer hardware from your original map (packet
parser, flow steering engine) now also recognizing UDP:4791 and handing that off to the RDMA transport
engine instead of the normal Ethernet RX path.

NIC's flow steering engine actually demuxes RoCEv2 traffic to QPs at hardware speed.


---

NOTE: 
- Biggest mistake people make when learning SmartNIC is treating them as "Just a Fast NIC". A ConnectX-5
  is actually a programmable network processor with firmware, DMA engines, schedulers, packet parsers,
  memory translation HW, and command processors. 
- Linux driver is primarily a manager of these HW blocks rather then the component that processes every
  packet. 

Mental Model to study layer by layer:

```
+-----------------------------------------------------+
| User Space                                           |
| ip, ethtool, rdma-core, DPDK, SPDK, OVS              |
+-----------------------------------------------------+
| Kernel Networking                                    |
| TCP/IP, Netfilter, XDP, TC, RDMA stack               |
+-----------------------------------------------------+
| mlx5_core / mlx5e / mlx5_ib drivers                  |
+-----------------------------------------------------+
| PCIe Interface                                       |
+-----------------------------------------------------+
| ConnectX-5 Firmware                                  |
| Command Processor                                    |
| Resource Manager                                     |
| Flow Steering                                        |
| Queue Scheduler                                      |
| Event Manager                                        |
+-----------------------------------------------------+
| ConnectX-5 Hardware                                  |
| RX/TX DMA                                            |
| Packet Parser                                        |
| Match Engine                                         |
| Queue Engines                                        |
| Interrupt Logic                                      |
| PCIe DMA                                             |
| Memory Translation                                   |
+-----------------------------------------------------+
```

## 1.0 HW Components: 

Ignoring PHYs and analog circuitry, the major digital HW blocks inside a ConnectX-5 are approximately:


### PCIe Interface:

Responsible for:
- PCIe enumeration
- BAR mapping
- MSI-X 
- DMA transactions 
- Doorbell reception

Linux sees this as a PCIe endpoint. 


### Embedded Processor:

CX-5 Contains embedded CPUs ( not user-programmable in general sense ).

These processors execute firmware:

**Firmware Performs**:
- Initialization
- Command execution 
- Resource allocation
- Error recovery
- device configuration

Linux Driver never directly manipulates most HW registers, Instead the drivers sends commands to
firmware. 

### DMA Engine:

Copies pkts between:

```mermaid
flowchart LR 
    A[ NIC Memory ] --> B[ Host DRAM ]

    classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
    classDef blue fill:#2196da,stroke:#1565C0,stroke-width:2px,color:#fff;

    class A green;
    class B blue;
``` 
Without CPU involvement. 

DMA performs:
- RX writes
- TX reads
- Completion Queue updates.

### Queue Engine:

Maintains:

```mermaid 
flowchart LR
    RQ["Receive Queue (RQ)"] --> SQ["Send Queue (SQ)"] 
    SQ --> CQ["Completion Queue (CQ)"] 
    CQ --> EQ["Event Queue (EQ)"]
    classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
    classDef blue fill:#2196da,stroke:#1565C0,stroke-width:2px,color:#fff;
    class RQ,CQ green;
    class SQ,EQ blue;
```
Each Queue is actually a Circular Buffer in Host memory.
HW walks these buffers directly. 

### Pkt Parser: 

Examines Incoming pkts:
Extracts:

```mermaid
flowchart  
    A["VLAN"] 
    B["IPv4"] 
    C["IPv6"] 
    D["TCP"] 
    E["UDP"] 
    F["VXLAN"] 
    G["GENEVE"] 
    H["GRE"]
    classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
    class A,B,C,D,E,F,G,H green;
```
Produces metadata. 

--- 

### Flow Steering Engine:

HW lookup engine:

Matches:
```mermaid 
flowchart 
A[IP] 
B[Port] 
C[Tunnel] 
D[Metadata] 
E[VLAN]

classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E green;
```

Determines: 
```mermaid 
flowchart
A[Drop] 
B[Forward] 
C[RSS] 
D[RDMA] 
E[HairPin] 
F[Send to Queue]

classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G,H green;
```
This is why SmartNICs can process pkts without CPU intervention. 

### Scheduler:

Schedules transmission.
Responsible for: 
- QoS 
- Rate limiting 
- Traffic Classes 
- Priority

### Interrupt/Event Engine:

Produces:

```
- Completion Interrupts 
- Async Events 
- Errors 
- Port Changes 
- Temperature alarm

```
Delivered through MSI-X. 

### Memory Translation Unit:

Similar to the concept of IOMMU:

Translates: 
```mermaid 
flowchart LR
    A["Virtual Address"] --> B["DMA Addresses"]
    classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
    classDef blue fill:#2196da,stroke:#1565C0,stroke-width:2px,color:#fff;

    class A green;
    class B blue;
```
Supports: 
- Memory Registration
- RDMA 
- ODP 

## 2.0 Firmware Responsibilities:

Firmware is effectively the operating system of the NIC. 
Firmware manages **Initialization** during Boot:

```mermaid 
flowchart LR
PCI["PCI Reset"] --> FB["Firmware boots"]
FB --> HW["Initialize HW"]
HW --> DRV["Wait for OS Driver"]

classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class PCI,FB,HW,DRV green;
```

### Command Processing: 

Drivers sends commands like :
```mermaid 
flowchart
    CQ["Create CQ"] 
    SQ["Create SQ"] 
    RQ["Destroy RQ"] 
    AFT["Alloc Flow Table"] 
    RM["Register Memory"]
    QP["Modify QP"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class CQ,SQ,RQ,AFT,RM,QP green;
```

Firmware validates them.

Allocates hardware resources.

Returns IDs.

### Resource Tracking:

Firmware Owns:
```mermaid 
flowchart 
    A["Queue IDs"]
    B["Flow IDs"]
    C["Memory Keys"]
    D["PDs"]
    E["EQs"]
    F["Interrupt vectors"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F green;
```

### Error Recovery:
Firmware detects:
```mermaid 
flowchart 
    A["ECC"]
    B["DMA timeout"]
    C["Link faults"]
    D["PCIe errors"]

classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D green;
```
Notifies Driver.

### Link Management: 

Negotiates:
```mermaid 
flowchart
    A["100G"] 
    B["40G"]
    C["25G"]
    D["10G"]
    E["FEC"]
    F["Autoneg"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F green;
```
Driver only requests changes.

## 3.0 Driver Components: 

The `mlx5` driver is split into several modules.
```mermaid 
flowchart 
    A[mlx5_core]
    B[mlx5e]
    C[mlx5_ib]
    D["mlx_fpga (older)"]
    E[mlx5_vdpa]
    F[mkx5_sf]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F green;
```

### `mlx5_core` :

Main PCI driver 

Responsible for
```mermaid
flowchart 
    A["PCI probe"]
    B["Firmware commands"]
    C["Interrupts"]
    D["Queue allocation"]
    E["Memory mapping"]
    F["Doorbells"]
    G["Events"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G green;
```
Think of it as the kernel interface to firmware.

### `mlx5e`:

Ethernet Driver
Creates: 
```mermaid 
flowchart
    A["net_device"]
    B["ndo_start_xmit()"]
    C["NAPI"]
    D["RSS"]
    E["XDP"]
    F["TC"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G green;
```

### `mlx5_ib` :

Implements
```mermaid 
flowchart 
    A["RDMA"]
    B["RoCE"]
    C["InfiniBand Verbs"]
```

## 4.0 Driver Initialization Sequence: 
Very roughly:
```mermaid 
flowchart TD
    A["PCI discovers device"] --> B["mlx5_core_probe()"]
    B --> C["Map BAR"]
    C --> D["Firmeare handshake"]
    D --> E["Read capabilities"]
    E --> F["Allocate Command queues"]
    F --> G["Allocate Event queues"]
    G --> H["Initialize Interrupts"]
    H --> I["mlx5e loads"]
    I --> J["Register net_device"]
    J --> K["ip link shows interface"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G,H,I,J,K green;
```

## 5.0 Pkt Receive Path: 

This is probably the most useful thing to understand.

```mermaid 
flowchart TD 
    A["Pkt arrives"] --> B["MAC"]
    B --> C["Parser"]
    C --> D["Flow Steering"]
    D --> E["RQ selected"]
    E --> F["DMA packet into host memory"]
    F --> G["CQ entry generated"]
    G --> H["Interrupt ( or Polling)"]
    H --> I["mlx5e_poll_rx_cq()"]
    I --> J["Build sdk"]
    J --> K["netif_receive_skb()"]
    K --> L["Linux networking stack"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G,H,I,J,K,L green;
```
Notice that firmware is not processing every packet.
Firmware is mainly involved in setup.
The HW datapath handles packets.


## 6.0 Pkt Transmit Path:

```mermaid 
flowchart TD
    A["Application"] --> B["TCP/IP"]
    B --> C["ndo_start_xmit()"]
    C --> D["mlx5e"]
    D --> E["Fill SQ descriptor"]
    E --> F["Ring doorbell"]
    F --> G["Hardware DMA reads packet"] 
    G --> H["Transmit"] 
    H --> I["Completion Queue updated"]
    I --> J["Driver frees skb"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G,H,I,J green;
```

## 7.0 Command Path vs Data Path
This distinction is extremely important 

### Command Path**

```mermaid 
flowchart 
    A["Driver"] --> B["Firmware"]
    B --> C["HW configuration"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F,G,H,I,J green;
```

Examples:

```mermaid 
flowchart 
    A["Create queue"]
    B["Destroy queue"]
    C["Allocate memory key"]
    D["Modify flow"]
    E["Set MTU"]
    F["Enable RSS"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F green;
```

### Data Path: 

```mermaid 
flowchart 
    A["Packet"] --> B["Hardware"]
    B --> C["DMA"]
    C --> D["Host memory"]
    D --> E["Driver poll"]
    E --> F["Linux stack"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D,E,F green;
```

Fast Path. 
No firmware involvement.

## 8.0 Important Data Structures in the Driver: 

Common structures in the mlx5 driver source:

- `struct mlx5_core_dev` – Represents the device and holds global state.
- `struct mlx5_eq` – Event Queue.
- `struct mlx5_cq` – Completion Queue.
- `struct mlx5e_rq` – Receive Queue.
- `struct mlx5e_sq` – Send Queue.
- `struct mlx5e_priv` – Ethernet driver private context.
- `struct mlx5_cmd` – Command interface to firmware.

Learning how these relate to one another provides a solid map of the driver's architecture.

## 9.0 Suggested Learning Order

To build an understanding that maps hardware, firmware, and the Linux driver together:
1. PCI enumeration and probe (mlx5_core).
2. Firmware command interface (how the driver creates and destroys resources).
3. Queue objects (SQ, RQ, CQ, EQ) and their lifecycle.
4. Doorbells and DMA (how the driver notifies the NIC and how the NIC accesses host memory).
5. Receive and transmit packet paths.
6. Flow steering and RSS.
7. RDMA-specific concepts (Queue Pairs, Completion Queues, Memory Registration, etc.).

By this it gets clear that the driver does less "packet processing code" and more as a control plane that
programs the NIC, while the CX5 HW hardware executes the data plane at line rate. 

For CX5 internals with Linux `mlx5` driver the next step is walk through the driver source file by file
from `mlx5_core` PCi probe, through firmware initialization, queue creation, and finally the RX/TX data
paths. 
Next is mapping each major function to the HW block or firmware service it configures. This approach
makes the interactions between HW, firmware and driver much easier to understand.
