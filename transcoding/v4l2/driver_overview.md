# Linux v4l2 m2m decoder and encoder driver using a VPU:

- Linux and VPU communicate using shared memory.
- Main steps:
    - Setting up the linux kernel modules to interact with Video4Linux2 (V4L2)
    - Handle the memory management,
    - implement encoder/decoder logic
    - Interface layer with the codec chip using a shared memory region for communication.

- Walkthrough of things that are essential in building the above driver:

## 1. Understand the Video4Linux2 (V4L2) framework:

- V4L2 API:

    V4L2 provides an interface for video devices like cameras, decoders, and encoders to interact with the
    linux kernel.
    It handles operations like capturing, encoding, decoding, streaming and processing video buffers.

- M2M (memory-to-memory):

    V4L2 supports the M2M interface, which allows for video data to be transfered between user-space and
    kernel space memory via device without using intermediate hw buffers.

## 2. Setting up the linux kernel:

First step is to create Linux kernel module to interface with V4L2 and the codec chip ( VPU ).

- Create a kernel module:
    Write a basic kernel module to initialize the driver, load and unload it, and register the video device.

- Video device registration: 
    Register a video device using "video_register_device()" to let V4L2 recognize the device.

- Define V4L2 Device operations:
    Implement the core V4L2 file operations for M2M video processing. This includes,
    - opening
    - closing
    - reading and 
    - writing buffers.

## 3. Memory management with shared memory:

The shared memory region is where the video processing codec chip and the host ( linux ) will exchange data.
This shared memory needs to be setup and managed carefully to avoid memory corruptions.

- Allocate Shared memory: 
    Setup a contiguous memory region that both the codec chip and the kernel modile can access. 
    Typically this memory region is allocated from a special memory pool or reserved memory region in the
    device tree.

    - use "dma_alloc_coherent()" or similar functions to allocate the shared memory in a way that gurantees
      cache-coherency between the kernel and the codec chip.

    - Memory mapping: Map the shared memory region so that the codec can write to it and the kernel can read
      from it, or vice-versa using "ioremap()" or "dma_alloc_coherent()".

    - Handle Synchronization: Since both codec chip fw and the linux access a common shared memory, use
      proper Synchronization mechanisms line "semaphores" or "spinlocks" to avoid race conditions.

## 4. Implementing M2M Decoder and Encoder logic:

Implement a decoder/encoder functions, typically require setting up video buffers, processing video frames,
and communicating with the codec chip.

- Decoder:
    1. Configure the codec chip:
       Send command to the codec chip fw to configure it for decoding, typically a memory-mapped I/O (MMIO)
       or an I2C/SPI interface, depending on the hardware.
     
    2. Video Buffer Handling: Use V4L2 "VIDIOC_QBUF" and "VIDIOC_DQBUF" ioctl calls to queue and dequeue
       video buffers. The buffers and transferred to/from the shared memory region for processing. 
 
    3. Frame Decoding: The codec processes the encoded frame in shared memory and writes the decoded frame
       back to the shared memory.
 
    4. Interrupt handling: The codec chip might signal the kernel via an interrupt when a frame is decoded.
       The driver will need an interrupt handler to process the result.

- Encoder:
    1. Configure the codec chip: Send command to the codec chip to configure it for video encoding.
 
    2. Capture input frames: Queue input buffers containing raw video data using "VIDIO_QBUF".
 
    3. Frame Encoding: The codec chip will encode frames and write the encoded data to the shared memory.
 
    4. Handle the output: Once the encoding is done, the driver must retrieve the encoded frames using
       "VIDIOC_DQBUF" and pass the data back to user-space or another processing system.

## 5. Implement V4L2 M2M Operations:
 
 The core operations of M2M video driver include managing video buffers, controlling the state of the
 device, and handling user-space interactions.

 - VIDIOC_STREAMON/VIDIOC_STREAMOFF: These V4L2 ioctls will start / stop the stream, enabling continuous
   decoding/encoding. 
  
 - VIDIOC_QBUF/VIDIOC_DQBUF: These ioctl's manage the queues for video buffers. The driver will need to
   handle queuing and dequeuing buffers from the shared memory.
 
 - Buffer Setup: For both the encoder and decoder, you will need to setup the appropriate formats ( pixel
   format, size, ... etc ) using "VIDIO_S_FMT" and "VIDIO_G_FMT".

## 6. Codec Interaction:

Depending on the codec hardware, communication with the codec may involve different protocols. The most
common are:

- Memory-Managed I/O (MMIO): Directly interact with the codec chip's registers via MMIO to configure the
  codec.
- I2C/SPI: If the codec chip has an I2C or SPI interface, you'll need to implement communication with the
  codec using these protocols.

## 7. Handle interrupts and Events:

Video decoding and encoding might trigger interrupt once a frame is processed by the codec. For this case we
need to:
    1. Setup Interrupt handlers: When the codec signals that a frame has been processed, handle the
       interrupt and de-queue the processed frame.
    2. V4L2 Event handling: V4L2 supports event-driven operations. Using "VIDIOC_DQEVENT" and "VIDIO_S_CTRL"
       to notify the user-space about the status of the video processing.

## 8. user-space Interface:

User-space application communicate with the kernel module via the V4L2 interface:
    1. Video Capture/Output: In user-space applications typically interact with the device using standard
       V4L2 ioctl calls to manage video buffers and stream data.
 
    2. Buffer management: use mmap() or ioctl to map the kernel memory buffer into user-space for
       processing.

## 9. Error Handling and Debugging: 

Throughout the developement, you'll need to carefully handle error conditions:
- Codec Errors: Handle any errors the codec might signal, such as buffer overflow or invalid configuration.
- Buffer overflows/underflows: ensure that the buffer management logic correctly handles buffer overflows or
  underflows when streaming video.
- Logging: use pr_info() , pr_warn() , pr_err() etc. to add logging for Debugging processes.


### 10.  Example Skeleton Code for M2M Decoder:
Here’s a very basic skeleton for setting up a V4L2 M2M device driver:

    ```c
    #include <linux/module.h>
    #include <linux/kernel.h>
    #include <linux/init.h>
    #include <linux/videodev2.h>
    #include <linux/platform_device.h>
    #include <linux/dma-mapping.h>
    #include <linux/vmalloc.h>
    #include <linux/io.h>
    #include <linux/interrupt.h>

    // Placeholder for codec configuration
    static int my_codec_init(void) {
        // Initialize codec
        return 0;
    }

    static void my_codec_deinit(void) {
        // De-initialize codec
    }

    static int my_m2m_open(struct file *file) {
        // Open the M2M device
        return 0;
    }

    static int my_m2m_close(struct file *file) {
        // Close the M2M device
        return 0;
    }

    static long my_m2m_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
        switch (cmd) {
            case VIDIOC_STREAMON:
                // Start stream
                break;
            case VIDIOC_STREAMOFF:
                // Stop stream
                break;
            case VIDIOC_QBUF:
                // Queue buffer
                break;
            case VIDIOC_DQBUF:
                // Dequeue buffer
                break;
        }
        return 0;
    }

    static const struct file_operations my_m2m_fops = {
        .owner = THIS_MODULE,
        .open = my_m2m_open,
        .release = my_m2m_close,
        .unlocked_ioctl = my_m2m_ioctl,
    };

    static struct video_device my_video_device = {
        .name = "my_m2m_video",
        .fops = &my_m2m_fops,
        .v4l2_dev = NULL,  // Assume we have a v4l2_dev instance
        .release = video_device_release,
    };

    static int __init my_m2m_init(void) {
        int ret;
        
        // Initialize codec hardware
        ret = my_codec_init();
        if (ret) {
            pr_err("Failed to initialize codec\n");
            return ret;
        }

        // Register the video device
        ret = video_register_device(&my_video_device, V4L2_BUF_TYPE_VIDEO_CAPTURE, -1);
        if (ret) {
            pr_err("Failed to register video device\n");
            my_codec_deinit();
            return ret;
        }

        pr_info("My M2M video driver initialized\n");
        return 0;
    }

    static void __exit my_m2m_exit(void) {
        video_unregister_device(&my_video_device);
        my_codec_deinit();
        pr_info("My M2M video driver unloaded\n");
    }

    module_init(my_m2m_init);
    module_exit(my_m2m_exit);

    MODULE_LICENSE("GPL");
    MODULE_AUTHOR("Author");
    MODULE_DESCRIPTION("V4L2 M2M Decoder and Encoder with Shared Memory");
    ```

### 11. Testing and Validation:

    Once the driver is developed, test it with a user-space application that communicates with the driver 
    using V4L2. 
    Validate the video capture and encoding/decoding pipelines, ensuring that the shared memory region is 
    properly utilized and synchronized.

### Final Considerations:
   - Concurrency: 
        Ensure that the memory region and codec chip are properly synchronized across multiple frames.
   - Performance Optimization: 
        Ensure the memory operations, like DMA and shared memory access, are optimized for high throughput.
   - Hardware Specifications: 
        Review the hardware specifications of your codec chip, as the driver may require specific 
        configurations or optimizations tailored to that hardware.

This walkthrough outlines the essential steps needed to create an M2M video driver that uses a shared 
memory region for communication with a video processing codec chip. 
Each part of the process can get complex depending on your codec's specifications and the V4L2 API's 
requirements, so careful attention to detail is necessary.




