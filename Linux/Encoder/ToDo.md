Extend the current V4L2 framework to support Encoding.

- Overview of kernel V4L2 framework
- M2M framework 
- RTK model
- RTK M2M decoder framework and work flow

- Extend to Encoding similar to RTK decoding 

----
Stage 1: V4L2 framework

Stage 2: how to implement the driver
The document DevTree_registr.md:
    Covers some sample temple for what has to be added to the device Tree
    and how to extend the driver to support encoding and decoding aspect.

- Todo : study the current driver layout to extend to support decoding.
Reference can be taken from chips&Media driver in the kernel.

Stage 3:  How to link the driver with the V4L2 Sub-System and extend the framework.

Stage 4: How to extetend the current driver to support Encoding.

---

ToDo At Bharat:

1. 
Try to Implement a SW based codec m2m v4l2 driver on  Linux.

- This would help to understand the current v4l2 framework.
- M2M framework for using as Encoder or Decoder. 
- How to Implement a M2M Codec. 
    - Implement a m2m codec which takes decoded frame from user space and pass it back to user-space
      or over rpc to a remote device and pass back the encoded frame.

2. 
- Study the Coda/wave5 driver and rtk_vdec driver.

3. 
Rust:
    - Finish Rust book and embedded rust.
    - Jump start with some sample project with rust.

4. Presentation with Rust:
    - Embedded Rust
    - eBPF + Rust 

----------
07/15:

- V4L2 Core 
    - framework 
    - m2m  Sub-System
    - Structures and API used  for drivers to leverage the v4l2 sub-system..
    - Structures and APIs used for encoding and decoding
