## Example1: trace_point2:

Generalizing your trace_point monitoring tool to accept both **subsystem** and **event name** makes it more 
powerful and usable across all tracepoints, not just `syscalls`.

---

Update the CLI so users can run the program like this:

```bash
./trace_pipe maple_tree ma_write ma_read
./trace_pipe sched sched_switch
./trace_pipe syscalls sys_enter_openat sys_exit_openat
```

That is:

* The **first argument** is the **subsystem** (e.g., `syscalls`, `sched`, `maple_tree`)
* The **remaining arguments** are **event names** from that subsystem


- Example: trace_point3 : Updating from the trace_point2


**Optional Enhancements**

Here are some powerful features you might want to add next:

---

## Example trace_pipe3: **Auto-discovery / listing of available events**

Let users list valid trace events from a subsystem:

```bash
./trace_pipe3 --list sched
```

#### Implementation plan:

* Add an optional `--list <subsystem>` flag.
* Print all events in `/sys/kernel/debug/tracing/events/<subsystem>/`.

---

## Example trace_point4: **PID filtering**

Only show trace events related to a specific process:

```bash
./trace_pipe4 syscalls sys_enter_execve --pid 1234
```

#### Implementation plan:

* Write `pid` to `/sys/kernel/debug/tracing/set_ftrace_pid`.

---

## Example trace_point5 **Write output to file**

Log everything to a file (in addition to stdout):

```bash
./trace_pipe5 syscalls sys_enter_read --out trace.log
```

---

## Example trace_point6: **Support multiple subsystems**

Instead of one subsystem at a time, allow:

```bash
./trace_pipe6 syscalls:sys_enter_read sched:sched_switch
```

#### Parsing format:

Each argument is `subsystem:event`
---

# Complete readme
---

##  `trace_pipe` — Tracepoint Monitor Using `tracefs`

`trace_pipe` is a simple, flexible command-line tool written in Rust that allows you to monitor Linux kernel tracepoints via `tracefs`. It supports multiple subsystems and events, optional PID filtering, and the ability to log output to a file.

---

### 🚀 Features

-- Monitor **multiple tracepoints** from different subsystems
-- Use `--list` to discover available events per subsystem
-- Optional **PID filtering** using `--pid <PID>`
-- Save trace output to a **file** with `--out <file>`
-- Clean shutdown with `Ctrl+C`, including tracepoint disable

---

###  Example Usage

#### Monitor tracepoints from multiple subsystems

```bash
./trace_pipe sched:sched_switch syscalls:sys_enter_execve
```

#### Apply PID filter

```bash
./trace_pipe sched:sched_switch --pid 1234
```

#### Save trace output to file

```bash
./trace_pipe syscalls:sys_enter_open --out trace.log
```

#### List available events in a subsystem

```bash
./trace_pipe --list sched
```

---

### Installation

#### Prerequisites

* Linux system with `tracefs` mounted at `/sys/kernel/debug/tracing`
* Rust (edition 2024)
* AArch64 cross-compiler if building for ARM (optional)

#### Build

```bash
cargo build --release
```

#### Cross-build for AArch64 (example):

```bash
cargo build --release \
    --target aarch64-unknown-linux-gnu \
    --config=target.aarch64-unknown-linux-gnu.linker="aarch64-linux-gnu-gcc"
```

---

### Example Events to Try

To list all available tracepoints:

```bash
cat /sys/kernel/debug/tracing/available_events
```

Examples from common subsystems:

* **`sched:sched_switch`**
* **`syscalls:sys_enter_openat`**
* **`maple_tree:ma_write`**

---

### CLI Reference

```bash
USAGE:
    trace_pipe [OPTIONS] <subsystem:event>...

ARGS:
    <subsystem:event>...    Tracepoints to monitor (e.g. sched:sched_switch)

OPTIONS:
    --list <subsystem>      List available events in a given subsystem and exit
    --pid <pid>             Only monitor events from the specified PID
    --out <file>            Write trace output to a file in addition to stdout
    -h, --help              Print help
    -V, --version           Show version
```

---

### How It Works

* Enables specified tracepoints by writing to:

  ```
  /sys/kernel/debug/tracing/events/<subsystem>/<event>/enable
  ```
* Reads from `trace_pipe` in real-time.
* Optional PID filter is applied via:

  ```
  /sys/kernel/debug/tracing/set_ftrace_pid
  ```
* On exit (`Ctrl+C`), all enabled tracepoints are disabled.

---

### Permissions

Running this tool typically requires root or `CAP_SYS_ADMIN` privileges.

Use `sudo` if needed:

```bash
sudo ./trace_pipe syscalls:sys_enter_execve
```

---

### Acknowledgements

* Uses `tracefs`, a powerful interface to Linux kernel tracing.
* Built using Rust  crates:

  * [`clap`](https://crates.io/crates/clap) for CLI
  * [`ctrlc`](https://crates.io/crates/ctrlc) for signal handling
  * [`colored`](https://crates.io/crates/colored) for terminal output

Let me know if you'd like a `Makefile`, example logs, or packaging for crates.io or Debian/Yocto.
