# Talking Points:


# Talking points for "slides.md"

## Slide 0: Introduction to Rust:

Good Afternoon, 
Todays topic Introduction to Rust and eBPF programming with Rust.

To set the stage: Rust a relatively a new programming language compared C, C++, Python, or Java. 

Yet, it has become one of the most talked-about languages in the industry. 

For over a decade now, it has consistently topped Stack Overflow’s surveys as the "most admired", and 
"most loved" language, with around 80% of developers who try it choosing to stick with it.

Alongside the language itself, its package manager and build tool, Cargo, has completely dominated the 
developer preference charts frequently ranking as a highly desired tool for cloud infrastructure and 
development. 

Take for example yocto a highly capable and powerful complex build system, can quickly consume time,
for managing dependencies, handling different build tools, mixing languages, handling toolchains and 
tussle with recipes.
One of the quality-of-life improvement Rust introduces is Cargo.
With Cargo, dependency management, compilation, and tracking are unified into a single tool. 
More importantly for our hardware-centric workflow, Cargo is highly extensible.

Features like build.rs (custom build scripts) and the xtask pattern give a powerful, native ways to 
handle complex code generation, hardware stepping logic, or custom image packaging without relying 
on fragile external scripting layers.

In this presentation we will not be going in depth of cargo, but rather cover the basics as a starting point.
Rather Today’s talk is about bridging that gap and explore Rust’s core features—particularly around 
memory safety—and how it explicitly addresses vulnerabilities that plague low-level software.

Slide 1: Disclaimer: 

The focus is not about language war, rather cover some evolving changes in systems programming domain.
As this is where it overlaps with the core of what we do here, writing firmware, BSP and driver logic .. 

And its also important to state that Rust is here not as a replacement to C, but 
should be viewed as a new tool in systems programming toolbox.
Our goal for today is to look under the hood and evaluate whether its time for us to seriously consider Rust. Can it benifit our developement, or does it provde any value addtion to products build on Realteks HW. Does it help in writing safer memory code, and  can this improve long-term code maintainability. 

Most Important part of the disclaimer: I am not a Rust expert, I am exploring this technology alongside your or like many others. And I would do my best to answer questions from engineering perspective going through this together.

Slide 2: Parts 

Todays talk can be grouped into two parts:
In Part #1: 
- we will mainly look at if Rust fits to be systems programming languge for kernel, driver or other utility related works.
- We will cover how Rust presents New programming model, with its features like "Ownership", "Borrowing", "Lifetimes" along with its compiler guarenties to memory safety with zero-cost abstration. 
- We will cover some other important features like memory layout, fearless concurrency, and its FFI to co-work with other languages. 

In Part #2: 
- we will put in use of the Rust feauters to write eBPF programs in Native Rust, as an alternative to the existing libbpf to achive CO-RE. This is a good starting point for playing with Rust as eBPF environment is restricted and deals with how to interact with different memory layouts
- Also How Rust can make unsafe code more reliable and predictable. 
- Followed by a Demo.

What we will not cover is Rust in Linux Kernel, we will not be building kernel modules and handling any Rust kernel related work, as this is heavy and deserves a seperate session. 

But the topics we will discuss will be fundamental for working with Rust and linux kernel. To get an idea of how strange and monumental we have to look back to 1994's,
back then there was an experimental branch of the Linux kernel created to support C++ along side C. Tha experiment was quickly abandonded and for long no second language would get into linux kernel, the main reason is languages do not meet all
the systems programming requirements. ( take Go, it comes with GC => Unpredictable responses )
Or C++ which also fails: 
The early c++ compilers were not reliable, they frequenly emitted bloated or unpredictable machine code. Its Constructors triggered implicit memory allocation and complex underlying operations. In kernel space memory management should be explicit, deterministic and entirely controlled by the developer. And C++ lacks runtime core kernel init happens before OS, meaning runtime support and libraries required in C++ is not present. 

And Linus and team maintainers, prefered raw,predictable control of C, as it gives
absolute transparency into how memory and pointer are manipulated right next to hw registers. 

The reason for Rust to break the mold, is from inception Rust natively supports, lower-level core environment called `no_std`. this strips out all the std library support, the memory allocator, and any other OS dependent runtime. This leaves with highly predictable, zero-overhead binary that compiles directly down to bare-metal. 

We will look at this `no_std` environment in the second half of our discussion when we talk about eBPF programming. ( the eBPF VM enforeces incredible rigid constrains, requiring a strict execution environment where traditional OS wrappers cannot exit)

In the First part we will try cover Rust as systems programming language and its unique approach allows to match raw performance, lack of runtime, and predictability of C while fundamentally eliminating the memory safety bugs that have histrically plagued systems-level engineering.

We will cover mainly what's new model Rust presents for memory safety. 


Good Afternoon, 

Today we’ll be looking at the Rust programming language from the point of systems programming and how its
becoming a new tool for systems programming toolbox.Specifically we'll explore why its has gained popularity for delivering memory safety 
without sacrificing performance. 

Rust is a general-purpose language, but it fits perfectly into the systems programming domain occupying the
exact same space as C, it give direct control over memory layout, compiles straight to machine code and has
no runtime GC. 

The core difference with Rust is its fundamentally different approach to memory management. Through its
concept of Ownership and lifetime tracking, the compiler guarantees that the generated code is completely
free from memory related bugs like use-after-free, dangling references, race conditions before the code can
even run. 

These are the reasons why Rust managed to secure a spot inside Linux kernel along side C. 

If I am not back in 90's there was an attempt to introduce C++ into Linux kernel, and it was famously
rejected and abandoned. The community turned it down because C++ introduces unpredictable control flow via
exceptions, hidden overhead, and had complex and unstable ABI compared with C simple and beautiful ABI. 

Note: 
( How ever Rust also does not have a stable ABI, it relies on C ABI to talk to outside world. Unlike C++ rust
does not use exceptions of error handling, it has zero cost abstrations and it give the developer full
control over allocations. Along with this and many other reasons the kernel community has welcomed Rust
alongside C to address security and memory related bugs. )

However, because the modern Linux kernel ecosystem is evolving toward a safer and more maintainable 
development model, the kernel community which has historically used C, has officially allowed Rust alongside
C to address a wide range of persistent security and memory issues.

The first experimental Rust support patches made their way into the kernel around 2020.
But just recently, at the December 2025 Kernel Maintainer Summit, Rust's status achieved a major milestone:
its experimental tag was officially dropped, and it was marked as stable and ready for production use.

In today's talk, we are not going to look at Rust in kernel development itself, which is a massive and heavy
topic on its own.

Instead, we will look at it strictly from the perspective of a systems programming language. 

We will examine what is the actual performance overhead is when compared to C, 
How it achieves this memory and thread safety at compile time, and, crucially, how it can co-work and 
interoperate with your existing C codebases via its FFI.

