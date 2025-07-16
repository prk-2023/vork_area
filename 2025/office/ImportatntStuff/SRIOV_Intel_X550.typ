#let articleTitle = "Rust Ownership with examples"

#align(right)[
  #heading(articleTitle)
  #line(length: 50%, stroke:(paint: black))
]
#show outline.entry: it => link(
  it.element.location(),
  it.indented(it.prefix(), it.body()),
)
#set heading(numbering: "1.")
#outline()
#pagebreak()

#line(length: 100%, stroke:(paint: red))
= Introduction to SRVIO

*Single Root I/O Virtualization (SR-IOV)* technology allows a single physical PCI Express (PCIe) device, 
such as a network interface card (NIC), to appear as multiple separate virtual devices. 

It's widely used in virtualization environments to improve performance by reducing overhead in the I/O path
between virtual machines (VMs) and physical devices.


*SR-IOV is not just for network controllers*, but network interface cards (NICs) are the *most common use 
case* because they benefit significantly from performance gains in virtualization.

- SR-IOV is a *PCI Express (PCIe) standard*, meaning it's a general-purpose mechanism for sharing *any PCIe
  device* among multiple virtual machines. 

  However:
  - *Most implementations focus on NICs*, because:
    - Networking is performance-sensitive.
    - NICs are relatively easy to virtualize with clean separation between data paths.

  - *Other PCIe devices* can support SR-IOV, including:
    - *Storage controllers* (e.g. NVMe SSDs)
    - *FPGAs*
    - *InfiniBand adapters*
    - *GPUs* (less common due to complexity, but possible)

- Why NICs Are the Primary Use Case:
  - *High throughput requirements* in cloud and data center environments.
  - *Latency-sensitive applications* (VoIP, trading systems).
  - *Well-developed driver ecosystem* in guest OSs.

#line(length: 100%, stroke:(paint: red))

=== What SR-IOV Does

Without SR-IOV:

- All VM network traffic goes through the hypervisor.
- The hypervisor has to switch packets between VMs and the physical NIC, which adds latency and CPU overhead.

With SR-IOV:

- The NIC is split into multiple *Virtual Functions (VFs)*.
- Each VF can be assigned directly to a VM.
- The VM communicates with the NIC *bypassing the hypervisor*, which reduces latency and CPU usage.


=== SR-IOV Components

#table(columns:3,
table.header[ Component ][Description ],
  [ *Physical Function (PF)* ],
    [ The full-featured PCIe function with config and mgmt capability. Controlled by the hypervisor. ],
  [ *Virtual Function (VF)*  ],
    [ Lightweight PCIe functions with limited configuration. Assigned to VMs.], 
  [ *Hypervisor* ],
    [ Manages PFs, assigns VFs to VMs, and controls access],
  [ *VM/Guest OS* ],
    [ Sees a VF as a regular network interface. Needs drivers that support SR-IOV.]
) 

=== How It Works

1. The hypervisor enables SR-IOV on a physical NIC.
2. The NIC exposes multiple VFs.
3. Each VF is mapped to a VM.
4. The VM uses a VF to send/receive network traffic directly.

=== Benefits

- *Performance*: Reduced latency and higher throughput.
- *Efficiency*: Lower CPU overhead on the host.
- *Scalability*: Multiple VMs can share one NIC with near-native performance.

=== Considerations and Limitations

- *Hardware Support*: Both NIC and platform must support SR-IOV.
- *Guest OS Support*: VM OS must have SR-IOV-compatible drivers.
- *Migration Complexity*: Live migration of VMs using SR-IOV can be complex or unsupported.
- *Security*: Direct hardware access can reduce isolation if not properly managed.

===  Common Use Cases

- High-performance networking in data centers and cloud environments.
- Network Function Virtualization (NFV).
- Latency-sensitive applications in VMs (e.g., trading platforms, VoIP).


== SR-IOV In Context of network interface controller (NIC Intel X550 design).


- What Is SR-IOV?

➤ *SR-IOV (Single Root I/O Virtualization)* is a *PCI Express (PCIe) standard* that allows a 
  *single physical device (like a NIC)* to *appear as multiple separate devices* to the system, without
  physically duplicating hardware.

- Goal of SR-IOV is to allow *direct, isolated access to hardware resources* (like network queues) by
  multiple machines (VMs) or containers while maintaining high throughput, low latency, and strong isolation
  *bypassing the hypervisor's software stack.*

