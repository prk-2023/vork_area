# 1.0 Timestamp:

## Why HW decoder reports wrong PTS and DTS after decoding:
1. Observation:

v4l2m2m based decoder in FFMpeg missing or invalid PTS and DTS in decoded  AVFrame:
Ex:
    Frame #0 | Type: ? |   \
    PTS: -9223372036854775808 | DTS: -9223372036854775808 |  \
    Timestamp: -1s | Resolution: 1920x1080 | Pixel fmt: nv12 | \ 
    Decoded frm MD5: 9b2c4088acb2c896d5d79adbe4b893ac  

Time stamps are valid and come from the input container/stream 

PTS is scaled to seconds using :

timestamp = 
    frame->pts * av_q2d(fmt_ctx-> streams[video_steam_index]->time_base);

The programs log with HW decoder (v4l2_m2m) has:
PTS: -9223372036854775808  // AV_NOPTS_VALUE
Timestamp: -1s             // Because PTS is NOPTS

=> this implies that the HW decoder is not propagating PTS/DTs to AVFrame's

2. Why: (HW Codec Specific) ( what might be going on at decoder)

HW decoders (v4l2m2m) often do not preserve timestamp metadata in decoded 
frames mainly when:
- There's no tight coupling between packet and frame timestamps.
- decoding is asynchronous and frames are pulled from a buffer without
  timestamp info

NOTE: This is often a design or limitation of the HW decoder implementation not FFMpeg itself.

3. Timebase and Scaling:

- av_q2d(fmt_ctx->streams[video_stream_index]->time_base) converts the
  stream's time base to seconds (e.g., 1/24000).

- SW decoder :
  " Frame #3 | Type: P | PTS: 3555 | DTS: 3555 | Timestamp: 0.148125s | Resolution: 1920x1080 | Pixel fmt: yuv420p | Decoded frm MD5: 9b2c4088acb2c896d5d79adbe4b893ac"

  This shows that SW decoder is using this correctly to compute:

  timestamp = pts * (1/24000) = 3555 / 24000 ~ 0.148125s

  In contrast HW decoder gives AV_NOPTS_VALUE so timestamp = -1s



## FIX: ( Workaround )
1.
If we are using **avcodec_send_packet()** and **avcodec_receive_frame()** loop
and the decoder does not assign PTS to frames, _propagage it manually_ from 
AVPacket:

```cpp
AVPacket* pkt;
// Save pts before sending
int64_t pkt_pts = pkt->pts;

// Send packet to decoder
avcodec_send_packet(codec_ctx, pkt);

// Receive frame
AVFrame* frame;
ret = avcodec_receive_frame(codec_ctx, frame);

if (ret == 0 && frame->pts == AV_NOPTS_VALUE) {
    frame->pts = pkt_pts;  // manually assign
}

```
NOTE: This above patch assumes 1:1 mapping between packet and frame. Means 
this will fail if the stream contains B frames or reordered streams.

2. Use AVFrame.best_effort_timestamp:

FFMpeg attempts to reconstruct timestamp when possible using:

``` 
    frame->best_effort_timestamp
```
Use this instead of **frame->pts:**

```cpp
    double timestamp = (frame->best_effort_timestamp != AV_NOPTS_VALUE)
  ? frame->best_effort_timestamp * av_q2d(fmt_ctx->streams[video_stream_index]->time_base)
  : -1;
```

## Recommended fix:

Update timestamp extraction to be more robust:

```cpp
int64_t effective_pts = (frame->best_effort_timestamp != AV_NOPTS_VALUE)
                      ? frame->best_effort_timestamp
                      : (frame->pts != AV_NOPTS_VALUE ? frame->pts : -1);

double timestamp = (effective_pts != -1)
                 ? effective_pts * av_q2d(fmt_ctx->streams[video_stream_index]->time_base)
                 : -1;
```

Also consider using frame->best_effort_timestamp seperately for diagnostics.


## Should the above Fix be used :

It depends on the goal we want to achieve :