And eBPF is the perfect starting point as it provides an excellent, low-overhead environment, helps 
- to understand user-space and kernel-space interaction, 
- shared memory concepts, 
- safe systems programming, and 
- high-performance tracing and networking. 

Furthermore, Rust’s ecosystem comes with many tools and modern frameworks that make it highly viable to 
build eBPF-based observability and telemetry internally and for customers.  


## slide 1: Disclaimer:

This talk is not about replacing C, nor its meant to start a language debate. 

C remains extremely important and will continue to power much of systems infrastructure. 

Instead we should view Rust as an additional tool in the sys-programming toolbox. 

If you follow the Kernel mailing list, the Introduction of Rust has lead to some incredibly heated
discussion, cause change in codebase implies debates.

Rust is particularly useful for eliminating classes of memory safety bugs that are difficult to manage in a
very large codebase. 

As codebase grows millions of lines of code, with hundreds of engineers, managing memory safety becomes a
problem rather then skill. And Rust handling of memory safety from runtime to compile time. 

( Simplifying code reviews related to memory bugs and allows developers to focus on actual HW. ) 


--- 

## slide 2: Overview:

The talk is divided into two parts.

In the first section, we’ll look at Rust as a systems programming language and understand some of the core
ideas that make it attractive for systems development :
- including zero-cost abstractions, 
- ownership and borrowing, 
- memory layout control, and 
- concurrency safety. 

In the second section, we’ll move into eBPF programming with Rust. 

We’ll explore Aya, a modern, pure-Rust eBPF framework. Which is an alternative for eBPF development 
alongside traditional toolchains like libbpf.
Finally we will go through demo aya project to show how a user-space Rust application can seamlessly 
interact with kernel-space eBPF programs, passing data cleanly back and forth with minimal latency.

--- 

## slide 3: Introduction to Rust: 

We are going to break down Rust as system programming language and understand its core propositions:
related to memory safety, compiler guarantees , concepts and performance .


---

## slide 4: 
    > Direct Hardware Access and Low-Level Control:
    > Zero-Cost Abstractions:
    > Manual or Deterministic Memory Management
    > Minimal Runtime Environment
    > Stability and Predictability

|[*Feature*],|[*C*],|[*C++*],|[*Rust*]|
| :--- | :--- | :--- | :--- |
|[Memory Safety],|[No],|[Manual (RAII)],|[Yes (Compile-time)]|
|[Garbage Collection],|[None],|[None],|[None],|
|[Complexity]|[Low],|[Very High]|,[High],|
|[Abstraction Power]|,[Low],|[High],|[High],|

Taking points:

For a language to be qualified as a systems programming language, it has to support:

1. Direct HW access and low level byte control. 

2. Requires Zero-Cost abstractions: that is we don't pay performance penalty for writing clean code. 

3. Deterministic memory management: We must know exactly when data is allocated and freed. 

4. Demand minimal runtime environment and absolute stability and predictability in execution. 

When we look at the qualities with major systems programming language stack up agains these requirements the
trade-off becomes very clear.

If we look at GC: None of these languages use GC. Which gives predictable execution with out random pauses. 

Memory safety: C give zero safety nets and depends on programmer. C++ give RAII (resource acquisition is
Initalization ( constructor/destructor )) which help but memory management is still manual and that is prone
for errors. 
Rust shifts the scope completely: Delivers Strict memory safety guaranteed at compile time. 

Complexity Vs Abstraction: 
  C is simple with low language complexity, but its abstraction power is lower ( building larger code base
  required a lot of manual boilerplate.)
  C++ has better abstraction power but increases complexity. 
  Rust also offers similar abstraction power as C++, allowing to write expressive code, but it has steep
  learning curve ( because of strict compiler checks )

Note:
- Direct Hardware Access and Low-Level Control:
   Rust code compile directly to machine code with out GC, and offers specialized language features to
   interact directly with HW addresses and CPU. 
   - no_std: Strips away OS level dependencies and allow to write bare-metal code.
   - `unsafe`: for actual talking with HW, requires bypass guard rails via unsafe to read/write to specific
     mem address. 
   - Inline assembly: for low level control or CPU specific instructions: support via `asm!` macro. 
   - #[repr(C)] :   Force compiler to layout data in memory that matches as C compiler would do. 


---

Slide: 5 and 6 : The eternal memory  bugs:

  *The numbers haven't moved in 20 years*
  - *~70 %* of Microsoft CVEs are memory safety bugs
    #ref-badge[Microsoft Security Response Centre, 2019] // Using our custom ref-badge
  - *~67 %* of Linux kernel CVEs are memory safety violations
    #ref-badge[Gaynor & Thomas, 2019]

|[*Cause*], |[*C has no protection against...*]|
| :--- | :--- |
|[Use-after-free], |[accessing freed memory via a dangling pointer]|
|[Buffer overflow], |[writing past the end of an allocation]|
|[Data race], |[two threads accessing shared memory without synchronisation]|


- The only way to eliminate a class of bugs is to make them unrepresentable in the type system.

- Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
- type-system +  compiler.


Talking points: 

- To understand why companies like Microsoft, Google, and the Linux Foundation are investing so heavily in 
  Rust, we look at the hard data. The reality is that the numbers haven't moved in twenty years.


- If we look at historical data from the Microsoft Security Response Center, roughly 70% of all security 
  vulnerabilities tracked as CVEs are rooted in memory safety bugs. 
  When independent security researchers analyzed the Linux kernel, they found an almost identical reality: 
  about 67% of kernel vulnerabilities are memory safety violations.

- This is despite the fact that we have incredible C static analyzers, aggressive fuzzing pipelines, and 
  rigorous code review processes.

- Why does this keep happening? It’s because C, by design, gives us raw speed and zero safety nets. 
  It has no native protection against the core issues we see in this table:

  - Use-after-free: 
    Accessing freed memory via a dangling pointer because tracking object lifecycles across complex 
    asynchronous code is incredibly difficult.

  - Buffer overflows: Writing past the end of an allocated array or buffer because C treats pointers and 
    arrays almost interchangeably without native bounds checks.

  - Data races: Multiple threads or hardware interrupts concurrently accessing and modifying shared memory 
    without proper synchronization.


- In a traditional systems environment, we try to catch these with runtime checks, sanitisers, or
  with discipline programming practices. But this gets into question when scaled to millions of lines of
  code. 

#pause 

- The Core Rust philosophy: The only way to completely eliminate a class of bugs is to make them completely
  unrepresentable in the language's type system.

- Rust eliminates every single row in this table at compile time. 
  By combining a strict type system with an aggressive compiler, 
  it ensures that if you attempt to write a use-after-free, a buffer overflow, or a data race, the code 
  simply will not compile. 

=> You get this guarantee upfront, with absolutely zero runtime overhead. <=

--- 

