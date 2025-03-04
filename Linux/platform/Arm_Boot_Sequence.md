# ARM Boot Sequence and ARM Trusted Firmware.

## The ARM Boot Sequence Overview
ARM systems use a **multi-stage boot process**, and the boot stages are generally defined as follows:

1. **BL1 (Bootloader Stage 1)**:

    - **Primary Bootloader**: This is the first stage in the boot process. 
      Its main function is to initialize the system, set up basic memory configuration, and prepare for 
      loading the next bootloader stage (BL2 or sometimes BL31, depending on the platform).

2. **BL2 (Bootloader Stage 2)**:

    - **Secondary Bootloader**: 
      In this stage, the system loads the necessary components required for further stages, such as setting 
      up the boot environment and validating secure keys or configurations for trust. 
      It often loads **BL31** (if the system uses **ATF**).

3. **BL31 (Bootloader Stage 3)**:

    - **ARM Trusted Firmware**: 
      **BL31** is part of the ARM Trusted Firmware (ATF), which provides key security functions and manages 
      secure execution environments on ARM platforms.

    - **Secure Monitor**: 
      BL31 is responsible for entering the **Secure Monitor** mode, which facilitates switching between 
      secure and non-secure worlds. In the ARM architecture, the system can run in two separate execution 
      environments:

        - **Secure World**: 
            This is a trusted environment that manages sensitive operations such as cryptographic services, 
            secure boot, and key management.

        - **Normal World**: 
          This is the regular environment where the operating system (like Linux or Android) runs.

    - BL31 handles the **secure boot process** by ensuring that only trusted firmware and software can run 
      on the system. 
      It also sets up **ARM's TrustZone** technology to isolate the secure and non-secure worlds. 
      This is achieved by managing the **Secure Monitor Call (SMC)** interface and implementing the 
      **ARMv8 Secure EL3** state.

    - **Initializing TrustZone**: 
      BL31 sets up the TrustZone hardware, which partitions the processor's resources into two separate 
      worlds (Secure and Non-Secure). It ensures that secure software can run without interference from 
      non-secure software.

4. **BL32 (Bootloader Stage 4)**:

    - This stage is typically used for loading additional secure software, such as a **secure OS** or 
      other trusted software components, if needed. It's not always used in all ARM boot sequences.

5. **BL33 (Bootloader Stage 5)**:

    - **Non-Secure Bootloader**: BL33 is typically the last stage of the boot sequence that loads the 
      non-secure OS (such as Linux, Android, or another operating system) into the system's memory and 
      begins execution in the non-secure world. This is usually where the main OS kernel is loaded.


### Key Functions of BL31

    - **Secure Boot**: 
        It verifies that the firmware being loaded is trusted and has not been tampered with. 
        This is critical to ensuring that no malicious code can compromise the boot process.

    - **TrustZone Initialization**: 
        BL31 enables the use of ARM’s **TrustZone** technology, which separates secure and non-secure 
        execution environments, allowing for secure operations like cryptographic key management, 
        secure storage, and firmware updates.

    - **Managing Secure World/Normal World Transition**: 
        It manages the transition between the **Secure World** (which executes in the ARM's secure 
        execution level **EL3**) and the **Normal World** (which typically runs in **EL1** or **EL0**). 
        This ensures the secure operation of the system and enforces separation between secure and 
        non-secure resources.

### Summary

    In the ARM boot process, **BL31** is a key stage that deals with **ARM Trusted Firmware (ATF)** and 
    manages **secure boot**, the **Secure Monitor**, and the separation of the **Secure World** and 
    **Normal World** using **TrustZone** technology. 
    It ensures that only trusted code is executed and provides mechanisms for the system to transition 
    securely between different execution environments. 
    It is integral to ARM-based platforms that require robust security and integrity, especially in 
    embedded, mobile, or IoT devices.

---
## ARM Trusted firmware

The code for **BL1**, **BL2**, **BL31**, **BL32**, and **BL33** is typically part of the 
**ARM Trusted Firmware (ATF)**, and this firmware is crucial for managing the boot sequence on ARM-based 
systems.

### Storage and Loading of ARM Trusted Firmware on an ARM SoC

When an **ARM System on Chip (SoC)** powers on, the boot process begins with the execution of code stored 
in specific regions of memory, as determined by the SoC's design. Here's how it generally works:

### 1. **Storage Location of ARM Trusted Firmware**

