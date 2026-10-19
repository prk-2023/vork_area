# TSO 


TCP Segment Offload (TSO)—also known as Large Send Offload (LSO)—is a networking technique that hands over the heavy lifting of chopping up network data from your computer's CPU to the network interface card (NIC).
It is the perfect example of using specialized, dedicated hardware to protect the main processor from burning out on repetitive math.

The Problem: The CPU "Packet Tax"

When an application wants to send a large chunk of data (like a 64KB file stream) over the internet, it cannot send it all at once. The network has a Maximum Transmission Unit (MTU) limit, usually 1,500 bytes.
Without TSO, your computer's CPU has to manually do all of the following work:
1. Chop that 64KB block into roughly 45 smaller, 1,500-byte pieces (segments).
2. Calculate a unique TCP checksum for every single piece to ensure no data corruption.
3. Attach IP and TCP headers to every single piece.
4. Pass 45 individual packets down to the network card.
At 1Gbps, a CPU can handle this. But at 10G, 25G, or 100G speeds, the CPU would spend 100% of its processing power doing nothing but chopping packets and calculating checksums, leaving zero room to actually run your applications or operating system.

The Solution: How TSO Works

When TSO is enabled, the operating system bypasses the tedious chopping process entirely:
Show Code
Download diagram SVG
1. The Hand-off: The CPU passes the entire, unbroken 64KB chunk of data down to the network card in a single operation.
2. The Hardware Execution: The specialized chip (ASIC) built directly onto the network card takes over. The NIC handles the physical slicing into 1,500-byte segments.
3. Checksum Offloading: The NIC calculates the mathematical TCP checksums in real-time right as the data slides out of the network port.

Why This Matters for 10G/25G Networks

By shifting this burden onto the network card, TSO provides massive architectural benefits:
• Drastically Drops CPU Overhead: Your main processor is freed up to do actual computing work instead of network bookkeeping.
• Reduces System Interrupts: Instead of the CPU handling 45 separate memory transfers and interrupts, it only handles one.
• Lowers Latency & Increases Throughput: Hardened network silicon chops packets at true wire-speed significantly more efficiently than a general-purpose CPU can.
In short, TSO is the exact kind of "efficient, dedicated silicon" design you mentioned earlier—using a highly specialized, long-lasting hardware block on the NIC to prevent the main CPU from working itself to death.
Are you troubleshooting a performance bottleneck on a high-speed system, or are you looking into how to optimize virtual machines and software routing settings?


---


Yes, the Intel i350 Linux driver explicitly supports TCP Segment Offload (TSO). [1] (/goto?url=CAESTQHrOzAVFFurRThabG8RmFxk6HhcflQx1ZnJPzdXGAWCTcFkKHi_tQrH83NK0RYz3GGhQVK2vhjwzeMszu5Ei5SxgHuHqUkL65TiFEys)
The Intel i350 relies on the standard igb kernel driver. Both the hardware silicon on the i350 controller and the igb driver have fully supported native hardware TSO (for both IPv4 and IPv6 traffic) since day one. [1] (/goto?url=CAEShQEB6zswFaApr49ZLiocD1xPCekkqa5ttv-cYs6Oxw65hZvIapCm7d98E6Q_gemc1sjWTrXjYYbIXF0RJobcahl0k4geuBNwTYen_IUv6B7gyx64B7R6l5ZwuJJpYRTtxuK9WBPt_rcZm9Q8ePMx3kYDvV5yZkrHkUGuiNiKV1m2EFyx8uOl), [2] (/goto?url=CAESTQHrOzAVFFurRThabG8RmFxk6HhcflQx1ZnJPzdXGAWCTcFkKHi_tQrH83NK0RYz3GGhQVK2vhjwzeMszu5Ei5SxgHuHqUkL65TiFEys), [3] (/goto?url=CAESWQHrOzAVuCGQQ9pMyY1eRGGQ9hUbmZB1qJS0lyTraOKt16ArCJ6C59IF1O4fQOPiY8tC552UO4on7N-ZaREwmaM0kt9YGCW_h45_VVW6B5AM2eVoXtK4s0CI), [4] (/goto?url=CAESxQEB6zswFRCCKIvnvYnhMMDHug-Sw8zhYgZ2ut19Nl-37gRIHHe7s7R7qUOxhw5xFqVcBgpMwdNIhUZHj1bV96eoKIv1ce6bpxnqpl4bn4nF8TKNV7C3iYnZMfyISAZw3oj1VwutUZNcNO1F14KIEtNyuoAXOy3RW3a17K0X6IqhyOKR_YeiLl3ycJiR2Dk-62gcrL5qzDWjujU_j7B1gBLQtU5WCTYX-2Bp34p4jVdg-t6FaDQ5gmHEwp6igm4tDsU3g0YlVw)
By default, the Linux kernel automatically enables TSO on this card to save CPU cycles. [1] (/goto?url=CAESggEB6zswFbUJ6zltdW_41_dtCOKGOj4qW1YRmuqPTdyLqZ9IPJUQkl8OoTCstpFZfMX2blTe6ja9pGTt6ZgdvgzBpXjeX0wcUmmNiOXrLjwgU2pRFm7TwlisTPBON4lWyiWK34zNIF_rivrm23_0ULHeyRRFM-yNxBI6v-gJ7qSom7MV), [2] (/goto?url=CAESTQHrOzAVFFurRThabG8RmFxk6HhcflQx1ZnJPzdXGAWCTcFkKHi_tQrH83NK0RYz3GGhQVK2vhjwzeMszu5Ei5SxgHuHqUkL65TiFEys)