## slide 7: Landscape before Rust: ( 3rd programming model )

  - Current systems are powerful but they also come with limitations 
    - absolute performance (C/C++) (manual memory mgmt)
    - absolute safety (Java/python/go) (automatic mem mgmt) 
  - Developer centric
  - Rust meets all the systems programming requirements.
    - 3rd Programming model. ( mem mgmt via Ownership & borrowing )

  *Before Rust:*

  - GC and fail to meet the needs. 
  - How Rust provides a third programming model to fix this
  - Change from developer centric to languge+compiler mandates

Talking Points:

The landscape before Rust generally consisted of two choices when it comes to memory management and safety:

Languages like java/go/pthon offered automatic memory safety via GC, but they have large runtime,
unpredictable pauses, bloated memory footprints or lack of direct HW control. 

Other side we have C/C++ offer strict programming requirements but their safety model is entirely developer
centric. 

Rust introduces a 3rd programming model that fundamentally different, it achieves memory safety via
Ownership and borrowing, these rules of memory safety are hardcoded into language type-system, The Compiler
acts as a automated mathematical co-pilot, verify memory bounds, resource lifetimes at build time which
ensures safety is inherent property of compiled binary, and not with developer to maintain. 

--- 

## slide 8: Important Language features: 

We will examine the specific language features Rust uses to enforce these compile-time safety guarantees. 
Next few slides, we are going to break down four important language features:

- Ownership: 
    The core rules governing which piece of code is responsible for initializing, managing, and deallocating
    a given resource or block of memory.

- Borrowing: 
    How Rust allows multiple parts of your code to access that memory safely without copying it, 
    utilizing either immutable or mutable references.

- Lifetimes: 
    The compile-time tracking mechanism that ensures a reference or pointer can never outlive the data it 
    points to, completely preventing dangling pointers.

- Thread Safety: 
    How these exact same memory rules naturally extend to multi-threaded environments, preventing 
    concurrency data races at the compiler level.


--- 
## slide 9: Ownership: (Memory safety at compile time )

*The three ownership rules*

#cols[
  - *Rule 1 : Each value has exactly one owner* 
  - *Rule 2 : There can only be one owner at a time (ownership can be moved).*

  ```rust
  let s1 = String::from("hello"); // s1 owns the heap data
  let s2 = s1;          // ownership MOVES to s2
  // println!("{}", s1); // ← compile error: s1 was moved
  ```
  The compiler tracks ownership *statically*. No runtime book keeping.

  - *Rule 3 : When the owner goes out of scope, the value is dropped*

  ```rust
  {
      let buf = alloc_dma_buf(); // allocation
  }   // ← Drop::drop() called HERE, automatically
      // No free() to forget. No leak possible.
  ```

#callout:
*Rust's ownership system* it's a type theoretic answer to manual memory management. 
  - It's a memory management model where each value has a single owner at a time, and the Compiler enforces rules about ownership/borrowing/lifetimes. 
  - Shifts memory safety from a runtime concern (like GC) to a compile time verification handled by the type system. 

#callout
-> Shifts memory safety from a runtime concern (like garbage collection) to a compile-time verification problem handled by the type system.

Talking Points: 

The first and most foundational concept in Rust: Ownership.

Ownership is Rust’s type-theoretic answer to manual memory management. 
It completely eliminates the need for a runtime GC by shifting memory safety to a compile-time verification 
problem. 

The entire model is governed by three deceptively simple rules enforced strictly by the compiler.

- Rule 1 and Rule 2 state that every value has exactly one owner, and there can only be one owner at a time.

  To see why this matters, look at the first code snippet. When we initialize a string or a buffer `s1`, 
  it owns that resource. 
  If we then assign `s2 = s1`, we aren't creating a shallow copy or a traditional pointer alias like we 
  would in C. Instead, ownership of the resource is moved to `s2`.

Because `s2` is now the sole owner, the compiler statically invalidates `s1`.
If you try to access `s1` on the very next line, the compiler will throw an error and refuse to build your 
binary. 

In C, aliasing pointers across different modules is the number one cause of *double-frees* and 
*use-after-free* bugs. 

Rust eliminates this entire class of bugs because the compiler tracks these moves statically, 
And this done  @ absolutely zero runtime bookkeeping or performance penalty.

Rule 3 states that when the owner goes out of scope, the value is dropped automatically.

The second example, which is highly relevant to our domain. 
Imagine we allocate a DMA buffer inside a block of code. 
In C, if an execution path hits an early return or an error handling branch, it is incredibly easy to 
forget to call free() or release that buffer, leading to a silent memory leak that can eventually crash.

In Rust, the moment the owner variable `buf` goes out of scope, the compiler automatically injects a call 
to the destructor, known as Drop::drop().

There is no manual free() to forget. 
No memory leak is possible, and memory cleanup becomes completely deterministic down to the instruction 
block. 
It gives you the absolute safety of a high-level language but retains the exact, predictable resource 
destruction required for low-level systems programming.

---

## slide 10: Ownership vs C: use-after-free


Most common kernel CVE class : caught at compile time in Rust.

[
  - This is not a bug detection problem.
  - This is program expressiveness problem. 
]

    ```c
    struct dma_buf *buf = dma_alloc(dev, size);
    submit_dma(dev, buf);

    kfree(buf);           /* freed */

    /* … 500 lines later … */
    read_completion(buf); /* UAF — undefined behaviour */
    /* gcc/clang: no warning, no error */
    ```

  
    ```rust
    let buf = DmaBuf::alloc(dev, size)?;
    submit_dma(dev, &buf);

    drop(buf);            // buf is freed here

    // read_completion(&buf);
    // ^^^ error[E0382]: use of moved value: `buf`
    //     value used here after move
    //     |  drop(buf);
    //     |       --- value moved here
    ```

[
  - The error message names the *exact line* where the value was moved and the *exact line* of the illegal use, before the code ever runs. 
  - no `valgrind`, no `KASAN`, no `OEM` execution.
]


Talking points:

Use-after-free is one of the most common class of vulnerabilities: 

This is not a Bug detection problem. This is a program expressiveness problem.
In C, the language simply lacks the vocabulary to express resource lifecycles to the compiler.

C code on the left. We allocate a DMA buffer, pass it off to the hardware, and later free it using kfree()
This code is totally valid to the compiler. 

If this function is 500 lines long, or if that pointer is passed across multiple asynchronous callbacks, 
it is entirely possible for an engineer to accidentally invoke `read_completion(buf)` hundreds of lines 
later.
Both `gcc` or `clang` : no warning and no errors. Compiler is blind that the pointer is dangling. 

Now with Rust: 
- We allocate our `DmaBuf`. When we call `drop(buf)`, we are explicitly passing ownership of the buffer to 
  the drop function, which cleans it up. 
  Because ownership was moved into drop, the original variable `buf` is instantly dead in the eyes of the 
  compiler.

- If you attempt to use `buf` on the next line for a read completion, the Rust compiler steps in and 
  completely halts the build.

- And the compilation error give detailed diagnostic naming the exact like where the value was moved. 

- We dont have to run tools like valgrind or kernel address sanitizers tool `KASAN`

---

## slide 11: Ownership prevents leaks — RAII in kernel drivers

