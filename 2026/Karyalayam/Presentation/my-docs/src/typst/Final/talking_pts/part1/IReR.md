### Slide 1: Introduction to Rust (Speaker Notes)

- **[Opening]** 

Good afternoon,  Today’s topic is **Introduction to Rust and eBPF Programming with Rust**.

- Before we begin to talk about Rust, it's worth to recognizing that modern computing infrastructure is 
  largely built on the foundation of **C** language.

- For more than 50 years, **C** has been the language of operating systems, device drivers, firmware, 
  networking stacks, and embedded space.
  **C** offers 
    - performance, 
    - portability, and 
    - direct hardware access 

  all of which makes it the most successful and widely used programming language.

- This presentation is not about why **C** is bad, nor is it about replacing decades of successful 
  engineering practices.

- Instead, it is about understanding the evolving systems programming landscape and why Rust has emerged as
  one of the technologies of interest from operating system vendors, silicon companies,cloud providers, and
  the open-source community.

**[ Why the Industry is Looking for Something New ]**

- Will also look at how over the time when software systems grow larger and are more connected, this
  brings changes in expectations.  
- And with these additional demands, today systems are expected to provide performance and reliability, and 
  also guarantee's strong security guarantees. 
- With growing codebases, distributed teams, and complex software lifecycles  all of which bring in 
  different sets of challenges.

- When we look across the industry, a major percentage of security vulnerabilities continue to  originate
  from memory-safety issues such as:

    - Buffer overflows
    - Use-after-free bugs
    - Null pointer dereferences
    - Data races
    - Lifetime and ownership errors

- While these bugs aren't for poor engineering, they are often the consequence of building highly complex
  systems using languages that force developers to handle every single detail perfectly. 

- Also from Industry there is a common question that many organizations are now asking:
    - Can we maintain the performance and control of low-level programming 
      while reducing entire classes of bugs before the code ever runs?

[The Rise of Rust]

- This is where Rust comes, It offers one such attempt to answer that question. 

- Though Rust is relatively young compared to **C**, it has gained industry momentum and has consistently 
  ranked among the most admired programming languages in developer surveys.(stackoverflow devel surveys)

- What makes Rust particularly interesting is that it targets the same problem domain as **C** and **C++**
  systems programming while it taking a different approach to memory management and concurrency safety.

- Unlike language such as java/py/go  which relying primarily on runtime garbage collection or developer
  discipline alone, Rust attempts to move many correctness checks into the compiler.

- As a result we get a language that aims to provide:
    - Low-level control
    - Predictable performance
    - Memory safety
    - Concurrency safety
  and more with out the use of a garbage collector.

[Setting Expectations] ( Skip this part while speaking )

- So Today's session is not intended to be a debate between **C** and Rust.

- And the good news is most systems software for the foreseeable future will continue to involve in **C** and
  many successful projects will remain C-based for years to come.

- Instead, we move our goal in understand the design principles behind Rust,
  And why major projects such as the Linux kernel have begun adopting it, and where it may fit alongside 
  existing systems programming practices.

- From there, we'll explore Rust from a systems programming perspective and look at how it is increasingly
  being used in kernel and eBPF development.

- Its also important to note that introducing any new language into use with existing systems has its own 
  pros and cons. And early study would help us better adapt to the fast changing in this domain.

---

### Slide 2:  ( Disclaimer:)


Disclaimer about the intent of this presentation.

Would like to state again the goal for today, is not to start a language war or argue that one language
should completely replace another.

Rather, focus is to discuss some of the evolving changes happening in the systems programming space:
especially in areas closely related to what many of us work on daily.

**C** remains one of the most important and successful programming lang ever created, and it continues to be
foundational to operating systems and embedded development today 

And Rust should not be viewed as a replacement for **C**, but rather as another tool in the systems 
programming toolbox.

Rather we should view this through the lens of engineering and evaluation to points like:

    * why the industry is paying attention to it,
    * what problems it attempts to solve,
    * whether it provides practical value for low-level development,
    * => whether Rust can improve: such as memory safety, reliability, and long-term maintainability.

Discussions around programming languages especially in Linux kernel and systems communities, can become 
very opinionated because developers naturally build strong trust in the tools they have relied on for decades.

Most importantly I would also like to state clearly:

- I am not presenting myself as a Rust expert.

- Like most of us in the industry, Rust caught my attention with its adoption into Linux kernel from early 
  experimental effort into a supported and actively maintained direction as of 2025 December.

- I am still exploring the technology myself, and today’s presentation is intended to shared my learning 
  experience.

- I will do my best to answer questions to the best of my knowledge and practical understanding.

--- 

### Slide 3: ( Overview ):


We divide today’s talk into two sections.

- In the first section: 
    We will introduce Rust from a systems programming perspective and look at some of the core concepts 
    that make low-level software development relevant in Rust.

This includes topics such as:

* zero-cost abstractions,
* ownership and borrowing,
* deterministic memory management,
* memory layout control,
* and concurrency safety.

With limited time we will not be covering the entire language, but to understand the design philosophy
behind Rust and how it attempts to provide both performance and safety without sacrificing low-level
control.

- In the second section, we will move into eBPF programming with Rust.

We will explore a Rust based eBPF framework called Aya, which is a modern pure-Rust based eBPF framework
which provides an alternative development approach alongside traditional eBPF toolchains such as `libbpf`
and `clang`/`LLVM` based workflows.

Finally, we will go through a small demo project to demonstrate how a user-space Rust application can
interact with kernel-space eBPF programs, exchange data efficiently, and build observability or tracing
pipelines with minimal overhead and latency.

---

### Slide 4: ( Introduction to Rust ) ( systems programming perspective )


**[Transition & Introduction]**

In this section, Fist we will see if Rust fits to be used in systems programming languages. 
And also examine, important properties behind its growing adoption and what it actually guarantees: 
compile-time correctness, predictable performance, and maintainable low-level abstractions.


---

### Slide 5: Evaluating Rust for Systems Programming:

**[The Baseline Criteria]**

To see if Rust is fit to be used in systems programming zone: 
The First baseline criteria is to check the requirements of systems software and essential checklist 
are required.

We define
Systems software is one that controls HW and mediates between the HW and every thing else around it, and
this compliance are characterized with some constrains: Such as 

