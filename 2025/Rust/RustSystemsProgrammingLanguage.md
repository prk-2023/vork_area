# Rust Systems programming Language:


## Introduction:

Rust was developed at Mozilla Research and aims at being reliable memory safe, fast and data race free.

Provides high-level abstractions while allowing for tight control over resources as i.e: memory management
for systems programming.

==> Most important features of Rust which are necessary to understand <==

1. Rust is a statically types Language offering type inference ( i.e compiler can infer the type in most of
   the situations by the surrounding expressions and statements, this take off the burden to some extent on 
   the programmer)

2. Ownership and Borrowing model was introduced allowing static safety guarantees and compile-time memory
   management, eliminating the need for garbage collection ( Read 2015 The Rust developers 2016b).

   This system was inspired by cyclones region-based memory management ( The Rust developers 2016b).
   Rust calls regions _life times_ and they are used by the compiler to track an object and issue its 
   de-location statically (Read 2015).

3. Rust relies soley on static code analysis within the compiler. Mainly in Ownership Model, Borrowing
   Rules, and lifetimes. All of this enforced with out the need for a garbage collector or runtime checks.

   A walk through of rust compiler task converting code to binary will give better understanding of the
   compilers tasks:

   * **Rust** relies heavily on **static code analysis** during compilation. This design is central to
     Rust's safety guarantees — particularly its **ownership model**, **borrowing rules**, & **lifetimes**
     — all enforced without needing a garbage collector or runtime checks.

   * **stages of the Rust compiler (`rustc`)**, from source code to binary. as below

4. What Does “Static Code Analysis Within the Compiler” Mean in Rust?

   In Rust:

   * **All safety checks happen at compile time** (static).
   * The compiler enforces **memory safety, concurrency safety, and type correctness** through analysis of:
        - **Ownership rules**
        - **Borrowing and lifetimes**
        - **Mutability**
        - **Type inference**
        - **Trait resolution**
        - **No runtime overhead** needed for these features (unlike Java, which rely on garbage collection).

   This static analysis is handled through the Rust compiler (`rustc`), which itself is built in multiple 
   stages.

5. Stages of the Rust Compiler (`rustc`)

Rust’s compiler pipeline is similar in structure to many modern compilers (like Clang or GCC), but with 
additional steps to enforce Rust-specific safety rules.

Here’s a detailed breakdown:

---

### **1. Lexical Analysis (Tokenization)**

* Source code (`.rs`) is broken down into **tokens** (keywords, identifiers, operators, etc.).
* This forms a stream of syntactic elements.

---

### **2. Parsing**

* The token stream is parsed into an **Abstract Syntax Tree (AST)**.
* The AST is a hierarchical, structured representation of the source code’s grammatical structure.

---

### **3. Macro Expansion**

* Rust’s powerful **macro system** (`macro_rules!`, procedural macros, attribute macros) is expanded at this
  stage.
* The AST is transformed to include all generated code.

---

### **4. Name Resolution**

* Variables, functions, modules, and types are **resolved to their definitions**.
* This includes **module resolution**, **trait scoping**, and **use/imports**.

---

### **5. Type Checking and Inference**

* **Type inference** is performed (Rust is strongly typed, but you can omit types in many places).
* The compiler ensures all expressions have a type and that types are used consistently.
* **Generic resolution** and **trait bounds checking** happen here.

---

### **6. Borrow Checker (Lifetime Analysis)**

* This is Rust’s signature safety engine.
* The compiler verifies:

  * Ownership is maintained (only one owner at a time).
  * Borrowing rules are respected (mutable vs immutable).
  * Lifetimes are valid — no dangling references.
* **No runtime code is generated for this** — it's 100% static analysis.

---

### **7. MIR (Mid-level Intermediate Representation) Generation**

* The compiler lowers the AST into a simplified, Rust-specific IR called **MIR**.
* MIR is easier to analyze and optimize than raw AST or LLVM IR.
* More checks happen here, including:

  * **Move analysis**
  * **Drop-checks** (ensuring types are correctly destructed)
  * **Const evaluation**

---

### **8. Optimizations (MIR and LLVM)**

* First, MIR-based optimizations are performed (e.g., dead code elimination).
* Then, the MIR is translated into **LLVM IR**, a lower-level portable IR.
* LLVM performs its own suite of optimizations like inlining, vectorization, etc.

---

### **9. Code Generation (LLVM Codegen)**

* LLVM back-end generates **machine code** from the optimized LLVM IR.
* Target-specific assembly or machine instructions are created for platforms like x86\_64, ARM, etc.

---

### **10. Linking**

* Rust uses **`rustc` → LLVM → linker (e.g., `lld`, `gcc`, or `clang`)**.
* Links together:

  * Your compiled code
  * Rust standard library (`std`)
  * Any other crates or libraries you depend on
* Produces a final **executable binary**.

---

### Optional: LTO & Incremental Compilation

* **LTO (Link Time Optimization)**: Performs additional optimizations across crates at the final linking
  stage.
* **Incremental compilation**: Reuses compilation artifacts to speed up repeated builds 
  (ex: in `cargo check` or `cargo build`).

---

## Summary Diagram of Compilation Stages

```
[Source Code (.rs)]
       ↓
[Lexing → Parsing]
       ↓
[AST → Macro Expansion]
       ↓
[Name Resolution]
       ↓
[Type Checking + Inference]
       ↓
[Borrow Checker & Lifetime Analysis]
       ↓
[MIR Generation → MIR Optimizations]
       ↓
[LLVM IR Generation → LLVM Optimizations]
       ↓
[Code Generation (machine code)]
       ↓
[Linking]
       ↓
[Final Binary Executable]
```

---

## Why This Matters

Rust's reliance on static analysis:

* **Eliminates many runtime errors** (null pointer, data races, memory leaks).
* **Removes the need for a garbage collector**.
* Enables **zero-cost abstractions**: high-level safety, low-level performance.

---

6. A walkthrough of what happens inside `cargo build` or how MIR and LLVM interact with `no_std` environments, 
WASM targets, or embedded systems, and how Rust's internals (like **MIR** and **LLVM**) adapt to:
* **`no_std` environments** (e.g., embedded/OS dev)
* **WASM** (WebAssembly) targets
* **Cross-compilation** scenarios

---

## What Happens When You Run `cargo build`

`cargo` is Rust’s **build system and package manager**. It wraps and orchestrates the compiler (`rustc`), linker, and dependency resolver.

### High-Level Workflow of `cargo build`

```bash
$ cargo build
```

#### 1. **Parse `Cargo.toml` and `Cargo.lock`**

   * Determines dependencies, versions, features, and build profiles (e.g., `dev`, `release`).
   * Computes dependency graph using `crates.io` or git/local paths.

#### 2. **Check if build artifacts are cached**

   * Uses **incremental compilation** if possible.
   * Skips unchanged files unless forced.

#### 3. **Compile dependencies first**

   * Compiles each crate in the dependency graph, in dependency order.
   * For each crate:

     * Runs through **lexing → parsing → AST → MIR → LLVM → binary** via `rustc`.

#### 4. **Compile your crate**

   * Includes main `lib.rs` or `main.rs`.
   * Applies build profile (`dev` uses no optimizations; `release` uses `--opt-level=3`).

#### 5. **Link artifacts**

   * Final stage uses system linker or `lld` to produce the binary.
   * May link in:

     * Standard library (`std`)
     * `core` and `alloc` for `no_std`
     * Dependencies, static libs, dynamic libs

#### 6. **Place binary in `target/` directory**

   * Example: `target/debug/your_binary`

---

## How MIR and LLVM Fit In

### 🔹 MIR: Mid-Level IR

* Rust-specific representation after type checking.
* Used for:

  * Lifetime analysis
  * Move checking
  * Const evaluation
  * Early optimizations

### 🔹 LLVM IR: Low-Level IR

* After MIR → LLVM IR
* This IR is architecture-agnostic and passed to the **LLVM backend**
* LLVM does:

  * Loop unrolling, inlining
  * Dead code elimination
  * Register allocation
  * Target-specific machine code generation

---

## `no_std` Environments

In `no_std`, the standard library is **not linked** (which normally includes I/O, heap, threading, etc.).

### Use Cases:

* Embedded development
* OS kernels
* Bootloaders
* Minimal environments

### Changes in the Pipeline:

* `#![no_std]` disables `std` and uses `core` + optionally `alloc`.
* No system allocator → must provide your own allocator if using `Box`, `Vec`, etc.
* Panic behavior must be defined (`abort` or custom handler).
* Custom startup (`#[no_main]`) and linker scripts are often used.
* You target something like `thumbv7em-none-eabi` using `--target`.

#### Cargo command:

```bash
cargo build --target thumbv7em-none-eabi
```

---

## 🕸️ WebAssembly (WASM) Targets

Rust compiles extremely well to **WASM** via the `wasm32-unknown-unknown` target.

### Changes in the Pipeline:

* Uses **LLVM's WASM backend**.
* No native `std`, I/O, or threads.
* `no_std` is often required, or use `wasm-bindgen`/`stdweb` to access JS features.

#### Example:

```bash
cargo build --target wasm32-unknown-unknown --release
```

Or with WASM bindings:

```bash
wasm-pack build
```

### Output:

* `.wasm` binary for the web
* Optionally `.js` glue code for interop

---

## Cross-Compilation and Custom Targets

Rust can cross-compile to virtually any platform:

* Embedded systems (e.g., ARM Cortex-M)
* Android, iOS
* RISC-V
* Custom operating systems

### Setup:

1. Add the target:

```bash
rustup target add thumbv7em-none-eabi
```

2. Cross-compile:

```bash
cargo build --target thumbv7em-none-eabi
```

3. Use `Xargo` or `build-std` if `core`/`alloc` must also be compiled for that target.

---

## Additional Tools & Tips

| Tool                            | Use                                                |
| ------------------------------- | -------------------------------------------------- |
| `cargo check`                   | Fast type-checking (no codegen)                    |
| `cargo build --release`         | Full optimizations (`--opt-level=3`)               |
| `cargo clean`                   | Remove `target/` artifacts                         |
| `cargo rustc -- --emit=llvm-ir` | Inspect LLVM IR                                    |
| `cargo build -Z build-std`      | Build core/std for custom targets                  |
| `cargo expand`                  | See macro-expanded code                            |
| `cargo asm`                     | View final assembly output (with `cargo-binutils`) |

---

## ummary

| Environment       | Key Change                               |
| ----------------- | ---------------------------------------- |
| Standard (`std`)  | Full runtime, threading, I/O             |
| `no_std`          | Bare-metal, manual allocator, no runtime |
| WASM              | Static, sandboxed, minimal runtime       |
| Cross-compilation | Use specific targets and toolchains      |

Rust's compilation pipeline is incredibly modular — **all analysis and safety happen at compile-time**, and
the final code is as close to C in performance as possible.

---

## Traits: 

Rust offers zero cost abstractions using traits.
Traits are roughly similar to an (Java) interface, offering a type-generic implementation which gets
transformed into a type concrete implementation during compilation.
This way abstract specifications can still be inlined and hence obtain good performance. 
Furthermore Rust offers dynamic dispatch to allow for polymorphism, giving the programmer the choice when to
trade off performance against flexibility.

Core idea of **traits** in Rust is a **powerful abstractions** that allow for **zero-cost, type-safe 
polymorphism**. 


Let's expand on this topic in detail, covering:

---

### **What Are Traits in Rust?**

A **trait** in Rust defines a **collection of methods** (and optionally associated types or constants) that 
a type can implement. They're conceptually similar to **Java interfaces** or **Haskell typeclasses**.

```rust
trait Drawable {
    fn draw(&self);
}
```

Any type implementing `Drawable` must provide a concrete implementation of `draw`.

---

### Traits and Zero-Cost Abstraction

**Zero-cost abstraction** in Rust means:

> High-level abstractions (like traits, iterators, etc.) compile down to low-level code with **no runtime overhead**.

#### How?

Rust uses **monomorphization** with **static dispatch** for trait generics.

##### Example:

```rust
fn render<T: Drawable>(item: T) {
    item.draw();
}
```

At compile time, the Rust compiler generates a **type-specific version** of `render()` for each `T`. This inlining and specialization enable **performance equivalent to hand-written, type-specific code**, with:

* **No dynamic dispatch**
* **No virtual tables**
* **No boxing**

---

### Trait Dispatch: Static vs Dynamic

Rust gives you **control** over **dispatch strategy**:

| Dispatch Type        | When Used                                      | Cost            | Mechanism                     |
| -------------------- | ---------------------------------------------- | --------------- | ----------------------------- |
| Static dispatch**  | Generic bounds (`T: Trait`)                    | Zero            | Inlining via monomorphization |
| Dynamic dispatch** | Trait objects (`&dyn Trait`, `Box<dyn Trait>`) | Slight overhead | Virtual table (vtable) lookup |

---

#### Static Dispatch (Monomorphization)

```rust
fn draw_item<T: Drawable>(item: T) {
    item.draw();
}
```

* `T` is resolved at compile time.
* Compiler generates a new version of `draw_item` for each `T`.
* **Fastest** — no vtable, no indirection.
* Similar to C++ templates.

---

#### Dynamic Dispatch (Trait Objects)

```rust
fn draw_object(item: &dyn Drawable) {
    item.draw();
}
```

* Uses a **vtable** (like Java or C++ virtual functions).
* Allows **heterogeneous collections** (e.g., `Vec<Box<dyn Drawable>>`).
* Enables **runtime polymorphism**.
* Slight performance cost: one pointer indirection per call.

---

### Traits in Practice

#### 1. **Trait Definition**

```rust
trait Area {
    fn area(&self) -> f64;
}
```

#### 2. **Trait Implementation**

```rust
struct Circle { radius: f64 }

impl Area for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius * self.radius
    }
}
```

#### 3. **Using Traits**

* **Static dispatch**:

  ```rust
  fn print_area<T: Area>(shape: T) {
      println!("Area = {}", shape.area());
  }
  ```

* **Dynamic dispatch**:

  ```rust
  fn print_area_dyn(shape: &dyn Area) {
      println!("Area = {}", shape.area());
  }
  ```

---

### Trait Bounds, Default Methods, and Associated Types

#### Default Methods

Traits can include method implementations:

```rust
trait Greet {
    fn name(&self) -> &str;
    fn greet(&self) {
        println!("Hello, {}!", self.name());
    }
}
```

#### Associated Types

```rust
trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}
```

More flexible than using generic parameters when a type depends on the trait.

---

### Trait Features for Power Users

| Feature                   | Description                                                                                         |
| ------------------------- | --------------------------------------------------------------------------------------------------- |
| `impl Trait`              | Used for **anonymous types** that implement a trait (e.g., `fn foo() -> impl Iterator<Item = i32>`) |
| Blanket impls             | Implement trait for all types satisfying a condition: `impl<T: Display> ToString for T {}`          |
| Coherence rules           | Rust prevents conflicting trait implementations across crates                                       |
| Trait objects             | `Box<dyn Trait>` for dynamic dispatch                                                               |
| Specialization (unstable) | Allows overriding trait methods for specific types                                                  |

---

### Summary

| Concept     | Static Dispatch    | Dynamic Dispatch                          |
| ----------- | ------------------ | ----------------------------------------- |
| Syntax      | `T: Trait`         | `&dyn Trait` or `Box<dyn Trait>`          |
| Performance | Inlined, zero-cost | Indirection, vtable call                  |
| Flexibility | Compile-time only  | Runtime polymorphism                      |
| Use Cases   | Fast, generic code | Heterogeneous collections, plugin systems |

Rust’s trait system is one of the key features that allows it to **combine safety, abstraction, and performance**. Unlike Java or Go, you **choose when to pay for flexibility**.

---

Would you like a code sample that benchmarks static vs dynamic dispatch? Or an example using trait objects in a plugin-style system?


