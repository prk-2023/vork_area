#import  "prastutih_theme.typ": *

// Global Configuration:
#show: doc => setup-presentation(
  title: [Introduction to Rust & eBPF with Rust],
  author: [ Pulumati Ram ],
  institution: [ RealTek Semiconductor Corporation ],
  doc
)

// Focus slides are specialized Metropolis layouts for big, centered text
#hero-slide(
  img: "./realtek_icons.png", 
  topic-title: " Introduction to Rust & eBPF with Rust ",
  topic-subtitle: "[Pulumati Ram] 
  [RealTek Semiconductor Corporation]"
)
// Renders the automatic title slide based on the config-info in your theme
#title-slide()

#focus-slide[
  #text(size: 1.2em, weight: "bold")[#underline(stroke: 1pt + rust-red)[> Disclaimer <] 
  ]

  #v(0.8em)

  #text(fill: rgb("#f66"))[
  Focus on systems evolution, not a language war 
  ]
  #line(length: 63%, stroke: 1pt + rust-red)
  #v(0.5em)

    \- Rust is not here to replace C everywhere \- #linebreak()
    \- Complementary systems programming tool \- #linebreak() 
    \- focus on spatial/temporal memory safety bugs. \-
]

// Another focus slide using the 'fancy-block' helper defined in theme.typ
#focus-slide[
  #v(0.3em)

  #fancy-block("#1", "Rust as a systems programming language","zero-cost abstraction, borrow checker, memory layout ctrl, fearless concurrency, Rust in Linux kernel" )

  #v(0.3em)

  #fancy-block("#2", "eBPF programming with Rust","Aya framework, observability case study")
]

== Agenda <touying:hidden>
#outline(title: none, indent: 1.5em, depth: 1)

// A Top-level heading (=) creates a Section Divider slide in Metropolis
= Introduction to Rust :
#text(size: 0.6em, fill: black.lighten(35%) )[A Systems Programmer's Perspective:]

#text(size: 0.8em, fill: black.lighten(45%))[· `Memory Safety`]
#text(size: 0.8em, fill: black.lighten(45%))[· `Compiler Guarantees`]
#text(size: 0.8em, fill: black.lighten(45%))[· `Modern Concepts`]
#text(size: 0.8em, fill: black.lighten(45%))[· `performance`]

== Systems programming language: 

#cols[
  *Systems software: controls hardware and mediates between it and everything else.*

  It's characterised by three constraints which are its requirements:

  1. *Direct hardware access*: memory-mapped registers, DMA engines, interrupt controllers
  2. *No managed runtime*: no garbage collector, no VM, no OS safety net beneath you 
  3. *Correctness is load-bearing*: A bug does not crash one user session; it crashes the whole system, corrupts flash, or silently misdelivers data to hardware

  *Your daily work is systems programming:*
  - Peripheral drivers (PCIe, MIPI, USB, UART, I2C, SPI)
  - DMA engine bring-up, scatter-gather list management
  - Power management (DVFS, clock trees, voltage domains)
  - Boot firmware, secure monitor. 
  - Android HAL native layer, Binder IPC, ION/DMA heap management
][
  *The languages that have historically owned this domain*

  #codebox(
    [

  #table(
    columns: (auto, auto, auto, auto),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 6pt),
    [*Language*], [*Domain*], [*Memory safe?*], [*No GC?*],
    [Assembly], [firmware, boot], [✗], [✓],
    [C],         [OS, drivers, embedded], [✗], [✓],
    [C++],       [firmware, RTOS, Android HAL], [✗ ¹], [✓],
    [Go],        [tooling, cloud], [✓], [✗],
    [*Rust*],    [*all of the above*], [*✓*], [*✓*],
  )

  #text(size: 0.6em, fill: luma(100))[
    ¹ RAII helps; raw pointers escape freely.\
  ]
    ]
  )

  #callout(color: safe-green)[
    Rust is the first language to occupy the *top-right cell simultaneously*, giving memory safety *and* no GC — with a formally verified type system. #ref-badge[Jung et al., RustBelt, POPL 2018]
  ]
]

// == Systems programming languages :
// // A double heading (==) creates a standard slide with a title at the top
// #cols[
//   #text(size: 0.9em, fill: black.lighten(27%))[
//     > Direct Hardware Access and Low-Level Control
//
//     > Zero-Cost Abstractions
//
//     > Manual or Deterministic Memory Management
//
//     > Minimal Runtime Environment
//
//     > Stability and Predictability
//   ]
// ][
//   #table(
//     gutter: 1em,
//     columns: (1fr, 1fr, 1fr, 1fr),
//     stroke: (x: none, y: 0.4pt + gray.lighten(45%)),
//     inset: (left: 1pt, top: 3pt, bottom: 7pt, right: 0pt),
//     [*Feature*],[*C*],[*C++*],[*Rust*],
//     [Memory Safety],[No],[Manual (RAII)],[Yes (Compile-time)],
//     [Garbage Collection],[None],[None],[None],
//     [Complexity],[Low],[Very High],[High],
//     [Abstraction Power],[Low],[High],[High],
//   )
// ]

// == The eternal memory bugs
//
// // Using the 'cols' helper for side-by-side layout
// #cols[
//   #block(fill:luma(220), inset:.5em, radius: .2em, width:100%) 
//   *The numbers haven't moved in 20 years*
//
//   - *~70 %* of Microsoft CVEs are memory safety bugs
//     #ref-badge[Microsoft Security Response Centre, 2019] // Using our custom ref-badge
//     
//   - *~67 %* of Linux kernel CVEs are memory safety violations
//     #ref-badge[Gaynor & Thomas, 2019]
//   
//
// ][
//   #block(fill:luma(220), inset:.5em, radius: .2em, width:100%) 
//   *The root causes*
//   #table(
//     columns: (auto, 1fr),
//     stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
//     inset: (y: 6pt, x: 4pt),
//     [*Cause*], [*C has no protection against...*],
//     [Use-after-free], [accessing freed memory via a dangling pointer],
//     [Buffer overflow], [writing past the end of an allocation],
//     [Data race], [two threads accessing shared memory without synchronisation],
//   )
//   
// ]
== The cost of the status quo — in numbers

