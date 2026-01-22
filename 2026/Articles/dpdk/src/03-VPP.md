# VPP Vector Packet Processing:  ( DPDK )

VPP is high performance open-source networking stack ( its a part of the linux foundation FO.io project)
that fundamentally changes how computer handles network traffic. 

Traditional Linux approach is to handle packets one by one from NIC and pass them over the networking
stack ( This is called 'scalar processing') VPP uses *vector processing* to achieve massive throughput
often up to 100% faster than standard kernel networking. 

## Scalar Vs Vector Processing:

The secret of faster processing with VPP is the way it handles the queues of incoming packets. 

- Scalar Processing( traditional way ):
In standard linux kernel, the system processes *one packet at a time*. 
1. CPU grabs a packet A.
2. It runs Packet A through the entire "graph" of functions:
    `Check IP -> Look Up Route -> Apply Firewall  -> Send Out `

3. CPU then clears it cache and starts over with Packet B. 
  There is a problem in this approach:
  It causes "I-Cache trashing", by the time CPU starts processing packet B, it has often "forgotten" the 
  instructions it just used for packer A, forcing it to reload them from slow main memory.

## Vector Processing ( VPP way )
VPP grabs a *vector* ( bunch of packets ) of up to 256 packets at once. 
1. It takes the entire batch to the first "node" ( eg: Check IP ).
2. CPU loads the instructions for "check IP" once and applies them to all 256 packets in row at same
   time. 
3. It then moves the whole batch to the next node. This approach has benefit : The CPU instructions stay
   in the **L1 instructions cache**. Eliminating the "Warm-up" time for the CPU, making it incredibly 
   efficient. 

For X86_64 platform AVX-512 and NEON on ARM allow a single CPU instruction to perform same operation on
multiple data points simultaneously. 

## Advantages of VPP:

- Reduced Cache misses: Since the same code is used for many packets in a row, the CPU doesn't have to keep fetching instructions from memory. 

- user-space operation: VPP can run in user-space rather than the Kernel. This precents the slow "context
  switching" that happens when data moves between the HW and the OS.
  
- DPDK Integration: This usually sits on top of DPDK, which allows it to talk directly to the network
  card (NIC) HW by passing the slow parts of the OS entirely. 

- Graph Node Architecture: VPP is modular, You can "plug in" new features (like custom firewall or load
  balancer) as new nodes in the processing graph without rewriting the core code. 


## Common Use-Cases: 

Because it is so fast and runs on "commodity" hardware (regular Intel/AMD/ARM servers), VPP is used for :

- *Cloud-Native Firewalls* : High-speed security at the edge of a network.

