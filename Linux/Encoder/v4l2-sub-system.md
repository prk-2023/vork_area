# V4L2 Sub-System:

- V4L2:

The Linux kernel's V4L2 (Video for Linux 2) subsystem is a set of APIs and drivers that provide a 
standardized way for applications to access and control video capture devices, such as webcams, 
TV tuners, and video encoders.

The V4L2 subsystem is responsible for managing the interaction between the kernel and user-space 
applications that want to capture or output video streams.

    [ Applications ] <==> [ /dev/videoX ] <==> [V4L2 Layer] <==> [ V4L2 kernel driver ]


V4L2 - set of APIs and standards for handling video devices on Linux. 
- Video devices could be camera sensors providing streams, video encoder , video decoder and apart from 
these there could be analog radio and any output drivers as device. 
- These v4l2 devices are char type device and each devices get represented by its names in the /dev
tree like /dev/video. If there are multiple devices or video related data, streams then there can be 
multiple video device names like /dev/video0 , /dev/video1 , basically /dev/videoX. 

- Since it provides set of APIs to handle these devices which lies in physical memory region of the 
system and get juice from kernel. 

- V4L2 gets integrated with media framework and resides in kernel as v4l2 driver ,helps to integrate 
the device/sub-device kernel driver with the media framework. 

- V4L2 API includes a very long list of driver callbacks to respond to the many ioctl() commands made 
available to user space.

User Space:                            [ Open (/dev/videoX)]
----------------------------------------------|------------------------------------------
Kernel                                        |
                                              |
                                              v
                  video_device.cdev.fops= v4l2_file_ops  -> video_device[0]=vdev0,video_device[1]=vdev1
                                              |
                                              |
                                              v 
                 struct v4l2_subdev < ------vdev->fops ------------+
                    |                           |videoioc_dqbuf    |
                                                v                  |
                                            dqueue_list         queue_list
                                                |                  |
                                                v                  v
                                              buffer1            buffer1
                                                |                  |
                                                v                  v
                                              buffer2            buffer2
                                                |                  |
                                                v                  v
                                              bufferN            bufferN
                                                 |                  |
                                                 |                  |
                                 save data       v                  v get buffer
                                 put buffer  +-------------------------+
                                 to the list | data processing module  |
                                             +-------------------------+



Kernel Side V4L2 Operations : -
a) Opening V4L2 device using v4l2_open()
b) Controlling V4L2 device using v4l2_ioctl()
c) Reading from V4L2 device using v4l2_read()
d) Writing onto V4L2 device using v4l2_write()
e) Polling onto V4L2 device using v4l2_poll()
f) Mmaping v4L2 device using v4l2_mmap()
g) Closing V4L2 device using v4l2_release()

for ex:
    ``` fd = open("/dev/video0", O_RDWR);
        close(fd)
    ```

V4L2 ioctl : 
    a)VIDIOC_S_FORMAT
    b)VIDIOC_S_CTRL
    c)VIDIOC_REQBUFS
    d)VIDIOC_QUERYBUF 
    e)VIDIOC_QBUF 
    f)VIDIOC_STREAMON 
    g)VIDIOC_DQBUF 
    h)VIDIOC_STREAMOFF

- [Application] 
   -> [Open device /dev/video0]
     -> [VIDEO_QUERYCAP]
       -> [VIDIOC_S_INPUT]
         -> [VIDIOC_REQBUF]
           -> [VIDIOC_QBUF]
             -> [VIDIOC_QUERYBUF]
               -> [VIDEO_STREAMON]

Video Buffer :

V4L2 has a video buffer layer which acts as medium between v4l2 driver and app(user side). 
There is video device which will be streaming data(video frames) into video buffers (vb) . 
==> this will require to implement calls like buffer allocation , queuing , dequeuing, streaming I/O 
and other streaming controls like start/stop. 
This not only reduces driver code but also provides an uniform and standard APIs for app/user side.

more in detail : Kernel documentation:
    https://www.kernel.org/doc/Documentation/video4linux/videobuf

Ref: above content:  More @ http://technoflinger.blogspot.com/2013/06/v4l2-tutorial.html

---


Here's an overview of the V4L2 subsystem and its components:

## - Components:

1. **V4L2 Core**: 

- The V4L2 core is the central component of the V4L2 subsystem. 
- It provides a set of APIs that allow user-space applications to interact with video devices. 
- V4L2 core is responsible for managing the video device's resources, such as buffers,formats, & controls.