- How It Works (Conceptually):
  Imagine slicing a physical NIC into *many lightweight "virtual NICs"*, each with its own:
  - PCI function (in hardware)
  - DMA queues
  - Interrupts (MSI-X)
  - MAC filters
  - Configuration space

  These slices are called *Virtual Functions (VFs)*.

  There’s also one *Physical Function (PF)* — the main function that configures the VFs.

- SR-IOV Architecture Overview

#table(columns:2, 
table.header[ Component][ Role ],
[ *PF (Physical Function)*          ],
  [ Full-featured PCI function with full control; visible to host OS  ],
[ *VF (Virtual Function)*           ],
  [ Lightweight PCI functions mapped to guests/VMs; fast and isolated ],
[ *Hypervisor or Host OS*           ],
  [ Creates and assigns VFs using PF                                  ],
[ *Guest OS*                        ],
  [ Sees VF as a standard PCI device and uses it like a real NIC      ],
[ *NIC Hardware (e.g., Intel X550)* ],
  [ Implements the queues, filters, and DMA for each VF in silicon]
)

- Flow Overview (Simplified)

  1. *BIOS/Host enables SR-IOV* in firmware
  2. *Host PF driver (ixgbe)* initializes NIC and *creates VFs* via sysfs:

    echo 4 > /sys/class/net/eth0/device/sriov_numvfs

  3. *Each VF appears as a PCI device* \( e.g., 0000:03:10.1 \)
  4. *Hypervisor assigns VF* to VM or container  via libvirt, VFIO,SR-IOV CNI 
  5. *Guest OS loads VF driver \(ixgbevf\)* and uses it as a high-performance NIC.


- Benefits of SR-IOV

#table(columns:2,
table.header[Benefit][Description],
[ *Performance*     ],[ Bypasses hypervisors software switch ; line-rate throughput ],
[ *Low latency*     ],[ Packets go direct from NIC to VM memory via DMA             ],
[ *Isolation*       ],[ Each VF has isolated queues, MAC filters, interrupts        ],
[ *Scalability*     ],[ Supports up to 64 VFs per NIC (Intel X550)                  ],
[ *Offload Support* ],[ VFs can use checksum, TSO, RSS — depending on NIC           ] 
)

- Limitations

- *Live migration is hard* (VF is hardware-tied)
- *Needs IOMMU* for secure DMA isolation
- *Not portable* like paravirtual drivers (e.g., VirtIO)
- *Fixed queue logic* – can’t easily modify VF behavior in hardware

- In Intel X550 Context:
  - The NIC *implements SR-IOV in hardware* (not emulated)
  - Each *VF has dedicated TX/RX queues*, MAC/VLAN filters, and MSI-X interrupts
  - *Guest OS sees VF as a PCI NIC* and uses "ixgbevf" driver
  - Combined with *XDP/eBPF*, you can still attach programmable packet logic per VF


= SR-IOV Introduction Based on Intel X550

*SR-IOV (Single Root I/O Virtualization)* technology allows a single physical network interface to appear 
as multiple separate virtual devices to a hypervisor or OS. 
This is essential in virtualized environments to achieve near-native performance for virtual machines (VMs).

1. *What is SR-IOV?*

- SR-IOV enables 1 physical PCIe device (ex a network adapter) to expose *multiple virtual functions (VFs)*.
- These VFs can be *directly assigned to VMs*, bypassing the SW-based virtual switch, which significantly
  reduces latency and CPU overhead.

---

== *Intel X550 Overview*

*Intel X550* is a *10 Gigabit Ethernet controller* with native support for SR-IOV. 
It is commonly used in server environments due to its:

- Dual 10GBASE-T ports
- PCIe 3.0 interface
- Support for *SR-IOV* and *VM Direct Path I/O*

== *How SR-IOV Works on Intel X550*

#table(columns:2,
table.header[ Component][Description],
[ *Physical Function (PF)* ],
  [ The full-featured PCIe function seen by the hypervisor. Manages VFs.],
[ *Virtual Functions (VF)* ],
  [ Lightweight PCIe functions for direct assignment to VMs. ],
[ *Intel X550 PF driver* ],
  [ Runs in the host and manages VF creation, configuration, and teardown. ],
[ *Hypervisor (e.g., ESXi, KVM, Hyper-V)* ],
  [ Recognizes the PF and allows VMs to use VFs. 
])

== *Enabling SR-IOV on Intel X550*

To use SR-IOV with an Intel X550 NIC:

==== a. *System Requirements*

