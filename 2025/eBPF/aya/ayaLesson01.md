# Aya eBPF Learning Notes

*Target: Develop on x86\_64 first, deploy on aarch64 embedded Linux*
*Development Environments: Fedora 36+, Debian 12*

- Setup
- Basics
- Write first program
- Building and running locally
- cross-compiling for aarch64
- Deploying to aarch64 embedded devices
- debugging tips
- References 
- Tips

---

## 1. **Setup Development Environment**

### On Fedora 36+ / Debian 12 (x86\_64)

* Install Rust toolchain (stable):

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  rustup default stable
  ```
* Add cross-compilation targets:

  ```bash
  rustup target add aarch64-unknown-linux-gnu
  ```
* Install cross compiler for aarch64:

  * Fedora:

    ```bash
    sudo dnf install gcc-aarch64-linux-gnu
    ```
  * Debian:

    ```bash
    sudo apt install gcc-aarch64-linux-gnu
    ```
* Install other dependencies:

  ```bash
  sudo dnf install clang llvm libelf-devel libbpf-devel
  sudo apt install clang llvm libelf-dev libbpf-dev
  ```

---

## 2. **Aya Basics**

* Aya crates:

  * `aya-bpf` — write eBPF programs (kernel space).
  * `aya` — user-space loader & control.
* eBPF programs are compiled with **no\_std** Rust + `cargo xtask` or custom build scripts.
* Programs can be attached as kprobes, uprobes, tracepoints, etc.
* Maps used to communicate between kernel and user space.

---

## 3. **Writing Your First eBPF Program (x86\_64)**

* Create Rust workspace with two crates:

  * `my_ebpf` — for kernel eBPF program (`no_std`, compiled with `cargo bpf` or cargo + aya build scripts).
  * `my_user` — for user space app (loads and attaches program).

* Example kprobe program to trace `sys_execve`.

### Step 1: Create a Rust Workspace with Two Crates

We separate the **kernel-space eBPF program** and the **user-space loader** into two crates.

#### Create the workspace directory:

```bash
mkdir aya-trace-execve
cd aya-trace-execve
cargo new --lib my_ebpf
cargo new my_user
```

#### Create `Cargo.toml` workspace file:

```toml
[workspace]
members = [
    "my_ebpf",
    "my_user"
]
```

---

### Step 2: Set Up `my_ebpf` Crate (eBPF Program)

The `my_ebpf` crate is where you write your kernel eBPF program in Rust.

#### Update `Cargo.toml` for `my_ebpf`:

```toml
[package]
name = "my_ebpf"
version = "0.1.0"
edition = "2021"

[dependencies]
aya-bpf = { version = "0.17", features = ["maps", "kprobe"] }

[lib]
crate-type = ["cdylib"]

[profile.dev]
panic = "abort"

[profile.release]
panic = "abort"
```

#### Update `src/lib.rs` in `my_ebpf`:

```rust
#![no_std]
#![no_main]

use aya_bpf::{
    macros::kprobe,
    programs::ProbeContext,
    helpers::bpf_trace_printk,
};

#[kprobe(name="trace_execve")]
pub fn trace_execve(ctx: ProbeContext) -> u32 {
    // Log a message to the kernel trace pipe
    let msg = b"execve syscall called!\0";
    unsafe {
        bpf_trace_printk(msg.as_ptr(), msg.len() as u32);
    }
    0
}

```

---

### Step 3: Build the eBPF Program

Aya programs compile to eBPF bytecode (which is architecture-independent).

You need to install the `bpfel-unknown-none` target for Rust:

```bash
rustup target add bpfel-unknown-none
```

Compile the eBPF program:

```bash
cargo build --package my_ebpf --release --target bpfel-unknown-none
```

The output `.so` file will be at:

```
target/bpfel-unknown-none/release/my_ebpf.so
```

---

### Step 4: Set Up `my_user` Crate (User-Space Loader)

This crate loads and attaches the eBPF program.

#### Update `Cargo.toml` for `my_user`:

```toml
[package]
name = "my_user"
version = "0.1.0"
edition = "2021"

