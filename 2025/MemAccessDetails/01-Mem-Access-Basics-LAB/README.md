# Memory Access Basics Lab

✅ Your code-based lab suite is ready under the file **`Memory Access Labs`**, complete with:

- `Makefile` for easy compilation (`make lab1`, `make lab2`, etc.)
- Separate files for each core topic (`memcpy`, stack/heap, MMIO, cache, alignment, and struct padding)
- Architecture-awareness (notes on AArch64 vs x86_64 behavior)

Let me know if you want:
- A `README.md` for learners,
- GDB/objdump walkthroughs for inspection,
- Bare-metal support or `qemu` scripts for MMIO testing on AArch64.
memory_lab/
├── Makefile
├── lesson1_memcpy.c
├── lesson2_stack_heap.c
├── lesson3_mmio.c
├── lesson4_cache.c
├── lesson5_alignment.c
├── bonus_struct_padding.c
└── README.md


This lab introduces fundamental memory access concepts via hands-on C examples.

## Lessons

1. `memcpy()` and `memmove()`
2. Stack vs Heap Memory Allocation
3. Simulated MMIO Access
4. Cache Access Patterns
5. Memory Alignment and Struct Packing

## Building

```bash
make        # Optimized
make debug  # Debug symbols

Awesome! Here’s how you can turn these memory access lessons into a self-contained **lab setup** with:

- Organized **code files**
- A **Makefile** to compile all examples
- Options to run with **debug symbols**
- Optional use of `gdb`/`objdump` for deeper analysis
- Architecture-specific notes

---

# 🧪 Memory Access Basics — Lab Setup

## 📁 **Directory Structure**
```
memory_lab/
├── Makefile
├── lesson1_memcpy.c
├── lesson2_stack_heap.c
├── lesson3_mmio.c
├── lesson4_cache.c
├── lesson5_alignment.c
├── bonus_struct_padding.c
└── README.md
```

---

## 📦 **Makefile**

```makefile
CC = gcc
CFLAGS = -Wall -O2
DBGFLAGS = -g -O0

TARGETS = lesson1_memcpy lesson2_stack_heap lesson3_mmio lesson4_cache lesson5_alignment bonus_struct_padding

all: $(TARGETS)

debug: CFLAGS=$(DBGFLAGS)
debug: $(TARGETS)

%: %.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGETS)
```

---

## 🧑‍💻 Running the Lab

```sh
make        # Build all examples with optimization
make debug  # Build all with debug symbols
make clean  # Clean binaries
```

Run individually:

```sh
./lesson1_memcpy
./lesson2_stack_heap
./lesson3_mmio
./lesson4_cache
./lesson5_alignment
./bonus_struct_padding
```

---

## 🧰 Optional GDB Commands

For any compiled binary with `make debug`, run:

```sh
gdb ./lesson5_alignment
```

Inside GDB:
```gdb
break main
run
info registers
x/16xb buffer
```

---

## 🔎 Optional objdump Analysis

```sh
objdump -d lesson1_memcpy | less
```

Useful for:
- Seeing `mov`, `rep movsb`, `ldr`, `str` for `memcpy`
- Spotting alignment-safe instructions on **AArch64** (`ldp`, `str`, etc.)

---

## 📄 README.md (Sample Intro)

```md
# Memory Access Basics Lab

This lab introduces fundamental memory access concepts via hands-on C examples.

## Lessons

1. `memcpy()` and `memmove()`
2. Stack vs Heap Memory Allocation
3. Simulated MMIO Access
4. Cache Access Patterns
5. Memory Alignment and Struct Packing

## Building

```bash
make        # Optimized
make debug  # Debug symbols
```

## Exploring Further

- Use `gdb` to inspect memory and variables.
- Use `objdump` to view assembly.
- Try running on both x86_64 and AArch64 to observe differences.

```

---

## ✅ Architecture-Specific Notes

| Topic        | x86_64                             | AArch64                              |
|--------------|-------------------------------------|---------------------------------------|
| `memcpy()`   | Can tolerate misaligned `memcpy`   | May trap on misaligned access        |
| MMIO         | Simulated via `volatile`            | Real MMIO needs `dsb`, `dmb`, `isb` |
| Alignment    | Misaligned reads slow but allowed   | Misaligned reads often forbidden     |
| Cache        | Inclusive multi-level (L1/L2/L3)     | Usually unified L2, non-inclusive    |

---

Would you like me to bundle all the code files into a `.zip` or paste them one by one here?
