// ─────────────────────────────────────────────────────────────────────────────
//  Rust in the Linux Kernel
//  Typst / Touying — Metropolis theme
//
//  Audience: Senior kernel / C engineers at an IC design house
//  Scope   : Why a second language, IC-house relevance, kernel basics,
//            advantages & challenges, Hello World module + compile steps
//
//  Build:   typst compile rust-in-kernel.typ rust-in-kernel.pdf
//  Preview: VS Code + Tinymist extension → open file → click preview
//
//  Packages auto-downloaded on first compile:
//    @preview/touying:0.7.1
//    @preview/numbly:0.1.0
// ─────────────────────────────────────────────────────────────────────────────

#import "@preview/touying:0.7.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

// ── Colour palette ────────────────────────────────────────────────────────────
#let rust-red     = rgb("#CE422B")
#let rust-dark    = rgb("#1A1A1A")
#let safe-green   = rgb("#2D6A4F")
#let warn-amber   = rgb("#854D0E")
#let ref-blue     = rgb("#1B4F8A")
#let code-bg      = rgb("#1E1E2E")
#let code-fg      = rgb("#CDD6F4")
#let kw-col       = rgb("#CBA6F7")
#let cm-col       = rgb("#585B70")
#let ok-col       = rgb("#A6E3A1")
#let er-col       = rgb("#F38BA8")
#let hi-col       = rgb("#FAB387")
#let anno-col     = rgb("#89DCEB")

// ── Design helpers ────────────────────────────────────────────────────────────

// Left-accent callout box
#let callout(body, color: rust-red) = block(
  fill:   color.lighten(90%),
  stroke: (left: 3pt + color),
  inset:  (left: 10pt, top: 7pt, bottom: 7pt, right: 9pt),
  radius: (right: 4pt),
  width:  100%,
  body,
)

// Citation badge
#let ref-badge(body) = box(
  fill:   ref-blue.lighten(88%),
  stroke: 0.4pt + ref-blue,
  inset:  (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: ref-blue, size: 0.59em, style: "italic", body),
)

// Two-column grid
#let cols(l, r, ratio: (1fr, 1fr)) = grid(
  columns: ratio, gutter: 1.2em, l, r,
)

// Dark code block with optional bar-title
#let code(body, title: none) = {
  if title != none {
    block(
      fill:   rust-red.lighten(88%),
      inset:  (x: 10pt, y: 4pt),
      radius: (top: 5pt),
      width:  100%,
      text(size: 0.63em, weight: "bold", fill: rust-red, title),
    )
  }
  block(
    fill:   code-bg,
    radius: if title != none { (bottom: 5pt) } else { 5pt },
    inset:  11pt,
    width:  100%,
    text(
      font: ("Noto Sans", "JetBrains Mono", "Noto Sans"),
      fill: code-fg,
      size: 0.70em,
      body,
    ),
  )
}

// Inline shell prompt style
#let sh(t) = text(font: ("Comic Neue","JetBrains Mono","Courier New"),
                  fill: ok-col, size: 0.78em, raw(t))

// Coloured tag badge
#let tag(body, color: rust-red) = box(
  fill:   color,
  inset:  (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: white, size: 0.60em, weight: "bold", body),
)

// ── Theme setup ───────────────────────────────────────────────────────────────
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,

  config-colors(
    primary:          rust-red,
    primary-dark:     rust-red.darken(20%),
    primary-light:    rust-red.lighten(55%),
    secondary:        safe-green,
    neutral-lightest: rgb("#F9F8F6"),
    neutral-light:    rgb("#EBEBEA"),
    neutral-dark:     rgb("#3A3A3A"),
    neutral-darkest:  rust-dark,
  ),

  config-info(
    title:       [Rust in the Linux Kernel],
    subtitle:    [Why a second language · IC-house relevance · Basics · Hello World],
    author:      [Pulumati Ram],
    date:        datetime.today(),
    institution: [ < Realtek Semiconductor Corporation >],
  ),
)

#set text(font: ("Comic Neue","Noto Sans","Liberation Sans"), size: 19pt)
#show raw:  set text(font: ("Comic Neue","JetBrains Mono","Courier New"), size: 0.82em)
#show link: set text(fill: rust-red)
#set heading(numbering: numbly("{1}.", default: "1.1"))

// ─────────────────────────────────────────────────────────────────────────────
//  TITLE SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#title-slide()

// ─────────────────────────────────────────────────────────────────────────────
//  AGENDA
// ─────────────────────────────────────────────────────────────────────────────
== Agenda <touying:hidden>
#outline(title: none, indent: 1.5em, depth: 1)

// ─────────────────────────────────────────────────────────────────────────────
//  1. WHY A SECOND LANGUAGE?
// ─────────────────────────────────────────────────────────────────────────────
= Why a Second Language in the Kernel?

== The kernel's memory safety record — the honest numbers

