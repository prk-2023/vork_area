// ─────────────────────────────────────────────────────────────────────────────
//  Introduction to Rust
//  Typst / Touying presentation · Metropolis theme
//
//  Audience : IC design house — kernel / BSP / C engineers, 5–30+ years
//  Scope    : Systems programming · Rust's fit · Ownership model ·
//             Borrowing & lifetimes · Security-focused language features
//
//  Build  :  typst compile intro-rust.typ intro-rust.pdf
//  Preview:  VS Code + Tinymist extension → open file → click preview
//
//  Packages auto-downloaded on first compile:
//    @preview/touying:0.7.1
//    @preview/numbly:0.1.0
// ─────────────────────────────────────────────────────────────────────────────

#import "@preview/touying:0.7.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

// ── Palette ───────────────────────────────────────────────────────────────────
#let rust-red    = rgb("#CE422B")   // Rust brand
#let rust-dark   = rgb("#1A1A1A")
#let safe-green  = rgb("#2D6A4F")   // safety / OK
#let warn-amber  = rgb("#854D0E")   // caution
#let ref-blue    = rgb("#1B4F8A")   // citations
#let code-bg     = rgb("#1E1E2E")   // code surface (Catppuccin Mocha)
#let code-fg     = rgb("#CDD6F4")
#let kw-col      = rgb("#CBA6F7")   // keywords
#let ok-col      = rgb("#A6E3A1")   // correct path
#let er-col      = rgb("#F38BA8")   // error path
#let hi-col      = rgb("#FAB387")   // highlighted token
#let cm-col      = rgb("#585B70")   // comments

// ── Design helpers ────────────────────────────────────────────────────────────

// Left-accent callout box
#let callout(body, color: rust-red) = block(
  fill:   color.lighten(90%),
  stroke: (left: 3pt + color),
  inset:  (left: 10pt, top: 7pt, bottom: 7pt, right: 9pt),
  radius: (right: 4pt),
  width:  100%,
  body,
)

// Citation badge
#let ref-badge(body) = box(
  fill:   ref-blue.lighten(88%),
  stroke: 0.4pt + ref-blue,
  inset:  (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: ref-blue, size: 0.59em, style: "italic", body),
)

// Two-column grid
#let cols(l, r, ratio: (1fr, 1fr)) = grid(
  columns: ratio, gutter: 1.2em, l, r,
)

// Dark code block with optional coloured title bar
#let code(body, title: none, accent: rust-red) = {
  if title != none {
    block(
      fill:   accent.lighten(88%),
      inset:  (x: 10pt, y: 4pt),
      radius: (top: 5pt),
      width:  100%,
      text(size: 0.63em, weight: "bold", fill: accent, title),
    )
  }
  block(
    fill:   code-bg,
    radius: if title != none { (bottom: 5pt) } else { 5pt },
    inset:  11pt,
    width:  100%,
    text(
      font: ("Fira Code", "JetBrains Mono", "Courier New"),
      fill: code-fg,
      size: 0.69em,
      body,
    ),
  )
}

// Numbered concept box used in the ownership section
#let concept-box(n, title, body, color: rust-red) = block(
  fill:   color.lighten(92%),
  stroke: 0.5pt + color.lighten(40%),
  radius: 6pt,
  inset:  10pt,
  width:  100%,
  stack(dir: ttb, spacing: 5pt,
    stack(dir: ltr, spacing: 8pt,
      circle(fill: color, radius: 9pt,
        align(center + horizon,
          text(fill: white, size: 0.65em, weight: "bold", str(n)))),
      text(size: 0.76em, weight: "bold", fill: color, title),
    ),
    text(size: 0.68em, fill: luma(30%), body),
  ),
)

// Side-by-side C / Rust comparison pair  (equal width, same height)
#let vs(c-body, r-body) = grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  code(c-body, title: "C", accent: warn-amber),
  code(r-body, title: "Rust", accent: safe-green),
)

// ── Theme ─────────────────────────────────────────────────────────────────────
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,

  config-colors(
    primary:          rust-red,
    primary-dark:     rust-red.darken(20%),
    primary-light:    rust-red.lighten(55%),
    secondary:        safe-green,
    neutral-lightest: rgb("#F9F8F6"),
    neutral-light:    rgb("#EBEBEA"),
    neutral-dark:     rgb("#3A3A3A"),
    neutral-darkest:  rust-dark,
  ),

  config-info(
    title:       [Introduction to Rust],
    subtitle:    [Systems Programming · Ownership Model · Safety-First Design],
    author:      [Your Name],
    date:        datetime.today(),
    institution: [IC Design Division],
  ),
)

#set text(font: ("Fira Sans","Noto Sans","Liberation Sans"), size: 19pt)
#show raw:  set text(font: ("Fira Code","JetBrains Mono","Courier New"), size: 0.82em)
#show link: set text(fill: rust-red)
#set heading(numbering: numbly("{1}.", default: "1.1"))

// ─────────────────────────────────────────────────────────────────────────────
//  TITLE SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#title-slide()

