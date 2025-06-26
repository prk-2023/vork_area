# eBPF programs:

eBPF is a technology in the kernel that enables running user-defined programs based on "**events**", 
with a validator mechanism ensuring the security of the eBPF programs running in the kernel.

## Linux kernel event types:

- Linux kernel is multi-layered, event-driven system. 

- Kernel events represent significant activities in the system, like process actions, file access,
  networking and hardware interrupts.
  These can categorize **Linux Kernel Events** into several major types, especially from the perspective of
  tracing, monitoring, and observability.

## eBPF Hook Points:

  Hook points are predefined locations in the kerenl where you can attach eBPF programs. When a kernel event
  occurs at a hook point the attached eBPF program is executed.
  Hook points are available across many Linux kernel sub-systems such as

  | Subsystem        | Hook Examples                       | Description                                  |
  | ---------------- | ----------------------------------- | -------------------------------------------- |
  | *Networking*     | `tc`, `XDP`, `socket filter`        | Pkt filtering, processing at different stages|
  |                  |                                     | (inbound/outbound, early/late)               |
  | *Tracing*        | `kprobes`, `tracepoints`, `uprobes` | Kernel/user fun's entry/exit, specific kernel|
  |                  |                                     | events                                       |
  | *Security*       | `LSM hooks`                         |Security policies eg restricting `open`,`exec`|
  | *Filesystem*     | `VFS hooks`                         | File open/read/write events                  |
  | *System calls*   | `seccomp` (extended with eBPF)      | Filter syscalls with fine-grained logic      |
  | *Scheduler*      | `cgroup hooks`, `perf events`       | Per-process/per-cgroup resource monitoring   |

  The hook points turn the kernel into a *event-driven system* from the perspective of observability and
  control.
  - Event = Hook point activation : every time the kernel hits a hook point ( like a pkt being received or a
    file being opened), it generates an event.
  - eBPF program = event handler: The eBPF program attaches to a hook point acts as an *event handler* which
    can:
    * Observe the event (ex: trace function parameters)
    * modify behaviour ( ex: block a syscall)
    * collect stats ( ex: latency ..)
    * emit custom events to user-space
  - Asynchronous and Low overhead : eBPF programs run in-kernel without context switching. They're JIT
    compiled for speed and have strict safety check ( no loops, bounded execution time), making them ideal
    for handling events in real-time with *minimal performance overhead*.
    example: when a packet is received:
    1. The kernel hits the *XDP hook* early in the network stack.
    2. If a eBPF program is attached to this hook, it runs immediately.
    3. The eBPF program can:
        - Allow the packet 
        - Drop it 
        - Redirect it 
        - Modify it 
       This is a classic event-based model: *event-trigger(pkt in)-> handler execution (eBPF program).
    
    Summary: 
    | Concept       | eBPF Equivalent                           |
    | ------------- | ----------------------------------------- |
    | Event         | Hook point being hit                      |
    | Event handler | eBPF program                              |
    | Event source  | Kernel subsystem (network, syscall, etc.) |
    | Event loop    | Kernel's execution path                   |

 1. System Call events ( syscalls )

  These events occur in kernel when a user-space application makes request to the kernel.
  Example syscalls like read(),  write(), open(),...
  Use case: Monitor what system calls a process makes.
  This also helps to detect abnormal behaviour ( example: execve for malware detection )

  A *system call(syscall)* is controlled way for user-space applications to request service from the kernel,
  such as I/O, memory allocation, process control...
  From a event-driven perspective, syscalls act as *event triggered by user-space programs*.

  Event-driven classification of system calls:
  | Component           | Event-Driven Interpretation                                      |
  | ------------------- | ---------------------------------------------------------------- |
  | **Event Source**    | User-space program invoking a syscall                            |
  | **Event Trigger**   | Execution of a syscall instruction (e.g., `int 0x80`, `syscall`) |
  | **Event Type**      | Type of syscall (e.g., `open()`, `read()`, `fork()`)             |
  | **Event Handler**   | The kernel's implementation of the syscall                       |
  | **Event Observers** | Mechanisms like eBPF, seccomp, audit, LSMs                       |

  Example: open("/etc/passwd", O_RDONLY)
  - user-space calls *open()*
  - Triggers an *event*: the open *syscall*
  - The kernel dispatches to its internal handler: *sys_openat()*
  - observers (if any) like eBPF, seccomp, audit may intercept or inspect it.
  - kernel completes the action or returns the error.

  *syscalls* can be further grouped into *event catefories*:
  | Syscall Category      | Example Syscalls                 | Event Type Description         |
  | --------------------- | -------------------------------- | ------------------------------ |
  | **File I/O**          | `open`, `read`, `write`, `close` | File access or modification    |
  | **Process Control**   | `fork`, `execve`, `wait`         | Process lifecycle events       |
  | **Memory Management** | `mmap`, `brk`, `munmap`          | Allocation/deallocation events |
  | **Interprocess Comm** | `pipe`, `socket`, `sendmsg`      | Communication setup and use    |
  | **Device I/O**        | `ioctl`, `read`, `write`         | Device-level event triggering  |
  | **Signals**           | `kill`, `sigaction`, `sigreturn` | Signal generation/handling     |
  | **Network**           | `connect`, `accept`, `bind`      | Network interaction events     |
  
  Observing *syscall events* ( hook mechanism)
  Various tools hook into syscall events:
  | Mechanism   | How It Hooks Syscalls                              |  Use Case                          |
  | ----------- | -------------------------------------------------- | ---------------------------------- |
  | eBPF  |Attaches to syscall entry/exit via tracepoints or kprobes |Observability,performance monitoring|
  | seccomp| Filters syscalls before execution (with optional eBPF filters)     | Security sandboxing     |
  | LSM    | Hooks into security-related syscall paths (via security\_\* hooks) | Access control          |
  | Audit  | Logs syscall activity via auditd                                   | Compliance & tracking   |
  | ptrace | Traps syscalls for inspection by debugger                          | Debugging, sandboxing   |

  eBPF + Syscalls: You can attach an eBPF program to the 
  *raw_syscalls:sys_enter* or *sys_exit* tracepoint to observe all syscall events.  

  Summary: system calls as kernel events:
  | Event Component | Syscalls Perspective                 |
  | --------------- | ------------------------------------ |
  | Event Source    | User-space program                   |
  | Event Trigger   | Invocation of a syscall              |
  | Event Type      | Specific syscall type (e.g., `read`) |
  | Event Handler   | Kernel syscall implementation        |
  | Event Observers | eBPF, seccomp, LSMs, audit, ptrace   |