#cols(
  [
  *Industry-wide memory safety statistics*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Source*], [*Finding*],
    [Microsoft MSRC], [~70 % of all CVEs are memory safety bugs],
    [Chrome team], [~70 % of high-severity bugs are memory safety],
    [Linux kernel], [~67 % of CVEs are memory safety violations],
    [Android team], [Memory unsafety estimated at \$68B in security costs],
    [NSA guidance], [C and C++ flagged as "memory-unsafe" languages],
    [CISA], ["The Case for Memory Safe Roadmaps" — mandates shift],
  )
  #callout[
    - These safety stats haven't changes in 20 years.
  ]

  #ref-badge[Microsoft MSRC 2019; Google Project Zero 2020; Linux Security Summit 2019; CISA 2023]
],[
  *The bug classes that drive these numbers*

  - *Use-after-free (UAF)*: most common kernel CVE class: IRQ handler retains a pointer to freed `struct device`
  - *Buffer overflow / OOB write*: DMA descriptor overrun corrupts adjacent kernel data
  - *Null dereference*: `container_of()` result not checked, dereferenced in probe path
  - *Data race*: two CPUs write a shared DMA counter without a lock
  - *Uninitialised read*: `struct` field read before all error paths initialise it
  - *Integer overflow*:  `nents * sizeof(entry)` wraps; under-allocated scatter-gather list

  #callout[
    - These are not exotic bugs requiring complex/adversarial inputs, they are everyday bugs we also encounter while de-bugging during SoC bring-up.
    - KASAN, KCSAN, and lockdep catch them at runtime 
    - *Rust prevents them at compile time.*
  ]
],
ratio: (0.8fr, 1.2fr),
)

// Three dashes (---) create a new slide while keeping the same title
== Fix for the status quo:

  // Using our custom callout box with the accent bar
  #callout[
    The only way to eliminate a class of bugs is to make them unrepresentable in the type system.
  ]
  // Overriding the default color of the callout
  #callout(color: safe-green)[
    - Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
    - Rust meets all the systems programming requirements.
      - 3rd Programming model. ( mem mgmt via Ownership & borrowing )
      - type-system, compiler.
  ]

// == Landscape before Rust 
//
// #cols[
//   *Status :*
//   - Current systems are powerful but they come with limitations 
//     - absolute performance (C/C++) (manual memory mgmt)
//     - absolute safety (Java/python/go) (automatic mem mgmt) 
//
//   - GC languages: pauses ( due to clean up ) High cost of overhead, unpredictable. 
//
//   - Large C code base quickly becomes developer centric.
//
//   ][
//     *Rust Features*
//
//     - Ownership Model: Safe, no GC Max performance.
//
//     - Zero-Cost Abstraction. ( no additional CPU cycles to achieve memory safety )
//     
//     - Rust moves development model from developer centered to *Langauge features + Compiler*
//   ]

// == Rust Programming model and feaures: ( summarized )
//
//   To solve memory related issues:
//   - C/C++ : manual memory management 
//   - GC ( python,java ): pauses ( due to clean up ) High cost of overhead, unpredictable. 
//   - Ownership Model: Safe, no GC Max performance 
//
//   #table(
//     columns: (1fr, 1fr, 1fr, 1fr),
//     stroke: (x: none, y: 0.4pt + rust-red.lighten(25%)),
//     inset: (left: 1pt, top: 3pt, bottom: 7pt, right: 0pt),
//     [Feature],[Manual (C)],[Garbage Collected (Java)],[Ownership (Rust)],
//     [Performance],[Maximum],[Lower (GC overhead)],[Maximum],
//     [Safety],[Low (Dangling pointers)],[High],[High],
//     [Responsibility],[Programmer],[Runtime System],[Compiler],
//     [Complexity],[High (Error prone)],[Low (Easy)],[Medium (Learning curve)],
//   )
//   - Rust moves development model from developer centered to *Langauge features + Compiler*

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
  #codebox(
    [
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
    ]
  )

  `unsafe { }` is not "turn off Rust" — it is an *explicit declaration* that you are taking responsibility for the invariants the type system cannot verify. It is grep-able, auditable, and contained.
]

== Property 3 — Zero-cost abstractions

#cols[
  *The Stroustrup principle, applied*

  > "What you don't use, you don't pay for. What you do use, you couldn't hand-code any better."

  Rust's abstractions compile to the same machine code as the equivalent hand-written C. This is not a promise — it is verifiable on Compiler Explorer.

  *Iterators and closures — no overhead*

  #codebox(
    [
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
    ]
  )
  #ref-badge[Compiler Explorer — godbolt.org; rustc -O2]
][
  *Generics — monomorphisation, not boxing*

  #codebox(
    [
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
    ]
  )

  *Lifetime annotations are erased before codegen*

  #codebox(
    [
      ```rust
      // 'a is compile-time analysis only — zero runtime cost:
      fn longest<'a>(x: &'a [u8], y: &'a [u8]) -> &'a [u8] { 
        if x.len() >= y.len() { x } else { y }
      }
      // Generates: same two-compare, one-return instruction
      //            sequence as the C pointer version
      ```
    ]
  )

  #callout(color: safe-green)[
    Borrow checking, lifetime analysis, type inference — all stripped before LLVM sees the code. *The runtime binary is as lean as hand-written C.*
  ]
]

== The aliasing advantage — Rust beats C's optimiser

This is the often-overlooked performance *advantage* Rust has *over* C.

#cols[
  *The C aliasing problem*

  C's pointer aliasing rules (C99 §6.5) say two pointers of different types *may not* alias — but two `u8*` pointers *might* always alias. The compiler must assume they overlap.

  #codebox(
    [  
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
    ]
  )
][
  *Rust's aliasing proof*

  Rust's exclusivity rule (`&mut T` is exclusive — no other reference exists) *proves* at compile time that `out` and `in_buf` do not overlap. LLVM gets this information and auto-vectorises without any annotation.

  #codebox(
    [
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
    ]
  )

  #callout(color: safe-green)[
    The *same property* that prevents data races also enables better codegen. Safety and performance arise from the same source: the aliasing proof in the type system.
  ]
]

=  Important Language features:

- Ownership 
- Borrowing 
- Lifetimes 
- Thread Safety 


== Ownership : Memory Safety at Compile Time

*The three ownership rules*

#cols[
  - *Rule 1 : Each value has exactly one owner* 
  - *Rule 2 : There can only be one owner at a time (ownership can be moved).*

  #codeblock(title: "C : compiles, crashes or corrupts silently")[
  ```rust
  let s1 = String::from("hello"); // s1 owns the heap data
  let s2 = s1;          // ownership MOVES to s2
  // println!("{}", s1); // ← compile error: s1 was moved
  ```
  ]

  The compiler tracks ownership *statically*. No runtime book keeping.

  - *Rule 3 : When the owner goes out of scope, the value is dropped*

  #codeblock(title: "C : compiles, crashes or corrupts silently")[
  ```rust
  {
      let buf = alloc_dma_buf(); // allocation
  }   // ← Drop::drop() called HERE, automatically
      // No free() to forget. No leak possible.
  ```
  ]
][
#callout[
  *Rust's ownership system* it's a type theoretic answer to manual memory management. 
  - It's a memory management model where each value has a single owner at a time, and the Compiler enforces rules about ownership/borrowing/lifetimes. 
  - Shifts memory safety from a runtime concern (like GC) to a compile time verification handled by the type system. 
]
  #callout(color: safe-green)[ -> Shifts memory safety from a runtime concern (like garbage collection) to a compile-time verification problem handled by the type system.
  ]
]

== Ownership vs C: use-after-free

Most common kernel CVE class : caught at compile time in Rust.