// ─────────────────────────────────────────────────────────────────────────────
//  AGENDA
// ─────────────────────────────────────────────────────────────────────────────
== Agenda <touying:hidden>
#outline(title: none, indent: 1.5em, depth: 1)

// ─────────────────────────────────────────────────────────────────────────────
//  1. WHAT IS SYSTEMS PROGRAMMING?
// ─────────────────────────────────────────────────────────────────────────────
= What Is Systems Programming?

== Defining the domain your team works in

#cols[
  *Systems software controls hardware and mediates between it and everything else.*

  It is characterised by three constraints that *no other software domain shares simultaneously*:

  1. *Direct hardware access* — memory-mapped registers, DMA engines, interrupt controllers
  2. *No managed runtime* — no garbage collector, no VM, no OS safety net beneath you
  3. *Correctness is load-bearing* — a bug does not crash one user session; it crashes the whole system, corrupts flash, or silently misdelivers data to hardware

  *Your daily work is systems programming:*
  - Peripheral drivers (PCIe, MIPI, USB, UART, I2C, SPI)
  - DMA engine bring-up, scatter-gather list management
  - Power management (DVFS, clock trees, voltage domains)
  - Boot firmware, UEFI / PSCI, secure monitor
  - Android HAL native layer, Binder IPC, ION heap management
][
  *The languages that have historically owned this domain*

  #table(
    columns: (auto, auto, auto, auto),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 6pt),
    [*Language*], [*Domain*], [*Memory safe?*], [*No GC?*],
    [Assembly], [firmware, boot], [✗], [✓],
    [C],         [OS, drivers, embedded], [✗], [✓],
    [C++],       [firmware, RTOS, Android HAL], [✗ ¹], [✓],
    [Ada/SPARK], [aerospace, defence], [✓ ²], [✓],
    [Go],        [tooling, cloud], [✓], [✗],
    [*Rust*],    [*all of the above*], [*✓*], [*✓*],
  )

  #text(size: 0.6em, fill: luma(100))[
    ¹ RAII helps; raw pointers escape freely.\
    ² SPARK subset only; tiny ecosystem.
  ]

  #callout(color: safe-green)[
    Rust is the first language to occupy the *top-right cell simultaneously* — memory safety *and* no GC — with a formally verified type system. #ref-badge[Jung et al., RustBelt, POPL 2018]
  ]
]

== The cost of the status quo — in numbers

#cols[
  *Industry-wide memory safety statistics*

  #table(
    columns: (auto, 1fr, auto),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Source*], [*Finding*], [*Year*],
    [Microsoft MSRC], [~70 % of all CVEs are memory safety bugs], [2019],
    [Chrome team], [~70 % of high-severity bugs are memory safety], [2020],
    [Linux kernel], [~67 % of CVEs are memory safety violations], [2019],
    [Android team], [Memory unsafety estimated at \$68B in security costs], [2021],
    [NSA guidance], [C and C++ flagged as "memory-unsafe" languages], [2022],
    [CISA], ["The Case for Memory Safe Roadmaps" — mandates shift], [2023],
  )

  #ref-badge[Microsoft MSRC 2019; Google Project Zero 2020; Linux Security Summit 2019; CISA 2023]
][
  *The bug classes that drive these numbers*

  - *Use-after-free (UAF)* — most common kernel CVE class: IRQ handler retains a pointer to freed `struct device`
  - *Buffer overflow / OOB write* — DMA descriptor overrun corrupts adjacent kernel data
  - *Null dereference* — `container_of()` result not checked, dereferenced in probe path
  - *Data race* — two CPUs write a shared DMA counter without a lock
  - *Uninitialised read* — `struct` field read before all error paths initialise it
  - *Integer overflow* — `nents * sizeof(entry)` wraps; under-allocated scatter-gather list

  #callout[
    These are not exotic bugs requiring adversarial inputs. *They are the everyday bugs your team debugs during SoC bring-up.* KASAN, KCSAN, and lockdep catch them at runtime — Rust prevents them at compile time.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. HOW RUST FITS SYSTEMS PROGRAMMING
// ─────────────────────────────────────────────────────────────────────────────
= How Rust Fits Systems Programming

== The three properties that make Rust a systems language

#cols[
  *Property 1 — No garbage collector, no runtime*

  Rust has no GC, no reference-counting runtime, no background threads, no stop-the-world pause. The memory model is:

  - Stack allocation: zero overhead — exactly like C `int x;`
  - Heap allocation: explicit, backed by the allocator you choose
  - Destructor: called at a *statically known point* by the compiler, not by a runtime at an unpredictable time

  This means Rust code can run:
  - In interrupt handlers (ISR context)
  - In firmware before the MMU is enabled
  - In a `#![no_std]` kernel module with no OS beneath it
  - On a bare-metal microcontroller with 16 KB of RAM

  *The binary output is a standard ELF — same format as a C object file.* A Rust kernel module is a `.ko` that `insmod`, `lsmod`, and `rmmod` treat identically.
][
  *Property 2 — Direct hardware access*

  Rust can do everything C can at the hardware interface:

  ```rust
  // Memory-mapped I/O register write
  // (identical to: *(volatile u32*)CTRL_REG = 0x1;)
  unsafe {
      core::ptr::write_volatile(
          CTRL_REG as *mut u32, 0x1
      );
  }

  // Inline assembly — same as GNU C __asm__ __volatile__
  use core::arch::asm;
  unsafe {
      asm!("dsb sy", options(nostack));
  }

  // Raw pointer arithmetic — same as C, explicitly unsafe
  let ptr = base_addr as *mut u32;
  unsafe { *ptr.add(offset) = value; }
  ```

  `unsafe { }` is not "turn off Rust" — it is an *explicit declaration* that you are taking responsibility for the invariants the type system cannot verify. It is grep-able, auditable, and contained.
]