- If the purpose is to compare decoded frame content (eg:pixel data, md5)
  between different decoders ( Ex: SW and HW ) then:

  Use: **best_effort_timestamp** or fallback logic as suggested.


* many HW decoders do not propagate PTS/DTS.
* But for Fair testing we would require some kind of timestamp or ordering to
  match frame reliably.
* **best_effort_timestamp** is FFMpeg's way to reconstruct frame timing when 
  the decoder does not provide it. 
  This gives consistency across decoders for our testing even if the HW decoder is lacking metadata.


## When not to use this above suggestion:

When we want to inspect raw behaviour or limitations of a HW decoder:

- Whether it correctly propagates metadata.
- How it handles timestamps, frame reordering.. etc

IN this case its we should not use **best_effort_timestamp** and leave 
PTS/DTS asis.

As overriding **frame->pts** with **best_effort_timestamp** or guessing 
defeats the purpose (  This would mask deficiencies in the decoder )

Fixing makes the tool as a validator rather then a comparator.

---

# 2. Decoded Frame Validataion: 

When decoding with FFMpeg various types of **errors & warnings** can be reported 
through  **AVFrame** and sometimes through **AVCodecContext** or **logs**.

Mainly using  **AVFrame::decode_error_flags** and other means:

## Pre-Frame Error Indicators:

1. **AVFrame::decode_error_flags** : 
   This is a bitmask field indicating decoding errors or concealments in the frame.

   Possible flags in  **include/libavutil/frame.h**:

   - FF_DECODE_ERROR_INVALID_BITSTREAM (0x0001): Invalid or corrupted bitstream
   - FF_DECODE_ERROR_MISSING_REFERENCE (0x0002): Required reference frame is missing (P/B frame)
   - FF_DECODE_ERROR_CONCEALMENT_ACTIVE (0x0004): Decoder had to conceal data due to errors.
   Example: 
   ```cpp
     if (frame->decode_error_flags & FF_DECODE_ERROR_INVALID_BITSTREAM)
     std::cout << "[WARNING] Invalid Bitstream!!!!\n";
   ```
2. Frame level Issues and Flags:
   Used by SW codecs to set extra info ( this not always used for errors)
   Ex: AV_FRAME_FLAG_CORRUPT:

   ```cpp
      if (frame->flags & AV_FRAME_FLAG_CORRUPT)
          std::cout << "[WARNING] Frame is marked as corrupt!\n";
   ```

3. Stream Or Packet Level error Signals:

  Before decoding packets may carry Error indicators:

  AV_PKT_FLAG_CORRUPT: Packet is suspected to be corrupt.

  This should be checked before sending packet to decoder:
  ```cpp
    if (pkt->flags & AV_PKT_FLAGS_CORRUPT)
      std::cout << "[WARNING] Packet is marked as corrupt!!!\n";

  ```