2. **Video Device Drivers**: 

- Video device drivers are kernel modules that implement the V4L2 API for specific video devices. 
- These drivers are responsible for controlling the HW and providing the necessary functionality to the 
  V4L2 core.

3. **Video Buffers**: 

- Video buffers are memory regions used to store video data. 
- The V4L2 core manages the allocation and deallocation of video buffers, which are then used by the 
  video device drivers to capture or output video streams.

4. **Video Formats**: 

- Video formats define the structure and layout of the video data stored in video buffers. 
- The V4L2 core provides a set of standard video formats, such as YUV, RGB, and MJPEG, which can be 
  used by video device drivers and user-space apps.

5. **Controls**: 

- Controls are used to configure and adjust various aspects of the video device, such as brightness, 
contrast, and gain. 
The V4L2 core provides a set of standard controls that can be used by user-space applications to adjust 
the video device's settings.


## - APIs:

The V4L2 API provides a set of ioctl() calls that allow user-space applications to interact with the 
V4L2 core and video device drivers. 

Some of the key APIs include:

1. **VIDIOC_QUERYCAP**: Retrieves information about the video device's capabilities.
2. **VIDIOC_S_FMT**: Sets the video format and buffer size for the video device.
3. **VIDIOC_REQBUFS**: Requests video buffers from the V4L2 core.
4. **VIDIOC_QBUF**: Queues a video buffer for capture or output.
5. **VIDIOC_DQBUF**: Dequeues a video buffer after capture or output.
6. **VIDIOC_STREAMON**: Starts or stops the video stream.
7. **VIDIOC_G_CTRL**: Gets the value of a control.
8. **VIDIOC_S_CTRL**: Sets the value of a control.

## - User-Space Applications:


- User-space applications, such as video capture tools, media players, and video conferencing software,
use the V4L2 API to interact with the V4L2 core and video device drivers. 
These applications can capture video streams, adjust video settings, and control the video device's 
behavior using the V4L2 API.

## - Benefits:

The V4L2 subsystem provides several benefits, including:

1. **Standardization**: 

V4L2 provides a standardized API for video capture devices, making it easier for developers to write 
applications that work with multiple devices.

2. **Portability**: 

V4L2 allows video device drivers to be written in a way that is independent of the underlying hardware, 
making it easier to port drivers to different platforms.

3. **Flexibility**: 

V4L2 provides a flexible framework that allows developers to implement custom video formats, controls, 
and features.

In summary, the V4L2 subsystem is a critical component of the Linux kernel that provides a standardized 
way for applications to access and control video capture devices. 

Its components, including the V4L2 core, video device drivers, video buffers, video formats, and controls,
work together to provide a flexible and portable framework for video capture and output.

## - V4L2 Core:

The V4L2 core is the central component of the V4L2 subsystem, responsible for managing the interaction 
between user-space applications and video device drivers. 

It provides a set of APIs that allow user-space applications to access and control video capture devices, 
and it manages the resources and functionality of the video device drivers.

**Architecture:**

The V4L2 core is implemented as a kernel module, which is loaded into the Linux kernel. 
It consists of several components, including:

1. **v4l2_device**: 
This is the main structure that represents a V4L2 device. It contains information about the device, 
such as its name, type, and capabilities.

2. **v4l2_ioctl_ops**: 
This structure defines the ioctl() operations that can be performed on a V4L2 device. 
It includes functions for handling ioctl() calls, such as VIDIOC_QUERYCAP and VIDIOC_S_FMT.

3. **v4l2_file_operations**: 
This structure defines the file operations that can be performed on a V4L2 device, such as open(), close(),
and ioctl().

4. **v4l2_buffer**: 
This structure represents a video buffer, which is a region of memory used to store video data.

**Functionality:**

The V4L2 core provides several key functionalities, including:

1. **Device Management**: 
The V4L2 core manages the lifetime of V4L2 devices, including device registration, deregistration, and 
hotplug events.

2. **Resource Management**: 
The V4L2 core manages the resources required by video device drivers, such as memory, interrupts, and 
DMA channels.

3. **Buffer Management**: 
The V4L2 core manages the allocation and deallocation of video buffers, which are used to store video data.

4. **Format Management**: 
The V4L2 core manages the video formats supported by the video device, including the format of the 
video data stored in video buffers.

5. **Control Management**: 
The V4L2 core manages the controls supported by the video device, such as brightness, contrast, and gain.