#callout[
  - This is not a bug detection problem.
  - This is program expressiveness problem. 
]

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
  - The error message names the *exact line* where the value was moved and the *exact line* of the illegal use, before the code ever runs. 
  - no `valgrind`, no `KASAN`, no `OEM` execution.
]


== Ownership prevents leaks — RAII ( kernel )

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

]
#callout(color: safe-green)[
  - Cleanup is automatic and deterministic via scope exit, each resource implements `Drop`, ensuring release on all return paths.
  - No explicit error-path cleanup logic required.
  - Rust turns "developer-managed control flow problem" $->$ "compiler-enforced lifetime and scope rule"
 // - *Zero `goto` cleanup; chains.* The compiler guarantees cleanup runs on every path. 
 // - Linux has thousands of `goto err_free_XYZ` labels that this eliminates.
]


// ──────────────────────
//  BORROWING & LIFETIMES
// ──────────────────────
= Borrowing & Lifetimes — Preventing Data Races

== Borrowing : the aliasing rules formalised

#callout[
  *Borrowing* is Rust's system for temporary access without transferring ownership. \ This is implemented via References, which are distinct in Rust compiler view. 
  //  It formalises the aliasing rules that C developers know informally but often violate.
]

#v(0.6em)

#cols[
  *Shared (immutable) borrows : `&T`*

  - Multiple readers can coexist
  - None can write while readers exist
  - Maps to: read-lock held, RCU read section

  #codebox(
    [ 
      ```rust
      fn print_all(items: &[DmaEntry]) { /* read-only */ }
      let ring = RingBuffer::new(256);
      print_all(&ring.entries);  // borrow
      print_all(&ring.entries);  // another borrow — fine
      // ring is still valid and owned here
      ```
    ]
  )
  #callout(color: rust-red)[
    *Data Race* = aliasing + mutation + no synchronisation
  ]
][
  *Exclusive (mutable) borrow : `&mut T`*

  - *One* writer, *no* concurrent readers
  - Maps to: write-lock held, spinlock held

  #codebox(
    [
      ```rust 
      fn add_entry(ring: &mut RingBuffer, e: DmaEntry) { 
        ring.entries.push(e); // exclusive access 
      }
      
      let mut ring = RingBuffer::new(256); 
      add_entry(&mut ring, entry);
      // `ring` is fully accessible again after add_entry returns
      ```
    ]
  )
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


== Important additional concepts:

Additional topics that are for those who want to go down the rabbit hole: 

- *Traits*: Rust's explicit code interfaces, defining shared behavior across different data types.

- *Generics*: Compile-time templates that allow you to write algorithms that work with multiple data types
  without code duplication, evaluated entirely at build time.

- *Trait-bounds*: Compile-time constraints on generics, allowing you to tell the compiler: 
  'This generic function only works on types that implement a specific hardware interface or trait.'

- *Smart pointers*: Custom data structures that act like pointers but wrap raw memory with automatic 
  lifecycle tracking, like managing a reference-counted memory region.

- *iterators*: Highly optimized, composable pointer-traversal abstractions that let you loop through arrays 
  or ring buffers safely without raw index pointer arithmetic.

- *macros*: Code-generation tools that compile down at build time, allowing you to write highly expressive 
  code without incurring any runtime or performance overhead.

- *attributes*:  Declarative metadata attached to your code, used for things like conditional compilation for 
  different processor targets or forcing explicit struct packing layout alignment.
// - Traits
// - Generics
// - Trait-bounds
// - Smart pointers
// - iterators
// - macros 
// - attributes 

// ───────────────────
//  4. COMPILER CHECKS
// ───────────────────

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
    #codebox(
      [ 
        ```rust 
        match direction { 
          DmaDir::ToDevice   => { … },
          DmaDir::FromDevice => { … }, 
          // error if DmaDir::Bidirectional not handled 
        }
        ```
      ]
    )
][
  *Error handling*
  - *`Result<T, E>`* — ignoring an error is a *compiler warning*
  #codebox(
    [
    ```rust
    #[must_use = "this Result must be handled"]
    fn map_dma(...) -> Result<SgTable, DmaError> { … }

    map_dma(dev, sg, nents); // warning: unused Result
    // The kernel C equivalent: silently dropping -ENOMEM
    ```
    ]
  )
  - `Option<T>` — no null, no null-deref

  *Unsafe quarantine*
  - `unsafe { }` blocks are *explicitly marked*
  - `grep -r "unsafe"` gives the *complete* audit surface
  - Safe code cannot call `unsafe` functions accidentally

  #callout[
    In C, all of the above require separate tools: ASAN, UBSAN, sparse, Coccinelle, clang-tidy, GCC sanitizers — none of them are mandatory, and none are exhaustive.
  ]
]

==  ecosystem: 

#callout[
  - Unlike C, where langauge/compiler/build system are seperate.
  - Rust rejects this fragmented approach and provides an entire unified development platform out of the box.
]
- Cargo ( Build system, package manager, test runner, doc generator all in one )
- tooling ( rustfmt, clippy )
- crates ( crate.io central repo)
- docs   ( docs.rust-lang.org)

// == Linux Kernel 
//
// - Rust is not going to replace C, The strong compile-time correctness helps to meaningfully reduce risks. 
// - Chronological update of Rust in Linux kernel. 
// - No more experimental 
// - Adoption Map.
//
// == Concepts useful for kernel/firmware work:
//
// - FFI ( precise control over memory ) Which is key for BPS/Firmware/low-level work.
// - Bitlevel layout control ( Key to access HW registers , MMIO ...)
// - `bindgen` 
// - Abstraction: C functions are not called directly by via wraps in safe Rust interfaces .
// - safe and unsafe encapsulation 
// - For kernel: kernel build flow 

= eBPF 

- A quick overview/refresher
- Why Rust for eBPF programs
- Aya 

== Quick Overview: 

#cols(
  [
  *eBPF: in one sentence*

  `eBPF` is a Linux Kernel model that lets you load user-supplied programs into the kernel *without a kernel patch, without a module, and without rebooting*, the kernel verifier guarantees safety.

  *The four-step plumbing tasks:*

  1. *Write* — BPF bytecode (from C or Rust source)
  2. *Verify* — kernel verifier: bounded loops, no OOB, type-checked
  3. *JIT* — native machine code; zero interpreter overhead after load
  4. *Attach* — hook point (kprobe, tracepoint, XDP, LSM, …) fires on event

  #callout[
  If the verifier accepts the program, it *cannot* crash the kernel ( checks for infinite-loop, or access out-of-bounds memory... more)
  ]
  ],[
  #image("./ebpf_plumbing.png")
  // *Common Hook types that are used*
  //
  // #table(
  //   columns: (auto, 1fr),
  //   stroke: (x: none, y: 0.3pt + luma(220)),
  //   inset: (y: 5pt),
  //   [`kprobe` / `kretprobe`], [any kernel function entry/return],
  //   [`tracepoint`], [stable kernel trace points],
  //   [`tp_btf`], [typed tracepoints — CO-RE friendly],
  //   [`perf_event`], [hardware PMU counters],
  //   [`xdp`], [NIC fast path — pre network stack],
  //   [`lsm`], [Linux Security Module hooks],
  //   [`cgroup_skb`], [per-cgroup packet filtering],
  //   [`raw_tp`], [raw tracepoints — lowest overhead],
  // )
], 
ratio: (1.5fr, 0.7fr),
)


