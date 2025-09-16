# Stage 2: Linux Kernel Basics

---
### 2.1 Linux Kernel Architecture Overview

**Key Components:**

* **Kernel Space vs User Space:** Kernel handles core OS functions; user space runs apps.

* **Monolithic Kernel:** Linux kernel is monolithic but modular (loadable modules).

* **Subsystems:**

  * Process scheduler
  * Memory management
  * Filesystem (VFS)
  * Networking stack
  * Device drivers

* **Kernel Threads:** Background kernel tasks.

* **System Calls:** Interface between user and kernel space.

---
#### 2.2.1 key Linux kernel subsystems 

Kernel Subsystems Explained

##### 2.2.1.1 **Process Scheduler**

* **Purpose:** Manages the execution of processes by deciding which process runs on the CPU and for how long.
* **How it works:**

  * Uses scheduling algorithms (like Completely Fair Scheduler - CFS) to allocate CPU time fairly.
  * Supports multitasking by rapidly switching between processes.

* **Key Data Structures:** `task_struct` represents each process/thread.

* **Key Concepts:** Process states (running, waiting, stopped), context switching.

---

##### 2.2.1.2 **Memory Management**

* **Purpose:** Manages all memory in the system (RAM and swap).

* **Functions:**

  * Allocating/freeing physical and virtual memory.
  * Paging, swapping, and caching.
  * Maintaining page tables and virtual address spaces.

* **Key Data Structures:**

  * `mm_struct` for process memory descriptor.
  * Page frames, page tables.

* **Mechanisms:**

  * Demand paging.
  * Kernel virtual memory mapping.

---

##### 2.2.1.3 **Filesystem (VFS - Virtual Filesystem Switch)**

* **Purpose:** Provides a unified API for all types of filesystems.

* **How it works:**

  * Abstracts different filesystem implementations (ext4, NFS, FAT).
  * Presents files and directories as a hierarchical tree.

* **Key Structures:**

  * `inode` (represents files).
  * `dentry` (directory entry).
  * `superblock` (filesystem metadata).

* **Mount points:** Kernel can mount multiple filesystems simultaneously.

---

##### 2.2.1.4 **Networking Stack**

* **Purpose:** Provides protocols and mechanisms for network communication.

* **Layers Implemented:**

  * Link Layer (Ethernet, Wi-Fi).
  * Network Layer (IP).
  * Transport Layer (TCP, UDP).

* **Features:**

  * Packet routing, filtering (iptables).
  * Socket API (used by user space programs).

* **Key Data Structures:**

  * `sk_buff` (socket buffer for packets).
  * Protocol control blocks.

---

##### 2.2.1.5 **Device Drivers**

* **Purpose:** Interface between kernel and hardware devices.

* **Role:**

  * Control hardware.
  * Provide access to devices via kernel interfaces (files in `/dev`).

* **Driver Types:**

  * Character drivers (e.g., serial port).
  * Block drivers (e.g., hard drives).
  * Network drivers (e.g., ethernet card).

* **Managed through:** Linux Device Model (our main focus later).

---

##### 2.2.1.6 **Kernel Threads**

* **Purpose:** Background kernel operations without user intervention.

* **Examples:**

  * `kworker` threads that handle deferred work.
  * `kswapd` manages memory swapping.

* **Characteristics:**

  * Run in kernel mode.
  * Can sleep and be scheduled just like user processes.

---

##### 2.2.1.7 **System Calls**

* **Purpose:** Bridge between user space and kernel space.

* **How it works:**

  * User applications invoke system calls (e.g., `read()`, `write()`, `open()`).
  * Kernel validates and executes these privileged operations.

* **Mechanism:**

  * Uses software interrupts/traps.
  * Architecture-specific syscall interface.

---
##### 2.2.1.8 Summary Table

| Subsystem         | Function                                | Key Concepts/Structures         |
| ----------------- | --------------------------------------- | ------------------------------- |
| Process Scheduler | CPU time allocation to processes        | `task_struct`, context switch   |
| Memory Management | Manage RAM, virtual memory, paging      | `mm_struct`, page tables        |
| Filesystem (VFS)  | Unified file interface                  | `inode`, `dentry`, `superblock` |
| Networking Stack  | Network protocols & communication       | `sk_buff`, socket API           |
| Device Drivers    | Hardware control & interface            | Character/block/net drivers     |
| Kernel Threads    | Background kernel tasks                 | `kworker`, `kswapd`             |
| System Calls      | Interface for user-kernel communication | Syscall table, traps            |

