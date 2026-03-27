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

