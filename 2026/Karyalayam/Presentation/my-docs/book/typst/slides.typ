// ─────────────────────────────────────────────────────────────────────────────
//  Introduction to Rust and eBPF with Rust
//  A Typst/Touying presentation — Metropolis theme
//
//  Build:
//    typst compile slides.typ slides.pdf
//
//  Live preview (Tinymist / VS Code):
//    Install the "Tinymist Typst" VS Code extension, then open this file.
//
//  Dependencies (auto-downloaded by Typst on first compile):
//    @preview/touying:0.7.1
//    @preview/numbly:0.1.0
//
//  Fonts (optional but recommended for the Metropolis look):
//    Fira Sans, Fira Code, Fira Math
//    Install on Ubuntu/Debian: sudo apt install fonts-firacode
//    Or download from https://github.com/mozilla/Fira
//    Typst will fall back gracefully if they are not installed.
// ─────────────────────────────────────────────────────────────────────────────

#import "@preview/touying:0.7.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

// ── Rust brand palette ────────────────────────────────────────────────────────
#let rust-orange   = rgb("#CE422B")  // official Rust logo orange-red
#let rust-dark     = rgb("#1C1C1C")  // near-black for code backgrounds
#let ebpf-teal     = rgb("#0D7377")  // teal accent for eBPF slides
#let ebpf-light    = rgb("#E0F4F5")  // light teal for eBPF callouts
#let kernel-purple = rgb("#4B3B8C")  // kernel subsystem colour
#let note-amber    = rgb("#F5A623")  // callout highlight

// ── Custom utility blocks ─────────────────────────────────────────────────────

// Highlighted callout box  →  #callout[text]
#let callout(body, color: rust-orange) = block(
  fill: color.lighten(88%),
  stroke: (left: 3pt + color),
  inset: (left: 10pt, top: 6pt, bottom: 6pt, right: 8pt),
  radius: (right: 4pt),
  width: 100%,
  body
)

// Two-column layout helper  →  #cols[left][right]
#let cols(left, right, ratio: (1fr, 1fr)) = grid(
  columns: ratio,
  gutter: 1.2em,
  left,
  right,
)

// Inline code pill  →  #c[text]
#let c(body) = raw(body)

// A small "NEW" badge for "Rust is not just systems" slides
#let badge(txt, color: rust-orange) = box(
  fill: color,
  inset: (x: 5pt, y: 2pt),
  radius: 3pt,
  text(fill: white, size: 0.65em, weight: "bold", txt)
)

// ── Presentation theme ────────────────────────────────────────────────────────
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,

  config-colors(
    primary:          rust-orange,
    primary-dark:     rust-orange.darken(20%),
    primary-light:    rust-orange.lighten(60%),
    secondary:        ebpf-teal,
    neutral-lightest: rgb("#FAFAF8"),   // slide background
    neutral-light:    rgb("#EEECEA"),
    neutral-dark:     rgb("#3A3A3A"),
    neutral-darkest:  rgb("#1C1C1C"),
  ),

  config-info(
    title:       [Introduction to Rust and eBPF with Rust],
    subtitle:    [Kernel Safety · Linux Internals · Production Observability],
    author:      [Pulumati Ram],
    date:        datetime.today(),
    institution: [ < RealTek Semiconductor Corporation > ],
  ),
)

// ── Typography ────────────────────────────────────────────────────────────────
#set text(font: ("Fira Sans", "Noto Sans", "Liberation Sans"), size: 20pt)
#show raw:  set text(font: ("Fira Code", "JetBrains Mono", "Courier New"), size: 0.82em)
#show link: set text(fill: rust-orange)

// Section headings use numbly: "1.", "1.1"
#set heading(numbering: numbly("{1}.", default: "1.1"))

// ─────────────────────────────────────────────────────────────────────────────
//  TITLE SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#title-slide()

// ─────────────────────────────────────────────────────────────────────────────
//  OUTLINE
// ─────────────────────────────────────────────────────────────────────────────
== Agenda <touying:hidden>

#outline(title: none, indent: 1.5em, depth: 1)

// ─────────────────────────────────────────────────────────────────────────────
//  PART 1 — THE PROBLEM LANDSCAPE
// ─────────────────────────────────────────────────────────────────────────────
= The Problem Landscape

== Memory safety — the kernel's original sin

