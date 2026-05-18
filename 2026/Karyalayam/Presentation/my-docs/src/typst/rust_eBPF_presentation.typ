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

// A Top-level heading (=) creates a Section Divider slide in Metropolis
= Introduction to Rust :
#text(size: 0.6em, fill: black.lighten(35%) )[A Systems Programmer's Perspective:]

#text(size: 0.8em, fill: black.lighten(45%))[· `Memory Safety`]
#text(size: 0.8em, fill: black.lighten(45%))[· `Compiler Guarantees`]
#text(size: 0.8em, fill: black.lighten(45%))[· `Modern Concepts`]
#text(size: 0.8em, fill: black.lighten(45%))[· `performance`]

== Systems programming languages :
// A double heading (==) creates a standard slide with a title at the top
#cols[
  #text(size: 0.9em, fill: black.lighten(27%))[
    > Direct Hardware Access and Low-Level Control

    > Zero-Cost Abstractions

    > Manual or Deterministic Memory Management

    > Minimal Runtime Environment

    > Stability and Predictability
  ]
][
  #table(
    gutter: 1em,
    columns: (1fr, 1fr, 1fr, 1fr),
    stroke: (x: none, y: 0.4pt + gray.lighten(45%)),
    inset: (left: 1pt, top: 3pt, bottom: 7pt, right: 0pt),
    [*Feature*],[*C*],[*C++*],[*Rust*],
    [Memory Safety],[No],[Manual (RAII)],[Yes (Compile-time)],
    [Garbage Collection],[None],[None],[None],
    [Complexity],[Low],[Very High],[High],
    [Abstraction Power],[Low],[High],[High],
  )
]

== The eternal memory bugs

// Using the 'cols' helper for side-by-side layout
#cols[
  #block(fill:luma(220), inset:.5em, radius: .2em, width:100%) 
  *The numbers haven't moved in 20 years*

  - *~70 %* of Microsoft CVEs are memory safety bugs
    #ref-badge[Microsoft Security Response Centre, 2019] // Using our custom ref-badge
    
  - *~67 %* of Linux kernel CVEs are memory safety violations
    #ref-badge[Gaynor & Thomas, 2019]
  

][
  #block(fill:luma(220), inset:.5em, radius: .2em, width:100%) 
  *The root causes*
  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
    inset: (y: 6pt, x: 4pt),
    [*Cause*], [*C has no protection against...*],
    [Use-after-free], [accessing freed memory via a dangling pointer],
    [Buffer overflow], [writing past the end of an allocation],
    [Data race], [two threads accessing shared memory without synchronisation],
  )
  
]

// Three dashes (---) create a new slide while keeping the same title
#pause

  // Using our custom callout box with the accent bar
  #callout[
    The only way to eliminate a class of bugs is to make them unrepresentable in the type system.
  ]
  // Overriding the default color of the callout
  #callout(color: safe-green)[
    - Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
    - type-system, compiler.
  ]

== Why Rust and Landscape before Rust ( 3rd programming model )

#cols[
  *Status :*

  - Current systems are powerful but they also come with limitations 
    - absolute performance (C/C++) (manual memory mgmt)
    - absolute safety (Java/python/go) (automatic mem mgmt) 
  - Developer centric
  - Rust meets all the systems programming requirements.
    - 3rd Programming model. ( mem mgmt via Ownership & borrowing )

  ][
  *Before Rust:*

  - GC and fail to meet the needs. 
  - How Rust provides a third programming model to fix this
  - Change from developer centric to languge+compiler mandates
  ]

== Rust Programming model and feaures: ( summarized )

  To solve memory related issues:
  - C/C++ : manual memory management 
  - GC ( python,java ): pauses ( due to clean up ) High cost of overhead, unpredictable. 
  - Ownership Model: Safe, no GC Max performance 

  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    stroke: (x: none, y: 0.4pt + rust-red.lighten(25%)),
    inset: (left: 1pt, top: 3pt, bottom: 7pt, right: 0pt),
    [Feature],[Manual (C)],[Garbage Collected (Java)],[Ownership (Rust)],
    [Performance],[Maximum],[Lower (GC overhead)],[Maximum],
    [Safety],[Low (Dangling pointers)],[High],[High],
    [Responsibility],[Programmer],[Runtime System],[Compiler],
    [Complexity],[High (Error prone)],[Low (Easy)],[Medium (Learning curve)],
  )
  - Rust moves development model from developer centered to *Langauge features + Compiler*

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

  ```rust
  fn print_all(items: &[DmaEntry]) { /* read-only */ }

  let ring = RingBuffer::new(256);
  print_all(&ring.entries);  // borrow
  print_all(&ring.entries);  // another borrow — fine
  // ring is still valid and owned here
  ```
  #callout(color: rust-red)[
    *Data Race* = aliasing + mutation + no synchronisation
  ]
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

- overview.
- Rust features for eBPF programs.
- Aya 

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
    [ *Rust Feature*           ],[    ],
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

