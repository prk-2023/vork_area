// ─────────────────────────────────────────────────────────────────────────────
//  Why Rust — A Systems Programmer's Perspective
//  Typst / Touying presentation  ·  Metropolis theme
//
//  Target          : Introduction to Rust & eBPF with Rust. ( part 1: Features)
//  Focus           : Memory safety, compiler guarantees, modern concepts,
//                    performance, references
//
//  Build:
//    typst compile rust-features.typ rust-features.pdf
//
//  Required packages (auto-downloaded on first compile):
//    @preview/touying:0.7.1
//    @preview/numbly:0.1.0
// ─────────────────────────────────────────────────────────────────────────────

#import "@preview/touying:0.7.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

// ── Palette ───────────────────────────────────────────────────────────────────
#let rust-red    = rgb("#CE422B")
#let rust-dark   = rgb("#1A1A1A")
#let safe-green  = rgb("#2D6A4F")
#let warn-amber  = rgb("#B5460F")
#let ref-blue    = rgb("#1B4F8A")
#let code-bg     = rgb("#1E1E2E")   // dark surface for code blocks
#let code-fg     = rgb("#CDD6F4")   // catppuccin mocha text
#let kw-color    = rgb("#CBA6F7")   // keywords
#let cm-color    = rgb("#6C7086")   // comments
#let st-color    = rgb("#A6E3A1")   // strings / ok path
#let er-color    = rgb("#F38BA8")   // error path
#let hi-color    = rgb("#FAB387")   // highlighted tokens

// ── Helpers ───────────────────────────────────────────────────────────────────

// Callout box with left accent bar
#let callout(body, color: rust-red) = block(
  fill:   color.lighten(90%),
  stroke: (left: 3pt + color),
  inset:  (left: 10pt, top: 7pt, bottom: 7pt, right: 9pt),
  radius: (right: 4pt),
  width:  100%,
  body,
)

// Small reference badge  →  #ref-badge[Jung et al., POPL 2018]
#let ref-badge(body) = box(
  fill:   ref-blue.lighten(88%),
  stroke: 0.4pt + ref-blue,
  inset:  (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: ref-blue, size: 0.6em, style: "italic", body)
)

// Two-column layout
#let cols(left, right, ratio: (1fr, 1fr)) = grid(
  columns: ratio,
  gutter:  1.2em,
  left, right,
)

// Dark code block with optional title
#let codeblock(body, title: none) = {
  if title != none {
    block(
      fill:   rust-red.lighten(88%),
      inset:  (x: 10pt, y: 4pt),
      radius: (top: 5pt),
      width:  100%,
      text(size: 0.65em, weight: "bold", fill: rust-red, title)
    )
  }
  block(
    fill:   code-bg,
    radius: if title != none { (bottom: 5pt) } else { 5pt },
    inset:  12pt,
    width:  100%,
    text(font: ("Noto Sans","JetBrains Mono","Liberation Mono"), fill: code-fg, size: 0.72em, body)
  )
}

// Inline keyword highlight
#let kw(t)  = text(fill: kw-color,  raw(t))
#let cm_(t) = text(fill: cm-color,  raw(t))
#let st_(t) = text(fill: st-color,  raw(t))
#let ok_(t) = text(fill: st-color,  t)
#let er_(t) = text(fill: er-color,  t)
#let hi_(t) = text(fill: hi-color,  t)

// Section divider annotation
#let anno(body) = align(right, text(size: 0.6em, fill: gray.lighten(20%), style: "italic", body))

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
    title:       [Why Rust — A Systems Programmer's Perspective],
    subtitle:    [Memory Safety · Compiler Guarantees · Modern Concepts · Performance],
    author:      [Pulumati Ram],
    date:        datetime.today(),
    institution: [ Realtek Semiconductor Corporation ],
  ),
)

#set text(font: ("Noto Sans","Noto Sans","Liberation Sans"), size: 15pt)
#show raw:  set text(font: ("Noto Sans","JetBrains Mono","Liberation Mono"), size: 0.81em)
#show link: set text(fill: rust-red)
#set heading(numbering: numbly("{1}.", default: "1.1"))

// ─────────────────────────────────────────────────────────────────────────────
//  TITLE SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#title-slide()

// Disclaimer: 
#focus-slide[
  #text(size: 1.2em, weight: "bold")[#underline(stroke: 1pt + rust-red)[> Disclaimer <] 
  ]

  #v(0.8em)

  #text(fill: rgb("#f66"))[
  Focus on systems evolution, not a language war 
  ]
  #line(length: 63%, stroke: 1pt + rust-red)
  #v(0.5em)

    \- Rust in the Linux kernel \- #linebreak()
    \- Direction and practical utility \- 
]

