# Rust Memory Safety — Talking Points

**Audience:** Senior kernel & C engineers (5–30+ years experience)  
**Topics:** Ownership · Borrowing · Borrow checker · Concurrency  
**Total points:** 18 across 4 sections

---

## Table of Contents

1. [Ownership](#1-ownership)
2. [Borrowing & the Borrow Checker](#2-borrowing--the-borrow-checker)
3. [Ownership & Lifetimes Preventing Data Races](#3-ownership--lifetimes-preventing-data-races)
4. [Concurrency](#4-concurrency)

---

## 1. Ownership

### 1.1 Every value has exactly one owner — the single-writer rule

**Tag:** `core rule`

**Talking points:**

- Draw the parallel your audience already knows: in C, a `struct device *` can be held by the driver, the
  bus subsystem, and an interrupt handler simultaneously — with no language-level enforcement of who is
  responsible for freeing it. Ownership gives exactly one answer: *the owner frees.*
- Ownership is not about *where* data lives — it is about *who is responsible* for it. Stack, heap, or
  global: one owner, always.
- When ownership moves (`let b = a;`), the original variable `a` is statically dead. The compiler inserts no
  runtime check — it simply stops emitting code that uses `a` after the move. This is pure compile-time
  analysis with zero overhead at runtime.
- Kernel parallel: `dev_hold()` / `dev_put()` are the C way of tracking ownership of `struct device`. Rust
  ownership removes the need to call them manually — the refcount is managed by the type system itself.

**Code example:**

```rust
let buf = DmaBuf::alloc(dev, 4096)?;  // buf owns the allocation
submit_dma(buf);                       // ownership MOVES to submit_dma
// buf.free() ← cannot call: buf was moved, compiler knows
```

**Reference:** Rust Reference §4.1 — Ownership

---

### 1.2 When the owner goes out of scope, memory is freed — zero-cost RAII

**Tag:** `kernel impact`

**Talking points:**

- This replaces the entire `goto err_free_X` pattern that accounts for a significant fraction of kernel
  driver complexity. Count the labels in any non-trivial `probe()` function.
- The compiler generates the same `free()` call a C programmer would write — but guarantees it runs on
  *every* exit path, including paths the programmer forgot.
- In kernel terms: `Drop` is called in *reverse order of construction*. If you allocate `resource_a`, then
  `resource_b`, then `resource_c`, and `resource_c` fails — `resource_b.drop()` then `resource_a.drop()` are
  called automatically, in the correct order, without any label.
- This is **not** garbage collection. There is no runtime to call at an arbitrary time. The destructor call
  is inserted at a *statically known point* by the compiler — the end of the scope.

**Code example:**

```rust
fn probe(pdev: &mut PciDev) -> Result<MyDrv> {
    let irq = pdev.alloc_irq(handler)?;   // if next line fails:
    let dma = pdev.alloc_dma(4096)?;      //   irq.drop() called here
    let bar = pdev.map_bar(0)?;           //   irq.drop(), dma.drop() here
    Ok(MyDrv { irq, dma, bar })           // all owned, no labels needed
}
```

**C comparison — the pattern Rust eliminates:**

```c
int probe(struct pci_dev *pdev) {
    int ret;
    void *irq = alloc_irq(pdev);
    if (!irq) { ret = -ENOMEM; goto err; }

    void *dma = alloc_dma(pdev, 4096);
    if (!dma) { ret = -ENOMEM; goto err_free_irq; }

    void *bar = map_bar(pdev, 0);
    if (!bar) { ret = -ENOMEM; goto err_free_dma; }

    return 0;

err_free_dma: free_dma(dma);
err_free_irq: free_irq(irq);
err:          return ret;
}
```

**Reference:** Rust Reference §10.5 — Drop

---

### 1.3 Ownership applies across function calls — move semantics, not copies

**Tag:** `zero cost`

**Talking points:**

- When you pass a value by move in Rust, no copy of the data occurs. The *ownership* transfers — the machine
  code is a simple register or stack-slot pass.
- This is the critical distinction from languages like Java or Python where "pass by reference" hides a
  hidden refcount increment. In Rust, if you want shared access, you *explicitly* borrow — the language
  forces you to say what you mean.
- Kernel impact: passing a `Box<T>` to a function is identical to passing a raw pointer at the machine
  level. The ownership transfer is a compile-time concept only — zero overhead.

**Code example:**

```rust
// Compiles to a single pointer move — no memcpy, no refcount
fn send_to_hw(buf: OwnedDmaBuf) { /* … */ }

let buf = OwnedDmaBuf::alloc(dev)?;
send_to_hw(buf);   // pointer moved, no allocation, zero overhead
// buf is gone from this scope — compiler enforces it
```

**Reference:** RustBelt §2 — Ownership & move semantics (Jung et al., POPL 2018)

---

## 2. Borrowing & the Borrow Checker

### 2.1 Shared borrows (`&T`): many readers, no writers — maps to read-lock

**Tag:** `C parallel`

**Talking points:**

- A shared borrow `&T` is a read-only view of data. Any number of `&T` references can coexist — because none
  of them can mutate the data, they cannot interfere with each other.
- The C parallel your audience will recognise immediately: an **RCU read-side critical section**. Multiple
  readers hold the data simultaneously because none are writing. Rust encodes this semantically as a type:
  `&T`.
- The key guarantee: while *any* `&T` exists, no `&mut T` can exist. This is the **aliasing XOR mutability**
  discipline, enforced statically.
- This means the compiler can tell LLVM that `&T` pointers never alias `&mut T` pointers. This is stronger
  than `restrict` in C — and it enables better auto-vectorisation and optimisation without any annotation.

**Code example:**

```rust
let ring = RingBuf::new(1024);
let r1 = &ring;    // shared borrow
let r2 = &ring;    // another shared borrow — fine
// let w = &mut ring;  ← error: cannot borrow as mutable
//                       because ring is borrowed as immutable
```

**Reference:** Rust Reference §10.3 — References & Borrowing

---

### 2.2 Exclusive borrows (`&mut T`): one writer, no readers — maps to write-lock

**Tag:** `C parallel`

**Talking points:**

- An exclusive borrow `&mut T` guarantees that *no other reference* — not even a read-only one — exists
  simultaneously. This is the exclusive ownership of a writer lock, enforced at compile time.
- C parallel: acquiring a spinlock before modifying shared state. In C, nothing stops you from accessing the
  data *without* the lock — the rule lives in a comment or in lockdep annotations. In Rust, the rule is in
  the type: you cannot get `&mut T` without giving up all `&T`s first.
- The scope of the exclusive borrow is the compiler's proof of the critical section. When the `&mut T` goes
  out of scope, the "lock" is implicitly released.
- Critically: this is **not** a runtime operation. There is no actual lock being acquired. The borrow
  checker's static analysis *proves* the access pattern is safe without any runtime mechanism.

**Code example:**

```rust
fn fill_ring(ring: &mut RingBuf, data: &[u8]) {
    ring.write(data);    // exclusive access — provably safe
}   // exclusive borrow ends here — other code can read ring again

// Meanwhile: NO other code can read ring during fill_ring — verified statically
```

**Reference:** RustBelt §3.1 — Mutable references (Jung et al., POPL 2018)

---

### 2.3 Lifetimes: no reference outlives its data — dangling pointers impossible

**Tag:** `formal proof`

**Talking points:**

- A lifetime `'a` is a label the compiler uses to track how long a piece of data is valid. It is *not* a
  runtime object — lifetimes are erased before code generation and have **zero runtime cost**.
- The borrow checker's job is to verify that every reference's lifetime is a *subset* of the lifetime of the
  data it points to. If it cannot prove this, the code does not compile.
- Kernel context: an interrupt handler holding a pointer to `struct device` after `device_unregister()` has
  been called is a classic UAF in C. With lifetimes, the compiler proves the reference cannot outlive the
  device.
- Named lifetimes (`fn longest<'a>(x: &'a str, y: &'a str) -> &'a str`) are annotations that help the
  compiler prove the invariant. In most cases the compiler infers them — explicit annotations are only
  needed when the relationship is ambiguous.

**Code example:**

```rust
// Dangling pointer — caught at compile time
fn get_ref() -> &str {
    let local = String::from("DMA buffer");
    &local  // error[E0106]: returns a reference to data
            //              owned by the current function
}  // local dropped here — would dangle in C

// Correct: lifetime 'a proves output lives as long as input
fn first_word<'a>(s: &'a str) -> &'a str { &s[..5] }
```

**Reference:** Jung et al., POPL 2018 §2.3 — Lifetime logic in λRust

---

### 2.4 The borrow checker is a theorem prover, not a linter

**Tag:** `formal proof`

**Talking points:**

- This is the most important framing point for a sceptical senior engineer: ASAN, Valgrind, and sparse are
  *detectors* — they require a test case to trigger the bug. The borrow checker is a *prover* — it runs on
  all possible executions simultaneously.
- **RustBelt** (Jung et al., POPL 2018) proved in Coq that if the borrow checker accepts a program, that
  program is memory-safe for *all possible inputs*. This is a machine-checked proof, not an empirical claim.
- The borrow checker runs at every `cargo check` or `rustc` invocation — it is part of the compilation, not
  a separate optional tool.
- It is **exhaustive**: it does not sample code paths. It reasons about all paths through the control flow
  graph simultaneously.

**Code example:**

```rust
// Borrow checker rejects this for ALL inputs — no test needed:
let v = vec![1, 2, 3];
let first = &v[0];   // shared borrow of v
v.push(4);           // error[E0502]: cannot borrow `v` as mutable
                     //               because it is also borrowed as immutable
println!("{}", first); // first could dangle after push reallocates
```

> **Key message for the room:** KASAN catches this if you exercise the code path. The borrow checker catches
> this before the binary exists, for all inputs, every time.

**Reference:** Jung, Jourdan, Krebbers, Dreyer — *RustBelt: Securing the Foundations of the Rust Programming
Language.* Proc. ACM Program. Lang. 2, POPL 2018, Article 66.
[plv.mpi-sws.org/rustbelt/popl18](https://plv.mpi-sws.org/rustbelt/popl18)

---

## 3. Ownership & Lifetimes Preventing Data Races

### 3.1 A data race requires aliasing + mutation: Rust makes both simultaneous impossible

**Tag:** `race freedom`

**Talking points:**

- The formal definition of a data race: two threads access the same memory location concurrently, at least
  one access is a write, and there is no synchronisation. This requires both **aliasing** (two pointers to
  the same location) and **unsynchronised mutation**.
- Rust's ownership rules make both properties impossible in safe code: `&mut T` is exclusive (no aliasing
  while mutating), and `&T` is read-only (no mutation while aliased). You cannot have both simultaneously —
  the type system *is the proof*.
- RustBelt extends this to the formal model: the `Send` and `Sync` marker traits define precisely which
  types can cross thread boundaries and be shared between threads. Every standard library type that would
  enable a data race does *not* implement these traits.
- This is not a "memory model" promise like C11 `_Atomic`. It is a **type-level proof** that the program
  cannot construct the scenario where a data race occurs.

**Code example:**

```rust
use std::thread;
let mut data = vec![0u8; 4096]; // shared DMA buffer

let t1 = thread::spawn(|| { data[0] = 0xFF; });
// error[E0373]: closure may outlive the current function,
//              but it borrows `data`
// error[E0502]: cannot borrow `data` as mutable
//               because it is also borrowed

// Both errors together = data race prevented statically.
// In C this compiles, runs, and silently corrupts memory.
```

**Reference:** RustBelt §3.3 — Send and Sync (Jung et al., POPL 2018); *RustBelt Meets Relaxed Memory* (Dang et al., POPL 2020)

---

### 3.2 `Send` and `Sync`: thread-safety is part of the type, not the documentation

**Tag:** `race freedom`

**Talking points:**

- `Send`: a type can be *moved* to another thread. `Sync`: a type can be *shared* between threads via `&T`.
  Both are compile-time marker traits — **zero runtime representation, zero overhead**.
- Kernel parallel: Linux has types that must never cross CPU boundaries without proper synchronisation —
  per-CPU data, IRQ-disabled critical sections. In C, this is documented in comments and enforced by lockdep
  at *runtime*. In Rust, it is encoded in `Send` / `Sync` and enforced by the *compiler* before the module
  loads.
- `Rc<T>` (non-atomic reference count) is NOT `Send`. The compiler prevents it from being moved to another
  thread. `Arc<T>` (atomic reference count) IS `Send` — the compiler knows it is safe. This is automatic: no
  runtime check, no programmer decision at the call site.
- For a kernel module: any data stored in a global (or in a struct that ends up in a global) must be `Sync`.
  If it is not — compile error. This catches the class of bugs where an engineer forgets that a `probe()`
  callback and an interrupt handler run on different CPUs.

**Code example:**

```rust
use std::rc::Rc;

let local_rc = Rc::new(42);  // NOT Send: non-atomic refcount
thread::spawn(move || {
    println!("{}", local_rc);
    // error[E0277]: `Rc<i32>` cannot be sent between threads safely
    // help: use `Arc<i32>` instead — atomic refcount, implements Send
});
```

**Reference:** RustBelt §3.3; Rust Standard Library — `std::marker::Send`, `std::marker::Sync`

---

### 3.3 `Mutex<T>` wraps the data — you cannot access it without the lock

**Tag:** `kernel impact`

**Talking points:**

- In C, a mutex protects data by *convention*: `pthread_mutex_lock(&mu); access data;
  pthread_mutex_unlock(&mu);`. Nothing in the language enforces the lock is held when the data is accessed.
  Linux uses lockdep at *runtime* to catch violations — but only for code paths that are exercised during
  testing.
- In Rust, `Mutex<T>` *wraps* the data. The data is only accessible through `Mutex::lock()`, which returns a
  `MutexGuard<T>`. The guard is the only path to the data — there is no way to access the data without
  holding the guard, because the data is not exposed otherwise.
- When the guard drops, the lock is released — automatically, on every exit path, including panics and `?`
  propagation.
- Kernel equivalent: `kernel::sync::Mutex<T>` and `kernel::sync::SpinLock<T>` in the Rust kernel crate
  implement exactly this. The lock and the data are bound together in one type — the lock order is
  structurally enforced.

**Code example:**

```rust
let shared = Arc::new(Mutex::new(DmaStats::new()));
let clone  = Arc::clone(&shared);

thread::spawn(move || {
    let mut guard = clone.lock().unwrap(); // MUST lock to access data
    guard.record(latency_ns);             // data only reachable via guard
}); // guard drops → unlock, automatic, every exit path

// This does not compile — there is no other path to the data:
// shared.inner.record()  ← field is private, no path exists
```

**C comparison:**

```c
// Nothing stops this — the lock is a convention, not a constraint:
pthread_mutex_t mu;
struct DmaStats stats;

void record(uint64_t ns) {
    stats.total += ns;   // lockdep: not checked until runtime
                         // and only if this code path is exercised
}
```

**Reference:** Rust Standard Library — `std::sync::Mutex`; kernel source — `rust/kernel/sync/mutex.rs`

---

## 4. Concurrency

### 4.1 Fearless concurrency: the type system enforces the rules, not the developer

**Tag:** `race freedom`

**Talking points:**

- "Fearless concurrency" is the Rust team's framing: add parallelism without fear of data races, because the
  type system will reject code that can race. This is enforced *before the binary exists*.
- For kernel engineers: this means you can parallelise a data structure — add a thread, add an `Arc`, add a
  channel — and the compiler tells you immediately if you have introduced a data race. You do not need to
  wait for a fuzzer, a stress test, or a customer report.
- The key insight: making code concurrent in Rust turns *latent data race bugs* into *immediate compile
  errors*. The bug is caught at the refactoring step, not at the production incident step.

**Code example:**

```rust
let stats = Arc::new(Mutex::new(Histogram::new()));

for _ in 0..num_cpus {
    let s = Arc::clone(&stats);
    thread::spawn(move || {
        s.lock().unwrap().record(sample_latency());
    }); // compiler verified: no data race
}
```

**Reference:** *The Rust Programming Language* Ch. 16 — Fearless Concurrency (Klabnik & Nichols, 2019)

---

### 4.2 Channels: ownership transfers data safely across thread boundaries

**Tag:** `C parallel`

**Talking points:**

- A channel in Rust (`std::sync::mpsc`, or `tokio` channels for async) transfers *ownership* of data between
  threads. The sending thread relinquishes its access at the moment of `send()` — the language enforces it.
  There is no shared memory to race on.
- C parallel: a message queue (`mq_send`, or the kernel's workqueue). Rust channels express the same
  semantic with compile-time safety: after `tx.send(buf)`, the sending thread cannot access `buf` —
  ownership moved.
- Recommended pattern for interrupt-to-task communication: the IRQ handler sends an owned event to a worker
  thread via a channel. The compiler proves the IRQ handler does not retain any reference to the event after
  sending.

**Code example:**

```rust
let (tx, rx) = mpsc::channel::<DmaEvent>();

// Producer: interrupt handler path
let tx_irq = tx.clone();
irq::request(IRQ_NUM, move |_| {
    tx_irq.send(DmaEvent::from_hw()).ok();
    // tx_irq is the only path to the event — no shared memory
});

// Consumer: worker thread
for event in rx {
    update_histogram(&mut hist, event);
}
```

**Reference:** Rust Reference §16.2 — Message Passing; `kernel::sync::Channel`

---

### 4.3 `async`/`await`: cooperative concurrency — same ownership rules apply across suspension points

**Tag:** `zero cost`

**Talking points:**

- Rust's `async`/`await` applies the same ownership and borrow-checking rules *across suspension points*. A
  reference held across an `.await` must be `Send` if the future might be polled on a different thread.
- This catches the class of bugs common in asynchronous C code: a callback holding a pointer to stack data
  that has been freed by the time the callback runs — the classic async UAF.
- For kernel Rust: `async` is used in eBPF program loading (Aya), in io_uring-based drivers, and in the
  kernel's async I/O infrastructure. The same compile-time guarantees apply.
- The generated code is a state machine — no heap allocation required, no runtime scheduler required in
  `no_std` environments. Zero overhead compared to an explicit state machine written in C.

**Code example:**

```rust
// References held across .await must be Send.
// Compiler catches this without running a single test:
async fn process(data: &mut DmaBuffer) {
    some_async_io().await;   // if polled on another thread,
    data.flush();            //   data must be safely Send
    // error[E0277]: `DmaBuffer` cannot be shared between threads safely
    // help: use Arc<Mutex<DmaBuffer>> instead
}
```

**Reference:** *Rust Async Book* — <https://rust-lang.github.io/async-book>; Aya framework async BPF loader

---

### 4.4 Atomic types + memory ordering: same hardware model, safer API than C11

**Tag:** `C parallel`

**Talking points:**

- C11 atomics (`_Atomic`, `atomic_load_explicit`, `memory_order_acquire`) and Rust atomics (`AtomicU32`,
  `.load(Ordering::Acquire)`) generate **identical machine code** for the same memory ordering. The
  difference is ergonomic safety, not semantics.
- Rust's `Ordering` enum is exhaustive — the compiler rejects unknown ordering values. In C, passing a wrong
  integer to `atomic_load_explicit` compiles silently. In Rust, a wrong `Ordering` is a type error.
- **RustBelt Meets Relaxed Memory** (Dang et al., POPL 2020) extends the formal soundness proof to cover C11
  relaxed-memory operations — and in doing so found a *data race in `Arc`* in the Rust standard library
  during the formalisation work. It was fixed. This is the kind of guarantee a formal proof provides.
- For kernel engineers: `kernel::sync::AtomicU32` and friends map directly to the kernel's `atomic_t`
  family. The memory ordering model is identical — the API is just harder to misuse.

**Code example:**

```rust
use std::sync::atomic::{AtomicU64, Ordering};

static DMA_COUNTER: AtomicU64 = AtomicU64::new(0);

// Called from interrupt context — same as C11 relaxed:
fn dma_complete() {
    DMA_COUNTER.fetch_add(1, Ordering::Relaxed);
}

// Read from process context — acquire fence:
let count = DMA_COUNTER.load(Ordering::Acquire);
```

**C equivalent (for comparison):**

```c
#include <stdatomic.h>
static atomic_uint_least64_t dma_counter = 0;

void dma_complete(void) {
    atomic_fetch_add_explicit(&dma_counter, 1, memory_order_relaxed);
}
uint64_t read_count(void) {
    return atomic_load_explicit(&dma_counter, memory_order_acquire);
}
// Identical machine code — but passing wrong memory_order_* is silent in C
```

**Reference:** Dang, Jourdan, Kaiser, Dreyer — *RustBelt Meets Relaxed Memory.* Proc. ACM Program. Lang. 4, POPL 2020, Article 34.

---

## Key References

| Reference | Where cited |
|-----------|-------------|
| Jung, Jourdan, Krebbers, Dreyer. **RustBelt: Securing the Foundations of the Rust Programming Language.** POPL 2018. [plv.mpi-sws.org/rustbelt/popl18](https://plv.mpi-sws.org/rustbelt/popl18) | Ownership, borrow checker, Send/Sync |
| Dang, Jourdan, Kaiser, Dreyer. **RustBelt Meets Relaxed Memory.** POPL 2020. | Atomic types, relaxed memory, data races |
| Microsoft MSRC, Gavin Thomas. **A Proactive Approach to More Secure Code.** 2019. | ~70% of CVEs are memory safety |
| Gaynor & Thomas. **Memory Safety in the Linux Kernel.** Linux Security Summit 2019. | ~67% of Linux CVEs |
| Klabnik & Nichols. **The Rust Programming Language.** 2nd ed. 2019. | Ownership, borrowing, fearless concurrency |
| **Rust Reference.** [doc.rust-lang.org/reference](https://doc.rust-lang.org/reference) | Language specification, lifetimes, borrowing rules |

---

## Summary: What the Compiler Proves at Every Build

| Property | C approach | Rust approach |
|----------|-----------|---------------|
| Use-after-free | KASAN (runtime, needs test path) | Borrow checker (compile time, all paths) |
| Dangling pointer | Valgrind / ASAN | Lifetime analysis (compile time) |
| Data race | KCSAN / ThreadSanitizer (runtime) | `Send`/`Sync` type system (compile time) |
| Null dereference | Static analysis heuristic | `Option<T>` type (compiler-forced handling) |
| Lock discipline | lockdep (runtime) | `Mutex<T>` wraps data (compile time) |
| Error propagation | Convention (`if (ret < 0)`) | `Result<T,E>` + `#[must_use]` (compiler warning) |
| Uninitialised read | Compiler warning (partial) | All fields must be initialised (compile error) |
