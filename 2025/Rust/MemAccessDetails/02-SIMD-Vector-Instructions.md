# **2. SIMD and Vector Instructions**

---

## **2.1 What Are Vector/SIMD Instructions?**

### 💡 Concept:
**SIMD** (Single Instruction, Multiple Data) allows parallel processing of multiple data elements using a 
single instruction. 
It's especially effective in operations on arrays (e.g., image processing, DSP, matrix operations).

### 📌 Key Idea:
Instead of:
```c
for (int i = 0; i < 4; i++) {
    dst[i] = src1[i] + src2[i];
}
```
A SIMD instruction can do this in **one shot** using a single register:
```c
dst = add_vector(src1, src2);  // Pseudocode
```

### 🧠 Why Use SIMD?
- Boosts throughput with minimal added power consumption
- Utilizes wide registers (128, 256, or 512 bits)
- Supported across architectures (AArch64 NEON, x86 SSE/AVX)

---

## **2.2 AArch64 SIMD (NEON) Overview**

### ✅ Registers:
- **128-bit SIMD registers**: `Q0` to `Q31`
- Each Q register can be accessed as:
  - **Qn** = 128-bit
  - **Dn** = 64-bit
  - **Sn** = 32-bit
  - **Hn** = 16-bit
  - **Bn** = 8-bit

| Type      | Register Size | Example Use                     |
|-----------|----------------|----------------------------------|
| `uint8x16_t` | 128-bit      | 16 unsigned 8-bit integers       |
| `float32x4_t`| 128-bit      | 4 float32 numbers                |

### 🚀 NEON Intrinsics:
These are C functions provided by the compiler that map to hardware SIMD instructions.

```c
uint8x16_t vaddq_u8(uint8x16_t a, uint8x16_t b); // Vector add
```

---

## **2.3 Common Vector Instructions (`LD1`, `ST1`, `LDP`, `STP`)**

| Instruction | Description                        | NEON Intrinsic Equivalent     |
|-------------|------------------------------------|-------------------------------|
| `LD1`       | Load 1 element into SIMD register  | `vld1q_u8()`                  |
| `ST1`       | Store 1 element from SIMD register | `vst1q_u8()`                  |
| `LDP`       | Load Pair (two registers)          | manual with 2x `vld1q_*()`    |
| `STP`       | Store Pair                         | manual with 2x `vst1q_*()`    |

### 🧪 Example (C):
```c
#include <arm_neon.h>
uint8_t data[16] = {1};
uint8x16_t reg = vld1q_u8(data);  // LD1
vst1q_u8(data, reg);              // ST1
```

---

## **2.4 Vectorized `memcpy()` Using NEON Intrinsics**

### 🚀 Goal:
Accelerate `memcpy` by moving 128-bits at a time.

### ✅ C Code:
```c
void neon_memcpy(uint8_t* dst, const uint8_t* src, size_t len) {
    for (size_t i = 0; i < len; i += 16) {
        uint8x16_t data = vld1q_u8(src + i);
        vst1q_u8(dst + i, data);
    }
}
```

> Must ensure `len` is a multiple of 16 and both buffers are 16-byte aligned 
(or use unaligned loads/stores if hardware allows).

---

## **2.5 Assembly View of SIMD-Optimized Code**

### 🔍 Compilation Technique:
Use `-S` flag to inspect assembly.

```bash
clang -O2 -S neon_memcpy.c -o neon_memcpy.s
```

### 🔬 What You’ll See:
```asm
ld1 {v0.16b}, [x1], #16   ; Load 16 bytes
st1 {v0.16b}, [x0], #16   ; Store 16 bytes
```

This is what makes NEON efficient: each pair of instructions transfers 16 bytes of data per loop iteration.

---

## 🦀 Rust Equivalent Highlights (Comparison)

| Concept      | C                            | Rust                                         |
|--------------|------------------------------|----------------------------------------------|
| Intrinsics   | `vld1q_u8`, `vst1q_u8`       | `core::arch::aarch64::*`                     |
| Unsafe Ops   | Raw memory and alignment     | `unsafe {}` blocks with compiler checks      |
| Safety       | Manual pointer handling      | Borrow checker ensures access rules          |
| Optimization | Compiler-dependent           | Inline assembly + `#[target_feature]`        |

### ✅ Example in Rust:
```rust
unsafe {
    let vec = vld1q_u8(ptr);
    vst1q_u8(dst_ptr, vec);
}
```

### 🛡️ Benefits of Rust:
- Fewer memory bugs (use-after-free, buffer overflows)
- Can build safe wrappers over SIMD
- Still gives access to raw power via intrinsics or inline assembly

---

Would you like:
- A formatted PDF version of this?
- The lab structure (with C + Rust labs side by side)?
- Exercises/quizzes for learners?

Let me know how you'd like to expand this!


