# RoCE: 

**RoCE** (RDMA over Converged Ethernet) with a ConnectX SmartNIC is the "gold standard" for understanding 
how modern data centers handle massive traffic with near-zero CPU overhead.

To understand how RDMA over Converged Ethernet (RoCE) and SmartNICs function, it helps to look at them as a
specialized HW-SW sandwich designed to eliminate the "middleman" ( The CPU ).

---

### 1. What is RDMA?

To understand RoCE, you first need to understand **RDMA (Remote Direct Memory Access)**.

In a "Normal" network (TCP/IP), the CPU is heavily involved. 

Every packet that arrives must be processed by the Kernel, copied from the NIC to a kernel buffer, and then
copied again into the Application's memory. This creates **Latency** and **CPU Overhead**.

**RDMA** allows one computer to read or write directly into the memory of another computer **without 
involving either system's CPU or Operating System kernel.**

---

### 2. Enter RoCE: InfiniBand meets Ethernet

Historically, RDMA only worked on **InfiniBand** hardware (special cables, special switches). **RoCE** was 
invented to allow these high-speed RDMA benefits to run over standard, cheap **Ethernet** infrastructure.

There are two versions you need to know:

* **RoCE v1:** An Ethernet layer-2 protocol. It is not routable (it stays within one switch/subnet).

* **RoCE v2:** Encapsulates the RDMA data inside a **UDP/IP packet**. This is what your ConnectX card uses.
  Because it has an IP header, it can be routed across different networks and works perfectly with standard 
  IP logic.

---

### 3. The "Secret Sauce": Zero-Copy and Kernel Bypass

When you use RoCE on your ConnectX card, three magic things happen:

1. **Kernel Bypass:** 
    The application talks directly to the NIC hardware. It "skips" the Linux networking stack entirely.
    
2. **Zero-Copy:** 
    The NIC pulls data directly from your RAM. There are no intermediate copies.

3. **Hardware Offload:** 
    The ConnectX card handles the "Retransmission" and "Acknowledge" logic that the CPU usually handles for
    TCP.

---

### Essential components that make up High performance EcoSystem:

Breakdown of the essential components that make this high performance ecosystem work:

#### 1. RDMA/RoCE SW Stack:

This layer allows your application to "talk" to the HW without the need to wait for the OS permission for
every packet. 

- *User-Space Library*: ( `libibverbs` ): Linux library that provides "Verbs" API. It allows to bypass the
  kernel. 

- 



### 4. Key Concepts for your Testing

Before you run your next script, keep these four terms in mind:

| Term | What it is | Why it matters for your script |
| --- | --- | --- |
| **HCA** | Host Channel Adapter | This is your ConnectX card. |
| **GID** | Global Identifier | The "RDMA Address." In RoCE v2, this is essentially your IP address. |
| **Verbs** | The API | You don't "send sockets"; you "post verbs" (Send, Receive, Read, Write). |
| **Queue Pair (QP)** | The Connection | Instead of a TCP Port, RDMA uses a pair of queues to send/receive data. |

---

### 5. Why your "Single Card, Two Namespace" test is brilliant

By putting Port 0 in `ns1` and Port 1 in `ns2`, you are forcing the data to:

1. Leave the RAM of the system.
2. Go through the **ConnectX Silicon**.
3. Exit the physical **Port 0**.
4. Travel through the **DAC Cable**.
5. Enter physical **Port 1**.
6. Return to RAM.

This confirms that your **Offload Engines** are working. 

If you just did a normal "Ping" between two local IPs, the Linux Kernel would shortcut the traffic internally
and never actually use the 25G wire!

---

### Next Step: Looking at the "Address Table"

Before we move to the next test, would you like to see how to use the `ibv_devinfo` or `rdma res` commands 
to see the **GID Table**? 
This will show you exactly which "ID" your card has assigned to its RoCE v2 (UDP) personality.

To see how RoCE is actually addressed, we look at the **GID (Global Identifier) Table**. 

In RoCE v2, the GID is essentially your IPv4 address mapped into a 128-bit IPv6-style format so the RDMA 
hardware can understand it.


### 1. The "Traditional" View: `show_gids`

Mellanox (NVIDIA) provides a specific script to make this table human-readable. 

Since your interfaces are inside namespaces, you must execute it there:

```bash
sudo ip netns exec ns1 show_gids

```

**What to look for in the output:**

* **Index:** This is the number (e.g., `0, 1, 2`) you pass to testing tools using the `-x` flag.
* **GID:** You should see your IP (`10.0.0.9`) embedded at the end of the GID string.
* **Type:** It should clearly state **RoCE v2**.
* **Device/Port:** It will confirm it's tied to `enp1s0f0np0`.

---

### 2. The "Modern" View: `rdma addr`

If you want to use the standard Linux `rdma-tool` (part of `iproute2`), run:

```bash
sudo ip netns exec ns1 rdma res show path

```

Or to see the hardware devices currently mapped:

```bash
sudo ip netns exec ns1 rdma dev

```

---

### 3. Deep Hardware Info: `ibv_devinfo`

To see the "Health" of the RDMA port (MTU size, Max Queue Pairs, and the "Active" state), use:

```bash
sudo ip netns exec ns1 ibv_devinfo -d mlx5_0 -p 1

```

> **Key Fields to Verify:**
> * **transport:** Should be `InfiniBand` (this is normal for RoCE).
> * **active_mtu:** For 25GbE, this is usually `1024` or `2048`. If it's too small, performance will drop.
> * **state:** Must be `PORT_ACTIVE`.
> 
> 

---

### 4. Why the GID Index Matters

When you eventually run your performance test (like `ib_send_bw`), the tool needs to know which "personality"
of the card to use.

* **Index 0/1:** Usually RoCE v1 (Legacy).
* **Index 2/3:** Usually **RoCE v2** (The one that uses UDP and IP).

If you pick the wrong index, your `ping` will work, but your RDMA test will fail with a "Connection Refused" 
or "Timeout" because the hardware is looking for a different packet header.

---

### Summary Table for your Namespaces

| Tool | Purpose |
| --- | --- |
| `show_gids` | Shows the IP-to-RDMA mapping and the **Index** number. |
| `ibv_devinfo` | Checks if the hardware port is "Active" and its Max MTU. |
| `rdma dev` | Confirms the `mlx5` device is actually inside your namespace. |