2. Tracepoints:

  *Tracepoints* are static instrumentation points *built into the kernel* placed at key code paths ( defined
  by kernel developers). They allow developers and observability tools to get insight into the kernel's
  internal operations without modifying kernel behaviour. 

  Tracepoints are used by *ftrace*, *perf*, *eBPF*, and *LTTng*,...

  They're predefined locations in the kernel where you can subscribe to be notified when certain *events
  occur* (eg: process scheduling, block I/O, syscall entry).

  Mapping tracepoints to event-driven components:
  | Event Component   | Tracepoint Interpretation                                                          |
  | ----------------- | ---------------------------------------------------------------------------------- |
  | Event Source  | The Linux kernel subsystem emitting the tracepoint (e.g., scheduler, VFS, networking)  |
  | Event Trigger | Code path reaches a tracepoint and emits it                                            |
  | Event Type    | The specific tracepoint name (e.g., `sched:sched_switch`, `syscalls:sys_enter_execve`) |
  | Event Handler | Attached listener (e.g., eBPF program, perf, tracefs)                                  |
  | Event Payload | Structured arguments passed by the tracepoint (e.g., process ID, filename, etc.)       |

  Example: Tracepoints *sched:sched_switch*
  - Location: emitted in the scheduler when the kernel switches between processes.
  - Event: Process context switch.
  - Payload: Includes info like prev PID, next PID, CPU ID, etc..
  - Consumers: eBPF programs or perf script that logs or analyzes CPU scheduling behaviour.

  Characteristics of Tracepoints:
  | Feature                   | Description                                                                |
  | ------------------------- | -------------------------------------------------------------------------- |
  | Static                | Declared in kernel code using `TRACE_EVENT()` macros                           |
  | Efficient             | If no listener is attached, the overhead is negligible                         |
  | Typed Arguments       | Each tracepoint passes structured and typed data                               |
  | Multiple Consumers    | `perf`,`bpftrace`,`SystemTap`, and custom eBPF programs can attach listeners   |
  | Kernel Version Stable | Many tracepoints are stable across kernel versions for tool compatibility      |

  Tracepoints vs Other Kernel Event Mechanisms
  | Mechanism      | Trigger Source             | Scope                        | Use Case                  |
  | ---------------- | -------------------------- | -------------------------- | ------------------------- |
  | Syscalls     | User program               | Entry/exit of kernel via API | Interface-level monitoring  |
  | eBPF kprobes | Any kernel function        | Dynamic, more invasive       | Low-level debugging         |
  | Tracepoints  | Internal kernel code       | Static & efficient       |Observability, structured events |
  | LSMs         | Security-sensitive actions | Access control only      |Security and policy enforcement  |

  Tracepoints + eBPF: Powerful Combo:
  eBPF programs can be attached to tracepoints to perform real-time analytics or filtering.
  example: 
  bpftrace -e 'tracepoint:sched:sched_switch { printf("CPU %d: %s -> %s\n", cpu, args.prev_comm, args.next_comm); }'

  This eBPF script reacts to every context switch — classic event-driven processing.

  Summary:
  | Tracepoint Role      | Event-Driven Analogy  |
  | -------------------- | --------------------- |
  | Defined in kernel    | Event source location |
  | Triggered at runtime | Event emission        |
  | Accepts listeners    | Event subscription    |
  | Exposes args         | Event payload         |
  | Used by tools        | Event handlers        |

  Recap: Tracepoints as Event Emitters:
  Tracepoints turn the Linux kernel into a publish-subscribe system:
  - Publishers: Kernel code paths emitting tracepoints
  - Subscribers: Observability tools attaching to those tracepoints
  - Events: Structured data emitted when tracepoints are hit

  This model is fundamental to modern Linux observability and performance debugging 
  — tracepoints are among the safest and most structured ways to consume kernel events.

  ==> List all available tracepoints:
  ``` 
  bpftrace -l 'tracepoint:syscalls:*exec*' 
  ```
