// Import presentation template 

#import "./vivarta.typ": *

// Global Configuration  for the presentations:
#show: doc => setup-presentation(
  title: [Introduction to Rust & eBPF with Rust],
  author: [PulumatiRam],
  institution: [ Realtek SemiConductor Corporation ],
  doc
)


// Focus Slide ( using specialized Metropolis layout for Big, centered text .. )
#hero-slide(
  img: "./imgs/realtek.jpg",
  topic-title: " Introduction to Rust & eBPF with Rust ",
  topic-subtitle: "[ Pulumati Ram ]"
)
// Render the automatic title slide based on vivarta::config-info
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

// ToC:
== Agenda <touying:hidden>
#outline(title: none, indent: 1.5em, depth: 1)
//#components.adaptive-columns(outline(indent: 1em))

// Top level heading: (=) to Create a section divider slide in Metropolis:
= Introduction to Rust:

#text(size: 0.6em, fill: black.lighten(25%) )[A Systems Programmer's Perspective:]

#text(size: 0.6em, fill: black.lighten(45%))[· `Memory Safety`]
#text(size: 0.6em, fill: black.lighten(45%))[· `Compiler Guarantees`]
#text(size: 0.6em, fill: black.lighten(45%))[· `Modern Concepts`]
#text(size: 0.6em, fill: black.lighten(45%))[· `performance`]

== Evaluating Rust for Systems Programming :
#cols[
  *Systems software:* Controls hardware and mediates between it and everything else.

  It's characterised by three constraints which are its requirements:

  1. *Direct hardware access*: memory-mapped registers, DMA engines, interrupt controllers
  2. *No managed runtime*: no garbage collector, no VM, no OS safety net beneath you 
  3. *Correctness is load-bearing*: A bug does not crash one user session; it crashes the whole system, corrupts flash, or silently misdelivers data to hardware

  *Rust as systems software:*
  Compiles directly to Machine code via *LLVM*, with zero overhead for bare-metal work.
  - *_no_std_* : attribute instructs compiler to isolate std lib and OS layers.
  - *_unsafe_* : Its the auditable escape hatch ( allows low-level operations, to be placed in blocks for audit)
  - *_asm!_ * : Supports architecture-specific instructions. 
][
  - *_#[repr(C)]_* : Binary Compatibility, Rust data-structs match exact memory layout of C, ensures seamless FFI execution when working with C.
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
    // [Go],        [tooling, cloud], [✓], [✗],
    [*Rust*],    [*all of the above*], [*✓*], [*✓*],
  )

  #text(size: 0.6em, fill: luma(100))[
    ¹ RAII helps; raw pointers escape freely.\
  ]
    ]
  )

  #callout(color: safe-green)[
    - Rust is the first language to satisfy, memory safety with out GC, and has a formally verified type system. #ref-badge[Jung et al., RustBelt, POPL 2018]
    - Trade off: steep learning curve.
  ]
]

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
//== Fix for the status quo:
--- 
 Fix for the status quo:

  // Using our custom callout box with the accent bar
  #callout[
    The only way to eliminate a class of bugs is to make them un-representable in the type system.
  ]
  // Overriding the default color of the callout
  #callout(color: safe-green)[
    - Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
    - Rust meets all the systems programming requirements.
      - 3rd Programming model. ( Memory Management Via Ownership & Borrowing )
      - type-system, compiler.
  ]
  #callout(color: rust-red)[
    Moving correctness and safety checks from runtime debugging into compile-time enforcement:
    - use-after-free:         *Compile time error* 
    - iterator invalidation:  *Compile time error*
    - double free:            *Compile time error* 
    - and many forms of data races: *Compile time error*
    ...
  ]

// ---------------------------
// Rust as systems programming 
// ---------------------------
= How Rust Fits Systems Programming

== The three properties that make Rust a systems language

#cols[
  *Property 1:  No garbage collector, no runtime*

  Rust has no GC, no reference-counting runtime, no background threads, no stop-the-world pause. The memory model is:

  - Stack allocation: zero overhead, exactly like C `int x;`
  - Heap allocation: explicit, backed by the allocator you choose
  - Destructor: called at a *statically known point* by the compiler, not by a runtime at an unpredictable time

  This means Rust code can run:
  - In interrupt handlers (ISR context)
  - In firmware before the MMU is enabled
  - In a `#![no_std]` kernel module with no OS beneath it
  - On a bare-metal microcontroller with 16 KB of RAM

  *The binary output is a standard ELF: same format as a C object file.* A Rust kernel module is a `.ko` that `insmod`, `lsmod`, and `rmmod` treat identically.
][
  *Property 2:  Direct hardware access*

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

  // Inline assembly : same as GNU C __asm__ __volatile__
  use core::arch::asm;
  unsafe {
      asm!("dsb sy", options(nostack));
  }

  // Raw pointer arithmetic : same as C, explicitly unsafe
  let ptr = base_addr as *mut u32;
  unsafe { *ptr.add(offset) = value; }
  ```
    ]
  )

  *`unsafe { }`* is not "turn off Rust": it is an *explicit declaration* that you are taking responsibility for the invariants the type system cannot verify. It is grep-able, auditable, and contained.
]

// New slide with same title
--- 
*Property 3:  Zero-cost abstractions* (The Stroustrup principle, applied )
    - "What you don't use, you don't pay for. What you do use, you couldn't hand-code any better."
    - Rust's abstractions compile to the same machine code as the equivalent hand-written C. 
  //This is not a promise, it is verifiable on  #ref-badge[Compiler Explorer: https://godbolt.org; rustc -O2 )]

  #codeblock()[
    ```c
#[unsafe(no_mangle)]                           |int square(int num) {                   |.LC0:                                                          
pub fn square(num: i32) -> i32 {               |    return num * num;                   |        .string "panic: attempt to multiply with overflow\n" 
    num * num                                  |}                                       |"square":                                                    
}                                              |// assembly                             |        push    rbp                                          
// assembly                                    |"square":                               |        mov     rbp, rsp                |#include <stdio.h>                 |
square:                                        |        push    rbp                     |        sub     rsp, 32                 |#include <stdlib.h>                |
        push    rax                            |        mov     rbp, rsp                |        mov     DWORD PTR [rbp-20], edi |int square(int num) {              |
        mov     dword ptr [rsp + 4], edi       |        mov     DWORD PTR [rbp-4], edi  |        mov     edx, 0                  |int result;                        |
        imul    edi, edi                       |        mov     eax, DWORD PTR [rbp-4]  |        mov     eax, DWORD PTR [rbp-20] |if (__builtin_mul_overflow (    |                
        mov     dword ptr [rsp], edi           |        imul    eax, eax                |        imul    eax, eax                |  num,num,& result) {              |
        seto    al                             |        pop     rbp                     |        jno     .L2                     |   fprintf(stderr,                 |
        jo      .LBB0_2                        |        ret                             |        mov     edx, 1                  |   "panic multiply with overflow");|
        mov     eax, dword ptr [rsp]           |                                        |.L2:                                    |   abort();// abort like rs        |
        pop     rcx                            |                                        |        mov     DWORD PTR [rbp-4], eax  |}                                  |
        ret                                    |                                        |        mov     eax, edx                                     
.LBB0_2:                                       |                                        |        and     eax, 1                                       
        lea     rdi, [rip + .Lanon.2fc01....1]                                          |        test    al, al                                       
        call    qword ptr [rip + core[18c8dd30382e7099]::panicking::panic_const::pan..  |        je      .L4                                          
                                                                                        |        mov     rax, QWORD PTR "stderr"[rip]                 
.Lanon.2fc01ec765ec0cb3dcc559126de20b30.0:                                              |        mov     rcx, rax                                     
        .asciz  "/app/example.rs"                                                       |        mov     edx, 41                                      
                                                                                        |        mov     esi, 1                                       
.Lanon.2fc01ec765ec0cb3dcc559126de20b30.1:                                              |        mov     edi, OFFSET FLAT:.LC0                        
        .quad   .Lanon.2fc01ec765ec0cb3dcc559126de20b30.0                               |        call    "fwrite"                                     
        .asciz  "\017\000\000\000\000\000\000\000\013\000..                             |        call    "abort"                                      
                                                                                        |.L4:                                                         
// As of Rust 1.75, small funs are automatically marked as #[inline] so they will showup|        mov     eax, DWORD PTR [rbp-4]                       
// in the output when compiling with optimisations. use #[unsafe(no_mangle)] to work    |        leave                                                
// around this issue                                                                    |        ret                                                  
                                                                                        |// This is equivalent fun in C that manually handles overflow and aborts.
       |
```
  ]

--- 
#cols[
  *Zero-Cost abstraction*
  - Holds for Iterators, closures or traits, comparable to writing equivalent code by hand in low-level style.
  *Iterators and closures: no overhead*
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
  #ref-badge[Compiler Explorer : godbolt.org; rustc -O2]
][
  *Generics : monomorphisation*

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
    Borrow checking, lifetime analysis, type inference : all stripped before LLVM sees the code. *The runtime binary is as lean as hand-written C.*
  ]
]

== The aliasing advantage: Why Rust often optimizes better than C

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

  Rust's exclusivity rule (`&mut T` is exclusive : no other reference exists) *proves* at compile time that `out` and `in_buf` do not overlap. LLVM gets this information and auto-vectorises without any annotation.

  #codebox(
    [
  ```rust
  // Rust: exclusive borrow PROVES no overlap
  // Compiler auto-vectorises : no annotation needed
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
    - The *same exclusive mutable property* that prevents data races also enables better codegen. 
    - Safety and performance arise from the same source: the aliasing guarantees proven by Rust's type system.
  ]
]
== Recap: 

- Features that make Rust language a systems programming language:
   - Minimum runtime and No Garbage collector.
   - Direct control over hardware and memory layout. 
   - Inlineable, Zero-Cost abstractions.
   - *`unsafe () `* for bare-metal freedom.
   - Seamless interoperability (FFI)
   - And more 

// ------------------------
// 3. Language features 
// ------------------------

// #focus-slide[
//     #align(center)[
//       #text(
//         fill: white,
//         size: 38pt,
//         weight: "bold",
//         style: "italic"
//       )[
//         #text(size: 0.8em, fill: black.lighten(45%))[· Ownership \ · Borrowing \ · Lifetimes \ · Thread Safety ] 
//       ]
//     ]
// ]
=  Important Language features:

#text(size: 0.8em, fill: black.lighten(45%))[· Ownership \ · Borrowing \ · Lifetimes \ · Thread Safety ] 

== Ownership : Memory Safety at Compile Time

#text(size: 1.2em, fill: black.lighten(25%))[The three ownership rules]

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

== Ownership vs C: use-after-free: ( #1 Kernel CVE Class )

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
  - *Zero `goto` cleanup; chains.* The compiler guarantees cleanup runs on every path. 
  - Linux has thousands of `goto err_free_XYZ` labels that this eliminates.
]

//  ------------------------
//  4. BORROWING & LIFETIMES
//  ------------------------
= Borrowing & Lifetimes ( Preventing Data Races )

== Borrowing : the aliasing rules , eliminating Data Races

#callout[
  *Borrowing* is Rust's system for temporary access without transferring ownership. \ This is implemented via References, which are distinct in Rust compiler view. 
  //  It formalises the aliasing rules that C developers know informally but often violate.
]

