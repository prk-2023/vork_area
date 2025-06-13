# 01- 🧠 **Memory Access Basics**

---

## **1.1 What is `memcpy()`**

### 🔍 Definition:
`memcpy()` is a standard C library function used to copy a block of memory from a source address to a
destination address.

### 📚 Syntax:
```c
void *memcpy(void *dest, const void *src, size_t n);
```
- `dest`: Pointer to the destination array where data will be copied.
- `src`: Pointer to the source of data.
- `n`: Number of bytes to copy.

### 🛠 Example:
```c
char src[10] = "hello";
char dest[10];
memcpy(dest, src, 6); // Copies "hello" including the null terminator
```

### 🚧 Key Notes:
- `memcpy()` performs a shallow byte-wise copy.
- It does **not** check for overlapping memory regions. Use `memmove()` instead for that.
- Can be optimized using SIMD instructions or hardware-level features.

NOTE:
  SIMD: Single instructions and multiple data (This are called **Vector instructions** which are CPU
  instructions that operate on multiple data values **in parallel** rather than one at a time. )

### 🔬 Real-world Analogy:
Think of `memcpy()` as a librarian copying text from one book to another, character by character,
without understanding the words.

---

## **1.2 Stack vs Heap vs MMIO Memory**

### 🧱 **Stack Memory**:
- **LIFO (Last-In-First-Out)** structure.
- Managed automatically (function calls, local variables).
- Fast allocation and deallocation.
- Size is limited (typically a few MBs).
- Stored in contiguous regions in memory.

#### 🔧 Example:
```c
void foo() {
    int x = 5; // Allocated on the stack
}
```

---

### 🏗 **Heap Memory**:
- Manually managed by the programmer (or garbage collector in higher-level languages).
- Larger than the stack.
- Slower allocation (involves system calls or allocator logic).
- Used for dynamic memory (`malloc`, `calloc`, `new` in C++).

#### 🔧 Example:
```c
int *ptr = malloc(sizeof(int) * 10); // Allocated on heap
free(ptr); // Must be freed manually
```

---

### ⚡ **MMIO (Memory-Mapped I/O)**:
- Used to access hardware peripherals as if they were memory locations.
- Special memory region mapped to device registers.
- Often volatile: access order and timing matter. (i.e volatile: variables value might be changed by factors outside
  the control of the current code execution, Eg: by another thread, an interrupt or external HW )
- Common in embedded systems.

#### 🔧 Example (C-style pseudo-code):
```c
#define LED_CTRL_REG *((volatile uint32_t*)0x40021000)
LED_CTRL_REG = 0x1; // Turn on LED
```

---

## **1.3 Cache Hierarchy and Memory Alignment**

### 🧠 **Cache Hierarchy**:
Modern CPUs have multiple cache levels to speed up memory access.

| Level | Scope     | Speed      | Size    |
|-------|-----------|------------|---------|
| L1    | Per core  | Fastest    | ~32KB   |
| L2    | Per core  | Slower     | ~256KB  |
| L3    | Shared    | Slowest    | ~10MB   |

- **Locality of reference**: Temporal (reuse of data), Spatial (accessing nearby data).
- **Cache misses**: Lead to latency—data has to be fetched from main memory (slow).

### 📦 Example:
```c
int arr[1000];
// Accessing arr[0], arr[1], ..., arr[999] makes use of spatial locality
```

---

### 📐 **Memory Alignment**:
- Data must be aligned in memory according to its type.
- Misalignment can lead to performance penalties or even faults on some architectures (e.g., ARM).

#### 📌 Alignment Rules (example for 32-bit):
- `int`: aligned to 4 bytes
- `double`: aligned to 8 bytes

#### 🔧 Example:
```c
struct Aligned {
    char c;
    int i; // Compiler inserts 3 bytes of padding after `c`
};
```

Use `__attribute__((packed))` in GCC to remove padding (not always recommended).

---

### 🧪 Demo: Performance Hit from Misalignment (C)
```c
#include <stdio.h>
#include <stdint.h>

int main() {
    uint8_t data[12];
    uint32_t *unaligned = (uint32_t*)(data + 1); // Misaligned access
    *unaligned = 0xDEADBEEF; // May cause fault or performance drop
}
```

---

Would you like this turned into a slide deck, interactive lab, or code-based lesson? 
I can help format or expand on any section depending on your audience.

---
Sure:
---

Great! Here's a **code-based lesson plan** for **Memory Access Basics**, complete with exercises, 
architecture-specific notes (for **x86_64** and **AArch64**), and observations learners can make by running 
the code. These examples are written in **C**, since it gives low-level control ideal for understanding 
memory access.

---

# 🧠 **Memory Access Basics — Code-Based Lessons**

---

## 🔹 Lesson 1: Using `memcpy()` Safely

### 📘 Objective:
- Understand how `memcpy()` works.
- Differentiate `memcpy()` vs `memmove()`.

