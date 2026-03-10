# Network Namespaces:

Network Namespaces (`netns`) are the fundamental building blocks of modern Linux containerization 
(like Docker and Kubernetes). 

Think of them as a "SimCity" for your network stack—a way to create isolated, virtualized networking env that
coexist on the same kernel but remain completely blind to each other.

Here is how you can set up and control these sandboxes.

---

## The Workflow: 5 Steps to Isolation

To connect a namespace to the rest of the world (or your root host), we use **veth pair** (virtual ethernet 
pair). 

It works like a virtual patch cable: one end stays in the root namespace, and the other gets shoved inside 
your new sandbox.

### 1. Create the Namespace

This creates a blank slate in `/var/run/netns/`.

```bash
sudo ip netns add ns-testing

```

### 2. Create the Virtual Cable (veth pair)

We need two ends. Let’s call them `veth-host` and `veth-ns`.

```bash
sudo ip link add veth-host type veth peer name veth-ns

```

### 3. Move the Interface

Now, we take `veth-ns` and move it into the namespace you created.

```bash
sudo ip link set veth-ns netns ns-testing

```

*Note: Once you do this, `veth-ns` will disappear from your root `ip link` output. 
It is now safely locked inside the namespace.*

### 4. Configure the Interfaces

Now we need to give them IP addresses and bring them "up."

**Inside the namespace:**

```bash
sudo ip netns exec ns-testing ip addr add 192.168.10.1/24 dev veth-ns
sudo ip netns exec ns-testing ip link set veth-ns up
sudo ip netns exec ns-testing ip link set lo up

```

**On the host (Root namespace):**

```bash
sudo ip addr add 192.168.10.2/24 dev veth-host
sudo ip link set veth-host up

```

---

## 5. Verify and Use

To run any command inside your namespace, you use `ip netns exec <name> <command>`.

* **Test connectivity:**
```bash
sudo ip netns exec ns-testing ping 192.168.10.2

```


* **Verify the routing table inside:**
```bash
sudo ip netns exec ns-testing ip route

```


* **Run a server (like iperf3) inside:**
```bash
sudo ip netns exec ns-testing iperf3 -s

```



---

## Pro-Tips for the High-Speed Engineer

* **Don't Forget the Loopback:** 
    A common "gotcha" is forgetting to bring up the loopback (`lo`) interface inside the namespace. 
    Many network services will fail to start if they can't bind to `127.0.0.1`.

* **Isolation is Absolute:** 
    You can run `iptables` inside `ns-testing` to block traffic without affecting your host's firewall rules.

* **Cleaning Up:** 
    If you delete the namespace (`sudo ip netns del ns-testing`), the virtual interface (`veth-ns`) inside 
    it is automatically destroyed by the kernel. 
    You only need to clean up `veth-host` manually.

---

# Connecting multiple namespaces to Linux Bridge:

Example Using a DAC (Direct Attach Copper) cable to loop back both ports of a ConnectX-5 is the 
"gold standard" for testing throughput and stability. 
It gives you a controlled, isolated environment to stress-test your PCIe lanes, driver performance, and 
CPU interrupts without involving the rest of your network.

To connect multiple namespaces together using a Linux Bridge, think of the Bridge as a **virtual switch** 
that exists inside your kernel. You can plug your namespaces into this switch, and they will be able to 
communicate with each other just like physical machines connected to a hardware switch.

---

## The Lab Setup: Bridge and Namespaces

Here is how to create a virtual network where two namespaces can talk to each other via a bridge.

### 1. Create the Bridge

The bridge acts as the central hub.

```bash
sudo ip link add br0 type bridge
sudo ip link set br0 up

```

### 2. Create the Namespaces

We will create two namespaces: `ns-alpha` and `ns-beta`.

```bash
sudo ip netns add ns-alpha
sudo ip netns add ns-beta

```

### 3. Connect Namespaces to the Bridge

We use a veth pair for each namespace. One end goes to the namespace, the other plugs into the bridge.

**For ns-alpha:**

```bash
# Create the veth pair
sudo ip link add veth-alpha type veth peer name veth-alpha-br

# Move one end into the namespace
sudo ip link set veth-alpha netns ns-alpha

# Plug the other end into the bridge
sudo ip link set veth-alpha-br master br0
sudo ip link set veth-alpha-br up

```

**For ns-beta:**

```bash
# Create the veth pair
sudo ip link add veth-beta type veth peer name veth-beta-br

# Move one end into the namespace
sudo ip link set veth-beta netns ns-beta

# Plug the other end into the bridge
sudo ip link set veth-beta-br master br0
sudo ip link set veth-beta-br up

```

### 4. Configure IPs inside the Namespaces

