// Import presentation template 

#import "./vivarta.typ": *

// Global Configuration  for the presentations:
#show: doc => setup-presentation(
  title: [Introduction to Rust & eBPF with Rust],
  author: [PukunatiRam],
  institution: [ Realtek SemiConductor Corporation ],
  doc
)


// Focus Slide ( using specialized Metropolis layout for Big, centered text .. )
#hero-slide(
  img: "./imgs/realtek_icons.png",
  topic-title: " Introduction to Rust & eBPF with Rust ",
  topic-subtitle: "[ Pulumati Ram ]"
)
// Render the automatic title slide based on vivarta::config-info
#title-slide()


// ToC:
== Agenda <touying:hidden>
#outline(title: none, indent: 1.5em, depth: 1)

// Top level heading: (=) to Create a section divider slide in Metropolis:

= eBPF: Quick Refresher: (Part #2)

== What is eBPF: 
#cols[
  *The model in one sentence*

  eBPF lets you load user-supplied programs into the kernel *without a kernel patch, without a module, and without rebooting*, the kernel verifier guarantees safety, the programs are attached to *hook points* allowing them to execute efficiently when those events occur.

  *The four-step contract*

  1. *Write* — BPF bytecode (from C or Rust source)
  2. *Verify* — kernel verifier: bounded loops, no OOB, type-checked
  3. *JIT* — native machine code; zero interpreter overhead after load
  4. *Attach* — hook point (kprobe, tracepoint, XDP, LSM, …) fires on event

  #callout[
    If the verifier accepts the program, it *cannot* crash the kernel, infinite-loop, or access out-of-bounds memory. This is a formal proof, not a heuristic.
  ]
][
  #image("./imgs/eBPF-fw.png",height:55%)
  
  *Hook types your team uses*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(220)),
    inset: (y: 5pt),
    [`kprobe` / `kretprobe`], [any kernel function entry/return],
    [`tracepoint`], [stable kernel trace points],
    [`tp_btf`], [typed tracepoints — CO-RE friendly],
    [`perf_event`], [hardware PMU counters],
    [`xdp`], [NIC fast path — pre network stack],
    [`lsm`], [Linux Security Module hooks],
    [`cgroup_skb`], [per-cgroup packet filtering],
    [`raw_tp`], [raw tracepoints — lowest overhead],
  )
]

== eBPF maps — the data bridge

#cols[
  *Maps = the only I/O channel for BPF programs*

  - Shared memory between kernel BPF code and userspace reader
  - Created by the loader before the program is attached
  - Accessed from both sides via file descriptors

  #table(
    columns: (1fr, 1fr),
    stroke: (x: none, y: 0.3pt + luma(220)),
    inset: (y: 4pt),
    [*Type*], [*Typical use*],
    [`HASH`], [key → value lookup],
    [`RINGBUF`], [high-throughput event stream ✓],
    [`PERCPU_ARRAY`], [per-CPU stats, lock-free],
    [`LRU_HASH`], [connection tracking],
    [`PERF_EVENT_ARRAY`], [legacy event pipe],
    [`ARRAY`], [fixed-size indexed data],
  )
][
  *Ring buffer — the preferred choice*

  #ref-badge[Introduced: Linux 5.8 — BPF_MAP_TYPE_RINGBUF]

  - Variable-length records — no fixed-size overhead
  - Single contiguous allocation — cache-friendly
  - `epoll` / `AsyncFd` compatible — Tokio-native in Aya
  - Dropped-event counter exposed to userspace for monitoring
  - *In Aya*: `#[map] static EVENTS: RingBuf = RingBuf::with_byte_size(4 * 1024 * 1024, 0);`

  #callout[
    Prefer `RINGBUF` over `PERF_EVENT_ARRAY` for all new work — lower overhead, simpler consumer, no per-CPU complexity.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. eBPF FRAMEWORK LANDSCAPE
// ─────────────────────────────────────────────────────────────────────────────
= eBPF Framework Landscape

== Three generations of eBPF development

#cols[
  *Generation 1 — BCC (BPF Compiler Collection)*
  #ref-badge("BCC") #ref-badge("Python front-end") #ref-badge("bpftrace")

  - BCC embeds a full *Clang/LLVM at runtime* on the target — compiles BPF C to bytecode when the script runs
  - `bpftrace`: DTrace-style one-liners — ideal for ad-hoc investigation:

    `bpftrace -e 'kprobe:dma_map_sg { @[comm] = count(); }'`
  - *Problems for production / embedded targets*:
    - LLVM + kernel headers required on every target system
    - A 100 MB toolchain runtime on a BSP is untenable
    - Programs depend on exact kernel header versions — not portable

  #callout(color: warn-amber)[
    BCC/bpftrace are *development tools*, not deployment solutions. They require the full build toolchain on the production target.
  ]
][
  *Generation 2 — libbpf + CO-RE*
  #ref-badge("libbpf") #ref-badge("CO-RE") #ref-badge("BTF")

  - Compile *once*, run on *any kernel* that has BTF (`CONFIG_DEBUG_INFO_BTF=y`)
  - BPF program compiled ahead-of-time with Clang; `BTF` type info embedded in the ELF
  - libbpf patches field offsets at load time using the *running kernel's BTF* — no recompilation needed
  - Ships as a small `.so` + the pre-compiled BPF object

  *Generation 3 — Language-native frameworks*
  #ref-badge("Aya (Rust)") #ref-badge("cilium/ebpf (Go)") #ref-badge("libbpf-rs (Rust)")

  - First-class language integration: type safety, package managers, native async, single binary
  - Aya: *pure Rust*, no libbpf dependency, no C toolchain at runtime
  - cilium/ebpf: *pure Go*, BPF kernel code still compiled with Clang + bpf2go
  - libbpf-rs: Rust *bindings to libbpf* (not a reimplementation)
]

