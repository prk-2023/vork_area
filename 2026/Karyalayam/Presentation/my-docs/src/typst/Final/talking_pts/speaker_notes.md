# Speaker Notes — Introduction to Rust & eBPF with Rust
### Audience: Embedded systems engineers, 10+ years experience, active eBPF users
### Context: Follows an internal libbpf + CO-RE talk; team head requested focus on how Rust improves the eBPF development experience

---

> **How to use these notes:**
> Sections marked `[QUICK]` are for audiences who already know the material — one or two sentences, then move on.
> Sections marked `[FULL]` are the core value for this audience — spend time here.
> Commented-out blocks `//` are backup material if questions arise; do not read aloud.

---

## PART 1 — RUST AS A SYSTEMS LANGUAGE

---

### Slide 1 · Title / Hero

Good afternoon. Today's topic is **Introduction to Rust and eBPF programming with Rust**.

Before we begin, one important framing point.

Modern computing infrastructure — operating systems, drivers, firmware, networking stacks — is built on **C**. That is fifty years of successful engineering, and this talk is not an argument against it.

What I want to share is how the systems programming landscape is evolving, and why Rust has caught the attention of OS vendors, silicon companies, cloud providers, and the Linux kernel community itself.

The reason this became interesting to me personally: Rust moved from experimental to **officially maintained** in the Linux kernel at the 2025 maintainer summit in Tokyo. That is the moment it shifted from a curiosity to something worth understanding deeply.

---

### Slide 2 · Disclaimer

A quick disclaimer before we go further.

I am not presenting myself as a Rust expert. Like many of you, Rust caught my attention through the kernel adoption story, and I am still exploring it myself. Today I am sharing what I have learned, not advocating for a migration.

The goal here is not to start a language debate. C will remain the foundation of systems and embedded development for a long time. Rust should be understood as another tool in the toolbox — one that attempts to solve specific, well-known problems.

Discussions about programming languages — especially in the Linux kernel community — can get very opinionated, because engineers build strong trust in tools that have worked for them. I ask that we approach this as a technical evaluation.

I will do my best to answer questions. If I do not know, I will say so.

---

### Slide 3 · Agenda

We divide today's talk into two sections.

**Part 1 — Rust as a systems language:** core design philosophy, memory model, compile-time safety guarantees, and how these properties relate to low-level development.

**Part 2 — eBPF with Rust:** this is the part most relevant to your daily work. We look at Aya, a pure-Rust eBPF framework, compare it to the libbpf workflow your team already knows, and go through a working example.

Given that your team just saw a talk on libbpf and CO-RE, I will keep the eBPF fundamentals brief and spend most of our time on **how Rust changes the development experience for the programs you are already writing**.

---

### Slide 4 · Introduction to Rust: A Systems Programming Perspective

`[QUICK]`

Before getting into language features, let us first ask the right question: can Rust actually be used for systems programming, or is it a general-purpose language that happens to be fast?

There is a real misconception here. Rust is frequently described as a general-purpose language, but its design constraints map precisely to what systems work requires. Let us verify that.

---

### Slide 5 · Evaluating Rust for Systems Programming

`[FULL]`

For a language to qualify as a systems programming language, it must satisfy three hard requirements:

1. **Direct hardware access** — MMIO registers, DMA, interrupt controllers, precise memory layout control. No abstraction layers hiding the silicon.
2. **No managed runtime** — no garbage collector, no VM, no OS safety net underneath. The language must be safe to run in an ISR, in early boot before the MMU is enabled, or on 16 KB of RAM.
3. **Load-bearing correctness** — a bug does not crash one user session. It crashes the whole system, corrupts flash, or silently misdelivers data to hardware.

**How Rust maps to these:**

- `no_std` strips the standard library completely, leaving only core language primitives. This is how Rust targets bare-metal, bootloaders, and kernel subsystems.
- `unsafe { }` is the explicit escape hatch for hardware interaction — raw pointer dereference, MMIO writes, inline assembly. It does not disable the compiler; it marks the boundary where the developer is taking direct responsibility.
- `asm!` macro provides first-class inline assembly. The syntax is cleaner than GCC's `__asm__ __volatile__` constraints, and because it comes from `core` — not `std` — it is fully available in `no_std` environments.
- `#[repr(C)]` forces exact C-compatible memory layout, padding and alignment. Zero-overhead FFI with existing C libraries and kernel structures.

**The comparison table:**
C gives absolute control with no built-in safety. C++ adds RAII but leaves ownership tracking manual across complex multithreaded codebases. Rust is the first language that gives memory and concurrency safety **without a garbage collector**, with a formally verified type system. The trade-off is a steep learning curve — the compiler does not negotiate.

---

### Slide 6 · The Cost of the Status Quo — In Numbers

`[QUICK — this audience knows the problem, do not dwell]`

These numbers are why the industry is paying attention.

Microsoft and the Chrome team found that 70% of CVEs are memory-safety issues. Independent studies of the Linux kernel show a nearly identical 67%. These numbers have **not changed in 20 years**, despite better static analyzers, kernel sanitizers, and experienced developers.

The reason is not poor engineering. It is that C intentionally gives unrestricted memory control, and at millions of lines of code across multiple teams and vendors, relying on discipline alone is statistically difficult. The NSA's 2023 guidance reflecting this is the industry acknowledging it formally.

This is the problem Rust was designed to address at the compiler level.

---

### Slide 7 · How Rust Addresses the CVE Pattern

`[QUICK]`

Rust's approach is to prevent entire classes of bugs before the code runs — not by catching them at runtime with sanitizers, but by making them **compile-time errors**.

In safe Rust (excluding explicit `unsafe` blocks): use-after-free, double free, iterator invalidation, and most data races are not runtime failures — they are rejected at build time. Without a GC, without hidden runtime overhead.

This is Rust's core proposition for systems work: moving correctness checks from runtime debugging into compile-time enforcement.

---

### Slide 8 · How Rust Fits Systems Programming

`[QUICK — transition slide]`

We have looked at the CVE problem. Now let us look at the mechanism — specifically the three properties that make Rust viable in our domain.

---

### Slide 9 · Property 1 & 2: Determinism and Hardware Access

`[FULL]`

**Property 1 — No GC, no runtime:**