### 📄 Code Sample:
```c
#include <stdio.h>
#include <string.h>

int main() {
    char src[] = "hello";
    char dest[10];

    memcpy(dest, src, strlen(src) + 1);
    printf("Copied string: %s\n", dest);

    // Dangerous usage (overlapping memory)
    char buffer[] = "abcdef";
    memcpy(buffer + 2, buffer, 4); // Overlap! Undefined behavior
    printf("Overlapped memcpy: %s\n", buffer);

    // Safe usage with memmove
    char buffer2[] = "abcdef";
    memmove(buffer2 + 2, buffer2, 4); // Correct
    printf("Overlapped memmove: %s\n", buffer2);

    return 0;
}
```

### 🔬 Observe:
- Run this on **x86_64** and **AArch64**.
- x86_64 may tolerate overlapping `memcpy()` (due to stronger memory handling), but AArch64 may misbehave
  or yield inconsistent results.

---

## 🔹 Lesson 2: Stack vs Heap

### 📘 Objective:
- Show stack allocation vs heap allocation.
- Understand scope and lifetime.

### 📄 Code Sample:
```c
#include <stdio.h>
#include <stdlib.h>

void stack_example() {
    int stack_var = 42;
    printf("Stack variable: %d (addr: %p)\n", stack_var, (void*)&stack_var);
}

void heap_example() {
    int *heap_var = malloc(sizeof(int));
    *heap_var = 84;
    printf("Heap variable: %d (addr: %p)\n", *heap_var, (void*)heap_var);
    free(heap_var);
}

int main() {
    stack_example();
    heap_example();
    return 0;
}
```

### 🧪 Experiment:
- Compare the address range of stack and heap on **x86_64 vs AArch64**.
  - On x86_64, stack addresses are typically high memory.
  - On AArch64, may vary depending on OS and ASLR settings.

---

## 🔹 Lesson 3: Memory-Mapped I/O (MMIO)

### 📘 Objective:
- Learn how to simulate MMIO with volatile memory.

### ⚠️ Note:
- On bare-metal or Linux with `/dev/mem`, MMIO can be tested for real.
- Here, we simulate it using `volatile` variables.

### 📄 Code Sample (Simulated MMIO):
```c
#include <stdint.h>
#include <stdio.h>

volatile uint32_t fake_register = 0;

void write_to_mmio(uint32_t value) {
    fake_register = value;
}

uint32_t read_from_mmio() {
    return fake_register;
}

int main() {
    write_to_mmio(0xDEADBEEF);
    printf("MMIO Read: 0x%X\n", read_from_mmio());
    return 0;
}
```

### 📌 AArch64 Note:
- **`volatile`** prevents reordering of accesses, crucial for MMIO.
- AArch64 requires **memory barriers** (`dsb`, `isb`, `dmb`) in real MMIO (not needed in this simulation).

---

## 🔹 Lesson 4: Cache Behavior and Spatial Locality

### 📘 Objective:
- Observe cache efficiency when accessing memory sequentially vs randomly.

### 📄 Code Sample:
```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define SIZE 1024 * 1024 // 1 million ints

int arr[SIZE];

void sequential_access() {
    for (int i = 0; i < SIZE; i++) {
        arr[i]++;
    }
}

void random_access() {
    for (int i = 0; i < SIZE; i++) {
        int index = rand() % SIZE;
        arr[index]++;
    }
}

int main() {
    clock_t start, end;

    start = clock();
    sequential_access();
    end = clock();
    printf("Sequential time: %f\n", (double)(end - start) / CLOCKS_PER_SEC);

    start = clock();
    random_access();
    end = clock();
    printf("Random time: %f\n", (double)(end - start) / CLOCKS_PER_SEC);

    return 0;
}
```

### 🧪 Result:
- Sequential access benefits from spatial locality and cache line prefetching.
- Random access causes frequent cache misses.

---

## 🔹 Lesson 5: Memory Alignment

### 📘 Objective:
- Understand alignment requirements and effects of misaligned access.

### 📄 Code Sample:
```c
#include <stdio.h>
#include <stdint.h>

int main() {
    uint8_t buffer[8];

    uint32_t *aligned = (uint32_t*)(buffer + 0);
    uint32_t *misaligned = (uint32_t*)(buffer + 1);

    *aligned = 0x12345678;
    printf("Aligned access OK: 0x%X\n", *aligned);

    // Caution: misaligned access (undefined behavior on some systems)
    *misaligned = 0xDEADBEEF;
    printf("Misaligned access OK? 0x%X\n", *misaligned);

    return 0;
}
```

### 🛑 AArch64 Warning:
- Misaligned access may cause a **segfault** or **alignment fault**.
- Use `__attribute__((packed))` or memcpy as fallback for portable structs.

---

## 🧩 Bonus: Struct Padding and Alignment

```c
#include <stdio.h>

struct A {
    char c;
    int i;
};

struct __attribute__((packed)) B {
    char c;
    int i;
};

int main() {
    printf("Size of A (aligned): %lu\n", sizeof(struct A));
    printf("Size of B (packed) : %lu\n", sizeof(struct B));
    return 0;
}
```

