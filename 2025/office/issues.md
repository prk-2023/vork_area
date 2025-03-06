# Issues:
---
1. chrome-399: 
---
h264-decode + h265-encode => assertion failed

Does VE1 handle interlace video:

Video
ID                                       : 33 (0x21)
Menu ID                                  : 2 (0x2)
Format                                   : AVC
Format/Info                              : Advanced Video Codec
Format profile                           : High@L4
Format settings                          : CABAC / 2 Ref Frames
Format settings, CABAC                   : Yes
Format settings, Reference frames        : 2 frames
Format settings, GOP                     : M=3, N=12
Codec ID                                 : 27
Duration                                 : 1 min 53 s
Bit rate                                 : 19.1 Mb/s
Width                                    : 1 440 pixels
Height                                   : 1 080 pixels
Display aspect ratio                     : 16:9
Frame rate                               : 25.000 FPS
Color space                              : YUV
Chroma subsampling                       : 4:2:0
Bit depth                                : 8 bits
Scan type                                : MBAFF
Scan type, store method                  : Interleaved fields
Scan order                               : Top Field First
Bits/(Pixel*Frame)                       : 0.491
Stream size                              : 259 MiB (86%)

Check the media using ffmpeg if its interlaced or progressive:
---
$ ffmpeg -i file
..
Stream #0:0(und): Video: h264 (High), yuv420p, 1920x1080, SAR 1:1 DAR 16:9, 25 fps, 25 tbr, 1k tbn, 50 tbc

=> check the video stream codec (e.g., h264) and any mention of interlaced video. 
   If the video is interlaced:
   FFmpeg should show "interlaced" or "tff" (top field first) / "bff" (bottom field first) in stream info.

or using ffprobe:

$ ffprobe -v error -select_streams v:0 -show_entries stream=field_order -of default=noprint_wrappers=1

This command will return information about the field order of the video. Possible outputs include:

progressive: The video is non-interlaced (progressive).
tff (Top Field First) or bff (Bottom Field First): The video is interlaced.

Possible values are:
    * field_order=tff
    * field_order=bff
    * field_order=progressive
---

Interlace: 
1. W.R.T Video technology:
    Interlacing refers to a technique used in video display where each frame is split into 
    two fields—one containing the odd lines and the other containing the even lines. 
    This technique was commonly used in older television systems (like NTSC and PAL) to reduce bandwidth 
    and improve the display of motion. 
    However, modern technologies often use progressive scanning, where entire image is displayed at once.
2. W.R.T Image processing:
    Interlacing can also refer to the way an image is stored or transmitted in a sequence of parts. 
    For example, in certain image file formats like PNG, interlacing can help display a rough version 
    of an image as it is being loaded, gradually improving the quality as more data is received.

3. General meaning: Interlacing is some thing that is intertwined or weave together of 2 or more things.

For a V4L2 (Video4Linux2) driver using a Video Processing Engine (VPE), the handling of interlaced video 
can be done at different stages, and it depends on both the capabilities of the VPU and how the 
V4L2 driver is structured.

### 1. **Video Processing Unit (VPU) Support for Interlace:**

If the Video Processing Engine itself supports interlaced video, it can perform the necessary operations 
like de-interlacing or scaling directly in hardware. This would typically involve:

   - **De-interlacing**:The VPU could convert interlaced video (fields) into a progressive format.
   - **Interlaced Output**: If the output needs to be interlaced, the VPE may generate the two fields 
                            required for interlacing.
   - **Field Handling**:VPU may have support for handling odd and even fields separately during processing.

In this case, the V4L2 driver would need to configure the VPU to handle the interlaced video correctly 
and pass the interlaced fields to the VPU. 
The V4L2 driver would then ensure that the VPU operates in the correct mode (interlaced vs progressive).

### 2. **Handling Interlace in the V4L2 Driver:**

If the Video Processing Engine doesn’t support interlacing or if the driver is using a simpler VPU that 
doesn't have direct interlaced video processing support, the V4L2 driver itself can handle interlaced video.
The driver could:

   - **Field-based Buffering**: The V4L2 driver can manage interlaced buffers by passing odd and even 
                                fields to the VPE separately.
   - **De-interlacing in Software**: If hardware support is unavailable, the driver could implement 
                                SW de-interlacing before passing the processed frames to the VPU.

### Summary:
- **If the VPU supports interlaced video**, the V4L2 driver will configure the VPU to handle interlaced 
    input and output accordingly.
- **If the VPU does not support interlacing**, the V4L2 driver may need to handle interlaced video in 
software (such as by de-interlacing or managing odd/even fields separately) or rely on other HW components.

Ideally, modern VPUs are often designed to handle both interlaced and progressive video, but if you are 
dealing with an older or simpler VPU, software handling in the driver might still be necessary.


My test using ffmeg -i tp.TP :

ffmpeg  -i tp.TP
[h264 @ 0x55c1a9c15400] co located POCs unavailable
    Last message repeated 5 times