== eBPF maps — the data bridge

#cols[
  *Maps = the only I/O channel for BPF programs*

  - Shared memory between kernel BPF code and userspace reader
  - Created by the loader before the program is attached
  - Accessed from both sides via file descriptors

  #table(
    columns: (1fr, 1fr),
    stroke: (x: none, y: 0.3pt + luma(220)),
    inset: (y: 4pt),
    [*Type*], [*Typical use*],
    [`HASH`], [key → value lookup],
    [`RINGBUF`], [high-throughput event stream ✓],
    [`PERCPU_ARRAY`], [per-CPU stats, lock-free],
    [`LRU_HASH`], [connection tracking],
    [`PERF_EVENT_ARRAY`], [legacy event pipe],
    [`ARRAY`], [fixed-size indexed data],
  )
][
  *Ring buffer : the preferred choice*

  #ref-badge[Introduced: Linux 5.8 — BPF_MAP_TYPE_RINGBUF]

  - Variable-length records — no fixed-size overhead
  - Single contiguous allocation — cache-friendly
  - `epoll` / `AsyncFd` compatible — Tokio-native in Aya
  - Dropped-event counter exposed to userspace for monitoring
  - #codeblock(title: "In Aya")[
  `#[map] static EVENTS: RingBuf = RingBuf::with_byte_size(4 * 1024 * 1024, 0);`
]
  #callout[
    Prefer `RINGBUF` over `PERF_EVENT_ARRAY` for all new work — lower overhead, simpler consumer, no per-CPU complexity.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. DOES RUST FIT eBPF?
// ─────────────────────────────────────────────────────────────────────────────

= Does Rust Fit eBPF?

== Why Rust is a natural fit for eBPF programs

#cols[
  *Shared constraints*

  eBPF programs and Rust both operate under the same fundamental constraint: *no undefined behaviour is acceptable*.

  - The BPF verifier rejects programs it cannot prove safe
  - Rust's type system rejects programs it cannot prove safe
  - Both operate at compile time or load time — not at runtime

  *`no_std` alignment*

  eBPF programs run with no kernel library, no allocator, no OS primitives. Rust's `#![no_std]` mode is the natural target — `aya-ebpf` provides the BPF-side runtime (`bpf_helpers`, map types, program macros) without any standard library dependency.
][
  *Type safety across the kernel boundary*

  The most expensive eBPF bug class in C: a *map* `struct` definition in the BPF program and the userspace loader that silently diverge.

#codeblock()[
  ```c

  // BPF program (C):
  struct event { u64 ts; u32 pid; };
  bpf_ringbuf_output(&rb, &e, sizeof(e), 0);

  // Userspace loader (C) — different file:
  struct event { u64 ts; u64 pid; }; // u64 ≠ u32 !
  // Reads wrong data — no compile error, no warning
  ```
]

  *Aya's solution*: one `#[no_std]` *common crate*, compiled for both targets. The `struct` is defined *once*. Layout disagreement is a *compile error*, not a runtime bug.

  #callout(color: rust-red)[
    This is the highest-value safety property of Rust for eBPF — not just memory safety in the BPF program, but *type-safe communication across the kernel/userspace boundary*.
  ]
]

== Key differences: 

#cols[
1. C based workflows:
  - *No strong cross-boundary sharing:*
    - Kernel side struct definition 
    - User space struct definition 
  Are duplicated manually.
    - Even using common headers, they are not enforced across compilation targets.

2. *No compiler-level guarantee of ABI consistency:*
  - Same struct in two places can silently diverge:
    - padding differences
    - type changes (u32 vs u64)
    - ordering changes
  C will still compile fine.
3. *Weak enforcement of "single source of truth"*
  - can centralize headers
    but nothing forces user-space and BPF-side builds to stay in sync.
][
  - Rust’s advantage one shared type definition across both worlds and enforced by the compiler.
  - ABI mismatches become compile-time errors.
#callout[
'C can absolutely run in a no_std-like environment, but the real challenge is the lack of compile-time enforcement that kernel and user-space agree on data layouts and interfaces.'
]
]

== Bytecode Generation with Rust: 

#cols[
  *C eBPF toolchain*

#codeblock(title: "C to bytecode")[
```c
program.bpf.c
     │
     │  clang -target bpf -O2 -g
     ▼
program.bpf.o     ← ELF with BPF bytecode + BTF
     │
     │  bpftool gen skeleton
     ▼
program.skel.h    ← generated C loader
     │
     │  gcc / clang (host)
     ▼
program             ← userspace binary
```
]

  What you need: 
  - *clang + LLVM (BPF backend) + bpftool + libelf + libbpf*. 
  - C toolchain mandatory for the BPF program even if userspace is Rust (libbpf-rs).
][
  *Rust / Aya toolchain*

#codeblock(title: "Rust to bytecode")[
```
program-ebpf/src/main.rs    (eBPF side)
program-common/src/lib.rs   (shared types)
program/src/main.rs         (userspace side)
     │
     │  rustc --target bpfel-unknown-none
     │  + bpf-linker (LLVM BPF backend)
     ▼
ELF object (embedded via include_bytes_aligned!)
     │
     │  cargo build (host)
     ▼
program             ← single self-contained binary
  ```
]

  What you need: 
  - *rustc (nightly) + bpf-linker*. ( no `clang`, no `bpftool`, no `libelf`, no `C` toolchain. The BPF ELF is embedded in the userspace binary: single artifact to deploy. )

  #callout[
    Aya does not wrap `libbpf`: it is a *pure-Rust reimplementation* of the BPF syscall layer, built on `libc` only.
    #ref-badge[github.com/aya-rs/aya — "built from the ground up purely in Rust"]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. THE eBPF PIPELINE
// ─────────────────────────────────────────────────────────────────────────────
= The eBPF Pipeline : Source to Running Hook

== Five stages from source to attached program

#v(0.4em)
#grid(
  columns: (1fr, 0.08fr, 1fr, 0.08fr, 1fr, 0.08fr, 1fr, 0.08fr, 1fr),
  gutter: 0pt,
  pipe-box(1, "Write", "Author BPF source:\nmap declarations,\nhook attributes,\nhelper calls", color: ebpf-teal),
  align(center + horizon, text(size: 1.2em, fill: ebpf-teal, "→")),
  pipe-box(2, "Compile", "Source → BPF bytecode\n(ELF object).\nBTF debug info\nembedded.", color: ebpf-teal),
  align(center + horizon, text(size: 1.2em, fill: ebpf-teal, "→")),
  pipe-box(3, "Load", "Userspace opens ELF,\ncreates maps,\nresolves CO-RE\nrelocations.", color: ebpf-teal),
  align(center + horizon, text(size: 1.2em, fill: ebpf-teal, "→")),
  pipe-box(4, "Verify + JIT", "Kernel verifier\nproves safety.\nJIT compiler emits\nnative code.", color: safe-green),
  align(center + horizon, text(size: 1.2em, fill: safe-green, "→")),
  pipe-box(5, "Attach", "Program linked to\nhook point.\nFires on every\nmatching event.", color: safe-green),
)
#v(0.6em)