#cols[
  *Why we are here*

  - *~67%* of Linux CVEs trace directly to memory safety violations
    #h(0.4em) _(Gaynor & Thomas, Linux Security Summit 2019 — still holds in 2025)_
  - Use-after-free, buffer overflows, data races
  - C gives you the loaded gun; the kernel expects developers not to shoot themselves
  - Cost: CVE triage, backport sprints, OEM escalations, re-spins

  #callout[
    What if the *compiler* proved correctness at patch submission time?
  ]
][
  #align(center)[
    #block(
      fill: rust-dark,
      radius: 6pt,
      inset: 14pt,
      width: 100%,
      text(fill: rgb("#E06C75"), size: 0.75em)[
        ```c
        // Classic UAF — compiles fine in C
        struct mlx5_wq *wq = alloc_wq();
        submit_dma(wq);
        free(wq);           // ← freed here
        read_completion(wq);// ← UAF: crash or silent corruption
        ```
      ]
    )
    #text(size: 0.65em, fill: gray)[
      C: no compile-time safety net
    ]
  ]
]

== The observability gap

#cols[
  *Traditional kernel debug tools*

  - `printk` / `dmesg` — rebuilds required, production noise
  - `ftrace` / `perf` — coarse granularity, hard to correlate
  - GDB attach — impossible on production Android SoCs

  *What we actually need*

  - Per-DMA-transfer latency without kernel rebuild
  - Per-UID network attribution on production Android
  - IRQ storm attribution during bring-up
][
  *eBPF fills the gap*

  - Inject observability at any kernel hook — zero patch required
  - Verifier guarantees: no crash, no infinite loop, no OOB access
  - CO-RE: one binary works across OEM kernel variants

  #callout(color: ebpf-teal)[
    *Rust* solves "write correct code". \
    *eBPF* solves "understand running code". \
    They compose.
  ]
]

== Why now — the 2025 inflection point

#cols[
  *Kernel milestones*

  - Dec 2025, Tokyo Maintainers Summit: #text(fill: rust-orange)[*"zero pushback"*] — experimental label removed, Rust is *core*
  - Android 16 (kernel 6.12): `ashmem` allocator ships in Rust on *millions of devices*
  - 6.13: PCI + platform driver bindings merged — all major subsystems can now accept Rust
  - Kernel 6.19: ~390 Rust source files in-tree
][
  *Regulatory tailwinds*

  - US CISA memory-safety guidance (2024)
  - EU Cyber Resilience Act — memory-safe languages strongly preferred
  - Google mandates Rust for new Android system code

  #callout[
    This is *not* a research topic anymore. \
    It is a *production skill* your team needs in 2025–2026.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  PART 2 — RUST FOR SENIOR ENGINEERS
// ─────────────────────────────────────────────────────────────────────────────
= Rust for Senior Engineers

== Ownership & borrowing — in kernel terms

#cols[
  *The mental model*

  - *Ownership* = single writer. The kernel enforces this socially (take the lock). Rust enforces it *mechanically*.
  - *Borrow checker* ≈ `MutexGuard<T>`: while the guard lives, no other code can touch `T`
  - *Lifetimes* ≈ DMA buffer validity windows — the buffer must outlive the DMA operation

  #callout[
    The rules you already follow in C, now *verified by the compiler at every commit*.
  ]
][
  #block(
    fill: rust-dark,
    radius: 6pt,
    inset: 14pt,
    width: 100%,
    text(fill: rgb("#ABB2BF"), size: 0.72em)[
      ```rust
      // Rust refuses to compile this
      let buf = alloc_dma_buf();
      submit_dma(&buf);
      drop(buf);            // ← freed here
      read_completion(&buf);// ← compile error:
                            //   use of moved value `buf`
      ```
    ]
  )
  #text(size: 0.65em, fill: gray)[
    Rust: UAF caught at *compile time*, not runtime
  ]
]

== Zero-cost abstractions and `no_std`

- *Zero-cost*: higher-level constructs compile to the same machine code as hand-written C — monomorphisation, not vtable dispatch
- Kernel Rust is `#![no_std]` — no stdlib, no OS allocator by default. Uses `core` + a custom `alloc` backed by the kernel's slab allocator
- *No GC, no runtime.* Output is a standard ELF `.ko` — `insmod`, `lsmod`, `rmmod` work identically

#callout[
  What you *lose*: `std::thread`, `std::fs`, `std::net` \
  What you *gain*: `kernel::sync`, `kernel::task`, `kernel::net` — safe wrappers with identical guarantees
]

== `unsafe` — the quarantine model

#cols[
  *Architecture*

  ```
  rust/bindings/     ← raw FFI (unsafe)
                       generated by bindgen
       ↓
  rust/kernel/       ← safe abstractions
                       SpinLock<T>, Mutex<T>,
                       Task, WorkQueue, Net…
       ↓
  drivers/subsystems ← SAFE Rust only
                       direct binding calls
                       are FORBIDDEN
  ```
][
  *Why this matters*

  - `unsafe` is *quarantined* to one layer, reviewed once, audited once
  - Every driver built on top inherits safety for free
  - Audit surface: just `grep -r "unsafe" .` — impossible in C

  #callout[
    All kernel C is implicitly unsafe. \
    In Rust you can *grep* for the dangerous parts.
  ]
]