== What popular projects use — and why it matters for your team

#cols[
  *Cilium — the reference for production eBPF at scale*
  #ref-badge[CNCF Graduated 2023; #1 CNI by CNCF Survey 2025 (47% YoY growth)]

  - Cilium's *data plane* is written in C, compiled with Clang, loaded via their own loader (built on `cilium/ebpf` Go library)
  - `cilium/ebpf` (pure Go) handles loading, map management, and CO-RE relocations — *no libbpf.so needed*
  - Tetragon (Cilium's runtime security tool): same stack — eBPF C + Go loader
  - eBPF Summit 2025 Hackathon: a proof-of-concept combining Aya (BPF kernel code in Rust) with Cilium's Go loader was a winning entry — showing the two worlds can interoperate

  *Key take-away for your team:* the industry trend is toward *language-native loaders that avoid libbpf.so* at runtime. Cilium chose Go; Aya is the Rust equivalent.
][
  *Other production users that inform the choice*

  #table(
    columns: (auto, auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Project*], [*Stack*], [*Why relevant*],
    [Red Hat bpfman], [Rust + Aya], [eBPF program lifecycle manager — systemd-style for BPF],
    [Deepfence ebpfguard], [Rust + Aya], [LSM security policy in Rust — no C required],
    [K8s Blixt], [Rust + Aya], [XDP load balancer — data plane in Rust],
    [Tracee], [Go + libbpf], [runtime security; BPF C + Go loader],
    [Falco], [C + libbpf], [syscall monitoring; traditional stack],
  )

  #callout(color: ebpf-teal)[
    The three projects using Aya in production — bpfman, ebpfguard, Blixt — all share the same motivation: *type safety across the kernel/userspace boundary* and *single-binary deployment without runtime C library dependencies*.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. libbpf + CO-RE WORKFLOW
// ─────────────────────────────────────────────────────────────────────────────
= libbpf + CO-RE — The Reference Workflow

== Why CO-RE matters for BSP teams

#cols[
  *The kernel fragmentation problem*

  Your BSP ships to multiple OEMs, each running different kernel versions — 5.15 LTS, 6.1 LTS, 6.6 LTS, plus OEM patches. Internal struct layouts differ between versions:

  ```
  Kernel 5.15:  struct task_struct { …pid at offset 0x2C8… }
  Kernel 6.1:   struct task_struct { …pid at offset 0x2D4… }
  Kernel 6.6:   struct task_struct { …pid at offset 0x2E0… }
  ```

  A BPF program that reads `task->pid` at a hardcoded offset *silently reads wrong memory* on a different kernel version.

  *Before CO-RE:* ship a separate BPF object per kernel version, or embed Clang on the target (BCC approach).
][
  *CO-RE: Compile Once, Run Everywhere*

  ```
  BPF source (.bpf.c / .rs)
       │  clang / rustc emits CO-RE relocation records
       │  alongside the bytecode in the ELF
       ▼
  BPF ELF object  (with .BTF section)
       │
       │  At load time on the target:
       │  libbpf / Aya reads /sys/kernel/btf/vmlinux
       │  (the running kernel's own type information)
       │  and patches offsets in the bytecode to match
       │  THIS kernel's struct layout
       ▼
  Correct program running on kernel 5.15, 6.1, 6.6 …
  ```

  *Requirement:* `CONFIG_DEBUG_INFO_BTF=y` in the target kernel. This is standard in all GKI kernels (Android 12+) and most recent distro kernels.

  #callout[
    *For Android BSP distribution*: one compiled binary runs on all OEM GKI variants. No per-OEM kernel header sets. No recompilation on the device. This is the decisive reason CO-RE was adopted.
  ]
]

== libbpf workflow — the five stages

#grid(
  columns: (1fr, 0.07fr, 1fr, 0.07fr, 1fr, 0.07fr, 1fr, 0.07fr, 1fr),
  gutter: 0pt,
  pipe-box(1, "1. Write", "program.bpf.c\n+ vmlinux.h\nSEC() macros\nbpf_helpers.h", color: ebpf-teal),
  align(center+horizon, text(size:1.1em, fill:ebpf-teal, "→")),
  pipe-box(2, "2. Compile", "clang -target bpf\n-g -O2\n→ program.bpf.o\n(ELF + BTF)", color: ebpf-teal),
  align(center+horizon, text(size:1.1em, fill:ebpf-teal, "→")),
  pipe-box(3, "3. Skeleton", "bpftool gen skeleton\n→ program.skel.h\nTyped C structs\nfor loader", color: ebpf-teal),
  align(center+horizon, text(size:1.1em, fill:ebpf-teal, "→")),
  pipe-box(4, "4. Load+Verify", "skel__open()\nskel__load()\nCO-RE patches\nKernel verifier", color: safe-green),
  align(center+horizon, text(size:1.1em, fill:safe-green, "→")),
  pipe-box(5, "5. Attach+Run", "skel__attach()\nbpf_link fd\nFires on events\nRead maps", color: safe-green),
)