#cols[
  *Stage 1 — Write*

  - Declare maps at crate/file level with attributes

  - Annotate functions with hook type (`#[kprobe]`, `#[tracepoint]`, …)

  - Call BPF helpers (`bpf_ktime_get_ns`, `bpf_get_current_comm`, …)

  - Access kernel struct fields via CO-RE macros

  - Share event struct definition with userspace via common crate / header
][
  *Stage 5 — Attach (detail)*

  The attachment is a *file descriptor* that the kernel holds. When it closes, the program is automatically detached — no cleanup code needed.

  - `kprobe`: attach to any kernel function symbol by name
  - `tracepoint`: attach to `subsystem/event_name` in tracefs
  - `xdp`: attach to a network interface by name
  - `lsm`: attach to a specific LSM hook name

  - *Aya*: the attachment is a Rust struct implementing `Drop` trait. RAII cleanup guaranteed, even on panic paths.
]

// ─────────────────────────────────────────────────────────────────────────────
//  HOW libbpf HANDLES EACH STAGE
// ─────────────────────────────────────────────────────────────────────────────
= The libbpf Approach — Stage by Stage

== libbpf: write & compile

#cols[
  *Stage 1 — Write (C)*

#codeblock(title: "program.bpf.c")[
  ```c
  #include "vmlinux.h"          // all kernel types in one header
  #include <bpf/bpf_helpers.h>
  #include <bpf/bpf_tracing.h>

  // Map declaration — section name encodes type
  struct {
      __uint(type, BPF_MAP_TYPE_RINGBUF);
      __uint(max_entries, 4 * 1024 * 1024);
  } events SEC(".maps");

  // Shared event struct — must match userspace manually
  struct dma_event { u64 start_ns; u32 nents; u32 pid; };

  // Hook attribute — clang section magic
  SEC("kprobe/dma_map_sg")
  int BPF_KPROBE(dma_map_sg_enter, …) {
      struct dma_event e = {};
      e.start_ns = bpf_ktime_get_ns();
      // …
      bpf_ringbuf_reserve(&events, sizeof(e), 0);
      return 0;
  }
  char LICENSE[] SEC("license") = "GPL";
  ```
]
][
  *Stage 2 — Compile (C toolchain)*

#codeblock(title: "Generate vmlinux.h: kernel types from BTF file")[
  ```bash
  # Generate vmlinux.h — all kernel types from BTF
  bpftool btf dump file /sys/kernel/btf/vmlinux \
      format c > vmlinux.h

  # Compile BPF source to BPF ELF object
  # -target bpf:  BPF bytecode output
  # -g:           embed BTF debug info (CO-RE)
  # -O2:          required: some BPF features need optimisation
  clang -target bpf -g -O2 \
      -D__TARGET_ARCH_x86 \
      -I. \
      -c program.bpf.c \
      -o program.bpf.o

  # Inspect the result
  llvm-objdump -d program.bpf.o   # disassemble BPF bytecode
  bpftool btf dump file program.bpf.o  # verify BTF is present
  ```
]

  The output `program.bpf.o` is a standard ELF file containing:
  - `.text` section: BPF bytecode instructions
  - `.BTF` section: type information for CO-RE
  - `.maps` section: map definitions
  - Relocation sections for helper calls
]

== libbpf: skeleton generation & loading

#cols[
  *Stage 2b — Generate skeleton (optional but recommended)*

#codeblock(title: "Auto generate type-safe C loader header")[
  ```bash
  # Auto-generate a type-safe C loader header
  bpftool gen skeleton program.bpf.o \
      > program.skel.h
  ```
]

  The generated `program.skel.h` provides:

#codeblock(title: "program.skel.h")[
  ```c
  struct program_bpf {
      struct bpf_object_skeleton *skeleton;
      struct bpf_object *obj;
      struct {
          struct bpf_map *events;  // typed map access
      } maps;
      struct {
          struct bpf_program *dma_map_sg_enter;
      } progs;
      struct {
          struct bpf_link *dma_map_sg_enter;
      } links;
  };
  // Auto-generated lifecycle functions:
  // program__open()  program__load()
  // program__attach() program__destroy()
  ```
]
][
  *Stage 3 — Load & Stage 4 verify (C userspace)*

#codeblock(title: "")[
  ```c
  #include "program.skel.h"
  struct program_bpf *skel;

  // Open: parse ELF, discover maps and programs
  skel = program__open();

  // (optional) pre-load configuration:
  skel->rodata->min_latency_ns = 1000;

  // Load: create maps, CO-RE relocations, submit to kernel verifier
  program__load(skel);
  // At this point: kernel has verified and JIT'd the program.
  // Maps are created and their fds are in skel->maps.*

  // Attach: link programs to hook points
  program__attach(skel);
  // dma_map_sg_enter now fires on every dma_map_sg() call
  ```
]
  - *CO-RE relocation* happens inside `__load()`: `libbpf` reads `/sys/kernel/btf/vmlinux`, patches field offsets in the BPF bytecode to match the running kernel's struct layout.
  - The skeleton collapses open + load + attach into three typed function calls. Without skeleton: you call `bpf_object__open()`, iterate programs, call `bpf_program__load()` per program, then `bpf_program__attach()` — verbose and untyped.
]

== libbpf: maps & teardown

#cols[
  *Maps from the C userspace side*

#codeblock(title: "Map from user space")[
  ```c
  // Access map fd from skeleton
  int map_fd = bpf_map__fd(skel->maps.events);

  // Ring buffer consumer (callback model)
  struct ring_buffer *rb = ring_buffer__new(
      map_fd, handle_event, NULL, NULL);

  // Poll — blocks until events or timeout
  while (running) {
      ring_buffer__poll(rb, 100 /* timeout ms */);
  }

  // Callback invoked per event
  static int handle_event(void *ctx,
      void *data, size_t size) {
      struct dma_event *e = data;
      printf("pid=%u latency=%.3f µs\n",
             e->pid,
             (e->end_ns - e->start_ns) / 1000.0);
      return 0;
  }
  ```
]
][
  *Stage 5 teardown (C)*

  #codeblock(title: "")[
  ```c
  // Teardown — must be called explicitly
  ring_buffer__free(rb);
  program__detach(skel);    // closes bpf_link fds
  program__destroy(skel);   // frees maps, programs, object

  // If __destroy() is not called:
  // - Maps leak until process exits
  // - Programs may stay attached if link pinned to bpffs
  // - No compiler warning, no safety net
  ```
  ]

  *Deployment dependencies*

  To ship a libbpf-based tool you need:
  - `libbpf.so` (or static `libbpf.a`) on the target
  - `libelf.so` (required by libbpf)
  - `libz.so` (required by libelf)
  - The `program.bpf.o` object file *or* embed it via skeleton

  #callout(color: warn-amber)[
    On Android or embedded targets: managing `.so` dependencies across OEM kernel variants is a real distribution problem. This is exactly what Aya solves.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. HOW AYA HANDLES EACH STAGE
