# RDMA:  Remote Direct Memory Access

---

## RDMA:

- **RDMA (Remote Direct Memory Access)** is not a physical cable or a specific port; it is a **data
  transfer paradigm**. 

- In traditional networking (TCP/IP), the CPU acts as a "middleman." It must copy data from the
  application, wrap it in headers, and hand it to the NIC. On the receiving end, the CPU does the
  reverse. This consumes CPU cycles and adds "jitter" (latency spikes).

- **RDMA changes the rules:** It allows one computer to read from or write to the memory of another
  computer **directly**, with zero involvement from the remote CPU. Once the "handshake" is done, the
  hardware takes over.

## RoCE:

- **RoCE (RDMA over Converged Ethernet)** is a specific protocol that allows the RDMA paradigm to run over
  standard Ethernet cables and switches.

- Historically, RDMA required specialized **InfiniBand** hardware. RoCE was invented to bring that same
  performance to the Ethernet world you already use. There are two versions:
    * **RoCE v1:** A Layer 2 protocol. It only works if both computers are on the same switch (same
      broadcast domain). It is rarely used today.
    * **RoCE v2:** The modern standard. It wraps RDMA data inside **UDP/IP** packets. Because it has an IP
      header, it can be **routed** across different subnets and data centers. This is what your
      **ConnectX-5** cards use.

---

## How Linux Supports the RDMA Ecosystem

- The Linux kernel doesn't treat RDMA as a "standard" network interface like `eth0`. Instead, it has a
  dedicated **RDMA Subsystem**.

### **The Kernel Side (`drivers/infiniband`)**

- Despite the name, this directory handles all RDMA (InfiniBand, RoCE, and iWARP).
    * **Core Stack (`ib_core`):** The engine that manages memory pinning and protection domains.
    * **Hardware Drivers:** This is where your ConnectX-5 lives. The driver is `mlx5_ib`. It translates
      generic RDMA commands into the specific language the ConnectX-5 hardware understands.
    * **Verbs API:** This is the "language" of RDMA. Instead of `send()` and `recv()`, you use "Verbs" like
      `post_send` and `poll_cq`.

### **The User Space Side (`rdma-core`)**

- Linux provides a set of libraries that allow your C or Rust code to talk to the hardware without going
  through the slow kernel path (Kernel Bypass).
    * **`libibverbs`:** The primary library for data transfer.
    * **`librdmacm`:** The "Connection Manager." Since RoCE v2 uses IP addresses, this library helps you
      find the other computer and set up the initial connection.

---

## Key Differences in the Linux CLI
When you plug in your ConnectX-5 cards, you will see two different "identities" for the same hardware:

| Interface Type | Tool to View | Purpose |
| :--- | :--- | :--- |
| **Ethernet Identity** | `ip link` | Used for standard pings, SSH, and TCP traffic. (e.g., `enp1s0`) |
| **RDMA Identity** | `ibv_devices` | Used for RDMA "Verbs" traffic. (e.g., `mlx5_0`) |

---

### Summary for your ConnectX-5 Setup
With CX5 cards on system, Linux will see the hardware as an Ethernet card, but the **`mlx5_ib`** driver will
"expose" an RDMA device to the system. You will use the Ethernet side to assign an IP address (the handshake
address) and the RDMA side to move the actual data.
Before we move to Phase 1 there are some important internals to pickup:

## 1. The Verbs API ( The language ):

- Standard Linux networking, you use "Sockets" (`send`, `recv`). In RDMA, we use **Verbs**.

- Because a "Socket" implies the Kernel is handling the buffer. 
- A "Verb" is a direct command to the Hardware.

* **The Big Three:** * `POST_SEND`: "Hey NIC, take this data and go."
    * `POST_RECV`: "Hey NIC, I've cleared some space in my RAM; put the next incoming data there."
    * `POLL_CQ`: "Hey NIC, are you done yet?"

### 2. The Memory "Pinning" Requirement
This is the #1 point of failure for beginners. 
* **Standard RAM:** The Linux kernel moves memory pages around (swapping) to optimize performance.
* **RDMA RAM:** The NIC needs to know the **physical address** of your data. If the Kernel moves a page while the NIC is writing to it, you get a system crash or data corruption.
* **The Fix:** You must "Register" memory. This "pins" the memory in place so the Kernel cannot touch it until the RDMA operation is over.

### 3. The Libraries (The Tools)
You don't need to know every file, just these three layers:
1.  **`libibverbs`**: The "Low-Level" library. You use this to move data.
2.  **`librdmacm`**: The "Connection Manager." You use this to find the other computer's IP and "dial" them.
3.  **`rdma-core`**: This is the umbrella project name on GitHub that contains both of the above.



---

### Update on Kernel/Hardware translation
You asked how a generic command becomes a "ConnectX-5" command. 
1.  **Your App** calls a Verb (e.g., `ibv_post_send`).
2.  **`libibverbs`** looks at your hardware and loads a "User-space Driver" (for CX5, this is `libmlx5`).
3.  **The User-space Driver** writes a specific "Doorbell" (a tiny piece of data) directly to the PCI-Express address of your CX5 card.
4.  **The CX5 Hardware** sees the Doorbell, fetches the command from your RAM, and sends the packet. 

**The Kernel (`ib_core`) is bypassed entirely during the actual data transfer!** It only gets involved to set up the permissions at the beginning.

---

Next Phase 1:
- With the understanding of "pinning RAM" and "ringing a hardware doorbell," the Soft-RoCE setup will make 
  much more sense. 
- Look at step-by-step commands to enable Soft-RoCE and run your first hardware-emulated ping.


