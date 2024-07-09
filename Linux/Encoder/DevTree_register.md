# Device Tree And Registration:

- Device node for decoder/encoder:

A sample device node that can be added to a DTSI (Device Tree Source Include) file for the VPU 
co-processor driver:

## Device node for VPUs Type 1:(single fw, handle encoding/decoding)

VPU for a typical that is capable of Enoding/Decoding with a single firmeware ( vpu_firmware.bin ).


```
vpu@1a000000 {
    compatible = "mycompany,vpu-encoder-decoder";
    reg = <0x1a000000 0x100000>; /* VPU register base address and size */
    interrupts = <GIC_SPI 12 IRQ_TYPE_LEVEL_HIGH>; /* VPU interrupt */
    clocks = <&clk_vpu>; /* VPU clock */
    clock-names = "vpu_clk";
    firmware-name = "vpu_firmware.bin"; /* VPU firmware file name */

    encoder {
        compatible = "mycompany,vpu-encoder";
    };

    decoder {
        compatible = "mycompany,vpu-decoder";
    };
};
```

Here's a brief explanation of the device node:

* `vpu@1a000000`: This is the node name, which can be any valid name, but it's common to use the 
                  base address of the device as the node name.
* `compatible`: This property specifies the compatible string that matches the driver's `of_match` table.
(
```
 of_match table: is a mechanism used by device drivers to specify the compatible devices
 they can handle. It's a way for the driver to declare its compatibility with specific devices, 
 and for the kernel to match the driver with the correct device.
 of_match = is a array of `of_device_id` struct which contains:
     - compatible: str that specifies the compatibility device name" 
     - data: a ptr to a private data struct that can be used by the driver to store additional info about 
     the device.
 of_match : is typicallt defined in the driver source code, and its used by the kernel to match the driver
 with the correct device during the device probing process.

 ex:
     static const struct of_device_id vpu_of_match[] = {
         { .compatible = "mycompany,vpu-encoder-decoder" },
         { .compatible = "mycompany,vpu-encoder" },
         { .compatible = "mycompany,vpu-decoder" },
         {}
     };
     MODULE_DEVICE_TABLE(of, vpu_of_match);

 the vpu_of_match table specified three compatible devices.
 The MODULE_DEVICE_TABLE macro is used to register the of_match table with the kernel.

 When the kernel boots it will iterate through the `of_match` tables of all registered drivers and 
 match the compatible string with the device tree nodes. If a match is found the kernel will call the 
 driver's probe function to initalize the device.

 In the case of the VPU driver, the compatible property in the device tree node 
 (e.g., compatible = "mycompany,vpu-encoder-decoder") is matched against the of_match table. 

 If a match is found, the kernel will call the VPU driver's probe function to initialize the device.

 By using the of_match table, the kernel can ensure that the correct driver is bound to the correct device,
 and that the driver can properly handle the device's capabilities and features.
```
)
* `reg`: This property specifies the base address and size of the VPU registers.

* `interrupts`: This property specifies the interrupt number and type for the VPU.

* `clocks` and `clock-names`: These properties specify the clock source and clock name for the VPU.

* `firmware-name`: This property specifies the name of the firmware file that needs to be loaded for the VPU.

* `encoder` and `decoder`: These are sub-nodes that specify the encoder and decoder interfaces provided 
   by the VPU. The `compatible` property in these sub-nodes should match the compatible string of 
   the encoder and decoder drivers.

Note that you may need to adjust the values of the properties based on your specific VPU hardware and 
system design.

## Independent firmeware to handle encoding and decoding:

VPU for a typical that is capable of Enoding/Decoding with a different firmewares
( encoder_firmware.bin, decoder_firmware.bin ).

1. **Separate hardware blocks**: 
If the VPU has separate HW blocks for encoding and decoding, each with its own registers, 
interrupts, and clocks, it's better to have separate device nodes for the encoder and decoder. 

This allows the driver to manage each block independently and optimize their performance.

