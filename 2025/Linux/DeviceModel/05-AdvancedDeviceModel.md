# Stage 5: Deeper Linux Kernel Device Model Internals

---

## 5.1 What you’ll learn in this stage:

* **Device hierarchy and device parent/child relationships**
* How **kobjects** and **sysfs** are structured in the kernel device model
* Understanding **driver binding and unbinding**
* Device lifecycle and power management hooks
* **Uevents** and hotplug mechanism
* Using **bus types** and custom buses
* Reference counting, device and driver ownership
* Debugging tools for device model (`sysfs`, `debugfs`, `udevadm`)

---

### 5.1.1 Device Hierarchy and Parent/Child Devices

* Every device (`struct device`) has a pointer to its **parent device**.
* Parent-child relations represent hardware topology (e.g., PCI bus → PCI device → child devices).
* Device nodes form a **tree structure** visible in `/sys/devices`.

```c
struct device {
    struct device *parent;
    ...
};
```

---

### 5.1.2 kobjects and sysfs

* `struct device` embeds a `struct kobject`.
* `kobject` represents kernel objects and helps organize them in **sysfs**.
* sysfs files are created relative to a device's kobject, e.g., `/sys/devices/...`.
* Sysfs is a **virtual filesystem** exposing kernel object attributes.

---

### 5.1.3 Driver Binding and Unbinding

* The kernel matches devices with drivers via **bus match callbacks**.
* The driver’s `.probe()` function is called when a match is found.
* `.remove()` is called when device is removed or driver unloaded.
* Drivers can implement `.shutdown()`, `.suspend()`, `.resume()` for power management.

---

### 5.1.4 Device Lifecycle and Power Management Hooks

* Drivers implement optional callbacks for:

  * `suspend()`
  * `resume()`
  * `freeze()`
  * `thaw()`
* These help manage device states during system suspend/resume.

---

### 5.1.5 Uevents and Hotplug

* When devices are added or removed, kernel generates **uevents**.
* User-space tools like `udevadm` listen to these events.
* Device nodes under `/dev` are created dynamically by udev.
* Driver can trigger uevents with `kobject_uevent()`.

---

### 5.1.6 Bus Types and Custom Buses

* Linux kernel organizes devices by buses (PCI, USB, platform, I2C, SPI).
* You can create custom buses by registering a new `struct bus_type`.
* Buses implement their own device/driver match logic.

---

### 5.1.7 Reference Counting and Ownership

* `kobject` and `device` structs use **reference counting** for lifetime management.
* Proper management avoids use-after-free or memory leaks.
* `get_device()` / `put_device()` increment/decrement device references.

---

### 5.1.8 Debugging Device Model

* View device tree with:

```bash
ls /sys/devices/
ls /sys/bus/platform/devices/
```

* Check driver-device bindings:

```bash
udevadm info --query=all --name=/dev/yourdevice
```

* Use debugfs interfaces (if enabled) to trace device model internals.

---

### 5.1.9 Would you like:

* A **code walkthrough of device parent-child relationships and their usage**?
* To dive into **creating a custom bus type**?
* A hands-on **walkthrough of hotplug/uevent handling**?


---

## 5.2  Device Parent-Child Relationships and Their Usage

### 5.2 1. Code Walkthrough: Device Parent-Child Relationships and Their Usage

---

### 5.2.2 Background

* Devices are organized in a **tree** via the `.parent` pointer.
* Parents are usually buses or physical devices that "own" or "contain" child devices.
* This hierarchy is visible in `/sys/devices` and used for power management, device lookup, and hotplug.

---

#### Example: Creating a Parent Device and Adding Child Devices

```c
#include <linux/device.h>
#include <linux/module.h>

static struct device *parent_dev;
static struct device *child_dev;

static int __init parent_child_init(void)
{
    int ret;

    /* Create parent device under the root bus */
    parent_dev = kzalloc(sizeof(*parent_dev), GFP_KERNEL);
    if (!parent_dev)
        return -ENOMEM;

    device_initialize(parent_dev);
    parent_dev->parent = NULL; // Root device has no parent
    parent_dev->bus = &platform_bus_type;
    dev_set_name(parent_dev, "my_parent_device");

    ret = device_add(parent_dev);
    if (ret) {
        kfree(parent_dev);
        return ret;
    }

    /* Create child device */
    child_dev = kzalloc(sizeof(*child_dev), GFP_KERNEL);
    if (!child_dev) {
        device_unregister(parent_dev);
        return -ENOMEM;
    }

    device_initialize(child_dev);
    child_dev->parent = parent_dev;  // Set parent pointer
    child_dev->bus = &platform_bus_type;
    dev_set_name(child_dev, "my_child_device");

    ret = device_add(child_dev);
    if (ret) {
        kfree(child_dev);
        device_unregister(parent_dev);
        return ret;
    }

    printk(KERN_INFO "Parent-child devices created\n");
    return 0;
}

static void __exit parent_child_exit(void)
{
    device_unregister(child_dev);
    device_unregister(parent_dev);
}

module_init(parent_child_init);
module_exit(parent_child_exit);
MODULE_LICENSE("GPL");
```