== Rust concurrency — what it means for SMP drivers

- `Send`: a type can be *moved* to another thread
- `Sync`: a type can be *shared* across threads
- These are *compile-time traits* — verified before the module loads

#cols[
  ```rust
  // kernel::sync::SpinLock<T>
  let guard = my_spinlock.lock();
  // Only accessible through guard:
  guard.field = value;
  // Compiler: cannot access `my_spinlock.field`
  //           without holding the lock
  drop(guard); // lock released
  ```
][
  #callout[
    *"Forgot to take the lock"* bugs become compile errors. \
    Interrupt handler data sharing races are caught *before* bring-up.
  ]

  This is the highest-value safety guarantee for SoC DMA engine and IRQ handler development.
]

// ─────────────────────────────────────────────────────────────────────────────
//  PART 3 — RUST IN THE LINUX KERNEL
// ─────────────────────────────────────────────────────────────────────────────
= Rust in the Linux Kernel

== Kernel Rust architecture

#cols(ratio: (1.1fr, 0.9fr))[
  *Three-layer stack*

  ```
  ┌─────────────────────────────────┐
  │  Driver / subsystem code        │  ← Safe Rust only
  │  e.g. mlx5, ashmem, nova        │
  ├─────────────────────────────────┤
  │  rust/kernel/ (abstractions)    │  ← Safe wrappers
  │  Mutex, SpinLock, Task,         │
  │  WorkQueue, Net, IRQ…           │
  ├─────────────────────────────────┤
  │  rust/bindings/ (raw FFI)       │  ← unsafe, auto-generated
  │  generated by bindgen           │    reviewed once
  ├─────────────────────────────────┤
  │  rust/helpers/ (C stubs)        │  ← inline fns bindgen
  │  wraps inline C macros          │    cannot parse
  └─────────────────────────────────┘
  ```
][
  *Key toolchain roles*

  #table(
    columns: (auto, 1fr),
    stroke: none,
    inset: (y: 5pt),
    [*`bindgen`*],   [C headers → Rust FFI],
    [*`pahole`*],    [DWARF → BTF (CO-RE)],
    [*`rust-analyzer`*], [LSP: `make LLVM=1 rust-analyzer`],
    [*`rustdoc`*],   [`make LLVM=1 rustdoc`],
    [*`clippy`*],    [Rust linter (replaces sparse)],
    [*`rustfmt`*],   [Auto-formatter],
  )

  #callout[
    `make LLVM=1 rustavailable` \
    diagnoses your entire setup in one command.
  ]
]

== Subsystem status map

#cols[
  *Production / upstreamed*

  - #text(fill: rgb("#2ECC71"))[●] *Asahi* (Apple Silicon DRM) — entirely Rust
  - #text(fill: rgb("#2ECC71"))[●] *Nova* (open NVIDIA DRM) — Rust from day one
  - #text(fill: rgb("#2ECC71"))[●] *Android Binder* — Rust rewrite, IPC UAF bugs eliminated
  - #text(fill: rgb("#2ECC71"))[●] *ashmem allocator* — Android 16 / kernel 6.12, ships on millions of devices
  - #text(fill: rgb("#F39C12"))[●] *NVMe* — PCI abstractions upstream (6.13+)
  - #text(fill: rgb("#F39C12"))[●] *Networking* — `kernel::net` partial, `sk_buff` in progress
][
  *Frontier*

  - #text(fill: rgb("#E74C3C"))[●] Filesystems — no major Rust FS yet; VFS abstractions under development
  - #text(fill: rgb("#F39C12"))[●] RDMA / mlx5 — active community work, not yet upstream

  *For IC design houses*

  - PCI + platform driver bindings are upstream → all new peripheral drivers can target Rust now
  - GPU drivers (Asahi/Nova) are the largest real-world Rust kernel codebases to study
]

== Hello World kernel module — annotated

#block(
  fill: rust-dark,
  radius: 6pt,
  inset: 14pt,
  width: 100%,
  text(fill: rgb("#ABB2BF"), size: 0.72em)[
    ```rust
    // SPDX-License-Identifier: GPL-2.0
    use kernel::prelude::*;

    module! {                      // ← replaces MODULE_AUTHOR/LICENSE/etc.
        type: HelloWorld,
        name: "rust_helloworld",
        license: "GPL",
    }

    struct HelloWorld;

    impl kernel::Module for HelloWorld {
        fn init(_: &'static ThisModule) -> Result<Self> {   // ← called by insmod
            pr_info!("Hello, Rust kernel world! (init)\n");
            Ok(HelloWorld)
        }
    }

    impl Drop for HelloWorld {     // ← called by rmmod — RAII, compiler guaranteed
        fn drop(&mut self) {
            pr_info!("Hello, Rust kernel world! (exit)\n");
        }
    }
    ```
  ]
)

