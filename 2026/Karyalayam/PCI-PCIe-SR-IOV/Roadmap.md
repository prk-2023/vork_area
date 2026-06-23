# Roadmap from PCI-PCIe-SR-IOV:


Welcome to the world of high-performance hardware virtualization! Going straight into SR-IOV without
understanding basic PCI and PCIe is like trying to learn advanced drift-racing before you know how a
transmission works.

Here is a structured, step-by-step roadmap designed to take you from foundational hardware concepts to the
intricacies of SR-IOV.

---

## The Learning Roadmap: From PCI to SR-IOV

### Phase 1: The Foundations of PCI (The Shared Bus Era)

Before modern high-speed links, there was the classic parallel bus. Understanding this era helps you
appreciate *why* modern PCIe was invented.

* **Key Concepts to Learn:**
* **The Parallel Bus Topology:** How multiple devices shared a single set of wires (wires for data, address,
  and control).
* **The Shared Bus Bottleneck:** Why reflection, clock skew, and electrical loading limited the speed of
  classic PCI.
* **The Host Bridge:** How the CPU talks to the PCI bus.
* **PCI Configuration Space:** The standardized 256-byte memory region every PCI device must implement so
  the OS can discover it (Vendor ID, Device ID, Base Address Registers (BARs)).
* **Memory-Mapped I/O (MMIO):** How the CPU uses BARs to map a device's internal registers directly into the
  system's memory address space.



---

### Phase 2: The Evolution to PCIe (Point-to-Point Power)

PCI Express (PCIe) completely flipped the script by moving from a shared parallel bus to a point-to-point serial network.

* **Key Concepts to Learn:**
* **Point-to-Point Topology:** Links, Lanes ($x1$, $x4$, $x8$, $x16$), and Dual-Simplex communication.
* **The Layered Architecture:**
* *Physical Layer:* Electrical signaling, clock embedding, and encoding.
* *Data Link Layer:* Error checking (CRC) and Ack/Nak packets for reliable delivery.
* *Transaction Layer:* Where the real work happens using **Transaction Layer Packets (TLPs)**.


* **PCIe Extended Configuration Space:** Expanded from 256 bytes to 4096 bytes to accommodate advanced features (like virtualization capabilities).
* **Memory Reads/Writes via TLPs:** How data actually moves across the fabric using non-posted and posted transactions.



---

### Phase 3: Introduction to I/O Virtualization (The Problem Statement)

Before jumping into SR-IOV, you need to understand the historical pain points of virtualizing hardware.

* **Key Concepts to Learn:**
* **Software Emulation:** The Hypervisor traps every I/O access from a Guest VM and emulates a fake device in software (safe, but incredibly slow).
* **Direct Passthrough ( there can be only one ):** Assigning an entire physical PCIe device directly to a single VM. It achieves near-native performance, but no other VM can use that hardware.
* **The Role of the IOMMU (Intel VT-d / AMD-Vi):** How the hardware maps Guest Physical Addresses (GPA) to Host Physical Addresses (HPA) and enforces DMA isolation so a bypassed VM can't corrupt host memory.



---

### Phase 4: Mastering SR-IOV (Single Root I/O Virtualization)

Now you are ready for the peak. SR-IOV bridges the gap between the performance of Direct Passthrough and the sharing capabilities of virtualization.

* **Key Concepts to Learn:**
* **The Core Philosophy:** One physical PCIe device presents itself to the system as multiple, independent PCIe devices.
* **Physical Functions (PF):** The fully-featured PCIe functions that include the SR-IOV capability structure. The host OS/hypervisor uses the PF to configure and manage the device.
* **Virtual Functions (VF):** Light-weight, stripped-down PCIe functions that only handle data movement. These are what you pass directly into the Guest VMs.
* **Routing and Routing IDs (Bus/Device/Function - BDF):** How the PCIe fabric routes TLPs directly to specific VFs using unique Requesters IDs.
* **The Data Path:** How a VM talks directly to a VF's BARs, bypassing the hypervisor entirely for ultra-low latency.



---

## 🛠️ Recommended Hands-On Checkpoints

To make this knowledge stick, try these exercises as you progress:

1. **During Phase 1 & 2:** Run `lspci -vvv` on a Linux machine. Look at the BAR allocations, the Link Speed (e.g., 8GT/s), and the Link Width (e.g., x4).
2. **During Phase 3:** Enable Intel VT-d or AMD-Vi in your BIOS, and try passing a secondary GPU or Network Card directly to a KVM/QEMU virtual machine.
3. **During Phase 4:** Find an SR-IOV capable Network Interface Card (Intel X520/X710 or Mellanox ConnectX are classic examples). Enable SR-IOV in the driver, create 4 VFs, and assign them to 4 different virtual machines.

---

Which phase of this roadmap aligns closest with your current hardware background? If you've already dabbled with `lspci` or basic VM creation, we can skip right into the PCIe layer mechanics!