2. **Different clock domains**: If the encoder and decoder have different clock domains, it's 
recommended to have separate device nodes. 
This ensures that the clock management is done correctly, and the driver can handle clock gating, 
frequency scaling, and other clock-related operations independently for each block.

Note:
---
**Clock Domain**:
A clock domain refers to a group of digital ckts or components that are driven by a common clock signal. 
i.e a clock domain is a region of a digital system where all the components are synchronized by the same 
clock signal. Clock domains are used to manage the timing and synchronization of signals within a 
digital system.

In the context of the VPU, a clock domain might refer to a specific clock signal that drives the 
encoder or decoder block. If the encoder and decoder have different clock domains, it means they are 
driven by separate clock signals, which can have different frequencies, phases, or other characteristics.

**Clock Gating**:
Clock gating is a power-saving technique used in digital ckts to reduce power consumption by stopping 
the clock signal to certain parts of the ckt when they are not in use. 
This is done by inserting a gate between the clock source and the clock input of the ckt, which can be 
controlled by a signal that indicates when the circuit is idle.

In the context of the VPU, clock gating might be used to stop the clock signal to the encoder or decoder 
block when it is not in use, reducing power consumption and heat generation.

**Frequency Scaling**:
Frequency scaling, also known as dynamic voltage and frequency scaling (DVFS), is a technique used to 
adjust the clock frequency of a digital circuit based on its workload or performance requirements. 
This is done to reduce power consumption, heat generation, and energy consumption.

In the context of the VPU, frequency scaling might be used to adjust the clock frequency of the encoder 
or decoder block based on the complexity of the video stream being processed. 
For example, if the video stream is simple, the clock frequency can be reduced to save power, while if 
the video stream is complex, the clock frequency can be increased to ensure proper processing.

**Clock-Related Operations**:
Clock-related operations refer to various tasks performed by the driver or firmware to manage the 
clock signals and clock domains within the VPU. These operations might include:
    * Clock initialization and configuration
    * Clock frequency scaling and adjustment
    * Clock gating and ungating
    * Clock domain crossing (i.e., synchronizing data transfer between different clock domains)
    * Clock monitoring and error detection

In the context of the VPU, clock-related operations are critical to ensure proper functioning of the 
encoder and decoder blocks, as well as to optimize power consumption and performance.

By having separate device nodes for the encoder and decoder, the driver can manage the clock domains, 
clock gating, frequency scaling, and other clock-related operations independently for each block, 
ensuring optimal performance, power efficiency, and reliability.

---

3. **Independent firmware loading**: 
If the encoder and decoder require different firmware images or have different firmware loading mechanisms,
separate device nodes can help manage the firmware loading process more efficiently.

4. **Distinct interfaces**: 
If the encoder and decoder provide distinct interfaces to the system, such as different video interfaces 
(e.g., HDMI for encoder and MIPI for decoder), separate device nodes can help manage these interfaces 
independently.

5. **Resource constraints**: 
In systems with limited resources (e.g., memory, interrupts), separating the device node into encoder 
and decoder nodes can help optimize resource allocation and reduce contention between the two blocks.

6. **Modular driver design**: 
If the driver is designed to be modular, with separate modules for the encoder and decoder, separate 
device nodes can help reflect this modular design and make it easier to maintain and update the driver.

Here's an example of how the device node could be split:
```
vpu_encoder@1a000000 {
    compatible = "mycompany,vpu-encoder";
    reg = <0x1a000000 0x10000>; /* Encoder register base address and size */
    interrupts = <GIC_SPI 12 IRQ_TYPE_LEVEL_HIGH>; /* Encoder interrupt */
    clocks = <&clk_encoder>; /* Encoder clock */
    clock-names = "encoder_clk";
    firmware-name = "encoder_firmware.bin"; /* Encoder firmware file name */
};

vpu_decoder@1a100000 {
    compatible = "mycompany,vpu-decoder";
    reg = <0x1a100000 0x10000>; /* Decoder register base address and size */
    interrupts = <GIC_SPI 13 IRQ_TYPE_LEVEL_HIGH>; /* Decoder interrupt */
    clocks = <&clk_decoder>; /* Decoder clock */
    clock-names = "decoder_clk";
    firmware-name = "decoder_firmware.bin"; /* Decoder firmware file name */
};
```
In this example, the device node is split into two separate nodes, `vpu_encoder` and `vpu_decoder`, each 
with its own set of properties and resources.