1. Systems Language should provide a **Direct HW access:** example it should allow to map MMIO registers, 
   handle CPU-specific instructions, control precise memory layouts, and interface directly with silicon.

   **Zero-cost abstractions:** If we use a higher-level abstraction, it cannot introduce hidden runtime
   overhead. The compiled machine code must be as efficient as manual, low-level implementation.

2. **Deterministic memory management:** To provide deterministic performance the language should not use 
   garbage collector and this is the key requirement for kernels, BSPs, and drivers.
   We must know exactly when memory is allocated and precisely when it is freed to ensure predictable
   execution latency.

3. When bugs occur the effect should be contained ( to one user or limited scope), This demands the
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

- `unsaf`e (The Auditable Escape Hatch): Rust does not stop you from low-level operations like 
  dereferencing raw memory-mapped pointers or interacting with hardware registers. 
  It simply requires you to wrap these operations in an unsafe block, this is to tells the compiler: 
  "I know the hardware layout here; stop checking this specific block." 

  This way we isolate the critical sections of codebase into an easily auditable map where unsafe boundaries
  are explicitly defined.

- `asm!`: Inline Assembly (asm!) Rust has first-class support for architecture-specific instructions. 
  Say we need to execute a cache invalidation pipeline, barrier instructions, or change CPU privilege 
  levels, we drop into inline assembly exactly like we do in C.

