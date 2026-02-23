# DPDK an d XDP:

> **Standard DPDK and XDP do not run on the same interface at the same time.**
> But they are not conceptually incompatible — they just operate in different models.

---

## Where XDP Runs

XDP runs:

* Inside the **Linux kernel**
* In the NIC driver's RX path
* Before `sk_buff` allocation
* As part of the normal `net_device` model

It requires:

* A kernel driver (e.g. `igc`, `e1000e`, `r8169`, `mlx5`)
* The interface to be managed by Linux

---

## Where DPDK Runs

DPDK:

* Bypasses the Linux networking stack
* Uses user-space drivers
* Uses polling (PMD – Poll Mode Drivers)
* Binds NIC to `vfio-pci` or `uio`
* Removes the NIC from the kernel

So when DPDK owns the NIC:

* The kernel driver is detached
* No `net_device`
* No *XDP*
* No *TC*
* No `netfilter`
* No `iptables`

The NIC is now fully controlled from user space.

---

## So Can XDP Work With DPDK?

### Standard DPDK Mode (NIC bound to vfio/uio)

No.

Because:

* XDP requires a kernel driver
* DPDK removes the kernel driver

So they cannot attach to the same interface simultaneously.

---

## But There Are Interesting Edge Cases

### 1. AF_XDP (This Is Important)

There is a hybrid approach:

**AF_XDP sockets**

This allows:

* XDP program in kernel
* Zero-copy packet delivery
* User space processing
* High performance
* No full driver bypass

AF_XDP is essentially:

* Kernel XDP filtering
* User-space packet handling
* Similar performance goals as DPDK
* But still integrated with kernel

This is often considered the “modern alternative” to DPDK for many use cases.

---

### 2. DPDK With Kernel Driver (Not Poll Mode)

DPDK can run in a special mode using:

* Kernel drivers
* `mlx5` PMD with kernel assistance

But this is more advanced and hardware-specific.

- Conceptual Difference

| Feature                 | XDP                 | DPDK |
| ----------------------- | ------------------- | ---- |
| Runs in kernel          | Yes                 | No   |
| Uses polling            | No (interrupt/NAPI) | Yes  |
| Uses batch processing   | Limited             | Yes  |
| Requires kernel driver  | Yes                 | No   |
| Can coexist on same NIC | No (normally)       | No   |

---


You should pick one model:

### Model A: XDP / AF_XDP

* Kernel-integrated
* Clean architecture
* Modern Linux networking
* Easier academic explanation

### Model B: DPDK

* Full user-space networking
* Poll-mode drivers
* More complex
* Different design philosophy

Trying to combine them on the same interface usually defeats the purpose.

---

## Important Insight

People often compare:

* **XDP vs DPDK**
* Not “XDP + DPDK”

They solve similar performance problems but using different architectures:

* XDP = kernel fast path
* DPDK = user-space bypass path

---

## One More Subtle Point

DPDK batches packets heavily.

XDP:

* Processes packet-by-packet
* But runs before skbuff
* Can still hit millions of packets per second

On 1G / 2.5G:

* XDP is more than sufficient
* DPDK is often overkill

---

#  Final Answer

> So XDP will also not work with DPDK?

Correct — not in the normal DPDK poll-mode setup where the NIC is detached from the kernel.

But:

* You can use AF_XDP for high-performance user-space processing
* Or choose pure DPDK
* Or choose pure XDP

Just not both controlling the same NIC at the same time.

---
