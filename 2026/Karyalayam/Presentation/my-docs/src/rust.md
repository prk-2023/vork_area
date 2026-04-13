# Introduction to Rust:

## Introduction: 

Rust is a **Systems programming Language** which focused on **Safety, Speed, and Concurrency** at the same
time. It's a language designed to to enforce memory safety without a Garbage Collector (GC).

1. **Zero-Cost Abstraction**" : Rust code compiles to native code (LLVM) with performance parity to C/C++.
    - Rust code compiles to native and its deployable virtually anywhere. 
    - Static Guarantees: Shifts the cost of safety from Runtime (latency spikes, GC pauses) to Compile-time 
      (the "Borrow Checker").
    - Immutability by Default: Encourages functional patterns to reduce side effects in complex state
      machines.
---
NOTE: i.e  no added tax on performance:

Things that happen under the hood:
- LLVM Pipeline: `cargo build --release`: `rustc` compiler does not actually generate machine code (the $1$s
  and $0$s ) directly. Instead 
  1. It translates your code into **LLVM Intermediate Representation (IR)**.
  2. It hands that IR over to **LLVM**, the same world-class optimization back-end used by **Clang (C/C++)**
     and **Swift**.
  3. LLVM performs aggressive optimizations (dead code elimination, loop unrolling, vectorization)
     specifically tuned for the target CPU architecture (x86, ARM, RISC-V).

  Because Rust and C++ use the same "optimizer engine," the final binary is often indistinguishable in terms
  of execution strategy.

- "Native Code" vs. Interpreted/JIT: Unlike Java or C#, Rust does not compile to bytecode that runs on a 
  Virtual Machine (JVM/CLR).
  * **No Runtime/VM:** No "middleman" managing the execution.
  * **Direct Execution:** The processor executes Rust instructions directly, eliminates the "warm-up" time 
    seen in JIT (Just-In-Time) compilers and significantly reduces the memory footprint.
  
- Performance Parity: The "Zero-Cost" Reality "Performance parity" => that a well-written Rust program will
  run at the same speed as a well-written C++ program. 
  - **Static Dispatch:** Like C++ templates, Rust’s "Generics" use `monomorphization`. The compiler generates 
    a specific version of a function for every type you use, so there is no runtime overhead for polymorphism.
  - **No Garbage Collection:** In Go or Java, performance is non-deterministic because the GC can 
    "stop the world" to clean memory at any time.
  - In Rust, memory is reclaimed the exact millisecond it goes out of scope, just like manual `free()` in C,
    but without the risk of forgetting it.

- The "Strictness" Advantage: Rust can occasionally **outperform** C/C++ due to its strict aliasing rules. 
  - In C, the compiler often has to be conservative because it can't be sure if two pointers point to the 
    same memory location (pointer aliasing). 
  - Because the **Borrow Checker** guarantees that a mutable reference is unique, the Rust compiler can 
    perform optimizations that a C compiler would be too "afraid" to attempt, such as more aggressive 
    register allocation.

> **In short:** You get the safety of a high-level language with the "bare metal" speed of the most powerful
> systems languages ever created.

---

2. Philosophical Shift: 

- Rust explicitly removes several foot-guns common in C++ and Java:
  - **No Nulls**: Replaced by the `Option<T>` *enum*. Force-handles the `None` case at compile time.
  - No Exceptions: Uses `Result<T, E>` for recoverable errors. Error handling becomes a visible part of the
    API contract, not a hidden side effect.
  - Composition over Inheritance:  No class hierarchies. Behavior is shared via Traits (interfaces on 
    steroids), avoiding the "fragile base class" problem.
---
Note: Replace implicit runtime dangers to explicit compile time contracts:

- *No Nulls* => replaced with => `Option<T>` Enums: In C++, Java, any object reference can be `null` leading
  to infamous `NullPointerExecption`, In Rust a value is either there or its is not, and compiler will
  **force** developer to check. 
  Ex: MMIO , requires dealing with optional HW components or nullable pointers to memory-mapped registers.
  Rust uses `Option<T>` to represent a HW interface that might not be initialized. 
  ```rust 
  struct EthernetDriver {
    // A raw pointer to a transmit buffer that might not be allocated yet
    tx_buffer: Option<*mut u8>, 
  }
  impl EthernetDriver {
    fn transmit(&self) {
        // The compiler prevents accessing tx_buffer directly.
        // You must handle the "None" (uninitialized) case.
        match self.tx_buffer {
            Some(ptr) => unsafe { /* Perform DMA transfer using the pointer */ },
            None => eprintln!("Hardware Error: TX Buffer not allocated"),
        }
    }
  }
  ```
- No Exceptions: System Calls & I/O : Systems code must be deterministic.
  You cannot afford the stack-unwinding overhead of exceptions during a high-frequency interrupt or a
  packet-processing loop. Result treats system failures as return values.

  ```rust 
  use std::os::unix::io::RawFd;

  // Error handling is explicit in the return type
  fn open_socket(port: u16) -> Result<RawFd, String> {
    if port < 1024 {
        return Err("Permission Denied: Privileged Port".to_string());
    }
    // Simulate system call returning a file descriptor
    Ok(3) 
  }

  fn main() {
    // The '?' operator provides a low-overhead way to propagate 
    // errors back up the stack without the cost of an exception.
    let fd = open_socket(80).map_err(|e| format!("Network stack init failed: {}", e));
  }
  ```

