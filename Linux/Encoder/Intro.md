# V4L2: Video4Linux 
---

- V4L2 is a collection of device drivers and APIs for supporting realtime video capture on linux systems

- support many types of audio-video devices:
    - webcams, tv tuners, related devices.

- the V4L2 subsystem standardizies there o/p allowing programmers to easily add video support to there 
applications.

- Video4Linux is responsible for creating V4L device nodes ( /dev/videoX, /dev/vbiX, /dev/radioX ) and 
tracking data from these nodes.

- Device node creation is handled by V4L device drivers using "struct video_device" ( v4l2-dev.h )
and it can be either be allocated dynamically or embedded in another large structure.

V4L was introduces in 2.1.x and dropped in 2.6.38 to be replaced with V4L2 a second version of V4L.

## Overview of the V4L2 driver framework:
---

( documents the important structures provided in V4L2 framework and their relationships )

- V4L2 drivers are complex for its complexity of the HW : most devices have multiple devices interfaced 
to the systemsbus via I2C bus and requires to support many different types of ICs.

- For long the framework was limited to "video_device struct" for creating V4L device node and "video_buf"
for handling the video buffers.

==> All device drivers were required to do setup of device instance and connecting sub-devices themselvs. 
( this added complexity and difficult to refactor code into utility functions shared by all drivers. )


### Structure of a Driver:
---

- All drivers have the following structure:

1. A struct for each device instance containing the device state.  
2. A Way to init and commanding sub-devices ( if-any )
3. Creating V4L2 device node ( /dev/videoX ..) and keeping track of device-node specific data.
4. File handle-specific structs containing per-filehandle data.
5. video buffer handling:
 
    device instances
      |
      +-sub-device instances
      |
      \-V4L2 device nodes
	  |
	  \-filehandle instances

### Structure of Framework:
---

- The framework closely resembles the driver structure: 
    1. A "v4l2_device" struct for the device instance data,
    2. A "v4l2_subdev" struct to refer to sub-device instance.
    3. "video_device" struct stores V4L2 device node data
    4. "v4l2_fh" struct keeps track of filehandle instances.

Note: V4L2 Framework also optionally integrates with the media framework.
If a driver sets the "v4l2_device->mdev" field, sub-devices and video nodes will automatically
appear in the media framework as entities.

### "struct v4l2_device":
---

- Each device instance is represented by a struct v4l2_device (v4l2-device.h).
- Very simple devices can just allocate this struct, but most of the time you would embed this 
struct inside a larger struct.

- You must register the device instance:

	v4l2_device_register(struct device *dev, struct v4l2_device *v4l2_dev);

- Registration will initialize the v4l2_device struct. 
- If the dev->driver_data field is NULL, it will be linked to v4l2_dev.

- Drivers that want integration with the media device framework need to set dev->driver_data manually to point to the 
driver-specific device structure that embed the struct v4l2_device instance.

This is achieved by a dev_set_drvdata() call before registering the V4L2 device instance. 
They must also set the struct v4l2_device mdev field to point to a properly initialized and registered 
media_device instance.

- If v4l2_dev->name is empty then it will be set to a value derived from dev 
(driver name followed by the bus_id, to be precise). 

If you set it up before calling v4l2_device_register then it will be untouched. If dev is NULL, 
then you *must* setup v4l2_dev->name before calling v4l2_device_register.