Unlike Go or Java, Rust has no garbage collector and no background runtime threads. Memory cleanup happens at a **statically known point** determined at compile time — when a variable goes out of scope. No unpredictable pause, no hidden allocation overhead.

The memory model is directly familiar from C:
- Stack allocation: zero overhead, identical to `int x;` in C.
- Heap allocation: entirely explicit, backed by whatever custom allocator you provide. You have full control over every byte.

This means Rust is safe in an ISR, in early-boot firmware before the MMU is enabled, or on a microcontroller with 16 KB of RAM. And the output is a standard ELF binary — a Rust kernel module is a `.ko` file. `insmod`, `lsmod`, `rmmod` cannot tell the difference.

**Property 2 — Direct hardware access:**

The code examples on this slide show how Rust does what C does at the silicon level:

- **MMIO write:** `core::ptr::write_volatile(CTRL_REG as *mut u32, 0x1)` — identical to a C volatile cast.
- **Inline assembly:** `asm!("dsb sy", options(nostack))` — same ARM data sync barrier you write in C with `__asm__ __volatile__`, but cleaner syntax, and available in `no_std`.
- **Raw pointer arithmetic:** same as C, explicitly wrapped in `unsafe`.

Notice that all of these are inside `unsafe { }` blocks. This is not the compiler being disabled — it is an explicit, grep-able declaration that this specific block interacts with hardware state the compiler cannot verify. Every potentially dangerous hardware interaction is marked, auditable, and isolated.

---

### Slide 10 · Property 3: Zero-Cost Abstractions

`[FULL — the assembly comparison is the payoff here]`

The third property is Rust's full adoption of Stroustrup's principle: *"What you don't use, you don't pay for. What you do use, you couldn't hand-code any better."*

**The assembly comparison:**

Look at the assembly generated for a simple integer squaring function in Rust vs. C.

The Rust debug build output is longer than C. This is intentional — Rust inserts an integer overflow check by default (`seto al`, `jo .LBB0_2`). In C, signed integer overflow is undefined behavior, so GCC removes the check entirely — the shorter output is shorter because the safety is absent, not because C is faster.

When we enable optimizations (`-O2` in C, `--release` in Rust), the generated assembly is nearly identical. To make C do what Rust does by default — check overflow and abort — you use `__builtin_mul_overflow`, at which point the assembly becomes comparable.

The point: **Rust's default-safe assembly is the same cost as C's manually-safe assembly**. You are not paying a tax; you are getting it for free.

**Iterators and closures — zero overhead:**

The high-level iterator pipeline for filtering and summing latencies compiles to the same tight `for` loop as the manual version. Godbolt confirms identical `ADDQ` instructions. You get readable code with no runtime penalty.

**Generics — monomorphization:**

The `min_of<T>` generic function generates a specialized version for each concrete type used — `min_of::<u32>`, `min_of::<u64>`. No vtable, no boxing, no indirection. This is critical for latency-sensitive code paths.

**Lifetimes — zero runtime cost:**

Lifetime annotations like `'a` are compile-time analysis only. The Rust front-end uses them to prove no reference outlives its data. Once that proof is complete, the annotations are completely stripped before LLVM sees the code. The final binary has identical pointer instructions to C. The safety is entirely in the type system, not in the runtime.

---

### Slide 11 · The Aliasing Advantage: Rust Often Optimizes Better Than C

`[FULL — this is directly relevant to performance work]`

This is one of Rust's less-discussed but highly relevant performance properties for this audience.

C's pointer aliasing rules mean the compiler must assume that two `uint8_t*` pointers might overlap in memory. Unless the developer explicitly adds the `restrict` keyword — which is an unchecked promise — the compiler must be defensive and generates less optimized code. If the promise is wrong, you get silent data corruption.

Rust's exclusivity rule solves this structurally. A `&mut T` reference is exclusive by construction: safe Rust prevents the existence of any other reference to the same memory while the mutable reference exists. This means when LLVM sees Rust code, it already has the aliasing proof — no annotation needed.

The result: LLVM can aggressively auto-vectorize loops it cannot safely vectorize in C without `restrict`. The buffer processing example on this slide generates a `VPOR ymm` loop (AVX2 SIMD) in Rust automatically. In C, you need to add `restrict` and trust the caller.

**The elegant insight:** the same exclusive mutable property that prevents data races also enables better codegen. Safety and performance arise from the same source — the aliasing proof in the type system.

---

### Slide 12 · Important Language Features: Ownership, Borrowing, Lifetimes

`[QUICK — transition]`

We have seen how Rust qualifies as a systems language. Now let us look at the core engine that delivers the safety guarantees: Ownership, Borrowing, and Lifetimes.

These are the mechanisms that enforce memory safety at compile time without a GC. We will quickly cover each, focused on how they prevent the exact bug classes that generate kernel CVEs.

---

### Slide 13 · Ownership: Memory Safety at Compile Time

`[FULL]`

Ownership is Rust's fundamental innovation. It is not a library or a runtime — it is a strict set of compile-time rules that govern how memory is managed.

**Three rules:**

- **Rule 1:** Each value has exactly one owner.
- **Rule 2:** Ownership can be moved, but only one owner exists at a time.
- **Rule 3:** When the owner goes out of scope, the value is dropped automatically.

**Rule 1 & 2 in practice:**

When you write `let s2 = s1;`, a C developer would expect a pointer copy — two variables pointing to the same heap memory. In Rust, this is a **move**. Ownership transfers entirely to `s2`. From that line onward, `s1` is invalid. Any attempt to use `s1` is a compile error.

In C, that same pattern compiles cleanly and produces a potential double-free — two variables pointing to the same allocation, one of which gets freed. The bug only surfaces at runtime.

Zero runtime bookkeeping. Zero performance overhead. The compiler tracks this statically.

**Rule 3 in practice:**

When `buf` hits the closing brace and goes out of scope, the compiler automatically inserts the cleanup call — `Drop::drop()`. No `free()` to forget. No leak possible. This is RAII, but enforced structurally by the language, not just convention.

**The shift:** Ownership converts memory safety from a runtime discipline — relying on developers to never make a mistake — into a compile-time verification problem solved by the type system.

---

### Slide 14 · Ownership vs. C: Eliminating Use-After-Free

