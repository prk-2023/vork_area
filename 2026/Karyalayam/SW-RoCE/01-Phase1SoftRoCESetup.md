# Soft - RoCE Setup: 


## Phase 1: Soft-RoCE Setup and the First "Ping"

In this phase, we are going to turn your standard Ethernet loopback or a virtual interface into an
RDMA-capable device. This allows you to practice the **Verbs workflow** without touching your ConnectX-5
hardware yet.

---

### 1. Install the RDMA Userspace Stack

First, we need the libraries that allow your code to talk to the `RDMA` subsystem.

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install rdma-core ibverbs-utils rdmacm-utils perftest
```

**On RHEL/CentOS/Fedora:**
```bash
sudo dnf install rdma-core libibverbs-utils librdmacm-utils perftest
```

---

### 2. Enable the Soft-RoCE Kernel Module

The kernel component for Soft-RoCE is called `rdma_rxe`. Loading this module tells the Linux kernel, "I want
to be able to emulate `RDMA` over standard Ethernet packets."

```bash sudo modprobe rdma_rxe ```

To verify it's loaded, run `lsmod | grep rxe`.

---

### 3. Create a Virtual RDMA Link 

Now, we "map" a new RDMA device (let's call it `rxe0`) to one of your existing network interfaces.
Even if you aren't connected to a network, you can use your **loopback** interface (`lo`).

1. **Find your interface:** Run `ip link` (look for `lo` or `eth0`).
2. **Bind the RDMA device:**
   ```bash
   # Mapping 'rxe0' to the 'lo' interface
   sudo rdma link add rxe0 type rxe netdev lo
   ```
3. **Verify:**
   ```bash
   rdma link show
   ibv_devices
   ```
   You should see `rxe0` listed with a GUID. This is your "Virtual NIC."

---

### 4. Running your first RDMA "Ping-Pong"
The `ibv_rc_pingpong` tool is the gold standard for testing. It uses a **Reliable Connection (RC)**—the most
common RDMA transport type.

Because we are using RoCE v2 (UDP-based), we must use a **GID (Global Identifier)** index. Since we mapped
to `lo` (127.0.0.1), that IP is stored in the GID table.

**Open two terminal windows on the same machine:**

**Terminal 1 (The Server):** 
```bash # -d: device, -g: GID index (usually 0 or 1 for RoCE) ibv_rc_pingpong -d rxe0 -g 0 ```

**Terminal 2 (The Client):** ```bash ibv_rc_pingpong -d rxe0 -g 0 localhost ```



---

### 5. What just happened under the hood? Even though it's emulated, the software followed the exact same

steps your ConnectX-5 cards will later:

1. **Open Device:** Both sides opened `rxe0`.
2. **Register Memory:** The tool allocated a buffer and "pinned" it using `ibv_reg_mr`.
3. **Queue Pairs:** They created a Send and Receive queue.
4. **The Handshake:** They exchanged their **QPN (Queue Pair Numbers)** and **LIDs/GIDs** over a standard
   TCP socket.
5. **The Transfer:** The Client sent a message. The `rdma_rxe` driver wrapped it in a UDP packet, sent it to
   `127.0.0.1`, and the server "received" it into the pinned memory.

---

### Phase 1 Troubleshooting & Observations
* **Check GIDs:** If it fails, run `ibv_devinfo -v | grep -A 4 GID`. This shows you which "index" matches
  your IP address. If index `1` shows your IP, use `-g 1` in the commands above.
* **CPU Usage:** Watch `top` while running a performance test (`ib_write_bw`). You'll notice CPU usage is
  high. **This is normal for emulation.** When we move to your CX5 cards, this CPU usage will drop to nearly
  0.

**Would you like to try running a performance benchmark (bandwidth test) on this emulated link to see how
much overhead the software emulation adds?**

--------------- 

Running a bandwidth test on your emulated link is the best way to see the "RDMA Verbs" in
action. It also highlights the massive difference between software emulation and the hardware offload your
ConnectX-5 cards will provide.

---

### 1. Run the Bandwidth Test The `perftest` package includes `ib_write_bw`, which measures **RDMA Write**
throughput. 

**Terminal 1 (Server):** ```bash # -d: device, -g: GID index, -a: run for all message sizes ib_write_bw -d
rxe0 -g 0 -a ```

**Terminal 2 (Client):** ```bash ib_write_bw -d rxe0 -g 0 -a localhost ```

### 2. What to Look For
* **The "Gap":** On a standard 1Gbps or 10Gbps Ethernet link, you’ll likely see the bandwidth cap out
  quickly. 
* **CPU Usage:** Open a third terminal and run `top`. You will see the `soft-roce` (or `kworker`) processes
  and your `ib_write_bw` process consuming significant CPU.



---

### 3. Comparison: Soft-RoCE vs. ConnectX-5 (Real Hardware) This is the "Aha!" moment of Phase 1. When you
eventually move this same test to your CX5 cards, the numbers will change drastically.

| Metric | Soft-RoCE (Emulated) | ConnectX-5 (Hardware) | | :--- | :--- | :--- | | **CPU Cycles** | ~500+
cycles per packet | **~35-50 cycles** per packet | | **Latency** | 20–50 microseconds | **< 1 microsecond**
| | **Throughput** | Limited by CPU speed | **Line rate** (100Gbps+) | | **Bypass** | Bypasses Application
Stack only | **Bypasses Kernel AND CPU** |



---

### 4. Why is the CPU so high in Emulation? In Soft-RoCE, the "Work" (packetizing, checksums, and Reliable
Connection state tracking) is done by a kernel thread (`rdma_rxe`). 
* **Emulation:** The CPU mimics the NIC hardware logic.
* **Hardware (CX5):** The ASIC on the card has a dedicated "Transport Engine" that does all this logic in
  silicon. 

### Phase 1 Summary Checklist
- [x] Installed `rdma-core` and `perftest`.
- [x] Loaded `rdma_rxe` and created `rxe0`.
- [x] Ran a successful `ibv_rc_pingpong`.
- [x] Observed CPU/Bandwidth behavior with `ib_write_bw`.

**Are you ready to graduate to Phase 2: Physically installing and configuring your two ConnectX-5 cards for
real RoCE v2?** (I can help with the `mlxconfig` commands to ensure they are in the correct Ethernet/RoCE
mode).