#v(0.6em)

#cols[
  *Shared (immutable) borrows : `&T`*

  - Multiple readers can coexist
  - None can write while readers exist
  //- Maps to: read-lock held, RCU read section

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

// -------------------------------
// Todo: move the below macro to ./vivarta.typ 
// Side-by-side C / Rust comparison pair  (equal width, same height)
#let vs(c-body, r-body) = grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  codeblock(c-body, title: "C"),
  codeblock(r-body, title: "Rust")
)
// -------------------------------

// == Data races — eliminated by the type system
//
// #cols[
//   *The formal argument*
//
//   A data race requires two conditions simultaneously:
//   1. *Aliasing* — two pointers to the same memory location
//   2. *Unsynchronised mutation* — at least one is writing
//
//   Ownership rules make both conditions simultaneously impossible in safe code:
//   - `&mut T` is exclusive → no aliasing while mutating
//   - `&T` is immutable → no mutation while aliased
//
//   *Therefore: if the program compiles, it has no data races.*
//
//   This was *formally machine-checked* in Coq by RustBelt (POPL 2018), and extended to C11 relaxed-memory atomics by RustBelt Meets Relaxed Memory (POPL 2020).
//   #ref-badge[Jung et al., POPL 2018; Dang et al., POPL 2020]
// ][
//   #vs(
//   ```c
//   /* Data race — compiles, UB at runtime */
//   uint64_t shared_counter;
//
//   void *thread_a(void *_) {
//       shared_counter++;   /* write */
//       return NULL;
//   }
//   void *thread_b(void *_) {
//       shared_counter++;   /* concurrent write */
//       return NULL;        /* undefined behaviour */
//   }
//   /* gcc: no warning. ThreadSanitizer: catches it
//      only if both threads execute concurrently. */
//   ```,
//   ```rust
//   // Data race — compile error:
//   let mut counter: u64 = 0;
//
//   let t1 = thread::spawn(|| {
//       counter += 1; // error[E0373]: closure may
//   });               // outlive current function,
//   let t2 = thread::spawn(|| { // but it borrows
//       counter += 1; // `counter`, which is owned
//   });               // by the current function
//   // Caught BEFORE the binary exists.
//   // Fix: Arc<AtomicU64> or Arc<Mutex<u64>>
//   ```
//   )
// ]

//  ----------------------------------
//  5. THE TYPE SYSTEM AS A SECURITY TOOL
//  ----------------------------------
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
  *Why this matters *

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
  - `Option<&T>` has *identical machine representation* to a nullable pointer — one word, null = `None`, non-null = `Some`. 
  - Zero overhead. 
  - The safety is entirely in the type, not the runtime. #ref-badge[Rust Reference §3.1 — Niche optimisation]
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

// ---------------------------------------
//  6. OTHER KEY SECURITY-FOCUSED FEATURES
// ---------------------------------------
// = Other Key Security-Focused Features
//
// == Integer safety and panic discipline
//
// #cols[
//   *Integer overflow — UB in C, defined in Rust*
//
//   In C, signed integer overflow is undefined behaviour. The compiler can *legally delete* the overflow check on the assumption it never happens.
//
//   ```c
//   // C: signed overflow → UB → compiler may "optimise"
//   // away the bounds check entirely (documented in GCC docs)
//   size_t alloc_size = nents * sizeof(struct entry);
//   if (alloc_size < nents) return -EINVAL; // may be removed!
//   void *buf = kmalloc(alloc_size, GFP_KERNEL);
//   ```
//
//   ```rust
//   // Rust debug build: overflow → controlled panic (BUG())
//   // Rust release build: wrapping, checked, or saturating
//   // — explicitly chosen, never undefined:
//   let alloc_size = nents
//       .checked_mul(size_of::<Entry>())
//       .ok_or(ErrKind::Overflow)?;
//   // Returns Err if it overflows — never silent.
//   ```
// ][
//   *Panic = explicit abort, not UB*
//
//   In kernel Rust (`#![no_std]`, custom `#[panic_handler]`), a panic does not unwind — it calls `BUG()` or halts the CPU, exactly like a kernel `BUG_ON()`. There is no hidden exception mechanism.
//
//   ```rust
//   #[cfg(not(test))]
//   #[panic_handler]
//   fn panic(_info: &PanicInfo) -> ! {
//       // In kernel context: trigger BUG() / halt
//       loop {}   // or: call kernel's panic() function
//   }
//   ```
//
//   #callout[
//     Rust panics are *predictable*, *locatable* (they include source location in debug builds), and *never undefined behaviour*. A Rust panic is always intentional; a C signed overflow is always a potential silent time bomb.
//   ]
// ]
//
// == Immutability by default
//
// #cols[
//   *C's dangerous default: everything is mutable*
//
//   ```c
//   void configure_hw(struct hw_config *cfg) {
//       /* cfg->base_addr can be modified here
//          even if that was not the intent.
//          Only `const struct hw_config *` prevents it,
//          and const is frequently omitted. */
//       cfg->base_addr = 0; // oops — accidental mutation
//   }
//   ```
//
//   *Rust's safe default: everything is immutable*
//
//   ```rust
//   fn configure_hw(cfg: &HwConfig) {
//       // cfg.base_addr = 0; // ← error[E0596]:
//       //   cannot assign to `cfg.base_addr`,
//       //   which is behind a `&` reference
//   }
//   // Mutation requires explicit declaration:
//   fn reconfigure(cfg: &mut HwConfig) {
//       cfg.base_addr = NEW_BASE; // only allowed here
//   }
//   ```
// ][
//   *Why this matters for BSP code*
//
//   - Read-only device tree data, register maps, and firmware blobs are *structurally immutable* — the type prevents accidental writes
//   - A configuration struct passed to an ISR as `&HwConfig` *cannot* be modified by the ISR — the compiler proves it
//   - Global immutable data (calibration tables, fuse values) declared as `static` — Rust distinguishes `static T` (immutable, `Sync`-required) from `static mut T` (requires `unsafe` — surfaces immediately in audit)
//
//   #callout(color: safe-green)[
//     *The secure-by-default principle*: mutability must be explicitly requested. The conservative default prevents a class of accidental writes that are otherwise silent in C.
//   ]
// ]
//
// == The type system as documentation — encoded, not commented
//
// #cols[
//   *C: intent in comments, verifiable nowhere*
//
//   ```c
//   /*
//    * MUST be called with dma_lock held.
//    * dev pointer MUST remain valid for the
//    * duration of the DMA operation.
//    * Returns negative errno on failure.
//    */
//   int map_dma(struct device *dev,
//               struct sg_table *sgt,
//               int nents,
//               enum dma_data_direction dir);
//   ```
//
//   None of these constraints are checked by the compiler. The comment is the only enforcement mechanism.
// ][
//   *Rust: intent in the type, checked at every call site*
//
//   ```rust
//   // "MUST be called with dma_lock held"
//   // → take a MutexGuard parameter — unobtainable otherwise
//   fn map_dma<'lock>(
//       _guard:  &'lock MutexGuard<DmaState>, // proof of lock
//       dev:     &'lock Device,               // must outlive guard
//       sgt:     &mut SgTable,
//       dir:     DmaDirection,                // typed enum, not int
//   ) -> Result<SgMapping<'lock>, DmaError>  // typed error
//   // The comment is now the type signature.
//   // Violations are compile errors, not runtime bugs.
//   ```
//
//   #callout(color: safe-green)[
//     Every invariant encoded in a Rust type signature is *checked at every call site in every crate that uses it* — including crates that were written years later by engineers who never read the comment.
//   ]
// ]
//
//  -------------------
//  7. Compiler Checks:
//  -------------------
= Compiler Checks : Beyond Memory safety:

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
    - In C, all of the above require separate tools.
    - The tools are not mandatory and they do not perform 100% check. 
  ]
]