Here’s the **folder structure**, **file contents**, and the **exercises/quizzes** so you can set it up 
manually on your machine:

---

## 📁 Folder Layout

```
simd_vector_lab_material/
├── lab1_intro_to_simd/
│   ├── c/
│   │   └── lab1_intro_to_simd.c
│   └── rust/
│       └── lab1_intro_to_simd.rs
├── lab2_vector_add/
│   ├── c/
│   │   └── lab2_vector_add.c
│   └── rust/
│       └── lab2_vector_add.rs
├── lab3_vector_memcpy/
│   ├── c/
│   │   └── lab3_vector_memcpy.c
│   └── rust/
│       └── lab3_vector_memcpy.rs
└── EXERCISES.md
```

---

## ✅ Lab Code Files

### `lab1_intro_to_simd.c`
```c
#include <arm_neon.h>
#include <stdio.h>

int main() {
    uint8x16_t a = vdupq_n_u8(42); // fill with 42
    uint8_t arr[16];
    vst1q_u8(arr, a);

    printf("SIMD filled vector: ");
    for (int i = 0; i < 16; i++) {
        printf("%u ", arr[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab1_intro_to_simd.rs`
```rust
#[cfg(target_arch = "aarch64")]
use core::arch::aarch64::*;

fn main() {
    #[cfg(target_arch = "aarch64")]
    unsafe {
        let a = vdupq_n_u8(42);
        let mut arr = [0u8; 16];
        vst1q_u8(arr.as_mut_ptr(), a);
        println!("SIMD filled vector: {:?}", arr);
    }
}
```

---

### `lab2_vector_add.c`
```c
#include <arm_neon.h>
#include <stdio.h>

int main() {
    uint8_t x[16] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    uint8_t y[16] = {1};

    uint8x16_t a = vld1q_u8(x);
    uint8x16_t b = vld1q_u8(y);
    uint8x16_t c = vaddq_u8(a, b);

    uint8_t result[16];
    vst1q_u8(result, c);

    printf("Vector add result: ");
    for (int i = 0; i < 16; i++) {
        printf("%u ", result[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab2_vector_add.rs`
```rust
#[cfg(target_arch = "aarch64")]
use core::arch::aarch64::*;

fn main() {
    #[cfg(target_arch = "aarch64")]
    unsafe {
        let x = [1u8, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
        let y = [1u8; 16];
        let a = vld1q_u8(x.as_ptr());
        let b = vld1q_u8(y.as_ptr());
        let c = vaddq_u8(a, b);

        let mut result = [0u8; 16];
        vst1q_u8(result.as_mut_ptr(), c);
        println!("Vector add result: {:?}", result);
    }
}
```

---

### `lab3_vector_memcpy.c`
```c
#include <arm_neon.h>
#include <stdio.h>

void neon_memcpy(uint8_t* dst, const uint8_t* src, size_t len) {
    for (size_t i = 0; i < len; i += 16) {
        uint8x16_t vec = vld1q_u8(src + i);
        vst1q_u8(dst + i, vec);
    }
}

int main() {
    uint8_t src[64] = {1};
    uint8_t dst[64] = {0};

    neon_memcpy(dst, src, 64);

    printf("Memcpy result: ");
    for (int i = 0; i < 64; i++) {
        printf("%u ", dst[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab3_vector_memcpy.rs`
```rust
#[cfg(target_arch = "aarch64")]
use core::arch::aarch64::*;

fn neon_memcpy(dst: &mut [u8], src: &[u8]) {
    assert_eq!(dst.len(), src.len());
    assert_eq!(dst.len() % 16, 0);
    unsafe {
        for i in (0..src.len()).step_by(16) {
            let vec = vld1q_u8(src[i..].as_ptr());
            vst1q_u8(dst[i..].as_mut_ptr(), vec);
        }
    }
}

fn main() {
    let src = [1u8; 64];
    let mut dst = [0u8; 64];
    neon_memcpy(&mut dst, &src);
    println!("Memcpy result: {:?}", dst);
}
```

---

## 🧠 `EXERCISES.md`

```markdown
# SIMD Lab Exercises & Quizzes

## Conceptual Questions

1. What is the difference between scalar and vector processing?
2. What are the advantages of using SIMD for operations on arrays?
3. Why is alignment important in SIMD operations?
4. Explain the difference between `LD1` and `LDP` instructions.
5. What’s the benefit of using NEON intrinsics instead of writing pure assembly?

## Coding Exercises

1. Modify `lab2_vector_add` to add two vectors of `int16_t` instead of `uint8_t`.
2. Implement a SIMD-based max function that compares two vectors and keeps the greater value.
3. Modify the `memcpy` to copy only every other 16-byte block (skip one block each loop).
4. Add benchmarks to compare scalar vs vector `memcpy`.
5. Use Rust’s `std::simd` once stabilized for an even safer abstraction over NEON.

## Advanced

- Disassemble the compiled NEON Rust code and identify which ARM64 SIMD instructions are used.
- Add conditional logic using SIMD (e.g., blend/mask).
```