[mpegts @ 0x55c1a9c0f5c0] DTS 800552250 < 800559450 out of order
[mpegts @ 0x55c1a9c0f5c0] PES packet size mismatch
[mpegts @ 0x55c1a9c0f5c0] Packet corrupt (stream = 0, dts = NOPTS).
[mpegts @ 0x55c1a9c0f5c0] PES packet size mismatch
[mpegts @ 0x55c1a9c0f5c0] Packet corrupt (stream = 1, dts = 810797850).
[mpegts @ 0x55c1a9c0f5c0] PES packet size mismatch
[mpegts @ 0x55c1a9c0f5c0] Packet corrupt (stream = 2, dts = 810797850).
Input #0, mpegts, from 'tp.TP':
  Duration: 00:01:53.92, start: 8894.988000, bitrate: 22091 kb/s
  Program 2
  Stream #0:0[0x21]: Video: h264 (High) ([27][0][0][0] / 0x001B), yuv420p(top first), 1440x1080 [SAR 15:11 DAR 20:11], 25 fps, 25 tbr, 90k tbn
  Stream #0:1[0x24]: Audio: dts (DTS) (DTS2 / 0x32535444), 48000 Hz, 5.1(side), fltp, 1536 kb/s
  Stream #0:2[0x26]: Audio: ac3 (AC-3 / 0x332D4341), 48000 Hz, 5.1(side), fltp, 384 kb/s
At least one output file must be specified
---
$ ffmpeg  -i tp.TP
[h264 @ 0x55c1a9c15400] co located POCs unavailable
    Last message repeated 5 times
[mpegts @ 0x55c1a9c0f5c0] DTS 800552250 < 800559450 out of order
[mpegts @ 0x55c1a9c0f5c0] PES packet size mismatch
[mpegts @ 0x55c1a9c0f5c0] Packet corrupt (stream = 0, dts = NOPTS).
[mpegts @ 0x55c1a9c0f5c0] PES packet size mismatch
[mpegts @ 0x55c1a9c0f5c0] Packet corrupt (stream = 1, dts = 810797850).
[mpegts @ 0x55c1a9c0f5c0] PES packet size mismatch
[mpegts @ 0x55c1a9c0f5c0] Packet corrupt (stream = 2, dts = 810797850).
Input #0, mpegts, from 'tp.TP':
  Duration: 00:01:53.92, start: 8894.988000, bitrate: 22091 kb/s
  Program 2
  Stream #0:0[0x21]: Video: h264 (High) ([27][0][0][0] / 0x001B), yuv420p(top first), 1440x1080 [SAR 15:11 DAR 20:11], 25 fps, 25 tbr, 90k tbn
  Stream #0:1[0x24]: Audio: dts (DTS) (DTS2 / 0x32535444), 48000 Hz, 5.1(side), fltp, 1536 kb/s
  Stream #0:2[0x26]: Audio: ac3 (AC-3 / 0x332D4341), 48000 Hz, 5.1(side), fltp, 384 kb/s
At least one output file must be specified


1. the output shows its not Interleaved but progressive video.
2.  warnings and errors related to the file’s structure and the processing of the streams. 
    Let's break down what's happening:
    a) **co-located POCs unavailable**:
    ```
    [h264 @ 0x55956419c400] co located POCs unavailable
    ```
   relates to H.264 video, where Picture Order Count (POC) is used to determine the display order of frames.
   The message indicates that co-located POCs (i.e., the POC values for some frames) 
   are not available/inconsistent. 
   ==> This can sometimes happen if the video stream is corrupt or improperly encoded.

    b) **PES packet size mismatch**:
    ```
    [mpegts @ 0x5595641965c0] PES packet size mismatch
    [mpegts @ 0x5595641965c0] Packet corrupt (stream = 0, dts = NOPTS).
    [mpegts @ 0x5595641965c0] PES packet size mismatch
    [mpegts @ 0x5595641965c0] Packet corrupt (stream = 1, dts = 810797850).
    [mpegts @ 0x5595641965c0] PES packet size mismatch
    [mpegts @ 0x5595641965c0] Packet corrupt (stream = 2, dts = 810797850).
    ```
    FFmpeg trying to decode or demux MPEG transport stream (MPEG-TS) data. 
    PES (Packetized Elementary Stream) packet size mismatch and 
    Packet corrupt errors indicate that the MPEG-TS file is damaged or improperly formatted, 
    and the data for the video or audio streams may not be properly synchronized or complete.

    c) **DTS out of order**:
    ```
    [mpegts @ 0x5595641965c0] DTS 800552250 < 800559450 out of order
    ```
    DTS (Decoding Time Stamp) being out of order suggests that the timestamps for decoding the frames are 
    incorrect or misordered in the stream, which can occur due to corruption or bad muxing of the file.

    2. Metadata Information:
    Despite these issues, FFmpeg still provides metadata about the streams:
    Video Stream info 
    ```
    Stream #0:0[0x21]: Video: h264 (High) ([27][0][0][0] / 0x001B), yuv420p(top first), 1440x1080 [SAR 15:11 DAR 20:11], 25 fps, 25 tbr, 90k tbn
    ```

