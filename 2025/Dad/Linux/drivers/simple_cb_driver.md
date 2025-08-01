# simple linux driver to demo callbacks via sysfs

**simple Linux kernel driver** that:

* Creates a class in `/sys/class/` with a writable attribute.
* Implements **two callbacks** that trigger when `"yes"` or `"no"` is written into the sysfs attribute.
* Includes a full explanation of **how sysfs callbacks work** in the kernel.

---

## **Goal Recap**

We’ll write a driver that:

* Registers a device class.
* Adds a writable attribute file (e.g., `/sys/class/simple_cb/control`).
* If user writes `"yes"`, callback A runs.
* If user writes `"no"`, callback B runs.

---

## 📄 Step-by-Step Driver Code

```c
// simple_cb_driver.c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/string.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("OpenAI");
MODULE_DESCRIPTION("Simple sysfs callback driver");
MODULE_VERSION("1.0");

static struct class *simple_class;
static struct device *simple_device;

static void on_yes(void)
{
    pr_info("Callback: YES was triggered!\n");
}

static void on_no(void)
{
    pr_info("Callback: NO was triggered!\n");
}

static ssize_t control_store(struct device *dev,
                             struct device_attribute *attr,
                             const char *buf, size_t count)
{
    if (sysfs_streq(buf, "yes")) {
        on_yes();
    } else if (sysfs_streq(buf, "no")) {
        on_no();
    } else {
        pr_info("Unknown command: '%s'\n", buf);
    }

    return count;
}

// Create writable file: /sys/class/simple_cb/control
static DEVICE_ATTR_WO(control);  // Write-only sysfs attribute

static int __init simple_cb_init(void)
{
    int ret;

    simple_class = class_create(THIS_MODULE, "simple_cb");
    if (IS_ERR(simple_class))
        return PTR_ERR(simple_class);

    simple_device = device_create(simple_class, NULL, 0, NULL, "cbdev");
    if (IS_ERR(simple_device)) {
        class_destroy(simple_class);
        return PTR_ERR(simple_device);
    }

    ret = device_create_file(simple_device, &dev_attr_control);
    if (ret) {
        device_destroy(simple_class, 0);
        class_destroy(simple_class);
        return ret;
    }

    pr_info("Simple callback driver loaded\n");
    return 0;
}

static void __exit simple_cb_exit(void)
{
    device_remove_file(simple_device, &dev_attr_control);
    device_destroy(simple_class, 0);
    class_destroy(simple_class);
    pr_info("Simple callback driver unloaded\n");
}

module_init(simple_cb_init);
module_exit(simple_cb_exit);
```

---

## 🔍 How It Works

### sysfs and Callbacks

In Linux, **sysfs** allows kernel drivers to expose attributes (like files) to user space under `/sys`. 
These files can be used to trigger kernel functions.

Here’s what’s happening in the code:

#### 1. `DEVICE_ATTR_WO(control)`

This macro creates a sysfs attribute named `control` that is **write-only** (WO).

It internally defines a function pointer table like this:

```c
struct device_attribute dev_attr_control = {
    .attr = { .name = "control", .mode = 0200 },
    .store = control_store,  // called when user writes to the file
};
```

#### 2. `control_store()`

This is the **callback function**. It's called when a user writes to the attribute:

```bash
echo yes > /sys/class/simple_cb/cbdev/control
```

* `buf` contains the string written.
* `sysfs_streq(buf, "yes")` is used to safely compare the input, trimming newline characters.

#### 3. `on_yes()` and `on_no()`

These are your **custom callbacks** triggered based on input. For now, they just print a message using `pr_info()`.

---

## 🧪 How to Build and Test

### 1. Save the code to `simple_cb_driver.c`

### 2. Compile it:

Create a `Makefile`:

```makefile
obj-m += simple_cb_driver.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

Then:

```bash
make
sudo insmod simple_cb_driver.ko
```

### 3. Test it:

```bash
# Write to sysfs
echo yes > /sys/class/simple_cb/cbdev/control
echo no  > /sys/class/simple_cb/cbdev/control

# Check kernel log
dmesg | tail
```

You should see:

```
Callback: YES was triggered!
Callback: NO was triggered!
```

### 4. Remove module:

```bash
sudo rmmod simple_cb_driver
```

---

## Summary

* Sysfs lets you create user-accessible files that trigger kernel code.
* Each file maps to a function in the driver (`store` for write, `show` for read).
* You wrote two basic **logic callbacks** (`on_yes` and `on_no`) that run depending on what the user types.

---

Would you like to extend this to include:

* Reading state (add `.show`)?
* Count how many times each callback is called?
* Control hardware or GPIOs instead of just printing?

Let me know!



# Build the above driver 

Sure! Here's a **complete project structure** with a `Makefile` to build and test your Linux kernel module (`simple_cb_driver`), suitable for placing into a single directory.

---

## 📁 Project Structure

```
simple_cb_driver/
├── Makefile
└── simple_cb_driver.c
```

---

## 📄 `simple_cb_driver.c`

Paste this into `simple_cb_driver/simple_cb_driver.c`:

```c
// simple_cb_driver.c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/string.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("OpenAI");
MODULE_DESCRIPTION("Simple sysfs callback driver");
MODULE_VERSION("1.0");

static struct class *simple_class;
static struct device *simple_device;

