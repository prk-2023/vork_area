### Slide 1: Introduction to Rust (Speaker Notes)

- **[Opening]** 

Good afternoon,  Today’s topic is **Introduction to Rust and eBPF Programming with Rust**.

- Before we talk about Rust, it's worth recognizing that modern computing infrastructure is largely built
  on the foundation of C.

- For more than 50 years, C has been the language of operating systems, device drivers, firmware, 
  networking stacks, and embedded space.
  The combination of 
    performance, 
    portability, and 
    direct hardware access 
  has made C, the most successful and widely used programming language.

- So this presentation is not about why C is bad, nor is it about replacing decades of successful 
  engineering practices.

- Instead, it is about understanding the evolving systems programming landscape and why Rust has emerged as
one of the technologies of interest from operating system vendors, silicon companies,
cloud providers, and the open-source community.

[Why the Industry is Looking for Something New]

- Over the time we see software systems grow larger and are more connected, this brings changes in
  expectations.  
- Today systems are expected to provide not only performance and reliability, but also strong security 
  guarantees. 
- With growing codebases, distributed teams, and complex software lifecycles offer different sets of challenges.

- When we look across the industry, a significant percentage of security vulnerabilities continue to
  originate from memory-safety issues such as:

    - Buffer overflows
    - Use-after-free bugs
    - Null pointer dereferences
    - Data races
    - Lifetime and ownership errors

- While these issues are not fully due to poor engineering. 
  They are often the consequence of building highly complex systems using languages that place
  responsibility for correctness of the developer.

- Also from Industry we see a common question that many organizations are now asking:
    - Can we maintain the performance and control of low-level programming while reducing entire classes 
      of bugs before the code ever runs?

[The Rise of Rust]

- This is where Rust comes, It offers one such attempt to answer that question. 

- Although Rust is relatively young compared to C, it has gained substantial industry momentum and has 
  consistently ranked among the most admired programming languages in developer surveys.

- What makes Rust particularly interesting is that it targets the same problem domain as C and C++ systems
  programming while taking a different approach to memory management and concurrency safety.

- Unlike language that relying primarily on runtime garbage collection or developer discipline alone,
  Rust attempts to move many correctness checks into the compiler.

- The result is a language that aims to provide:
    - Low-level control
    - Predictable performance
    - Memory safety
    - Concurrency safety
  All of these and more with out the use of a garbage collector.


[Setting Expectations]

- So Today's session is not intended to be a debate between C and Rust.

- And the good news is most systems software for the foreseeable future will continue to involve in C and
  many successful projects will remain C-based for years to come.

- Instead, we move our goal in understand the design principles behind Rust,
  And why major projects such as the Linux kernel have begun adopting it, and where it may fit alongside 
  existing systems programming practices.

- From there, we'll explore Rust from a systems programming perspective and look at how it is increasingly
  being used in kernel and eBPF development.

- Its also important to note that Introduction of a new language into use with existing systems has its own 
  pros and cons. And early study would help us better adapt to the fast changing landscape of programming.

---

### Slide 2:  ( Disclaimer:)


Disclaimer about the intent of this presentation.

Would like to state again the goal for today is not to start a language war or argue that one language should completely replace another.

Rather, focus is to discuss some of the evolving changes happening in the systems programming space:
especially in areas closely related to what many of us work on daily.

C remains one of the most important and successful programming languages ever created, and it continues to
be foundational to operating systems and embedded development today 

And Rust should not be viewed as a replacement for C, but rather as another tool in the systems programming toolbox.

The purpose is to view this through the lens of engineering perspective and evaluation to points like:

    * why the industry is paying attention to it,
    * what problems it attempts to solve,
    * whether it provides practical value for low-level development,
    * => whether Rust can improve: such as memory safety, reliability, and long-term maintainability.

Discussions around programming languages especially in Linux kernel and systems communities, can become 
very opinionated because developers naturally build strong trust in the tools they have relied on for decades.

More importantly I would like to state clearly:

    - I am not presenting myself as a Rust expert.
    - Like many engineers in the industry, Rust caught my attention with its adoption into Linux kernel 
      from early experimental effort into a supported and actively maintained direction as of 2025 December.

    - I am still exploring the technology myself, and today’s presentation is intended as a shared my 
      learning experience.

    - I will do my best to answer questions to the best of my knowledge and practical understanding.

--- 

### Slide 3: ( Overview ):


We divide today’s talk into two sections.

- In the first section, we will introduce Rust from a systems programming perspective and look at some of the
core concepts that make it increasingly relevant for low-level software development.

This includes topics such as:

* zero-cost abstractions,
* ownership and borrowing,
* deterministic memory management,
* memory layout control,
* and concurrency safety.

With limited time the goal is not to cover the entire language, but to understand the design philosophy
behind Rust and how it attempts to provide both performance and safety without sacrificing low-level
control.

- In the second section, we will move into eBPF programming with Rust.

We will explore Aya, a modern pure-Rust based eBPF framework which provides an alternative development approach
alongside traditional eBPF toolchains such as `libbpf` and `clang`/`LLVM` based workflows.

Finally, we will walk through a small demo project to demonstrate how a user-space Rust application can
interact with kernel-space eBPF programs, exchange data efficiently, and build observability or tracing
pipelines with minimal overhead and latency.

---

### Slide 4: ( Introduction to Rust ) ( systems programming perspective )


**[Transition & Introduction]**

In this section, we will see how Rust fits to be in the club of systems programming languages. 
And also examine, important properties behind its growing adoption and what it actually guarantees: 
compile-time correctness, predictable performance, and maintainable low-level abstractions.


---

### Slide 5: Evaluating Rust for Systems Programming:

**[The Baseline Criteria]**

First baseline criteria is to check the requirements of systems software and what essential checklist are its required to be a systems programming language.

Systems software is one that controls HW and mediates between the HW and every thing else around it, and
this compliance are characterized with some constrains: Such as 

1. Systems Language should provide a **Direct HW access:** example it should allow to map MMIO registers, 
   handle CPU-specific instructions, control precise memory layouts, and interface directly with silicon.

   **Zero-cost abstractions:** If we use a higher-level abstraction, it cannot introduce hidden runtime
   overhead. The compiled machine code must be as efficient as manual, low-level implementation.

2. **Deterministic memory management:** A garbage collector is a non-starter for kernels, BSPs, and drivers.
   We must know exactly when memory is allocated and precisely when it is freed to ensure predictable
   execution latency.

3. In when bugs occur the effect should be contained ( to one user or limited scope), This demands the
   systems programming language for program correctness, as small bug can have large consequence.

**Rust as systems software:**

A common misconception among low-level developers is that because Rust focuses heavily on safety, it must 
hide the hardware or abstract away raw pointers. 

In reality, Rust compiles directly to native machine code via LLVM and provides explicit, zero-overhead
primitives for bare-metal systems work.

- `no_std` (The Bare-Metal Switch): This attribute instructs the compiler to completely detach from the 
  standard library and OS layers. 
  It strips the runtime down to the bare metal, leaving only the core language primitives. 
  This is what allows Rust to be used for early-boot code, microcontrollers, and deep kernel subsystems.

- `unsaf`e (The Auditable Escape Hatch): Rust does not forbid low-level operations like 
  dereferencing raw memory-mapped pointers or interacting with hardware registers. 
  It simply requires you to wrap these operations in an unsafe block, this is to tells the compiler: 
  "I know the hardware layout here; stop checking this specific block." 

  This gives isolation of the critical sections of codebase into an easily auditable map where unsafe 
  boundaries are explicitly defined.

