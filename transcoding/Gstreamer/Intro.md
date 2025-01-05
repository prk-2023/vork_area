# GStremer:

ref :
 https://gstreamer.freedesktop.org/documentation/tutorials/index.html?gi-language=c


Gstreamer and its plugin ecosystem provides a environment for multimedia processing, streaming and handling
various media formats. 

Gstreamer is powerful framework that is widely used for building multimedia applications.

Gstreamer uses a graph-based structure of elements, each representing a different multimedia task, such as
decoding, encoding, filtering, rendering ... etc....

Getting Started with Gstreamer and its plugin ecosystem involves understanding the basics of Gstreamer
framework, setting up the environment and divide in to specific development tasks:


### 1. Understanding GStreamer Basics: 

- Gstreamer is a multimedia framework that supports creating and mapping pipelines for processing audio,
  video and other media formats. 

- The design is highly modular and relies on plugins to handle specific tasks:

#### 1.1 Key concepts: 

* Elements: Building blocks of a pipeline, like sources, filters and sinks.

    - An elemets is a basic blcok of Gstreamer pipeline.
    - It represents a single operation or function, such as reading a file, decoding audio, or rendering
      video. 
    - Examples of elements include:
        1. 'filestc' : reads data from a file.
        2. 'decodebin' : decodes audio or video.
        3. xvimagesink : render video to a X window.

* States: 
    - An Element can be in one of several states:
        1. 'NULL' : Element is not initialized
        2. 'READY': The element is initialized and ready to process data.
        3. 'PAUSED': element is paused and not processing data.
        4. 'PLAYING': element is processing data.

* Pipelines: A chain of media processing elements.
    - A sequence of elements connected together to process data.
    - pipelines can be simple ( eg: render from a file and playing audio) or complex ( eg: decoding
      video, applying effects, and rendering to a display ).

* Bins and pipelines: Groups of elements for hierarchical management. 

* Pads: Connection points between elements. ( input/output ports ).
    - A pad is an input or output of an element.
    - Pads are used to connect-elements together to from a pipeline.
    - there are two types of pads:
        1. 'Sink pad'  : an input pad that receives data from another element.
        2. 'Source pad': an output pad that sends data to another element.

- Ghost Pads: 
    - A pad that is not connected to an element. 
    - Ghost pads are used to expose the pads of an element that is contained within a bin.

* Buffers: data conainers, they conatin the mediadata ( audio or video frames )
    - Buffer is a container that holds a chunk of data ( ex: audio or video frames).
    - Buffers are used to transfer data between elements.
    - Buffers have specific format, such as raw audio or video frames, and may be compressed or
      uncompressed.

* Events: messages passed between elements ( eg: to seep to a specific position or to handle EOS ..) 
    - Events are used to communicate between elemets and the pipelines.
    - Examples of events include:
        1. 'EOS' : End of stream indicate the end of stream.
        2. 'ERROR': indicate an error has occured.
        3. 'NEW_SEGMENT' : indicate a new segment of data is available.

- Bins:
    - A bin is a container that holds a group of elements.
    - Bins are used to manage the lifecycle of elements and provide a way to connect elements together. 

* Caps ( Capabilities ) describe the format and properties of a buffer.
    - caps are used to negotiate the format of data between elements.
    - Examples of caps include:
        1. 'video/x-raw' : raw video frames.
        2. 'audio/xraw'  : raw audio frames.

* Bus: bus is a event-driven system that handles messages, such as errors or EOS events, duting pipeline
  execution. Each pipeline has its own bus, which you can listen to from important messages ( like error,
  warning or EOS signale ).

* Gstreamer Plugins: Libraries that provide specific elements. 

#### 1.2 Installation:


sudo apt update
sudo apt install gstreamer1.0-tools \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-libav \
                libgstreamer1.0-dev \
                libgstreamer-plugins-base1.0-dev

Tools installed are :
- "gst-launch-1.0" and "gst-inspect-1.0" for testing and debugging. 

- Plugings from base, good, bad, ugly and libav.
    - gst-plugins-base: basic plugins, such as 'filesrc', 'filesink', and 'queue'.
    - gst-plugins-good: offers set of well-maintained plugins, including 'videotestsrc', 'audiotestsrc',
      and 'xvimagesink'.
    - gst-plugins-ugly: includes plugins that are not well-maintained or are specific to certain use
      cases such as 'x264' and 'faac'.
    - gst-plugins-bad: provides plugins that are still experimental or under development, such as
      'webrtc' and 'openh264'.


### 2. Basic Pipeline structure:

- A basic pipeline structure contains of:

    1. Source element: reads data from a source ( eg: file , network )
    2. Decode element: decode the data (eg: audio, video)
    3. process elemnet: process the decoded data ( eg: applies effets...)
    4. Sink element: renders the processed data to destination (eg: diaplsy, file)


Ex: Typical pipeline:

 `$ gst-launch-1.0 filesrc location=./video.mp4 ! decodebin ! videoconvert ! xvimagesink`

This pipeline reads a video file, decodes it, converts the video format and renders it to anx-window using
the 'xvimagesink' element. 

### 3. Write a simple application:

- Install Gstreamer development libs.

- Simple C program using Gstreamer.

    ```c 
    // simple_pipeline.c 
    #include <gst/gst.h>

    int main(int argc, char *argv[]) {
        // Initialize GStreamer
        gst_init(&argc, &argv);

        // Create a simple pipeline
        GstElement *pipeline = gst_parse_launch("videotestsrc ! autovideosink", NULL);
        if (!pipeline) {
            g_printerr("Failed to create pipeline.\n");
            return -1;
        }

        // Start playing the pipeline
        GstStateChangeReturn ret = gst_element_set_state(pipeline, GST_STATE_PLAYING);
        if (ret == GST_STATE_CHANGE_FAILURE) {
            g_printerr("Unable to set the pipeline to the playing state.\n");
            gst_object_unref(pipeline);
            return -1;
        }

        // Wait for 5 seconds to observe the output
        g_print("Pipeline running for 5 seconds...\n");
        g_usleep(5000000);

        // Stop the pipeline
        g_print("Stopping pipeline...\n");
        gst_element_set_state(pipeline, GST_STATE_NULL);

        // Free resources
        gst_object_unref(pipeline);
        g_print("Pipeline stopped and cleaned up.\n");

        return 0;
    }
    
    ```
- gst_init(): Initializes the GStreamer library.

- gst_parse_launch(): Creates the pipeline from a pipeline string argument.

- gst_element_set_state(): Change the pipeline state (eg: PLAYING, NULL ...)

- g_usleep(): daly execution for 5 seconds to observe the video output.

- gst_object_unref: cleans up allocated resources.

The above program is an example to build and excute a GStreamer pipeline programmatically.

You can exetend it by handling and executing more elements or handling events like EOS or error.


