# GStreamer Basic concepts:


GStreamer is a powerful framework used for building media processing pipelines, GStreamer provides the tools you need to manipulate and process data efficiently.

The Core, GStreamer is built around the concept of pipelines, sequences of elements that process data from one end to another. Each Elements can be a sources (ex : reading from file), filters (ex : converting formats), or sinks (ex : outputting to a display or speaker).

The pipe line based architecture can be effective in building a powerful video Analytics platform, example the pipe lines design can help in reading from sources (files, rtsp..) and leverage the HW decoder to speed and processing. Gstreamer would make this a suitable candidate to be used with AIoT/edge devices for performing media analytics.

Typical example: 
    decoding the video stream
    pre-process the decoded data
    perform algos on the data for object detection and tracing,
    video classification, 
    add additional meta-data,
    sending data over 
    streaming rtp/rtsp
    event detection of specific events.

Gstreamer pipeline based architecture can help in building for a real-time analytics and decision making tool with scalable solutions.

## Getting started:

Start from Gstreamer Application development manual ( https://gstreamer.freedesktop.org/documentation/installing/index.html?gi-language=c ) 

  * GStreamer architecture: pipelines, elements, pads, bins
  * Core concepts: sources, sinks, filters, caps, buffers
  * Simple pipeline creation and execution

The above are the essential items in diving into GStreamer development.
A strong foundation in GStreamer before diving into Rust will make the transition much smoother. 

Example to understand gst: ( create a simple pipeline to display a video)

                        +----------------+     +----------------+
                        |                |     |Audio/video sink|
    [file source] ==> [sink] decode sink |==>[sink] decode sink |
                        |                |     |                |
                        +----------------+     +----------------+
    
    pipeline of elements in GST. `filesrc`, `decodebin`, and `audiovideosink`.


* Elements:  This is the most basic processing unit, they are the basic building blocks of GST pipeline. Each element has a specific role, such as reading data ( source ), processing (filtering) or out-puting it (sink):
    - filesrc: Read data from file.
    - decodebin: Detect the file video stream format and decode the data
    - autovideosink: Display the video on the screen.

* Pad: Connection point on an element. Can be *source pad* (output) or *sink pad* (input). Its like a point of connection in a GST element, where data flows in or out. Every element has 2 types of pads: Source pad ( where data exits from the element ) and Sink Pads ( where data enters). 

* Caps (Capabilities):  Metadata about the media (eg: format,resolution,fps). Used for negotiation.

* Bin: Container that groups elements together. Pipelines are a kind of bin, this is like a container of elements. It groups multiple elements together, managing them as a single entity. ( useful when dealing complex pipelines) In above Example `decodebin` its a 'bin' because it automatically detects the formats of incoming data, creates the necessary elements to decode it, and manages them internally. You dont have to worry about what's inside, consider it as a black box that simplifies the pipeline design.

* Pipeline: A special type of bin. Represents a running or paused media processing graph. i.e it a special type of bin that managed the flow of data between elements. It controls the state of the elements and ensures data flows correctly from source to sink. Pipelines can contain multiple elements and bins, working together to process and deliver media.

The easy approach is to start by breaking down the *GStreamer architecture and core concepts*, with *practical examples and references*, mostly using *C (the native language of GStreamer)*. You can optionally use *Python* via PyGObject (`gi.repository.Gst`) if C feels too low-level.

---

## 1. GStreamer Architecture Overview

### Core Building Blocks

| Concept          | Description                                                                             |
| ----------------------- | --------------------------------------------------------------------------------------- |
| *Element*      | The most basic processing unit (eg:`videotestsrc`, `autovideosink`, `audioconvert`)  |
| *Pad*          | Connection point on an element. Can be **source pad** (output) or **sink pad** (input). |
| *Caps* (Capabilities)| Metadata about the media (eg: format,resolution,fps). Used for negotiation.|
| *Bin*          | Container that groups elements together. Pipelines are a kind of bin.            |
| *Pipeline*     | A special type of bin. Represents a running or paused media processing graph.    |

Each element connects to others via pads. When pads are compatible (determined using *caps*), data flows as buffers from source → sink.

---

## 2. Core Concepts with Examples

---
### Elements, Pads, and Pipelines

#### C Example: Minimal Video Test Pipeline

This program builds a simple pipeline: `videotestsrc ! autovideosink`

```c
#include <gst/gst.h>

int main(int argc, char *argv[]) {
    GstElement *pipeline;
    GstBus *bus;
    GstMessage *msg;

    // Initialize GStreamer
    gst_init(&argc, &argv);

    // Create pipeline with elements linked automatically
    pipeline = gst_parse_launch("videotestsrc ! autovideosink", NULL);

    // Start playing
    gst_element_set_state(pipeline, GST_STATE_PLAYING);

    // Wait until error or EOS
    bus = gst_element_get_bus(pipeline);
    msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
                                     GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

    // Free resources
    if (msg != NULL)
        gst_message_unref(msg);
    gst_object_unref(bus);
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(pipeline);
    return 0;
}
```

Run with:

```sh
gcc `pkg-config --cflags --libs gstreamer-1.0` test.c -o test
./test
```

*Reference*:

* [`gst_parse_launch`](https://gstreamer.freedesktop.org/documentation/gstreamer/gstparse.html?gi-language=c#gst_parse_launch)

---

### Manual Element Creation and Linking

```c
GstElement *source, *sink, *pipeline;
pipeline = gst_pipeline_new("test-pipeline");
source = gst_element_factory_make("videotestsrc", "source");
sink = gst_element_factory_make("autovideosink", "sink");

gst_bin_add_many(GST_BIN(pipeline), source, sink, NULL);
gst_element_link(source, sink);
```

*Reference*:

* [GstElement](https://gstreamer.freedesktop.org/documentation/gstreamer/gstelement.html)
* [GstPad](https://gstreamer.freedesktop.org/documentation/gstreamer/gstpad.html)

---

### Sources, Sinks, Filters

Each GStreamer pipeline consists of:

* *Source*: produces data (e.g., `videotestsrc`, `filesrc`, `v4l2src`)
* *Filters*: process/convert data (e.g., `videoconvert`, `audioconvert`)
* *Sinks*: consume data (e.g., `autovideosink`, `autoaudiosink`, `filesink`)

#### Example:

```sh
gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink
```

---

### Caps (Capabilities)

**Caps** describe the format of data flowing through a pad.

You can filter or force formats:

```sh
gst-launch-1.0 videotestsrc ! video/x-raw,width=640,height=480 ! autovideosink
```

 *Why it's important*: Elements negotiate formats using caps. If they don’t match, linking fails.

 [Caps documentation](https://gstreamer.freedesktop.org/documentation/gstreamer/gstcaps.html)

---

### Buffers

Buffers are actual containers for data (e.g., a frame or audio chunk). You’ll handle them when using `appsink`, `appsrc`, or writing custom plugins.

You don't usually manipulate buffers in basic pipelines unless you're writing low-level processing.

---

## 3. Practice Examples

### Example: Play a Video File

```sh
gst-launch-1.0 playbin uri=file:///path/to/video.mp4
```

### Example: Record Microphone to File (WAV)

```sh
gst-launch-1.0 alsasrc ! audioconvert ! wavenc ! filesink location=output.wav
```

### Example: Show Webcam Stream

```sh
gst-launch-1.0 v4l2src ! videoconvert ! autovideosink
```

---

## Recommended Reading and Resources

| Resource                                  | Type         | Link                                                                                                                                                                                   |
| ----------------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Official GStreamer Docs**               | Reference    | [https://gstreamer.freedesktop.org/documentation/](https://gstreamer.freedesktop.org/documentation/)                                                                                   |
| **Basic Tutorials (in C)**                | Step-by-step | [https://gstreamer.freedesktop.org/documentation/tutorials/basic/index.html](https://gstreamer.freedesktop.org/documentation/tutorials/basic/index.html)                               |
| **gst-launch Cheat Sheet**                | Examples     | [https://gstreamer.freedesktop.org/documentation/tools/gst-launch.html](https://gstreamer.freedesktop.org/documentation/tools/gst-launch.html)                                         |
| **GStreamer Concepts (Pads, Caps, etc.)** | Deep Dive    | [https://gstreamer.freedesktop.org/documentation/frequently-asked-questions/#what-is-a-pad](https://gstreamer.freedesktop.org/documentation/frequently-asked-questions/#what-is-a-pad) |

---

## Suggested Exercises (Your Turn)

Try these in either `gst-launch-1.0` or C:

1. Show a test pattern (`videotestsrc`) with different patterns
2. Play a local audio file
3. Record webcam + microphone and save to `.mp4`
4. Apply a video effect (e.g., `videobalance`, `vertigotv`) in a pipeline
5. Build a custom pipeline with separate elements in C

---

Would you like me to walk through one of these tutorial exercises in more detail (e.g., build a manual pipeline in C or Python)?


# code walk through *building a manual GStreamer pipeline in C* — step-by-step — using `videotestsrc`, `videoconvert`, and `autovideosink`.

This will help you understand:

* Manual element creation
* Adding elements to a pipeline
* Linking elements via pads
* Starting/stopping the pipeline
* Handling basic messages (EOS, ERROR)

---

##  Goal: Display a test video stream in a window

We'll replicate this simple `gst-launch` pipeline:

```sh
gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink
```

But build it entirely with C code.

---

##  Full Example: `manual_pipeline.c`

```c
#include <gst/gst.h>

int main(int argc, char *argv[]) {
    GstElement *pipeline, *source, *convert, *sink;
    GstBus *bus;
    GstMessage *msg;
    GError *error = NULL;

    // Step 1: Initialize GStreamer
    gst_init(&argc, &argv);

    // Step 2: Create pipeline elements
    source = gst_element_factory_make("videotestsrc", "source");
    convert = gst_element_factory_make("videoconvert", "convert");
    sink = gst_element_factory_make("autovideosink", "sink");

    // Step 3: Create the empty pipeline
    pipeline = gst_pipeline_new("test-pipeline");

    if (!pipeline || !source || !convert || !sink) {
        g_printerr("Not all elements could be created.\n");
        return -1;
    }

    // Step 4: Add elements to the pipeline
    gst_bin_add_many(GST_BIN(pipeline), source, convert, sink, NULL);

    // Step 5: Link the elements together
    if (!gst_element_link_many(source, convert, sink, NULL)) {
        g_printerr("Elements could not be linked.\n");
        gst_object_unref(pipeline);
        return -1;
    }

    // Step 6: Set the source properties (optional)
    g_object_set(source, "pattern", 0, NULL);  // 0 = default pattern

    // Step 7: Start playing
    gst_element_set_state(pipeline, GST_STATE_PLAYING);

    // Step 8: Wait until error or EOS
    bus = gst_element_get_bus(pipeline);
    msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
                                     GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

    // Step 9: Parse message
    if (msg != NULL) {
        GError *err;
        gchar *debug_info;

        switch (GST_MESSAGE_TYPE(msg)) {
            case GST_MESSAGE_ERROR:
                gst_message_parse_error(msg, &err, &debug_info);
                g_printerr("Error received: %s\n", err->message);
                g_error_free(err);
                g_free(debug_info);
                break;
            case GST_MESSAGE_EOS:
                g_print("End-Of-Stream reached.\n");
                break;
            default:
                // We should not reach here
                g_printerr("Unexpected message received.\n");
                break;
        }
        gst_message_unref(msg);
    }

    // Step 10: Free resources
    gst_object_unref(bus);
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(pipeline);

    return 0;
}
```

---

##  Build and Run

### Save it as: `manual_pipeline.c`

### Compile with:

```sh
gcc manual_pipeline.c -o manual_pipeline `pkg-config --cflags --libs gstreamer-1.0`
```

### Run it:

```sh
./manual_pipeline
```

It should open a window with the classic "TV test pattern" video output.

---

## Key Concepts Reinforced

| Step                         | Concept                                  |
| ---------------------------- | ---------------------------------------- |
| `gst_element_factory_make`   | Elements are created by factory names    |
| `gst_bin_add_many`           | Pipeline is a bin — add elements into it |
| `gst_element_link_many`      | Link elements (internally connects pads) |
| `g_object_set`               | Configure element properties             |
| `gst_element_set_state`      | Start/stop playback                      |
| `gst_bus_timed_pop_filtered` | Wait for messages like error or EOS      |
| Cleanup                      | Always reset to NULL state and unref     |

---

##  Bonus: Try modifying it

Here are a few variations you can try:

1. **Change the test pattern:**

   ```c
   g_object_set(source, "pattern", 18, NULL);  // E.g., snow pattern
   ```

2. **Add a video effect filter:**
   Insert a `vertigotv` or `agingtv` between `convert` and `sink`.

   ```c
   GstElement *effect = gst_element_factory_make("vertigotv", "effect");
   gst_bin_add_many(GST_BIN(pipeline), effect, NULL);
   gst_element_link_many(source, convert, effect, sink, NULL);
   ```

3. **Add a `capsfilter`:**

   ```c
   GstCaps *caps = gst_caps_from_string("video/x-raw,width=640,height=480");
   GstElement *capsfilter = gst_element_factory_make("capsfilter", "filter");
   g_object_set(capsfilter, "caps", caps, NULL);
   gst_caps_unref(caps);
   ```

---

# GST for embedded platforms:

*GStreamer development for embedded platforms*, then sticking with *C* is 100% the right move. GStreamer is widely used in embedded multimedia systems (like on Raspberry Pi, i.MX8, Jetson, or even custom SoCs), and C is what most native applications, plugins, and system integrations are written in.

A possible tailored learning journey specifically for *embedded use cases*.

---

## Embedded-Focused GStreamer Learning Path (in C)

---

### Step 1: **Master Core Concepts** (as you're doing now)

You're already on this — continue with:

* Element creation & linking manually
* Caps negotiation
* Using the message bus
* Playing with different sinks (e.g., `fbdevsink`, `waylandsink`, `kmssink` for embedded platforms)

---

### Step 2: **Understand Embedded-Specific Elements and Sinks**

#### Common Elements for Embedded:

| Purpose           | Element                                                                |
| ----------------- | ---------------------------------------------------------------------- |
| Camera Input      | `v4l2src`, `nvarguscamerasrc` (Jetson), `imxv4l2videosrc`              |
| Video Output      | `fbdevsink`, `kmssink`, `waylandsink`, `glimagesink`, `nvdrmvideosink` |
| Hardware Encoding | `vpuenc`, `omxh264enc`, `x264enc`, `v4l2h264enc`, `v4l2h265enc`        |
| Hardware Decoding | `v4l2h264dec`, `imxvpudec`, `nvh264dec`                                |

*Tip:* Use `gst-inspect-1.0` on your embedded device to see available plugins:

```sh
gst-inspect-1.0 | grep sink
gst-inspect-1.0 v4l2src
```

---

### Step 3: **Cross-compile GStreamer for your platform**

* Use [Yocto](https://www.yoctoproject.org/) or [Buildroot](https://buildroot.org/) if you’re building a full embedded image
* Or compile GStreamer manually with `--host=arm-linux-gnueabihf` for custom SDKs

Build essential plugins:

```sh
./configure --enable-static --disable-gtk-doc --prefix=/opt/gst \
            --host=arm-linux-gnueabihf
make && make install
```

---

### Step 4: **Develop On Target or Cross-Deploy**

**On-target dev:** Useful for quick testing
**Cross-compile:** Ideal for production builds

Toolchains:

* For ARMv7: `arm-linux-gnueabihf-gcc`
* For ARM64: `aarch64-linux-gnu-gcc`

Use `pkg-config` with the sysroot:

```sh
export PKG_CONFIG_SYSROOT_DIR=/path/to/sysroot
export PKG_CONFIG_PATH=$PKG_CONFIG_SYSROOT_DIR/usr/lib/pkgconfig
```

---

### Step 5: **Project Ideas for Embedded Targets**

1. **Simple Camera Preview App**

   * C app using `v4l2src ! videoconvert ! fbdevsink` or `kmssink`

2. **H.264 Video Recorder**

   * Camera input → encoder → MP4 muxer → filesink

3. **RTSP Server from Camera**

   * Use GStreamer's RTSP Server API (`libgstrtspserver`)

4. **Touchscreen Kiosk Media Player**

   * Play video + UI using Qt (QtGStreamer) or directly with framebuffer

5. **Still Image Capture**

   * Capture a frame and encode it as JPEG or PNG

---

## Reference: Minimal Embedded C Example

### **Embedded-friendly video preview (framebuffer or HDMI output)**

```c
#include <gst/gst.h>

int main(int argc, char *argv[]) {
    GstElement *pipeline;
    GstBus *bus;
    GstMessage *msg;

    gst_init(&argc, &argv);

    pipeline = gst_parse_launch("v4l2src ! videoconvert ! fbdevsink", NULL);

    gst_element_set_state(pipeline, GST_STATE_PLAYING);

    bus = gst_element_get_bus(pipeline);
    msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
                                     GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

    if (msg != NULL)
        gst_message_unref(msg);
    gst_object_unref(bus);
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(pipeline);

    return 0;
}
```

Replace `fbdevsink` with `autovideosink`, `waylandsink`, `kmssink`, etc. depending on your embedded GPU/display stack.

---

## Key Resources for Embedded GStreamer

| Resource                                                                                                       | Description                                    |
| -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| [GStreamer on Embedded Linux](https://bootlin.com/doc/training/video/video-slides.pdf)                         | Bootlin’s open-source GStreamer training (PDF) |
| [GStreamer RTSP Server](https://gstreamer.freedesktop.org/documentation/rtsp-server/index.html)                | API docs for streaming video                   |
| [Yocto Layer `meta-gstreamer`](https://layers.openembedded.org/layerindex/branch/master/layer/meta-gstreamer/) | For Yocto integration                          |
| [NXP i.MX GStreamer Guide](https://www.nxp.com/docs/en/user-guide/IMX_GSTREAMER_UG.pdf)                        | Platform-specific tuning                       |

---

## Next Steps

Would you like help with:

* A **camera capture + H.264 record** pipeline in C?
* Using **RTSP server** in an embedded context?
* Cross-compilation setup for a specific SoC (e.g., Raspberry Pi, i.MX8)?