TODO: check File Integrity: 
    The repeated PES packet size mismatch and Packet corrupt warnings indicate that the `tp.TP` file might 
    be damaged or corrupted. 
    You may want to consider checking the integrity of the file or try to repair it using tools like 
    **FFmpeg's `-err_detect`** or other media repair software.

  
  ```
  ffmpeg -i tp.TP output.mp4
  ```
  Or if you just want to check the file without processing it, you could use the `-an -vn` flags to disable audio/video output:
  ```
  ffmpeg -i tp.TP -an -vn
  ```
  
- **Fixing Corrupt Streams**: If the file is indeed corrupted, you might attempt to re-mux or re-encode it. For example:
  ```
  ffmpeg -i tp.TP -c copy output.mp4
  ```
  This would try to copy the streams to a new container, potentially bypassing issues like corruption in the MPEG-TS container.

File seems to have issues related to stream corruption or improper muxing. 
If the issue is not with the file itself, you might want to explore other fixes or re-encode the streams for better compatibility.

POC:
    - POC is a numerical value assigned to each frame (or picture) in a video sequence. 
    It indicates the order in which the frames should be displayed, and it allows the decoder to manage 
    complex dependencies between frames during playback.

    - The display order of frames is important in inter-frame compression codecs like H.264, where not 
    all frames are encoded independently. Some frames (such as B-frames) are encoded using information 
    from previous and future frames, so the order in which they are displayed might differ from the order 
    in which they are decoded.

    - POC value is assigned during encoding and is used during decoding to reconstruct the correct display 
    order of the frames.
    Each frame has its own unique POC value within a video sequence. 
    The decoder uses these values to properly reorder the frames for correct playback.

    So for bitstreams that contain only I,P frames the importance of POC is less complex then having
    B-frames.
    And less complex as P frame still depends that referes previous I or P frame. 

    - Decoder: Display Order vs. Decoding Order:
    Video frames are often decoded in a different order than they should be displayed. 
    Because of the way video compression works, where certain frames (like P-frames and B-frames) depend on 
    other frames (previous or future ones) for decoding.
    POC helps the decoder understand the correct display order, which may not match the decoding order.


SUGGESTIONS:
- ffmpeg -i tp.TP
    shows the file is progressive and not interleaved. 
    ( ffmpeg fetches meta-data info not just from header but also bitstream analyzing directly 
      As I know mediainfo mainly relies on container meta-data and may not perform bitstream analysis for 
      reporting)

    - ffmpeg errors: file is corrupted:
      1. unable to read POC pic order count used for display order of frame can not be read/corrupted.
      2. PES (Packetized Elementary Stream) packet size mismatch related to demux the ts file
      3. Also error on reading DTS and outoff order DTS ==> corrupt stream or wrong muxing media.

    - full error of the bitstream :
      ffmpeg  -xerror -v 9 -loglevel 99 -i tp.TP -an -f null - 2>&1 | tee dmp.log

GPT: 
using **GStreamer** with the **V4L2** driver and encountering issues due to corrupted streams (such as problems reading **POC** values), there are a few approaches you can try to prevent the crash by making the system more resilient to errors. Here are some tips for dealing with corrupted video streams in **GStreamer** while interfacing with **V4L2**.

### Key Approaches for GStreamer to Prevent V4L2 Crashes:

1. **Error Resilience with GStreamer Elements**:
   In **GStreamer**, you can configure certain elements to handle errors gracefully, such as **`decodebin`**, **`v4l2video4linux2dec`**, and other decoder elements. Using these, GStreamer can be configured to handle corrupted frames better, without crashing the system.

   - **Using `decodebin`**:
     The `decodebin` element can automatically select an appropriate decoder and handle stream errors to some degree. You can also control error handling more explicitly by configuring the decoder settings.

     Example pipeline:
     ```bash
     gst-launch-1.0 filesrc location=input.mp4 ! decodebin ! v4l2sink device=/dev/video0
     ```

   - **GStreamer Error Handling**: Use the **`error handling`** mechanisms in **GStreamer** to avoid crashes when a corrupted stream is encountered:
     - Add an **error callback** on the bus to handle error messages. This can allow the application to catch and respond to errors without crashing:
       ```c
       GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(pipeline));
       gst_bus_add_watch(bus, bus_call, loop);  // where bus_call is your error handler
       ```

     - **Example error handler**:
       ```c
       static gboolean bus_call(GstBus *bus, GstMessage *msg, gpointer data) {
           GMainLoop *loop = (GMainLoop *)data;
           switch (GST_MESSAGE_TYPE(msg)) {
               case GST_MESSAGE_ERROR:
                   GError *err;
                   gchar *debug_info;
                   gst_message_parse_error(msg, &err, &debug_info);
                   g_printerr("Error: %s\n", err->message);
                   g_error_free(err);
                   g_free(debug_info);
                   g_main_loop_quit(loop);
                   break;
               default:
                   break;
           }
           return TRUE;
       }
       ```

2. **Adjusting the V4L2 Element for Error Handling**:
   The **V4L2** plugin in **GStreamer** can be configured to handle certain errors, but you may need to set it up properly to avoid crashes.

   - **Configure `v4l2video4linux2dec`**: When using **V4L2** decoders in **GStreamer**, you can try setting parameters that prevent the decoder from crashing on corrupted frames. For example, using **non-blocking I/O** or ignoring errors in specific elements.

     Example pipeline with V4L2 decoder:
     ```bash
     gst-launch-1.0 filesrc location=input.mp4 ! v4l2video4linux2dec ! v4l2sink device=/dev/video0
     ```

