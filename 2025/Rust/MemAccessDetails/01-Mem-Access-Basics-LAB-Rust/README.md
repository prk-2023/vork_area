## 📁 Project Structure (`memory_access_basics_rust`)
```
memory_access_basics_rust/
├── Cargo.toml
├── README.md
├── .cargo/config.toml
└── src/
    ├── main.rs
    ├── lab1_memcpy.rs
    ├── lab2_stack_heap.rs
    ├── lab3_mmio.rs
    ├── lab4_cache.rs
    ├── lab5_alignment.rs
    ├── lab6_struct_padding.rs
```

---

## 🛠 Each Lab

### 🔹 `lab1_memcpy.rs`
- Safe `.copy_from_slice()`
- Unsafe `copy_nonoverlapping()`
- Comparison on overlapping behavior

### 🔹 `lab2_stack_heap.rs`
- Show stack-allocated and heap-allocated variables
- Print addresses
- Compare x86_64 vs AArch64 behavior

### 🔹 `lab3_mmio.rs`
- Simulated MMIO with `volatile` pointer access
- Safe wrapper around `read_volatile()` / `write_volatile()`

### 🔹 `lab4_cache.rs`
- Sequential vs random memory access
- Benchmark with `std::time::Instant`
- Optional: Add rayon for parallel cache stress testing

### 🔹 `lab5_alignment.rs`
- Aligned vs misaligned structs
- Demonstrate safe and unsafe access
- Use `#[repr(C)]` and `#[repr(packed)]`

### 🔹 `lab6_struct_padding.rs`
- Show how alignment affects `struct` size
- Visualize padding and memory layout

---

## 📘 README.md
- Overview of concepts
- How to run each lab:
  ```bash
  cargo run --bin lab1_memcpy
  ```
- Notes on behavior differences between **x86_64** and **AArch64**

---

## 🧪 Architecture Support
- Cross-compilation support (`.cargo/config.toml`)
- Target AArch64:
  ```toml
  [build]
  target = "aarch64-unknown-linux-gnu"
  ```

---

## 🔧 Optional: Add GDB & objdump support
- `.gdbinit` for stepping into unsafe memory copies
- Use `cargo-objdump` to inspect memory layout

---

Would you like me to generate and zip up this Rust project for download, or paste the files here one by one so you can copy them directly?

./memory_access_basics_rust.zip  