== Property 3 — Zero-cost abstractions

#cols[
  *The Stroustrup principle, applied*

  > "What you don't use, you don't pay for. What you do use, you couldn't hand-code any better."

  Rust's abstractions compile to the same machine code as the equivalent hand-written C. This is not a promise — it is verifiable on Compiler Explorer.

  *Iterators and closures — no overhead*

  ```rust
  // High-level, expressive:
  let total: u64 = latencies
      .iter()
      .filter(|&&ns| ns > threshold)
      .sum();

  // Compiles to exactly this loop — same as C:
  let mut total: u64 = 0;
  for &ns in &latencies {
      if ns > threshold { total += ns; }
  }
  // Godbolt: identical ADDQ loop in both cases
  ```
  #ref-badge[Compiler Explorer — godbolt.org; rustc -O2]
][
  *Generics — monomorphisation, not boxing*

  ```rust
  // One generic function:
  fn min_of<T: Ord>(a: T, b: T) -> T {
      if a <= b { a } else { b }
  }

  // Compiler generates TWO specialised versions:
  // min_of::<u32>(a: u32, b: u32) -> u32
  // min_of::<u64>(a: u64, b: u64) -> u64
  // No vtable. No boxing. No indirection.
  ```

  *Lifetime annotations are erased before codegen*

  ```rust
  // 'a is compile-time analysis only — zero runtime cost:
  fn longest<'a>(x: &'a [u8], y: &'a [u8]) -> &'a [u8] {
      if x.len() >= y.len() { x } else { y }
  }
  // Generates: same two-compare, one-return instruction
  //            sequence as the C pointer version
  ```

  #callout(color: safe-green)[
    Borrow checking, lifetime analysis, type inference — all stripped before LLVM sees the code. *The runtime binary is as lean as hand-written C.*
  ]
]

== The aliasing advantage — Rust beats C's optimiser

This is the often-overlooked performance *advantage* Rust has *over* C.

#cols[
  *The C aliasing problem*

  C's pointer aliasing rules (C99 §6.5) say two pointers of different types *may not* alias — but two `u8*` pointers *might* always alias. The compiler must assume they overlap.

  ```c
  // C: compiler cannot vectorise safely
  // because it cannot prove src ≠ dst
  void process(uint8_t *dst,
               const uint8_t *src, size_t n) {
      for (size_t i = 0; i < n; i++)
          dst[i] = src[i] | 0x80;
  }
  // Must add `restrict` keyword AND trust the caller
  void process(uint8_t *restrict dst,
               const uint8_t *restrict src, size_t n);
  // restrict is a promise, not a proof
  ```
][
  *Rust's aliasing proof*

  Rust's exclusivity rule (`&mut T` is exclusive — no other reference exists) *proves* at compile time that `out` and `in_buf` do not overlap. LLVM gets this information and auto-vectorises without any annotation.

  ```rust
  // Rust: exclusive borrow PROVES no overlap
  // Compiler auto-vectorises — no annotation needed
  fn process(out: &mut [u8], in_buf: &[u8]) {
      for (o, &b) in out.iter_mut().zip(in_buf) {
          *o = b | 0x80;
      }
  }
  // Generated: VPOR ymm loop (AVX2)
  // No restrict. No trust. The type system proved it.
  ```

  #callout(color: safe-green)[
    The *same property* that prevents data races also enables better codegen. Safety and performance arise from the same source: the aliasing proof in the type system.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. OWNERSHIP — THE CORE PROGRAMMING MODEL
// ─────────────────────────────────────────────────────────────────────────────
= Ownership — A New Programming Model

== Why a new model was needed

#cols[
  *The C memory management contract*

  In C, the programmer mentally tracks two parallel states for every allocation:
  - The *data* itself (stored in memory)
  - *Who is responsible* for freeing it (stored in the programmer's head)

  This mental model does not survive:
  - Function calls that may retain a pointer
  - Error paths that return early
  - Interrupt handlers that fire asynchronously
  - Multi-author code where "who owns this?" is undocumented

  *The result:* every kernel driver `probe()` function contains a `goto err_free_X` chain to handle the cases the programmer remembered. CVEs happen when one path was forgotten.
][
  *Rust's answer: make ownership a language concept*

  Rust makes the "who is responsible" question *part of the type system*. The compiler tracks ownership the same way it tracks types — exhaustively, for every code path.

  Three rules, enforced at compile time:

  #concept-box(1, "Single owner",
    "Every value has exactly one owner at any moment.\nThe owner is responsible for the value's lifetime.", color: rust-red)
  #v(4pt)
  #concept-box(2, "Scope = lifetime",
    "When the owner's scope ends, the value is automatically freed.\nNo manual free(). No leak. No double-free.", color: rust-red)
  #v(4pt)
  #concept-box(3, "Move, don't copy",
    "Passing a value to a function transfers ownership.\nThe original variable becomes statically invalid.\nNo hidden copies. No refcount increment.", color: rust-red)
]