#focus-slide[
  #v(0.4em)
  #text(fill: rust-red )[_Part 1_] #linebreak()
  #text(fill: rgb("#f93"))[Rust as a systems programming language]

  #v(0.4em)
  #text(fill: rust-red)[_Part 2_] #linebreak()
  #text(fill: rgb("#f93"))[Rust in the Linux kernel]

  #v(0.4em)
  #text(fill: rust-red)[_Part 3_] #linebreak()
  #text(fill: rgb("#f93"))[`eBPF` programming with Rust]

]
// ─────────────────────────────────────────────────────────────────────────────
//  AGENDA
// ─────────────────────────────────────────────────────────────────────────────
== Part 1: Rust as Systems Programming Language <touying:hidden>

=== The Problem — Why Another Systems Language?
- #text(fill: rust-red)[$`C`$] is the de-facto industry standard for systems programming.
- #text(fill: rust-red)[$`C`$] built system (can contain errors that are easy to make and difficult to detect even with rigorous code review.
- Safety in the currently developer-dependent ( complexity + cost of maintenance )
- Linux kernel: evolved over 30+ years, there is a growing concern that new developers are less interested 
  in working with the risks associated with "manual" C.

#text(fill: rust-red)[*`rust`*] 
  - Language philosophy aims to address the above #text(fill: rust-red)[$`C`$] challenges, with out compromising on security,performance or reliability.
// ─────────────────────────────────────────────────────────────────────────────
//  1. THE PROBLEM — WHY ANOTHER SYSTEMS LANGUAGE?
// ─────────────────────────────────────────────────────────────────────────────
//== The Problem — Why Another Systems Language?

== The eternal memory bug

#cols[
  *The numbers haven't moved in 20 years*

  - *~70 %* of Microsoft CVEs are memory safety bugs
    #ref-badge[Microsoft Security Response Centre, 2019]
  - *~67 %* of Linux kernel CVEs are memory safety violations
    #ref-badge[Gaynor & Thomas, Linux Security Summit, 2019]
  - Chrome: *70 %* of high-severity bugs are memory safety issues
    #ref-badge[Google Project Zero, 2020]
  - Android: memory unsafety caused *\$68B* in security costs est. 2019
    #ref-badge[Android team blog, 2021]

  #callout[
    Better tooling (ASAN, Coverity, sparse) *reduces* the rate — it does not *eliminate* the class. The only way to eliminate a class of bugs is to make them unrepresentable in the type system.
  ]
][
  *The two root causes*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
    inset: (y: 6pt, x: 4pt),
    [*Cause*], [*C has no protection against...*],
    [Use-after-free], [accessing freed memory via a dangling pointer],
    [Buffer overflow], [writing past the end of an allocation],
    [Data race], [two threads accessing shared memory without synchronisation],
    [Null deref], [dereferencing a pointer that might be `NULL`],
    [Uninit. read], [reading before a write path has initialised a field],
    [Integer overflow], [signed overflow, UB, silent wrong results],
  )
]

---

#cols[
#callout(color: safe-green)[
    Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
  ]
][
  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
    inset:  (left: 1pt, top: 1pt, bottom: 7pt, right: 0pt),
    [*Cause*], [*C has no protection against...*],
    [Use-after-free], [accessing freed memory via a dangling pointer],
    [Buffer overflow], [writing past the end of an allocation],
    [Data race], [two threads accessing shared memory without synchronisation],
    [Null deref], [dereferencing a pointer that might be `NULL`],
    [Uninit. read], [reading before a write path has initialised a field],
    [Integer overflow], [signed overflow, UB, silent wrong results],
  )
]

== Space before Rust

#cols[
  *Safe but slow* (GC languages)
  - Java, Go, Python — garbage collector guarantees no UAF
  - *Cost*: GC pauses, unpredictable latency, large runtimes
  - Unsuitable for kernel code, real-time, interrupt handlers

  *Fast but unsafe* (C, C++)
  - Maximum control, minimum overhead
  - *Cost*: all memory bugs are the programmer's problem
  - 30+ years of CVEs are the empirical evidence

  #callout[
    Rust closes the gap: *safety without a GC*, performance matching C, zero-cost abstractions.
    #ref-badge[Jung et al., POPL 2018 — "the holy grail of PL research"]
  ]
][
  #align(center)[
    #table(
      columns: (auto, auto, auto),
      stroke: 0.5pt + gray,
      inset: 8pt,
      fill: (col, row) => {
        if row == 0 { rust-red.lighten(80%) }
        else if col == 0 and row == 2 { safe-green.lighten(80%) }
        else { white }
      },
      [], [*Memory safe*], [*No GC / no runtime*],
      [C / C++],  [✗], [✓],
      [*Rust*],   [*✓*], [*✓*],
      [Java / Go],[✓], [✗],
    )
    #v(0.6em)
    #text(size: 0.65em, fill: gray)[
      Rust uniquely occupies the upper-right cell.
    ]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. OWNERSHIP — THE CORE MECHANISM