- BIOS must support and enable SR-IOV and VT-d (Intel Virtualization for Directed I/O)
- Intel X550 NIC firmware and driver must support SR-IOV
- Hypervisor must support PCI passthrough and SR-IOV

==== b. *Steps*

 1. *Enable VT-d and SR-IOV* in BIOS
 2. Load the *ixgbe* or *ixgbevf* driver (Intel's driver for X550)
 3. Configure number of VFs (e.g., via sysfs on Linux)

  echo 8 > /sys/class/net/eth0/device/sriov_numvfs

4. Assign VFs to VMs using hypervisor tools (e.g. 'virsh', 'virt-manager', vSphere)

== *Benefits of Using SR-IOV on Intel X550*

- *Reduced CPU overhead*: No need for software-based switching
- *Lower latency*: Direct VM access to NIC
- *Higher throughput*: Up to 10 Gbps per VF depending on config
- *Improved isolation*: Traffic for one VM does not interfere with others

== *Use Cases*

- *High-performance virtualized workloads* (e.g., NFV, databases)
- *Low-latency applications* (e.g., financial services)
- *Cloud environments* needing consistent performance

== *Limitations and Considerations*

- Not all features (like traffic shaping or monitoring) are available on VFs
- Some live migration scenarios are *not supported*
- VM-to-VM traffic on same host may need software switching
- Requires *driver support in guest OS*


=  HW Arch of *Intel X550* Ethernet controlleri

It's a dual-port 10 Gigabit Ethernet (10GbE) controller that supports advanced features like *SR-IOV*, 
*VM Direct Path I/O*, and *PCIe 3.0*. 

To understand how it supports *multiple virtual interfaces* in hardware, we need to look at the 
architectural design of the Intel X550.

== Intel X550 Hardware Architecture – Detailed View

The Intel X550 is designed to *virtualize I/O at the hardware level*, allowing one physical NIC to appear 
as many *logical or virtual NICs*. 
This is accomplished through *multi-queue support*, *PCIe multi-function capabilities*, and 
*virtualization-aware DMA engines*.

=== 1. Core Components in Intel X550

#table(columns:2, 
table.header[Component][Function],
[ *MAC (Media Access Control)*       ],[ Two independent 10G MACs – one per port                                      ], 
[ *PHY (Physical Layer Transceiver)* ],[ 10GBASE-T (copper) for direct connection to Ethernet networks                ], 
[ *PCIe Interface*                   ],[ PCIe Gen3 x8 for high-bandwidth communication with host                      ], 
[ *DMA Engines*                      ],[ Perform data transfers to/from system memory with support for virtualization ], 
[ *Packet Buffers and Queues*        ],[ TX and RX queues per port, scalable with VFs                                 ], 
[ *SR-IOV Engine*                    ],[ Hardware logic to virtualize the device into multiple functions              ], 
[ *Interrupt Management*             ],[ MSI/MSI-X support for scalable interrupt delivery per VF/queue               ], 
[ *Switch Fabric (Internal)*         ],[ For separating traffic between PF and VFs internally                         ]) 

=== 2. How the Intel X550 Supports Multiple Interfaces (via SR-IOV)

Step-by-Step Design Overview

==== a. PCIe Multi-Function Capability

- The X550 exposes a *Physical Function (PF)* and can create multiple *Virtual Functions (VFs)*.
- Each VF has its own *PCI configuration space*, BARs (Base Address Registers), and DMA paths.
- The hardware design allows the *PF driver in the host OS or hypervisor* to configure and manage these VFs.

==== b. Internal Queues and Buffering

- For *each VF*, the X550 allocates *dedicated TX and RX queues*.
- These queues are managed by *hardware schedulers* that ensure each VF gets fair access to the PCIe and MAC resources.
- This enables *traffic isolation*, *QoS*, and *multi-tenant support*.

==== c. DMA Engine with Address Translation

- Each VF uses a separate *DMA context*.
- X550 includes *IOMMU (or VT-d) hooks*, enabling safe mem mapping from guest VM space to host physical mem.
- Data is transferred directly between guest VM memory and the NIC without host CPU intervention (bypass of
  hypervisor data path).

==== d. Interrupt Isolation

- X550 supports *MSI-X*, allowing *per-VF interrupt vectors*.
- Each VF can independently generate interrupts to the guest VM, ensuring *low latency* and *better 
  performance scaling*.

==== e. Internal Switching (Optional)