##  sample device driver using the devtree:

Here is a sample device node for a Linux kernel for a VPU co-processor used for encoding and decoding:
```
#include <linux/platform_device.h>
#include <linux/of_device.h>

static const struct of_device_id vpu_of_match[] = {
    { .compatible = "mycompany,vpu-encoder-decoder" },
    {}
};

MODULE_DEVICE_TABLE(of, vpu_of_match);

static int vpu_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    struct vpu_drvdata *drvdata;

    drvdata = devm_kzalloc(dev, sizeof(*drvdata), GFP_KERNEL);
    if (!drvdata)
        return -ENOMEM;

    platform_set_drvdata(pdev, drvdata);

    /* Initialize VPU registers and memory */
    drvdata->vpu_base = devm_ioremap_resource(dev, res);
    if (IS_ERR(drvdata->vpu_base))
        return PTR_ERR(drvdata->vpu_base);

    drvdata->vpu_clk = devm_clk_get(dev, "vpu_clk");
    if (IS_ERR(drvdata->vpu_clk))
        return PTR_ERR(drvdata->vpu_clk);

    clk_prepare_enable(drvdata->vpu_clk);

    /* Initialize VPU firmware */
    drvdata->firmware = request_firmware("vpu_firmware.bin", dev);
    if (!drvdata->firmware)
        return -ENOENT;

    /* Initialize VPU interrupts */
    drvdata->irq = platform_get_irq(pdev, 0);
    if (drvdata->irq < 0)
        return drvdata->irq;

    /* Register VPU encoder and decoder interfaces */
    drvdata->encoder_dev = video_register_device(&vpu_encoder_template, dev, "vpu-encoder");
    if (IS_ERR(drvdata->encoder_dev))
        return PTR_ERR(drvdata->encoder_dev);

    drvdata->decoder_dev = video_register_device(&vpu_decoder_template, dev, "vpu-decoder");
    if (IS_ERR(drvdata->decoder_dev))
        return PTR_ERR(drvdata->decoder_dev);

    return 0;
}

static int vpu_remove(struct platform_device *pdev)
{
    struct vpu_drvdata *drvdata = platform_get_drvdata(pdev);

    video_unregister_device(drvdata->encoder_dev);
    video_unregister_device(drvdata->decoder_dev);

    clk_disable_unprepare(drvdata->vpu_clk);
    release_firmware(drvdata->firmware);

    return 0;
}

static struct platform_driver vpu_driver = {
    .probe = vpu_probe,
    .remove = vpu_remove,
    .driver = {
        .name = "vpu-encoder-decoder",
        .of_match_table = vpu_of_match,
    },
};

module_platform_driver(vpu_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("VPU Co-processor driver for encoding and decoding");
```
This sample code defines a platform driver for a VPU co-processor that provides both encoding and decoding 
capabilities. 
The driver uses the `platform_device` framework to interact with the VPU hardware.

Here's a brief explanation of the code:

* The `vpu_of_match` table specifies the compatible string for the VPU device, which is used to match the 
device tree node with this driver.
* The `vpu_probe` function is called when the driver is bound to the VPU device. 
It initializes the VPU registers and memory, clocks, firmware, and interrupts. 
It also registers the VPU encoder and decoder interfaces using the `video_register_device` function.
* The `vpu_remove` function is called when the driver is unbound from the VPU device. 
It unregisters the VPU encoder and decoder interfaces, disables the clock, and releases the firmware.
* The `vpu_driver` structure defines the platform driver, which includes the `probe` and `remove` 
functions, as well as the `of_match_table` that specifies the compatible string.

