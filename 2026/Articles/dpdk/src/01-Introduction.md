# DPDK:


What is DPDK?

Data Plane Development Kit is a set of **open-source libraries designed to accelerate packet processing by 
bypassing the standard Linux kernel network stack**.

In a traditional setup, the kernel handles every packet via interrupts, which causes significant overhead. 
`DPDK` moves this process to **user-space**, allowing the application to "poll" the network card directly 
for lightning-fast speeds.

---

## 1. Core Architecture Concepts

To understand DPDK, you must understand its three "pillars" of performance:

1. **EAL (Environment Abstraction Layer):** 
    The foundation that hides hardware specifics. 
    It manages memory allocation, PCI access, and multi-core thread affinity.

2. **PMD (Poll Mode Driver):** 
    Instead of waiting for an interrupt (which is slow), PMDs continuously check the NIC for new data. 
    This eliminates the "context switch" between user-space and kernel-space.

3. **Hugepages:** 
    Standard memory pages are 4 KB. 
    DPDK uses **Hugepages** (2 MB or 1 GB) to reduce "TLB misses," ensuring the CPU can find packet data in 
    memory much faster.

[ Note:

    - TBL: Translation lookaside buffer, a small very fast cache inside the CPU that stores recent mapping
      from Virtual Memory addresses => physical memory address. Programs use virthal addresses but RAM uses
      *physical address*, the CPU needs these translation for every memory access.

    - TLB Misses: This happens when CPU looks up a virtual address in TLB and does not find it there. ( some
      cpu's do extra work to find the translation elsewhere )
        * If TLB not found ( TLB Miss )
        * CPU consults the page table in memory 
        * if Page table entry exists: 
            - It loads the translation into the TLB, 
            - Execution continues but slower. 
        * If Page table entry does not exist:
            - A page fault occurs ( more expensive : as fault occurs when a program accesses a memory page 
              that is either not in RAM yet or is not permitted to access. )

    - TBL Misses => 
        * Slow downs program execution 
        * Increase memory latency 
        * Frequent TLB misses:
            - Poor memory locality
            - working set larger then the TLB 
            - Inefficient data structures or access patterns. 

    - Context we use TLB:
        * Performance profiling tools ( `perf`, `Vtune` )
        * HPC 
        * Database and memory intensive applications.

    - TLB are fixed in HW and cannot be resized in SW. The number of entries, associative and structures are
      dicided by CPU microarchitecture.
      Ex: 
        * L1 data TLB: 32 - 128 entries 
        * L1 instruction TLB: ~32–128 entries
        * L2 (shared) TLB: hundreds to a few thousand entries
    - Memory access flow:
        - CPU generates a Virtual memory 
        - TLB lookup => get physical Address
        - physical address used to access: 
            * L1 cache 
            * then L2 
            * then L3 
            * then RAM 
        => Cache access depends on TLB translation.
            Larger caches → better data locality
            Better locality → fewer pages touched
            Fewer pages → fewer TLB misses
        But increase in Cache size does not tranlate to increase TLB size. 

    - This information is in PMU counters of the CPU and suitable tool is `perf`
    * step 1: check what the CPU supports : 
        `perf list` 
      Look for `bTLB-load-misses`, `iTLB-load-misses`, `cache-misses`, `page-fault`... If the event isn't
      listed then your CPU/Kernel does not expose it.
    * step 2: High level view
        `perf stat -d ./your_app`
        THis prints:
            - cache references, 
            - cache misses,
            - page faults,
            - cycles/instructions 
            - context switches.
    * step 3: Measure TLB misses ( key for HugePages ) Data TLB is important for DPDK. 
        `perf stat -e dTLB-loads,dTLB-load-misses ./Your_App`
       we can interpret from above command :
       - dTLB-loads → how many memory translations were needed
       - dTLB-load-misses → how many missed the TLB 
       - miss-rate: 
        ` dTLB-load-maafs / dTLB-loads `

]

## 2. Environment Setup

Before coding, you must configure your Linux environment to allow `DPDK` to take control of the hardware.

### Step 1: Reserve Hugepages

Check if your system has hugepages enabled and reserve them (e.g., 1024 pages of 2MB each):

```bash
# Reserve 2GB of memory in 2MB hugepages
echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Mount them so DPDK can use them
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs nodev /mnt/huge

```

### Step 2: Install DPDK

The modern way to build DPDK is using **Meson** and **Ninja**:

```bash
sudo apt install meson ninja-build python3-pyelftools
git clone http://dpdk.org/git/dpdk
cd dpdk
meson build
ninja -C build
sudo ninja -C build install
sudo ldconfig

```

---

## 3. Preparing the NIC

You must "unbind" your network interface from the Linux kernel driver and "bind" it to a DPDK-compatible
driver (like `vfio-pci`).

```bash
# Check your PCI addresses (e.g., 0000:03:00.0)
dpdk-devbind.py --status

# Bind the interface to vfio-pci
sudo modprobe vfio-pci
sudo dpdk-devbind.py --bind=vfio-pci 0000:03:00.0

```

---

## 4. Writing Your First App (Hello World)

DPDK applications always start by initializing the EAL. 
This code will run a "Hello" message on every available CPU core.

```c
#include <stdio.h>
#include <rte_eal.h>
#include <rte_lcore.h>

// This function runs on every "slave" core
static int hello_world(__attribute__((unused)) void *arg) {
    unsigned lcore_id = rte_lcore_id();
    printf("Hello from core %u\n", lcore_id);
    return 0;
}

int main(int argc, char **argv) {
    // 1. Initialize the Environment Abstraction Layer
    int ret = rte_eal_init(argc, argv);
    if (ret < 0)
        rte_panic("Error with EAL initialization\n");

    // 2. Launch the function on all available cores
    rte_eal_mp_remote_launch(hello_world, NULL, CALL_MAIN);

    // 3. Wait for all cores to finish
    rte_eal_mp_wait_lcore();

    // 4. Clean up
    rte_eal_cleanup();
    return 0;
}

```

### How to Run it:

Compile it using `pkg-config` and run with the `-l` flag to specify which CPU cores to use:

```bash
gcc main.c $(pkg-config --cflags --libs libdpdk) -o hello_dpdk
sudo ./hello_dpdk -l 0-3

```

---

## 5. Summary Table: Kernel vs. DPDK

| Feature | Traditional Linux Kernel | DPDK (User-space) |
| --- | --- | --- |
| **Data Path** | NIC  Kernel  App | NIC  App (Bypass Kernel) |
| **Notification** | Interrupt-driven | Polling-driven (100% CPU) |
| **Memory** | 4KB Pages | 2MB/1GB Hugepages |
| **Context Switches** | Frequent (Slow) | None (Zero-copy) |


## Basic Forwarding Example: 
Next: Code example for a "Basic Forwarding" app to see how to actually receive and send packets?

Building a basic forwarding application (often called "L2 Forwarding" or "Skeleton") is the best way to
see how `DPDK` actually handles traffic.

In this model, the application polls a receiving port (RX), takes the packet "burst," and immediately
sends it out on a transmitting port (TX).

### 1. The Packet Processing Flow

In DPDK, we don't handle packets one-by-one. We handle them in **bursts** (usually 32 packets at 
a time) to maximize CPU instruction cache efficiency.