- Some virtualization environments may enable internal *packet switching* between VFs (eg: VM-2-VM traffic).
- This is limited and often handled by the *hypervisor*, but the X550 design provides necessary hooks.

=== SR-IOV Hardware Support Summary in Intel X550

#table(columns:2,
table.header[Feature][ Supported in X550 ],
[ PCIe Gen3                    ],[  (8 lanes)                                  ], 
[ Number of VFs per port       ],[  Up to 64 (total across both ports)         ], 
[ MSI-X per VF                 ],[  Yes                                        ], 
[ Queues per VF                ],[  At least 2 (TX and RX), often configurable ], 
[ DMA isolation                ],[  Yes (per VF)                               ], 
[ Link and Flow Control per VF ],[  Basic support                              ], 
[ VLAN and Filtering per VF    ],[  Hardware-enforced filtering                ]) 

=== Benefits of Hardware-based Multi-interface Support

- *Near-native VM performance*
- *Full isolation between VMs*
- *Lower CPU overhead on host*
- *Better scalability for multi-tenant environments*

=== Example Hardware Flow: Packet from VF to Wire

1. VF in VM writes packet to its TX queue in memory.
2. DMA engine in X550 reads packet using IOMMU translation.
3. Packet is queued in hardware TX scheduler.
4. Packet is transmitted via the appropriate MAC (Port 0 or 1).
5. If incoming packet is for a VF, it is demuxed based on MAC/VLAN filtering and placed in that VF’s RX queue.


=== Block Diagram (Textual Representation)

```
                   +------------------------+
                   |     Host Memory        |
                   |  (PF + VF Buffers)     |
                   +-----------+------------+
                               |
                               | PCIe Gen3 x8
                               |
             +----------------+----------------+
             |         Intel X550 Controller   |
             |                                  |
             | +---------+     +---------+      |
             | | PF      |<--->| Config  |      |
             | +---------+     +---------+      |
             | +---------+     +---------+      |
             | | VF[0]   |<--->| DMA Eng |      |
             | +---------+     +---------+      |
             | | VF[1]   |<--->| Queues  |      |
             | +---------+     +---------+      |
             |      ...                        |
             | +---------+                     |
             | | VF[N]   |                     |
             | +---------+                     |
             |       |                         |
             |       +------------------+      |
             |                          |      |
             |       +------------+     |      |
             |       | MAC 0/1    |<----+      |
             |       +------------+            |
             |          PHY 0/1                |
             +---------------------------------+
```

=== Comparision with VirtIO of Linux:

SR-IOV is like giving each VM its own physical NIC interface, carved out from the real hardware.
VirtIO is like sharing the NIC through smart, cooperative software tricks.

Conceptually, both aim to provide a fast virtual network device to VMs.

But SR-IOV (Intel X550) is implemented in HW with PCIe-level granularity, while VirtIO is implemented in 
software via paravirtual drivers.


=== Intel X550 SR-IOV Block Diagram:

```raw
                +-------------------------------------+
                |             Linux Kernel            |
                |                                     |
                | +------------------+               |
                | | PF Driver        |  ixgbe        |<--- Management Interface
                | +------------------+               |
                | +------------------+               |
                | | VF Driver(s)     |  ixgbevf      |<--- VF device drivers in VM or host
                | +--------+---------+               |
                +----------|-------------------------+
                           |
              PCIe Gen3 x8 | (each VF/PF appears as PCI function)
                           v
      +--------------------+-------------------------+
      |                Intel X550 NIC                |
      |                                               |
      |  +------------+     +---------------------+   |
      |  | PCIe Logic |<--->| DMA Engine w/ Queues|<---- TX/RX queues per VF/PF
      |  +------------+     +----------+----------+   |
      |                                |              |
      |               +-----------------------------+ |
      |               |     Virtual Function Logic  | |
      |               +-----------------------------+ |
      |                     PF / VF / MSI-X block      |
      |                                               |
      |     +------------------+   +----------------+  |
      |     |     MAC Port 0   |   |   MAC Port 1   |  |  <-- 10G Ethernet MACs
      |     +--------+---------+   +--------+-------+  |
      |              |                      |          |
      |     +--------v---------+   +--------v--------+ |
      |     |    PHY (10G-T)   |   |   PHY (10G-T)   | |  <-- Copper PHYs
      |     +--------+---------+   +--------+--------+ |
      |              |                      |          |
      +--------------+----------------------+----------+
                     |                      |
                  10GBASE-T             10GBASE-T
                  Ethernet              Ethernet
```

