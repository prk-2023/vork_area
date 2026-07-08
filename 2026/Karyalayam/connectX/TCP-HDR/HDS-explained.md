https://networking-docs.nvidia.com/kernelupstreamrn/617/changes-and-new-features#:~:text=TCP%20Zero%20Copy,N%2FA

NV's Header Data Split is implemented in the kernel as TCP Zero Copy.
我們正在討論要不要做這各...我覺得這個是有用的...但需要數據證明..
 
There might be two directions to test...
1. Using kernel driver: Then test the RX to see CPU usage
2. Tested with DPDK

DPDK can be used to test PPS performance... then observe the impact of RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT.

I think this is very important... But I just can't convince the inside... Ha... We need data to help
I found a paper from 2020... There is also data:
https://netdevconf.info/0x14/pub/slides/36/storage_application_performance_boost.pdf
IOPS increased from 680K to 1.4M IOPS


If you want to test kernel-level TCP zero copy, you can refer to this tool.
https://github.com/torvalds/linux/blob/master/tools/testing/selftests/net/tcp_mmap.c
The existing iperf seems to only implement TX side zero copy


-----------------------------------------

# TCP Zero-Copy:

TCP Zero Copy on NVIDIA ConnectX-7 and newer ConnectX adapters is recevice side optimization built
around **Header-Data Split ( HDS )**

Its goal is to eliminate unnecessary memory copies for TCP payloads while still allowing OS to efficiently
process packet headers.

This feature is a particularly valuable in:
- High performance storage ( NVMe-Over TCP )
- AI data pipelines
- High speed web servers
- Database servers
- DPDK/SPDK based applications
- Linux networking stack at 100/200/400 GbE 

**Why Zero Copy matters:**

- Normally when TCP packet arrives, several memory operations occur. 

**Traditional receive path **: Suppose a packet arrives:
```
+-----------------------------+
| Ethernet | IP | TCP | DATA |
+-----------------------------+
```
The NIC DMA-writes the entire packet into receive buffer. 
Later Linux TCP stack copies the payload into the application's receive buffer:
```
        NIC
        │
        │ DMA
        ▼
    Kernel RX Buffer
        │
        │ memcpy()
        ▼
    Application Buffer
```
The memcpy() operation becomes expensive:
For example:
    - 100 Gbps = 12.5 GB/sec
    - copying 12.5 GB/sec consumes enormous CPU bandwidth. 
    - CPU Cache pollution increases.
    - Memory bandwidth becomes the bottleneck instead of the network. 
At 200-400 Gbps, memory copying can dominate CPU utilization. 

=> this demands different approach to reduce the CPU utilization, which is where TCP zero copy comes up.

## Idea behing TCP Zero Copy:

Instead of copying payload data, the application directly uses the pages into which the NIC DMA's the
payload.

Conceptually:
```
    NIC DMA
        │
        ▼
    Payload Page
        │
        │
    Application references same page
```
In this flow we elimiate `memcpy()` thus "Zero Copy"

### Header-split HDS is needed for this:

The problem is that the Linux networking stack needs to modify or inspect headers:

For example:
```
    Ethernet Header
    IP Header
    TCP Header 
    Payload
```
The headers are frequently touched.
Payload is often untouched. 

If everything resides in one DMA buffer:
```
+---------------------------------------+
| Header | Payload                      |
+---------------------------------------+
```
then 
- CPU cache loads payload unnecessary
- modifing headers dirties cache lines containing payload 
- payload pages cannot easily be handed directly to applications. 
This is where NVIDIA HW+driver seperates them. 

### Header-Data Split (HDS)

The NIC writes headers and payload into different memory regions

Instead of:

```
    Buffer A

    +--------------------------------+
    | Header + Payload               |
    +--------------------------------+
```

the NIC produces:
```
    Header Buffer

    +----------------+
    | Ethernet       |
    | IP             |
    | TCP            |
    +----------------+

    Payload Page

    +-----------------------------------+
    | Payload                           |
    +-----------------------------------+
``` 
Using two independent DMA opeartions


**Receive DMA**

```
        Packet arrives

            Packet

        +-------------------------------+
        | Header | Payload              |
        +-------------------------------+

                  NIC
             /         \
            /           \
        DMA Header    DMA Payload
           |             |
           ▼             ▼
        Small Buffer   Large Page
```
The kernel processes only the header.
The payload page remains untouched.

### Why this is faster

**Without HDS :**
```
    CPU loads:

    Header
    Payload
```
Cache:
```
    L1 Cache

    +----------------------+
    | Header + Payload     |
    +----------------------+
```
Most payload is never examined.
Cache pollution occurs

**With HDS :**

```
    CPU touches only

    Header Buffer
```
payload remains in memory.
Application later receives ownership of the payload page.
=> No Copy.

### memory layout:

example:

Packet:

```
    1500-byte Ethernet frame

    64 bytes header

    1436 bytes payload
```

**Without HDS:**
```
    DMA

    +----------------------------------------+
    |64B Header|1436B Payload                |
    +----------------------------------------+
```