#callout[
  No `module_init` / `module_exit`. *`Drop` guarantees cleanup* runs — the compiler verifies it. C cannot make this guarantee.
]

== Benefits vs hardships — honest assessment

#cols[
  *Real wins*

  - Compiler-verified locking discipline — no "forgot to unlock on error path"
  - RAII cleanup — teardown in the correct order, guaranteed
  - CVE reduction: Greg Kroah-Hartman — "drivers in Rust are proving safer than C equivalents"
  - Easier refactoring — blast radius of struct changes surfaced at compile time
  - Attracts modern systems developers to the kernel community
][
  *Real friction*

  - Toolchain pinned per kernel release — can't `rustup update` freely
  - Kernel has no stable internal API — bindings track C-side changes
  - Binding coverage lags full C surface area
  - Some maintainers still resistant — patch velocity varies by subsystem
  - Dual-language CI burden: two compilers, two sanitizer configs
  - GCC Rust (`gccrs`) not yet production-ready for in-kernel use
]

// ─────────────────────────────────────────────────────────────────────────────
//  PART 4 — eBPF FUNDAMENTALS
// ─────────────────────────────────────────────────────────────────────────────
= eBPF Fundamentals

== What eBPF is — and what it is not

#cols[
  *The model*

  1. Userspace writes BPF bytecode (C or Rust)
  2. Kernel *verifier* proves safety:
     - Bounded loops (DAG)
     - No OOB memory access
     - Register type tracking
  3. JIT compiles to native machine code
  4. Attaches to a *hook point*
  5. Communicates via *BPF maps*

  #callout(color: ebpf-teal)[
    If the verifier accepts it, the program *cannot* crash the kernel. This is a *formal proof*, not a heuristic.
  ]
][
  *Key hook types for IC/Android work*

  #table(
    columns: (auto, 1fr),
    stroke: none,
    inset: (y: 4pt),
    [`kprobe`],      [any kernel function entry],
    [`kretprobe`],   [any kernel function return],
    [`tracepoint`],  [stable kernel trace points],
    [`perf_event`],  [hardware PMU counters],
    [`xdp`],         [NIC fast path (pre-stack)],
    [`lsm`],         [LSM security hooks],
    [`cgroup_skb`],  [per-cgroup network policy],
    [`tp_btf`],      [typed tracepoints (CO-RE)],
  )
]

== BPF maps — the data bridge

#cols[
  *Maps = the only I/O channel for BPF programs*

  #table(
    columns: (1fr, 1fr),
    stroke: (x: none, y: 0.4pt + gray),
    inset: (y: 5pt),
    [*Type*], [*Use case*],
    [`HASH`], [key-value lookup],
    [`RINGBUF`], [high-throughput event stream ✓],
    [`PERCPU_ARRAY`], [per-CPU stats, lock-free],
    [`LRU_HASH`], [connection tracking],
    [`ARRAY`], [fixed-size indexed data],
    [`PERF_EVENT_ARRAY`], [legacy event pipe],
  )
][
  *Why `RINGBUF` is preferred (kernel 5.8+)*

  - Single contiguous memory region — fewer cache misses
  - Variable-length entries — no waste
  - Epoll / `AsyncFd` compatible — Tokio-friendly
  - Dropped-event counter exposed to userspace

  #callout(color: ebpf-teal)[
    The ring buffer is how our *DMA latency tracer* sends events to userspace — zero copy, epoll-driven.
  ]
]

== CO-RE: Compile Once, Run Everywhere

#cols[
  *The Android kernel fragmentation problem*

  ```
  OEM A: kernel 5.10  struct task_struct { … offset 0x2C8 … }
  OEM B: kernel 6.1   struct task_struct { … offset 0x2D0 … }
  OEM C: kernel 6.6   struct task_struct { … offset 0x2E0 … }
  ```

  A BPF program compiled against one version *silently reads wrong memory* on another.

  #callout(color: ebpf-teal)[
    *CO-RE solution*: emit relocation records at compile time, patch them at *load time* using BTF from the running kernel.
  ]
][
  *How it works*

  ```
  BPF source (.c / .rs)
      │  __builtin_preserve_access_index()
      │  → emits relocation records into ELF
      ↓
  BPF ELF object
      │  libbpf / Aya reads kernel BTF
      │  → patches field offsets at load time
      ↓
  Runs correctly on any BTF-enabled kernel
  ```

  *BTF requirement*: `CONFIG_DEBUG_INFO_BTF=y`

  *pahole note*: when Rust + BTF are both enabled, pahole must support `--lang-exclude=rust` to exclude Rust DWARF from BTF generation.
]

