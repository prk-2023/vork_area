CICD tool: test/profile transcoding pipeline

This is inspired by the unit test of UGREEN transcode, 
written based on the framework of google test. 
It tests more than 500 files in total, using 

    ffmpeg demux+parse 
    and 
    gstreamer dec+scaling down+enc. 

(takes about 30 mins to test)

Uses:
    - FFMpeg, Gstreamer 
    - Crow : Web API Crow Framework for HTTP handling.
      Template to allow trigger transcoding jobs via HTTP request and monitor results.
      Installation @ https://github.com/CrowCpp/Crow
      (depends on asio-devel)

CICD flow:

    - Setup HTTP server using Crow to receive transcoding requests.
    - Server runs the FFMpeg/Gstreamer based transcoding ( HW and SW ) commands as sub-processes.
    - Log the transcoding results (output the errors and performance)


+----------------------+
|    Test Scheduler    |
+----------------------+
         |
         v
+----------------------+       +------------------+
|  Input/Test Manager  | <---> | Test Case Config |
+----------------------+       +------------------+
         |
         v
+-----------------------------+
|  Backend Execution Engine   |
| - Selects SW or HW decoding |
| - Run FFmpeg or GStreamer   |
| - Use MPP Acceleration (HW) |
| - Pass CLI args (SW or HW)  |
+-----------------------------+
         |
         v
+------------------------------+
|   Log Capture & Analyzers    |
| - FPS, CPU, memory usage     |
| - CRC/frame diff comparisons |
| - Crash/error detection      |
+------------------------------+
         |
         v
+------------------------+
|  Report Generator/API  |
+------------------------+


or :

+----------------------+
|    Test Scheduler    |
+----------------------+
         |
         v
+----------------------+       +------------------+
|  Input/Test Manager  | <---> | Test Case Config |
+----------------------+       +------------------+
         |
         v
+--------------------------------------------------+
|           Backend Execution Engine               |
|  - Select SW or HW processing mode               |
|  - Frameworks: FFmpeg / GStreamer                |
|                                                  |
|  +--------------------------------------------+  |
|  |               Media Pipeline               |  |
|  |  - Demuxing                                |  |
|  |  - Parsing                                 |  |
|  |  - Decoding  (SW: libavcodec | HW: V4L2, ) |  |
|  |  - Scaling   (SW: swscale    | HW: )       |  |
|  |  - Encoding  (SW: x264/x265  | HW: )       |  |
|  +--------------------------------------------+  |
|                                                  |
|  - Construct and run CLI args for FFmpeg/Gst     |
+--------------------------------------------------+
         |
         v
+------------------------------+
|   Log Capture & Analyzers    |
|  - FPS, CPU, memory usage     |
|  - CRC/frame diff comparisons |
|  - Crash/error detection      |
+------------------------------+
         |
         v
+------------------------+
|  Report Generator/API  |
+------------------------+