In C, every error exit path in a driver must remember to call the right cleanup. 
Rust makes this structurally impossible to get wrong.

    ```c
    int my_driver_probe(struct pci_dev *pdev) {
        void *res_a = alloc_a();
        if (!res_a) return -ENOMEM;

        void *res_b = alloc_b();
        if (!res_b) {
            free_a(res_a);   /* easy to forget */
            return -ENOMEM;
        }

        void *res_c = alloc_c();
        if (!res_c) {
            free_b(res_b);   /* must remember order */
            free_a(res_a);   /* and every prior alloc */
            return -ENOMEM;
        }
        /* … */
    }
    ```


    ```rust
    fn my_driver_probe(pdev: &PciDev) -> Result {
        let res_a = ResourceA::alloc()?;
        // If this fails, res_a.drop() is called —
        // even on the ? early return

        let res_b = ResourceB::alloc()?;
        // res_b drops if res_c fails below

        let res_c = ResourceC::alloc()?;

        // All three are freed in reverse order
        // automatically when the function returns
        // — success or failure
        Ok(MyDriver { res_a, res_b, res_c })
    }
    ```

  - Cleanup is automatic and deterministic via scope exit, each resource implements `Drop`, ensuring release on all return paths.
  - No explicit error-path cleanup logic required.
  - Rust turns "developer-managed control flow problem" $->$ "compiler-enforced lifetime and scope rule"


Talking points:

Generally found in driver probe functions: 
Where we have to assume that everything can fail 
    - allocations can return `null`, 
    - hardware can timeout, and 
    - clocks might not initialize. 

Because C has no native resource management tracking, every single error exit path in a driver must manually
remember to call the exact right cleanup functions, in the exact right order.

As you can see, if `alloc_b` fails, we have to remember to clean up `res_a`. 
If `alloc_c` fails, we have to explicitly clean up `res_b` and `res_a`. 

We see kernel code using `goto` blocks in production kernel code to manage this. Single miss leads to memory
leak and could lead to hardware lockup.

With Rust: Every thing changes with RAII.

- We attempt to allocate our resources using the `?` operator. 
- In Rust, `?` means: If this operation succeeds, `unwrap` the value and keep going; if it fails, execute 
  an early return with the `error`.

- Here is where the `Drop` trait happens. The compiler tracks exactly which variables have been initialized 
  at every single line of code. If `ResourceC::alloc()` fails, the function returns immediately via the `?`
  operator. The compiler knows that `res_a` and `res_b` were successfully initialized, so it automatically 
  triggers their destructors in reverse order right there on the spot.

- If the function succeeds, all three resources are packed cleanly into the `MyDriver` struct, transferring
  ownership forward.

=> zero explicit error-path cleanup logic required.
=> No `goto` blocks, no manual pairing of `alloc` and `free` across different exit points.

---

## slide 12: Borrowing and Lifetimes: 

- Borrowing allows multiple parts of your code to access data without taking ownership. 
- Lifetimes are compiler rules that track these borrows, ensuring references never outlive the actual data.

Together, they guarantee memory safety and data race freedom without needing a garbage collector.

---  

### slide 13: Borrowing : the aliasing rules formalised

*Borrowing* is Rust's system for temporary access without transferring ownership.  
This is implemented via References, which are distinct in Rust compiler view. 
//  It formalises the aliasing rules that C developers know informally but often violate.

*Shared (immutable) borrows : `&T`*
  - Multiple readers can coexist
  - None can write while readers exist
  - Maps to: read-lock held, RCU read section

  ```rust
  fn print_all(items: &[DmaEntry]) { /* read-only */ }

  let ring = RingBuffer::new(256);
  print_all(&ring.entries);  // borrow
  print_all(&ring.entries);  // another borrow — fine
  // ring is still valid and owned here
  ```

*Data Race* = aliasing + mutation + no synchronisation

*Exclusive (mutable) borrow : `&mut T`*

  - *One* writer, *no* concurrent readers
  - Maps to: write-lock held, spinlock held

  ```rust
  fn add_entry(ring: &mut RingBuffer, e: DmaEntry) {
      ring.entries.push(e); // exclusive access
  }

  let mut ring = RingBuffer::new(256);
  add_entry(&mut ring, entry);
  // `ring` is fully accessible again after add_entry returns
  ```

The compiler *proves* that at any point in the program, either *one writer* or *N readers* holds access to any memory location, but never both. This is the data race freedom guarantee.

Talking Points: 

- With Ownership model, we have to constantly move variables around, in which case writing real-world 
  systems code would be incredibly restrictive. To solve this, Rust introduces Borrowing.

- Borrowing is Rust’s system for granting temporary access to memory without transferring ownership. 

- It is implemented via **references**. 

- What makes Rust unique here is that it formalizes the exact aliasing rules that C developers know 
  informally but often violate under complex runtime conditions.

- Data Race mathematically is defined by three conditions: you have aliasing (multiple pointers pointing to 
  the same memory), you have mutation (at least one pointer is writing), and you have no synchronization.

- To eliminate data races entirely at compile time, Rust splits **references** into two mutually exclusive
  types.

- First, we have Shared Borrows, represented as `&T`
- Multiple readers can coexist simultaneously, but absolutely no one can write to that memory while these 
  readers exist.
- In the code block. We pass a shared reference to our DMA ring buffer entries to a print function. 
  We can do this as many times as we want. It acts exactly like a read-lock or an `RCU` read-side critical 
  section in the Linux kernel the data is guaranteed to remain stable and immutable while we look at it.

- Second, we have Exclusive Borrows, represented as `&mut T`.

- This grants a single writer absolute access to the memory, but with a catch: 
    - there can be zero concurrent readers and zero other writers while that borrow is active. 

- The second code block. 
    When we call `add_entry`, we pass an exclusive reference `&mut` ring. 
    For the exact duration of that function call, the compiler locks down access. 
    It maps directly to holding a hardware `spinlock` or an exclusive write-lock.

Once the function returns, the borrow ends, and the owner ring becomes fully accessible again.

The Rust compiler enforces "aliasing XOR mutation rule". It proves mathematically at compile time that for 
any given memory location, you either have `N` active readers `OR` exactly one writer—but never both.

Compiler tracks this and gives data race freedom guarantee before even the code loads on to hardware. 


--- 

## slide 14: Lifetimes — dangling pointers eliminated

Lifetimes are the compiler's proof that a reference never outlives the data it points to. Named by the programmer, verified by the borrow checker.

  ```rust
  fn get_ptr() -> &str {           // ← error: missing lifetime
      let local = String::from("DMA buffer");
      &local   // ← would return pointer to stack data
  }  // `local` dropped here — pointer would dangle

  // Rust requires an explicit lifetime annotation that proves
  // the returned reference lives as long as the input:
  fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
      if x.len() > y.len() { x } else { y }
  }
  // 'a = "the output lives at least as long as both inputs"
  // If this invariant cannot be satisfied, the code does not compile.
  ```

