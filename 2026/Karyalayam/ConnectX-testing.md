1. Install the necessary tooling:

Install RDMA Stack:
```
sudo apt update
sudo apt install -y rdma-core ibverbs-utils perftest libibverbs1
```

- `ibverbs-utils`: Contains `ibv_devinfo` to check hardware status.
- `perftest`: Contains the "Golden Standard" benchmarks (`ib_write_bw`, `ib_send_lat`).

2. Verify HW Link State:

Check if the NIC is visible and the link is "Up":

```
# Check if the mlx5_core driver found your card
$ ibv_devinfo
    hca_id: mlx5_0
    transport: InfiniBand (0) (Don't worry, this is correct for RoCE)
    port: 1
    state: PORT_ACTIVE (4)
    link_layer: Ethernet
```

3. IP Configuration

For RoCE to work, both NICs must be on the same IP subnet. 
Assign IPs to the specific interface (e.g., enp1s0f0).

```
Node A> $ sudo ip addr add 192.168.10.1/24 dev enp1s0f0
        $ sudo ip link set enp1s0f0 up
Node B> $ sudo ip addr add 192.168.10.2/24 dev enp1s0f0
        $ sudo ip link set enp1s0f0 up
Bring them up: sudo ip link set enp1s0f0 up
```

4. The RoCE v2 Connectivity Test

RoCE v2 uses GID (Global ID) index 3 by default on most modern ConnectX cards. We will use `ib_write_bw` to test raw RDMA write bandwidth.

```
#Note A ( server )
#-d: device, -x: GID index (3 is RoCE v2), -a: run all message sizes

$ sudo ib_write_bw -d mlx5_0 -x 3 -a
```

```
#Note B ( Client )
#Point to Node A's IP
$ sudo ib_write_bw -d mlx5_0 -x 3 -a 192.168.10.1
```

5. Validating "kernel Bypass":
While the test is running, run top or htop on both machines.

- Observation: Even at 25Gbps (saturated link), you will notice that CPU usage stays near 0%.

- If 0% CPU usage => SmartNIC is doing heavy lifting via RDMA, bypassing the Linux Kernel.


6. Troubleshooting Common Issues

- No GID Index 3? Run show_gids to see which index corresponds to RoCE v2.

- Firewalls: RoCE v2 uses UDP Port 4791. Ensure ufw or iptables isn't blocking it.

- MTU: For 25G, it is highly recommended to use Jumbo Frames (MTU 9000) for better performance:

```
$ sudo ip link set enp1s0f0 mtu 9000` 
```

--------------------

Test With Single ConnectX card: since ConnectX 5 has 2 ports:

1. Configure the interfaces:

```
# Set Port 1
sudo ip addr add 192.168.10.1/24 dev enp1s0f0
sudo ip link set enp1s0f0 up

# Set Port 2
sudo ip addr add 192.168.10.2/24 dev enp1s0f1
sudo ip link set enp1s0f1 up
```

2. Fix the "Linux Loopback" Problem
By default, the Linux kernel is "smart"—if it sees you trying to send a packet to an IP that it already owns, it will route it internally through the lo (Software Loopback) interface, bypassing the NIC entirely. To force the traffic out of the silicon and across the cable, you must use Network Namespaces:

```
# Create two isolated network namespaces
sudo ip netns add ns1
sudo ip netns add ns2

# Move each physical port into a namespace
sudo ip link set enp1s0f0 netns ns1
sudo ip link set enp1s0f1 netns ns2