// ---------------------
// 9. Ecosystem 
// ---------------------
= The Rust Ecosystem

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
    [`cargo-generate`], [kickstart a new project using git repo as template],
    [`cargo-expand`], [Rust code: after all macros have been expanded.],
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
// == Important additional concepts:
//
// Additional topics that are for those who want to go down the rabbit hole: 
//
// - *Traits*: Rust's explicit code interfaces, defining shared behavior across different data types.
//
// - *Generics*: Compile-time templates that allow you to write algorithms that work with multiple data types
//   without code duplication, evaluated entirely at build time.
//
// - *Trait-bounds*: Compile-time constraints on generics, allowing you to tell the compiler: 
//   'This generic function only works on types that implement a specific hardware interface or trait.'
//
// - *Smart pointers*: Custom data structures that act like pointers but wrap raw memory with automatic 
//   lifecycle tracking, like managing a reference-counted memory region.
//
// - *iterators*: Highly optimized, composable pointer-traversal abstractions that let you loop through arrays 
//   or ring buffers safely without raw index pointer arithmetic.
//
// - *macros*: Code-generation tools that compile down at build time, allowing you to write highly expressive 
//   code without incurring any runtime or performance overhead.
//
// - *attributes*:  Declarative metadata attached to your code, used for things like conditional compilation for 
//   different processor targets or forcing explicit struct packing layout alignment.
//

// ----------
//  APPENDIX:
// ----------
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

// == Key references
//
// #set text(size: 0.72em)
//
// *Formal verification*
// - Jung, R., Jourdan, J-H., Krebbers, R., Dreyer, D. *"RustBelt: Securing the Foundations of the Rust Programming Language."* POPL 2018. #link("https://plv.mpi-sws.org/rustbelt/popl18/")
// - Dang, H-H., Jourdan, J-H., Kaiser, J-O., Dreyer, D. *"RustBelt Meets Relaxed Memory."* POPL 2020.
//
// *Industry data*
// - Microsoft MSRC. "A Proactive Approach to More Secure Code." Gavin Thomas, 2019.
// - Google Project Zero. "Memory Safety Issues in Chrome." 2020.
// - Android Security Blog. "Memory Safety in Android." 2021. #link("https://security.googleblog.com")
// - CISA. "The Case for Memory Safe Roadmaps." 2023. #link("https://www.cisa.gov/resources-tools/resources/case-memory-safe-roadmaps")
//
// *Language specification and learning*
// - The Rust Reference. #link("https://doc.rust-lang.org/reference/")
// - The Rust Programming Language (Klabnik & Nichols). #link("https://doc.rust-lang.org/book/")
// - Comprehensive Rust (Google). #link("https://google.github.io/comprehensive-rust/")
//
// *Performance*
// - Paczos, K. "The Speed of Rust vs C." #link("https://kornel.ski/rust-c-speed/") 2023.
// - Compiler Explorer. #link("https://godbolt.org")
//
// *Production deployments*
// - Cloudflare. "How We Built Pingora." 2022. #link("https://blog.cloudflare.com/how-we-built-pingora")
// - Agache et al. "Firecracker." NSDI 2020.


= eBPF: Quick Refresher: (Part #2)

== What is eBPF: 
#cols[
  *The model in one sentence*

  eBPF lets you load user-supplied programs into the kernel *without a kernel patch, without a module, and without rebooting*, the kernel verifier guarantees safety, the programs are attached to *hook points* allowing them to execute efficiently when those events occur.

  *The four-step contract*

  1. *Write* — BPF bytecode (from C or Rust source)
  2. *Verify* — kernel verifier: bounded loops, no OOB, type-checked
  3. *JIT* — native machine code; zero interpreter overhead after load
  4. *Attach* — hook point (kprobe, tracepoint, XDP, LSM, …) fires on event

  #callout[
    If the verifier accepts the program, it *cannot* crash the kernel, infinite-loop, or access out-of-bounds memory. This is a formal proof, not a heuristic.
  ]
][
  #image("./imgs/eBPF-fw.png",height:45%)
 
  *Hook types your team uses*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(220)),
    inset: (y: 5pt),
    [`kprobe` / `kretprobe`], [any kernel function entry/return],
    [`tracepoint`], [stable kernel trace points],
    [`tp_btf`], [typed tracepoints — CO-RE friendly],
    [`perf_event`], [hardware PMU counters],
    [`xdp`], [NIC fast path — pre network stack],
    [`lsm`], [Linux Security Module hooks],
    [`cgroup_skb`], [per-cgroup packet filtering],
    [`raw_tp`], [raw tracepoints — lowest overhead],
  )
]

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
  *Ring buffer — the preferred choice*

  #ref-badge[Introduced: Linux 5.8 — BPF_MAP_TYPE_RINGBUF]

  - Variable-length records — no fixed-size overhead
  - Single contiguous allocation — cache-friendly
  - `epoll` / `AsyncFd` compatible — Tokio-native in Aya
  - Dropped-event counter exposed to userspace for monitoring
  - *In Aya*: `#[map] static EVENTS: RingBuf = RingBuf::with_byte_size(4 * 1024 * 1024, 0);`

  #callout[
    Prefer `RINGBUF` over `PERF_EVENT_ARRAY` for all new work — lower overhead, simpler consumer, no per-CPU complexity.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. eBPF FRAMEWORK LANDSCAPE
// ─────────────────────────────────────────────────────────────────────────────
= eBPF Framework Landscape

== Three generations of eBPF development

#cols[
  *Generation 1 — BCC (BPF Compiler Collection)*
  #ref-badge("BCC") #ref-badge("Python front-end") #ref-badge("bpftrace")

  - BCC embeds a full *Clang/LLVM at runtime* on the target — compiles BPF C to bytecode when the script runs
  - `bpftrace`: DTrace-style one-liners — ideal for ad-hoc investigation:

    `bpftrace -e 'kprobe:dma_map_sg { @[comm] = count(); }'`
  - *Problems for production / embedded targets*:
    - LLVM + kernel headers required on every target system
    - A 100 MB toolchain runtime on a BSP is untenable
    - Programs depend on exact kernel header versions — not portable

  #callout(color: warn-amber)[
    BCC/bpftrace are *development tools*, not deployment solutions. They require the full build toolchain on the production target.
  ]
][
  *Generation 2 — libbpf + CO-RE*
  #ref-badge("libbpf") #ref-badge("CO-RE") #ref-badge("BTF")

  - Compile *once*, run on *any kernel* that has BTF (`CONFIG_DEBUG_INFO_BTF=y`)
  - BPF program compiled ahead-of-time with Clang; `BTF` type info embedded in the ELF
  - libbpf patches field offsets at load time using the *running kernel's BTF* — no recompilation needed
  - Ships as a small `.so` + the pre-compiled BPF object

  *Generation 3 — Language-native frameworks*
  #ref-badge("Aya (Rust)") #ref-badge("cilium/ebpf (Go)") #ref-badge("libbpf-rs (Rust)")

  - First-class language integration: type safety, package managers, native async, single binary
  - Aya: *pure Rust*, no libbpf dependency, no C toolchain at runtime
  - cilium/ebpf: *pure Go*, BPF kernel code still compiled with Clang + bpf2go
  - libbpf-rs: Rust *bindings to libbpf* (not a reimplementation)
]

