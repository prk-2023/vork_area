# Stage 4: Writing and Binding Drivers


## Stage 4.1 : Writing and Binding Drivers
---

### 4.1.1 Overview

In this stage, you’ll learn how to:

* Write a **platform driver** that binds to devices (manual or DT).
* Expose device attributes via **sysfs**.
* Handle **probe** and **remove** functions properly.
* Use **device resources** (memory regions, IRQs).
* Understand the **driver lifecycle**.

---

### 4.1.2 Driver Skeleton with Sysfs Attribute Example

Here’s a minimal platform driver example that:

* Binds to a device named `"my_device"` (DT or manual).
* Creates a sysfs attribute `foo` that can be read/written by userspace.
* Cleans up on removal.

```c
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/sysfs.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("You");
MODULE_DESCRIPTION("Platform driver with sysfs attribute");

struct my_dev_data {
    int foo;
};

/* Show function for sysfs attribute 'foo' */
static ssize_t foo_show(struct device *dev,
                        struct device_attribute *attr,
                        char *buf)
{
    struct my_dev_data *data = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", data->foo);
}

/* Store function for sysfs attribute 'foo' */
static ssize_t foo_store(struct device *dev,
                         struct device_attribute *attr,
                         const char *buf,
                         size_t count)
{
    struct my_dev_data *data = dev_get_drvdata(dev);
    int ret, val;

    ret = kstrtoint(buf, 10, &val);
    if (ret)
        return ret;

    data->foo = val;
    return count;
}

/* Define the sysfs attribute */
static DEVICE_ATTR(foo, 0644, foo_show, foo_store);

/* Probe function */
static int my_driver_probe(struct platform_device *pdev)
{
    struct my_dev_data *data;
    int ret;

    printk(KERN_INFO "my_driver: probe\n");

    data = devm_kzalloc(&pdev->dev, sizeof(*data), GFP_KERNEL);
    if (!data)
        return -ENOMEM;

    data->foo = 42;  // Default value

    /* Store driver data in device */
    dev_set_drvdata(&pdev->dev, data);

    /* Create sysfs file */
    ret = device_create_file(&pdev->dev, &dev_attr_foo);
    if (ret)
        return ret;

    return 0;
}

/* Remove function */
static int my_driver_remove(struct platform_device *pdev)
{
    printk(KERN_INFO "my_driver: remove\n");

    /* Remove sysfs file */
    device_remove_file(&pdev->dev, &dev_attr_foo);

    return 0;
}

/* Platform driver structure */
static struct platform_driver my_driver = {
    .driver = {
        .name = "my_device",
        .owner = THIS_MODULE,
    },
    .probe = my_driver_probe,
    .remove = my_driver_remove,
};

module_platform_driver(my_driver);
```

---

### 4.1.3 What’s Happening Here?

| Step                     | Explanation                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `my_driver_probe`        | Allocates driver data, sets default `foo = 42`, creates sysfs attribute `foo` |
| `foo_show` & `foo_store` | Read/write sysfs attribute `foo`                                              |
| `dev_set_drvdata()`      | Associates private data with the device                                       |
| `device_create_file()`   | Adds a file to `/sys/devices/.../foo`                                         |
| `my_driver_remove`       | Cleans up by removing the sysfs attribute                                     |

---

### 4.1.4 Compile and Test

* Build as usual with a Makefile.
* Insert the module.
* Check `/sys/bus/platform/devices/my_device/foo` to read/write `foo`.

Example:

```bash
cat /sys/bus/platform/devices/my_device/foo
42
echo 100 > /sys/bus/platform/devices/my_device/foo
cat /sys/bus/platform/devices/my_device/foo
100
```

---

### 4.1.5 Handling Resources (Memory, IRQ)

Drivers often need to access hardware resources described in the device:

```c
struct resource *res;
void __iomem *regs;

res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
regs = devm_ioremap_resource(&pdev->dev, res);
if (IS_ERR(regs))
    return PTR_ERR(regs);
```

For IRQs:

```c
int irq = platform_get_irq(pdev, 0);
if (irq < 0)
    return irq;

/* request_irq() and handler setup */
```

---

### 4.1.6 Summary

* Writing drivers involves implementing **probe()** and **remove()** callbacks.
* Use **sysfs** to expose device settings and status to userspace.
* Use **devm\_** managed APIs for simpler resource management.
* Use **platform\_get\_resource()** to obtain hardware info passed by DT or board files.
* Register driver with **platform\_driver\_register()** or `module_platform_driver()`.

---

**full extended example** including resource handling, IRQs, and sysfs.

## 4.2 Example **full extended example** of a Linux platform driver that demonstrates:


* Handling **memory-mapped I/O resource**.
* Handling an **IRQ** (interrupt).
* Exposing a **sysfs attribute**.
* Proper **probe() / remove()** lifecycle.
* Using **devm\_** managed APIs for cleanup.

---