# Configure IPs inside the namespaces
sudo ip netns exec ns1 ip addr add 192.168.10.1/24 dev enp1s0f0
sudo ip netns exec ns1 ip link set enp1s0f0 up
sudo ip netns exec ns2 ip addr add 192.168.10.2/24 dev enp1s0f1
sudo ip netns exec ns2 ip link set enp1s0f1 up
```

CheckA: Physical link status after connecting the pots using a DAC Cable ( Direct attached Copper)
```
# Check if both ports show "Link detected: yes" and "Speed: 25000Mb/s"
sudo ip netns exec ns1 ethtool enp1s0f0
sudo ip netns exec ns2 ethtool enp1s0f1
```

Check B: The "Unplug" Test (The Gold Standard)
Start a ping between the namespaces:
```
sudo ip netns exec ns1 ping 192.168.10.2
```
Now, physically pull the DAC cable out. * If the ping stops, Success! You have proven that the traffic was physically leaving the NIC and crossing the cable.

Note for XDP Development:

When testing XDP on this loopback setup, you can now simulate "External" traffic. 
You can run a packet generator in `ns1` to "attack" `ns2`. 
Because the packets are coming in through the physical wire of Port 2, your XDP program on Port 2 will 
treat them exactly like they came from a remote server in a real data center.


3. Run the Performance Test
Now, you can run the RDMA benchmark between the two namespaces. This forces the data to leave ns1, go through the ConnectX-5 silicon, out Port 1, across the DAC cable, in through Port 2, and back into the silicon for ns2.

- Start the Server in Namespace 1:
```
sudo ip netns exec ns1 ib_write_bw -d mlx5_0 -x 3
```
- Start the Client in Namespace 2:
```
sudo ip netns exec ns2 ib_write_bw -d mlx5_1 -x 3 192.168.10.1
```

4. Summing up:

- True Hardware Path: You are exercising the actual Transceivers, SerDes, and DMA engines.

- Congestion Control Testing: Since you are both the sender and receiver, you can easily use tools like mlxtool to simulate packet loss and see how the card's hardware retransmission (which we discussed earlier) handles it.

- Kernel Bypass Validation: Run htop while the test hits 24.5Gbps. You’ll see the CPU is barely idling, proving the RDMA engine is working.

----------------------
XDP:

1. The Interface "Name" Trap
On a ConnectX-5, the hardware presents two different "personalities" to Linux:

- The Ethernet Interface: (e.g., enp1s0f0) — This is where XDP lives.

- The IB/RDMA Interface: (e.g., mlx5_0) — This is used for ib_write_bw and RoCE.

Crucial Point: You cannot attach an XDP program directly to the `mlx5_0` (InfiniBand) device name. You must attach it to the Ethernet interface name associated with that port. 
When you send RoCE traffic (which is UDP/IP encapsulated), it will pass through the Ethernet driver's RX path, where your XDP hook is waiting.

2. Native vs. Generic Mode with Aya
When you use Aya to load this, you have to choose a mode.
For ConnectX-5 Ex, you should always aim for Native Mode to get the performance your hardware is capable of.

```
// Example snippet of how you would attach this in your userspace code
let prog: &mut Xdp = bpf.program_mut("pps_counter").unwrap().try_into()?;
prog.load()?;
// Use XdpFlags::DRV_MODE for Native (Driver) mode
prog.attach(&iface, XdpFlags::DRV_MODE)?;
```

3. Will you see "Zero PPS"?

As we touched on earlier, here is exactly what your `COUNTER` map will show vs. what the CPU will do:

- Map Counter: Your `COUNTER` will increment perfectly for every packet.

- Host CPU PPS: If you use `XDP_PASS` (as in your code), the packets continue to the Linux Kernel. You will see high PPS in tools like `sar -n DEV` or `ifstat`.

- CPU Usage: Because ConnectX-5 runs XDP in Native (Driver) Mode, the host CPU is still doing the work to run your Rust logic. You will see a specific CPU core (the one handling the NIC's RSS queue) spike in usage.

4. A Note on your Code
Your unsafe block for the counter is correct for a `PerCpuArray`, but since you're evaluating this for a dev team, keep in mind:

- Memory Barriers: At 25Gbps (approx. 37 million packets per second), memory atomicity matters if you move to a shared Array instead of PerCpuArray.

- Bounds Checking: Aya/eBPF is strict. Even though you have unwrap_or, the verifier might still complain if it can't prove that val is valid before the dereference.

============

Action Plan:

To properly evaluate this for your team, you should focus on the three pillars of SmartNIC development: 
    1. **Co-existence**, 
    2. **Native Mode Performance**, and 
    3. the **Path to Hardware Offload**.

---

### 1. The "Dual-Face" Co-existence

You are exactly right: `enp1s0f0` (Ethernet) and `mlx5_0` (Verbs/RDMA) are two different software entry points to the **exact same hardware engine**.

* **Traffic Visibility:** When you run an RDMA test (RoCE v2), the packets are technically UDP packets on the wire. Your XDP program attached to the Ethernet interface **will see them**.
* **The "Pass" Requirement:** As a developer, if your XDP program does not specifically recognize and `XDP_PASS` RoCE traffic (UDP Port 4791), you risk dropping your high-speed data plane traffic before it even reaches the RDMA engine.

### 2. Limitations of ConnectX-5 XDP Native Mode

For your team's evaluation report, highlight these "Hard Truths" about the CX-5 (and even CX-6) series:

* **No True HW Offload:** Unlike some FPGA-based NICs or specific NPUs (like Netronome), the ConnectX-5 **does not** execute eBPF instructions on the NIC's silicon. It executes them in the **Host Driver** (Native mode).
* **Multi-Buffer Constraints:** If you are working with Jumbo Frames (MTU 9000), the ConnectX-5 driver's XDP implementation has historically struggled with "Multi-buffer" support in zero-copy mode. As of late 2025/2026, while `Striding RQ` (a Mellanox-specific tech) improves this, it’s still a complex edge case for XDP development.
* **CPU Interaction:** Because it is "Native" and not "Offloaded," the host CPU still consumes cycles for every packet. At 25Gbps (approx. 37M packets per second), a single CPU core will likely hit 100% just running your `pps_counter` logic.

### 3. Strategy: The "XDP to TC" Pipeline

If your dev team's goal is **Zero Host CPU** usage, your evaluation should conclude that XDP is the "Development/Prototyping" layer, while **TC-Flower** is the "Production/Hardware" layer.

| Metric | XDP Native (Aya/Rust) | TC Flower (Switchdev) |
| --- | --- | --- |
| **Logic Location** | Host CPU (Driver) | NIC ASIC (Hardware) |
| **Programmability** | Full C/Rust logic | Simple Match-Action |
| **Host Impact** | High CPU Interrupts | **Zero Host Interrupts** |
| **CX-5 Support** | Excellent | Excellent (via ASAP²) |

---

### Final "Evaluation" Pro-Tip:

If you want to prove the "Smart" in SmartNIC to your team, try this:

1. Attach your Aya XDP counter to `enp1s0f0`.
2. Observe the CPU spike in `top` during a 25G blast.
3. Then, use a `tc filter` command to offload a simple "drop" rule to the hardware.
4. Watch the CPU usage **drop to near zero** while the traffic is still being blocked at line rate. This effectively demonstrates the difference between "Software Smart" (XDP) and "Hardware Smart" (ASIC Offload).

**Would you like the specific `tc` commands to move your eBPF logic into the hardware ASIC to show that "Zero CPU" state?**

---------------------

Since you are in the architectural and evaluation phase rather than the benchmarking phase, your role is to act as the "bridge" between the **Linux Networking Stack** and the **NIC Hardware**.

For a development team building or integrating SmartNICs, here are the critical technical "pillars" they must keep in mind regarding XDP.

---

### 1. The "Visibility" Paradox (XDP vs. RDMA)

Your team needs to understand that **XDP sits "before" the RDMA engine** in the hardware pipeline of a ConnectX-5.

* **The Development Hurdle:** If the team develops a security XDP program (e.g., a firewall) but doesn't explicitly account for the RoCE UDP headers (Port 4791), they will accidentally kill the high-speed data plane.
* **The Strategy:** Design your XDP metadata parsing to recognize "RDMA Control" vs. "RDMA Data" packets. You can count them in XDP, but you must `XDP_PASS` them instantly to avoid adding latency to the RDMA hardware.

---

### 2. Memory Architecture: The "PCIe Bottleneck"

Even with XDP "Native Mode," the data still traverses the PCIe bus to reach the Host CPU's memory for your Rust/Aya code to inspect it.

* **The Development Hurdle:** On a PCIe x8 slot (which your card has), you have a finite bandwidth. If your XDP program performs "XDP_TX" (reflecting packets back out), you are using the PCIe bus **twice** (In and Out).
* **The Strategy:** The team should evaluate if "Header-Only" processing is sufficient. If you only need to look at the first 128 bytes of a packet, you can significantly reduce memory pressure compared to pulling the entire 9000-byte Jumbo Frame into the CPU cache.

---

### 3. "Native" isn't "Offloaded" (Managing Expectations)

This is the most significant point for your leadership team.

* **The Development Hurdle:** There is a common misconception that "SmartNIC + XDP = Zero CPU." On a ConnectX-5, this is **false**. XDP runs on the **Host CPU**.
* **The Strategy:** Highlight that XDP on ConnectX-5 is for **Software-Defined Programmability**, not **Hardware Offload**. If the product requirement is "Zero Host CPU," the team must either:
1. Target **DPUs** (where XDP runs on the card's ARM cores).
2. Target **ASIC-Steering (TC-Flower)** for the high-volume rules.



---

### 4. Driver & Firmware "Lock-in"

XDP performance and features are heavily dependent on the specific version of the `mlx5_core` driver and the NIC firmware.

* **The Development Hurdle:** Features like `XDP_REDIRECT` (sending a packet to a different NIC) or `AF_XDP` (Zero-copy to userspace) may behave differently or be buggy on older firmware versions of the CX-5 Ex.
* **The Strategy:** Establish a **Firmware/Kernel Baseline** early. Ensure the whole team is developing on a specific LTS Kernel (e.g., 6.1+) and firmware version to avoid "works on my machine" bugs related to the NIC's internal eSwitch behavior.

---

### Summary for your Evaluation

| Team Focus | What they need to know |
| --- | --- |
| **Security Team** | XDP is the fastest way to drop packets, but the CPU still "feels" the interrupt. |
| **Storage Team** | RDMA and XDP co-exist, but XDP must be "RoCE-aware" to avoid breaking NVMe-oF. |
| **Infrastructure Team** | XDP Native mode is limited by the Host CPU's single-core performance. |
| **Product Owners** | To reach "True SmartNIC" status (Zero CPU), we must look toward DPU or TC-Offload. |

---

**Would you like me to draft a "Technical Constraints" slide or summary specifically regarding how XDP interacts with the ConnectX-5's internal eSwitch?**
