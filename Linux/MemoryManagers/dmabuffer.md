# DMA Buffer sharing:

## Sharing buffer between devices:

- CPUs may not have gotten hugely faster in recent years, but they have gained in other ways ; a typicl SoC
  device now has many number of peripherals which would qualify as reasonably powerful CPU's in their own
  right. 

- More powerful devices with direct access to memory bus can take on more demanding tasks. 
  Ex: Image frame captured from a camera device can often be passed directly to the graphics processor for
  display without all of the user-space processing that was once necessary.

- Increasingly the CPUs job looks like that of a shop foreman whose main concern is keeping all of the other
  processors busy.
  The foreman's job will be easier if various devices under its control can communicate with each other.

- The buffer sharing patch : https://lwn.net/Articles/455098/
```
    Buffer sharing proof-of-concept: (Aug 15, 2011 by corbet)

From:	 	Marek Szyprowski <m.szyprowski-AT-samsung.com>
To:	 	linaro-mm-sig-AT-lists.linaro.org, linux-media-AT-vger.kernel.org
Subject:	 	Buffer sharing proof-of-concept
Date:	 	Tue, 02 Aug 2011 11:48:07 +0200
Message-ID:	 	<4E37C7D7.40301@samsung.com>
Cc:	 	Tomasz Stanislawski <t.stanislaws-AT-samsung.com>, Kyungmin Park <kyungmin.park-AT-samsung.com>, Marek Szyprowski <m.szyprowski-AT-samsung.com>
Archive‑link:	 	Article
Hello Everyone,

This patchset introduces the proof-of-concept infrastructure for buffer 
sharing between multiple devices using file descriptors. The 
infrastructure has been integrated with V4L2 framework, more 
specifically videobuf2 and two S5P drivers FIMC (capture interface) and 
TV drivers, but it can be easily used by other kernel subsystems, like DRI.

In this patch the buffer object has been simplified to absolute minimum 
- it contains only the buffer physical address (only physically 
contiguous buffers are supported), but this can be easily extended to 
complete scatter list in the future.

Best regards
-- 
Marek Szyprowski
Samsung Poland R&D Center
```

- The idea of this is to make it possible for multiple kernel subsystems to share buffers under the control
  of user-space.
- With the above type of feature, applications could wire kernel subsystems together in problem-specific
  ways then get out of the way, letting the devices involved process the data as it passes through.

- There are some challenges which must be dealt with to make this functionality safe to export to
  applications:
  - The applications should not be able to "create" buffers at arbitrary kernel addresses. 
    Kernel space address should not be visible to user-space at all, so the kernel should provide other way
    for the application to refer to a specific buffer.
  - Shared buffers should not go away until all users have let go of it. 
    A buffer may be created by a specific device driver, but it must persist, even if the device is closed,
    until nobody else expects it to be there.

- The Initial mechanism added in the first patch set ( Tomasz Stanislawski) is simple:

  Kernel code that is wanting to make a buffer available to other parts of the kernel via user-space starts
  by filling in one these structures:

  struct shrbuf {
    void (*get) (struct shrbuf *);
    void (*put) (struct shrbuf *);
    unsigned long dma_addr;
    unsigned long size;
  }

  `shrbuf` (shared buffer) structure members:
  1. `void (*get)(struct shrbuf *);`: 
        * function pointer that points to a function that takes a `struct shrbuf *` as an argument and
          returns `void`.
        * The `get` function is likely used to retrieve or acquire the shared buffer.
  2. `void (*put)(struct shrbuf *);`:
        * function pointer that points to a function that takes a `struct shrbuf *` as an argument and
          returns `void`.
        * The `put` function is likely used to release or put back the shared buffer.
  3. `unsigned long dma_addr;`:
        * unsigned long integer that stores the DMA (Direct Memory Access) address of the shared buffer.
        * The DMA address is a physical address that can be used by hardware devices to access the buffer.
  4. `unsigned long size;`:
        * unsigned long integer that stores the size of the shared buffer.

-  The `shrbuf` struct is designed to manage a shared buffer that can be accessed by multiple entities,
   possibly including hardware devices. 
- The `get` and `put` function pointers provide a way to control access to the buffer, while the 
  `dma_addr` and `size` members provide information about the buffer's location and size.

- example of how this struct might be used:
```c
struct shrbuf my_buf = {
    .get = my_get_func,
    .put = my_put_func,
    .dma_addr = 0x10000000,
    .size = 1024,
};

// Later, to acquire the buffer:
my_buf.get(&my_buf);

// Use the buffer...

// When done, release the buffer:
my_buf.put(&my_buf);
```
In this example, `my_get_func` and `my_put_func` are functions that implement the logic for acquiring and 
releasing the shared buffer, respectively. 
The `dma_addr` and `size` members are initialized with the physical address and size of the buffer.

- NOTE: The above shrbuf structure is a simplified one for only as a proof of concept and ignores things like:
    - the address should be "dma_addr_t" 
    - there is no reason to put the kernel virtual address there, only physically-contiguous buffers are
      allowed...

- the get() and put() : manage reference counters to the buffer, which must continue to exist until that
  count goes to zero.
- Any subsystem depending on a buffer's continued existence should hold a reference to that buffer. 
- the put() function should release the buffer when the last reference is dropped.

- Once this structure exists, it can be passed to:

    `int shrbuf_export(struct shrbuf *sb);`

  The return value (if all goes well) will be an integer file descriptor which can be handed to user space.
  This file descriptor embodies a reference to the buffer, which now will not be released before the file
  descriptor is closed.

- Other than closing it, there is very little that the application can do with the descriptor other than 
  give it to another kernel subsystem; attempts to read from or write to it will fail, for example.

- If a kernel subsystem receives a file descriptor which is purported to represent a kernel buffer, it can
  pass that descriptor to:

     `struct shrbuf *shrbuf_import(int fd);`

  The return value will be the same shrbuf structure (or an ERR_PTR() error value for a file descriptor of 
  the wrong type). 
  A reference is taken on the structure before returning it, so the recipient should call put() at some 
  future time to release it.

- The patch set includes a new Video4Linux2 ioctl() command (VIDIOC_EXPBUF) enabling the exporting of
  buffers as file descriptors; a couple of capture drivers have been augmented to support this
  functionality. No examples of the other side (importing a buffer) have been posted yet.

- This patch has been picked up by Sumit Semwal, who modified it considerably in response to comments from a
  number of developers. And this modified version patch was merged for 3.3  which differs enough from its 
  predecessors that it merits another look here. ( core idea still remains the same ).

- The mechanism allows DMA buffers to be shared between devices that might otherwise be unaware of each
  other.

Recap:
--- 
- DMA Buffers:  (Direct Memory Access) buffers are regions of memory that are used to transfer data between
  devices, such as peripherals, and the system memory.
  These buffers are typically used in conjunction with DMA controllers, which are responsible for managing 
  the transfer of data between devices and the system memory.

