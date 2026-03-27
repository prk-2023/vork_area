# Phase 3 Lossless Network

Phase 3 is the "Reliability" phase. Because RDMA is designed for high-speed, zero-copy transfers, it assumes the underlying network is **lossless**. If a standard Ethernet switch gets congested and drops even a single RDMA packet, the performance can drop by 90% or more as the hardware waits for a timeout.

To fix this, we use **PFC (Priority Flow Control)**. Unlike standard "Pause" frames that stop all traffic on a cable, PFC allows us to pause *only* the RDMA traffic while letting standard traffic (like SSH or HTTP) keep flowing.

---

### 1. The Strategy: Priority 3
By industry convention, **Priority 3** is usually reserved for "Lossless" RoCE traffic. We will configure your ConnectX-5 cards to:
1.  Trust the **DSCP** or **PCP** tags in the packets.
2.  Enable PFC specifically on **Priority 3**.

### 2. Configure PFC on ConnectX-5
You will use the `mlnx_qos` tool (part of the `mlnx-tools` or `rdma-core` packages). Run these commands on **both hosts**.

#### **Step A: Check current QoS settings**
```bash
# Replace 'enp1s0f0' with your actual Ethernet interface name
sudo mlnx_qos -i enp1s0f0
```

#### **Step B: Enable PFC on Priority 3**
The `--pfc` flag takes 8 values (for priorities 0-7). We want to set the 4th value (index 3) to `1`.
```bash
# Enable PFC on priority 3, disable on others
sudo mlnx_qos -i enp1s0f0 --pfc 0,0,0,1,0,0,0,0
```

#### **Step C: Set Trust Mode**
For RoCE v2, it is best to trust the **DSCP** bits in the IP header.
```bash
sudo mlnx_qos -i enp1s0f0 --trust dscp
```

---

### 3. Optional but Recommended: ECN (Explicit Congestion Notification)
PFC is a "hard stop." **ECN** is a "soft slow-down." It tells the sender to reduce its speed *before* the buffers overflow. This is highly recommended for ConnectX-5.

```bash
# Enable ECN for RoCE (Notification Point and Reaction Point)
echo 1 | sudo tee /sys/class/net/enp1s0f0/ecn/roce_np/enable/3
echo 1 | sudo tee /sys/class/net/enp1s0f0/ecn/roce_rp/enable/3
```



---

### 4. How to Verify It's Working
Run your bandwidth test again (`ib_write_bw`). While it's running, check the hardware counters for "Pause Frames." If the network gets congested, these numbers should increase.

```bash
# Check if the NIC is receiving or sending pause frames
ethtool -S enp1s0f0 | grep prio3_pause
```

---

### 5. Summary Checklist
- [x] PFC enabled on Priority 3.
- [x] Trust mode set to DSCP.
- [x] ECN enabled (optional but better).
- [x] **Note:** If you are using a switch between the cards, the **switch** must also have PFC enabled on Priority 3 for this to work!

---

**Is your hardware configuration complete? If so, would you like to move on to Phase 4: Writing your first actual C or Rust code to perform a "One-Sided" RDMA Write between your two cards?**
