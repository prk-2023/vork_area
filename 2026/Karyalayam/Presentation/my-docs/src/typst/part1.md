# Introduction to Rust and eBPF with Rust.

## Introduction:

### ( Slide #1 : Disclaimer )
Good Afternoon, the topic for the presentation is Rust and eBPF with rust,  We will start by looking at what
Rust is all about why its gaining popularity even as a systems programming language, I also want to high
light that discussion is not about language war but high light trends in systems programming landscape
and this is not about which language is better or a debate should Rust replace C. 
The aim  is to evaluate the tool and not religion. 
From an evolutionary rather than revolutionary perspective, Rust should be viewed as a complementary tool
for solving specific classes of bugs, particularly spatial and temporal memory safety issues which are
historically difficult to eliminate in a large C codebase. And see how Rust provided memory safety with out
tax, which is we don't have to trade performance for security.

Main objective is to analyze technical "why" and "how" behind Rust's integration into the Linux kernel and
along with its practical utility for modern systems engineer and this should matter the most for Your
organization. 

In short what do we have in store: Rust provides "Deterministic performance", it has no garbage collector
and still provides zero cost guarantees like C++ or other GC language. 

( Things not covered: install rust and what tools come with rust ecosystem, such as rustup, clippy, rust-analyzer and more )

### ( Slide #2 : Parts )

The talk is divided into 3 parts:

- Part 1: Introduction to Rust ( And a look as a systems programming language )
   Rust fills the gap in many domains of programming, in our discussion we will try to focus on the features
   that fits as a systems programming language: We will look in to what features of Rust are important from
   a systems programming perspective and how design/features of Rust prevent bugs. 
   Features like 
   - Ownership, 
   - Borrow checker and concurrency ( this is what missing in C ). ( With multi core cpus, data races are
     prevented at compile time)
   - => precise control over memory representation using features like #[repr(C)] which enable FFI for
     interoperability which is suitable for BSP,Firmware, and low-level. 
   - => Rust allows for exact bit-level layout control ( which is key for MMIO and HW registers ). Firmware
     and driver programs generally requires unsafe writing to memory address, Rust does not forbid this
     action, instead it encapsulates it so the rest of the system remains safe.
   - zero-cost abstraction 
   - Cargo: build tool and more, a very powerful build systems that works well with dependency management
     and more. Cargo is designed for maximise/ease productivity.


- Part 2: Rust in Linux Kernel: ( I will like to point that I have not play this domain since stable
  integration into kernel was starting from this year 2026 onwards and its quite new and growing )
    - Rust is not going to replace C in Linux kernel, rather a stronger compile-time correctness allows now
      for developers to meaningfully reduce risks. 
    - We will look at Chronological update from its initial proposal to current stable ( pinned ) types.
    - Experimental Phase is over and fundamental Rust abstractions like `Arc`, `Mutex`, `Box` are now part
      of the upstream kernel.
    - Build flow: How rust its integrated into the existing kernel build system.
    - Role of `bindgen` ( a tool that helps generate Rust FFI from C headers ) this automates the dangerous
      part of the interfacing with thousands of C headers. 
    - Abstraction layer: Why `C` functions are not called directly but wrap them in safe Rust interfaces:
      which is for "safety", but to provide idiomatic interface that prevent the user of the driver from
      even being able to cause a Null point dereference or a use-after-free.. event.
      Goal isn't just calling `C` but creating **safe wrappers**.
      If a engineer writes a driver in Rust, the compiler should prevent them from forgetting to release
      spinlock.
    - Hello world rust kernel module. 
    - Adoption map:
        Which parts of the Linux Kernel are Early adopters and which are still in wait and watch zone, and
        also cover Industry push ( from google, Ms, amazon )

- Part 3: `eBPF` programming with Rust. 
    - With Rust getting official support as kernel's second supported language, this should make is possible to experiment with `eBPF`.
    - there are couple of frameworks how we can run `eBPF` code using Rust, and we will explore how this can
      be achieved and what are the pro's and con's with this approach. 
      - crate `libbpf-rs` wrapper framework that uses the default libbpf-c framework. 
      - Aya framwork : A pure rust approach ( loader and kernel ebpf programs in pure rust ), Aya rust
        framework comes with set of multiple crates that are useful for running eBPF programs. 
    - Since Aya is a pure Rust approach and it shares the same memory safety guarantees in the loader
      (userspace) as it does in the eBPF program (kernel-space), creating a unified, safe pipeline.
    - Rust's type system often like what the eBPF verifier wants, this makes development loop faster.
    - Real-time performance monitoring and network packet manipulation with rust makes complex eBPF logic
      much less "stiff" then restricted `C`. 

    - example: Tracking DMA latency with microsecond precision using BPF maps.

In short Rust reduces "technical debt" over maintaining a large code-base and different Linux kernel
versions.


## Part 1:  

