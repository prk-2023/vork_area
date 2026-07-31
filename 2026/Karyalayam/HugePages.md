# HugePages:


## Page:

A **page** is the basic unit of memory management used by the operating system and the CPU. 

Instead of treating memory as one long continuous block, memory is divided into fixed-size chunks called 
**pages**.

Think of it like a book:

* **Memory** = the entire book
* **Pages** = the individual pages of the book
* The operating system keeps track of which pages belong to which process.

### Virtual memory

Every process sees its own **virtual address space**. 

For example, your program might think it has memory like this:

```text
Virtual address space:

0x00000000
+-----------+
| Page 0    |
+-----------+
| Page 1    |
+-----------+
| Page 2    |
+-----------+
| ...       |
+-----------+
```

These virtual pages are mapped to physical RAM by the operating system.

For example:

```text
Virtual page   Physical page

Page 0   --->  RAM page 42
Page 1   --->  RAM page 810
Page 2   --->  RAM page 13
```

The pages don't have to be adjacent in physical memory.

---

### Why use pages?

Without paging, every program would require one large, contiguous chunk of RAM.

Suppose you need 12 KB.

Without pages:

```text
RAM

+---------------------------+
| 12 KB contiguous space    |
+---------------------------+
```

If there isn't one continuous 12 KB block available—even if there is 100 MB free in total—the allocation
could fail.

With paging (assuming 4 KB pages):

```text
Need 12 KB

Page A
Page B
Page C
```

These pages can be stored anywhere:

```text
RAM

Page A -> Frame 18

Page B -> Frame 500

Page C -> Frame 9
```

The operating system tracks these mappings, so your program still experiences them as one continuous 12 KB
region.

---

### Why are pages fixed size?

Using a fixed size makes memory management much simpler.

If the page size is 4 KB:

* Every page is exactly 4,096 bytes.
* Every physical page frame is also exactly 4,096 bytes.
* The operating system only needs to record which physical frame each virtual page maps to.

---

### What is a page table?

A **page table** records the mapping between virtual pages and physical memory.

For example:

| Virtual page | Physical frame |
| ------------ | -------------- |
| 0            | 52             |
| 1            | 120            |
| 2            | 8              |
| 3            | Not in RAM     |

When your program accesses an address, the CPU consults the page table (with help from the **Translation
Lookaside Buffer (TLB)**) to determine the corresponding physical location.

---

#### Example

Suppose the page size is 4 KB and your program accesses:

```text
Address = 9000
```

Since:

* 4 KB = 4096 bytes

The address falls into:

```text
9000 / 4096 = page 2
remainder = 808
```

So the CPU:

1. Looks up virtual page 2 in the page table.
2. Finds the corresponding physical frame (say, frame 100).
3. Accesses byte 808 within physical frame 100.

---

### Relation to hugepages

A normal page is usually:

```text
4 KB
```

A hugepage might be:

```text
2 MB
```

or

```text
1 GB
```

Instead of managing many small 4 KB pages:

```text
[4K][4K][4K][4K]...
```

the operating system can manage one large page:

```text
[          2 MB          ]
```

This reduces the number of page table entries and TLB lookups, which can improve performance for
applications that use large amounts of memory.

In essence, a page is the operating system's standard "block size" for memory. Just as a filesystem stores
data in fixed-size disk blocks, the operating system stores and manages RAM in fixed-size memory pages.

---

## Huge pages


Kernel **hugepages** are memory pages that are much larger than the standard memory page size. 

They reduce the overhead of managing virtual memory by allowing a single page table entry to cover a much
larger region of memory.

### Why hugepages exist

Normally, memory is divided into small fixed-size pages:

* Standard page size: **4 KB** (on most x86-64 Linux systems)
* Hugepage sizes commonly available:

  * **2 MB**
  * **1 GB** (on hardware that supports it)

If an application allocates 1 GB of memory:

* Using 4 KB pages requires about **262,144 pages**.
* Using 2 MB hugepages requires only **512 pages**.

This greatly reduces the size of the page tables and the amount of work the CPU performs when translating
virtual addresses to physical addresses.

### Benefits

Hugepages can improve performance by:

* Reducing **Translation Lookaside Buffer (TLB)** misses.
* Decreasing page table memory usage.
* Lowering CPU overhead for memory-intensive workloads.
* Improving performance for applications with very large memory footprints.

They're especially useful for:

* Databases (PostgreSQL, Oracle, MySQL)
* Virtual machines (KVM/QEMU)
* High-performance computing (HPC)
* Large in-memory caches
* Some machine learning workloads

### Types of hugepages in Linux

Linux supports two main mechanisms.

#### 1. Transparent Huge Pages (THP)

* Managed automatically by the kernel.
* Applications don't need to be modified.
* The kernel tries to combine adjacent 4 KB pages into 2 MB pages.
* Can fall back to normal pages if necessary.

Pros:

* Easy to use
* No manual configuration

Cons:

* May introduce latency when pages are collapsed or split.
* Some database vendors recommend disabling it.

#### 2. Explicit (Static) HugeTLB Pages

These are reserved in advance.

Example:

```bash
echo 1024 > /proc/sys/vm/nr_hugepages
```

This reserves 1024 hugepages.

Applications explicitly request them using APIs such as:

* `mmap()` with `MAP_HUGETLB`
* Shared memory backed by hugetlbfs

Pros:

* Guaranteed availability
* Predictable performance

Cons:

* Memory is reserved even if unused.
* Requires administrator configuration.

### Example

Suppose a process uses 4 GB of RAM.

With 4 KB pages:

```
4 GB / 4 KB
= 1,048,576 pages
```

With 2 MB hugepages:

```
4 GB / 2 MB
= 2048 pages
```