Now, define the IP addresses for these virtual interfaces.

```bash
sudo ip netns exec ns-alpha ip addr add 192.168.100.1/24 dev veth-alpha
sudo ip netns exec ns-alpha ip link set veth-alpha up
sudo ip netns exec ns-alpha ip link set lo up

sudo ip netns exec ns-beta ip addr add 192.168.100.2/24 dev veth-beta
sudo ip netns exec ns-beta ip link set veth-beta up
sudo ip netns exec ns-beta ip link set lo up

```

---

## How to Test This

You now have a fully functional virtual switch. You can verify connectivity by pinging from one namespace 
to the other:

```bash
sudo ip netns exec ns-alpha ping 192.168.100.2

```

### Integrating your ConnectX-5 (The DAC Loopback)

By using DAC cable to connect the physical ports of a ConnectX-5, similar to connecting ethernet ports using 
a cross-over cable, you can "bridge" your physical interface into this virtual network too. 

If you attach one of your ConnectX-5 interfaces (`enp...`) to `br0`, traffic from your namespaces will be 
able to exit out of your physical cable and hit the other port of the ConnectX-5.

**Add physical port to the bridge:**

```bash
sudo ip link set enpXXs0 master br0

```

*(Warning: Be careful with bridging physical interfaces to prevent network loops if your card is also connected to a real switch!)*

---

### Pro-Tip for 25G Testing

When you test the throughput between namespaces through the bridge, notice that it uses the CPU to route 
packets. Since you are targeting 25 Gbps, you might notice the CPU usage spike significantly. 

If you want to see if the NIC can handle the load at line rate without software switching overhead, you would
skip the bridge and test directly between two namespaces assigned to separate physical interfaces 
(using `ip netns exec <ns> ip link set <interface> netns <ns>`).

Next: Measure the CPU overhead difference between using a Linux bridge vs. a direct point-to-point namespace
connection:

---

# CPU monitor while stress testing:


`mpstat` is for general CPU monitoring, and it’s excellent for spotting that dreaded high
`%soft` (SW interrupt) usage that plagues 25 Gbps links. 

However, at 25 Gbps, `mpstat` only tells you *that* you have a problem—it doesn't tell you *where* the 
traffic is bottlenecked.

To go "pro," you need to bridge the gap between CPU usage and the Network Interface Card (NIC). 

---

## 1. The Bottleneck: The "Interrupt Storm"

When you push 25 Gbps, the biggest enemy is **unbalanced interrupts**. 
If your NIC is configured incorrectly, all network traffic might hit a single CPU core, causing that core to
max out at 100% while the others sit idle.

### The Pro Workflow:

1. **Monitor Interrupt Distribution:**
Check if the NIC's IRQs (Interrupt Requests) are being spread evenly across all cores.
```bash
watch -d "cat /proc/interrupts | grep mlx5"

```

*Look for the column corresponding to your cores. If one core has an order-of-magnitude higher count than 
the others, you have an imbalance.*

2. **Optimize via `ethtool`:**
You need to ensure **Receive Side Scaling (RSS)** is active. 
This tells the NIC to hash incoming traffic and spread it across multiple queues (and thus, multiple CPU 
cores).

```bash
# Check current queue count
ethtool -l <interface_name>

# Check RSS hashing capabilities
ethtool -x <interface_name>

```
---

## 2. The Professional Monitoring Toolkit

Beyond `mpstat`, these are the tools senior network engineers use to diagnose high-speed performance:

| Tool | Focus | Why use it for 25G? |
| --- | --- | --- |
| **`perf top`** | Kernel Functions | Shows if your CPU is spending all its time on `napi_poll` or `netif_receive_skb`. |
| **`nicstat`** | NIC Statistics | Gives a high-level, clear view of throughput, packets, and errors per second. |
| **`ss -nmp`** | TCP Socket Metrics | Vital if you are using TCP; tells you about congestion window (`cwnd`) and RTT. |
| **`bpftrace`** | Deep Kernel Tracing | The gold standard. You can write scripts to measure latency of specific function calls in the kernel. |

---

## 3. The "Pro" Strategy for Namespace Testing

Since you are using namespaces, the complexity multiplies. 
You aren't just managing the physical NIC; you are managing the virtual traffic going through the kernel's 
**software bridge** (or `veth` pairs).

**The Professional Diagnostic Loop:**

1. **Isolate the bottleneck:** 
    - Use `top` or `htop` to see if the CPU spike is on the physical NIC interrupt or the `ksoftirqd` process 
    handling the virtual switch.