#cols[
  *CVE analysis (2019, still representative in 2025)*

  - *~67 %* of Linux kernel CVEs → memory safety violations
    #ref-badge[Gaynor & Thomas, Linux Security Summit 2019]
  - *~70 %* of Microsoft OS CVEs → same root cause
    #ref-badge[Microsoft MSRC, Gavin Thomas, 2019]
  - *~70 %* of Chrome high-severity bugs → memory safety
    #ref-badge[Google Project Zero, 2020]

  The bug classes:

  #table(
    columns: (1fr, 1fr),
    stroke: (x: none, y: 0.3pt + luma(200)),
    inset: (y: 4pt),
    [use-after-free (UAF)], [null dereference],
    [buffer overflow / OOB], [uninitialized read],
    [data race / TOCTOU], [double free],
  )
][
  *Why tools alone are not enough*

  - *KASAN / KCSAN* — catch bugs at runtime, need a test to trigger them
  - *Coverity / sparse* — heuristic; high false-positive rate
  - *Coccinelle* — semantic patches; manual rule authoring per pattern
  - *Fuzzing (syzkaller)* — excellent, but coverage is probabilistic

  #callout[
    Tools *reduce* the rate. They do not *eliminate the class*.
    \ The only way to eliminate a class is to make it unrepresentable in the type system.
  ]

  *Rust's answer*: move the check from runtime / fuzzing / review to *every single compilation*.
]

== The "why not C++ / Ada / D?" question

Your senior engineers will ask. Here are the honest answers.

#cols[
  *C++*
  - No borrow checker → same UAF / data-race classes remain
  - RAII helps but is not enforced (raw pointers escape)
  - Greg KH (Feb 2025): *"C++ isn't going to give us any of that any decade soon"*
    #ref-badge[Greg Kroah-Hartman, LKML, February 2025]
  - `std::unique_ptr` requires discipline; compiler does not prove exclusivity

  *Ada / SPARK*
  - Strong safety record in aerospace / defence
  - Vanishingly small kernel developer community
  - No production Linux driver ecosystem; no active upstream effort
][
  *D, Zig, others*
  - No formal upstream effort with Linus' acceptance
  - No machine-checked soundness proof for their type systems

  *Rust — why it specifically*
  - *RustBelt* (POPL 2018): machine-checked Coq proof that the type system is sound
    #ref-badge[Jung et al., POPL 2018]
  - *Existing compiler* with LLVM backend (same as Clang; same optimiser)
  - *Active upstream effort* accepted by Linus, Greg KH, and the 2025 Maintainers Summit
  - *Industrial backing*: Google, Microsoft, Red Hat, Samsung, Collabora full-time engineers
    #ref-badge[Prossimo / ISRG, 2025]

  #callout(color: safe-green)[
    Rust is not chosen because it is fashionable. It is chosen because it is the only language with an in-tree upstream path, a formally verified type system, and a C-compatible LLVM codegen.
  ]
]

== The decision timeline — not an experiment anymore

#cols[
  *Chronology*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.3pt + luma(200)),
    inset: (y: 5pt),
    [*2019*], [Linux Security Summit: 67% CVE stat published],
    [*2020*], [Miguel Ojeda RFC: Rust for Linux],
    [*Oct 2022*], [Merged in kernel 6.1 — labelled "experimental"],
    [*Jan 2025*], [6.13: misc + char driver bindings — *"tipping point"* (GKH)],
    [*Feb 2025*], [GKH public post: *new drivers should be in Rust*],
    [*Dec 2025*], [Tokyo Maintainers Summit: *"experiment is done, Rust is here to stay"* — *zero pushback*],
  )

  #ref-badge[LWN.net; Phoronix; devclass.com; kernel.org]
][
  *Where we are in kernel 6.19 (2025)*

  - *~390 Rust source files* in mainline tree
  - `CONFIG_RUST` no longer marked experimental
  - In production: Android 16 (kernel 6.12) ships `ashmem` allocator in Rust — *millions of devices*
    #ref-badge[Miguel Ojeda, kernel.org, December 2025]

  *Subsystems with Rust code upstreamed*

  - Android Binder driver rewrite
  - Apple Asahi DRM GPU driver (largest in-tree Rust codebase)
  - Nova (open NVIDIA DRM) — Rust from day one
  - NVMe storage driver abstractions
  - PHY drivers, null block driver, DRM panic QR code
  - PCI + platform bindings merged (6.13) → almost all subsystems can now accept Rust

  #callout(color: safe-green)[
    Not a research project. Not a prototype. *Production code shipping on real hardware.*
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. DOES AN IC DESIGN HOUSE NEED TO CARE?
// ─────────────────────────────────────────────────────────────────────────────
= Does Our IC Design House Need to Care?

== The BSP / reference design reality

Your team ships *Board Support Packages* and *reference designs* based on Linux and Android. Here is where Rust intersects directly with that work.

#cols[
  *Driver deliverables your team owns*

  - PCIe endpoint / root complex drivers
  - DMA engine controllers
  - USB PHY / controller drivers
  - MIPI CSI / DSI host drivers
  - NPU / DSP accelerator drivers
  - Power management (PMIC, clock, regulators)
  - Custom inter-processor communication (IPC)

  These are exactly the *new peripheral driver* category that Greg KH is asking to be written in Rust going forward.
  #ref-badge[GKH, LKML, Feb 2025: "for new code / drivers, writing them in Rust… is a win for all of us"]
][
  *Android BSP implications*

  - Android 16 (GKI 6.12) ships Rust kernel code in production
  - *Google AOSP mandates Rust for new Android system components*
    #ref-badge[Android Security Blog, 2021–2024]
  - OEMs and SoC vendors that supply GKI-compliant BSPs will increasingly receive Rust driver templates from Google
  - Failing to support Rust in your kernel team = compatibility risk for next-generation Android targets

  #callout[
    *The question is not whether you will encounter Rust kernel code.*
    \ It is whether you will be *reading* it (catching up) or *writing* it (leading).
  ]
]

== Regulatory and commercial pressure