- Phy: 
  Physical layer (bottom layer)
  Converts digital Ethernet frames to electrical signals for 10GBASE-T (copper)
  Interfaces directly with cables and switches

- MAC: 
  Media Access Control layer (data link layer)
  Handles framing, error checking, pause frames, VLANs, etc.
  Each port (0 and 1) has its own dedicated MAC block

- DMA Engine:
  Each PF and VF has access to DMA queues for TX and RX
  Supports descriptor-based transfer of packets to/from host memory

- PCIe Logic:
  Exposes the PF and multiple VFs to the host via PCIe
  Each VF has its own function ID, BARs, interrupts

=== How the Device is Exposed to Linux:

1. PF (Physical Function):
    Shows up as ethX device in Linux using the ixgbe driver
    Manages the creation of VFs via sysfs:
    ```bash 
    echo 4 > /sys/class/net/ethX/device/sriov_numvfs
    ```
    After this, each VF appears as a separate PCI device (e.g., 0000:03:10.1)

2. VF (Virtual Function):
    Uses the ixgbevf driver (in guest or host)
    Shows up as ensXfY or similar interface
    Can be assigned to a VM (via VFIO or libvirt)
    Linux treats each VF as a separate NIC.


===  Can XDP Be Applied?

XDP (eXpress Data Path) is a fast, programmable packet hook that runs in driver context before the kernel 
networking stack.

In Intel X550:
  - XDP can be applied at the PF or VF interface
  - XDP is supported in the ixgbe and ixgbevf drivers (depending on kernel version and driver build)
  - Applied after the packet is DMA'd into system memory, but before netfilter or the TCP/IP stack.

```bash
  NIC RX (VF)                                               
    |                                                       
    v    
  DMA -> Memory Ring Buffer                                 
    |                                                       
    v                                                       
  [ XDP Hook Here ]   <-- XDP runs here (in driver context) 
    |                                                       
    v                                                       
  Kernel Networking Stack (if not dropped or redirected)    
```
- Supported XDP Modes on Intel X550:
    - XDP SKB mode: Always supported
    - XDP DRV mode: Depends on driver support (ixgbe has partial support)
    - XDP ZC (zero-copy): Not supported on X550 (only newer NICs like Intel E810)

=== X550 and AVB Support:

*Audio Video Bridging (AVB)* is a set of IEEE standards (mostly IEEE 802.1Q-2018) designed to provide:

- *Time-synchronized low-latency streaming* of audio and video over Ethernet
- *Deterministic QoS (Quality of Service)* for media traffic
- *Traffic shaping and reservation protocols* (e.g., IEEE 802.1Qav, 802.1AS)

AVB requires hardware and software that supports precise time synchronization and traffic scheduling.

1. Hardware Timestamping
  - The Intel X550 *does support IEEE 1588 Precision Time Protocol (PTP)* hardware timestamping.
  - PTP is essential for synchronizing clocks across network devices, a prerequisite for AVB timing.
  - This capability is exposed through the Linux `ptp4l` and kernel PTP infrastructure.

2. Traffic Shaping and Scheduling

  - AVB also requires *hardware support for scheduled traffic and traffic shaping* at Layer 2 (per-stream 
    bandwidth reservations).
  - Intel X550 *does not natively implement the full AVB TSN (Time-Sensitive Networking) feature set* such 
    as IEEE 802.1Qav credit-based shaper or IEEE 802.1Qbv time-aware scheduler.
  - Some traffic prioritization (802.1p VLAN priority tagging and QoS) is supported but is more basic.

3. Software Stack
  - AVB functionality typically requires the OS/network stack and possibly additional user-space or firmware 
    components to manage stream reservation and scheduling.
  - The Intel X550 relies on software (Linux kernel and user-space tools) to implement much of the AVB 
    control plane.

AVB Feature                         : Intel X550 Support                
----------------------------------- : ------------------------------- 
IEEE 1588 PTP hardware timestamping : Supported                       
Traffic shaping (802.1Qav)          : Not fully supported in hardware
Time-aware scheduling (802.1Qbv)    : Not supported                  
Basic 802.1p priority tagging       : Supported                      
Software AVB stack support          : Dependent on OS and user tools    

- *Intel X550 can participate in AVB networks primarily by providing PTP hardware timestamping*, 
  enabling precise synchronization.
- However, it does not fully support AVB/TSN traffic scheduling and shaping in hardware.
- For full AVB compliance, additional hardware (like specialized TSN switches or NICs with TSN support) or 
  software must be used.