---

#### 2.2.2 Code Snippets of the above Subsystems:

These snippets won’t be full kernel modules but are simplified fragments inspired by kernel code to help understand the ideas.



---

##### 2.2.2.1 **Process Scheduler**

```c
// Simplified task_struct example representing a process in the kernel
struct task_struct {
    pid_t pid;           // Process ID
    char comm[16];       // Process name
    int state;           // Running, sleeping, stopped, etc.
    struct task_struct *next; // Pointer to next process in scheduling queue
};

// Simplified function to simulate process state change
void set_process_state(struct task_struct *task, int new_state) {
    task->state = new_state;
    printk(KERN_INFO "Process %s (PID %d) state changed to %d\n",
           task->comm, task->pid, new_state);
}

// In reality, the scheduler switches tasks using context switching and runs the highest priority task.
```

---

##### 2.2.2.2 **Memory Management**

```c
// Kernel allocates memory using kmalloc (like malloc but for kernel)
void example_memory_allocation(void) {
    char *buffer;

    buffer = kmalloc(1024, GFP_KERNEL); // Allocate 1024 bytes in kernel memory
    if (!buffer) {
        printk(KERN_ERR "Memory allocation failed\n");
        return;
    }

    memset(buffer, 0, 1024); // Clear allocated memory

    printk(KERN_INFO "Allocated 1024 bytes at %p\n", buffer);

    kfree(buffer); // Free the allocated memory
}
```

---

##### 2.2.2.3 **Filesystem (VFS)**

```c
// Example: A simple kernel module to create a proc entry (a virtual file in /proc)
// This uses VFS abstractions.

#include <linux/proc_fs.h>

static struct proc_dir_entry *my_proc_file;

static ssize_t my_read(struct file *file, char __user *buf, size_t count, loff_t *ppos) {
    char my_data[] = "Hello from kernel VFS!\n";
    size_t len = sizeof(my_data);

    if (*ppos > 0) // EOF check
        return 0;

    if (copy_to_user(buf, my_data, len))
        return -EFAULT;

    *ppos = len;
    return len;
}

static const struct proc_ops my_proc_ops = {
    .proc_read = my_read,
};

static int __init my_module_init(void) {
    my_proc_file = proc_create("my_vfs_file", 0444, NULL, &my_proc_ops);
    printk(KERN_INFO "Created /proc/my_vfs_file\n");
    return 0;
}

static void __exit my_module_exit(void) {
    proc_remove(my_proc_file);
    printk(KERN_INFO "Removed /proc/my_vfs_file\n");
}
```

---

##### 2.2.2.4 **Networking Stack**

```c
// Simplified: Creating and sending a socket buffer (sk_buff) packet
// Note: Real networking code is complex; this is illustrative only.

#include <linux/skbuff.h>
#include <linux/netdevice.h>

void send_packet_example(struct net_device *dev) {
    struct sk_buff *skb;

    skb = alloc_skb(1500, GFP_ATOMIC); // Allocate socket buffer (1500 bytes)
    if (!skb) {
        printk(KERN_ERR "Failed to allocate skb\n");
        return;
    }

    skb_put(skb, 100); // Add 100 bytes of data (dummy)
    skb->dev = dev;

    printk(KERN_INFO "Sending packet on device %s\n", dev->name);

    dev_queue_xmit(skb); // Transmit the packet
}
```

---

##### 2.2.2.5 **Device Drivers**

```c
// Minimal character device driver example setup

#include <linux/module.h>
#include <linux/fs.h>

static int my_open(struct inode *inode, struct file *file) {
    printk(KERN_INFO "Device opened\n");
    return 0;
}

static int my_release(struct inode *inode, struct file *file) {
    printk(KERN_INFO "Device closed\n");
    return 0;
}

static struct file_operations fops = {
    .open = my_open,
    .release = my_release,
};

static int major;

static int __init my_driver_init(void) {
    major = register_chrdev(0, "mychardev", &fops);
    printk(KERN_INFO "Registered char device with major number %d\n", major);
    return 0;
}

static void __exit my_driver_exit(void) {
    unregister_chrdev(major, "mychardev");
    printk(KERN_INFO "Unregistered char device\n");
}
```