#cols[
  *Dependencies required on the build host*

  ```bash
  # Generate vmlinux.h — all kernel types from BTF
  bpftool btf dump file \
      /sys/kernel/btf/vmlinux format c > vmlinux.h

  # Compile BPF program
  clang -target bpf -g -O2 \
      -D__TARGET_ARCH_x86 -I. \
      -c program.bpf.c -o program.bpf.o

  # Generate typed C skeleton header
  bpftool gen skeleton program.bpf.o \
      > program.skel.h

  # Compile userspace loader
  gcc -o program program.c \
      -lbpf -lelf -lz
  ```
][
  *Dependencies required on the target*

  - `libbpf.so` (or statically linked `libbpf.a`)
  - `libelf.so` — required by libbpf
  - `libz.so` — required by libelf
  - The pre-compiled `program.bpf.o` file *or* embedded via skeleton

  *Teardown discipline (C)*

  ```c
  ring_buffer__free(rb);    // must not forget
  skel__detach(skel);       // must not forget
  skel__destroy(skel);      // must not forget
  // No compiler warning if any of these are missing
  ```

  #callout(color: warn-amber)[
    *The target-side library dependency chain* — libbpf → libelf → libz — is the friction point for embedded Linux, Android, and custom BSPs where controlling the runtime library set is important.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  4. DOES RUST FIT eBPF?
// ─────────────────────────────────────────────────────────────────────────────
= Does Rust Fit eBPF?

== Why Rust is a natural fit for eBPF programs

#cols[
  *Shared constraints*

  eBPF programs and Rust both operate under the same fundamental constraint: *no undefined behaviour is acceptable*.

  - The BPF verifier rejects programs it cannot prove safe
  - Rust's type system rejects programs it cannot prove safe
  - Both operate at compile time or load time — not at runtime

  *`no_std` alignment*

  eBPF programs run with no kernel library, no allocator, no OS primitives. Rust's `#![no_std]` mode is the natural target — `aya-ebpf` provides the BPF-side runtime (`bpf_helpers`, map types, program macros) without any standard library dependency.
][
  *Type safety across the kernel boundary*

  The most expensive eBPF bug class in C: a map struct definition in the BPF program and the userspace loader that silently diverge.

  ```c
  // BPF program (C):
  struct event { u64 ts; u32 pid; };
  bpf_ringbuf_output(&rb, &e, sizeof(e), 0);

  // Userspace loader (C) — different file:
  struct event { u64 ts; u64 pid; }; // u64 ≠ u32 !
  // Reads wrong data — no compile error, no warning
  ```

  *Aya's solution*: one `#[no_std]` *common crate*, compiled for both targets. The struct is defined *once*. Layout disagreement is a *compile error*, not a runtime bug.

  #callout(color: rust-red)[
    This is the highest-value safety property of Rust for eBPF — not just memory safety in the BPF program, but *type-safe communication across the kernel/userspace boundary*.
  ]
]

== The bytecode generation question

#cols[
  *C eBPF toolchain*

  ```
  program.bpf.c
       │
       │  clang -target bpf -O2 -g
       ▼
  program.bpf.o     ← ELF with BPF bytecode + BTF
       │
       │  bpftool gen skeleton
       ▼
  program.skel.h    ← generated C loader
       │
       │  gcc / clang (host)
       ▼
  program             ← userspace binary
  ```

  *What you need*: clang + LLVM (BPF backend) + bpftool + libelf + libbpf. C toolchain mandatory for the BPF program even if userspace is Rust (libbpf-rs).
][
  *Rust / Aya toolchain*

  ```
  program-ebpf/src/main.rs    (eBPF side)
  program-common/src/lib.rs   (shared types)
  program/src/main.rs         (userspace side)
       │
       │  rustc --target bpfel-unknown-none
       │  + bpf-linker (LLVM BPF backend)
       ▼
  ELF object (embedded via include_bytes_aligned!)
       │
       │  cargo build (host)
       ▼
  program             ← single self-contained binary
  ```

  *What you need*: rustc (nightly) + bpf-linker. *No clang, no bpftool, no libelf, no C toolchain.* The BPF ELF is embedded in the userspace binary — one artifact to deploy.

  #callout[
    Aya does not wrap libbpf — it is a *pure-Rust reimplementation* of the BPF syscall layer, built on `libc` only.
    #ref-badge[github.com/aya-rs/aya — "built from the ground up purely in Rust"]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. RUST APPROACHES: libbpf-rs vs Aya
// ─────────────────────────────────────────────────────────────────────────────
= Rust Approaches — libbpf-rs and Aya

== Two distinct strategies

#v(0.4em)

#grid(
  columns: (1fr, 0.08fr, 1fr),
  gutter: 0pt,

  // libbpf-rs column
  block(
    fill:  ref-blue.lighten(92%),
    stroke: 0.5pt + ref-blue.lighten(40%),
    radius: 6pt, inset: 14pt, width: 100%,
    stack(dir: ttb, spacing: 8pt,
      text(weight: "bold", size: 0.85em, fill: ref-blue, "libbpf-rs"),
      text(size: 0.68em, fill: luma(20%), style: "italic", "Rust bindings over libbpf"),
      line(length: 100%, stroke: 0.4pt + ref-blue.lighten(50%)),
      text(size: 0.70em)[
        - BPF *kernel side*: still written in *C*, compiled with Clang
        - Userspace loader: *Rust* wrapping libbpf via `libbpf-sys`
        - `bpf2rs` generates Rust skeletons from the BPF ELF
        - `libbpf.so` + `libelf.so` *still required on the target*
        - Familiar to existing libbpf-C teams; lower migration cost
        - C toolchain still mandatory in the build pipeline
      ],
      block(fill: ref-blue.lighten(84%), radius: 4pt, inset: (x:8pt,y:5pt),
        text(size: 0.65em, fill: ref-blue.darken(20%))[
          *Good for*: teams migrating from C libbpf who want Rust userspace only
        ]),
    ),
  ),

  align(center+horizon,
    stack(dir: ttb, spacing: 4pt,
      text(size: 1.2em, fill: luma(150), "vs"),
    )
  ),

  // Aya column
  block(
    fill:  rust-red.lighten(92%),
    stroke: 0.5pt + rust-red.lighten(40%),
    radius: 6pt, inset: 14pt, width: 100%,
    stack(dir: ttb, spacing: 8pt,
      text(weight: "bold", size: 0.85em, fill: rust-red, "Aya"),
      text(size: 0.68em, fill: luma(20%), style: "italic", "Pure-Rust reimplementation"),
      line(length: 100%, stroke: 0.4pt + rust-red.lighten(50%)),
      text(size: 0.70em)[
        - BPF *kernel side*: written in *Rust*, compiled with `rustc + bpf-linker`
        - Userspace loader: *Rust*, built on `libc` crate only — *no libbpf, no libelf, no C*
        - Shared struct crate: one definition, type-safe across both sides
        - Target binary: *single statically-linked executable* with musl
        - CO-RE via `aya-obj` — pure-Rust BTF parser and relocation engine
        - Async-native: `AsyncFd<RingBuf>` works directly with Tokio
      ],
      block(fill: rust-red.lighten(84%), radius: 4pt, inset: (x:8pt,y:5pt),
        text(size: 0.65em, fill: rust-red.darken(20%))[
          *Good for*: new projects, embedded/Android targets, teams comfortable with Rust
        ]),
    ),
  ),
)

