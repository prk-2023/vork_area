# Stage 3: Intro to Linux Device Model

---

## 3.1 What is the Linux Device Model?

The Linux Device Model provides a unified way for the kernel to represent and manage hardware devices and their drivers. It’s a framework that organizes devices, drivers, buses, and classes in a hierarchical structure and facilitates device discovery, driver binding, and sysfs representation.

---

## 3.2 Key Concepts & Structures

| Concept    | Description                                           | Key Kernel Struct      |
| ---------- | ----------------------------------------------------- | ---------------------- |
| **Device** | Represents a physical or virtual hardware device      | `struct device`        |
| **Driver** | Software controlling a device                         | `struct device_driver` |
| **Bus**    | Physical or logical bus connecting devices            | `struct bus_type`      |
| **Class**  | Logical grouping of devices (e.g., input devices)     | `struct class`         |
| **Sysfs**  | Virtual filesystem exposing device model data to user | `/sys`                 |
| **UEVENT** | Hotplug event generated on device changes             | Used by `udev`         |

---

## 3.3 Relationships

* **Bus** contains multiple **devices**.
* A **device** is bound to a **driver**.
* **Devices** are grouped into **classes** (e.g., `block`, `net`, `input`).
* The device model exposes information in `/sys` and manages hotplug events.

---

## 3.4 `struct device`

```c
struct device {
    struct device_private *p;     // Private data
    struct device *parent;        // Parent device in hierarchy
    struct device_driver *driver; // Bound driver
    struct bus_type *bus;         // Bus this device belongs to
    struct class *class;          // Class this device belongs to
    dev_t devt;                   // Device number (major, minor)
    char *init_name;              // Name of device
    struct kobject kobj;          // Kernel object for sysfs
    // ... more fields
};
```

* This structure represents the device in kernel.
* Devices are organized as a tree (via `parent`).

---

## 3.5 `struct device_driver`

```c
struct device_driver {
    const char *name;                   // Driver name
    struct bus_type *bus;               // Bus this driver supports
    int (*probe)(struct device *dev);  // Called when device is found
    int (*remove)(struct device *dev); // Called when device is removed
    struct kobject driver_kobj;         // Kernel object for sysfs
    // ... more fields
};
```

* Drivers register themselves with a bus.
* `probe()` binds driver to device.

---

## 3.6 `struct bus_type`

```c
struct bus_type {
    const char *name;                  // Name of the bus (e.g., "pci", "usb")
    int (*match)(struct device *, struct device_driver *); // Matching function
    int (*probe)(struct device *);    // Optional bus-specific probe
    void (*remove)(struct device *);  // Optional remove function
    struct kobject kobj;               // Kernel object for sysfs
    // ... more fields
};
```

* Manages the devices connected via this bus.
* Handles device-driver matching.

---

## 3.7 `struct class`

```c
struct class {
    const char *name;                 // Class name (e.g., "net", "block")
    struct kobject *class_kobj;      // Kernel object for sysfs
    struct module *owner;             // Owning module
    struct device *dev;              // Devices belonging to this class
    // ... more fields
};
```

* Groups devices for sysfs and user-space visibility.
* Helps create `/sys/class/` entries.

---

## 3.8 Sysfs & `/sys` Layout

* `/sys` is a virtual filesystem exposing the device model.
* Common directories:

  * `/sys/bus/` — buses and their devices/drivers.
  * `/sys/class/` — device classes.
  * `/sys/devices/` — physical device hierarchy.
* Attributes here are readable and writable files representing device properties.

---

## 3.9 Hotplug & Uevents

* When devices are added or removed, the kernel sends **uevents**.
* Userspace daemon `udev` listens for these events and creates/removes device nodes in `/dev`.
* This is critical for dynamic hardware management.

---

## 3.10 Hands-on Exercises

* Explore `/sys/class/`, `/sys/bus/`, `/sys/devices/` directories.
* Use `udevadm monitor` to watch kernel uevents when plugging/unplugging USB devices.
* Write a simple kernel module that registers a dummy device and creates sysfs attributes.

---

## 3.11 Suggested Reading