6. **ioctl() Handling**: 
The V4L2 core handles ioctl() calls from user-space applications, including VIDIOC_QUERYCAP, VIDIOC_S_FMT, 
and VIDIOC_REQBUFS.

7. **Video Streaming**: 
The V4L2 core manages the video streaming process, including the queuing and dequeuing of video buffers.



**Key Data Structures:**

The V4L2 core uses several key data structures to manage video devices and buffers, including:

1. **v4l2_device**: 
This structure represents a V4L2 device and contains information about the device, such as its name, type, 
and capabilities.

2. **v4l2_buffer**: 
This structure represents a video buffer and contains information about the buffer, such as its size, 
format, and flags.

3. **v4l2_format**: 
This structure represents a video format and contains information about the format, such as its type, 
width, and height.

4. **v4l2_control**: 
This structure represents a control and contains information about the control, such as its type, value, 
and flags.

**Key Functions:**

The V4L2 core provides several key functions that are used by video device drivers and user-space 
applications, including:

1. **v4l2_device_register()**: 
Registers a V4L2 device with the V4L2 core.

2. **v4l2_device_unregister()**: 
Unregisters a V4L2 device from the V4L2 core.

3. **v4l2_ioctl()**: 
Handles ioctl() calls from user-space applications.

4. **v4l2_buf_init()**: 
Initializes a video buffer.

5. **v4l2_buf_prepare()**: 
Prepares a video buffer for capture or output.

6. **v4l2_buf_queue()**: 
Queues a video buffer for capture or output.

7. **v4l2_buf_dequeue()**: 
Dequeues a video buffer after capture or output.


**Benefits:**

The V4L2 core provides several benefits, including:

1. **Standardization**: 
The V4L2 core provides a standardized API for video capture devices, making it easier for developers to
write applications that work with multiple devices.

2. **Portability**: 
V4L2 core allows video device drivers to be written in a way that is independent of the underlying 
hardware, making it easier to port drivers to different platforms.

3. **Flexibility**: 
The V4L2 core provides a flexible framework that allows developers to implement custom video formats,
controls, and features.

4. **Efficiency**: 
The V4L2 core provides an efficient way to manage video devices and buffers, reducing the overhead of 
video capture and output operations.

---
M2M device:

- V4L2 core also handles Memory-to-Memory (M2M) devices.

- M2M devices are a type of video device that performs video processing operations, such as encoding,
decoding, and transcoding, without capturing or outputting video data to/from external devices. 

Instead, they process video data in memory, hence the name "Memory-to-Memory".

The V4L2 core provides support for M2M devices through the `v4l2_m2m` module, which is a part of the 
V4L2 core. 
This module provides a set of APIs and data structures that allow M2M devices to be managed and controlled
by the V4L2 core.

Here are some key aspects of M2M device support in the V4L2 core:

**M2M Device Registration**:

M2M devices register with the V4L2 core using the `v4l2_m2m_device_register()` function, which is similar
to the `v4l2_device_register()` function used by capture devices.

The registration process involves providing information about the M2M device, such as its capabilities, 
formats, and controls.

**M2M Buffer Management**:

M2M devices use the same buffer management API as capture devices, with some modifications to accommodate 
the M2M use case. 
The `v4l2_m2m_buffer` structure is used to represent an M2M buffer, which is a region of memory used to
store video data.

**M2M IOCTLs**:

The V4L2 core provides a set of M2M-specific ioctl() calls, such as `VIDIOC_M2M_STREAMON` and
`VIDIOC_M2M_STREAMOFF`, which allow user-space applications to control the M2M device's streaming state.

**M2M Queue Management**:

M2M devices use a queue-based approach to manage the processing of video data. 
The V4L2 core provides APIs for queueing and dequeuing buffers, as well as for managing the queue's state.

**M2M Device Controls**:

M2M devices can have controls, such as bitrate, framerate, and quality, which can be adjusted by user-space
applications using the V4L2 core's control API.

The V4L2 core's support for M2M devices provides a flexible and standardized way for developers to 
implement video processing pipelines using M2M devices. This allows for more efficient and scalable
video processing, as well as easier integration with other V4L2 devices and applications.

Some examples of M2M devices that can be supported by the V4L2 core include:

* Video encoders (e.g., H.264, VP9)
* Video decoders (e.g., H.264, VP9)
* Transcoders (e.g., H.264 to VP9)
* Image processing units (e.g., scaling, cropping, filtering)

By supporting M2M devices, the V4L2 core provides a more comprehensive framework for video processing 
and manipulation in Linux.