- DMA buffers are designed to be shared between multiple devices and drivers, allowing them to access and
  transfer data without the need for explicit copying or intervention by the CPU. 
  This sharing of buffers is key to enabling efficient and high-performance data transfer between devices.

- Characteristics of DMA Buffers: DMA buffers have several characteristics that make them suitable for
  sharing between devices and drivers:
  1. Contiguous memory allocation: DMA buffers are typically allocated as contiguous blocks of memory, which
     allows for efficient transfer of data between devices.

  2. Physical memory address: DMA buffers are allocated in physical memory, which allows devices to access
     them directly using their physical memory address.
  
  3. Device-independent: DMA buffers are not specific to any particular device or driver, allowing them to
     be shared between multiple devices and drivers.

  4. Kernel-managed: DMA buffers are managed by the kernel, which provides a layer of abstraction and
     ensures that the buffers are properly allocated, deallocated, and protected.

- Kernel Address Space vs. Device-Specific:
  DMA buffers are part of the kernel address space, but they are also accessible by devices using their 
  physical memory address. 
  This allows devices to transfer data to and from the buffers without the need for explicit copying or 
  intervention by the CPU.

- In terms of memory allocation, DMA buffers are typically allocated in the kernel's physical memory pool,
  which is a region of memory that is reserved for kernel use. 
  However, the buffers themselves are not necessarily part of the kernel's virtual address space, as they 
  are intended to be accessed by devices using their physical memory address.

- To access a DMA buffer, a device typically uses its physical memory address, which is mapped to the
  buffer's location in physical memory. 
  The kernel provides a mechanism for devices to map their physical memory address to the buffer's location 
  in physical memory, allowing them to access the buffer directly.

- dma-buf Framework:
  The `dma-buf` framework is a kernel framework that provides a way to manage and share DMA buffers between 
  devices and drivers. 
  The framework provides a set of APIs and data structures that allow devices and drivers to allocate, 
  deallocate, and access DMA buffers in a safe and efficient manner.

- The `dma-buf` framework is designed to provide a layer of abstraction between devices and drivers,
  allowing them to share DMA buffers without the need for explicit knowledge of each other's implementation 
  details. 
- The framework also provides a mechanism for devices and drivers to synchronize access to DMA buffers,
  ensuring that data is transferred correctly and efficiently.

- => DMA buffers are regions of memory that are used to transfer data between devices and the system memory. 
- => They are part of the kernel address space, but are also accessible by devices using their physical
  memeory address.
- => The `dma-buf` framework provides a way to manage and share DMA buffers between devices and drivers,
  allowing for efficient and high-performance data transfer.
 
 ---

- Buffer sharing: The initial target use of sharing buffer between producers adn consumers of video stream:
  a camera device, for ex: can acquire a stream of frames into a series of buffers that are shared with the
  graphics adapter, enabling the capture and display of the data with no copying in the kernel.

- In the 3.3 sharing scheme, one driver will set itself up as an exporter of sharable buffers. 
  That requires providing a set of callbacks to the buffer sharing code:

    struct dma_buf_ops {
	int (*attach)(struct dma_buf *buf, struct device *dev,
		      struct dma_buf_attachment *dma_attach);
	void (*detach)(struct dma_buf *buf, struct dma_buf_attachment *dma_attach);
	struct sg_table *(*map_dma_buf)(struct dma_buf_attachment *dma_attach,
					enum dma_data_direction dir);
	void (*unmap_dma_buf)(struct dma_buf_attachment *dma_attach, struct sg_table *sg);
	void (*release)(struct dma_buf *);
    };

- Briefly, attach() and detach() inform the exporting driver when others take or release references to the 
  buffer. 
- The map_dma_buf() and unmap_dma_buf() callbacks, instead, cause the buffer to be prepared (or unprepared)
  for DMA and pass ownership between drivers.
- A call to release() will be made when the last reference to the buffer is released.

- The exporting driver makes the buffer available with a call to:

   `struct dma_buf *dma_buf_export(void *priv, struct dma_buf_ops *ops,size_t size, int flags);`

- NOTE: the size of the buffer is specified in the above export call, but the call has no pointer to the
  buffer itself. In fact, the current version of the interface never passes around CPU-accessible buffer
  pointers at all. 
- One of the actions performed by dma_buf_export() is the creation of an anonymous file to represent the
  buffer; flags is used to set the mode bits on that file.

- Since the file is anonymous, it is not visible to the rest of the kernel (or user space) in any useful
  way. Truly exporting the buffer, instead, requires obtaining a file descriptor for it and making that 
  descriptor available to user space. The descriptor can be had with:

    int dma_buf_fd(struct dma_buf *dmabuf);

- There is no standardized mechanism for passing that file descriptor to user space, so it seems likely that
  any subsystem implementing this functionality will add its own special ioctl() operation to get a buffer's
  file descriptor. 
  The same is true for the act of passing a file descriptor to drivers that will share this buffer; it is 
  something that will happen outside of the buffer-sharing API. 

- A driver wishing to share a DMA buffer has to go through a series of calls after obtaining the
  corresponding file descriptor, the first of which is:

    `struct dma_buf *dma_buf_get(int fd);`

  This function obtains a reference to the buffer and returns a dma_buf structure pointer that can be used 
  with the other API calls to refer to the buffer. 
  When the driver is finished with the buffer, it should be returned with a call to dma_buf_put().

- The next step is to "attach" to the buffer with:

    struct dma_buf_attachment *dma_buf_attach(struct dma_buf *dmabuf,
					      struct device *dev);
  This function will allocate and fill in yet another structure:

    struct dma_buf_attachment {
    	struct dma_buf *dmabuf;
	    struct device *dev;
	    struct list_head node;
	    void *priv;
    };

- That structure will then be passed to the exporting driver's attach() callback. 
- There seems to be a couple of reasons for the existence of this step, the first of which is simply to let
  the exporting driver know about the consumers of the buffer. Beyond that, the device structure passed by 
  the calling driver can contain a pointer (in its dma_params field) to one of these structures:

    struct device_dma_parameters {
	    unsigned int max_segment_size;
	    unsigned long segment_boundary_mask;
    };

  The exporting driver should look at these constraints and ensure that the buffer it is exporting can 
  satisfy them; if not, the attach() call should fail. 
  If multiple drivers attach to the buffer, the exporting driver will need to allocate the buffer in a way 
  that satisfies all of their constraints.

- The final step is to map the buffer for DMA:

    struct sg_table *dma_buf_map_attachment(struct dma_buf_attachment *attach,
					    enum dma_data_direction direction);

  This call turns into a call to the exporting driver's map_dma_buf() callback. 
  If this call succeeds, the return value will be a "scatterlist" that can be used to program the DMA 
  operation into the device. 
  A successful return also means that the calling driver's device owns the buffer; it should not be touched 
  by the CPU during this time.

