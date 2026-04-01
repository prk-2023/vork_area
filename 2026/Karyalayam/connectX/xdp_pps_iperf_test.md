1. mpstat

| mpstat |
| :--- | 
|11:53:27 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle|
|11:53:28 AM  all    0.58    0.58    7.80    0.00    0.17    6.06    0.00    0.00    0.00   84.81|
|11:53:28 AM    0    0.00    1.02   20.41    0.00    1.02    9.18    0.00    0.00    0.00   68.37|
|11:53:28 AM    1    0.00    3.96    1.98    0.00    0.00    0.99    0.00    0.00    0.00   93.07|
|11:53:28 AM    2    0.00    0.00    0.00    0.00    0.00    1.01    0.00    0.00    0.00   98.99|
|11:53:28 AM    3    0.00    0.00    1.69    0.00    0.00   51.69    0.00    0.00    0.00   46.61|
|11:53:28 AM    4    1.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   98.00|
|11:53:28 AM    5    1.01    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   98.99|
|11:53:28 AM    6    3.03    0.00   21.21    0.00    0.00    0.00    0.00    0.00    0.00   75.76|
|11:53:28 AM    7    0.00    0.00    4.04    0.00    0.00    0.00    0.00    0.00    0.00   95.96|
|11:53:28 AM    8    0.00    1.00    0.00    0.00    1.00    1.00    0.00    0.00    0.00   97.00|
|11:53:28 AM    9    1.08    0.00   48.39    0.00    0.00    0.00    0.00    0.00    0.00   50.54|
|11:53:28 AM   10    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00|
|11:53:28 AM   11    1.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   99.00|

Single card:
1.
Port0: Host system network
3: enp1s0f0np0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 xdp/id:122 qdisc mq state UP group default qlen 1000
    link/ether 6c:b3:11:88:55:b4 brd ff:ff:ff:ff:ff:ff
    altname enx6cb3118855b4
    inet 10.0.0.9/24 scope global enp1s0f0np0
       valid_lft forever preferred_lft forever
2.
Port1:
sudo ip netns add ns1
sudo ip link set enp1s0f1np1 netns ns1
sudo ip netns exec ns1 ip addr add 10.0.0.99/24  dev enp1s0f1np1
sudo ip netns exec ns1 ip link set enp1s0f1np1 up

NOTE: libpf-rs and aya fail to bind connectx interface when MTU set to 9000
      libbpf+C works Since:
      For bpf_set_link_xdp_fd(ifindex, fd, flags)  if we pass 0 as C flag and thekernel uses best
      effort approach. 
      On many drivers if Native (DRV) mode fails because the constrain like MTU, the kernel will
      silently fall back to Genric Mode (SKB) and the attachment is success. 

TODO: Check Why Rust loader fails to attach. ( related to Rust security checking ? )

- Buffer Constraint: ConnectX hardware uses a specific memory page layout for its Receive Queue (RQ).
- The Math: Setting MTU to 9000 (Jumbo Frames), the pkt plus the required XDP headroom 
  often exceeds the size of a single standard memory page ($4\text{ KB}$) or the driver's
  pre-allocated stride size.
- The Result: Instead of trying to "guess" how to split the packet, the driver simply returns -EINVAL
  (Invalid Argument) during the attachment phase because it cannot guarantee a linear buffer that fits
  both the huge packet and the XDP overhead.

3.
Host> ipref3 server
ns1>  iperf3 client

TCP :
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  27.3 GBytes  23.4 Gbits/sec  1329            sender
[  5]   0.00-10.00  sec  27.3 GBytes  23.4 Gbits/sec                  receiver

pps :
PPS: 1519532
PPS: 2021763
PPS: 2022998
PPS: 2026346
PPS: 2029354
PPS: 2029849
PPS: 2026800
PPS: 2028242
PPS: 2026230
PPS: 2018639
PPS: 488035

so average pps ~ 2025000

verification:
packet size = bitrate/(pps * 8)
            = 23400000000/(2025000 * 8)
            = 1,444 bytes

Standard mtu : 1500 bytes
tcp overhead (20 bytes ) + ipv4 overhead (20bytes) ==> actual payload 1460
this is close to the calculated value.

4. cpu load: 15% for 23.4 Gbps processing.

mpstat -P ALL 1

