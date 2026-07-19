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
- 100G 
- 40G 
- 25G 
- 10G 
- FEC 
- Autoneg
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
    D["Enable RSS"]
classDef green fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
class A,B,C,D green;
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