- Binary Compatibility (#[repr(C)]): We cannot rewrite entire codebases overnight. 
  Rust uses the #[repr(C)] attribute to guarantee that a Rust data structure matches the exact memory layout,
  padding, and alignment of a standard **C** struct. 
  This ensures a seamless FFI execution when interfacing with existing **C** libraries, legacy driver 
  components.

**[The Landscape Tradeoffs]**
When we map C, C++, and Rust against these requirements, the engineering tradeoffs become very clear:

* **Memory & Concurrency Safety:** 
    - **C** gives us absolute control but zero built-in safety guarantees;
      correctness relies entirely on our discipline and code reviews. 
    - **C++** introduces RAII, which helps, but tracking ownership across complex, multi-threaded codebases 
      remains highly manual. 
    - Rust moves both memory and concurrency safety entirely into the **compile-time layer**.

Rust is the first language that guarantees memory-safety with out GC and has a verified typesystem.

* **The Learning Curve:** 

    The most important trade-off we face with Rust is its steep learning curve.
    Rust's compiler does not negotiate; it forces you to resolve ownership and lifetime ambiguities before 
    a single line of machine code is generated. 

The tradeoff of these langaguages when compared with :
* **Complexity vs. Abstraction:**  **C** is simple but lacks high-level abstraction power, requiring significant:
    - manual architecture and boilerplate as codebases scale. 
    - **C++** offers huge abstraction power but at the cost of immense language complexity. 
    - Rust targets the same high abstraction level as **C++** but uses its type system to enforce structural 
      correctness.

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

- Languages like **C** intentionally prioritize unrestricted control and performance over safety guarantees.
- **C** gives us absolute, direct access to memory, which is exactly what we need for hardware. 
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

( - Reference counting: (swift, python) cleanup happens automatically and immediate when a
piece of data's rc hits zero. To do this language injects hidden code around variables 
  - Rust’s compiler strictly enforces thread safety. A standard `Rc` pointer cannot be sent across threads,
    meaning it uses blazing-fast, non-atomic math. 
    If you want thread-safe reference counting, you must explicitly use `Arc` (Atomic Reference Counted). 
    Rust forces you to make the conscious choice between speed and thread safety, rather than making a 
    safe-but-slow assumption for you behind the scenes.
),

**The memory model maps exactly to what you already know in C:**

* **Stack allocation:** Has zero overhead. It is identical to declaring an `int x;` in C.
* **Heap allocation:** Is entirely explicit and backed by whatever custom allocator you provide.
* **Cleanup:** When a variable goes out of scope, the compiler inserts the cleanup code at a *statically known point* during compilation. It does not happen unpredictably at runtime.

Because of this, Rust is safe to run in the most heavily constrained environments we deal with. You can run Rust in an Interrupt Service Routine (ISR), in early-boot firmware before the MMU is even enabled, or on a bare-metal microcontroller with just 16 Kilobytes of RAM.

And critically for build integration: the output is a standard ELF binary. A Rust kernel module compiles to a standard `.ko` file. Tools like `insmod`, `lsmod`, and `rmmod` cannot tell the difference—to the system, it looks and executes exactly like a **C** object file.

**[Property 2: Unrestricted Hardware Access]**
The second property is direct hardware access. A major fear when adopting a "safe" language is that it will
hide the hardware behind restrictive abstractions. 
Rust doesn't do this.

It can do everything **C** can do at the silicon level.

*(Point to the code blocks on the slide)*

* **Memory-Mapped I/O:** 
    If you need to hit a HW control register, you can do a volatile write exactly like casting a ptr in C.

* **Inline Assembly:** 
    Rust uses `asm!` macro instead of GCC ":" based syntax.
    For example in embedded **C** writing data synchronization barriers , mainly when dealing with DMA,
    Context switching, or peripheral registers on ARM, in **C** it of the form 
    `__asm__ __volatile__("dsb sy" : : : "memory");`
    Rust handles the exact arch instruction using `asm!` macro:
    - `use core::arch::asm;` : Its from Core and not std => its fully available for #![no_std] => can
      be used with bare-metal firmware, rtos kernels, and bootloaders.
    - "dsb sy": This is ARM Data synchronization barrier, One massive quality-of-life upgrade in
      Rust: it defaults to Intel/ARM standard syntax, not the clunky AT&T percent-sign syntax (%%)
      we often wrestled with in GCC."

    If you need to execute an architecture-specific data synchronization barrier ( enforce ordering and
    completion of memory operations (ARM) ) like the `dsb` instruction shown here.
    Rust has direct support for inline assembly that mirrors GNU **C** syntax.

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

**[The **C++** Connection]**
The third property is something many of you who write **C++** will be very familiar with: zero-cost abstractions. 

- Rust fully adopts Stroustrup’s principle: 
    *"What you don't use, you don't pay for. And what you do use, you couldn't hand-code any better."* 

  Rust allows to write highly expressive, modern-looking code, but it guarantees that this code compiles 
  down to the exact same machine instructions as manual C. 

  We don't have to take the compiler's word for this we can verify it line-by-line on Compiler Explorer.
  (Godbolt.org) 

For comparison I have posted the assembly generated by Rust and **C** of a function that squares a number.
- We see the rust part of assembly is longer then **C** which in the middle. 
- This is because of rust's default safety guarantees for performing overflow check in *debug* builds. 
- In the unoptimized Rust snippet `seto al` checks if the multiplication overflowed 
- `jo .LBB0_2` jumps to the panicking routine if a overflow occurred. 

- When we open the optimization in **C** and Rust ( or use --release build) we will see the assembly generated
  have almost same number of instructs. ( -O2 or -C opt-level=2 or --release ( which is -C opt-level=3)  )

- In standard **C** singed Int overflow is UB, the compiler assumes it will never happen, which is why GCC does
  not generate any safety check. 
- To make **C** behave like Rust code ( checking overflow and terminating) we use `__builtin_mul_overflow` or
  compiler flags. 

- Note: What I notice is zero-cost abstraction means you dont pay performance penalty for using higher-level
  features ( like iterators, closures or traits ) compared to writing the equivalent code by hand in
  low-level style.

---
### Slide ( continuation )
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


//The code blocks show **C** `restrict` problem vs. the Rust exclusive borrow 

**[The Performance Surprise]**

When we talk about Rust in systems programming, the conversation almost always focuses on memory safety. 
But this slide highlights something that is frequently overlooked: 
    the performance *advantage* Rust often has over C.

**[The **C** Compiler's Dilemma]**

Let’s look at a very standard **C** function: processing two byte arrays.
*(Point to the **C** code)*
 According to C's pointer aliasing rules, the compiler must assume that two `uint8_t` `src` and `dst` 
 pointers might  overlap in memory. 

 Because of this, the **C** compiler is forced to be defensive and generates less optimized code.

**[The **C** Workaround: Promises, not Proofs]**

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
When we say `let s2 = s1;`, a **C** developer might think we are just copying a pointer. 
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
inserts the call to `Drop::drop()`. It acts exactly like **C++** RAII, but it is deeply woven into the language 
rules. There is no `free()` for the developer to forget, and no silent leak is possible.


**[The Big Shift]**
The ultimate takeaway here is that ownership completely shifts memory safety. 
It takes what has historically been a stressful runtime discipline, relying on developers to never make a 
mistake and turns it into a compile-time verification problem solved entirely by the type system.

---
### Slide 14: 3.2: Ownership vs. **C** — Eliminating Use-After-Free (Speaker Notes)


**[Contextualizing the Threat]**

Next we look at real-world application of ownership.
The Use-After-Free (UAF), is consistently one of the most common and dangerous kernel CVE classes.

The core point to make here is that : 

**this is not a bug detection problem; it is a program expressiveness problem.** 

In standard C, you simply do not have a way to express to the compiler that a pointer has become invalid 
after a certain point in time.

**[The **C** Reality]**
Look at the **C** snippet on the left. This is a very typical pattern we see in drivers:

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


**[The **C** Reality: The `goto` Maintenance Tax]**

Let’s walk through the **C** snippet.

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
**In Rust, a reference is not just a raw memory address like a **C** pointer it is a distinct type with strict 
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

Think about how we do this in **C** today. 
We write a global variable, and right next to it, we write a comment:
`/* NOTE: Must hold dma_stats_lock before accessing this structure! */`. 

That comment is a polite request. 
If an developer, misses the comment, and accesses the variable directly without acquiring the lock, the **C** 
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

The fundamental problem in **C** is that a pointer is just a raw memory address. 
It can point to a valid structure, or it can point to `0x0`. The compiler cannot tell the difference, 
leaving it entirely up to the developer to remember the check.


**[The **C** Reality: Invisible Risks]**
Look at the **C** snippet on the slide. We call `platform_get_resource`. If that resource isn't present in the 
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

At the machine level, the binary layout of a Rust `Option<&T>` is bit-for-bit identical to a standard **C** nullable pointer. It occupies exactly one machine word. You get absolute compile-time enforcement of safety with exactly zero bytes of memory overhead and zero runtime cycles wasted on extra tags.

---

### Slide 21: 5.3: `Result<T, E>` — No Silent Error Drops (Speaker Notes)


**[The Hazard of Dropped Errors]**
Moving from missing data to failed operations, let's talk about error handling. 

In C, error signaling is largely an implicit protocol. 
Functions return an `int`, where a negative value indicates an error code like `-EINVAL` or `-ENOMEM`.

The core flaw in this model is that the language allows you to completely ignore that integer. 
Look at the **C** example: calling `pci_enable_device`, `pci_request_regions`, and `request_irq` sequentially without capturing their return values compiles flawlessly. If the first function fails, the driver blindly marches forward, attempting to request hardware regions and register interrupts on a half-dead or uninitialized device. This puts the hardware in an completely undefined state, creating silent bugs that are notoriously difficult to reproduce and debug.

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

**(Visual: Side-by-side comparison of a **C** `switch` statement with a `default` catch-all vs. Rust's `match` statement showing Compiler Error E0004)**

**[The Maintenance Tax on Enums]**

As systems evolve, our hardware specifications change. Protocols get updated, and new hardware generations 
are introduced. 

In both **C** and Rust, we represent these architectural states using enumerations.

But when an enum expands, a massive maintenance risk is introduced. 
This slide exposes how a routine specification update can introduce a critical runtime failure in C, and 
how Rust intercepts it at build time.

**[The **C** Reality: The Silent Fall-Through]**

Look at the **C** snippet on the left. We have an enum tracking PCIe speeds, originally going up to `GEN4`. A driver function calculates the available bandwidth based on this speed. To be defensive, the developer added a `default:` case that returns `0`.

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
Everything we have covered so far sounds incredible for application development, but we are systems engineers. We write code that handles hardware interrupts, configures MMU tables, maps registers, and interoperates with legacy **C** subsystems. If the compiler strictly blocks raw pointer access and memory manipulation, how can we actually write a driver?

The answer is the `unsafe` keyword. It is the language's built-in mechanism for interfacing directly with the physical world.

**[Demystifying `unsafe`: The Four Superpowers]**
There is a massive misconception that `unsafe` disables the Rust compiler. It does not. An `unsafe { }` block grants you exactly **four specific capabilities** that the compiler cannot automatically verify for safety:

1. The ability to dereference a raw pointer (`*const T` or `*mut T`).
2. The ability to call an unsafe function—which includes all external **C** functions via FFI.
3. The ability to access or modify mutable global static variables.
4. The ability to manually implement an unsafe trait, like `Send` or `Sync`.

**[What `unsafe` Does NOT Do]**
It is just as critical to understand what `unsafe` does *not* do. Inside an `unsafe` block, the borrow checker is still fully active. Type checking is still active. Lifetime analysis is still fully enforced. If you attempt to violate a lifetime rule or misalign types inside an `unsafe` block, the compiler will still reject the build. You have not turned off the compiler; you have simply stepped into an auditable zone where you are taking manual responsibility for raw memory safety invariants.

**[The Audit Argument]**
This creates a massive paradigm shift for code reviews and security audits.

Look at the `grep` command on the slide. If a safety-critical bug or memory corruption issue occurs in a driver subsystem, a code auditor can run a single `grep` command to isolate the entire attack surface. Every line of code capable of corrupting memory is explicitly wrapped in the word `unsafe`.

In a traditional **C** codebase, every single line of code is part of the audit surface. There is no equivalent query to isolate memory-unsafe operations because any pointer access anywhere can cause undefined behavior.

**[The Kernel's Three-Layer Architecture]**
The modern approach to Rust in the kernel exploits this isolation through a clean, three-layer architecture:

* At the very bottom, we have `rust/bindings/`. This layer directly interfaces with the core **C** kernel headers. It is full of `unsafe` calls, but it is automatically generated by tools like `bindgen`, audited once, and rarely touched.
* In the middle, we have `rust/kernel/`. This layer takes those raw **C** bindings and wraps them in safe, idiomatic Rust abstractions. This is where the heavy engineering happens to ensure that lifetimes and ownership match the kernel's design.
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

**[Comparison with **C** Tools]**
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

| Tool | Role | **C** Equivalent |
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

1. **Write:** We write our program in a high-level language like **C** or Rust. Then we compile it into
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
- Generation 1 uses BCC and `bpftrace`. BCC compiles the eBPF **C** code directly on the target device when
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
- Generation 3 brings first-class language integration. Instead of writing a loader in **C** and binding it
  to other languages, we use frameworks built completely inside modern languages like Rust and Go.

* **Aya** is written in **pure Rust**. It does not use the **C** `libbpf` library at all. It handles
  everything natively through Rust.
* **cilium/ebpf** is written in pure Go for the user-space side, but still uses Clang to compile the
  kernel side.
* **libbpf-rs** provides Rust bindings that talk to the traditional **C** `libbpf` library.

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

- Cilium uses **C** for its kernel code, but it uses Go for its user-space loader. Crucially, Cilium does
  **not** use the traditional **C** `libbpf.so` library at runtime. Instead, they built their own pure Go
  library (`cilium/ebpf`) to load the bytecode and manage maps.

- In 2025, engineers even proved that an eBPF kernel program written in Rust using Aya can work perfectly
  with Cilium’s Go loader.

- The main lesson for our team is this: the industry is moving away from shared **C** libraries like
  `libbpf.so`. Modern systems prefer language-native loaders. Cilium chose Go for this purpose. For our
  team, **Aya is the Rust equivalent**.

**[Aya in Real-World Production]** The table shows other major infrastructure projects that use the Rust
and Aya stack today:

* **Red Hat bpfman:** This tool manages the lifecycle of eBPF programs on a system, acting like `systemd`
  but for BPF code. It is built completely with Rust and Aya.
* **Deepfence ebpfguard:** This tool checks security policies inside the kernel using Linux Security
  Modules (LSM). By using Aya, they wrote the entire system in Rust with no **C** code required.
* **K8s Blixt:** A high-performance network load balancer that runs its fast data path in Rust using XDP.

**[Why These Projects Chose Aya]** All of these modern projects chose Aya for the exact same reasons:

1. **Unified Safety:** They wanted type safety that spans across both the kernel code and the user-space
code.
2. **Simple Deployment:** They wanted a single binary file that they can deploy easily, without worrying
about external runtime **C** library dependencies.

Older tools like Tracee and Falco still use the traditional **C** and `libbpf` design. But new infrastructure
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

The image is clear. This slide details the traditional C-based `libbpf` workflow to show the five stages and the target dependencies.

Here are the speaker notes for this slide, using simple, direct English tailored for your audience:

---

### Slide 36: 6.2: libbpf Workflow — The Five Stages (Speaker Notes)


**[The Traditional 5-Stage Process]**

- To understand why we use Aya, we must first look at the traditional **C** workflow using `libbpf`. 
- This process has five distinct stages:

1. **Write:** You write your kernel BPF program in C. You must use `bpftool` to extract a massive header
   file called `vmlinux.h` from your kernel.
2. **Compile:** You use `clang` to compile that **C** code into an ELF object file containing bytecode and BTF
   data.
3. **Skeleton:** You use `bpftool` again to generate a **C** header file called a "skeleton." This provides
   typed **C** structures so your user-space loader can interact with your kernel code.
4. **Load & Verify:** In your user-space program, you call functions like `skel__open()` and `skel__load()`.
   This is when `libbpf` applies CO-RE patches and the kernel verifier checks the code.
5. **Attach & Run:** Finally, you call `skel__attach()`. The program links to the events, and you can now
   read data from the maps.

**[The Problem: Complex Dependencies on the Target]** Look at the right side of the slide. This traditional
workflow creates a long chain of library dependencies that you must install on your target embedded device.

To run your application, the target device requires:

* **`libbpf.so`** to load the bytecode.
* **`libelf.so`** because `libbpf` needs to parse ELF files.
* **`libz.so`** because `libelf` needs compression libraries.

For embedded Linux developers and BSP teams, this dependency chain causes friction. If you are building a
clean, minimal root filesystem, managing these extra shared libraries adds extra weight and testing
complexity.

**[The Teardown Risk in C]** There is also a code maintenance problem with the **C** implementation. When your
program exits, you must manually free the ring buffers, detach the skeleton, and destroy the object using
functions like `skel__destroy()`.

If an engineer forgets to write these cleanup functions, the program will leak memory or file descriptors.
The **C** compiler will **not** give you any warnings or errors if you forget them.

---
### Slide 37: 7.0: Does Rust Fit eBPF? (Speaker Notes)

**[Transition]**
Now We want to answer an important question: Why should we use Rust for eBPF? Are they a good match for each other?

---

### Slide 38: 7.1: Why Rust is a Natural Fit for eBPF Programs (Speaker Notes)


**[Shared Goals: No Undefined Behavior]**
Rust and eBPF are a perfect match because they have the exact same design goal: 
    they do not accept undefined behavior.

* The eBPF kernel verifier rejects your program if it cannot prove the code is 100% safe.
* The Rust compiler rejects your program if it cannot prove the code is 100% safe.

Both systems force you to fix safety issues *before* the code runs, not at runtime.

**[The `#![no_std]` Match]**
An eBPF program inside the Linux kernel runs in a very restricted environment. It has no standard operating system libraries, and it has no default memory allocator.

Rust is perfect for this environment because it has a built-in mode called `#![no_std]`. This mode tells the compiler to build code without the standard library. The `aya-ebpf` library provides all the necessary BPF helpers, map types, and macros for this restricted environment.

**[The Big Problem in C: Diverging Structures]**
In traditional **C** eBPF development, a very common and dangerous bug happens at the boundary between kernel space and user space.

Look at the **C** code example on the slide.

* Inside the BPF kernel code, an engineer defines an event structure where `pid` is a 32-bit integer (`u32`).
* Inside the user-space loader code—which is in a completely different file—the engineer accidentally defines `pid` as a 64-bit integer (`u64`).

The two structures do not match in memory. The user-space program will silently read the wrong data from the map. The **C** compiler will **not** show any error or warning because these are separate files.

**[Aya's Solution: The Shared Crate]**
Aya solves this problem completely using Rust modules. You create one single, shared folder called a `common` crate using the `#![no_std]` mode. You define your map structures **only once** inside this folder.

Both your kernel eBPF program and your user-space loader import this exact same folder. If you change a variable size, both sides update automatically. If there is a layout mistake, the compiler will halt the build immediately.

This is one of the biggest advantages of using Aya. It gives you true type safety across the kernel and user-space boundary.

---

### Slide 39: 8: The Bytecode Generation Question (Speaker Notes)


**[The Left Side: Traditional **C** Toolchain Workflow]**
- Let us look at the compilation steps on the left side of the slide. In the traditional **C** workflow,
  generating your final program requires several steps and multiple different tools.

- First, you write your kernel code in C. You must use `clang` with a special target to compile it into a
  BPF object file. Next, you must use a separate tool called `bpftool` to create a skeleton header file.
  Finally, you use `gcc` or `clang` on your host machine to build the user-space binary.

- This means your build system must install and manage many separate pieces: `clang`, `LLVM`, `bpftool`,
  `libelf`, and `libbpf`. Even if you use a Rust user-space library like `libbpf-rs`, you are still forced
  to maintain a full **C** compiler toolchain just to build the kernel-space code.

**[The Right Side: Modern Rust and Aya Workflow]**
- Now look at the right side of the slide. This is the Aya workflow. Your kernel code, shared types, and
  user-space loader all exist inside the same standard Rust project structure.

- We use the standard Rust compiler, `rustc`, along with a tool called `bpf-linker` to compile the kernel
  code into an ELF object file. Then, inside your user-space code, we use a built-in Rust macro called
  `include_bytes_aligned!`.

- This macro takes the compiled kernel bytecode and embeds it directly *inside* the user-space binary file
  during the build. When you run `cargo build`, the output is one single, self-contained binary file that
  contains everything.

**[The Main Takeaway]**
- With Aya, your development requirements are small. You only need `rustc` and `bpf-linker`. You do not need
  `clang`. You do not need `bpftool`. You do not need `libelf`. And you do not need any runtime C
  toolchains.

- To deploy your application, you only need to copy **one single binary file** to your target embedded
  machine.

- It is important to understand that Aya does not wrap or hide the **C** `libbpf` library. It is a completely
  pure-Rust rewrite of the BPF system call layer. It talks directly to the Linux kernel using standard
  system calls, making it clean, fast, and completely independent of external **C** libraries.

---
### Slide 40: 9.0: Rust Approaches — libbpf-rs and Aya (Speaker Notes)

**(Visual: Section 9 Title Slide)**

**[Transition]**
When you decide to use Rust for eBPF development, you have two different choices. These choices use two very different strategies.

Let us look at the differences between a tool called `libbpf-rs` and the framework we are focusing on, **Aya**.

---

### Slide 41: 9.1: Two Distinct Strategies (Speaker Notes)

**[Strategy 1: libbpf-rs]**
The first option is `libbpf-rs`. This tool acts as a bridge or a wrapper over the traditional **C** code.

* **Kernel Side:** You still write your kernel eBPF program in C. You must compile it using Clang.
* **User Space:** You write your loader program in Rust. This Rust loader wraps around the standard C
  `libbpf` library.
* **How it works:** A tool called `bpf2rs` reads your compiled **C** bytecode and generates Rust skeleton files.
* **Target Dependencies:** Because it is just a wrapper, your target embedded hardware **still requires
  `libbpf.so` and `libelf.so**` to run the program.

`libbpf-rs` is a good choice for teams that already have a large amount of existing **C** eBPF code and only
want to update their user-space tools to Rust. The transition cost is low, but you must keep a **C** compiler in
your build pipeline.

**[Strategy 2: Aya]**
The second option is Aya. Aya is a complete rewrite of the eBPF layer using pure Rust.

* **Kernel Side:** You write your eBPF program completely in Rust. You compile it using `rustc` and
  `bpf-linker`.
* **User Space:** Your loader is written in pure Rust. It is built on top of the basic `libc` crate. It has
  zero dependency on the **C** `libbpf` or `libelf` libraries.
* **The Embedded Win:** By using the `musl` toolchain, you can compile your entire application into a
  **single, statically-linked executable file**.
* **CO-RE Handling:** Aya does not need external tools to handle kernel version changes. It includes its own
  pure-Rust BTF parser called `aya-obj` to handle CO-RE relocations automatically.
* **Modern Features:** It is built for asynchronous code. It turns eBPF ring buffers into standard
  asynchronous types that work directly with the Tokio framework.

`Aya` is the best choice for new projects, embedded Linux boards, and Android systems.

**[Our Choice]** In this presentation, we focus on **Aya**. For our team’s embedded goals, eliminating
runtime **C** libraries, avoiding `clang` on the target, and deploying a single static binary file provides the
highest value.

---
### Slide 42: 10.0: Aya Framework Overview (Speaker Notes)

**(Visual: Section 10 Title Slide)**

Now, let us look inside the Aya framework. 
We will see its internal architecture and how its different parts map to the old **C** tools.

---

### Slide 43: 10.1: Architecture and Component Map (Speaker Notes)

Look at the architecture map on the slide. Aya splits its components into two clear halves: user space at
the top, and kernel space at the bottom.

Let us review the user-space components first:

* **Your user-space binary** uses standard Rust and asynchronous code. It calls `Ebpf::load()` to start
  everything.

* **`aya`** is the main library. It wraps the Linux `bpf()` system call natively in Rust. It provides your
  basic program types like XDP and your map types like Ring Buffer.
* **`aya-obj`** is the engine that parses ELF and BTF data. It reads the system file
  `/sys/kernel/btf/vmlinux` and handles all CO-RE adjustments. Because it is pure Rust, it completely
  removes our need for the `libelf.so` library.
* **`aya-log`** receives real-time print messages sent from the kernel.

Now look at the kernel-space components at the bottom:

* **Your BPF program** uses `#![no_std]` because it runs inside the kernel.
* **`aya-ebpf`** provides the core code runtime for the kernel side, including macros like `#[xdp]` and
  helper functions.
* **`aya-log-ebpf`** allows you to write simple logging commands like `info!()` and `warn!()` directly
  inside your kernel code.
* **`aya-ebpf-bindings`** contains the official Linux kernel structures, generated automatically.

**[What Aya Replaces]** The table shows how Aya simplifies your development system. It completely replaces
the old **C** `libbpf` stack:

* `aya` replaces `libbpf.so` and the **C** skeleton files.
* `aya-obj` replaces `libelf.so` and `libz.so`.
* `aya-ebpf` replaces old **C** headers like `bpf_helpers.h`.
* `aya-log-ebpf` replaces the old `bpf_printk()` function. It uses a fast ring buffer instead of a slow
  tracing log.
* `aya-tool` and `aya-build` replace old manual tools like `bpftool` and complex Makefiles.

**[The Big Benefit]** The main takeaway is simple: **Zero **C** runtime dependencies on your target hardware.**
The entire framework is written in Rust. It communicates with the operating system using one single system
call: `bpf()`. We do not need to install or update any shared **C** libraries on our production boards.

---
### Slide 44: 11: Aya for Embedded and Android — The musl Advantage (Speaker Notes)

**[The Deployment Problem]**
Let us look at the deployment problems on embedded Linux and Android devices.

When you use a traditional **C** `libbpf` tool, you cannot just copy one file to your target hardware. Your
program is dynamically linked, meaning it requires three other shared libraries to exist on the device:
`libbpf.so`, `libelf.so`, and `libz.so`.

On a minimal embedded filesystem or a production Android device, this creates major problems:

* **Missing Libraries:** `libelf` is a development library, so it is usually completely missing from
  production images.
* **Version Mismatches:** The version of `libbpf` pre-installed on the device might not match the version
  you used to compile your code.
* **Security Blocks:** Android has strict linker namespace rules. The operating system will often block your
  program from loading unrecognized external shared libraries.
* **Build Complexity:** If you cross-compile for different target architectures like ARM64 or RISC-V, your
  development laptop must maintain cross-compiled versions of all three helper libraries. This makes your
  build scripts very difficult to manage.

**[The Aya and musl Solution]** Aya removes this complexity completely by using the `musl` **C** library target.
`musl` is a lightweight alternative to the standard GNU **C** library (`glibc`) that allows full static linking.

Look at the command examples on the right side of the slide:

1. **Add Target:** We run `rustup target add` once to install the ARM64 musl compilation target.
2. **Build:** We use a tool called `cross` to cross-compile our code. This tool handles the compilation
inside a clean container environment automatically.

**[The Final Output]** When you run the Linux `file` command on the compiled output, look at the result. It
shows that our tool is an ARM64 executable that is **statically linked** and **stripped**.

This means everything your program needs—the user-space loader logic, the required helper libraries, and the
kernel eBPF bytecode—is packed tightly inside **one single binary file**.

**[Deployment]** Deploying this application to an Android device or an embedded board is incredibly simple.
As shown in the code blocks, you use `adb push` to copy the single file to the device, use `chmod` to make
it executable, and run it.

You do not need to install any external packages. You do not need to configure library paths. Combined with
CO-RE, this single file will run instantly on any ARM64 Linux kernel that supports BTF, including custom
BSPs and official Android devices.

---
### Slide 45: 12: Building with Aya Template (Speaker Notes)


**[Transition]**
Let us now look at how to actually set up our development host system and create a new Aya project.

Aya provides an official project template that configures everything for us automatically.

---

### Slide 46: 11.1: Prerequisites and Scaffold (Speaker Notes)


**[One-Time Environment Setup]**
Before we can write any code, we must install a few development tools on our computer. You only need to do
this setup once:

1. **Rust Nightly:** We must install the nightly version of the Rust toolchain. We need this because the
   specialized BPF compilation target—called `bpfel-unknown-none`—uses experimental compiler features that
   are only available in nightly Rust.
2. **bpf-linker:** This is a custom linker tool for Rust. It includes a built-in copy of the LLVM BPF
   backend. It translates the compiled Rust output into valid eBPF bytecode.
3. **cargo-generate:** This is a standard Rust tool used to create new projects from online templates.
4. **Verification:** You can run the `rustc --print target-list` command shown on the slide to confirm that
   the `bpfel` target is installed and visible.

**[Scaffolding the Project]**
- Once your environment is ready, you use the `cargo generate` command. You point it to the official Aya
  template repository on GitHub and provide a name for your project, such as `dma-latency-tracer`.

- This template sets up the directory structure we discussed earlier. It gives you a folder for the
  user-space program, a folder for the kernel-space program, and a shared folder for common structures.

**[The Simplified Build Process]** Look at the bottom of the slide. To compile the entire application, you
only need to type a single command: `cargo build --release`.

- In older versions of Aya, developers had to use a separate automated script called `xtask` to compile the
  kernel code first, and then compile the user-space code second. The modern Aya template removes this extra
  step completely.

- The template includes a standard Rust build script called `build.rs` inside the user-space project. When
  you run `cargo build`, this script automatically starts a background compiler command to compile your eBPF
  folder using the nightly toolchain.

- Once the kernel bytecode is generated, the script uses the `include_bytes_aligned!` macro to embed that
  bytecode directly inside your final user-space binary. You run one command, and you get one self-contained
  deployment file.

---
### Slide 47: 12.0: Project Layout and Rust Features That Simplify eBPF (Speaker Notes)

Now that we understand the prerequisites, let us look at the exact file layout of an Aya project.

We will see how a standard Rust feature called a **workspace** makes it easy to manage both your kernel code
and your user-space loader in one place.

---

### Slide 48: 12.1: Three-Crate Workspace Structure (Speaker Notes)

**[The Core Directory Structure]**
When you generate an Aya project, it creates a single directory containing three separate sub-folders, or
"crates." This is called a Rust workspace.

* At the root, the main **`Cargo.toml`** file ties all three folders together.
* The **`rust-toolchain.toml`** file is very important. It pins the specific nightly version of Rust for the
  project. This ensures that every engineer on your team compiles the code with the exact same compiler
  version.

**[1. The Common Crate]** The first folder is the **`-common`** crate. This crate uses the `#![no_std]` mode
because it must remain lightweight.

Look at the structure definition for **`DmaEvent`**. It uses the **`#[repr(C)]`** attribute. This attribute
tells the Rust compiler to arrange the variables in memory exactly like a standard **C** structure. This is
necessary because the Linux kernel expects data to be structured this way.

Because both the kernel eBPF program and the user-space loader import this common folder, they use the exact
same memory layout. If you add a field here, both sides update instantly.

**[2. The eBPF Crate]** The second folder is the **`-ebpf`** crate. This is where you write your actual
kernel logic, such as your `kprobe` handlers.

Look at the **`.cargo/config.toml`** file for this folder. It changes the build settings specifically for
the kernel side:

* **`target = "bpfel-unknown-none"`** sets the compilation target to a little-endian BPF processor.
* **`"-C", "link-arg=--btf"`** tells the linker tool to generate and embed the BTF type records. This is
  what makes your binary CO-RE compatible.
* **`build-std = ["core"]`** tells Rust to compile its core library from source code, because there is no
  pre-compiled standard library available for the BPF processor.

**[3. The User-Space Crate]** The third folder is the main user-space crate. This is a standard Rust
application that can use the network, standard libraries, and asynchronous runtimes like Tokio.

This folder contains a file called **`build.rs`**. As you can see in the code extract, when you type `cargo
build`, this script runs a background command that compiles the eBPF crate using the nightly compiler and
the BPF target.

Once the compilation finishes, it moves the output bytecode file into your build folder. The user-space code
then uses the `include_bytes_aligned!` macro to read that file and embed it directly inside your final
application binary.

You do not need separate build steps, automation scripts, or Makefiles. A single `cargo build` command
builds everything.

--- 
### Slide 49: 13.0: How Rust Simplifies eBPF (Speaker Notes)

Now that we have seen the complex setup and manual cleanup required by the traditional **C** toolchain, let us
look at how Aya utilizes Rust's native language features to eliminate these pain points.

This slide breaks down six core advantages that make Aya safer, cleaner, and much more reliable for
production environments.

---

### Slide 50: 13.1: Six Safety and Ergonomic Advantages of Aya (Speaker Notes)

**[1. Shared Common Crate]** First, as we touched on earlier, Aya eliminates the boundary risk between
kernel space and user space. By defining a structure like `DmaEvent` once inside a shared `no_std` common
crate, we force the compiler to verify layout safety.

If there is a structural layout mismatch or an invalid field size, it triggers a **compile-time error**. It
is impossible to accidentally deploy code that silently parses the wrong bytes on the user-space side.

**[2. RAII Attachment Handles]** Second, Aya solves the cleanup problem using a classic Rust pattern called
RAII, or Resource Acquisition Is Initialization. When you attach an eBPF program, it returns a typed handle
that implements Rust's `Drop` trait.

If your program encounters an error, propagates a failure with the `?` operator, or exits early, this handle
goes out of scope. When it does, Rust **automatically detaches the eBPF program and closes the file
descriptors**. You never have to worry about leaking attachments because you forgot to write a manual
destroy function.

**[3. Result Types & Error Propagation]** Third, Aya handles system errors explicitly. Every single call to
load code or modify maps returns a standard Rust `Result`.

If your BPF binary file is malformed or if the kernel verifier rejects your program, it will not silently
fail and let your application continue running blindly. The `?` operator forces immediate, explicit error
propagation that catches failures exactly where they happen.

**[4. Async Ring Buffer Integration]** Fourth, reading data streams from the kernel is incredibly efficient.
Aya wraps the eBPF ring buffer inside an asynchronous file descriptor (`AsyncFd<RingBuf>`). This allows it
to plug directly into modern async runtimes like Tokio.

Instead of writing complex, global C-style callback loops with void pointers, you write a clean async loop
that waits for data natively. The application state stays fully owned by your async task.

**[5. Typed Program Kinds]** Fifth, Aya uses explicit type downcasting to protect your event attachments.
When you pull a program out of an ELF file, it starts as an untyped object. You must explicitly cast it—for
example, converting it to a `KProbe`.

The compiler will only allow you to call `attach()` with arguments that are legally valid for a kprobe
event. In traditional C, the attachment functions are untyped, meaning you can accidentally pass an XDP
argument to a tracepoint hook, causing a silent runtime failure.

**[6. Structured `aya-log`]** Finally, Aya provides modern logging inside the kernel. Instead of using the
old, slow `bpf_printk()` function—which requires you to manually parse raw debug files out of the global
tracing pipeline—Aya provides standard `info!()` and `warn!()` macros.

These macros stream structured logs from the kernel into a dedicated ring buffer automatically. Your
user-space code subscribes to this stream and routes the messages straight into your standard application
logging framework, like `env_logger`. It looks and feels just like debugging normal user-space code.

---
### Slide 51: 13.2 : BPF Program Side — Key Patterns (Speaker Notes)

Now that we have reviewed a basic kprobe implementation, let us look at the recurring design patterns you
will use when writing the kernel-space side of an eBPF program. Writing eBPF in Rust changes the syntax, but
more importantly, it changes how safely we interact with kernel data types.

### Key Pattern Comparisons

| Pattern | Traditional **C** / libbpf | Modern Rust / Aya |
| --- | --- | --- |
| **Entry Point Definitions** | `SEC("kprobe/dma_map_sg")` | `#[kprobe]` (Attribute Macro) |
| **Context Handling** | `PT_REGS_PARM1(ctx)` or `BPF_KPROBE` | Strongly-typed `ProbeContext`, `XdpContext` |
| **Map Interactions** | `bpf_map_update_elem(&map, &k, &v, flags)` | `MAP.insert(&k, &v, flags)` (Object-Oriented) |
| **Memory Safeguards** | Manual pointer math & unchecked pointer casting | Explicit `unsafe` scoping for boundary reads |

**[Pattern 1: Program Entry Points & Declarations]**
In the traditional **C** world, you declare where a program hooks into the kernel using string-based section
macros, like `SEC("kprobe/...")` or `SEC("xdp")`. If you misspell the string inside that macro, the C
compiler will not notice. You will only find out much later at runtime when the loader fails to attach the
program.

Aya replaces these error-prone strings with native Rust **Attribute Macros**, such as `#[kprobe]`, `#[xdp]`,
or `#[lsm]`. Because these are macro attributes recognized directly by the compiler pipeline, syntax errors
or invalid hook declarations are caught immediately during compilation.

**[Pattern 2: Strongly-Typed Context Objects]** When an event fires, the kernel passes a raw execution
context pointer to the eBPF program. In C, extracting function parameters requires wrapping your entry point
in complex macro abstractions like `BPF_KPROBE(...)` or manually unwrapping CPU registers using
architecture-specific macros.

Aya delivers native type safety by providing dedicated context structures for each program type. For
example, a kprobe uses `ProbeContext`, while a network packet filter uses `XdpContext`. These structs expose
safe, idiomatic methods to read parameters without needing architecture-dependent registry definitions.

**[Pattern 3: Object-Oriented Map Operations]** Interacting with BPF maps in **C** is procedural and requires
passing raw pointers continuously. You are forced to call global helper functions like
`bpf_map_update_elem()`, pass the memory address of your map, the address of your key, and the address of
your value. This code is verbose and easy to miswrite.

Aya brings an object-oriented approach to the kernel. Maps are declared as static variables using the
`#[map]` attribute. When you want to save data, you interact with the map object directly by invoking
standard methods, such as `MAP.insert(&key, &value, 0)`. It reads and writes exactly like standard
user-space code.

**[Pattern 4: Explicit Isolation of Unsafe Code]** When writing eBPF programs, you must read memory spaces
that belong to the core Linux kernel. In C, all pointer manipulation looks identical, meaning there is no
visual distinction between reading local stack variables and reading highly volatile kernel memory
addresses.

In Rust, interacting with the external host environment forces you to place those specific lines of code
inside an explicit `unsafe` block. This layout acts as a vital guardrail for our BSP engineering team. It
immediately signals during code reviews exactly where the program is touching raw kernel internals,
separating standard safe logic from low-level pointer tracking.
---

### Slide 52: 13.3: Userspace Loader — Load, Attach, Consume (Speaker Notes)

Now that we have looked at the kernel-space code, let us focus on the host application running in user space.

We will compare the traditional **C** loading sequence side-by-side with Aya's asynchronous Rust implementation
to see how we load the bytecode, attach to hooks, and safely consume event streams.

Implementation Comparison — **C** vs. Rust

**[Phase 1: The Load Phase]** Let us break this code comparison down into the three phases mentioned: Load,
Attach, and Consume.

First, look at the top of both code blocks for the **Load** phase:

* In C, you work with a raw skeleton structure, invoking procedural commands like `prog_open()` followed by
  `prog_load()`. This initializes the maps and passes the bytecode through the kernel verifier.
* In Rust, Aya simplifies this into a single line: `Ebpf::load(BPF_BYTES)?`. The `BPF_BYTES` array is the
  bytecode that was embedded directly into our binary at build time.

Right after loading, Aya forces a strict type downcast. We look up the program by its string name and
explicitly call `.try_into::<KProbe>()`. If the bytecode inside the ELF file is actually an XDP program
instead of a KProbe, this cast fails immediately with a clean Rust error. In C, everything remains an
untyped pointer, making type mismatches easy to miss.

**[Phase 2: The Attach Phase]** Next is the **Attach** phase:

* In C, you call `prog__attach(skel)`. This attaches the hook and returns a file descriptor behind the
  scenes inside the skeleton object.
* In Rust, you call `prog.attach("dma_map_sg", 0)?`. This returns a concrete token called `_link`. This
  token is tied directly to Rust’s lifetime tracking engine. As long as this variable remains alive in
  memory, the eBPF hook stays attached.

**[Phase 3: The Consume Phase (The Ring Buffer)]** The most significant architectural change is the
**Consume** phase, where we pull events out of the kernel ring buffer.

Look at the **C** implementation on the left. **C** uses a synchronous, blocking callback architecture:

1. You must call `ring_buffer__new()` and pass a raw **C** function pointer (`handle_event`).
2. You must pass `NULL` values for application contexts because **C** callbacks cannot naturally capture
surrounding local state.
3. You must spin up a manual loop that continuously calls `ring_buffer__poll()`, blocking the thread for a
specified number of milliseconds.

Now look at the modern Aya approach on the right. Aya treats the kernel ring buffer as a standard
asynchronous event stream:

1. We extract the map safely using `bpf.take_map("EVENTS")`.
2. We wrap that ring buffer inside an asynchronous file descriptor helper called `AsyncFd::new(rb)`. This
integrates the kernel ring buffer directly into standard user-space async runtimes like Tokio.
3. Inside our execution loop, we simply call `afd.readable().await?`. The thread does not block or waste CPU
cycles polling; it yields control back to the operating system until the kernel explicitly wakes it up
because new data is ready.
4. When data arrives, we read it using standard iterator syntax, casting the raw pointer safely to our
strongly-typed `DmaEvent` struct that we imported from our common crate.

**[Phase 4: The Hidden Benefit — Teardown]** Finally, look at the very bottom of both blocks.

In the **C** code, you are fully responsible for manual cleanup. You must explicitly remember to call
`ring_buffer__free()`, `prog__detach()`, and `prog__destroy()`. If your program crashes, panics, or returns
early due to an error before reaching these lines, those resources will leak in the background.

In the Rust code on the right, there is **zero cleanup code written**. Because `bpf`, `_link`, and `afd` all
implement Rust’s native `Drop` trait, the moment the execution loop ends—whether it ends normally, returns
an error via the `?` operator, or crashes—Rust guarantees that all file descriptors are closed and all
kernel hooks are detached automatically.

---

Demo: Build and cross build:

