# Introduction to Rust & eBPF programming with Rust


## Slide 1: Introduction:

- Rust is a general-purpose programming language. 

- Started in 2006 @ Mozilla by Graydon Hoare, ( Official sponsored the project) with its first stable
  release 1.0 in May 2015 was followed by Big tech adoption (Discord, Cloudflare, Dropbox..), As of 2021
  it went independent with Rust Foundation and now supported by Google, microsoft, AWS and Meta.

- Rust is on the top sport of the Stack Overflow Developer Survey since 2016 as the most loved and growing
  language.  The survey is not just a trend, but a indicator of how the language solves the most painful
  problems in SW. Some of the most notable of them are :
  * memory safety ( Ownership model, Borrowing, Lifetimes )
  * Fearless Concurrency. ( No data races and thread safe )
  * Tooling ( Cargo: package manager, builder and more )

### Memory Safety:

- Memory safety paradox: Performance vs Reliability:

  In systems programming we typically face a binary choice that Rust aims to break:
  - Manual Memory management (C/C++): Gives maximum performance and control, but places the burden of
    safety on the developer. A single logical error of adoption of code that contains local errors can lead
    to a kernel panic or critical security vulnerability ( Buffer Overflow ).

  - Managed Management ( Java/Python ): High safety via GC this leads to non-detrministic behaviour, pauses
    in runtime. 
  - Rust Alternative: No GC, no runtume overhead. Rust moves the validation logic from **runtime** to
    **compile-time** via the **Borrow Checker**.

- The Ownership Model: Deterministic Resource Management:

  Rust replaces manual `kfree()` or `delete` with a strict ownership system. This is essentially **RAII
  (Resource Acquisition Is Initialization)** enforced by the compiler.

  * **Single Ownership:** Every allocation has exactly one owner variable.
  * **Automatic Cleanup:** When the owner’s scope ends, the memory is dropped immediately.
  * **Zero-Cost:** There is no "searching" for dead memory; the compiler inserts the "free" instructions at
    the exact point they are needed.

> **Impact:** Eliminates **Memory Leaks** and **Double-Free** errors at the architectural level.

- Borrowing & References: ( The Aliasing XOR Mutability Rule )

  To handle data without moving ownership, Rust uses "Borrowing." This is governed by a strict rule designed
  to prevent memory corruption and data races.

- **The Rule:** You can have **Exclusive Access** OR **Shared Access**, but never both.

| Type | Syntax | Rule | Use Case |
| :--- | :--- | :--- | :--- |
| **Immutable Borrow** | `&T` | Unlimited concurrent readers. | Reading state/buffers. |
| **Mutable Borrow** | `&mut T` | Exactly **one** active writer; no other readers allowed. | Modifying drivers/registers. |



> **Impact:** prevents **Data Races** at compile time. If two threads try to access the same memory where
> one is writing, the code simply will not compile.

- The Borrow Checker: ( Static Analysis for Systems Integrity )

  The Borrow Checker is the compiler component that audits these rules. 
  * **Compile-Time Validation:** 
    - It ensures no reference ever outlives the data it points to.

  * **No More Dangling Pointers:** 
    - If a function attempts to return a pointer to a stack-allocated variable that is about to be dropped, 
      the Borrow Checker flags it as a compile error.

  * **Kernel-Grade Safety:** 
    - Security CVEs are caught before the code ever runs on target hardware.
  
Recap:
---
* **Performance:** Matches C/C++ (Zero-cost abstractions).

* **Safety:** Matches Java/Python (Memory safe by default).

* **Concurrency:** "Fearless concurrency" by enforcing thread-safety at the type-system level.

---

## Fearless Concurrency:

"Concurrency" usually translates to "Debugging Deadlocks and Race Conditions at 3 AM." But Rust converts
these runtime nightmares into compiler errors.

Traditional systems programming (C/C++), concurrency is "hope-based." 
- We hope we locked the `mutex`; 
- We hope we didn’t create a data race.