// ─────────────────────────────────────────────────────────────────────────────
= Ownership — Memory Safety at Compile Time

== The three ownership rules

#callout[
  *Rust's ownership system* is its type-theoretic answer to manual memory management. It was first formally verified by *RustBelt* (Jung et al., POPL 2018) using the Iris separation logic framework in Coq. #ref-badge[Jung et al., Proc. ACM Program. Lang. 2, POPL, Art. 66, 2018]
]

#v(0.6em)

#cols[
  *Rule 1 — Each value has exactly one owner*

  ```rust
  let s1 = String::from("hello"); // s1 owns the heap data
  let s2 = s1;          // ownership MOVES to s2
  // println!("{}", s1); // ← compile error: s1 was moved
  ```

  The compiler tracks ownership *statically*. No runtime bookkeeping.

  *Rule 2 — When the owner goes out of scope, the value is dropped*

  ```rust
  {
      let buf = alloc_dma_buf(); // allocation
  }   // ← Drop::drop() called HERE, automatically
      // No free() to forget. No leak possible.
  ```
][
  *Rule 3 — One mutable reference OR many immutable references, never both*

  ```rust
  let mut v = vec![1, 2, 3];
  let r1 = &v;           // immutable borrow
  let r2 = &v;           // another immutable borrow — OK
  // let r3 = &mut v;    // ← compile error:
                         //   cannot borrow as mutable
                         //   while borrowed as immutable

  // Once r1, r2 are no longer used:
  let r3 = &mut v;       // now OK — exclusive access
  v.push(4);
  ```

  #callout(color: safe-green)[
    Rule 3 *is* the aliasing XOR mutability discipline. The same invariant that makes the Linux kernel's `rcu_read_lock` / spinlock discipline correct — enforced by the type checker, not by convention.
  ]
]

== Ownership vs C: use-after-free

Most common kernel CVE class : caught at compile time in Rust.

#cols[
  #codeblock(title: "C : compiles, crashes or corrupts silently")[
    ```c
    struct dma_buf *buf = dma_alloc(dev, size);
    submit_dma(dev, buf);

    kfree(buf);           /* freed */

    /* … 500 lines later … */
    read_completion(buf); /* UAF — undefined behaviour */
    /* gcc/clang: no warning, no error */
    ```
  ]
][
  #codeblock(title: "Rust : compile error, zero runtime cost")[
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
  ]
]

#callout[
  The error message names the *exact line* where the value was moved and the *exact line* of the illegal use, before the code ever runs. No Valgrind, no KASAN, no OEM escalation.
]

== Ownership prevents leaks — RAII in kernel drivers

In C, every error exit path in a driver must remember to call the right cleanup. 

Rust makes this structurally impossible to get wrong.

#cols[
  #codeblock(title: "C : common leak pattern")[
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
  ]
][
  #codeblock(title: "Rust : Drop handles every exit path")[
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
  ]

  #callout(color: safe-green)[
    *Zero `goto` cleanup; chains.* The compiler guarantees cleanup runs on every path. Linux has thousands of `goto err_free_X` labels that this eliminates.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. BORROWING & LIFETIMES
// ─────────────────────────────────────────────────────────────────────────────
= Borrowing & Lifetimes — Preventing Data Races

== Borrowing — the aliasing rules formalised

#callout[
  *Borrowing* is Rust's system for temporary access without transferring ownership. \ It formalises the aliasing rules that C developers know informally but often violate.
  #ref-badge[Rust Reference §10: "References & Borrowing"]
]

#v(0.6em)

#cols[
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
][
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

  #callout(color: safe-green)[
    The compiler *proves* that at any point in the program, either *one writer* or *N readers* holds access to any memory location, but never both. This is the data race freedom guarantee.
  ]
]

== Lifetimes — dangling pointers eliminated

Lifetimes are the compiler's proof that a reference never outlives the data it points to. Named by the programmer, verified by the borrow checker.

#codeblock(title: "Dangling pointer caught at compile time")[
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
]

#callout[
  In kernel drivers: a reference to a `struct device` inside an interrupt handler *must not outlive the device*. Lifetimes encode and verify this invariant statically. No more `dev_hold()` / `dev_put()` mismatches.
]

