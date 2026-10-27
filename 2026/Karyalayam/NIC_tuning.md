# Linux NIC-to-socket packet processing: tuning and troubleshooting guide

**Linux bare-metal servers and VMs · High-throughput and low-latency workloads**

## 1. Understand the packet-drop counters first

```text
RX: bytes       packets   errors  dropped  missed
    946618814   916712    0       8239     0
```


The interface reports 8,239 RX drops out of 916,712 received packets, approximately 0.90% of the reported RX
packet count. This is worth investigating, but the snapshot alone does not establish the cause or whether
those drops occurred in the hardware or software path.



| Counter | What it generally indicates |
| :--- | :--- |
| `RX errors` | Receive errors reported by the interface or driver, such as malformed frames or other hardware/driver errors. |
| `RX dropped` | Packets discarded at the interface/driver accounting layer; the exact meaning depends on the driver. |
| `RX missed` | Receive packets missed by the hardware, often because receive resources were unavailable; interpretation is driver-specific. |
| `netstat -s`/`nstat` | Protocol-level statistics, including TCP errors, retransmissions, and other IP/TCP events. |
| `ethtool -S` | Driver- and device-specific counters, often the best source for distinguishing queue drops, missed packets, and hardware errors. |


Important: `ip -s link` does not, by itself, prove that the RX ring is overflowing. 

Check detailed driver counters and compare counter deltas over a representative traffic interval. 

A nonzero cumulative counter may reflect an earlier event rather than a current bottleneck.

Useful diagnostic commands:

```bash
IF=enp3s0

ip -s -s link show dev "$IF"
sudo ethtool -S "$IF"
sudo ethtool -g "$IF"
sudo ethtool -l "$IF"
sudo ethtool -k "$IF"

nstat -az
cat /proc/net/softnet_stat
cat /proc/interrupts
mpstat -P ALL 1
```

For accurate before-and-after comparisons, record the counters, run a representative workload, and record
them again. Look for which counters increase during the drop event, rather than relying on absolute
historical totals.


## 2. Packet-processing path: wire to application socket

1. Physical link and NIC receive hardware

Ethernet frames arrive; PHY/MAC and hardware resources receive them.

2. NIC RX descriptor ring + DMA buffers

NIC DMA writes packet data into host memory using posted receive buffers.

Potential loss: no available descriptors/buffers, hardware overrun, or device-specific resource exhaustion.

3. MSI-X interrupt moderation and NAPI polling

Interrupts notify the driver; NAPI polls RX queues and processes packets in batches.

4. Linux receive processing and protocol stack

Driver, optional GRO, routing, netfilter, IP, TCP/UDP and socket demultiplexing.

Potential loss: per-CPU backlog overflow, protocol errors, filtering, or resource exhaustion.

5. TCP/UDP socket receive queue

Data waits for the application to read it; TCP receive-window and socket-memory limits can affect throughput.

6. User-space application

recv()/recvmsg(), epoll, io\_uring, or an application-specific receive loop.

This is a logical pipeline, not a strict one-packet-at-a-time sequence. Modern Linux uses DMA, interrupt
moderation, NAPI batching, per-CPU processing, and optional offloads. Some work happens concurrently.

A few important distinctions:

- The NIC RX ring is not the same as `net.core.netdev_max_backlog`. The former is a device
  receive-descriptor queue; the latter limits packets queued on the software input backlog.
- NAPI is not simply a hardware interrupt queue. An interrupt typically schedules polling, after which the
  driver processes packets in batches.
- Socket receive memory is downstream of NIC reception. Increasing `rmem_max` does not directly fix hardware
  RX-ring exhaustion.
- CPU frequency is not the only relevant CPU factor. Packet rate, single-core saturation, IRQ distribution,
  cache locality, NUMA placement, and application scheduling can all be bottlenecks.