3. Kprobes and Kretprobes?

   These are Dynamic kernel instrumentation mechanism related to the event-driven architecture of the
   kernel.

   Kprobes: they let you dynamically attach probes (handlers) to almost any kernel function or instruction
   address. When that point is hit, your handler executes.

   Kretprobles: are special types of kprobes that trigger *after a function returns*, allowing inspection of
   the return values.

   Kprobe and Kretprobes: together provide entry and exit probes for arbitarary functions.

   These can be thought as a *dynamic event triggers*, they enable custom actions to be executed when
   certain _function-level kernel events_ occur.

   kprobes and Kretprobes ( event modle)
   | Event Component   | Kprobe/Kretprobe Interpretation                      |
   | ----------------- | ---------------------------------------------------- |
   | **Event Source**  | Kernel function or address                           |
   | **Event Trigger** | Function is entered (kprobe) or returned (kretprobe) |
   | **Event Type**    | Specific function (e.g., `do_sys_open`)              |
   | **Event Handler** | Custom logic (e.g., eBPF program or kernel module)   |
   | **Event Payload** | Function args (kprobe) or return value (kretprobe)   |

  Example: kprobes on *sys_execve*
  - Target Function: *sys_execve* ( system call to run a program)
  - Kprobe: triggers when the function is entered.
    ( we get access to syscall arguments (filename, args))
  - Kretprobes: Triggers when the function returns
    ( we inspect the return val (success/fail))

  How Kprobes work:
  - A breakpoint or jump instruction is inserted at the target function address.
  - when the kernel hits this point, it diverts execution to your registered handler.
  - kretprobe hook into the functions return address using a return trampoline.

  Usescases for kprobes/kretprobe:
  | Use Case                | Example                                            |
  | ----------------------- | -------------------------------------------------- |
  | Debugging kernel issues | Attach to internal functions to trace execution    |
  | Security monitoring     | Watch for suspicious calls to `do_execve`          |
  | Performance profiling   | Measure function latency with kprobe + kretprobe   |
  | Observability via eBPF  | Collect arguments/return values for custom metrics |

  Comparison with Tracepoints:
  | Feature        | Tracepoints                        | Kprobes                                      |
  | ---------------| ---------------------------------- | -------------------------------------------- |
  | Static/Dynamic | Static (predefined in kernel code) | Dynamic (can probe almost any function)      |
  | Typed Args     | Yes (predefined structs)           | No (manual parsing of registers/stack)       |
  | Overhead       | Very low                           | Slightly higher due to dynamic nature        |
  | Safety         | Very safe                          | Needs care — can break the system if misused |
  | eBPF Support   | Yes (via `tracepoint` hook)        | Yes (via `kprobe`/`kretprobe` hooks)         |

  Kprobes + eBPF: Dynamic Event Handling
  With eBPF, you can attach lightweight programs to kprobes/kretprobes for safe, high-speed, real-time 
  analysis. Example with bpftrace
  \# Monitor execve system calls dynamically
  bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("execve: %s\n", str(args->filename)); }'
  bpftrace -e 'kprobe:sys_execve { printf("execve: %s\n", str(arg0)); }'

  \# Capture return value of execve
  bpftrace -e 'kretprobe:sys_execve { printf("Return: %d\n", retval); }'

  Summary:
  | Kprobe Concept       | Event-Driven Analogy        |
  | -------------------- | --------------------------- |
  | Probe Target         | Event source                |
  | Hook on Entry        | Event trigger (start)       |
  | Hook on Return       | Event trigger (completion)  |
  | Probe Handler        | Event handler               |
  | Args/Retval          | Event payload               |
  | eBPF, bpftrace, perf | Event consumers/subscribers |


  ==> List all available kprobes and kretprobes:
  ``` 
  bpftrace -l 'kprobe:*exec*' 
  bpftrace -l 'kretprobe:*exec*' 
  ```
  Kprobes and Kretprobes turn arbitrary kernel functions into event sources, enabling precise and real-time 
  inspection of the kernel’s internal behavior. 
  Combined with eBPF, they form a dynamic, programmable event-handling system inside the Linux kernel 
  — powerful for debugging, security, and observability.