**With HDS:**

```
    DMA #1

    +------------+
    |64B Header  |
    +------------+

    DMA #2

    +--------------------------------+
    |1436B Payload                   |
    +--------------------------------+
```

### Page reuse:

Linux prefers page-size buffers:

For example:
```
    4096-byte page

    +--------------------------------+
    | Payload                        |
    +--------------------------------+
```

Instead of copying:

```
    Page
    │
    │ memcpy()
    ▼
    Socket Buffer
```

The page itself becomes the socket payload.

```
    Page
    ↓
    skb frag
    ↓
    Application
```

### How Linux represents this:

Linux networking uses a `sk_buff` (socket buffer) 

Normally:

```
    skb

    +-------------------------------+
    | Header + Payload              |
    +-------------------------------+
```

with HDS:

```
    skb

    Header Pointer
            │
            ▼
    +------------+
    | Header     |
    +------------+
    Fragment List
        │
        ▼
    +----------------------------+
    | Payload Page               |
    +----------------------------+
```
The payload is referenced as a page fragment rather than copied into the linear part of the `sk_buff`.


### Scatter-Gather DMA:

Modern NICs already support scatter-gather DMA.

Instead of one destination:

```
        Packet
          ↓
        Buffer A
```

they support:

```
    Packet
      ↓
    Header Buffer
    Payload Buffer
```

The hardware automatically splits the incoming packet according to configured offsets.

### Where the split happens?

The NIC parses:

```
    Ethernet
        ↓
    IPv4 / IPv6
        ↓
       TCP
        ↓
     Payload
```

After parsing:

```
    Ethernet
    IP
    TCP
```
are written into the header buffer.
Everything after the TCP header is written into payload pages. 

### Zero Copy to applications:

Applications using mechanisms such as `MSG_ZEROCOPY` (primarily for transmit), 
`io_uring`, or frameworks that can consume page-backed socket data can benefit from reduced copying 
on the receive path when the kernel and driver support it.

Conceptually:
```
        NIC
         ↓
    DMA Payload Page
         ↓
    Kernel references page
         ↓
    Application maps page
```
No payload copy occurs.

### CPU savings

Without HDS:

```
    DMA
     ↓
    Copy
     ↓
    Application

    CPU cost

    DMA + memcpy + cache misses
```

With HDS:
```
    DMA
     ↓
 Application

 CPU cost

 DMA only
```

Typical Benifits include:
- lower CPU utilization
- reduced cache pollution
- higher throughput 
- lower latency 

The exact gains depend on workload, packet sizes, kernel support and application design.

### Typical workloads

HDS is especially effective when packets contain:
```
    Small header

    Large payload
```

Example:
```
    HTTP response
    Header
    Payload = 64 KB
    
    ---- or ----
    NVMe/TCP
    Header
    Payload = 128 KB
```
The larger the payload, the more copy overhead is avoided. 

### Why ConnectX-7 added this

At:
- 100 GbE
- 200 GbE
- 400 GbE

memory bandwidth often becomes the limiting factor.

For example:

```
    400 Gbps
    =
    50 GB/sec
    
    Copy once
    =
    50 GB/sec memory read
    +
    50 GB/sec memory write
    =
    100 GB/sec memory traffic
```

A single memcpy effectively doubles the memory bandwidth consumed for the payload.

Zero-copy receive avoids that additional traffic.


### End-to-end receive flow

```
        Incoming Packet
            │
            ▼
    +-------------------------------+
    | Ethernet/IP/TCP | Payload     |
    +-------------------------------+
               │
       ConnectX-7 Parser
               │
       Header-Data Split
               │
        ┌─────────────┐
        │             │
        ▼             ▼
    Header DMA     Payload DMA
        │             │
    Small Buffer    Page Pool
        │             │
    Linux TCP        skb fragment
        │             │
    Header parsed    Payload page attached

            │
            ▼

    Application consumes payload

    (no payload memcpy)
    
```

### Key distinction

It's worth distinguishing **TCP Zero Copy based on HDS** from other "zero-copy" technologies:

- **Transmit zero copy** (such as Linux `MSG_ZEROCOPY` ) avoids copying application data before 
  sending it.
  
- **Receive zero copy with HDS** focuses on incoming packets, separating headers from payloads 
  so the payload pages can be passed through the networking stack with minimal or no copying.
  
- **RDMA** bypasses the TCP/IP stack entirely and allows direct memory access between systems. 
  HDS-based TCP Zero Copy still uses the standard TCP/IP networking stack but optimizes how 
  received data is managed.

In short, Header-Data Split is the hardware mechanism, while TCP Zero Copy is the higher-level 
receive optimization enabled by that mechanism. 

By DMA-writing protocol headers into small buffers and payloads into page-aligned memory, 
ConnectX-7 allows the Linux networking stack to process only the headers while handing 
payload pages forward with little or no copying, significantly reducing CPU and memory-bandwidth 
overhead at modern Ethernet speeds.