- *Software Routers* : Replacing expensive hardware routers with standard servers (ex: Netgate's TNSR).

- *5G/Core Networking*: Handling the massive data loads required for modern telecommunications.

-------------------------------------------------------------------------- 

# Setup Guide for VPP Env on Linux:


Getting VPP running in a container—especially with **Podman** is the perfect bridge between your current
XDP knowledge and the high-throughput world of vectorized processing.

Since VPP usually wants to "own" the hardware (NICs and Memory), running it in a container requires a 
bit of specific plumbing to ensure it has the right permissions and resources.

---

## 1. Prerequisites: The Host Setup

Before launching the container, the host OS needs to be prepared for "high-speed" userspace networking. 
*VPP* relies on **Hugepages** to avoid the overhead of standard memory paging.

Run these on your host:

```bash
# Allocate 1024 hugepages (2MB each = 2GB total)
sudo sysctl -w vm.nr_hugepages=1024

# Verify allocation
grep Huge /proc/meminfo

```

On Fedora 42: 
```bash 
$ grep Huge /proc/meminfo 
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
FileHugePages:      2048 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB
```
- `*Hugepagesize: 2048 kB`: the default size your CPU/Kernel supports (2MB pages).
- `HugePages_Total: 0`: This is the "pool" available for DPDK. Since it's zero, DPDK will fail to
  initialize its Memory Pool (mempool) and requires configuration.

- `FileHugePages: 2048 kB`: This usually indicates Transparent Huge Pages (THP) or a small internal
  kernel mapping. DPDK generally requires Static *Hugepages*, not these dynamic ones.

This shows *Hugepages* is  supported by default and needs to configure to use it. 

### Quick configuration:

For DPDK and VPP, you typically need to reserve a specific number of pages. 
For a lab environment, 1024 pages (2GB total) is a good starting point.

```bash 
$ su - 

## Reserve 1024 pages of 2MB each:
# echo 1024 | sudo tee /proc/sys/vm/nr_hugepages
1024
## Verify the change:
# grep HugePages_Total /proc/meminfo
HugePages_Total:    1024

```
To make this persistent across reboots, add this line to `/etc/sysctl.conf`: 
`vm.nr_hugepages=1024`

---

## 2. The Podman Workflow

VPP is distributed via a standard Ubuntu-based image from FD.io. 
Fedora user, the most stable way to get VPP is through the nucleo/vpp Copr repository, which is highly
active and provides builds for all current Fedora branches (including Rawhide) and EPEL (RHEL 8/9).

Because VPP needs to manage shared memory and potentially bypass the kernel, we use 
specific flags.

### Step 1: Create a basic `startup.conf`

VPP needs a configuration file to tell it *not* to try and steal your physical NICs (since we are just
starting out). Create a file named `vpp.conf` on your host:

```text
unix {
  nodaemon
  cli-listen /run/vpp/cli.sock
  full-coredump
}

api-segment {
  prefix vpp
}

plugins {
    plugin dpdk_plugin.so { disable }
}

```

### Step 2: Run with Podman (privileged mode)

Podman needs to bypass the standard container isolation to talk to the NIC and the memory manager.

Use the following command to launch the container.

* **`--privileged`**: Required for VPP to manage memory regions.
* **`--network host`**: Allows the VPP control plane to be accessible, though for true data-plane
  testing, we would use use `veth` pairs later.

```bash
podman run -d \
  --name vpp-dev \
  --privileged \
  --network host \
  -v /dev/hugepages:/dev/hugepages \
  -v $(pwd)/vpp.conf:/etc/vpp/startup.conf \
  fdio/vpp-centos8:latest

```
or 
```bash 
podman run -dt \
    --name vpp-dev \
    --privileged \
    --network host \
    -v /dev/hugepages:/dev/hugepages:rw \
    -v /dev:/dev \
    -v /lib/modules:/lib/modules:ro \
    -v /sys:/sys:rw \
    docker.io/library/vpp:latest

```

---

## 3. Interacting with VPP

Once the container is running, you don't "shell" into it like a normal app. You use **`vppctl`**, the specialized CLI.

```bash
# Enter the VPP CLI
podman exec -it vpp-dev vppctl

# Inside the VPP CLI, try these commands:
vpp# show version
vpp# show runtime    <-- This is where you see the Graph Nodes!
vpp# show interface

```

---

## 4. The "Step 1" Exercise: Create a Loopback

To see the graph in action without physical hardware, create a loopback interface and "up" it.

1. **Create Interface:** `vpp# loopback create`
2. **Assign IP:** `vpp# set interface ip address loop0 192.168.1.1/24`
3. **Set Status:** `vpp# set interface state loop0 up`
4. **Trace the Graph:** `vpp# trace add af-packet-input 10`

---

## 5. Why Podman + VPP is your "Rust Playground"

Now that you have this running, you can see why it's powerful for your Rust ambitions:

* **The Shared Memory API:** You can mount `/run/vpp/` from the container to your host. Your Rust app (using FFI) can then connect to that socket and "talk" to VPP without being inside the container.
* **Isolation:** If your Rust-based VPP plugin causes a panic, you just restart the container. It won't crash your host's networking like a bad XDP program might if it hangs the driver.


Next: Creating a "Veth Pair":
      This would allow you to send traffic from your Linux Host into the VPP container 
      and actually see the packet vectors moving through the graph.

# Creating a "Veth Pair" ( view packet vector movement through the graph)

To move from a passive "loopback" setup to a real "traffic-processing" environment, we will use a **veth pair**.

Think of a veth pair as a virtual ethernet cable: one end stays on your **Linux Host** ( acting like a
standard network card), and the other end is "plugged into" **VPP** inside the container.

### Step 1: Create the "Virtual Cable" on the Host

On your Linux host (outside the container), create a pair of connected virtual interfaces.

```bash
# Create the veth pair: 'vpp-host' and 'vpp-peer'
sudo ip link add name vpp-host type veth peer name vpp-peer

# Bring both ends up
sudo ip link set dev vpp-host up
sudo ip link set dev vpp-peer up

# Assign an IP to the host-side so we can send pings
sudo ip addr add 10.10.1.1/24 dev vpp-host

```

---

### Step 2: Plug the other end into VPP

Now, we tell VPP to "claim" the `vpp-peer` interface using its **AF_PACKET** driver. 
This driver allows VPP to read raw packets directly from a Linux interface.

```bash
# Enter the VPP CLI
podman exec -it vpp-dev vppctl

# 1. Create the host-interface in VPP
vpp# create host-interface name vpp-peer

# 2. Bring it up inside VPP
vpp# set interface state host-vpp-peer up

# 3. Assign it an IP on the same subnet
vpp# set interface ip address host-vpp-peer 10.10.1.2/24

```

---

### Step 3: Test and Trace (The "Deep Dive" Moment)

Now you can send traffic from your host into the VPP graph. 
This is where you see the **Vectorization** in action.

1. **Start a Trace in VPP:**
Tell VPP to capture the next 10 packets that hit the input node.
`vpp# trace add af-packet-input 10`
2. **Ping from the Host:**
Open a new terminal on your host and run:
`ping -c 1 10.10.1.2`
3. **Inspect the Graph in VPP:**
Go back to the VPP CLI and run:
`vpp# show trace`

---

### Understanding the Trace Output

When you run `show trace`, you aren't just seeing "a packet was received." 
You are seeing the **Node Pipeline**:

* **af-packet-input**: The driver pulled the packet from the Linux socket.
* **ethernet-input**: VPP looked at the MAC address.
* **ip4-input**: VPP validated the IPv4 header.
* **ip4-icmp-input**: VPP recognized it as a ping.
* **ip4-lookup**: VPP looked at its routing table to see where 10.10.1.2 lives.
* **ip4-local**: VPP realized the packet is for "itself" and processed the ICMP reply.

### Why this matters for Rust

In a Rust-based setup, you would eventually create a **new node** (e.g., `rust-logic-node`).
You would then "punt" packets from `ip4-input` to your Rust node. 
Because VPP uses **vectors**, if 100 people pinged VPP at the same time, all 100 packets would hit the
`af-packet-input` node together and travel through the graph as a single batch.

Next: Above we see how traffic flowing and can see the nodes, and we can see how to define a custom 
   Next Node" in the graph to redirect this traffic to a specific processing path

# Moving Packets: The Veth Pair Setup

Now, let's connect your Linux host to the VPP container so you can see real data flowing through the graph.

### 1. Create the "Virtual Cable" on the Host

On your Linux host, create a pair of connected virtual interfaces. This acts like a physical patch cable
between your host OS and the VPP stack.

```bash
# Create the veth pair: 'vpp-host' and 'vpp-peer'
sudo ip link add name vpp-host type veth peer name vpp-peer

# Bring both ends up
sudo ip link set dev vpp-host up
sudo ip link set dev vpp-peer up

# Assign an IP to the host-side
sudo ip addr add 10.10.1.1/24 dev vpp-host

```

### 2. Plug the "vpp-peer" end into VPP

Inside the container, we tell VPP to "capture" that interface. 
Because we are in a container, we use the **af_packet** driver, which allows VPP to treat a Linux interface 
like a raw hardware port.

```bash
# Enter the VPP CLI
podman exec -it vpp-dev vppctl

# 1. Create the interface in VPP
vpp# create host-interface name vpp-peer

# 2. Bring it up
vpp# set interface state host-vpp-peer up

# 3. Assign the VPP-side IP
vpp# set interface ip address host-vpp-peer 10.10.1.2/24

```

### 3. Trace and Ping (The Graph in Action)

Now, send a packet and watch VPP process it step-by-step.

1. **In VPP CLI:** Start a capture.
`vpp# trace add af-packet-input 10`
2. **On Host Terminal:** Send a ping.
`ping -c 1 10.10.1.2`
3. **In VPP CLI:** View the path.
`vpp# show trace`

---

## The Next Step: Custom Steering

The `show trace` output shows the packet following the "standard" path (Input  IP4-Input  ICMP-Echo-Reply).

As a Rust developer, your goal is likely to **intercept** that packet. 
In VPP, you do this by changing the **"Next Index"** of a node. 
Instead of the packet going to `ip4-input`, you can tell VPP to send 
it to a different node.


Next: How "Feature Arcs" work in VPP? This is how you "hook" your own logic into the 
      packet stream without breaking the existing IP stack.

# Feature Arc architecture. 

This is exactly how you would "plug in" a Rust-based node to handle your custom logic.

## 1. What is a Feature Arc?

In a standard graph, Node A must explicitly know that its "Next" is Node B. 
If you want to add a custom firewall, you'd normally have to modify the code of 
`ip4-input` to point to your new node—which is a maintenance nightmare.

**Feature Arcs** solve this by creating a "pluggable pipeline" *within* the graph. 
Instead of hard-wiring nodes, VPP creates an "Arc" (like `ip4-unicast`) that has a list of features
enabled for a specific interface.

### How it works:

1. **The Entry Point:** A packet enters a "Head" node (e.g., `ip4-input`).
2. **The Arc Check:** The node checks if any "features" are enabled on the incoming interface.
3. **The Hook:** If your custom Rust node is registered on that arc, VPP dynamically inserts it into the path.
4. **The Hand-off:** Your node processes the packet and then calls `vnet_feature_next()`, which  tell VPP
   to the next feature in line or back to the main stack (like `ip4-lookup`).

---

## 2. Registering a Custom Node (The "Rust Hook")

If you were using a Rust FFI wrapper to build a plugin, you would use a registration macro equivalent to 
the C `VNET_FEATURE_INIT`. 

This tells VPP: "I want my node to run on the `ip4-unicast` arc, specifically **before** the standard 
`ip4-lookup`."

```c
// Conceptual registration in a plugin
VNET_FEATURE_INIT (my_rust_filter, static) = {
  .arc_name = "ip4-unicast",
  .node_name = "my-rust-node",
  .runs_before = VNET_FEATURES ("ip4-lookup"),
};

```

---

## 3. Why this is "Async Friendly"

Because VPP handles packets in **vectors** (batches), your Rust node receives a frame of up to 256 pkts.

* You can use **SIMD** to scan all 256 packets for a specific pattern at once.
* If your logic is complex (e.g., checking an external database), you could potentially "suspend" the
  processing of that vector, though in a high-speed data plane, you usually want to avoid this to
  maintain "wire speed."

---

## 4. Try it now: Seeing the Arcs

In Podman container, you can see every available "hook" point in the system.

**Run this command in `vppctl`:**

```bash
vpp# show features

```

You will see a massive list of arcs (like `device-input`, `ip4-unicast`, `ip6-unicast`). 
Any of these can be "hijacked" by a custom node.

**To see what is currently running on your `vpp-peer` interface:**

```bash
vpp# show interface host-vpp-peer features

```

Right now, it will likely be empty or just have the basic `ip4-unicast` pointers.

---

### The Next "Aha!" Moment

Now that you know how packets flow, the next step is understanding the **Buffer Metadata**. 
Every packet carries a small "suitcase" of data (`vnet_buffer_t`) that tells nodes what has
already happened to it.

Next : how the `vnet_buffer_t` metadata is used to pass state between nodes—and how you would access 
   this in Rust via FFI.

# `vlib_buffer_t` metadata. 

This is the "suitcase" that travels with every packet. 
In a Rust-based approach, mastering this structure is how you gain the same level of control as a C plugin.

## 1. The Anatomy of a Buffer (`vlib_buffer_t`)

Every packet in VPP is managed by a `vlib_buffer_t`. 
It consists of a header (the metadata) and the actual packet data (the payload).

### The Layout

VPP uses a "split" layout to maximize CPU cache performance. 
The first 64 bytes (the first cache line) contain the most critical pointers:

* **`current_data`**: A signed offset. It tells you exactly where the "active" header starts relative to the buffer's start.
* **`current_length`**: How many bytes of valid data are in this buffer.
* **`flags`**: Status bits (e.g., `IS_TRACED`, `IS_IP4`).
* **`opaque`**: This is a 40-byte (10 x `u32`) area used to pass information between nodes.

---

## 2. Accessing Metadata in Rust

When building a Rust wrapper for a VPP node, your primary job is to cast the raw pointer VPP gives 
you into a Rust-safe struct. Because VPP's memory layout is strictly defined in C, you must use `#[repr(C)]` in Rust to ensure the fields align perfectly.

### The "Opaque" Space

The `opaque` field is the most powerful part for a developer. For example, if the `ip4-input` node before
your node, it will have already parsed the IP header and stored the **VRF index** or **Next Hop** in the
`opaque` section.

```rust
#[repr(C)]
pub struct VlibBuffer {
    pub current_data: i16,
    pub current_length: u16,
    pub flags: u32,
    pub free_list_index: u8,
    pub buffer_pool_index: u8,
    pub error: u16,
    pub next_buffer: u32,
    pub opaque: [u32; 10], // The "scratchpad" for nodes
}

```

---

## 3. The "Rust Strategy" for Vectors

In your Rust logic, you won't process one packet at a time. You will receive a pointer to an array of 
**buffer indices** (not direct pointers, for memory efficiency).

**The Workflow:**

1. **Load the Indices:** Receive `u32 *indices` from VPP.
2. **Prefetch:** Use Rust intrinsics (like `core::arch::x86_64::_mm_prefetch`) to tell the CPU to grab the metadata for the *next* 4 packets while you process the current one.
3. **Process:** Loop through the batch, updating the `opaque` data or `current_data` pointer (e.g., stripping a VLAN tag).
4. **Enqueue:** Tell VPP which "Next Node" in the graph this whole batch (or sub-batch) should go to.

---

## 4. Why this is safer in Rust

In C, accidentally writing `b->opaque[12]` would cause a silent memory corruption. In Rust:

* You wrap the `opaque` array in a **type-safe union** or a struct.
* You use **bounds-checked** slices for the packet data.
* If your logic panics, your wrapper can catch it, log the error, and "drop" the packet vector safely instead of crashing the entire VPP process.

---

### Seeing it in Real-time

You can actually see these "opaque" values in your Podman container right now.

**Run a trace again, but with high verbosity:**

```bash
vpp# trace add af-packet-input 1
# ... send a ping from host ...
vpp# show trace

```

Look for lines like `opaque: [0x0, 0x1, ...]`. These are the values your Rust code would be reading 
to make decisions.


Next: "Next-Node" logic.
This is how you tell VPP, "I'm done with these 256 packets, send them to the NAT node next.


# Next Node Logic:

In VPP, once your node (potentially a Rust-based one) has finished its work, it must hand the packet 
vector off to the next stage. This isn't a simple function call—it’s a "dispatch" that maintains the vectorized flow.

### 1. The "Next Index" Strategy

VPP doesn't use function pointers for every packet. 
Instead, each node has a **Next-Node Table**.

* **Index 0:** Usually mapped to `error-drop`.
* **Index 1:** Usually mapped to the "normal" next step (e.g., `ip4-lookup`).
* **Index 2+:** Custom paths (e.g., `nat-input`, `crypto-engine`).

In your code, you don't say "Send to IP4-Lookup." You say "Send this batch to **Next Index 1**."

### 2. The Vector Dispatch Loop

When your node runs, it receives a "Frame" of packet indices. 
Your job is to fill a corresponding "Next Frame."

**The typical workflow (in "Pseudo-FFI" logic):**

1. **Get the Frame:** You get a pointer to the incoming vector of 256 packets.
2. **Get the Next Frame:** You ask VPP for space in the next node's queue using `vlib_get_next_frame`.
3. **The Processing Loop:** You loop through your 256 packets. For each packet, you decide its destination.
4. **Put the Frame:** You tell VPP you're done using `vlib_put_next_frame`.

### 3. Feature Arcs: The "Smart" Way to Move

If you are writing a **Feature Node** (the plugin style we discussed), you don't even have to hard-code 
the index. You use `vnet_feature_next()`.

* **The Logic:** Your Rust code calls this function, and VPP looks at the interface configuration to see
  what feature comes after yours.

* **Dynamicism:** If the user disables the NAT plugin at runtime, `vnet_feature_next()` automatically
  skips it and sends the packet straight to the next active feature.

---

### 4. A Deep Dive Comparison: Rust vs. C Next-Node Logic

| Operation | Standard C Plugin | Rust FFI Wrapper |
| --- | --- | --- |
| **Batching** | Uses `while (n_left > 0)` loops manually. | Can use **high-level iterators** (`.chunks(4)`) for better readability. |
| **Safety** | Directly manipulates raw `u32` indices. | Can wrap indices in a **NewType** to prevent mixing up packet IDs with node IDs. |
| **Prefetching** | Uses `CLIB_PREFETCH` macros. | Uses `core::arch` intrinsics to warm up the cache for the *next* batch of packets. |

### Summary: Why this is the "Final Boss" of VPP

The complexity of VPP isn't the packet logic (parsing an IP header is easy); it's the **Frame Management**.

* If you "lose" a packet index and don't put it in a next frame, you have a **memory leak**.
* If you put the same packet into two different next frames, you have a **double-free/corruption**.

**This is exactly where Rust’s Ownership model is a superpower.** You can design a wrapper where a `Packet` object *must* be consumed by a `send_to_next()` method, making it compile-time impossible to "lose" a packet.

Further you can jump in to implementing Rust trait that enforces this "Must-Dispatch" rule to prevent memory leaks in the VPP graph.

