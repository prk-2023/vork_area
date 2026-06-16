
### Slide 1 · Title / Hero

Good afternoon. Today's topic is **Introduction to Rust and eBPF programming with Rust**.

Before we begin, one important framing point.

- In Modern computing infrastructure :
    operating systems, drivers, firmware, networking stacks  are mostly built on **C**. 
    Which is an outcome of 50+ years of successful engineering, and this talk is not an argument against it.

- Rather I want to share how the systems programming landscape is evolving, and why Rust has caught the
  attention of OS vendors, silicon companies, cloud providers, and mainly the **Linux kernel community**
  itself.

- The reason this became interesting to me personally: Rust moved from experimental to **officially
  maintained** in the Linux kernel at the 2025 maintainer summit in Tokyo. That is the moment it shifted
  from a curiosity to something worth understanding deeply.

- If you might have watched or read about Rust there are tons of them on youtube you would quickly realise
  there are about 3 different perspectives, those who love rust, those who hate rust and rest skeptical
  about it. ( as of the new released kernel version 7.1 there are already 350 rust source files in the
  kernel infrastructure ). But we will not be talking about Rust for Linux kernel, as its a deserves a
  separate presentation, and honestly I still have not played or worked with it. 

- With this dual language support in the Kernel, understanding the key concepts of rust will be of help. 
  In these presentation we will look at some of the key features and try to understand the language 
  philosophy of Rust.

// Offcourse with two languages we have additional trouble, how to maintain and what is the roadmap, if my
// implementation is in sync with other language, can I benefit from this, can it help fix known issues.

// - Also from Industry there is a common question,  for the need that : 
//    - Can we maintain the performance and control of low-level programming 
//      while reducing entire classes of bugs before the code ever runs?

--- 

### Slide 2 · Disclaimer

A quick disclaimer before we go further.

- I am not presenting myself as a Rust expert. Like many of you, Rust caught my attention through the kernel
  adoption story, and I am still exploring it myself. Today I am sharing what I have learned, not advocating
  for a migration.

- The goal here is not to start a language debate. C will remain the foundation of systems and embedded
  development for a long time. Rust should be understood as another tool in systems programming toolbox — 
  one that attempts  to solve specific, well-known problems.

- Discussions about programming languages — especially in the Linux kernel community — can get very
  opinionated, because engineers build strong trust in tools that have worked for them. I ask that we
  approach this as a technical evaluation.

I will do my best to answer questions. As covering entire domain of a programming language is difficult, and 
If I do not know, I will say so. 

---

### Slide 3 · Agenda

We divide today's talk into two sections.

**Part 1 — Rust as a systems language:** core design philosophy, memory model, compile-time safety
guarantees, and how these properties relate to low-level development.

**Part 2 — eBPF with Rust:** this is the part most relevant to your daily work. We look at Aya, a pure-Rust
eBPF framework, compare it to the libbpf workflow your team already knows, and go through a working example.

With time constraint and our technical sharing sessions have already covers eBPF, libbpf and CO-RE, 
I will keep the eBPF fundamentals brief and spend most of our time on **how Rust changes the development 
experience for the programs that we are already writing**.

---

### Slide 4 · Introduction to Rust: A Systems Programming Perspective

`[QUICK]`

Before getting into language features, let us first ask the right question: can Rust actually be used for
systems programming, or is it a general-purpose language that happens to be fast?

There is a real misconception here. Rust is frequently described as a general-purpose language, but its
design constraints map precisely to what systems work requires. Let us verify that.

---

### Slide 5 · Evaluating Rust for Systems Programming

`[FULL]`

For a language to qualify as a systems programming language, it must satisfy three hard requirements:

1. **Direct hardware access** — MMIO registers, DMA, interrupt controllers, precise memory layout control.
   No abstraction layers hiding the silicon.
2. **No managed runtime** — no garbage collector, no VM, no OS safety net underneath. The language must be
   safe to run in an ISR, in early boot before the MMU is enabled, or on 16 KB of RAM.
3. **Load-bearing correctness** — a bug does not crash one user session. It crashes the whole system,
   corrupts flash, or silently misdelivers data to hardware.

**How Rust maps to these:**

- `no_std` strips the standard library completely, leaving only core language primitives. This is how Rust
  targets bare-metal, bootloaders, and kernel subsystems.
- `unsafe { }` is the explicit escape hatch for hardware interaction — raw pointer dereference, MMIO writes,
  inline assembly. It does not disable the compiler; it marks the boundary where the developer is taking
  direct responsibility.
- `asm!` macro provides first-class inline assembly. The syntax is cleaner than GCC's `__asm__ __volatile__`
  constraints, and because it comes from `core` — not `std` — it is fully available in `no_std`
  environments.
- `#[repr(C)]` forces exact C-compatible memory layout, padding and alignment. Zero-overhead FFI with
  existing C libraries and kernel structures.

**The comparison table:** C gives absolute control with no built-in safety. C++ adds RAII but leaves
ownership tracking manual across complex multithreaded codebases. Rust is the first language that gives
memory and concurrency safety **without a garbage collector**, with a formally verified type system. The
trade-off is a steep learning curve — the compiler does not negotiate.

---