`[FULL — this is the #1 kernel CVE class]`

Use-After-Free is consistently the most common and dangerous kernel CVE class. This slide shows that eliminating it is not a bug-detection problem — it is a **program expressiveness problem**.

In standard C, there is no way to tell the compiler that a pointer has become invalid after a certain point. The language has no concept of it.

**The C example:**
Allocate a DMA buffer, submit it to hardware, call `kfree(buf)`. Then — 500 lines later, in an async completion callback — someone uses `buf` again. Classic UAF. Pure undefined behavior. GCC and Clang give zero warnings. The binary compiles, ships, and corrupts memory on a customer device.

**The Rust example:**
After `drop(buf)`, any attempt to use `buf` produces **Compiler Error E0382: use of moved value**. The error message names the exact line where the value was moved and the exact line of the illegal use.

No valgrind. No KASAN run. No test execution. **The security boundary is enforced at every build, instantly.**

---

### Slide 15 · Ownership Prevents Leaks: RAII in the Kernel

`[FULL — directly relevant to driver code]`

Managing resource allocation across error exit paths is one of the most tedious and error-prone parts of kernel driver development. In C, it is entirely a human discipline. Rust makes it structurally impossible to get wrong.

**The C reality:**

Allocate `res_a` — if `res_b` fails, free `res_a`. If `res_c` fails, free both `res_b` and `res_a`, in the correct reverse order. In a real kernel driver this leads to cascades of `goto err_free_res_b`, `goto err_free_res_a` labels. The Linux kernel source tree has thousands of these. Every new error branch added requires manually auditing every exit path.

**The Rust approach:**

The `?` operator on each allocation automatically triggers an early return on failure. But because `res_a` owns its resource, the compiler automatically inserts `res_a.drop()` on that early return path. All three resources are freed in reverse order on every exit — success, error, or panic — without a single `goto` label.

Rust converts a developer-managed control flow problem into a compiler-enforced scope rule. Zero `goto` cleanup chains. Zero missed paths. Zero runtime overhead.

---

### Slide 16 · Borrowing: Aliasing Rules and Data Race Elimination

`[FULL — connects directly to multi-core embedded work]`

Borrowing is Rust's system for temporary access without transferring ownership. It formalizes the aliasing rules that C developers know informally but cannot enforce.

**Two types of reference:**

- `&T` — shared (immutable) borrow. Multiple readers can coexist. None can write while readers exist. Maps to: RCU read section, read-lock held.
- `&mut T` — exclusive (mutable) borrow. One writer, zero concurrent readers. Maps to: spinlock held, write-lock held.

A data race requires aliasing plus unsynchronized mutation. Rust's borrow rules make both simultaneously impossible in safe code — `&mut T` is exclusive (no aliasing while mutating), `&T` is immutable (no mutation while aliased). This is formally machine-checked: **if the program compiles, it has no data races.** This proof was verified in Coq by RustBelt (POPL 2018).

---

### Slide 17 · Lifetimes: Dangling Pointers Eliminated

`[QUICK for this audience — they understand pointer validity]`

Lifetimes are the compiler's mechanism for proving that every reference is valid for its entire use. They have zero runtime representation — erased before code generation.

Every "dangling pointer to freed device" CVE is a lifetime violation. In Rust, `IrqHandler<'dev>` ties the handler's lifetime to the device's lifetime at the type level. The handler becoming statically invalid before the drop is a compile error, not a kernel oops.

The safety is a compile-time proof, not a runtime check.

---

### Slide 18 · The Type System as a Security Tool

`[QUICK — transition to specific type features]`

In C, the type system tracks size, alignment, and memory layout. In Rust, the type system is extended into a concurrency security model. The next slides show the specific mechanisms.

---

### Slide 19 · `Option<T>`: Null Pointer Elimination

`[FULL]`

Null pointer dereferences are a constant source of kernel oopses, especially in driver initialization and probe paths.

In C, a pointer is a raw memory address — it can point to a valid structure or to `0x0`. The compiler cannot distinguish, and the developer must remember to check.

**The C risk:** `platform_get_resource()` returns `NULL` if the resource is absent. If the developer passes `res->start` directly to `ioremap` without checking, the kernel triggers a `BUG()` panic. The compiler gives zero warnings because accessing a struct member via pointer is syntactically valid.

**Rust's approach:** APIs that might return nothing return `Option<Resource>` — an enum that is either `Some(resource)` or `None`. You cannot call `.start` or `.size()` on the `Option` directly. The type system forces you to unpack it with a `match` block first.

**Zero runtime cost:** `Option<&T>` has identical machine representation to a C nullable pointer — one word, where `0x0` represents `None` and any non-zero address represents `Some`. This is the **niche optimization** — the compiler uses the already-forbidden null address as the `None` sentinel. No extra tag bytes, no runtime overhead.

---

### Slide 20 · `Result<T, E>`: No Silent Error Drops

`[FULL]`

In C, error signaling is an implicit protocol — functions return `int` where negative means failure. The language allows you to ignore that integer entirely.

**The C pattern:** calling `pci_enable_device()`, `pci_request_regions()`, `request_irq()` sequentially without checking return values compiles flawlessly. If the first call fails, the driver marches forward and attempts to configure hardware in an undefined state.

**Rust's `Result<T, E>` and `#[must_use]`:** every function that can fail returns `Result`. The `#[must_use]` attribute means discarding a `Result` is a compiler warning — and in production builds, a hard error. The type system forces you to acknowledge the failure path.

**The `?` operator:** `pdev.enable()?` expands exactly to a `match` — `Ok` continues, `Err` immediately propagates the error up the call stack. No exceptions. No `longjmp`. No hidden control flow. The generated assembly is standard conditional branches. Every early return path is explicit, local, and grep-able.

Your `checkpatch.pl` warns about unchecked return values after the fact. Rust makes non-checking a build error by default.

---

### Slide 21 · Exhaustive `match`: No Silent Enum Gaps

`[FULL — directly relevant to hardware spec evolution]`

When hardware specifications change, new states get added to enumerations. In C, this silently breaks every switch statement that used a `default:` catch-all.

**The C risk:** Adding `GEN5` to a PCIe speed enum causes every unupdated `switch` to silently fall through to `default: return 0`. Catastrophic silent logic failure. GCC `-Wall` might warn — if you use it, parse the logs, and treat warnings as errors.

**Rust's `match` is exhaustive by default.** Adding `Gen5` to the enum without adding the corresponding `match` arm is **Compiler Error E0004: non-exhaustive patterns**. The compiler names the exact variant you forgot, across your entire codebase and every external crate that uses it. Refactoring becomes a compiler-guided checklist, not a guessing game.

---

### Slide 22 · `unsafe`: The Auditable Escape Hatch

`[FULL — important for this audience's mental model of Rust]`

This is the most misunderstood feature of Rust, especially for systems developers. `unsafe` is not a switch that turns off the compiler.

`unsafe { }` grants exactly **four specific capabilities:**
1. Dereference a raw pointer (`*const T`, `*mut T`)
2. Call an unsafe function (including all `extern "C"` FFI)
3. Access or modify a mutable global static variable
4. Manually implement an unsafe trait (`Send`, `Sync`)

**What `unsafe` does NOT disable:** the borrow checker, type checking, lifetime analysis, `#[must_use]`. Lifetime violations and type mismatches inside `unsafe` blocks are still compile errors.

**The audit argument — this is critical for code review:**

```bash
# Complete audit surface for all unsafe code in a driver subsystem:
grep -rn "unsafe" drivers/my_soc/
```

In a C codebase, every single line of code is part of the audit surface. There is no equivalent query to isolate memory-unsafe operations, because any pointer access anywhere can cause undefined behavior.

In Rust, this one command surfaces every location in the codebase where manual memory responsibility is taken. This changes the security audit from "review everything" to "review the marked boundaries."

---

### Slide 23 · What the Rust Compiler Verifies at Every Build

`[QUICK — summary slide]`

The compiler verifies all of this at every single build: no use-after-free, no dangling references, no data races, no null dereferences, no uninitialized reads, exhaustive enum handling, and mandatory error propagation.

In C you can catch these with separate tools — sanitizers, static analyzers, sparse, valgrind. But these are optional, separate, and do not cover 100% of code paths. They require the test to actually execute the vulnerable path.

Rust replaces this toolchain of optional post-hoc checks with one compiler that enforces these rules structurally. Every engineer on the team must comply — the build refuses otherwise.

---

### Slide 24 · Rust Ecosystem and Tooling

`[QUICK]`

Rust ships with a unified, standard toolchain:

| Tool | Role | C equivalent |
|---|---|---|
| `cargo` | Build, test, dependency management | Make / CMake / pkg-config |
| `rustfmt` | Code formatting | clang-format |
| `clippy` | Linting and code quality | Coverity / sparse |
| `rustdoc` | Documentation generation | Doxygen |
| `rust-analyzer` | IDE integration | Language server extensions |

Because everyone uses the same tools, onboarding and code sharing are straightforward.

Real-world signal of maturity: AWS Firecracker, Cloudflare Pingora (1 trillion requests/day), Android 16's memory allocator, and — most relevant here — the Linux kernel's `rust/` tree.

---

## PART 2 — eBPF PROGRAMMING WITH RUST

> **Context note for the presenter:** This section follows a libbpf + CO-RE talk the team already attended. The head of this team asked specifically: *how does Rust improve the experience of writing eBPF programs?* That is the lens for this entire section. Spend minimal time re-explaining what they already know; spend maximum time on the delta that Rust and Aya introduce.

---

### Slide 25 · eBPF Quick Refresher

`[QUICK — one slide, two minutes]`

Your team has used eBPF through BCC, bpftrace, and libbpf. The execution model is already familiar. I will not re-explain it.

One point worth holding onto for the comparison ahead: **Rust does not change the eBPF execution model.** The BPF verifier, the JIT, the kernel hook infrastructure — all unchanged. The kernel only sees BPF bytecode. Whether that bytecode was generated by Clang from C or `rustc` from Rust makes no difference to the verifier.

What Rust changes is the **developer experience** of writing, debugging, and deploying those programs. That is what we are examining for the rest of this talk.

---

### Slide 26 · eBPF Maps: The Data Bridge

`[QUICK for this audience — they know maps cold]`

Maps are the primary communication channel between kernel eBPF code and userspace. You know this well.

One point relevant to the Rust section ahead: the **ring buffer** (`RINGBUF`, Linux 5.8) integrates directly with Rust's async model. Aya exposes it as `AsyncFd<RingBuf>`, which plugs natively into Tokio. This is not just an ergonomics improvement — it is a **performance architecture change** we will come back to.

---

### Slide 27 · eBPF Framework Landscape: Three Generations

`[QUICK — they lived through this evolution]`

- **Generation 1 (BCC/bpftrace):** Full Clang/LLVM on the target at runtime. Development tool only — 100+ MB toolchain on a BSP is untenable.
- **Generation 2 (libbpf + CO-RE):** Compile once, ship a small pre-compiled object and `libbpf.so`. The previous talk covered this.
- **Generation 3 (language-native frameworks):** Aya (pure Rust), cilium/ebpf (pure Go), libbpf-rs (Rust bindings over libbpf). First-class language integration: type system, package managers, native async, single binary.

Our focus: **Aya** — the only framework that gives you one language, one toolchain, and zero C runtime dependencies from kernel code to userspace loader.

---

### Slide 28 · What Popular Projects Use

`[QUICK]`

Cilium is the clearest industry signal. They chose Go for their userspace loader specifically to avoid `libbpf.so` at runtime — building `cilium/ebpf` as a pure Go replacement. The industry trend is away from shared C loader libraries toward language-native loaders.

**Aya is the Rust equivalent of that choice.**

Production Aya deployments today: Red Hat bpfman (eBPF lifecycle manager), Deepfence ebpfguard (LSM policies in Rust), Kubernetes Blixt (XDP load balancer). All three share the same motivation: type safety across the kernel/userspace boundary and single-binary deployment.

---

### Slide 29 · libbpf + CO-RE: The Reference Workflow

`[QUICK — they know this, use it to set up the contrast]`

Your team already knows this workflow from the previous talk. I am showing it here to set up a direct comparison, not to teach it.

The two friction points worth holding in mind for what comes next:

1. **Build complexity:** Clang → BPF object → bpftool skeleton → GCC/Clang userspace loader. Multiple separate tools, multiple stages.
2. **Target dependencies:** `libbpf.so` → `libelf.so` → `libz.so`. This chain is the embedded deployment problem.

And the teardown risk in C:
```c
ring_buffer__free(rb);    // must not forget
skel__detach(skel);       // must not forget
skel__destroy(skel);      // must not forget
// No compiler warning if any of these are missing
```

---

### Slide 30 · Why CO-RE Matters for BSP Teams

`[QUICK — they know CO-RE, just acknowledge and move]`

You know this already. Your kernels ship at different versions to different OEMs. CO-RE's relocation mechanism — reading `/sys/kernel/btf/vmlinux` at load time and patching offsets — is what makes one binary portable across kernel versions.

The Aya-specific point: Aya implements CO-RE in **pure Rust** via `aya-obj`, its own BTF parser and relocation engine. This means no `libelf.so` and no `libz.so` on the target. The same CO-RE semantics, without the C library dependency chain.

Requirement unchanged: `CONFIG_DEBUG_INFO_BTF=y` in the target kernel.

---

### Slide 31 · Does Rust Fit eBPF?

`[FULL — this is the core of the talk the team head requested]`

**Why Rust and eBPF are a natural match:**

Both operate under the same fundamental constraint: **no undefined behavior is acceptable**.

- The BPF verifier rejects programs it cannot prove safe.
- Rust's type system rejects programs it cannot prove safe.
- Both enforce this before the code runs, not at runtime.

Rust's `#![no_std]` mode is the natural fit for the eBPF kernel side — no standard library, no allocator, just core primitives. `aya-ebpf` provides the BPF helpers, map types, and program macros for this restricted environment.

**The highest-value safety property:**

The most expensive eBPF bug class in C is a silent struct layout divergence between the kernel program and the userspace loader. You have probably seen this:

```c
// BPF program (C):
struct event { u64 ts; u32 pid; };

// Userspace loader (C) — different file:
struct event { u64 ts; u64 pid; }; // u64 ≠ u32
// Reads wrong data. No compile error. No warning.
```

The two definitions live in separate files. The C compiler has no mechanism to catch this. The ring buffer silently delivers misaligned data to userspace, and you spend hours with `bpf_printk` and gdb before finding the struct divergence.

**Aya's solution:** one `#![no_std]` **common crate**, compiled into both sides. The struct is defined once. Layout disagreement is a **compile error, not a runtime bug.**

This is not just convenience — it is the most practically impactful safety guarantee for teams actively writing eBPF programs.

---

### Slide 32 · Bytecode Generation: C vs. Rust Toolchain

`[FULL]`

**C/libbpf toolchain:**
```
program.bpf.c
    → clang -target bpf -O2 -g
    → program.bpf.o (ELF + BTF)
    → bpftool gen skeleton
    → program.skel.h
    → gcc / clang (host)
    → program binary
```
Requires: clang, LLVM, bpftool, libelf, libbpf. Even if your userspace is in Rust (`libbpf-rs`), you still need the full C toolchain for the BPF kernel code.

**Aya/Rust toolchain:**
```
*-ebpf/src/main.rs    (kernel side)
*-common/src/lib.rs   (shared types)
*/src/main.rs         (userspace side)
    → rustc --target bpfel-unknown-none + bpf-linker
    → ELF object (embedded via include_bytes_aligned!)
    → cargo build (host)
    → single self-contained binary
```
Requires: `rustc` (nightly) + `bpf-linker`. No clang, no bpftool, no libelf, no C toolchain. The BPF ELF is embedded in the userspace binary at build time — one artifact to ship.

---

### Slide 33 · Execution Model: What Actually Changes

`[FULL — important for skeptical engineers]`

This is the slide for engineers who will immediately ask: "Is this just a different frontend, or does it change something fundamental?"

Answer: **Rust changes the developer experience, not the kernel-side execution model.**

Look at the right side of the diagram. Both libbpf and Aya:
- Implement CO-RE
- Consume BTF from `/sys/kernel/btf/vmlinux`
- Perform relocations at load time
- Generate adjusted BPF bytecode
- Submit through the same kernel verifier

From the kernel's perspective, there is zero difference. The verifier sees BPF instructions. It does not know or care about the source language.

The differences are on the build side and the userspace side:
- libbpf: eBPF in C, compiled with Clang. Userspace loader in C wrapping libbpf APIs.
- Aya: eBPF in Rust, compiled with rustc + bpf-linker. Userspace loader in Rust using Aya APIs.

If you already understand libbpf and CO-RE, you already understand Aya's runtime architecture. The deployment model is the same. What changes is everything on the developer-facing side.

---

### Slide 34 · Rust Approaches: libbpf-rs vs Aya

`[FULL]`

When adopting Rust for eBPF, there are two distinct strategies:

**libbpf-rs:** Rust bindings over the existing C libbpf library.
- BPF kernel side: still C, still compiled with Clang
- Userspace: Rust wrapping libbpf via `libbpf-sys`
- `libbpf.so` + `libelf.so` still required on the target
- Good for: teams with existing C eBPF code wanting only userspace Rust

**Aya:** Pure-Rust reimplementation of the entire BPF syscall layer.
- BPF kernel side: Rust, compiled with `rustc + bpf-linker`
- Userspace: pure Rust, built on `libc` only — zero C library dependencies
- CO-RE via `aya-obj` — pure-Rust BTF parser
- Async-native: `AsyncFd<RingBuf>` integrates directly with Tokio
- Deployable as a single statically-linked binary with musl

**For embedded and Android targets:** Aya's musl static binary advantage eliminates the `libelf` / `libz` / `libbpf` version management problem entirely.

This session focuses on Aya. For your team's embedded goals, the single-binary deployment with no C runtime dependencies is the highest practical value.

---

### Slide 35 · Aya Framework Architecture

`[FULL]`

The Aya crate family maps directly to what you already use:

| Aya crate | Replaces |
|---|---|
| `aya` | `libbpf.so` + skeleton loader |
| `aya-obj` | `libelf.so` + `libz.so` + libbpf ELF parser |
| `aya-ebpf` | `bpf_helpers.h` + `bpf/bpf_tracing.h` |
| `aya-log` | Custom ring buffer log consumer |
| `aya-log-ebpf` | `bpf_printk()` — but ring-buffer based, not tracefs |
| `aya-tool` | `bpftool btf dump … format c > vmlinux.h` |
| `aya-build` | `bpftool gen skeleton` + Makefile integration |
| Common crate | Manually-matched C header in both files |

**Zero C runtime dependencies on the target.** The entire stack is Rust + one `bpf()` syscall. No `libelf.so`, no `libz.so`, no `libbpf.so`.

---

### Slide 36 · Aya for Embedded and Android: The musl Advantage

`[FULL — directly addresses embedded deployment pain]`

A libbpf-based tool ships as a dynamically-linked binary requiring three libraries on the target:
```
/usr/bin/my-tracer      → linked to:
/usr/lib/libbpf.so.1    → must exist on target
/usr/lib/libelf.so.1    → must exist on target
/usr/lib/libz.so.1      → must exist on target
```

On a minimal embedded rootfs or Android:
- `libelf` is usually absent — it is a development library, not a production one
- `libbpf` version on the device may not match what you compiled against
- Android's linker namespace rules can block unrecognized shared libraries
- Cross-compiling for ARM64 or RISC-V requires maintaining cross-compiled versions of all three `.so` files

**Aya + musl gives you one self-contained binary:**
```bash
rustup target add aarch64-unknown-linux-musl
cargo install cross
cross build --release --target aarch64-unknown-linux-musl

# Result: ELF 64-bit, ARM aarch64, statically linked, stripped

adb push my-tracer /data/local/tmp/
adb shell chmod +x /data/local/tmp/my-tracer
adb shell /data/local/tmp/my-tracer
```

One file. No library management. No version conflicts. Combined with CO-RE, this binary runs on any ARM64 Linux kernel with `CONFIG_DEBUG_INFO_BTF=y` — custom BSP, GKI Android, any OEM variant.

---

### Slide 37 · How Rust Improves the eBPF Development Experience

> **[PRESENTER NOTE — this is the slide the team head asked for. Spend the most time here.]**

`[FULL]`

Here are the six concrete improvements Rust and Aya bring over the C/libbpf workflow you already know:

---

**① Shared Common Crate — Cross-Boundary Type Safety**

The struct layout divergence bug described earlier is eliminated structurally.

In C, your kernel BPF code and userspace loader live in separate files with separately-defined structs that the compiler has no way to cross-check. Layout divergence compiles silently and produces wrong data at runtime.

In Aya, you define `DmaEvent` once in a shared `no_std` common crate:
```rust
// *-common/src/lib.rs — compiled into BOTH sides
#[repr(C)]
pub struct DmaEvent {
    pub ts_ns:    u64,
    pub pid:      u32,
    pub duration: u32,
}
```
Both the kernel program and userspace loader import this exact module. If you change a field type, both sides update automatically. Layout disagreement is a **compile error**. This eliminates the most common and hardest-to-debug eBPF integration bug.

---

**② RAII Attachment Handles — Zero Leak Risk**

In C, you are responsible for manual cleanup on every exit path:
```c
ring_buffer__free(rb);
skel__detach(skel);
skel__destroy(skel);
// No warning if you forget any of these
```

In Aya, the attachment handle implements Rust's `Drop` trait:
```rust
let _link = prog.attach("dma_map_sg", 0)?;
// _link goes out of scope → eBPF program automatically detached
// File descriptors automatically closed
// Works on normal exit, early return, or error propagation
```

The `_link` variable is the attachment. As long as it is alive, the hook is active. When it goes out of scope — whether the program exits normally, returns early via `?`, or panics — Rust guarantees the eBPF program is detached and the fd is closed. **You cannot leak this.**

---

**③ `Result` Types — No Silent Verifier Failures**

In C, if the kernel verifier rejects your BPF program, you get a negative return code from the load function. If that code is not checked, your program continues as if loading succeeded, then silently fails at event attachment.

In Aya, `Ebpf::load()` returns `Result`. Ignoring it is a compiler warning (hard error in release builds). The `?` operator propagates failures immediately with a typed error that includes the verifier log:
```rust
let mut bpf = Ebpf::load(BPF_BYTES)?;
// If the verifier rejects the program, this returns
// Err with the full verifier output — immediately.
// Cannot be silently ignored.
```

---

**④ Async Ring Buffer — Performance Architecture, Not Just Ergonomics**

This is the point most relevant to your performance tuning work.

In C, consuming from the ring buffer uses a synchronous polling loop:
```c
rb = ring_buffer__new(bpf_map__fd(map), handle_event, NULL, NULL);
while (1) {
    ring_buffer__poll(rb, 100 /* ms timeout */);
    // Thread blocks here for up to 100ms
    // CPU cycles consumed even when no events arrive
}
```

In Aya with Tokio:
```rust
let afd = AsyncFd::new(ring_buf)?;
loop {
    let mut guard = afd.readable().await?;
    // Thread yields to the OS scheduler — zero CPU cycles wasted
    // Kernel wakes the thread exactly when new events arrive
    while let Some(item) = guard.get_inner_mut().next() {
        let event = unsafe { &*(item.as_ptr() as *const DmaEvent) };
        process(event);
    }
    guard.clear_ready();
}
```

`afd.readable().await` does not burn CPU cycles waiting. The thread yields to the async runtime and the OS only wakes it when the kernel signals the ring buffer fd as readable. This is not just a cleaner API — it changes the CPU utilization profile of your userspace consumer, which matters when you are running this alongside the hardware workload you are monitoring.

---

**⑤ Typed Program Kinds — No Silent Attachment Errors**

In C, attaching an eBPF program uses untyped function calls. Passing the wrong hook arguments or attaching an XDP program with kprobe arguments produces a runtime failure, not a build error.

In Aya, the program type is enforced at the type level:
```rust
// The compiler forces you to prove this is a KProbe before calling attach()
let prog: &mut KProbe = bpf.program_mut("dma_map_sg")?.try_into()?;
prog.attach("dma_map_sg", 0)?;
// try_into() fails at runtime with a typed error if the bytecode
// is actually an XDP program — not a silent misbehavior
```