---

##### 2.2.2.6 **Kernel Threads**

```c
#include <linux/kthread.h>

static struct task_struct *my_thread;

int my_thread_fn(void *data) {
    while (!kthread_should_stop()) {
        printk(KERN_INFO "Kernel thread running\n");
        ssleep(5); // Sleep for 5 seconds
    }
    printk(KERN_INFO "Kernel thread stopping\n");
    return 0;
}

static int __init my_init(void) {
    my_thread = kthread_run(my_thread_fn, NULL, "my_kthread");
    if (IS_ERR(my_thread))
        printk(KERN_ERR "Failed to create thread\n");
    else
        printk(KERN_INFO "Kernel thread started\n");
    return 0;
}

static void __exit my_exit(void) {
    if (my_thread)
        kthread_stop(my_thread);
    printk(KERN_INFO "Module exit\n");
}
```

---

##### 2.2.2.7 **System Calls**

```c
// Adding a new system call requires patching kernel (complex process).
// Here's a *simplified* example of how a syscall might look internally:

asmlinkage long sys_hello(void) {
    printk(KERN_INFO "Hello from syscall!\n");
    return 0;
}

// User-space app calls it with syscall number assigned in syscall table.
// Kernel executes sys_hello and prints to kernel log.
```

---

##### 2.2.2.8 Summary

* **Scheduler:** Manages `task_struct` processes and their states.
* **Memory:** Uses `kmalloc` and `kfree` for dynamic allocation.
* **VFS:** Abstracts filesystems; allows creating virtual files in `/proc`.
* **Networking:** Uses `sk_buff` structures for packet handling.
* **Device Drivers:** Registered with file operations for hardware interaction.
* **Kernel Threads:** Special kernel processes for background work.
* **System Calls:** Interfaces between user apps and kernel functions.

---

### 2.2 Kernel Source Code Layout

**Important directories:**

| Directory  | Purpose                            |
| ---------- | ---------------------------------- |
| `arch/`    | Architecture-specific code         |
| `drivers/` | Device drivers                     |
| `fs/`      | Filesystem code                    |
| `include/` | Header files                       |
| `kernel/`  | Core kernel code (scheduling, IPC) |
| `mm/`      | Memory management                  |
| `net/`     | Networking stack                   |
| `scripts/` | Build scripts                      |

---

### 2.3 Kernel Build System

* **Configure kernel**: `make menuconfig` or `make defconfig`
* **Build kernel and modules:** `make`, `make modules`
* **Install kernel:** `make modules_install`, `make install`
* **Reboot into new kernel**

---

### 2.4 Loadable Kernel Modules (LKM)

**Concept:**

* LKMs allow dynamic loading/unloading of kernel code.
* Used for drivers or extensions.

**Key Functions:**

* `module_init()` — registers init function.
* `module_exit()` — registers cleanup function.
* `insmod`, `rmmod` — manually insert/remove modules.
* `lsmod` — lists loaded modules.
* `modinfo` — shows module info.

---

### 2.5 Kernel Logging and Debugging

* `printk()` — Kernel equivalent of `printf()`.
* Log levels: `KERN_INFO`, `KERN_ERR`, etc.
* `dmesg` — read kernel logs.
* Debugging with `kgdb`, `ftrace`.

---

### 2.6 Writing Your First Kernel Module

**Example: Simple Hello World module**

```c
#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A simple Hello World kernel module");

static int __init hello_init(void) {
    printk(KERN_INFO "Hello, Kernel!\n");
    return 0;
}

static void __exit hello_exit(void) {
    printk(KERN_INFO "Goodbye, Kernel!\n");
}

module_init(hello_init);
module_exit(hello_exit);
```

---

### 2.7 Hands-on Exercises

1. Build and insert the Hello World module (`insmod hello.ko`).
2. Check messages via `dmesg`.
3. Remove the module (`rmmod hello`).
4. Modify the module to print current kernel version.
5. Explore `lsmod`, `modinfo` commands.

---

### Suggested Reading & Resources

* [Linux Kernel Newbies](https://kernelnewbies.org/)
* [Kernel Module Programming Guide](https://sysprog21.github.io/lkmpg/)
* [The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/)

---

### Summary of Stage 2 Goals

* Understand kernel architecture and build process
* Be able to write, compile, and load a simple kernel module
* Know how to use kernel logs for debugging

---