- Composition over Inheritance(Traits): Device Drivers
  ( Rust uses Traits to define shared behavior (interfaces) and Structs to hold data, keeping them strictly
    decoupled.) 

  Instead of a deep class hierarchy (e.g., Hardware -> Bus -> PCIe -> NIC), Rust uses Traits to define 
  capabilities. A `struct` implements the `Read` or `Write trait`, allowing it to be used by any generic 
  system utility.

  ```rust 
  trait ByteStream {
    fn write_byte(&mut self, byte: u8);
  }

  struct UART { base_address: usize }
  struct SPI  { bus_id: u8 }

  impl ByteStream for UART {
    fn write_byte(&mut self, byte: u8) {
        // Low-level register write for Serial Communication
    }
  }

  impl ByteStream for SPI {
    fn write_byte(&mut self, byte: u8) {
        // Low-level bit-banging for SPI Bus
    }
  }
  // Generic function that doesn't care about the underlying hardware
  fn send_heartbeat(device: &mut impl ByteStream) {
    device.write_byte(0xAA);
  }
  ```

Why the above matters:
- ABI Stability: Traits avoid the "vtable bloat" often found in complex C++ inheritance trees.
- Predictable Latency: Avoiding exceptions, you ensure that your "Happy Path" and "Error Path" have similar,
  predictable execution costs—critical for real-time systems.
- Safety at the Edge: Using Option for pointers ensures that a null-pointer dereference is caught at 
  compile time, preventing the kernel panics that plague C-based drivers.

---
3. **The Borrow Checker: Ownership Invariants**
  - It enforces three strict rules to prevent Use-After-Free and Data Races:

    | Concept | Rule | Technical Outcome |
    | :--- | :--- | :--- |
    | **Ownership** | Each value has a single "Owner" variable. | Deterministic cleanup (RAII) without a GC. |
    | **Moves** | Assigning `a = b` moves ownership (bitwise copy of stack metadata). | Prevents "Double Free" errors. |
    | **Borrowing** | You can have $\infty$ immutable borrows OR **one** mutable borrow. | Eliminates **Data Races** at the compiler level. |

  -  In Rust, **aliasing + mutation = disaster**. The compiler ensures you never have both at the same time.

- **Concurrency without the Anxiety**: In most languages, thread safety is a "best effort" by the
  developers. In Rust, it is a requirement for compilation.
  * If a data structure isn't thread-safe, the compiler will refuse to "Send" it across a thread boundary.
* **Shared State:** Handled via `Arc<Mutex<T>>`, where the Mutex *owns* the data. You cannot access the 
  inner $T$ without locking the Mutex first.

- Summarizing : 
    * **Reliability:** Drastically reduces the "Mean Time Between Failures."
    * **Efficiency:** Minimal runtime footprint; ideal for Cloud Native, Edge, and WASM.
    * **Maintainability:** Strong typing and explicit error handling make refactoring large-scale systems 
      significantly safer.


-------------
- Programs build with Rust have there memory remain safe even without GC. 

- Has no Nulls, and no exceptions, no Inheritance, and it's variables are immutable by default. 

- Community breaks down developers into 3 groups:
    - People who understand the potential of Rust and use it.
    - People who have not tried it.
    - People who are trying to wrap their heads around the borrow checker. 

- Rust Borrow checker is one of the most major contribution to programming technology, and its the main idea
  that causes most misunderstanding among other users. 

- Borrow checker Working principle:
  * You refer to a variable ( by reading / setting its state for ex) only in the context in which you
    declare it. What you cant do it assign to another variable, pass it as a function argument, or other
    regular things we do with variables in C. The only possible things you are allowed to do with
    variables in Rust are:
    * You are allowed to move the variable to another variable. In which case the assignee loses whatever
       state it had before, and the original variable becomes unusable. 
       The value inside the variable can exist only in one place at a time.
    * You can take a reference to it. References are more like the variables you know and love, in that 
       they can be assigned, passed around, and compared. 
       There are two kinds of reference:
       - An immutable reference. You can take as many immutable references to a variable as you wish, but 
         you can’t assign through them or call any function that changes the variable’s state. 
         As long as any immutable references exist, the original variable is treated as immutable as well.
       - If the variable is mutable, you can also take a mutable reference to it. That can’t be assigned or
         passed around (other than by moving it), and there can be only one at a time. As long as a mutable
         reference exists, the variable itself goes off-limits: it effectively becomes invisible.
       - You can have either immutable references, one mutable reference, or no references at all. You 
         can’t mix references. But if you have a mutable reference, you can take any number of immutable 
         references to it.



Rust is a low-level language like C, and it doesn't use Garbage Collection (GC) by default. 

- Rust's most unique of memory safety is achieved by its feature of **Ownership**. 
