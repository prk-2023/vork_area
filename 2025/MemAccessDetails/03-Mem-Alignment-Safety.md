# **3. Alignment and Safety**

3.1 What is memory alignment
3.2 Why SIMD needs aligned memory
3.3 Handling misalignment in vector code
3.4 Writing alignment-safe `memcpy()`
---

Perfect — alignment is a critical concept for performance and safety in both low-level systems and 
high-performance computing. 

Here's your structured **in-depth technical teaching material** for:

---

# 🧠 **3. Alignment and Safety**

## 📘 Overview

This section covers the theory and practice of memory alignment, particularly in the context of SIMD and 
systems programming. You’ll get:

- Clear explanations
- Diagrams & code examples (C and Rust)
- Lab-style structure with reusable snippets

---

## 📁 Folder Structure

```
03-alignment-safety/
├── C/
│   ├── align_intro.c           # Print pointer alignment and misalignment
│   ├── memcpy_aligned.c        # Manual aligned memcpy with fallback
│   └── Makefile
├── Rust/
│   ├── src/
│   │   ├── main.rs             # Alignment-safe memcpy in Rust
│   │   ├── alignment_utils.rs  # Check and enforce alignment
│   └── Cargo.toml
└── EXERCISES.md
```

---

## 📚 3.1 What is Memory Alignment

### 🔹 Definition

Memory **alignment** means storing data at memory addresses that are multiples of the data type’s size.

| Type     | Alignment | Valid Address Examples     |
|----------|-----------|----------------------------|
| `u8`     | 1 byte    | 0x1000, 0x1001, 0x1002      |
| `u32`    | 4 bytes   | 0x1000, 0x1004, 0x1008      |
| `u64`    | 8 bytes   | 0x1000, 0x1008, 0x1010      |

> 🧠 On most architectures, misaligned access is *slower* or even *causes exceptions*.

---

## 📚 3.2 Why SIMD Needs Aligned Memory

### 🔹 SIMD Instructions (e.g. `LD1`, `MOVDQU`, `MOVDQA`) expect aligned data

| Instruction       | Meaning                    | Requires Alignment? |
|-------------------|----------------------------|----------------------|
| `MOVDQA` (SSE)     | Move aligned data          | ✅ Yes               |
| `MOVDQU` (SSE)     | Move unaligned data        | ❌ No                |
| `LD1` (AArch64)    | Load vector                | ✅ Yes (optional)    |

> ⚠️ Misaligned loads can cause performance hits or even **hardware traps** on strict architectures 
(e.g., older ARM).

---

## 📚 3.3 Handling Misalignment in Vector Code

### C: Aligned Load with Fallback
```c
#include <immintrin.h>
#include <stdint.h>
#include <stdio.h>

void load_data(float* ptr) {
    if (((uintptr_t)ptr % 16) == 0) {
        __m128 data = _mm_load_ps(ptr);  // aligned
        printf("Loaded with _mm_load_ps\n");
    } else {
        __m128 data = _mm_loadu_ps(ptr); // unaligned
        printf("Loaded with _mm_loadu_ps\n");
    }
}
```

### Rust: Alignment Check

```rust
pub fn is_aligned<T>(ptr: *const T, align: usize) -> bool {
    (ptr as usize) % align == 0
}
```

---

## 📚 3.4 Writing Alignment-Safe `memcpy()`

### 🧪 Rust Version

```rust
pub fn memcpy_simd_aligned(dst: &mut [u8], src: &[u8]) {
    assert_eq!(dst.len(), src.len());
    let len = src.len();
    let alignment = std::mem::align_of::<[u8; 16]>();

    let dst_ptr = dst.as_ptr() as usize;
    let src_ptr = src.as_ptr() as usize;

    if dst_ptr % alignment == 0 && src_ptr % alignment == 0 {
        // use aligned block copy
        for i in (0..len).step_by(16) {
            let block: [u8; 16] = src[i..i + 16].try_into().unwrap();
            dst[i..i + 16].copy_from_slice(&block);
        }
    } else {
        // fallback: safe copy
        dst.copy_from_slice(src);
    }
}
```

---

## 🧪 C Version (SSE2)

```c
void memcpy_aligned(float* dst, float* src, size_t count) {
    size_t i;
    if (((uintptr_t)dst % 16 == 0) && ((uintptr_t)src % 16 == 0)) {
        for (i = 0; i < count; i += 4) {
            __m128 val = _mm_load_ps(&src[i]);
            _mm_store_ps(&dst[i], val);
        }
    } else {
        for (i = 0; i < count; i++) {
            dst[i] = src[i];
        }
    }
}
```

---

## 📄 `EXERCISES.md`