How to Verify TSO on Your i350

You can check the real-time status of TSO on your specific system using the ethtool command. Run the following command in your terminal (replace eth0 with your actual i350 interface name, which usually looks like eth0, enp1s0f0, etc.):
bash
ethtool -k eth0 | grep tcp-segmentation-offload
Use code with caution.
Expected Output:
text
tcp-segmentation-offload: on
	tx-tcp-segmentation-offload: on
	tx-tcp-ecn-segmentation-offload: on
	tx-tcp-mangleid-segmentation-offload: on
	tx-tcp6-segmentation-offload: on
Use code with caution.

Pro-Tip: The "Software Routing" Exception

If you are planning to use an i350 network card to build one of those custom software routers/firewalls (like an x86 box running pfSense, OPNsense, or standard Linux iptables/nftables) that we discussed earlier, you actually have to keep a major architectural rule in mind: You should turn TSO off on a router.
• Why? TSO is designed for endpoints (a server or a PC originating or receiving its own data).
• The Catch: When a machine acts as a router, it is just passing packets through from one interface to another. If TSO is active on a routing box, the hardware tries to buffer and segment packets that don't belong to it, which frequently corrupts the packet sizing, confuses downstream network switches, and actually introduces severe latency or packet drops. [1] (/goto?url=CAESggEB6zswFbUJ6zltdW_41_dtCOKGOj4qW1YRmuqPTdyLqZ9IPJUQkl8OoTCstpFZfMX2blTe6ja9pGTt6ZgdvgzBpXjeX0wcUmmNiOXrLjwgU2pRFm7TwlisTPBON4lWyiWK34zNIF_rivrm23_0ULHeyRRFM-yNxBI6v-gJ7qSom7MV)
If you are using the i350 as a dedicated network router, you can forcefully turn TSO off via the command line to prevent routing glitches:
bash
sudo ethtool -K eth0 tso off
Use code with caution.
Are you setting up this i350 card inside a standard server/host to handle local applications, or is this card going to act as the interface for a DIY software router/firewall?


---

# Header payload data splitting:


Header-payload data splitting (often called Header Split or Header-Data Split) is an advanced performance feature supported by high-end network interface cards—including your Mellanox (NVIDIA) ConnectX (mlx5) series.
It solves a massive bottleneck in how a computer's operating system handles incoming network traffic at extreme speeds (like 10G, 25G, and beyond) by separating metadata from actual data the moment it hits the wire.

The Problem: Memory Misalignment and CPU Cache Pollution

Every network packet arriving at your network card consists of two parts:
1. The Header (Metadata): The TCP/IP or UDP protocol instructions (where the packet is from, where it is going, port numbers, flags). This is tiny—usually around 40 to 64 bytes.
2. The Payload (Actual Data): The actual file chunk, video frame, or database query you requested. This fills up the rest of the packet (up to 1,500 bytes or 9,000 bytes for jumbo frames).
Without Header Splitting, the network card dumps the entire packet as one continuous block into a single buffer in the computer's system memory (RAM). Because headers are varying sizes, the actual payload data gets dynamically pushed around and misaligned in memory.
When the CPU wants to process the data, it has to fetch both the header and the payload together. This fills the CPU's hyper-fast L1/L2 cache with messy header garbage, causing "cache misses" and forcing the CPU to work significantly harder to sort out the actual data.

