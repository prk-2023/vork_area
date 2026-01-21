# DPDK on Custom HW:


To support the **Data Plane Development Kit (DPDK)** on an embedded platform, you need to move away from
traditional kernel-based networking and toward a "poll-mode" architecture. 

This requires specific configurations across the hardware, kernel, and software layers.

Here are the essential topics you need to address to get DPDK running effectively:

## 1. Hardware & CPU Architecture

DPDK relies heavily on specific CPU features to achieve high throughput.

* **Instruction Set Support:** 
    Ensure your processor (ARMv8, x86, etc.) supports SIMD instructions (like NEON or AVX) which DPDK uses 
    for vectorized packet processing. 

[ Note: 
    - SIMD: Single Instruction Multiple Data
    - vectorized Packet Procecssing(VPP): Vectorized here referes to shifting from a scalar (one-at-a-time)
      approach to a batch (multiple-at-a-time) approach. 
      Linux kernel cpu process one pkt at a time, pulls a pkt from MIC and runs it through the entire stack
      ( Ethernet-> IP -> TCP ) and moves to the next packet.
      In VPP a burst of pkts typically 256 and moves that entire batch through each stage of the processing
      graph together. And SIMD is necessary for this to achieve True Vectorization. 
    - On Intel AVX-512 or ARM's NEON allow a single CPU instruction to perform same operation  on multiple
      data points simultaneously.
]

* **Hugepages:** 
    Standard 4KB memory pages cause frequent TLB misses in high-speed networking. 
    You must configure the system to use **2MB or 1GB Hugepages** to provide large, 
    contiguous chunks of physical memory.

[ Note:
    - There are two ways to setup hugepages: at boot time or runtime. Boot time setup is more stable since
      at runtime allocation the memory is too fragmented. 

    - cmdline args: (Boot time)
        `default_hugepagesz=1G hugepagesz=1G hugepages=4`

    - Runtime: you can reserve 2MB pages on the fly without rebooting:
        `# Reserve 1024 pages of 2MB each (2GB total)`
        `echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`
    - once memory is reserved Kernel needs a way to hand it to DPDK. this is done via special filesystem
      called `hugetlbfs`
      ```
      sudo mkdir -p /mnt/huge 
      sudo mount -t hugetlbfs nodev /mnt/huge 

      Or can be done via fstab entry:
        nodev /mnt/huge hugetlbfs defaults 0 0
      ```
    - Once setup DPDK EAL (environment Abstraction layer) takes over. 
      Below is the lifecycle of a hugepage in DPDK app:
      * memory panning: During initalization, DPDK scans /dev/hugepage and maps that into virual address
        space. 
      * zero-copy: Because hugepages are physically contiguous, DPDK can tell the NIC exactly where to 
        "drop" packets in RAM via DMA (Direct Memory Access). 
        The CPU doesn't have to copy data from kernel space to user space.
      * Mbuf Pools: DPDK carves these hugepages into smaller buffers called rte_mbufs. Every pkt you 
        receive sits in a tiny slice of a hugepage.
      * Multi-process Sharing: Because hugepages are backed by files in /dev/hugepages, two different DPDK
        processes can map the same file to share packet data instantly without expensive IPC 
]

* **Cache Alignment:** 
    Understanding the L1/L2 cache line size (typically 64 bytes) is critical for structuring data to avoid 
    "false sharing."

## 2. Kernel & Driver Configuration

Since DPDK "bypasses" the Linux kernel, you have to change how the OS interacts with your Network Interface
Cards (NICs).

* **UIO or VFIO:** 
    You need to decide on a userspace I/O framework. 
    **VFIO** is the modern standard as it uses the IOMMU for better security and memory protection.

* **Polling vs. Interrupts:** You must disable standard kernel drivers for the target interfaces and bind 
  them to DPDK-compatible drivers like `vfio-pci` or `uio_pci_generic`.

* **IOMMU:** Ensure IOMMU (or SMMU on ARM) is enabled in the BIOS/Bootloader to allow safe DMA mapping 
  from userspace.

## 3. Resource Management (Isolation)

In an embedded environment, resources are limited. 
You must prevent the OS from interfering with DPDK threads.

* **Core Isolation (`isolcpus`):** 
  Use kernel boot parameters to "hide" specific CPU cores from the Linux scheduler. 
  DPDK will then pin its execution threads to these isolated cores.

* **Affinity:** 
  Mapping specific software threads to specific hardware cores to ensure the data stays in the local L1/L2 
  cache.

* **No-HZ Mode:** 
  Configuring the kernel to be "tickless" on isolated cores to prevent timer interrupts from stealing CPU 
  cycles.

## 4. Memory & Buffer Management

* **Mempools and Mbufs:**
  DPDK uses a specialized allocator called a `mempool`. 
  You need to understand how `rte_mbuf` structures store packet metadata and payloads.

* **Zero-Copy Principle:** 
  The goal is to move packets from the NIC to application memory without ever calling `memcpy`.

## 5. The Environment Abstraction Layer (EAL)

The **EAL** is the heart of DPDK that hides the complexity of the underlying hardware. 
You must learn how to initialize it:

* Setting the `-l` (core mask).
* Defining `--huge-dir` (hugepage location).
* Whitelisting/Blacklisting specific PCI devices.

---

### Summary Checklist for Implementation

| Category | Requirement |
| --- | --- |
| **Boot Params** | `default_hugepagesz=1G hugepagesz=1G hugepages=4 isolcpus=1-3` |
| **Dependencies** | Python 3, Meson, Ninja, and `libnuma-dev` |
| **Driver Tool** | Use `dpdk-devbind.py` to switch NICs from kernel to DPDK mode |
| **Compilation** | Cross-compiling for your specific target (e.g., `aarch64-linux-gnu`) |