---

### 2. Basic Forwarding Code

This simplified example demonstrates the core "Poll Mode" loop.

```c
#include <rte_eal.h>
#include <rte_ethdev.h>
#include <rte_mbuf.h>

#define BURST_SIZE 32
#define MEMPOOL_CACHE_SIZE 256

static void lcore_main(struct rte_mempool *mbuf_pool) {
    uint16_t port;

    // Check that we have at least two ports to forward between
    RTE_ETH_FOREACH_DEV(port) {
        if (rte_eth_dev_socket_id(port) > 0 && 
            rte_eth_dev_socket_id(port) != (int)rte_socket_id())
            printf("WARNING: Port %u is on remote NUMA node\n", port);
    }

    // The "Infinite Loop" - This is the Poll Mode Driver in action
    for (;;) {
        RTE_ETH_FOREACH_DEV(port) {
            struct rte_mbuf *bufs[BURST_SIZE];
            
            // 1. Receive a burst of packets
            const uint16_t nb_rx = rte_eth_rx_burst(port, 0, bufs, BURST_SIZE);

            if (unlikely(nb_rx == 0))
                continue;

            // 2. Forward packets to the "adjacent" port (0->1, 1->0)
            const uint16_t nb_tx = rte_eth_tx_burst(port ^ 1, 0, bufs, nb_rx);

            // 3. Free any packets that couldn't be transmitted
            if (unlikely(nb_tx < nb_rx)) {
                for (uint16_t buf = nb_tx; buf < nb_rx; buf++)
                    rte_pktmbuf_free(bufs[buf]);
            }
        }
    }
}

```