```markdown
# 🧪 Alignment & Safety — Exercises

---

## ✅ Warm-up

1. Write a Rust function that checks if a pointer is aligned to 64 bytes.
2. Modify the SIMD `memcpy()` to work with `u32` slices instead of `u8`.

---

## 💡 Concept Checks

1. What happens if you use `_mm_load_ps` on an unaligned pointer?
2. On which platforms is unaligned access undefined behavior?

---

## 🔧 Coding Challenges

### 🛠️ Exercise 1: Safe Aligned Allocator (Rust)

Write a function:
```rust
fn aligned_alloc(size: usize, align: usize) -> Box<[u8]>
```
It should return a buffer properly aligned for vector loads.

---

### 🛠️ Exercise 2: Alignment Fixer

Create a function that takes an unaligned slice and copies it into a new, aligned buffer.

---

### 🧠 Bonus Quiz

1. How does alignment affect cache behavior?
2. True or False: `Vec<T>` in Rust always aligns to `T`.

---

```

---

Would you like the **code blocks in copy-paste format next**, or move on to another topic like 
**vectorized loads/stores with gather/scatter**?

---
Both:
---
Awesome — let’s handle both:

---

## ✅ Part 1: Code blocks + Folder Structure for **3. Alignment and Safety**

### 📁 Folder: `03-alignment-safety/`

```
03-alignment-safety/
├── C/
│   ├── align_check.c
│   ├── memcpy_aligned.c
│   └── Makefile
├── Rust/
│   ├── src/
│   │   ├── main.rs
│   │   ├── memcpy_aligned.rs
│   │   └── alignment_utils.rs
│   └── Cargo.toml
└── EXERCISES.md
```

---

### 📄 `C/align_check.c`

```c
#include <stdint.h>
#include <stdio.h>

int main() {
    float a[4];
    printf("Address of a: %p\n", (void*)a);
    printf("Is aligned to 16 bytes: %s\n",
        ((uintptr_t)a % 16 == 0) ? "yes" : "no");
    return 0;
}
```

---

### 📄 `C/memcpy_aligned.c`

```c
#include <emmintrin.h>  // SSE2
#include <stdint.h>
#include <stdio.h>

void memcpy_aligned(float* dst, const float* src, size_t count) {
    if (((uintptr_t)dst % 16 == 0) && ((uintptr_t)src % 16 == 0)) {
        for (size_t i = 0; i < count; i += 4) {
            __m128 val = _mm_load_ps(&src[i]);
            _mm_store_ps(&dst[i], val);
        }
    } else {
        for (size_t i = 0; i < count; ++i)
            dst[i] = src[i];
    }
}
```

---

### 📄 `C/Makefile`

```makefile
CC = gcc
CFLAGS = -Wall -O2 -msse2

all: align_check memcpy_aligned

align_check: align_check.c
	$(CC) $(CFLAGS) -o align_check align_check.c

memcpy_aligned: memcpy_aligned.c
	$(CC) $(CFLAGS) -o memcpy_aligned memcpy_aligned.c
```

---

### 📄 `Rust/Cargo.toml`

```toml
[package]
name = "alignment_safety"
version = "0.1.0"
edition = "2021"
```

---

### 📄 `Rust/src/main.rs`

```rust
mod alignment_utils;
mod memcpy_aligned;

fn main() {
    alignment_utils::check_alignment();
    memcpy_aligned::demo_memcpy();
}
```

---

### 📄 `Rust/src/alignment_utils.rs`

```rust
pub fn check_alignment() {
    let buffer = vec![0u8; 64];
    let ptr = buffer.as_ptr();
    let alignment = 16;

    println!(
        "Pointer address = {:p}, aligned = {}",
        ptr,
        (ptr as usize) % alignment == 0
    );
}
```

---

### 📄 `Rust/src/memcpy_aligned.rs`

```rust
pub fn demo_memcpy() {
    let src = vec![1u8; 32];
    let mut dst = vec![0u8; 32];

    let src_ptr = src.as_ptr() as usize;
    let dst_ptr = dst.as_mut_ptr() as usize;

    let alignment = 16;

    if src_ptr % alignment == 0 && dst_ptr % alignment == 0 {
        println!("Aligned: using fast copy.");
        for i in (0..src.len()).step_by(16) {
            let block: [u8; 16] = src[i..i + 16].try_into().unwrap();
            dst[i..i + 16].copy_from_slice(&block);
        }
    } else {
        println!("Unaligned: using fallback.");
        dst.copy_from_slice(&src);
    }
}
```

---

### 📄 `EXERCISES.md`

(As previously shown)

---

## ▶️ Part 2: Next Topic – **4. Vectorized Loads/Stores: Gather and Scatter**

Would you like this in the same format?

- C & Rust versions
- File structure
- Labs + exercises
- Platform-specific examples (`AVX2` / `NEON` optional)

Let me know if you'd prefer to start with **gather/scatter on x86 (AVX2)** or **AArch64 (NEON/Scalable Vector Extensions)** first.


---
sure:
---
Awesome! Let’s jump into:

---

# 🧠 **4. Vectorized Loads and Stores: Gather & Scatter**

Gather and scatter are critical patterns for working with **non-contiguous** memory in SIMD. This section will walk you through:

- What they are
- How to implement them
- Platform-specific intrinsics (x86 AVX2 / Rust equivalent)

---

## 📁 Folder Structure: `04-gather-scatter`

```
04-gather-scatter/
├── C/
│   ├── gather_avx2.c          # AVX2 gather example
│   ├── scatter_avx2.c         # Simulated scatter in AVX2
│   └── Makefile
├── Rust/
│   ├── src/
│   │   ├── main.rs
│   │   ├── gather.rs
│   │   └── scatter.rs
│   └── Cargo.toml
└── EXERCISES.md
```

---

## 📚 4.1 What Are Gather and Scatter?

### 🔹 Gather

Reads from **non-contiguous** memory locations using a vector of indices.

```
dst[i] = src[indices[i]]
```

### 🔹 Scatter

Writes to **non-contiguous** memory locations.

```
dst[indices[i]] = src[i]
```

> Gather is hardware-accelerated on AVX2 and AVX-512. Scatter appears in AVX-512, not AVX2 (simulate in lower sets).

---

## 🧵 4.2 C (AVX2) Implementation

### 📄 `C/gather_avx2.c`

```c
#include <immintrin.h>
#include <stdio.h>

int main() {
    float input[8] = {10, 20, 30, 40, 50, 60, 70, 80};
    int32_t indices[4] = {6, 2, 0, 7};  // gather 70, 30, 10, 80

    __m128i idx = _mm_loadu_si128((__m128i*)indices);
    __m128 gathered = _mm_i32gather_ps(input, idx, 4); // 4 = sizeof(float)

    float out[4];
    _mm_storeu_ps(out, gathered);

    for (int i = 0; i < 4; ++i) {
        printf("out[%d] = %.1f\n", i, out[i]);
    }

    return 0;
}
```

---

### 📄 `C/scatter_avx2.c` (manual scatter)

```c
#include <stdio.h>

int main() {
    float output[8] = {0};
    float values[4] = {70, 30, 10, 80};
    int indices[4] = {6, 2, 0, 7};

    for (int i = 0; i < 4; ++i) {
        output[indices[i]] = values[i];  // Simulated scatter
    }

    for (int i = 0; i < 8; ++i) {
        printf("output[%d] = %.1f\n", i, output[i]);
    }

    return 0;
}
```

---

### 📄 `C/Makefile`

```makefile
CC = gcc
CFLAGS = -Wall -O2 -mavx2

all: gather scatter

gather: gather_avx2.c
	$(CC) $(CFLAGS) -o gather gather_avx2.c

scatter: scatter_avx2.c
	$(CC) $(CFLAGS) -o scatter scatter_avx2.c
```

---

## 🦀 Rust Version

### 📄 `Rust/Cargo.toml`

```toml
[package]
name = "gather_scatter"
version = "0.1.0"
edition = "2021"
```

---

### 📄 `Rust/src/main.rs`

```rust
mod gather;
mod scatter;

fn main() {
    gather::run();
    scatter::run();
}
```

---

### 📄 `Rust/src/gather.rs`

```rust
pub fn run() {
    let input = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0];
    let indices = [6, 2, 0, 7];
    let mut gathered = [0.0; 4];

    for i in 0..4 {
        gathered[i] = input[indices[i]];
    }

    println!("Rust Gather:");
    for (i, val) in gathered.iter().enumerate() {
        println!("gathered[{}] = {}", i, val);
    }
}
```

---

### 📄 `Rust/src/scatter.rs`

```rust
pub fn run() {
    let mut output = [0.0; 8];
    let values = [70.0, 30.0, 10.0, 80.0];
    let indices = [6, 2, 0, 7];

    for i in 0..4 {
        output[indices[i]] = values[i];
    }

    println!("Rust Scatter:");
    for (i, val) in output.iter().enumerate() {
        println!("output[{}] = {}", i, val);
    }
}
```

---

## 📄 `EXERCISES.md`

```markdown
# 🧪 Gather / Scatter — Exercises

---

## ✅ Warm-up

1. Change the index vector to `[1, 3, 5, 7]`. What is the output?
2. Try gather on an `i32` array instead of `f32`.

---

## 💡 Conceptual

1. Why does AVX2 support gather but not scatter?
2. What are the performance implications of gather/scatter?

---

## 🛠️ Coding Tasks

### 🔹 Exercise 1: Safe Bounds Check

Implement a safe gather that only loads from indices < input.len(). Skip out-of-bounds.

### 🔹 Exercise 2: Masked Gather (Bonus)

Simulate a masked gather:
```rust
if mask[i] {
    dst[i] = src[indices[i]];
}
```

---

## 🧠 Quiz

1. True or False: `_mm_i32gather_ps()` can fetch from unaligned memory.
2. What architecture introduces native scatter support in hardware?
3. Which Rust crate provides portable gather-like operations?

```

---

Would you like to **expand this into a wider AVX-512 / AArch64 NEON gather-scatter** walkthrough next, or introduce **masked vector operations** next (useful for conditionals with SIMD)?