// ─────────────────────────────────────────────────────────────────────────────
= How Rust (Aya) Handles Each Stage

== Stage-by-stage comparison

// Column headers
#grid(columns: (1fr, 1fr, 1fr), gutter: 1pt,
  block(fill: luma(220), radius: 4pt, inset: (x:8pt,y:6pt), width: 100%,
    text(size: 0.72em, weight: "bold", "Stage")),
  block(fill: blue.lighten(80%), radius: 4pt, inset: (x:8pt,y:6pt), width: 100%,
    text(size: 0.72em, weight: "bold", fill: blue.lighten(15%), "libbpf (C)")),
  block(fill: ebpf-teal.lighten(80%), radius: 4pt, inset: (x:8pt,y:6pt), width: 100%,
    text(size: 0.72em, weight: "bold", fill: ebpf-teal, "Aya (Rust)")),
)
#vs-row("1. Write BPF source",
  "C source (.bpf.c), SEC() macros,\nbpf_helpers.h, vmlinux.h",
  "Rust source (no_std), #[kprobe] / #[map]\nattributes, aya-ebpf crate")
#vs-row("2. Compile → bytecode",
  "clang -titlearget bpf -g -O2\n→ program.bpf.o",
  "rustc --target bpfel-unknown-none\n+ bpf-linker → ELF object")
#vs-row("2b. Skeleton / embedding",
  "bpftool gen skeleton → program.skel.h\nIncluded in userspace C source",
  "include_bytes_aligned!() embeds ELF\ninto userspace binary at compile time")
#vs-row("3. Open / parse ELF",
  "bpf_object__open() or skel__open()\nReads ELF, discovers maps & progs",
  "Ebpf::load(BYTES) — pure Rust ELF\nparser (aya-obj), no libelf dep")
#vs-row("4. Load + verify",
  "bpf_object__load() or skel__load()\nMaps created, CO-RE patches applied,\nbpf() syscall → verifier → JIT",
  "prog.load() per program type\nAya performs CO-RE, calls bpf() syscall\nSame kernel verifier & JIT path")
#vs-row("4b. Attach to hook",
  "skel__attach() or bpf_program__attach()\nbpf_link fd returned",
  "prog.attach(\"dma_map_sg\", 0)?\nReturns typed handle implementing Drop")
#vs-row("5. Maps: read events",
  "ring_buffer__new() + ring_buffer__poll()\nCallback-based consumer",
  "RingBuf::try_from(map)? + AsyncFd\nAsync / epoll — Tokio-native")
#vs-row("6. Teardown",
  "skel__detach() + skel__destroy()\nManual, must not forget",
  "RAII — all handles Drop automatically\nCompiler guarantees cleanup")

== Aya BPF-side: write & declare

#cols[
  #codeblock(title: "dma-tracer-ebpf/src/main.rs : BPF program Rust")[

    ```rust
    #![no_std]
    #![no_main]
    use aya_ebpf::{
        helpers::{bpf_ktime_get_ns,
                  bpf_get_current_pid_tgid},
        macros::{kprobe, kretprobe, map},
        maps::{HashMap, RingBuf},
        programs::{ProbeContext, RetProbeContext},
    };
    use dma_tracer_common::DmaEvent; // ← shared type

    // ── Maps — declared at crate level ──────────
    #[map]
    static START: HashMap<u64, u64> =
        HashMap::with_max_entries(4096, 0);

    #[map]
    static EVENTS: RingBuf =
        RingBuf::with_byte_size(4 * 1024 * 1024, 0);

    // ── Hook: kprobe on dma_map_sg entry ────────
    #[kprobe]
    pub fn dma_map_sg_enter(ctx: ProbeContext) -> u32 {
        let pid_tgid = bpf_get_current_pid_tgid();
        let pid = (pid_tgid & 0xFFFF_FFFF) as u32;
        let key = pid as u64;
        let ts = unsafe { bpf_ktime_get_ns() };
        let _ = START.insert(&key, &ts, 0);
        0
    }
    ```
  ]
][
#codeblock(title: "kretprobe — measure & emit")[
    ```rust
    #[kretprobe]
    pub fn dma_map_sg_exit(ctx: RetProbeContext) -> u32 {
        let end = unsafe { bpf_ktime_get_ns() };
        let pid = (bpf_get_current_pid_tgid()
                   & 0xFFFF_FFFF) as u32;
        let key = pid as u64;

        if let Some(start) = START.get(&key) {
            let _ = START.remove(&key);
            // Reserve slot in ring buffer
            if let Some(mut buf) =
                EVENTS.reserve::<DmaEvent>(0)
            {
                unsafe {
                    (*buf.as_mut_ptr()).latency_ns =
                        end.saturating_sub(*start);
                    (*buf.as_mut_ptr()).pid = pid;
                }
                buf.submit(0);
            }
        }
        0
    }

    #[cfg(not(test))]
    #[panic_handler]
    fn panic(_: &core::panic::PanicInfo) -> ! {
        loop {}   // BPF panic = halt
    }
    ```
  ]
]

== Aya userspace: load, attach, consume