== Lifetimes prevent data races — the formal proof

#cols[
  *Why ownership + lifetimes = data-race freedom*

  A data race requires *two* concurrent accesses where *at least one is a write*. The ownership model makes this impossible:

  1. A *mutable* borrow `&mut T` is *exclusive* — no other borrow (mutable or shared) can exist simultaneously
  2. A *shared* borrow `&T` prevents any mutable borrow from existing
  3. Both are enforced statically — no runtime check, no lock

  Therefore: if the code compiles, there are no data races.

  #ref-badge[RustBelt: Jung et al., POPL 2018 — formally machine-checked in Coq/Iris]
  #ref-badge[RustBelt Meets Relaxed Memory: Dang et al., POPL 2020]
][
  #codeblock(title: "Data race — caught at compile time")[
    ```rust
    use std::thread;

    let mut data = vec![1u8; 4096]; // DMA buffer

    // Try to share mutable data across threads:
    let t1 = thread::spawn(|| {
        data[0] = 0xFF; // write
    });
    let t2 = thread::spawn(|| {
        data[1] = 0xAA; // write concurrently
    });
    // error[E0502]: cannot borrow `data` as mutable
    // because it is also borrowed
    // error[E0373]: closure may outlive the current
    // function, but it borrows `data`
    ```
  ]

  #callout(color: safe-green)[
    The compiler rejects the data race *statically*. In C this compiles, runs, and silently corrupts memory — or causes a kernel panic during DMA completion.
  ]
]

== `Send` and `Sync` — thread safety in the type system

#callout[
  *`Send`*: a type can be moved to another thread. \
  *`Sync`*: a type can be shared between threads (via `&T`). \
  These are *marker traits* — compile-time properties with zero runtime representation.
  #ref-badge[RustBelt §3.3: formal definition of Send and Sync via ownership predicates]
]

#cols[
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
][
  *Practical impact for kernel drivers*

  - A spinlock-protected struct is `Sync` if and only if `T: Send`
  - The compiler *refuses* to put non-`Send` data in a global
  - Interrupt handler shared data must be `Sync` — enforced before the module loads

  #callout(color: safe-green)[
    Every concurrency contract that Linux documents in comments (`/* must hold lock X before accessing Y */`) Rust encodes in the *type signature* and verifies at compilation.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  4. COMPILER CHECKS
// ─────────────────────────────────────────────────────────────────────────────
= Compiler Checks — Beyond Memory Safety

== What the Rust compiler verifies at every build

#cols[
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
][
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

  #callout[
    In C, all of the above require separate tools: ASAN, UBSAN, sparse, Coccinelle, clang-tidy, GCC sanitizers — none of them are mandatory, and none are exhaustive.
  ]
]

== `#[must_use]` and exhaustive errors — no silent failures

A fundamental problem in C driver code: `if (ret < 0) { … }` is optional. The compiler never complains if you forget it.

#cols[
  #codeblock(title: "C — error silently dropped, device in bad state")[
    ```c
    pci_enable_device(pdev);   /* returns int, ignored */
    pci_set_master(pdev);      /* called even on error */

    if (request_irq(irq, handler, 0, "mydrv", dev)) {
        /* forgot to check enable_device above */
        return -EIO;
    }
    /* device may not actually be enabled */
    ```
  ]
][
  #codeblock(title: "Rust — every error must be handled")[
    ```rust
    pdev.enable()?;     // ? propagates Err immediately
    pdev.set_master();  // only reached if enable succeeded

    pdev.request_irq(irq, handler)?;
    // If any ? returns Err:
    // — function returns immediately
    // — Drop runs on all acquired resources
    // — no resource in partially-initialised state

    // Forgetting ? is a warning:
    // warning: unused `Result` that must be used
    ```
  ]
]

#callout[
  The `?` operator is not magic — it is `match result { Ok(v) => v, Err(e) => return Err(e.into()) }`. It is purely a compile-time transformation. No exceptions, no longjmp, no hidden control flow.
]

== Pattern matching — exhaustiveness by proof

`match` in Rust is *exhaustive*: the compiler proves every possible case is handled. There is no `default:` that silently swallows new enum variants.