Note that this is just a sample code, and you will need to modify it to fit your specific VPU hardware 
and use case. 
You may also need to add additional functionality, such as handling interrupts, managing memory, and 
implementing the encoder and decoder interfaces.

## example 2: for Independent fw for encoding/decoding:

Device driver code that accesses the device tree information and handles two firmwares for 
encoding and decoding:

```c
#include <linux/module.h>
#include <linux/of_device.h>
#include <linux/firmware.h>

static const struct of_device_id vpu_of_match[] = {
    { .compatible = "mycompany,vpu-encoder-decoder" },
    {}
};
MODULE_DEVICE_TABLE(of, vpu_of_match);

static int vpu_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    struct vpu_drvdata *drvdata;
    const struct of_device_id *of_id;
    struct firmware *fw_encoder, *fw_decoder;

    drvdata = devm_kzalloc(dev, sizeof(*drvdata), GFP_KERNEL);
    if (!drvdata)
        return -ENOMEM;

    platform_set_drvdata(pdev, drvdata);

    of_id = of_match_device(vpu_of_match, dev);
    if (!of_id)
        return -EINVAL;

    /* Get firmware nodes from device tree */
    fw_encoder = firmware_request_nowarn(THIS_MODULE, true, "encoder_firmware.bin", dev);
    if (IS_ERR(fw_encoder))
        return PTR_ERR(fw_encoder);

    fw_decoder = firmware_request_nowarn(THIS_MODULE, true, "decoder_firmware.bin", dev);
    if (IS_ERR(fw_decoder)) {
        firmware_release(fw_encoder);
        return PTR_ERR(fw_decoder);
    }

    /* Load firmware into device */
    drvdata->encoder_fw = fw_encoder;
    drvdata->decoder_fw = fw_decoder;

    /* Initialize VPU registers and memory */
    drvdata->vpu_base = devm_ioremap_resource(dev, res);
    if (IS_ERR(drvdata->vpu_base)) {
        firmware_release(fw_encoder);
        firmware_release(fw_decoder);
        return PTR_ERR(drvdata->vpu_base);
    }

    /* Initialize VPU clocks and interrupts */
    drvdata->vpu_clk = devm_clk_get(dev, "vpu_clk");
    if (IS_ERR(drvdata->vpu_clk)) {
        firmware_release(fw_encoder);
        firmware_release(fw_decoder);
        return PTR_ERR(drvdata->vpu_clk);
    }

    clk_prepare_enable(drvdata->vpu_clk);

    /* Initialize encoder and decoder interfaces */
    drvdata->encoder_dev = video_register_device(&vpu_encoder_template, dev, "vpu-encoder");
    if (IS_ERR(drvdata->encoder_dev)) {
        firmware_release(fw_encoder);
        firmware_release(fw_decoder);
        return PTR_ERR(drvdata->encoder_dev);
    }

    drvdata->decoder_dev = video_register_device(&vpu_decoder_template, dev, "vpu-decoder");
    if (IS_ERR(drvdata->decoder_dev)) {
        video_unregister_device(drvdata->encoder_dev);
        firmware_release(fw_encoder);
        firmware_release(fw_decoder);
        return PTR_ERR(drvdata->decoder_dev);
    }

    return 0;
}

static int vpu_remove(struct platform_device *pdev)
{
    struct vpu_drvdata *drvdata = platform_get_drvdata(pdev);

    video_unregister_device(drvdata->decoder_dev);
    video_unregister_device(drvdata->encoder_dev);

    firmware_release(drvdata->decoder_fw);
    firmware_release(drvdata->encoder_fw);

    clk_disable_unprepare(drvdata->vpu_clk);

    return 0;
}

static struct platform_driver vpu_driver = {
    .probe = vpu_probe,
    .remove = vpu_remove,
    .driver = {
        .name = "vpu-encoder-decoder",
        .of_match_table = vpu_of_match,
    },
};

module_platform_driver(vpu_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("VPU Co-processor driver for encoding and decoding");
```
In this updated code, we've added the following changes:

* We've added two firmware nodes to the device tree, one for the encoder firmware and one for the 
decoder firmware.

* In the `vpu_probe` function, we use the `firmware_request_nowarn` function to request the firmware 
nodes from the device tree.

* We load the firmware into the device using the `firmware_request_nowarn` function.

* We store the firmware pointers in the `drvdata` structure.

* We release the firmware pointers in the `vpu_remove` function.


Note that this code assumes that the device tree node has the following structure:
```c
vpu@1a000000 {
    compatible = "mycompany,vpu-encoder-decoder";
    reg = <0x1a000000 0x100000>;
    interrupts = <GIC_SPI 12 IRQ_TYPE_LEVEL_HIGH>;
    clocks = <&clk_vpu>;
    clock-names = "vpu_clk";

    firmware {
        encoder {
            firmware-name = "encoder_firmware.bin";
        };
        decoder {
            firmware-name = "decoder_firmware.bin";
        };
    };
};
```
This device tree node specifies two firmware nodes, one for the encoder firmware and one for the decoder 
firmware. The `firmware-name` property specifies the name of the firmware file to be loaded.

------------------------

## v4l2_device_register():

- `v4l2_device_register()` is a function in the Linux kernel's V4L2 framework that registers a V4L2 device 
with the kernel. This function is used to register a V4L2 device, such as a video codec, with the kernel, 
making it available for use by user-space applications.

```c 
    int v4l2_device_register(struct device *dev, struct v4l2_device *v4l2_dev)
```
**Arguments:**

- `dev`: A pointer to a `struct device` that represents the underlying device. 
         This is typically a platform device or a PCI device.
- `v4l2_dev`: A pointer to a `struct v4l2_device` that represents the V4L2 device to be registered.

1. struct device *dev: Ptr to basic device structure which represented the underlying device in the kernel.

This device obj is typically created by the device driver using `device_create()` or
`platform_device_register()`.

In the context of V4L2 this device obj is usually a representation of a video capture device such as a 
webcam, TV tuner, or video encoder or a codec device which can be a hw accelerator or a sw based codec.

2. `struct v4l2_device *v4l2_dev`: a ptr to a struct v4l2_device which represents the V4L2 Device.
This struct contains information about the V4L2 device, such as its capabilities, controls, buffers.

The `v4l2_device` structure is defined in `include/media/v4l2-dev.h` and contains the following
members:

```c
/**
 * struct v4l2_device - main struct to for V4L2 device drivers
 *
 * @dev: pointer to struct device.
 * @mdev: pointer to struct media_device, may be NULL.
 * @subdevs: used to keep track of the registered subdevs
 * @lock: lock this struct; can be used by the driver as well
 *	if this struct is embedded into a larger struct.
 * @name: unique device name, by default the driver name + bus ID
 * @notify: notify operation called by some sub-devices.
 * @ctrl_handler: The control handler. May be %NULL.
 * @prio: Device's priority state
 * @ref: Keep track of the references to this struct.
 * @release: Release function that is called when the ref count
 *	goes to 0.
 *
 * Each instance of a V4L2 device should create the v4l2_device struct,
 * either stand-alone or embedded in a larger struct.
 *
 * It allows easy access to sub-devices (see v4l2-subdev.h) and provides
 * basic V4L2 device-level support.
 *
 * .. note::
 *
 *    #) @dev->driver_data points to this struct.
 *    #) @dev might be %NULL if there is no parent device
 */
struct v4l2_device {
	struct device *dev;
	struct media_device *mdev;
	struct list_head subdevs;
	spinlock_t lock;
	char name[36];
	void (*notify)(struct v4l2_subdev *sd,
			unsigned int notification, void *arg);
	struct v4l2_ctrl_handler *ctrl_handler;
	struct v4l2_prio_state prio;
	struct kref ref;
	void (*release)(struct v4l2_device *v4l2_dev);
};
```
For a M2MV4L2 media codec device, the `v4l2_device` struct is initialized with the following information:

* `name`: A string that identifies the V4L2 device.

* `type`: The type of V4L2 device (e.g., V4L2_BUF_TYPE_VIDEO_CAPTURE for a capture device).

* `dev`: a pointer to the underlying `struct device` object

* `mdev`: A ptr to a `struct media_device` that represents the media device associated with the V4L2 device.

* `ops`: a pointer to a `v4l2_device_ops` structure, which contains function pointers for various
         V4L2 device operations (e.g., open, close, read, write, etc.)
		 
* `m2m_ops`: a pointer to a `v4l2_m2m_ops` structure, which contains function pointers specific 
             to M2M operations (e.g., queue setup, buffer management, etc.)
			 
* `ctrl_handler`: a pointer to a `v4l2_ctrl_handler` structure, which manages the device's controls 
		 		 (e.g., codec settings, bitrate, etc.)
				 
* `priv`: a private data pointer, which can be used by the device driver to store device-specific data

The `v4l2_device` structure is initialized differently for decoder and encoder devices:

**Decoder Device:**

* `v4l2_device_caps` is set to `V4L2_CAP_VIDEO_M2M_MPLANE` to indicate that the device supports 
multi-planar video decoding.
* `v4l2_device_ops` is set to a `v4l2_device_ops` structure that provides functions for decoder-specific 
operations (e.g., `vidioc_querycap`, `vidioc_s_fmt`, etc.).
* `m2m_ops` is set to a `v4l2_m2m_ops` structure that provides functions for M2M decoder operations (e.g., 
`m2m_queue_setup`, `m2m_buffer_prepare`, etc.).

**Encoder Device:**

* `v4l2_device_caps` is set to `V4L2_CAP_VIDEO_M2M_MPLANE` to indicate that the device supports multi-
planar video encoding.
* `v4l2_device_ops` is set to a `v4l2_device_ops` structure that provides functions for encoder-specific 
operations (e.g., `vidioc_querycap`, `vidioc_s_fmt`, etc.).
* `m2m_ops` is set to a `v4l2_m2m_ops` structure that provides functions for M2M encoder operations (e.g., 
`m2m_queue_setup`, `m2m_buffer_prepare`, etc.).

When `v4l2_device_register()` is called, the kernel initializes the `v4l2_device` structure and adds it to
the list of registered V4L2 devices. 

The device driver is responsible for filling in the necessary fields of the `v4l2_device` structure before
calling `v4l2_device_register()`.

By registering a M2M V4L2 media codec device, the kernel makes it available to user-space applications, 
which can then use the V4L2 API to access and control the device for video encoding and decoding 
operations.

## **M2M V4L2 Media Codec Device**:
In the context of a M2M (Memory-to-Memory) V4L2 media codec device, `v4l2_device_register()` is used to 
register both the decoder and encoder devices with the kernel.

For a decoder device, the `v4l2_device` structure would typically have the following settings:

* `type` = `V4L2_BUF_TYPE_VIDEO_CAPTURE`
* `ioctl_ops` = pointer to a `struct v4l2_ioctl_ops` that defines the ioctl operations supported by the decoder
* `drv_priv` = pointer to a private data structure specific to the decoder driver

For an encoder device, the `v4l2_device` structure would typically have the following settings:

* `type` = `V4L2_BUF_TYPE_VIDEO_OUTPUT`
* `ioctl_ops` = pointer to a `struct v4l2_ioctl_ops` that defines the ioctl operations supported by the encoder
* `drv_priv` = pointer to a private data structure specific to the encoder driver