3. **Use `identity` Element to Catch Errors**:
   The **`identity`** element can be used in the GStreamer pipeline to intercept corrupted buffers or unexpected frames before they reach the sink (e.g., V4L2). This allows you to either skip problematic buffers or handle them without crashing.

   Example pipeline with **`identity`**:
   ```bash
   gst-launch-1.0 filesrc location=input.mp4 ! decodebin ! identity drop-on-late-buffer=true ! v4l2sink device=/dev/video0
   ```

   The `drop-on-late-buffer=true` option tells GStreamer to drop late buffers, which can be helpful in preventing crashes caused by corrupted or out-of-order frames.

4. **Buffer Error Handling in GStreamer**:
   In GStreamer, you can handle errors in buffers by setting error recovery strategies, for example, by using the **`v4l2video4linux2dec`** decoder’s error handling features, such as **ignoring broken frames** or **buffer error flags**.

   Example pipeline with error handling and buffer skipping:
   ```bash
   gst-launch-1.0 filesrc location=input.mp4 ! decodebin ! v4l2video4linux2dec ! fakesink
   ```

   The **`fakesink`** element will discard the video output but allow you to catch errors in the decoding process, helping you detect issues without causing a crash.

5. **Handle Frame Corruption in User Code**:
   If you're building a **custom GStreamer application**, you can manage frame errors directly in your code. You can monitor for buffer errors and skip or requeue buffers based on certain error flags.

   - For example, in your GStreamer pipeline, check for corrupted frames or flags that indicate errors:
     ```c
     if (GST_BUFFER_FLAG_IS_SET(buffer, GST_BUFFER_FLAG_ERROR)) {
         // Handle or skip the corrupted frame
     }
     ```

6. **Enable `v4l2` Extensions for Error Recovery**:
   If your specific **V4L2 driver** supports extensions or specific flags to manage error recovery, ensure that these are enabled. For instance, certain V4L2 decoders support **buffer requeuing** or flag settings that help handle errors gracefully.

### Example GStreamer Pipeline with Error Handling:
```bash
gst-launch-1.0 filesrc location=input.mp4 ! decodebin ! v4l2video4linux2dec ! v4l2sink device=/dev/video0
```

You can then set up an error handler in your user-space application to catch these issues and react to them, either by skipping the problematic frames or by gracefully handling any stream errors.

### Conclusion:
To prevent GStreamer from crashing when dealing with a corrupted stream (such as errors in reading **POC** values), you can:
1. Use **`decodebin`** to automatically handle errors.
2. Set up error handling with GStreamer’s **bus callbacks** to intercept and deal with stream errors.
3. Use the **`identity`** element to catch and skip corrupted buffers.
4. Check **GStreamer’s V4L2 elements** to enable error recovery options, and consider using **software decoding** as a fallback.
   
These techniques help make your application more resilient and avoid crashes due to corrupted streams when using **GStreamer** and **V4L2**.
---
2. chrome 406: [stateful-V4L2-encoder] vp8-decode + h265-encode => Internal data stream error.
---
test command : 
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_VP8_WMAV1_30FPS.mkv" ! parsebin ! v4l2vp8dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/480P_VP8_WMAV1_30FPS.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Pipeline is PREROLLING ...
Missing element: Windows Media Audio 7 decoder
ERROR: from element /GstPipeline[ 1770.994036] [VDEC]  Releasing instance ffffff800bb16600
:pipeline0/GstParseBin:parsebin0[ 1770.995439] [VDEC]  Releasing done
/GstMatroskaDemux:matroskademux0: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/matroska/matroska-demux.c(6109): gst_matroska_demux_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstMatroskaDemux:matroskademux0:
streaming stopped, reason not-linked (-1)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

Error might be caused by the related missing decoders or unlinked elements, particularly concerning the
"parsbin" and other elements in the pipeline.

- "parsbin" element: automatically selects the appropriate demuxer based on the file format.
  If the file is "MKV" ( matroska ) the 'parsbin' might not always link correctly with the appropriate
  decoder, in this case may be missing audio decoder for WMA7 decoder.

  Try replace the parsbin with the specific demuxer "matroskademux" for vp8 video.

  or check if the "windows media audio 7 decoder" is supported and available. 
  also check if (gstreamer1.0-plugins-ugly is supported for proprietary codecs)

---
3. chrome: 405: [stateful-V4L2-encoder] h265-decode + h265-encode => Internal data stream error.
---
test command : 
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/1080P_H265.mkv" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/WDVideo-videotestfile-FunctionalTest-1080P_H265.mkv.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Pipeline is PREROLLING ...
ERROR: from element /GstPipeline[ 1001.791597] [VDEC]  Releasing instance ffffff8005dd7000
:pipeline0/GstParseBin:parsebin0[ 1001.792958] [VDEC]  Releasing done
/GstMatroskaDemux:matroskademux0: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/matroska/matroska-demux.c(6109): gst_matroska_demux_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstMatroskaDemux:matroskademux0:
streaming stopped, reason not-negotiated (-4)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

