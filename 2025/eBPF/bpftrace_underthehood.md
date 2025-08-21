# bpftrace:

```bpftrace
#!/usr/bin/bpftrace
/*
 * execsnoop.bt   Trace new processes via exec() syscalls.
 *                For Linux, uses bpftrace and eBPF.
 *
 * This traces when processes call exec(). It is handy for identifying new
 * processes created via the usual fork()->exec() sequence. Note that the
 * return value is not currently traced, so the exec() may have failed.
 *
 * TODO: switch to tracepoints args. Support more args. Include retval.
 *
 * This is a bpftrace version of the bcc tool of the same name.
 *
 * 15-Nov-2017  Brendan Gregg   Created this.
 * 11-Sep-2018     "     "      Switched to use join().
 */

#ifndef BPFTRACE_HAVE_BTF
#include <linux/sched.h>
#endif

BEGIN
{
        printf("%-15s %-7s %-7s %s\n", "TIME", "PID", "PPID", "ARGS");
}

tracepoint:syscalls:sys_enter_exec*
{
        $task = (struct task_struct *)curtask;
        printf("%15s %-7d %-7d ", strftime("%H:%M:%S.%f", nsecs), pid, $task->real_parent->pid);
        join(args.argv);
}
```
Try to understand **how `bpftrace` programs work under the hood** — 
especially **who pushes the eBPF code into the kernel**.

- Most eBPF tools are divided into:

1. **Kernel-space part**: The eBPF bytecode (tracing, filtering, etc.)
2. **User-space part**: The program that loads eBPF, attaches it, and reads output.

---

## So who actually pushes the eBPF code into the kernel?

> **Answer:** The **`bpftrace` binary itself** does.

### 🔧 Here's how it works:

1. **You run your script**:

   ```bash
   sudo ./execsnoop.bt
   ```

2. **`bpftrace` parses the script**:

   * It converts your high-level `bpftrace` language into **LLVM IR** (Intermediate Representation).
   * Then it compiles this IR into **eBPF bytecode** using LLVM.