### 3. Key Components Explained

* **`rte_mbuf` (Message Buffer):** This is the data structure that carries the packet. In DPDK, the
  actual packet data stays in a fixed memory location; only the pointers (`mbufs`) are passed around. This is what makes it "Zero-Copy."

* **`rte_mempool`:** DPDK pre-allocates memory for packets at startup. Creating and destroying buffer on
  the on the fly is too slow, so we "borrow" and "return" buffers to this pool.

* **`rte_eth_rx_burst`:** This function goes directly to the NIC's hardware ring buffer. 
  It doesn't wait for data—if there are no packets, it returns `0` immediately and moves to the next instruction.
* **`port ^ 1`:** A simple bitwise trick used in basic DPDK examples to swap between Port 0 and Port 1.

---

### 4. Running the Application

When running a real packet-processing app, you usually need to provide more parameters to the EAL:

```bash
sudo ./forwarder -l 1-2 -n 4 -- -p 0x3

```

* **`-l 1-2`**: Run on CPU cores 1 and 2.
* **`-n 4`**: Number of memory channels in your hardware (optimizes throughput).
* **`--`**: Separator between EAL arguments and your application's arguments.
* **`-p 0x3`**: (Application specific) A bitmask to enable ports 0 and 1 ().

### Important Performance Note

When you run this, you will notice that your **CPU usage hits 100% immediately** on the assigned cores. 
This is normal. Since DPDK is polling, it is constantly "asking" the NIC for data as fast as possible, even if no traffic is flowing.

Next: Explore how to use "TestPMD," the built-in tool DPDK provides to benchmark your hardware without
writing any C code?**

## DPDK app Testing: 

Writing your own DPDK application is great for learning, but when you want to actually benchmark
your hardware or test complex features (like RSS or Checksum offloading), the industry standard is **TestPMD**.

TestPMD is a pre-built application distributed with DPDK that acts as a powerful, interactive 
packet-processing shell.

---

### 1. Launching `TestPMD`

Assuming you have already bound your NICs to `vfio-pci` (as shown in the first step), you can launch `TestPMD`.

```bash
# -l 1,2,3: Use cores 1, 2, and 3
# -n 4: 4 memory channels
# -- : Separator
# -i: Interactive mode
sudo dpdk-testpmd -l 1,2,3 -n 4 -- -i

```

* **Core 1:** Will act as the "Main" core to handle the interactive command line.
* **Cores 2 & 3:** Will be dedicated to forwarding packets at line rate.

---

### 2. Common Forwarding Modes

`TestPMD` is versatile because it allows you to change how it treats packets on the fly.

| Mode | Command | Description |
| --- | --- | --- |
| **IO (Default)** | `set fwd io` | Simplest/Fastest. Receives on Port X, sends on Port Y. |
| **MAC Swap** | `set fwd macswap` | Swaps Source and Destination MAC addresses before sending. |
| **RX-Only** | `set fwd rxonly` | Acts as a packet sink (useful for checking if packets arrive). |
| **TX-Only** | `set fwd txonly` | Acts as a traffic generator (useful for stress testing). |

---

### 3. Running a Benchmark

Once the `testpmd>` prompt appears, follow these steps to start a test:

1. **Check Port Info:**
```bash
testpmd> show port info all

```


2. **Start Forwarding:**
```bash
testpmd> start

```


3. **Monitor Performance:**
Wait a few seconds, then view the throughput:
```bash
testpmd> show port stats all

```


You will see metrics like **Rx-pps** (Packets Per Second) and **Rx-bps** (Bits Per Second). 
For a 10Gbps link with 64-byte packets, you should see roughly **14.88 Mpps**.

4. **Stop and Quit:**
```bash
testpmd> stop
testpmd> quit

```



---

### 4. Advanced: Multiple Queues (RSS)

If you have a high-speed NIC (40G or 100G), a single CPU core cannot keep up. You need to use **Receive Side Scaling (RSS)** to spread traffic across multiple cores.