4. uprobes and uretprobes:

   These are user-space counterparts of the kprobes and kretprobes.

   Uprobes are dynamic probes that you can attach to functions in *user-space binaries or shared libraries*.

   uretprobes are similar, but trigger when the instrumented function returs, letting you access its return
   values.

   Uprobes in even-driven kernel model:
   transform function calls in user-space application into observable events:

   | EventComponent| Uprobe/Uretprobe Interpretation                         |
   | ------------- | ------------------------------------------------------- |
   | Event Source  | User-space binary or shared library                     |
   | Event Trigger | Function entry (Uprobe) or return (Uretprobe)           |
   | Event Type    | Specific symbol/function (e.g., `malloc`, `main`)       |
   | Event Handler | Uprobe or Uretprobe handler (e.g., eBPF program)        |
   | Event Payload | Function arguments (Uprobe) or return value (Uretprobe) |


   Example: malloc in user-program:
   - You attach a Uprobe to malloc in libc.so 
   - Every time any user process calls malloc(), the Uprobe triggers. 
   - You can log: 
        Function arguments ( exL size requested )
        stack trace ( to see caller )
   - with a uretprobe you get the pointer returned by malloc()

   Characteristics of uprobes and uretprobes:
   | Feature       | Description                                                   |
   | ------------- | ------------------------------------------------------------- |
   | Dynamic       | Attach to any symbol in a user binary or library              |
   | Non-intrusive | No modification to the user-space binary required             |
   | Safe          | Managed via kernel breakpoint handling                        |
   | Kernel-backed | Handled by the Linux kernel’s Uprobe infrastructure           |
   | Supports eBPF | Allows safe, high-performance analysis of user-space behavior |

   Comparison: Uprobes and kprobes:
   | Feature           | Kprobes (Kernel)       | Uprobes (User-space)       |
   | ----------------- | ---------------------- | -------------------------- |
   | **Target**        | Kernel function        | User-space function        |
   | **Access**        | Kernel context         | User-space context         |
   | **Use Cases**     | Debug kernel internals | Debug application behavior |
   | **eBPF Support**  | Yes                    | Yes                        |
   | **Return Probes** | Kretprobes             | Uretprobes                 |

   Uprobes + eBPF = Dynamic Application Event Handling:

   \# Trace every call to malloc from any binary
   sudo bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc { printf("malloc size: %d\n", arg0); }'

   \# Trace return value of malloc
   sudo bpftrace -e 'uretprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc {printf("malloc ret: %p\n", retval); }'