== Ownership eliminates use-after-free — the #1 kernel CVE class

#vs(
```c
// UAF — compiles fine, crashes in production
struct mlx5_wq *wq = alloc_wq(dev);
if (!wq) return -ENOMEM;

submit_dma(dev, wq);     // DMA started

kfree(wq);               // freed here

/* … 500 lines later … */
complete_dma(wq);        // UAF — wq is freed
/* gcc: no warning. KASAN: catches it IF
   this path is exercised in testing.       */
```,
```rust
let wq = WorkQueue::alloc(dev)?; // wq owns allocation

submit_dma(dev, &wq);   // borrow — wq still owns it

drop(wq);               // explicitly freed

// complete_dma(&wq);
// ^^^
// error[E0382]: borrow of moved value: `wq`
//   value borrowed here after move
//
// Caught BEFORE the binary exists.
// No KASAN required. No test case needed.
```
)

== Ownership eliminates goto-cleanup chains

The `goto err_free_X` pattern is a C idiom *invented to compensate* for the absence of automatic cleanup. Rust makes it structurally unnecessary.

#vs(
```c
int my_probe(struct pci_dev *pdev) {
    int ret;
    struct my_irq *irq = alloc_irq(pdev);
    if (!irq) { ret = -ENOMEM; goto err; }

    struct my_dma *dma = alloc_dma(pdev, 4096);
    if (!dma) { ret = -ENOMEM; goto err_free_irq; }

    struct my_bar *bar = map_bar(pdev, 0);
    if (!bar) { ret = -EINVAL; goto err_free_dma; }

    return 0;          // success

err_free_dma: free_dma(dma);
err_free_irq: free_irq(irq);
err:          return ret;
/* Miss one label → leak. Wrong order → double-free. */
}
```,
```rust
fn my_probe(pdev: &mut PciDev) -> Result<MyDrv> {
    // Each `?` is an early return on error.
    // Whatever has been allocated so far drops
    // automatically, in reverse order.
    let irq = MyIrq::alloc(pdev)?;
    let dma = MyDma::alloc(pdev, 4096)?;
    let bar = MyBar::map(pdev, 0)?;

    Ok(MyDrv { irq, dma, bar })

    // No labels. No error codes. No goto.
    // Compiler guarantees correct teardown
    // on every exit path — including paths
    // added six months from now by a different
    // engineer who never read this function.
}
```
)

#callout(color: safe-green)[
  `Drop` is called in *reverse construction order* — guaranteed by the compiler for *every* exit path. The equivalence to C++ RAII is exact; unlike C++, you cannot "escape" it by holding a raw pointer.
]

// ─────────────────────────────────────────────────────────────────────────────
//  4. BORROWING & LIFETIMES
// ─────────────────────────────────────────────────────────────────────────────
= Borrowing & Lifetimes

== Borrowing — temporary access without transferring ownership

Instead of transferring ownership, a function can *borrow* a value — receive temporary access without becoming the owner.

#cols[
  *Shared borrow — `&T` — read-only*

  ```rust
  fn print_stats(ring: &RingBuf) {
      // read-only access — ring is not consumed
      println!("entries: {}", ring.len());
  }

  let ring = RingBuf::new(1024);
  print_stats(&ring);   // borrow — ring survives
  print_stats(&ring);   // borrow again — fine
  // ring is still valid and usable here
  ```

  - *Many* shared borrows can coexist
  - None can mutate the data while borrowed
  - Kernel parallel: *RCU read-side critical section*

  #callout(color: safe-green)[
    While any `&T` exists, *no* `&mut T` can exist. This is the aliasing XOR mutability rule — enforced statically.
  ]
][
  *Exclusive borrow — `&mut T` — read-write*

  ```rust
  fn fill(ring: &mut RingBuf, data: &[u8]) {
      ring.write(data); // exclusive access
  }
  // `ring` is fully available again after fill() returns

  let mut ring = RingBuf::new(1024);
  fill(&mut ring, &payload);

  // You cannot do this:
  let r1 = &ring;
  // let w  = &mut ring; // ← error: ring is borrowed
  //                     //   as immutable — cannot
  //                     //   also borrow as mutable
  print_stats(r1);       // r1 used here
  ```

  - *Exactly one* exclusive borrow can exist at a time
  - No shared borrow can exist simultaneously
  - Kernel parallel: *spinlock held / write-lock held*

  #callout(color: safe-green)[
    There is *no runtime lock* being acquired here. The borrow checker *proves* the access is exclusive at compile time — zero overhead.
  ]
]

