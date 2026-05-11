# Introduction to Rust and eBPF with Rust:


Introduction:

Systems programming is evolving but the core constraints remain the same:
    - performance 
    - determinism
    - hardware control 
    - low-level safety 

- C language has evolved along with this ideas, and is the dominant language as it maps closely to hardware
  and the programs are predictable. 

- How ever modern systems face a recurring class of issues:
    - Memory safety bugs ( use-after-free, buffer overflow )
    - concurrency bugs ( data race in kernel contexts )
    - security vulnerabilities in privileged code paths. 

Its key to understand that these changes are not meant about replacing existing foundation, but about
expanding the toolbox for safer systems development. 


### Disclaimer: 


A No-hype disclaimer and Scope:

This talk focuses on the ongoing evolution in systems programming, and not intended to be a debate about  
“language war.” 

The aim is to evaluating a tool and not religion. 

From an evolutionary rather than revolutionary perspective, Rust should be views as a complementary tool for
solving specific classes of bugs - particularly spatial and temporal memory safety issues which are
historically difficult to eliminate in a large C-based codebase. 

The main objective is to analyze technical "why" and "how"  behind Rust's integration into the Linux kernel
and along with its practical utility for modern systems engineer as this matters the most for your companies
work.

The talk is divided into 3 parts:

Part 1: Introduction to rust as systems programming language 