---

Next: jump into x86 SIMD next (SSE/AVX)
---
let's move into **x86 SIMD (SSE/AVX)** with the same structured approach we used for AArch64 NEON.

---

## 🧠 **3. x86 SIMD and Vector Instructions (SSE/AVX)**

### ✅ Plan:

#### 3.1 What are SIMD instructions (recap with x86 context)
- What is SSE (Streaming SIMD Extensions)?
- What is AVX (Advanced Vector Extensions)?
- Register widths: 128-bit (SSE), 256-bit (AVX), 512-bit (AVX-512)
- Data types: `__m128`, `__m256`, `__m512` etc.

#### 3.2 Register model and instruction sets
- `XMM`, `YMM`, `ZMM` registers
- Common instructions:
  - Load/store: `_mm_loadu_ps`, `_mm256_loadu_si256`, `_mm_storeu_ps`
  - Arithmetic: `_mm_add_ps`, `_mm256_add_epi32`
  - Masked operations (AVX2/AVX-512)

#### 3.3 SSE and AVX vector intrinsics: C Examples
- Filling vectors
- Vector addition
- Memory copy with SIMD
- Alignment: `_mm_malloc` and `_mm_free`

#### 3.4 Rust equivalents (using `std::arch::x86_64`)
- How to write similar examples in Rust with `#[target_feature]`
- Pros: Safety, feature detection, portability

#### 3.5 Disassembly: SSE/AVX in Assembly
- `objdump` or `cargo asm`
- Recognizing vector instructions (`movaps`, `addps`, `vmovdqa`, etc.)

---

## 🧪 Labs Plan (C + Rust side-by-side)

| Lab | Title                     | Intrinsics Used                           |
|-----|---------------------------|--------------------------------------------|
| 1   | Intro to SSE              | `_mm_set1_epi8`, `_mm_storeu_si128`       |
| 2   | Vector Add (SSE/AVX)      | `_mm_add_ps`, `_mm256_add_ps`             |
| 3   | SIMD Memcpy               | `_mm_loadu_si128`, `_mm_storeu_si128`     |

---

## 🚧 Coming Up:
I'll prep:
- A parallel folder like before: `x86_simd_lab_material/`
- With C and Rust labs
- Exercises like “switch from SSE to AVX”, “compare aligned vs unaligned loads”, and 
“benchmark scalar vs SIMD”

Ready to generate code + exercises, or want a quick overview/visuals first?


---
Great! Here’s the complete **folder structure**, **file contents**, and **exercise sheet** for the **x86 SIMD (SSE/AVX)** labs — presented in plain text and copy-paste friendly code blocks.

---

## 📁 Folder Structure

```
x86_simd_lab_material/
├── lab1_intro_sse/
│   ├── c/
│   │   └── lab1_intro_sse.c
│   └── rust/
│       └── lab1_intro_sse.rs
├── lab2_vector_add/
│   ├── c/
│   │   └── lab2_vector_add.c
│   └── rust/
│       └── lab2_vector_add.rs
├── lab3_simd_memcpy/
│   ├── c/
│   │   └── lab3_simd_memcpy.c
│   └── rust/
│       └── lab3_simd_memcpy.rs
└── EXERCISES.md
```

---

## ✅ Lab Code Files

### `lab1_intro_sse.c`
```c
#include <emmintrin.h>  // SSE2
#include <stdio.h>

int main() {
    __m128i vec = _mm_set1_epi8(42); // Fill all 16 bytes with 42
    uint8_t result[16];
    _mm_storeu_si128((__m128i*)result, vec);

    printf("SSE Vector: ");
    for (int i = 0; i < 16; i++) {
        printf("%d ", result[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab1_intro_sse.rs`
```rust
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;

fn main() {
    #[cfg(target_arch = "x86_64")]
    unsafe {
        let vec = _mm_set1_epi8(42);
        let mut result = [0i8; 16];
        _mm_storeu_si128(result.as_mut_ptr() as *mut __m128i, vec);
        println!("SSE Vector: {:?}", result);
    }
}
```

---

### `lab2_vector_add.c` (SSE)
```c
#include <emmintrin.h>  // SSE2
#include <stdio.h>

int main() {
    __m128i a = _mm_set1_epi8(1);
    __m128i b = _mm_set1_epi8(2);
    __m128i c = _mm_add_epi8(a, b);

    uint8_t result[16];
    _mm_storeu_si128((__m128i*)result, c);

    printf("Vector Add Result: ");
    for (int i = 0; i < 16; i++) {
        printf("%u ", result[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab2_vector_add.rs`
