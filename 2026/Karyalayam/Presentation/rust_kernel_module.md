# Rust kernel module:


- Select a distro that is friendly with Rust  Fedora/Debian 13+ 

- **Fedora 43**, has been one of the most aggressive distros in packaging the Rust-for-Linux toolchain.

- Things to keep in mind: Kernel has no std lib so the rust code must be `no_std`. And you must use the
  kernel crate. 

- So Building a "Hello World" in the kernel is different than a standard Rust app.

- Its also important to note that We can not use Cargo to directly build kernel modules directly, since
  Linux kernel is its own "special world" that Cargo doesn't fully understand out of the box. 

> 1. The "C Glue" Problem: Every time the kernel updates, the C headers (the "rules of the road") change.
>    The The kernel's Kbuild (the Makefile system) handles the complex job of running bindgen to translate
>    those C rules into something Rust can read. Cargo doesn't know how to look at your specific Fedora
>    Kernel's headers to do this.
> 2. Compiler Flags: The kernel requires very specific, "dangerous" compiler flags (like -mno-red-zone or
>    -fno-common) to prevent the code from crashing the CPU. Cargo doesn't know these by default.


### 1. The "Hello World" Code
Create a file named `hello_rust.rs`. Note that we use a macro to define the module metadata, similar to how it's done in C.

```rust
//! A simple Hello World kernel module in Rust.

use kernel::prelude::*;

module! {
    type: HelloRust,
    name: "hello_rust",
    author: "Your Name",
    description: "My first Rust kernel module",
    license: "GPL",
}

struct HelloRust;

impl kernel::Module for HelloRust {
    fn init(_module: &'static InternalModule) -> Result<Self> {
        pr_info!("Hello from Rust! The Fedora kernel is now memory-safe.\n");
        Ok(HelloRust)
    }
}

impl Drop for HelloRust {
    fn drop(&mut self) {
        pr_info!("Goodbye from Rust! Module unloaded.\n");
    }
}
```

---

### 2. Prepare Your Fedora Environment
Fedora provides a specific "toolset" for kernel development. You'll need the headers and the specialized Rust compilers.

```bash
# Install the necessary build tools
sudo dnf install kernel-devel-$(uname -r) rust-src make gcc clang bindgen lld 
```
Check the Kernel is configured to support rust, also check `rustc` version kernel was build with, match with
the rustc version on the development system.
```bash
$ zgrep CONFIG_RUST /proc/config.gz || grep CONFIG_RUST /boot/config-$(uname -r)
gzip: /proc/config.gz: No such file or directory
CONFIG_RUSTC_VERSION=109301
CONFIG_RUST_IS_AVAILABLE=y
CONFIG_RUSTC_LLVM_VERSION=210108
CONFIG_RUSTC_HAS_COERCE_POINTEE=y
CONFIG_RUSTC_HAS_SPAN_FILE=y
CONFIG_RUSTC_HAS_UNNECESSARY_TRANSMUTES=y
CONFIG_RUSTC_HAS_FILE_WITH_NUL=y
CONFIG_RUSTC_HAS_FILE_AS_C_STR=y
CONFIG_RUST=y
CONFIG_RUSTC_VERSION_TEXT="rustc 1.93.1 (01f6ddf75 2026-02-11) (Fedora 1.93.1-1.fc43)"
CONFIG_RUST_FW_LOADER_ABSTRACTIONS=y
CONFIG_RUST_PHYLIB_ABSTRACTIONS=y
# CONFIG_RUST_BITMAP_HARDENED is not set
# CONFIG_RUST_DEBUG_ASSERTIONS is not set
CONFIG_RUST_OVERFLOW_CHECKS=y
# CONFIG_RUST_BUILD_ASSERT_ALLOW is not set
```

To verify your system is ready to compile Rust for the kernel:
```bash
make -C /lib/modules/$(uname -r)/build LLVM=1 rustavailable
```
*If this returns "Rust is available," you are good to go.*

---

### 3. The Makefile
Kernel modules require a specific `Makefile` structure to link correctly with the existing kernel headers.

Create a file named `Makefile`:
```makefile
obj-m := hello_rust.o

# Point to your current kernel build directory
KDIR := /lib/modules/$(uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) LLVM=1 modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
```

---

### 4. Build and Test
Now, run the following commands in your terminal:

**Step 1: Compile**
```bash
make
```
This will produce a file named `hello_rust.ko` (the Kernel Object).

**Step 2: Load the Module**
```bash
sudo insmod hello_rust.ko
```

**Step 3: Check the Output**
Check the kernel ring buffer to see your message.
```bash
dmesg | tail -n 1
# Output should be: [ 1234.56] Hello from Rust! The Fedora kernel is now memory-safe.
```

**Step 4: Unload the Module**
```bash
sudo rmmod hello_rust
dmesg | tail -n 1
# Output should be: [ 1235.10] Goodbye from Rust! Module unloaded.
```



### A Quick Note on LLVM
In the commands above, I used `LLVM=1`. This is because, as of 2026, the Rust-to-C "bridge" (bindgen) and the Rust compiler itself rely heavily on the LLVM infrastructure. While you *can* use GCC, using the LLVM toolchain for both the C and Rust parts usually results in a much smoother build experience on Fedora.

Does the `module!` macro look familiar to you from C development, or do you want to dive into why we use `impl Drop` instead of an `exit` function?