#v(0.6em)
#callout(color: ebpf-teal)[
  *This session focuses on Aya* — pure-Rust, no C toolchain at runtime, single-binary deployment, first-class embedded and Android support.
  #ref-badge[github.com/aya-rs/aya — "built from the ground up purely in Rust, using only the libc crate"]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. AYA FRAMEWORK OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
= Aya Framework Overview

== Architecture and component map

#cols(ratio: (1.05fr, 0.95fr))[
  *Crate family and responsibilities*

  ```
  ┌──────────────────────────────────────────────┐
  │  Your userspace binary  (std, async)         │
  │  Ebpf::load() · map access · link handles    │
  ├──────────────────────────────────────────────┤
  │  aya          ← core userspace library       │
  │  Pure Rust bpf() syscall wrapper             │
  │  Program types: KProbe KRetProbe Xdp Lsm …   │
  │  Map types: HashMap RingBuf Array PerfMap …  │
  ├──────────────────────────────────────────────┤
  │  aya-obj      ← ELF + BTF + CO-RE engine     │
  │  Pure Rust ELF parser                        │
  │  Reads /sys/kernel/btf/vmlinux               │
  │  Patches relocations — no libelf dependency  │
  ├──────────────────────────────────────────────┤
  │  aya-log      ← userspace log receiver       │
  │  Reads aya-log-ebpf ring buffer              │
  └──────────────────────────────────────────────┘
  ┌──────────────────────────────────────────────┐
  │  Your BPF program  (no_std, no_main)         │
  │  #[kprobe] #[xdp] #[lsm] · map access        │
  ├──────────────────────────────────────────────┤
  │  aya-ebpf     ← BPF-side runtime crate       │
  │  Program macros: #[kprobe] #[map] #[xdp] …   │
  │  Helper wrappers: bpf_ktime_get_ns() …       │
  │  Map structs: HashMap RingBuf PerfMap …      │
  ├──────────────────────────────────────────────┤
  │  aya-log-ebpf ← BPF-side logging             │
  │  info!() warn!() → log ring buffer           │
  ├──────────────────────────────────────────────┤
  │  aya-ebpf-bindings ← kernel uapi types       │
  │  Generated from kernel headers by bindgen    │
  └──────────────────────────────────────────────┘
  ```
][
  *What each component replaces (vs libbpf stack)*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Aya crate*], [*Replaces in libbpf world*],
    [`aya`], [`libbpf.so` + `libbpf-sys` + skeleton loader],
    [`aya-obj`], [`libelf.so` + `libz.so` + libbpf ELF parser],
    [`aya-ebpf`], [`bpf_helpers.h` + `bpf/bpf_tracing.h`],
    [`aya-log`], [custom ring buffer log consumer],
    [`aya-log-ebpf`], [`bpf_printk()` (but ring-buffer based)],
    [`aya-tool`], [`bpftool btf dump … format c > vmlinux.h`],
    [`aya-build`], [`bpftool gen skeleton` + Makefile integration],
    [`common crate`], [manually-matched C header in both files],
  )

  #callout(color: ebpf-teal)[
    *Zero C runtime dependencies on the target.* The entire stack is Rust + one `bpf()` syscall. `aya-obj` implements its own ELF and BTF parser — no `libelf.so` needed.
  ]
]

== Aya for embedded and Android — the musl advantage