---

### 5.2.3 What happens?

* `parent_dev` is registered as a root device.
* `child_dev` is registered with `parent_dev` as its parent.
* In `/sys/devices`, you’d see:

```
/sys/devices/my_parent_device/my_child_device
```

* Power management and sysfs paths follow this hierarchy automatically.

---

## 5.3 Creating a Custom Bus Type

### 5.3.1 Creating a Custom Bus Type

---

### 5.3.2 Why create a custom bus?

* To manage your own class of devices and drivers not fitting existing buses.
* Provide your own matching and probing logic.

---

#### Minimal Custom Bus Example

```c
#include <linux/device.h>
#include <linux/module.h>

static int my_bus_match(struct device *dev, struct device_driver *drv)
{
    /* Simple match: device and driver names must match */
    return strcmp(dev_name(dev), drv->name) == 0;
}

static struct bus_type my_bus_type = {
    .name = "mybus",
    .match = my_bus_match,
};

static int __init mybus_init(void)
{
    int ret = bus_register(&my_bus_type);
    if (ret)
        printk(KERN_ERR "Failed to register mybus\n");
    else
        printk(KERN_INFO "mybus registered\n");
    return ret;
}

static void __exit mybus_exit(void)
{
    bus_unregister(&my_bus_type);
    printk(KERN_INFO "mybus unregistered\n");
}

module_init(mybus_init);
module_exit(mybus_exit);
MODULE_LICENSE("GPL");
```

---

### 5.3.3 Adding Devices and Drivers on Custom Bus

```c
/* Device */
struct device mydev = {
    .init_name = "mydevice0",
    .bus = &my_bus_type,
};

/* Driver */
struct device_driver mydrv = {
    .name = "mydevice0",
    .bus = &my_bus_type,
    .probe = mydrv_probe,
    .remove = mydrv_remove,
};
```

* Register devices/drivers with `device_register()` and `driver_register()`.
* Driver's `.probe()` called if `match()` returns true.

---

## 5.4 Walkthrough of Hotplug/Uevent Handling (Pseudocode)

---

###  5.4.1 What is a uevent?

* A kernel notification event emitted when devices appear/disappear.
* Triggers user-space actions (like creating device nodes).

---

### 5.4.2 Pseudocode to Emit a Uevent in Driver

```c
function driver_probe(device dev)
    initialize device resources
    set up device
    // Notify user-space of new device:
    kobject_uevent(&dev.kobj, KOBJ_ADD)
    return 0

function driver_remove(device dev)
    // Notify user-space device is gone:
    kobject_uevent(&dev.kobj, KOBJ_REMOVE)
    cleanup resources
```

---

### 5.4.3 User-Space Response

* `udevd` or `systemd-udevd` listens for kernel uevents.
* When it sees `KOBJ_ADD` with a device path, it applies rules and creates `/dev` entries.
* When it sees `KOBJ_REMOVE`, it deletes device nodes.

---

### 5.4.4 Kernel Flow

1. Device registered → `device_add()`
2. Kernel calls `kobject_uevent()` internally → sends event
3. User-space receives event via netlink socket
4. User-space runs scripts/rules for device setup

---

### 5.4.5 Additional Info

* Drivers can trigger custom uevents with environment variables:

```c
char *envp[] = { "KEY=VALUE", NULL };
kobject_uevent_env(&dev->kobj, KOBJ_CHANGE, envp);
```

* Useful for notifying userspace of state changes.

---

---

### 5.5.5 Summary

| Topic               | Key Point                                         |
| ------------------- | ------------------------------------------------- |
| Device Parent/Child | Devices linked with `.parent` and form sysfs tree |
| Custom Bus          | Allows custom device/driver infrastructure        |
| Uevent/Hotplug      | Kernel-to-user notifications on device changes    |

---