By registering both the decoder and encoder devices with the kernel using `v4l2_device_register()`, 
kernel can manage the devices and provide a interface for user-space applications to access and ctrl them.

## Buffers and IOCTL:

**Buffer Management for M2M Device:**
In a V4L2 M2M device, buffer management is implemented using the `struct v4l2_m2m_ctx` structure, 
defined in `include/media/v4l2-mem2mem.h`.

`struct v4l2_m2m_ctx` represents a M2M context, which is a set of buffers and queues used for
memory-to-memory operations. 
This structure is used to manage the buffers and queues for both the decoder and encoder devices.

Here are some important fields in `struct v4l2_m2m_ctx`:

* `q_ctx`: An array of `struct v4l2_m2m_queue_ctx` structures, which represent the capture and output queues.
* `buf_ctx`: An array of `struct v4l2_m2m_buffer_ctx` struct, which represent the buffers allocated for the
             M2M operation.
* `fh`: A file handle that represents the open file descriptor for the M2M device.

The `v4l2_m2m_ctx` structure is typically allocated and initialized by the driver during the `open()` 
operation, and is used to manage the buffers and queues throughout the lifetime of the M2M device.

**Ioctls for M2M Codec Encode and Decode Functions:**
To provide access to user-space applications to access the M2M codec encode and decode functions,
ioctls are implemented in the driver. Ioctls are a way for user-space applications to communicate with
kernel-space drivers.

In a V4L2 M2M device, ioctls are implemented using the `struct v4l2_ioctl_ops` structure, 
defined in `include/media/v4l2-dev.h`.

Here are some important fields in `struct v4l2_ioctl_ops`:

* `vidioc_querycap`: A function that returns the capabilities of the device.
* `vidioc_enum_fmt_vid_cap`: A function that enumerates the supported formats for capture.
* `vidioc_enum_fmt_vid_out`: A function that enumerates the supported formats for output.
* `vidioc_g_fmt_vid_cap`: A function that gets the current format for capture.
* `vidioc_g_fmt_vid_out`: A function that gets the current format for output.
* `vidioc_s_fmt_vid_cap`: A function that sets the format for capture.
* `vidioc_s_fmt_vid_out`: A function that sets the format for output.
* `vidioc_reqbufs`: A function that requests buffers for the M2M operation.
* `vidioc_querybuf`: A function that queries the status of a buffer.
* `vidioc_qbuf`: A function that queues a buffer for processing.
* `vidioc_dqbuf`: A function that dequeues a buffer after processing.

For a M2M codec device, the following ioctls are typically implemented:

* `VIDIOC_ENCODE_CMD`: An ioctl that starts the encoding process.
* `VIDIOC_DECODE_CMD`: An ioctl that starts the decoding process.
* `VIDIOC_GET_CODEC_INFO`: An ioctl that returns information about the codec.
* `VIDIOC_SET_CODEC_PARAMS`: An ioctl that sets parameters for the codec.

These ioctls are implemented in the driver's `ioctl` function, which is called when a user-space app 
issues an ioctl command to the device. 

The `ioctl` function is responsible for handling the ioctl command and performing the necessary actions.

Here's an example of how the `ioctl` function might be implemented:
```c
static int m2m_ioctl(struct file *file, unsigned int cmd, void *arg)
{
    struct v4l2_m2m_ctx *m2m_ctx = file->private_data;

    switch (cmd) {
    case VIDIOC_ENCODE_CMD:
        // Start encoding process
        return m2m_encode(m2m_ctx, arg);
    case VIDIOC_DECODE_CMD:
        // Start decoding process
        return m2m_decode(m2m_ctx, arg);
    case VIDIOC_GET_CODEC_INFO:
        // Return codec information
        return m2m_get_codec_info(m2m_ctx, arg);
    case VIDIOC_SET_CODEC_PARAMS:
        // Set codec parameters
        return m2m_set_codec_params(m2m_ctx, arg);
    default:
        return -EINVAL;
    }
}
```
