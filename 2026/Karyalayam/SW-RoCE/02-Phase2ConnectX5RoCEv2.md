## Phase 2: Real Hardware — ConnectX-5 Setup

Because CX5 cards are "VPI" (Virtual Protocol Interconnect), they can act as either InfiniBand or Ethernet. We need to ensure they are set to **Ethernet mode** to use **RoCE v2**.

### 1. Identify your Hardware
First, find the PCI address and current mode of your cards.
```bash
# List all Mellanox devices
lspci | grep Mellanox

# Show the RDMA device name (e.g., mlx5_0)
ibv_devices
```

### 2. Configure for Ethernet Mode
Use the `mlxconfig` tool (part of the `mft` or `mstflint` package) to check and set the port type. Replace `0000:01:00.0` with your card's PCI address.

```bash
# Query current configuration
sudo mlxconfig -d 0000:01:00.0 q | grep LINK_TYPE

# Set port 1 to Ethernet (1 = InfiniBand, 2 = Ethernet)
sudo mlxconfig -d 0000:01:00.0 set LINK_TYPE_P1=2

# Repeat for the second port if your card is dual-port (LINK_TYPE_P2=2)
```
**Important:** You must **reboot** the machine after running `mlxconfig` for the changes to take effect in the hardware firmware.

### 3. Assign IP Addresses
RoCE v2 relies on standard UDP/IP. Assign an IP to the Ethernet interface associated with each card.
```bash
# Host A
sudo ip addr add 192.168.10.1/24 dev enp1s0f0
sudo ip link set enp1s0f0 up

# Host B
sudo ip addr add 192.168.10.2/24 dev enp1s0f0
sudo ip link set enp1s0f0 up
```

### 4. Verify RoCE v2 GID
RDMA uses a **GID (Global Identifier)** table. For RoCE v2, one of these GIDs will map to your IP address.
```bash
# Show the GID table for your device
show_gids
```
Look for an entry that says `RoCE v2` and shows your assigned IP. Note its **Index** (usually `3` or `4` on CX5).



---

## The "Real World" Benchmark
Now, run the same test you did in Phase 1, but on the real hardware.

**Server:**
```bash
# -d: the real mlx5_0 device, -g: the GID index for RoCE v2
ib_write_bw -d mlx5_0 -g 3 -a
```

**Client:**
```bash
ib_write_bw -d mlx5_0 -g 3 -a 192.168.10.1
```

### What to Observe Now:
1.  **Throughput:** If you have a 100G card, you should see numbers near **11,500 MB/s**.
2.  **CPU Usage:** Run `top`. Unlike Soft-RoCE, the CPU usage should be **nearly 0%**, even at max speed. The CX5 hardware is doing all the work.

---

## Phase 3 Preview: Lossless Networking
In a back-to-back setup, this works perfectly. But once you add a **network switch**, you enter "Phase 3." Standard switches drop packets when busy. Since RDMA doesn't have the slow "back-off" logic of TCP, a single dropped packet causes a massive performance crash.

**Would you like to learn how to configure "PFC" (Priority Flow Control) to prevent these drops, or should we move into writing your first C/Rust code specifically for the CX5 cards?**


------

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
