# Introduction to Rust and eBPF with Rust:

### Disclaimer: 

This talk focuses on the ongoing evolution of systems programming, not on promoting a “language war.” The
goal is to highlight the direction of the ecosystem and the practical utility emerging from Rust’s
integration with the Linux kernel.

The talk is split into 3 parts:

Part 1:
    Introduction to rust as systems programming language (Ideas of Rust that has made it popular in short time).
Part 2: 
    Rust in Linux Kernel ( Chronological update, Hello World, build flow and which stacks are adopting and
    which are not, and the push from Industry )
Part 3: 
    eBPF programming with Rust ( Aya, example dma latency, xdp, AF_XDP an alternative to dpdk and RDMA )

## Part 1:

### Slide 1: ( Rust as a systems programming language)

- `C` remains the de-facto industry standard for systems programming.
- Systems built with C often contain errors that are easy to make and difficult to detect even during rigorous code review.
- Safety in the currently developer-dependent ( complexity + cost of maintenance )
- Linux kernel: evolved over 30+ years, there is a growing concern that new developers are less interested 
  in working with the risks associated with "manual" C.

Rust Model Philosophy: Address many of these challenges with out compromising on security,performance or reliability.


### Slide 2: Memory safety: ( The eternal memory bug)

- ~67% of Linux CVEs traced to memory safety violations (Gaynor & Thomas, Linux Security Summit 2019 — still
  holds in 2025 audits)
- Concrete driver examples: use-after-free in USB subsystem, OOB writes in DMA engine code — the kind your
  team has debugged
- C gives you the loaded gun; kernel developers are expected not to shoot themselves. This doesn't scale
  with team size.
- Frame the cost: CVE triage, patch backports, OEM customer escalations, re-spins. Audience knows this pain
  directly.
- Set up the question: what if the compiler could prove correctness at submission time?

=> Root cause: use-after-free, Buffer overflow, Data Race, Null Deref, un-init reads, integer overflow.
Better tooling(ASAN, Coverity, ..) can only reduce the bug rate, but can not eliminate the bugs. 
The only way to eliminate a class of bugs is to make them un-representable in the type system.

### slide 3:
=> Rust eliminates every one of the listed bugs at compilation time ( static analysis ) and with Zero
runtime cost.

### Slide 4: before Rust:

-  *Safe but slow* (GC languages)
  - Java, Go, Python — garbage collector guarantees no UAF
  - *Cost*: GC pauses, unpredictable latency, large runtimes
  - Unsuitable for kernel code, real-time, interrupt handlers

-  *Fast but unsafe* (C, C++)
  - Maximum control, minimum overhead
  - *Cost*: all memory bugs are the programmer's problem
  - 30+ years of CVEs are the empirical evidence

- Rust closes the gap: 
    - offers safety without a *GC*, 
    - performance matching C 
    - zero-cost abstractions ( no additional cpu cycles )

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



