#let fancybold(varna, body) = {
  text(fill: varna, font:"Open Sans", style: "italic", weight: "semibold", body)
}
#let skew(angle,vscale: 1,body) = {
  let (a,b,c,d)= (1,vscale*calc.tan(angle),0,vscale)
  let E = (a + d)/2
  let F = (a - d)/2
  let G = (b + c)/2
  let H = (c - b)/2
  let Q = calc.sqrt(E*E + H*H)
  let R = calc.sqrt(F*F + G*G)
  let sx = Q + R
  let sy = Q - R
  let a1 = calc.atan2(F,G)
  let a2 = calc.atan2(E,H)
  let theta = (a2 - a1) /2
  let phi = (a2 + a1)/2

  set rotate(origin: bottom+center)
  set scale(origin: bottom+center)

  rotate(phi,scale(x: sx*100%, y: sy*100%,rotate(theta,body)))
}
#let fake-italic(body) = skew(-18deg,body)
#set page( background: rotate(24deg,
  text(36pt, fill: rgb("FFCBC4"))[
    $bb(bb("CONFIDENTAIAL"))$ #linebreak() $bb("DRAFT")$
  ]
))
#set par(justify: true)
#set document(title: "RTD1916b Yocto SDK Developer’s Guide", author: "Realtek", description: "v1.0.0", date: datetime.today())
//#set text(font: "Go Mono", lang: "en")
#set text(font: "Open Sans", lang: "en")
#set page(
  numbering: "1",
  number-align: center,
  margin: (top: 1.5in, bottom: 1in, left: 1in, right: 1in),
)
#set heading(numbering: "1.",  )

// Custom styles for notes, tips, and warnings
#let note(body) = block(
  fill: luma(240),
  inset: 1em,
  radius: 4pt,
  width: 100%,
  stroke: 1pt + luma(200),
  align(center + horizon)[
    #text(weight: "bold")[Note:] #h(0.5em) #body
  ]
)

#let tip(body) = block(
  fill: rgb(230, 255, 230),
  inset: 1em,
  radius: 4pt,
  width: 100%,
  stroke: 1pt + rgb(180, 255, 180),
  align(center + horizon)[
    #text(weight: "bold")[Tip:] #h(0.5em) #body
  ]
)

#let warning(body) = block(
  fill: rgb(255, 230, 230),
  inset: 1em,
  radius: 4pt,
  width: 100%,
  stroke: 1pt + rgb(255, 180, 180),
  align(center + horizon)[
    #text(weight: "bold")[Warning:] #h(0.5em) #body
  ]
)

// Title Page
#let Title = fake-italic("Yocto SDK Developer's Guide")
#v(30%)
#align(center)[
  #block(width: 100%)[
    #text(font: "Open Sans", 22pt, weight: "bold")[#Title] \
    #text(2pt)[-------]\
    #text(20pt, weight: "bold", fill: maroon)[*Varna123 B*] \
    #v(1em)
    #text(16pt, fill: maroon )[Version 1.0.0] \
  ]
  #v(20%)
  #image( "rust.png" , width: 15%) // Optional: Add your company/product logo
  #v(1fr)
  #text(12pt)[DayBreak]
]

#pagebreak()

#align(center)[
  #text(fill: black, font:"Open Sans", style: "italic", weight: "semibold")[History]
]

#table(columns:4, align: auto,
    table.header[*Date*][*Version*][*Author*][*Summary*],
    [2024/04/16],[1.0],[ xxx ],[Initial Release],
  )
#pagebreak()

#fancybold(red, "License Information")
#line(length: 100%)

Any information contained in or derived from this electronic message and any attachment (including but not limited to any software development kit ("SDK"), patch, bug-fix, build script, and build instruction; collectively, the "Information") is highly confidential and treated as trade secrets. 
The Information shall be kept confidential, and any disclosure, copying or distribution of the Information without the sender’s consent is strictly prohibited.
If you are not the intended recipient, please notify the sender and delete this electronic message entirely without using, retaining, or disclosing any of its contents. Thank you for your cooperation.
#line(length: 100%)

#pagebreak()
// Table of Contents
#outline()
#pagebreak()
= Introduction to Yocto:

== Overview

The Yocto Project is an open-source collaboration project that provides templates, tools, and methods to help developers create custom Linux-based systems for embedded products. It simplifies and standardizes the process of building a Linux distribution tailored to specific hardware and softwae requirements.