== Lifetimes — no reference outlives its data

Lifetimes are the compiler's mechanism for proving that *every reference is valid for its entire use*.

#cols[
  *What lifetimes prevent*

  ```rust
  // Dangling pointer — compile error:
  fn get_name() -> &str {
      let local = String::from("ConnectX-5");
      &local  // error[E0106]: missing lifetime
              // local is dropped at end of function
              // returning a reference to it would dangle
  }

  // Correct — lifetime 'a ties input to output:
  // "the returned reference lives as long as s"
  fn first_word<'a>(s: &'a str) -> &'a str {
      s.split_whitespace().next().unwrap_or("")
  }
  // If s is valid, the return is valid.
  // Compiler verifies this at every call site.
  ```
][
  *Lifetimes in kernel context*

  Every "dangling pointer to freed device" CVE is a lifetime violation.

  ```rust
  struct IrqHandler<'dev> {
      dev:  &'dev Device,   // 'dev = device's lifetime
      data: &'dev [u8],     // must not outlive device
  }

  // The compiler proves:
  // IrqHandler cannot outlive the Device it references.
  // device_unregister() → Device drops →
  // any IrqHandler<'dev> holding &'dev Device
  // becomes statically invalid before the drop.
  // There is no runtime check — the proof is structural.
  ```

  #callout[
    Lifetimes have *zero runtime representation*. They are erased before code generation. The safety is purely a compile-time proof.
    #ref-badge[Jung et al., POPL 2018 §2.3 — lifetime logic in λRust]
  ]
]

== Data races — eliminated by the type system

#cols[
  *The formal argument*

  A data race requires two conditions simultaneously:
  1. *Aliasing* — two pointers to the same memory location
  2. *Unsynchronised mutation* — at least one is writing

  Ownership rules make both conditions simultaneously impossible in safe code:
  - `&mut T` is exclusive → no aliasing while mutating
  - `&T` is immutable → no mutation while aliased

  *Therefore: if the program compiles, it has no data races.*

  This was *formally machine-checked* in Coq by RustBelt (POPL 2018), and extended to C11 relaxed-memory atomics by RustBelt Meets Relaxed Memory (POPL 2020).
  #ref-badge[Jung et al., POPL 2018; Dang et al., POPL 2020]
][
  #vs(
  ```c
  /* Data race — compiles, UB at runtime */
  uint64_t shared_counter;

  void *thread_a(void *_) {
      shared_counter++;   /* write */
      return NULL;
  }
  void *thread_b(void *_) {
      shared_counter++;   /* concurrent write */
      return NULL;        /* undefined behaviour */
  }
  /* gcc: no warning. ThreadSanitizer: catches it
     only if both threads execute concurrently. */
  ```,
  ```rust
  // Data race — compile error:
  let mut counter: u64 = 0;

  let t1 = thread::spawn(|| {
      counter += 1; // error[E0373]: closure may
  });               // outlive current function,
  let t2 = thread::spawn(|| { // but it borrows
      counter += 1; // `counter`, which is owned
  });               // by the current function
  // Caught BEFORE the binary exists.
  // Fix: Arc<AtomicU64> or Arc<Mutex<u64>>
  ```
  )
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. THE TYPE SYSTEM AS A SECURITY TOOL
// ─────────────────────────────────────────────────────────────────────────────
= The Type System as a Security Tool

== `Send` and `Sync` — thread safety in the type

#cols[
  *Two marker traits, zero runtime cost*

  - `Send`: a type can be safely *moved* to another thread
  - `Sync`: a type can be safely *shared* between threads via `&T`
  - Both are compile-time properties — no vtable, no runtime check

  *Automatic, conservative derivation*

  - `Rc<T>` — *not* `Send` (non-atomic refcount). The compiler refuses to let it cross a thread boundary.
  - `Arc<T>` — `Send` + `Sync` (atomic refcount). Safe to share.
  - `Cell<T>` — *not* `Sync` (interior mutability without lock).
  - `Mutex<T>` — `Sync` because `lock()` serialises access.

  #callout[
    Any type you write is automatically *not* `Send` + `Sync` unless all its fields are. This means the *safe default is conservative* — you opt in to thread sharing, you don't opt out of races.
  ]
][
  *Why this matters for BSP / driver teams*

  ```rust
  // Per-CPU data structure — must not cross CPU boundary
  struct PerCpuDmaStats {
      count: u64,
      total_ns: u64,
  }
  // PerCpuDmaStats contains no Sync interior mutability
  // → it is NOT Sync → compiler refuses global shared access

  // To share across CPUs: wrap in the correct primitive
  use std::sync::Arc;
  use kernel::sync::SpinLock;

  static SHARED: Arc<SpinLock<PerCpuDmaStats>> = …;

  // SpinLock<T> is Sync — its lock() method serialises.
  // You cannot access the data without the guard.
  // The guard is the only path to the inner T.
  ```

  In C: `/* must hold dma_stats_lock before accessing */` — a comment. In Rust: a compile error if the lock is not held — because the data is not reachable without it.
]

== `Option<T>` — null pointer elimination

