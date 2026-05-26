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
//  2. DOES RUST FIT eBPF?
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
//  3. THE eBPF PIPELINE
// ─────────────────────────────────────────────────────────────────────────────
= The eBPF Pipeline — Source to Running Hook

== Five stages from source to attached program

#v(0.4em)
#grid(
  columns: (1fr, 0.08fr, 1fr, 0.08fr, 1fr, 0.08fr, 1fr, 0.08fr, 1fr),
  gutter: 0pt,
  pipe-box(1, "Write", "Author BPF source:\nmap declarations,\nhook attributes,\nhelper calls", color: ebpf-teal),
  align(center + horizon, text(size: 1.2em, fill: ebpf-teal, "→")),
  pipe-box(2, "Compile", "Source → BPF bytecode\n(ELF object).\nBTF debug info\nembedded.", color: ebpf-teal),
  align(center + horizon, text(size: 1.2em, fill: ebpf-teal, "→")),
  pipe-box(3, "Load", "Userspace opens ELF,\ncreates maps,\nresolves CO-RE\nrelocations.", color: ebpf-teal),
  align(center + horizon, text(size: 1.2em, fill: ebpf-teal, "→")),
  pipe-box(4, "Verify + JIT", "Kernel verifier\nproves safety.\nJIT compiler emits\nnative code.", color: safe-green),
  align(center + horizon, text(size: 1.2em, fill: safe-green, "→")),
  pipe-box(5, "Attach", "Program linked to\nhook point.\nFires on every\nmatching event.", color: safe-green),
)
#v(0.6em)

#cols[
  *Stage 1 — Write*

  - Declare maps at crate/file level with attributes
  - Annotate functions with hook type (`#[kprobe]`, `#[tracepoint]`, …)
  - Call BPF helpers (`bpf_ktime_get_ns`, `bpf_get_current_comm`, …)
  - Access kernel struct fields via CO-RE macros
  - Share event struct definition with userspace via common crate / header
][
  *Stage 5 — Attach (detail)*

  The attachment is a *file descriptor* that the kernel holds. When it closes, the program is automatically detached — no cleanup code needed.

  - `kprobe`: attach to any kernel function symbol by name
  - `tracepoint`: attach to `subsystem/event_name` in tracefs
  - `xdp`: attach to a network interface by name
  - `lsm`: attach to a specific LSM hook name
  - *Aya*: the attachment is a Rust struct implementing `Drop` — RAII cleanup guaranteed, even on panic paths.
]