下列檔案也會
--------------
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_H265_AAC_30FPS.mkv" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-videotestfile-FunctionalTest-480P_H265_AAC_30FPS.mkv.mkv"

gst-launch-1.0 filesrc location="wd/WDVideo/MOV_0053.mp4" ! parsebin ! v4l2h265dec capture-io-mode=4 !
v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-MOV_0053.mp4.mkv"3.
chrome: 405: test command : 
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/1080P_H265.mkv" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/WDVideo-videotestfile-FunctionalTest-1080P_H265.mkv.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Pipeline is PREROLLING ...
ERROR: from element /GstPipeline[ 1001.791597] [VDEC]  Releasing instance ffffff8005dd7000
:pipeline0/GstParseBin:parsebin0[ 1001.792958] [VDEC]  Releasing done
/GstMatroskaDemux:matroskademux0: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/matroska/matroska-demux.c(6109): gst_matroska_demux_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstMatroskaDemux:matroskademux0:
streaming stopped, reason not-negotiated (-4)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

下列檔案也會
--------------
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_H265_AAC_30FPS.mkv" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-videotestfile-FunctionalTest-480P_H265_AAC_30FPS.mkv.mkv"

gst-launch-1.0 filesrc location="wd/WDVideo/MOV_0053.mp4" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-MOV_0053.mp4.mkv"
---
test command : 
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/1080P_H265.mkv" ! parsebin !
v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink
location="out/WDVideo-videotestfile-FunctionalTest-1080P_H265.mkv.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Pipeline is PREROLLING ...
ERROR: from element /GstPipeline[ 1001.791597] [VDEC]  Releasing instance ffffff8005dd7000
:pipeline0/GstParseBin:parsebin0[ 1001.792958] [VDEC]  Releasing done
/GstMatroskaDemux:matroskademux0: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/matroska/matroska-demux.c(6109):
gst_matroska_demux_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstMatroskaDemux:matroskademux0:
streaming stopped, reason not-negotiated (-4)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

下列檔案也會
--------------
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_H265_AAC_30FPS.mkv" ! parsebin
! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink
location="out/WDVideo-videotestfile-FunctionalTest-480P_H265_AAC_30FPS.mkv.mkv"

gst-launch-1.0 filesrc location="wd/WDVideo/MOV_0053.mp4" ! parsebin ! v4l2h265dec capture-io-mode=4 !
v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-MOV_0053.mp4.mkv"3.
chrome: 405: test command : 
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/1080P_H265.mkv" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/WDVideo-videotestfile-FunctionalTest-1080P_H265.mkv.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Pipeline is PREROLLING ...
ERROR: from element /GstPipeline[ 1001.791597] [VDEC]  Releasing instance ffffff8005dd7000
:pipeline0/GstParseBin:parsebin0[ 1001.792958] [VDEC]  Releasing done
/GstMatroskaDemux:matroskademux0: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/matroska/matroska-demux.c(6109): gst_matroska_demux_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstMatroskaDemux:matroskademux0:
streaming stopped, reason not-negotiated (-4)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

下列檔案也會
--------------
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_H265_AAC_30FPS.mkv" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-videotestfile-FunctionalTest-480P_H265_AAC_30FPS.mkv.mkv"

gst-launch-1.0 filesrc location="wd/WDVideo/MOV_0053.mp4" ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-MOV_0053.mp4.mkv"
---
test command : 
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/1080P_H265.mkv" ! parsebin !
v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink
location="out/WDVideo-videotestfile-FunctionalTest-1080P_H265.mkv.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Pipeline is PREROLLING ...
ERROR: from element /GstPipeline[ 1001.791597] [VDEC]  Releasing instance ffffff8005dd7000
:pipeline0/GstParseBin:parsebin0[ 1001.792958] [VDEC]  Releasing done
/GstMatroskaDemux:matroskademux0: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/matroska/matroska-demux.c(6109):
gst_matroska_demux_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstMatroskaDemux:matroskademux0:
streaming stopped, reason not-negotiated (-4)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

Issue also exists with the below files also:
--------------
gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_H265_AAC_30FPS.mkv" ! parsebin
! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink
location="out/WDVideo-videotestfile-FunctionalTest-480P_H265_AAC_30FPS.mkv.mkv"

gst-launch-1.0 filesrc location="wd/WDVideo/MOV_0053.mp4" ! parsebin ! v4l2h265dec capture-io-mode=4 !
v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location="out/WDVideo-MOV_0053.mp4.mkv"

The error suggests that GStreamer is unable to properly negotiate the media types between elements in the 
pipeline, resulting in a failure during the "prerolling" phase. 
Specifically, the `streaming stopped, reason not-negotiated (-4)` 
error indicates that one or more elements couldn't agree on the required formats or capabilities for 
processing the media.

### Key Issues and Fixes:
1. **`parsebin` and `matroskademux`**:
   - `parsebin` is a generic element that tries to automatically pick the correct demuxer, 
   but it can sometimes fail to negotiate properly with subsequent elements, especially when you're 
   explicitly specifying decoders like `v4l2h265dec` or `v4l2h265enc`.

   - Since you're working with an MKV file, it’s better to use `matroskademux`, which is specifically 
   designed for MKV files.

