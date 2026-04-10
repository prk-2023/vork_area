# Introduction into Rust and eBPF with Rust.


Hello everyone, the topic for today's talk is Introduction to Rust, and eBPF with Rust.

C programming language has been around since 50+ years and evolved to be the go-to programming language for
systems programming, as it gives total control over the silicon.

Rust is the first language that gives us the same control but protects us from 'hidden' costs of that
control. 

Rust for Linux is an ongoing project started in 2022 to add Rust as a programming language that can be used
within the Linux kernel software. The project aims to leverage Rust's memory safety to reduce bugs when
writing kernel drivers. 

https://www.youtube.com/watch?v=i8a2alQPw3Y

https://www.phoronix.com/news/Linux-7.0-Driver-Core#:~:text=Kernel%20Drivers%20%2D%20Phoronix-,Linux%207.0%20Driver%20Core%20Changes%20Bring%20More%20Enhancements%20For%20Rust,register%20abstractions%20for%20Rust%20drivers.

- Kernel Maintainer summit in late 2025 the community reached unanimous consensus: Rust is no longer an
  experiment. Which means its going to stay as a part of the Kernel. 

- This shift was largely  driven by Android 16 which shipped Rust-based Kernel components line (`ashmem`
  allocator) in production on millions of devices. Pointing that Rust does not just work in Lab but it works
  in scale. 

- While C remains the primary language for the core kernel, it looks maintainers are not encouraged to
  accept rust for new drivers. 

- Recently one of the projects that caught my eye while studying RDMA: Was a Opensource RealTek PHY driver:
    * RealTek Generic FE-GE PHY driver is a "poster child" for Rust in the kernel.
    * PHY Chip which handled the actual electrical/optical signals on the wire. RealTek Driver is often
      referred to as Reference Driver.
      - It keeps a simple design compared to complex GPU/Disk Drivers. Mostly consisting of reading/writing
        to HW registers. 
      - Safety: Network drivers are a massive attack surface. By writing the RealTek PHY driver in Rust,
        developers eliminate common C bugs like "null pointer deferences" or "buffer overflow" which are
        common targets by hackers to break-in or gain control via the network. 

| Component | Type | Description |
| :--- | :--- | :--- |
| ASIX AX88772A | Network PHY | A common USB-to-Ethernet adapter driver. |
| Realtek Generic | Network PHY | The one you saw; supports various FE-GE chips. |
| rnull | Block Device | A Rust-based replacement for the "null" device used for testing. |
| DRM Panic | Graphics | A utility that displays a QR code during a system crash (Kernel Panic) so you can scan it for debug info. |
| Binder | Android IPC | A Rust rewrite of the critical communication system for Android. |
| Nova | GPU | An ambitious, ongoing project to write a modern NVIDIA driver in Rust. |

- The Standard build for linux kernel has CONFIG_RUST set to `n`, this would skip all the `.rs` files during
  the build process. 
- When Rust becomes mandatory: ( like RealTek PHY ) the rust toolchain is mandatory.
  Setting `CONFIG_REALTEK_RUST_PHY=y` The kernel Kconfig system will automatically force CONFIG_RUST=y. 
  THis requires `rustc` and `bindgen` for building the rust code. 

Toolchain Sandwitch:
|Tool|Purpose|
| :--- | :--- |
|GCC / Clang|Compiles the 95% of the kernel still written in C.|
|rustc|The Rust compiler (currently targeting version 1.85+ as the baseline).|
|bindgen|A critical bridge tool that translates C headers so Rust can understand them.|
|LLVM / LLD|"Most Rust kernel builds prefer the LLVM linker to ensure the C and Rust parts ""glue"" together correctly."|

- Distro Pressure: 
    Debian/Fedora: Even You don't want to install Rust the distros will force :
    Debian 13 and 14: Officially made Rust as hard requirement for many core packages ( like `apt`)

- Kernel build check: To check the machine is ready for modern Bi-lingual world, run the below command
  inside the recent kernel source folder:
  ```bash 
  make LLVM=1 rustavailable
  ```
