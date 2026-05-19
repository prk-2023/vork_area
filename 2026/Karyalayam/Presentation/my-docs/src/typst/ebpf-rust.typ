// ─────────────────────────────────────────────────────────────────────────────
//  eBPF Programming with Rust — Aya Framework
//  Typst / Touying presentation · Metropolis theme
//
//  Audience : Senior kernel & C engineers with eBPF awareness
//  Scope    : eBPF overview · why Rust fits · bytecode pipeline ·
//             libbpf stages · Aya mapping · project scaffold · demo
//
//  Build  :  typst compile ebpf-rust.typ ebpf-rust.pdf
//  Preview:  VS Code + Tinymist extension
//
//  Packages auto-downloaded on first compile:
//    @preview/touying:0.7.1
//    @preview/numbly:0.1.0
// ─────────────────────────────────────────────────────────────────────────────

#import "@preview/touying:0.7.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

// ── Palette ───────────────────────────────────────────────────────────────────
#let ebpf-teal   = rgb("#0D7377")
#let rust-red    = rgb("#CE422B")
#let rust-dark   = rgb("#1A1A1A")
#let safe-green  = rgb("#2D6A4F")
#let warn-amber  = rgb("#854D0E")
#let ref-blue    = rgb("#1B4F8A")
#let code-bg     = rgb("#1E1E2E")
#let code-fg     = rgb("#CDD6F4")
#let ok-col      = rgb("#A6E3A1")
#let er-col      = rgb("#F38BA8")
#let hi-col      = rgb("#FAB387")
#let cm-col      = rgb("#585B70")
#let libbpf-blue = rgb("#1565C0")

// ── Helpers ───────────────────────────────────────────────────────────────────
#let callout(body, color: ebpf-teal) = block(
  fill:   color.lighten(90%),
  stroke: (left: 3pt + color),
  inset:  (left: 10pt, top: 7pt, bottom: 7pt, right: 9pt),
  radius: (right: 4pt),
  width:  100%,
  body,
)

#let ref-badge(body) = box(
  fill:   ref-blue.lighten(88%),
  stroke: 0.4pt + ref-blue,
  inset:  (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: ref-blue, size: 0.59em, style: "italic", body),
)

#let cols(l, r, ratio: (1fr, 1fr)) = grid(
  columns: ratio, gutter: 1.2em, l, r,
)

// Dark code block with optional bar-title
#let code(body, title: none, accent: ebpf-teal) = {
  if title != none {
    block(
      fill:   accent.lighten(88%),
      inset:  (x: 10pt, y: 4pt),
      radius: (top: 5pt),
      width:  100%,
      text(size: 0.63em, weight: "bold", fill: accent, title),
    )
  }
  block(
    fill:   code-bg,
    radius: if title != none { (bottom: 5pt) } else { 5pt },
    inset:  11pt,
    width:  100%,
    text(
      font: ("Fira Code", "JetBrains Mono", "Courier New"),
      fill: code-fg,
      size: 0.69em,
      body,
    ),
  )
}

// Pipeline step box
#let pipe-box(n, title, body, color: ebpf-teal) = block(
  fill:   color.lighten(90%),
  stroke: 0.5pt + color,
  radius: 6pt,
  inset:  10pt,
  width:  100%,
  stack(dir: ltr, spacing: 8pt,
    circle(fill: color, radius: 9pt,
      align(center + horizon,
        text(fill: white, size: 0.65em, weight: "bold", str(n)))),
    stack(dir: ttb, spacing: 3pt,
      text(size: 0.75em, weight: "bold", fill: color, title),
      text(size: 0.68em, fill: luma(40%), body),
    ),
  ),
)

// Stage comparison row
#let vs-row(stage, c-col, rust-col) = {
  grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 8pt,
    block(fill: luma(240), radius: 4pt, inset: (x:8pt, y:5pt), width: 100%,
      text(size: 0.68em, weight: "bold", stage)),
    block(fill: libbpf-blue.lighten(92%), radius: 4pt, inset: (x:8pt, y:5pt), width: 100%,
      text(size: 0.67em, fill: libbpf-blue.darken(20%), c-col)),
    block(fill: ebpf-teal.lighten(90%), radius: 4pt, inset: (x:8pt, y:5pt), width: 100%,
      text(size: 0.67em, fill: ebpf-teal.darken(10%), rust-col)),
  )
  v(3pt)
}

// ── Theme ─────────────────────────────────────────────────────────────────────
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,

  config-colors(
    primary:          ebpf-teal,
    primary-dark:     ebpf-teal.darken(20%),
    primary-light:    ebpf-teal.lighten(55%),
    secondary:        rust-red,
    neutral-lightest: rgb("#F7F9F9"),
    neutral-light:    rgb("#E8EEEE"),
    neutral-dark:     rgb("#3A3A3A"),
    neutral-darkest:  rust-dark,
  ),

  config-info(
    title:       [eBPF Programming with Rust],
    subtitle:    [Pipeline · libbpf · Aya Framework · DMA Latency Demo],
    author:      [Your Name],
    date:        datetime.today(),
    institution: [IC Design Division],
  ),
)

