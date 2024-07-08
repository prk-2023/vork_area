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

