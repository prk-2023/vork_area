# RDMA : RoCE 


Having **ConnectX-5** (CX5) cards is like having a private lab for the world’s fastest networking.

Structured roadmap designed to take you from "bits here and there" to building and tuning a real RoCE v2 system. 

---

## Phase 1: The "Sandbox" (Simulated / Soft-RoCE)
**Goal:** Master the API without worrying about hardware configuration or cables.
* **Environment:** Any Linux machine (even a VM).
* **Key Concept:** Learning the **Verbs Lifecycle** (Context → PD → MR → CQ → QP).
* **Tasks:**
    1.  **Setup Soft-RoCE:** Use `rdma link add rxe0 type rxe netdev eth0`.
    2.  **Hello World:** Run `ibv_rc_pingpong` (part of `libibverbs-utils`) on a loopback interface.
    3.  **Code Study:** Read the source of `rc_pingpong.c`. It is the "Rosetta Stone" of RDMA programming.
    4.  **Python Exploration:** Use the `pyverbs` library (included in `rdma-core`) to interactively create QPs and MRs in a Jupyter notebook.

---

## Phase 2: Hardware Bring-up (ConnectX-5)
**Goal:** Transition from software emulation to hardware offload.
* **Environment:** Two Linux hosts connected back-to-back (or via a 10/25/100G switch).
* **Steps for your CX5 cards:**
    1.  **Driver Check:** Ensure `mlx5_core` is loaded. Use `ibstat` or `ibv_devinfo` to see the cards.
    2.  **Firmware/Mode:** Use `mlxconfig` to ensure the link type is set to **Ethernet** (`LINK_TYPE_P1=2`).
    3.  **The Handshake:** Configure standard IPv4 addresses on both cards. RoCE v2 uses UDP/IP for routing.
    4.  **Verification:** Run `ibv_ud_pingpong -g 0` (The `-g` flag is mandatory for RoCE to select a GID/IP index).



---

## Phase 3: The "Losing Sleep" Phase (Lossless Networking)
**Goal:** Understand why RDMA fails on standard Ethernet and how to fix it.
* **The Problem:** RDMA assumes a "lossless" fabric. If a standard switch drops a packet, RDMA performance drops to near zero due to retransmission timeouts.
* **Advanced Config (The "Real World" Skills):**
    1.  **MTU 9000:** Enable Jumbo Frames on both hosts (`ip link set dev <dev> mtu 9000`).
    2.  **PFC (Priority Flow Control):** Use `mlnx_qos` to enable PFC on priority 3. This tells the NIC to send "PAUSE" frames if it's overwhelmed.
    3.  **ECN (Explicit Congestion Notification):** Learn to configure the NIC to "mark" packets when congestion starts, so the sender slows down *before* drops happen.

---

## Phase 4: Programming (C and Rust)
**Goal:** Build your own data-mover.
* **Project 1: The Out-of-Band Handshake.** Write a C or Rust program that uses a normal TCP socket to exchange `rkey`, `vaddr`, and `qpn`, then performs one `ibv_post_send`.
* **Project 2: RDMA Read/Write.** Move away from "Send/Receive" (two-sided) and implement a "One-Sided" Write where the client updates a buffer on the server without the server's CPU knowing.
* **Project 3: Rust Safety.** Use the `ibverbs` or `rdma-cm` crates. Focus on how Rust's **Ownership** model handles "Pinned Memory" (which is the hardest part of RDMA).

---

## Phase 5: The "AI & Storage" Tier
**Goal:** See where RoCE is used in 2026.
1.  **NVMe-over-Fabrics (NVMe-oF):** Set up one host as a "Target" (disk server) and the other as an "Initiator." Mount a remote SSD over RoCE and run `fio` benchmarks.
2.  **GPUDirect RDMA (if you have GPUs):** Learn how the CX5 can pull data directly from an NVIDIA GPU's memory.

---

### Suggested Learning Path Order

| Week | Focus | Tool/Command to Master |
| :--- | :--- | :--- |
| **1** | Soft-RoCE & Verbs API | `rdma link`, `ibv_rc_pingpong` |
| **2** | CX5 Hardware & GIDs | `mlxconfig`, `ibv_devinfo -v` |
| **3** | Handshaking & Connect | `librdmacm` (Connection Manager) |
| **4** | Performance Tuning | `mlnx_qos`, `perftest` (ib_write_bw) |
| **5** | Application Design | C/Rust memory registration logic |

--- 

# Roadmap:

Learning smart networking technologies like RDMA (Remote Direct Memory Access), RoCE (RDMA over Converged
Ethernet), InfiniBand, and iWARP requires a combination of understanding high-performance networking
fundamentals, kernel-level programming, and hands-on lab experience with specialized hardware. 

RDMA enables direct memory access between computers without CPU involvement, offering high throughput and
low latency, with RoCEv2 being popular for Ethernet-based AI training and InfiniBand for HPC

## A structured approach to learning these technologies:

1. Core Theoretical Concepts:

- RDMA Basics: Understand the core tenets: Kernel Bypass (avoiding the OS for faster packet processing),
  Zero-Copy (direct memory transfer), and Transport Offloads.
- RDMA Verbs API: Learn the fundamental verbs for RDMA operations: Queue Pairs (QP), Completion Queues (CQ),
  and Memory Regions (MR).
- Protocols Comparison:
    - InfiniBand (IB): High performance, requires dedicated switches and cables.
    - RoCEv2: RDMA over UDP/IP (Ethernet), requires lossless Ethernet configuration (PFC, ECN).
- iWARP: RDMA over TCP/IP, more mature in Wide Area Networks (WAN), but lower performance than RoCE/IB. 

2. Recommended Learning Resources

- NVIDIA Academy: Offers a comprehensive, free course, "The Fundamentals of RDMA Programming," which includes modules on RoCE, InfiniBand, and RDMA coding examples.
- Netdev Tutorials: Search for "Netdev 0x16 - RDMA programming tutorial" for in-depth Linux RDMA interface knowledge.
- Red Hat Documentation: Chapter 1. Introduction to InfiniBand and RDMA in RHEL documentation provides excellent practical guides on configuring Soft-RoCE, iWARP, and IPoIB.
- GitHub Repositories: Explore rdma-core for the user-space libraries and examples (ibverbs). 


- https://academy.nvidia.com/en/course/rdma-programming-intro/?cm=446#:~:text=Introduction%20to%20RoCE%20Introduction%20to,for%20completion%20Cleanup%20RDMA_CM%20Application
- https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_infiniband_and_rdma_networks/understanding-infiniband-and-rdma_configuring-infiniband-and-rdma-networks 
- https://www.naddod.com/blog/infiniband-vs-roce-choosing-a-network-for-ai-data-centers?srsltid=AfmBOoqedPFvL1SpKuDyq4v60CkLQ_vxVVbSSjCYZsZ_9Nh9JYj0h78O#:~:text=Conclusion,in%20AI%20data%20center%20networks.

3. Practical Hands-On Skills

- Setup Soft-RoCE (RXE): If you lack RDMA hardware, use Linux's software implementation of RoCE to practice programming on standard NICs.

- RDMA Programming (C/C++): Learn to write C applications that use libibverbs. Key exercises include implementing "pingpong" tests to measure latency between two machines.
- Lossless Ethernet Configuration: Study how to configure Priority-based Flow Control (PFC) and Explicit Congestion Notification (ECN) on switches, which are essential for RoCEv2.
- Work with Mellanox/NVIDIA ConnectX: Familiarize yourself with mlx5_core drivers and tools like ibv_devinfo, ibv_rc_pingpong, and iperf3. 

- https://aijourn.com/rocev2-vs-infiniband-vs-iwarp-for-infrastructure-deployment-a-technical-comparison-for-large-scale-training-fabrics/#:~:text=InfiniBand%20enables%20fast%20synchronization%20through,workloads%20that%20involve%20frequent%20synchronization.

4. Application-Specific Learning (AI/HPC)
- Distributed AI Training: Understand how RDMA is used for GPU-to-GPU communication (GPUDirect RDMA).
- Storage Networking: Study how NVMe-oF (NVMe over Fabrics) utilizes RDMA to reduce latency in storage networks. 

- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-rdma.html#:~:text=About%20GPUDirect%20RDMA%20and%20GPUDirect%20Storage%0A%0AGPUDirect%20RDMA,or%20BlueField%20DPUs%2C%20or%20video%20acquisition%20adapters. 
- https://www.naddod.com/blog/rdma-accelerates-cluster-performance-improvement#:~:text=Distributed%20training%20with%20multiple%20machines%20and%20GPUs,to%20accelerate%20GPU%20communication%20between%20multiple%20machines.
- https://www.youtube.com/watch?v=wLW3UzUw5rY&t=4s 
- https://intelligentvisibility.com/rdma-roce-iwarp-guide