#cols[
  #codeblock(title: "Adding a new variant — compiler catches every callsite")[
    ```rust
    enum PcieSpeed { Gen1, Gen2, Gen3, Gen4, Gen5 }

    fn lane_bandwidth(speed: PcieSpeed) -> u64 {
        match speed {
            PcieSpeed::Gen1 => 250_000_000,
            PcieSpeed::Gen2 => 500_000_000,
            PcieSpeed::Gen3 => 985_000_000,
            PcieSpeed::Gen4 => 1_969_000_000,
            // Forgot Gen5?
            // error[E0004]: non-exhaustive patterns:
            //   `PcieSpeed::Gen5` not covered
        }
    }
    ```
  ]
][
  *Why this matters in practice*

  - Add `Gen5` to the enum → *every* `match` that doesn't handle it fails to compile
  - Zero chance of a silently wrong `default:` path
  - Pattern matching also *destructures* and extracts data:

  ```rust
  match dma_result {
      Ok(nents) if nents > 0 => {
          submit_to_hw(nents)
      },
      Ok(0)    => return Err(ErrKind::NoEntries),
      Err(e)   => return Err(e.into()),
  }
  ```

  #callout(color: safe-green)[
    Kernel C `switch` on an enum value: silently falls through if a new value is added. Sparse can warn about this — but only if you run it. Rust makes it a *compile error* by default.
  ]
]

== The type system eliminates `NULL`

One of C's most costly design decisions: any pointer can be `NULL`, and dereferencing it is undefined behaviour.

#cols[
  ```c
  /* C */
  struct irq_data *d = irq_get_irq_data(irq);
  /* d might be NULL — easy to forget the check */
  d->irq_common_data.handler_data = priv;
  /* null deref → BUG() → kernel panic */
  ```

  #v(0.5em)

  ```rust
  // Rust: irq_get_irq_data returns Option<IrqData>
  match irq_get_irq_data(irq) {
      Some(d) => d.set_handler_data(priv),
      None    => return Err(ErrKind::InvalidIrq),
  }
  // Compiler proved: d is valid inside Some(_)
  // There is no raw pointer dereference here
  ```
][
  *`Option<T>` is the type-safe null*

  - `None` = absent value
  - `Some(T)` = present value
  - You *cannot access the inner T* without handling `None` first
  - No accidental null dereference — it is a type error

  #callout[
    `Option<&T>` is represented as a nullable pointer at the machine level — *same memory layout, zero overhead* — but the type system forces you to check it before use.
    #ref-badge[The Rust Reference: §3.1 "Niche optimisation of Option"]
  ]

  *For kernel engineers:*

  `container_of()` macro results, device tree node lookups, optional firmware callbacks — all naturally expressed as `Option<T>`.
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. MODERN PROGRAMMING CONCEPTS
// ─────────────────────────────────────────────────────────────────────────────
= Modern Programming Concepts

== Traits — interfaces that compose

Traits are Rust's abstraction mechanism. They are closer to Haskell type classes than to C++ virtual dispatch — and critically, they are resolved *at compile time* (zero virtual dispatch overhead).

#cols[
  *Define the contract once*

  ```rust
  trait DmaDevice {
      fn map_sg(&self, sg: &mut SgList) -> Result<usize>;
      fn unmap_sg(&self, sg: &mut SgList);
      fn sync_for_cpu(&self, sg: &SgList);
  }
  ```

  *Implement for any type*

  ```rust
  impl DmaDevice for Mlx5HcaDev {
      fn map_sg(&self, sg: &mut SgList) -> Result<usize> {
          // ConnectX-5 specific path
      }
      // …
  }
  impl DmaDevice for VirtioNetDev { /* … */ }
  ```
][
  *Static dispatch — monomorphisation*

  ```rust
  // Compiler generates ONE specialised version per type
  // No vtable, no indirect call, fully inlining-eligible
  fn trace_dma<D: DmaDevice>(dev: &D, sg: &mut SgList) {
      let nents = dev.map_sg(sg)?;
      record_event(nents, dev.name());
  }
  ```

  *Dynamic dispatch — explicit opt-in*

  ```rust
  // When you need runtime polymorphism:
  fn attach_tracer(dev: &dyn DmaDevice) { … }
  ```

  #callout[
    In C, this pattern requires a `struct ops { int (*map_sg)(…); … }` with manual pointer management. Rust's trait system is the same concept — with compiler enforcement of the interface contract and zero-cost static dispatch as the default.
  ]
]

== Zero-cost abstractions — the performance guarantee

#callout[
  *"Zero-cost abstractions: what you don't use, you don't pay for. And further: what you do use, you couldn't hand-code any better."*
  — Bjarne Stroustrup (C++ standard, adopted verbatim by the Rust team)
  #ref-badge[Stroustrup, "Foundations of C++", 2012; Rust Reference: §1 "Design goals"]
]