#cols[
  *Regulatory tailwinds*

  - US CISA (2023–2024): explicit guidance to move to memory-safe languages; *C and C++ flagged as unsafe by default*
    #ref-badge[CISA, "The Case for Memory Safe Roadmaps", 2023]
  - EU Cyber Resilience Act (2024): product security requirements; memory-safe code is a concrete mitigation
  - US National Cybersecurity Strategy (2023): shift liability toward language-level safety

  *What this means for an IC design house:*

  OEM customers in automotive, industrial, and medical markets will ask:
  _"What is your memory-safety strategy for kernel drivers delivered with this SoC?"_

  A Rust driver is a concrete, auditable answer.
][
  *Competitive positioning*

  - BSP vendors who can *deliver* Rust-capable drivers will have an advantage in 2026+ RFQs
  - The driver audit surface with Rust is *explicit*:
    `grep -rn "unsafe"` gives the complete list of manually-verified code
  - Reduced CVE exposure in delivered BSPs = fewer post-shipment patch obligations

  *Talent pipeline*

  - Computer science graduates entering the workforce in 2024–2026 are learning Rust in university curricula (Stanford, MIT, CMU, ETH Zürich all now teach Rust)
  - Teams that establish Rust kernel competence attract this cohort
  - A Rust kernel module in the interview process is a differentiator

  #callout(color: safe-green)[
    *Bottom line*: Rust in the kernel is not optional for a serious Linux/Android BSP vendor on a 3–5 year horizon. The question is *how fast* to invest.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. KERNEL RUST — BASIC DEVELOPMENT CONCEPTS
// ─────────────────────────────────────────────────────────────────────────────
= Kernel Rust — Basic Development Concepts

== The three-layer architecture

#cols(ratio: (1.05fr, 0.95fr))[
  *How Rust code lives in the kernel*

  ```
  ┌─────────────────────────────────────────────┐
  │  Your driver / subsystem code               │
  │  (pure safe Rust — no raw C calls)          │
  │  drivers/misc/my_driver.rs                  │
  └──────────────┬──────────────────────────────┘
                 │  uses only safe abstractions
  ┌──────────────▼──────────────────────────────┐
  │  rust/kernel/   —  Safe abstraction layer   │
  │  Mutex<T>  SpinLock<T>  Task  WorkQueue     │
  │  Device  Platform  PCI  Net  IRQ  DMA …     │
  │  Written once, reviewed once, safe forever  │
  └──────────────┬──────────────────────────────┘
                 │  wraps (unsafe internally)
  ┌──────────────▼──────────────────────────────┐
  │  rust/bindings/  — Raw FFI (auto-generated) │
  │  Generated by bindgen from C headers        │
  │  All calls are unsafe — never call directly │
  └──────────────┬──────────────────────────────┘
                 │
  ┌──────────────▼──────────────────────────────┐
  │  rust/helpers/  — C stub wrappers           │
  │  Wraps inline C functions / macros that     │
  │  bindgen cannot parse                       │
  └─────────────────────────────────────────────┘
  ```
][
  *The key design invariant*

  - Driver code *never* calls `rust/bindings/` directly
  - This is enforced by convention + code review (not yet the compiler, but that is the goal)
  - The unsafe boundary is quarantined in one layer

  *What the `kernel` crate provides today*
  #ref-badge[docs.kernel.org/rust; rust-for-linux.github.io/docs/kernel]

  - `kernel::sync` — Mutex, SpinLock, RwLock, CondVar, Arc
  - `kernel::task` — Task (process / thread handle)
  - `kernel::workqueue` — deferred work
  - `kernel::net` — networking abstractions
  - `kernel::platform` — platform device / driver
  - `kernel::pci` — PCI device / driver (6.13+)
  - `kernel::dma` — DMA coherent allocator
  - `kernel::irq` — interrupt handling
  - `kernel::of` — Device Tree / Open Firmware

  #callout[
    If the abstraction you need does not exist yet in `rust/kernel/`, *that is where your team contributes*. This is a strength: force-multiplied by the safe wrapper being shared upstream.
  ]
]

== What changes vs. C kernel development

#cols[
  *What stays the same*
  - kbuild / Kconfig — same `obj-$(CONFIG_FOO) += foo.o` style
  - `insmod` / `rmmod` / `modinfo` — identical
  - `dmesg` — same output; `pr_info!` maps to `printk(KERN_INFO …)`
  - Module signing, GPL license requirement
  - Debugging: KASAN, KCSAN, ftrace, perf — all work with Rust modules
  - Review process, LKML submission, git send-email / b4

  *What is fundamentally different*
  - No `module_init` / `module_exit` — replaced by the `module!` macro + `impl Module` + `impl Drop`
  - No `goto err_free_X` chains — RAII handles all cleanup paths
  - Error returns are `Result<T, E>` not `int` — can't be silently ignored
  - No null pointers — `Option<T>` forces explicit handling
  - Data structure sharing across threads must implement `Sync` (compiler enforced)
][
  *The kbuild integration*

  Rust source files are first-class citizens in kbuild:

  ```makefile
  # In your subsystem Makefile — exactly like C
  obj-$(CONFIG_MY_RUST_DRIVER) += my_driver.o

  # kbuild sees .rs source → invokes rustc automatically
  # No separate cargo invocation needed for in-tree modules
  ```

  ```kconfig
  # In your Kconfig
  config MY_RUST_DRIVER
      tristate "My Rust peripheral driver"
      depends on RUST          # gates on Rust availability
      depends on PCI
      help
        Rust implementation of the XYZ peripheral driver.
        Provides memory-safe DMA engine management.
  ```

  #callout[
    The Kbuild system calls `rustc` automatically when it sees `.rs` objects — you do not invoke cargo for in-tree modules. Cargo is only used for *out-of-tree* development with the `build.rs` pattern.
  ]
]

