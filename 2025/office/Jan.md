13th:

The patch seem to work well.
Below are some initial testing I have done:
Test 1: encode

# gst-launch-1.0 filesrc location=/mnt/enc/jolin.mp4 ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mp4mux ! filesink location=/mnt/enc/out/264_1080p_to_265.mp4

# gst-launch-1.0 filesrc location=/mnt/enc/hevc.mp4 ! parsebin ! v4l2h265dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! mpegtsmux ! filesink location=/mnt/enc/out/265_1080p_to_265.ts

# gst-launch-1.0 filesrc location=/mnt/enc/vp9.webm ! parsebin ! v4l2vp9dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! matroskamux ! filesink location=/mnt/enc/out/vp9_1080p_to_265.mkv

The files can play normally using xxplay, mpv, vlc.

Test 2: ( check bitstream and read NAL's: )

# gst-launch-1.0 filesrc location=/mnt/10.mp4 ! parsebin ! v4l2h264dec capture-io-mode=4 ! v4l2h265enc output-io-mode=5 ! h265parse ! filesink location=/mnt/10.265

Hevcbitstream browser ( https://github.com/virinext/hevcesbrowser.git ) to read 10.265 file:

Found NAL units:

VPS, SPS, PPS, AUD (pic_type =4), IDR_W_RADL AUD (pic_type =4), TRAIL_R,
AUD (pic_type =4), TRAIL_R, AUD (pic_type =4), TRAIL_R, ........

Meta data can be read at the correct offsers for VPS,SPS, PPS.
I notice meta-data for NAL AUD -> pic_type is always  4.
( from spec possible values for pic_type should be 0,1,2 )
Not sure if this is valid or has any other side effect  or this value can be ignored.

14th:
出現馬賽克原因是decoder吐出來的pts不連續, 中間不定時跳了好幾個, 導致gstreamer判定某些frame是drop狀態, 而encoder卻拿來用, 所以decoder邊拿來放新的decoded frame, encoder卻邊拿去讀. 而pts不連續是因為gstreamer餵給v4l2的每一筆bs不是一張完整的frame, 譬如有三筆bs三個PTS才組成一個一張frame, 所以中間兩筆的pts就掉了, 此問題修正於:

The reason for the mosaic issue is that the decoder outputs PTS (Presentation Time Stamp) values that are not continuous.
Occasionally, it jumps several PTS values, causing GStreamer to interpret some frames as dropped.
However, the encoder still uses these frames. As a result, the decoder continuously outputs new decoded frames while
the encoder is still reading old ones.

The PTS discontinuity occurs because the data provided to the V4L2 (Video4Linux2) interface in GStreamer is not
complete for each frame. For example, three different bitstreams (BS) might be required to form a single complete
frame, and the PTS values for the middle two BS fragments are lost in the process.

This issue has been addressed in a subsequent fix.

### Explanation:
- **PTS (Presentation Time Stamp)**: This is used to determine when each frame should be displayed in a video stream.
- **Decoder and Encoder synchronization problem**: The decoder processes frames in sequence and outputs them, but when the encoder reads them, it may still be reading frames that should have already been processed.
- **GStreamer and V4L2 interaction**: GStreamer feeds incomplete or fragmented bitstreams to V4L2, which causes the PTS for some frames to be lost or out of order. This results in frames being incorrectly dropped or out of sync.


Yes, the explanation you provided is logically sound and valid for the mosaic issue you're describing. Here's a breakdown of why it makes sense:

1. **PTS Discontinuity**:
   The issue stems from discontinuous Presentation Time Stamps (PTS), which are critical in video decoding and rendering. When PTS values jump unpredictably, it means the frames are not being processed in the correct temporal sequence. If the decoder outputs frames without proper timing information or with gaps in timing, the playback becomes irregular, causing artifacts like mosaics or frame drops.

2. **Decoder and Encoder Synchronization**:
   As the decoder outputs frames (with potentially missing or out-of-order PTS), the encoder may still be trying to process the previous frame based on older timestamps or frames that have already been dropped. This can cause a mismatch where the decoder feeds fresh frames while the encoder is still using old frames that are no longer valid, leading to inconsistencies in the output stream.

3. **GStreamer and V4L2 Handling of Bitstreams**:
   In the case you're describing, GStreamer is feeding V4L2 with fragmented bitstreams (i.e., not all the data necessary to complete a frame is provided in a single packet). For instance, when three different bitstreams are required to complete a frame, but only two are processed, the PTS for the missing middle pieces are lost. As a result, the decoder and encoder are operating on incomplete data, which causes PTS misalignment and frame drop issues.

4. **Mosaic Artifact**:
   When these issues occur (misaligned frames, dropped frames, missing data), it results in corrupted output, which can manifest as mosaic-like artifacts in the video playback, since the frames do not align properly for encoding or rendering.

### Conclusion:
The explanation correctly identifies that the root cause of the mosaic issue is the improper synchronization between the decoder and encoder due to lost or discontinuous PTS values, as well as the fragmented bitstream delivery. Fixing the fragmentation and ensuring continuous, properly timed PTS values will likely resolve this issue.
Both patching GStreamer and handling the issue in the V4L2 driver could be reasonable approaches, but the best solution depends on the specific context and requirements of your system. Here's a breakdown of each approach and its potential benefits:

### 1. **Patching GStreamer:**

#### Pros:
- **Control at the Application Layer**: By modifying GStreamer, you can directly address the issue at the source, especially since it’s handling the fragmented bitstreams and controlling how data is passed to V4L2.
- **More Flexibility**: You can implement specific changes or enhancements that are tailored to the application or pipeline, without needing to modify lower-level hardware drivers.
- **Easier Debugging and Maintenance**: GStreamer is a higher-level abstraction compared to V4L2, which makes it easier to test and debug in user-space, especially if you already have a working GStreamer pipeline.

#### Potential Solution:
- **Reorder and Synchronize PTS**: Ensure that GStreamer synchronizes and maintains the PTS values properly for fragmented bitstreams. You could implement logic to track and reorder fragmented data and ensure that the encoder receives frames with continuous and correct PTS values.
- **Handling Frame Fragmentation**: GStreamer could be patched to correctly handle the bitstream fragmentation (e.g., by reassembling the frame properly before passing it on to V4L2). This would ensure that the full frame is processed and that PTS values are assigned correctly.
- **Dropping Frames Logic**: Improve the handling of frame drops so that the encoder is not receiving frames that should be dropped or incomplete.

#### Challenges:
- **Complexity in Bitstream Management**: The challenge of handling fragmented bitstreams in GStreamer can get quite complex, especially if you have multiple types of fragmentation scenarios to account for.
- **Potential Compatibility Issues**: Patching GStreamer might introduce compatibility issues with other components or other pipelines, depending on your environment.

### 2. **Handling in V4L2 Driver:**

#### Pros:
- **Direct Control Over Hardware**: Modifying the V4L2 driver gives you direct control over how frames are processed at the hardware level, ensuring that the PTS values are correctly managed and that the fragmented bitstreams are handled in a more robust way.
- **Lower Overhead for Applications**: By resolving the issue at the driver level, the application layer (e.g., GStreamer) doesn't need to be modified extensively, and you could potentially achieve a more efficient solution.
- **Less Risk of Breaking User-Space Logic**: Since the V4L2 driver is at a lower level in the system, patching it reduces the risk of introducing unexpected behavior in higher-level application pipelines like GStreamer.

#### Potential Solution:
- **Reassemble Frames in V4L2**: The driver could be modified to handle the reassembly of fragmented bitstreams and ensure that the PTS is synchronized correctly before passing frames to the encoder. This ensures that the encoder receives complete frames with valid timing information.
- **PTS Synchronization in the Driver**: The driver could ensure that the PTS values are properly tracked and managed, so that the decoder and encoder are in sync.
- **Buffer Management**: The V4L2 driver could be enhanced to manage the incoming bitstreams more effectively, so that incomplete frames are not passed to the encoder or decoder.

#### Challenges:
- **Complexity in Driver Modification**: Patching the V4L2 driver may require deeper knowledge of the hardware and driver internals, making it more complex than patching an application like GStreamer.
- **Potential Hardware Constraints**: Depending on the hardware, V4L2 drivers might be more tightly coupled to the hardware-specific implementation, which could limit the flexibility of solutions and require careful testing on the actual platform.

### Which Solution to Choose?

- **Patching GStreamer** would be a good first step if you're looking to solve the issue at a higher level without needing to modify low-level drivers. It could be quicker and easier to test, especially if you’re familiar with GStreamer and already have a working pipeline.

- **Handling in V4L2** might be the better approach if the issue is deeply tied to how the hardware handles bitstream fragmentation or if you want to ensure that the solution is more robust across different applications and environments. This approach might require more expertise in low-level driver development but could result in a more stable and universal solution.

### Recommended Approach:
1. **Start by investigating GStreamer**: If the issue is mostly within the user-space pipeline (e.g., how frames are passed to V4L2), patching GStreamer might be the faster and more manageable solution. Ensure the fragmentation and PTS synchronization issues are handled correctly.

2. **Move to the V4L2 driver if necessary**: If you find that the problem lies more in how the V4L2 driver is managing fragmented bitstreams or PTS, and GStreamer modifications don’t fully solve the issue, then it might make sense to patch the driver to handle these low-level concerns.

In some cases, both approaches could be combined for a comprehensive solution.



---
CHROME-101:

There are two ways to confirm whether it is hw video decode:

Method 1:

# cat /sys/devices/platform/realtek-vpu.0/video_status

If it returns 1, it means that the v4l2 device is turned on.

Method 2:
 echo 8 > /proc/sys/kernel/printk
 echo "0xff" > /sys/class/video4linux/video0/dev_debug

 If a bunch of logs are sprayed, it means hw decode