- Note that mapping a buffer is an operation that can block for a number of reasons; 
  if the buffer is busy elsewhere, for example. 
  Also worth noting is that, until this call is made, the buffer need not necessarily be allocated anywhere.
  The exporting driver can wait until others have attached to the buffer so that it can see their 
  DMA constraints and allocate the buffer accordingly. 
  Of course, if the buffer lives in device memory or is otherwise constrained on the exporting side, it can 
  be allocated sooner.
  
- After the DMA operation is completed, the sharing driver should unmap the buffer with:

    void dma_buf_unmap_attachment(struct dma_buf_attachment *attach,
				  struct sg_table *sg_table);

  That will, in turn, generate a call to the exporting driver's unmap_dma_buf() function. 

- Detaching from the buffer (when it is no longer needed) can be done with:

    void dma_buf_detach(struct dma_buf *dmabuf, struct dma_buf_attachment *attach);
  
  As might be expected, this function will call the exporting driver's detach() callback.

- As of 3.3, there are no users for this interface in the mainline kernel. 
  There seems to be a fair amount of interest in using it, though, so Dave Airlie pushed it into the 
  mainline with the idea that it would make the development of users easier. 
  Some of those users can be seen (in an early form) in Dave's drm-prime repository and Rob Clark's 
  OMAP4 tree.


NOTE: 
    - attach()/detach() are not really for reference counting, that is handled with 
      dma_buf_get()/dma_buf_put() (under the hood it is using 'struct file *' refcnting). 

    - Driver writers adding support for dmabuf should be sure to do a dma_buf_get() in their ioctl for 
    importing the dmabuf, and keep the 'struct dma_buf *' ptr, rather than holding on to the file 
    descriptor (int).

    - The attach()/detach() is really just advisory to the exporting driver to help it know the constraints
    of potentially multiple different devices that would be sharing the buffer. 
    For example, a camera and encoder might share a single buffer w/ display/gpu.
 
 ---
User-space Perspective of DMA-Buffers:

Basics:

How to **use DMA-buffers** from user space?

- it's important to understand **what DMA-buffers are** and **how they fit into the overall system**,
  especially in the context of **user-space** applications. Breakdown of the essential things to know about
  **DMA-buffers** before you can start using them effectively.

### 1. **What is DMA (Direct Memory Access)?**
DMA allows peripherals (like a GPU, camera, network interface card, etc.) to **access main memory** 
directly, without needing the CPU to be involved in every data transfer. 
This improves efficiency by offloading repetitive data movement tasks to the hardware.

- **DMA Buffers** are a special type of memory buffer designed to work efficiently with DMA engines.
  These buffers are often used when devices need to access memory directly, such as when transferring data 
  between a device (e.g., GPU or network card) and the system memory.

NOTE: [

1. 
- A **DMA engine** is a HW component/controller that facilitates the transfer of data directly between 
  **memory** and **peripheral devices** (such as **GPUs**, **network cards**, **storage devices**, etc.) 
  without involving the **CPU**. This allows for **faster** and **more efficient data transfers**, 
  offloading the work from the CPU and enabling it to perform other tasks while data is being moved in the 
  background.
- The DMA engine allows peripherals to access system memory (RAM) directly.( CPU offloading )
- **Autonomous Operation**: Once the DMA engine is programmed, it can perform the data transfer
  independently of the CPU.
- **Efficient Data Transfer**: engines are commonly used in high-speed data transfer where the CPU would
  otherwise become a bottleneck.
- **Peripheral and Memory Communication**: DMA engines are typically used for communication between 
  **I/O devices (peripherals)** and **system memory** (RAM), but can also be used for communication between 
  different memory areas (e.g., memory-to-memory).
- **Types of DMA Engines:**
    - **Memory-to-Device**: Data is transferred from system memory to a device 
    (e.g., CPU writes data to a network interface card or a GPU).
    - **Device-to-Memory**: Data is transferred from a device into system memory 
    (e.g., when receiving network data from a network card or reading from a disk).
    - **Memory-to-Memory**: Data is moved between two memory regions 
    (e.g., memory copies initiated by the DMA engine).

2. **How Are DMA Buffers Allocated and Accessed in Linux (Embedded and Non-Embedded)?**
- In Linux (both embedded and non-embedded systems), DMA buffers are allocated through the kernel's 
  **DMA API** to allow peripherals to access memory directly. 
  These buffers are typically allocated in a way that makes them suitable for DMA operations, meaning they 
  need to be **physically contiguous** and **aligned** in memory, and **cache-coherent** to avoid 
  synchronization issues.
-  A. **Buffer Allocation for DMA in Linux**
    **`dma_alloc_coherent()`**
   - **Used for**: Allocating physically contiguous mem that can be directly accessed by DMA engines.
   - **Behavior**: Allocates memory that is **cache-coherent**, meaning the CPU and DMA engine can safely 
     access it without cache-related issues.
   - **Use cases**: most commonly used for buffers that will be used for high-speed, CPU-independent 
     transfers like video streaming, networking, or any I/O operation that involves peripherals and needs 
     zero-copy access.
    ```
    void *cpu_addr;
    dma_addr_t dma_handle;
    size_t size = 4096;
    struct device *dev = ...;  // Pointer to the device object
    // Allocate memory for DMA buffer
    cpu_addr = dma_alloc_coherent(dev, size, &dma_handle, GFP_KERNEL);
    if (!cpu_addr) {
        pr_err("DMA buffer allocation failed\n");
        return NULL;
    } 
    // cpu_addr is the virtual address for CPU access
    // dma_handle is the physical address for the DMA engine
   ```
   - **`dma_alloc_coherent()`** allocates both the virtual address (`cpu_addr`) and the physical address 
   (`dma_handle`) of the buffer. The **virtual address** is used by the CPU, and the **physical address** 
   is used by the DMA engine to directly access the buffer.

   B. **`dma_alloc_attrs()`**
   - **Used for**: Allocating DMA memory with additional attributes, which can be used for fine-grained 
     control over the allocation (e.g., setting caching behavior).
   - **Behavior**: Similar to `dma_alloc_coherent()`, but more flexible in terms of setting attributes that
     might control cacheability, alignment, or memory type (normal, uncached, etc.).
   - **Use cases**: When you need specific control over memory access characteristics or alignment.

   **Example:**
   ```c
   void *cpu_addr;
   dma_addr_t dma_handle;
   size_t size = 4096;
   struct device *dev = ...;
   
   // Allocate memory with specific attributes
   cpu_addr = dma_alloc_attrs(dev, size, &dma_handle, GFP_KERNEL, DMA_ATTR_NO_WARN);
   if (!cpu_addr) {
       pr_err("DMA buffer allocation failed\n");
       return NULL;
   }
   ```

   C. **`dma_alloc_noncoherent()`**
   - **Used for**: Allocating memory that does not need to be cache-coherent. 
   This type of allocation may be useful when the buffer will only be accessed by the device and not the 
   CPU or when cache management is handled manually.
   - **Use cases**: Typically used for non-coherent devices like some network cards, where you manage cache 
   coherency yourself.

   D. **`dma_buf` for Shared Buffers (e.g., for GPUs or Video Processing)**:
   - **`dma-buf`** is a special Linux framework used for **sharing memory buffers** between different 
   devices or subsystems (e.g., CPU, GPU, VPU, camera, etc.) without needing to copy data. 
   These buffers are often allocated in kernel space but are shared with user space via file descriptors.
   - The kernel uses the **`dma-buf` framework** to export a buffer to another device or subsystem that can 
   directly access the buffer.

   The framework allows one device or driver to **export** the buffer and another to **import** it, 
   facilitating **zero-copy** memory sharing between subsystems.

- **Embedded Linux Systems**
   - DMA buffers need to be **contiguous** and located in a specific **physical address space** to meet HW
     requirements. This is important for devices like **video decoders**, **network interfaces**, or 
     **display buffers**, which need to operate with very specific memory layouts.

   - Memory is often **more constrained** in embedded systems, so DMA buffers are typically allocated with 
   careful consideration to size, alignment, and location in memory.

   - Additionally, embedded systems often have specialized **I/O peripherals** 
   (e.g., **camera modules**, **display controllers**, **video processing units**) that require 
   **direct memory access** to buffers.

- In both embedded and non-embedded systems, the same **DMA API** 
(`dma_alloc_coherent()`, `dma_alloc_attrs()`, etc.) is used to allocate buffers that can be directly 
accessed by the DMA engine, but embedded systems often deal with stricter memory constraints and may have 
custom memory regions optimized for DMA.
]