```rust
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;

fn main() {
    #[cfg(target_arch = "x86_64")]
    unsafe {
        let a = _mm_set1_epi8(1);
        let b = _mm_set1_epi8(2);
        let c = _mm_add_epi8(a, b);

        let mut result = [0i8; 16];
        _mm_storeu_si128(result.as_mut_ptr() as *mut __m128i, c);
        println!("Vector Add Result: {:?}", result);
    }
}
```

---

### `lab3_simd_memcpy.c`
```c
#include <emmintrin.h>  // SSE2
#include <stdio.h>
#include <string.h>

void simd_memcpy(uint8_t* dst, const uint8_t* src, size_t len) {
    for (size_t i = 0; i < len; i += 16) {
        __m128i v = _mm_loadu_si128((const __m128i*)(src + i));
        _mm_storeu_si128((__m128i*)(dst + i), v);
    }
}

int main() {
    uint8_t src[64] = {1};
    uint8_t dst[64] = {0};

    simd_memcpy(dst, src, 64);

    printf("SIMD Memcpy Result: ");
    for (int i = 0; i < 64; i++) {
        printf("%u ", dst[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab3_simd_memcpy.rs`
```rust
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;

fn simd_memcpy(dst: &mut [u8], src: &[u8]) {
    assert_eq!(dst.len(), src.len());
    assert!(dst.len() % 16 == 0);
    unsafe {
        for i in (0..dst.len()).step_by(16) {
            let v = _mm_loadu_si128(src[i..].as_ptr() as *const __m128i);
            _mm_storeu_si128(dst[i..].as_mut_ptr() as *mut __m128i, v);
        }
    }
}

fn main() {
    let src = [1u8; 64];
    let mut dst = [0u8; 64];
    simd_memcpy(&mut dst, &src);
    println!("SIMD Memcpy Result: {:?}", dst);
}
```

---

## 🧠 `EXERCISES.md`

```markdown
# x86 SIMD (SSE/AVX) Lab Exercises

## Conceptual

1. What are the differences between SSE and AVX?
2. How does register width (XMM vs YMM vs ZMM) affect performance and alignment?
3. What are the alignment requirements of `_mm_load_si128` vs `_mm_loadu_si128`?

## Hands-on Coding

1. Change `lab2_vector_add` to operate on `int32_t` using `_mm_add_epi32`.
2. Rewrite `lab3_simd_memcpy` using AVX (`__m256i`, `_mm256_loadu_si256`, etc).
3. Benchmark scalar `memcpy()` vs SIMD version for different sizes.

## Rust Challenges

1. Rewrite `lab2_vector_add.rs` to use `i32x4` if using nightly and `std::simd`.
2. Implement SIMD-based `memset` that sets a buffer to a value using `_mm_set1_epi8`.

## Advanced

- Disassemble the Rust SIMD executable using `cargo asm` and identify `movdqa`, `paddb`, `vmovdqu`.
- Explain how you’d conditionally select AVX2 or SSE2 at runtime using Rust feature detection.
```

---

This structure mirrors your previous labs — everything clean and easy to extend.

Would you like to proceed to:
- Add **AVX2 version** of lab2 and lab3?
- Or jump into **disassembly and benchmarks** next?


---
Both:
---
Awesome — let’s extend this with **AVX2 versions** of the labs and also guide you through 
**disassembly and benchmarking** steps.

---

## ✅ Updated Folder Structure

```
x86_simd_lab_material/
├── lab1_intro_sse/
├── lab2_vector_add/
│   ├── c/
│   │   ├── lab2_vector_add_sse.c
│   │   └── lab2_vector_add_avx2.c
│   └── rust/
│       ├── lab2_vector_add_sse.rs
│       └── lab2_vector_add_avx2.rs
├── lab3_simd_memcpy/
│   ├── c/
│   │   ├── lab3_simd_memcpy_sse.c
│   │   └── lab3_simd_memcpy_avx2.c
│   └── rust/
│       ├── lab3_simd_memcpy_sse.rs
│       └── lab3_simd_memcpy_avx2.rs
└── EXERCISES.md
```

---

## 💻 AVX2 Code Examples

### `lab2_vector_add_avx2.c`
```c
#include <immintrin.h>
#include <stdio.h>

int main() {
    __m256i a = _mm256_set1_epi32(1);
    __m256i b = _mm256_set1_epi32(2);
    __m256i c = _mm256_add_epi32(a, b);

    int result[8];
    _mm256_storeu_si256((__m256i*)result, c);

    printf("AVX2 Vector Add Result: ");
    for (int i = 0; i < 8; i++) {
        printf("%d ", result[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab2_vector_add_avx2.rs`
```rust
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;

fn main() {
    #[cfg(target_feature = "avx2")]
    unsafe {
        let a = _mm256_set1_epi32(1);
        let b = _mm256_set1_epi32(2);
        let c = _mm256_add_epi32(a, b);

        let mut result = [0i32; 8];
        _mm256_storeu_si256(result.as_mut_ptr() as *mut __m256i, c);
        println!("AVX2 Vector Add Result: {:?}", result);
    }
}
```