#cols[
  #codeblock(title: "dma-tracer/src/main.rs — userspace loader")[
    ```rust
    use aya::{include_bytes_aligned, Ebpf,
              maps::RingBuf,
              programs::{KProbe, KRetProbe}};
    use aya_log::EbpfLogger;
    use tokio::io::unix::AsyncFd;

    // BPF ELF embedded at compile time — no runtime file I/O
    static BPF_CODE: &[u8] = include_bytes_aligned!(
        concat!(env!("OUT_DIR"),
                "/dma-latency-tracer-ebpf")
    );

    #[tokio::main]
    async fn main() -> anyhow::Result<()> {
        // ── Load ──────────────────────────────
        let mut bpf = Ebpf::load(BPF_CODE)?;
        EbpfLogger::init(&mut bpf).ok();

        // ── Attach kprobe ─────────────────────
        let entry: &mut KProbe = bpf
            .program_mut("dma_map_sg_enter")?
            .try_into()?;
        entry.load()?;
        entry.attach("dma_map_sg", 0)?;

        // ── Attach kretprobe ──────────────────
        let exit: &mut KRetProbe = bpf
            .program_mut("dma_map_sg_exit")?
            .try_into()?;
        exit.load()?;
        exit.attach("dma_map_sg", 0)?;
    ```
  ]
][
  #codeblock(title: "Async ring-buffer consumer")[
    ```rust
        // ── Consume ring buffer ───────────────
        let rb_map = bpf.take_map("EVENTS")?;
        let ring = RingBuf::try_from(rb_map)?;
        // Wrap in AsyncFd → Tokio epoll integration
        let async_fd = AsyncFd::new(ring)?;

        loop {
            tokio::select! {
                _ = tokio::signal::ctrl_c() => break,
                guard = async_fd.readable() => {
                    let mut g = guard?;
                    let rb = g.get_inner_mut();
                    while let Some(item) = rb.next() {
                        let ev: DmaEvent = unsafe {
                            *(item.as_ptr()
                              as *const DmaEvent)
                        };
                        println!(
                          "pid={} lat={:.2}µs",
                          ev.pid,
                          ev.latency_ns as f64/1000.0
                        );
                    }
                    g.clear_ready();
                }
            }
        }
        // ── Teardown: automatic via Drop ──────
        // bpf, entry, exit, rb all drop here —
        // links closed, maps freed, no leak possible
        Ok(())
    }
    ```
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. AYA ARCHITECTURE OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
= Aya Architecture Overview

== Component map

#cols(ratio: (1fr, 1fr))[
  *Aya crate family*

  ```
  ┌──────────────────────────────────────────┐
  │  Your userspace loader (std, async)      │
  │  uses: aya, aya-log, aya-obj             │
  ├──────────────────────────────────────────┤
  │  aya            — core loader library    │
  │  Ebpf::load()   programs  maps  links    │
  ├──────────────────────────────────────────┤
  │  aya-obj        — ELF + BTF + CO-RE      │
  │  Pure Rust ELF parser, relocation engine │
  ├──────────────────────────────────────────┤
  │  aya-log        — userspace log receiver │
  │  Reads aya-log-ebpf ring messages        │
  └──────────────────────────────────────────┘

  ┌──────────────────────────────────────────┐
  │  Your BPF program (no_std, no_main)      │
  │  uses: aya-ebpf, aya-log-ebpf            │
  ├──────────────────────────────────────────┤
  │  aya-ebpf       — BPF-side runtime       │
  │  #[map]  #[kprobe]  #[xdp]  helpers      │
  ├──────────────────────────────────────────┤
  │  aya-log-ebpf   — log from BPF programs  │
  │  info!() warn!() → aya-log ring buffer   │
  ├──────────────────────────────────────────┤
  │  aya-ebpf-bindings — kernel type defs    │
  │  Generated from kernel uapi headers      │
  └──────────────────────────────────────────┘
  ```
][
  *What each component handles*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 2pt),
    [*`aya`*], [Load BPF ELF, create maps, attach programs, manage links. Pure-Rust bpf() syscall wrapper. CO-RE via aya-obj.],
    [*`aya-obj`*], [Parse BPF ELF, process BTF sections, apply CO-RE relocations. No libelf dependency.],
    [*`aya-ebpf`*], [BPF-side runtime: `#[map]`, `#[kprobe]`, `#[xdp]`, `#[lsm]`, … macros; helper function wrappers; map type structs.],
    [*`aya-log`*], [Userspace receiver: polls a dedicated ring buffer for log records from aya-log-ebpf.],
    [*`aya-log-ebpf`*], [BPF-side: `info!()`, `warn!()`, `debug!()` macros that format and submit log events to the log ring buffer.],
    [*`aya-tool`*], [CLI: generates Rust bindings (`vmlinux.rs`) from kernel BTF — equivalent of `bpftool btf dump … format c > vmlinux.h`.],
  )

  #callout[
    *No libbpf, no libelf, no C toolchain required at runtime.* The entire stack is pure Rust + one `bpf()` syscall.
    #ref-badge[github.com/aya-rs/aya, 2024]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. CREATING AN AYA PROJECT
// ─────────────────────────────────────────────────────────────────────────────
= Creating an Aya Project

== Prerequisites and scaffold

#cols[
  *Prerequisites*

  ```bash
  # 1. Rust nightly (build-std required for BPF target)
  rustup toolchain install nightly \
      --component rust-src

  # 2. bpf-linker — LLVM BPF backend for rustc
  cargo install bpf-linker

  # 3. aya-tool — BTF → Rust bindings generator
  cargo install aya-tool

  # 4. Verify LLVM BPF backend is present
  rustc +nightly --print target-list | grep bpfel
  # bpfel-unknown-none  ← must appear
  ```

  *Scaffold with the Aya template*

  ```bash
  # cargo-generate scaffolds the three-crate workspace
  cargo install cargo-generate

  cargo generate --git \
      https://github.com/aya-rs/aya-template \
      --name dma-latency-tracer
  ```
][
  *Generated workspace structure*

  #codebox(
    [
    ```
    dma-latency-tracer/
    ├── Cargo.toml                  ← workspace root
    ├── rust-toolchain.toml         ← pins nightly
    │
    ├── dma-latency-tracer-common/
    │   └── src/lib.rs              ← #[no_std] shared types
    │                                 DmaEvent, histogram bounds
    │
    ├── dma-latency-tracer-ebpf/
    │   ├── .cargo/config.toml      ← target=bpfel-unknown-none
    │   ├── Cargo.toml              ← aya-ebpf dep
    │   └── src/main.rs             ← #[kprobe], #[kretprobe]
    │
    └── dma-latency-tracer/
        ├── build.rs   ← KEY        ← cross-compiles eBPF crate,
        │                             copies to $OUT_DIR
        ├── Cargo.toml        ← aya dep, tokio
        └── src/main.rs       ← Ebpf::load, attach, ringbuf
  ```
    ]
  )

  #callout[
    *No xtask needed.* A single `cargo build` cross-compiles the eBPF crate (via `build.rs`) and embeds the result. One command, one binary output.
  ]
]

== The three Cargo.toml files — key dependencies

#cols[
  #codeblock(title: "dma-latency-tracer-ebpf/Cargo.toml")[
    ```toml
    [package]
    name    = "dma-latency-tracer-ebpf"
    version = "0.1.0"
    edition = "2021"

    [[bin]]
    name = "dma-latency-tracer-ebpf"
    path = "src/main.rs"

    [dependencies]
    # BPF-side runtime: macros, map types, helpers
    aya-ebpf     = "0.1"
    # Logging from BPF programs
    aya-log-ebpf = "0.1"
    # Shared struct definitions (no_std)
    dma-latency-tracer-common = {
        path = "../dma-latency-tracer-common",
        default-features = false
    }
    ```
  ]
][
  #codeblock(title: "dma-latency-tracer/Cargo.toml (userspace)")[
    ```toml
    [package]
    name    = "dma-latency-tracer"
    version = "0.1.0"
    edition = "2021"

    [dependencies]
    # Core Aya loader library (async_tokio feature)
    aya      = { version = "0.13", features = ["async_tokio"] }
    aya-log  = "0.2"

    # Shared event struct (with std features enabled)
    dma-latency-tracer-common = { path = "../.." }

    # Async runtime — ring buffer consumer
    tokio    = { version = "1", features = [
        "macros", "rt-multi-thread", "signal", "time"] }
    anyhow   = "1"
    clap     = { version = "4", features = ["derive"] }
    log      = "0.4"
    env_logger = "0.11"

    [build-dependencies]
    anyhow   = "1"     # build.rs error handling
    ```
  ]
]

