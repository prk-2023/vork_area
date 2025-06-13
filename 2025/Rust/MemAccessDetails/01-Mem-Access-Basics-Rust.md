#  **Memory Access Basics a Rust-specific deep-dive teaching material*

### 📚 Topics:
- `memcpy()` in Rust (1.1)
- Stack vs Heap vs MMIO in Rust (1.2)
- Cache hierarchy and memory alignment in Rust (1.3)

This version focuses on **idiomatic Rust**, yet includes **unsafe code** where needed to explore low-level 
behavior, including architecture-specific notes for **x86_64** and **AArch64**.

---

# 🧠 Memory Access Basics in Rust

---

## 🟦 **1.1 What is `memcpy()` in Rust?**

### 🧾 High-Level:
Rust does not expose `memcpy()` directly but provides **safe** and **unsafe** ways to copy memory.

---

### ✅ Safe Copying: Using `.clone()` and `.copy_from_slice()`
```rust
fn safe_copy() {
    let src = [1u8, 2, 3, 4, 5];
    let mut dst = [0u8; 5];
    dst.copy_from_slice(&src);
    println!("Copied: {:?}", dst);
}
```

---

### 🔥 Unsafe Equivalent: Using `core::ptr::copy_nonoverlapping` (like `memcpy`)
```rust
fn memcpy_like() {
    let src = [1u8, 2, 3, 4, 5];
    let mut dst = [0u8; 5];
    unsafe {
        core::ptr::copy_nonoverlapping(src.as_ptr(), dst.as_mut_ptr(), src.len());
    }
    println!("Unsafe copy: {:?}", dst);
}
```

- Equivalent to `memcpy()`: no overlap allowed.
- Use `copy()` if overlap may exist (like `memmove()`).

### ❗ Note:
Unsafe memory copy is **architecture-sensitive**:
- **AArch64**: misaligned access may **panic** or degrade performance.
- **x86_64**: may tolerate misaligned access but still has performance cost.

---

## 🟦 **1.2 Stack vs Heap vs MMIO in Rust**

### 🔶 Stack Allocation (default for primitives and small fixed-size arrays)
```rust
fn stack_example() {
    let x = 42; // i32 on stack
    let arr = [0u8; 1024]; // Array on stack
    println!("{}, len={}", x, arr.len());
}
```

---

### 🟩 Heap Allocation (via `Box`, `Vec`, `String`, etc.)
```rust
fn heap_example() {
    let boxed = Box::new(42);
    let vec = vec![1, 2, 3];
    println!("Boxed: {}, Vec: {:?}", boxed, vec);
}
```

### 📍 Observations:
```rust
use std::mem;

fn addr_demo() {
    let stack_var = 42;
    let heap_var = Box::new(42);
    println!("Stack var at {:p}", &stack_var);
    println!("Heap var at {:p}", &*heap_var);
}
```

- Stack address is high (on x86_64).
- Heap address typically in lower memory region.

---

### 🧠 MMIO Simulation in Rust (embedded-style)

Rust provides direct register access via **raw pointers** and `volatile`.

```rust
fn fake_mmio() {
    const MMIO_ADDR: *mut u32 = 0x1000_0000 as *mut u32;
    unsafe {
        MMIO_ADDR.write_volatile(0xDEADBEEF); // Write to fake MMIO
        let val = MMIO_ADDR.read_volatile();  // Read back
        println!("MMIO Read: 0x{:X}", val);
    }
}
```

- `write_volatile` / `read_volatile` ensure compiler doesn't optimize away hardware access.
- Real MMIO is typically used in `no_std` + embedded targets (`cortex-m`, `riscv`, `aarch64`).

---

## 🟦 **1.3 Cache Hierarchy and Memory Alignment**

### 🧠 Cache Effects (via access patterns)

Rust can't directly control CPU caches but we can benchmark access patterns:

```rust
use std::time::Instant;

fn cache_demo() {
    let mut arr = vec![0u8; 1_000_000];
    let now = Instant::now();
    for i in 0..arr.len() {
        arr[i] += 1;
    }
    println!("Sequential: {:?}", now.elapsed());

    let now = Instant::now();
    for _ in 0..arr.len() {
        let idx = rand::random::<usize>() % arr.len();
        arr[idx] += 1;
    }
    println!("Random: {:?}", now.elapsed());
}
```

### 📌 Result:
- Sequential access benefits from spatial locality and cache lines.
- Random access causes cache misses and slowness.
- Same logic applies to **x86_64** and **AArch64**, though cache sizes differ.

---

### 📐 Alignment in Rust

Rust aligns values by default, but you can override it.

#### Default alignment:
```rust
#[repr(C)]
struct Aligned {
    a: u8,
    b: u32, // 3 bytes of padding inserted after `a`
}
```

#### Packed struct (misaligned!)
```rust
#[repr(C, packed)]
struct Packed {
    a: u8,
    b: u32, // Misaligned
}

fn misaligned_access() {
    let data = Packed { a: 1, b: 0xDEAD_BEEF };
    unsafe {
        let ptr = &data.b as *const u32;
        println!("Read misaligned b: 0x{:X}", *ptr);
    }
}
```

### ⚠️ Architecture Notes:
- **AArch64**: May crash on misaligned access (`SIGBUS`) unless handled carefully.
- **x86_64**: May tolerate it, but slower.

---

### Bonus: Alignment with `align` Attribute
```rust
#[repr(align(64))]
struct CacheLineAligned([u8; 64]);

fn main() {
    let data = CacheLineAligned([0; 64]);
    println!("Aligned at 64B: {:p}", &data);
}
```

This is useful for:
- SIMD operations
- Cache line alignment (to avoid false sharing in concurrency)

---

## 🛠 Suggested Exercises (in Rust)

| Exercise | Goal |
|---------|------|
| Write safe and unsafe versions of a memory copy | Understand how `copy_nonoverlapping` works |
| Benchmark heap vs stack allocation | Compare performance and address ranges |
| Access misaligned fields in packed structs | See what happens on x86_64 vs AArch64 |
| Implement a fake MMIO register and toggle a flag | Practice volatile memory access |
| Profile cache-efficient vs inefficient access patterns | Explore impact of access locality |

---

Would you like:
- These turned into a **Rust workspace with `cargo run` commands per module**?
- Added support for `no_std` + embedded targets (like AArch64 bare-metal)?
- A `README.md` guide for learners?