```bash
# --rxq=4 --txq=4: Use 4 hardware queues
# --nb-cores=4: Use 4 forwarding cores
sudo dpdk-testpmd -l 1-5 -n 4 -- -i --rxq=4 --txq=4 --nb-cores=4

```

### Pro-Tip for Benchmarking

If you don't see the performance you expect, ensure:

* **NUMA Affinity:** Your CPU cores and NIC are on the same socket (check `lscpu`).
* **Isolated Cores:** Use the Linux kernel parameter `isolcpus` so the OS doesn't try to run other tasks
  on your DPDK cores.


Next: Write a simple `Makefile` or `meson.build` file to compile your custom DPDK projects:

## Compile Custom DPDK project:

`Meson` is the standard to compile DPDK projects. However, many developers still use a 
**Makefile** with `pkg-config` for small, portable projects.

Here are the two shortest ways to get your code running.

---

### Option 1: The Modern `meson.build` (Recommended)

This is the fastest method and automatically handles all dependencies. Create a file named `meson.build` 
in your project folder:

```python
project('dpdk_app', 'c')

dpdk = dependency('libdpdk')
sources = files('main.c')

executable('dpdk_app', sources, dependencies: dpdk)

```

**To compile:**

```bash
meson setup build
ninja -C build

```

---

### Option 2: The Classic `Makefile`

If you prefer standard `make`, use `pkg-config` to dynamically find the DPDK headers and libraries
installed on your system.

```makefile
APP = dpdk_app
SRCS-y := main.c

PKGCONF = pkg-config --define-prefix

CFLAGS += -O3 $(shell $(PKGCONF) --cflags libdpdk)
LDFLAGS += $(shell $(PKGCONF) --libs libdpdk)

$(APP): $(SRCS-y)
	gcc $(CFLAGS) $(SRCS-y) -o $(APP) $(LDFLAGS)

clean:
	rm -f $(APP)

```

**To compile:**

```bash
make

```

---

### Which one should you use?

* Use **Meson** if you plan to build a larger project or want to upstream your code to the DPDK community.
* Use the **Makefile** for quick "one-file" experiments or if you are integrating DPDK into an existing
  legacy build system.

### Best Practices for optimizing your code,(memory alignment or pre-fetching):

To squeeze every drop of performance out of DPDK, you need to write "hardware-aware" code.
Here are the most critical optimizations in short:

#### 1. CPU & Memory Locality (NUMA)

Always run your threads on the same CPU socket where your NIC is physically plugged in.
Accessing memory across sockets (the QPI/UPI link) increases latency significantly.

* **Check:** Use `lscpu` to see which cores belong to which NUMA node.
* **Code:** Use `rte_eth_dev_socket_id(port)` to ensure you allocate your mempool on the correct node.

#### 2. Cache Alignment

Modern CPUs read data in 64-byte "cache lines." 
If your data structure crosses a line, the CPU has to fetch twice.

* **Practice:** Use `__rte_cache_aligned` when defining structures.

```c
struct my_data {
    uint64_t counter;
    /* ... */
} __rte_cache_aligned;

```

#### 3. Software Prefetching

If you know you are about to process a packet, tell the CPU to load it into the cache **before** you actually need it.

* **Code:** Use `rte_prefetch0(packet_address)`.
* **Strategy:** While processing Packet A, prefetch Packet B.

#### 4. Avoid "Branch Misprediction"

Inside your tight forwarding loop, avoid complex `if/else` logic.

* **Practice:** Use `unlikely()` and `likely()` macros for error checks so the CPU prioritizes the "fast path."

```c
if (unlikely(nb_rx == 0))
    continue;

```

#### 5. Memory Management

* **Bulk Operations:** Always allocate and free `mbufs` in bursts (e.g., 32 at a time) rather than one by one to reduce lock contention on the mempool.
* **Hugepages:** Never skip hugepages; standard 4KB pages will cause "TLB thrashing," killing your throughput.

----

# Rust and DPDK:

Using Rust with DPDK is one of the most exciting areas in systems networking. 
Combines the **"bare-metal" performance** of DPDK with the **memory safety** and 
**modern ergonomics** of Rust.

The scope of Rust with DPDK can be broken down into three main categories:

---

### 1. The Value Proposition: Why Rust?