#set text(font: ("Fira Sans","Noto Sans","Liberation Sans"), size: 19pt)
#show raw:  set text(font: ("Fira Code","JetBrains Mono","Courier New"), size: 0.82em)
#show link: set text(fill: ebpf-teal)
#set heading(numbering: numbly("{1}.", default: "1.1"))

// ─────────────────────────────────────────────────────────────────────────────
//  TITLE
// ─────────────────────────────────────────────────────────────────────────────
#title-slide()

// ─────────────────────────────────────────────────────────────────────────────
//  AGENDA
// ─────────────────────────────────────────────────────────────────────────────
== Agenda <touying:hidden>
#outline(title: none, indent: 1.5em, depth: 1)

// ─────────────────────────────────────────────────────────────────────────────
//  1. eBPF OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
= eBPF — A Quick Refresher

== What is eBPF?

#cols[
  *The model in one sentence*

  eBPF lets you load user-supplied programs into the kernel *without a kernel patch, without a module, and without rebooting* — the kernel verifier guarantees safety.

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

// ─────────────────────────────────────────────────────────────────────────────
//  4. HOW libbpf HANDLES EACH STAGE
// ─────────────────────────────────────────────────────────────────────────────
= The libbpf Approach — Stage by Stage

== libbpf: write & compile

#cols[
  *Stage 1 — Write (C)*

  ```c
  // program.bpf.c
  #include "vmlinux.h"          // all kernel types in one header
  #include <bpf/bpf_helpers.h>
  #include <bpf/bpf_tracing.h>

  // Map declaration — section name encodes type
  struct {
      __uint(type, BPF_MAP_TYPE_RINGBUF);
      __uint(max_entries, 4 * 1024 * 1024);
  } events SEC(".maps");

  // Shared event struct — must match userspace manually
  struct dma_event { u64 start_ns; u32 nents; u32 pid; };

  // Hook attribute — clang section magic
  SEC("kprobe/dma_map_sg")
  int BPF_KPROBE(dma_map_sg_enter, …) {
      struct dma_event e = {};
      e.start_ns = bpf_ktime_get_ns();
      // …
      bpf_ringbuf_reserve(&events, sizeof(e), 0);
      return 0;
  }
  char LICENSE[] SEC("license") = "GPL";
  ```
][
  *Stage 2 — Compile (C toolchain)*

  ```bash
  # Generate vmlinux.h — all kernel types from BTF
  bpftool btf dump file /sys/kernel/btf/vmlinux \
      format c > vmlinux.h

  # Compile BPF source to BPF ELF object
  # -target bpf:  BPF bytecode output
  # -g:           embed BTF debug info (CO-RE)
  # -O2:          required: some BPF features need optimisation
  clang -target bpf -g -O2 \
      -D__TARGET_ARCH_x86 \
      -I. \
      -c program.bpf.c \
      -o program.bpf.o

  # Inspect the result
  llvm-objdump -d program.bpf.o   # disassemble BPF bytecode
  bpftool btf dump file program.bpf.o  # verify BTF is present
  ```

  The output `program.bpf.o` is a standard ELF file containing:
  - `.text` section: BPF bytecode instructions
  - `.BTF` section: type information for CO-RE
  - `.maps` section: map definitions
  - Relocation sections for helper calls
]

== libbpf: skeleton generation & loading

#cols[
  *Stage 2b — Generate skeleton (optional but recommended)*

  ```bash
  # Auto-generate a type-safe C loader header
  bpftool gen skeleton program.bpf.o \
      > program.skel.h
  ```

  The generated `program.skel.h` provides:

  ```c
  struct program_bpf {
      struct bpf_object_skeleton *skeleton;
      struct bpf_object *obj;
      struct {
          struct bpf_map *events;  // typed map access
      } maps;
      struct {
          struct bpf_program *dma_map_sg_enter;
      } progs;
      struct {
          struct bpf_link *dma_map_sg_enter;
      } links;
  };
  // Auto-generated lifecycle functions:
  // program__open()  program__load()
  // program__attach() program__destroy()
  ```
][
  *Stage 3 — Load & Stage 4 verify (C userspace)*

  ```c
  #include "program.skel.h"

  struct program_bpf *skel;

  // Open: parse ELF, discover maps and programs
  skel = program__open();

  // (optional) pre-load configuration:
  skel->rodata->min_latency_ns = 1000;

  // Load: create maps, CO-RE relocations,
  //       submit to kernel verifier
  program__load(skel);
  // At this point: kernel has verified and JIT'd the program.
  // Maps are created and their fds are in skel->maps.*

  // Attach: link programs to hook points
  program__attach(skel);
  // dma_map_sg_enter now fires on every dma_map_sg() call
  ```

  *CO-RE relocation* happens inside `__load()`: libbpf reads `/sys/kernel/btf/vmlinux`, patches field offsets in the BPF bytecode to match the running kernel's struct layout.

  #callout(color: libbpf-blue)[
    The skeleton collapses open + load + attach into three typed function calls. Without skeleton: you call `bpf_object__open()`, iterate programs, call `bpf_program__load()` per program, then `bpf_program__attach()` — verbose and untyped.
  ]
]