#cols[
  *Iterators compile to tight loops*

  ```rust
  // High-level — reads like intent
  let total: u64 = latencies
      .iter()
      .filter(|&&ns| ns > threshold)
      .sum();

  // Compiles to exactly the same assembly as:
  let mut total: u64 = 0;
  for &ns in latencies {
      if ns > threshold { total += ns; }
  }
  ```

  *Godbolt confirms*: both emit `ADDQ` in a tight loop with no branch overhead when `threshold` is a constant.
  #ref-badge[Compiler Explorer (godbolt.org): rustc -O2]
][
  *Generics use monomorphisation — no boxing*

  ```rust
  fn min_latency<T: Ord>(a: T, b: T) -> T {
      if a <= b { a } else { b }
  }
  // Calling with u64 generates u64-specific code
  // Calling with u32 generates u32-specific code
  // No virtual dispatch, no boxing, no indirection
  ```

  *Lifetime annotations are compile-time only*

  ```rust
  // 'a is erased before code generation
  fn longest<'a>(x: &'a str, y: &'a str) -> &'a str { … }
  // Produces the same assembly as the C equivalent
  // with raw pointers — but is provably safe
  ```

  #callout(color: safe-green)[
    Borrow checking and lifetime analysis are *pure static analysis* — they are stripped out before LLVM sees the code. The runtime binary is as lean as handwritten C.
  ]
]

== Error handling — `Result<T, E>` and the `?` operator

Unlike C (`errno`, negative return values, `goto err_free`) or C++ (exceptions with hidden control flow), Rust makes errors *first-class values in the type signature*.

#cols[
  *C patterns and their problems*

  ```c
  int pci_probe(struct pci_dev *pdev) {
      int ret;
      ret = pci_enable_device(pdev);   /* -errno or 0 */
      if (ret) goto err;
      ret = pci_request_regions(pdev, DRV_NAME);
      if (ret) goto err_disable;
      /* … 20 more error paths … */
  err_disable:
      pci_disable_device(pdev);
  err:
      return ret;
  }
  /* Problems:
     - ret is untyped int; semantics undocumented
     - easy to jump to wrong label
     - no compiler check that all paths handled */
  ```
][
  *Rust — errors are types, `?` propagates them*

  ```rust
  fn pci_probe(pdev: &mut PciDev) -> Result<MyDev> {
      pdev.enable()?;           // Err → return immediately
      pdev.request_regions()?;  // Drop runs on previous
      let irq = pdev.alloc_irq(handler, 0)?;

      Ok(MyDev { pdev, irq })
      // On any ?, all acquired resources are
      // dropped in reverse order automatically
  }
  /* Benefits:
     - error type is in the signature → documented
     - ? is explicit, grep-able, auditable
     - no goto, no labels, no cleanup lists
     - compiler warns if Result is ignored    */
  ```

  #ref-badge[Rust RFC 0243: "Trait-based exception handling" (? operator)]
]

== Fearless concurrency — async and channels

Rust's ownership model extends to asynchronous code. The same borrow checker that prevents data races in synchronous code works across `async`/`await` boundaries.

#cols[
  *Channels — safe message passing*

  ```rust
  use std::sync::mpsc;

  let (tx, rx) = mpsc::channel::<DmaEvent>();

  // Producer thread — owns the tx end
  thread::spawn(move || {
      tx.send(DmaEvent { latency_ns: 1842, … }).unwrap();
  });

  // Consumer — owns the rx end
  for event in rx {
      update_histogram(&mut hist, event.latency_ns);
  }
  // No shared mutable state — the type system
  // prevents concurrent access to `event`
  ```
][
  *`Arc<Mutex<T>>` — safe shared state*

  ```rust
  let shared_hist = Arc::new(Mutex::new(Histogram::new()));

  let hist_clone = Arc::clone(&shared_hist);
  thread::spawn(move || {
      let mut h = hist_clone.lock().unwrap();
      h.record(latency_ns);
      // lock guard drops here — unlocks automatically
  });

  // Main thread
  let h = shared_hist.lock().unwrap();
  h.print_report();
  ```

  #callout(color: safe-green)[
    The `Mutex<T>` *wraps* the data — you *cannot access* the histogram without holding the lock, because the data is only reachable through `lock()`. This is structurally enforced, not documented convention.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. PERFORMANCE
// ─────────────────────────────────────────────────────────────────────────────
= Performance — No Runtime Tax

== Rust's performance model

#cols[
  *What Rust does NOT have*

  #table(
    columns: (auto, auto, auto),
    stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
    inset: (y: 5pt),
    [*Feature*], [*C*], [*Rust*],
    [Garbage collector], [✗], [✗],
    [Runtime], [minimal], [none],
    [Boxing by default], [✗], [✗],
    [Virtual dispatch by default], [✗], [✗],
    [Exception tables], [✗], [✗ (panic = abort)],
    [Hidden allocations], [✗], [✗],
  )

  #callout[
    Rust's borrow checking, lifetime analysis, and trait resolution are *all compile-time*. The runtime binary is indistinguishable from equivalent hand-written C.
    #ref-badge[kornel.ski/rust-c-speed — empirical analysis]
  ]
][
  *What Rust adds over C*

  - *LLVM backend* — same optimiser as Clang. Identical IR, identical codegen
  - *Alias information*: Rust's exclusivity rule tells LLVM that `&mut T` pointers never alias — enabling optimisations C cannot guarantee
    ```rust
    // Rust can auto-vectorise this because the compiler
    // PROVES src and dst do not overlap:
    fn copy_dma(dst: &mut [u8], src: &[u8]) {
        dst.copy_from_slice(src);
    }
    // C requires `restrict` keyword and hopes the
    // programmer is honest about aliasing
    ```
  - *Panic = abort* in kernel / embedded: `#![panic_handler]` resolves to a halt — no unwind tables, no binary bloat
]

