# cache and non cache memory in V4l2 m2m driver:


V4L2 M2M (Memory-to-Memory) driver for a hardware codec that handles decoding and encoding, a proper 
management of *cacheable vs. non-cacheable memory* is *crucial* to ensuring correct and efficient operation. 
This is especially true when dealing with DMA (Direct Memory Access), which is how most hardware codecs 
interact with memory.

Here’s how cache and non-cache memory operations play into the development:

---

## 🔧 The Role of Cache vs. Non-Cache Memory

### 1. *DMA Coherency and Cache Maintenance*

Hardware codecs typically access memory via DMA. If the CPU caches the same memory region that the hardware 
accesses via DMA, the data may become *incoherent*. This means:

* The CPU sees *stale* data because the HW wrote to memory directly (but CPU reads from cache).
* The HW reads *stale* data because the CPU modified the buffer, but hasn't flushed the cache to RAM.

To avoid this:

* You *must maintain cache coherency* by either:

  * Using *non-cacheable memory* (i.e., memory not cached by CPU),
  * Or performing **explicit cache operations** (flush/invalidate) before/after DMA access.

---

## Key Concepts:

### a. *Non-Cacheable Memory*

* Used for buffers that hardware will write to or read from.
* Avoids cache coherency issues because there's no cache to go stale.
* Typically allocated using `dma_alloc_coherent()`.

*Pros:*

* No need for manual cache flush/invalidate.
* Safe for DMA.

*Cons:*

* Slower CPU access compared to cached memory.

---

### b. *Cacheable Memory with Manual Cache Management*

* Offers better CPU performance.
* But requires **explicit cache maintenance** using functions like:

  * `dma_sync_single_for_device()`
  * `dma_sync_single_for_cpu()`

*Usage pattern* (example for decoder input buffer):

* CPU writes compressed data to buffer.
* Call `dma_sync_single_for_device()` before giving it to the codec.
* HW processes the buffer.
* Call `dma_sync_single_for_cpu()` after codec finishes if CPU will read the output.

---

## Where It Matters in V4L2 M2M Codec Drivers

### 1. *Input Buffers (Decoder/Encoder)*

* These are typically **written by the CPU** (user space) and **read by the HW**.
* You need to **flush caches** before DMA read or use non-cacheable mappings.

### 2. *Output Buffers (Decoded Frames / Encoded Streams)*

* These are **written by the HW** and **read by the CPU**.
* You need to **invalidate cache** after DMA write or use non-cacheable mappings.

---

## 🛠️ In the Driver Code

You often use:

```c
vb2_dma_contig_plane_dma_addr(vb, plane)
```

to get DMA address, and

```c
dma_sync_single_for_device(dev, dma_addr, size, direction)
dma_sync_single_for_cpu(dev, dma_addr, size, direction)
```

to maintain cache coherency.

Or:

* Use `VB2_MEMORY_DMABUF` or `VB2_MEMORY_MMAP` with `dma_buf` export/import logic that properly handles 
  cache maintenance.

---

##  Best Practices

* Use `dma_alloc_coherent()` for HW-only buffers.
* Use `dma_map_*()` and sync functions for buffers shared between CPU and HW.
* Use `VB2_DMABUF` when sharing buffers across devices (e.g., zero-copy pipelines).
* Align buffer sizes to cacheline/page boundaries to avoid partial cacheline issues.

---

##  Summary

| Memory Type       | Use Case                | Pros                | Cons                  |
| ----------------- | ----------------------- | ------------------- | --------------------- |
| Non-cacheable     | HW-only or DMA-buffers  | No coherency issues | Slower CPU access     |
| Cacheable         | CPU-accessed buffers    | Faster for CPU      | Needs sync operations |
| Mixed (with sync) | Shared CPU<->HW buffers | Best performance    | Complex management    |

---

If you're seeing data corruption, tearing, or artifacts, it's likely due to cache incoherency. Let me know if you want an example of how to integrate these cache ops into a V4L2 driver or manage DMABUFs safely.