- `asm!`: Inline Assembly (asm!) Rust has first-class support for architecture-specific instructions. 
  When we need to execute a cache invalidation pipeline, barrier instructions, or change CPU privilege 
  levels, we drop into inline assembly exactly like we do in C.

- Binary Compatibility (#[repr(C)]): We cannot rewrite entire codebases overnight. 
  Rust uses the #[repr(C)] attribute to guarantee that a Rust data structure matches the exact memory layout,
  padding, and alignment of a standard C struct. 
  Ensures completely seamless FFI execution when interfacing with existing C libraries, legacy driver 
  components, or fixed hardware descriptors.

**[The Landscape Tradeoffs]**
When we map C, C++, and Rust against these requirements, the engineering tradeoffs become very clear:

* **Memory & Concurrency Safety:** 
    - C gives us absolute control but zero built-in safety guarantees;
      correctness relies entirely on our discipline and code reviews. 
    - C++ introduces RAII, which helps, but tracking ownership across complex, multi-threaded codebases 
      remains highly manual. 
    - Rust moves both memory and concurrency safety entirely into the **compile-time layer**.

The tradeoff of these langaguages when compared with :
* **Complexity vs. Abstraction:** C is simple but lacks high-level abstraction power, requiring significant:
    - manual architecture and boilerplate as codebases scale. 
    - C++ offers huge abstraction power but at the cost of immense language complexity. 
    - Rust targets the same high abstraction level as C++ but uses its type system to enforce structural 
      correctness.

Another trade off is the 
* **The Learning Curve:** 

    The most important trade-off we face with Rust is its steep learning curve.
    Rust's compiler does not negotiate; it forces you to resolve ownership and lifetime ambiguities before 
    a single line of machine code is generated. 
---
### Slide 6: The cost of the status quo - in numbers

To understand why companies like Google, Microsoft, Amazon, and the broader Linux ecosystem are investing 
so in Rust, is clearly driven from statical data related these bugs.

The reality is that the industry is trapped by what we can call the "eternal memory bug." 

Look at the numbers on the slide: 

Historical reports from the Microsoft Security Response Center showed that roughly 70% of their tracked 
Common Vulnerabilities and Exposures CVEs were caused by memory safety issues. 

Independent studies of the Linux kernel show a remarkably similar pattern: 
    ~67% of kernel vulnerabilities are memory-safety related.

What makes these numbers so staggering is that they persist despite massive investments in modern tooling.
Developers/Companies use:
    Advanced static analysis tools
    Kernel sanitizers (KASAN, etc.)
    A Rigorous formal review processes
    ...and highly experienced systems developers writing the code.

But the percentage of CVEs has not changed since 20+ years...

To answer why does this keep happening? It comes down to the fundamental design of the languages we use. 

- Languages like C intentionally prioritize unrestricted control and performance over safety guarantees.
- C gives us absolute, direct access to memory, which is exactly what we need for hardware. 
  But natively, it offers zero protection against:
    - Use-after-free: Accessing memory after it has been released back to the allocator.
    - Buffer overflows: Writing just one byte beyond our allocated space and corrupting adjacent memory.
    - Data races: Unsynchronised concurrent access to shared state across threads or cores.

When a codebase is small, a single developer can keep the memory model in their head. 
But as firmware, BSPs, and kernel subsystems grow into millions of lines of code—spanning multiple teams, 
different vendors, and hardware generations relying entirely on developer discipline to catch every memory 
violation is a statistical impossibility.

This is the exact problem Rust was built to solve at the compiler level.

---
### Slide 7:  The cost of status quo - In numbers

Rust's approach to these common CVE related problems differently:
To prevent broad classes of memory and concurrency bugs before the code can run.

With its core central ideas:
    - Such as a Strict ownership Model,
    - A strong Type system 
    - Lifetime analysis,
    - and aggressive compile-time verification.

In safe Rust, issues such as: ( note we exclude unsafe code blocks )
    * use-after-free,
    * iterator invalidation,
    * double free,
    * and many forms of data races
become compile-time errors instead of runtime failures.

And importantly, these guarantees are achieved without requiring a garbage collector or introducing hidden
runtime overhead.

That is one of Rust’s most important propositions for systems programming: 

Moving large categories of correctness and safety checks from runtime debugging into compile-time enforcement.

--- 

### Slide 8: 2. How Rust Fits system programming:

So far, we have talked about the why the historical context and the data driving the industry's shift. 

Now let’s move into the how.

In this section, we are going to look at exactly how Rust maps to the day-to-day realities of systems 
programming. 

We will look at how it handles the hardware interface, how it manages memory without a runtime, and how it 
actually integrates into environments like the kernel.

---
### Slide 9:  2.1: The Properties That Make Rust a Systems Language (Speaker Notes)

**[Property 1: Absolute Determinism (No GC, No Runtime)]**
The first and most critical property of Rust for our domain is determinism.

Unlike languages like Go or Java, Rust has no garbage collector. It has no reference-counting runtime 
silently running in the background, no hidden threads, and absolutely no stop-the-world pauses.

**The memory model maps exactly to what you already know in C:**

* **Stack allocation:** Has zero overhead. It is identical to declaring an `int x;` in C.
* **Heap allocation:** Is entirely explicit and backed by whatever custom allocator you provide.
* **Cleanup:** When a variable goes out of scope, the compiler inserts the cleanup code at a *statically known point* during compilation. It does not happen unpredictably at runtime.

Because of this, Rust is safe to run in the most heavily constrained environments we deal with. You can run Rust in an Interrupt Service Routine (ISR), in early-boot firmware before the MMU is even enabled, or on a bare-metal microcontroller with just 16 Kilobytes of RAM.

And critically for build integration: the output is a standard ELF binary. A Rust kernel module compiles to a standard `.ko` file. Tools like `insmod`, `lsmod`, and `rmmod` cannot tell the difference—to the system, it looks and executes exactly like a C object file.

**[Property 2: Unrestricted Hardware Access]**
The second property is direct hardware access. A major fear when adopting a "safe" language is that it will
hide the hardware behind restrictive abstractions. 
Rust doesn't do this.

It can do everything C can do at the silicon level.

*(Point to the code blocks on the slide)*

* **Memory-Mapped I/O:** 
    If you need to hit a HW control register, you can do a volatile write exactly like casting a ptr in C.

* **Inline Assembly:** 
    If you need to execute an architecture-specific data synchronization barrier ( enforce ordering and
    completion of memory operations (ARM) ) like the `dsb` instruction shown here.
    Rust has direct support for inline assembly that mirrors GNU C syntax.

* **Raw Pointers:** You can still do raw pointer arithmetic like in C.


**[Demystifying `unsafe`]**

Notice that all of these above operations are wrapped in an `unsafe { }` block.

It is very important to understand what this means. `unsafe` is **not** a switch that turns off the Rust 
compiler. 
It is an explicit, verifiable declaration. It is you, the developer, telling the compiler: 

*"I am directly interacting with HW state or raw memory that you cannot verify. I am taking responsibility 
  for this specific block."*

From an engineering management and security review perspective, this is huge. 
It means that instead of undefined behavior hiding anywhere in a massive codebase, all potentially dangerous
hardware interactions are explicitly marked, highly grep-able, and strictly contained.

---
### Slide 10: 2.1: The Properties That Make Rust a Systems Language (Speaker Notes) ( continuation )

Property 3 — Zero-cost abstractions (Speaker Notes)

**(Visual: Code snippets showing iterators, generics, and lifetimes)**

**[The C++ Connection]**
The third property is something many of you who write C++ will be very familiar with: zero-cost abstractions. 

- Rust fully adopts Stroustrup’s principle: 
    *"What you don't use, you don't pay for. And what you do use, you couldn't hand-code any better."* 

  Rust allows to write highly expressive, modern-looking code, but it guarantees that this code compiles 
  down to the exact same machine instructions as manual C. 

  We don't have to take the compiler's word for this we can verify it line-by-line on Compiler Explorer.
  (Godbolt.org) 

**[Iterators: High-Level Syntax, Low-Level Speed]**

Let's look at the first example. 
If we want to filter and sum an array of hardware latencies, we can use an iterator pipeline. 
It looks very high-level, almost like Python or JavaScript.

However, the Rust compiler aggressively unrolls and optimizes this. 
It flattens that chain into the exact same tight `for` loop you see below it. 
If you put this into Godbolt, both versions generate the exact same assembly instructions. 
You get the safety and readability of iterators with zero runtime penalty.

**[Generics: Monomorphization over V-Tables]**

The second example is generics. ( Which is a way to write code that works for many different data types 
with out code duplication)

In the example the generic function like `min_of`, 

- Rustcompiler generates a specialized versions for every types that is used as shown in the comment 
this is called Monomorphization. i.e the compiler that generates `min_of::<u32>` or `min_of::<u64>`, and 
so on and the cpu executes direct machine instructions. ( this is critical for low-level code where few 
cycles matter but this increases binary size as compiler generates different specialized copies)


**[Lifetimes: Compile-Time Phantoms]**
Finally, let's look at the syntax that usually scares people away from Rust:
    lifetimes, like the `'a` you see in this function.

It looks complex, but here is the most important thing to understand about lifetimes: 
    **they do not exist at runtime**. 

All of this lifetime annotation, all the borrow checking, all the type inference it is completely erased 
before the code ever reaches the LLVM backend.

The compiler uses it purely for static analysis to prove memory safety. 
Once the proof is complete, it is stripped away. 
The final runtime binary is as lean and raw as hand-written C.

---
### Slide 11: 2.2: The aliasing advantage — Rust beats C's optimiser (Speaker Notes)


//The code blocks show C `restrict` problem vs. the Rust exclusive borrow 

**[The Performance Surprise]**

When we talk about Rust in systems programming, the conversation almost always focuses on memory safety. 
But this slide highlights something that is frequently overlooked: 
    the performance *advantage* Rust often has over C.

**[The C Compiler's Dilemma]**

Let’s look at a very standard C function: processing two byte arrays.
*(Point to the C code)*
 According to C's pointer aliasing rules, the compiler must assume that two `uint8_t` `src` and `dst` 
 pointers might  overlap in memory. 

 Because of this, the C compiler is forced to be defensive and generates less optimized code.

**[The C Workaround: Promises, not Proofs]**

The workaroud function is shown as below. with addition of the `restrict` keyword, this tells the compiler, 
 *"I promise these buffers do not overlap."*
And allow to generate a better optimized code. 

 But here is the critical flaw: `restrict` is just a promise. It is an unchecked human guarantee. 

 If the caller makes a mistake and passes overlapping buffers, the compiler will not warn you, and you will 
 get silent data corruption at runtime.


**[The Rust Solution: Compile-Time Proof]**
Now look at the exact same function in Rust.

*(Point to the Rust code)*
Rust solves this not with a promises but with guarantees from the type system.

We take a mutable reference for the 'output' (`&mut [u8]`) and an immutable reference for the 'input'.  
=> Rust’s fundamental borrowing rule is that a mutable reference is strictly **exclusive**. 
   i.e No other reference can point to same memory (pointed by the mutable reference) while it exists. 
   //Which means aliasing is discouraged, in Rust ( safe code )

   If this code compiles, it is mathematically proven that no other reference to that memory exists. 
   The buffers *cannot* overlap.

**[LLVM Auto-Vectorization]**
Because of this, the LLVM backend gets this exclusivity proof for free. 
It doesn't need a `restrict` hint. 
It looks at this loop, knows the pointers cannot alias, and aggressively auto-vectorizes it into 
instructions. 
No annotations. No trusting the caller.

**[The Core Takeaway]**

This also brings us to one of the most elegant aspects of the language: 
**The exact same property that prevents data races is the property that enables better code generation.** 
Safety and performance are not a tradeoff here, they both arise from the same aliasing proof in the type system.

---
### Slide 12:  3.0: Important Language Features (Speaker Notes)

**(Visual: Section 3 Title Slide outlining: Ownership, Borrowing, Lifetimes, Thread Safety)**

Till now we covered some of important the baseline properties for why Rust fits to be a systems language. 
We will move over to look at the core engine of the language itself. 

If you  happen to read any book or article on Rust, there are four terms you will see repeat : 
**Ownership, Borrowing, Lifetimes, and Thread Safety**.

**[The Systems Perspective]**

We aren't going to look at these features as just syntax rules. 
Instead, we are going to look at them as concrete engineering tools designed to eliminate specific, costly 
classes of runtime bugs that we fight every day things like 
    use-after-free, 
    double frees, 
    dangling pointers, 
and multi-core data races.

Let’s step through them one by one to see how they actually map to the memory layout and how the compiler 
tracks them.

---
### Slide 13: 3.1: Ownership — Memory Safety at Compile Time (Speaker Notes)

//**(Visual: The three rules of ownership prominently displayed, with the two code blocks showing Move 
//semantics and Scope-based drop)**

**[The Core Engine]**

Now we are touching the absolute core engine of Rust: **Ownership**. If you look under the hood, ownership 
isn’t a runtime library or a magic trick; it is a strict, type theoretic answer to the challenges of manual
memory management.

In C, if you copy a pointer, you now have two variables pointing to the same block of memory. 
If one path frees that memory, the other path doesn't know, and you get a silent corruption or a crash. 
Rust eliminates this entirely by enforcing three compile-time rules.

**[Rule 1 & 2: Single Ownership and the Move Semantic]**

* **Rule 1:** Each value has exactly one owner.
* **Rule 2:** There can only be one owner at a time. Ownership can be moved, but it cannot be duplicated 
              implicitly.

Let’s look at the first code example to see how this plays out.

*(Point to the String example)*
When we create `s1`, it owns that heap-allocated string. 
When we say `let s2 = s1;`, a C developer might think we are just copying a pointer. 
But in Rust, this is a **Move**. 

Ownership of that memory is transferred entirely to `s2`.

From this exact line onward, `s1` is considered uninitialized by the compiler. 
If you try to use `s1` on the very next line, the code will refuse to compile. 

In C, a mistake like this compiles perfectly, only to crash or corrupt memory silently at runtime. 
In Rust, the compiler tracks this tracking statically there is absolutely zero runtime bookkeeping or 
performance overhead.

**[Rule 3: Deterministic Cleanup (Drop)]**

* **Rule 3:** When the owner goes out of scope, the value is dropped automatically.

*(Point to the DMA buffer example)*
Let’s look at how this applies to something close to our work: allocating a DMA buffer inside a code block. 

In C, we have to manually ensure that every single execution path—including error paths and early 
returns—calls the appropriate `free()` or cleanup function. If we miss just one path, we leak resources.

In Rust, the moment `buf` hits that closing curly brace and goes out of scope, the compiler automatically 
inserts the call to `Drop::drop()`. It acts exactly like C++ RAII, but it is deeply woven into the language 
rules. There is no `free()` for the developer to forget, and no silent leak is possible.


**[The Big Shift]**
The ultimate takeaway here is that ownership completely shifts memory safety. 
It takes what has historically been a stressful runtime discipline, relying on developers to never make a 
mistake and turns it into a compile-time verification problem solved entirely by the type system.

---
### Slide 14: 3.2: Ownership vs. C — Eliminating Use-After-Free (Speaker Notes)


**[Contextualizing the Threat]**

Next we look at real-world application of ownership.
The Use-After-Free (UAF), is consistently one of the most common and dangerous kernel CVE classes.

The core point to make here is that : 

**this is not a bug detection problem; it is a program expressiveness problem.** 

In standard C, you simply do not have a way to express to the compiler that a pointer has become invalid 
after a certain point in time.

**[The C Reality]**
Look at the C snippet on the left. This is a very typical pattern we see in drivers:

1. We allocate a DMA buffer.
2. We submit it to the hardware.
3. We free it using `kfree(buf)`.

Then, maybe 500 lines of complex logic later or perhaps inside an asynchronous callback or after an error 
handling branch, someone attempts to read the completion status using that same `buf` pointer.

This is a classic Use-After-Free. It is pure undefined behavior. But as far as GCC or Clang are concerned, 
this code is perfectly valid. The compiler will give you zero warnings and zero errors. It compiles cleanly, 
only to corrupt memory or panic a customer's device silently in the field.

**[The Rust Defense]**

Now look at how the exact same scenario plays out in Rust on the right.
We allocate the buffer, submit it, and then explicitly call `drop(buf)` to free it.

If we try to pass that same buffer to `read_completion` on the next line, the Rust compiler steps in and 
completely halts the build. 
It throws **Compiler Error E0382: use of moved value**.

**[The Power of Compile-Time Diagnostics]**
What makes this incredibly powerful is the clarity of the diagnostic. The compiler doesn’t just say "error." 
The error message names the *exact line* where the value was initialized, the *exact line* where it was 
dropped and moved out of scope, and the *exact line* of the illegal subsequent use. 
It gives you a complete temporal analysis of your memory before a single byte of machine code is generated.

Think about what this means for our daily workflow. We don't have to spin up a specialized simulation, we 
don't have to run heavy `Valgrind` builds, and we don't have to wait for `KASAN` (Kernel Address Sanitizer) 
to catch a panic during OEM execution testing. The security boundary is enforced instantly at every single
build.

---

### Slide 15: 3.3: Ownership Prevents Leaks — RAII in the Kernel (Speaker Notes)

**[Context & The Kernel Reality]**

The Psudo Liux driver code with `probe` function as shown on the left side of this slide. 

Here Managing resource allocation during device initialization can be tedious and error-prone parts of 
kernel development.

In C, tracking state across error exit paths is a purely human discipline. 
Rust makes it structurally impossible to get this wrong.


**[The C Reality: The `goto` Maintenance Tax]**

Let’s walk through the C snippet.

We allocate `res_a`. 
If it succeeds, we try to allocate `res_b`. If `res_b` fails, we have to remember to free `res_a` before 
returning an error code. If we then try to allocate `res_c` and *that* fails, we have to free both 
`res_B` and `res_A` in the correct reverse order.

In a real kernel driver, this usually leads to massive cascades of `goto` cleanups like 
`goto err_free_res_b;`, `goto err_free_res_a;`. 

The Linux kernel source tree literally has thousands of these cleanup labels. 
Every single time a new feature or error branch is added, the developer has to manually audit every single 
exit path to ensure no resources are leaked. Miss just one path, and you have a memory or hardware resource leak.

**[The Rust Alternative: The `?` Operator and Automatic `Drop`]**
Now look at the Rust implementation on the right.

Notice how clean the control flow is. We use the `?` operator at the end of each allocation function.

If `ResourceA::alloc()` succeeds, it returns the resource. If `ResourceB::alloc()` fails, the `?` operator 
immediately triggers an early return from the function.

But here is the critical part: because `res_a` was successfully initialized and owns its resource, the 
compiler automatically inserts a call to `res_a.drop()` right on that early return path.

If all three allocations succeed, they are wrapped up into our driver structure. If the driver is later 
unloaded, all three resources are automatically torn down in the exact reverse order of their allocation.


**[The Structural Win]**
What Rust is doing here is turning a 
**developer-managed control flow problem** into a **compiler-enforced scope rule**.

We get completely free of  `goto` cleanup chains. 
There is no explicit error-path cleanup logic to write, maintain, or peer-review. 
The compiler guarantees that cleanup runs perfectly on every single execution branch, with zero runtime 
overhead.

---
### Slide 16: 4.0: Borrowing and Lifetimes — Preventing Data Races (Speaker Notes)


Til now, we’ve looked at **Ownership**, which is great for managing the lifecycle of resources and 
preventing leaks. But if we had to move ownership of a buffer every single time a function wanted to look 
at it, writing code would be completely impractical. 

Drivers need to pass references to packet buffers, configuration blocks, and hardware registers without 
giving up ownership.

This brings us to **Borrowing and Lifetimes**. 

This is how Rust handles temporary access to data, and it is the exact mechanism that allows the language to
guarantee data race freedom at compile time.

---

### Slide 17: 4.1: Borrowing — The Aliasing Rules Formalized (Speaker Notes)

**(Visual: Code blocks for Shared Borrows `&T` and Exclusive Borrows `&mut T` side-by-side with kernel-locking comparisons)**

**[Formalizing the Unspoken Rules]**
As systems and kernel developers, we all know the informal rules of memory management: if multiple threads 
are reading a buffer, no one should write to it. 

If a thread is writing to a buffer, no one else should touch it.
We implement this using locks, spinlocks, and design patterns.

Rust doesn't change these rules; it simply formalizes them in the compiler. 
**In Rust, a reference is not just a raw memory address like a C pointer it is a distinct type with strict 
metadata that the compiler tracks statically.**

**[Shared Borrows: `&T` (The Read Lock)]**

Let's look at the first category: **Shared Borrows**, denoted by `&T`.
*(Point to the `print_all` code example)*
When we pass `&ring.entries` to `print_all`, we are lending a read-only view of the data.

* You can have as many concurrent readers as you want.
* But as long as those readers exist, the compiler will completely block any attempt to modify that data.
* Once the function returns and the borrows end, the original owner (`ring`) is fully available.

**[The Data Race Formula]**
Before we look at mutable references, let's remember the mathematical definition of a data race:


Data Race = Aliasing (multiple pointers) + Mutation (writing) + No Synchronization

If we can structurally eliminate either *Aliasing* or *Mutation* at compile time, a data race becomes physically 
impossible. This is what Rust achieves.

**[Exclusive Borrows: `&mut T` (The Write Lock)]**
This brings us to **Exclusive Borrows**, denoted by `&mut T`.
*(Point to the `add_entry` code example)*

When we pass `&mut ring` to `add_entry`, we are granting a mutable reference.

This maps directly to holding a **spinlock** or a **write-lock**.
The rule here is strict: you can have exactly *one* writer, and while that writer has access,
*zero* concurrent readers are allowed anywhere else in the program.

**[The Compile-Time Law: Aliasing XOR Mutation]**
To summarize this entire system, the Rust compiler enforces a strict mathematical law: 
    **Aliasing XOR Mutation**.

At any given point in a program's execution, a memory location can have either:

1. Unlimited concurrent readers (`&T`), **OR**
2. Exactly one exclusive writer (`&mut T`).

But it can never have both. 
Because the compiler checks and proves this invariant at every single build line, data races are entirely 
eliminated before your code ever runs on hardware.

---

### Slide 18:  4.2: Lifetimes — No Reference Outlives Its Data (Speaker Notes)

**[Transition & Core Concept]**

We just established that Rust allows us to borrow data. 
But borrowing raises a fundamental question: *How does the compiler guarantee that the data being borrowed 
doesn't vanish while we are still looking at it?* 
This is where **Lifetimes** come in. 
Lifetimes are simply the compiler's mechanism for proving that every single reference remains valid for its
entire scope of use.

**[The Dangling Pointer Catch]**
Let’s look at the first code snippet to see what lifetimes prevent.
*(Point to `get_name`)*

Here, we instantiate a local string variable inside a function and try to return a reference to it. 
Because `local` is allocated within this scope, it is dropped the moment the function ends. 
Returning a reference to it would leave us with a classic dangling pointer. 
The Rust compiler analyzes this, catches the violation, and throws a compile error before you can ever ship 
the code.

To fix this when relationships are complex, we use explicit lifetime annotations, like the `'a` syntax you 
see in `first_word`. 
This isn't a runtime variable; it's a compile-time contract. 
It explicitly tells the compiler: 

*"The reference returned by this function is structurally tied to the lifespan of the input string `s`."* 
The compiler then verifies this rule at every single call site.

**[The Kernel Reality: Invalidation Before Drop]**
To see why this matters deeply to us, let's look at a concrete kernel driver example. 
Think about how many CVEs in systems software boil down to a "dangling pointer to a freed device."

*(Point to the `IrqHandler` example)*

Imagine we have an interrupt handler struct, `IrqHandler`, that needs to hold a reference to our hardware
`Device`. 
By declaring `struct IrqHandler<'dev>`, we are encoding a strict hardware invariant directly into the code. 
We are telling the compiler that this handler contains references that are bound to the lifetime of the 
device, `'dev`.

Now, look at what happens if the driver flow calls something like `device_unregister()`. 
The `Device` is dropped. 
Because of the lifetime relationship we defined, the borrow checker proves that the `IrqHandler` becomes 
statically invalid *before* that drop can occur. 
If any code tries to trigger that handler or read its data after the device is gone, the build fails.

**[The Performance Win]**
And remember the underlying theme of this presentation: this entire tracking mechanism has 
**zero runtime representation**. 
There are no reference counters ticking away in the background, and no hidden CPU cycles spent checking 
bounds. 

The lifetimes are entirely erased before code generation. 
The security is completely structural, verified 100% at compile time.

---
### Slide 19: 5.1: The Type System as a Security Tool (Speaker Notes)

**[The Evolution of Types]**

In C, the type system has a relatively simple job: it tells the compiler the size, alignment, and 
representation of a piece of data in memory. 

An `int` is 4 bytes; a pointer is 8 bytes.

In Rust, the type system is extended to act as a concurrency security tool. 
It doesn't just track *what* the data is; it tracks *how* the data is allowed to behave across 
multi-threaded and multi-core boundaries. 
It does this through two foundational concepts called **Marker Traits**: `Send` and `Sync`.

**[Two Marker Traits, Zero Runtime Cost]**

* **`Send`** means a type can be safely **moved** to another thread. The ownership changes threads entirely.
* **`Sync`** means a type can be safely **shared** between multiple threads simultaneously via immutable 
  references (`&T`).

The most critical engineering point here is that these are **marker traits**. 
They contain no code, they have no virtual method tables (vtables), and they introduce absolutely zero 
runtime checking overhead. They are purely compile-time flags used by the compiler to verify thread safety.

**[Conservative by Default]**
Rust takes a highly conservative approach to code safety. 
When you define a new structure, Rust automatically checks every single field inside it. 
Your new type is only considered `Send` or `Sync` if *every single sub-component* has already been proven 
safe. 
You don't have to remember to opt in to thread safety; the compiler forces safety by default.

Look at the examples on the slide:

* `Rc<T>` uses a standard, fast reference counter. Because modifying it from two threads simultaneously 
   would cause a data race, the compiler flags it as *not* `Send`. 
   If you try to pass it to another thread, your build fails.

* `Arc<T>` uses atomic operations for its counter. The compiler recognizes this and marks it as safe to
  share across threads.

* `Cell<T>` allows internal mutation without locking. 
  Therefore, it is strictly flagged as *not* `Sync`.

**[The Driver Win: Replacing Comments with Compiler Laws]**
Let’s look at why this matters intimately to a BSP or driver team working on multi-core silicon.

*(Point to the `PerCpuDmaStats` example)*

Imagine we have a structure tracking DMA statistics per CPU core. 
We do not want Core 0's stats being interleaved or corrupted by Core 1. 
Because this raw struct doesn't have built-in synchronization, it is *not* `Sync`. 
The compiler will strictly block any attempt to expose it as a global shared variable.

If we *do* want to share it across cores safely, we are forced to wrap it in a proper concurrent primitive 
like a `SpinLock`.


Notice the structure here: `SpinLock<PerCpuDmaStats>`. In Rust, a lock does not sit *next* to the data it 
protects; the lock **encapsulates** the data.

Think about how we do this in C today. 
We write a global variable, and right next to it, we write a comment:
`/* NOTE: Must hold dma_stats_lock before accessing this structure! */`. 

That comment is a polite request. 
If an developer, misses the comment, and accesses the variable directly without acquiring the lock, the C 
compiler will not say a word. You have just introduced a silent, intermittent multi-core race condition 
that might take weeks to root-cause.

In Rust, you physically cannot bypass the lock. The inner data is completely inaccessible until you call 
`.lock()`, which returns a lock guard. 
The type system forces you to hold the lock to even see the data. 
A missed lock isn't a runtime bug here—it's a compile error.

---
### Slide 20 : 5.2: `Option<T>` — Null Pointer Elimination (Speaker Notes)

**[The Billion-Dollar Mistake in the Kernel]**

In kernel space, it is a constant source of oopses and security flaws, especially inside driver 
initialization and device probe paths.

The fundamental problem in C is that a pointer is just a raw memory address. 
It can point to a valid structure, or it can point to `0x0`. The compiler cannot tell the difference, 
leaving it entirely up to the developer to remember the check.


**[The C Reality: Invisible Risks]**
Look at the C snippet on the slide. We call `platform_get_resource`. If that resource isn't present in the 
Device Tree, it returns `NULL`. 

If an engineer is rushing or refactoring and immediately passes `res->start` into `ioremap`, the system 
tries to read offset zero. 
The kernel will instantly trigger a `BUG()` panic or a kernel oops. 
The compiler gives zero warnings because, syntactically, accessing a struct member via a pointer is 
completely valid.

**[The Rust Alternative: Making Absence Explicit]**
Rust completely eliminates this class of bugs by removing universal null pointers from safe code. 
Instead, if a resource might be absent, the API is forced to return an `Option<Resource>` enum.

An `Option` can either be `Some(Resource)` or `None`. Because it is an enum, you physically cannot call 
`.start` or `.size()` directly on `res`. 
The type system completely isolates the underlying resource. 
The only way to get to the inner data is to explicitly unpack it, typically using a `match` block as shown 
on the right.

If the resource is there, you map it; if it's `None`, you handle the error and exit early. 
Once you pass that match block, the variable `base` is guaranteed by the compiler to be valid.

**[The Niche Optimization: Zero Runtime Cost]**

Now, performance and hardware engineers will immediately ask: *"Doesn't wrapping every reference in an enum add extra layout bytes and runtime tagging overhead?"* The answer is no, thanks to a compiler feature called the **niche optimization**. The compiler knows that a valid Rust reference can never be zero (`0x0`). Therefore, the compiler uses `0x0` internally to represent `None`, and any non-zero address to represent `Some`.

At the machine level, the binary layout of a Rust `Option<&T>` is bit-for-bit identical to a standard C nullable pointer. It occupies exactly one machine word. You get absolute compile-time enforcement of safety with exactly zero bytes of memory overhead and zero runtime cycles wasted on extra tags.

---

### Slide 21: 5.3: `Result<T, E>` — No Silent Error Drops (Speaker Notes)


**[The Hazard of Dropped Errors]**
Moving from missing data to failed operations, let's talk about error handling. 

In C, error signaling is largely an implicit protocol. 
Functions return an `int`, where a negative value indicates an error code like `-EINVAL` or `-ENOMEM`.

The core flaw in this model is that the language allows you to completely ignore that integer. 
Look at the C example: calling `pci_enable_device`, `pci_request_regions`, and `request_irq` sequentially without capturing their return values compiles flawlessly. If the first function fails, the driver blindly marches forward, attempting to request hardware regions and register interrupts on a half-dead or uninitialized device. This puts the hardware in an completely undefined state, creating silent bugs that are notoriously difficult to reproduce and debug.

**[Forced Error Propagation with `#[must_use]`]**
Rust fixes this by formalizing error handling into a concrete type: `Result<T, E>`. A function either returns `Ok(value)` or `Err(error)`.

Crucially, the `Result` type is decorated with the `#[must_use]` compiler attribute. If a function returns a `Result` and you attempt to discard it or ignore it, the compiler treats it as a **warning by default**—and in our kernel and production builds, we turn these warnings into hard compilation errors. You are structurally forced by the type system to acknowledge the failure path.

**[Demystifying the `?` Operator]**
To prevent this strictness from cluttering your code with endless nested error checks, Rust provides the question mark (`?`) operator.

It can look like syntax magic at first glance, so let’s pull back the curtain. Look at the lower code block: writing `pdev.enable()?` expands exactly to a local `match` statement. If the result is `Ok`, it extracts the inner value and execution continues. If it is an `Err`, it immediately returns from the current function and propagates that error up the call stack, automatically converting it if necessary.

**[No Hidden Mechanics]**
For low-level software, what the `?` operator *doesn't* do is just as important as what it does:

* There are **no exceptions**—meaning no hidden control flow paths.
* There is **no `longjmp**` and absolutely no complex stack unwinding runtime overhead.

The generated assembly consists of standard, highly predictable conditional branch instructions. Every single early return path remains completely explicit, local, and fully grep-able during code reviews.

**[Moving Policy into the Compiler]**
Every enterprise systems team has coding style guides that mandate checking every single return value, and we write tools like `checkpatch.pl` to flag violations after the fact. Rust takes those defensive policies out of fragile, external scripts and enforces them directly within the language grammar. You cannot accidentally cut corners on error handling.

---

### Slide 22: 5.4: Exhaustive `match` — No Silent Enum Gaps (Speaker Notes)

**(Visual: Side-by-side comparison of a C `switch` statement with a `default` catch-all vs. Rust's `match` statement showing Compiler Error E0004)**

**[The Maintenance Tax on Enums]**

As systems evolve, our hardware specifications change. Protocols get updated, and new hardware generations 
are introduced. 

In both C and Rust, we represent these architectural states using enumerations.

But when an enum expands, a massive maintenance risk is introduced. 
This slide exposes how a routine specification update can introduce a critical runtime failure in C, and 
how Rust intercepts it at build time.

**[The C Reality: The Silent Fall-Through]**

Look at the C snippet on the left. We have an enum tracking PCIe speeds, originally going up to `GEN4`. A driver function calculates the available bandwidth based on this speed. To be defensive, the developer added a `default:` case that returns `0`.

Now, imagine a year later, the specification updates and another engineer adds `GEN5` to the enum definition. They audit the code, but they miss this specific utility function in a deep subsystem. What happens?

The code compiles with absolutely zero errors. At runtime, when a Gen 5 card is inserted, the switch block fails to match, hits the `default:` escape hatch, and silently returns `0` bytes of bandwidth. This is a catastrophic, silent logical failure.

Yes, tools like GCC with `-Wall` or `sparse` *might* warn you about unhandled enums, but they only do so if you remember to use them, parse the logs, and explicitly treat those warnings as hard errors.

**[The Rust Alternative: Exhaustive Enforcement]**
Now look at the Rust example on the right. We add `Gen5` to our `PcieSpeed` enum. If we forget to add the corresponding arm to our `match` block, the compiler halts the entire build immediately with **Error E0004: non-exhaustive patterns**. It explicitly names the exact variant you forgot to handle.

Rust completely eliminates the need for an arbitrary `default:` or wildcard arm. When you expand an enum, the type system systematically alerts you to *every single location* across your entire codebase, including external crates, that must be updated to support the new hardware. Refactoring code ceases to be a guessing game; it becomes a compiler-guided checklist.

---

### Slide 23: 5.5: `unsafe` — The Auditable Escape Hatch (Speaker Notes)

**(Visual: Layout listing the 4 capabilities of `unsafe`, the `grep` command snippet, and a block diagram representing the Linux Kernel's 3-layer Rust architecture)**

**[The Reality of Low-Level Work]**
Everything we have covered so far sounds incredible for application development, but we are systems engineers. We write code that handles hardware interrupts, configures MMU tables, maps registers, and interoperates with legacy C subsystems. If the compiler strictly blocks raw pointer access and memory manipulation, how can we actually write a driver?

The answer is the `unsafe` keyword. It is the language's built-in mechanism for interfacing directly with the physical world.

**[Demystifying `unsafe`: The Four Superpowers]**
There is a massive misconception that `unsafe` disables the Rust compiler. It does not. An `unsafe { }` block grants you exactly **four specific capabilities** that the compiler cannot automatically verify for safety:

1. The ability to dereference a raw pointer (`*const T` or `*mut T`).
2. The ability to call an unsafe function—which includes all external C functions via FFI.
3. The ability to access or modify mutable global static variables.
4. The ability to manually implement an unsafe trait, like `Send` or `Sync`.

**[What `unsafe` Does NOT Do]**
It is just as critical to understand what `unsafe` does *not* do. Inside an `unsafe` block, the borrow checker is still fully active. Type checking is still active. Lifetime analysis is still fully enforced. If you attempt to violate a lifetime rule or misalign types inside an `unsafe` block, the compiler will still reject the build. You have not turned off the compiler; you have simply stepped into an auditable zone where you are taking manual responsibility for raw memory safety invariants.

**[The Audit Argument]**
This creates a massive paradigm shift for code reviews and security audits.

Look at the `grep` command on the slide. If a safety-critical bug or memory corruption issue occurs in a driver subsystem, a code auditor can run a single `grep` command to isolate the entire attack surface. Every line of code capable of corrupting memory is explicitly wrapped in the word `unsafe`.

In a traditional C codebase, every single line of code is part of the audit surface. There is no equivalent query to isolate memory-unsafe operations because any pointer access anywhere can cause undefined behavior.

**[The Kernel's Three-Layer Architecture]**
The modern approach to Rust in the kernel exploits this isolation through a clean, three-layer architecture:

* At the very bottom, we have `rust/bindings/`. This layer directly interfaces with the core C kernel headers. It is full of `unsafe` calls, but it is automatically generated by tools like `bindgen`, audited once, and rarely touched.
* In the middle, we have `rust/kernel/`. This layer takes those raw C bindings and wraps them in safe, idiomatic Rust abstractions. This is where the heavy engineering happens to ensure that lifetimes and ownership match the kernel's design.
* At the top layer, we have `drivers/your_ip/`. This is where the actual device driver code lives. Because it consumes the safe kernel abstractions, it can be written in **100% pure, safe Rust with zero `unsafe` blocks**.

This means your day-to-day driver logic is completely covered by compile-time proofs against use-after-free, data races, and null pointer exceptions. If a crash or memory bug happens, you don't waste time debugging your driver logic; you check the centralized abstraction layer.

--- 
### Slide 24: 6.0: Compiler Checks — Beyond Memory Safety (Speaker Notes)

We just talked about how Rust protects memory. Now, let us look at the bigger picture.


The Rust compiler does not just check memory. It also checks types, math errors, and code logic. It does all of this at the same time, during every single build.

---

### Slide 25: 6.1: What the Rust Compiler Verifies at Every Build (Speaker Notes)

In Rust, the compiler gives you automatic safety. 
It checks your code completely every time you compile.

Let us review what the compiler guarantees:

* **Memory Safety:** No use-after-free bugs. No data races between threads. No null pointers.
* **Initialization:** You cannot read a variable by mistake before setting its value. The compiler stops you.
* **Math Errors:** In debug mode, if an integer overflows, the program stops safely. It does not create hidden data errors.
* **Complete Logic:** As we saw with the PCIe speed example, `match` blocks must cover every choice. If you add a new option, the compiler tells you exactly where to fix your code.
* **Error Checking:** If a function returns a `Result` error code, you must handle it. If you ignore it, the compiler gives you a warning or an error. You cannot drop errors silently.

**[Comparison with C Tools]**
In C, you can find these bugs too. But you need many separate tools to do it.

Here is the problem in C:

* These tools are **optional**.
* They are separate from each other.
* They do not check 100% of your code paths.

Rust replaces many of these separate tools with **one single compiler**. 
The safety rules are part of the language. 
Every engineer must follow them, and every build is automatically verified.

---

### Slide 26: 7.0: The Rust Ecosystem (Speaker Notes)

Now, let us look at the tools and the community.

A good language needs good tools. 
Rust does not just give you a compiler. 
It gives you a complete development environment.

---

### Slide 27: 7.1: Tooling and the Modern Ecosystem (Speaker Notes)

**[All Tools in One Package]**
In C, every team must choose their own tools. One team uses Make, another uses CMake. One team uses Doxygen, another uses something else.

Rust changes this. When you install Rust, you get all standard tools automatically. 
They are official, and they work together perfectly.

Let us look at the main tools in the table:

| Tool | Role | C Equivalent |
| --- | --- | --- |
| **`cargo`** | Builds code, runs tests, manages external libraries | Make / CMake / `pkg-config` |
| **`rustfmt`** | Formats your code automatically | `clang-format` |
| **`clippy`** | Finds bugs and code quality issues | Coverity / `sparse` |
| **`rustdoc`** | Generates documentation from comments | Doxygen |
| **`cargo-expand`** | Shows code after macro expansion | `gcc -E` |
| **`rust-analyzer`** | Provides autocomplete and inline errors inside your IDE | VS Code / Vim extension |

Because every Rust developer uses these exact same tools, it is very easy to share code and onboard new engineers.

**[Rust is Reshaping Modern Software]**
Rust is no longer just a niche language for small projects. It is changing the entire software industry.

Here are real-world examples:

* **The Tools We Use:** This presentation was made using **Typst**, a fast document generator written completely in Rust. Popular command-line tools like `ripgrep` (a faster `grep`) and `fd` (a faster `find`) are also written in Rust.
* **Cloud Infrastructure:** **AWS Firecracker** powers millions of cloud containers, and **Cloudflare Pingora** handles 1 trillion internet requests every day. Both are built on Rust for speed and safety.
* **Mobile Devices:** **Android 16** uses Linux Kernel 6.12 and runs the core memory allocator (`ashmem`) using Rust. It is already running on millions of production devices worldwide.

The main takeaway here is clear: Rust has moved past the experimental phase. It is now the standard choice for building fast, safe, and modern infrastructure.


---

### Slide 28: eBPF Quick Refresher (Speaker Notes)

In the second part of the presentation we will talk about eBPF programming using Rust.

Before that we will quickly review of how eBPF works before we look at the Rust tools.
This will not be covering what eBPF is and what types of tooling is used to generate bytecode and load
the programs for tracing and observability as they have been covered in earlier presentations.

---

### Slide 29: What is eBPF? (Speaker Notes)

**(Visual: The four-step diagram showing Write, Verify, JIT, and Attach, alongside the table of hook types)**

**[The Core Model]**

- In simple terms, eBPF lets us run safe code inside the Linux kernel. We do not need to modify the
  kernel source code. We do not need to load a traditional kernel module. And we do not need to reboot
  the system.

- The code connects to specific event hooks inside the kernel and runs instantly when those events
  happen.

**[The Four-Step Lifecycle]**
Every eBPF program follows a strict four-step process:

1. **Write:** We write our program in a high-level language like C or Rust. Then we compile it into
   standard eBPF bytecode.
2. **Verify:** We load the bytecode into the kernel. The kernel verifier checks the code completely. It
   checks for safe loops, valid memory limits, and correct types.
3. **JIT (Just-In-Time):** If the code is safe, the kernel translates the bytecode into native machine
   code. There is no interpreter slowdown. The code runs at native hardware speed.
4. **Attach:** We connect the code to a hook point. When that hardware or software event occurs, our code
   runs.

**[The Verifier Guarantee]**
- The verifier does not guess safety. It uses mathematical proof. If the verifier accepts the bytecode,
  the program **cannot** crash the operating system, it **cannot** lock up in an infinite loop, and it
  **cannot** read secret memory out of bounds.

**[Common Hook Types]** The table shows the exact hooks our team uses for development:

* We use **`kprobe`** to look at any internal kernel function.
* We use **`tp_btf`** for typed tracepoints because they work well with modern compile-once
  run-everywhere (CO-RE) systems.
* We use **`xdp`** for network packet filtering. This runs directly on the network interface card driver
  before the main network stack even sees the packet. This is what we use to block network attacks
  quickly.

---
### Slide 30: eBPF Maps — The Data Bridge (Speaker Notes)

**[How Maps Work]**
- An eBPF program inside the kernel cannot perform standard Input/Output. It cannot write directly to
  files or send network data on its own. Instead, it uses **eBPF maps** to talk to the outside world.

- Maps are pieces of shared memory. The user-space loader creates the maps first, before attaching the
  eBPF program. After that, both the kernel code and the user-space program read and write data through
  standard Linux file descriptors.

**[Common Map Types]** The table shows the maps we use most often:

* We use **`HASH`** maps for looking up key-value pairs.
* We use **`PERCPU_ARRAY`** for statistics. It creates a separate array for each CPU core, which means it
  is lock-free and has very high performance.
* We use **`LRU_HASH`** when we need to track network connections without running out of memory.

**[Why We Choose Ring Buffer]** Let us focus on the **Ring Buffer** (`RINGBUF`). It was added in Linux
5.8. For all our new projects, we should always choose `RINGBUF` instead of the older `PERF_EVENT_ARRAY`.

Here is why:

* **Memory Efficiency:** It handles variable-length records. We do not need to use fixed-size structures,
  so we do not waste memory bytes.
* **Rust Integration:** It works perfectly with standard asynchronous tools like Tokio in Rust. Aya turns
  the ring buffer into an `AsyncFd`, so your user-space program can read events efficiently without
  locking up a CPU core.
* **Easy Monitoring:** If the kernel generates events too fast and data is lost, `RINGBUF` tracks the
  dropped events and shows the number directly to user space.

Look at the code example at the bottom. This is how we write a ring buffer in Aya. We use the `#[map]`
attribute and define a static variable with a size—here, 4 Megabytes. It is clean, explicit, and easy to
read.

---
### Slide 32: eBPF Framework Landscape (Speaker Notes)


**[Introduction]**
- Let us look at how eBPF tools have changed over time. There are three main generations of eBPF
  development tools.

**[Generation 1: BCC and bpftrace]**
- Generation 1 uses BCC and `bpftrace`. BCC compiles the eBPF C code directly on the target device when
  you run the script. This means you must install the full Clang and LLVM compiler on your production
  system.

- Tools like `bpftrace` are excellent for quick debugging on a development laptop. But for embedded
  devices, this approach does not work. A compiler toolchain takes up more than 100 Megabytes of
  storage space. Also, the code depends on exact kernel header versions, so it is not portable. BCC is
  a development tool, not a deployment tool.

**[Generation 2: libbpf + CO-RE]**
- Generation 2 introduced `libbpf` and CO-RE, which stands for Compile Once, Run Everywhere. With this
  method, you compile the eBPF code ahead of time on your development laptop.

- The compiled ELF file includes BTF type information. When you load the program, `libbpf` reads the
  running kernel's BTF data and adjusts the memory offsets automatically. This allows you to ship a
  very small pre-compiled object file and a small shared library (`.so`). You no longer need a compiler
  on your embedded target.

**[Generation 3: Language-Native Frameworks]**
- Generation 3 brings first-class language integration. Instead of writing a loader in C and binding it
  to other languages, we use frameworks built completely inside modern languages like Rust and Go.

* **Aya** is written in **pure Rust**. It does not use the C `libbpf` library at all. It handles
  everything natively through Rust.
* **cilium/ebpf** is written in pure Go for the user-space side, but still uses Clang to compile the
  kernel side.
* **libbpf-rs** provides Rust bindings that talk to the traditional C `libbpf` library.

Our focus is on Aya because it gives us a single, safe, unified toolchain using pure Rust from top to
bottom.

---
### Slide 33: What Popular Projects Use — And Why It Matters for Your Team (Speaker Notes)

**[The Big Industry Trend]**
- Let us look at how the largest software companies use eBPF today. This will help us understand why
  choosing the right framework is important for our own team.

**[Cilium: The Industry Standard]**
- Cilium is the most popular project for production eBPF in large data centers. It handles network
  traffic and security at a massive scale.

- Cilium uses C for its kernel code, but it uses Go for its user-space loader. Crucially, Cilium does
  **not** use the traditional C `libbpf.so` library at runtime. Instead, they built their own pure Go
  library (`cilium/ebpf`) to load the bytecode and manage maps.

- In 2025, engineers even proved that an eBPF kernel program written in Rust using Aya can work perfectly
  with Cilium’s Go loader.

- The main lesson for our team is this: the industry is moving away from shared C libraries like
  `libbpf.so`. Modern systems prefer language-native loaders. Cilium chose Go for this purpose. For our
  team, **Aya is the Rust equivalent**.

**[Aya in Real-World Production]** The table shows other major infrastructure projects that use the Rust
and Aya stack today:

* **Red Hat bpfman:** This tool manages the lifecycle of eBPF programs on a system, acting like `systemd`
  but for BPF code. It is built completely with Rust and Aya.
* **Deepfence ebpfguard:** This tool checks security policies inside the kernel using Linux Security
  Modules (LSM). By using Aya, they wrote the entire system in Rust with no C code required.
* **K8s Blixt:** A high-performance network load balancer that runs its fast data path in Rust using XDP.

**[Why These Projects Chose Aya]** All of these modern projects chose Aya for the exact same reasons:

1. **Unified Safety:** They wanted type safety that spans across both the kernel code and the user-space
code.
2. **Simple Deployment:** They wanted a single binary file that they can deploy easily, without worrying
about external runtime C library dependencies.

Older tools like Tracee and Falco still use the traditional C and `libbpf` design. But new infrastructure
projects are choosing Rust and Aya for safer and cleaner operations.

---

### Slide 34: libbpf + CO-RE — The Reference Workflow (Speaker Notes)

**[Transition]**
Let us look closer at the modern eBPF workflow. We will focus on CO-RE, which means Compile Once, Run Everywhere.

This part is more specific to our current approach to eBPF

---

### Slide 35: Why CO-RE Matters for BSP Teams (Speaker Notes)

**[The Problem: Different Kernel Versions]**
Typically our development spans different HW designs running OWRT, Yocto, Android. These devices run
different Linux kernel versions, like 5.15, 6.1, or 6.6. Each customer might also add their own kernel
patches.

Inside the Linux kernel source code, structures change between versions. Look at the example on the slide
for `struct task_struct`:

* In Kernel 5.15, the process ID (`pid`) is at memory offset `0x2C8`.
* In Kernel 6.1, it moves to offset `0x2D4`.
* In Kernel 6.6, it moves to offset `0x2E0`.

If a BPF program uses a fixed memory number to read `task->pid`, it will read the wrong memory on a
different kernel version.

Before CO-RE, you had two choices to fix this: you had to build a separate eBPF binary for every single
kernel version, or you had to install a compiler on the target device to build the code at runtime. Both
choices are very difficult for embedded systems.

**[The Solution: How CO-RE Works]** CO-RE solves this problem completely.

1. **At Build Time:** You compile your BPF code just once on your development laptop using Clang or Rust.
The compiler creates the bytecode and adds special "relocation records" inside a section called `.BTF` in
the ELF file. This section records which structure fields your code wants to read.
2. **At Load Time:** You copy that single ELF file to the target device. When your loader program (like
Aya) starts, it reads the running kernel's own layout info from the file `/sys/kernel/btf/vmlinux`.
3. **The Fix:** Aya automatically adjusts the memory offsets in the bytecode to match the running kernel
exactly.

**[Target Requirements]** To use this feature, the target kernel must be compiled with the option
`CONFIG_DEBUG_INFO_BTF=y`.

Today, this option is enabled by default in all standard Linux distributions and all Android Generic
Kernel Images (GKI) starting from Android 12. For Android BSP deployment, this means one single compiled
eBPF file runs perfectly on all devices, no matter the phone manufacturer or kernel changes. You do not
need multiple sets of kernel headers, and you do not need to recompile code on the device.

--- 