The Solution: How Header-Payload Splitting Works

When Header Splitting is enabled, the ASIC processor on your Mellanox mlx5 card parses the incoming packet in real-time and splits it into two distinct destination paths before sending it over the PCIe bus to your RAM:
Show Code
Download diagram SVG
1. The Header Buffer: The card strips the 40-64 byte header and places it into a small, dedicated memory ring buffer. The CPU grabs this tiny header immediately to run its network protocol checks.
2. The Payload Buffer: The card takes the large payload and drops it into a completely separate, page-aligned memory buffer (usually aligned to 4KB operating system memory pages).

Why This is a Game-Changer for Modern Networks

By separating the two elements at the hardware level, your system achieves three massive efficiency spikes:
• Zero-Copy Architecture: Because the payload is perfectly aligned to a system memory page boundary, the operating system can hand the data directly over to your application (like a database or web server) without the CPU ever having to copy the data from one place in RAM to another.
• Perfect CPU Cache Utilization: The CPU cache stays incredibly clean. It only loads the tiny headers it needs to route the traffic, keeping the heavy payloads cleanly resting in main memory until the application asks for them.
• Maximum Throughput with Zero Overhead: This feature allows high-performance servers to achieve true line-rate 25G, 50G, or 100G speeds without spiking the CPU usage, keeping the system running incredibly cool and efficient.
Your Mellanox mlx5 card is widely regarded as one of the best in the industry at executing this exact hardware-level optimization.
Would you like to know how to verify if Header Split is active on your Mellanox mlx5 card under Linux, or are you exploring this to optimize a specific application like a high-speed storage array (NVMe-oF) or a virtualization cluster?

---

# Timestamp offload:


Timestamp offload is a hardware feature where the Network Interface Card (NIC)—like your Mellanox mlx5 or Intel i350—injects an ultra-precise timestamp into a network packet at the exact physical microsecond it enters or leaves the network port.
Just like TCP Segment Offload and Header Splitting, this hands a complex, time-sensitive operation over to dedicated silicon, preventing the CPU from injecting its own latency into the math.

The Problem: Software Time-Stamping is Inaccurate

In high-speed networking, knowing exactly when a packet arrived is critical. Without hardware offloading, timestamping happens via software:
1. A packet hits the network card.
2. The network card triggers a system interrupt to tell the CPU data has arrived.
3. The CPU stops what it is doing, wakes up the operating system kernel, and the OS looks at the system clock to stamp the packet.
The Bottleneck: The time it takes for the network card to alert the CPU, and for the CPU to respond, varies wildly depending on how busy the processor is. If the CPU is handling a heavy workload, a packet might sit in memory for several microseconds before getting stamped. At 10G or 25G speeds, a delay of just 1 microsecond means hundreds of packets have already passed by, rendering software timestamps highly inaccurate.

The Solution: Hardware Timestamp Offload

When Timestamp Offload is enabled, the network card uses an on-board hardware clock (PHC - PTP Hardware Clock) built directly into the network ASIC.
Show Code
Download diagram SVG
• Ingress (Incoming): The exact nanosecond the physical electrical or optical signal hits the port, the NIC captures the hardware clock value and attaches it directly to the packet's metadata buffer before sending it over the PCIe bus to RAM.
• Egress (Outgoing): When the system sends a packet, the NIC captures the exact moment the final bit clears the physical wire, recording it for the operating system to review.
The CPU completely bypasses the scheduling lag, receiving a perfectly accurate record of physical transmission.

Why This is Critical for High-Speed Systems


1. Precision Time Protocol (PTP / IEEE 1588)

While standard network time (NTP) synchronizes computers to within a few milliseconds, PTP requires nanosecond-level accuracy. Timestamp offloading is the absolute foundation of PTP. It allows thousands of separate physical machines across a network to lock their hardware clocks together with staggering precision.

2. High-Frequency Trading (HFT) & Financial Math

In financial markets, a microsecond difference determines who wins or loses a trade. Financial servers use Mellanox ConnectX cards with timestamp offloading to log the exact arrival sequence of market data down to the nanosecond, ensuring precise audit trails and ultra-low-latency execution.

3. Telemetry and Packet Analysis

If you are running packet captures (like tcpdump or Wireshark) on a high-speed link, software timestamping will make packets look out of order or artificially delayed. Hardware timestamp offload guarantees that the logs reflect the literal reality of the wire.