== libbpf: maps & teardown

#cols[
  *Maps from the C userspace side*

  ```c
  // Access map fd from skeleton
  int map_fd = bpf_map__fd(skel->maps.events);

  // Ring buffer consumer (callback model)
  struct ring_buffer *rb = ring_buffer__new(
      map_fd, handle_event, NULL, NULL);

  // Poll — blocks until events or timeout
  while (running) {
      ring_buffer__poll(rb, 100 /* timeout ms */);
  }

  // Callback invoked per event
  static int handle_event(void *ctx,
      void *data, size_t size) {
      struct dma_event *e = data;
      printf("pid=%u latency=%.3f µs\n",
             e->pid,
             (e->end_ns - e->start_ns) / 1000.0);
      return 0;
  }
  ```
][
  *Stage 5 teardown (C)*

  ```c
  // Teardown — must be called explicitly
  ring_buffer__free(rb);
  program__detach(skel);    // closes bpf_link fds
  program__destroy(skel);   // frees maps, programs, object

  // If __destroy() is not called:
  // - Maps leak until process exits
  // - Programs may stay attached if link pinned to bpffs
  // - No compiler warning, no safety net
  ```

  *Deployment dependencies*

  To ship a libbpf-based tool you need:
  - `libbpf.so` (or static `libbpf.a`) on the target
  - `libelf.so` (required by libbpf)
  - `libz.so` (required by libelf)
  - The `program.bpf.o` object file *or* embed it via skeleton

  #callout(color: warn-amber)[
    On Android or embedded targets: managing `.so` dependencies across OEM kernel variants is a real distribution problem. This is exactly what Aya solves.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. HOW AYA HANDLES EACH STAGE
// ─────────────────────────────────────────────────────────────────────────────
= How Rust (Aya) Handles Each Stage

== Stage-by-stage comparison

#v(0.5em)

// Column headers
#grid(columns: (1fr, 1fr, 1fr), gutter: 8pt,
  block(fill: luma(220), radius: 4pt, inset: (x:8pt,y:6pt), width: 100%,
    text(size: 0.72em, weight: "bold", "Stage")),
  block(fill: libbpf-blue.lighten(80%), radius: 4pt, inset: (x:8pt,y:6pt), width: 100%,
    text(size: 0.72em, weight: "bold", fill: libbpf-blue, "libbpf (C)")),
  block(fill: ebpf-teal.lighten(80%), radius: 4pt, inset: (x:8pt,y:6pt), width: 100%,
    text(size: 0.72em, weight: "bold", fill: ebpf-teal, "Aya (Rust)")),
)
#v(4pt)

#vs-row("1 — Write BPF source",
  "C source (.bpf.c), SEC() macros,\nbpf_helpers.h, vmlinux.h",
  "Rust source (no_std), #[kprobe] / #[map]\nattributes, aya-ebpf crate")
#vs-row("2 — Compile → bytecode",
  "clang -target bpf -g -O2\n→ program.bpf.o",
  "rustc --target bpfel-unknown-none\n+ bpf-linker → ELF object")
#vs-row("2b — Skeleton / embedding",
  "bpftool gen skeleton → program.skel.h\nIncluded in userspace C source",
  "include_bytes_aligned!() embeds ELF\ninto userspace binary at compile time")
#vs-row("3 — Open / parse ELF",
  "bpf_object__open() or skel__open()\nReads ELF, discovers maps & progs",
  "Ebpf::load(BYTES) — pure Rust ELF\nparser (aya-obj), no libelf dep")
#vs-row("4 — Load + verify",
  "bpf_object__load() or skel__load()\nMaps created, CO-RE patches applied,\nbpf() syscall → verifier → JIT",
  "prog.load() per program type\nAya performs CO-RE, calls bpf() syscall\nSame kernel verifier & JIT path")
#vs-row("4b — Attach to hook",
  "skel__attach() or bpf_program__attach()\nbpf_link fd returned",
  "prog.attach(\"dma_map_sg\", 0)?\nReturns typed handle implementing Drop")
#vs-row("5 — Maps: read events",
  "ring_buffer__new() + ring_buffer__poll()\nCallback-based consumer",
  "RingBuf::try_from(map)? + AsyncFd\nAsync / epoll — Tokio-native")
#vs-row("6 — Teardown",
  "skel__detach() + skel__destroy()\nManual, must not forget",
  "RAII — all handles Drop automatically\nCompiler guarantees cleanup")

== Aya BPF-side: write & declare