11:53:27 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
11:53:28 AM  all    0.58    0.58    7.80    0.00    0.17    6.06    0.00    0.00    0.00   84.81
11:53:28 AM    0    0.00    1.02   20.41    0.00    1.02    9.18    0.00    0.00    0.00   68.37
11:53:28 AM    1    0.00    3.96    1.98    0.00    0.00    0.99    0.00    0.00    0.00   93.07
11:53:28 AM    2    0.00    0.00    0.00    0.00    0.00    1.01    0.00    0.00    0.00   98.99
11:53:28 AM    3    0.00    0.00    1.69    0.00    0.00   51.69    0.00    0.00    0.00   46.61
11:53:28 AM    4    1.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   98.00
11:53:28 AM    5    1.01    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   98.99
11:53:28 AM    6    3.03    0.00   21.21    0.00    0.00    0.00    0.00    0.00    0.00   75.76
11:53:28 AM    7    0.00    0.00    4.04    0.00    0.00    0.00    0.00    0.00    0.00   95.96
11:53:28 AM    8    0.00    1.00    0.00    0.00    1.00    1.00    0.00    0.00    0.00   97.00
11:53:28 AM    9    1.08    0.00   48.39    0.00    0.00    0.00    0.00    0.00    0.00   50.54
11:53:28 AM   10    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
11:53:28 AM   11    1.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   99.00

2026/03/20:
---
| Category  | Task  | Progress | Description |Comments|
| :--- | :--- | :--- | ---: | :--- |
|XDP| Performance, HW Assistence| On-Going |XDP Support Modes :  1. Offload Mode: Host cpu 100% free, eBPF code runs on NIC's Internal processor. 2. Native mode: ConnectX 3,4,5,7 eBPF program runs on the Host CPU but inside the driver before the kernel allocates an `sk_buff`.  3. SKB Mode: fallback mode if driver has no XDP support, kernel alredy converted the raw pkt to `sk_buff`, eBPF prog runs in `netif_receive_skb()`. Hardware optimizations like Multi-packet WQE and Striding RQ. Includes AF_XDP Zero-Copy support for host-based packet processing.| "Focus is on ""Hardware Assist"" for XDP running on the Host CPU, not on-card execution."|
|XDP (RoCEV2 like smarter data path) | AF_XDP address family (kerenel) or Zero-Copy | On-Going | Implement a programmable alternative to RDMA/RoCE. Uses AF_XDP to redirect pkts to User-Space application Memory (UMEM), it can also allows custome protocol parsing and filtering before data reaches application. | |
|XDP vs DPDK | AF_XDP (Zero-Copy) vs DPDK | On-going| High-performance per-packet redirection to user-space. Differs from DPDK's batch-polling, uses eBPF to make real-time decisions before zero-copy DMA. |DPDK Polling mode consumes Host CPU even with no traffic. AF_XDP wakes up only when packet arrives. Power efficient then DPDK|

## snic: meeting:

### Optimization Philosophy: Performance via HW Assistance
####  1. The primary scope is to leverage Hardware-Assisted XDP to achieve near line-speed packet processing. By offloading the 'decision-making' to the earliest possible stage, we minimize CPU cycles per packet while maintaining the flexibility of a software-defined control plane.
####  2. This allows the ASIC to handle the "heavy lifting" (like checksums/parsing) while the CPU handles the "intelligence."

### The Architecture: Native Mode Efficiency

#### 1. "By utilizing XDP Native Mode, we intercept traffic in the driver's 'receive path' before the expensive overhead of Linux Kernel sk_buff allocation. This 'Early Hook' architecture allows for immediate actions—such as XDP_DROP, XDP_TX (hairpin), or XDP_REDIRECT—directly within the NIC's DMA ring."
#### 2. This reduces the "Instruction Per Packet" (IPP) count significantly compared to standard kernel networking.

### Data Delivery: "Programmable Zero-Copy" (AF_XDP)

#### 1. We treat AF_XDP (Zero-Copy mode) as a Programmable RDMA alternative. Unlike fixed-function RoCE, AF_XDP allows us to use eBPF to dynamically steer specific traffic flows directly into user-space application memory (UMEM). This provides the performance of a 'Kernel Bypass' while retaining full programmability of the ingress pipeline.
#### 2.  You gain the latency benefits of RoCE without being locked into its fixed protocol constraints.
#### 3.  AF_XDP is "Application-Agnostic." Unlike RoCE, which often requires specific hardware/drivers on both ends of the wire, your XDP program can talk to any standard Ethernet sender while still getting that "Direct-to-App" speed on your end.

### ToDo:
- What's required for XDP native driver support 
- Mpps vs. CPU usage
- AF_XDP  Vs RDMA/RoCE
- AF_XDP Vs DPDK
---
---