== eBPF tooling landscape

#cols[
  *C-based ecosystem (current standard)*

  - *`libbpf`* — canonical C loader. Used by Android kernel team, bpftool, bpftrace
  - *`bpftool`* — inspect programs, dump maps, generate skeletons, introspect BTF
  - *`bpftrace`* — one-liner DTrace-like frontend:
    ```bash
    bpftrace -e \
      'kprobe:dma_map_sg {
         @[comm] = count();
       }'
    ```

  *Limitation*: no type safety at the userspace/kernel boundary — map struct mismatch = silent data corruption
][
  *Where Rust (Aya) enters*

  - *`aya`* — pure-Rust reimplementation of libbpf. No libelf.so dependency → ideal for static Android binaries
  - *`libbpf-rs`* — Rust bindings to C libbpf (alternative)
  - *`redbpf`* — older Rust framework (less active)

  #callout(color: ebpf-teal)[
    Aya compiles the BPF program *and* the userspace loader *both* in Rust. One language, one toolchain, type-safe boundary.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  PART 5 — eBPF WITH RUST (AYA)
// ─────────────────────────────────────────────────────────────────────────────
= eBPF with Rust — Aya Framework

== Why Rust for eBPF — the type-safety argument

#cols[
  *The C eBPF boundary problem*

  ```c
  // kernel-side BPF program (C)
  struct dma_event {
      u64 latency_ns;
      u32 nents;      // ← defined here
  };
  bpf_ringbuf_output(&events, &ev, sizeof(ev), 0);

  // userspace loader (C) — separate file
  struct dma_event {
      u64 latency_ns;
      u32 pid;        // ← different field!
      u32 nents;      //   off-by-one silently
  };
  ```

  *Result*: reads wrong field, no compiler error, no runtime error — just wrong numbers.
][
  *Aya solution: shared Rust crate*

  ```rust
  // dma-latency-tracer-common/src/lib.rs
  // compiled for BOTH bpfel-unknown-none AND host
  #[repr(C)]
  pub struct DmaEvent {
      pub latency_ns: u64,
      pub nents:      u32,
      pub pid:        u32,
  }
  ```

  The *same type* is imported by the BPF program and the userspace loader. Layout disagreement is a *compile error*, not a runtime bug.

  #callout[
    This is the highest-leverage safety property of Aya for production DMA tracers.
  ]
]

== Aya workspace structure

#cols[
  *Three-crate layout (no xtask needed)*

  ```
  dma-latency-tracer/
  ├── Cargo.toml              ← workspace root
  ├── rust-toolchain.toml     ← pins nightly
  │
  ├── dma-latency-tracer-common/
  │   └── src/lib.rs          ← #[no_std] shared types
  │                             DmaEvent, histogram buckets
  │
  ├── dma-latency-tracer-ebpf/
  │   ├── .cargo/config.toml  ← target=bpfel-unknown-none
  │   └── src/main.rs         ← kprobe + kretprobe programs
  │
  └── dma-latency-tracer/     ← userspace loader
      ├── build.rs  ← KEY     ← cross-compiles eBPF,
      │                         copies to $OUT_DIR
      └── src/main.rs         ← loads BPF, reads ringbuf,
                                prints histogram
  ```
][
  *Why `build.rs` instead of `xtask`?*

  - xtask requires two separate commands: `cargo xtask build-ebpf && cargo build`
  - `build.rs` makes *`cargo build` alone* sufficient
  - eBPF compilation is a *dependency* of the host binary — Cargo's incremental rebuild logic applies

  ```rust
  // dma-latency-tracer/build.rs (key part)
  Command::new(&cargo)
      .arg("+nightly")
      .arg("build")
      .arg("--package").arg("dma-latency-tracer-ebpf")
      .arg("--target").arg("bpfel-unknown-none")
      .arg("-Z").arg("build-std=core")
      .status()?;
  ```

  #callout[
    The compiled BPF ELF is *embedded* into the userspace binary via `include_bytes_aligned!` — ships as a single binary.
  ]
]

== DMA latency tracer — eBPF program anatomy