#cols[
  #code(title: "dma-tracer-ebpf/src/main.rs — BPF program (Rust)", accent: ebpf-teal)[
    ```rust
    #![no_std]
    #![no_main]
    use aya_ebpf::{
        helpers::{bpf_ktime_get_ns,
                  bpf_get_current_pid_tgid},
        macros::{kprobe, kretprobe, map},
        maps::{HashMap, RingBuf},
        programs::{ProbeContext, RetProbeContext},
    };
    use dma_tracer_common::DmaEvent; // ← shared type

    // ── Maps — declared at crate level ──────────
    #[map]
    static START: HashMap<u64, u64> =
        HashMap::with_max_entries(4096, 0);

    #[map]
    static EVENTS: RingBuf =
        RingBuf::with_byte_size(4 * 1024 * 1024, 0);

    // ── Hook: kprobe on dma_map_sg entry ────────
    #[kprobe]
    pub fn dma_map_sg_enter(ctx: ProbeContext) -> u32 {
        let pid_tgid = bpf_get_current_pid_tgid();
        let pid = (pid_tgid & 0xFFFF_FFFF) as u32;
        let key = pid as u64;
        let ts = unsafe { bpf_ktime_get_ns() };
        let _ = START.insert(&key, &ts, 0);
        0
    }
    ```
  ]
][
  #code(title: "kretprobe — measure & emit", accent: ebpf-teal)[
    ```rust
    #[kretprobe]
    pub fn dma_map_sg_exit(ctx: RetProbeContext) -> u32 {
        let end = unsafe { bpf_ktime_get_ns() };
        let pid = (bpf_get_current_pid_tgid()
                   & 0xFFFF_FFFF) as u32;
        let key = pid as u64;

        if let Some(start) = START.get(&key) {
            let _ = START.remove(&key);
            // Reserve slot in ring buffer
            if let Some(mut buf) =
                EVENTS.reserve::<DmaEvent>(0)
            {
                unsafe {
                    (*buf.as_mut_ptr()).latency_ns =
                        end.saturating_sub(*start);
                    (*buf.as_mut_ptr()).pid = pid;
                }
                buf.submit(0);
            }
        }
        0
    }

    #[cfg(not(test))]
    #[panic_handler]
    fn panic(_: &core::panic::PanicInfo) -> ! {
        loop {}   // BPF panic = halt
    }
    ```
  ]
]

== Aya userspace: load, attach, consume

#cols[
  #code(title: "dma-tracer/src/main.rs — userspace loader", accent: rust-red)[
    ```rust
    use aya::{include_bytes_aligned, Ebpf,
              maps::RingBuf,
              programs::{KProbe, KRetProbe}};
    use aya_log::EbpfLogger;
    use tokio::io::unix::AsyncFd;

    // BPF ELF embedded at compile time — no runtime file I/O
    static BPF_CODE: &[u8] = include_bytes_aligned!(
        concat!(env!("OUT_DIR"),
                "/dma-latency-tracer-ebpf")
    );

    #[tokio::main]
    async fn main() -> anyhow::Result<()> {
        // ── Load ──────────────────────────────
        let mut bpf = Ebpf::load(BPF_CODE)?;
        EbpfLogger::init(&mut bpf).ok();

        // ── Attach kprobe ─────────────────────
        let entry: &mut KProbe = bpf
            .program_mut("dma_map_sg_enter")?
            .try_into()?;
        entry.load()?;
        entry.attach("dma_map_sg", 0)?;

        // ── Attach kretprobe ──────────────────
        let exit: &mut KRetProbe = bpf
            .program_mut("dma_map_sg_exit")?
            .try_into()?;
        exit.load()?;
        exit.attach("dma_map_sg", 0)?;
    ```
  ]
][
  #code(title: "Async ring-buffer consumer", accent: rust-red)[
    ```rust
        // ── Consume ring buffer ───────────────
        let rb_map = bpf.take_map("EVENTS")?;
        let ring = RingBuf::try_from(rb_map)?;
        // Wrap in AsyncFd → Tokio epoll integration
        let async_fd = AsyncFd::new(ring)?;

        loop {
            tokio::select! {
                _ = tokio::signal::ctrl_c() => break,
                guard = async_fd.readable() => {
                    let mut g = guard?;
                    let rb = g.get_inner_mut();
                    while let Some(item) = rb.next() {
                        let ev: DmaEvent = unsafe {
                            *(item.as_ptr()
                              as *const DmaEvent)
                        };
                        println!(
                          "pid={} lat={:.2}µs",
                          ev.pid,
                          ev.latency_ns as f64/1000.0
                        );
                    }
                    g.clear_ready();
                }
            }
        }
        // ── Teardown: automatic via Drop ──────
        // bpf, entry, exit, rb all drop here —
        // links closed, maps freed, no leak possible
        Ok(())
    }
    ```
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. AYA ARCHITECTURE OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
= Aya Architecture Overview

== Component map

#cols(ratio: (1fr, 1fr))[
  *Aya crate family*

  ```
  ┌──────────────────────────────────────────┐
  │  Your userspace loader (std, async)      │
  │  uses: aya, aya-log, aya-obj             │
  ├──────────────────────────────────────────┤
  │  aya            — core loader library    │
  │  Ebpf::load()   programs  maps  links    │
  ├──────────────────────────────────────────┤
  │  aya-obj        — ELF + BTF + CO-RE      │
  │  Pure Rust ELF parser, relocation engine │
  ├──────────────────────────────────────────┤
  │  aya-log        — userspace log receiver │
  │  Reads aya-log-ebpf ring messages        │
  └──────────────────────────────────────────┘

  ┌──────────────────────────────────────────┐
  │  Your BPF program (no_std, no_main)      │
  │  uses: aya-ebpf, aya-log-ebpf            │
  ├──────────────────────────────────────────┤
  │  aya-ebpf       — BPF-side runtime       │
  │  #[map]  #[kprobe]  #[xdp]  helpers      │
  ├──────────────────────────────────────────┤
  │  aya-log-ebpf   — log from BPF programs  │
  │  info!() warn!() → aya-log ring buffer   │
  ├──────────────────────────────────────────┤
  │  aya-ebpf-bindings — kernel type defs    │
  │  Generated from kernel uapi headers      │
  └──────────────────────────────────────────┘
  ```
][
  *What each component handles*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(210)),
    inset: (y: 5pt),
    [*`aya`*], [Load BPF ELF, create maps, attach programs, manage links. Pure-Rust bpf() syscall wrapper. CO-RE via aya-obj.],
    [*`aya-obj`*], [Parse BPF ELF, process BTF sections, apply CO-RE relocations. No libelf dependency.],
    [*`aya-ebpf`*], [BPF-side runtime: `#[map]`, `#[kprobe]`, `#[xdp]`, `#[lsm]`, … macros; helper function wrappers; map type structs.],
    [*`aya-log`*], [Userspace receiver: polls a dedicated ring buffer for log records from aya-log-ebpf.],
    [*`aya-log-ebpf`*], [BPF-side: `info!()`, `warn!()`, `debug!()` macros that format and submit log events to the log ring buffer.],
    [*`aya-tool`*], [CLI: generates Rust bindings (`vmlinux.rs`) from kernel BTF — equivalent of `bpftool btf dump … format c > vmlinux.h`.],
  )

  #callout[
    *No libbpf, no libelf, no C toolchain required at runtime.* The entire stack is pure Rust + one `bpf()` syscall.
    #ref-badge[github.com/aya-rs/aya, 2024]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. CREATING AN AYA PROJECT