2. **Decoder and Encoder Negotiation**:
   - The error could also be related to the way you're specifying the video decoder (`v4l2h265dec`) and
   encoder (`v4l2h265enc`). 
   The `v4l2h265dec` element may not be correctly negotiating with the MKV stream 
   (e.g., the input format or buffer settings might not be compatible).

   - You should consider using a more flexible approach with `decodebin`, which automatically handles 
   format negotiation between decoders and encoders, or ensure that your `v4l2h265dec` and `v4l2h265enc` 
   are configured correctly.

3. **Using `decodebin` instead of `parsebin`**:
   - As `decodebin` can auto-select the appropriate decoders for both audio and video streams, it might 
   be more appropriate for your use case.

### Suggested Command:

Replace `parsebin` with `matroskademux` and try using `decodebin` for auto-format detection:

```bash
gst-launch-1.0 filesrc location="wd/1080p_H265.mkv" ! matroskademux ! decodebin ! \
        v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/out.ts"
```

### Explanation of Changes:
1. **`matroskademux`**: This element is specifically designed for parsing MKV files and will handle 
    demuxing more reliably than `parsebin` for MKV files.
   
2. **`decodebin`**: This automatically detects and selects the appropriate video and audio decoders for 
    the streams in the MKV file. It will dynamically choose the correct decoder, which avoids potential 
    negotiation issues when explicitly specifying `v4l2h265dec`.

3. **`v4l2h265enc`**: This is kept for H.265 encoding, assuming you're targeting hardware-based encoding.

4. **Other Elements**: The rest of the pipeline remains the same, with the `h265parse` and 
    `mpegtsmux` elements preparing the H.265 stream and multiplexing it into an 
    MPEG transport stream (`.ts` file).

### Additional Notes:
- **Check Installed Plugins**: Ensure that you have the necessary GStreamer plugins installed, particularly
  those for H.265 and MKV handling. You might need:

  - `gstreamer1.0-plugins-good` (for `matroskademux` and common decoders).
  - `gstreamer1.0-plugins-bad` (for additional codec support, including hardware-accelerated elements 
                                like `v4l2h265dec`/`v4l2h265enc`).
  - `gstreamer1.0-plugins-ugly` (for proprietary codecs if necessary).

  Install them using:
  ```bash
  sudo apt-get install gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
  ```

### Debugging the Negotiation Issue:
To further investigate the negotiation issue, you can add the `-v` (verbose) flag to the command to get detailed logs:

```bash
gst-launch-1.0 -v filesrc location="wd/1080p_H265.mkv" ! matroskademux ! decodebin ! \
        v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/out.ts"
```

This will provide more insights into how the elements are being linked and whether any particular element 
is failing to negotiate properly.

### Conclusion:
Try the revised command with `matroskademux` and `decodebin` to resolve the negotiation issues. 
If the problem persists, use the verbose logging to debug further, and check if the appropriate 
GStreamer plugins and drivers are installed for H.265 support.

---
3.  chrome-404: [stateful-V4L2-encoder] h264-decode + h265-encode => fail (diff. container got diff. error)
---
output to mp4 file: 
test command : gst-launch-1.0 filesrc location="synology/m2ts/dump.m2ts" ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mp4mux ! filesink location= "out/m2ts-dump.m2ts.mp4"
error log : mp4_error.txt

output to ts file: 
test command : gst-launch-1.0 filesrc location="synology/m2ts/dump.m2ts" ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location= "out/m2ts-dump.m2ts.ts"
error log : ts_error.txt

output to mkv file: 
test command : time gst-launch-1.0 filesrc location="synology/m2ts/dump.m2ts" ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location= "out/m2ts-dump.m2ts.mkv"
log : mkv_error.txt : v4l2 driver panic:
    

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

From Logs: 
The primary issue appears to be related to the error in multiplexing the stream due to a 
buffer lacking a PTS. 
This could be caused by a variety of factors, including:

Incorrect Configuration: The GStreamer pipeline might not be configured correctly, leading to the absence 
of PTS in the buffers.

Input Stream Issues: Problems with the input stream, such as missing or incorrect timestamps, could cause 
this error.

Component Compatibility: Incompatibilities or bugs in the components used in the pipeline (e.g., GstMP4Mux) 
might also lead to this issue.

To resolve the problem, it would be necessary to:

Verify Pipeline Configuration: 
Ensure that the GStreamer pipeline is correctly configured, paying special attention to elements that handle
timestamping and synchronization.