[
  In kernel drivers: a reference to a `struct device` inside an interrupt handler *must not outlive the device*. Lifetimes encode and verify this invariant statically. No more `dev_hold()` / `dev_put()` mismatches.
]


Talking Points: :

- Lifetimes are the compiler’s mathematical proof that a reference never outlives the data it points to. 

-  In C, tracking how long an allocated structure exists relative to the pointers pointing to it is 
  completely manual. If an object is freed while a pointer is still active, you get a catastrophic 
  **dangling pointer.**

- With Rust as in the code block: we initialize a local variable `local` on the stack inside a function and
  try to return a reference to it. 

- This code is a hard compile-time error. The compiler looks at the scope boundary, realizes that `local` 
  is dropped at that closing brace, and refuses to return a reference that would instantly dangle.

- To handle more complex tracking like when data flows through functions, Rust uses explicit lifetime 
  annotations, represented by a single tick followed by a label, like 'a.

- the longest function example: Syntax does not change but we add annotation as meta-data, which is
  information to borrow-checker: which tells the return reference will live only as long as shortest lived
  input parameter. 

- If the caller tries to use that return reference either input data block is dropped, the code will not
  compile. 

- Think of this as a reference to physical `struct device` that you pass into an interrupt handler or a 
  concurrent worker thread. As We know that the reference must not outlive the device itself. 
  In traditional C kernel programming, we protect against this using runtime reference counters like 
  `dev_hold()` and `dev_put()`. Missing a single `dev_put()` the device is permanently leaked. Calling early
  we get panic. 

--- 

## slide 15: `Send` and `Sync` — thread safety in the type system

  *`Send`*: a type can be moved to another thread. \
  *`Sync`*: a type can be shared between threads (via `&T`). \
  These are *marker traits* — compile-time properties with zero runtime representation.
  #ref-badge[RustBelt §3.3: formal definition of Send and Sync via ownership predicates]

  ```rust
  // `Rc<T>` is NOT Send (reference counting not atomic)
  // The compiler prevents it from crossing a thread boundary:
  use std::rc::Rc;
  let rc = Rc::new(42);
  thread::spawn(move || {
      println!("{}", rc);
  });
  // error[E0277]: `Rc<i32>` cannot be sent between
  // threads safely — use Arc<T> instead
  ```

*Practical impact for kernel drivers*

  - A spinlock-protected struct is `Sync` if and only if `T: Send`
  - The compiler *refuses* to put non-`Send` data in a global
  - Interrupt handler shared data must be `Sync` — enforced before the module loads

    Every concurrency contract that Linux documents in comments (`/* must hold lock X before accessing Y */`) Rust encodes in the *type signature* and verifies at compilation.

Talking Points: 

-  concurrency bugs are the absolute hardest to reproduce and fix.
- In C, our concurrency contracts live exclusively in text comments.
  /* Note: Must hold lock X before accessing structure Y */. 
  We hope everyone reads the comment, and we hope everyone follows it.

- Rust encodes concurrency contracts directly into the type system using two foundational concepts: 
    Send and Sync.

    - `Send` means a type can safely be transferred completely to another thread or processor core.
    - `Sync` means a type can be safely shared across multiple threads or cores simultaneously via immutable
      references.
    - These are what we call **marker traits**. They have zero runtime representation and generate 
      absolutely no overhead or extra machine code instructions. 
    - They exist purely for the compiler to run static graph analysis on how data moves across execution 
      boundaries.

- Code snippet: we try to use `Rc`, which is a non-atomic `reference counter`. 
  Because `Rc` uses a fast but non-thread-safe counter increment, moving it to another thread would create 
  a silent data race on the reference count value.

- In C compiler compiles cleanly and can lead to corrupt memory. 
- In Rust compiler checks the type signature, realized Rc does not implement `Send` trait, and compiler
  drops a compile time error. It can hits instead of Rc use Arc atomic reference counter. 


Note:
The practical impact this has for writing BSPs/kernel drivers/firmware for your co-processors:

- First, a lock-protected structure is only considered `Sync` if the underlying data is `Send`. 
- This means you cannot accidentally place an `unsafe`, non-thread-safe data type inside a `spinlock` or 
  `mutex.`

- Second, the compiler strictly refuses to let you put `non-Send` data into global static variables, 
  completely eliminating un-synchronized global state corruption.

- Third, any data shared with an interrupt service routine (ISR) or an asynchronous event handler must be 
  marked as `Sync`. The compiler enforces this architecture contract before a single block of your module 
  can even load.

- Essentially, every single concurrency rule that we traditionally document in text comments or README files
  is converted by Rust into a strict type signature that is mathematically verified at compilation. 
  The compiler simply prevents you from compiling a data race."

---

## slide 16: Important Additional Concepts: 

To wrap up our structural look at the language, there is a whole ecosystem of features that we don't have 
time to fully unpack today, but are essential if you want to dive deeper down the Rust rabbit hole.

If you look at production Rust drivers or toolchains, you will encounter these terms frequently, so here is 
a quick systems-level primer for them:

- Traits: Rust's explicit code interfaces, defining shared behavior across different data types, similar to 
  abstract base classes or structured function pointer tables in C.

- Generics: Compile-time templates that allow you to write algorithms that work with multiple data types
  without code duplication, evaluated entirely at build time.

- Trait-bounds: Compile-time constraints on generics, allowing you to tell the compiler: 
  'This generic function only works on types that implement a specific hardware interface or trait.'

- Smart pointers: Custom data structures that act like pointers but wrap raw memory with automatic 
  lifecycle tracking, like managing a reference-counted memory region.

- iterators: Highly optimized, composable pointer-traversal abstractions that let you loop through arrays 
  or ring buffers safely without raw index pointer arithmetic.

- macros: Code-generation tools that compile down at build time, allowing you to write highly expressive 
  code without incurring any runtime or performance overhead.

- attributes:  Declarative metadata attached to your code, used for things like conditional compilation for 
  different processor targets or forcing explicit struct packing layout alignment.

---

## slide 17: Compiler checks ( beyond memory safety )


## slide 18 : What the Rust compiler verifies at every build

  *Memory safety* (previous sections)
  - No use-after-free
  - No dangling references
  - No data races
  - No null dereferences (`Option<T>` instead of `NULL`)
  - No uninitialized reads (all fields must be initialised)

  *Type system*
  - Integer overflow in debug builds → panic (not UB)
  - Exhaustive `match` — all enum variants handled
    ```rust
    match direction {
        DmaDir::ToDevice   => { … },
        DmaDir::FromDevice => { … },
        // error if DmaDir::Bidirectional not handled
    }
    ```

  *Error handling*
  - `Result<T, E>` — ignoring an error is a *compiler warning*
    ```rust
    #[must_use = "this Result must be handled"]
    fn map_dma(...) -> Result<SgTable, DmaError> { … }

    map_dma(dev, sg, nents); // warning: unused Result
    // The kernel C equivalent: silently dropping -ENOMEM
    ```
  - `Option<T>` — no null, no null-deref

  *Unsafe quarantine*
  - `unsafe { }` blocks are *explicitly marked*
  - `grep -r "unsafe"` gives the *complete* audit surface
  - Safe code cannot call `unsafe` functions accidentally

    In C, all of the above require separate tools: ASAN, UBSAN, sparse, Coccinelle, clang-tidy, GCC sanitizers — none of them are mandatory, and none are exhaustive.

