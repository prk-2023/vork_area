# Linux ION Memory Allocator:


ref: https://lwn.net/Articles/480055/

---

ION Mmeory allocator was introduced by Google:

- Back arounf 2011 Android eco-system had fragmented memory management interfaces: 
    - Android devices using NVidia Tegra used: NVMAP
    - TI OMAP : Used CMEM
    - Qualcomm MSM: Used PMEM.

- Google introduced ION which is a generalized memory manager on Android Rel 5.0, which the vendors switched
  there memory management to ION.

- Summarize the ION interface to user-space and kernel space :
  Besides being a memory pool manager, ION also enables its clients to share buffers, hence it treads the 
  same ground as the DMA buffer sharing framework from Linaro (DMABUF). This article will end with a 
  comparison of the two buffer sharing schemes.

- ION heaps:
  ION manages one or more memory pools, some of which are set aside at boot time to combat fragmentation or 
  to serve special hardware needs. 
  GPUs, display controllers, and cameras are some of the hardware blocks that may have special memory 
  requirements. 

  ION presents its memory pools as ION heaps. Each type of Android device can be provisioned with a 
  different set of ION heaps according to the memory requirements of the device. 
  The provider of an ION heap must implement the following set of callbacks:

  struct ion_heap_ops {
	int (*allocate) (struct ion_heap *heap, struct ion_buffer *buffer, unsigned long len,
                    unsigned long align, unsigned long flags);
	void (*free) (struct ion_buffer *buffer);
	int (*phys) (struct ion_heap *heap, struct ion_buffer *buffer, ion_phys_addr_t *addr, size_t *len);
    struct scatterlist *(*map_dma) (struct ion_heap *heap,
			 struct ion_buffer *buffer);
	void (*unmap_dma) (struct ion_heap *heap, 
	         struct ion_buffer *buffer);
	void * (*map_kernel) (struct ion_heap *heap, 
	         struct ion_buffer *buffer);
	void (*unmap_kernel) (struct ion_heap *heap, 
	         struct ion_buffer *buffer);
	int (*map_user) (struct ion_heap *heap, struct ion_buffer *buffer,
			 struct vm_area_struct *vma);
  };

- Briefly, allocate() and free() obtain or release an ion_buffer object from the heap. 
- A call to phys() will return the physical address and length of the buffer, but only for
  physically-contiguous buffers. 
- If the heap does not provide physically contiguous buffers, it does not have to provide this callback. 
- Here ion_phys_addr_t is a typedef of unsigned long, and will, someday, be replaced by phys_addr_t in 
  include/linux/types.h. 
- The map_dma() and unmap_dma() callbacks cause the buffer to be prepared (or unprepared) for DMA. 
- The map_kernel() and unmap_kernel() callbacks map (or unmap) the physical memory into the kernel virtual
  address space. A call to map_user() will map the memory to user space. There is no unmap_user() because 
  the mapping is represented as a file descriptor in user space. 
- The closing of that file descriptor will cause the memory to be unmapped from the calling process.

The default ION driver offers three heaps as listed below:

   ION_HEAP_TYPE_SYSTEM:        memory allocated via vmalloc_user().
   ION_HEAP_TYPE_SYSTEM_CONTIG: memory allocated via kzalloc.
   ION_HEAP_TYPE_CARVEOUT:	carveout memory is physically contiguous and set aside at boot.

Developers may choose to add more ION heaps. For example, this NVIDIA patch was submitted to add 
ION_HEAP_TYPE_IOMMU for hardware blocks equipped with an IOMMU.

- Using ION from user space

    Typically, user space device access libraries will use ION to allocate large contiguous media buffers. 
    For example, the still camera library may allocate a capture buffer to be used by the camera device. 
    Once the buffer is fully populated with video data, the library can pass the buffer to the kernel to be
    processed by a JPEG encoder hardware block.
    
    A user space C/C++ program must have been granted access to the /dev/ion device before it can allocate 
    memory from ION. A
    call to open("/dev/ion", O_RDONLY) returns a file descriptor as a handle representing an ION client. 
    Yes, one can allocate writable memory with an O_RDONLY open. 
    There can be no more than one client per user process. 
    To allocate a buffer, the client needs to fill in all the fields except the handle field in this 
    data structure:

   struct ion_allocation_data {
        size_t len;
        size_t align;
        unsigned int flags;
        struct ion_handle *handle;
   }

   The handle field is the output parameter, while the first three fields specify the alignment, length and 
   flags as input parameters. 
   The flags field is a bit mask indicating one or more ION heaps to allocate from, with the fallback 
   ordered according to which ION heap was first added via calls to ion_device_add_heap() during boot. 

   In the default implementation, ION_HEAP_TYPE_CARVEOUT is added before ION_HEAP_TYPE_CONTIG. 
   The flags of ION_HEAP_TYPE_CONTIG | ION_HEAP_TYPE_CARVEOUT indicate the intention to allocate from 
   ION_HEAP_TYPE_CARVEOUT with fallback to ION_HEAP_TYPE_CONTIG.