---

### `lab3_simd_memcpy_avx2.c`
```c
#include <immintrin.h>
#include <stdio.h>

void simd_memcpy_avx2(uint8_t* dst, const uint8_t* src, size_t len) {
    for (size_t i = 0; i < len; i += 32) {
        __m256i v = _mm256_loadu_si256((const __m256i*)(src + i));
        _mm256_storeu_si256((__m256i*)(dst + i), v);
    }
}

int main() {
    uint8_t src[64] = {1};
    uint8_t dst[64] = {0};
    simd_memcpy_avx2(dst, src, 64);

    printf("AVX2 Memcpy Result: ");
    for (int i = 0; i < 64; i++) {
        printf("%u ", dst[i]);
    }
    printf("\n");
    return 0;
}
```

---

### `lab3_simd_memcpy_avx2.rs`
```rust
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;

fn simd_memcpy_avx2(dst: &mut [u8], src: &[u8]) {
    assert_eq!(dst.len(), src.len());
    assert!(dst.len() % 32 == 0);
    unsafe {
        for i in (0..dst.len()).step_by(32) {
            let v = _mm256_loadu_si256(src[i..].as_ptr() as *const __m256i);
            _mm256_storeu_si256(dst[i..].as_mut_ptr() as *mut __m256i, v);
        }
    }
}

fn main() {
    let src = [1u8; 64];
    let mut dst = [0u8; 64];
    simd_memcpy_avx2(&mut dst, &src);
    println!("AVX2 Memcpy Result: {:?}", dst);
}
```

---

## 🔍 Disassembly Tips

### 🔧 C: Using `objdump`
```bash
gcc -O2 lab2_vector_add_avx2.c -o add_avx2
objdump -d add_avx2 | grep -i 'vmov\|vadd\|vpxor'
```

### 🦀 Rust: Using `cargo asm`
Install:
```bash
cargo install cargo-asm
```

Disassemble:
```bash
cargo asm lab2_vector_add_avx2::main
```

Look for:
- `vmovdqa`, `vaddps`, `vaddpd`, `vpxor`

---

## ⏱️ Benchmarking Scalar vs SIMD

### Rust example (use `criterion`)
Add to `Cargo.toml`:
```toml
[dev-dependencies]
criterion = "0.5"
```

Write `benches/bench_memcpy.rs`:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn scalar_copy(dst: &mut [u8], src: &[u8]) {
    for (d, s) in dst.iter_mut().zip(src.iter()) {
        *d = *s;
    }
}

// Add your SIMD version here...

fn benchmark(c: &mut Criterion) {
    let src = [42u8; 1024];
    let mut dst = [0u8; 1024];

    c.bench_function("scalar_copy", |b| {
        b.iter(|| scalar_copy(black_box(&mut dst), black_box(&src)))
    });

    // Add SIMD benchmarks here...
}