Check Input Streams: Validate that the input streams have correct and consistent timestamps.
use:
    ffprobe -v error -select_streams v:0 -show_entries frame=pkt_pts_time,pkt_dts_time \
        -of csv=print_section=0 input_video.mp4

    show_entries frame=pkt_pts_time,pkt_dts_time: 
        This tells ffprobe to display the presentation timestamp (pkt_pts_time) and decoding timestamp 
        (pkt_dts_time) for each frame.
    check: pkt_pts_time ( presentation time stamp for that frame)
           pkt_dts_time ( decode timestamp for that frame)
        => the differecne between consecutive timestamps should generally be consistent i.e for a 30fps
        video the difference should be around 1/30 sec or ~0.033 sec. 
        => If time stamps are not consistent then there can be large jumps in time. A -ve value of pts
        indicates some trouble. 
        ex ouput:
        pkt_pts_time,pkt_dts_time
        0.000000,0.000000
        0.033333,0.033333
        0.066667,0.066667
        0.100000,0.100000
        ...

        use ffmpeg to fix time stamps:
        ffmpeg -i input_video.mp4 -c:v copy -c:a copy -fflags +genpts output_video.mp4
        -fflags +genpts: forces to regenerate the PTS for the output file, which can help fix corrupted 
        timestamps.


Update Components: Consider updating GStreamer and its components to the latest versions to address any 
known bugs or compatibility issues.

