# ARM Multi Stage Boot Process (From Power-On)

 **ARM boot process** from **power-on** to the point where your system starts running the **bootloader** 
 (like U-Boot or GRUB). This explanation will be **beginner-friendly** and build up your understanding 
 step by step.

---

## ARM Boot Process 

When an ARM system powers on, it doesn't go straight to Linux or Android. 
It first runs through a **multi-stage boot process** to initialize hardware, load firmware, and finally 
reach the main bootloader.

Here’s the basic journey:

---

### 1. Power On / Reset

* The CPU starts running **very basic firmware** from **ROM**.
* This ROM code is **hardcoded** by the chip manufacturer (like Broadcom, Rockchip, etc.).
* This first step is sometimes called:

> **BL0** or **ROM code**

---

### 2. First Stage Bootloader (BL1)

* Purpose: Initialize **basic hardware** like DRAM (RAM), clocks, etc.
* Loads the **next stage** of the firmware into RAM.
* Still runs in a secure environment.

> **BL1** = "Boot Loader stage 1"

> Think of it as a tiny helper to prepare for the bigger bootloader.

---

### 3. Second Stage Bootloader (BL2)

* Runs after BL1, with RAM ready.
* Loads the next binaries: `BL31`, `BL32`, and `BL33` into memory.
* Checks security settings (like signature verification for secure boot).

> **BL2** = "Boot Loader stage 2"

---

### 4. EL3 Runtime Firmware (BL31)

* This is the **Trusted Firmware**.
* Runs at the **highest privilege level** (EL3).
* Manages the **secure/non-secure split** using ARM **TrustZone**.
* Hands off control to:

  * Secure OS (like OP-TEE, optional)
  * The main bootloader (U-Boot, Linux, etc.)

> **BL31** = Secure Monitor / Trusted Firmware Runtime

---

### 5. Secure OS (Optional - BL32)

* Runs in the **Secure World**, at EL1.
* Examples: **OP-TEE** (a secure OS for trusted applications)
* Only needed if you're doing things like secure payments, DRM, etc.

> **BL32** is optional and only used for extra security services.

---

### 6. Bootloader (BL33)

* This is the **main bootloader** — runs in the **Normal World**.

* Examples:

  * **U-Boot** (common in embedded systems)
  * **GRUB** (in servers)
  * **Little Kernel (LK)** or **fastboot** (in Android)

* Loads the final **operating system kernel** (Linux, Android, etc.)

> **BL33** = Main Bootloader (non-secure)

---

### 7. Operating System

* Once the bootloader finishes, it runs the **OS kernel**.
* The OS can now boot user apps and manage the full system.

---

## Visual Summary

```
[Power On / Reset]
       ↓
[BL0 - ROM Code]
       ↓
[BL1 - First Bootloader]
       ↓
[BL2 - Loads firmware and bootloader]
       ↓
[BL31 - Trusted Firmware (Secure Runtime at EL3)]
       ↓
[BL32 - Secure OS (optional)]
       ↓
[BL33 - Bootloader (e.g., U-Boot)]
       ↓
[Operating System (Linux, Android, etc.)]
```

---

## Analogy

Think of this like **starting a car**:

1. **Turn key (BL0)** — starts the basic electronics.
2. **Engine ignition (BL1/BL2)** — prepares the car to run.
3. **Car computer startup (BL31)** — configures systems, security checks.
4. **Driver dashboard (BL33)** — bootloader gets ready.
5. **Drive off (OS)** — the OS takes control and drives everything.

---

## Summary of Stages

| Stage | Name         | Role                       | Runs At    |
| ----- | ------------ | -------------------------- | ---------- |
| BL0   | ROM Code     | Power-on code, loads BL1   | Vendor ROM |
| BL1   | First Stage  | Initializes RAM, loads BL2 | Secure     |
| BL2   | Second Stage | Loads BL31, BL32, BL33     | Secure     |
| BL31  | Runtime FW   | Trusted Firmware (EL3)     | EL3        |
| BL32  | Secure OS    | Secure services (optional) | EL1-S      |
| BL33  | Bootloader   | Loads and runs the OS      | EL2/EL1    |