== Key concepts: `module!`, `impl Module`, `impl Drop`

Three macros / traits replace everything `module_init` / `module_exit` do in C.

#cols[
  *C*

  ```c
  static int __init my_init(void)
  {
      pr_info("loaded\n");
      /* allocate resources */
      return 0;
  err_free:
      /* manual cleanup of everything allocated so far */
      return -ENOMEM;
  }

  static void __exit my_exit(void)
  {
      /* must mirror every allocation in init */
      pr_info("unloaded\n");
  }

  module_init(my_init);
  module_exit(my_exit);
  MODULE_LICENSE("GPL");
  MODULE_AUTHOR("…");
  MODULE_DESCRIPTION("…");
  ```
][
  *Rust*

  ```rust
  use kernel::prelude::*;

  module! {                         // replaces MODULE_* macros
      type: MyDriver,               // + wires init/exit
      name: "my_driver",
      author: "Your Name",
      description: "Rust driver",
      license: "GPL",
  }

  struct MyDriver { /* owned resources */ }

  impl kernel::Module for MyDriver {
      fn init(_module: &'static ThisModule)
          -> Result<Self>           // ← Result, not int
      {
          pr_info!("loaded\n");
          Ok(MyDriver { /* … */ })  // Err → never loaded
      }                             // no goto needed
  }

  impl Drop for MyDriver {
      fn drop(&mut self) {          // called on rmmod
          pr_info!("unloaded\n");
          // resources drop automatically in field order
      }
  }
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  4. ADVANTAGES
// ─────────────────────────────────────────────────────────────────────────────
= Advantages of Rust in Kernel Development

== Compile-time guarantees — what you gain immediately

#cols[
  *UAF and dangling pointers — eliminated*

  The borrow checker proves at compile time that no reference outlives the data it points to. In kernel terms: no IRQ handler can hold a pointer to a `struct device` that has been unregistered.

  *Data races — eliminated in safe code*

  `SpinLock<T>` in Rust wraps the data — you *cannot access the data without holding the lock*. It is a compile error, not a bug discovered in a test.

  ```rust
  let guard = my_spinlock.lock(); // guard is the ticket
  guard.field = value;    // only accessible via guard
  // guard drops here → lock released automatically
  ```
][
  *Exhaustive error handling*

  ```rust
  // This is a COMPILE WARNING in Rust:
  dma_map_sg(dev, sg, nents, dir);
  // warning: unused `Result` that must be used

  // In C, this is silent — no warning, no error:
  // dma_map_sg(dev, sg, nents, dir); // return value dropped
  ```

  *`Option<T>` replaces nullable pointers*

  Every pointer that "might be NULL" in C becomes `Option<&T>` or `Option<Box<T>>`. The compiler forces you to handle `None` before accessing the value. Null dereferences become a type error.

  #callout(color: safe-green)[
    Quote from Greg KH (Feb 2025): *"the vast majority of the kernel bugs are due to stupid little corner cases in C that are totally gone in Rust."*
    #ref-badge[GKH, Linux Kernel Mailing List, February 2025]
  ]
]

== Structural advantages for a large IC design team

#cols[
  *Safe API design*

  Greg KH (Feb 2025): *"Rust also gives us the ability to define our in-kernel APIs in ways that make them almost impossible to get wrong when using them."*
  #ref-badge[GKH, LKML, Feb 2025]

  - A DMA mapping API that accepts only the correct enum for direction — not an integer
  - A platform driver `probe` that *must* return a `Result` — not hope the engineer checked `ret`
  - Lock ordering encoded in the type system — no more `lockdep` surprises

  *Auditable unsafe surface*

  ```bash
  # Complete audit surface for your BSP driver:
  grep -rn "unsafe" drivers/my_soc/

  # In C: every line of the file is the audit surface
  ```
][
  *Refactoring confidence*

  When you change a struct — add a field, remove a field, change a type — Rust's compiler shows you *every* call site that breaks. In C this requires careful manual search, grep heuristics, and hoping the testsuite covers the missed paths.

  For a large IC design team maintaining multiple SoC generations of BSPs, this is a *multiplier on maintainer productivity*.

  *Documentation enforced by the type system*

  - `#[must_use]` on any `Result`-returning function → callers cannot silently discard it
  - Lifetime annotations document how long a reference is valid
  - Trait bounds document what a function requires of its arguments

  #callout(color: safe-green)[
    *Empirical data* (USENIX ATC 2024 study of Rust-for-Linux): Rust drivers have fewer post-merge bug fixes than equivalent C drivers in the same subsystem period.
    #ref-badge[Li et al., "An Empirical Study of Rust-for-Linux", USENIX ATC 2024]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. CHALLENGES
// ─────────────────────────────────────────────────────────────────────────────
= Challenges — The Honest Picture

== Technical challenges

#cols[
  *Toolchain pinning*

  - Each kernel release requires a *specific* `rustc` version
  - The kernel uses unstable compiler features (e.g., `core_ffi_c`, allocator API)
  - You cannot just `rustup update` — the version must match
  - Script: `scripts/min-tool-version.sh rustc` tells you the exact version

  ```bash
  # Pin the correct version for this kernel tree:
  rustup override set \
    $(scripts/min-tool-version.sh rustc)
  ```

  *Abstraction coverage lag*

  - The `rust/kernel/` abstraction layer covers only a fraction of the full C kernel API surface
  - If your subsystem's C API doesn't have a Rust wrapper yet, *you write the wrapper*
  - This is getting faster: 6.13 brought PCI + platform + misc bindings

  *pahole / BTF interaction*

  - When `CONFIG_DEBUG_INFO_BTF=y` and `CONFIG_RUST=y` are both set, `pahole` must support `--lang-exclude=rust` (v1.24+) to exclude Rust DWARF from BTF generation
  - A common "silent gotcha" for teams enabling Rust + eBPF CO-RE in the same build
][
  *Dual-language CI burden*

  - Two compilers, two sanitiser configurations
  - `KASAN_SW_TAGS` is incompatible with `CONFIG_RUST` — must use full KASAN instead
  - Rust compiler error messages look different from GCC/Clang — new skill for CI triage

  *Cultural / social friction*

  - Not all subsystem maintainers accept Rust patches (their right under kernel policy)
  - Some have expressed strong opposition — Christoph Hellwig resigned as DMA maintainer partly over this
    #ref-badge[LWN.net, February 2025]
  - Linus Torvalds has said he would override maintainers who refuse Rust without technical justification
    #ref-badge[Phoronix, March 2025]

  #callout(color: warn-amber)[
    *Mitigation strategy for IC teams*: target *new* peripheral drivers and new IP blocks. Do not attempt to rewrite existing C drivers (that path is not upstream-friendly and provides the most friction). Focus on greenfield.
  ]
]