For the kernel's official explanation of RSS, RPS, RFS and queue distribution, see the [Linux networking
scaling documentation](<https://docs.kernel.org/networking/scaling.html>).


## 3. Diagnose the bottleneck before changing settings

Use this decision table to select the next investigation.

| Observation during load | Likely investigation |
| :--- | :--- |
| NIC missed/no-buffer counters increase | RX ring sizing, RX queue count, interrupt moderation, PCIe/device limits, driver behavior |
| One RX queue is overloaded while others are quiet | RSS hash/indirection table, queue count, IRQ affinity |
| `/proc/net/softnet_stat` shows increasing drops | Per-CPU input backlog saturation, CPU processing capacity, RPS configuration |
| One CPU has high `%soft` or `ksoftirqd` activity | IRQ distribution, RSS/RPS, packet rate, expensive protocol/filtering work |
| TCP retransmissions rise | Packet loss, congestion, network path, MTU issues, or receiver overload; not necessarily local RX-ring overflow |
| Packets reach the host but application reads lag | Application scheduling, socket queueing, receive-loop performance, socket memory |
| Only one high-rate flow is slow | A single RSS flow generally remains on one RX queue; adding queues alone may not distribute that flow |

Commands to examine CPU and queue behavior:


```bash
# CPU utilization, including software interrupt load
mpstat -P ALL 1

# Interrupts by CPU and device queue
watch -n 1 cat /proc/interrupts

# Per-interface queue counts
ls -l /sys/class/net/enp3s0/queues/

# RX/TX queue distribution and device statistics
sudo ethtool -S enp3s0

# Link speed, duplex, and negotiated link state
sudo ethtool enp3s0

# Protocol statistics and TCP retransmission counters
nstat -az
```

The correct response depends on the counter that is growing. A larger buffer can absorb a short burst, but
it cannot permanently compensate for a sustained packet-processing rate that is lower than the arrival rate.

## 4. Tune NIC RX/TX ring buffers

### 4.1 Inspect the supported values

Use the actual interface name on your server. Your sample interface is `enp3s0`; `enp1s0f0np0` in the
original example is a different interface name.

```bash
IF=enp3s0

sudo ethtool -i "$IF"
sudo ethtool -g "$IF"
```

Example output:

text

```
Pre-set maximums:
RX: 8192
TX: 8192

Current hardware settings:
RX: 1024
TX: 1024
```

The maximum is driver/device-dependent. Do not assume every NIC supports 4,096 or 8,192 entries.

### 4.2 Increase the RX ring when diagnostics justify it

For ex: try increasing RX from 1,024 to 4,096 if the driver supports it and RX-ring exhaustion is indicated:

```bash
sudo ethtool -G "$IF" rx 4096
sudo ethtool -g "$IF"
```

You can also change TX ring entries if transmit-side congestion or queue starvation is indicated:


```bash
sudo ethtool -G "$IF" tx 4096
```

Use the highest supported value only when testing demonstrates a benefit. Some drivers round requested
values, impose alignment constraints, or require a device reset.

Corrections to the original document:

- An RX ring is generally a descriptor ring in host memory associated with DMA buffers, not simply a small
  buffer stored entirely inside the NIC.
- Increasing from 1,024 to 4,096 gives four times as many descriptor entries, not eight times. The effective
  packet buffering capacity also depends on buffer layout, descriptor use, and packet sizes.
- More entries may absorb short bursts, but they cannot eliminate sustained overload. They may also increase
  queueing latency and memory consumption.
- TX ring tuning is not a direct fix for incoming packet drops.

The supported ring parameters and their semantics are documented in the [`ethtool`
manual](<https://man7.org/linux/man-pages/man8/ethtool.8.html>).

## 5. Configure hardware offloads

First inspect the features that the driver supports and whether they are active:

```bash
sudo ethtool -k "$IF"
```

For a typical TCP server, the following features are often beneficial when supported:


```bash
sudo ethtool -K "$IF" gro on
sudo ethtool -K "$IF" tso on
sudo ethtool -K "$IF" gso on
sudo ethtool -K "$IF" rx on
sudo ethtool -K "$IF" tx on
```

If you need VLAN acceleration and your driver supports it, check the current state before changing it:


```bash
sudo ethtool -K "$IF" rxvlan on txvlan on
```

Some options may be fixed, unsupported, or controlled by another feature. Confirm the result with `ethtool -k`.

| Feature | Function | Main benefit |
| --- | --- | --- |
| GRO | Combines compatible incoming packets in software in the receive path | Reduces per-packet protocol-processing overhead |
| LRO | Larger receive aggregation, commonly implemented in hardware or the driver | Can reduce CPU overhead, but may be unsuitable for forwarding or some workloads |
| GSO | Allows the stack to handle large logical packets before segmentation | Reduces overhead from processing individual packets |
| TSO | NIC segments large TCP transmit packets into MTU-sized frames | Reduces transmit CPU work |
| RX/TX checksum offload | NIC computes or validates supported checksums | Reduces checksum-processing work |


Two corrections matter here:

1. GRO is not necessarily hardware reassembly. Linux software GRO is common; hardware-supported aggregation
   is device-dependent.
2. TSO is a transmit optimization, not a direct RX-ring fix. It does not inherently improve incoming packet
   handling, and a universal CPU reduction such as “50%” cannot be promised.

For high-packet-rate UDP, packet forwarding, packet capture, or latency-sensitive workloads, test offload
behavior under the actual workload. The best configuration can differ from a conventional TCP application
server.

## 6. Configure RSS, hardware queues, and IRQ affinity

This is an important missing section in your original document.

For many high-throughput servers, Receive Side Scaling (RSS) and multiple hardware RX queues should be
evaluated before enabling RPS across every CPU. RSS distributes flows among NIC receive queues in hardware;
queue/interrupt configuration then determines where much of the initial packet processing happens.


### 6.1 Check the available queue configuration


```bash
sudo ethtool -l "$IF"
ls -l /sys/class/net/"$IF"/queues/
grep -i "$IF" /proc/interrupts
```

If the NIC supports multiple combined channels, you can test a suitable count:


```bash
sudo ethtool -L "$IF" combined 8
```

This is only an example. The NIC may support fewer channels, separate RX/TX channel types, or a different
configuration. Do not blindly allocate one queue per CPU: benchmark queue count and CPU placement,
especially on NUMA systems.

### 6.2 Check interrupt distribution


```bash watch -n 1 cat /proc/interrupts ```

Look for RX-related interrupts accumulating on one CPU while others remain idle. Review the active
`irqbalance` configuration before manually assigning IRQ affinity, because `irqbalance` may subsequently
change the placement.

The objective is to distribute work sensibly across available RX queues and CPUs while preserving cache and
NUMA locality—not to force all traffic onto CPU 0 or to spread every operation across all CPUs
indiscriminately.

## 7. Configure RPS and RFS when appropriate

RPS is a software mechanism for steering received packets to CPUs for further protocol processing. It can
help when the NIC has fewer hardware queues than useful processing CPUs, but it adds inter-processor
communication overhead.

If RSS already distributes hardware queues effectively across CPUs, RPS may be redundant.


### 7.1 Configure RPS selectively

Inspect each receive queue:


```bash
for f in /sys/class/net/"$IF"/queues/rx-*/rps_cpus; do
    printf '%s: ' "$f"
    cat "$f"
done
```

Your original example writes `ffff`, which represents CPUs 0–15 only on systems using the usual hexadecimal
CPU bitmap interpretation. It is not a portable way to select every CPU on every server.

On systems where RPS is beneficial, choose a CPU mask based on the CPUs available to the workload, hardware
IRQ placement, and NUMA topology. For example, to enable RPS on CPUs 0–7:


```bash
for f in /sys/class/net/"$IF"/queues/rx-*/rps_cpus; do
    echo 00ff | sudo tee "$f" >/dev/null
done
```

This is an example mask, not a universal recommendation. It is also a runtime setting and may need to be
reapplied after reboot.

### 7.2 Consider RFS for application locality

Receive Flow Steering (RFS) extends the steering approach by trying to process flows on CPUs where the
consuming application runs. It can help workloads with many concurrent flows, but it requires additional
configuration and testing.

Do not enable RPS, RFS, and accelerated RFS indiscriminately. First establish the hardware queue
distribution and the application's CPU affinity, then test whether software steering improves throughput or
latency.

## 8. Tune kernel backlog and networking budgets

Create `/etc/sysctl.d/99-network-throughput.conf` only after collecting baseline measurements. The following
is a starting profile for a high-throughput server, not a universal production configuration:


```bash
# Software input backlog per CPU
net.core.netdev_max_backlog = 10000

# Per-cycle receive processing limits
net.core.netdev_budget = 300
net.core.netdev_budget_usecs = 2000

# Maximum socket buffer limits (64 MiB)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864

# Default socket buffers (128 KiB starting values)
net.core.rmem_default = 131072
net.core.wmem_default = 131072

# TCP receive and send buffer autotuning limits
net.ipv4.tcp_rmem = 4096 131072 67108864
net.ipv4.tcp_wmem = 4096 131072 67108864
```

Apply and verify:

```bash
sudo sysctl --system

sysctl net.core.netdev_max_backlog
sysctl net.core.netdev_budget
sysctl net.core.netdev_budget_usecs
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem
```

### What these parameters actually do

- `net.core.netdev_max_backlog`: maximum packets queued on the software input backlog when packets arrive
  faster than the kernel can process them.
- `net.core.netdev_budget`: packet-processing budget for a NAPI/softirq processing cycle.
- `net.core.netdev_budget_usecs`: time limit for that processing cycle.
- `net.core.rmem_max` and `wmem_max`: maximum socket buffer sizes permitted through the relevant socket
  interfaces.
- `net.ipv4.tcp_rmem` and `tcp_wmem`: minimum, initial/default, and maximum TCP receive/send buffer
  parameters.

The backlog is not a universal queue for every packet in the receive path. In particular, the NAPI
processing budget is not simply the size of the software backlog. Increasing these values can help under
certain conditions, but can also increase CPU occupancy and queueing latency.


### Socket memory is not the same as the NIC ring

Your original configuration sets `rmem_default` and `wmem_default` to 32 MiB. That can be unnecessarily
large as a system-wide default, especially with many sockets. A larger `rmem_max` is a permitted ceiling; it
does not mean every socket immediately allocates 64 MiB.

TCP receive autotuning is generally enabled by default. Application calls such as `setsockopt(SO_RCVBUF)`
can affect autotuning behavior and have their own accounting rules. For UDP, the application must also keep
up with incoming datagrams; increasing the buffer only provides more time to absorb a temporary mismatch.

For TCP throughput, consider the bandwidth-delay product (BDP):

$$
\text{BDP in bytes} =
\frac{\text{bandwidth in bits/s}\times\text{RTT in seconds}}{8}
$$

For example, a 10 Gbit/s path with a 10 ms RTT has a BDP of approximately 12.5 MB. That is useful context
for evaluating TCP windows and socket buffering, but it does not imply that every socket should use that
much memory.

## 9. Interrupt moderation and NAPI

Inspect the NIC's current interrupt-coalescing settings:


```bash
sudo ethtool -c "$IF"
```

Some devices support parameters such as `rx-usecs`, `rx-frames`, or adaptive RX coalescing. If supported,
you can test a modest change, for example:


```bash
sudo ethtool -C "$IF" adaptive-rx on
```

Use only settings reported as supported by the driver.

- More coalescing can reduce interrupt overhead and improve throughput under heavy load.
- Less coalescing can reduce receive latency but increase interrupt frequency and CPU consumption.
- NAPI processes packets in batches and may continue polling without one interrupt per packet.

There is no universally optimal coalescing value. Benchmark both throughput and latency
percentiles—particularly p99 and p99.9—rather than optimizing only packets per second.


## 10. Additional production considerations

### 10.1 NUMA locality and CPU placement

On multi-socket servers, NIC PCIe devices are usually attached to a particular NUMA node. Processing packets
on remote-node CPUs can increase memory-access and cache-coherency costs.


```bash
cat /sys/class/net/"$IF"/device/numa_node
lscpu
numactl --hardware
```

Aim to align NIC queues, IRQ handling, packet-processing threads, and memory allocation with the NIC's NUMA
node where practical. A NUMA node value of `-1` means the kernel does not report a specific node for that
device.

### 10.2 VM and virtual NIC considerations

In virtualized environments, the guest does not necessarily control the physical NIC's RX rings or hardware
queues.

Investigate both sides of the virtual boundary:

- Guest: vNIC queue count, guest CPU scheduling, vCPU availability, guest softirq load, socket queues.
- Host: physical NIC queues, host IRQ distribution, vhost threads, bridge/OVS processing, host CPU
  saturation.
- Virtualization configuration: virtio multiqueue, vCPU pinning, vhost-net, SR-IOV, or passthrough where
  appropriate.

Increasing a guest's virtual RX ring setting cannot necessarily increase the physical NIC's hardware ring
capacity.

### 10.3 Application receive-loop performance

The packet path does not end when the kernel receives the packet. The application must consume it.

Inspect:

- Whether receive threads are CPU-bound or frequently descheduled.
- Whether the application reads packets in efficient batches.
- Whether socket receive queues grow or overflow.
- Whether locks, memory allocation, logging, or per-packet processing dominate.
- Whether `epoll`, `io_uring`, `recvmmsg()`, or other batching approaches fit the workload.

For specialized packet-processing systems, technologies such as AF\_XDP, DPDK, or XDP may be worth
evaluating. These change the processing architecture and introduce additional operational trade-offs; they
are not simply another sysctl tuning knob.

### 10.4 TCP backlog and connection handling

For a server receiving many new TCP connections, distinguish connection-establishment pressure from
established-connection data processing.

Relevant settings include:


```bash
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_max_syn_backlog
```

The application's `listen()` backlog, SYN processing, and established socket receive buffers solve different
problems. Increase connection backlog limits only when evidence shows that connection queues are filling.

I would remove `net.ipv4.tcp_max_tw_buckets = 2000000` from the general tuning profile. TIME\_WAIT is not
the same as an RX packet-processing queue, and increasing this limit does not fix NIC drops. Adjust it only
when there is a specific, measured TIME\_WAIT management issue.


### 10.5 BBR and congestion control

BBR can be useful for some high-bandwidth or high-RTT TCP paths, but it is not a general-purpose NIC drop fix.

Check the supported algorithms before changing congestion control:


```bash
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
```

Do not force BBR, `fq`, or a specific congestion-control algorithm solely to eliminate RX drops. Evaluate
the actual end-to-end TCP workload, network path, fairness requirements, and latency behavior.

## 11. Corrected performance matrix

The following comparison describes intended tuning outcomes, not guaranteed results.

| Metric | Baseline | Tuned objective |
| --- | --- | --- |
| RX ring | Driver-specific default | Enough descriptors to absorb measured bursts |
| RX drops | Unknown until measured | No sustained unexplained drop-counter growth |
| Hardware queues | Default queue configuration | Appropriate RSS distribution and queue count |
| IRQ/softirq load | Potentially imbalanced | Balanced according to queue count and CPU topology |
| Software backlog | Default kernel setting | Sufficient capacity without excessive queueing delay |
| GRO/TSO/GSO | Driver/kernel defaults | Suitable offloads enabled and validated |
| Socket buffers | Kernel defaults and application settings | Enough buffering for the workload and network BDP |
| Application processing | Unmeasured | Application consumes packets at the required rate |
| Throughput | Workload-dependent | Target sustained throughput without unacceptable loss |
| Latency | Workload-dependent | Target p99/p99.9 latency with bounded queues |


Avoid claiming that a specific configuration guarantees zero drops, line-rate throughput, or a fixed
percentage improvement. Results depend on packet size, packets per second, NIC and driver capabilities, CPU
architecture, protocol mix, and application behavior.

## 12. Recommended tuning sequence

1. Establish a baseline

Capture `ethtool -S`, `ip -s -s link`, `/proc/net/softnet_stat`, `/proc/interrupts`, CPU utilization, packet
rate, throughput, and latency.

2. Fix the hardware receive path

Verify link speed, driver/firmware, supported RX ring sizes, queue count, RSS configuration, and NIC error
counters.

3. Tune CPU distribution

Examine IRQ affinity, NAPI/softirq saturation, NUMA placement, RSS, and whether RPS/RFS is actually needed.

4. Tune the kernel and socket layers

Adjust backlog and NAPI budgets only when indicated; validate offloads and socket-buffer behavior under the
real workload.

5. Benchmark and validate

Compare packets per second, throughput, drop-counter deltas, CPU usage, and latency percentiles. Change one
group of settings at a time and retain a rollback configuration.

## 13. Quick reference: commands to retain in your runbook


```bash
# Identify the NIC and driver
ip -br link
sudo ethtool -i "$IF"
sudo ethtool "$IF"

# Rings, channels, offloads, and interrupt moderation
sudo ethtool -g "$IF"
sudo ethtool -l "$IF"
sudo ethtool -k "$IF"
sudo ethtool -c "$IF"

# Device-specific errors and queue counters
sudo ethtool -S "$IF"

# Interface and protocol counters
ip -s -s link show dev "$IF"
nstat -az

# CPU, softirq, and interrupt distribution
mpstat -P ALL 1
cat /proc/softirqs
cat /proc/interrupts
cat /proc/net/softnet_stat

# NIC queue directories and NUMA topology
ls /sys/class/net/"$IF"/queues/
cat /sys/class/net/"$IF"/device/numa_node
```

Final recommendation: Start with the 8,239 RX drops shown in your sample, but do not immediately apply every
tuning parameter in the original document. First establish which counters increase under load. If hardware
missed/no-buffer counters grow, investigate RX queues and ring sizing. If softnet drops grow, investigate
software backlog and CPU processing. If packets reach the socket but the application falls behind, focus on
socket buffering and application consumption.

That approach is more reliable than maximizing every buffer and enabling every steering mechanism—and it is
much more likely to improve real throughput without introducing unnecessary latency or resource consumption.
