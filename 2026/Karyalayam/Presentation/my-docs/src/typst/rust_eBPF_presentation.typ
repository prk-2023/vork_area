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
  img: "./Realtek.jpg", 
  topic-title: " Introduction to Rust & eBPF with Rust ",
  topic-subtitle: "[Pulumati Ram] 
  [RealTek Semiconductor Corporation]"
)
// Renders the automatic title slide based on the config-info in your theme
#title-slide()

// Another focus slide using the 'fancy-block' helper defined in theme.typ
#focus-slide[
  #v(0.3em)

  #fancy-block("#1", "Rust as a systems programming language","zero-cost abstraction, Borrow checker, memory layout ctrl, Fearless concurrency, Rust in Linux kernel" )

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

== The eternal memory bug

// Using the 'cols' helper for side-by-side layout
#cols[
  *The numbers haven't moved in 20 years*

  - *~70 %* of Microsoft CVEs are memory safety bugs
    #ref-badge[Microsoft Security Response Centre, 2019] // Using our custom ref-badge
    
  - *~67 %* of Linux kernel CVEs are memory safety violations
    #ref-badge[Gaynor & Thomas, 2019]

][
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

== Why Rust:

- Current systems are powerful but they also come with limitations
- developer centric 
- Rust meets all the systems programming requirements.

== Landscape before Rust:


- GC and fail to meet the needs. 
- How Rust provides a third programming model to fix this
- Change from developer centric to languge+compiler mandates

== Rust Programming model and feaures:

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

== Ownership:

- What is Ownership and its importance. 
- What are the Ownership rules.
- Ownership rules and memory management model. 
- Who enforces these rules ( developer to compiler shift )

== Ownership and RAII 

- resource acquisition is initialization 
- key point for its acceptance into Linux kernel 

== Borrowing 

- trouble Ownership can introduce, and how borrowing helps.
- references.
- Borrowing and Its Rules.
- Features of Borrowing and what it helps fix/prevent.
- Compiler.

== Borrowing and Lifetimes:

- What is Lifetime.
- How compiler helps to ensure every reference points to valid memory. 
- Lifetime annotation (`'a`), ( developer help compiler with additional info on references )
- compare it with C ( How lifetime lead to no NULLPointer and UAF ).
- Example Device driver /Bor

== `Sync` and `Send` ( Thread safety )

- Thread safety is baked into Type system through *marker traits*: `Send` & `Sync`
- Send trait 
- Sync trait 
- How other languages allow passing of non-thread safe object leading to crash (that happen sometimes).
- `Send` & `Sync` prevent data-race

== Other important concepts:

- Traits
- Generics
- Trait-bounds
- Smart pointers
- iterators
- macros 
- attributes 

= Compiler 

== Compiler Task: 

- Memory Safety 
- TypeSystem Guarantees ( correctness )
- Error handling ( risk isolation with `unsafe` boundaries )
- Shift System reliability from runtime debugging and external tooling to compile-time enforcement by the
  language itself. 

==  Rust ecosystem: 

- Language 
- Compiler 
- Cargo
- tooling
- crates 
- docs 

== Linux Kernel 

- Rust is not going to replace C, The strong compile-time correctness helps to meaningfully reduce risks. 
- Chronological update of Rust in Linux kernel. 
- No more experimental 
- Adoption Map.

== Concepts useful for kernel/firmware work:

- FFI ( precise control over memory ) Which is key for BPS/Firmware/low-level work.
- Bitlevel layout control ( Key to access HW registers , MMIO ...)
- `bindgen` 
- Abstraction: C functions are not called directly by via wraps in safe Rust interfaces .
- safe and unsafe encapsulation 
- For kernel: kernel build flow 


= eBPF 


== Introduction eBPF with Rust.

- With official support in kernel and possible to experiment Rust with eBPF.
- eBPF bytecode verifier. 
- Crates and current status. 

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

