# Media Sub-System: ( & V4L2 )

- The Linux kernel media subsystem is a collection of kernel modules and APIs that provide a framework 
for handling media devices, such as cameras, video capture cards, and audio devices. 

- The media subsystem is responsible for managing the interaction between the kernel and media devices, 
providing a standardized way for user-space applications to access and control these devices.

## Interactions between media subsystem and kernel 

### **1. Device Registration**

* Interaction: Registering a media device with the kernel media subsystem.
* Source file: `drivers/media/media-device.c` (function: `media_device_register()`)

### **2. Device Enumeration**

* Interaction: Enumerating media devices connected to the system.
* Source file: `drivers/media/media-device.c` (function: `media_device_enum_entities()`)

### **3. Entity Creation**

* Interaction: Creating a media entity (e.g., a video device) within a media device.
* Source file: `drivers/media/entity.c` (function: `media_entity_create()`)

### **4. Pad Configuration**

* Interaction: Configuring the pads (input/output ports) of a media entity.
* Source file: `drivers/media/entity.c` (function: `media_entity_setup_link()`)

### **5. Link Establishment**

* Interaction: Establishing a link between two media entities.
* Source file: `drivers/media/entity.c` (function: `media_entity_create_link()`)

### **6. Stream Control**

* Interaction: Controlling the stream (e.g., start/stop) of a media entity.
* Source file: `drivers/media/stream.c` (function: `media_stream_start()`)

### **7. Buffer Management**

* Interaction: Managing buffers for media data transfer.
* Source file: `drivers/media/v4l2-buffer.c` (function: `v4l2_buffer_init()`)

### **8. IOCTL Handling**

* Interaction: Handling IOCTL (Input/Output Control) commands from user-space applications.
* Source file: `drivers/media/v4l2-dev.c` (function: `v4l2_ioctl()`)

### **9. Device File Operations**

* Interaction: Handling file operations (e.g., open, close, read, write) on media device files.
* Source file: `drivers/media/v4l2-dev.c` (function: `v4l2_fop_open()`)

The above are few basic interactions of the many functions provided by the Linux kernel media subsystem. 
The source files mentioned above are in `drivers/media` directory.

## media subsystem components:
---
The media subsystem is divided into several components:

    **Media Controller**
    **Media Entities**: 
    **Media Interfaces**: 

### 1. **Media Controller**: 
This is the core component of the media subsystem, responsible for managing the media devices and 
providing a unified interface to user-space applications. 
The media controller is implemented as a kernel module (`media.ko`).

### 2. **Media Entities**: 
These are the individual media devices, such as cameras, video capture cards, or audio devices. 
Each entity represents a single device or a group of devices that can be controlled together.

### 3. **Media Interfaces**: 
These are the APIs that provide access to the media entities. 
There are several types of media interfaces, including:

    - **Video4Linux (V4L2)**: 
        This is the most commonly used media interface, which provides a standardized API for 
        video capture and output devices.
    - **ALSA (Advanced Linux Sound Architecture)**: 
        This interface provides access to audio devices.
    - **DVB (Digital Video Broadcasting)**: 
        This interface provides access to digital TV devices.

Now, let's dive deeper into V4L2, which is a crucial part of the media subsystem.

## **Video4Linux (V4L2)**

- V4L2 is a set of APIs and kernel modules that provide a standardized interface for video capture and 
output devices. 
- It was introduced as a replacement for the older Video4Linux (V4L) API. 
V4L2 is designed to be flexible, extensible, and easy to use, making it a widely adopted standard in the 
Linux world.

- V4L2 provides a device-independent API, which means that user-space applications can access and 
control various video devices without knowing the specific details of each device. 

This is achieved through a set of ioctl() calls, which allow applications to perform operations such as:

    * Device discovery and enumeration
    * Device configuration (e.g., setting resolution, frame rate, and format)
    * Video capture and playback
    * Control of device-specific features (e.g., brightness, contrast, and zoom)

### V4L2 API parts:

The V4L2 API is divided into two parts:

    **V4L2 Core**
    **V4L2 Subdev**

### 1. **V4L2 Core**: 

Core provides the basic API for video capture and output devices, including device discovery, 
configuration, and control.