== Benchmarks — what the numbers say

#callout[
  *"In many benchmarks, Rust and C are within 1–3% of each other. When Rust is faster, it is usually because the aliasing information enables better auto-vectorisation. When C is faster, it is usually because a C programmer hand-optimised a specific inner loop."*
  #ref-badge[kornel.ski/rust-c-speed, 2023; The Computer Language Benchmarks Game, 2024]
]

#cols[
  *Industrial data points*

  - *Cloudflare Pingora* (Rust, replaces Nginx): same throughput, *\~70 % lower memory usage* per connection
    #ref-badge[Cloudflare Blog, "How we built Pingora", 2022]
  - *Mozilla Firefox* (Rust CSS engine, Stylo): *2× speedup* vs. C++ equivalent, fewer CVEs
    #ref-badge[Mozilla Engineering Blog, "Servo and Stylo", 2017]
  - *Android Binder* (Rust rewrite): *zero regressions* in performance; eliminated the UAF CVE class in IPC
    #ref-badge[Android Open Source Blog, "Memory safety for Android", 2021]
  - *Linux mlx5 driver tests*: Rust prototype showed no measurable overhead vs. C on throughput benchmarks
    #ref-badge[LPC 2022: "Rust in the Linux kernel" talk, kernel.org]
][
  *The aliasing advantage — concrete example*

  ```c
  // C: compiler cannot vectorise safely
  // — it cannot prove buf_in ≠ buf_out
  void add_headers(u8 *buf_out, const u8 *buf_in,
                   size_t n) {
      for (size_t i = 0; i < n; i++)
          buf_out[i] = buf_in[i] | 0x80;
  }
  // Must use `restrict` to get auto-vectorisation
  ```

  ```rust
  // Rust: exclusive mutable borrow PROVES no overlap
  // Compiler auto-vectorises without any annotation
  fn add_headers(out: &mut [u8], in_buf: &[u8]) {
      for (o, &b) in out.iter_mut().zip(in_buf) {
          *o = b | 0x80;
      }
  }
  ```

  #callout(color: safe-green)[
    The *same type-system property* that prevents data races *also enables better codegen*. Safety and performance are not in tension — they arise from the same source.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. THE BIGGER PICTURE — RUST TOOLING ECOSYSTEM
// ─────────────────────────────────────────────────────────────────────────────
= The Ecosystem — Rust is Reshaping the Toolchain

== A language that attracted a new toolchain generation

#callout[
  Rust's safety guarantees and modern ergonomics have attracted developers to build *entire new categories of tooling* in it — not just systems software. These tools now affect your daily workflow whether you use Rust or not.
]

#cols[
  *These slides are written in Rust*

  - *Typst* — next-generation document system (these slides)
    \ Zero-config, sub-second compile, Git-friendly plain text
    \ Written entirely in Rust #ref-badge[typst.app]

  *Your build pipeline*

  - *ripgrep* (`rg`) — faster `grep` #ref-badge[github.com/BurntSushi/ripgrep]
  - *fd* — faster `find`
  - *bat* — syntax-highlighting `cat`
  - *Ruff* — Python linter, 10–100× faster than pylint
    #ref-badge[astral.sh/ruff]
  - *uv* — Python package manager, replaces pip
  - *swc* — JS/TS compiler, 70× faster than Babel
][
  *Critical infrastructure, written in Rust*

  - *Cloudflare Pingora* — processes 1 trillion requests/day
    #ref-badge[Cloudflare Blog, 2022]
  - *AWS Firecracker* — microVM hypervisor powering Lambda & Fargate
    #ref-badge[NSDI 2020]
  - *Google crosvm* — ChromeOS VM monitor
  - *Microsoft Azure* — hypervisor components
  - *1Password* — password manager core

  *The meta-point for this audience*

  Rust adoption signals a shift in how systems software is written. Teams that invest now — especially in kernel driver work where safety guarantees directly translate to CVE reduction — will have a measurable engineering advantage within 2–3 years.
]