== What popular projects use — and why it matters for your team

#cols[
  *Cilium — the reference for production eBPF at scale*
  #ref-badge[CNCF Graduated 2023; #1 CNI by CNCF Survey 2025 (47% YoY growth)]

  - Cilium's *data plane* is written in C, compiled with Clang, loaded via their own loader (built on `cilium/ebpf` Go library)
  - `cilium/ebpf` (pure Go) handles loading, map management, and CO-RE relocations — *no libbpf.so needed*
  - Tetragon (Cilium's runtime security tool): same stack — eBPF C + Go loader
  - eBPF Summit 2025 Hackathon: a proof-of-concept combining Aya (BPF kernel code in Rust) with Cilium's Go loader was a winning entry — showing the two worlds can interoperate

  *Key take-away for your team:* the industry trend is toward *language-native loaders that avoid libbpf.so* at runtime. Cilium chose Go; Aya is the Rust equivalent.
][
  *Other production users that inform the choice*

  #table(
    columns: (auto, auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Project*], [*Stack*], [*Why relevant*],
    [Red Hat bpfman], [Rust + Aya], [eBPF program lifecycle manager — systemd-style for BPF],
    [Deepfence ebpfguard], [Rust + Aya], [LSM security policy in Rust — no C required],
    [K8s Blixt], [Rust + Aya], [XDP load balancer — data plane in Rust],
    [Tracee], [Go + libbpf], [runtime security; BPF C + Go loader],
    [Falco], [C + libbpf], [syscall monitoring; traditional stack],
  )

  #callout(color: ebpf-teal)[
    The three projects using Aya in production — bpfman, ebpfguard, Blixt — all share the same motivation: *type safety across the kernel/userspace boundary* and *single-binary deployment without runtime C library dependencies*.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. libbpf + CO-RE WORKFLOW
// ─────────────────────────────────────────────────────────────────────────────
= libbpf + CO-RE — The Reference Workflow

== Why CO-RE matters for BSP teams

#cols[
  *The kernel fragmentation problem*

  Your BSP ships to multiple OEMs, each running different kernel versions — 5.15 LTS, 6.1 LTS, 6.6 LTS, plus OEM patches. Internal struct layouts differ between versions:

  ```
  Kernel 5.15:  struct task_struct { …pid at offset 0x2C8… }
  Kernel 6.1:   struct task_struct { …pid at offset 0x2D4… }
  Kernel 6.6:   struct task_struct { …pid at offset 0x2E0… }
  ```

  A BPF program that reads `task->pid` at a hardcoded offset *silently reads wrong memory* on a different kernel version.

  *Before CO-RE:* ship a separate BPF object per kernel version, or embed Clang on the target (BCC approach).
][
  *CO-RE: Compile Once, Run Everywhere*

  ```
  BPF source (.bpf.c / .rs)
       │  clang / rustc emits CO-RE relocation records
       │  alongside the bytecode in the ELF
       ▼
  BPF ELF object  (with .BTF section)
       │
       │  At load time on the target:
       │  libbpf / Aya reads /sys/kernel/btf/vmlinux
       │  (the running kernel's own type information)
       │  and patches offsets in the bytecode to match
       │  THIS kernel's struct layout
       ▼
  Correct program running on kernel 5.15, 6.1, 6.6 …
  ```

  *Requirement:* `CONFIG_DEBUG_INFO_BTF=y` in the target kernel. This is standard in all GKI kernels (Android 12+) and most recent distro kernels.

  #callout[
    *For Android BSP distribution*: one compiled binary runs on all OEM GKI variants. No per-OEM kernel header sets. No recompilation on the device. This is the decisive reason CO-RE was adopted.
  ]
]

== libbpf workflow — the five stages

#grid(
  columns: (1fr, 0.07fr, 1fr, 0.07fr, 1fr, 0.07fr, 1fr, 0.07fr, 1fr),
  gutter: 0pt,
  pipe-box(1, "1. Write", "program.bpf.c\n+ vmlinux.h\nSEC() macros\nbpf_helpers.h", color: ebpf-teal),
  align(center+horizon, text(size:1.1em, fill:ebpf-teal, "→")),
  pipe-box(2, "2. Compile", "clang -target bpf\n-g -O2\n→ program.bpf.o\n(ELF + BTF)", color: ebpf-teal),
  align(center+horizon, text(size:1.1em, fill:ebpf-teal, "→")),
  pipe-box(3, "3. Skeleton", "bpftool gen skeleton\n→ program.skel.h\nTyped C structs\nfor loader", color: ebpf-teal),
  align(center+horizon, text(size:1.1em, fill:ebpf-teal, "→")),
  pipe-box(4, "4. Load+Verify", "skel__open()\nskel__load()\nCO-RE patches\nKernel verifier", color: safe-green),
  align(center+horizon, text(size:1.1em, fill:safe-green, "→")),
  pipe-box(5, "5. Attach+Run", "skel__attach()\nbpf_link fd\nFires on events\nRead maps", color: safe-green),
)


#cols[
  *Dependencies required on the build host*

  ```bash
  # Generate vmlinux.h — all kernel types from BTF
  bpftool btf dump file \
      /sys/kernel/btf/vmlinux format c > vmlinux.h

  # Compile BPF program
  clang -target bpf -g -O2 \
      -D__TARGET_ARCH_x86 -I. \
      -c program.bpf.c -o program.bpf.o

  # Generate typed C skeleton header
  bpftool gen skeleton program.bpf.o \
      > program.skel.h

  # Compile userspace loader
  gcc -o program program.c \
      -lbpf -lelf -lz
  ```
][
  *Dependencies required on the target*

  - `libbpf.so` (or statically linked `libbpf.a`)
  - `libelf.so` — required by libbpf
  - `libz.so` — required by libelf
  - The pre-compiled `program.bpf.o` file *or* embedded via skeleton

  *Teardown discipline (C)*

  ```c
  ring_buffer__free(rb);    // must not forget
  skel__detach(skel);       // must not forget
  skel__destroy(skel);      // must not forget
  // No compiler warning if any of these are missing
  ```

  #callout(color: warn-amber)[
    *The target-side library dependency chain* — libbpf → libelf → libz — is the friction point for embedded Linux, Android, and custom BSPs where controlling the runtime library set is important.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  4. DOES RUST FIT eBPF?
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

  The most expensive eBPF bug class in C: a map struct definition in the BPF program and the userspace loader that silently diverge.

  ```c
  // BPF program (C):
  struct event { u64 ts; u32 pid; };
  bpf_ringbuf_output(&rb, &e, sizeof(e), 0);

  // Userspace loader (C) — different file:
  struct event { u64 ts; u64 pid; }; // u64 ≠ u32 !
  // Reads wrong data — no compile error, no warning
  ```

  *Aya's solution*: one `#[no_std]` *common crate*, compiled for both targets. The struct is defined *once*. Layout disagreement is a *compile error*, not a runtime bug.

  #callout(color: rust-red)[
    This is the highest-value safety property of Rust for eBPF — not just memory safety in the BPF program, but *type-safe communication across the kernel/userspace boundary*.
  ]
]

== The bytecode generation question