#cols[
  *The deployment problem on embedded / Android targets*

  A libbpf-based tool ships as:
  ```
  /usr/bin/my-tracer         ← ELF dynamically linked to:
  /usr/lib/libbpf.so.1       ← must exist on target
  /usr/lib/libelf.so.1       ← must exist on target
  /usr/lib/libz.so.1         ← must exist on target
  ```

  On Android or a minimal embedded rootfs:
  - `libelf` is often absent — it's a development library
  - `libbpf` version may not match what you compiled against
  - Android's linker namespace rules may prevent loading unrecognised shared libraries
  - A `system_ext` partition APK distributing a native `.so` chain is a maintenance burden

  *For cross-compiled BSP targets* (ARM64, RISC-V):
  - The host must have cross-compiled versions of all three `.so` files
  - Sysroot management becomes a per-target-per-kernel exercise
][
  *Aya + musl: one self-contained binary*

  ```bash
  # Add musl target (one-time)
  rustup target add aarch64-unknown-linux-musl

  # Cross-compile with musl — static binary
  # (cross wraps cargo with the right cross-compiler)
  cargo install cross
  cross build --release \
      --target aarch64-unknown-linux-musl

  # Result: a single fully static binary
  file target/aarch64-unknown-linux-musl/\
           release/my-tracer
  # my-tracer: ELF 64-bit LSB executable, ARM aarch64,
  #            statically linked, stripped

  # Copy to target — zero other files needed
  adb push my-tracer /data/local/tmp/
  adb shell chmod +x /data/local/tmp/my-tracer
  adb shell /data/local/tmp/my-tracer
  ```

  #callout(color: ebpf-teal)[
    *True compile once, run everywhere*: a musl-linked Aya binary + BTF CO-RE runs on any ARM64/x86 Linux kernel with BTF support — distribution, Android OEM kernel, or custom BSP — without any library installation. #ref-badge[aya-rs.dev — "a single self-contained binary can be deployed on many Linux distributions"]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. BUILDING WITH AYA-TEMPLATE
// ─────────────────────────────────────────────────────────────────────────────
= Building with Aya Template

== Prerequisites and scaffold

#cols[
  *One-time setup*

  ```bash
  # 1. Rust nightly — required for bpfel-unknown-none target
  rustup toolchain install nightly \
      --component rust-src

  # 2. bpf-linker — LLVM BPF backend for rustc
  #    (bundles the right LLVM version)
  cargo install bpf-linker

  # 3. Scaffold tool
  cargo install cargo-generate

  # 4. Verify BPF target is available
  rustc +nightly --print target-list \
      | grep bpfel
  # bpfel-unknown-none  ← must appear

  # 5. Optional: aya-tool for kernel type bindings
  cargo install aya-tool
  ```
][
  *Scaffold the project*

  ```bash
  cargo generate \
      --git https://github.com/aya-rs/aya-template \
      --name dma-latency-tracer

  cd dma-latency-tracer

  # Build everything in one command
  # build.rs cross-compiles the eBPF crate automatically
  cargo build --release

  # Result:
  # target/release/dma-latency-tracer  ← userspace binary
  #   └── embeds the compiled BPF ELF via include_bytes_aligned!
  ```

  #callout[
    *No xtask, no separate build step.* The `build.rs` in the userspace crate invokes a child `cargo +nightly build --target bpfel-unknown-none -Z build-std=core` automatically. `cargo build` is the only command.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  8. PROJECT LAYOUT AND RUST FEATURES
// ─────────────────────────────────────────────────────────────────────────────
= Project Layout and Rust Features That Simplify eBPF

== Three-crate workspace structure

#cols(ratio: (1fr, 1fr))[
  *Directory layout*

  ```
  dma-latency-tracer/
  ├── Cargo.toml            ← workspace root
  ├── rust-toolchain.toml   ← pins nightly for eBPF crate
  │
  ├── dma-latency-tracer-common/
  │   └── src/lib.rs
  │     #![no_std]
  │     #[repr(C)]
  │     pub struct DmaEvent {   ← ONE definition
  │         pub latency_ns: u64,  used by BOTH
  │         pub nents: u32,       BPF and userspace
  │         pub pid: u32,
  │         pub comm: [u8; 16],
  │     }
  │
  ├── dma-latency-tracer-ebpf/
  │   ├── .cargo/config.toml  ← target = bpfel-unknown-none
  │   └── src/main.rs         ← #[kprobe] programs
  │
  └── dma-latency-tracer/
      ├── build.rs            ← cross-compiles eBPF crate
      └── src/main.rs         ← Ebpf::load, attach, async consumer
  ```
][
  *The .cargo/config.toml for the eBPF crate*

  ```toml
  # dma-latency-tracer-ebpf/.cargo/config.toml
  [build]
  target    = "bpfel-unknown-none"
  rustflags = [
      "-C", "debuginfo=2",     # embed BTF
      "-C", "link-arg=--btf",  # CO-RE relocs
  ]

  [unstable]
  build-std = ["core"]         # cross-compile core
  ```

  *The userspace build.rs — key extract*

  ```rust
  Command::new(&cargo)
      .arg("+nightly")
      .arg("build")
      .arg("--package")
      .arg("dma-latency-tracer-ebpf")
      .arg("--target")
      .arg("bpfel-unknown-none")
      .arg("-Z").arg("build-std=core")
      .status()?;
  // Copies compiled ELF to $OUT_DIR
  // Userspace embeds via:
  // include_bytes_aligned!(concat!(env!("OUT_DIR"),
  //     "/dma-latency-tracer-ebpf"))
  ```
]

== Rust features that make eBPF programming safer and cleaner