Null pointer dereferences account for a significant share of kernel crashes. Rust's type system eliminates the possibility by making "might be absent" explicit in the type.

#vs(
```c
/* NULL dereference — common in probe paths */
struct resource *res =
    platform_get_resource(pdev, IORESOURCE_MEM, 0);
/* res might be NULL — easy to forget the check */

void __iomem *base = ioremap(res->start, res->end
                              - res->start + 1);
/* Null dereference if check was skipped → BUG() */
```,
```rust
// Option<T> forces explicit handling of "not found"
let res: Option<Resource> =
    pdev.get_resource(IORESOURCE_MEM, 0);

// Cannot access res.start without handling None first:
let base = match res {
    Some(r) => ioremap(r.start, r.size())?,
    None    => return Err(ErrKind::NoResource),
};
// After the match, `base` is definitely valid.
// There is no raw pointer to dereference unsafely.
```
)

#callout[
  `Option<&T>` has *identical machine representation* to a nullable pointer — one word, null = `None`, non-null = `Some`. Zero overhead. The safety is entirely in the type, not the runtime. #ref-badge[Rust Reference §3.1 — Niche optimisation]
]

== `Result<T, E>` — no silent error drops

#cols[
  *The C pattern and its failure mode*

  In C, every `int`-returning function can signal failure via a negative return. The compiler does not warn if the return value is discarded.

  ```c
  pci_enable_device(pdev);    /* error silently dropped */
  pci_request_regions(pdev, DRV_NAME);   /* same */
  request_irq(irq, handler, 0, "drv", dev); /* same */
  /* Device may be in undefined state — no indication */
  ```

  *Rust's `#[must_use]` + `Result<T, E>`*

  ```rust
  pdev.enable()?;              // ? propagates Err immediately
  pdev.request_regions()?;     // compiler proves this only
  pdev.request_irq(handler)?;  // runs if enable succeeded
  // Each function returns Result<_, Error>.
  // Discarding it is a COMPILER WARNING:
  // warning[unused_must_use]: unused `Result` that must be used
  ```
][
  *What `?` actually does — no magic*

  ```rust
  // These two are exactly equivalent:
  pdev.enable()?;

  match pdev.enable() {
      Ok(val)  => val,
      Err(err) => return Err(err.into()),
  };
  ```

  - No exceptions — no hidden control flow
  - No `longjmp` — no stack unwinding surprise
  - The error path is *explicit, local, and grep-able*
  - Every early return is a `?` — auditable in code review

  #callout(color: safe-green)[
    The Linux kernel style guide recommends checking every return value. Rust makes non-checking a *compiler warning by default* — the rule that currently lives in `checkpatch.pl` is instead enforced at compilation.
  ]
]

== Exhaustive `match` — no silent enum gaps

#cols[
  *The C `switch` silent-default problem*

  ```c
  enum pcie_speed { GEN1, GEN2, GEN3, GEN4, GEN5 };

  uint64_t bandwidth(enum pcie_speed s) {
      switch (s) {
          case GEN1: return 250000000ULL;
          case GEN2: return 500000000ULL;
          case GEN3: return 985000000ULL;
          case GEN4: return 1969000000ULL;
          /* GEN5 added later — falls through to: */
          default:   return 0; /* silent wrong result */
      }
  }
  /* gcc -Wall: may warn. sparse: may warn.
     Both require the tool to be run AND the warning
     to be treated as an error. Neither is guaranteed. */
  ```
][
  *Rust's exhaustive `match`*

  ```rust
  enum PcieSpeed { Gen1, Gen2, Gen3, Gen4, Gen5 }

  fn bandwidth(s: PcieSpeed) -> u64 {
      match s {
          PcieSpeed::Gen1 => 250_000_000,
          PcieSpeed::Gen2 => 500_000_000,
          PcieSpeed::Gen3 => 985_000_000,
          PcieSpeed::Gen4 => 1_969_000_000,
          // ↑ forgot Gen5?
          // error[E0004]: non-exhaustive patterns
          //   `PcieSpeed::Gen5` not covered
          //
          // Adding Gen5 to the enum breaks every
          // match that does not handle it — instantly,
          // at every call site, in every crate.
      }
  }
  ```

  #callout(color: safe-green)[
    There is no `default:` escape hatch by default. When you add a new variant to an enum, the compiler shows you *every* location in the codebase that must be updated.
  ]
]

== `unsafe` — the auditable escape hatch

