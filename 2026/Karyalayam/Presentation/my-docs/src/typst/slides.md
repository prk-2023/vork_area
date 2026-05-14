# Overview:

## Part 1: ( Introduction to Rust )

### Slide 0: (Introduction)

- Introduction to Rust and eBPF with Rust.
- Disclaimer
- Overview of presentation

### Slide 1: Introduction to Rust:

- Systems programming language 
    - What are the requirements of a systems programming language 
    - What are the issues with the current languages and how to fix them.  

### Slide 2: Bugs and issues:

- Current survey of known issues
- Maintenance and long term projection
- What other options are there to current model of development that can fix/minimize bugs/issues.

### Slide 3: Why Rust:

- Address the bugs and issues.
- Rust's approach and compare if it meets systems programming requirement. 

### Slide 4: Landscape before Rust:

- GC and fail to meet the needs. 
- How Rust provides a third programming model to fix this
- Change from developer centric to languge+compiler mandates

### Slide 5: Rust programming model and features 

- What is the 3rd programming model and its capabilities.
- Features of Rust and what they achieve. ( compare some with C examples )

### Slide 6: Ownership ( memory safety at compile time )

- What is Ownership and its importance. 
- What are the Ownership rules.
- Ownership rules and memory management model. 
- Who enforces these rules ( developer to compiler shift )

### Slide 7: Ownership features:

- UAF and Dangling pointers 
- Prevents leaks 

### Slide 8: Ownership and RAII 

- Resource acquisition is initialization.
- Hows its implemented.
- One of the key points for its acceptance into Linux Kernel.

### Slide 9: Borrowing

- trouble Ownership can introduce, and how borrowing helps.
- references.
- Borrowing and Its Rules.
- Features of Borrowing and what it helps fix/prevent.
- Compiler.

### Slide 10: Borrowing and Lifetimes:

- What is Lifetime.
- How compiler helps to ensure every reference points to valid memory. 
- Lifetime annotation (`'a`), ( developer help compiler with additional info on references )
- compare it with C ( How lifetime lead to no NULLPointer and UAF ).
- Example Device driver /Bor

### Slide 11: `Sync` and `Send` ( Thread safety )

- Thread safety is baked into Type system through **marker traits**: `Send` & `Sync`
- Send trait 
- Sync trait 
- How other languages allow passing of non-thread safe object leading to crash (that happen sometimes).
- `Send` & `Sync` prevent data-race

### Slide 12: Other important concepts:

- Traits
- Generics
- Trait-bounds
- Smart pointers
- iterators
- macros 
- attributes 

### Slide 13: Compiler 

- Compilers Job 
- Memory Safety 
- TypeSystem Guarantees ( correctness )
- Error handling ( risk isolation with `unsafe` boundaries )
- Shift System reliability from runtime debugging and external tooling to compile-time enforcement by the
  language itself. 

### Slide 14: Rust ecosystem: 

- Language 
- Compiler 
- Cargo
- tooling
- crates 
- docs 

### Slide 15: Linux Kernel 

- Rust is not going to replace C, The strong compile-time correctness helps to meaningfully reduce risks. 
- Chronological update of Rust in Linux kernel. 
- No more experimental 
- Adoption Map.

### Slide 16: Concepts useful for kernel/firmware work:

- FFI ( precise control over memory ) Which is key for BPS/Firmware/low-level work.
- Bitlevel layout control ( Key to access HW registers , MMIO ...)
- `bindgen` 
- Abstraction: C functions are not called directly by via wraps in safe Rust interfaces .
- safe and unsafe encapsulation 
- For kernel: kernel build flow 

## Part 2: 


### Slide 17: Introduction eBPF with Rust.

- With official support in kernel and possible to experiment Rust with eBPF.
- eBPF bytecode verifier. 
- Crates and current status. 

### Slide 18: ( `eBPF` CO-RE overview )

- Recap of eBPF ( libbpf/ CO-RE )
- Steps and flow 

### Slide 19: possible approaches to run eBPF with Rust 

- `Aya`: Full Rust based approach to run eBPF 
- `libbpf-rs`: leverage `libbpf-c` and Rust

### Slide 20: Aya:

- Framework and its components 
- Typical Aya project 
- How to build Kernel and Userspace loader program 

### Slide 21: Cross build ( CO-RE )

- How to cross build aya project 
- `musl` toolchain => highly portable ( true CO-RE )

### Slide 22: Example:

- DMA latency mapper: 
- Project layout 

### Slide 23: Common region 

- Helps memory Interface between kernel and user-space 

### Slide 24: Kernel eBPF program 

- eBPF program 
- `no_std` and `no_main` 
- `#panic` handler 
- Maps 

### Slide 25: Loader 

- User Space loader 
- find and load byte code 
- attach 
- create map 

### Slide 26: Loader, multiple hooks point, sync and telemetry.

- Async program model 
- multiple hook points and maps 
- extensions telemetry and logging.. ( todo )

### Slide 27: Demo  

- example crates 
- Demo and analysis 
- Comparison with `libbpf-c`


---------------------
Talking Points:
---------------------


# Talking points for "slides.md"

## Slide 0: Introduction to Rust:

Good Afternoon, the title for todays presentation is "Intro to Rust and eBPF programming with Rust".

Rust is relatively a new programming language that has called for attention in many areas of programming,
from Applications, stacks, Operating systems and bare-metal. 

Before start I would like to cover the Disclaimer for the present talk.
The presentation is not about language war but highlight trends in systems programming landscape. 
Also to note, some kernel developers look at Rust as an replacement for C, but its should be views as a
complementary tool for solving specific class of bugs generally related to spatial and temporal memory
safety issues, which are historically difficult to eliminate in a large C codebase. And see how Rust
provides memory safety without tax,  that means no additional CPU cycles to ch

The key point on how Rust provides memory safety with out Taxing and  
this has led to the language gives memory safety 