#v(0.3em)

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,

  // Feature 1
  block(fill: rust-red.lighten(92%), stroke: 0.5pt + rust-red.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: rust-red,
        "1. Shared common crate — type-safe boundary"),
      text(size: 0.67em)[
        `DmaEvent` defined once in `common/src/lib.rs` with `#[repr(C)]`. Compiled for `bpfel-unknown-none` (no_std) and host (std). Struct layout mismatch is a *compile error*, not a silent wrong result. The same `comm: [u8; 16]` field is correctly sized and aligned on both sides — always.
      ],
    )
  ),

  // Feature 2
  block(fill: rust-red.lighten(92%), stroke: 0.5pt + rust-red.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: rust-red,
        "2. RAII attachment handles — guaranteed teardown"),
      text(size: 0.67em)[
        `prog.attach(…)?` returns a typed handle implementing `Drop`. When the handle goes out of scope — on any exit path, including `?` propagation or panic — the BPF link fd is closed and the program detached. No `skel__detach()` to forget. No leaked attachment if the consumer loop exits early.
      ],
    )
  ),

  // Feature 3
  block(fill: ebpf-teal.lighten(92%), stroke: 0.5pt + ebpf-teal.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: ebpf-teal,
        "3. Result<T,E> + ? — no silent load failures"),
      text(size: 0.67em)[
        Every Aya call returns `Result<T, Error>`. `Ebpf::load(bytes)?` will not silently continue if the BPF ELF is malformed or the kernel rejects the program. The `?` operator propagates the error immediately with source location. In C: `skel__load(skel)` returns `int` — easy to ignore.
      ],
    )
  ),

  // Feature 4
  block(fill: ebpf-teal.lighten(92%), stroke: 0.5pt + ebpf-teal.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: ebpf-teal,
        "4. Async ring buffer — epoll without callbacks"),
      text(size: 0.67em)[
        `AsyncFd<RingBuf>` integrates with Tokio's event loop natively. The consumer `loop { select! { guard = async_fd.readable() => { … } } }` is structured flow — not a C callback (`ring_buffer__poll` + `handle_event` function pointer). State between events is naturally owned by the async task. No global callback context pointer needed.
      ],
    )
  ),

  // Feature 5
  block(fill: safe-green.lighten(92%), stroke: 0.5pt + safe-green.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: safe-green,
        "5. Typed program kinds — no runtime mismatches"),
      text(size: 0.67em)[
        `bpf.program_mut("name")?.try_into::<KProbe>()` — the downcast is explicit and returns `Err` if the program type does not match. Calling `attach()` on a `KProbe` handle only accepts kprobe-valid arguments. In C: `bpf_program__attach()` is untyped; wrong hook arguments silently fail or attach to the wrong point.
      ],
    )
  ),

  // Feature 6
  block(fill: safe-green.lighten(92%), stroke: 0.5pt + safe-green.lighten(50%),
    radius: 5pt, inset: 10pt,
    stack(dir: ttb, spacing: 5pt,
      text(weight: "bold", size: 0.75em, fill: safe-green,
        "6. aya-log — structured logging from BPF programs"),
      text(size: 0.67em)[
        `info!(&ctx, "dma_map_sg: pid={} nents={}", pid, nents)` inside the BPF program writes to a dedicated ring buffer. The userspace `EbpfLogger::init(&mut bpf)` subscribes and routes to `env_logger` / `log` — the same logging infrastructure as the rest of the Rust application. No `bpf_printk()` parsing. No separate trace_pipe reader.
      ],
    )
  ),
)

== BPF program side — key patterns

#cols[

  #text(size: 0.65em, weight: "bold", fill: rust-red, "C / libbpf — BPF program ")
  #codebox(
```c

SEC("kprobe/dma_map_sg")
int BPF_KPROBE(dma_map_sg_enter,
               struct device *dev,
               struct scatterlist *sg,
               int nents,
               enum dma_data_direction dir)
{
    u64 pid_tgid = bpf_get_current_pid_tgid();
    u32 pid = pid_tgid & 0xFFFFFFFF;
    u64 ts  = bpf_ktime_get_ns();
    bpf_map_update_elem(&start_map,
        &pid, &ts, BPF_ANY);
    return 0;
}
// Map declared separately with struct + __uint macros
// Struct shared with userspace via MANUALLY matched header
```, ) 
][
  #text(size: 0.65em, weight: "bold", fill: rust-red, "Rust / Aya — BPF program")
  #codebox(
```rust
// Rust / Aya — BPF program
#[kprobe]
pub fn dma_map_sg_enter(ctx: ProbeContext) -> u32 {
    let pid = (bpf_get_current_pid_tgid()
               & 0xFFFF_FFFF) as u32;
    let ts  = unsafe { bpf_ktime_get_ns() };
    // Map declared at crate level with #[map]
    let _  = START_MAP.insert(&(pid as u64), &ts, 0);
    0
}
// Struct imported from common crate — ONE definition
// Layout verified by the compiler across both sides
```
)]

== Userspace side — load, attach, consume

#cols[
  #text(size: 0.65em, weight: "bold", fill: rust-red, "C / libbpf — userspace loader")
#codebox(
```c
struct prog_bpf *skel = prog__open();

// CO-RE, maps created, verifier called:
prog__load(skel);

// Hook attached, bpf_link fd returned:
prog__attach(skel);

// Ring buffer callback model:
struct ring_buffer *rb = ring_buffer__new(
    bpf_map__fd(skel->maps.events),
    handle_event, NULL, NULL);

while (running)
    ring_buffer__poll(rb, 100);

// MUST manually clean up:
ring_buffer__free(rb);
prog__detach(skel);
prog__destroy(skel);
```) 
][
#text(size: 0.65em, weight: "bold", fill: rust-red, "Rust / Aya — userspace loader")
#codebox(
```rust
// 
let mut bpf = Ebpf::load(BPF_BYTES)?;

// Typed downcast — compile error if wrong kind:
let prog: &mut KProbe = bpf
    .program_mut("dma_map_sg_enter")?
    .try_into()?;
prog.load()?;
let _link = prog.attach("dma_map_sg", 0)?;
// _link implements Drop — detach is automatic

// Async ring buffer — no callback, no context ptr:
let rb  = RingBuf::try_from(bpf.take_map("EVENTS")?)?;
let afd = AsyncFd::new(rb)?;
loop {
    let mut g = afd.readable().await?;
    while let Some(item) = g.get_inner_mut().next() {
        let e = unsafe { *(item.as_ptr() as *const DmaEvent) };
        // e.latency_ns, e.pid, e.comm — all typed
    }
    g.clear_ready();
}
// bpf, _link, afd all Drop here — zero cleanup code
```
)
]

// ─────────────────────────────────────────────────────────────────────────────
//  9. DEMO — DMA LATENCY TRACER
// ─────────────────────────────────────────────────────────────────────────────
= Demo — DMA Latency Tracer

== Test setup — ConnectX-5 crossover DAC