### 2. **What is a DMA Buffer (`dma-buf`)?**
A **DMA buffer** is a shared memory region that can be used across different **drivers and subsystems** 
in the Linux kernel. The key features are:

- **Zero-copy** mechanism: buffers can be passed between subsystems (e.g., CPU, GPU, camera, etc.) without 
needing to copy data, which improves performance.
- **Sharing memory across drivers**: The `dma-buf` framework allows one component (e.g., a GPU) to 
**export** a memory buffer to another (e.g., a video decoder) so that both can access it directly.

- **User space access**: Through specific interfaces (e.g., file descriptors), DMA-buffers can be accessed 
in user space.

### 3. **Why Use DMA Buffers in User Space?**
DMA buffers are particularly useful when you need to share large amounts of data between different 
subsystems or components, such as when working with graphics, multimedia, or other I/O-heavy operations. 
In these scenarios, **zero-copy access** and **low-latency data transfers** are critical for performance.

For example:
- **GPU rendering** to a display buffer (e.g., rendering a video frame in memory shared with a display driver).

- **Multimedia pipelines** where a camera (or encoder) shares a buffer with a GPU or a video processing unit 
(VPU) without copying data.

- **Networking and I/O** scenarios where large amounts of data need to be transferred between devices.

---

### 4. **User-Space Requirements for DMA Buffers**
Before you can use `dma-buf` in user space, there are several key concepts and tools you need to understand.
These are summarized below:

#### A. **File Descriptors and `ioctl` Interfaces**
- **File Descriptors**: `dma-buf` is often accessed via **file descriptors** in user space, much like any 
other resource like files or devices. A file descriptor can be obtained through `open()` on special device 
nodes exposed by the kernel.

- **ioctl**: The `dma-buf` interface uses **ioctl** calls to perform various operations. 
These operations allow user space to manipulate or interact with the buffer (e.g., importing, exporting, 
synchronizing).
- For example, using `ioctl()` to import or export the DMA buffer via its file descriptor.

#### B. **Mapping the DMA Buffer to User Space**
DMA buffers are usually **memory-mapped** into user space using **`mmap()`**. 
This allows user space to interact with the buffer as if it were regular memory, without needing to copy the 
data. 
- **`mmap()`** is used to map the DMA buffer into a user-space memory region, where you can then read or 
write to it directly.
  
#### C. **Synchronization Mechanisms**
When using DMA buffers, you need to be aware of synchronization:
- **CPU-Hardware Synchronization**: When accessing the buffer from user space, especially when it’s shared 
with hardware (e.g., a GPU or VPU), synchronization is crucial. 

For example, the CPU might need to ensure that hardware writes are completed before accessing the 
buffer \(or vice versa).

- The kernel provides synchronization functions like 
`dma_buf_begin_cpu_access()` and `dma_buf_end_cpu_access()` 
to ensure proper synchronization between the CPU and the hardware when accessing the DMA buffer.
  
#### D. **Exporting and Importing DMA Buffers**
- **Exporting**: A driver or subsystem creates the DMA buffer and **exports** it, meaning it makes it 
available for other components to use. The export function typically provides a file descriptor or other 
handle that can be passed to user space.
  
- **Importing**: The user-space component (consumer) **imports** the DMA buffer by using the file descriptor 
provided by the producer. Once imported, the consumer can map the buffer into its mem space for direct access.

#### E. **Device Nodes**
- The kernel provides **device nodes** for managing DMA buffers. These nodes are typically found under 
  `/dev/` (e.g., `/dev/dma-buf` or other specialized paths).
- You interact with these device nodes in user space to create, import, and manage DMA buffers.

#### F. **Memory Allocation and Management**
- **Contiguous Memory**: Many DMA buffers require **contiguous memory** to ensure efficient transfers 
to/from hardware. This is because DMA engines often require physically contiguous memory regions to operate 
efficiently.

- In Linux, functions like `dma_alloc_coherent()` or `dma_alloc_attrs()` are used by kernel modules to 
  allocate such buffers.
- **Shared Memory**: The kernel may allocate a buffer using one of these memory allocation functions, 
  and then share it using the `dma-buf` framework.

---

### 5. **DMA-Buf Exporting and Importing Workflow in User Space**
Here’s a simplified workflow showing what’s required from user space when using a `dma-buf`:

1. **Buffer Creation (Kernel-side)**: 
   - A driver or subsystem allocates a DMA buffer and exports it via the `dma-buf` framework.
   - The kernel exposes the buffer to user space through a special file (e.g., `/dev/dma-buf`).

2. **Importing in User Space**:
   - User space **opens the device file** (e.g., `/dev/dma-buf`) and imports the buffer via a system call 
     like `ioctl()`.
   - This provides a **file descriptor** for the DMA buffer.

3. **Memory Mapping**:
   - Using the file descriptor, user space can **map the buffer** into its address space using `mmap()`.
   - The buffer is now accessible as regular memory in user space.

