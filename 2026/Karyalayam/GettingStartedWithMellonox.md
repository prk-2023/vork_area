# Mellonox: ( Nvidia)

# Introduction 

Mellonox NIC are specialized High Performance adapters designed to deliver maximum throughput and
ultra-low latency in data centers, cloud environments, and HPC clusters. 
They are mainly used to accelerate network traffic, reduce CPU overhead, and enable direct, fast
communication between servers and storage. 
Areas of interest:

- AI and ML:  Heavily used in AI factories and GPU accelerated workloads, such as AI training and
  inference, requiring high bandwidth ( up to 400 Gb/s or 800 Gb/s) and low latency, lossless
  networking transmission. 

- HPC: They are standard in scientific computing, research and technical simulation environments due to
  their support for *InfiniBand* and high-speed Ethernet ( up to 400GbpE )

- Data Center Visualization and cloud: Mellanox NICs are used in public, private, and hybrid clouds to
  accelerate Software-Defined Networking (SDN) and Network Functions Virtualization (NFV).

- Storage Networking (NVMe-oF): They are used to accelerate storage access, supporting technologies NVMe
  over Fabrics (NVMe-oF), which reduces latency when accessing remote storage.

- Remote Direct Memory Access (RDMA): Mellanox NICs support RoCE (RDMA over Converged Ethernet) and
  InifiniBand, allowing data to be transferred directly between the memory of two computers without
  involving the CPU, greatly increasing efficiency.

- Security Offloading: They feature hardware acceleration for security, including in-line encryption and
  decryption (IPsec and TLS) and hardware root-of-trust, to secure data-in-motion.

- SmartNIC/DPU Functionality: They are used as SmartNICs (e.g., ConnectX-6/7/8) to offload network,
  storage, and security tasks from the host CPU, freeing up computing resources.


## Product line and Features:

Their best known product lines include:
- **ConnectX** : Ethernet & InfiniBand Adapters ( ConnectX-5, -6, -7, and -8)
- **BlueField**: SmartNIC / DPU ( data processing unit) that combine network, storage and security
  functions with embedded ARM Core.

- **Spectrum**: Ethernet Switch designed for high-performance networking. 

- **Quantum**: InfiniBank switches.


### Features:

#### 1. Very High Performance:

Compared with typical networking NICs in market from RTK, Intel... 
Mellonox cards Offer:

- 10G, 25G, 40G, 50G, 100G, 200Gm 400G speeds.
- Extremely low latency ( Critical for HPC and Finance )
- High Packet-per-second throughput 
- Advanced Hardware off-loading.

#### 2. RDMA Support:

Mellonox cards are famous for RDMA ( Remote Direct Memory Access )
- Zero-Copy Networking 
- Bypasses kernel networking stack
- Ultra-low latency. 
- Very high throughput.

#### 3. Strong HW Offloading:

They support advanced offloads like:

- TCP segmentation offload (TSO)
- Large receive offload (LRO)
- Checksum offload
- SR-IOV (virtual functions)
- Flow steering
- VXLAN offload
- Geneve offload
- IPsec / TLS offload (newer models)

Making them ideal for:

- Virtualization
- Containers
- Cloud networking
- NFV

#### 4. SmartNIC / DPU Capabilities (BlueField)

BlueField cards are not just NICs — they contain:

- ARM cores
- Their own Linux OS
- On-card processing
- Hardware acceleration engines

They can:

- Run firewall
- Do storage processing
- Handle encryption
- Offload Kubernetes networking
- Act as infrastructure isolation layer

All this are very different from normal NICs below for comparison:

| Feature    | Mellanox      | Typical Intel/Realtek |
| ---------- | ------------- | --------------------- |
| Target     | Datacenter    | Desktop / Enterprise  |
| RDMA       | Yes           | Usually No            |
| Speed      | Up to 400G    | Usually ≤10G          |
| Offloads   | Very advanced | Basic                 |
| DPU option | Yes           | No                    |
| Complexity | High          | Low                   |

---


## Linux Support:

### 1. Driver Stack

Mellanox drivers in Linux:

* `mlx4` (older generation)  ( included in mainline Linux Kernel )
* `mlx5` (modern generation) ( included in mainline Linux Kernel )

For advanced features may require:

* **MLNX_OFED** (Mellanox/NVIDIA's enhanced driver package)

NOTE: You must understand:

* Kernel config options
* Firmware version compatibility
* ethtool
* devlink
* rdma-core

### 2. Firmware Is the key ( Matters A LOT )

Unlike simpler NICs:

* Firmware version must match driver expectations <===
* Features are firmware-gated.
* You often update firmware using:

  * `mstflint`
  * `mlxup`

### 3. `PCIe` Requirements

These cards require:

* High PCIe lanes (x8 or x16)
* Correct PCIe generation (Gen3/Gen4/Gen5)
* Good power supply
* Proper cooling

On embedded boards:

* Lane availability may be limited
* Signal integrity may be an issue
* BIOS settings matter (ACS, SR-IOV, BAR sizing)

---

### 4. Device Tree vs ACPI ( for embedded solutions )

Most Mellanox cards are server-oriented:

* Usually assume x86 + ACPI
* ARM support exists (especially with BlueField)
* Device tree support may require extra care on custom SoCs

---

### 5. RDMA Stack Complexity ( Remote DMA )

If you use RDMA:

You must understand:

* ibverbs
* rdma-core
* queue pairs (QP)
* completion queues (CQ)
* memory registration
* zero-copy design

This is very different from standard socket programming.

### 6. Networking Stack Bypass

With RDMA or DPDK:

* Traffic can bypass kernel networking
* Debugging becomes harder
* `tcpdump` may not see traffic
* Traditional `netfilter` doesn’t apply

As an embedded developer, this impacts:

* Security model
* Debug flow
* System architecture

### 7. Virtualization & SR-IOV

They are heavily used in:

* KVM
* OpenStack
* Kubernetes CNI

You should know:

* Virtual functions (VFs)
* PF/VF driver binding
* IOMMU configuration

---

### 8. Debugging Tools You’ll Use

* `ethtool`
* `devlink`
* `rdma`
* `ibv_devinfo`
* `mlxconfig`
* `perf`
* `tcpdump` (limited use with RDMA)

---

## Summary:

- These cards are NOT a Good Fit if your requirement are:

* You only need 1G/2.5G Ethernet
* Power budget is limited
* PCB space is small
* Cost sensitivity is high
* No need for RDMA/offloads

They may be overkill if your requirements are as above.

- Its to be notes that they are enterprise-class hardware:

* High-performance
* RDMA-capable
* Heavily offloaded
* Data-center oriented
* Complex but powerful

If planning to use with a embedded Linux system for development, the biggest differences are:

* Firmware dependency
* RDMA model
* PCIe requirements
* Debug complexity
* Driver stack depth


------------------

Mellanox (now NVIDIA Networking) is indeed one of the few vendors that supports **Hardware Offload** for 
eBPF/XDP, but it is typically reserved for their "SmartNIC" tier.

While almost all modern Mellanox cards support Native Mode (running in the mlx5 driver), only the newer 
generations support Offload Mode (running on the NIC hardware itself).

### Support by Generation

While almost all modern Mellanox cards support **Native Mode** (running in the `mlx5` driver), only the 
newer generations support **Offload Mode** (running on the NIC hardware itself).

| Card Generation | Driver | Native XDP | Offload XDP |
| --- | --- | --- | --- |
| **ConnectX-3** | `mlx4` | ✅ Yes | ❌ No |
| **ConnectX-4** | `mlx5` | ✅ Yes | ❌ No |
| **ConnectX-5** | `mlx5` | ✅ Yes | ⚠️ Partial (FPGA versions) |
| **ConnectX-6 / 7** | `mlx5` | ✅ Yes | ✅ **Yes** |
| **BlueField (DPU)** | `mlx5` | ✅ Yes | ✅ **Yes** (on the ARM cores/eSwitch) |

---

### How "Offload" Works on Mellanox

On Mellanox hardware, XDP offload is usually tied to the **ASIC's eSwitch** or the **internal processor** 
(in the case of BlueField DPUs).

1. **Direct ASIC Offload:** 

On high-end ConnectX-6/7 cards, the NIC can translate certain BPF instructions directly into hardware 
steering rules.

2. **DPU Offload (BlueField):** 
These cards have actual ARM CPU cores on the NIC. When you "offload" here, the XDP program runs on the 
NIC's ARM cores, completely bypassing the host's x86 CPU.

---

### How to check if your Mellanox card supports it

Even if you have a ConnectX-6, offload might be disabled in the firmware or not supported by your specific 
kernel version. You can check using `ethtool`:

```bash
# Look for 'hw-tc-offload' or 'bpf-can-offload'
ethtool -k enp3s0 | grep offload

```

To attempt to load an XDP program in offload mode on a Mellanox card:

```bash
sudo ip link set dev enp3s0 xdpoffload obj my_prog.o

```

If you get `Netlink answer: Operation not supported`, it means either the **driver**, the **firmware**, or 
the **hardware** version doesn't support true hardware offload.

### A Practical Warning

For "Budget" builds, you will likely find **ConnectX-4** cards on eBay for very cheap ($50). 
While they are amazing for **Native XDP** (very fast!), they **do not** support **Offload XDP**. 
You would need to step up to much more expensive, modern hardware for true offloading.

Would you like to know the difference in "Packet per Second" (PPS) performance between Native and Offload 
modes on this type of hardware?