The ARM Trusted Firmware components (BL1, BL2, BL31, BL32, BL33) are typically stored in non-volatile 
memory (NVM), such as:

    - **On-Chip ROM (Read-Only Memory)**: 
        Many ARM SoCs have a **boot ROM** or **first-stage bootloader (FSBL)** embedded in the chip itself. 

        This is the first piece of code that gets executed upon power-on or reset. 
        The **boot ROM** typically contains BL1 or a very small part of the early bootloader, which is 
        responsible for loading the next stages of the boot process from external storage.

    - **External Flash Memory**: 
        In many systems, the subsequent stages of the bootloader (BL2, BL31, BL32, BL33) are stored in 
        external storage, such as:
            - **NAND flash**
            - **eMMC (embedded MultiMediaCard) storage**
            - **SPI NOR flash**
            - **UFS (Universal Flash Storage)**

      The **external flash** typically holds the complete ARM Trusted Firmware, which is loaded into memory 
      during the boot process. 
      The exact location where the firmware is stored on the external memory depends on the configuration 
      and the system's specific bootloader setup.

### 2. **Loading the Firmware on Power-On**

When power is first applied to an ARM-based SoC, the **boot ROM** or **FSBL** embedded on the chip is the 
first to run. It typically performs the following steps:

#### **BL1 (First Stage Bootloader)**

- The **boot ROM** (on-chip ROM) starts executing, which contains **BL1**. BL1 typically does the following:

    - It initializes basic hardware components (e.g., memory controller, CPU, etc.).
    - It reads the next stage of the bootloader (often **BL2**) from the external storage (e.g., NAND flash, eMMC) and loads it into memory.

#### **BL2 (Second Stage Bootloader)**

- **BL2** is loaded by BL1 into memory, and it performs further initialization. Its key tasks include:

    - Verifying the integrity of the firmware (e.g., using cryptographic hashes or signatures).
    - Setting up a secure boot environment.
    - Loading **BL31** into memory (ARM Trusted Firmware).

#### **BL31 (ARM Trusted Firmware)**

- **BL31** is a core component of ARM Trusted Firmware (ATF), and it is loaded into **high memory** 
    (typically in **DRAM**). Once loaded, **BL31**:

    - Initializes **TrustZone**.
    - Manages the **Secure Monitor** and transitions between the **Secure World** and **Normal World**.
    - Sets up secure boot and handles **SMC (Secure Monitor Calls)**.

    **BL31** can also configure hardware, such as **Power Management** or **Secure Storage**, to ensure 
    secure operations for subsequent stages.

#### **BL32 (Optional)**

- If the system uses a secure operating system or further secure firmware 
(such as a **Trusted Execution Environment (TEE)** like **OP-TEE**), **BL32** is loaded by **BL31**. 
BL32 typically runs in the **Secure World** and provides services like secure cryptography, trusted storage, 
or secure applications.

    - The TEE is loaded from external storage, and its code is typically stored in the same external flash 
      memory or another designated location.

#### **BL33 (Non-Secure Operating System)**

    - **BL33** is the last stage, which loads the **Non-Secure Operating System** (such as Linux, Android, 
      or another OS) into memory and begins execution.

    - BL33 is often referred to as the **normal world bootloader**, and it is responsible for initializing 
      the non-secure environment. The OS kernel is loaded from storage and handed over to the 
      operating system for initialization.

### 3. **Where Is ARM Trusted Firmware Stored and Loaded from?**

    - **On-Chip ROM**: The first part of the boot sequence, such as BL1 (or the boot ROM), is typically 
    stored in the **on-chip ROM** of the SoC. 
    This ROM is non-volatile and remains accessible at power-on, making it the first code that is executed.

    - **External Storage (Flash, eMMC, etc.)**: 
        After the first stage (BL1) loads, the next stages of the bootloader (BL2, BL31, BL32, and BL33) 
        are stored in external memory, which could be:
        - **NAND flash**
        - **SPI NOR flash**
        - **eMMC**
        - **UFS**

    - **DRAM**: When **BL2** and **BL31** are loaded, they are typically placed into **DRAM** (dynamic RAM),
      which is where the system executes the majority of its boot code. 
      This is a high-speed memory that is initialized during the boot process.

### 4. **Summary of the Loading Process:**

    1. **Power-On**: When the SoC powers on, the **on-chip boot ROM** is executed (BL1).
    2. **BL1** loads **BL2** from external storage (flash memory).
    3. **BL2** may verify and load **BL31** (ARM Trusted Firmware) into DRAM, along with any optional 
       **BL32** (TEE or secure OS).
    4. **BL31** initializes **TrustZone**, the **Secure Monitor**, and transitions to the **Normal World** 
       (BL33).
    5. **BL33** loads the main operating system (e.g., Linux or Android) into memory and begins execution.

### Conclusion

- **BL1** is typically stored in the **on-chip ROM** of the SoC, while the remaining stages 
  (BL2, BL31, BL32, BL33) are stored in **external flash memory** (e.g., NAND, eMMC, or SPI NOR flash).

- The firmware is loaded from this external storage into **DRAM** for execution.