#cols[
  *Physical topology*

  ```
  ┌──────────────────────────────────────────────┐
  │  Host motherboard — PCIe Gen 3.0 x16 slot    │
  │                                              │
  │  ┌────────────────────────────────────────┐  │
  │  │  Mellanox ConnectX-5 100GbE            │  │
  │  │  (PCIe Gen 4 card — links at Gen 3)    │  │
  │  │                                        │  │
  │  │  Port 0 (enp6s0f0) ──╮  DAC crossover  │  │
  │  │  Port 1 (enp6s0f1) ──╯  cable          │  │
  │  └────────────────────────────────────────┘  │
  └──────────────────────────────────────────────┘

  ns0 (192.168.100.1) ←——DAC——→ ns1 (192.168.100.2)
  Traffic traverses physical cable — no loopback path
  ```

  *Namespace setup — isolate the two ports*

  ```bash
  sudo ip netns add ns0 && sudo ip netns add ns1
  sudo ip link set enp6s0f0 netns ns0
  sudo ip link set enp6s0f1 netns ns1
  sudo ip netns exec ns0 \
      ip addr add 192.168.100.1/24 dev enp6s0f0
  sudo ip netns exec ns1 \
      ip addr add 192.168.100.2/24 dev enp6s0f1
  ```
][
  *What we instrument*

  `dma_map_sg(struct device*, struct scatterlist*, int nents, enum dma_data_direction dir)`

  The mlx5 driver calls this for every WQE (Work Queue Entry) posted to the HCA. Latency = IOMMU DMA mapping overhead — the performance-relevant part of each DMA transaction.

  *Expected latency profile — ConnectX-5 on PCIe Gen 3 host*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*Range*], [*Interpretation*],
    [< 2 µs],  [IOMMU TLB warm — normal path ✓],
    [2–10 µs], [TLB pressure / NUMA distance],
    [10–50 µs],[IOMMU page-table walk — TLB miss],
    [> 50 µs], [CPU C-states or frequency scaling],
  )

  PCIe Gen 3 vs Gen 4: the Gen 3 link halves *bandwidth* but does *not* increase individual DMA mapping latency. Latency is dominated by IOMMU and NUMA topology.
]

== Build and run

#codeblock(
  ```bash
  # ── Prerequisites (one-time) ─────────────────────────────────────────────
  rustup toolchain install nightly --component rust-src
  cargo install bpf-linker

  # ── Build — single command ────────────────────────────────────────────────
  # build.rs drives eBPF cross-compilation automatically
  cargo build --release

  # ── For ARM64 target (cross-compile + musl static binary) ─────────────────
  cargo install cross
  cross build --release --target aarch64-unknown-linux-musl
  # Push single static binary to target — no library installation needed
  adb push target/aarch64-unknown-linux-musl/release/dma-latency-tracer \
      /data/local/tmp/

  # ── Generate traffic through the DAC cable ───────────────────────────────
  sudo ip netns exec ns0 iperf3 -s &
  sudo ip netns exec ns1 iperf3 -c 192.168.100.1 -t 120 -P 8

  # ── Run the tracer (requires CAP_BPF / root) ─────────────────────────────
  sudo RUST_LOG=info ./target/release/dma-latency-tracer \
      --interval 5 \
      --min-latency-us 1 \
      --filter-comm iperf3
  ```,title: "Full build and run sequence")

== Demo output — event stream

#codeblock(title: "Individual DMA events above threshold")[
  ```
  [INFO]  dma-latency-tracer: attached kprobe + kretprobe on dma_map_sg
  [INFO]  Setup: ConnectX-5 PCIe Gen4 @ Gen3 slot | DAC crossover | ns0 ↔ ns1
  [INFO]  Reporting every 5s  |  filter: iperf3  |  min threshold: 1 µs

  [INFO]  [cpu=03] pid=12345 comm=iperf3        nents= 16  dir=TO_DEVICE     lat=  1.842 µs
  [INFO]  [cpu=07] pid=12345 comm=iperf3        nents= 32  dir=TO_DEVICE     lat=  2.201 µs
  [INFO]  [cpu=01] pid=12345 comm=iperf3        nents= 16  dir=FROM_DEVICE   lat=  1.634 µs
  [INFO]  [cpu=11] pid=12347 comm=kworker/11:1H nents=  4  dir=BIDIRECTIONAL lat=  8.443 µs
  [INFO]  [cpu=03] pid=12345 comm=iperf3        nents= 64  dir=TO_DEVICE     lat= 31.771 µs ← TLB miss
  [INFO]  (max_events reached — histogram continues)
  ```
]

== Demo output — latency histogram
//title: "Per-interval histogram — 5 second window, 48 291 events")
#codebox(
  ```
  ════════════════════════════════════════════════════════════════════════
    dma_map_sg latency histogram  (window events: 48 291)
    System: ConnectX-5 PCIe Gen4 | Gen3 host slot | DAC crossover cable
  ────────────────────────────────────────────────────────────────────────
               range      count       %    dist (normalised to peak)
         0 – 500 ns       2 134    4.42%   |████░░░░░░░░░░░░░░░░░░░░░░░░|
       500 ns – 1 µs      5 891   12.20%   |████████████░░░░░░░░░░░░░░░░|
           1 – 2 µs      18 432   38.17%   |████████████████████████████|  ← peak
           2 – 3 µs      14 201   29.41%   |███████████████████████░░░░░|
           3 – 5 µs       5 912   12.24%   |████████████░░░░░░░░░░░░░░░░|
         5 – 7.5 µs       1 102    2.28%   |██░░░░░░░░░░░░░░░░░░░░░░░░░░|
        7.5 – 10 µs         401    0.83%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
          10 – 15 µs        128    0.26%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
          15 – 30 µs         82    0.17%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
             > 30 µs          8    0.02%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
  ────────────────────────────────────────────────────────────────────────
    Fast ( < 2 µs):  26 457  (54.8%)  — IOMMU TLB warm ✓
    Slow (> 30 µs):       8   (0.0%)  — check C-states / IOMMU pressure
  ────────────────────────────────────────────────────────────────────────
     pid  comm               count    avg µs    min µs    max µs
   12345  iperf3             48 291     1.923     0.312    87.441
   12347  kworker/11:1H          62     7.114     3.201    31.771
  ════════════════════════════════════════════════════════════════════════
  ```
)