#cols[
  *C eBPF toolchain*

  ```
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

  *What you need*: clang + LLVM (BPF backend) + bpftool + libelf + libbpf. C toolchain mandatory for the BPF program even if userspace is Rust (libbpf-rs).
][
  *Rust / Aya toolchain*

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

  *What you need*: rustc (nightly) + bpf-linker. *No clang, no bpftool, no libelf, no C toolchain.* The BPF ELF is embedded in the userspace binary — one artifact to deploy.

  #callout[
    Aya does not wrap libbpf — it is a *pure-Rust reimplementation* of the BPF syscall layer, built on `libc` only.
    #ref-badge[github.com/aya-rs/aya — "built from the ground up purely in Rust"]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. RUST APPROACHES: libbpf-rs vs Aya
// ─────────────────────────────────────────────────────────────────────────────
= Rust Approaches — libbpf-rs and Aya

== Two distinct strategies

#v(0.4em)

#grid(
  columns: (1fr, 0.08fr, 1fr),
  gutter: 0pt,

  // libbpf-rs column
  block(
    fill:  ref-blue.lighten(92%),
    stroke: 0.5pt + ref-blue.lighten(40%),
    radius: 6pt, inset: 14pt, width: 100%,
    stack(dir: ttb, spacing: 8pt,
      text(weight: "bold", size: 0.85em, fill: ref-blue, "libbpf-rs"),
      text(size: 0.68em, fill: luma(20%), style: "italic", "Rust bindings over libbpf"),
      line(length: 100%, stroke: 0.4pt + ref-blue.lighten(50%)),
      text(size: 0.70em)[
        - BPF *kernel side*: still written in *C*, compiled with Clang
        - Userspace loader: *Rust* wrapping libbpf via `libbpf-sys`
        - `bpf2rs` generates Rust skeletons from the BPF ELF
        - `libbpf.so` + `libelf.so` *still required on the target*
        - Familiar to existing libbpf-C teams; lower migration cost
        - C toolchain still mandatory in the build pipeline
      ],
      block(fill: ref-blue.lighten(84%), radius: 4pt, inset: (x:8pt,y:5pt),
        text(size: 0.65em, fill: ref-blue.darken(20%))[
          *Good for*: teams migrating from C libbpf who want Rust userspace only
        ]),
    ),
  ),

  align(center+horizon,
    stack(dir: ttb, spacing: 4pt,
      text(size: 1.2em, fill: luma(150), "vs"),
    )
  ),

  // Aya column
  block(
    fill:  rust-red.lighten(92%),
    stroke: 0.5pt + rust-red.lighten(40%),
    radius: 6pt, inset: 14pt, width: 100%,
    stack(dir: ttb, spacing: 8pt,
      text(weight: "bold", size: 0.85em, fill: rust-red, "Aya"),
      text(size: 0.68em, fill: luma(20%), style: "italic", "Pure-Rust reimplementation"),
      line(length: 100%, stroke: 0.4pt + rust-red.lighten(50%)),
      text(size: 0.70em)[
        - BPF *kernel side*: written in *Rust*, compiled with `rustc + bpf-linker`
        - Userspace loader: *Rust*, built on `libc` crate only — *no libbpf, no libelf, no C*
        - Shared struct crate: one definition, type-safe across both sides
        - Target binary: *single statically-linked executable* with musl
        - CO-RE via `aya-obj` — pure-Rust BTF parser and relocation engine
        - Async-native: `AsyncFd<RingBuf>` works directly with Tokio
      ],
      block(fill: rust-red.lighten(84%), radius: 4pt, inset: (x:8pt,y:5pt),
        text(size: 0.65em, fill: rust-red.darken(20%))[
          *Good for*: new projects, embedded/Android targets, teams comfortable with Rust
        ]),
    ),
  ),
)

#v(0.6em)
#callout(color: ebpf-teal)[
  *This session focuses on Aya* — pure-Rust, no C toolchain at runtime, single-binary deployment, first-class embedded and Android support.
  #ref-badge[github.com/aya-rs/aya — "built from the ground up purely in Rust, using only the libc crate"]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. AYA FRAMEWORK OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
= Aya Framework Overview

== Architecture and component map

#cols(ratio: (1.05fr, 0.95fr))[
  *Crate family and responsibilities*

  ```
  ┌──────────────────────────────────────────────┐
  │  Your userspace binary  (std, async)         │
  │  Ebpf::load() · map access · link handles    │
  ├──────────────────────────────────────────────┤
  │  aya          ← core userspace library       │
  │  Pure Rust bpf() syscall wrapper             │
  │  Program types: KProbe KRetProbe Xdp Lsm …   │
  │  Map types: HashMap RingBuf Array PerfMap …  │
  ├──────────────────────────────────────────────┤
  │  aya-obj      ← ELF + BTF + CO-RE engine     │
  │  Pure Rust ELF parser                        │
  │  Reads /sys/kernel/btf/vmlinux               │
  │  Patches relocations — no libelf dependency  │
  ├──────────────────────────────────────────────┤
  │  aya-log      ← userspace log receiver       │
  │  Reads aya-log-ebpf ring buffer              │
  └──────────────────────────────────────────────┘
  ┌──────────────────────────────────────────────┐
  │  Your BPF program  (no_std, no_main)         │
  │  #[kprobe] #[xdp] #[lsm] · map access        │
  ├──────────────────────────────────────────────┤
  │  aya-ebpf     ← BPF-side runtime crate       │
  │  Program macros: #[kprobe] #[map] #[xdp] …   │
  │  Helper wrappers: bpf_ktime_get_ns() …       │
  │  Map structs: HashMap RingBuf PerfMap …      │
  ├──────────────────────────────────────────────┤
  ```
][
  ```
  │  aya-log-ebpf ← BPF-side logging             │
  │  info!() warn!() → log ring buffer           │
  ├──────────────────────────────────────────────┤
  │  aya-ebpf-bindings ← kernel uapi types       │
  │  Generated from kernel headers by bindgen    │
  └──────────────────────────────────────────────┘
  ```
  *What each component replaces (vs libbpf stack)*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Aya crate*], [*Replaces in libbpf world*],
    [`aya`], [`libbpf.so` + `libbpf-sys` + skeleton loader],
    [`aya-obj`], [`libelf.so` + `libz.so` + libbpf ELF parser],
    [`aya-ebpf`], [`bpf_helpers.h` + `bpf/bpf_tracing.h`],
    [`aya-log`], [custom ring buffer log consumer],
    [`aya-log-ebpf`], [`bpf_printk()` (but ring-buffer based)],
    [`aya-tool`], [`bpftool btf dump … format c > vmlinux.h`],
    [`aya-build`], [`bpftool gen skeleton` + Makefile integration],
    [`common crate`], [manually-matched C header in both files],
  )

  #callout(color: ebpf-teal)[
    *Zero C runtime dependencies on the target.* The entire stack is Rust + one `bpf()` syscall. `aya-obj` implements its own ELF and BTF parser — no `libelf.so` needed.
  ]
]

== Aya for embedded and Android — the musl advantage

#cols[
  *The deployment problem on embedded / Android targets*

  A libbpf-based tool ships as:
  ```
  /usr/bin/my-tracer         ← ELF dynamically linked to:
  /usr/lib/libbpf.so.1       ← must exist on target
  /usr/lib/libelf.so.1       ← must exist on target
  /usr/lib/libz.so.1         ← must exist on target
  ```

  On Android or a minimal embedded rootfs:
  - `libelf` is often absent — it's a development library
  - `libbpf` version may not match what you compiled against
  - Android's linker namespace rules may prevent loading unrecognised shared libraries
  - A `system_ext` partition APK distributing a native `.so` chain is a maintenance burden

  *For cross-compiled BSP targets* (ARM64, RISC-V):
  - The host must have cross-compiled versions of all three `.so` files
  - Sysroot management becomes a per-target-per-kernel exercise
][
  *Aya + musl: one self-contained binary*

  ```bash
  # Add musl target (one-time)
  rustup target add aarch64-unknown-linux-musl

  # Cross-compile with musl — static binary
  # (cross wraps cargo with the right cross-compiler)
  cargo install cross
  cross build --release \
      --target aarch64-unknown-linux-musl

  # Result: a single fully static binary
  file target/aarch64-unknown-linux-musl/\
           release/my-tracer
  # my-tracer: ELF 64-bit LSB executable, ARM aarch64,
  #            statically linked, stripped

  # Copy to target — zero other files needed
  adb push my-tracer /data/local/tmp/
  adb shell chmod +x /data/local/tmp/my-tracer
  adb shell /data/local/tmp/my-tracer
  ```

  #callout(color: ebpf-teal)[
    *True compile once, run everywhere*: a musl-linked Aya binary + BTF CO-RE runs on any ARM64/x86 Linux kernel with BTF support — distribution, Android OEM kernel, or custom BSP — without any library installation. #ref-badge[aya-rs.dev — "a single self-contained binary can be deployed on many Linux distributions"]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. BUILDING WITH AYA-TEMPLATE
// ─────────────────────────────────────────────────────────────────────────────
= Building with Aya Template

== Prerequisites and scaffold

#cols[
  *One-time setup*

  ```bash
  # 1. Rust nightly — required for bpfel-unknown-none target
  rustup toolchain install nightly \
      --component rust-src

  # 2. bpf-linker — LLVM BPF backend for rustc
  #    (bundles the right LLVM version)
  cargo install bpf-linker

  # 3. Scaffold tool
  cargo install cargo-generate

  # 4. Verify BPF target is available
  rustc +nightly --print target-list \
      | grep bpfel
  # bpfel-unknown-none  ← must appear

  # 5. Optional: aya-tool for kernel type bindings
  cargo install aya-tool
  ```
][

  *Scaffold the project*

  ```bash
  cargo generate \
      --git https://github.com/aya-rs/aya-template \
      --name hello-xdp

  cd hello-xdp

  # Build everything in one command
  # aya-build drives eBPF cross-compilation automatically
  cargo build --release

  # Result:
  # target/release/hello-xdp  ← userspace binary
  #   └── embeds the compiled BPF ELF via aya-build
  ```
  #callout[
    *No xtask, no separate build step.* The `build.rs` in the userspace crate invokes a child `cargo +nightly build --target bpfel-unknown-none -Z build-std=core` automatically. `cargo build` is the only command.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  8. PROJECT LAYOUT AND RUST FEATURES
// ─────────────────────────────────────────────────────────────────────────────
= Project Layout and Rust Features That Simplify eBPF

== Three-crate workspace structure

#cols(ratio: (1fr, 1fr))[
  *Directory layout — aya-template generated*

  ```
  hello-xdp/
  ├── Cargo.toml            ← workspace root
  ├── rust-toolchain.toml   ← pins nightly for eBPF crate
  │
  ├── hello-xdp-common/
  │   └── src/lib.rs
  │     #![no_std]
  │     (optional: shared event structs)
  │
  ├── aya-ebpf/
  │   ├── .cargo/config.toml  ← target = bpfel-unknown-none
  │   ├── Cargo.toml
  │   └── src/main.rs         ← #[xdp] program
  │
  └── hello-xdp/
      ├── Cargo.toml
      └── src/main.rs         ← Ebpf::load, attach, event consumer
  ```

  Each crate has a clear purpose: common types, BPF kernel code, userspace loader.
][
  *Key files in the BPF crate*

  ```toml
  # aya-ebpf/.cargo/config.toml
  [build]
  target = "bpfel-unknown-none"
  rustflags = [
      "-C", "debuginfo=2",     # embed BTF
      "-C", "link-arg=--btf",  # CO-RE
  ]

  [unstable]
  build-std = ["core"]  # cross-compile core
  ```

  *aya-build integration in userspace Cargo.toml*

  ```toml
  [build-dependencies]
  aya-build = { version = "0.1", features = ["ebpf"] }
  ```

  The `build.rs` automatically generated by the template handles the cross-compilation — `cargo build` does everything.
]

== Rust features that make eBPF programming safer and cleaner

#v(0.3em)

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,

  // Feature 1
  block(fill: rust-red.lighten(92%), stroke: 0.5pt + rust-red.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: rust-red,
        "1. Shared common crate — type-safe boundary"),
      text(size: 0.67em)[
        `DmaEvent` defined once in `common/src/lib.rs` with `#[repr(C)]`. Compiled for `bpfel-unknown-none` (no_std) and host (std). Struct layout mismatch is a *compile error*, not a silent wrong result. The same `comm: [u8; 16]` field is correctly sized and aligned on both sides — always.
      ],
    )
  ),

  // Feature 2
  block(fill: rust-red.lighten(92%), stroke: 0.5pt + rust-red.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: rust-red,
        "2. RAII attachment handles — guaranteed teardown"),
      text(size: 0.67em)[
        `prog.attach(…)?` returns a typed handle implementing `Drop`. When the handle goes out of scope — on any exit path, including `?` propagation or panic — the BPF link fd is closed and the program detached. No `skel__detach()` to forget. No leaked attachment if the consumer loop exits early.
      ],
    )
  ),

  // Feature 3
  block(fill: ebpf-teal.lighten(92%), stroke: 0.5pt + ebpf-teal.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: ebpf-teal,
        "3. Result<T,E> + ? — no silent load failures"),
      text(size: 0.67em)[
        Every Aya call returns `Result<T, Error>`. `Ebpf::load(bytes)?` will not silently continue if the BPF ELF is malformed or the kernel rejects the program. The `?` operator propagates the error immediately with source location. In C: `skel__load(skel)` returns `int` — easy to ignore.
      ],
    )
  ),

  // Feature 4
  block(fill: ebpf-teal.lighten(92%), stroke: 0.5pt + ebpf-teal.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: ebpf-teal,
        "4. Async ring buffer — epoll without callbacks"),
      text(size: 0.67em)[
        `AsyncFd<RingBuf>` integrates with Tokio's event loop natively. The consumer `loop { select! { guard = async_fd.readable() => { … } } }` is structured flow — not a C callback (`ring_buffer__poll` + `handle_event` function pointer). State between events is naturally owned by the async task. No global callback context pointer needed.
      ],
    )
  ),

  // Feature 5
  block(fill: safe-green.lighten(92%), stroke: 0.5pt + safe-green.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: safe-green,
        "5. Typed program kinds — no runtime mismatches"),
      text(size: 0.67em)[
        `bpf.program_mut("name")?.try_into::<KProbe>()` — the downcast is explicit and returns `Err` if the program type does not match. Calling `attach()` on a `KProbe` handle only accepts kprobe-valid arguments. In C: `bpf_program__attach()` is untyped; wrong hook arguments silently fail or attach to the wrong point.
      ],
    )
  ),

  // Feature 6
  block(fill: safe-green.lighten(92%), stroke: 0.5pt + safe-green.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: safe-green,
        "6. aya-log — structured logging from BPF programs"),
      text(size: 0.67em)[
        `info!(&ctx, "dma_map_sg: pid={} nents={}", pid, nents)` inside the BPF program writes to a dedicated ring buffer. The userspace `EbpfLogger::init(&mut bpf)` subscribes and routes to `env_logger` / `log` — the same logging infrastructure as the rest of the Rust application. No `bpf_printk()` parsing. No separate trace_pipe reader.
      ],
    )
  ),
)