criterion_group!(benches, benchmark);
criterion_main!(benches);
```

Run:
```bash
cargo bench
```

---

should we continue with x86-64 assembly walkthroughs next?

---

Perfect — let’s dive into **x86-64 assembly walkthroughs**, specifically focusing on how to read and understand the output of vectorized C and Rust code compiled with SSE/AVX intrinsics.

---

## 🧠 **x86-64 SIMD Assembly Walkthroughs (SSE/AVX)**

### 📌 Goals:
- Understand which instructions are generated for common vector operations
- Learn how to differentiate scalar vs SIMD code at the assembly level
- Identify optimization patterns (loop unrolling, aligned loads, etc.)

---

## ✅ 1. Tools and Setup

### 🔧 For C:
```bash
gcc -O2 -mavx2 -S lab2_vector_add_avx2.c -o lab2_vector_add_avx2.s
objdump -d ./a.out | less
```

### 🦀 For Rust:
Install:
```bash
cargo install cargo-asm
```

Usage:
```bash
cargo asm lab2_vector_add_avx2::main
```

---

## ✅ 2. What to Look for

### 💡 Common SIMD Instructions:
| Instruction | Description                      | Set     |
|-------------|----------------------------------|----------|
| `movaps`    | Move aligned packed floats       | SSE      |
| `movdqa`    | Move aligned packed integers     | SSE2     |
| `addps`     | Packed float addition            | SSE      |
| `addpd`     | Packed double addition           | SSE2     |
| `vaddps`    | AVX packed float add             | AVX      |
| `vaddpd`    | AVX packed double add            | AVX      |
| `vmovdqu`   | AVX unaligned move               | AVX      |
| `vpaddb`    | AVX/SSE packed byte add          | AVX2     |
| `vpxor`     | AVX/SSE XOR packed ints          | AVX2     |

---

## ✅ 3. C AVX2 Disassembly Walkthrough

### 🔍 Code (`lab2_vector_add_avx2.c`)
```c
__m256i a = _mm256_set1_epi32(1);
__m256i b = _mm256_set1_epi32(2);
__m256i c = _mm256_add_epi32(a, b);
```

### 🔎 Assembly (with `-O2 -mavx2`)
```asm
vpbroadcastd     ymm0, DWORD PTR .LC0[rip] ; broadcast value to all lanes
vpbroadcastd     ymm1, DWORD PTR .LC1[rip]
vpaddd           ymm0, ymm0, ymm1          ; ymm0 = ymm0 + ymm1
vmovdqu          YMMWORD PTR [rsp-0x20], ymm0
```

#### 🧠 Notes:
- `vpbroadcastd`: AVX2 instruction to replicate a scalar across all elements
- `vpaddd`: AVX2 256-bit packed int add
- `vmovdqu`: store unaligned

---

## ✅ 4. Rust AVX2 Disassembly Walkthrough

### 🔍 Code (Rust `lab2_vector_add_avx2.rs`)
```rust
let a = _mm256_set1_epi32(1);
let b = _mm256_set1_epi32(2);
let c = _mm256_add_epi32(a, b);
```

### 🔎 Assembly via `cargo asm`
```asm
vpbroadcastd     ymm0, esi
vpbroadcastd     ymm1, edi
vpaddd           ymm2, ymm0, ymm1
vmovdqu          ymmword ptr [rcx], ymm2
```

#### 🧠 Notes:
- Rust uses safe abstractions but emits same SIMD instructions
- `vpbroadcastd` replicates the constant across lanes
- `vpaddd` is 256-bit vector addition

---

## ✅ 5. Memcpy Comparison (SSE vs AVX)

| Version | Instructions Used       | Width | Notes                            |
|---------|-------------------------|-------|----------------------------------|
| SSE     | `movdqu` + `movdqu`     | 128b  | 16 bytes per iteration           |
| AVX     | `vmovdqu` + `vmovdqu`   | 256b  | 32 bytes per iteration           |
| AVX-512 | `vmovdqa64`, etc.       | 512b  | 64 bytes per iteration (ZMM)     |

---

## 🔎 6. Scalar vs SIMD - Assembly Clues

### Scalar Add
```asm
mov eax, [rdi]
add eax, [rsi]
mov [rdx], eax
```

### SIMD Add
```asm
vpbroadcastd ymm0, ...
vpbroadcastd ymm1, ...
vpaddd       ymm0, ymm0, ymm1
```

### Loop Unrolling Example (Autovectorization)
```asm
vmovdqu ymm0, [rsi]
vmovdqu ymm1, [rsi+0x20]
vmovdqu [rdi], ymm0
vmovdqu [rdi+0x20], ymm1
```

---

## 🛠️ Optional Rust Feature Detection Example

To run different SIMD versions dynamically:

```rust
if is_x86_feature_detected!("avx2") {
    unsafe { avx2_memcpy(...) }
} else {
    scalar_memcpy(...)
}
```

---

## 🔚 Summary

- You now know how to **spot SIMD in disassembly**, both in C and Rust
- SSE/AVX instructions follow a clear naming pattern: `mov`, `add`, `xor`, etc., prefixed with `v` in AVX
- **Rust emits high-perf SIMD** and offers dynamic feature detection to stay safe and portable

---

Would you like:
- AVX-512 follow-up next?
- Or move into higher-level SIMD abstractions in Rust like `std::simd` or `portable_simd`?


---
move to higher-level SIMD abstractions in rust:
---
Nice — moving into **high-level SIMD in Rust** is a great next step! These abstractions give you safe, portable access to SIMD without manually managing registers or worrying about target-specific intrinsics.

---

## 🧠 Overview: High-Level SIMD in Rust

### ✅ Two main options:
| Feature            | `std::simd`                      | `portable_simd` (nightly)          |
|--------------------|----------------------------------|------------------------------------|
| Availability       | Stable in Rust 1.74+ (limited)   | Nightly + `#![feature(portable_simd)]` |
| Platform Support   | x86/x86_64 + others              | Truly cross-platform (WASM, ARM, etc.) |
| Use Case           | 128-bit lanes                    | 128–512-bit lanes, dynamic length  |
| Abstraction        | Types like `u32x4`, `f32x4`      | Same, but more complete            |

---

## 📁 Lab Structure Proposal

```
portable_simd_intro/
├── Cargo.toml
├── src/
│   ├── main.rs              # Basic SIMD add/mul example
│   └── memcpy_simd.rs       # Vectorized memcpy via portable_simd
├── benches/
│   └── simd_bench.rs        # Criterion benchmarks
└── EXERCISES.md             # Quizzes and puzzles
```

---