The wrong program kind produces a typed error, not undefined behavior.

---

**⑥ Structured `aya-log` — Kernel Logging Without tracefs Parsing**

In C, `bpf_printk()` writes to the global kernel trace pipe at `/sys/kernel/debug/tracing/trace_pipe`. Reading it requires a separate reader process, and the output is a raw text stream mixed with everything else writing to that global buffer.

In Aya:
```rust
// Kernel side:
info!(&ctx, "dma_map_sg called: pid={}, duration_ns={}", pid, duration_ns);

// Userspace side — receives structured log into your normal logging framework:
EbpfLogger::init(&mut bpf)?;
// Messages appear via env_logger, tracing, or any standard Rust logger
```

`aya-log-ebpf` uses a dedicated ring buffer — not the global tracefs pipe. Your kernel log messages arrive directly in your userspace application's logging framework, with timestamp, level, and message, exactly like debugging normal userspace code. No separate `cat /sys/kernel/debug/...` reader. No shared buffer contention with other kernel subsystems.

---

### Slide 38 · Project Setup: Prerequisites and Scaffold

`[FULL]`

One-time environment setup:

```bash
# 1. Nightly Rust — required for the bpfel-unknown-none target
rustup toolchain install nightly
rustup component add rust-src --toolchain nightly

# 2. bpf-linker — includes LLVM BPF backend, translates Rust output to BPF bytecode
cargo install bpf-linker

# 3. cargo-generate — creates new projects from templates
cargo install cargo-generate

# 4. Verify BPF target is available
rustc --print target-list | grep bpf
# Expected: bpfel-unknown-none, bpfeb-unknown-none
```

Scaffolding a new project:
```bash
cargo generate https://github.com/aya-rs/aya-template
# Prompts for project name, e.g.: dma-latency-tracer
# Generates: dma-latency-tracer-ebpf/, dma-latency-tracer-common/, dma-latency-tracer/
```

Build the entire project — one command:
```bash
cargo build --release
# build.rs inside the userspace crate automatically:
# 1. Compiles the eBPF crate with nightly + bpf-linker
# 2. Embeds the BPF bytecode via include_bytes_aligned!
# 3. Produces one self-contained binary
```

No xtask. No Makefile. No separate skeleton generation step.

---

### Slide 39 · Project Layout: Three-Crate Workspace

`[FULL]`

```
dma-latency-tracer/
├── Cargo.toml              # Workspace root — ties all three crates together
├── rust-toolchain.toml     # Pins nightly version — same compiler for the whole team
│
├── dma-latency-tracer-common/   # Shared types — compiled into BOTH sides
│   └── src/lib.rs
│       #![no_std]
│       #[repr(C)]
│       pub struct DmaEvent { pub ts_ns: u64, pub pid: u32, ... }
│
├── dma-latency-tracer-ebpf/     # Kernel-side BPF program
│   ├── .cargo/config.toml
│   │   target = "bpfel-unknown-none"     # little-endian BPF processor
│   │   "-C", "link-arg=--btf"           # emit BTF for CO-RE
│   │   build-std = ["core"]             # compile core from source (no prebuilt for BPF)
│   └── src/main.rs
│       #![no_std] #![no_main]
│       #[kprobe] pub fn dma_map_sg(ctx: ProbeContext) -> u32 { ... }
│
└── dma-latency-tracer/          # Userspace loader (std, async, Tokio)
    ├── build.rs                 # Compiles eBPF crate, embeds bytecode
    └── src/main.rs
        Ebpf::load(include_bytes_aligned!(...))
```

The `rust-toolchain.toml` file is important for team consistency — it pins the exact nightly version so every engineer compiles with identical toolchain settings.

---

### Slide 40 · BPF Program Side: Key Patterns

`[FULL]`

| Pattern | C / libbpf | Rust / Aya |
|---|---|---|
| Entry point | `SEC("kprobe/dma_map_sg")` string macro | `#[kprobe]` attribute macro |
| Context handling | `PT_REGS_PARM1(ctx)`, `BPF_KPROBE` macros | Typed `ProbeContext`, `XdpContext` structs |
| Map interaction | `bpf_map_update_elem(&map, &k, &v, flags)` | `MAP.insert(&k, &v, flags)` |
| Unsafe boundaries | All pointer access looks identical | Kernel memory reads explicitly in `unsafe { }` |

**Entry points:** `SEC("kprobe/...")` strings are unchecked. A typo is a runtime attachment failure. `#[kprobe]` is checked by the compiler pipeline — invalid hook declarations fail at build time.

**Context objects:** In C, extracting parameters from a kprobe requires architecture-specific macros like `PT_REGS_PARM1(ctx)` that depend on the CPU register layout. In Aya, `ProbeContext` and `XdpContext` expose typed methods — no architecture-specific register definitions.

**Map operations:** C requires global helper function calls with raw pointer arguments. Aya maps are declared as static variables with `#[map]` and expose object-oriented methods — `MAP.insert()`, `MAP.get()`. Reads like userspace code.

**Unsafe isolation:** In C, reading kernel memory and reading local stack variables look identical syntactically. In Aya, reading external kernel memory goes inside `unsafe { }`. During code review, the unsafe boundaries are immediately visible — exactly the grep-able audit surface we described earlier, now applied inside eBPF programs.

---

### Slide 41 · Userspace Loader: Load, Attach, Consume

`[FULL — the teardown section is the strongest point here]`

Three phases, with a direct C vs. Rust comparison:

**Phase 1 — Load:**
- C: `prog_open()` → `prog_load()` — procedural skeleton calls with raw structs.
- Rust: `Ebpf::load(BPF_BYTES)?` — single call. Bytes are embedded in the binary at build time. Type-safe downcast: `.try_into::<KProbe>()` fails immediately if the bytecode kind does not match.

**Phase 2 — Attach:**
- C: `prog__attach(skel)` returns an fd inside the skeleton object.
- Rust: `prog.attach("dma_map_sg", 0)?` returns a typed `_link` handle. This handle's lifetime is tracked by the borrow checker. The program stays attached as long as `_link` is alive.

**Phase 3 — Consume (the ring buffer):**

C uses a synchronous blocking callback:
```c
rb = ring_buffer__new(fd, handle_event, NULL, NULL);
while (1) {
    ring_buffer__poll(rb, 100);  // blocks; burns CPU; NULL context
}
```