== BPF program side — key patterns

#cols[

  #text(size: 0.65em, weight: "bold", fill: rust-red, "C / libbpf — BPF program ")
  #codebox(
```c

SEC("kprobe/dma_map_sg")
int BPF_KPROBE(dma_map_sg_enter,
               struct device *dev,
               struct scatterlist *sg,
               int nents,
               enum dma_data_direction dir)
{
    u64 pid_tgid = bpf_get_current_pid_tgid();
    u32 pid = pid_tgid & 0xFFFFFFFF;
    u64 ts  = bpf_ktime_get_ns();
    bpf_map_update_elem(&start_map,
        &pid, &ts, BPF_ANY);
    return 0;
}
// Map declared separately with struct + __uint macros
// Struct shared with userspace via MANUALLY matched header
```, ) 
][
  #text(size: 0.65em, weight: "bold", fill: rust-red, "Rust / Aya — BPF program")
  #codebox(
```rust
// Rust / Aya — BPF program
#[kprobe]
pub fn dma_map_sg_enter(ctx: ProbeContext) -> u32 {
    let pid = (bpf_get_current_pid_tgid()
               & 0xFFFF_FFFF) as u32;
    let ts  = unsafe { bpf_ktime_get_ns() };
    // Map declared at crate level with #[map]
    let _  = START_MAP.insert(&(pid as u64), &ts, 0);
    0
}
// Struct imported from common crate — ONE definition
// Layout verified by the compiler across both sides
```
)]

== Userspace side — load, attach, consume

#cols[
  #text(size: 0.65em, weight: "bold", fill: rust-red, "C / libbpf — userspace loader")
#codebox(
```c
struct prog_bpf *skel = prog__open();

// CO-RE, maps created, verifier called:
prog__load(skel);

// Hook attached, bpf_link fd returned:
prog__attach(skel);

// Ring buffer callback model:
struct ring_buffer *rb = ring_buffer__new(
    bpf_map__fd(skel->maps.events),
    handle_event, NULL, NULL);

while (running)
    ring_buffer__poll(rb, 100);

// MUST manually clean up:
ring_buffer__free(rb);
prog__detach(skel);
prog__destroy(skel);
```) 
][
#text(size: 0.65em, weight: "bold", fill: rust-red, "Rust / Aya — userspace loader")
#codebox(
```rust
// 
let mut bpf = Ebpf::load(BPF_BYTES)?;

// Typed downcast — compile error if wrong kind:
let prog: &mut KProbe = bpf
    .program_mut("dma_map_sg_enter")?
    .try_into()?;
prog.load()?;
let _link = prog.attach("dma_map_sg", 0)?;
// _link implements Drop — detach is automatic

// Async ring buffer — no callback, no context ptr:
let rb  = RingBuf::try_from(bpf.take_map("EVENTS")?)?;
let afd = AsyncFd::new(rb)?;
loop {
    let mut g = afd.readable().await?;
    while let Some(item) = g.get_inner_mut().next() {
        let e = unsafe { *(item.as_ptr() as *const DmaEvent) };
        // e.latency_ns, e.pid, e.comm — all typed
    }
    g.clear_ready();
}
// bpf, _link, afd all Drop here — zero cleanup code
```
)
]

