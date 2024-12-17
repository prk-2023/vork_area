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
  