3. **`bpftrace` uses the `bpf()` syscall**:

   * It uses the [`bpf()` syscall](https://man7.org/linux/man-pages/man2/bpf.2.html) with commands like 
     `BPF_PROG_LOAD`, `BPF_MAP_CREATE`, etc.
   * This loads the bytecode into the kernel and verifies it.

4. **It attaches your eBPF program** to the tracepoint:

   * For example, to `tracepoint:syscalls:sys_enter_execve`
   * Under the hood, it might use a perf event or raw tracepoint FD.

5. **Reads data back from kernel (via BPF maps or perf buffers)**:

   * When your eBPF code emits output (like `printf()`), `bpftrace` listens to it using a perf buffer.
   * The user-space part handles formatting and showing it on the terminal.

---

##  Simplified Architecture

```
+-----------------+           +------------------+
| execsnoop.bt    |  ======>  |  bpftrace binary |
+-----------------+           +------------------+
                                  |
                                  |  LLVM compiles to eBPF bytecode
                                  |
                             [ bpf() syscall ]
                                  |
                            Loads eBPF into kernel
                                  |
                        Attaches to tracepoints
                                  |
                          Collects data (perf/map)
                                  |
                          Formats and prints output
```

---

## You can even trace this happening!

Run:

```bash
sudo strace -e trace=bpf bpftrace execsnoop.bt
```

You'll see calls like:

```
bpf(BPF_PROG_LOAD, {prog_type=...}, ...) = <fd>
```

This shows `bpftrace` doing the actual `bpf()` syscall.

---

### Summary

| Role              | Done by                          |
| ----------------- | -------------------------------- |
| Parses script     | `bpftrace` user-space binary     |
| Compiles to eBPF  | `bpftrace` via LLVM              |
| Loads eBPF        | `bpftrace` using `bpf()` syscall |
| Attaches to hooks | `bpftrace`                       |
| Reads output      | `bpftrace`, via perf buffers     |
| You write         | Only the `.bt` script 😄         |

---

# Internals of bpftrce (Overview)
Internals of how a `bpftrace` script (like `execsnoop.bt`) is **compiled and run**, and you want to know:

> **Which part gets converted into LLVM IR and compiled into eBPF bytecode?**

---

## Quick answer

> **Only the bodies of your probes and `BEGIN` blocks** 

— i.e., what goes inside `{ ... }` — are converted to LLVM IR and then compiled into eBPF bytecode.

---

### So in this script:

```bpftrace
BEGIN
{
    printf("%-15s %-7s %-7s %s\n", "TIME", "PID", "PPID", "ARGS");
}

tracepoint:syscalls:sys_enter_exec*
{
    $task = (struct task_struct *)curtask;
    printf("%15s %-7d %-7d ", strftime("%H:%M:%S.%f", nsecs), pid, $task->real_parent->pid);
    join(args.argv);
}
```

### The parts compiled to LLVM IR → eBPF bytecode:

#### The body of the `BEGIN` block:

```bpftrace
printf("%-15s %-7s %-7s %s\n", "TIME", "PID", "PPID", "ARGS");
```

* This is compiled into eBPF and **runs once at the very beginning**, in a kernel context (technically as a special probe).

#### The body of the `tracepoint:syscalls:sys_enter_exec*` block:

```bpftrace
$task = (struct task_struct *)curtask;
printf("%15s %-7d %-7d ", strftime("%H:%M:%S.%f", nsecs), pid, $task->real_parent->pid);
join(args.argv);
```

* This code:

  * Reads kernel structures (`curtask`, `task_struct`)
  * Calls helper functions like `strftime()`, `join()`, etc.
* All of this is converted to **LLVM IR**, then compiled to **eBPF bytecode**.

---

### Not compiled into eBPF (user-space only):

| Code                                                       | Reason                                                                                                    |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `#ifndef BPFTRACE_HAVE_BTF` and `#include <linux/sched.h>` | Used **at compile time** to help the parser understand kernel struct layouts. Not part of runtime or eBPF |
| Comments                                                   | Obviously ignored                                                                                         |
| Probe definitions (`BEGIN`, `tracepoint:...`)              | Used by the `bpftrace` parser to determine **where** to attach the eBPF programs                          |

---

### Why only `{ ... }` parts are compiled

`bpftrace` is a **high-level language**, but eBPF has strict rules:

* No loops (unless bounded)
* No heap allocations
* No unbounded recursion
* Limited stack and registers

So only a safe subset of the language is **lowered to LLVM IR → eBPF**, and that subset is only what's inside the probe bodies.

---

### Summary

| Part                           | Compiled to eBPF? | Notes                    |
| ------------------------------ | ----------------- | ------------------------ |
| `BEGIN { ... }` block          | ✅ Yes             | Runs once at start       |
| `tracepoint:... { ... }` block | ✅ Yes             | Attached to tracepoint   |
| Includes / macros              | ❌ No              | Used only during parsing |
| Comments / probe headers       | ❌ No              | Metadata for parser      |

---



The code below is the part that **`bpftrace` compiles into LLVM IR**, which is then converted into 
**eBPF bytecode** and loaded into the kernel using the `bpf()` syscall:

```bpftrace
BEGIN
{
        printf("%-15s %-7s %-7s %s\n", "TIME", "PID", "PPID", "ARGS");
}

tracepoint:syscalls:sys_enter_exec*
{
        $task = (struct task_struct *)curtask;
        printf("%15s %-7d %-7d ", strftime("%H:%M:%S.%f", nsecs), pid, $task->real_parent->pid);
        join(args.argv);
}
```

---

## Recap of what happens

1. **`bpftrace` parses this code**, identifies probe blocks (`BEGIN`, `tracepoint:...`).
2. **Each `{ ... }` block** is translated to **LLVM IR**.
3. Then **LLVM compiles** the IR into **eBPF bytecode**.
4. Finally, `bpftrace` uses the **`bpf()` syscall** to load the programs into the kernel and attach them.

---

## What doesn't get compiled:

Anything outside those probe blocks, like:

* Comments
* Preprocessor directives:

  ```c
  #ifndef BPFTRACE_HAVE_BTF
  #include <linux/sched.h>
  #endif
  ```
* Probe headers (`BEGIN`, `tracepoint:...`) — these are **used by the parser**, not compiled into bytecode.

---

# Loading the bytecode to kernel:

> **How does the LLVM IR (generated from bpftrace code) get loaded into the kernel?**

The key thing to know is:

> **LLVM IR is *not* directly loaded into the kernel.**
> It is first compiled to **eBPF bytecode**, and *that* bytecode is loaded into the kernel via the `bpf()` syscall.

---

##  Here's how the full flow works:

### 1. **bpftrace parses the high-level script**

* The user writes in bpftrace language (`.bt` file).
* `bpftrace` internally parses the code and builds an AST (Abstract Syntax Tree).

### 2. **bpftrace lowers it to LLVM IR**

* The probe bodies (code inside `{ ... }`) are translated to **LLVM IR**.
* This IR describes the logic in a low-level, platform-independent format.

You can see this if you run:

```bash
bpftrace -d script.bt  # -d = debug output, shows LLVM IR
```

---

### 3. **LLVM IR → eBPF bytecode**

* `bpftrace` invokes **LLVM’s backend** (via `llc`) to compile the IR to **eBPF bytecode**.
* This bytecode is just a series of 64-bit instructions that follow the eBPF ISA.

---

### 4. **Load eBPF into kernel using `bpf()` syscall**

Once compiled to bytecode, `bpftrace` calls:

```c
bpf(BPF_PROG_LOAD, ...)
```

This syscall sends:

* The eBPF program type (e.g., `BPF_PROG_TYPE_TRACEPOINT`)
* A pointer to the bytecode
* Any BPF maps it needs
* Licensing info
* Attach target info (like the tracepoint ID)

If verification passes (no loops, stack overflow, bad pointer derefs, etc.), the kernel loads the program 
and returns a **program file descriptor (FD)**.

---

### 5. **Attach the program to an event source**

For example, if you wrote:

```bpftrace
tracepoint:syscalls:sys_enter_execve
```

Then bpftrace attaches the loaded eBPF program to the raw tracepoint using:

```c
perf_event_open(...)   // creates event FD
ioctl(event_fd, PERF_EVENT_IOC_SET_BPF, prog_fd);
```

Now, whenever that tracepoint fires, your eBPF program is executed in-kernel.

---

### 🔄 Summary of Flow

```text
Your Script (.bt)
   ↓
Parsed by bpftrace
   ↓
Lowered to LLVM IR
   ↓
Compiled via llc to eBPF bytecode
   ↓
Loaded into kernel via bpf(BPF_PROG_LOAD)
   ↓
Attached to tracepoint (via perf_event_open + ioctl)
   ↓
Kernel runs your program on each event
```

---

## 📌 Tools and Components Involved

| Stage              | Tool/Component                               |
| ------------------ | -------------------------------------------- |
| LLVM IR generation | `bpftrace` internal IR builder               |
| IR to bytecode     | LLVM’s `llc` (e.g., `llc -march=bpf`)        |
| Kernel loading     | `bpf(BPF_PROG_LOAD)` syscall                 |
| Attaching to hook  | `perf_event_open()` + `ioctl()`              |
| Runtime output     | Perf buffer read by `bpftrace` in user space |

---

# data path of eBPF program from kernel space to user space:

 **data path from kernel to userspace** in an eBPF program, specifically with `bpftrace`. 
 Let's explain it **step by step**, using your `execsnoop.bt` script as a concrete example.

---

## Question Summary:

> When the eBPF function runs in kernel (e.g., on `execve`), **how is the data passed to userspace**, and
  **who prints it to the terminal**?

---

## Overview:

When your probe fires in the kernel:

1. eBPF code **executes inside the kernel**.
2. It **emits data** using a special mechanism (like a **perf event buffer**).
3. The **`bpftrace` user-space process** is listening to that buffer.
4. `bpftrace` **reads the data, formats it**, and prints it to your terminal.

---

## Step-by-Step Breakdown

### 1. Kernel: eBPF program is triggered

* When a syscall like `execve` is called, the kernel fires the `tracepoint:syscalls:sys_enter_execve`.
* Your eBPF bytecode is attached to this tracepoint, so it's executed.

---

###  2. Kernel: eBPF program emits data using `bpf_trace_printk()` or perf buffer

In your `execsnoop.bt`, these lines:

```bpftrace
printf("%15s %-7d %-7d ", strftime(...), pid, ppid);
join(args.argv);
```

are internally translated by `bpftrace` to emit data using something like:

* `bpf_trace_printk()` (older, limited, debug-style printing), or
* **`perf_event_output()`** helper (preferred for structured data)

Behind the scenes, bpftrace sets up a **perf buffer** to transfer this data.

---

### 3. Userspace: `bpftrace` process reads the perf buffer

* When you run your `.bt` script, the `bpftrace` process:

  * Sets up the **perf ring buffer**.
  * Hooks into the kernel using `poll()` or `epoll()` to wait for data.
  * Reads from the buffer when data is available.

Think of it like a pipe: kernel writes, userspace reads.

---

### 4. Userspace: `bpftrace` formats and prints the data

* After reading the raw event data, `bpftrace`:

  * Decodes the format (e.g., timestamps, strings, integers)
  * Applies the formatting you wrote (`printf(...)`)
  * Prints it to `stdout`, which is your terminal

So, **you see the final output because the `bpftrace` binary interprets and formats the event data** emitted from the kernel.

---

## Example Output Flow

```
[execve syscall] ─▶ eBPF program runs ─▶ perf_event_output() emits data
                                          ↓
                                 perf ring buffer (in kernel)
                                          ↓
                             bpftrace reads & decodes data
                                          ↓
                            Formats it with printf / join()
                                          ↓
                                Printed to your terminal
```

---

## Internals Summary

| Step | Kernel space                           | User space                   |
| ---- | -------------------------------------- | ---------------------------- |
| 1    | `execve` fires tracepoint              | —                            |
| 2    | eBPF runs, calls `perf_event_output()` | —                            |
| 3    | —                                      | `bpftrace` reads perf buffer |
| 4    | —                                      | Formats + prints to console  |

---

### Want to see this in action?

You can trace `bpftrace` reading the perf buffer:

```bash
sudo strace -e trace=read bpftrace execsnoop.bt
```

Or dump perf events in raw form with tools like `perf record` or `trace-cmd`.

---

# recap:

**just like with `gcc`**, where you can stop at intermediate stages like preprocessing (`-E`), compiling 
to assembly (`-S`), or object code (`-c`), you can **also stop the `bpftrace` compilation process at key 
stages** to inspect things like:

* Parsed AST
* LLVM IR
* eBPF bytecode
* Syscalls made

---

## Intermediate Stages in `bpftrace` (Compilation & Loading)

| Stage                  | Description                                  | How to Stop & Inspect                |
| ---------------------- | -------------------------------------------- | ------------------------------------ |
| 1. Parsing             | Converts `.bt` to AST                        | `bpftrace -d`                        |
| 2. LLVM IR Generation  | High-level IR from probe logic               | `bpftrace -d` (shows IR)             |
| 3. eBPF Bytecode       | LLVM IR compiled into eBPF instructions      | `bpftrace -dd`                       |
| 4. Loading to Kernel   | Bytecode loaded via `bpf()` syscall          | `strace -e bpf`                      |
| 5. Attachment & Events | Program attached, data read from perf buffer | Runtime: via `perf_event_open`, etc. |

---

## Commands You Can Use

### Show LLVM IR

```bash
bpftrace -d execsnoop.bt
```

This shows:

* AST (Abstract Syntax Tree)
* **LLVM IR** for each probe
* eBPF pseudo-code (in human-readable form)

---

### Show Full Debug Info (including bytecode)

```bash
bpftrace -dd execsnoop.bt
```

This adds:

* eBPF **bytecode dump**
* Full program structure
* Loaded map details

---

### Trace syscalls (like `bpf()`)

```bash
sudo strace -e bpf bpftrace execsnoop.bt
```

This lets you see:

* `bpf(BPF_PROG_LOAD, ...)`
* `bpf(BPF_MAP_CREATE, ...)`
* Other `bpf()` syscalls being used to load and manage programs and maps.

---

## Advanced: Save Intermediate Files (if using BCC or libbpf)

If you're writing eBPF with C + `clang` directly (e.g., via BCC or libbpf), you can also:

```bash
clang -target bpf -O2 -g -c prog.c -o prog.o     # Compile to eBPF ELF
llvm-objdump -S prog.o                           # Disassemble
bpftool prog load prog.o /sys/fs/bpf/my_prog     # Load manually
```

But `bpftrace` is higher level and doesn't save an intermediate `.o` file — though **you can extract it** from memory or logs for debugging.

---

### Summary: Yes, You Can Stop at Each Stage

| Stage         | GCC Equivalent | `bpftrace` Tool / Flag        |
| ------------- | -------------- | ----------------------------- |
| Parse         | `-E`           | `bpftrace -d` (AST shown)     |
| Compile to IR | `-S`           | `bpftrace -d` (LLVM IR shown) |
| Bytecode      | `-c`           | `bpftrace -dd`                |
| Link/Load     | `ld`           | `bpf()` syscall via strace    |
| Run           | `./a.out`      | `bpftrace execsnoop.bt`       |

---

Let me know if you want to go deeper — for example, saving the bytecode as ELF or inspecting perf buffers live.