2. **Trace the path:** 
    - If the performance is poor, use `perf` to see where the CPU cycles are going. 
    - If you see high time spent in `dev_queue_xmit`, the software bridge is struggling to pass packets to the namespace.

3. **Use `ethtool` statistics:** Don't trust the interface counters alone. Look at the "drop" counters
   specifically: 

```bash
ethtool -S <interface_name> | grep -E "drop|discard|err"

```

### A Note on `irqbalance`

On most Linux distros, a daemon called `irqbalance` is running by default. 

**At 25 Gbps, kill it.** `irqbalance` is designed for general-purpose workloads. 
For high-speed networking, you want to manually pin your NIC queues to specific CPU cores (affinity) using 
the `smp_affinity` settings in `/proc/irq/`. 

This ensures deterministic performance, which is exactly what you need for consistent 25G benchmarks.

---

**Next Steps for You:**
If you want to see if your ConnectX-5 is currently optimized, run `ethtool -l [interface]` to see how many 
queues are currently assigned, and `cat /proc/interrupts` to see if they are actually being utilized evenly.

Next: Manual interrupt affinity pinning setup to bypass `irqbalance` and ensure your cores are handling the 
load perfectly:

---

# Disable `irqbalance` daemon:

Moving away from `irqbalance` is the step that separates standard server admin from high-frequency network 
engineering. 

When you manually pin IRQs, you create a deterministic "path" for the data, minimizing cache misses and 
cross-socket latency.

Before we begin, a critical reminder: **Always respect NUMA topology.** 

If your NIC is physically connected to the PCIe lanes of CPU 0, pinning interrupts to cores on CPU 1 will 
force traffic to cross the inter-connect (QPI/UPI), which will introduce latency and likely throttle your 
25 Gbps throughput.

---

## 1. Disable the Disruptor

First, stop the daemon that tries to "helpfully" rebalance interrupts while you're trying to set them.

```bash
sudo systemctl stop irqbalance
sudo systemctl disable irqbalance

```

## 2. Identify the IRQs and NUMA Node

Find which NUMA node your ConnectX-5 is on.

```bash
cat /sys/class/net/enpXXs0/device/numa_node

```

*If it returns `0`, only pin to cores on CPU 0. If `1`, only pin to cores on CPU 1.*

Now, grab the list of interrupts for your interface:

```bash
grep "mlx5" /proc/interrupts

```

*Note: This will output a list of IRQ numbers (the first column).*

## 3. The "Pro" Pinning Script

Instead of doing this manually, use this script to iterate through the queues and pin them sequentially to 
specific CPU cores. This example assumes you want to pin queues to **Cores 0-7**.

```bash
#!/bin/bash
# Interface name
IFACE="enpXXs0"
# List of cores to pin to (Example: 0,1,2,3,4,5,6,7)
CORES=(0 1 2 3 4 5 6 7)

# Get the IRQs for the specific interface
IRQS=$(cat /proc/interrupts | grep "$IFACE" | awk '{print $1}' | sed 's/://')

i=0
for irq in $IRQS; do
    # Get the core index
    core=${CORES[$i % ${#CORES[@]}]}
    echo "Pinning IRQ $irq to CPU $core"
    
    # Write the core hex mask to smp_affinity_list
    echo $core | sudo tee /proc/irq/$irq/smp_affinity_list
    
    ((i++))
done

```

### Why this works:

* **Deterministic Behavior:**
    - Every time you run this, the same packet queue hits the same CPU core. 
    - The CPU's L1/L2 cache becomes "warmed up" to that specific traffic flow.

* **Avoids `ksoftirqd` contention:** 
    By pinning to specific, separate cores, you prevent multiple queues from competing for CPU cycles on the
    same logical processor.

---

## 4. Verification

After running the script, keep an eye on the interrupt distribution. 

Run this command while your `iperf3` test is running:

```bash
watch -d "cat /proc/interrupts | grep mlx5"

```

**What you want to see:**

* The interrupt counts (the columns under the CPU numbers) should be increasing at a **consistent rate** 
  across all the cores you assigned.
* If one core is jumping by 10,000s and others are stuck at 0, your pinning didn't "take" (often because `irqbalance` restarted or the interface was reset).

---

## Pro-Level "Gotcha": The PCIe Bus

Since you are testing a 25G link, if you are seeing high packet loss but the CPU usage on the pinned cores 
is low, you might be hitting a **PCIe bandwidth limit** or **Buffer Exhaustion** on the card itself.

Check for "Discards" or "Errors" using:

```bash
ethtool -S <interface_name> | grep -E "rx_discards|rx_errors"

```

If these numbers are climbing while you test, no amount of CPU pinning will fix it—you have a physical 
bottleneck (cable, transceiver, or PCIe slot speed).

