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

* `firmware-name`: This property specifies the name of the firmware file that needs to be loaded for
                   the VPU.

* `encoder` and `decoder`: These are sub-nodes that specify the encoder and decoder interfaces provided 
                           by the VPU. 
                           The `compatible` property in these sub-nodes should match the compatible string 
                           of the encoder and decoder drivers.

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