How to Check Timestamp Support on Your Mellanox Card

Your Mellanox mlx5 card has world-class PTP hardware clock support. You can see its exact timestamp capabilities using ethtool:H
bash
ethtool -T eth0
Use code with caution.
Expected Output for mlx5:
text
Time stamping parameters for eth0:
Capabilities:
	hardware-transmit     (SOF_TIMESTAMPING_TX_HARDWARE)
	software-transmit     (SOF_TIMESTAMPING_TX_SOFTWARE)
	hardware-receive      (SOF_TIMESTAMPING_RX_HARDWARE)
	software-receive      (SOF_TIMESTAMPING_RX_SOFTWARE)
PTP Hardware Clock: 0
Hardware Transmit Timestamp Modes: off, on, onwithtimestamp
Hardware Receive Filter Modes: none, all
Use code with caution.
The presence of hardware-transmit and hardware-receive means your card is fully equipped to handle this without ever touching your main CPU.
Are you setting up precision time synchronization (PTP) for a database cluster, or are you looking at timestamping for packet capture and latency testing?

---

# GSO :


Generic Segmentation Offload (GSO) is the software-driven partner to TCP Segment Offload (TSO).
While TSO requires a specialized, high-end hardware chip (like your Mellanox or Intel cards) to chop up massive data packets, GSO is a clever architectural trick built entirely into the Linux kernel operating system. It acts as a universal safety net, ensuring the CPU remains highly efficient even when the physical network hardware lacks advanced slicing capabilities.

The Problem: The "All-or-Nothing" Hardware Trap

As we discussed with TSO, passing a massive 64KB block of data directly down the network stack saves immense CPU processing cycles. However, if the operating system attempts to pass a giant 64KB chunk down to a cheap or older network card that doesn't understand hardware TSO, the network card will simply drop or corrupt the data.
Before GSO existed, the Linux kernel had to constantly check every single network card's hardware capabilities. If TSO wasn't explicitly supported by the chip, the CPU was forced to manually chop up every single packet at the absolute top of the networking stack, dragging down overall system performance.

The Solution: "Delay the Chop"

GSO completely re-engineered this pipeline using a concept called deferred segmentation. Instead of chopping up data early, GSO instructs the Linux kernel to treat all outbound traffic as if the network card is an ultra-fast, high-end chip.
The kernel processes the giant 64KB block through the entire complex software stack (firewall rules, routing tables, encryption layers) as one single large packet.
The "magic" happens at the very last microsecond before the data leaves the operating system:
Show Code
Download diagram SVG
1. The Fast Lane: If the network card driver supports hardware TSO, GSO steps aside and hands the giant packet directly to the hardware.
2. The Software Fallback: If the network card is a legacy device or has TSO turned off, GSO software chops the packet into standard 1,500-byte segments right at the driver boundary, just before passing it to the physical wire.

Why GSO is a Genius Performance Trick

• Massive CPU Savings (Even Without Hardware Support): By processing one giant packet through the complex firewall and routing tables instead of 45 smaller ones, the CPU bypasses a massive amount of internal bookkeeping overhead.
• Unified Code Base: Developers do not have to write separate network optimization paths for premium Mellanox enterprise cards versus generic legacy adapters. GSO makes the behavior identical from the operating system's perspective.
• Flawless Virtualization: GSO is the absolute backbone of high-speed virtual machines (KVM, QEMU). It allows a virtual machine to send massive chunks of data to a virtual switch at lightning speeds without simulating hardware slicing limits at the software level.

GSO vs. TSO: The Quick Comparison


Feature	TSO (TCP Segment Offload)	GSO (Generic Segmentation Offload)
Where it happens	Hardware ASIC (On the Mellanox / Intel NIC)	Software Kernel (Inside Linux OS)
Protocols Supported	Strictly TCP (typically)	Any protocol (TCP, UDP, GRE, VXLAN tunnels)
CPU Overhead	Absolute lowest (Zero CPU usage for slicing)	Medium-low (Saves CPU during routing, but uses CPU to slice at the end)

You can check your system's GSO status using the same ethtool command: ethtool -k eth0 | grep generic-segmentation-offload. On any modern Linux distribution, you will find it is turned on by default.
Now that you have looked into TSO, Header Splitting, Timestamping, and GSO, are you building a comprehensive blueprint to tune a Linux kernel for maximum networking throughput, or are you diagnosing a specific performance drop?