#block(
  fill: rust-dark,
  radius: 6pt,
  inset: 12pt,
  width: 100%,
  text(fill: rgb("#ABB2BF"), size: 0.70em)[
    ```rust
    // Maps — declared at crate level, visible to the kernel
    #[map] static START_MAP: HashMap<u64, EntryData> =
        HashMap::with_max_entries(4096, 0);   // key = cpu<<32 | pid

    #[map] static EVENTS: RingBuf =
        RingBuf::with_byte_size(4 * 1024 * 1024, 0);  // 4 MiB ring

    #[kprobe]                                // ← entry probe
    pub fn dma_map_sg_enter(ctx: ProbeContext) -> u32 {
        let nents: i32 = unsafe { ctx.arg(2).ok_or(1i64)? };
        let key = ((cpu as u64) << 32) | (pid as u64);
        START_MAP.insert(&key, &EntryData { start_ns, nents, … }, 0)?;
        Ok(0)
    }

    #[kretprobe]                             // ← return probe
    pub fn dma_map_sg_exit(ctx: RetProbeContext) -> u32 {
        let end_ns = bpf_ktime_get_ns();
        let entry  = START_MAP.get(&key).ok_or(3i64)?;
        let latency_ns = end_ns - entry.start_ns;
        // Reserve + fill + submit to ring buffer
        let mut buf = EVENTS.reserve::<DmaEvent>(0).ok_or(4i64)?;
        unsafe { (*buf.as_mut_ptr()).latency_ns = latency_ns; }
        buf.submit(0);
    }
    ```
  ]
)

== ConnectX-5 + PCIe Gen 3 — test setup

#cols[
  *Physical topology*

  ```
  ┌─────────────────────────────────────┐
  │  Host (PCIe Gen 3.0 x16 slot)       │
  │                                     │
  │  ┌────────────────────────────────┐ │
  │  │  ConnectX-5 100GbE (PCIe Gen4) │ │
  │  │  Port 0 (enp6s0f0) ──╮         │ │
  │  │  Port 1 (enp6s0f1) ──╯ DAC     │ │
  │  └────────────────────────────────┘ │
  └─────────────────────────────────────┘

  ns0 ─── Port 0 ─── [DAC cable] ─── Port 1 ─── ns1
   192.168.100.1                       192.168.100.2
  ```

  Card links at *Gen 3 speed* (limited by host slot). Namespaces force traffic through the *physical medium* — no loopback shortcut.
][
  *DMA latency expectations at Gen 3*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray),
    inset: (y: 5pt),
    [*Range*], [*Interpretation*],
    [< 2 µs],  [IOMMU TLB warm — normal path ✓],
    [2–10 µs], [Mild TLB pressure or NUMA miss],
    [10–50 µs],[IOMMU TLB miss (page walk)],
    [> 50 µs], [C-states / CPU frequency scaling],
  )

  #callout(color: ebpf-teal)[
    PCIe Gen4→Gen3 halves *bandwidth* but does not increase DMA latency for individual SG operations. Latency is dominated by IOMMU + NUMA.
  ]
]

== Sample output — latency histogram

#block(
  fill: rust-dark,
  radius: 6pt,
  inset: 12pt,
  width: 100%,
  text(fill: rgb("#ABB2BF"), size: 0.68em)[
    ```
    ═══════════════════════════════════════════════════════════════════
      dma_map_sg latency histogram  (total events: 48 291)
      System: ConnectX-5 PCIe Gen4 card | Gen3 host slot | DAC crossover
    ───────────────────────────────────────────────────────────────────
                range    count       %   dist
          0 – 500 ns      2134    4.42%  |████░░░░░░░░░░░░░░░░░░░░░░░░░░|
         500 ns – 1µs     5891   12.20%  |████████████░░░░░░░░░░░░░░░░░░|
           1 – 2 µs      18432   38.17%  |██████████████████████████████|  ← peak
           2 – 3 µs      14201   29.41%  |███████████████████████░░░░░░░|
           3 – 5 µs       5912   12.24%  |████████████░░░░░░░░░░░░░░░░░░|
         5 – 7.5 µs       1102    2.28%  |██░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
        7.5 – 10 µs        401    0.83%  |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
    ───────────────────────────────────────────────────────────────────
      Fast (< 2 µs): 26457 (54.8%)  — IOMMU TLB warm ✓
      Slow (> 30µs):    38  (0.1%)  — check C-states / IOMMU pressure
    ───────────────────────────────────────────────────────────────────
       pid  comm               count    avg µs    min µs    max µs
     12345  iperf3             48291     1.923     0.312    87.441
    ```
  ]
)

// ─────────────────────────────────────────────────────────────────────────────
//  PART 6 — RUST BEYOND KERNEL & SYSTEMS
// ─────────────────────────────────────────────────────────────────────────────
= Rust Beyond Kernel & Systems

== Rust is reshaping the *entire* toolchain

#align(center)[
  #callout[
    *Typst* — the tool that generated these slides — is written entirely in Rust. #badge("NEW")
  ]
]