We will explore what features makes rust a systems programming language.
    - zero-cost abstraction: High level ergonomics without Garbage collection tax 
    - Borrow Checker as static analyzer: Rust moves Use-after-free, Race Conditions from runtime to
      compile-time. 
    - Memory Layout control: precise control over memory representation using features such as (#[repr(C)])
      enabling seamless FFI interoperability and suitability for BSPs, firmwares and low-level system work.
    - Fearless Concurrency: Rusts type system enforces thread-safety guarantees by design, helping prevents 
      data races in SMP env. 
    - Hardware/System Fit: #[repr(C)] and Zero-Cost abstractions, proves Rust can "talk" to the hw and the 
      existing C codebase without overhead.
      Rust does'nt mess with memory layout unless you ask for it, we can share a struct between C and Rust bit-for-bit."
    - Borrow checker and Concurrency is what is missing with C.

(These are some of the ideas that has made Rust popular in short time).

Part 2: Rust in Linux kenrnel:
    - Chronological update from initial proposal to current stable ( pinned ) types.
    - Build flow: How rust is integrated into the exisiting kernel build system. 
    - Role of `bindgen` ( generates Rust FFI from C headers)
    - Abstractions layer: why we do not call C fun's directly but wrap them in safe Rust interfaces. This is
      for "safety," but to provide idiomatic interfaces that prevent the user of the driver from ever being
      able to cause a Null pointer dereference or a Use-after-free.
    - Hello world: a brief comparison between rust  `module!` macro vs the traditional `module_init/exit`
      pattern.
    - Adoption Map:


| adoption status  | sub-systems  | 
| :--- | :--- | 
| Early Adopters: | NVMe drivers, DRM abstractions, and Android Binder. |
| Wait and watch zone:| Core MM ( Memory management ) and deeply entrenched legacy subsystem. |
| Industry Push:| google, Microsoft( funding to reduce long tail of security Vulnerabilities), amazon. |


Part 3: eBPF programming with Rust 
    - Aya Framework: A purely Rust-based eBPF library that doesn't depend on libbpf or llvm at runtime.
    - Observability Case Study: Tracking DMA latency with microsecond precision using BPF maps.
    - The Fast Path: XDP & AF_XDP: 
        - XDP: Programmable packet processing at the NIC driver level.
        - AF_XDP: efficient zero-copy packet processing using shared UMEM regions managed safely from Rust.
    - Rust + AF_XDP vs DPDK:  Why parts of the industry is looking at Rust + AF_XDP as a mem-safe, 
      maintainable alternative to traditional DPDK for user-space networking stacks.

NOTE: 
- that Rust is not going to replace C in Linux kernel.
- The more realistic question is: where does stronger compile-time correctness meaningfully reduce risks in
  modern systems software. 

## Part 1:

### Slide 1: ( Rust as a systems programming language)

- `C` remains the de-facto industry standard for systems programming across operating systems, kernels,
  embedded systems, and runtime infrastructure. 

- However systems written in C  are prone to classes of errors that are both easy to introduce and difficult
  to detect, even under careful code-review and testing ( ex: mem-safety issues, undefined behaviour,
  concurrency issues) 
- In this model safety is largely developer-dependent, leading to complexity and maintenance cost.
- In the case of Linux kernels after 30+ years of evolution, there is a concern about the sustainability of 
  onboard new contributors who are expected to work within the constrains and risks of manual memory
  management in C.

Rust design philosophy:
Rust aims to address many of these challenged by shifting correctness guarantees to the compiler, while
preserving performance, low-level control, and reliability expected from systems programming. 

In short Rust hits all essential markers of a systems programming language:

    - NO GC: Unlike Java or Python, Rust has no runtime overhead or "stop-the-world" pauses. It manages memory via RAII and a Compile-time Borrow Checker. This ensures deterministic performance and a minimal footprint, making it a viable replacement for C in kernels, drivers, and real-time systems.

    Note: RAII (Refer raii.md)[./raii.md]  ( refer to this doc if some one ask for how it raii works)

    - Zero-Cost Abstractions: Key for systems programmer. It means that high-level features (like iterators, closures, or generics) compile down to the same efficient machine code you would have written by hand in C.i.e compiler is smart enough to "erase" the high-level syntax, leaving only the raw assembly behind.

    - Memory Safety without Overhead: Rust prevents "segmentation faults" and "dangling pointers"—the bane of C/C++—at compile time. It does this through Ownership and Borrowing, which track who "owns" a piece of data and for how long.

    - Bare Metal Capability: Rust can run "No-Std" (without a standard library), making it suitable for microcontrollers, OS kernels, and firmware where there is no operating system to rely on.

    - Fearless Concurrency: In systems programming, multi-threading is necessary but dangerous (leading to data races). Rust’s type system ensures that data cannot be modified by two threads at once, catching race conditions before the code even runs.

### Slide 2: Memory safety: ( The eternal memory bug)

Memory safety has not meaningfully improved: the Number of issues over the past 20 years have not changed. 
- 70% of Microsoft CVEs are memory safety issues.
- ~67% of Linux Common Vulnerability Exposures ( CVEs ) are traced to memory safety violations 
  (Gaynor & Thomas, Linux Security Summit 2019 — still  holds in 2025 audits)
- 70% of high-severity chromium bugs are memory safety related. 
- Android ecosystem estimates attribute $68B in security costs ( 2019 ) to memory safety issues. 

Insights: 
- Tooling ASan, Coverity, Sparse : reduce bug rates but do not eliminate entire classes of bugs.
- fundamental limitation is architectural: ** As long as type-system allows these states, they remain
  possible at runtime. 

- Elimination of these bugs: Make them un-representable in the type-system and with help of compiler. 

Root-causes :
The table shows some common root causes for bugs:

- These are not “rare edge cases”
- They are systemic failure modes of the memory model itself
- They persist because C prioritizes performance and control over safety invariants and kernel developers
  are expected not to shoot themselves. But generally this doesn't scale with team size.

### slide 3:

=> Rust eliminates every one of the listed bugs at compilation time ( static analysis ) and with Zero
runtime cost that is it requires no additional CPU cycles to achieve this.

- Kernel maintainers spend a big part of their time reviewing code for memory leaks or pointer errors. 
  Rust adoption would significantly reduce time in fixing basic memory bugs.

- The above survey on CVEs and How rust eliminates them has been the main reason for its adoption into Linux
  kernel as a second language.

- Frame the cost: CVE triage, patch backports, OEM customer escalations, re-spins. Audience knows this pain
  directly.


### Slide 4: before Rust:


OS and system developers have historically faces a binary tradeoff:
1. Safe but slower ( GC - based languages )
    - Java, Go, Python ..
    - memory safety is enforced via garbage collector.
    - eliminates entire classes of bugs like use-after-free. 
These come at a cost:
    - GC pauses leading to unpredictable latency. 
    - Runtime overhead ( consumes additional cpu cycles )
    - large execution footprint.
    - poor fit for kernel code, interrupt context, and real-time constrains. 

2. *Fast but unsafe* (C, C++) 
    - Maximum control, minimum overhead
    - *Cost*: all memory bugs are the programmer's problem
    - 30+ years of CVEs are the empirical evidence

Rust closes the gap: 

Rust is positioned to bridge this long-standing divide:
    - provides memory safety without a garbage collector. 
    - Maintains performance comparable to C.
    - Enables zero-cost abstractions ( no hidden runtime over head ==> no additional cpu cycles)

This allows Rust to combine:
    - The control of systems programming.
    - with safety guarantees previously only available in managed run-times.

=> Rust is not just another general purpose language: It represents a new point in the systems programming
design space, where safety and performance are no longer mutually exclusive. 
 
### Slide 5: 

Ownership Memory safety at compile time:

Ownership is a memory management model where each value has a single owner at any given time.

The compiler enforces rules around Ownership, moves and scope, shifting memory safety from runtime
enforcement to compile-time verification. 

Core rules:
1. Each value has a single owner.
2. There can only be one owner at a time ( ownership can be transferred, i.e moved )
3. When Owner goes out of scope, the value gets dropped ( memory is freed ).

=> The key idea here is the rules are enforced by the compiler, making invalid memory states
un-representable at runtime.

Next slide: Use-after-free:

In C memory ownership is implicit and manual:
    - memory can be freed while pointer still reference it. 
    - Compiler does not track lifetime relationships.
    - This leads to use-after-free (UAF) and dangling pointer bugs. 

Rust Prevents this class of bugs by construction:
    - Once ownership is moved the old reference is invalidated.
    - The compiler tracks lifetimes and enforces validity.
    - use-after-free becomes a compile-time-error, not a runtime bug.

Ownership model is one of the Rust's defining contributions, reshaping how memory safety can be expressed at
compile time. 
It encodes memory safety directly into the type system rather than relying on runtime checks or developer
discipline. 

Next Slide: ownership prevents leaks:

Ownership prevents leaks — RAII in kernel drivers

In C, every error exit path in a driver must explicitly handle cleanup.
This makes resource management error-prone and path-dependent, especially as control flow grows.

While Rust makes this structurally reliable.

( check at gemini: "what is RAII with respect to linux kernel")

--- 
### slide 5: Borrowing & Lifetimes - Preventing Data Races:

- If Ownership were the only mechanism then code would become impractical very quickly because, the program
  needs to transfer ownership just to read or temporarily use data. 
  This where Borrowing comes in:
- Borrowing lets temporary access data without taking ownership. 

- Borrowing allows rust to safely support:
    - Shared access 
    - mutation 
    - function calls 
    - efficient code without copying 
    - concurrency safely 
- while still preventing:
    - dangling pointers 
    - use-after-free 
    - data races 
    - double free bugs 

- Borrowing is the mechanism of accessing data without taking ownership. This is implemented via
  **References**, which are distinct types in the Rust Compilers view. 
  1. So a `String`, `&String` and `&mut String` are 3 different types with different capabilities. 
  2. Physical vs Logical: Physically references are just pointers ( mem addresses) like in C. Logically they
     are "permission slips" that the compiler tracks to ensure memory safety. 
  3. => Rust allows Shared Read-Access ( many &T ) or Exclusive Write-Access ( &mut T ) But never both
     simultaneously, This eliminates data race at compilation time. ( As in the slides example  shows)
     i.e 
     Data race = Aliasing + Mutation + No synchronization 
     Rust solves this by banning the combination. 


Next-Slide: ( Lifetimes and Dangling pointers )

This slide moves from *permission* ( what you can do ) to **duration** ( how long you can do it ).
=> Lifetimes are the compiler's way to ensuring that every reference points to valid memory. 

- Rust lifetimes are a compile-time mechanism used by the borrow checker to ensure that all references to
  data are valid and never dangle, preventing memory safety bugs. 

- A lifetime is the scope for which a reference is valid. 

- Every reference in Rust has a lifetime, even if the compiler usually infers it for you. 

- Core Rule: **A Reference cannot outlive its owner** 

- In C or other languages you can accidentally free memory while a pointer is still looking at it. ( this
  creates a dangling pointer )

- In Rust Borrow Checker compares the scope of the data ( The Owner ) and scope of reference (the Borrower). 

- If the Borrower scope is longer then owner the code fails to compile. 

- Explicit lifetime annotations (` 'a `)
    - Sometimes the compiler needs help, especially when a function returns a reference. 
    - Explain that ` 'a ` doesn't change how long a variable lives; it simply described the relationship
      between the inputs and outputs so the compiler can verify them. 
    - Analogy: Its like a contract stating. This return value is guaranteed to be valid as long as this
      specific input is still around. 

- Unlike C where there is freedom to point to garbage, Rust gives you guarantee that if a pointer exists,
  the data behind it exists too. This ensures there you never meet with `NullPointer` or `use-after-free`
  error in production. 

- In kernel : `struct device` is often managed by reference counting ( like `Kobject`). However raw `C`
  doesn't stop you from storing a pointer to that device in a structure that exists longer than the device
  itself. ( Rust lifetime system turns this logic to compilation error )

- Device Drivers: 
    - Drivers often deal with HW that can be hot-plugged ( USB, PCIe )
    - When a device is removed ( unplugged) kernel must ensure no active code ( mainly interrupt handler )
      tries to access that memory. 

    - If interrupt handler holds a  reference to `&Device` Rust lifetime system ensures the handler's
      registration cannot outlive the `Device` Object. 

    - Compiler forces a relationship:  `Lifetime(Handler) < Lifetime(Device)` 

- Race to grave: 
    - In C you might un-register the interrupt, but if a thread is still executing that handler and the 
      device memory is freed, the system crashes.

    - In Rust, the API for registering a handler can be designed to "borrow" the device. 
      If you try to drop the device while the borrow (the handler) is still active, the code won't compile.

- Static Analysis vs Runtime debugging.
    - C Approach: Rely on developer discipline and complex `kref` incrementing/decrementing. 
      Debugging failures requires analyzing memory dumps.
    - Rust Approach: The "Borrow Checker" acts as a static analyzer. 
      If the driver logic is unsound, the build fails. 
      It shifts the "cost" of the error from the end-user (a crash) to the developer (a compiler message).

Todo: update the slide with mermaid


...
- Borrowing looks similar to pointers in C, but they behave differently to the compilers. 
- In C we can have any number of pointers to a same integer, they can read and write to it simultaneously,
  the language does not stop you from doing anything dangerous ( leaving synchronization to developer ),
  In Rust Borrowing , a references is an address + permission slip, that is checked by the compiler at every
  step. 

- So adding `&` and `&mut` to a base type, is creating a new distinct types in the Eyes of the compiler.


- It formalises the aliasing rules that C developers know informally but often violate.


--- 
### Slide 4: 
- Rust is a Systems programming Language, a relatively new programming language on the block.

- It started in 2006 by a Graydon Hoare a SW engineer at Mozilla
    
    - After it's first stable release 1.0 (may 2015) it was followed by big tech adoption ( AWS Firecracker
      (micro-VMs), Google’s Android Bluetooth stack )
    - As of 2021 it went independent with Rust Foundation ( support from google, MS, AWS ..)

- Rust has gain a attention over past 5 years for its design principles and with the adoption into Linux
  kernel, the basic idea of the language is cornered to security/performance and importantly the way it
  mandates these ideas rather then depending on the developer to put them in to practice.

- Why Rust for Systems: ( Most notable features )
    1. Memory Safety (No runtime memory management or deterministic mgmt, ( no GC ), adoption of  Ownership
       Model, Borrowing, Lifetimes, type system eliminates use-after-free, double free )
    - Fearless Concurrency ( Compile time verification of `Send`/`Sync`, eliminates data Races )
    - Modern Tooling ( Cargo package manager, builder and more  handle cross build, dependencies, replaces
      complex Makefile, Autotools, build scripts ..)
    - Zero-Cost Abstraction: High level safety with C-level performance. ( Safety features requires no 
      additional CPU cycles)
    - `#[no_std]`: Rust can run without standard library ( bare metal ), we will use in our later eBPF 
      example. 
    - FFI `#[repr(C)]`: Rust was built to talk to C, allowing to work seamlessly with C drivers, diagnostic 
      telemetry or complex state machines in Rust, linking them seamlessly. FFI makes sure to match the C
      ABI of the target. 
    - Compiler ( Static analysis, Mandates Rust ideology for builds, ensures mathematical correctness ) 
    - Rust = "C + built-in formal verification"
      
### Slide 2: 



