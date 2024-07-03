# extending Linux Kernel with eBPF and Rust.

## What is EBPF:

- eBPF: extended Berkely Pkt Filter

- BPF (Berkeley Packet Filter) technology is used for filtering network packets. 
- Originally developed in the 1990s at the Univ of Cal, Berkeley. 
- Over time, the Linux kernel community extended and enhanced BPF, leading to the creation of eBPF (extended BPF).

## BPF VM:

- The term BPF is also used to refer the VM that runs in the Kernel, which is responsible for executing
BPF programs, (the BPF programs are writen to run on the VM ), The VM is offen refered to as BPF virtual machine 
or BPF interpreter.

- VM tasks:
    - Loading and Verifying BPF progs ( load into memory and verify its correctness and safety before running them )
    - Executing BPF instructions: VM executes the BPF instructions using the eBPF instruction set to perform 
    filtering, tracing, or other tasks.
    - Managing memory and resources: VM manages the memory and resources required by BPF programs, ensuring that 
    they do not access unauthorized areas of memory or consume excessive resources.
    - Sandbox Env: Vm provides Sandboxed env for BPF programs, isolating them from the rest of the kernel and 
    preventing them from causing harm or accessing sensitve data.

- BPF VM :
    - Implemented as a part of the kernel (requires related CONFIGS_ enabled) and is tightly integrated with 
    the kernel internals. 
    - Its responsible for executing BPF programs in various contexts, such as
        1. Socket Filtering: VM exe's BPF progs attached to sockets to filter incomming and outgoing network pkts.
        2. Tracing: VM exe's BPF progs attached to tracepoints to collect and analyze system events and performance.
        3. XDP: BPF progs attached to XDP(eXpress Data Path) to perform high-performance pkt processing & filtering.
        4. Other Use cases: VM exe'c BPF progs in other contexts such as for security monitoring pkt processing and forwarding.
NOTE:
    - BPF term refers to both Instruction Set and VM that executes BPF programs in the kenrel.
    - BPF VM provides a sandboxed env for executing BPF programs ensuring safely and correctness allowing to  cover wide range of tasks.

## Extension to BPF: 

The main reasons for extending BPF were:

1. **Limited instruction set**: 
The original BPF had a limited set of instructions, which made it difficult to implement complex filtering rules.
2. **Performance**: BPF was not optimized for modern CPU architectures, leading to performance issues.
3. **Security**: BPF had some security limitations, such as the lack of memory protection and limited access ctrl.

To address these limitations, the Linux kernel community extended BPF to create eBPF. 
The key changes and additions include:

**Instruction Set Extensions**:

1. **New instructions**: eBPF introduced new instructions, such as `call` and `exit`, which enable more complex filtering rules.
2. **Wider registers**: eBPF registers were increased from 32 bits to 64 bits, allowing for more efficient processing of larger packets.
3. **Improved arithmetic**: eBPF added support for more advanced arithmetic operations, such as multiplication and division.

**Performance Optimizations**:

1. **Just-In-Time (JIT) compilation**: eBPF introduced JIT compilation, which translates BPF bytecode into native machine code, resulting in significant performance improvements.
2. **Cache-friendly design**: eBPF was optimized for modern CPU cache hierarchies, reducing memory access latency.

**Security Enhancements**:

1. **Memory protection**: eBPF introduced memory protection mechanisms, such as bounds checking and access control, to prevent buffer overflows and other security vulnerabilities.
2. **Verifier**: eBPF includes a built-in verifier that checks the safety and correctness of BPF programs before they are executed.

**Additional Features**:

1. **Maps**: eBPF introduced maps, which are data structures that allow BPF programs to store and retrieve data.
2. **Program types**: eBPF supports multiple program types, such as socket filters, tracepoints, and XDP (eXpress Data Path).
3. **Attach types**: eBPF allows attaching programs to various points in the kernel, such as sockets, tracepoints, and network devices.
4. **Helper functions**: eBPF provides a set of helper functions that can be called from BPF programs, such as `bpf_get_current_pid_tgid()` and `bpf_get_current_uid_gid()`.

**Other notable changes and additions**:

1. **BPF Type Format (BTF)**: eBPF introduced BTF, a metadata format that describes the layout of data structures and functions.
2. **BPF syscall**: eBPF provides a syscall interface for loading, attaching, and managing BPF programs.
3. **bpftool**: eBPF includes a command-line tool, bpftool, for managing and debugging BPF programs.
4. **Integration with other kernel subsystems**: eBPF has been integrated with various kernel subsystems, such as the networking stack, tracing, and security frameworks.

These changes and additions have transformed eBPF into a powerful and flexible technology for filtering, tracing, and securing network packets, as well as for implementing various other kernel-level functionality.