#cols[
  *Document & typesetting*
  - *Typst* — next-gen LaTeX replacement. Millisecond compile times. Written in Rust.
  - *mdBook* — Rust documentation standard (The Rust Book, eBPF Book)

  *Web & networking*
  - *Cloudflare Workers* — Rust WASM at the edge
  - *Pingora* — Cloudflare's Nginx replacement in Rust (1 trillion requests/day)
  - *Axum* / *Actix-web* — high-performance web frameworks
][
  *Compiler & language tooling*
  - *swc* — TypeScript/JS compiler (Rust, 70× faster than Babel)
  - *Ruff* — Python linter (Rust, 10–100× faster than pylint/flake8)
  - *uv* — Python package manager (Rust, replaces pip)
  - *OXC* — JavaScript toolchain in Rust

  *Databases & storage*
  - *TiKV* — distributed KV store (Rust, used by TiDB)
  - *Surrealdb* — multi-model database in Rust
  - *Glommio* — io_uring async I/O for storage engines
]

== Rust in operating systems beyond Linux

#cols[
  *OS kernels*
  - *Redox OS* — microkernel written fully in Rust
  - *Theseus OS* — research OS, safe inter-component isolation
  - *Hubris* (Oxide Computer) — embedded RTOS in Rust
  - *r9* — Plan 9-inspired Rust kernel

  *Firmware & embedded*
  - *Embassy* — async embedded Rust framework (replaces RTOS for many use cases)
  - *TOCK OS* — secure embedded OS in Rust (used in Google Titan chips)
  - *Rust for UEFI* — UEFI firmware modules in Rust
][
  *Cloud & hypervisors*
  - *Firecracker* (AWS) — microVM hypervisor powering AWS Lambda, written in Rust
  - *Cloud Hypervisor* (Intel/Microsoft) — VMM in Rust
  - *crosvm* (Google) — ChromeOS VM monitor in Rust
  - *Kata Containers* runtime in Rust

  #callout[
    Every layer of the stack — firmware, hypervisor, OS, toolchain, web server — now has a serious Rust implementation.
  ]
]

== The Rust ecosystem for IC teams — a map

