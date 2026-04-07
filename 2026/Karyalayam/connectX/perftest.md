# `perftest`

`perftest` is the standard "Rite of Passage" for anyone working with RDMA. 

It is the industry-standard tool for verifying that your hardware and drivers are actually achieving the 
speeds promised on the box.


Since you are using **ConnectX-5** cards with **RoCE**, there are a few specific flags you must use that 
aren't necessary for InfiniBand.

---

### 1. The Core Commands
The `perftest` package is actually a suite of individual binaries. You'll use these most often:
* **`ib_write_bw`**: Measures RDMA Write bandwidth (the most common test for peak throughput).
* **`ib_send_lat`**: Measures Send/Receive latency (the "ping-pong" of RDMA).
* **`ib_read_bw`**: Measures RDMA Read bandwidth.

---

### 2. Running your first RoCE test
To run a test, you need two machines (Server and Client). Because you are using RoCE, you **must** specify
the GID index and use the `-R` flag for RDMA-CM (Connection Manager) to handle the IP routing.

#### Step A: Find your GID Index
Run this on both machines:
```bash
show_gids
```
Look for the index that says **RoCE v2**. Usually, it's index **3**.

#### Step B: Run the Server (Receiver)
```bash
# -d: device name (e.g., mlx5_0)
# -x: GID index (the RoCE v2 index from step A)
# -R: use RDMA_CM for connection (essential for RoCE)
ib_write_bw -d mlx5_0 -x 3 -R
```

#### Step C: Run the Client (Sender)
```bash
# [server_ip] is the IP address of the server's ConnectX-5 port
ib_write_bw -d mlx5_0 -x 3 -R [server_ip]
```

---

### 3. Key Parameters to Master
Once you get a basic connection working, use these flags to stress the hardware:

| Flag | Meaning | Why use it? |
| :--- | :--- | :--- |
| `-s` | **Size** | Test different message sizes (e.g., `-s 65536` for 64KB). |
| `-a` | **All** | Runs through a range of message sizes automatically. |
| `-D` | **Duration** | Run for X seconds instead of a set number of iterations (e.g., `-D 10`). |
| `-b` | **Bidirectional** | Tests full-duplex (sending and receiving at the same time). |
| `--report_gbits` | **Gbps** | Converts the output from MB/sec to Gbps for easier reading. |



---

### 4. Pro-Tips for ConnectX-5 (25Gbps)
* **NUMA Alignment:** If your server has two CPUs, ensure the `perftest` process is running on the same CPU
  that the NIC is physically plugged into. Use `lscpu` and `lspcie` to check. Run with: `numactl -N 0
  ib_write_bw ...`
* **MTU Mismatch:** If you see "Timeouts" or zero throughput, check that your switch and your NICs are both
  set to the same MTU (usually 1500 or 9000 for Jumbo Frames).
* **CPU Frequency:** RDMA is fast enough that CPU "Power Saving" modes can actually bottleneck the setup.
  Set your CPU governor to `performance`.

**Quick Question:** Do you have a switch between these two ConnectX-5 cards, or are they connected
"back-to-back" with a single cable?
