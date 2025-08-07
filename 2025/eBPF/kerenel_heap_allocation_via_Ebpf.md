
Thanks for the clarification — you're asking for an **eBPF program to display a summary of kernel heap allocations**, not user-space ones.

In the kernel, heap allocations typically happen via functions like:

* `kmalloc()`, `kfree()`
* `__kmalloc()`, `kfree()`
* `kzalloc()`, `kvzalloc()`, etc.

To summarize kernel heap allocations using eBPF, we can:

* Hook into `__kmalloc()` and `kfree()` using **kprobes** and **kretprobes**
* Track allocations by storing allocated pointer and size in a BPF hash map
* Keep counters for total allocated and freed memory
* Print a summary periodically

---

### ✅ Kernel Heap Summary with BCC + eBPF (Python)

```python
from bcc import BPF
import time

bpf_program = """
#include <uapi/linux/ptrace.h>
#include <linux/slab.h>

BPF_HASH(allocs, u64, u64);  // pointer -> size
BPF_HASH(stats, u32, u64);   // 0 = alloc count, 1 = free count, 2 = total bytes allocated

int trace_kmalloc_entry(struct pt_regs *ctx, size_t size, gfp_t flags) {
    bpf_trace_printk("kmalloc size = %lu\\n", size);
    bpf_set_retval(ctx, size);  // store size in return context
    return 0;
}

int trace_kmalloc_return(struct pt_regs *ctx) {
    u64 ptr = PT_REGS_RC(ctx);
    u64 size = PT_REGS_PARM1(ctx);  // size passed to kmalloc

    if (ptr == 0)
        return 0;

    allocs.update(&ptr, &size);

    u32 alloc_key = 0, bytes_key = 2;
    u64 one = 1;

    u64 *ac = stats.lookup(&alloc_key);
    u64 *bt = stats.lookup(&bytes_key);
    if (ac) (*ac)++; else stats.update(&alloc_key, &one);
    if (bt) (*bt) += size; else stats.update(&bytes_key, &size);

    return 0;
}

int trace_kfree(struct pt_regs *ctx, void *ptr) {
    u64 address = (u64)ptr;
    u64 *size = allocs.lookup(&address);
    u32 free_key = 1;
    u64 one = 1;

    if (size) {
        u64 *fr = stats.lookup(&free_key);
        if (fr) (*fr)++; else stats.update(&free_key, &one);
        allocs.delete(&address);
    }

    return 0;
}
"""

# Load BPF program
b = BPF(text=bpf_program)

# Attach to __kmalloc (not kmalloc, as it’s a wrapper) and kfree
b.attach_kprobe(event="__kmalloc", fn_name="trace_kmalloc_entry")
b.attach_kretprobe(event="__kmalloc", fn_name="trace_kmalloc_return")
b.attach_kprobe(event="kfree", fn_name="trace_kfree")

print("Tracing kernel heap (kmalloc/kfree)... Press Ctrl+C to stop.")

try:
    while True:
        time.sleep(5)
        stats = b["stats"]

        allocs = stats[0].value if 0 in stats else 0
        frees = stats[1].value if 1 in stats else 0
        bytes_allocated = stats[2].value if 2 in stats else 0

        print("\n[Kernel Heap Summary]")
        print(f"  Total kmallocs:  {allocs}")
        print(f"  Total kfrees:    {frees}")
        print(f"  Bytes allocated: {bytes_allocated}")
except KeyboardInterrupt:
    print("\nExiting...")
```

---

### 🔧 How to Run

1. Install BCC: `sudo apt install bpfcc-tools python3-bcc`
2. Run the script as root:

   ```bash
   sudo python3 kernel_heap_summary.py
   ```

---

### 📋 Output (Example)

```
[Kernel Heap Summary]
  Total kmallocs:  1234
  Total kfrees:    1200
  Bytes allocated: 987654
```

---

### 🚫 Limitations

* Doesn’t capture other allocators like `vmalloc`, `kmem_cache_alloc`.
* Only tracks live allocations during the script runtime.
* Kernel pointer obfuscation (KASLR, KPTI, etc.) may affect tracing on hardened kernels.

---

### 🧠 Optional Enhancements

* Track memory per process or per PID (if you include `bpf_get_current_pid_tgid()`).
* Track peak heap usage.
* Monitor specific allocation sizes or flags.
* Add `vmalloc` and `kfree` tracking for a broader heap view.

---

Would you like a **C-based eBPF program using libbpf** instead of BCC?