Rust changes this by making thread-safety a requirement for compilation.

In Kernel/Android development, shared resources are inevitable. 
Rust handles this using the same **Ownership** and **Borrowing** rules applied to memory:

- **The Data Race Prevention:** Data race occurs when two threads access the same memory, at least one is a
  write, and they aren't synchronized.

- **The Rust Solution:** Because the compiler enforces **Aliasing XOR Mutability**, it is physically
  impossible to have a mutable reference (`&mut T`) in one thread while another thread holds any reference
  to that same data.


- Send and Sync: The Concurrency Traits

Rust doesn't just guess if a structure is thread-safe; it uses two "marker traits" to categorize every type 
in the system:

    * **`Send`:** Can this data be moved to another thread?
        * *Example:* A unique pointer is `Send`. A raw pointer to thread-local storage is not.

    * **`Sync`:** Can this data be accessed by multiple threads simultaneously? (i.e. is `&T` safe to share?)
        * *Ex:* An `AtomicInt` or a `Mutex` is `Sync`. A standard `unsync` integer is not.

> **The Power of Static Analysis:** If you try to pass a non-thread-safe object (like a plain pointer) into
> a new thread, the **compiler will error**. You are notified of the concurrency bug at your desk, not via a
> kernel dump from the field.

- Safe Synchronization Primitives: ( Rust’s std lib provides primitives that are "wrapped" for safety.

- **Mutexes that Protect Data, Not Just Code:** In C, a `mutex_t` is just a lock floating near the data.
  Developer have to remember to lock it. In Rust, the **Mutex owns the data**.
  * To get to the data, you **must** lock the Mutex.
  * When the "Lock Guard" goes out of scope, the Mutex **automatically unlocks**.

- **Channels for Message Passing:** Rust provides `mpsc` (Multi-Producer, Single-Consumer) channels. This
  allows for "Communication by ownership" you send a buffer down a channel, and you physically lose access
  to it in the sending thread. No use-after-send errors.

- No-Cost Concurrency

Generally Kernel and BSP developers concerned about overhead:

* **Zero Runtime Cost:** These checks are entirely static. The generated assembly is identical to 
  well-written, manual C synchronization.

* **Deterministic Destruction:** Just like memory, locks are released deterministically based on scope. No more forgotten `unlock()` calls in complex `if/else` logic or early returns.

Recap:
---
* **C/C++ Concurrency:** Hard to write, harder to debug, relies on developer discipline.
* **Rust Concurrency:** Hard to write (initially), but **guaranteed to be safe if it compiles.**
* **Result:** You spend less time debugging "Heisenbugs" and more time writing logic. We move from "Defensive Programming" to "Correct-by-Construction."

---
## Cargo ( Tooling ):

- Programming languages depend on 3rd part tools for building, packaging, imaging, handling dependency
  versions.. and more.
- Rust comes with **Cargo** which is considered as a gold standard for package management:
  * One command to download libraries. ( Crates )
  * One command to run tests.
  * One command to build. 
  * One command for micro benchmarking 

- Cross Compilation: made simple with --target flag 
- Standard library management: cargo can automatically download/build the standard library ( or a  `no_std`
  core) for target architecture (ARM, RISC-V, X86_64 )
  - Build profiles: Easy to switch between `dev` and `release`
  - Dead Code Elimination: Compiler and linker work together to ensure that unused dependencies don't
    bloat the binaries. 

  - Modular architecture: xtask, script, generate 

- rustup, rust-analyzer, rustfmt, ...

---
- Compiler: 
    - Rust compiler is very friendly, and emits errors hinting what is exactly but what is
---

- Rust syntax is similar to C/C++, although many of its features were influenced by OCaml a functional 
  programming language such as immutability, higher-order functions, algebraic data types and pattern
  matching.

- Rust also supports object-oriented programming via `structs`, `enums`, `traits`, and`` methods. (i.e: Rust
  fits into be called a Functional, object-oriented, systems, application development,programming language)