#cols(ratio: (1fr, 1fr))[
  *Development tools you already use (or should)*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray),
    inset: (y: 4pt),
    [*cargo*],    [unified build, test, bench, publish],
    [*clippy*],   [linter — replaces Coccinelle/sparse for Rust],
    [*rustfmt*],  [auto-formatter — no more style debates],
    [*rustdoc*],  [doc generation from source comments],
    [*miri*],     [UB detector — runs Rust under an interpreter],
    [*cargo-fuzz*],[coverage-guided fuzzing, libFuzzer backend],
    [*cargo-deny*],[license + CVE audit for dependencies],
  )
][
  *The IC driver development pipeline*

  ```
  Write driver (.rs)
       │
       ▼
  cargo clippy       ← linting (= sparse + Coccinelle)
       │
       ▼
  cargo test         ← unit tests (no VM needed)
       │
       ▼
  make LLVM=1        ← kernel build + bindgen
       │
       ▼
  miri / KASAN       ← UB / memory error detection
       │
       ▼
  Submit patch       ← Rust: compiler pre-validated it
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  PART 6 — SYNTHESIS & ROADMAP
// ─────────────────────────────────────────────────────────────────────────────
= Synthesis & Roadmap

== The full picture — Rust + eBPF together

#align(center)[
  #grid(
    columns: (1fr, 0.15fr, 1fr),
    gutter: 0pt,

    block(
      fill: rust-orange.lighten(88%),
      stroke: 2pt + rust-orange,
      radius: 8pt, inset: 16pt, width: 100%,
      align(center)[
        *Rust in the kernel* \
        #v(6pt)
        Correct code at write time \
        Compiler-verified safety \
        Memory-safe drivers \
        RAII cleanup guarantees
      ]
    ),

    align(center + horizon)[
      #text(size: 2em, fill: gray)[+]
    ],

    block(
      fill: ebpf-teal.lighten(88%),
      stroke: 2pt + ebpf-teal,
      radius: 8pt, inset: 16pt, width: 100%,
      align(center)[
        *eBPF with Aya* \
        #v(6pt)
        Observable code at run time \
        Verifier-proven safety \
        Production tracing \
        CO-RE portability across OEMs
      ]
    ),
  )
]

#v(1em)
#callout[
  *One-line summary for leadership*: "Rust gives us correctness guarantees the C compiler cannot. eBPF gives us production observability without source code changes. Together they reduce our security exposure and debug cycle time."
]

== Team adoption roadmap — 12 months

#cols[
  *Phase 1 — Foundation (M1–3)*

  - Form Rust guild: 3–5 dedicated engineers
  - `make LLVM=1 rustavailable` — set up every dev machine
  - Complete `samples/rust/` exercises in-tree
  - Deploy Aya "hello kprobe" on first development board

  *Phase 2 — First wins (M3–6)*

  - Shadow a C driver in Rust (GPIO / I2C adapter)
  - Deploy Aya power-profiling tool to Android dev board
  - Measure: CVEs caught, debug-cycle time saved
  - Generate credibility data for leadership
][
  *Phase 3 — Production (M6–12)*

  - First *greenfield peripheral driver* written in Rust from day one
  - Aya diagnostic suite as a *product deliverable* alongside next SoC SDK
  - Consider upstream submission for community visibility and OEM signalling

  *Regulatory note*

  - CISA memory-safety guidance + EU CRA both require memory-safe languages in critical software
  - Rust kernel drivers are a *concrete security posture argument* to OEM customers

  #callout[
    BSP suppliers who can deliver Rust-capable drivers will have an advantage in 2026 RFQs.
  ]
]

== Anticipated hard questions

#cols[
  *"Why not better C static analysis?"*

  Coverity/sparse/Coccinelle are heuristics. Rust's ownership checker is a *formal proof at every compile*. The question is about guarantees, not detection rates.

  *"What about GCC Rust (gccrs)?"*

  Active development, important for architectures where LLVM support is weak. Not production-ready for in-kernel work yet. Track it for embedded SoC targets.

  *"Is the eBPF verifier formally verified?"*

  Not yet (active research: Jitterbug, Serval). Verifier has had bugs. For security-critical deployments, pair with LSM hooks and `CAP_BPF` restrictions.
][
  *"GPL implications for Rust modules?"*

  Same as C. Modules must be GPL-2.0 to use GPL-exported kernel symbols. Aya userspace programs are Apache-2.0/MIT — no issue there.

  *"Compile time?"*

  Yes, Rust compiles slower than C. Incremental builds help significantly. For CI pipelines, offset this against fewer debug cycles downstream.

  *"Who maintains Rust drivers long-term?"*

  Miguel Ojeda leads Rust-for-Linux. Google, Red Hat, Collabora all have full-time engineers dedicated to it. The 2025 summit decision signals long-term commitment.
]

// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *Rust is not just a systems language.*

  It is reshaping every layer of the stack —
  from kernel drivers to the tool that compiled these slides.

  The question is not _whether_ to adopt it.
  The question is _how fast_.
]

// ─────────────────────────────────────────────────────────────────────────────
//  APPENDIX / BACKUP SLIDES
// ─────────────────────────────────────────────────────────────────────────────
= Appendix <touying:hidden>

== Build and run the DMA tracer

```bash
# Prerequisites
rustup toolchain install nightly --component rust-src
cargo install bpf-linker          # uses host LLVM via rustup

# Build (one command — no xtask needed)
cargo build

# Network namespace setup (ConnectX-5 crossover DAC)
sudo ip netns add ns0 && sudo ip netns add ns1
sudo ip link set enp6s0f0 netns ns0
sudo ip link set enp6s0f1 netns ns1
sudo ip netns exec ns0 ip addr add 192.168.100.1/24 dev enp6s0f0
sudo ip netns exec ns1 ip addr add 192.168.100.2/24 dev enp6s0f1

# Generate traffic through the DAC cable
sudo ip netns exec ns0 iperf3 -s &
sudo ip netns exec ns1 iperf3 -c 192.168.100.1 -t 120 -P 8

# Run the tracer (root required for CAP_BPF)
sudo RUST_LOG=info cargo run -- --interval 5 --filter-comm iperf3
```

== pahole + BTF + Rust interaction

When both `CONFIG_DEBUG_INFO_BTF=y` and `CONFIG_RUST=y` are set in the same kernel build:

- pahole must support `--lang-exclude=rust` to strip Rust DWARF before generating BTF
- This prevents Rust's DWARF info from polluting the BTF map used by CO-RE BPF programs
- Check: `pahole --version` → requires pahole v1.24+
- Kernel Kconfig guard: `PAHOLE_HAS_LANG_EXCLUDE` — if this is not set and BTF is enabled, `CONFIG_RUST` will be blocked

```bash
# Verify pahole version and capability
pahole --version
pahole --help 2>&1 | grep lang-exclude
```

This is a common "silent gotcha" for teams enabling Rust in a kernel that was already using eBPF CO-RE tracing.

== Rust toolchain pinning — why and how

The kernel requires a specific `rustc` version because it uses unstable compiler features (e.g. `core_ffi_c`, `allocator_api`). Using a newer compiler may break compilation.

```bash
# The kernel tells you exactly which version it needs
cat scripts/min-tool-version.sh | grep rustc

# Pin it for this directory only
rustup override set $(scripts/min-tool-version.sh rustc)

# Verify
rustc --version
# rustc 1.XX.0-nightly (xxxxxxxxx YYYY-MM-DD)
```

This is managed automatically when using the workspace `rust-toolchain.toml` file provided with the DMA tracer project.
