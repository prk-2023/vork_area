//-- Page setup  --//
#let fancybold(varna, body) = {
  text(fill: varna, font:"Open Sans", style: "italic", weight: "semibold", body)
}
#let skew(angle,vscale: 1,body) = {
  let (a,b,c,d)= (1,vscale*calc.tan(angle),0,vscale)
  let E = (a + d)/2
  let F = (a - d)/2
  let G = (b + c)/2
  let H = (c - b)/2
  let Q = calc.sqrt(E*E + H*H)
  let R = calc.sqrt(F*F + G*G)
  let sx = Q + R
  let sy = Q - R
  let a1 = calc.atan2(F,G)
  let a2 = calc.atan2(E,H)
  let theta = (a2 - a1) /2
  let phi = (a2 + a1)/2

  set rotate(origin: bottom+center)
  set scale(origin: bottom+center)

  rotate(phi,scale(x: sx*100%, y: sy*100%,rotate(theta,body)))
}
#let fake-italic(body) = skew(-18deg,body)

//First line indent for paragrah in the document 
#set par(first-line-indent: (amount: 2em, all: true)) // true to all paragraphs of the document
//set the content of the pragraph into justify  (for visual appearance)
#set par(justify: true)

#set page( background: rotate(24deg,
  text(36pt, fill: rgb("FFCBC4"))[
    $bb(bb("CONFIDENTAIAL"))$ #linebreak() $bb("DRAFT")$
  ]
))
//#set text(font: "Go Mono", lang: "en")
#set text(font: "Open Sans", lang: "en")
#set page(
  numbering: "1",
  number-align: center,
  margin: (top: 1.5in, bottom: 1in, left: 1in, right: 1in),
)
// Custom styles for notes, tips, and warnings
#let note(body) = block(
  fill: luma(240),
  inset: 1em,
  radius: 4pt,
  width: 100%,
  stroke: 1pt + luma(200),
  align(center + horizon)[
    #text(weight: "bold")[Note:] #h(0.5em) #body
  ]
)

#let tip(body) = block(
  fill: rgb(230, 255, 230),
  inset: 1em,
  radius: 4pt,
  width: 100%,
  stroke: 1pt + rgb(180, 255, 180),
  align(center + horizon)[
    #text(weight: "bold")[Tip:] #h(0.5em) #body
  ]
)

#let warning(body) = block(
  fill: rgb(255, 230, 230),
  inset: 1em,
  radius: 4pt,
  width: 100%,
  stroke: 1pt + rgb(255, 180, 180),
  align(center + horizon)[
    #text(weight: "bold")[Warning:] #h(0.5em) #body
  ]
)

// Title Page
#let Title = fake-italic("RTD1619b Yocto SDK Developer's Guide")
#v(30%)
#align(center)[
  #block(width: 100%)[
    #text(font: "Open Sans", 22pt, weight: "bold")[#Title] \
    #text(2pt)[-------]\
    #text(20pt, weight: "bold", fill: maroon)[*RTD1619b*] \
    #v(1em)
    #text(16pt, fill: maroon )[Version 1.0.0] \
  ]
  #v(20%)
  #image( "yocto_project_blog_logo-1024x535.png" , width: 15%) // Optional: Add your company/product logo
  #v(1fr)
  #text(12pt)[RealTek]
]

#align(center)[
  #text(fill: black, font:"Open Sans", style: "italic", weight: "semibold")[History]
]

//-- Document stat --//

// Table of Contents
#outline()
#set document(title: "Remote Processor Guide", author: "daybreak", description: "v1.0.0", date: datetime.today())
#set heading(numbering: "1.",  )

= Remote Processor:

Ref: The official kernel documentation for remote processor can be found at:

    https://docs.kernel.org/staging/remoteproc.html

== Introduction:


The `remoteproc` framework in the Linux kernel is primarily concerned with managing remote processor ( or coprocessors 

The `remoteproc` subsystem in the Linux kernel is primarily concerned with managing remote processors (or coprocessors
coprocessors) in a heterogeneous system. These systems often feature a primary CPU and additional
processors, such as DSPs (Digital Signal Processors), GPUs, or other specialized co-processors that run independently of the main CPU but still need to communicate with it.

To understand the `remoteproc` system and its kernel implementation, it's important to cover a few key historical and conceptual aspects:

### 1. **History of Heterogeneous Computing**

* **Heterogeneous Systems**: Modern computing systems increasingly use heterogeneous computing, where the main processor (often a powerful general-purpose CPU like ARM, x86, or PowerPC) works alongside specialized processors like GPUs (Graphics Processing Units), DSPs, FPGAs, or NPUs (Neural Processing Units). These specialized processors are optimized for specific tasks such as video encoding/decoding, machine learning, signal processing, or graphics rendering.
* **Co-Processors**: Historically, these specialized processors were considered "co-processors" — running in parallel with the main CPU but typically not directly managed by the operating system. Instead, they often required specific device drivers or custom software to communicate with the main system.

### 2. **Early Linux Support for Remote Processors**

* **Legacy of Remote Processor Management**: Initially, Linux was designed to manage only the main CPU. As heterogeneous systems grew in popularity, it became apparent that there was no unified way to handle remote processors (e.g., DSPs or specialized accelerators). This led to the development of `remoteproc`, which provides a framework for managing remote processors in Linux.
* **RemoteProc Goals**: The goal of the `remoteproc` subsystem is to provide a standardized way for the Linux kernel to manage these remote processors, load their firmware, and set up communication between the main CPU and remote processor(s). The subsystem helps decouple the details of remote processor management from the core Linux kernel, enabling cleaner, more maintainable code.

### 3. **Architecture of `remoteproc`**

The `remoteproc` subsystem abstracts out the complexities of managing remote processors and provides a consistent interface for both hardware and software:

* **Firmware Loading**: Many remote processors require firmware to function. The `remoteproc` subsystem manages the loading and unloading of this firmware. This is an essential feature because remote processors typically don't boot from the main system's firmware.
* **State Management**: Remote processors can be in different states, such as powered off, idle, running, or suspended. `remoteproc` provides mechanisms for state transitions and event handling, which helps coordinate the operation of remote processors in a complex system.
* **Memory Management**: Remote processors often need memory that is distinct from the main system memory. The `remoteproc` subsystem handles memory regions that are shared between the main CPU and remote processors.

### 4. **The `remoteproc` Kernel API**

The `remoteproc` subsystem provides a set of kernel APIs to interact with remote processors. Key functionalities include:

* **Initialization**: The `remoteproc` API handles the setup and initialization of remote processors, including memory management and device configuration.
* **State Transitions**: The API allows the kernel to move the remote processor between various states, such as powered off, halted, running, or suspended.
* **Interrupt Handling**: Remote processors often generate interrupts, which need to be handled by the main system. The `remoteproc` subsystem includes support for handling interrupts coming from remote processors.
* **Communication Mechanisms**: Many systems use a form of inter-process communication (IPC) between the main CPU and the remote processor. `remoteproc` often interfaces with other subsystems (like `rpmsg`, which is used for messaging between processors) to facilitate this communication.

### 5. **Integration with Other Kernel Subsystems**

* **RPMsg (Remote Processor Messaging)**: One common method of communication between a main processor and a remote processor is via the `rpmsg` subsystem. The `remoteproc` subsystem often works in tandem with `rpmsg` to facilitate message passing, data transfer, and synchronization between processors.
* **Devicetree**: In many embedded systems, the devicetree is used to describe the hardware configuration of the system, including remote processors. The `remoteproc` subsystem is often integrated with devicetree, allowing for automatic initialization and configuration of remote processors at boot time.
* **PM (Power Management)**: Power management is crucial when dealing with remote processors, especially in mobile and embedded systems where power consumption is a concern. The `remoteproc` subsystem integrates with the Linux power management infrastructure to ensure that remote processors are powered on or off as necessary.

### 6. **Real-World Use Cases**

* **System-on-Chip (SoC) Designs**: Modern SoCs (such as those used in smartphones, tablets, and embedded systems) often contain multiple processors, including general-purpose CPUs, GPUs, DSPs, and NPUs. Managing these processors efficiently is essential for system performance, power management, and functionality.
* **Embedded Systems**: Embedded systems often use remote processors to handle specialized tasks, such as video encoding/decoding or sensor data processing. In these systems, the remoteproc subsystem ensures that the remote processors are initialized and managed correctly.
* **Accelerators in AI/ML**: The rise of machine learning and AI has spurred the need for specialized accelerators like NPUs or TPUs. These processors require efficient integration into the Linux kernel, and the `remoteproc` subsystem plays a key role in managing them.

### 7. **Key Concepts to Understand**

To dive deeper into the `remoteproc` documentation, you'll need a good grasp of the following concepts:

* **Firmware Management**: Understanding how firmware is loaded, executed, and unloaded is fundamental. In some cases, remote processors must load their firmware at runtime, which is managed by the kernel's `remoteproc` subsystem.
* **State Transitions**: The ability to transition a remote processor between various states (e.g., halted, running) is central to its management.
* **Interprocessor Communication**: Understanding how data is exchanged between the main CPU and remote processors (via IPC, `rpmsg`, or memory sharing) is crucial to understanding how remote processors fit into the system.
* **Platform-Specific Code**: In some cases, supporting a specific remote processor requires writing platform-specific code in the kernel, especially when dealing with non-standard hardware.
* **Synchronization**: Remote processors may need to synchronize with the main CPU or with each other, so understanding synchronization techniques in the Linux kernel (e.g., mutexes, spinlocks) is important.

### 8. **Key Documentation Sections**

* **Introduction to RemoteProc**: Provides an overview of the subsystem's purpose and general usage.
* **APIs and Functions**: Lists the various kernel functions and structures for interacting with remote processors.
* **DeviceTree Integration**: Explains how to integrate remote processors into the devicetree for hardware description and initialization.
* **Use Cases and Examples**: Includes examples of how the `remoteproc` subsystem is used in real-world scenarios.

### Conclusion

The `remoteproc` subsystem is a key part of the Linux kernel for managing remote processors. It allows the main CPU to interact with specialized processors, loading their firmware, managing memory, and facilitating interprocessor communication. To fully understand the `remoteproc` subsystem, it's important to have a background in embedded systems, kernel programming, and heterogeneous computing, along with a grasp of how the Linux kernel handles device management, memory management, and power management.

If you'd like to dive deeper into any of these topics or have specific questions, feel free to ask!



Great question.

The **Remote Processor Subsystem (`remoteproc`) is not exclusive to the Linux kernel** — it is simply **one implementation** of a general concept: managing and communicating with **remote (or auxiliary) processors** in a heterogeneous system. So to answer directly:

---

### ✅ No, `remoteproc` is not Linux-exclusive in concept.

But...

### ⚠️ Yes, **Linux's `remoteproc` is a kernel-specific subsystem** implementation.

---

## 🔍 What is Remote Processor Management?

In modern **heterogeneous computing**, you typically have:

* A **main processor** (e.g., ARM Cortex-A running Linux or an RTOS)
* One or more **remote processors** (e.g., DSPs, Cortex-M cores, NPUs)

Managing these remote processors involves:

* Loading firmware
* Booting / stopping the processor
* Managing shared memory
* Inter-processor communication (IPC)

This is what Linux’s `remoteproc` subsystem does — it provides **drivers and APIs** to do all of this within the Linux kernel.

---

## 🦀 What about Rust-based RTOSes?

Yes, it **is absolutely possible** to implement similar remote processor management in **Rust-based RTOSes** or any embedded OS, **but you would need to implement it yourself** (or use an existing framework if available).

### Rust RTOS Example Projects:

* **Tock OS**: A secure embedded RTOS written in Rust
* **Hubris**: A microkernel by Oxide Computer
* **RTIC** (Real-Time Interrupt-driven Concurrency) framework for Rust on bare-metal

### Challenges in Rust RTOS for remoteproc functionality:

1. **Firmware loading**: The RTOS must support reading and parsing firmware images, possibly from flash or over-the-air.
2. **Boot control**: You must have a hardware-specific mechanism to control the remote processor (e.g., kick off a Cortex-M core from a Cortex-A).
3. **Memory mapping**: You need to set up shared memory correctly between the processors.
4. **IPC**: You would need to implement a messaging protocol like `rpmsg` or a custom one.

### Can Rust do this?

Yes:

* Rust has low-level control over memory and hardware.
* Rust's safety guarantees can help prevent bugs in memory sharing and IPC.
* But it lacks **mature, universal subsystems** like `remoteproc` and `rpmsg` — you'd need to build or port them.

---

## 🚀 Real-World Example Without Linux

On **many SoCs (e.g., TI's AM335x, NXP i.MX, STM32MP1)**:

* The **main CPU** runs Linux (or a RTOS),
* The **remote core** (e.g., M4F or DSP) runs a small RTOS or bare-metal firmware.

Some use cases:

* The main OS is Linux (with `remoteproc`)
* The remote core runs **FreeRTOS, Zephyr, or even a Rust-based RTOS**

In theory, you could replace both OSes with **Rust-based systems** (e.g., have a Cortex-A running Rust and booting a Cortex-M running another Rust RTOS).

---

## 🧩 Summary

| Feature                      | Linux `remoteproc`    | Rust RTOS                 |
| ---------------------------- | --------------------- | ------------------------- |
| Supported today              | ✅ Mature              | 🟡 Experimental / DIY     |
| Firmware management          | ✅ Yes                 | 🔧 Possible (manual)      |
| Interprocessor communication | ✅ via `rpmsg`         | 🔧 Custom or ported       |
| Power/state management       | ✅ Yes                 | 🔧 Depends on HAL support |
| Use in production            | ✅ Yes (e.g., TI, NXP) | 🟡 Rare (still growing)   |

---

## 🛠️ Conclusion

The idea of managing remote processors is **not limited to Linux**. Any OS — including those written in Rust — **can** manage remote processors **if it implements the necessary logic**.

The **Linux `remoteproc`** subsystem is just a mature, ready-made solution. If you’re using or building a **Rust-based RTOS**, you’d need to replicate this behavior yourself — which is a great opportunity, but also a challenge.

Would you like an architectural diagram or example Rust code outline for such a system?

------------------------------

You're right again — **designing the communication channel** between the host (Linux) and the remote processor (RTOS or firmware) is **one of the most complex and critical parts** of a heterogeneous system.

Let's unpack your question and explore:

---

## 🔁 Standard Communication Mechanisms

### 💬 Common Options Today:

| Mechanism            | Layer                             | Notes                                                              |
| -------------------- | --------------------------------- | ------------------------------------------------------------------ |
| **RPMsg**            | Application-level messaging       | Built on top of `virtio` & `mailbox`; most common for `remoteproc` |
| **Mailbox**          | Hardware interrupt + minimal data | Often used by RPMsg under the hood                                 |
| **Shared memory**    | Fast, low-overhead data exchange  | Needs synchronization and memory management                        |
| **Custom protocols** | Often tightly coupled             | Harder to generalize, high maintenance                             |

---

## 🧠 Can We Replace RPMsg/Mailbox with virtIO Devices?

### ✅ Yes, *in theory*, you can replace RPMsg with **standard virtIO devices** (like `virtio-net`, `virtio-serial`, `virtio-rpmsg`).

But:

* You’ll need to implement or **port virtIO support to the remote OS** (e.g., Zephyr, FreeRTOS, or your custom RTOS).
* Both ends (Linux + remote OS) need to support the **same virtqueue, descriptor ring, and transport protocol**.
* You'll need a **transport mechanism** (often based on shared memory + mailbox interrupts) to carry virtIO traffic.

---

### 📦 What is virtIO?

VirtIO is a **paravirtualized device framework** — designed for VMs but applicable to any system that needs virtual devices. Originally used in QEMU/KVM for devices like:

* `virtio-net` (network)
* `virtio-blk` (block device)
* `virtio-console` / `virtio-serial`

The **RPMsg protocol itself is built on virtIO**:

> `RPMsg` = `virtio` + `shared memory` + `mailbox` + `message protocol`

So you're basically asking:
**Can I use virtIO, but with other standard devices (not RPMsg)?**

---

## 🔌 Designing with virtIO Devices

### 🔁 Example 1: `virtio-net`

* You could expose a **virtual network device** to the RTOS.
* RTOS sends/receives packets as if through a NIC — Linux receives them via the `virtio-net` interface.
* You’d need:

  * A shared memory ring buffer for TX/RX descriptors
  * A mailbox or interrupt to notify the other core
  * A virtIO-net frontend on the RTOS side (there are examples in Zephyr!)

### 🔁 Example 2: `virtio-serial` or `virtio-console`

* This mimics a UART or console channel.
* Works well for command/control or log data.
* Simpler than `virtio-net`, but still needs virtIO framework.

---

## ⚠️ Challenges

| Challenge                    | Description                                                                                                 |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Remote OS support**        | You must port the virtIO frontend (device) drivers to your RTOS, which may not have standard virtIO support |
| **Transport setup**          | You still need a physical transport (shared memory, mailbox)                                                |
| **Virtqueue implementation** | You must manage virtqueue memory layout, ring buffers, and notifications                                    |
| **Firmware complexity**      | Often more complex than RPMsg, especially for small RTOSes or bare-metal targets                            |

---

## 🧪 When is this worth doing?

### ✅ Good use cases:

* You want to abstract your communication as a **device** (e.g., network interface, serial link, block storage).
* You want to **reuse Linux device drivers** (e.g., bring up a remote processor as a virtual NIC).
* You need **multiplexed channels** or higher performance than RPMsg.

### ❌ Not great for:

* Simple message-passing (RPMsg is easier).
* Tiny MCUs or RTOSes with minimal RAM/code footprint.
* When a ready-made RPMsg driver exists.

---

## 🏁 Summary

> Yes, **you can design a communication system using virtIO devices** (like `virtio-net`, `virtio-console`, etc.) instead of RPMsg + mailbox. In fact, **RPMsg already uses virtIO under the hood.**

But:

* You must **implement or port the virtIO frontend** to your remote OS.
* You still need **shared memory** and **interrupt-based signaling** (often via mailbox).
* This is **heavier than RPMsg** for most embedded use cases — so it’s more suited to powerful remote processors (e.g., Cortex-A or rich RTOS) than tiny MCUs.

---

Would you like:

* A diagram comparing `RPMsg` vs `virtio-net` style designs?
* Sample virtIO frontend skeleton for Zephyr or bare-metal?

Let me know how deep you'd like to go.

--------------------------------------
Great observation — you're touching on **shared memory coordination**, which is **crucial in remoteproc + heterogeneous systems**. Let's break this down into a clear explanation of:

---

### ✅ The Two Memory Regions You're Talking About

| Region                  | Purpose                                                           | Access                                               |
| ----------------------- | ----------------------------------------------------------------- | ---------------------------------------------------- |
| **A: RTOS-only memory** | Boot code, stack, heap, BSS for remote firmware                   | Used only by the remote core (not accessed by Linux) |
| **B: Shared memory**    | Data exchange between Linux & remote OS (buffers, messages, etc.) | Must be **coherently managed** between both          |

So **Region A** is private to the remote processor.
**Region B** is shared — and needs coordination.

---

## 🧩 So How Does Region B Work? (Shared Memory)

### 🧠 Memory Mapping

* Linux kernel allocates Region B (e.g., via CMA, DT, or static memory map)
* The memory region is:

  * **Mapped in Linux** kernel space (or user space via `mmap`)
  * **Linked or statically mapped** into the remote processor’s firmware (through the linker script or MMU config)
* Linux tells the remoteproc about this memory via the **resource table**

---

### 🔄 Coordination: Who Accesses When?

There are **three general strategies**:

---

### 1. **RPMsg (Message Passing Over Shared Memory) – Recommended**

**RPMsg**, built on **virtIO**, handles **shared memory + synchronization** with **virtqueues and signaling**:

* Memory B is structured as:

  * **tx/rx rings**
  * **buffers**
  * **flags / ready bits**
* The **virtIO queue structure** ensures:

  * Only one side owns a buffer at a time
  * Notification via mailbox or interrupt (e.g., “buffer ready”)
* RPMsg provides an abstraction — **you don’t need to implement locking manually**

✔ Easy
✔ Robust
✔ Already supported in Linux and Zephyr, FreeRTOS, etc.

---

### 2. **Custom Protocol: Flag-Based Locking in Shared Memory**

If you **don’t want RPMsg** and want a lightweight design:

* Use a shared region structured like:

```c
struct shared_buffer {
    volatile uint32_t ready;    // 0 = not ready, 1 = ready
    volatile uint32_t consumed; // 0 = waiting, 1 = consumed
    uint8_t data[1024];         // shared payload
};
```

* Example protocol:

  * RTOS writes data → sets `ready=1`
  * Linux polls or gets interrupt → reads data → sets `consumed=1`
  * RTOS waits until `consumed=1` before reusing buffer

⚠ Must use `volatile`, and memory barriers (`__sync_synchronize()` or `__DMB()` on ARM)
⚠ Race conditions can happen if logic isn't carefully implemented
⚠ Doesn’t scale to many channels or high throughput easily

---

### 3. **Using Mailbox + Shared Buffer**

Some designs use:

* Mailbox or hardware interrupt to signal “new data”
* Shared buffer in memory with known location

In this case:

* Buffer ownership is implicitly synchronized by:

  * Only writing after receiving "ACK"
  * Using barriers and flags to control access

Can be combined with **simple lock-free queues** in memory:

* Circular buffers
* Double-buffering

---

## 📐 Example: Linux + RTOS Shared Memory Flow

```text
     Linux Core                     Remote Processor Core
   -------------                   -----------------------
1. Allocates region B (via CMA or DT)
2. Maps B to Linux kernel
3. Passes region B address via resource table
                                  <- Firmware linker maps Region B to same physical address
                                  <- Knows where the shared buffer is

4. Writes to Region B
5. Sets flag, sends interrupt     -> RTOS ISR reads flag
                                  -> Reads data, clears flag
                                  -> Responds via same memory region or RPMsg
```

---

## 🔒 What about Mutual Exclusion?

> You **do not want to use real mutexes or semaphores** across OS boundaries — they assume shared scheduling, which doesn’t exist across processors.

Instead, you use:

* **Atomic flags**
* **Memory barriers**
* **Mailboxes or interrupts**
* **Single producer, single consumer patterns** (SPSC ring buffer)

---

## ✅ Best Practice Summary

| Feature      | RPMsg                       | Custom                                |
| ------------ | --------------------------- | ------------------------------------- |
| Performance  | Medium                      | High (can be lean)                    |
| Ease of use  | Easy (already implemented)  | Needs careful design                  |
| Safety       | High                        | Risky without barriers and atomic ops |
| RTOS support | Yes (Zephyr, FreeRTOS)      | Manual                                |
| Scaling      | Supports multiple endpoints | Needs extra design                    |

---

## 📌 Conclusion

You're spot on — **Region B shared memory** needs clear coordination:

* Use **RPMsg** if you can: It handles memory ownership and signaling for you using virtqueues + mailbox interrupts.
* If you must go custom:

  * Use shared flags
  * Combine with mailbox/IRQ
  * Use memory barriers and atomic access patterns

---

Would you like:

* A simple C struct + flag-based communication example?
* A deep dive into RPMsg internals and resource table format?

Let me know how deep you'd like to go!


----------------
OpenAMP
