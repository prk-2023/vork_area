# RDMA:  Remote Direct Memory Access

---

## RDMA:

- **RDMA (Remote Direct Memory Access)** is not a physical cable or a specific port; it is a **data
  transfer paradigm**. 

- In traditional networking (TCP/IP), the CPU acts as a "middleman." It must copy data from the
  application, wrap it in headers, and hand it to the NIC. On the receiving end, the CPU does the
  reverse. This consumes CPU cycles and adds "jitter" (latency spikes).

- **RDMA changes the rules:** It allows one computer to read from or write to the memory of another
  computer **directly**, with zero involvement from the remote CPU. Once the "handshake" is done, the
  hardware takes over.

## RoCE:

- **RoCE (RDMA over Converged Ethernet)** is a specific protocol that allows the RDMA paradigm to run over
  standard Ethernet cables and switches.

- Historically, RDMA required specialized **InfiniBand** hardware. RoCE was invented to bring that same
  performance to the Ethernet world you already use. There are two versions:
    * **RoCE v1:** A Layer 2 protocol. It only works if both computers are on the same switch (same
      broadcast domain). It is rarely used today.
    * **RoCE v2:** The modern standard. It wraps RDMA data inside **UDP/IP** packets. Because it has an IP
      header, it can be **routed** across different subnets and data centers. This is what your
      **ConnectX-5** cards use.

---

## How Linux Supports the RDMA Ecosystem

- The Linux kernel doesn't treat RDMA as a "standard" network interface like `eth0`. Instead, it has a
  dedicated **RDMA Subsystem**.

### **The Kernel Side (`drivers/infiniband`)**

- Despite the name, this directory handles all RDMA (InfiniBand, RoCE, and iWARP).
    * **Core Stack (`ib_core`):** The engine that manages memory pinning and protection domains.
    * **Hardware Drivers:** This is where your ConnectX-5 lives. The driver is `mlx5_ib`. It translates
      generic RDMA commands into the specific language the ConnectX-5 hardware understands.
    * **Verbs API:** This is the "language" of RDMA. Instead of `send()` and `recv()`, you use "Verbs" like
      `post_send` and `poll_cq`.

### **The User Space Side (`rdma-core`)**

- Linux provides a set of libraries that allow your C or Rust code to talk to the hardware without going
  through the slow kernel path (Kernel Bypass).
    * **`libibverbs`:** The primary library for data transfer.
    * **`librdmacm`:** The "Connection Manager." Since RoCE v2 uses IP addresses, this library helps you
      find the other computer and set up the initial connection.

- `libibverbs`: Core linux user-space library that enables applications to perform Remote Direct Memory
  (RDMA) operations.
  - Provides Standardized HW-agnostic API that allow SW to communicate directly with RDMA capable network
    HW ( infiniband, iWARP and RoCE ) adapters. Allowing programs to by-pass the OS kernel for data
    transfer. 
  - This achieve high-throughput and low-latency networking by reducing CPU overhead:
    * Kernel Bypass: data path operations happen directly between applications and network HW. ( avoids
      overhead of system calls and context switched into the kernel)
    * Zero-Copy Networking: Data is moved directly between application memory and the network HW, avoiding
      intermediate copies between user and kernel memory buffers. 
    * Async I/O: Used mechanisms like *Complete Queues* (CQs) to handle data transfers asynchronously,
      allowing the applications to continue processing without waiting for network operations to finish.

- `libibvers` Verbs API: Library implements the **Verbs** Interface as defined in InfiniBand Arch Spec.
  This API provides the primitives for resource management, such as creating Protection Domains, Memory
  Regions, Completion Queues and Queue Pairs. 

- `User/Kernel Interaction` : 
    - *Control Path*: Complex setup/teardown tasks ( creating resource ) are handled by communicating with
      the kerenl via the `ib_verbs` kernel module. 
    - *Fast Path*: Once resources are established, the application interacts directly with the network HW by
      writing to HW registers mapped into its user-space memory ( `mmap()`)

- Vendor Plugins: `libbibverbs` acts as an abstraction layer.To support specific HW it uses vendor-specific
  user-space drivers ( providers ) that handle the actual communication with the specific network adapter. 