- User-space clients interact with ION using the ioctl() system call interface. 
  To allocate a buffer, the client makes this call:

    `int ioctl(int client_fd, ION_IOC_ALLOC, struct ion_allocation_data *allocation_data)`

  This call returns a buffer represented by ion_handle which is not a CPU-accessible buffer pointer. 
  The handle can only be used to obtain a file descriptor for buffer sharing as follows:

    `int ioctl(int client_fd, ION_IOC_SHARE, struct ion_fd_data *fd_data);`

  Here client_fd is the file descriptor corresponding to /dev/ion, and fd_data is a data structure with an 
  input handle field and an output fd field, as defined below:

   struct ion_fd_data {
        struct ion_handle *handle;
        int fd;
   }

  The fd field is the file descriptor that can be passed around for sharing. 
  On Android devices the BINDER IPC mechanism may be used to send fd to another process for sharing. 
  To obtain the shared buffer, the second user process must obtain a client handle first via the 
  open("/dev/ion", O_RDONLY) system call. 
  ION tracks its user space clients by the PID of the process (specifically, the PID of the thread that is 
  the "group leader" in the process). 
  Repeating the open("/dev/ion", O_RDONLY) call in the same process will get back another file descriptor 
  corresponding to the same client structure in the kernel.

  To free the buffer, the second client needs to undo the effect of mmap() with a call to munmap(), and the 
  first client needs to close the file descriptor it obtained via ION_IOC_SHARE, and call ION_IOC_FREE as 
  follows:

    int ioctl(int client_fd, ION_IOC_FREE, struct ion_handle_data *handle_data);

  Here ion_handle_data holds the handle as shown below:

     struct ion_handle_data {
	     struct ion_handle *handle;
     }

    The ION_IOC_FREE command causes the handle's reference counter to be decremented by one. 
    When this reference counter reaches zero, the ion_handle object gets destroyed and the affected 
    ION bookkeeping data structure is updated.

## Sharing ION buffers in the kernel

-  User processes can also share ION buffers with a kernel driver: 

   In the kernel, ION supports multiple clients, one for each driver that uses the ION functionality. 
   A kernel driver calls the following function to obtain an ION client handle:

    `struct ion_client *ion_client_create(struct ion_device *dev, 
                                        unsigned int heap_mask, const char *debug_name)`

   The first argument, dev, is the global ION device associated with /dev/ion; 
   (why a global device is needed, and why it must be passed as a parameter, is not entirely clear.)
   The second argument, heap_mask, selects one or more ION heaps in the same way as the ion_allocation_data.
   The flags field was covered in the previous section. 
   For smart phone use cases involving multimedia middleware, the user process typically allocates the 
   buffer from ION, obtains a file descriptor using the ION_IOC_SHARE command, then passes the file 
   desciptor to a kernel driver. 

   The kernel driver calls ion_import_fd() which converts the file descriptor to an ion_handle object, as 
   shown below:

     struct ion_handle *ion_import_fd(struct ion_client *client, int fd_from_user);

   The ion_handle object is the driver's client-local reference to the shared buffer. 

   The ion_import_fd() call looks up the physical address of the buffer to see whether the client has 
   obtained a handle to the same buffer before, and if it has, this call simply increments the reference 
   counter of the existing handle.

- Some hardware blocks can only operate on physically-contiguous buffers with physical addresses, so 
  affected drivers need to convert ion_handle to a physical buffer via this call:
  
   int ion_phys(struct ion_client *client, struct ion_handle *handle,
	       ion_phys_addr_t *addr, size_t *len)

Needless to say, if the buffer is not physically contiguous, this call will fail.

- When handling calls from a client, ION always validates the input file descriptor, client and handle 
  arguments. 
  For example, when importing a file descriptor, ION ensures the file descriptor was indeed created by an 
  ION_IOC_SHARE command. When ion_phys() is called, ION validates whether the buffer handle belongs to the 
  list of handles the client is allowed to access, and returns error if the handle is not on the list. 
  This validation mechanism reduces the likelihood of unwanted accesses and inadvertent resource leaks.

ION provides debug visibility through debugfs. 
It organizes debug information under /sys/kernel/debug/ion, with bookkeeping information in stored files 
associated with heaps and clients identified by symbolic names or PIDs.


## Comparing ION and DMABUF
ION and DMABUF share some common concepts. The dma_buf concept is similar to ion_buffer, while dma_buf_attachment serves a similar purpose as ion_handle. Both ION and DMABUF use anonymous file descriptors as the objects that can be passed around to provide reference-counted access to shared buffers. On the other hand, ION focuses on allocating and freeing memory from provisioned memory pools in a manner that can be shared and tracked, while DMABUF focuses more on buffer importing, exporting and synchronization in a manner that is consistent with buffer sharing solutions on non-ARM architectures.

The following table presents a feature comparison between ION and DMABUF:

- Memory Manager Role 
    - ION replaces PMEM as the manager of provisioned memory pools. The list of ION heaps can be extended 
      per device.
    - DMABUF is a buffer sharing framework, designed to integrate with the memory allocators in DMA mapping
      frameworks, like the work-in-progress DMA-contiguous allocator, also known as the Contiguous Memory 
      Allocator (CMA). DMABUF exporters have the option to implement custom allocators.


