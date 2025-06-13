# Memory Access Basics in Rust

This project explores memory access concepts using Rust:

1. memcpy() equivalent
2. Stack vs Heap allocation
3. Simulated MMIO
4. Cache behavior
5. Memory alignment
6. Struct padding

## How to run a lab
Use:
```bash
cargo run --bin lab1_memcpy --target x86_64-unknown-linux-gnu
```

## Cross Compilation
To compile for AArch64:
```bash
cargo build --target aarch64-unknown-linux-gnu
```