4. **Synchronization**:
   - If the buffer is shared between subsystems (e.g., CPU and GPU), synchronization is needed to ensure 
   that the correct subsystem accesses the buffer at the right time.
   - The kernel provides synchronization mechanisms via the `dma-buf` API, ensuring that one subsystem 
   doesn't overwrite data while another subsystem is reading or writing to it.

5. **Releasing the Buffer**:
   - When the buffer is no longer needed, the user space application calls `close()` on the file descriptor 
   and `munmap()` to unmap the memory region.
   - The kernel then frees the resources associated with the `dma-buf`.

---
### 6. **Key Concepts for User-Space Programming**
- **File Descriptors**: You will use file descriptors to open, read, and write DMA buffers in user space.
- **Memory Mapping**: Use `mmap()` to map the buffer into user space.
- **Synchronization**: Ensure proper synchronization when sharing the buffer between subsystems or hardware 
  and the CPU.
- **Zero-Copy**: Benefit from zero-copy memory sharing between subsystems, reducing data duplication and 
  improving performance.
- **Kernel APIs**: Be familiar with kernel APIs (`ioctl`, `mmap`, etc.) for interacting with DMA buffers.

---

### Summary
To work with **DMA-buffers** in user space, you need to:
1. Understand the **concept of DMA buffers** and their purpose (sharing memory between subsystems).
2. Use **file descriptors** to import the DMA buffer.
3. **Map** the buffer into your application’s address space via `mmap()`.
4. Manage **synchronization** between different subsystems that access the buffer.
5. **Release** the buffer properly when done.

User-space applications don't need to handle the lower-level memory management of DMA buffers directly 
(this is done by the kernel). 
Instead, you primarily interact with the buffer through **file descriptors**, and the kernel takes care of 
memory allocation, synchronization, and other management tasks.

By using the **`dma-buf` framework**, you can efficiently share memory between different hardware or 
software components without copying data, allowing for high-performance applications in areas like 
**graphics rendering**, **video processing**, or **networking**.

-------------------------
Explain how to use DMA buff from user space to pass a shared buffer memory from one stack to other.

In a SBC running linux, Create a user-space library that can access the dma buffers 


### 1. **What Are DMA Engines?**

A **DMA (Direct Memory Access) engine** is a hardware component or controller that facilitates the transfer 
of data directly between **memory** and **peripheral devices** (such as **GPUs**, **network cards**, 
**storage devices**, etc.) without involving the **CPU**. This allows for **faster** and **more efficient 
data transfers**, offloading the work from the CPU and enabling it to perform other tasks while data is 
being moved in the background.

#### Key Characteristics of DMA Engines:
- **Direct Memory Access**: The DMA engine allows peripherals to access system memory (RAM) directly, 
bypassing the CPU, which improves data transfer speeds and reduces CPU load.
  
- **Autonomous Operation**: Once the DMA engine is programmed, it can perform the data transfer 
independently of the CPU. The CPU typically only needs to configure the DMA engine and handle completion 
interrupts.

- **Efficient Data Transfer**: DMA engines are commonly used in high-speed data transfer scenarios where 
the CPU would otherwise become a bottleneck. For example, when a camera module needs to capture large 
frames of image data and send them to the memory, the DMA engine facilitates this transfer without 
CPU intervention.

- **Peripheral and Memory Communication**: DMA engines are typically used for communication between 
**I/O devices (peripherals)** and **system memory** (RAM), but can also be used for communication between 
different memory areas (e.g., memory-to-memory).

#### Types of DMA Engines:
- **Memory-to-Device**: 
Data is transferred from system memory to a device (e.g., CPU writes data to a network interface card or a GPU).
- **Device-to-Memory**: 
Data is transferred from a device into system memory (e.g., when receiving network data from a network 
card or reading from a disk).
- **Memory-to-Memory**: 
Data is moved between two memory regions (e.g., memory copies initiated by the DMA engine).

### 2. **How Are DMA Buffers Allocated and Accessed in Linux (Embedded and Non-Embedded)?**

In Linux (both embedded and non-embedded systems), DMA buffers are allocated through the kernel's 
**DMA API** to allow peripherals to access memory directly. 

These buffers are typically allocated in a way that makes them suitable for DMA operations, meaning they 
need to be **physically contiguous** and **aligned** in memory, and **cache-coherent** to avoid 
synchronization issues.

#### A. **Buffer Allocation for DMA in Linux**

##### 1. **`dma_alloc_coherent()`**
   - **Used for**: Allocating physically contiguous memory that can be directly accessed by DMA engines.
   - **Behavior**: Allocates memory that is **cache-coherent**, meaning the CPU and DMA engine can safely 
   access it without cache-related issues.
   - **Use cases**: This is most commonly used for buffers that will be used for high-speed, 
   CPU-independent transfers like video streaming, networking, or any I/O operation that involves 
   peripherals and needs zero-copy access.
   
   **Example:**
   ```c
   void *cpu_addr;
   dma_addr_t dma_handle;
   size_t size = 4096;
   struct device *dev = ...;  // Pointer to the device object
   
   // Allocate memory for DMA buffer
   cpu_addr = dma_alloc_coherent(dev, size, &dma_handle, GFP_KERNEL);
   if (!cpu_addr) {
       pr_err("DMA buffer allocation failed\n");
       return NULL;
   }
   
   // cpu_addr is the virtual address for CPU access
   // dma_handle is the physical address for the DMA engine
   ```

   - **`dma_alloc_coherent()`** allocates both the virtual address (`cpu_addr`) and the physical address 
   (`dma_handle`) of the buffer. The **virtual address** is used by the CPU, and the **physical address** 
   is used by the DMA engine to directly access the buffer.

##### 2. **`dma_alloc_attrs()`**
   - **Used for**: Allocating DMA memory with additional attributes, which can be used for fine-grained 
   control over the allocation (e.g., setting caching behavior).
   - **Behavior**: Similar to `dma_alloc_coherent()`, but more flexible in terms of setting attributes that 
   might control cacheability, alignment, or memory type (normal, uncached, etc.).
   - **Use cases**: When you need specific control over memory access characteristics or alignment.

   **Example:**
   ```c
   void *cpu_addr;
   dma_addr_t dma_handle;
   size_t size = 4096;
   struct device *dev = ...;
   
   // Allocate memory with specific attributes
   cpu_addr = dma_alloc_attrs(dev, size, &dma_handle, GFP_KERNEL, DMA_ATTR_NO_WARN);
   if (!cpu_addr) {
       pr_err("DMA buffer allocation failed\n");
       return NULL;
   }
   ```

##### 3. **`dma_alloc_noncoherent()`**
   - **Used for**: Allocating memory that does not need to be cache-coherent. This type of allocation may 
   be useful when the buffer will only be accessed by the device and not the CPU or when cache management 
   is handled manually.
   - **Use cases**: Typically used for non-coherent devices like some network cards, where you manage cache 
   coherency yourself.