== build.rs — the key integration file

#codeblock(title: "dma-latency-tracer/build.rs — drives eBPF cross-compilation")[
  ```rust
  use std::{env, path::PathBuf, process::Command};

  fn main() -> Result<(), Box<dyn std::error::Error>> {
      let out_dir      = PathBuf::from(env::var_os("OUT_DIR").unwrap());
      let manifest_dir = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap());
      let workspace    = manifest_dir.parent().unwrap().to_path_buf();
      let cargo        = env::var_os("CARGO").map(PathBuf::from)
                             .unwrap_or_else(|| PathBuf::from("cargo"));

      // Rebuild when BPF source changes
      println!("cargo::rerun-if-changed=../dma-latency-tracer-ebpf/src/main.rs");
      println!("cargo::rerun-if-changed=../dma-latency-tracer-common/src/lib.rs");

      let profile = env::var("PROFILE").unwrap_or("debug".into());

      // Cross-compile the eBPF crate to bpfel-unknown-none
      let status = Command::new(&cargo)
          .current_dir(&workspace)
          .arg("+nightly")
          .arg("build")
          .arg("--package").arg("dma-latency-tracer-ebpf")
          .arg("--target").arg("bpfel-unknown-none")
          .arg("-Z").arg("build-std=core")
          .args(if profile == "release" { &["--release"][..] } else { &[] })
          .status()?;

      if !status.success() { return Err("eBPF build failed".into()); }

      // Copy compiled BPF ELF to OUT_DIR for include_bytes_aligned!()
      let src = workspace.join("target/bpfel-unknown-none")
                         .join(&profile).join("dma-latency-tracer-ebpf");
      std::fs::copy(&src, out_dir.join("dma-latency-tracer-ebpf"))?;
      Ok(())
  }
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  8. AYA PROS AND CONS
// ─────────────────────────────────────────────────────────────────────────────
= Aya — Pros and Cons

== The honest assessment

#cols[
  *Strengths*

  - *Pure Rust end-to-end* — no C toolchain, no libelf, no libbpf.so on the target. Ship a single statically-linked binary.
  - *Type-safe kernel/userspace boundary* — shared `common` crate; struct layout divergence is a compile error.
  - *RAII teardown* — attachment handles implement `Drop`; cleanup is compiler-guaranteed, not programmer-remembered.
  - *Async-native* — `AsyncFd<RingBuf>` integrates with Tokio directly; no callback model needed.
  - *CO-RE support* — BTF-based relocations via `aya-obj`; one binary across kernel versions.
  - *Static binary + musl* — deploy on Android, embedded, or any Linux target without library concerns.
  - *aya-log* — `info!()` from BPF programs to userspace with zero boilerplate.
  - *Active ecosystem* — Red Hat (bpfman), Deepfence (ebpfguard), Kubernetes SIG-Network (Blixt) all use Aya in production.
    #ref-badge[aya-rs.dev, 2024]
][
  *Limitations and caveats*

  - *Nightly Rust required* for building the BPF crate (`-Z build-std=core`, unstable features). Stable toolchain cannot target `bpfel-unknown-none` today.
  - *Smaller ecosystem* than libbpf-C. libbpf has a larger set of reference examples, upstream docs, and kernel integration tests.
  - *Some program types lag* — not all BPF program types have first-class Aya support; may need `unsafe` raw syscalls for cutting-edge hooks.
  - *bpf-linker* is a separate install — it bundles LLVM; takes time to install and can lag behind upstream LLVM releases.
  - *No bpftrace-like one-liner* — Aya is a library, not a scripting frontend. For ad-hoc investigation, bpftrace (C) remains the fastest tool.
  - *Debugging BPF verifier errors* — verifier output is in raw log form; Aya surfaces it but does not beautify it (neither does libbpf).

  #callout(color: warn-amber)[
    *Guidance*: for production eBPF tools built and maintained by a Rust-capable team — use Aya. For quick one-off probes and kernel-side investigation — `bpftrace` first, then promote to Aya when the pattern is proven.
  ]
]


== Rust for eBPF programming:

#callout[
  - Kernel does not care the bytecode is generated from C/Rust/Go/Zig.\ Rust is chosen for its type system & owenership model which make is safe and align with eBPF verifier's strict rules, reducing time and frustration. 
]
#cols[
  eBPF Bytecode generation is mainly about:
  - Predictable low level compilation 
  - Restricted Runtime behavior 
  - Controllable Memory Model 
  - Ability to Target the BPF Backend in LLVM. 
][

  #table(
    columns: (1fr, 1fr),
    stroke: (x: 0.4pt + rust-red.lighten(25%), y: 0.4pt + rust-red.lighten(25%)),
    inset: (left: 9pt, top: 4pt, bottom: 7pt, right: 0pt),
    [ *Rust Feature*         ],[ ---    ],
    [ Native compilation     ],[ Yes    ],
    [ _no_std_, _no_main_    ],[ Yes    ],
    [ No mandatory runtime   ],[ Yes    ],
    [ No GC                  ],[ Yes    ],
    [ Memory safety          ],[ Yes    ],
    [ LLVM support           ],[ Yes    ],
    [ Low-level control      ],[ Yes    ],
    [ Deterministic behavior ],[ Mostly ]
  )
]
#callout[
  - small runtime footprint, deterministic execution, compile-time safety, LLVM BPF backend support
  - makes Rust more practical to write eBPF programs then others.
]
// #callout[
//   - Programming eBPF with Rust: Fast path for kernel developers to become familiar with Rust, shared tooling and abstraction. 
// ]
//
==  `eBPF` CO-RE overview 

- Recap of eBPF ( libbpf/ CO-RE )
- Steps and flow 

== Possible approaches to run eBPF with Rust 

- `Aya`: Full Rust based approach to run eBPF 
- `libbpf-rs`: leverage `libbpf-c` and Rust

== Aya:

- Framework and its components 
- Typical Aya project 
- How to build Kernel and Userspace loader program 

== Cross build ( CO-RE )

- How to cross build aya project 
- `musl` toolchain => highly portable ( true CO-RE )

== Example:

- DMA latency mapper: 
- Project layout 

== Common region 

- Helps memory Interface between kernel and user-space 

== Kernel eBPF program (kernel space)

- eBPF program 
- `no_std` and `no_main` 
- `#panic` handler 
- Maps 

== Loader (user-space)

- User Space loader 
- find and load byte code 
- attach 
- create map 

== Loader, multiple hooks point, sync and telemetry.

- Async program model 
- multiple hook points and maps 
- extensions telemetry and logging.. ( todo )

== Demo  

- example crates 
- Demo and analysis 
- Comparison with `libbpf-c`