4. Missing or invalid Timestamps ( technically this is not error but should be used
   for testing /validator tools )

   ```cpp
   if (frame->pts == AV_NOPTS_VALUE)
    std::out  << "[NOTICE] Frame is missing PTS \n";

   if (frame->pict_type == AV_PICTURE_TYPE_NONE)
    std::out  << "[NOTICE] Frame picture type is unknown!!! ";


# Error detection inside ffmpeg:

Understanding how **`AVFrame`** internally marks frames as corrupted or having decode errors we need to look 
into FFmpeg's decoding internals.

### How does `AVFrame` decide the frame has corruption/errors?

`AVFrame` itself is mostly a **data container** that stores decoded frame data. 
It doesn’t perform decoding or corruption checks on its own. 
Instead, the corruption/error flags you see in `AVFrame::decode_error_flags` are set 
**by the decoder during the decoding process**.

---

### What happens internally?

1. **During decoding**, each codec implementation (like H.264, HEVC, VP9, etc.) processes compressed data 
   and tries to produce an uncompressed frame.

2. If the decoder detects **problems in the bitstream**, like missing references, invalid syntax, or errors 
   it cannot fully conceal, it sets specific error flags inside the frame.

3. These error flags are communicated back by the decoder to the framework and stored inside the 
   `AVFrame` struct before returning it to the user.

---

### Relevant `AVFrame` flags related to errors:

* **`decode_error_flags`**:
  This is a bitmask with flags like:

  * `FF_DECODE_ERROR_INVALID_BITSTREAM` — Decoder detected invalid or corrupt bitstream.
  * `FF_DECODE_ERROR_MISSING_REFERENCE` — Missing reference frame needed for decoding (common in inter-frame codecs).
  * `FF_DECODE_ERROR_CONCEALMENT_ACTIVE` — Decoder applied error concealment to hide visible corruption.

These constants are defined in FFmpeg headers like `libavcodec/avcodec.h` and are decoder-generated.

---

### Example scenario:

* Say a frame references a previous frame that is missing or corrupted.
* The decoder notices this during motion compensation or prediction.
* It sets `FF_DECODE_ERROR_MISSING_REFERENCE` in the `decode_error_flags` of the output `AVFrame`.
* Your code reads this flag and can print a warning or take corrective action.

---

### Summary

| What                            | Where it happens                      | Who sets it                             | What it means                                                    |
| ------------------------------- | ------------------------------------- | --------------------------------------- | ---------------------------------------------------------------- |
| Frame corruption                | During codec bitstream decoding       | Codec decoder logic                     | Decoding errors, missing references, or concealment flagged here |
| `decode_error_flags` in AVFrame | After decoding, before frame delivery | Decoder sets these flags inside AVFrame | Flags tell you about detected decode errors                      |

---

## HW decoder 

- HW decoders often do not expose detailed error flags in the same way SW decoder does.

- HW decoder may just produce the output frame without detailed error info embedded in
  AVFrame::decode_error_flags

- Sometimes HW decoder silently drops frames, Outputs black frames or delivers frames with artifacts but
  without error flags.


### What options do you have for error detection on HW-decoded frames?

1. **Check `AVFrame::decode_error_flags` — if your driver/decoder supports it**
   Sometimes, the FFmpeg wrapper for HW decoders attempts to map driver errors to these flags, but often 
   this is limited or not implemented.

2. **Check for missing PTS/DTS timestamps or irregularities**
   HW decoders may miss PTS/DTS or produce non-monotonic timestamps. This is a hint something may be wrong.

3. **Detect corrupted frames by hashing and comparing frame MD5 or checksums**
   As you do with your MD5 hash on raw frame data, you can compare against expected hashes or look for 
   frame-to-frame anomalies (black frames, repeated frames).

4. **Visual/Statistical analysis of the decoded frame data**

   * Check if frames are all zeros or mostly uniform (black/grey).
   * Calculate pixel variance or entropy to detect frozen or corrupted frames.
   * Detect sudden resolution changes or pixel format changes.

5. **Monitor error messages/logs from the HW driver**
   Sometimes the V4L2 driver logs or ioctl calls may reveal error conditions, which you can capture separately.

6. **Use FFmpeg's `avcodec` error callbacks or side data (if available)**
   In rare cases, the HW decoder might export extra metadata or error info as side data on the frame.

7. **Software fallback for verification**
   For critical applications, you might decode a subset of frames with a software decoder and compare results.

---

### Summary: HW decoder error detection limitations

| Method                         | Likelihood with HW decoder | Comments                            |
| ------------------------------ | -------------------------- | ----------------------------------- |
| `decode_error_flags`           | Low to medium              | Often not set or limited support    |
| PTS/DTS irregularities         | Medium                     | Useful but indirect error indicator |
| Frame MD5 or pixel data checks | High                       | Your current method works well      |
| Visual/entropy checks          | High                       | Can detect frozen or black frames   |
| Driver/hardware logs           | Medium                     | Needs separate monitoring           |
| Side data from decoder         | Low                        | Rarely implemented                  |
| Software decode fallback       | High                       | Expensive, but most reliable        |

---