##### 4. **`dma_buf` for Shared Buffers (e.g., for GPUs or Video Processing)**:
   - **`dma-buf`** is a special Linux framework used for **sharing memory buffers** between different 
   devices or subsystems (e.g., CPU, GPU, VPU, camera, etc.) without needing to copy data. 
   These buffers are often allocated in kernel space but are shared with user space via file descriptors.
   - The kernel uses the **`dma-buf` framework** to export a buffer to another device or subsystem that can
   directly access the buffer.

   The framework allows one device or driver to **export** the buffer and another to **import** it, 
   facilitating **zero-copy** memory sharing between subsystems.

---

#### B. **Allocating DMA Buffers in Non-Embedded vs Embedded Linux Systems**

The method of allocating and using DMA buffers is mostly **identical** between embedded and non-embedded 
systems from the perspective of the kernel, as they both utilize the same **DMA API**. However, there are 
some practical differences:

##### 1. **Non-Embedded Linux Systems (General-Purpose Systems)**
   - On **non-embedded systems** (e.g., desktops, laptops), the DMA engine typically works with higher-level
   components like **network adapters**, **storage devices**, and **GPUs**.
   - Here, DMA buffers might be used for activities like **disk I/O**, **network transfers**, and 
   **graphics rendering**. These systems often rely on more generic, flexible memory allocation methods.
   - In such systems, memory is generally less constrained, so large DMA buffers are often created from 
   system RAM.

##### 2. **Embedded Linux Systems**
   - In **embedded systems**, DMA buffers need to be **contiguous** and located in a specific 
   **physical address space** to meet hardware requirements. 
   This is especially important for devices like **video decoders**, **network interfaces**, 
   or **display buffers**, which need to operate with very specific memory layouts.
   - Memory is often **more constrained** in embedded systems, so DMA buffers are typically allocated with 
   careful consideration to size, alignment, and location in memory.
   - Additionally, embedded systems often have specialized **I/O peripherals** (e.g., **camera modules**, 
   **display controllers**, **video processing units**) that require **direct memory access** to buffers.

In both embedded and non-embedded systems, the same **DMA API** 
(`dma_alloc_coherent()`, `dma_alloc_attrs()`, etc.) is used to allocate buffers that can be directly 
accessed by the DMA engine, but embedded systems often deal with stricter memory constraints and may have 
custom memory regions optimized for DMA.

---

### 3. **How DMA Buffers Are Accessed Directly by Devices**

- **Mapping Physical Memory**: 
DMA buffers are allocated in **physically contiguous memory**. 
For DMA engines to use these buffers, the **physical address** of the buffer 
(i.e., `dma_handle` obtained during buffer allocation) is passed to the DMA engine, so it knows where the 
buffer is located in memory.

- **CPU vs. Device Access**: The **CPU** accesses the DMA buffer through the **virtual address** 
(`cpu_addr`), which can be mapped via `mmap()` in user space, while the **DMA engine** accesses the buffer 
through the **physical address** (`dma_handle`).

- **Cache Coherency**: DMA engines often operate in environments where memory **cache coherency** is 
critical. When using a buffer with DMA engines, the kernel ensures that the memory used for DMA is 
**cache-coherent**, meaning there is no risk of data inconsistency between CPU and device access. 
This is why `dma_alloc_coherent()` is frequently used.

### Conclusion

1. **DMA Engines** are hardware components that allow peripherals to access system memory directly, 
bypassing the CPU, which improves efficiency and performance for data transfer.
  
2. **DMA Buffers** are allocated in Linux using specific functions from the **DMA API** 
(`dma_alloc_coherent()`, `dma_alloc_attrs()`, etc.) that ensure the buffer is physically contiguous, 
cache-coherent, and suitable for direct access by the DMA engine.

3. **Accessing DMA Buffers**: Devices access these buffers using **physical addresses** while the CPU can 
access them via **virtual addresses**. In embedded systems, strict memory constraints often lead to careful 
buffer allocation and management.

In both embedded and non-embedded systems, the kernel provides the necessary tools to allocate, access, 
and share DMA buffers between subsystems and devices in an efficient manner.

============================
In Linux, when working with **System-on-Chip (SoC)** systems, the **DMA buffers** themselves are not typically described directly 
in the **Device Tree**. 

However, the **DMA-capable devices** (such as a GPU, camera, display controller, network adapter, etc.) that will use these DMA
buffers often require **DMA-related configuration** in the Device Tree.

### Key Points about Device Tree and DMA Buffers:

1. **Device Tree Overview**:  
   The **Device Tree** is a data structure used by the Linux kernel to describe the hardware in a system. 
   This includes describing devices, their properties, and how the kernel should interact with them. 
   The Device Tree is particularly important in **embedded systems** and **SoCs**, where hardware may vary 
   widely from platform to platform.

2. **DMA in the Device Tree**:  
   While **DMA buffers** themselves are not explicitly described in the Device Tree, 
   the **DMA controllers** and devices that will utilize DMA buffers are typically described. 
   This allows the kernel to know how to configure DMA channels, manage memory regions, and interact with 
   specific peripherals that require DMA.

   The DMA controllers (or engines) in the SoC are defined as part of the **Device Tree** to ensure that 
   the kernel knows where to find the DMA controller and how to interface with it.

### What Needs to be Included in the Device Tree:

1. **DMA Controllers**:
   The Device Tree must describe the DMA controller hardware (or DMA engines) present in the SoC. 
   The controller is responsible for managing the transfer of data between memory and peripheral devices, 
   and it often interacts with the DMA-capable devices.

   Example (in a device tree fragment):
   ```dts
   dma@some_address {
       compatible = "some,dma-controller";
       reg = <0x12345678 0x1000>;  // Base address and size of the DMA controller registers
       #dma-cells = <2>;            // Specifies the number of arguments for each DMA channel
       interrupts = <1 2>;          // Interrupt lines
   };
   ```

2. **DMA-Capable Devices**:
   Devices such as **GPU**, **camera**, **video processor**, **network adapters**, etc., that make use of 
   DMA need to be specified in the device tree as well. These devices may have their own DMA channels and 
   need to specify the appropriate **DMA controller** they use.

   Example for a device that uses DMA:
   ```dts
   gpu@some_address {
       compatible = "some,gpu-device";
       reg = <0xabcdef 0x1000>;
       dma-channel = <&dma 0>;  // Link this device to a specific DMA channel
   };
   ```