## 🧪 Example: Portable SIMD Addition

### `main.rs`
```rust
#![feature(portable_simd)]

use core::simd::{Simd, SimdUint};

fn main() {
    let a = Simd::<u32, 8>::splat(1);
    let b = Simd::<u32, 8>::splat(2);
    let c = a + b;

    println!("SIMD add result: {:?}", c);
}
```

You get:
```
SIMD add result: [3, 3, 3, 3, 3, 3, 3, 3]
```

---

## 🧠 Vectorized Memcpy Example

### `memcpy_simd.rs`
```rust
#![feature(portable_simd)]

use core::simd::{Simd, SimdPartialEq};

pub fn simd_memcpy(dst: &mut [u8], src: &[u8]) {
    assert_eq!(dst.len(), src.len());

    let lane_count = 16;
    type Block = Simd<u8, 16>;

    let chunks = dst.len() / lane_count;
    for i in 0..chunks {
        let base = i * lane_count;
        let data = Block::from_slice(&src[base..base + lane_count]);
        data.write_to_slice(&mut dst[base..base + lane_count]);
    }
}
```

---

## ⚖️ Why This is Cool

| Feature                        | Benefit                                           |
|-------------------------------|---------------------------------------------------|
| Type-safe lanes               | No casting between pointer types                 |
| Portable                      | Same code runs on ARM NEON, AVX2, WASM SIMD      |
| Fallbacks                     | Rust automatically falls back to scalar if needed |
| Composable APIs               | Use `.simd_eq()`, `.simd_gt()`, `.reduce_sum()`  |

---

## 🏁 Benchmarks with Criterion

```toml
[dev-dependencies]
criterion = "0.5"
```

```rust
// benches/simd_bench.rs
use criterion::{criterion_group, criterion_main, Criterion};
use portable_simd_intro::simd_memcpy;

fn bench_simd(c: &mut Criterion) {
    let src = vec![42u8; 1024];
    let mut dst = vec![0u8; 1024];

    c.bench_function("simd_memcpy", |b| {
        b.iter(|| simd_memcpy(&mut dst, &src));
    });
}

criterion_group!(benches, bench_simd);
criterion_main!(benches);
```

---

## 📚 Exercise Ideas (EXERCISES.md)

1. Implement `simd_max()` for `Simd<f32, 8>`
2. Implement SIMD mask filter: keep even numbers
3. Compare scalar and SIMD versions of dot product
4. Explore runtime `target_feature` dispatch in Rust

---

Want this zipped and ready to go?

Or prefer a walkthrough of `std::simd` on stable Rust next?

---
Short Walkthrough of std::simd:
---
Sure! Here's a **short, focused walkthrough** of using `std::simd`, the stable version of high-level SIMD in Rust (available since **Rust 1.74**).

---

## 🧠 What is `std::simd`?

`std::simd` is a **type-safe, portable abstraction** over SIMD registers that allows you to write vectorized code without touching platform-specific intrinsics. It provides types like `Simd<f32, 4>` for vectorized operations.

> ⚠️ Currently, `std::simd` supports **fixed-width 128-bit vectors** only.

---

## ✅ Enabling `std::simd`

No need for nightly or `#![feature(...)]` — just use the crate:

### In `Cargo.toml`
```toml
[dependencies]
stdsimd = "0.1.0"  # as of Rust 1.74+
```

Or if you’re using `std` and don’t need the external crate:
```rust
use std::simd::{Simd, SimdPartialEq};
```

---

## 🔢 Example: SIMD Vector Add

```rust
use std::simd::Simd;

fn main() {
    let a = Simd::from_array([1.0, 2.0, 3.0, 4.0]);
    let b = Simd::from_array([4.0, 3.0, 2.0, 1.0]);
    let c = a + b;

    println!("Vector result: {:?}", c);
}
```

Output:
```
Vector result: [5.0, 5.0, 5.0, 5.0]
```

---

## 🧠 Available Operations

| Operation      | Example             |
|----------------|---------------------|
| Add/Sub        | `a + b`, `a - b`    |
| Multiply       | `a * b`             |
| Comparison     | `a.simd_eq(b)`      |
| Bitwise        | `a & b`, `a | b`    |
| Reduce         | `a.reduce_sum()`    |

---

## 🧪 SIMD Comparison Example

```rust
use std::simd::Simd;

fn elementwise_max(a: &[f32], b: &[f32]) -> Vec<f32> {
    assert_eq!(a.len(), b.len());
    let mut out = Vec::with_capacity(a.len());

    for (chunk_a, chunk_b) in a.chunks(4).zip(b.chunks(4)) {
        let va = Simd::from_slice(chunk_a);
        let vb = Simd::from_slice(chunk_b);
        let max = va.simd_max(vb);
        out.extend_from_slice(&max.to_array());
    }

    out
}
```

---

## ⚖️ Pros of `std::simd`