== Practical gotchas for kernel module development

#cols[
  *No `std`, no heap by default*

  - Kernel Rust is `#![no_std]` — the full Rust standard library is unavailable
  - `String`, `Vec`, `HashMap` are available via the kernel's `alloc` crate (backed by slab allocator) — but you must use `kernel::alloc` not `std::collections`
  - No panics with stack traces — `panic!` in kernel Rust → kernel `BUG()` / halt

  *`no_std` compatible patterns*

  ```rust
  // Wrong — std not available
  use std::vec::Vec;

  // Correct — kernel's alloc-backed Vec
  use kernel::prelude::*;
  // KVec, KBox, etc. from kernel crate
  ```

  *GDB / symbol demangling*

  - Rust uses the v0 symbol mangling scheme
  - GDB < 10.2 and Binutils < 2.36 don't understand it → symbols show as garbage
  - Fix: `sudo apt install gdb` (GDB 12+ on Ubuntu 22.04+) — then Rust symbols demangle correctly
][
  *The rustc version dance in CI*

  Every kernel version pins a specific Rust compiler. If your CI builds the kernel with a different rustc than the one `scripts/min-tool-version.sh rustc` specifies, the build *silently fails or produces wrong output*.

  *Recommended CI setup*

  ```bash
  # In CI entry script:
  cd $KERNEL_SRC
  REQUIRED=$(scripts/min-tool-version.sh rustc)
  rustup override set $REQUIRED
  rustup component add rust-src rustfmt clippy
  cargo install --locked \
    --version $(scripts/min-tool-version.sh bindgen) \
    bindgen-cli

  # Verify everything is ready:
  make LLVM=1 rustavailable
  # Should print: Rust is available!
  ```

  #callout(color: warn-amber)[
    The *single most common failure* when setting up a new Rust kernel build environment: wrong `rustc` version or missing `rust-src` component. `make LLVM=1 rustavailable` diagnoses every dependency in one command.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. HELLO WORLD — STEP BY STEP
// ─────────────────────────────────────────────────────────────────────────────
= Hello World Kernel Module — Step by Step

== Step 1 — Prerequisites

#cols[
  *System requirements*

  - Linux kernel 6.1+ source (6.8+ recommended)
  - x86_64 or aarch64 host (ARM64 Rust kernel support: 6.1+)
  - LLVM + Clang (same version as rustc's embedded LLVM)
  - `pahole` ≥ 1.16 (dwarves package)

  ```bash
  # Ubuntu 22.04 / 24.04
  sudo apt update && sudo apt install -y \
    build-essential libncurses-dev bison flex \
    libssl-dev libelf-dev clang lld llvm \
    dwarves bc python3

  # Fedora 39+
  sudo dnf install -y \
    gcc make ncurses-devel bison flex \
    openssl-devel elfutils-libelf-devel \
    clang lld llvm dwarves bc python3
  ```
][
  *Rust toolchain*

  ```bash
  # 1. Install rustup (if not already present)
  curl --proto '=https' --tlsv1.2 \
    -sSf https://sh.rustup.rs | sh
  source "$HOME/.cargo/env"

  # 2. Get the kernel source
  git clone --depth=1 \
    https://git.kernel.org/pub/scm/linux/kernel/git/\
    torvalds/linux.git
  cd linux

  # 3. Pin the exact rustc version this kernel requires
  rustup override set \
    $(scripts/min-tool-version.sh rustc)

  # 4. Add required components
  rustup component add rust-src rustfmt clippy

  # 5. Install bindgen (version pinned by the kernel)
  cargo install --locked \
    --version $(scripts/min-tool-version.sh bindgen) \
    bindgen-cli
  ```

  #callout[
    Steps 3–5 are *different for every kernel version*. The `scripts/min-tool-version.sh` script is the source of truth.
  ]
]

== Step 2 — Verify the toolchain

Before touching Kconfig, confirm everything is wired up correctly.