3. **Memory Regions for DMA**:
   For **DMA buffers**, the kernel needs to know which **physical memory regions** are available for DMA. 
   In some cases, the **memory regions** for DMA buffers may need to be specified in the Device Tree, 
   particularly if the SoC has **special memory regions** that are reserved for DMA 
   (e.g., video buffers or memory for network data).

   Example (describing a memory region for DMA buffers):
   ```dts
   memory@some_memory_region {
       reg = <0x80000000 0x40000000>;  // Start address and size of reserved memory
       no-map;  // Optionally, mark this memory as non-mappable
   };
   ```

   In some systems, **`reserved-memory`** nodes in the Device Tree can be used to specify areas of memory 
   that are designated for use by DMA-capable devices.

   Example (using `reserved-memory`):
   ```dts
   reserved-memory {
       #address-cells = <1>;
       #size-cells = <1>;

       dma-buffer@80000000 {
           reg = <0x80000000 0x10000000>;  // DMA buffer memory starting at 0x80000000
           no-map;  // Prevent the kernel from mapping this memory into the virtual address space
       };
   };
   ```

4. **DMA Buffers in User Space**:
   While the device tree may define memory regions for DMA-capable devices, **user-space applications** 
   don't directly interact with the Device Tree for DMA buffers. Instead, user space requests DMA buffers 
   through **kernel APIs** like `dma_alloc_coherent()`, `dma_alloc_attrs()`, or 
   through the **dma-buf framework** for sharing buffers between devices.

   However, the **kernel** will reference these memory regions and allocate DMA buffers within the bounds 
   of the defined memory regions (e.g., using `dma_alloc_coherent()` for memory regions described in the 
   device tree).

### Do DMA Buffers Need to be Defined in the Device Tree?

#### Direct Answer:  
**No, DMA buffers themselves are not directly defined in the Device Tree.** The **Device Tree** typically 
describes the devices that use DMA (e.g., the GPU, camera, or video processor), the **DMA controllers**, 
and the **memory regions** that could be used by DMA-capable devices. The actual **DMA buffer allocation** 
is handled by the kernel using appropriate APIs, often based on the available memory regions defined in the 
Device Tree.

### Example Workflow:

1. **Device Tree Setup**:
   - The Device Tree will describe the DMA controller (`dma@address`) and any **memory regions** reserved 
   for DMA (e.g., `reserved-memory` nodes).
   - Devices that use DMA (like a GPU or camera) will be linked to these DMA controllers.

2. **DMA Buffer Allocation**:
   - During initialization, the **driver** for the device (such as the GPU driver) will request 
   a **DMA buffer** using kernel APIs (`dma_alloc_coherent()`, etc.).
   - The **kernel** will ensure that the buffer is allocated in a **DMA-compatible memory region** and is 
   usable by the hardware.

3. **User Space Interaction**:
   - If the DMA buffer needs to be shared between subsystems, the **dma-buf framework** might be used, 
   allowing user-space applications to map the buffer via a file descriptor.

### Summary:
- DMA buffers themselves are not typically described in the **Device Tree**.
- The **Device Tree** primarily describes **DMA controllers** and **DMA-capable devices**.
- The **DMA memory regions** (such as reserved memory for devices) can be defined in the Device Tree.
- The **kernel** handles the allocation and management of DMA buffers, while user-space applications 
  interact with these buffers through appropriate system calls and kernel APIs.

If you are working with a custom SoC or device, you might need to ensure that the device tree reflects the 
correct configuration for the **DMA controllers** and any **reserved memory regions** that are required for
DMA operations.

===============


===> Complete Picture: kernel and user space:

**DMA Buffer Memory Allocator**

The DMA Buffer Memory Allocator is a kernel component that manages the 
allocation and deallocation of memory buffers for use with DMA (Direct Memory Access) operations. 

DMA is a technique used to transfer data between devices, such as peripherals, without involving the CPU.

The DMA Buffer Memory Allocator provides a way to manage the allocation of contiguous memory blocks, 
which are required for DMA operations. 
The allocator ensures that the allocated memory is properly aligned, sized, and protected, making it 
suitable for use with DMA-capable devices.

**Kernel Component**

The kernel component responsible for managing the DMA Buffer Memory Allocator is the **dma-buf** subsystem. 

The dma-buf subsystem provides a framework for managing DMA buffers, including the allocation and deallocation 
of memory, as well as the management of buffer ownership and synchronization.

The dma-buf subsystem consists of several components, including:

1. **dma-buf core**: The core component of the dma-buf subsystem, responsible for managing the allocation 
and deallocation of DMA buffers.

2. **dma-buf device drivers**: Device drivers that use the dma-buf subsystem to manage DMA buffers for 
their respective devices.

3. **dma-buf userspace API**: A userspace API that allows applications to interact with the dma-buf subsystem 
and manage DMA buffers.

Some of the key kernel components involved in the DMA Buffer Memory Allocator include:

1. **dma-buf.c**: The core implementation of the dma-buf subsystem.
2. **dma-heap.c**: A component that manages the allocation and deallocation of DMA buffers from a heap.
3. **dma-fence.c**: A component that manages the synchronization of DMA buffers using fences.

## *Using DMA Buffer Memory Allocator from Userspace**

To use the DMA Buffer Memory Allocator from userspace, you can use the **dma-buf** API, which provides a set of 
system calls and ioctl commands to manage DMA buffers. 

Here are the general steps to use the DMA Buffer Memory Allocator from userspace:

1. **Open the dma-buf device file**: Open the `/dev/dma-buf` device file to access the dma-buf subsystem.
2. **Create a dma-buf**: Use the `ioctl` command to create a new dma-buf, specifying the size and alignment of the buffer.
3. **Map the dma-buf**: Use the `mmap` system call to map the dma-buf into your application's address space.
4. **Use the dma-buf**: Use the mapped dma-buf to transfer data between devices, such as peripherals.
5. **Unmap the dma-buf**: Use the `munmap` system call to unmap the dma-buf from your application's address space.
6. **Release the dma-buf**: Use the `ioctl` command to release the dma-buf, freeing up the allocated memory.

Here is an example code snippet that demonstrates how to use the DMA Buffer Memory Allocator from

```#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

// Define the dma-buf device file
#define DMA_BUF_DEVICE "/dev/dma-buf"

// Define the dma-buf size and alignment
#define DMA_BUF_SIZE 4096
#define DMA_BUF_ALIGNMENT 4096

int main() {
    int dma_buf_fd;
    void *dma_buf_addr;
    uint32_t dma_buf_size;

    // Open the dma-buf device file
    dma_buf_fd = open(DMA_BUF_DEVICE, O_RDWR);
    if (dma_buf_fd < 0) {
        perror("open");
        return -1;
    }

    // Create a new dma-buf
    dma_buf_size = DMA_BUF_SIZE;
    if (ioctl(dma_buf_fd, _IOC(_IOC_READ | _IOC_WRITE, 'D', 1, sizeof(dma_buf_size)), &dma_buf_size) < 0) {
        perror("ioctl");
        return -1;
    }

    // Map the dma-buf into our address space
    dma_buf_addr = mmap(NULL, dma_buf_size, PROT_READ | PROT_WRITE, MAP_SHARED, dma_buf_fd, 0);
    if (dma_buf_addr == MAP_FAILED) {
        perror("mmap");
        return -1;
    }

    // Use the dma-buf to transfer data between devices
    // ...

    // Unmap the dma-buf from our address space
    if (munmap(dma_buf_addr, dma_buf_size) < 0) {
        perror("munmap");
        return -1;
    }

    // Release the dma-buf
    if (ioctl(dma_buf_fd, _IOC(_IOC_READ | _IOC_WRITE, 'D', 2, sizeof(dma_buf_size)), &dma_buf_size) < 0) {
        perror("ioctl");
        return -1;
    }

    // Close the dma-buf device file
    close(dma_buf_fd);

    return 0;
}
```