Talking Points: 

- To keep a  C codebase robust requires ecosystem of external tools :
  ASAN for memory 
  USSAN for undefined behaviour 

And these tools are not mandatory and they are not unified and they dont cover 100% of the code. 

- Rust changes this completely by baking in all these checks directly into mandatory compiler pass. 

- Every single build, the compiler verifies three distinct layers of defense:

1. checks Memory Safety: ensures there are no use-after-free bugs, no data races, no uninitialized 
   memory reads, and crucially, no null-pointer dereferences. 
   It achieves this because Rust does not have a NULL pointer. 
   Instead, it uses a functional type called `Option<T>`, which forces you to explicitly handle the 
   'absence' of a value before you can ever read its contents.

2. Enforces strict Type and Flow Safety. 
  Code snippet: In C, if you add a new `enum` variant to a driver state machine, a switch/case block will 
  silently ignore it if you forget to update it. 
  In Rust, the compiler forces exhaustive pattern matching. 
  If you add Bidirectional to this DMA direction `enum`, the compiler will instantly reject the build until 
  you explicitly write the code to handle it. 
  Furthermore, undefined behaviors like integer overflows are caught in debug builds, triggering a clean 
  panic rather than executing silent, corrupted math.

3. Third, it mandates Error Handling. 
   Some time we see kernel driver silently drop an -ENOMEM or an -EIO because an error return value wasn't 
   checked? 
   In Rust, functions that can fail return a `Result` type marked with #[must_use]. 
   If you call `map_dma` and try to ignore the result, the compiler immediately flags it with a warning. 
   You physically cannot ignore an error state by accident.


- If the compiler is so strict how do we actually write actual HW drivers, read MMIO register or talk to
  co-procecssors. This is done by **Unsafe quarantine**.
  Rust allows you to drop into an explicit `unsafe {}` block when you need to perform low-level opeartions
  like de-referencing raw register pointer. 

- Unsafe does not disables compiler: it simply acts as a boundary marker. 

---

## slide 19: Ecosystem:

- C:  language is separate from the compiler, the compiler is separate from the build system, and 
  dependency management is essentially a manual process, which often leads to complex Makefiles.

- Rust rejects this fragmented approach. Provides an entire unified development platform out of the box.

- The most important one of this is Cargo. 
- Cargo is Rust’s built-in build system, package manager, test runner, and documentation generator all 
  rolled into one.

- Instead of writing hundreds of lines of build logic, Cargo handles compilation dependencies declaratively.
  It talks seamlessly to `crates.io`, the central registry for thousands of open crates.
  If you need an optimized, peer-reviewed ring buffer implementation, or a network protocol parser, you 
  don't copy-paste code; you declare it as a single line in a configuration file, and Cargo handles the 
  rest, including strict version locking.

- Cargo simplifies Cross builds: Unlike C where we can end up with maintaining custom environment scripts. 
  Compiling for different HW architecture is often simple as running 
  `cargo build --target=aarch64..`, Cargo automatically fetched and hooks in the correct bare-metal
  toolchain target automatically. 


---

## slide 20: eBPF


- So this topic is basically a continuation of the earlier eBPF sessions.

- Earlier we already discussed:

  * how eBPF works,
  * what does the eBPF verifier checks for safety,
  * the execution model,
  * and the tooling ecosystem around it. ( BCC, libbpf .. )

- What we are doing today is slightly different.

- Instead of focusing on eBPF itself, we are looking at:
    - what happens when we bring Rust into the picture.

- The main question is:
    - can we leverage Rust’s features to improve the eBPF development workflow?

- We will compare:
    - what remains exactly the same,
    - what gets better,
    - and what trade-offs we introduce.

- One important thing to remember:
    - The eBPF programs are just bytecode.
    - So the kernel really does not care whether that bytecode came from C or Rust or Go.

- That means:
    - interaction with kernel internals is still the same, 
    - we still deal with the same verifier,
    - and we still operate under the same constrained execution environment.

- So Rust does not remove eBPF limitations.

- What Rust improves is the developer experience.

- One of the biggest advantages is:

  - we can use a single language and compiler for both 
    - the eBPF side,
    - and the user-space loader side.
    - offers a rich echo-system of modern frameworks ( async code ) 

- This reduces a lot of friction between user-space and kernel-space.

- For example:

  - fewer ABI mismatch issues,
  - fewer alignment and padding problems,
  - and easier sharing of common data structures.

- Map definitions also become strongly typed.

- So many mistakes get caught during compile time itself.

- Another advantage is tooling simplicity.

- We no longer need complicated multi-language build pipelines.

- Rust’s compile-time checks are also very useful here.

- Many memory safety and logical issues are caught before the program even reaches the kernel verifier.

- In many cases this also produces cleaner verifier-friendly bytecode.

- And finally,

- * working with Rust in eBPF is also a practical entry point into the broader Rust-for-kernel ecosystem.
-
- So the overall takeaway is:

  * Rust does not change what eBPF is,
  * it changes how safely and ergonomically we build eBPF programs.

--- 

## slide 21: Quick Overview: 

*eBPF: in one sentence*

`eBPF` is a Linux Kernel model that lets you load user-supplied programs into the kernel *without a kernel patch, without a module, and without rebooting*, the kernel verifier guarantees safety.

*The four-step plumbing tasks:*

1. *Write* — BPF bytecode (from C or Rust source)
2. *Verify* — kernel verifier: bounded loops, no OOB, type-checked
3. *JIT* — native machine code; zero interpreter overhead after load
4. *Attach* — hook point (kprobe, tracepoint, XDP, LSM, …) fires on event

If the verifier accepts the program, it *cannot* crash the kernel ( checks for infinite-loop, or access out-of-bounds memory... more)
#image("./ebpf_plumbing.png")

Talking Points:
    
- So this slide is a quick refresher of what eBPF actually is, in the simplest possible form.

- In a single sentence:
  - eBPF is a Linux kernel mechanism that allows us to load user-defined progs into the kernel.
  - without patching the kernel.
- without loading kernel modules.
  - and without rebooting the system.
  - while still keeping safety guarantees through the kernel verifier.

* Now, to understand how eBPF actually runs, we can think of it as a simple four-step pipeline.
---