* [LWN: The Linux device model, part 1](https://lwn.net/Articles/19499/)
* [Linux Device Drivers, Chapter 3: The Linux Device Model](https://lwn.net/Kernel/LDD3/)
* Kernel Documentation: `/Documentation/driver-api/`

---

Let's clarify how **`platform_device`** fits into the **Linux Device Model** scope.

---

## 3.2 `platform_device` and `platform_driver`

###  3.2.1 What is a `platform_device`?

A `platform_device` is a type of device that is **not discoverable by standard buses** like PCI or USB. These are usually:

* **SoC peripherals** (e.g., UART, SPI, I2C controllers, GPIOs).
* Devices that the kernel **must be explicitly told about** — often via:

  * Static code in board files (old way)
  * Device Tree (modern, embedded systems)
  * ACPI (on x86)

---

###  3.2.2 How Does It Fit in the Device Model?

| Component           | Role                                        |
| ------------------- | ------------------------------------------- |
| `platform_device`   | Represents a statically declared device     |
| `platform_driver`   | The driver that handles platform devices    |
| `platform_bus_type` | The logical bus (`bus_type`) they belong to |

So even though there's no real physical bus, the Linux kernel **creates a virtual bus** called the **platform bus**.

---

### 3.3.3 Breakdown in the Device Model

| Device Model Concept | Implementation Example                                            |
| -------------------- | ----------------------------------------------------------------- |
| **Device**           | `struct platform_device` (embedded `struct device`)               |
| **Driver**           | `struct platform_driver` (has `probe()`/`remove()`)               |
| **Bus**              | `platform_bus_type` (shared by all platform devices)              |
| **Binding**          | Kernel matches `platform_device.name` with `platform_driver.name` |
| **Class (optional)** | May be created to group devices logically                         |

---

### 3.3.4 Lifecycle

1. A `platform_device` is registered:

   ```c
   platform_device_register(&my_device);
   ```
2. The kernel tries to match it with a registered `platform_driver`:

   ```c
   platform_driver_register(&my_driver);
   ```
3. If `my_device.name == my_driver.name`, then `my_driver.probe()` is called.

---

### 3.3.5 Visualization

```
        [ platform_bus_type ]
                 |
        -----------------------
        |                     |
[ platform_device ]   [ platform_driver ]
        \_____________________/
               name match → probe()
```

---

### 3.3.6 In `/sys`

Platform devices show up under:

* `/sys/bus/platform/devices/`
* `/sys/devices/platform/`

And you can see platform drivers at:

* `/sys/bus/platform/drivers/`

---

### 3.3.7 Example Use Case

A GPIO controller on an embedded board:

* Declared via Device Tree or static init as a `platform_device`.
* Linux GPIO driver registers a `platform_driver`.
* On match, the driver `probe()` is called and initializes the GPIO controller.

---

### 3.3.8 Summary Table

| Term                | Description                                          |
| ------------------- | ---------------------------------------------------- |
| `platform_device`   | Describes a non-discoverable, static device          |
| `platform_driver`   | Handles platform devices with matching name          |
| `platform_bus_type` | The "bus" for these devices in the model             |
| Match mechanism     | String match between `device.name` and `driver.name` |
| Sysfs location      | `/sys/bus/platform/`, `/sys/devices/platform/`       |

---


## 3.4 Code example for `platform_device` and `platform_driver` (No Device Tree):

Code example of registering a platform_device and platform_driver, or a look at how this works with the Device Tree (common on embedded systems like Raspberry Pi, BeagleBone, etc.).

 **complete and commented example** of a `platform_device` and `platform_driver` in the Linux kernel. 
 This example is kept **self-contained**, meaning:

* No Device Tree is used.
* The device is manually registered in code.
* This is suitable for learning/testing on a virtual kernel or sandbox.

---
Goal

Create a platform device named `"my_device"` and a matching platform driver named `"my_device"`. When the device is registered, the driver’s `probe()` function is called. The driver also unregisters cleanly on module exit.
---
### 3.4.1 File: `platform_device_driver.c`

```c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("You");
MODULE_DESCRIPTION("Platform device and driver example");

/* ------------------ PLATFORM DRIVER CODE ------------------ */

// Called when the device is matched and bound to this driver
static int my_platform_probe(struct platform_device *pdev) {
    printk(KERN_INFO "my_platform_driver: probe called for device %s\n", pdev->name);
    return 0; // Success
}

// Called when the device is removed or driver is unloaded
static int my_platform_remove(struct platform_device *pdev) {
    printk(KERN_INFO "my_platform_driver: remove called for device %s\n", pdev->name);
    return 0;
}

// Define the platform driver structure
static struct platform_driver my_platform_driver = {
    .probe = my_platform_probe,
    .remove = my_platform_remove,
    .driver = {
        .name = "my_device", // This must match the device name
        .owner = THIS_MODULE,
    },
};

/* ------------------ PLATFORM DEVICE CODE ------------------ */

// Create the device resources (optional — usually used for memory, IRQs, etc.)
static struct resource my_device_resources[] = {
    // No hardware resources in this simple example
};

// Define the platform device structure
static struct platform_device my_platform_device = {
    .name = "my_device", // Must match the driver name for auto-binding
    .id = -1,            // Only one instance of this device
    .num_resources = 0,  // No resources used
    .resource = my_device_resources,
};

/* ------------------ MODULE INIT / EXIT ------------------ */

static int __init my_module_init(void) {
    int ret;

    printk(KERN_INFO "Initializing platform device and driver\n");

    // Register the driver first so it’s ready when device is added
    ret = platform_driver_register(&my_platform_driver);
    if (ret)
        return ret;

    // Now register the platform device
    ret = platform_device_register(&my_platform_device);
    if (ret) {
        platform_driver_unregister(&my_platform_driver);
        return ret;
    }

    return 0;
}

static void __exit my_module_exit(void) {
    printk(KERN_INFO "Exiting platform device and driver\n");

    // Unregister the device before the driver
    platform_device_unregister(&my_platform_device);
    platform_driver_unregister(&my_platform_driver);
}

module_init(my_module_init);
module_exit(my_module_exit);
```

---

### 3.4.2 How to Compile and Test

1. **Save the code** as `platform_device_driver.c`.

2. **Write a Makefile**:

   ```makefile
   obj-m += platform_device_driver.o

   all:
   	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

   clean:
   	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
   ```

3. **Build and Insert**:

   ```bash
   make
   sudo insmod platform_device_driver.ko
   dmesg | tail
   ```

4. **Output Expected**:

   ```
   Initializing platform device and driver
   my_platform_driver: probe called for device my_device
   ```

5. **Remove Module**:

   ```bash
   sudo rmmod platform_device_driver
   dmesg | tail
   ```

   Output:

   ```
   my_platform_driver: remove called for device my_device
   Exiting platform device and driver
   ```

---

### 3.4.3 Where It Appears in `/sys`

* `/sys/bus/platform/devices/my_device`
* `/sys/bus/platform/drivers/my_device`

---

### 3.4.4 Differences: Regular Drivers vs Platform Drivers

| Feature                | **Regular Driver (e.g., PCI, USB)** | **Platform Driver**                               |
| ---------------------- | ----------------------------------- | ------------------------------------------------- |
| **Device Discovery**   | Auto-discovered (e.g., PCI scan)    | Must be statically registered or from Device Tree |
| **Bus Type**           | PCI, USB, I2C, etc.                 | `platform_bus_type` (virtual bus)                 |
| **Resources**          | Provided by hardware                | Passed manually (in code or Device Tree)          |
| **Matching Mechanism** | Uses Vendor/Device IDs              | Matches `.name` strings exactly                   |
| **Hotplug support**    | Full support                        | Limited — typically fixed devices                 |
| **Common Usage**       | PCs, plug-and-play devices          | Embedded SoCs, fixed hardware                     |

---

### 3.4.5 Summary

* `platform_device` and `platform_driver` work together using **name-based matching**.
* These are ideal for **non-discoverable devices** such as those in embedded boards.
* The platform bus is a **virtual bus** created by the Linux device model to unify handling of these devices.

---

## 3.5 Code example for `platform_device` and `platform_driver` (using Device Tree):

Excellent — you're diving into the real-world approach used on **embedded systems** today, especially ARM-based SoCs like Raspberry Pi, BeagleBone, i.MX, etc. In those systems, **Device Tree (DT)** is the preferred way to describe hardware.

---

What We’ll Do

We'll re-implement the previous `platform_device` + `platform_driver` example, but this time:

* The device will be described in the **Device Tree**.
* The driver will be written as a **platform driver that uses a compatible string**.
* The binding will happen automatically when the kernel parses the Device Tree and finds a match.

---

### 3.5.1 Architecture Recap (With Device Tree)

```
+------------------+
| Device Tree Blob |
| (compiled .dtb)  |
+--------+---------+
         |
         v
+--------------------------+
| platform_device created  | <-- automatically from DT
+--------------------------+
         |
         v
+--------------------------+
| platform_driver          | <-- matches based on "compatible"
+--------------------------+
         |
         v
|-> probe() is called
```

---

### 3.5.2 Step 1: Device Tree Source

If you're running on real hardware (e.g., BeagleBone, Raspberry Pi), you’d typically modify an overlay or board file.

Here’s an example **Device Tree node** for our driver:

### `my_device.dts` (or added to an existing `.dts` file)

```dts
/ {
    my_device@0 {
        compatible = "myvendor,my-device";
        status = "okay";
    };
};
```

**Note:**

* `compatible` is a string used to match the driver.
* You could add `reg = <0x...>` or `interrupts = <...>` if needed.

Once added, compile it using the Device Tree compiler:

```bash
dtc -I dts -O dtb -o my_device.dtbo my_device.dts
```

Then apply using your platform’s method (e.g., `config.txt` on RPi or u-boot overlay loading).

---

### 3.5.3 Step 2: Platform Driver Code (Using `of_match_table`)

#### `dt_platform_driver.c`

```c
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h> // For Device Tree matching

MODULE_LICENSE("GPL");
MODULE_AUTHOR("You");
MODULE_DESCRIPTION("Platform driver using Device Tree");

/* Device Tree match table */
static const struct of_device_id my_of_match[] = {
    { .compatible = "myvendor,my-device" },
    { } // Null terminator
};
MODULE_DEVICE_TABLE(of, my_of_match);

/* Probe function called when matched */
static int my_dt_probe(struct platform_device *pdev) {
    printk(KERN_INFO "my_dt_driver: probe called for %s\n", pdev->name);
    return 0;
}

static int my_dt_remove(struct platform_device *pdev) {
    printk(KERN_INFO "my_dt_driver: remove called for %s\n", pdev->name);
    return 0;
}

/* Platform driver structure */
static struct platform_driver my_dt_driver = {
    .driver = {
        .name = "my_dt_driver",           // Kernel-internal
        .of_match_table = my_of_match,    // For DT matching
        .owner = THIS_MODULE,
    },
    .probe = my_dt_probe,
    .remove = my_dt_remove,
};

module_platform_driver(my_dt_driver);
```

---

### 3.5.4 Step 3: Build and Insert Module

Use the same Makefile as before:

```makefile
obj-m += dt_platform_driver.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

Then:

```bash
make
sudo insmod dt_platform_driver.ko
dmesg | tail
```

If the device is present in the active DT, you should see:

```
my_dt_driver: probe called for my_device
```

---

### 3.5.5 In `/sys`

With DT and platform driver:

* `/sys/bus/platform/devices/my_device`
* `/sys/bus/platform/drivers/my_dt_driver`
* `/sys/firmware/devicetree/base/my_device@0` (read-only DT blob)

---

### 3.5.6  Summary of Differences (Manual vs Device Tree)

| Feature             | Manual `platform_device` | Device Tree (DT)                   |
| ------------------- | ------------------------ | ---------------------------------- |
| Device registration | Manual in C code         | Described in `.dts` files          |
| Match mechanism     | `.name` string           | `of_match_table` → `compatible`    |
| Flexibility         | Hardcoded                | Easy to modify without recompiling |
| Real-world usage    | Legacy or testing        | ✅ Standard for embedded systems    |
| Device hierarchy    | Must be built manually   | DT auto-creates hierarchy          |

---