#cols[
  *What `unsafe` enables*

  Four capabilities are only available inside `unsafe { }` blocks:
  1. Dereference a raw pointer (`*const T`, `*mut T`)
  2. Call an `unsafe fn` (including all `extern "C"` FFI)
  3. Access or modify a mutable static variable
  4. Implement an `unsafe trait` (e.g., `Send`, `Sync` manually)

  *What `unsafe` does NOT do*

  - Does not disable the borrow checker
  - Does not disable type checking
  - Does not disable lifetime analysis
  - Does not disable `#[must_use]`

  Only the four capabilities above are relaxed.
][
  *The audit argument*

  ```bash
  # Complete audit surface for all driver unsafe code:
  grep -rn "unsafe" drivers/my_soc/

  # In C: every line is the audit surface.
  # There is no equivalent grep.
  ```

  *The kernel's three-layer architecture uses this:*

  ```
  rust/bindings/     ← all unsafe — auto-generated,
                       reviewed once, never touched
       ↓ wraps
  rust/kernel/       ← safe abstractions built on top
       ↓ exposes
  drivers/your_ip/   ← pure safe Rust — zero unsafe
                       UAF / race / null proof covers
                       all of your driver code
  ```

  #callout[
    In C, "how much of this is manually memory-managed?" has no answer. In Rust: *count the `unsafe` blocks*.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. OTHER KEY SECURITY-FOCUSED FEATURES
// ─────────────────────────────────────────────────────────────────────────────
= Other Key Security-Focused Features

== Integer safety and panic discipline

#cols[
  *Integer overflow — UB in C, defined in Rust*

  In C, signed integer overflow is undefined behaviour. The compiler can *legally delete* the overflow check on the assumption it never happens.

  ```c
  // C: signed overflow → UB → compiler may "optimise"
  // away the bounds check entirely (documented in GCC docs)
  size_t alloc_size = nents * sizeof(struct entry);
  if (alloc_size < nents) return -EINVAL; // may be removed!
  void *buf = kmalloc(alloc_size, GFP_KERNEL);
  ```

  ```rust
  // Rust debug build: overflow → controlled panic (BUG())
  // Rust release build: wrapping, checked, or saturating
  // — explicitly chosen, never undefined:
  let alloc_size = nents
      .checked_mul(size_of::<Entry>())
      .ok_or(ErrKind::Overflow)?;
  // Returns Err if it overflows — never silent.
  ```
][
  *Panic = explicit abort, not UB*

  In kernel Rust (`#![no_std]`, custom `#[panic_handler]`), a panic does not unwind — it calls `BUG()` or halts the CPU, exactly like a kernel `BUG_ON()`. There is no hidden exception mechanism.

  ```rust
  #[cfg(not(test))]
  #[panic_handler]
  fn panic(_info: &PanicInfo) -> ! {
      // In kernel context: trigger BUG() / halt
      loop {}   // or: call kernel's panic() function
  }
  ```

  #callout[
    Rust panics are *predictable*, *locatable* (they include source location in debug builds), and *never undefined behaviour*. A Rust panic is always intentional; a C signed overflow is always a potential silent time bomb.
  ]
]

== Immutability by default

#cols[
  *C's dangerous default: everything is mutable*

  ```c
  void configure_hw(struct hw_config *cfg) {
      /* cfg->base_addr can be modified here
         even if that was not the intent.
         Only `const struct hw_config *` prevents it,
         and const is frequently omitted. */
      cfg->base_addr = 0; // oops — accidental mutation
  }
  ```

  *Rust's safe default: everything is immutable*

  ```rust
  fn configure_hw(cfg: &HwConfig) {
      // cfg.base_addr = 0; // ← error[E0596]:
      //   cannot assign to `cfg.base_addr`,
      //   which is behind a `&` reference
  }
  // Mutation requires explicit declaration:
  fn reconfigure(cfg: &mut HwConfig) {
      cfg.base_addr = NEW_BASE; // only allowed here
  }
  ```
][
  *Why this matters for BSP code*

  - Read-only device tree data, register maps, and firmware blobs are *structurally immutable* — the type prevents accidental writes
  - A configuration struct passed to an ISR as `&HwConfig` *cannot* be modified by the ISR — the compiler proves it
  - Global immutable data (calibration tables, fuse values) declared as `static` — Rust distinguishes `static T` (immutable, `Sync`-required) from `static mut T` (requires `unsafe` — surfaces immediately in audit)

  #callout(color: safe-green)[
    *The secure-by-default principle*: mutability must be explicitly requested. The conservative default prevents a class of accidental writes that are otherwise silent in C.
  ]
]

== The type system as documentation — encoded, not commented