Debugging: Use GStreamer's debugging tools and mechanisms to further diagnose the issue, potentially adding 
more detailed logging or using tools like gst-debug to inspect the pipeline behaviour in real-time.
---
4. chrome-401 : [stateful-V4L2-encoder] VC1-decode + h265-encode => Internal data stream error.
---
test command : 
gst-launch-1.0 filesrc location="synology/wmv/1080p.wmv" ! parsebin ! v4l2vc1dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/wmv-1080p.wmv.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Setting pipeline to PAUSED ...
[  190.768673] [VDEC]  Created instance: ffffff80127b6000, m2m_ctx: ffffff80065ea800
Pipeline is PREROLLING ...
Missing element: Advanced Streaming Format (ASF) demuxer
ERROR: from element /GstPipeline[  190.788121] [VDEC]  Releasing instance ffffff80127b6000
:pipeline0/GstParseBin:parsebin0[  190.789487] [VDEC]  Releasing done
/GstTypeFindElement:typefind: Internal data stream error.
Additional debug info:
/usr/src/debug/gstreamer1.0/1.22.12/plugins/elements/gsttypefindelement.c(1257): gst_type_find_element_loop (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstTypeFindElement:typefind:
streaming stopped, reason not-linked (-1)
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

note: 下列檔案也會發生
test command : 
gst-launch-1.0 filesrc location="synology/wmv/720p.wmv"  ! parsebin ! v4l2vc1dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/wmv-720p.wmv.ts"

> 
Ensure that a correct demuxer for the ASF container (.wmv files). Instead of parsebin, you can explicitly 
use the asfdemux element for ASF/WMV file parsing.

---
5. chrome-400 [stateful-V4L2-encoder] mpeg2-decode + h265-encode => not support interleaved Interlacing 
---


test command : 
gst-launch-1.0 filesrc location="synology/mpeg/1080p.mpg" ! parsebin ! v4l2mpeg2dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/mpeg-1080p.mpg.ts"

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

---------------------
error log : 
Setting pipeline to PAUSED ...
[15517.020312] [VDEC]  Created instance: ffffff80613f7a00, m2m_ctx: ffffff8004dd9800
Pipeline is PREROLLING ...
Redistribute latency...
ERROR: from element /GstPipeline:pipeline0/v4l2mpeg2dec:v4l2mpeg[15517.227990] [VDEC]  Releasing instance ffffff80613f7a00
2dec0: Device '/dev/video1' does[15517.229950] [VDEC]  Releasing done
 not support interleaved interlacing
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/sys/v4l2/gstv4l2object.c(4340): gst_v4l2_object_set_format_full (): /GstPipeline:pipeline0/v4l2mpeg2dec:v4l2mpeg2dec0:
Device wants progressive interlacing
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
ERROR: from element /GstPipeline:pipeline0/v4l2mpeg2dec:v4l2mpeg2dec0: Device '/dev/video1' does not support interleaved interlacing
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/sys/v4l2/gstv4l2object.c(4340): gst_v4l2_object_set_format_full (): /GstPipeline:pipeline0/v4l2mpeg2dec:v4l2mpeg2dec0:
Device wants progressive interlacing
ERROR: pipeline doesn't want to preroll.
Freeing pipeline ...

note: 下列檔案也有問題
test command : 
gst-launch-1.0 filesrc location="synology/mpeg/720p.mpg" ! parsebin ! v4l2mpeg2dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/mpeg-720p.mpg.ts"

gst-launch-1.0 filesrc location="synology/mpeg/HD.Club-2008.Taipei.101.FireWorks.v3.5min.mpg" ! parsebin ! v4l2mpeg2dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/mpeg-HD.Club-2008.mpg.ts"

gst-launch-1.0 filesrc location="wd/WDVideo/videotestfile/FunctionalTest/480P_MPEG2_AAC_30FPS.mkv" ! parsebin ! v4l2mpeg2dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mp4mux ! filesink location="out/480P_MPEG2_AAC_30FPS.mp4"

> 
The error occurs because the v4l2mpeg2dec element (which is the HW-based MPEG-2 decoder) does not support 
interleaved interlacing. 
The message "Device '/dev/video1' does not support interleaved interlacing" indicates that the HW device 
is unable to handle the specific type of video (likely interlaced video) in the input stream.

Interlaced Video: 
Interlaced video stores frames in two fields (odd and even lines), used for older television formats. 
Progressive video, on the other hand, displays each frame sequentially.

Hardware Decoder Limitation: The v4l2mpeg2dec decoder on your device only supports progressive video but 
cannot handle interlaced frames that are combined in an interleaved fashion 
(fields stored together in the same frame).

Possible Workaround: If your video is interlaced and you want to use hardware acceleration, you may need to 
either:
1. Convert the video to progressive format before decoding.
 gst-launch-1.0 filesrc location="in.mpg" ! parsebin ! videoconvert ! v4l2mpeg2dec capture-io-mode=4 \
     ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="outout.ts"
    
    videoconvert: element converts the video format and can help in converting interlaced video to 
    progressive format before passing it to the hardware decoder.

2. Use a different software-based decoder (instead of relying on hardware decoding) that can handle 
interlaced video. ( replace v4l2mpeg2dec with ffdec_mpeg2video )

gst-launch-1.0 filesrc location="in.mpg" ! parsebin ! ffdec_mpeg2video ! v4l2h265enc output-io-mode=5 ! \ 
        h265parse ! mpegtsmux ! filesink location="outout.ts"

---
6. chrome-398: [stateful-V4L2-encoder] h264-decode + h265-encode => output file can not be played.
---
test command : 
  gst-launch-1.0 filesrc location=synology/qnap/segmentfault/trp.TRP ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mp4mux ! filesink location=out/qnap-segmentfault-trp.TRP.mp4

file location :
\\172.19.7.1\SQA_Media_D_ASP\To_Hsinchu\cks\testfile

output file playback command :
  gst-launch-1.0 filesrc location="out/qnap-segmentfault-trp.TRP.mp4" ! parsebin ! v4l2h265dec ! waylandsink

result: output file 無法撥放,error log : 
---------------------
13079.797744] realtek-capture display-capture: In open device
[13079.799856] realtek-capture display-capture: _capture_krpc_init
[13079.801340] realtek-capture display-capture: _capture_rpc_create
[13079.805332] realtek-capture display-capture: _capture_rpc_create end
[13079.807660] [VDEC]  Created instance: ffffff801ebb1a00, m2m_ctx: ffffff8004f7d800
[13079.813014] [VDEC]  Releasing instance ffffff801ebb1a00
[13079.814328] [VDEC]  Releasing done
Setting pipeline to PAUSED ...
[13079.820684] [VDEC]  Created instance: ffffff801ebb1a00, m2m_ctx: ffffff8004f7d800
Pipeline is PREROLLING ...
ERROR: from element /GstPipeline[13079.837330] [VDEC]  Releasing instance ffffff801ebb1a00
:pipeline0/GstParseBin:parsebin0[13079.838795] [VDEC]  Releasing done
/GstQTDemux:qtdemux0: This file contains no playable streams.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/isomp4/qtdemux.c(509): gst_qtdemux_post_no_playable_stream_error (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstQTDemux:qtdemux0:
no known streams found
ERROR: pipeline doesn't want to preroll.
ERROR: from element /GstPipeline:pipeline0/GstParseBin:parsebin0/GstQTDemux:qtdemux0: This file contains no playable streams.
Additional debug info:
/usr/src/debug/gstreamer1.0-plugins-good/1.22.12/gst/isomp4/qtdemux.c(509): gst_qtdemux_post_no_playable_stream_error (): /GstPipeline:pipeline0/GstParseBin:parsebin0/GstQTDemux:qtdemux0:
no known streams found
ERROR: pipeline doesn't want to preroll.
Setting pipeline to NULL ...
Freeing pipeline ...

note:
原始檔案可以撥放.
command : 
gst-launch-1.0 filesrc location="synology/qnap/segmentfault/trp.TRP" ! parsebin ! v4l2h264dec ! waylandsink

下列檔案,output file 播放也有問題:
gst-launch-1.0 filesrc location="wd/KaminoMedia-TestFiles/!Video/3GP/MPEG-4_AVC_BASE@L3_AAC-LC/video-2011-01-27-10-45-32.3gp" ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location="out/video-2011-01-27-10-45-32.ts"

==>
The qtdemux element (which is used to demux MP4 files) did not find any playable streams in the output mp4 
file. This could happen for a number of reasons, such as:

Incorrect MP4 Format: 
    The way the MP4 file was generated might not be correct, or it may not contain valid video/audio streams.

Incorrect Encoding/Parsing: The v4l2h265enc encoder might not have produced a valid H.265 stream, or the 
file might be in a format that qtdemux doesn't support.

- check ffmpeg -i output.mp4 file for information. 
- ensure correct mp4 muxing: (mp4mux) is correctly handling the video stream and packaging it into the 
MP4 container. Sometimes, GStreamer can fail to properly mux the video if the stream isn't 
correctly formatted.

gst-launch-1.0 filesrc location="in.TRP" ! parsebin ! v4l2h264dec capture-io-mode=4 ! \ 
     v4l2h265enc output-io-mode=5 ! h265parse ! queue ! mp4mux ! filesink location="out.TRP.mp4"

  - queue: Adding a queue between the encoder and the muxer can help manage the data flow and prevent issues
           with stream processing.
  - mp4mux: This muxes the encoded H.265 video stream into the MP4 container.


---