### 4.2.1 Full Extended Platform Driver Example

```c
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/interrupt.h>
#include <linux/sysfs.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("You");
MODULE_DESCRIPTION("Extended platform driver example with resources, IRQ, and sysfs");

struct my_driver_data {
    void __iomem *regs;      // MMIO base address
    int irq;
    int irq_counter;
};

/* Sysfs attribute to read IRQ count */
static ssize_t irq_count_show(struct device *dev,
                              struct device_attribute *attr,
                              char *buf)
{
    struct my_driver_data *data = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", data->irq_counter);
}
static DEVICE_ATTR(irq_count, 0444, irq_count_show, NULL);

/* IRQ handler */
static irqreturn_t my_irq_handler(int irq, void *dev_id)
{
    struct platform_device *pdev = dev_id;
    struct my_driver_data *data = platform_get_drvdata(pdev);

    data->irq_counter++;
    printk(KERN_INFO "my_driver: IRQ %d occurred, count=%d\n", irq, data->irq_counter);

    /* Normally, you'd handle device IRQ here */

    return IRQ_HANDLED;
}

/* Probe function */
static int my_driver_probe(struct platform_device *pdev)
{
    struct resource *res_mem;
    int irq;
    int ret;
    struct my_driver_data *data;

    printk(KERN_INFO "my_driver: probe start\n");

    /* Allocate driver data */
    data = devm_kzalloc(&pdev->dev, sizeof(*data), GFP_KERNEL);
    if (!data)
        return -ENOMEM;

    /* Get memory resource from device tree or board file */
    res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res_mem) {
        dev_err(&pdev->dev, "Failed to get MEM resource\n");
        return -ENODEV;
    }

    /* Map memory resource */
    data->regs = devm_ioremap_resource(&pdev->dev, res_mem);
    if (IS_ERR(data->regs)) {
        dev_err(&pdev->dev, "Failed to map registers\n");
        return PTR_ERR(data->regs);
    }

    /* Get IRQ resource */
    irq = platform_get_irq(pdev, 0);
    if (irq < 0) {
        dev_err(&pdev->dev, "Failed to get IRQ\n");
        return irq;
    }
    data->irq = irq;

    /* Request IRQ */
    ret = devm_request_irq(&pdev->dev, irq, my_irq_handler, 0,
                           dev_name(&pdev->dev), pdev);
    if (ret) {
        dev_err(&pdev->dev, "Failed to request IRQ\n");
        return ret;
    }

    data->irq_counter = 0;

    /* Save driver data */
    platform_set_drvdata(pdev, data);

    /* Create sysfs attribute */
    ret = device_create_file(&pdev->dev, &dev_attr_irq_count);
    if (ret) {
        dev_err(&pdev->dev, "Failed to create sysfs attribute\n");
        return ret;
    }

    printk(KERN_INFO "my_driver: probe successful\n");
    return 0;
}

/* Remove function */
static int my_driver_remove(struct platform_device *pdev)
{
    printk(KERN_INFO "my_driver: remove\n");

    device_remove_file(&pdev->dev, &dev_attr_irq_count);

    /* devm_* APIs automatically free resources and IRQs */

    return 0;
}

/* Match table for device tree */
static const struct of_device_id my_driver_of_match[] = {
    { .compatible = "myvendor,my-device", },
    { },
};
MODULE_DEVICE_TABLE(of, my_driver_of_match);

/* Platform driver structure */
static struct platform_driver my_driver = {
    .driver = {
        .name = "my_device",
        .of_match_table = my_driver_of_match,
        .owner = THIS_MODULE,
    },
    .probe = my_driver_probe,
    .remove = my_driver_remove,
};

module_platform_driver(my_driver);
```

---

### 4.2.2 Explanation:

| Feature                   | Explanation                                            |
| ------------------------- | ------------------------------------------------------ |
| `platform_get_resource()` | Gets device’s MMIO resource (e.g., registers)          |
| `devm_ioremap_resource()` | Maps MMIO memory into kernel virtual address space     |
| `platform_get_irq()`      | Gets IRQ number from device                            |
| `devm_request_irq()`      | Registers interrupt handler, with automatic cleanup    |
| `my_irq_handler()`        | IRQ handler increments a counter and prints debug info |
| `device_create_file()`    | Creates sysfs file `irq_count` to expose IRQ count     |
| `devm_kzalloc()`          | Allocates driver private data, automatically freed     |
| `of_device_id` table      | Matches Device Tree node’s compatible string           |

---

### 4.2.3 Device Tree Node Example

Here’s an example snippet for the Device Tree `.dts` file that would work with this driver:

```dts
my_device@10000000 {
    compatible = "myvendor,my-device";
    reg = <0x10000000 0x1000>;     // Base address + size
    interrupts = <5>;              // IRQ number 5
    status = "okay";
};
```

---

### 4.2.4 How to Test

1. Build and insert the module.

2. Load the Device Tree overlay or modify DT to include the node above.

