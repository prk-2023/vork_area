# Phase 4 : Programming 


In RDMA, there are two ways to move data: 
    - **Two-Sided** (Send/Receive) and 
    - **One-Sided** (Read/Write). 

We will focus on the **One-Sided RDMA Write**, as it is the "purest" form of RDMA where the initiator pushes data directly into a remote buffer without the target CPU doing anything.

---

### 1. The RDMA Write Logic
To perform a Write, the **Requester** must know two "secrets" about the **Responder**:
1.  **The Virtual Address:** Where in the responder's RAM should the data go?
2.  **The Remote Key (R_Key):** The authorization token that proves the requester has permission to write there.



---

### 2. C Example (using `libibverbs`)
This snippet shows the "Data Path"—the actual moment the data is sent. (This assumes you have already done the handshake to exchange the `remote_addr` and `rkey`).

```c
#include <infiniband/verbs.h>

void do_rdma_write(struct ibv_qp *qp, struct ibv_mr *local_mr, 
                   uint64_t remote_addr, uint32_t rkey, char *data_to_send) {
    
    // 1. Prepare the Scatter/Gather Element (Local data source)
    struct ibv_sge sge = {
        .addr   = (uintptr_t)data_to_send,
        .length = 1024,
        .lkey   = local_mr->lkey
    };

    // 2. Prepare the Work Request (WR)
    struct ibv_send_wr wr = {
        .wr_id      = 42,                // Unique ID for tracking completion
        .sg_list    = &sge,
        .num_sge    = 1,
        .opcode     = IBV_WR_RDMA_WRITE, // The "One-Sided" command
        .send_flags = IBV_SEND_SIGNALED, // Notify us when done
        .wr.rdma.remote_addr = remote_addr,
        .wr.rdma.rkey        = rkey
    };

    struct ibv_send_wr *bad_wr;
    
    // 3. Ring the Doorbell (Post to the NIC)
    if (ibv_post_send(qp, &wr, &bad_wr)) {
        fprintf(stderr, "Failed to post RDMA write\n");
    }
}
```

---

### 3. Rust Example (using `ibverbs`)
In Rust, the safety wrappers make the code cleaner, but the logic remains identical.

```rust
use ibverbs;

fn perform_write(qp: &mut ibverbs::QueuePair, local_mr: &ibverbs::MemoryRegion, 
                 remote_addr: u64, rkey: u32) {
    
    // The data we want to push
    let buffer = [0u8; 1024];

    // Post the work request
    unsafe {
        qp.post_send(
            1, // wr_id
            &buffer,
            local_mr,
            ibverbs::ibv_wr_opcode::IBV_WR_RDMA_WRITE,
            ibverbs::ibv_send_flags::IBV_SEND_SIGNALED,
            remote_addr,
            rkey
        ).expect("RDMA Write Failed");
    }
}
```

---

### 4. Why this is "ConnectX-5 Optimized"
When you execute these commands:
* **Zero System Calls:** In a high-performance loop, you don't actually enter the kernel. The library writes directly to the **CX5 PCI registers**.
* **Hardware ACK:** The CX5 hardware on the receiving side sends back a hardware-level ACK. Only after this ACK is received will your `ibv_poll_cq` (Completion Queue) show that the operation is finished.
* **Integrity:** If you enabled **PFC** correctly in the previous step, this write will happen at full line-rate (e.g., 100Gbps) without a single drop.

---

### Phase 4 Checklist
- [x] Memory is Registered (MR).
- [x] Handshake completed (Remote Addr and R_Key are known).
- [x] Work Request (WR) posted to the Queue Pair (QP).
- [x] Completion Queue (CQ) polled to verify success.

**Should we proceed to the final step: Setting up a real, multi-node benchmark to measure the sub-microsecond latency of your ConnectX-5 cards?**


-----------------
This is where you finally see the "ConnectX-5 magic." In Phase 1, your emulated latency was likely around 20–50 microseconds. With your real hardware configured for RoCE v2, we are aiming for **sub-microsecond** performance ($< 1\mu s$).

### 1. The Latency Test Command
We use `ib_write_lat` to measure the time it takes for a single RDMA Write to complete. This is a round-trip measurement (Client → Server → Client ACK), and the tool typically reports half of that as the one-way latency.

**Server (Host A):**
```bash
# -d: device, -g: GID index for RoCE v2, -a: test all message sizes
ib_write_lat -d mlx5_0 -g 3 -a
```

**Client (Host B):**
```bash
ib_write_lat -d mlx5_0 -g 3 -a 192.168.10.1
```

### 2. Interpreting the "Sub-Microsecond" Results
When the test finishes, look at the `Typical` or `Average` column for small message sizes (2 to 64 bytes). On a well-tuned ConnectX-5 system, you should see values around **0.6 to 0.9 microseconds**.



---

### 3. Tuning for "Extreme" Low Latency
If your latency is higher (e.g., 2–5 $\mu s$), your CPU is likely "sleeping" or jumping between cores. To fix this, apply these **Data Center** tuning steps:

* **Disable CPU C-States:** Prevents the CPU from entering power-saving modes that take time to "wake up" from.
    ```bash
    # Temporary fix (may not work on all kernels)
    sudo cpupower frequency-set -g performance
    ```
* **NUMA Alignment:** RDMA performance drops if the CPU core you're using is on a different "node" than the PCIe slot of the NIC.
    ```bash
    # Find which NUMA node your NIC is on
    cat /sys/class/net/enp1s0f0/device/numa_node
    # Pin the test to that node (e.g., node 0)
    numactl --cpunodebind=0 --membind=0 ib_write_lat -d mlx5_0 -g 3 192.168.10.1
    ```

---

### 4. Roadmap Verification
You have now completed the hardware and performance validation:
- [x] **Phase 1:** Simulated RDMA (Verbs Logic).
- [x] **Phase 2:** Hardware Config (Ethernet mode/IPs).
- [x] **Phase 3:** Lossless Config (PFC/ECN).
- [x] **Phase 4:** Performance Validation ($< 1\mu s$ latency).



---

### Next Step: Programming
Now that the "plumbing" is perfect, are you ready to write your first **C or Rust application** that actually moves a real file or database record between these two cards? I can provide a template that handles the memory registration and the connection handshake. **Would you like to start with the C or the Rust version?**