In traditional C-based DPDK, a single pointer error or "use-after-free" of a packet buffer (`mbuf`) can
crash an entire high-speed gateway or lead to silent data corruption.

* **Memory Safety without GC:** 
    Rust’s ownership model ensures that once a packet is sent (TX), your code can no longer accidentally modify it. This eliminates a massive class of bugs without the "stop-the-world" pauses of a Garbage Collector (like Go or Java).

* **Fearless Concurrency:** 
    DPDK relies on a "run-to-completion" model across multiple cores. Rust’s `Send` and `Sync` traits prevent data races at compile time, making multi-core packet processing much safer to implement.

* **Zero-Cost Abstractions:** 
    You can build high-level, readable APIs for packet parsing (using crates like `nom` or `etherparse`) that compile down to machine code just as fast as hand-written C.

---

### 2. The Current Ecosystem (2026)

While DPDK is natively written in C, the "bridge" to Rust has matured significantly:

* **`dpdk-sys` / Bindgen:** Most projects use automated bindings to call DPDK's C functions directly.

* **Encapsulation Frameworks:** * **Capsule:** One of the most popular Rust frameworks designed specifically for DPDK. It provides a "functional" style for building network functions (like firewalls or load balancers).

* **NetBricks:** An earlier influential research project that proved Rust could match C's performance in DPDK environments.

* **In-Kernel Progress:** With Rust now officially in the Linux kernel, there is an increasing push to standardize "Safe Wrappers" for DPDK libraries (like `ethdev` and `ring`).

### 3. Performance Reality Check

**Can Rust keep up with C?** Yes. Benchmarks consistently show that Rust-DPDK applications perform within **95-99%** of pure C implementations.

| Feature | C + DPDK | Rust + DPDK |
| --- | --- | --- |
| **Throughput** | Maximum (Line rate) | Equivalent (Line rate) |
| **Development Speed** | Slow (Manual debugging) | Fast (Compiler-aided) |
| **Safety** | High risk (Buffer overflows) | Very High (Compile-time checks) |
| **Binary Size** | Tiny | Small (Slightly larger overhead) |

---

### 4. Challenges to Consider

* **FFI Overhead:** Every time you call a C function from Rust, there is a tiny "transition" cost. In packet processing where nanoseconds matter, this requires careful design (e.g., using `static inline` wrappers).

* **`unsafe` Blocks:** To use DPDK's low-level features (like direct memory access), you will still need to write `unsafe` Rust code. The goal is to wrap that `unsafe` code in a safe API so the rest of your app doesn't have to worry about it.

* **Learning Curve:** You have to master both the complexity of DPDK (Hugepages, NUMA, PMDs) and the rigor of Rust (lifetimes, borrowing).


## Hello world example in Rust:

In Rust, we typically use **FFI (Foreign Function Interface)** to talk to DPDK's C libraries. Because DPDK relies heavily on pointers and manual memory management, the Rust code that interacts directly with it must be wrapped in `unsafe` blocks.

### 1. Minimal Rust-DPDK Bridge

This is a conceptual look at how you initialize the EAL using the `dpdk-sys` bindings.

```rust
use dpdk_sys::{rte_eal_init, rte_pktmbuf_free, rte_eth_rx_burst};
use std::ffi::CString;
use std::os::raw::c_char;

fn main() {
    // 1. Convert Rust strings to C-style strings for DPDK
    let args = vec![CString::new("dpdk_rust_app").unwrap()];
    let mut c_args: Vec<*mut c_char> = args.iter().map(|arg| arg.as_ptr() as *mut c_char).collect();

    // 2. Initialize EAL (requires 'unsafe' because it's a C call)
    unsafe {
        let ret = rte_eal_init(c_args.len() as i32, c_args.as_mut_ptr());
        if ret < 0 {
            panic!("Cannot init EAL");
        }
        println!("DPDK initialized successfully from Rust!");
    }
}

```

---

### 2. The "Safe" Abstraction (The Capsule Approach)

Real-world Rust DPDK development doesn't look like the "raw" C-style code above. Instead, you use a framework (like **Capsule**) to turn raw pointers into safe Rust types.

Instead of manually freeing buffers, you use a declarative pipeline:

```rust
// A hypothetical "Safe" Rust packet filter
fn process_packets(q: PortQueue) {
    q.receive() // Returns a high-level Stream of packets
     .map(|packet| {
         let mut ethernet = packet.parse::<Ethernet>()?;
         // Rust checks bounds here automatically
         ethernet.swap_addresses(); 
         Ok(ethernet)
     })
     .send(tx_port); // Ownership is transferred, prevents double-free
}

```

---

### 3. Summary of the Rust Scope

If you are starting a new high-performance networking project in 2026, here is where Rust fits:

* **Security-Critical Apps:** If you're building a Firewall, IDS, or VPN Gateway, Rust is the gold standard because it prevents memory-based exploits.
* **Complex Protocols:** Parsing complex protocols (like GTP or 5G signaling) is much safer in Rust thanks to its robust pattern matching and error handling.
* **Performance Parity:** You aren't sacrificing speed; you are just moving your "debugging time" from **runtime** (C crashes) to **compile-time** (Rust compiler errors).

---

### Comparison: Code Style

| Feature | C + DPDK | Rust + DPDK (with wrappers) |
| --- | --- | --- |
| **Packet Access** | Pointer arithmetic (dangerous) | Iterators & Bounds checking (safe) |
| **Multicore** | Manual thread pinning | `tokio` or `rayon` style concurrency |
| **Error Handling** | Integer return codes (-1, -ENOMEM) | `Result<T, E>` with detailed messages |


## Rust DPDK specific GitHub repositories or documentation for the current leading Rust-DPDK frameworks 

In 2026, the ecosystem for Rust and DPDK has matured from experimental scripts to production-ready frameworks. If you are looking to start a project today, here are the primary resources and libraries you should explore.

---

### 1. Leading Frameworks (2026)

#### **Capsule**

This remains the most popular framework for high-level network function development. It provides a declarative, "Safe" wrapper around DPDK.

* **Best for:** Building Firewalls, Load Balancers, and complex packet-processing pipelines.
* **Key Feature:** It replaces the manual loop-and-poll logic with a pipeline of combinators (similar to Rust’s `Iterator`).
* **Documentation:** [Capsule Docs](https://docs.rs/capsule)

#### **Codilime / rust-dpdk**

A widely used set of bindings that leverages `bindgen` to ensure compatibility with modern DPDK versions (e.g., DPDK 24.xx and 25.xx).

* **Best for:** Developers who want more control and are comfortable with a "C-like" style but within the Rust environment.
* **GitHub:** [codilime/rust-dpdk](https://github.com/codilime/rust-dpdk)

#### **dpdk-sys**

This is the low-level, raw FFI (Foreign Function Interface) crate. Most other frameworks use this as their foundation.

* **Best for:** Creating your own abstractions or very niche optimizations where you need direct access to every DPDK struct.
* **Source:** [dpdk-sys on Lib.rs](https://lib.rs/crates/dpdk-sys)

---

### 2. High-Level Architecture Comparison

Using Rust doesn't just change the syntax; it changes how you manage packet memory.

| Feature | C-DPDK Approach | Rust-DPDK (Capsule/Safe) |
| --- | --- | --- |
| **Packet Buffer** | Manual `rte_pktmbuf_free` | Automatic cleanup when `Mbuf` drops |
| **Concurrency** | Threads + Locks (Risk of Deadlock) | `Send` and `Sync` traits (Compile-time safety) |
| **Protocol Parsing** | Manual offset calculation (`void*`) | Typed structs and `nom` combinators |

---

### 3. Recommended Learning Path

1. **Start with the "Raw" Bindings:** Use `dpdk-sys` to write a basic "Hello World" similar to the C version. This helps you understand how the Rust FFI handles C pointers.
2. **Move to Capsule:** Once you understand the EAL initialization, use Capsule to see how a "declarative" pipeline can replace the infinite `for` loop.
3. **Explore `rust-vmm`:** If your goal is virtualization (Cloud/NIC acceleration), check out the [rust-vmm project](https://github.com/rust-vmm). It uses DPDK-like concepts for virtio and vhost-user devices.

---

### 4. Summary Checklist for your `Cargo.toml`

To get started, you'll typically need these dependencies:

```toml
[dependencies]
# The core bindings
dpdk-sys = "0.x"
# Safe abstractions (if using Capsule)
capsule = "0.x"
# High-speed parsing
etherparse = "0.13" 
# Manual memory/pointer alignment
aligned = "0.4"

```

