# Talking Points:


# Talking points for "slides.md"

## Slide 0: Introduction to Rust:

Good Afternoon, 

Today we’ll be looking at the Rust programming language which has turning to be a new tool in systems 
programming toolbox.Specifically we'll explore why its has gained popularity for delivering memory safety 
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