- **ARM Trusted Firmware (ATF)**, which contains **BL31**, plays a crucial role in managing the 
  secure boot process, initializing TrustZone, and transitioning between the secure and non-secure worlds 
  on ARM platforms.

## Firmware execution time till u-boot bootloader.

The time it takes for **ARM firmware** (such as **BL1**, **BL2**, **BL31**, etc.) to reach and load the 
**U-Boot bootloader** (or any other bootloader like a **non-secure OS kernel**) can vary depending on 
several factors, including the **SoC** (System on Chip) design, **firmware optimizations**, and 
**hardware configurations**. 

However, a typical timeframe for this process is usually in the range of **500 milliseconds to 2 seconds**.

### Breakdown of the Boot Process and Timing:

1. **BL1 (Bootloader Stage 1)**: 

    - **Time Taken**: Typically **< 1 second**.
    - **Function**: BL1 is the first stage in the ARM boot process, which is usually stored in the 
      **on-chip ROM** of the SoC. It performs basic hardware initialization (e.g., memory controller) and 
        reads the next stage (usually **BL2**) from external storage (like **NAND**, **eMMC**, or 
        **SPI flash**). The time for this step is very short because it's minimal code executed directly 
        from the ROM.

2. **BL2 (Bootloader Stage 2)**:
   - **Time Taken**: Typically **< 1 second**.
   - **Function**: BL2 is typically loaded from **external storage** by BL1 and is responsible for initializing the system further, verifying firmware integrity, and loading **BL31** (ARM Trusted Firmware). The time taken to load **BL31** is dependent on the speed of the external storage, but it generally doesn't take more than 1 second.

3. **BL31 (ARM Trusted Firmware)**:
   - **Time Taken**: Typically **< 1 second**.
   - **Function**: BL31 initializes the **ARM TrustZone**, configures the **Secure Monitor** for switching between Secure and Non-Secure worlds, and sets up any necessary secure boot protocols. This stage is typically executed in **DRAM**, so it takes a very short time to initialize before transitioning to the next bootloader (either **BL32** or **BL33**). It is relatively lightweight and optimized for fast execution.

4. **BL33 (Non-Secure Bootloader, typically U-Boot)**:
   - **Time Taken**: This is the most variable stage depending on the implementation of U-Boot and any additional initialization it performs. **U-Boot** itself typically takes a few hundred milliseconds to a second to load, depending on the hardware configuration, device initialization, and boot configuration (e.g., loading environment variables, peripheral setup, etc.).

   - **For U-Boot**, the time spent here is usually a few hundred milliseconds up to 1 second, depending on how much it needs to initialize. The time also depends on whether U-Boot is loaded from **eMMC**, **SPI flash**, or **NAND**, as the speed of these devices affects the time required for the bootloader to load.

### Overall Time from Power-On to U-Boot:

- The **total time** from power-on until U-Boot begins execution (after all the stages of ARM firmware are loaded) is typically in the range of **500 ms to 2 seconds** in most ARM-based systems.
  
### Key Factors That Affect Boot Time:

- **Storage Speed**: The speed of the **external storage** (e.g., NAND flash, eMMC, SPI flash, or UFS) plays a critical role in how quickly the firmware stages are loaded into memory. Faster storage will lead to faster boot times.
  
- **SoC Design and Firmware**: The specific SoC (like Qualcomm Snapdragon, NXP i.MX, or Broadcom BCM series) and the optimizations in the ARM Trusted Firmware (ATF) influence how quickly the boot sequence can proceed.

- **Peripheral Initialization**: Some ARM platforms may include extensive peripheral initialization in the early boot stages, which can slightly increase the time before the system reaches U-Boot.

- **Secure Boot**: Platforms using **secure boot** mechanisms (like ARM TrustZone) might add a bit of overhead in the process of verifying firmware signatures or other security checks.

### Example Boot Times:

- **Typical ARM Platform with Secure Boot**: On a typical embedded ARM platform with **ARM Trusted Firmware** and **U-Boot**, the firmware stages (BL1, BL2, BL31) typically take less than **1 second** combined, with **U-Boot** loading within the next **500 ms to 1 second**.
  
- **High-End ARM Platforms (e.g., Qualcomm or Samsung SoCs)**: On more complex ARM platforms like those used in smartphones or high-performance systems, the process may take closer to **2 seconds** due to additional security checks, peripheral initialization, or more complex hardware setups.

### Conclusion:
On a typical ARM-based platform, the entire process from **power-on** to the point where **U-Boot** or a similar bootloader begins execution usually takes around **500 milliseconds to 2 seconds**. The majority of the time is spent loading **ARM Trusted Firmware** (BL1, BL2, and BL31), with minimal time required to load the U-Boot bootloader itself, which can take an additional **500 milliseconds to 1 second** depending on the storage and hardware configuration.