static void on_yes(void)
{
    pr_info("Callback: YES was triggered!\n");
}

static void on_no(void)
{
    pr_info("Callback: NO was triggered!\n");
}

static ssize_t control_store(struct device *dev,
                             struct device_attribute *attr,
                             const char *buf, size_t count)
{
    if (sysfs_streq(buf, "yes")) {
        on_yes();
    } else if (sysfs_streq(buf, "no")) {
        on_no();
    } else {
        pr_info("Unknown command: '%s'\n", buf);
    }

    return count;
}

static DEVICE_ATTR_WO(control);  // Write-only attribute

static int __init simple_cb_init(void)
{
    int ret;

    simple_class = class_create(THIS_MODULE, "simple_cb");
    if (IS_ERR(simple_class))
        return PTR_ERR(simple_class);

    simple_device = device_create(simple_class, NULL, 0, NULL, "cbdev");
    if (IS_ERR(simple_device)) {
        class_destroy(simple_class);
        return PTR_ERR(simple_device);
    }

    ret = device_create_file(simple_device, &dev_attr_control);
    if (ret) {
        device_destroy(simple_class, 0);
        class_destroy(simple_class);
        return ret;
    }

    pr_info("Simple callback driver loaded\n");
    return 0;
}

static void __exit simple_cb_exit(void)
{
    device_remove_file(simple_device, &dev_attr_control);
    device_destroy(simple_class, 0);
    class_destroy(simple_class);
    pr_info("Simple callback driver unloaded\n");
}

module_init(simple_cb_init);
module_exit(simple_cb_exit);
```

---

## 🛠️ `Makefile`

Paste this into `simple_cb_driver/Makefile`:

```makefile
# Makefile for building the simple_cb_driver kernel module

obj-m += simple_cb_driver.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

load:
	sudo insmod simple_cb_driver.ko

unload:
	sudo rmmod simple_cb_driver

reload: unload load

log:
	dmesg | tail -20
```

---

## 🧪 How to Build and Test

Run these from the `simple_cb_driver/` directory:

### 🔨 Compile the module

```bash
make
```

### 📥 Insert the module

```bash
sudo insmod simple_cb_driver.ko
```

### 📂 Write to sysfs

```bash
echo yes > /sys/class/simple_cb/cbdev/control
echo no  > /sys/class/simple_cb/cbdev/control
```

### 🔎 Check kernel logs

```bash
dmesg | tail -20
```

You should see:

```
Callback: YES was triggered!
Callback: NO was triggered!
```

### 🧹 Cleanup

```bash
sudo rmmod simple_cb_driver
make clean
```

---

Let me know if you want to:

* Package it as a `.deb` or `.rpm`
* Add a read-back attribute
* Include a counter or timestamp for each trigger

Happy experimenting!

# use eBPF to check on the program

Let's write a `bpftrace` script to **trace when the sysfs callback is triggered** — specifically, when the user runs:

```bash
echo yes > /sys/class/simple_cb/cbdev/control
```

We'll trace the kernel function that handles this write: the `store` callback, i.e., `control_store()` in your driver.

---

## What We're Tracing

In the kernel driver, the function:

```c
static ssize_t control_store(struct device *dev, ...)
```

gets called on each `echo` write. We want to **trace when `control_store()` is entered** and 
**print the input buffer** (i.e., what was echoed).

---

## bpftrace Script

Here’s the `bpftrace` script:

```bpftrace
#!/usr/bin/env bpftrace

kprobe:control_store
{
    printf("[bpftrace] sysfs control_store() triggered\n");
}

kretprobe:control_store
{
    printf("[bpftrace] control_store() returned: %d\n", retval);
}
```

> **Note**: This assumes your module is compiled with symbols (no `strip`) so that `control_store` is 
  visible. If not, see notes below to trace by address or with `uprobes`.

---

## How to Use

### 1. Run the tracer:

```bash
sudo bpftrace trace_control_store.bt
```

### 2. Trigger the callback:

```bash
echo yes > /sys/class/simple_cb/cbdev/control
```

### 3. Output will look like:

```
[bpftrace] sysfs control_store() triggered
[bpftrace] control_store() returned: 3
```

---

## Alternative: Trace Any sysfs Write

If symbols are stripped or you want a generic way, trace the VFS layer:

```bpftrace
tracepoint:sysfs:sysfs_write_file
/args->dev_name == "cbdev"/
{
    printf("[bpftrace] write to /sys/class/simple_cb/cbdev/%s\n", str(args->attr_name));
}
```

This will match any write to the `cbdev` device's sysfs attributes.

---

## Notes

* `kprobe:control_store` works **only if the symbol is exported and visible**.
* You can confirm symbol visibility with:

  ```bash
  grep control_store /proc/kallsyms
  ```
* If it's not there, rebuild the module **without stripping** or trace via a known kernel interface like `vfs_write`.

---

## Save as Script

Save as `trace_control_store.bt`:

```bash
chmod +x trace_control_store.bt
sudo ./trace_control_store.bt
```

---

Let me know if you want:

* The echoed string (`buf`) printed in trace.
* A trace to include PID or command name of the writer.
* A `perf` or `ftrace` version for older kernels.

Want to go deeper? I can help you write a full `BPF` program too.


NOTE: the above bpftrace would not work as the function we want to trace is not exported to symbol table  in the driver.