#code(title: "Toolchain verification — run this first")[
  ```bash
  cd linux

  # This command runs the exact same checks as Kconfig.
  # If anything is missing it explains WHY, not just that it failed.
  make LLVM=1 rustavailable

  # Expected output when everything is correct:
  # Rust is available!

  # Common failure outputs and their fixes:
  # "rustc version X is too old"
  #   → rustup override set $(scripts/min-tool-version.sh rustc)
  #
  # "rust-src component is missing"
  #   → rustup component add rust-src
  #
  # "bindgen X is required but Y was found"
  #   → cargo install --locked \
  #       --version $(scripts/min-tool-version.sh bindgen) bindgen-cli
  #
  # "pahole version X is too old"
  #   → install dwarves ≥ 1.24 from your distro or source
  ```
]

== Step 3 — Configure the kernel

#code(title: "Kernel configuration — enable Rust support")[
  ```bash
  # Start from a known-good minimal config
  make LLVM=1 defconfig

  # Open the interactive menu
  make LLVM=1 menuconfig
  # Navigate: General setup → [*] Rust support

  # OR set it directly (faster in scripts)
  scripts/config --enable CONFIG_RUST
  scripts/config --enable CONFIG_SAMPLES
  scripts/config --enable CONFIG_SAMPLES_RUST
  # CONFIG_SAMPLES_RUST enables all samples/rust/ modules

  # Verify the config is coherent
  make LLVM=1 olddefconfig

  # Check that CONFIG_RUST is actually set
  grep "^CONFIG_RUST" .config
  # Expected: CONFIG_RUST=y
  ```
]

#callout[
  `CONFIG_RUST` will *not appear* in menuconfig until `make LLVM=1 rustavailable` succeeds. This is intentional — the Kconfig guard prevents a broken build before the toolchain is ready.
]

== Step 4 — Examine the in-tree Hello World

The kernel ships a canonical example at `samples/rust/rust_minimal.rs`. Study this before writing your own.

#code(title: "samples/rust/rust_minimal.rs — annotated")[
  ```rust
  // SPDX-License-Identifier: GPL-2.0
  //! A minimal Rust kernel module — the authoritative sample.
  //! Source: samples/rust/rust_minimal.rs

  use kernel::prelude::*;          // pr_info!, Result, ThisModule, etc.

  module! {
      type: RustMinimal,           // the struct that represents this module
      name: "rust_minimal",        // name shown by lsmod / modinfo
      author: "Rust for Linux Contributors",
      description: "Rust minimal sample",
      license: "GPL",              // required to use GPL-exported symbols
  }

  struct RustMinimal {
      numbers: Vec<i32>,           // owned resources — freed when module unloads
  }

  impl kernel::Module for RustMinimal {
      // Called on insmod.  Returns Ok(Self) or Err → module not loaded.
      fn init(_module: &'static ThisModule) -> Result<Self> {
          pr_info!("Rust minimal sample (init)\n");

          let mut numbers = Vec::new();
          numbers.try_push(72)?;   // try_push returns Result — ? propagates error
          numbers.try_push(108)?;
          numbers.try_push(200)?;

          Ok(RustMinimal { numbers })
      }
  }

  impl Drop for RustMinimal {
      // Called on rmmod.  The compiler GUARANTEES this runs — no exceptions.
      fn drop(&mut self) {
          pr_info!("Rust minimal sample (exit) numbers: {:?}\n",
                   self.numbers);
      }    // self.numbers is freed HERE automatically
  }
  ```
]

== Step 5 — Write your own Hello World

For a *standalone* file in the samples directory, the minimal scaffolding:

#cols[
  #code(title: "samples/rust/rust_helloworld.rs")[
    ```rust
    // SPDX-License-Identifier: GPL-2.0
    //! Hello World Rust kernel module.

    use kernel::prelude::*;

    module! {
        type: HelloWorld,
        name: "rust_helloworld",
        author: "Your Name <you@company.com>",
        description: "Hello World — IC Design Division",
        license: "GPL",
    }

    struct HelloWorld;

    impl kernel::Module for HelloWorld {
        fn init(_: &'static ThisModule)
            -> Result<Self>
        {
            pr_info!("Hello, Rust kernel world!\n");
            pr_info!("  Running on: {}\n",
                c_str!("IC Design SoC BSP"));
            Ok(HelloWorld)
        }
    }

    impl Drop for HelloWorld {
        fn drop(&mut self) {
            pr_info!("Goodbye from Rust!\n");
        }
    }
    ```
  ]
][
  *Register it with kbuild*

  Add to `samples/rust/Kconfig`:

  ```kconfig
  config SAMPLE_RUST_HELLOWORLD
      tristate "Hello World sample"
      depends on RUST
      help
        Builds the Hello World Rust module.
        To compile as loadable: M
        To build into kernel:   Y
  ```

  Add to `samples/rust/Makefile`:

  ```makefile
  obj-$(CONFIG_SAMPLE_RUST_HELLOWORLD) += \
      rust_helloworld.o
  ```

  Enable in config:

  ```bash
  scripts/config \
    --module CONFIG_SAMPLE_RUST_HELLOWORLD
  ```
]

== Step 6 — Build the module

#code(title: "Build the kernel with the Rust sample module")[
  ```bash
  # Option A — build the full kernel (first-time)
  # LLVM=1 uses clang + lld (best-supported Rust toolchain)
  make LLVM=1 -j$(nproc)

  # Option B — build only the samples directory (faster iteration)
  make LLVM=1 samples/rust/

  # Option C — build a specific module file
  make LLVM=1 samples/rust/rust_helloworld.o

  # Inspect the resulting module
  ls -lh samples/rust/rust_helloworld.ko
  modinfo samples/rust/rust_helloworld.ko
  # filename:       …/rust_helloworld.ko
  # author:         Your Name <you@company.com>
  # description:    Hello World — IC Design Division
  # license:        GPL
  # vermagic:       6.X.0 SMP preempt mod_unload

  # Optional: disassemble the BPF-free ELF to verify codegen
  llvm-objdump -d samples/rust/rust_helloworld.ko | head -40
  ```
]