// ─────────────────────────────────────────────────────────────────────────────
//  8. REFERENCES
// ─────────────────────────────────────────────────────────────────────────────
= References <touying:hidden>

== Academic references

#set text(size: 0.75em)

*Formal verification of Rust's type system*

- Jung, R., Jourdan, J-H., Krebbers, R., Dreyer, D. *"RustBelt: Securing the Foundations of the Rust Programming Language."* _Proc. ACM Program. Lang._ 2, POPL, Article 66. January 2018. #link("https://plv.mpi-sws.org/rustbelt/popl18/")[plv.mpi-sws.org/rustbelt/popl18]
- Dang, H-H., Jourdan, J-H., Kaiser, J-O., Dreyer, D. *"RustBelt Meets Relaxed Memory."* _Proc. ACM Program. Lang._ 4, POPL, Article 34. January 2020.
- Grannan, Z., Bílý, A., et al. *"Place Capability Graphs: A General-Purpose Model of Rust's Ownership and Borrowing Guarantees."* arXiv:2503.21691, 2025.
- Silva, T., Bispo, J., Carvalho, T. *"Foundations for a Rust-Like Borrow Checker for C."* LCTES 2024. ACM.
- Li, J., et al. *"Formally Understanding Rust's Ownership and Borrowing System at the Memory Level."* _Formal Methods in System Design,_ Vol. 64, Issue 1. Springer, July 2024.

*Industry data — memory safety statistics*

- Microsoft Security Response Centre. *"A Proactive Approach to More Secure Code."* Gavin Thomas, 2019.
- Gaynor, A., Thomas, G. *"Memory Safety in the Linux Kernel."* Linux Security Summit, 2019.
- Google Project Zero. *"A Survey of Memory Safety Issues in Chrome."* 2020. #link("https://googleprojectzero.blogspot.com")[googleprojectzero.blogspot.com]
- Android team. *"Memory Safety in Android."* Android Open Source Blog, 2021.

== Industry references

#set text(size: 0.75em)

*Performance analysis*

- Paczos, K. *"The Speed of Rust vs C."* #link("https://kornel.ski/rust-c-speed")[kornel.ski/rust-c-speed], 2023.
- The Computer Language Benchmarks Game. #link("https://benchmarksgame-team.pages.debian.net/benchmarksgame")[benchmarksgame-team.pages.debian.net], 2024.
- Compiler Explorer (Godbolt). Rustc -O2 output verification. #link("https://godbolt.org")[godbolt.org]

*Production deployments*

- Cloudflare. *"How We Built Pingora, Our Rust-based HTTP Proxy."* Cloudflare Blog, 2022. #link("https://blog.cloudflare.com/how-we-built-pingora")[blog.cloudflare.com]
- Agache, A., et al. *"Firecracker: Lightweight Virtualization for Serverless Applications."* NSDI 2020. USENIX.
- Mozilla. *"Shipping Rust in Firefox: The Quantum CSS / Stylo Story."* Mozilla Engineering Blog, 2017.

*Standards and language specifications*

- The Rust Reference. #link("https://doc.rust-lang.org/reference")[doc.rust-lang.org/reference], 2024.
- Rust RFC 0243. *"Trait-based exception handling."* rust-lang.org/RFCs/0243.
- Stroustrup, B. *"Foundations of C++."* ESOP 2012. Springer.

*Kernel-specific*

- Ojeda, M., et al. *"Rust in the Linux Kernel."* LPC 2022 talk. #link("https://kernel.org")[kernel.org]
- Linux Kernel Documentation: `Documentation/rust/`. #link("https://docs.kernel.org/rust/")[docs.kernel.org/rust]
- Corbet, J. *"Rust Goes Mainstream in the Linux Kernel."* LWN.net, December 2025.

// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *The borrow checker is not a restriction.*

  It is a proof system that tells you, at submission time,\
  that your driver does not have a use-after-free, a data race,\
  a missing error path, or an uninitialised pointer.

  Every kernel bug it catches is a CVE that never ships.
]

== 
#focus-slide[
  #text(size: 1.6em, weight: "bold")[
    Thank you.
  ]

  Questions?
]