userspace:
```c
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

// Define the dma-buf device file
#define DMA_BUF_DEVICE "/dev/dma-buf"

// Define the dma-buf size and alignment
#define DMA_BUF_SIZE 4096
#define DMA_BUF_ALIGNMENT 4096

int main() {
    int dma_buf_fd;
    void *dma_buf_addr;
    uint32_t dma_buf_size;

    // Open the dma-buf device file
    dma_buf_fd = open(DMA_BUF_DEVICE, O_RDWR);
    if (dma_buf_fd < 0) {
        perror("open");
        return -1;
    }

    // Create a new dma-buf
    dma_buf_size = DMA_BUF_SIZE;
    if (ioctl(dma_buf_fd, _IOC(_IOC_READ | _IOC_WRITE, 'D', 1, sizeof(dma_buf_size)), &dma_buf_size) < 0) {
        perror("ioctl");
        return -1;
    }

    // Map the dma-buf into our address space
    dma_buf_addr = mmap(NULL, dma_buf_size, PROT_READ | PROT_WRITE, MAP_SHARED, dma_buf_fd, 0);
    if (dma_buf_addr == MAP_FAILED) {
        perror("mmap");
        return -1;
    }

    // Use the dma-buf to transfer data between devices
    // ...

    // Unmap the dma-buf from our address space
    if (munmap(dma_buf_addr, dma_buf_size) < 0) {
        perror("munmap");
        return -1;
    }

    // Release the dma-buf
    if (ioctl(dma_buf_fd, _IOC(_IOC_READ | _IOC_WRITE, 'D', 2, sizeof(dma_buf_size)), &dma_buf_size) < 0) {
        perror("ioctl");
        return -1;
    }

    // Close the dma-buf device file
    close(dma_buf_fd);

    return 0;
}
```
Note that this is a simplified example, and in practice, you may need to handle errors and exceptions more 
robustly. 
Additionally, the dma-buf API may vary depending on the specific Linux kernel version and configuration.


===============
Ref: https://openbeagle.org/Seth/linux/-/blob/6.1.26-ti-rt-r5/Documentation/driver-api/dma-buf.rst
Buffer Sharing and Synchronization:
---
The dma-buf subsystem provides the framework for sharing buffers for hardware (DMA) access across 
multiple device drivers and subsystems, and for synchronizing asynchronous hardware access.

This is used, for example, by drm "prime" multi-GPU support, but is of course not limited to GPU use cases.

The three main components of this are: 
    (1) dma-buf, representing a sg_table and exposed to userspace as a fd to allow passing between devices, 
    (2) fence, which provides a mechanism to signal when one device has finished access, and 
    (3) reservation, which manages the shared or exclusive fence(s) associated with the buffer.
    
Shared DMA Buffers:
---
Shared DMA Buffers
This document serves as a guide to device-driver writers on what is the dma-buf buffer sharing API,
how to use it for exporting and using shared buffers. 


Any device driver which wishes to be a part of DMA buffer sharing, can do so as
either the **'exporter'** of buffers, or the **'user'** or **'importer'** of buffers.

Say a driver A wants to use buffers created by driver B, 
    then B is called the exporter, and 
         A as buffer-user/importer.
         
         
The exporter:
    - implements and manages operations in :c:type:`struct dma_buf_ops<dma_buf_ops>` for the buffer, 
    - allows other users to share the buffer by using dma_buf sharing APIs, 
    - manages the details of buffer allocation, wrapped in a :c:type:`structdma_buf <dma_buf>`,
    - decides about the actual backing storage where this allocation happens,
    - and takes care of any migration of scatterlist - for all (shared) users of this buffer.
    
The buffer-user:
    - Is one of (many) sharing users of the buffer.
    - doesn't need to worry about how the buffer is allocated, or where.
    - and needs a mechanism to get access to the scatterlist that makes up this buffer in memory, 
      mapped into its own address space, so it can access the same area of memory. 
      This interface is provided by :c:type:`structdma_buf_attachment <dma_buf_attachment>`.


Any exporters or users of the dma-buf buffer sharing framework must have a 'select DMA_SHARED_BUFFER' in 
their respective Kconfigs.


## Userspace Interface Notes:

Mostly a DMA buffer file descriptor is simply an opaque object for userspace, and hence the generic interface 
exposed is very minimal. There's a few things to consider though:

- Since kernel 3.12 the dma-buf FD supports the llseek system call, 
  but only with offset=0 and whence=SEEK_END|SEEK_SET. 
  SEEK_SET is supported to allow the usual size discover pattern size = SEEK_END(0); SEEK_SET(0). 
  Every other llseek operation will report -EINVAL.
  
  If llseek on dma-buf FDs isn't support the kernel will report -ESPIPE for all cases. 
  Userspace can use this to detect support for discovering the dma-buf size using llseek.
  
- In order to avoid fd leaks on exec, the FD_CLOEXEC flag must be set on the file descriptor.  
  This is not just a resource leak, but a potential security hole.  It could give the newly exec'd 
  application access to buffers, via the leaked fd, to which it should otherwise not be permitted access.
  
  The problem with doing this via a separate fcntl() call, versus doing it atomically when the fd is 
  created, is that this is inherently racy in a multi-threaded app[3].  
  The issue is made worse when it is library code opening/creating the file descriptor, as the application 
  may not even be aware of the fd's.
  
  To avoid this problem, userspace must have a way to request O_CLOEXEC flag be set when the dma-buf fd is 
  created.  
  So any API provided by the exporting driver to create a dmabuf fd must provide a way to let userspace 
  control setting of O_CLOEXEC flag passed in to dma_buf_fd().

- Memory mapping the contents of the DMA buffer is also supported. 
  See the discussion below on CPU Access to DMA Buffer Objects for the full details.
  
- The DMA buffer FD is also pollable, see Implicit Fence Poll Support below for details.

- The DMA buffer FD also supports a few dma-buf-specific ioctls, see DMA Buffer ioctls below for details.