That's over **500× fewer pages** to manage.

### Checking hugepage status

View reserved hugepages:

```bash
cat /proc/meminfo | grep Huge
```

Typical output:

```text
HugePages_Total:    512
HugePages_Free:     500
HugePages_Rsvd:      10
HugePages_Surp:       0
Hugepagesize:      2048 kB
```

Or:

```bash
grep Huge /proc/meminfo
```

### Transparent Huge Pages status

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
```

Example:

```text
[always] madvise never
```

The option in brackets is currently active.

### Trade-offs

Advantages:

* Faster address translation
* Lower TLB miss rate
* Smaller page tables
* Better performance for large memory workloads

Disadvantages:

* Higher internal fragmentation (unused space within a large page)
* Reserving explicit hugepages reduces memory available for other uses
* Transparent Huge Pages can occasionally cause latency spikes due to page compaction or splitting

### Summary

| Feature            | Standard Pages               | Hugepages                                |
| ------------------ | ---------------------------- | ---------------------------------------- |
| Typical size       | 4 KB                         | 2 MB or 1 GB                             |
| TLB entries needed | Many                         | Much fewer                               |
| Page table size    | Large                        | Smaller                                  |
| Performance        | General purpose              | Better for large memory workloads        |
| Memory efficiency  | Better for small allocations | Can waste memory due to larger page size |

In short, hugepages are an optimization that trades some memory flexibility for lower CPU overhead and
better performance when working with large contiguous memory regions.


---

## Example use-case: Virtual Machines:

For VM's the  amount of hugepage memory you reserve must be **at least as large as the memory that the
QEMU VM will back with hugepages**.

For example, suppose you launch a VM with:

```bash
qemu-system-x86_64 -m 8G ...
```

If you want the entire 8 GB of guest RAM to use hugepages, then you need to reserve at least **8 GB** worth
of hugepages.

Assuming 2 MB hugepages:

```text
8 GB / 2 MB = 4096 hugepages
```

So you would configure:

```bash
echo 4096 > /proc/sys/vm/nr_hugepages
```

### What if you reserve more?

Suppose you reserve 16 GB worth of hugepages but your VM only uses 8 GB.

* VM uses: **8 GB**
* Reserved: **16 GB**
* Unused: **8 GB**

The extra 8 GB simply remains reserved for hugepages and cannot be used for normal memory allocations until
those hugepages are released. It doesn't make the VM faster.

### What if you reserve less?

Suppose:

* VM memory = **8 GB**
* Hugepages reserved = **6 GB**

Then:

* If the VM is configured to require explicit hugepages (using `memory-backend-file`, `hugetlbfs`, or
  `-mem-prealloc` with hugepages), **QEMU will usually fail to start** because it cannot allocate all the
  requested hugepage-backed memory.
* If you're using **Transparent Huge Pages (THP)** instead, the kernel may use hugepages where possible and
  fall back to normal 4 KB pages for the rest.

### Rule of thumb

| Hugepages reserved  | Result                                    |
| ------------------- | ----------------------------------------- |
| Less than VM memory | VM may fail to start (explicit hugepages) |
| Equal to VM memory  | Ideal                                     |
| More than VM memory | Works, but wastes reserved RAM            |

So, for explicit hugepages, the recommended practice is to reserve **approximately the same amount of
hugepage memory as the total guest memory** (or slightly more if you plan to start multiple VMs or want some
headroom). Reserving significantly more is generally unnecessary unless you know you'll need it later.

### Example NVIDIA DGX: Virtual Machines

In this case we have NVIDIA DGX with 
* **Host RAM:** 128 GB
* **VM1 RAM:** 2 GB
* **VM2 RAM:** 2 GB
* **Total guest RAM:** **4 GB**

The fact that the host has **128 GB** is **not** what determines the hugepage setting. What matters is **how
much guest memory you want to back with hugepages**.

### If using 2 MB hugepages (the common case)

Total hugepage-backed memory needed:

```text
2 GB + 2 GB = 4 GB
```

Number of hugepages:

```text
4 GB / 2 MB = 2048 hugepages
```

So you would configure:

```bash
echo 2048 > /proc/sys/vm/nr_hugepages
```

You can verify:

```bash
grep Huge /proc/meminfo
```

You should see something like:

```text
HugePages_Total: 2048
Hugepagesize:    2048 kB
```

---

### Memory layout

Your 128 GB host would roughly look like this:

```text
128 GB Host RAM
+-----------------------------------------------------------+
|                                                           |
| 4 GB reserved as hugepages                               |
|  - VM1: 2 GB                                              |
|  - VM2: 2 GB                                              |
|                                                           |
| Remaining ~124 GB available to Linux                      |
+-----------------------------------------------------------+
```

Only **4 GB** is reserved for hugepages; the remaining memory is still available for the host OS and other
applications.

---

### Should you reserve more?

You could reserve 6 GB or 8 GB if you expect to:

* start additional VMs later,
* increase the VM memory size,
* or want spare hugepages available.

For example:

```bash
echo 4096 > /proc/sys/vm/nr_hugepages
```

reserves **8 GB** of hugepage memory. This works, but **4 GB of it would sit unused** until another VM or
application allocates it.

---

### Best practice

For a DGX with **128 GB RAM** running only **two 2 GB VMs**, reserve **4 GB** of hugepages (2048 × 2 MB
pages). This is sufficient and avoids unnecessarily taking RAM away from the host.

Note: 
One additional consideration on NVIDIA DGX systems is that the host often needs substantial RAM for
GPU drivers, CUDA applications, containers, and data loading. Unless you have a specific reason to reserve
extra hugepages, it's generally better to keep the reservation close to your actual VM requirements so the
remaining memory stays available for those workloads.