== Reading the output

#cols[
  *What the histogram tells you*

  - *Peak at 1–2 µs*: healthy — IOMMU TLB is warm, mlx5 scatter-gather lists (16–32 nents) served from cached page table entries
  - *Tail at 3–10 µs*: mild TLB pressure as the ring cycles — expected under sustained 100 GbE load at line rate
  - *Outliers > 30 µs*: IOMMU page-table walk (TLB miss) or CPU C-state wakeup. Correlate with `scaling_cur_freq`
  - *`kworker` at `BIDIRECTIONAL`*: mlx5 firmware completion posting — normal for ConnectX-5

  *PCIe Gen 3 vs Gen 4 note*

  The Gen 3 link halves *bandwidth* to ~128 Gbps theoretical (from 256 Gbps Gen 4). Individual DMA mapping latency is *not* affected — dominated by IOMMU + NUMA, not PCIe link speed.
][
  *Actionable follow-up from this data*

  - High `> 10 µs` count during iperf3 → enable huge pages for IOMMU to reduce TLB misses:
    `echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`
  - Latency spikes correlated with `kworker` PIDs → firmware-level power management interfering with IOMMU
  - Per-CPU histogram shows one CPU with consistently higher latency → mlx5 IRQ affinity misalignment from PCIe slot NUMA node
  - High `nents` correlation with high latency → large scatter-gather lists exhausting IOMMU TLB; tune `net.core.optmem_max` or adjust NIC queue depth

  #callout(color: ebpf-teal)[
    *Zero kernel changes. Zero driver modifications.* This runs on a production kernel against production traffic. The Aya binary is 3.2 MB statically linked — deployable to any target with `scp` or `adb push`.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *Aya is not a wrapper around libbpf.*

  *It is a reimplementation — in Rust, for Rust.*

  One language. One toolchain. One binary.\
  Type-safe across the kernel/userspace boundary.\
  Deploy anywhere Linux + BTF exist.
]

// ─────────────────────────────────────────────────────────────────────────────
//  APPENDIX
// ─────────────────────────────────────────────────────────────────────────────
= Appendix <touying:hidden>

== aya-tool — generating kernel type bindings

```bash
# Install aya-tool
cargo install aya-tool

# Generate Rust bindings for specific kernel structs
# from the running kernel's BTF — equivalent of
# bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
# but produces a Rust module:
aya-tool generate task_struct > \
    dma-latency-tracer-ebpf/src/vmlinux.rs

# Use in BPF program:
// mod vmlinux;
// use vmlinux::task_struct;
```

== CO-RE in Aya — the relocation chain

```
BPF program (Rust):
  uses: bpf_core_read!(task, pid)
  rustc + bpf-linker emit:
    → BTF_CO-RE relocations in the BPF ELF
    → .BTF section with type information

At Ebpf::load() time (Aya):
  1. aya-obj parses the BPF ELF
  2. Reads /sys/kernel/btf/vmlinux
  3. For each CO-RE relocation record:
     looks up the field offset in the RUNNING kernel's BTF
     (may differ from the compile-time layout)
  4. Patches BPF bytecode with the correct offset
  5. Submits patched bytecode via bpf() syscall → verifier → JIT

Result: one binary. Runs on kernel 5.15, 6.1, 6.6, 6.12 —
        any kernel where CONFIG_DEBUG_INFO_BTF=y
```

== References

#set text(size: 0.72em)

*Aya framework*
- Aya book: #link("https://aya-rs.dev/book/")[aya-rs.dev/book]
- API docs: #link("https://docs.rs/aya")[docs.rs/aya]
- awesome-aya: #link("https://github.com/aya-rs/awesome-aya")[github.com/aya-rs/awesome-aya]
- FOSDEM 2025: "Building your eBPF Program with Rust and Aya" — #link("https://archive.fosdem.org/2025/schedule/event/fosdem-2025-5534-building-your-ebpf-program-with-rust-and-aya/")

*libbpf and CO-RE*
- libbpf overview: #link("https://docs.kernel.org/bpf/libbpf/libbpf_overview.html")[docs.kernel.org/bpf/libbpf]
- CO-RE reference: #link("https://nakryiko.com/posts/bpf-core-reference-guide/")[nakryiko.com]
- libbpf-bootstrap: #link("https://nakryiko.com/posts/libbpf-bootstrap/")[nakryiko.com]

*Framework landscape*
- cilium/ebpf (Go): #link("https://github.com/cilium/ebpf")[github.com/cilium/ebpf]
- libbpf-rs: #link("https://github.com/libbpf/libbpf-rs")[github.com/libbpf/libbpf-rs]
- Podobnik, T. "Go, C, Rust, and More: Picking the Right eBPF Application Stack." Medium, 2025.

*Production Aya deployments*
- Red Hat bpfman: #link("https://bpfman.io")[bpfman.io]
- Deepfence ebpfguard: #link("https://github.com/deepfence/ebpfguard")[github.com/deepfence/ebpfguard]
- Kubernetes Blixt: #link("https://github.com/kubernetes-sigs/blixt")[github.com/kubernetes-sigs/blixt]

*eBPF fundamentals*
- Gregg, B. *BPF Performance Tools.* Addison-Wesley, 2019.
- CNCF Annual Survey 2025 — Cilium adoption.