5. Netfilter Hooks /XDP/TC 
   
   Netfilter Hooks, XDP (eXpress data path) and TC (traffic control) are mechanism for interacting with
   *network packet processing* in the kernel. These are all part of the event-driven model, where specific
   events (ex:pkt arrival) trigger execution of eBPF program at defined points in the netowrk stack.

   Netfilter Hooks: 
   - Subsystem in the kernel mainly for packet filtering NAT and other firewall related  operations.
   - Hookpoints: Operates at several points in the packet flow:
        - NF_INET_PRE_ROUTING
        - NF_INET_LOCAL_IN
        - NF_INET_FORWARD
        - NF_INET_LOCAL_OUT
        - NF_INET_POST_ROUTING
   - eBPF Integration: eBPF can attach to netfilters via *nftable* using *nftable eBPF maps* or *BPF
     programs in xt_bpf* iptables extension.
   - Usage: stateful firewall, NAT, packet mangling
   - Event model fit: Triggered by pkt reception at defined hook points, - fits the event-driven model as it
     reacts to packets entering/exiting various parts of the stack.

   XDP Hooks: (eXpress Data path)
   - A fast, Low-level packet processing framework that operates *very early in the pkts life* right after
     it it received by the NIC driver *before the network stack*
   - Hook Point: Attached to driver level (rx path) before SKB (socket buffer) is allocated.
   - eBPF Integration: eBPF progs run in the context of *XDP* to decide whether to:
     * *XDP_PASS*: let the packet go up the stack.
     * *XDP_DROP*: drop it immediately.
     * *XDP_TX*:  Send it back out.
     * *XDP_REDIRECT*: Send to different interface or User-space.
   - Usage: DDoS mitigation, filtering, load balancing.
   - Event model fit:  Ideal for *reactive network applications*, triggered on *pkt reception at the
     earliest point*, enabling real-time decisions.

   TC : Traffic control:
   Originally used for traffic shaping and queuing (QoS), now extended to allow eBPF programs to run at
   *ingress and egress* points of network interfaces.
   - Hookpoints:
     * *TC_INGRESS*: Before pkt is processed by the network stack.
     * *TC_EGRESS*: After pkt is processed by the networking stack, before leaving the system.
   - eBPF Integration: *cls_bpf* classifier allows eBPF programs to be attached to these points using *tc*
     command.
   - Usage: QoS enforcement, rate limiting, packet modification, observability.
   - Event model fit: Like XDP, this is event-driven by packets moving through interfaces, but at a higher
     level (using SKBs)

   Event based  architecture fit:
   | Component     | Trigger Event      | Stack Position      | Latency Impact | eBPF Role                  |
   | ------------- | ------------------ | ------------------- | -------------- | -------------------------- |
   |XDP  | Pkt recv at NIC          | Earliest (L2/L3)    | Lowest         | Early-drop,redirect,filter        |
   |Netfilter |Pkt processed by kernel network stack|Mid(IP processing) | Medium | Stateful/NAT rules,filtering|
   |TC  | Pkt enters or leaves network interface | Late (L3–L4)   | Higher | QoS, shaping, visibility, logging |


   Summary:

| Feature    | XDP                     | TC                        | Netfilter                      |
| ---------- | ----------------------- | ------------------------- | ------------------------------ |
| Hook Point | NIC driver (early)      | Ingress/Egress (TC layer) | Netfilter hooks (IP layer)     |
| Use Cases  | High-speed filtering    | QoS, shaping, debugging   | Firewall, NAT, packet mangling |
| Speed      | Very High               | Moderate to High          | Moderate                       |
| Event Type | Packet arrival (driver) | Packet ingress/egress     | Packet routing decision        |
| eBPF Usage | `xdp_bpf`               | `cls_bpf`, `act_bpf`      | `xt_bpf` or via nftables       |


6. Perf Events / Hardware Counters

  Events generated by performance monitoring units (PMUs) or SW counters ( CPU cycles, cache misses.. )
  kerenl subsystem that provides access to performance monitoring feature - both sw and hw events.

  Event Source:
  - SW events: Scheduler switches, page faults, syscalls etc...
  - HW events: CPU cycles, cache misses, branch misses, instructions retired...etc
  - eBPF Integration: eBPF progs can be attched to perf events via:
    * *perf_event_open()*  (user-space)
    * *bpf_program__attach_perf_event()* (libbpf)
  - Triggers *BPF_PROG_TYPE_PERF_EVENT*

  Usage:
  - Profiling CPU bound applications.
  - Performance metrics collection
  - Observability tools like *bcc, bpftrace, perf, systemtap*

  HW Performance Counters:
  Special registers in CPU that count specific HW-level activities
  - CPU cycles
  - Branch instructions
  - Cache references/misses.
  Exposed Via: *perf* subsystem ( linux *perf_event* API) often accessed througn *perf_events* in eBPF.
  - eBPF Role: eBPF programs can be triggered based on thresholds (eg: "every 1 million instructions").
  - Acts as hardware-triggered events in the event model.
  Example Events:
    PERF_COUNT_HW_CPU_CYCLES
    PERF_COUNT_HW_CACHE_MISSES

  Kernel Event Model: Rather than being triggered by packets, like XDP or TC, perf events are triggered by 
  system or CPU activities — such as:
  - A specific number of CPU cycles elapsing
  - A specific syscall being executed
  - A context switch happening
  - A tracepoint filtering
  When the event occurs, a registered eBPF program is invoked as an event handler, 
  just like an interrupt service routine.
  
  Summary:
| Feature           | Perf Events                       | Hardware Counters                          |
| ----------------- | --------------------------------- | ------------------------------------------ |
| Hook Point        | Software/hardware event system    | CPU performance counters                   |
| Trigger           | Syscalls, faults, context switch  | Cache misses, branch events                |
| eBPF Program Type | `BPF_PROG_TYPE_PERF_EVENT`        | `BPF_PROG_TYPE_PERF_EVENT`                 |
| Event Origin      | Kernel tracepoints or software    | Hardware PMU (Performance Monitoring Unit) |
| Use Cases         | Observability, profiling, tracing | Low-overhead CPU profiling                 |
| Speed             | Low latency, async                | Very low overhead, CPU-level               |
| Example Tools     | `bpftrace`, `perf`, `bcc`         | `perf top`, `bpftrace -e ...`              |
| Trigger Frequency | Tunable (e.g., every N syscalls)  | Tunable (e.g., every 1M cycles)            |
 
   Analogy with Networking Hooks:

| Hook Type   | What Triggers It             | Domain        | Program Type                  |
| ----------- | ---------------------------- | ------------- | ----------------------------- |
| XDP         | Network packet at NIC        | Networking    | `BPF_PROG_TYPE_XDP`           |
| TC          | Packet ingress/egress        | Networking    | `BPF_PROG_TYPE_SCHED_CLS`     |
| Netfilter   | Packet at Netfilter hooks    | Networking    | `BPF_PROG_TYPE_SOCKET_FILTER` |
| Perf Events | Kernel or software event     | Observability | `BPF_PROG_TYPE_PERF_EVENT`    |
| HW Counters | CPU event (e.g., cache miss) | Observability | `BPF_PROG_TYPE_PERF_EVENT`    |

  Usescases:
  - cpu profiling
  - hotspot detection
  - sampling based analysis

  Tools that use it:
  - perf 
  - flamegraph
  - eBPF (perf_event_open )


7. Scheduler Events

   Triggered by the process/thread scheduler — when tasks are switched in or out, blocked, etc.

   Use Case : 
   - Track CPU usage and context switches
   - Visualize process lifetimes

   Example Tracepoints
   - sched:sched_switch
   - sched:sched_wakeup

8. Filesystem / VFS Events

   File access (read/write/open), mount/unmount, etc

   Use Case: Monitor file activity & Detect suspicious file access (ransomware detection)
   Tools: 
   - Audit subsystem
   - fanotify/inotify
   - eBPF (via tracepoints or LSM)

 9. LSM (Linux Security Module) Hooks

    Security decision points in the kernel (e.g., before opening a file or sending a packet).

    Use Case:
    - Enforce security policies (e.g., allow/deny file access).
    - Runtime enforcement in tools like SELinux, AppArmor, or eBPF-based LSMs.

10. Cgroup Events

    Triggered by container and group-based resource changes.

    Use Case:
    - Monitor or restrict CPU, memory, and I/O per container.
    - Attach eBPF programs to enforce limits or collect stats.





 Summary of all the events typs in kernel:
| Event Type         | Trigger Source      | Hook Mechanism       | Common Use Case                   |
| ------------------ | ------------------- | -------------------- | --------------------------------- |
| Syscalls           | App → Kernel        | Tracepoints, kprobes | Auditing, sandboxing              |
| Tracepoints        | Static kernel hooks | eBPF, perf           | Metrics, low-overhead tracing     |
| Kprobes/Kretprobes | Kernel functions    | eBPF                 | Arbitrary function tracing        |
| Uprobes/Uretprobes | User-space funcs    | eBPF                 | App-specific profiling            |
| Netfilter/XDP/TC   | Packets             | eBPF, nftables       | Networking & security enforcement |
| Perf Events        | CPU counters        | perf, eBPF           | Performance profiling             |
| Scheduler Events   | Kernel scheduler    | Tracepoints          | CPU usage, load analysis          |
| Filesystem Events  | VFS layer           | Auditd, fanotify     | File access monitoring            |
| LSM Hooks          | Kernel security     | SELinux, eBPF LSM    | Access control                    |
| Cgroup Events      | Resource changes    | eBPF                 | Container isolation, metrics      |