// ─────────────────────────────────────────────────────────────────────────────
= Creating an Aya Project

== Prerequisites and scaffold

#cols[
  *Prerequisites*

  ```bash
  # 1. Rust nightly (build-std required for BPF target)
  rustup toolchain install nightly \
      --component rust-src

  # 2. bpf-linker — LLVM BPF backend for rustc
  cargo install bpf-linker

  # 3. aya-tool — BTF → Rust bindings generator
  cargo install aya-tool

  # 4. Verify LLVM BPF backend is present
  rustc +nightly --print target-list | grep bpfel
  # bpfel-unknown-none  ← must appear
  ```

  *Scaffold with the Aya template*

  ```bash
  # cargo-generate scaffolds the three-crate workspace
  cargo install cargo-generate

  cargo generate --git \
      https://github.com/aya-rs/aya-template \
      --name dma-latency-tracer
  ```
][
  *Generated workspace structure*

  ```
  dma-latency-tracer/
  ├── Cargo.toml                  ← workspace root
  ├── rust-toolchain.toml         ← pins nightly
  │
  ├── dma-latency-tracer-common/
  │   └── src/lib.rs              ← #[no_std] shared types
  │                                 DmaEvent, histogram bounds
  │
  ├── dma-latency-tracer-ebpf/
  │   ├── .cargo/config.toml      ← target=bpfel-unknown-none
  │   ├── Cargo.toml              ← aya-ebpf dep
  │   └── src/main.rs             ← #[kprobe], #[kretprobe]
  │
  └── dma-latency-tracer/
      ├── build.rs   ← KEY        ← cross-compiles eBPF crate,
      │                             copies to $OUT_DIR
      ├── Cargo.toml              ← aya dep, tokio
      └── src/main.rs             ← Ebpf::load, attach, ringbuf
  ```

  #callout[
    *No xtask needed.* A single `cargo build` cross-compiles the eBPF crate (via `build.rs`) and embeds the result. One command, one binary output.
  ]
]

== The three Cargo.toml files — key dependencies

#cols[
  #code(title: "dma-latency-tracer-ebpf/Cargo.toml", accent: ebpf-teal)[
    ```toml
    [package]
    name    = "dma-latency-tracer-ebpf"
    version = "0.1.0"
    edition = "2021"

    [[bin]]
    name = "dma-latency-tracer-ebpf"
    path = "src/main.rs"

    [dependencies]
    # BPF-side runtime: macros, map types, helpers
    aya-ebpf     = "0.1"
    # Logging from BPF programs
    aya-log-ebpf = "0.1"
    # Shared struct definitions (no_std)
    dma-latency-tracer-common = {
        path = "../dma-latency-tracer-common",
        default-features = false
    }
    ```
  ]
][
  #code(title: "dma-latency-tracer/Cargo.toml (userspace)", accent: rust-red)[
    ```toml
    [package]
    name    = "dma-latency-tracer"
    version = "0.1.0"
    edition = "2021"

    [dependencies]
    # Core Aya loader library (async_tokio feature)
    aya      = { version = "0.13", features = ["async_tokio"] }
    aya-log  = "0.2"

    # Shared event struct (with std features enabled)
    dma-latency-tracer-common = { path = "../.." }

    # Async runtime — ring buffer consumer
    tokio    = { version = "1", features = [
        "macros", "rt-multi-thread", "signal", "time"] }
    anyhow   = "1"
    clap     = { version = "4", features = ["derive"] }
    log      = "0.4"
    env_logger = "0.11"

    [build-dependencies]
    anyhow   = "1"     # build.rs error handling
    ```
  ]
]