### **V4L2 Subdev**: 

V4L2 Subdev provides an additional API for controlling specific sub-devices, such as sensors, lenses, 
or image processing units.

- V4L2 is widely used in various Linux-based systems, including:

* Embedded systems (e.g., cameras, set-top boxes, and smartphones)
* Desktop systems (e.g., webcams, TV tuners, and video capture cards)
* Industrial systems (e.g., machine vision, surveillance, and medical imaging)

In summary, the Linux kernel media subsystem provides a framework for managing media devices, 
and V4L2 is a key component of this subsystem, offering a standardized API for video capture and 
output devices.


## **V4L2 Device Registration with the Media Subsystem**

V4L2 devices get registered with the media subsystem through a series of steps, which I'll outline below.
This process involves initializing the V4L2 device, creating a media device, and registering the device 
with the media subsystem.

### **Step 1: V4L2 Device Initialization**

The V4L2 device driver initializes the device by calling `v4l2_device_register()` 
(defined in `drivers/media/v4l2-dev.c`). This function allocates memory for the V4L2 device structure 
and initializes its fields.

### **Step 2: Media Device Creation**

The V4L2 device driver creates a media device by calling `media_device_create()` 
(defined in `drivers/media/media-device.c`). This function allocates memory for the media device structure 
and initializes its fields.

### **Step 3: V4L2 Device Registration with Media Subsystem**

The V4L2 device driver registers the V4L2 device with the media subsystem by calling 
`media_device_register()` (defined in `drivers/media/media-device.c`). This function adds the media device 
to the media subsystem's device list and initializes the device's media entity.

### **Step 4: Entity Creation**

The V4L2 device driver creates a media entity (e.g., a video device) within the media device by
calling `media_entity_create()` (defined in `drivers/media/entity.c`). 
This function allocates memory for the media entity structure and initializes its fields.

### **Step 5: Pad Configuration**

The V4L2 device driver configures the pads (input/output ports) of the media entity by 
calling `media_entity_setup_link()` (defined in `drivers/media/entity.c`). 
This function sets up the links between the media entity's pads and the media device's pads.

### **Step 6: Link Establishment**

The V4L2 device driver establishes a link between the media entity and the media device by 
calling `media_entity_create_link()` (defined in `drivers/media/entity.c`). 
This function creates a link between the media entity's pads and the media device's pads.

### **Step 7: V4L2 Device Registration with V4L2 Subsystem**

The V4L2 device driver registers the V4L2 device with the V4L2 subsystem by 
calling `v4l2_device_register_subdev()` (defined in `drivers/media/v4l2-dev.c`). 
This function adds the V4L2 device to the V4L2 subsystem's device list.

Here's some sample code to illustrate the registration process:
```c
#include <linux/v4l2-dev.h>
#include <linux/media-device.h>

static int __init my_v4l2_device_init(void)
{
    struct v4l2_device *v4l2_dev;
    struct media_device *media_dev;
    struct media_entity *entity;

    /* Step 1: V4L2 device initialization */
    v4l2_dev = v4l2_device_register(NULL, &my_v4l2_ops);
    if (IS_ERR(v4l2_dev))
        return PTR_ERR(v4l2_dev);

    /* Step 2: Media device creation */
    media_dev = media_device_create(v4l2_dev, "my_media_device");
    if (IS_ERR(media_dev))
        return PTR_ERR(media_dev);

    /* Step 3: V4L2 device registration with media subsystem */
    media_device_register(media_dev);

    /* Step 4: Entity creation */
    entity = media_entity_create(media_dev, "my_video_device");
    if (IS_ERR(entity))
        return PTR_ERR(entity);

    /* Step 5: Pad configuration */
    media_entity_setup_link(entity, 0, media_dev, 0);

    /* Step 6: Link establishment */
    media_entity_create_link(entity, media_dev);

    /* Step 7: V4L2 device registration with V4L2 subsystem */
    v4l2_device_register_subdev(v4l2_dev);

    return 0;
}
```
This code initializes a V4L2 device, creates a media device, registers the V4L2 device with the 
media subsystem, creates a media entity, configures the pads, establishes a link, and registers the 
V4L2 device with the V4L2 subsystem.