---


## Related Documents from ARM

If you're diving into ARM boot and firmware design, these are helpful:

| Document Name                             | ID         | What It Covers                                      |
| ----------------------------------------- | ---------- | --------------------------------------------------- |
| **Trusted Board Boot Requirements**       | DEN0006C   | Secure boot process, image authentication           |
| **Firmware Design Guide for ARMv8-A**     | DEN0024    | Architecture of boot firmware, ELs, TrustZone       |
| **ARMv8-A Architecture Reference Manual** | DDI0487    | Technical spec of exception levels, registers, etc. |
| **ARM Trusted Firmware-A Documentation**  | *(online)* | Open-source implementation (BL1–BL33)               |

---

### Where to find this info

* **TF-A documentation site (open-source)**
  [https://trustedfirmware-a.readthedocs.io/](https://trustedfirmware-a.readthedocs.io/)

* **ARM Developer site (official specs)**
  [https://developer.arm.com/documentation/](https://developer.arm.com/documentation/)

You can search for:

* **DEN0006C (TBBR spec)**
* **Trusted Firmware-A documentation**
* **Firmware Design Guide**

###  Tip for Searching

Use Google or your search engine with:

```
site:developer.arm.com DEN0006C
```

or:

```
"Trusted Board Boot Requirements" ARM
```

If you want, I can walk you through how this works on a specific board like Raspberry Pi, Rockchip, or a 
virtual ARM environment like QEMU. Just ask!


---------------------------------------------------------------------------------------------
# Raspberry Pi Boot Process ( Pi3 or 4)

The **boot process of a Raspberry Pi (especially Raspberry Pi 3 or 4)** step by step — 
from **power-on** to the point where the OS starts — and compare it to the **standard ARM Trusted Firmware 
flow (BL1 → BL2 → BL31 → BL33, etc.)**.

> Raspberry Pi **does not exactly follow the standard ARM Trusted Firmware-A (TF-A) flow**, because 
it's a special platform designed to be simple, but the ideas are similar. Let’s explore how it works.

---

## Raspberry Pi Boot Flow (Raspberry Pi 3/4)

```
[1] SoC ROM Bootloader (1st Stage)
[2] bootcode.bin (2nd Stage)
[3] start.elf (GPU Firmware)
[4] config.txt and cmdline.txt (Configuration)
[5] kernel8.img / kernel.img (ARM64/ARM32 OS Kernel)
[6] initramfs, rootfs, etc.
```

Let’s break it down.

---

### Step 1: **Power On + SoC Boot ROM (1st Stage)**

* The **Broadcom SoC (BCM2837 / BCM2711)** has a built-in **ROM**.
* This **reads the SD card’s first FAT partition** and looks for:

  ```
  bootcode.bin
  ```

This is like **BL1** in the TF-A model — it's the very first thing that runs, but **burned into the chip**.

---

### Step 2: **bootcode.bin (2nd Stage Bootloader)**

* Runs on the **VideoCore GPU**, not the ARM CPU.
* Initializes **SD card**, **memory**, **USB**, and loads the next firmware:

  ```
  start.elf
  ```

This is like **BL2** — it's loading the next stage of the boot process.

---

### Step 3: **start.elf (GPU Firmware + Boot Manager)**

* Also runs on the **GPU**, not the ARM CPU.
* Handles:

  * Config files (`config.txt`, `cmdline.txt`)
  * Splitting memory between GPU and CPU
  * Optional loading of overlays (device tree)
  * Finally, it **loads the ARM CPU kernel** into RAM.

This is roughly equivalent to **BL31 + BL33 combined**, though it’s **not** standard TF-A and **not open source**.

---

### Step 4: **Configuration Files**

* Located in the SD card's **FAT boot partition**:

  * `config.txt` – controls firmware behavior (GPU memory split, overclocking, enabling UART, etc.)
  * `cmdline.txt` – passed as command-line arguments to the Linux kernel

---

### Step 5: **kernel8.img (or kernel.img)**

* This is the **actual OS kernel** — usually Linux.

  * `kernel8.img` = 64-bit kernel (AArch64)
  * `kernel.img` = 32-bit kernel (AArch32)

This is what would be **BL33** in the standard ARM TF-A model.

---

### Step 6: **Linux Kernel Boot + User Space**

* The kernel initializes hardware, mounts root filesystem, and starts **init system** (like systemd or init).
* At this point, you're in the **Linux OS**.

---

## Raspberry Pi Boot Flow vs ARM Trusted Firmware Flow

| Stage | Raspberry Pi             | Standard ARM (TF-A)       | Notes                                     |
| ----- | ------------------------ | ------------------------- | ----------------------------------------- |
| BL1   | SoC ROM Code             | BL1 (in ROM)              | Both are in-chip boot ROMs                |
| BL2   | bootcode.bin             | BL2                       | Loads firmware, prepares environment      |
| BL31  | start.elf                | BL31 (EL3 Runtime)        | Not ARM standard; handled by GPU firmware |
| BL33  | kernel8.img / kernel.img | BL33 (bootloader/kernel)  | Direct boot into kernel or U-Boot         |
| BL32  | (not used)               | BL32 (optional secure OS) | Secure world not used by default          |

---

## Can You Use Trusted Firmware-A on Raspberry Pi?

* **Raspberry Pi does NOT use TF-A by default**, but...
* **Advanced users** can build a custom boot flow using **TF-A + U-Boot + Linux**, especially on Pi 3 and Pi 4 (64-bit capable).
* Projects like [ARM Trusted Firmware for Raspberry Pi 3](https://github.com/ARM-software/arm-trusted-firmware/tree/master/plat/rpi3) exist for experimenting.

> But this is **not required** for most use cases. The GPU handles booting on the Pi for simplicity.

---

## Summary

* Raspberry Pi uses a **GPU-first boot process**, where the **VideoCore GPU boots the system and loads the kernel**.
* It doesn’t use standard ARM TF-A boot stages, but the concepts (initial ROM, staged firmware, kernel loading) still apply.
* For normal users, you just need `bootcode.bin`, `start.elf`, and `kernel8.img`.
* For advanced users, it's possible to replace this with a **TF-A + U-Boot** boot flow.

---

--------------------------------------------

# **Boot process on a Rockchip-based board** (like **RK3399**, **RK3328**, or **RK3568**)

The **boot process on a Rockchip-based board** (like **RK3399**, **RK3328**, or **RK3568**), 
- from **power-on** to **Linux boot** — and compare it with the **ARM Trusted Firmware-A (TF-A)** stages.

Unlike Raspberry Pi, Rockchip **does follow** the **standard ARM Trusted Firmware-A flow**, so this example 
will help you see a real-world implementation of the BL1 → BL2 → BL31 → BL33 model.

---

## Example Target: **Rockchip RK3399** (used in Pinebook Pro, Rock Pi 4, etc.)

---

Boot Flow Overview

```
[1] SoC Boot ROM (BL1)
[2] MiniLoader / SPL (BL2)
[3] Trusted Firmware-A (BL31)
[4] U-Boot (BL33)
[5] Linux Kernel (vmlinuz + DTB)
```

Let's go step by step.

---

## Step 1: **Power-On + SoC Boot ROM (BL1)**

* This is **hardcoded into the Rockchip SoC** (like RK3399).
* It runs from **internal ROM**, and it:

  * Looks for a bootloader on **SPI NOR**, **eMMC**, **SD**, or **USB OTG**.
  * Loads the **next boot stage**: typically **`idbloader.img`** from sector 64 on the boot device.

Equivalent to: **BL1** in ARM TF-A.

> You can’t change this — it's built into the chip.

---

## Step 2: **MiniLoader / SPL (BL2)**

* This is the **first-stage loader** stored in:

  ```
  idbloader.img
  ```
* It typically contains:

  * **DDR initialization code** (since RAM isn't usable yet)
  * **TFA/BL31** (EL3 runtime firmware)
* It’s a combination of:

  * **DDR init binary** (Rockchip-provided)
  * **TF-A SPL** (boot stage that loads BL31)

Equivalent to: **BL2** in ARM TF-A

---

## Step 3: **Trusted Firmware-A (BL31)**

* This is the **EL3 runtime firmware** from ARM TF-A.
* Responsible for:

  * **Switching to the non-secure world**
  * Handling **Secure Monitor Calls (SMCs)**
  * Optionally loading a secure OS (BL32, like OP-TEE)
* It hands off to U-Boot (BL33).

Equivalent to: **BL31** in ARM TF-A

> This is a **standard TF-A binary** that can be built from source for Rockchip platforms.

---

## Step 4: **U-Boot (BL33)**

* This is the **main bootloader**, loaded by TF-A (BL31).
* U-Boot:

  * Initializes more hardware (USB, network, etc.)
  * Loads the **Linux kernel, initramfs, and device tree**
  * Handles boot menus or recovery if enabled

Equivalent to: **BL33** in TF-A model

> Can be configured to load kernel via extlinux, boot.scr, or direct boot.

---

## Step 5: **Linux Kernel**

* The kernel image is loaded into memory by U-Boot.
* Device Tree (.dtb) and optional initramfs are also loaded.
* The Linux kernel takes over, mounts rootfs, and launches user space.

This is where the OS starts.

---

## Boot Image Files (on SD/eMMC)

On most Rockchip boards, you’ll see these files when preparing a bootable image:

| File                   | Purpose                                   |
| ---------------------- | ----------------------------------------- |
| `idbloader.img`        | Contains DDR init + SPL (BL2)             |
| `uboot.img`            | U-Boot (BL33)                             |
| `trust.img`            | Contains BL31 (TF-A runtime)              |
| `boot.img`             | Linux kernel + initramfs (Android format) |
| `kernel.img` / `Image` | Raw Linux kernel                          |
| `rootfs.img`           | Root filesystem (ext4 or squashfs)        |

> These are usually written to disk using tools like `dd` or flashed with **rkdeveloptool**.

---

## Rockchip Boot Flow vs TF-A Model

| Stage | Rockchip Name | ARM TF-A Name | Description          |
| ----- | ------------- | ------------- | -------------------- |
| BL1   | SoC Boot ROM  | BL1           | Hardcoded ROM loader |
| BL2   | idbloader.img | BL2           | SPL + DDR init       |
| BL31  | trust.img     | BL31          | EL3 runtime firmware |
| BL33  | uboot.img     | BL33          | Main bootloader      |
| —     | kernel.img    | Linux kernel  | Final OS             |

---

## Flash Layout (for SD card or eMMC)

On Rockchip devices, boot components are **written to fixed sectors**:

| Component       | Offset (sector) | Notes                      |
| --------------- | --------------- | -------------------------- |
| `idbloader.img` | 64              | Contains SPL/DDR init      |
| `uboot.img`     | 16384           | U-Boot proper              |
| `trust.img`     | 24576           | Contains BL31 (TF-A)       |
| `boot.img`      | Varies          | Linux kernel and initramfs |

---

## Building Bootloader Stack (for Developers)

You can build all of this from source:

1. **Build ARM Trusted Firmware (BL31)**

   ```bash
   make PLAT=rk3399 bl31
   ```

2. **Build U-Boot (BL33)**

   ```bash
   make rock-pi-4-rk3399_defconfig
   make
   ```

3. **Pack Images**

   ```bash
   tools/mkimage -n rk3399 -T rksd -d idbloader.img out.img
   cat uboot.img >> out.img
   ```

Or use Rockchip's **`mkimage`** and **`rkbin` tools** to generate:

* `trust.img` (for BL31)
* `loader.img` (full bootloader blob)

---

## Summary

Rockchip uses a **standard ARM TF-A boot architecture**, unlike Raspberry Pi:

* Boot ROM → SPL (BL2) → TF-A (BL31) → U-Boot (BL33) → Linux
* Uses **ARM Trusted Firmware-A** for security and world switching
* Developers can build or replace each stage
* Much more "open" and standard-compliant than the Pi boot model

---