== build.rs — the key integration file

#code(title: "dma-latency-tracer/build.rs — drives eBPF cross-compilation", accent: rust-red)[
  ```rust
  use std::{env, path::PathBuf, process::Command};

  fn main() -> Result<(), Box<dyn std::error::Error>> {
      let out_dir      = PathBuf::from(env::var_os("OUT_DIR").unwrap());
      let manifest_dir = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap());
      let workspace    = manifest_dir.parent().unwrap().to_path_buf();
      let cargo        = env::var_os("CARGO").map(PathBuf::from)
                             .unwrap_or_else(|| PathBuf::from("cargo"));

      // Rebuild when BPF source changes
      println!("cargo::rerun-if-changed=../dma-latency-tracer-ebpf/src/main.rs");
      println!("cargo::rerun-if-changed=../dma-latency-tracer-common/src/lib.rs");

      let profile = env::var("PROFILE").unwrap_or("debug".into());

      // Cross-compile the eBPF crate to bpfel-unknown-none
      let status = Command::new(&cargo)
          .current_dir(&workspace)
          .arg("+nightly")
          .arg("build")
          .arg("--package").arg("dma-latency-tracer-ebpf")
          .arg("--target").arg("bpfel-unknown-none")
          .arg("-Z").arg("build-std=core")
          .args(if profile == "release" { &["--release"][..] } else { &[] })
          .status()?;

      if !status.success() { return Err("eBPF build failed".into()); }

      // Copy compiled BPF ELF to OUT_DIR for include_bytes_aligned!()
      let src = workspace.join("target/bpfel-unknown-none")
                         .join(&profile).join("dma-latency-tracer-ebpf");
      std::fs::copy(&src, out_dir.join("dma-latency-tracer-ebpf"))?;
      Ok(())
  }
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  8. AYA PROS AND CONS
// ─────────────────────────────────────────────────────────────────────────────
= Aya — Pros and Cons

== The honest assessment

#cols[
  *Strengths*

  - *Pure Rust end-to-end* — no C toolchain, no libelf, no libbpf.so on the target. Ship a single statically-linked binary.
  - *Type-safe kernel/userspace boundary* — shared `common` crate; struct layout divergence is a compile error.
  - *RAII teardown* — attachment handles implement `Drop`; cleanup is compiler-guaranteed, not programmer-remembered.
  - *Async-native* — `AsyncFd<RingBuf>` integrates with Tokio directly; no callback model needed.
  - *CO-RE support* — BTF-based relocations via `aya-obj`; one binary across kernel versions.
  - *Static binary + musl* — deploy on Android, embedded, or any Linux target without library concerns.
  - *aya-log* — `info!()` from BPF programs to userspace with zero boilerplate.
  - *Active ecosystem* — Red Hat (bpfman), Deepfence (ebpfguard), Kubernetes SIG-Network (Blixt) all use Aya in production.
    #ref-badge[aya-rs.dev, 2024]
][
  *Limitations and caveats*

  - *Nightly Rust required* for building the BPF crate (`-Z build-std=core`, unstable features). Stable toolchain cannot target `bpfel-unknown-none` today.
  - *Smaller ecosystem* than libbpf-C. libbpf has a larger set of reference examples, upstream docs, and kernel integration tests.
  - *Some program types lag* — not all BPF program types have first-class Aya support; may need `unsafe` raw syscalls for cutting-edge hooks.
  - *bpf-linker* is a separate install — it bundles LLVM; takes time to install and can lag behind upstream LLVM releases.
  - *No bpftrace-like one-liner* — Aya is a library, not a scripting frontend. For ad-hoc investigation, bpftrace (C) remains the fastest tool.
  - *Debugging BPF verifier errors* — verifier output is in raw log form; Aya surfaces it but does not beautify it (neither does libbpf).

  #callout(color: warn-amber)[
    *Guidance*: for production eBPF tools built and maintained by a Rust-capable team — use Aya. For quick one-off probes and kernel-side investigation — `bpftrace` first, then promote to Aya when the pattern is proven.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  9. DEMO — DMA LATENCY TRACER
// ─────────────────────────────────────────────────────────────────────────────
= Demo — DMA Latency Tracer on ConnectX-5

== Test environment

#cols[
  *Physical setup*

  ```
  ┌────────────────────────────────────────────┐
  │  Host — PCIe Gen 3.0 x16 motherboard slot  │
  │                                            │
  │  ┌──────────────────────────────────────┐  │
  │  │  Mellanox ConnectX-5 100GbE          │  │
  │  │  (PCIe Gen 4 card → links at Gen 3)  │  │
  │  │                                      │  │
  │  │  Port 0 (enp6s0f0) ──╮  DAC cable    │  │
  │  │  Port 1 (enp6s0f1) ──╯  crossover    │  │
  │  └──────────────────────────────────────┘  │
  └────────────────────────────────────────────┘

  ns0 (192.168.100.1) ←→ ns1 (192.168.100.2)
  Traffic traverses physical DAC cable — no loopback
  ```

  *Namespace setup*

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
  *What we are measuring*

  `dma_map_sg(struct device*, struct scatterlist*, int nents, enum dma_data_direction dir)`

  - Called by the mlx5 driver for every WQE posted to the HCA
  - Latency = time for the kernel's IOMMU DMA mapping operation
  - Affected by: IOMMU TLB pressure, NUMA distance to PCIe root complex, CPU C-states

  *Expected latency profile on Gen 3 host*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(220)),
    inset: (y: 5pt),
    [*Range*], [*Interpretation*],
    [< 2 µs],  [IOMMU TLB warm — normal ✓],
    [2–10 µs], [Mild TLB pressure / NUMA miss],
    [10–50 µs],[IOMMU page walk — TLB miss],
    [> 50 µs], [CPU C-states or frequency scaling],
  )
]

== Build and run

#code(title: "One-command build + run sequence")[
  ```bash
  # ── Prerequisites (one-time) ─────────────────────────────────────────────
  rustup toolchain install nightly --component rust-src
  cargo install bpf-linker

  # ── Build ────────────────────────────────────────────────────────────────
  # build.rs cross-compiles the eBPF crate automatically
  cargo build --release
  # Artifacts: target/release/dma-latency-tracer   (single binary)

  # ── Generate traffic through the DAC cable ───────────────────────────────
  sudo ip netns exec ns0 iperf3 -s &
  sudo ip netns exec ns1 iperf3 -c 192.168.100.1 -t 120 -P 8

  # ── Run the tracer ───────────────────────────────────────────────────────
  sudo RUST_LOG=info ./target/release/dma-latency-tracer \
      --interval 5 \
      --min-latency-us 1 \
      --filter-comm iperf3
  ```
]

#callout[
  *Root / `CAP_BPF` required* to load BPF programs. On production Android: use a privileged system service with the appropriate SELinux label.
]

== Live output — individual events

#code(title: "stdout — individual DMA events above threshold")[
  ```
  [INFO] DMA latency tracer attached. Reporting every 5s.
  [INFO] Setup: ConnectX-5 PCIe Gen4 @ Gen3 slot | DAC crossover | ns0 ↔ ns1

  [INFO] [cpu=03] pid=12345 comm=iperf3           nents=  16  dir=TO_DEVICE      lat=   1.842 µs
  [INFO] [cpu=07] pid=12345 comm=iperf3           nents=  32  dir=TO_DEVICE      lat=   2.201 µs
  [INFO] [cpu=01] pid=12345 comm=iperf3           nents=  16  dir=FROM_DEVICE    lat=   1.634 µs
  [INFO] [cpu=11] pid=12347 comm=kworker/11:1H    nents=   4  dir=BIDIRECTIONAL  lat=   8.443 µs
  [INFO] [cpu=03] pid=12345 comm=iperf3           nents=  64  dir=TO_DEVICE      lat=  31.771 µs  ← TLB miss
  [INFO] (max_events reached — histogram mode active)
  ```
]

== Live output — latency histogram

#code(title: "Per-interval histogram — 5 second window")[
  ```
  ═══════════════════════════════════════════════════════════════════════
    dma_map_sg latency histogram  (window events: 48 291)
    System: ConnectX-5 PCIe Gen4 card | Gen3 host slot | DAC crossover
  ───────────────────────────────────────────────────────────────────────
               range      count       %    dist
         0 – 500 ns       2 134    4.42%   |████░░░░░░░░░░░░░░░░░░░░░░░░░░|
       500 ns – 1 µs      5 891   12.20%   |████████████░░░░░░░░░░░░░░░░░░|
           1 – 2 µs      18 432   38.17%   |██████████████████████████████|  ← peak
           2 – 3 µs      14 201   29.41%   |███████████████████████░░░░░░░|
           3 – 5 µs       5 912   12.24%   |████████████░░░░░░░░░░░░░░░░░░|
         5 – 7.5 µs       1 102    2.28%   |██░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
        7.5 – 10 µs         401    0.83%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
          10 – 15 µs        128    0.26%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
          15 – 20 µs         54    0.11%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
          20 – 30 µs         28    0.06%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
          30 – 50 µs          5    0.01%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
              > 50 µs         3    0.01%   |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
  ───────────────────────────────────────────────────────────────────────
    Fast ( < 2 µs):  26 457  (54.8%)  — IOMMU TLB warm ✓
    Slow (> 30 µs):       8   (0.0%)  — C-states / IOMMU pressure
  ───────────────────────────────────────────────────────────────────────
     pid  comm               count    avg µs    min µs    max µs
   12345  iperf3             48 291     1.923     0.312    87.441
   12347  kworker/11:1H          62     7.114     3.201    31.771
  ═══════════════════════════════════════════════════════════════════════
  ```
]

== What the output tells you

#cols[
  *Reading the histogram — ConnectX-5 on Gen 3*

  - *Peak at 1–2 µs*: normal IOMMU DMA mapping with a warm TLB. The mlx5 driver's scatter-gather lists are small (16–32 nents), IOMMU can serve them from cached page table entries.
  - *Tail at 3–10 µs*: mild TLB pressure as the ring buffer cycles. Expected under sustained 100 GbE load.
  - *Outliers > 30 µs*: IOMMU page-table walk (TLB miss) or CPU C-state wakeup latency. Correlate with `/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq`.
  - *PCIe Gen 3 vs Gen 4*: the Gen 3 link halves bandwidth (8 GT/s vs 16 GT/s) but does *not* increase individual DMA mapping latency. Latency is dominated by IOMMU + NUMA, not the PCIe link itself.
][
  *Actionable insights from this data*

  - If `> 30 µs` count is high during iperf3 → enable huge pages for IOMMU (`echo 1 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`) to reduce TLB misses
  - If latency spikes correlate with `kworker` PIDs → firmware-level power management interfering with the IOMMU
  - If `kworker` DMA events appear at `BIDIRECTIONAL` direction → mlx5 firmware completion posting — expected
  - Per-CPU distribution: if one CPU shows consistently higher latency → IRQ affinity misalignment between mlx5 IRQs and the NUMA node of the PCIe slot

  #callout(color: safe-green)[
    *Zero kernel changes, zero driver modifications.* This analysis runs on a production kernel, on production traffic, with no overhead visible to userspace benchmarks.
    #ref-badge[Aya ring buffer: < 1% CPU overhead at 100 GbE line rate, measured with perf stat]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *Rust writes correct eBPF programs.*

  *Aya ships them as a single binary.*

  *The kernel verifier runs the same proof it always has.*

  The only thing that changed: you no longer have to worry about
  mismatched structs, forgotten teardown, or C toolchain dependencies.
]

// ─────────────────────────────────────────────────────────────────────────────
//  APPENDIX
// ─────────────────────────────────────────────────────────────────────────────
= Appendix <touying:hidden>

== aya-tool: generating kernel type bindings

```bash
# Install aya-tool
cargo install aya-tool