* Step one is **write**:

  * we write an eBPF program,
  * typically in C or Rust,
  * For C code its gets compiled using clang/LLVM 
    ( C -> LLVM IR -> ebpf Bytecode)
    (component is eBPF backend )
    So Clang + LLVM = standard tool chain for C eBPF programs. 
  * And with Rust we have `libbpf-rs` and `Aya` ( new approach )
    ( Rust -> LLVM -> ebpf Bytecode)
    Rust eBPF target is compiled with "bpfel-unknown-none" 
   
  - Some older /hybrid approches:
    - Some setups compile eBPF parts in C using clang.
    - Then embed or interface with Rust User-space code. 


Note: 
    - Both C and Rust rely on LLVM eBPF backend.
    - C uses clang as front-end.
    - Rust uses `rustc` as front-end. 
    - And both converge at:
        - LLVM -> eBPF bytecode generation. 


---

* Step two is **verify**:

  * the program is passed through the kernel verifier,
  * which checks things like:

    * bounded loops,
    * no out-of-bounds memory access,
    * and overall type and safety constraints.

---

* Step three is **JIT compilation**:

  * once verified, the bytecode is converted into native machine code,
  * so there is no interpreter overhead during execution.

* Step four is **attach**:

  * the program is attached to a kernel hook,
  * such as `kprobes`, `tracepoints`, `XDP`, or `LSM` hooks,
  * and it runs whenever that event is triggered.

* The key idea here is:

  * if the verifier accepts the program,
  * it is guaranteed not to crash the kernel.

* That guarantee comes from strict checks like:

  * preventing infinite loops,
  * blocking invalid memory access,
  * and enforcing safe execution boundaries.

* So in essence:

  * eBPF acts like a safe programmable layer inside the kernel,
  * where logic can be injected dynamically at runtime.

* And if we connect this to the diagram on the slide:

  * we start by writing the program in Rust or C,
  * it compiles into BPF bytecode,
  * the kernel verifier checks safety,
  * then it gets loaded and attached to kernel hooks,
  * and finally it runs when an event happens.

* During execution:

  * eBPF programs can interact with maps,
  * and those maps are used to store and exchange data.

* That data is then sent from kernel space to user space,

  * which is how observability, tracing, and networking tools are built on top of eBPF.
    

--- 
## Slide 22 : eBPF Maps : the data bridge

*Maps = the only I/O channel for BPF programs*

- Shared memory between kernel BPF code and userspace reader
- Created by the loader before the program is attached
- Accessed from both sides via file descriptors

  [*Type*], [*Typical use*],
  --------------------------
  [`HASH`], [key → value lookup],
  [`RINGBUF`], [high-throughput event stream ✓],
  [`PERCPU_ARRAY`], [per-CPU stats, lock-free],
  [`LRU_HASH`], [connection tracking],
  [`PERF_EVENT_ARRAY`], [legacy event pipe],
  [`ARRAY`], [fixed-size indexed data],

*Ring buffer : the preferred choice* ([Introduced: Linux 5.8 — BPF_MAP_TYPE_RINGBUF])

- Variable-length records — no fixed-size overhead
- Single contiguous allocation — cache-friendly
- `epoll` / `AsyncFd` compatible — Tokio-native in Aya
- Dropped-event counter exposed to userspace for monitoring
- *In Aya*: `#[map] static EVENTS: RingBuf = RingBuf::with_byte_size(4 * 1024 * 1024, 0);`

- Prefer `RINGBUF` over `PERF_EVENT_ARRAY` for all new work — lower overhead, simpler consumer, no per-CPU complexity.

Talking Points:

So this slide is about the important concept in eBPF:maps:

- In simple terms:

  - maps are the only real I/O channel for eBPF programs.

- Because eBPF programs run inside the kernel and are heavily restricted,

  - they cannot directly print,
  - they cannot do file I/O,
  - and they cannot directly talk to user-space.


- So instead:

  - maps act as shared memory between kernel space and user space.

- The idea is:

  - the eBPF program writes data into maps,
  - and user-space programs read that data through file descriptors.


- These maps are typically:

  - created by the user-space loader first,
  - before the eBPF program is attached,
  - and then passed into the kernel.


- Once created:

  - both kernel eBPF code and user-space programs can access them using file descriptors.


- Now, there are multiple types of maps, each optimized for different use cases.

- For example:

  - **HASH map**
    - used for key-value lookups,
    - like tracking connections or state.

- **RINGBUF**
  - used for high-throughput event streaming,
  - very efficient for pushing events to user space.

- **PERCPU_ARRAY**
  - used for per-CPU statistics,
  - avoids locking and reduces contention.

 **LRU_HASH**
  - used for connection tracking or caching,
  - automatically evicts least recently used entries.

- **PERF_EVENT_ARRAY**
  - older mechanism for event streaming,
  - still used but largely being replaced.

- **ARRAY**
  - fixed-size indexed storage,
  - useful for counters or static data.

- Among all of these, one of the most important modern choices is the **ring buffer**.

- The ring buffer was introduced in Linux 5.8 as `BPF_MAP_TYPE_RINGBUF`.

- It has become the preferred option for event delivery because:

  - it supports variable-length records,
  - so there is no need to predefine fixed-size events,
  - it uses a single contiguous memory region,
  - which improves cache efficiency,
  - and it avoids per-CPU complexity.

- From a performance perspective:

  - it is lower overhead compared to older event mechanisms,
  - and simpler to consume from user space.

- It also integrates very well with modern `async` runtimes: (MORE AT NOTE)
  - for example, in Rust with Aya,
  - it can be used with `epoll` or async abstractions like `AsyncFd` in Tokio.


* Another practical advantage is observability:
  * it exposes dropped-event counters,
  * so user-space can detect when it is falling behind.

* In code, especially with Aya, it looks like:
  * you define a static ring buffer map,
  * allocate a memory size,
  * and then use it as the primary event channel.

* And the key design recommendation is:
  * prefer `RINGBUF` for all new eBPF work,
  * because it is faster,
  * simpler,
  * and avoids older per-CPU complexity from `PERF_EVENT_ARRAY`.

* So the takeaway is:
  * maps are the bridge between kernel and user space,
  * and ring buffer is now the modern standard for streaming data out of eBPF programs.

NOTE: The reason ring buffer integrates well with modern async runtimes is because of how its consumption model matches event-driven programming.
1. Ring Buffer is a poll-based, not callback-based 
    - the eBPF ring-buffer is exposed to user-space as a FD
    - The FD then can be polled/epolled or integrated into `async` reactors.
2. So instead of:
    - "call this callback when data arrives" 
   You get: 
    - "wake me up when this FD is readable"

3. This matches `async`  runtime design perfectly. 
    Rust `async` runtimes like: Tokio, smol 
    are built around: event loops, readiness-based I/O ( epoll/kqueue/io_ring style)

4. Ring buffer fits naturally because:
    - It behaves like a stream of readiness events 
    - not a blocking or callback-heavy API.

5. Aya makes this much easier than C
    - The ringbuffer FD is directly integrated into `epoll` or `AsyncFd` ( tokio abstraction )
    - this allows to await events like normal async I/O ( without threads )