3. Check dmesg for probe messages:

   ```
   my_driver: probe successful
   ```

4. Trigger the IRQ (hardware-specific, or simulate it).

5. Read IRQ count from sysfs:

   ```
   cat /sys/bus/platform/devices/my_device/irq_count
   ```

---

### 4.2.5 Summary:

* **Resources** are retrieved with `platform_get_resource()` and mapped with `devm_ioremap_resource()`.
* **IRQ handling** is done with `platform_get_irq()` and `devm_request_irq()`.
* Sysfs exposes driver variables to userspace with `device_create_file()`.
* `devm_` APIs simplify cleanup by tying resource lifetime to the device.
* Device Tree node binds the device to the driver using `compatible` string.

---

Would you like to:

* Explore how to **simulate IRQs** for testing?
* See an example of **writing to and reading from MMIO registers**?

---

## 4.3 Simulating IRQs for Testing

---

### 4.3.1 Why Simulate IRQs?

* On many embedded platforms, generating a real hardware IRQ requires physical hardware action.
* For testing driver IRQ handlers, simulating interrupts in software is handy.

---

### 4.3.2 Methods to Simulate IRQs

#### a) Using `generic_handle_irq()` (Kernel Internal)

This is a low-level method to trigger an IRQ from kernel code. It needs a valid IRQ number and context.

**Limitation:** Requires kernel space and may need special privileges.

---

#### b) Using `irq_set_irqchip_state()` or `irq_set_irqchip_state_locked()`

Used to set IRQ lines programmatically, but usually hardware/IRQ chip specific.

---

#### c) Use `tasklet` or `workqueue` to simulate IRQ handling logic (not real IRQ)

---

#### d) Use `misc` device + `raise_irq()` in test kernel module (complex)

---

### 4.3.3  Simple way: trigger IRQ handler manually in driver

You can create a **sysfs file** or a **proc entry** to manually call the IRQ handler for testing:

#### Add this to your driver:

```c
#include <linux/uaccess.h> // For copy_from_user

static ssize_t trigger_irq_store(struct device *dev,
                                 struct device_attribute *attr,
                                 const char *buf,
                                 size_t count)
{
    struct my_driver_data *data = dev_get_drvdata(dev);

    /* Directly call IRQ handler */
    my_irq_handler(data->irq, dev_get_drvdata(dev));

    return count;
}

static DEVICE_ATTR_WO(trigger_irq);

...

/* In probe, create the file */
device_create_file(&pdev->dev, &dev_attr_trigger_irq);

...

/* In remove, remove the file */
device_remove_file(&pdev->dev, &dev_attr_trigger_irq);
```

**Usage from userspace:**

```bash
echo 1 > /sys/bus/platform/devices/my_device/trigger_irq
```

This will call the IRQ handler directly, simulating an IRQ event for testing.

---

## 4.4 Reading and Writing MMIO Registers

---

### 4.4.1 Basics

* The device exposes registers via a **memory-mapped IO region**.
* The driver maps this region into CPU address space using `ioremap` or `devm_ioremap_resource`.
* Read/write are done using special functions to prevent compiler optimizations and ensure ordering.

---

### 4.4.2 Key Functions

| Function              | Description                        |
| --------------------- | ---------------------------------- |
| `readl(addr)`         | Read 32-bit little endian register |
| `readw(addr)`         | Read 16-bit register               |
| `readb(addr)`         | Read 8-bit register                |
| `writel(value, addr)` | Write 32-bit value                 |
| `writew(value, addr)` | Write 16-bit value                 |
| `writeb(value, addr)` | Write 8-bit value                  |

---

### 4.4.3 Example Usage in Your Driver

Let's say the device has a **control register** at offset `0x00` and a **status register** at offset `0x04` from the base address `regs`.

```c
#define REG_CTRL  0x00
#define REG_STATUS 0x04

/* Writing a value to control register */
writel(0x1, data->regs + REG_CTRL);

/* Reading from status register */
u32 status = readl(data->regs + REG_STATUS);
printk(KERN_INFO "Status register: 0x%x\n", status);
```

---

### 4.4.4 Extended Example: Read-modify-write

```c
u32 val;

/* Read current value */
val = readl(data->regs + REG_CTRL);

/* Set bit 2 */
val |= (1 << 2);

/* Write back */
writel(val, data->regs + REG_CTRL);
```

---

###  4.4.5 Where to Place This?

You can add these operations:

* Inside `probe()` to initialize the device.
* Inside IRQ handler to clear interrupt flags.
* Inside sysfs `store` method to control device.

---

### 4.4.6 Summary

| Task                 | How-To Summary                                 |
| -------------------- | ---------------------------------------------- |
| Simulate IRQ         | Add sysfs file that calls IRQ handler manually |
| Map device registers | Use `devm_ioremap_resource()` in probe         |
| Read/write registers | Use `readl()`, `writel()` with base+offset     |

---

