# what is trace_pipe:

Its a file in the Linux kernel's tracing filesystem (tracefs) that provides a real-time, human-readable view
of events recorded by the kernel's tracing infrastructure, spcifically *ftrace".

It acts a live, streaming output for the kernel's trace buffer.

### How it Works:

- *ftrace* tracing system in the linux kernel records various kernel events, such as function calls,
  scheduler activity, and I/O operations, into a ring buffer. 

- *trace_pipe* file is special interface that allows a user to read contents of this ring buffer as they are
  being writing

- *trace_pipe* file is special interface that allows a user to read contents of this ring buffer as they are
  being written. 

- when you read from /sys/kernel/tracing/trace_pipe, the kernel sends you a formatted stream of tracing
  events, this is similar to "tail -f" command on a log file.

- *trace_pipe* and *trace* ( another file tracefs ):
    - *trace_pipe* is a destructive operation, and once an event is read from the pipe its removed from the
      buffer and cannot be read again. 
    - *trace* file , when reading from the entire contents of the buffer is in non-destructive, but it
      does'nt provide dynamic real-time continuous stream that *trace_pipe* does.

### common use cases:

*trace_pipe* : essential for real-time system debugging and peformance analysis. It's often used to :
    - Monitor Linux kernel events. 
    - debug performance issues. Trace specific function call to point where delays are occuring. For
      example- you can enable function tracing for a specific subsystem and watch the call stack as it
      happens.
    - Analyze scheduling behaviour: Track context switches and CPU migrations in real time to understand how
      processes are being scheduled.
    - Provide a streaming data source for tools: Other performance analysis tools, like perf, can read from
      *trace_pipe* to process trace data live.

### Why use eBPF over trace_pipe:

If we can trace a systemcall say using "ftrace" why do we need eBPF program to trace/profile the system?

eBPF: More powerful, Programmable, and Flexible then Static tracepoings like "trace_pipe".

### Example:

What `trace_pipe` + ftrace gives you:

When you do:

```bash
echo 1 > /sys/kernel/debug/tracing/events/syscalls/sys_enter_bpf/enable
cat /sys/kernel/debug/tracing/trace_pipe
```

You get:

* A **pre-defined, fixed-format** trace of each syscall to `bpf()`
* **No filtering, no post-processing, no conditional logic**
* Just raw output streamed line by line
* Minimal control over what gets logged or how

This is **passive tracing** — good for basic monitoring or debugging.

---

###  What eBPF gives you:

Hooking an eBPF program (e.g. with tools like `bpftrace`, `bcc`, or direct `libbpf`) lets you:

| Feature                                                                | ftrace | eBPF |
| ---------------------------------------------------------------------- | ------ | ---- |
| Dynamic filtering (e.g., only trace PID 1234 or cmd==`BPF_MAP_CREATE`) | x      | ok   |
| Attach logic (e.g., count/map histograms)                              | x      | ok   |
| Collect stack traces                                                   | x      | ok   |
| Aggregate data (histograms, maps, metrics)                             | x      | ok   |
| Send events to userspace asynchronously                                | x      | ok   |
| Minimal performance overhead for complex use cases                     | x      | ok   |
| Program custom logic (e.g., drop events, rate limit)                   | x      | ok   |
| Runtime safety and verification                                        | x      | ok   |
| Hook *any* function, not just syscalls or tracepoints                  | x      | ok   |

---

### Example Scenario

Let’s say you want to trace only BPF programs being loaded (`cmd == BPF_PROG_LOAD`), and you want to record:

* The program type
* The process name
* The first few bytes of code being loaded
* The number of times this happens per second

**With ftrace** — not possible without writing a custom kernel module or filtering logs offline.

**With eBPF**, this is a few lines in `bpftrace`:

```bash
bpftrace -e '
tracepoint:syscalls:sys_enter_bpf /args->cmd == 5/ {
  @[comm] = count();
}
'
```

Or in C with libbpf, you could even inspect and validate contents of `struct bpf_attr`.

---

### When to use ftrace vs eBPF

| Use Case                                         | Tool                              |
| ------------------------------------------------ | --------------------------------- |
| Quick one-off syscall tracing                    | ftrace / `trace_pipe`             |
| Deep insight into syscall arguments and behavior | eBPF                              |
| Low-overhead production monitoring               | eBPF                              |
| Custom metrics, histograms, or stack traces      | eBPF                              |
| Full-system tracing                              | ftrace + eBPF (e.g., with `perf`) |

---

### Summary

You **can** get basic tracing with `trace_pipe`, but:

* **No filtering**
* **No aggregation**
* **No logic**
* **No control**

**eBPF gives you all of that** — it's essentially a programmable tracing and monitoring tool inside the kernel.

---


# *capabilities of `tracefs` and eBPF* beyond just using `trace_pipe`. 

Both are powerful observability tools in Linux, and they **complement** each other — `tracefs` is the 
traditional tracing framework, and eBPF is the next-generation programmable one.

Let’s look at the **“goodies”** in both:

---

## Overview

| Area                     | tracefs               | eBPF                                    |
| ------------------------ | --------------------- | --------------------------------------- |
| Syscall & kernel tracing | ok                    | ok                                       |
| Custom filtering/logic   | x                     | ok                                       |
| Aggregation/stats/maps   | x                     | ok                                       |
| Userspace interaction    | Limited               | Rich                                    |
| Tooling ecosystem        | Mature (perf, ftrace) | Rapidly growing (bcc, bpftrace, libbpf) |

---

## `tracefs` Features (under `/sys/kernel/debug/tracing/`)

Here are some powerful parts of `tracefs` beyond `trace_pipe`:

### 1. **Available Tracepoints**

* Directory: `/sys/kernel/debug/tracing/events/`
* System-wide static tracepoints (e.g., syscalls, scheduler, networking)
* List all:

  ```bash
  cat available_events
  ```

### 2. **Current Trace Buffer**

* File: `/sys/kernel/debug/tracing/trace`
* Snapshot of current trace buffer (vs. live stream in `trace_pipe`)

### 3. **Filter Events**

* Per-event filtering (very basic):

  ```bash
  echo 'common_pid == 1234' > events/sched/sched_switch/filter
  ```

### 4. **Function Tracer**

* Trace arbitrary kernel functions:

  ```bash
  echo function > current_tracer
  echo 'do_sys_open' > set_ftrace_filter
  ```

### 5. **Function Graph Tracer**

* Call graph visualization of kernel functions:

  ```bash
  echo function_graph > current_tracer
  ```

### 6. **Stack Tracing**

* Collect kernel (and user) stack traces

### 7. **Kprobes/uprobes**

* Add dynamic tracing probes:

  ```bash
  echo 'p:myprobe sys_openat' > kprobe_events
  echo 1 > events/kprobes/myprobe/enable
  ```

### 8. **Histograms**

* Limited support via synthetic events or perf histogram scripting

---

## eBPF Features (via bpftrace, bcc, libbpf, etc.)

### 1. **Programmatic Logic**

* Conditional tracing:

  ```bpftrace
  tracepoint:syscalls:sys_enter_bpf /args->cmd == 5/ { printf("prog load\n"); }
  ```

### 2. **Maps, Histograms, Stats**

* Count, average, and bucketize data:

  ```bpftrace
  @hist = hist(args->cmd);
  ```

### 3. **Stack Traces**

* Kernel and userspace:

  ```bpftrace
  profile:hz:99 { @[ustack] = count(); }
  ```

### 4. **Attach to Anything**

* Tracepoints, kprobes, uprobes, perf events, networking hooks, etc.

### 5. **Async User-Space Events**

* Send data to user space via `perf_event_output`

### 6. **Safety & Performance**

* Verified bytecode, JIT-compiled for safety and speed

### 7. **Tooling Ecosystem**

* `bpftrace` – high-level DSL
* `bcc` – Python wrappers
* `libbpf` – C/C++ raw API
* Tools like:

  * `execsnoop`, `opensnoop`, `runqlat`, `tcplife`, `tcpdump`-style tracing

---

## Tool Comparison Summary

| Tool                    | Strength                            |
| ----------------------- | ----------------------------------- |
| `trace_pipe`            | Live syscall & tracepoint stream    |
| `trace`                 | Snapshot of buffer                  |
| `function_graph` tracer | Visualize call graphs               |
| `kprobes/uprobes`       | Dynamically probe any symbol        |
| `perf`                  | Rich profiling & tracing            |
| `bpftrace`              | High-level programmable tracing     |
| `bcc`                   | Rich Python-based tracing           |
| `libbpf`                | Low-level, production-grade tracing |
| `bpftool`               | Inspect and manage eBPF programs    |

---

## Summary

If you're serious about observability, both `tracefs` and `eBPF` are essential tools in your toolbox:

* **Use `tracefs`** for fast prototyping, basic tracing, and simple syscalls/function tracing.
* **Use eBPF** when you need control, programmability, performance, or integration into larger systems 
  (like metrics exporters or security tools).

---