6. With C based approach, this requires:
    - Manually setup `epoll`
    - manage event loops by ourself.
    - spawn dedicated pooling threads 

   Common patterns look like 
    - infinite while loop pooling 
    - blocking reads 
    - or custom dispatcher threads. 
   This => more boilerplate code, harder concurrency control, and manual synchronization between
   threads. 

7. Key differences: 
    C: "Must continuously poll/manage threads to read events"
    Rust: "wait for event like any other async stream"

8. Ringbuffer specifically enables this:
    - Exposes a single FD.
    - Supports non-blocking reads 
    - Works cleanly with readiness notification ( epoll )

=> this makes it fundamentally compatible with :
    - event loops 
    - async executors 
    - Structures concurrency 

9. In short Rust makes this integration natural through `async` abstractions like `AsyncFd`, while C
   required manual event loop and thread management. 

---

## Slide 23: Does Rust Fit eBPF?

Before we go into details on using Rust. We first address 

    - does Rust actually fit into the eBPF ecosystem?

- To answer that, we first need to look at how the ecosystem looks today.

- In most real-world systems:
  - eBPF is not written in just one language or toolchain.

- Instead, it is a combination of multiple layers:
  - eBPF programs are often written in C,
  - compiled using LLVM and Clang,
  - user-space components might be written in Go, Python, or C++,
  - and then glued together with custom build systems.

- So the reality is:
  - eBPF development today is already a multi-language, multi-toolchain system.

- This naturally introduces complexity:
  - different memory models,
  - different ABI assumptions,
  - and multiple build and deployment pipelines.

- Now, if we look at industry adoption:
  - one of the strongest examples is networking.

- For example, projects like **Cilium**:
  - use eBPF heavily for Kubernetes networking,
  - replacing traditional networking layers like iptables in many cases,
  - and pushing eBPF into production at scale.

- In systems like Cilium:
  - the eBPF layer is typically C-based and LLVM-driven,
  - while user-space control planes are written in Go,
  - again reinforcing this multi-language reality.

- So the question becomes:
  - does introducing Rust simplify this or make it more complex?

- Rust’s role here is not to replace everything:
  - it is not replacing the kernel,
  - it is not replacing eBPF itself,
  - and it is not forcing a new execution model.

- Instead, Rust fits in as a unifying layer:
  - especially for both eBPF programs and user-space components.

- The key improvements Rust brings are:
  - safer memory handling in user space,
  - shared data models between kernel and user space,
  - and reduced ABI mismatches due to stronger type guarantees.

- In practice, this means:
  - fewer “glue code” problems between components,
  - fewer serialization bugs,
  - and more predictable behavior across the stack.

- So rather than replacing existing systems:
  - Rust gradually reduces friction inside them.

- The important mindset shift is:
  - eBPF ecosystems are already complex and multi-language,
  - Rust does not introduce that complexity,
  - it tries to unify parts of it.


- So the takeaway is:
  - Rust fits eBPF not by changing what eBPF is,
  - but by simplifying how we build and maintain the systems around it.

---

## Slide 24: Why Rust is a natural fit for eBPF programs:

*Shared constraints*

eBPF programs and Rust both operate under the same fundamental constraint: *no undefined behaviour is acceptable*.

- The BPF verifier rejects programs it cannot prove safe
- Rust's type system rejects programs it cannot prove safe
- Both operate at compile time or load time — not at runtime

*`no_std` alignment*

eBPF programs run with no kernel library, no allocator, no OS primitives. Rust's `#![no_std]` mode is the natural target — `aya-ebpf` provides the BPF-side runtime (`bpf_helpers`, map types, program macros) without any standard library dependency.

*Type safety across the kernel boundary*

The most expensive eBPF bug class in C: a map struct definition in the BPF program and the userspace loader that silently diverge.

  ```c
  // BPF program (C):
  struct event { u64 ts; u32 pid; };
  bpf_ringbuf_output(&rb, &e, sizeof(e), 0);

  // Userspace loader (C) — different file:
  struct event { u64 ts; u64 pid; }; // u64 ≠ u32 !
  // Reads wrong data — no compile error, no warning
  ```

*Aya's solution*: one `#[no_std]` *common crate*, compiled for both targets. The struct is defined *once*. Layout disagreement is a *compile error*, not a runtime bug.

- This is the highest-value safety property of Rust for eBPF — not just memory safety in the BPF program, but *type-safe communication across the kernel/userspace boundary*.

Talking Points:

Now we look at why Rust is actually a *natural fit* for eBPF, not just a convenient one.

- The core idea starts with a shared constraint:
  - both eBPF and Rust fundamentally reject undefined behaviour.

- On the eBPF side:
  - the kernel verifier only allows programs it can prove to be safe,
  - otherwise the program is rejected before it ever runs.

- On the Rust side:
  - the compiler enforces safety through the type system,
  - and rejects unsafe patterns at compile time.

- So in both cases:
  - safety is enforced *before execution*,
  - not during runtime.

- That alignment is important because:
  - eBPF does not have runtime recovery,
  - and Rust is designed to avoid runtime failure classes in the first place.

- Another strong alignment is `no_std`.

- eBPF programs run in a very minimal environment:
  - no standard library,
  - no OS abstractions,
  - no dynamic allocation guarantees in many cases.

- Rust supports this directly through:
  - `#![no_std]` mode.

- This is exactly where frameworks like **Aya eBPF** fit in:
  - they provide the BPF-side runtime,
  - helpers for maps,
  - program macros,
  - and bindings to kernel helpers,
  - all without relying on the Rust standard library.

- So Rust is not forced into eBPF.
- It already has a mode that matches eBPF constraints.

- Now the most important part is type safety across the kernel boundary.

- One of the biggest real-world problems in eBPF is this:
  - kernel-side and user-space must agree on data structures,
  - but in C, they are often defined separately.

- That leads to a subtle but dangerous issue:
  - structs drift over time,
  - padding or field types change,
  - but there is no compiler-level enforcement across both sides.

- So you can easily get a situation like:
  - BPF side defines `u32 pid`,
  - user space accidentally assumes `u64 pid`,
  - and everything still compiles.

- The problem is:
  - there is no immediate error,
  - but the data interpretation is silently wrong.

- This is one of the hardest classes of bugs in traditional eBPF systems.

- Rust solves this in a more structural way:
  - using a shared crate compiled for both kernel and user space.

- In frameworks like Aya:
  - the same struct definition is reused across both worlds,
  - so there is only one source of truth.

- That means:
  - if the layout changes,
  - both sides break at compile time,
  - instead of silently misbehaving at runtime.

- This is actually one of the highest-value improvements Rust brings to eBPF:
  - not just memory safety inside the program,
  - but *type-safe communication between kernel and user space*.

- So the key takeaway is:
  - Rust fits eBPF because both share the same philosophy of rejecting unsafe behavior early,
  - and Rust extends that safety across the kernel-user boundary, where most real-world bugs actually happen.