#callout[
  The `.ko` output is a standard ELF kernel module — the same format as any C module. `insmod`, `lsmod`, `rmmod`, `modprobe` all work identically.
]

== Step 7 — Load, test, unload

Use a VM or a development board. Do *not* load untested kernel modules on a production machine.

#code(title: "Load, observe, unload — in a VM or dev board")[
  ```bash
  # Load the module (requires root / CAP_SYS_MODULE)
  sudo insmod samples/rust/rust_helloworld.ko

  # Verify it is loaded
  lsmod | grep rust_helloworld
  # rust_helloworld    12288  0

  # Read the kernel log
  sudo dmesg | tail -5
  # [  245.831042] rust_helloworld: Hello, Rust kernel world!
  # [  245.831044] rust_helloworld:   Running on: IC Design SoC BSP

  # Inspect module metadata
  cat /sys/module/rust_helloworld/version   # if set
  ls  /sys/module/rust_helloworld/

  # Unload the module — triggers Drop::drop()
  sudo rmmod rust_helloworld

  # Verify the exit message
  sudo dmesg | tail -3
  # [  312.441187] rust_helloworld: Goodbye from Rust!
  ```
]

== Step 8 — IDE support (rust-analyzer)

One command generates `rust-project.json` for full IDE intelligence — autocomplete, inline errors, go-to-definition — inside the kernel tree.

#code(title: "Enable rust-analyzer LSP for the kernel tree")[
  ```bash
  # Generate the rust-project.json that tells rust-analyzer
  # about the kernel's no_std environment and crate structure
  make LLVM=1 rust-analyzer

  # Generated file: rust-project.json in the kernel root
  ls -lh rust-project.json

  # VS Code: open the kernel directory, install the
  # "rust-analyzer" extension — it picks up rust-project.json
  # automatically.

  # Neovim (via nvim-lspconfig):
  # rust-analyzer will use rust-project.json if present.

  # Generate kernel API documentation (HTML)
  make LLVM=1 rustdoc
  xdg-open Documentation/output/rust/rustdoc/kernel/index.html
  ```
]

#callout[
  With `rust-analyzer` configured, you get: inline borrow-checker errors as you type, auto-complete for `kernel::sync::Mutex` and all other kernel crate types, jump-to-definition across the `rust/kernel/` abstraction layer, and inline documentation from `rustdoc` comments. The same IDE experience as userspace Rust — in kernel code.
]

== Build flow summary

#cols[
  *Complete flow from scratch*

  ```
  1. Install LLVM / Clang / dwarves
         ↓
  2. Install rustup
         ↓
  3. Clone kernel source
         ↓
  4. rustup override set
       $(scripts/min-tool-version.sh rustc)
         ↓
  5. rustup component add rust-src rustfmt clippy
         ↓
  6. cargo install bindgen-cli
       (version from scripts/min-tool-version.sh bindgen)
         ↓
  7. make LLVM=1 rustavailable    ← verify
         ↓
  8. make LLVM=1 menuconfig       ← enable CONFIG_RUST
         ↓
  9. make LLVM=1 -j$(nproc)       ← build
         ↓
  10. sudo insmod your_module.ko  ← load
         ↓
  11. dmesg | tail                ← observe
         ↓
  12. sudo rmmod your_module      ← unload
  ```
][
  *Key differences from C module development*

  #table(
    columns: (1fr, 1fr),
    stroke: (x: none, y: 0.3pt + luma(200)),
    inset: (y: 5pt),
    [*C*], [*Rust*],
    [`module_init` / `module_exit`], [`module!` + `impl Module` + `impl Drop`],
    [`MODULE_LICENSE("GPL")`], [`license: "GPL"` in `module!`],
    [`goto err_free_X`], [RAII — no labels needed],
    [`int ret = fn(); if (ret) …`], [`fn()?;` — propagates automatically],
    [`if (!ptr) return -ENOMEM;`], [`Option<T>` — forced by type system],
    [sparse / Coccinelle for lint], [clippy + rustfmt built-in],
    [`printk(KERN_INFO …)`], [`pr_info!("…\n")`],
  )

  *Compiler flag*: always use `LLVM=1` for Rust builds.
  GCC support exists but is still experimental (gccrs).

  #callout(color: safe-green)[
    *First goal for your team*: get `make LLVM=1 rustavailable` printing "Rust is available!" on every developer machine. That is the foundation everything else builds on.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  7. ADOPTION ROADMAP FOR AN IC DESIGN HOUSE
// ─────────────────────────────────────────────────────────────────────────────
= Adoption Roadmap

== Practical 12-month plan for your team