### 📌 Takeaway:
- On x86_64: Struct A → 8 bytes; Struct B → 5 bytes.
- On AArch64: Similar behavior, but packed structs may cause misaligned access.

---

Would you like this turned into a lab with **Makefile**, **compiler flags**, or even **assembly-level inspection** with `objdump` or `gdb`?


---
Sure:
---
---
Memory Access Lab:
---
/* Memory Access Basics - Lab Suite */

/* Makefile */
# Save as Makefile in the same directory
# Usage: make lab1, make lab2, etc.

CC = gcc
CFLAGS = -O2 -Wall -Wextra

all: lab1 lab2 lab3 lab4 lab5 lab6

lab1: lab1_memcpy.c
	$(CC) $(CFLAGS) -o lab1 lab1_memcpy.c

lab2: lab2_stack_heap.c
	$(CC) $(CFLAGS) -o lab2 lab2_stack_heap.c

lab3: lab3_mmio_sim.c
	$(CC) $(CFLAGS) -o lab3 lab3_mmio_sim.c

lab4: lab4_cache.c
	$(CC) $(CFLAGS) -o lab4 lab4_cache.c

lab5: lab5_alignment.c
	$(CC) $(CFLAGS) -o lab5 lab5_alignment.c

lab6: lab6_struct_padding.c
	$(CC) $(CFLAGS) -o lab6 lab6_struct_padding.c

clean:
	rm -f lab1 lab2 lab3 lab4 lab5 lab6

/* Lab 1 - memcpy vs memmove */
// lab1_memcpy.c
#include <stdio.h>
#include <string.h>

int main() {
    char src[] = "hello";
    char dest[10];

    memcpy(dest, src, strlen(src) + 1);
    printf("Copied string: %s\n", dest);

    char buffer[] = "abcdef";
    memcpy(buffer + 2, buffer, 4);
    printf("Overlapped memcpy: %s\n", buffer);

    char buffer2[] = "abcdef";
    memmove(buffer2 + 2, buffer2, 4);
    printf("Overlapped memmove: %s\n", buffer2);

    return 0;
}

/* Lab 2 - Stack vs Heap */
// lab2_stack_heap.c
#include <stdio.h>
#include <stdlib.h>

void stack_example() {
    int stack_var = 42;
    printf("Stack variable: %d (addr: %p)\n", stack_var, (void*)&stack_var);
}

void heap_example() {
    int *heap_var = malloc(sizeof(int));
    *heap_var = 84;
    printf("Heap variable: %d (addr: %p)\n", *heap_var, (void*)heap_var);
    free(heap_var);
}

int main() {
    stack_example();
    heap_example();
    return 0;
}

/* Lab 3 - Simulated MMIO */
// lab3_mmio_sim.c
#include <stdint.h>
#include <stdio.h>

volatile uint32_t fake_register = 0;

void write_to_mmio(uint32_t value) {
    fake_register = value;
}

uint32_t read_from_mmio() {
    return fake_register;
}

int main() {
    write_to_mmio(0xDEADBEEF);
    printf("MMIO Read: 0x%X\n", read_from_mmio());
    return 0;
}

/* Lab 4 - Cache locality */
// lab4_cache.c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define SIZE 1024 * 1024
int arr[SIZE];

void sequential_access() {
    for (int i = 0; i < SIZE; i++) arr[i]++;
}

void random_access() {
    for (int i = 0; i < SIZE; i++) {
        int index = rand() % SIZE;
        arr[index]++;
    }
}

int main() {
    clock_t start, end;

    start = clock();
    sequential_access();
    end = clock();
    printf("Sequential time: %f\n", (double)(end - start) / CLOCKS_PER_SEC);

    start = clock();
    random_access();
    end = clock();
    printf("Random time: %f\n", (double)(end - start) / CLOCKS_PER_SEC);

    return 0;
}

/* Lab 5 - Alignment */
// lab5_alignment.c
#include <stdio.h>
#include <stdint.h>

int main() {
    uint8_t buffer[8];
    uint32_t *aligned = (uint32_t*)(buffer + 0);
    uint32_t *misaligned = (uint32_t*)(buffer + 1);

    *aligned = 0x12345678;
    printf("Aligned: 0x%X\n", *aligned);

    *misaligned = 0xDEADBEEF; // Warning: may cause fault on AArch64
    printf("Misaligned: 0x%X\n", *misaligned);

    return 0;
}

/* Lab 6 - Struct padding */
// lab6_struct_padding.c
#include <stdio.h>

struct A {
    char c;
    int i;
};

struct __attribute__((packed)) B {
    char c;
    int i;
};

int main() {
    printf("Size of A (aligned): %lu\n", sizeof(struct A));
    printf("Size of B (packed): %lu\n", sizeof(struct B));
    return 0;
}
---