This document helps developers to integrate DayBreak Varna123 B platform support to Yocto via its meta layer. 

This document provides instructions to developers on setting up environment and building installable image from Yocto Project, methods for programming and updating files on Evaluation Module (EVM) board, along with debugging tips and configuration options.

== Purpose of this Guide

The Varna123 B SDK seamlessly integrates with standard Yocto Project 4.0.17 (Kirkstone)
This document explains how to integrate DayBreaK's  custom *meta-daybreaks* layers, which form the Board Support Package (*BSP*), into the Yocto build system for the *Varna123 B* platform. The meta-daybreaks layers include board-specific kernel configurations, device trees, bootloader setups, drivers, and application recipes tailored for Varna123 B platform.

This document provides a step-by-step process to incorporate your meta-daybreaks layers alongside standard Yocto layers and OpenEmbedded sources, ensuring a seamless integration with RTD1916b platform.
The document covers tasks that are associated with development: 

#list(indent: 2em,
[ Add custom software packages and applications ],
[ Modify kernel and bootloader configurations ],
[ Tailor filesystem layouts and image contents ],
[ Support hardware-specific features like NPUs or peripherals ],
)

#list(indent: 2em, 
[Customize and program eMMC],
[Replacing kernel and U-Boot proper FIT images manually],
[ How to use the GPIO/PWM/PCIe/SATA on the platform ],
[ Secure Boot ],
[ Maintenance tasks \( rescue and upgrade modes \) ],
[ Debugging methods and techniques. ],
)

Using the Yocto Project, you will build a complete Linux image customized for Varna123 B hardware. Additionally, the build process can generate an *SDK (Software Development Kit)* that provides cross-compilation tools, libraries, and headers, enabling application developers to build software compatible with the target image.
== Target Audience

This guide is intended for developers familiar with Linux embedded systems who want to:

#list(indent: 2em,
  [ Understand the Yocto build environment structure],
  [ Integrate and maintain custom meta layers for product builds],
  [ Customize kernel, bootloader, and root filesystem configurations],
)

Basic knowledge of Linux command line, cross-compilation, and embedded system concepts is assumed.

== Structure of This Guide

Following this introduction, you will find detailed sections covering prerequisites, source acquisition, meta layer integration, building bootloader and kernel, customizing images, and advanced topics such as NPU support and root filesystem management.

#pagebreak()

= Target Platform Overview: DayBreak Varna123 B

The DayBreak Varna123 B is a powerful platfrom designed for multimedia and embedded applications. It features a quad-core ARM Cortex-XX CPU, delivering strong performance while maintaining energy efficiency, making it suitable for a wide range of consumer electronics, AIoT devices, and industrial systems.

== Key Features of DayBreak Varna123 B:

#list( indent: 1em,
  [ *CPU:* Quad-core ARM Cortex-XX processor, up to XX GHz ],
  [ *GPU:* ARM Mali-XXX GPU supporting OpenGL ES XX and OpenCL X.X],
  [ *Memory Interface:* Supports DDR3 memory for fast and efficient operation],
  [ *Multimedia:* Hardware acceleration for 1080p video decoding and encoding],
  [ *Peripherals:* Includes interfaces such as USB, HDMI, PCIe, UART, SPI, I2C, and SDIO],
  [ *Neural Processing Unit (NPU):* Provides hardware acceleration for AI workloads (depending on variant)],
  [ *Storage:* Supports eMMC, NAND, and SD card storage options ],
)
== Board and BSP Support

For the Varna123 B platform, Yocto builds typically rely on Board Support Packages (BSPs) provided by DayBreak or community maintainers. These BSPs include:

#list(indent: 1em, 
  [ *Kernel source and patches* optimized for Varna123 B hardware],
  [ *Bootloader (U-Boot)* with support for RK-specific initialization and device trees],
  [ *Device trees* describing hardware layout, used for kernel configuration],
  [ *Middleware and drivers* tailored for peripherals and hardware accelerators ],
)

== Integration Considerations

When integrating your meta layers with Yocto for Varna123 B, it is important to:

#list(indent: 2em, 
  [ Use compatible kernel and bootloader versions aligned with DayBreak BSPs ],
  [ Ensure device tree files correctly describe your hardware variations],
  [ Leverage platform-specific recipes for multimedia, NPU, and hardware interfaces],
  [ Configure partition layouts and filesystem types supported by Varna123 B hardware],
)