#cols[
  *C: intent in comments, verifiable nowhere*

  ```c
  /*
   * MUST be called with dma_lock held.
   * dev pointer MUST remain valid for the
   * duration of the DMA operation.
   * Returns negative errno on failure.
   */
  int map_dma(struct device *dev,
              struct sg_table *sgt,
              int nents,
              enum dma_data_direction dir);
  ```

  None of these constraints are checked by the compiler. The comment is the only enforcement mechanism.
][
  *Rust: intent in the type, checked at every call site*

  ```rust
  // "MUST be called with dma_lock held"
  // → take a MutexGuard parameter — unobtainable otherwise
  fn map_dma<'lock>(
      _guard:  &'lock MutexGuard<DmaState>, // proof of lock
      dev:     &'lock Device,               // must outlive guard
      sgt:     &mut SgTable,
      dir:     DmaDirection,                // typed enum, not int
  ) -> Result<SgMapping<'lock>, DmaError>  // typed error
  // The comment is now the type signature.
  // Violations are compile errors, not runtime bugs.
  ```

  #callout(color: safe-green)[
    Every invariant encoded in a Rust type signature is *checked at every call site in every crate that uses it* — including crates that were written years later by engineers who never read the comment.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. THE BROADER ECOSYSTEM
// ─────────────────────────────────────────────────────────────────────────────
= The Broader Rust Ecosystem

== Tooling that ships with the language

#cols[
  *Unified toolchain — no separate install decisions*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Tool*], [*Role (and C equivalent)*],
    [`cargo`], [build, test, bench, publish — replaces Make + CMake + pkg-config],
    [`rustfmt`], [auto-formatter — replaces `clang-format` debates],
    [`clippy`], [semantic linter — replaces Coverity / sparse for Rust code],
    [`rustdoc`], [doc generation from `///` comments — replaces Doxygen],
    [`miri`], [UB detector — runs Rust under an interpreter; finds logic errors in `unsafe`],
    [`cargo-fuzz`], [coverage-guided fuzzing backed by libFuzzer],
    [`cargo-deny`], [license + CVE audit of dependency tree],
    [`rust-analyzer`], [LSP: autocomplete, inline errors, go-to-definition — IDE-native],
  )
][
  *The ecosystem signal: Rust is reshaping every layer*

  - *These slides* — written in *Typst*, which is itself written in Rust
  - *ripgrep* (`rg`) — faster `grep`, written in Rust #ref-badge[github.com/BurntSushi/ripgrep]
  - *fd* — faster `find`
  - *Ruff* — Python linter, 10–100× faster than pylint #ref-badge[astral.sh/ruff]
  - *uv* — Python package manager, replaces pip
  - *swc* — JS/TS compiler, 70× faster than Babel
  - *Cloudflare Pingora* — HTTP proxy serving 1 trillion requests/day #ref-badge[Cloudflare Blog 2022]
  - *AWS Firecracker* — microVM hypervisor powering Lambda + Fargate #ref-badge[NSDI 2020]
  - *Android 16* — kernel 6.12, `ashmem` allocator in Rust — production on millions of devices

  #callout(color: safe-green)[
    The meta-point for this audience: *the tool generating these slides is written in Rust*. The language has escaped "systems niche" and is reshaping the entire software toolchain stack.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *Ownership · Borrowing · Lifetimes*

  are not restrictions.

  They are the compiler's proof system —
  verifying, at every build, that your driver
  has no use-after-free, no data race,
  no null dereference, and no silent error drop.

  *Every kernel bug they prevent is a CVE that never ships.*
]

// ─────────────────────────────────────────────────────────────────────────────
//  APPENDIX
// ─────────────────────────────────────────────────────────────────────────────
= Appendix <touying:hidden>

== Getting started with Rust

```bash
# 1. Install rustup (manages Rust toolchain versions)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# 2. Verify installation
rustc --version   # rustc 1.XX.0 (...)
cargo --version   # cargo 1.XX.0 (...)

# 3. Install useful components
rustup component add rustfmt clippy rust-analyzer

# 4. First project
cargo new hello-driver
cd hello-driver
cargo build
cargo run
cargo clippy      # linter
cargo fmt         # formatter
cargo test        # unit tests

# 5. Recommended learning path for C/kernel developers
# The Rust Programming Language (free): https://doc.rust-lang.org/book/
# Rustlings (interactive exercises): https://rustlings.cool
# Rust by Example: https://doc.rust-lang.org/rust-by-example/
# Comprehensive Rust (Google, Android focus): https://google.github.io/comprehensive-rust/
```

== Key references

#set text(size: 0.72em)

*Formal verification*
- Jung, R., Jourdan, J-H., Krebbers, R., Dreyer, D. *"RustBelt: Securing the Foundations of the Rust Programming Language."* POPL 2018. #link("https://plv.mpi-sws.org/rustbelt/popl18/")
- Dang, H-H., Jourdan, J-H., Kaiser, J-O., Dreyer, D. *"RustBelt Meets Relaxed Memory."* POPL 2020.

*Industry data*
- Microsoft MSRC. "A Proactive Approach to More Secure Code." Gavin Thomas, 2019.
- Google Project Zero. "Memory Safety Issues in Chrome." 2020.
- Android Security Blog. "Memory Safety in Android." 2021. #link("https://security.googleblog.com")
- CISA. "The Case for Memory Safe Roadmaps." 2023. #link("https://www.cisa.gov/resources-tools/resources/case-memory-safe-roadmaps")

*Language specification and learning*
- The Rust Reference. #link("https://doc.rust-lang.org/reference/")
- The Rust Programming Language (Klabnik & Nichols). #link("https://doc.rust-lang.org/book/")
- Comprehensive Rust (Google). #link("https://google.github.io/comprehensive-rust/")

*Performance*
- Paczos, K. "The Speed of Rust vs C." #link("https://kornel.ski/rust-c-speed/") 2023.
- Compiler Explorer. #link("https://godbolt.org")

*Production deployments*
- Cloudflare. "How We Built Pingora." 2022. #link("https://blog.cloudflare.com/how-we-built-pingora")
- Agache et al. "Firecracker." NSDI 2020.