// // ─────────────────────────────────────────────────────────────────────────────
// //  9. DEMO — DMA LATENCY TRACER
// // ─────────────────────────────────────────────────────────────────────────────
// = Demo — DMA Latency Tracer
//
// == Test setup — ConnectX-5 crossover DAC
//
// #cols[
//   *Physical topology*
//
//   ```
//   ┌──────────────────────────────────────────────┐
//   │  Host motherboard — PCIe Gen 3.0 x16 slot    │
//   │                                              │
//   │  ┌────────────────────────────────────────┐  │
//   │  │  Mellanox ConnectX-5 100GbE            │  │
//   │  │  (PCIe Gen 4 card — links at Gen 3)    │  │
//   │  │                                        │  │
//   │  │  Port 0 (enp6s0f0) ──╮  DAC crossover  │  │
//   │  │  Port 1 (enp6s0f1) ──╯  cable          │  │
//   │  └────────────────────────────────────────┘  │
//   └──────────────────────────────────────────────┘
//
//   ns0 (192.168.100.1) ←——DAC——→ ns1 (192.168.100.2)
//   Traffic traverses physical cable — no loopback path
//   ```
//
//   *Namespace setup — isolate the two ports*
//
//   ```bash
//   sudo ip netns add ns0 && sudo ip netns add ns1
//   sudo ip link set enp6s0f0 netns ns0
//   sudo ip link set enp6s0f1 netns ns1
//   sudo ip netns exec ns0 \
//       ip addr add 192.168.100.1/24 dev enp6s0f0
//   sudo ip netns exec ns1 \
//       ip addr add 192.168.100.2/24 dev enp6s0f1
//   ```
// ][
//   *What we instrument*
//
//   `dma_map_sg(struct device*, struct scatterlist*, int nents, enum dma_data_direction dir)`
//
//   The mlx5 driver calls this for every WQE (Work Queue Entry) posted to the HCA. Latency = IOMMU DMA mapping overhead — the performance-relevant part of each DMA transaction.
//
//   *Expected latency profile — ConnectX-5 on PCIe Gen 3 host*
//
//   #table(
//     columns: (auto, 1fr),
//     stroke: (x: none, y: 0.3pt + luma(210)),
//     inset: (y: 5pt),
//     [*Range*], [*Interpretation*],
//     [< 2 µs],  [IOMMU TLB warm — normal path ✓],
//     [2–10 µs], [TLB pressure / NUMA distance],
//     [10–50 µs],[IOMMU page-table walk — TLB miss],
//     [> 50 µs], [CPU C-states or frequency scaling],
//   )
//
//   PCIe Gen 3 vs Gen 4: the Gen 3 link halves *bandwidth* but does *not* increase individual DMA mapping latency. Latency is dominated by IOMMU and NUMA topology.
// ]
//
// == Build and run
//
// #codeblock(
//   ```bash
//   # ── Prerequisites (one-time) ─────────────────────────────────────────────
//   rustup toolchain install nightly --component rust-src
//   cargo install bpf-linker
//
//   # ── Build — single command ────────────────────────────────────────────────
//   # build.rs drives eBPF cross-compilation automatically
//   cargo build --release
//
//   # ── For ARM64 target (cross-compile + musl static binary) ─────────────────
//   cargo install cross
//   cross build --release --target aarch64-unknown-linux-musl
//   # Push single static binary to target — no library installation needed
//   adb push target/aarch64-unknown-linux-musl/release/dma-latency-tracer \
//       /data/local/tmp/
//
//   # ── Generate traffic through the DAC cable ───────────────────────────────
//   sudo ip netns exec ns0 iperf3 -s &
//   sudo ip netns exec ns1 iperf3 -c 192.168.100.1 -t 120 -P 8
//
//   # ── Run the tracer (requires CAP_BPF / root) ─────────────────────────────
//   sudo RUST_LOG=info ./target/release/dma-latency-tracer \
//       --interval 5 \
//       --min-latency-us 1 \
//       --filter-comm iperf3
//   ```,title: "Full build and run sequence")
//
// == Demo output — event stream
//
// #codeblock(title: "Individual DMA events above threshold")[
//   ```
//   [INFO]  dma-latency-tracer: attached kprobe + kretprobe on dma_map_sg
//   [INFO]  Setup: ConnectX-5 PCIe Gen4 @ Gen3 slot | DAC crossover | ns0 ↔ ns1
//   [INFO]  Reporting every 5s  |  filter: iperf3  |  min threshold: 1 µs
//
//   [INFO]  [cpu=03] pid=12345 comm=iperf3        nents= 16  dir=TO_DEVICE     lat=  1.842 µs
//   [INFO]  [cpu=07] pid=12345 comm=iperf3        nents= 32  dir=TO_DEVICE     lat=  2.201 µs
//   [INFO]  [cpu=01] pid=12345 comm=iperf3        nents= 16  dir=FROM_DEVICE   lat=  1.634 µs
//   [INFO]  [cpu=11] pid=12347 comm=kworker/11:1H nents=  4  dir=BIDIRECTIONAL lat=  8.443 µs
//   [INFO]  [cpu=03] pid=12345 comm=iperf3        nents= 64  dir=TO_DEVICE     lat= 31.771 µs ← TLB miss
//   [INFO]  (max_events reached — histogram continues)
//   ```
// ]
//
// == Demo output — latency histogram
// //title: "Per-interval histogram — 5 second window, 48 291 events")
// #codebox(
//   ```
//   ════════════════════════════════════════════════════════════════════════
//     dma_map_sg latency histogram  (window events: 48 291)
//     System: ConnectX-5 PCIe Gen4 | Gen3 host slot | DAC crossover cable
//   ────────────────────────────────────────────────────────────────────────
//                range      count       %    dist (normalised to peak)
//          0 – 500 ns       2 134    4.42%   |████░░░░░░░░░░░░░░░░░░░░░░░░|
//        500 ns – 1 µs      5 891   12.20%   |████████████░░░░░░░░░░░░░░░░|
//            1 – 2 µs      18 432   38.17%   |████████████████████████████|  ← peak
//            2 – 3 µs      14 201   29.41%   |███████████████████████░░░░░|
//            3 – 5 µs       5 912   12.24%   |████████████░░░░░░░░░░░░░░░░|
//          5 – 7.5 µs       1 102    2.28%   |██░░░░░░░░░░░░░░░░░░░░░░░░░░|
//         7.5 – 10 µs         401    0.83%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
//           10 – 15 µs        128    0.26%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
//           15 – 30 µs         82    0.17%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
//              > 30 µs          8    0.02%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
//   ────────────────────────────────────────────────────────────────────────
//     Fast ( < 2 µs):  26 457  (54.8%)  — IOMMU TLB warm ✓
//     Slow (> 30 µs):       8   (0.0%)  — check C-states / IOMMU pressure
//   ────────────────────────────────────────────────────────────────────────
//      pid  comm               count    avg µs    min µs    max µs
//    12345  iperf3             48 291     1.923     0.312    87.441
//    12347  kworker/11:1H          62     7.114     3.201    31.771
//   ════════════════════════════════════════════════════════════════════════
//   ```
// )
//
// == Reading the output
//
// #cols[
//   *What the histogram tells you*
//
//   - *Peak at 1–2 µs*: healthy — IOMMU TLB is warm, mlx5 scatter-gather lists (16–32 nents) served from cached page table entries
//   - *Tail at 3–10 µs*: mild TLB pressure as the ring cycles — expected under sustained 100 GbE load at line rate
//   - *Outliers > 30 µs*: IOMMU page-table walk (TLB miss) or CPU C-state wakeup. Correlate with `scaling_cur_freq`
//   - *`kworker` at `BIDIRECTIONAL`*: mlx5 firmware completion posting — normal for ConnectX-5
//
//   *PCIe Gen 3 vs Gen 4 note*
//
//   The Gen 3 link halves *bandwidth* to ~128 Gbps theoretical (from 256 Gbps Gen 4). Individual DMA mapping latency is *not* affected — dominated by IOMMU + NUMA, not PCIe link speed.
// ][
//   *Actionable follow-up from this data*
//
//   - High `> 10 µs` count during iperf3 → enable huge pages for IOMMU to reduce TLB misses:
//     `echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`
//   - Latency spikes correlated with `kworker` PIDs → firmware-level power management interfering with IOMMU
//   - Per-CPU histogram shows one CPU with consistently higher latency → mlx5 IRQ affinity misalignment from PCIe slot NUMA node
//   - High `nents` correlation with high latency → large scatter-gather lists exhausting IOMMU TLB; tune `net.core.optmem_max` or adjust NIC queue depth
//
//   #callout(color: ebpf-teal)[
//     *Zero kernel changes. Zero driver modifications.* This runs on a production kernel against production traffic. The Aya binary is 3.2 MB statically linked — deployable to any target with `scp` or `adb push`.
//   ]
// ]
//