- ✅ Safe and idiomatic
- ✅ Automatically portable (works on x86_64, AArch64)
- ✅ No `unsafe` required for most operations
- ✅ Works with `cargo bench` and profiling tools

---

## ⚠️ Limitations

| Limitation       | Details                        |
|------------------|--------------------------------|
| Only 128-bit     | `Simd<T, 4>` or `Simd<T, 8>` max |
| No dynamic width | No runtime-lane-size config    |
| No aligned loads | Yet to be stabilized           |

---

Want a quick zipped lab structure with examples using only `std::simd`? 
---
Sure:
---

Great! Here's the **full lab structure**, **file contents**, and **exercises/quizzes** for a short hands-on lab using stable Rust's `std::simd`.

---

## 📁 Folder Structure: `std_simd_intro`

```
std_simd_intro/
├── Cargo.toml
├── src/
│   ├── main.rs              # Demo of vector addition using std::simd
│   ├── simd_max.rs          # Element-wise max using std::simd
│   └── simd_utils.rs        # Reusable SIMD helpers
└── EXERCISES.md             # Learning exercises & quizzes
```

---

## 📄 Cargo.toml

```toml
[package]
name = "std_simd_intro"
version = "0.1.0"
edition = "2021"

[dependencies]
```

> ✅ `std::simd` is part of the standard library starting from Rust 1.74+. No need to add external crates.

---

## 📄 `src/main.rs`

```rust
use std::simd::Simd;

fn main() {
    let a = Simd::from_array([1.0, 2.0, 3.0, 4.0]);
    let b = Simd::from_array([4.0, 3.0, 2.0, 1.0]);
    let c = a + b;

    println!("a + b = {:?}", c); // Should print: [5.0, 5.0, 5.0, 5.0]
}
```

---

## 📄 `src/simd_max.rs`

```rust
use std::simd::Simd;

pub fn elementwise_max(a: &[f32], b: &[f32]) -> Vec<f32> {
    assert_eq!(a.len(), b.len());
    let mut out = Vec::with_capacity(a.len());

    for (chunk_a, chunk_b) in a.chunks_exact(4).zip(b.chunks_exact(4)) {
        let va = Simd::from_slice(chunk_a);
        let vb = Simd::from_slice(chunk_b);
        let max = va.simd_max(vb);
        out.extend_from_slice(&max.to_array());
    }

    // handle remainder
    for i in a.len() - (a.len() % 4)..a.len() {
        out.push(a[i].max(b[i]));
    }

    out
}
```

---

## 📄 `src/simd_utils.rs`

```rust
use std::simd::Simd;

/// Dot product of two f32 arrays using SIMD
pub fn simd_dot(a: &[f32], b: &[f32]) -> f32 {
    assert_eq!(a.len(), b.len());
    let mut acc = Simd::splat(0.0);

    for (chunk_a, chunk_b) in a.chunks_exact(4).zip(b.chunks_exact(4)) {
        let va = Simd::from_slice(chunk_a);
        let vb = Simd::from_slice(chunk_b);
        acc += va * vb;
    }

    let mut sum = acc.reduce_sum();

    // handle remainder
    for i in a.len() - (a.len() % 4)..a.len() {
        sum += a[i] * b[i];
    }

    sum
}
```

---

## 📄 `EXERCISES.md`

```markdown
# 🧪 SIMD in Rust (std::simd) — Exercises & Quizzes

---

## ✅ Part 1: Warm-up

1. Replace `f32` with `u32` and try adding two vectors.
2. What happens if the input slice isn't a multiple of 4?

---

## 🧠 Part 2: Code Challenges

### 🔹 Exercise 1: Scalar fallback

Implement a safe fallback for `elementwise_max()` for non-multiple-of-4 lengths without using `chunks_exact()`.

### 🔹 Exercise 2: SIMD min function

Create a new function `elementwise_min(a: &[f32], b: &[f32]) -> Vec<f32>` using `simd_min()`.

### 🔹 Exercise 3: SIMD Threshold Filter

Implement:
```rust
fn threshold_filter(input: &[f32], threshold: f32) -> Vec<f32>
```
Use `simd_gt()` and return 0.0 for elements below threshold.

---

## 🤔 Quiz

1. What is the output type of `Simd::<f32, 4>::splat(1.0) + Simd::<f32, 4>::splat(2.0)`?
2. Which of these are valid operations on `Simd<u32, 4>`?
    - `a * b`
    - `a & b`
    - `a / b`
    - `a.simd_eq(b)`
3. Which `std::simd` method reduces a vector into a single value?

---

## 🏁 Bonus

- Modify the dot product to support `Simd<f64, 2>` instead.
- Benchmark SIMD vs scalar versions using `cargo bench`.
```

---

Would you like a matching folder that uses `portable_simd` next, for side-by-side comparison and broader lane support?