#cols[
  *Phase 1 — Foundation (months 1–3)*

  - Form a *Rust kernel guild*: 3–5 engineers from existing kernel team
  - Every dev machine: `make LLVM=1 rustavailable` → "Rust is available!"
  - Walk through `samples/rust/` — run each sample, read each source
  - `make LLVM=1 rust-analyzer` → IDE configured
  - Read `Documentation/rust/` in the kernel tree
  - Target: each guild member loads / unloads `rust_minimal.ko` from their own build

  *Phase 2 — First real module (months 3–6)*

  - Shadow an existing *simple* C driver in Rust:
    - A GPIO controller or I2C adapter (simple register I/O)
    - A misc char device that exposes a sysfs attribute
  - Write the Kconfig / Makefile integration
  - Run both the C and Rust versions in parallel; compare `dmesg`, `/sys` output, and KASAN results
  - Measure: lines of code, `unsafe` count, bug count post-merge
][
  *Phase 3 — Greenfield Rust driver (months 6–12)*

  - The *next new peripheral IP block* gets its kernel driver written in Rust from day one
  - Target PCI or platform driver (bindings upstream since 6.13)
  - Consider upstream submission — even a driver that does not merge teaches your team the process and builds relationships with subsystem maintainers

  *Phase 4 — BSP integration*

  - Include the Rust-capable toolchain in your BSP SDK / Yocto layer
  - Add `make LLVM=1 rustavailable` to your BSP CI gate
  - Document the `rustup override set` step in your BSP bring-up guide
  - Evaluate using Rust for Android HAL native components (userspace Rust + kernel Rust = coherent safety story to OEM customers)

  #callout(color: safe-green)[
    *The first win that matters for management*: a Rust driver for new IP that passes your existing test suite with *zero* KASAN findings — compared to how many the equivalent C bring-up generated. That number is your ROI argument.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  CLOSING FOCUS SLIDE
// ─────────────────────────────────────────────────────────────────────────────
#focus-slide[
  *The kernel now has three core languages:*
  *C · Assembly · Rust*

  New peripheral drivers at your IC design house can be written in Rust *today*.

  The toolchain is in mainline. The decision is made.
  The only question is whether your team is ready.
]

// ─────────────────────────────────────────────────────────────────────────────
//  APPENDIX — QUICK REFERENCE
// ─────────────────────────────────────────────────────────────────────────────
= Appendix <touying:hidden>

== Quick-reference: essential commands

```bash
# ── Toolchain setup ───────────────────────────────────────────────────────
rustup override set $(scripts/min-tool-version.sh rustc)
rustup component add rust-src rustfmt clippy
cargo install --locked \
  --version $(scripts/min-tool-version.sh bindgen) bindgen-cli

# ── Verification ──────────────────────────────────────────────────────────
make LLVM=1 rustavailable          # should print "Rust is available!"

# ── Configuration ─────────────────────────────────────────────────────────
make LLVM=1 menuconfig             # General setup → Rust support
scripts/config --enable CONFIG_RUST
scripts/config --enable CONFIG_SAMPLES_RUST

# ── Build ─────────────────────────────────────────────────────────────────
make LLVM=1 -j$(nproc)            # full kernel
make LLVM=1 samples/rust/          # samples only
make LLVM=1 rust-analyzer          # generate IDE project file
make LLVM=1 rustdoc                # generate API documentation

# ── Load / unload ─────────────────────────────────────────────────────────
sudo insmod path/to/module.ko
lsmod | grep module_name
sudo dmesg | tail -10
sudo rmmod module_name

# ── Inspect ───────────────────────────────────────────────────────────────
modinfo path/to/module.ko          # author, license, vermagic
llvm-objdump -d path/to/module.ko  # disassemble — verify codegen
```

== Key files and documentation

```
# In-tree Rust source
rust/                        ← Rust core support (bindgen, kernel crate, helpers)
rust/kernel/                 ← safe abstraction layer (the API your drivers use)
samples/rust/                ← canonical examples (start here)
  rust_minimal.rs            ← simplest possible module
  rust_module_parameters.rs  ← module parameters (equivalent of module_param)
  rust_miscdev.rs            ← misc char device (register /dev entry)
  rust_platform.rs           ← platform driver pattern

# Documentation
Documentation/rust/quick-start.rst     ← toolchain setup guide
Documentation/rust/general-info.rst    ← architecture overview
Documentation/rust/coding-guidelines.rst

# Online references
docs.kernel.org/rust/                  ← rendered kernel Rust docs
rust-for-linux.github.io/docs/kernel/  ← kernel crate API reference
rust-for-linux.com                     ← project status, policy, links
```

== References

#set text(size: 0.72em)

*Kernel Rust policy and status*
- Miguel Ojeda. "The experiment is done — Rust is here to stay." kernel.org patch, December 2025.
- Greg Kroah-Hartman. "Why New Kernel Code Should Be in Rust." LKML post, February 2025. Phoronix coverage: #link("https://www.phoronix.com/news/Greg-KH-On-New-Rust-Code")
- Linux Kernel Documentation: `Documentation/rust/`. #link("https://docs.kernel.org/rust/")
- Rust for Linux project: #link("https://rust-for-linux.com") · Kernel policy: #link("https://rust-for-linux.com/rust-kernel-policy")

*Academic*
- Jung, R., et al. "RustBelt: Securing the Foundations of the Rust Programming Language." POPL 2018. #link("https://plv.mpi-sws.org/rustbelt/popl18/")
- Li, H., et al. "An Empirical Study of Rust-for-Linux: The Success, Dissatisfaction, and Compromise." USENIX ATC 2024.

*CVE statistics*
- Gaynor, A., Thomas, G. "Memory Safety in the Linux Kernel." Linux Security Summit 2019.
- Microsoft MSRC. "A Proactive Approach to More Secure Code." Gavin Thomas, 2019.

*Regulatory*
- CISA. "The Case for Memory Safe Roadmaps." 2023. #link("https://www.cisa.gov/resources-tools/resources/case-memory-safe-roadmaps")
- Android Security Blog. "Memory Safety in Android." 2021. #link("https://security.googleblog.com")