Aya uses async event-driven consumption:
```rust
let afd = AsyncFd::new(ring_buf)?;
loop {
    let mut guard = afd.readable().await?;  // yields; zero CPU; kernel wakes on data
    while let Some(item) = guard.get_inner_mut().next() {
        let event: &DmaEvent = unsafe { &*(item.as_ptr() as *const DmaEvent) };
        // event is typed — DmaEvent from the shared common crate
    }
}
```

The `await` yields the thread to the OS scheduler. The kernel file descriptor mechanism wakes it exactly when the ring buffer has data. No timeout loop. No CPU cycles burned polling. This is particularly relevant when your userspace consumer is running on a system you are also trying to measure — the observer's CPU cost affects the measurement.

**Phase 4 — Teardown (the hidden benefit):**

Look at the bottom of the C code. You must explicitly call `ring_buffer__free()`, `prog__detach()`, `prog__destroy()`. If your program returns early via an error before reaching these lines, resources leak. No compiler warning.

In the Rust code, there is **zero cleanup code written**. `bpf`, `_link`, and `afd` all implement `Drop`. The moment the event loop ends — normal exit, early return via `?`, or panic — Rust guarantees all file descriptors are closed and all kernel hooks are detached. **Automatically. For free.**

---

### Slide 42 · Hello XDP: Generated BPF Program

`[FULL]`

The Aya template generates a working XDP program. Walk through the structure:

```rust
#![no_std]
#![no_main]

use aya_ebpf::{bindings::xdp_action, macros::xdp, programs::XdpContext};
use aya_log_ebpf::info;

#[xdp]
pub fn hello_xdp(ctx: XdpContext) -> u32 {
    match try_hello_xdp(ctx) {
        Ok(ret) => ret,
        Err(_) => xdp_action::XDP_ABORTED,
    }
}

fn try_hello_xdp(ctx: XdpContext) -> Result<u32, u32> {
    info!(&ctx, "received a packet");
    Ok(xdp_action::XDP_PASS)
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}
```

One line of actual logic: `info!(&ctx, "received a packet")`. The rest is Rust infrastructure — the `#[xdp]` macro registers the entry point, `Result<u32, u32>` gives idiomatic error handling, `#[panic_handler]` is required by `no_std`.

Note the `try_hello_xdp` pattern — wrapping the logic in a function returning `Result` means you can use `?` for early error returns inside XDP programs, which is significantly cleaner than C's manual return-code checking inside hook functions.

---

### Slide 43 · Build and Test

`[QUICK]`

```bash
cargo build --release
sudo RUST_LOG=hello_xdp=info ./target/release/hello-xdp

# Other terminal:
ping 8.8.8.8
```

Expected output — every log line is a packet processed by the kernel BPF program, delivered via the dedicated aya-log ring buffer to your userspace logger. No tracefs. No `cat /sys/kernel/debug/tracing/trace_pipe`.

---

### Closing Focus Slide

**Aya is not a wrapper around libbpf.**

**It is a reimplementation — in Rust, for Rust.**

One language. One toolchain. One binary.
Type-safe across the kernel/userspace boundary.
Deploy anywhere Linux + BTF exist.

---

## APPENDIX

---

### A1 · aya-tool: Generating Kernel Type Bindings

```bash
cargo install aya-tool

# Generate Rust bindings for kernel structs from running kernel's BTF
# Equivalent of: bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
# But produces a Rust module:
aya-tool generate task_struct > dma-latency-tracer-ebpf/src/vmlinux.rs

# In BPF program:
// mod vmlinux;
// use vmlinux::task_struct;
```

---

### A2 · CO-RE in Aya: The Relocation Chain

```
BPF program (Rust):
  uses: bpf_core_read!(task, pid)
  rustc + bpf-linker emit:
    → BTF_CO-RE relocations in the BPF ELF
    → .BTF section with type information

At Ebpf::load() time (Aya):
  1. aya-obj parses the BPF ELF (pure Rust — no libelf)
  2. Reads /sys/kernel/btf/vmlinux
  3. For each CO-RE relocation:
     looks up field offset in the RUNNING kernel's BTF
  4. Patches BPF bytecode with correct offset
  5. Submits via bpf() syscall → verifier → JIT

Result: one binary. Runs on kernel 5.15, 6.1, 6.6, 6.12 —
        any kernel where CONFIG_DEBUG_INFO_BTF=y
```

---

### A3 · Getting Started with Rust

```bash
# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install nightly + components
rustup toolchain install nightly
rustup component add rustfmt clippy rust-analyzer

# Recommended learning path for C/kernel developers:
# - The Rust Programming Language (free): https://doc.rust-lang.org/book/
# - Rustlings (interactive exercises): https://rustlings.cool
# - Comprehensive Rust (Google, Android focus): https://google.github.io/comprehensive-rust/
# - Aya book: https://aya-rs.dev/book/
```

---

### A4 · References

**Aya framework**
- Aya book: https://aya-rs.dev/book/
- API docs: https://docs.rs/aya
- awesome-aya: https://github.com/aya-rs/awesome-aya
- FOSDEM 2025: "Building your eBPF Program with Rust and Aya" — https://archive.fosdem.org/2025/schedule/event/fosdem-2025-5534-building-your-ebpf-program-with-rust-and-aya/

**libbpf and CO-RE**
- libbpf overview: https://docs.kernel.org/bpf/libbpf/libbpf_overview.html
- CO-RE reference guide: https://nakryiko.com/posts/bpf-core-reference-guide/

**Framework landscape**
- cilium/ebpf (Go): https://github.com/cilium/ebpf
- libbpf-rs: https://github.com/libbpf/libbpf-rs

**Production Aya deployments**
- Red Hat bpfman: https://bpfman.io
- Deepfence ebpfguard: https://github.com/deepfence/ebpfguard
- Kubernetes Blixt: https://github.com/kubernetes-sigs/blixt

**Formal verification**
- Jung et al., "RustBelt: Securing the Foundations of the Rust Programming Language." POPL 2018.

**eBPF fundamentals**
- Gregg, B. *BPF Performance Tools.* Addison-Wesley, 2019.