### ( Slide #3 : Why Rust ( systems programming perspective ) ) 

`C` World:  ( systems programming language, issues )

- `C` langauge is the de-facto industry standard for systems programming across Operating systems, kernels,
  embedded systems, and runtime infrastructure. 

- The language evolved along with the advancements of HW and meets the features for systems programming
  language. 
  - Minimal abstraction: Near 1-to-1 correspondence between code and machine instructions the CPU executes.
    `C` does not hide mem-management or complex data structures behind black-boxes. 
  - No runtime overheads : there is no GC running in the background, for pauses and memory cleanup.
  - Deterministic behaviour: can predict how a piece of code will perform, critical for real-time. 
  - Direct memory manipulation: Write to specific memory address to turn on a network card. `C`s pointers
    allow direct access to memory. Bit wise operations to flip individual bits key for device drivers and
    controlling HW registers.
  - Portability and the "C Standard Library": C is often called "portable assembly." While assembly language
    is tied to a specific processor (like x86 or ARM), C code can be compiled for almost any architecture
    with minimal changes.
  - Tiny footprint: compiled binaries are small making it ideal for embedded systems.
  - Deterministic Resource management: Systems generally come with limited memory and C offer total control
    over Heap and Stack of the program. 

- However systems written in `C` are prone to classes of error which are easy to introduce and difficult 
  to detect, even under careful code-review and testing. These issues are due to lack of safety net, and
  developer is sole responsible for every byte of memory.
  - Memory issues: buffer overflow, user-after-free, dangling pointers, manual memory management (requires
    run free()( deallocation ) in right order and right way. 
  - Language standard doesn't define what should happen if you do something wrong. The program might work
    today and fail tomorrow on a different computer.
  - Data Races: C doesn't stop 2 parts of a program from changing the same piece of data at the exact same
    time, leading to "race conditions" that are notoriously hard to debug.

- `C` model offers great control and power but the model is largely developer-dependent, leading to
  complexity and maintenance cost. 

- For projects like Linux Kernel, which have evolved over 30+ years, there is a concern about the
  sustainability of onboard new contributors who are expected to work within the constrains and risks of
  manual memory management in `C`.

Rust: 

- First : Rust hits all the essential markers of a systems programming language: 
    - NO GC: Unlike Java/Python other similar languages, Rust has no runtime overhead ( no stop-the-world
      pauses). 
    - Rust manages memory via RAII ( Resource acquisition is Initialization ) resource lifecycle is locked
      with lifetime of the object. Rust handles this by Drop trait, the compiler add the drop trait
      automatically for all the variables that go out of scope. 
      * In the Kernel: If a driver programmer writes a function that acquires a **SpinLock**, they don't
        have to manually call `unlock`. When the `Guard` object created by the lock goes out of scope, the
        hardware is automatically unlocked.
      * **The Risk in C:** If you have 5 different resources to clean up, your `goto` logic must be
        perfectly ordered. One mistake leads to a "Use-After-Free" or a leak.
      * **The Rust Fix:** Rust’s RAII handles this automatically and in the correct reverse order of
        acquisition.
      If the function returns early due to an error, the compiler ensures every resource acquired up to
      that point is cleaned up, and nothing more.
   - precise control over memory representation using features like #[repr(C)] which enable FFI for
     interoperability which is suitable for BSP,Firmware, and low-level. 
     By default Rust compiler ( llvm ) might re-order fields in a `struct` to optimize memory and usage and
     reduce padding, this may be efficient for SW but is dangerous for HW, where change in bits by
     reordering can be bad. Rust uses #[repr(C)] which tells the compiler to layout the structure exactly
     like `C`, which ensures the memory map to match the HW expectation. 
   - Rust allows for exact bit-level layout control ( which is key for MMIO and HW registers ). 
     `C` uses `volatile` keyword to tell compiler dont optimize this access away, even if it looks I'm
     writing the same value twice. 
     Rust uses `core::ptr::read_volatile` and `core::ptr::write_volatile`, It allows to define a pointer
     directly to a specific Hex Address ( 0x00FFAABBCC for a GPIO controller ) and manipulate it directly. 
   - Memory safety without overhead: Rust prevents "segmentation faults", "dangling-pointers",
     "use-after-free", "race-conditions" through its "ownership" and "Borrowing" features, which track who
     owns a piece of data and for how long. Rust type system ensures that data cannot be modified by two
     threads at once, catching race-conditions before the code even runs. 
   - Bare Metal capability: Rust can run "no_std" ( without standard library ) making it suitable for
     micro-controllers, OS kernels, Firmware where there is no OS to rely on. 
   - Zero-Cost Abstraction: Rust does all the above without the need of additional CPU cycles.
  
### ( Slide #4 : Memory safety )   

- Memory safety has not meaningfully improved: The Number of issues over the past 20 years have not changed:
    - 70% of Microsoft CVE's are memory safety issues. 
    - ~67% of Linux CVE Common vulnerability exposures. Are traced to memory safety violations.
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

### ( Slide #5 : Before Rust )

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

### ( Slide #6 Ownership Memory safety at compile time )

Programming languages were grouped into two groups:

Manual memory management: C/C++ ( total control, risky of memory leaks and crashes depended on programmer )

Management via GC: Python/Java, safety and easy to use, cost of pauses and run had a high memory overhead,
and not practical for systems programming. 

Rust Owenrship 3rd way: provides the safety of a GC without the performance penalty of one. 
It achieves this by shifting the work to the compile-time. 
The compiler tracks the "lifetime" of every variable and inserts the "free" or "cleanup" commands precisely
where they are needed before the program even runs. ( via drop trait )

This is one of the major contribution to programming community, as it solves:
- Data races at compilation compile-time.
- Catches vulnerabilities earlier in the development cycle.
- A big percent of bugs ( about 70%) are memory related and can be prevented at compilation time. 

Ownership is a memory management model where each value has a single owner at any given time.

The compiler enforces rules around Ownership, moves and scope, shifting memory safety from runtime
enforcement to compile-time verification. 

Core rules:
1. Each value has a single owner.
2. There can only be one owner at a time ( ownership can be transferred, i.e moved )
3. When Owner goes out of scope, the value gets dropped ( memory is freed ).

=> The key idea here : The rules are enforced by the compiler, making invalid memory states 
   un-representable at runtime.

#### ( Slide #7 : use-after-free and dangling pointers )

In C memory ownership is implicit and manual:
    - memory can be freed while pointer still reference it. 
    - Compiler does not track lifetime relationships.
    - This leads to use-after-free (UAF) and dangling pointer bugs. 

Rust Prevents this class of bugs by construction:
    - Once ownership is moved the old reference is invalidated.
    - The compiler tracks lifetimes and enforces validity.
    - use-after-free becomes a compile-time-error, not a runtime bug.

(ToDo: refer to the code on the slide or update the code examples )

#### ( Slide #8 : prevent leaks )

In C, every error exit path in a driver must explicitly handle cleanup.
This makes resource management error-prone and path-dependent, especially as control flow grows.

While Rust makes this structurally reliable.

( refer to [RAII document for more details](./raii.md) )


### ( Slide #9 : Borrowing and Lifetimes )

If Ownership was the only mechanism then code would become impractical and very quickly, as the program
would require to transfer ownership just to read or temporarily use data. 

or 

Since we can't move ownership every single time we want to read a variable, we "borrow" it. 
This introduces the syntax (& and &mut) and the rules (the 1 writer vs. many readers).

Moving ownership every time we read a variable is inefficient.
Borrowing lets us access data temporarily without "taking" it.

The Mechanism of borrowing: We use References.
    - Physically they are just pointers (memory addresses), exactly like in C.
    - Logically they are "Permission Slips" tracked by the compiler.

=> Borrowing is the mechanism of accessing data without taking ownership. 
   Implemented via **References**, which are distinct types in the Rust Compilers view. 

The Rules:
    - Shared Access (&T): Many readers can look at the data at once.
    - Exclusive Access (&mut T): Only 1 writer can touch the data, and no one else can even look at it 
      while they do.
    - Golden Rule: You can have Many Readers XOR One Writer. Never both simultaneously.

- Borrowing prevents: 
    Memory bugs: No more Dangling Pointers or Use-After-Free. If the owner dies, the "permission slip"
                 (reference) becomes invalid immediately.
    Concurrency Bugs: By banning the combination of Aliasing + Mutation, Rust eliminates Data Races
                  at compile-time. You don't need a Mutex to prove a single-threaded borrow is safe.

- In `C` ptr is just an address, In Rust "reference" is an **Address + a Lifetime + a Permission Level**.

=> Rust compiler can do much more then C compiler with the same raw information. 


- Borrowing is the mechanism of accessing data without taking ownership. 
   Implemented via **References**, which are distinct types in the Rust Compilers view. 
  1. So a `String`, `&String` and `&mut String` are 3 different types with different capabilities. 
  2. Physical vs Logical: Physically references are just pointers ( mem addresses) like in C. Logically they
     are "permission slips" that the compiler tracks to ensure memory safety. 
  3. => Rust allows Shared Read-Access ( many &T ) or Exclusive Write-Access ( &mut T ) But never both
     simultaneously, This eliminates data race at compilation time. ( As in the slides example  shows)
     i.e 
     Data race = Aliasing + Mutation + No synchronization 
     Rust solves this by banning the combination. 

( TODO: Update the slide talk about what borrowing is )


### ( Slide #10 : Borrowing Lifetimes )

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

(TODO: update the slide for lifetimes add mermaid / code blocks if possible )

### ( Slide #11 : sync and send: thread safety in type system) 

(TODO: talking points sync with slide or update if required )


### ( Slide #12 : Compiler ) 