[dependencies]
aya = "0.17"
tokio = { version = "1", features = ["full"] }
```

#### Update `src/main.rs` in `my_user`:

```rust
use aya::{Bpf, programs::KProbe};
use std::convert::TryInto;
use tokio;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    // Load the eBPF program
    let mut bpf = Bpf::load_file("../my_ebpf/target/bpfel-unknown-none/release/my_ebpf.so")?;

    // Get the kprobe program by name
    let program: &mut KProbe = bpf.program_mut("trace_execve").unwrap().try_into()?;

    // Load and attach kprobe to the kernel function "sys_execve"
    program.load()?;
    program.attach("sys_execve", 0)?;

    println!("Attached to sys_execve, tracing... Press Ctrl+C to exit.");

    // Keep running to receive events
    tokio::signal::ctrl_c().await?;

    Ok(())
}
```

---

### Step 5: Build the User-Space Loader

```bash
cargo build --package my_user --release
```

---

### Step 6: Run the User Program with Proper Permissions

To load eBPF programs, root privileges are required:

```bash
sudo ./target/release/my_user
```

---

### Step 7: Verify Tracing Output

Your eBPF program logs messages to the kernel trace pipe. You can see these messages by reading from `/sys/kernel/debug/tracing/trace_pipe`:

```bash
sudo cat /sys/kernel/debug/tracing/trace_pipe
```

When you run any command that calls `execve`, you should see:

```
execve syscall called!
```
---
* **Debugging**: Use `dmesg` for kernel errors if the program fails to load.
* **Function name**: The `sys_execve` symbol might differ by kernel version (e.g., `__x64_sys_execve`); check with `sudo bpftool kprobe list` or `sudo cat /proc/kallsyms | grep execve`.
---

## 4. **Building & Running Locally**

* Compile kernel program:

  ```bash
  cargo build --target=bpfel-unknown-none --package my_ebpf
  ```
* Compile user space program normally.
* Load and attach program with Aya user-space library.
* Use tools like `bpftool`, `tracefs`, or `dmesg` to verify.

---

## 5. **Cross-Compiling for aarch64**

* Add `aarch64-unknown-linux-gnu` target.
* Use `cargo build --target=aarch64-unknown-linux-gnu` for user space.
* For eBPF programs, compile with `bpfel-unknown-none` (eBPF bytecode is architecture independent).
* Transfer binaries to embedded device.

---

## 6. **Deploying to aarch64 Embedded Device**

* Make sure kernel supports eBPF, BTF, and required tracepoints.
* Transfer binary via `scp` or other means.
* Run user space loader.
* Monitor with `sudo bpftool prog` and `dmesg`.

---

## 7. **Debugging Tips**

* Use `bpf_trace_printk` for simple debug output.
* Check kernel logs: `dmesg`.
* Use `bpftool` to inspect maps, programs, and attachments.
* Use Aya’s tracing and logging features.

---

## 8. **Learning Resources**

* [Aya GitHub repo](https://github.com/aya-rs/aya)
* Aya official docs: [https://docs.rs/aya/latest/aya/](https://docs.rs/aya/latest/aya/)
* eBPF tutorials (bcc-based but concepts apply): [https://github.com/iovisor/bpf-docs](https://github.com/iovisor/bpf-docs)
* Linux kernel docs on eBPF: [https://www.kernel.org/doc/html/latest/bpf/index.html](https://www.kernel.org/doc/html/latest/bpf/index.html)
* Rust cross-compilation guides

---

## 9. **Tips**

* Start simple: write small kprobe or tracepoint programs.
* Use x86\_64 local dev to iterate fast.
* Once stable, test cross-compile and deploy on aarch64 device.
* Use musl for fully static linking if needed.

---
References1:
Refs: https://www.ebpf.top/en/post/ebpf_rust_aya/  
---
# Aya Intro


## Introduction:

- Starting kernel version 6.1 , Rust programming language is been supported in the Linux kernel.
- Rust ( systems programming lanaguge) offers robust compile-time guarantees and precise control over memory
  lifetimes. Its introduction to the kernel brings additional safety measures to the early stages of kernel
  development. 

- eBPF is a technology in the kernel that enables running user-defined programs based on *events, with a
  validator mechanism* ensures security of the eBPF programs running in the kernel.

- Rust and eBPF share common goal to ensure kernel safety, albeit with different focuses. 

- Writing eBPF progs in Rust often involves unsafe memory reads and writes in the kernel, leveraging Rust
  and Aya can provide a fast and efficient development experience. This includes
  * Automatically generating the entire program framework (eBPF program and corresponding user-space code),
    parameter validation, error handling, unified build and management processes and more.

- Aya is a eBPF library focused on operability and developer experience, built entirely on Rust, using only
  the libc package for system calls. 

- Official website for Aya: https://github.com/aya-rs/aya/

- What Aya offers:

    * Management, building and testing of projects using Rust's Cargo tool.
    * Support for direct generating CO-RE bindings with Rust and kernel files.
    * Easy code sharing between user tool code (Rust) and eBPF code running in the kernel.
    * No dependencies on LLVM, libbpf, bcc and like things

## Process of writing eBPF progs and generating user-space programs using Aya.

### setting up Rust development environment.

#### Create a VM virtual machine 