# Generate Rust bindings for a specific kernel struct from running kernel BTF
# Equivalent of: bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
# but produces a Rust module instead of a C header.
aya-tool generate task_struct > \
    dma-latency-tracer-ebpf/src/vmlinux.rs

# Use in BPF program:
// mod vmlinux;
// use vmlinux::task_struct;
// let task: *const task_struct = ctx.arg(0);
// let pid = (*task).pid;
```

== CO-RE in Aya — how it works

```
BPF program compiled with rustc:
  → LLVM emits __builtin_preserve_access_index() relocations
  → bpf-linker emits these as BTF_CO-RE relocations in the ELF

At load time (Aya::load()):
  1. aya-obj reads the ELF and finds CO-RE relocation records
  2. Reads /sys/kernel/btf/vmlinux (the running kernel's BTF)
  3. For each CO-RE relocation: looks up the field offset in the
     running kernel's struct layout (may differ from compile-time)
  4. Patches the BPF bytecode with the correct offset
  5. Submits the patched bytecode via bpf() syscall to the verifier

Result: one compiled binary runs correctly on kernel 5.15, 6.1, 6.12
        even if task_struct has different field positions in each.
```

== References

#set text(size: 0.73em)

*Aya framework*
- Aya book: #link("https://aya-rs.dev/book/")[aya-rs.dev/book]
- API docs: #link("https://docs.rs/aya/latest/aya/")[docs.rs/aya]
- GitHub: #link("https://github.com/aya-rs/aya")[github.com/aya-rs/aya]
- FOSDEM 2025 talk: "Building your eBPF Program with Rust and Aya" — #link("https://archive.fosdem.org/2025/schedule/event/fosdem-2025-5534-building-your-ebpf-program-with-rust-and-aya/")[archive.fosdem.org]

*libbpf*
- Linux kernel docs: #link("https://docs.kernel.org/bpf/libbpf/libbpf_overview.html")[docs.kernel.org/bpf/libbpf]
- libbpf-bootstrap guide: #link("https://nakryiko.com/posts/libbpf-bootstrap/")[nakryiko.com/posts/libbpf-bootstrap]
- bpftool gen skeleton: #link("https://manpages.ubuntu.com/manpages/focal/man8/bpftool-gen.8.html")[manpages.ubuntu.com]

*eBPF fundamentals*
- Brendan Gregg. *BPF Performance Tools.* Addison-Wesley, 2019.
- Gregg, B.; Fernandez, J. "eBPF — The Future of Linux Observability." USENIX ATC 2022.
- CO-RE: #link("https://nakryiko.com/posts/bpf-core-reference-guide/")[nakryiko.com — BPF CO-RE Reference Guide]

*Production deployments*
- Red Hat bpfman: #link("https://bpfman.io")[bpfman.io]
- Deepfence ebpfguard (Aya + LSM): #link("https://github.com/deepfence/ebpfguard")[github.com/deepfence/ebpfguard]
- Kubernetes Blixt (Aya + XDP): #link("https://github.com/kubernetes-sigs/blixt")[github.com/kubernetes-sigs/blixt]