// ─────────────────────────────────────────────────────────────────────────────
//  9. DEMO — HELLO XDP
// ─────────────────────────────────────────────────────────────────────────────
= Demo — Hello XDP

== Why XDP for a simple demo

#cols[
  *XDP (eXpress Data Path) — the simplest hook for live testing*

  XDP programs run on *every packet arrival* at the NIC driver level — before the kernel network stack processes the packet. This makes it ideal for demos:

  - *Easy to trigger*: just send a packet (ping, curl, etc.)
  - *Fast feedback*: no kernel driver involvement needed
  - *Safe to experiment with*: `XDP_PASS` means "let the packet through normally"
  - *Low overhead*: runs in the NIC driver's RX path

  Other hooks (kprobe, tracepoint) require specific kernel function calls that may or may not happen during normal system activity. XDP fires on *every* packet automatically.
][
  *Scaffold from aya-template*

  ```bash
  cargo generate \
    --git https://github.com/aya-rs/aya-template \
    --name hello-xdp

  # When prompted for program type, select: xdp

  cd hello-xdp
  cargo build --release
  ```

  The template generates three crates:
  - `aya-ebpf/` — BPF program with `#[xdp]` hook
  - `hello-xdp-common/` — shared event types (optional)
  - `hello-xdp/` — userspace loader + packet consumer

  Everything is ready to compile in one step.
]

== The generated BPF program

#codeblock(title: "aya-ebpf/src/main.rs — Hello XDP from template")[
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
      Ok(xdp_action::XDP_PASS)   // let packet through
  }

  #[panic_handler]
  fn panic(_info: &core::panic::PanicInfo) -> ! {
      unsafe { core::hint::unreachable_unchecked() }
  }
  ```
]

#callout[
  *One line of actual logic*: `info!(&ctx, "received a packet");` — the rest is Rust infrastructure. Every packet triggers a log entry visible in userspace. The `try_hello_xdp` pattern is idiomatic Rust for error handling.
]

== The generated userspace loader

#codeblock(title: "hello-xdp/src/main.rs — simplified")[
  ```rust
  use aya::Ebpf;
  use aya::programs::Xdp;
  use aya_log::EbpfLogger;
  use log::info;
  use std::os::unix::io::AsRawFd;

  #[tokio::main]
  async fn main() -> Result<(), Box<dyn std::error::Error>> {
      env_logger::builder()
          .filter_module("hello_xdp", log::LevelFilter::Info)
          .try_init()?;

      let mut ebpf = Ebpf::load(aya::include_bytes_aligned!(
          concat!(env!("OUT_DIR"), "/hello_xdp-ebpf")
      ))?;
      EbpfLogger::init(&mut ebpf)?;

      let prog: &mut Xdp = ebpf.program_mut("hello_xdp")?.try_into()?;
      prog.load()?;

      // Attach to the default network interface
      let iface = "eth0";  // or your interface name
      prog.attach(iface, aya::programs::XdpFlags::default())?;

      info!("XDP program attached to {}", iface);
      info!("Try: ping 8.8.8.8  (or any traffic on {})", iface);

      tokio::signal::ctrl_c().await?;
      info!("Detaching...");
      Ok(())
  }
  ```
]

== Build and test

#codeblock(title: "Full build sequence")[
  ```bash
  # Build (first time takes 30–60 seconds due to nightly Rust compilation)
  cargo build --release

  # Load and run — requires root or CAP_BPF
  sudo RUST_LOG=hello_xdp=info \
      ./target/release/hello-xdp

  # In another terminal: generate traffic
  ping 8.8.8.8
  # or: curl https://example.com
  # or: iperf3 to a remote host
  ```
]

#codeblock(title: "Sample output — from any outgoing packets")[
  ```
  [INFO]  XDP program attached to eth0
  [INFO]  Try: ping 8.8.8.8  (or any traffic on eth0)
  [2025-06-02T14:32:15.123Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.124Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.125Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.126Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.127Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.128Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.129Z INFO  hello_xdp] received a packet
  [2025-06-02T14:32:15.131Z INFO  hello_xdp] received a packet
  ^C
  [INFO]  Detaching...
  ```

  *Every log line is a packet processed by the kernel eBPF program.* No userspace polling. No callbacks. Pure XDP native speed.
]

#callout(color: ebpf-teal)[
  *That's it.* One simple program demonstrating the full Aya stack: BPF kernel code in Rust, userspace loader in Rust, shared types, logging, async integration. The same patterns scale to production tools like bpfman, ebpfguard, and Blixt.
]
// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *Aya is not a wrapper around libbpf.*

  *It is a reimplementation — in Rust, for Rust.*

  One language. One toolchain. One binary.\
  Type-safe across the kernel/userspace boundary.\
  Deploy anywhere Linux + BTF exist.
]

// ─────────────────────────────────────────────────────────────────────────────
//  APPENDIX
// ─────────────────────────────────────────────────────────────────────────────
= Appendix <touying:hidden>

== aya-tool — generating kernel type bindings

```bash
# Install aya-tool
cargo install aya-tool

# Generate Rust bindings for specific kernel structs
# from the running kernel's BTF — equivalent of
# bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
# but produces a Rust module:
aya-tool generate task_struct > \
    dma-latency-tracer-ebpf/src/vmlinux.rs

# Use in BPF program:
// mod vmlinux;
// use vmlinux::task_struct;
```

== CO-RE in Aya — the relocation chain

```
BPF program (Rust):
  uses: bpf_core_read!(task, pid)
  rustc + bpf-linker emit:
    → BTF_CO-RE relocations in the BPF ELF
    → .BTF section with type information

At Ebpf::load() time (Aya):
  1. aya-obj parses the BPF ELF
  2. Reads /sys/kernel/btf/vmlinux
  3. For each CO-RE relocation record:
     looks up the field offset in the RUNNING kernel's BTF
     (may differ from the compile-time layout)
  4. Patches BPF bytecode with the correct offset
  5. Submits patched bytecode via bpf() syscall → verifier → JIT

Result: one binary. Runs on kernel 5.15, 6.1, 6.6, 6.12 —
        any kernel where CONFIG_DEBUG_INFO_BTF=y
```

== References

#set text(size: 0.72em)

*Aya framework*
- Aya book: #link("https://aya-rs.dev/book/")[aya-rs.dev/book]
- API docs: #link("https://docs.rs/aya")[docs.rs/aya]
- awesome-aya: #link("https://github.com/aya-rs/awesome-aya")[github.com/aya-rs/awesome-aya]
- FOSDEM 2025: "Building your eBPF Program with Rust and Aya" — #link("https://archive.fosdem.org/2025/schedule/event/fosdem-2025-5534-building-your-ebpf-program-with-rust-and-aya/")

*libbpf and CO-RE*
- libbpf overview: #link("https://docs.kernel.org/bpf/libbpf/libbpf_overview.html")[docs.kernel.org/bpf/libbpf]
- CO-RE reference: #link("https://nakryiko.com/posts/bpf-core-reference-guide/")[nakryiko.com]
- libbpf-bootstrap: #link("https://nakryiko.com/posts/libbpf-bootstrap/")[nakryiko.com]

*Framework landscape*
- cilium/ebpf (Go): #link("https://github.com/cilium/ebpf")[github.com/cilium/ebpf]
- libbpf-rs: #link("https://github.com/libbpf/libbpf-rs")[github.com/libbpf/libbpf-rs]
- Podobnik, T. "Go, C, Rust, and More: Picking the Right eBPF Application Stack." Medium, 2025.

*Production Aya deployments*
- Red Hat bpfman: #link("https://bpfman.io")[bpfman.io]
- Deepfence ebpfguard: #link("https://github.com/deepfence/ebpfguard")[github.com/deepfence/ebpfguard]
- Kubernetes Blixt: #link("https://github.com/kubernetes-sigs/blixt")[github.com/kubernetes-sigs/blixt]

*eBPF fundamentals*
- Gregg, B. *BPF Performance Tools.* Addison-Wesley, 2019.
- CNCF Annual Survey 2025 — Cilium adoption.