- `rdma-core`:  `libibvers` is a part of `rdma-core` project, which contains the common user-space
  infrastructure for all RDMA technologies on Linux.

- `librdmacm`: For applications that require standard IP-based addressing ( Connection establishment, route
  resolution), `libibverbs` is typically used in conjunction with `librdmacm` ( RDMA Connection Manager).

Reference:
    - [RDMAmojo blog:](www.rdmamojo.com) RDMAmojo resource for understanding the API and InfiniBand
      concepts. 

### Control Flow of RDMA application: 

Before sending a single byte, you need to set ip a specific set of resources:

- ** `libibvers` initialization workflow**: Setting up a connection involves several distinct objects that
  work together. ( i.e setting up a private high-speed lane ).
  1. **Device Discovery**: 
    - `ibv_get_device_list()`: find available RDMA adapters
    - `ibv_open_device()`: Start a session. 
  2. **Protection Domain (PD)**:
    - `ib_alloc_pd()`: Create a PD. This acts as container that groups resources ( like memory and queues)
      to ensure they can work together securely. 
  3. **Memory Registraion (MR)**: You must "pin" the mem you want to use for data transfer using:
    - `ibv_reg_mr()`: Tells the OS not to move this memory to disk (swap) so the HW can access it directly. 
  4. **Completion Queue (CQ)**:
    - `ibv_create_cq()`: Creates a CQ. This queue is where HW places "work completions" to tell you a
      transfer is done. 
  5. **Queue Pair (QP)**:
    - `ibv_create_qp()`: Creates a QP. This consists of a *Send Queue* and *Receive Queue*. This is primary
      interface for posting work requests. 

### Simple Code Ex: Opening a Device: 

Code snippet : How to initialize the very first step in C:
test.c
```c 
#include <stdio.h>
#include <infiniband/verbs.h>

int main() {
   struct ibv_device **dev_list;
   struct ibv_context *context;
   /* 1. Get the list of RDMA Devices */
   dev_list = ibv_get_device_list(NULL);
   if (!dev_list) {
      perror("Failed to get RDMA devices list");
      return 1;
   }
   /* 2. Open the first available device */
   context = ibv_open_device(dev_list[0]);
   if (!context) {
      fprintf(stderr,"Couldn't release context for %s\n", ibv_get_device_name(dev_list[0]));
      return 1;
   }
   printf("RDMA device %s opened successfully.\n", ibv_get_device_name(dev_list[0]));
   /* 3. cleanup */ 
   ibv_free_device_list(dev_list);

   return 0;
}
```
Makefile:
```make
# Compiler
CC = gcc

# Compiler flags: 
# -Wall for general warnings
CFLAGS = -Wall

# Linker flags: -libverbs is required for libibverbs applications
LDFLAGS = -libverbs

# Binary name
TARGET = rdma_test

# Source file
SRC = test.c

all: $(TARGET)

$(TARGET): $(SRC)
        $(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

clean:
        rm -f $(TARGET)

# Useful target to run with sudo since RDMA devices often require root privileges
run: $(TARGET)
        sudo ./$(TARGET)

```
```bash 
$ ./rdma_test 
RDMA device rocep1s0f0 opened successfully.
```
---

## Key Differences in the Linux CLI
When you plug in your ConnectX-5 cards, you will see two different "identities" for the same hardware:

| Interface Type | Tool to View | Purpose |
| :--- | :--- | :--- |
| **Ethernet Identity** | `ip link` | Used for standard pings, SSH, and TCP traffic. (e.g., `enp1s0`) |
| **RDMA Identity** | `ibv_devices` | Used for RDMA "Verbs" traffic. (e.g., `mlx5_0`) |

---

### Summary for your ConnectX-5 Setup
With CX5 cards on system, Linux will see the hardware as an Ethernet card, but the **`mlx5_ib`** driver will
"expose" an RDMA device to the system. You will use the Ethernet side to assign an IP address (the handshake
address) and the RDMA side to move the actual data.
Before we move to Phase 1 there are some important internals to pickup:

## 1. The Verbs API ( The language ):

- Standard Linux networking, you use "Sockets" (`send`, `recv`). In RDMA, we use **Verbs**.

- Because a "Socket" implies the Kernel is handling the buffer. 
- A "Verb" is a direct command to the Hardware.

* **The Big Three:** * `POST_SEND`: "Hey NIC, take this data and go."
    * `POST_RECV`: "Hey NIC, I've cleared some space in my RAM; put the next incoming data there."
    * `POLL_CQ`: "Hey NIC, are you done yet?"

### 2. The Memory "Pinning" Requirement
This is the #1 point of failure for beginners. 
* **Standard RAM:** The Linux kernel moves memory pages around (swapping) to optimize performance.
* **RDMA RAM:** The NIC needs to know the **physical address** of your data. If the Kernel moves a page while the NIC is writing to it, you get a system crash or data corruption.
* **The Fix:** You must "Register" memory. This "pins" the memory in place so the Kernel cannot touch it until the RDMA operation is over.

### 3. The Libraries (The Tools)
You don't need to know every file, just these three layers:
1.  **`libibverbs`**: The "Low-Level" library. You use this to move data.
2.  **`librdmacm`**: The "Connection Manager." You use this to find the other computer's IP and "dial" them.
3.  **`rdma-core`**: This is the umbrella project name on GitHub that contains both of the above.

---

## `Ping Pong`: style data transfer.

- "Hello world" of RDMA. Demonstrates how two machines actually exchange data once the device is opened. 

### RDMA Data transfer Flow:

In a standard "Send/Receive" operation, the flow follows a strict handshake between the CPU and the HCA 
(Host Channel Adapter):

1. **Post Receive:** 
    - The receiver must *first* tell its HW where to put incoming data by posting a "Receive Request" to its
      Queue Pair.
2.  **Post Send:** 
    - The sender posts a "Send Request" containing the data.
3.  **Hardware Transfer:** 
    - The *HCAs* communicate across the network without involving either CPU.

4.  **Completion:** 
    - Both sides poll their Completion Queues (CQ) to see a "Work Completion" (WC) entry, signaling the
      transfer is finished.

### Detailed Code Example: Memory Registration and Sending

Once you have your `context` and `pd` (Protection Domain) from the previous step, you would register memory
and send a buffer like this:

```c
    // 1. Register a memory buffer (1KB) for RDMA
    char *buf = malloc(1024);
    struct ibv_mr *mr = ibv_reg_mr(pd, buf, 1024, IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_READ);

    // 2. Prepare a "Scatter/Gather" element (points to our data)
    struct ibv_sge sge;
    sge.addr   = (uintptr_t)buf;
    sge.length = 1024;
    sge.lkey   = mr->lkey;

    // 3. Prepare a "Work Request" (the command for the HCA)
    struct ibv_send_wr wr, *bad_wr;
    memset(&wr, 0, sizeof(wr));
    wr.wr_id      = 123; // Private ID to track this specific request
    wr.sg_list    = &sge;
    wr.num_sge    = 1;
    wr.opcode     = IBV_WR_SEND;
    wr.send_flags = IBV_SEND_SIGNALED; // Tell HCA to create a Completion entry

    // 4. Post the send to the Queue Pair (qp)
    if (ibv_post_send(qp, &wr, &bad_wr)) {
        fprintf(stderr, "Error posting send\n");
    }

    // 5. Wait for completion
    struct ibv_wc wc;
    while (ibv_poll_cq(cq, 1, &wc) < 1) {
        // Busy-wait/spin until data is sent
    }

    if (wc.status == IBV_WC_SUCCESS) {
        printf("Message sent successfully!\n");
    }
```

### Comparison: RDMA vs. Standard Sockets
It helps to visualize why `libibverbs` feels so different from standard `TCP/UDP` programming:

| Feature | Standard Sockets (`POSIX`) | RDMA (`libibverbs`) |
| :--- | :--- | :--- |
| **Data Copying** | Multiple (User $\rightarrow$ Kernel $\rightarrow$ NIC) | Zero (User $\rightarrow$ NIC) |
| **CPU Usage** | High (Interrupts, Protocol Stack) | Near Zero (Offloaded to HCA) |
| **Latency** | ~10–50 microseconds | < 1 microsecond |
| **Complexity** | Simple (read/write) | High (Queue management) |

Install development libraries to compile and run the code.

###  Requirements:

1. `ibv_device`: list of all RDMA-capable devices currently recognized by the verbs library.

```bash 

$ ibv_devices 
    device                 node GUID
    ------              ----------------
    rocep1s0f0          6cb31103008855b4
    rocep1s0f1          6cb31103008855b5

```
2. `ibv_devinfo`: state of the physical ports, the maximum supported MTU, and the link layer (InifiniBand
   vs. Ethernet/RoCE).
   ```bash 

   $ ibv_devinfo
     hca_id: rocep1s0f0
        transport:                      InfiniBand (0)
        fw_ver:                         16.35.4506
        node_guid:                      6cb3:1103:0088:55b4
        sys_image_guid:                 6cb3:1103:0088:55b4
        vendor_id:                      0x02c9
        vendor_part_id:                 4119
        hw_ver:                         0x0
        board_id:                       MT_0000000425
        phys_port_cnt:                  1
                port:   1
                        state:                  PORT_ACTIVE (4)
                        max_mtu:                4096 (5)
                        active_mtu:             1024 (3)
                        sm_lid:                 0
                        port_lid:               0
                        port_lmc:               0x00
                        link_layer:             Ethernet

     hca_id: rocep1s0f1
        transport:                      InfiniBand (0)
        fw_ver:                         16.35.4506
        node_guid:                      6cb3:1103:0088:55b5
        sys_image_guid:                 6cb3:1103:0088:55b4
        vendor_id:                      0x02c9
        vendor_part_id:                 4119
        hw_ver:                         0x0
        board_id:                       MT_0000000425
        phys_port_cnt:                  1
                port:   1
                        state:                  PORT_ACTIVE (4)
                        max_mtu:                4096 (5)
                        active_mtu:             1024 (3)
                        sm_lid:                 0
                        port_lid:               0
                        port_lmc:               0x00
                        link_layer:             Ethernet

   ```
   - **hca_id**: The name you use in code 
   - **port_list**: Most cards have 1 or 2 ports. 
   - **state**: This must say PORT_ACTIVE. If it says PORT_DOWN or PORT_INITIALIZING, your code will be able
     to "open" the device, but you won't be able to send any data.
   - **link_layer**: Tells you if you are running on InfiniBand or Ethernet (RoCE).

3. Kernel modules:
```bash 
$ lsmod | grep ib_uverbs
  ib_uverbs             217088  2 rdma_ucm,mlx5_ib
  ib_core               585728  12 rdma_cm,ib_ipoib,rpcrdma,ib_srpt,iw_cm,ib_iser,ib_umad,ib_isert,rdma_ucm,ib_uverbs,mlx5_ib,ib_cm
```

4. Hardware Presence: Check if the PCIe card is even visible.
```bash 
$ lspci | grep -i mellanox  
01:00.0 Ethernet controller: Mellanox Technologies MT27800 Family [ConnectX-5]
01:00.1 Ethernet controller: Mellanox Technologies MT27800 Family [ConnectX-5]
```

### Soft-RoCE : You dont require expensive HW :

- You can simulate an RDMA device over your standard Ethernet card using Soft-RoCE (RXE):

```bash 

$ sudo rdma link add rxe0 type rxe netdev eth0

```
Now, `ibv_devices` will show `rxe0`, and your code will run perfectly for testing!

### Update on Kernel/Hardware translation
You asked how a generic command becomes a "ConnectX-5" command. 
1.  **Your App** calls a Verb (e.g., `ibv_post_send`).
2.  **`libibverbs`** looks at your hardware and loads a "User-space Driver" (for CX5, this is `libmlx5`).
3.  **The User-space Driver** writes a specific "Doorbell" (a tiny piece of data) directly to the PCI-Express address of your CX5 card.
4.  **The CX5 Hardware** sees the Doorbell, fetches the command from your RAM, and sends the packet. 

**The Kernel (`ib_core`) is bypassed entirely during the actual data transfer!** It only gets involved to set up the permissions at the beginning.
---

Next Phase 1:
- With the understanding of "pinning RAM" and "ringing a hardware doorbell," the Soft-RoCE setup will make 
  much more sense. 
- Look at step-by-step commands to enable Soft-RoCE and run your first hardware-emulated ping.

