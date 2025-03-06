# GPON Standards 

GPON (Gigabit Passive Optical Network) relies on a set of standards that define its operation, from 
physical layer specifications to transmission convergence and network management. 

These standards ensure interoperability, scalability, and reliability of GPON deployments. 
The primary standards used in GPON are defined by the **ITU-T (International Telecommunication Union 
    - Telecommunication Standardization Sector)**, and they are as follows:

### 1. **ITU-T G.984 Series: GPON Standards**

The ITU-T G.984 series is the main set of standards for GPON, and it outlines the specifications for both 
the physical and data link layers, as well as the overall architecture of GPON systems.

- **G.984.1**: **General Requirements and Overview**

  - This standard defines the high-level requirements and architecture for GPON. It provides a comprehensive overview of the system, including a description of the OLT (Optical Line Terminal), ONT (Optical Network Terminal), and the optical distribution network (ODN). It also covers the general performance characteristics and operational guidelines.

- **G.984.2**: **Physical Media Dependent (PMD) Layer**
  - Defines the physical layer specifications for GPON, such as the type of optical fiber used, the wavelengths for downstream (1490 nm) and upstream (1310 nm) transmission, and the power budgets. It specifies the characteristics of the optical signal and how it is transmitted over the fiber network.
  
- **G.984.3**: **Transmission Convergence (TC) Layer**
  - Describes the transmission convergence layer, which is responsible for mapping the higher layer frames (Ethernet or ATM) onto the GPON physical layer. This standard handles the segmentation and reassembly of data packets and ensures the proper framing of data for efficient transmission over the optical network.
  
- **G.984.4**: **OMCI (ONT Management and Control Interface)**
  - Defines the management interface between the OLT and the ONT. The OMCI is used for remote management and configuration of the ONT, including tasks like provisioning, diagnostics, firmware updates, and performance monitoring. OMCI ensures that the OLT can control and monitor the operation of the ONT.
  
- **G.984.5**: **Interface for the ONT (Optical Network Terminal)**
  - This part of the standard defines the interface between the ONT and the end user devices, ensuring that the physical connection and communication between the ONT and the end-user network devices are standardized and reliable.

### 2. **ITU-T G.987 Series: 10G-PON (XG-PON)**

The G.987 series extends the GPON standard to provide even higher speeds, known as **10G-PON** or **XG-PON**. This is designed for future-proofing GPON networks to handle increasing bandwidth demands.

- **G.987.1**: Describes the architecture and key components for 10G-PON.
- **G.987.2**: Provides the specifications for the physical layer.
- **G.987.3**: Defines the transmission convergence (TC) layer for 10G-PON.
- **G.987.4**: Extends OMCI for 10G-PON, allowing for remote management and control of the higher-speed ONTs.

### 3. **IEEE 802.3ah: Ethernet in the First Mile (EFM)**

- This standard, also known as **EFM**, is the foundation for Ethernet over passive optical networks (EPON) but is closely related to GPON in terms of providing Ethernet-based services over optical networks.
- While GPON uses ATM or GEM (GPON Encapsulation Method) for data encapsulation, EFM is mainly used for EPON systems, but it still plays a role in the broader landscape of passive optical networking (PON) technologies.

### 4. **ITU-T G.983: BPON (Broadband PON)**

Before GPON, there was **BPON** (Broadband PON), defined by the **ITU-T G.983 series**, which was a predecessor to GPON but is largely outdated now in favor of the higher-speed and more efficient GPON standard. While GPON is not directly based on BPON, some of the concepts and architecture were carried over.

- **G.983.1**: General requirements and overview for BPON.
- **G.983.2**: Defines the physical media dependent (PMD) layer for BPON.
- **G.983.3**: Defines the ATM (Asynchronous Transfer Mode) adaptation layer for BPON.

### 5. **ITU-T G.8080: Architecture for Transport Networks**

Though not specific to GPON, **G.8080** defines the architecture of transport networks, which includes aspects related to GPON in the context of optical network systems. It describes network layering, fault management, and recovery mechanisms that can apply to GPON as part of a larger transport network.

### 6. **ITU-T G.9960: HomePNA and G.hn for GPON**

In some GPON deployments, **HomePNA** and **G.hn** standards can be used for in-home networking. These standards enable high-speed home networking over existing coaxial cable, power lines, or phone lines. They can be used in conjunction with GPON to provide seamless in-home connectivity.

### 7. **ITU-T G.988: ONU (Optical Network Unit) Management and Control Interface (OMCI)**

The **G.988** standard complements **G.984.4**, further detailing the **OMCI** interface. It defines management protocols for remote configuration, diagnostics, monitoring, and maintenance of ONUs in a GPON system. This ensures efficient management and supports different types of ONUs from various vendors in a GPON network.

### 8. **XGS-PON and NG-PON2 (Next-Generation PON)**

The **XGS-PON** and **NG-PON2** standards are the next evolution of PON technology and are related to GPON’s development as they aim to offer higher speeds (10 Gbps and beyond) and more flexible architectures.

- **XGS-PON**: Defines 10Gbps symmetric speeds for both upstream and downstream, making it an ideal choice for symmetric high-bandwidth services.
- **NG-PON2**: The **Next-Generation PON 2** standard aims to provide 40Gbps symmetric bandwidth, using WDM-PON (Wavelength Division Multiplexing) technology, which allows multiple wavelengths to run over a single fiber, increasing network capacity.

### Summary of Key GPON Standards:

- **ITU-T G.984 Series**: Core standards for GPON (includes G.984.1 to G.984.5).
- **ITU-T G.987 Series**: Standards for 10G-PON (XG-PON).
- **IEEE 802.3ah**: Ethernet in the First Mile (related to EPON).
- **ITU-T G.983**: BPON (predecessor to GPON).
- **ITU-T G.8080**: Transport network architecture that includes GPON.
- **ITU-T G.9960**: Home networking standards, relevant to in-home GPON integration.
- **ITU-T G.988**: OMCI for ONU management in GPON networks.

These standards ensure that GPON networks are standardized, interoperable, scalable, and capable of meeting the high-speed broadband demands of modern telecommunications systems.
