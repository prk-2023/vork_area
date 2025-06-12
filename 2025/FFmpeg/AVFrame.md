# AVFrame Structure:

**AVFrame** structure is core component for handling decoded media data such as video frame or audio
samples.

When decoding video, a codec like H.264 of MPEG-4 reads the encoded bitstream, decodes it into raw data
(pixels, usually in YUV format) and stores that data in a AVFrame.

AVFrame Structure overview:

### Key fields of AVFrame:

```c
    typedef struct AVFrame {
        uint8_t *data[AV_NUM_DATA_POINTERS];    // Pointers to the actual image/audio data
        int linesize[AV_NUM_DATA_POINTERS];     // Number of bytes per line for each plane
        int width, height;                      // Dimensions of the video frame
        enum AVPixelFormat format;              // Format of the image (e.g., AV_PIX_FMT_YUV420P)
        
        int64_t pts;                            // Presentation timestamp
        int64_t pkt_dts;                        // Decompressed timestamp from input packet
        int key_frame;                          // 1 if this frame is a keyframe 
        enum AVPictureType pict_type;           // I, P, B frame type 
        uint8_t *error[AV_NUM_DATA_POINTERS];   // Error information per data plane
        
        int flags;                              // Additional info like corruption flags
        
        AVBufferRef *buf[AV_NUM_DATA_POINTERS]; // Buffers for each data plane
        // ... (many other fields)
    } AVFrame;
   
```

### How is AVFrame used in Decoding:

When decoding a typical flow looks as below:

1. Read packets using av_read_frame()
2. Send packets to the decoder using avdecode_send_packet()
3. Receive decoded frames using avcodec_receive_frame()
4. Process the AVFrame: Ex: render or store

```c 
    AVPacket *pkt;
    AVFrame *frame;

    // Initialize packet and frame
    pkt = av_packet_alloc();
    frame = av_frame_alloc();

    // Read and decode loop
    while (av_read_frame(fmt_ctx, pkt) >= 0) {
        avcodec_send_packet(codec_ctx, pkt);
        while (avcodec_receive_frame(codec_ctx, frame) == 0) {
            // Use frame (display, convert, write, etc.)
        }
        av_packet_unref(pkt);
    }
```

### Error Detection in AVFrame:

1. AVFrame.error[]

    * This array indicates decoding errors per data plane (Y,U,V).
    * It is codec-dependent and not always filled in.
    * All we do in the program is Access it:
      example: 
      ```c 
        if (frame->error[0]) {
            //Error in Y plane
        } 
      ```
2. AVFrame.flags & AV_FRAME_FLAG_CORRUPT:

    * This flag signals **overall corruption** in the frame.
    * Set by the decoder if the frame is partially or fully damaged.
    * You can check :
      For Example:
      ```c 
        if (frame->flags & AV_FRAME_FLAG_CORRUPT) {
            fprintf(stderr, "Frame is corrupt\n");
        }
      ```
3. Detailed Macroblock Error mapping:

    * FFMpeg does **track error concealment at the macroblock level**, but this detail is mostly internal.
    * for more fine grain information :
        - use **debug_uv** or **vismv** FFmpeg flags to visualize macroblock errors.
        - Patch or extend decoders like H.264 to expose internal macroblock error maps if needed.

### How Debug Macroblock Errors:

While these are not directly exposed via AVFrame here is what we can do:

Method 1:  Use FFMpeg CLI debug options:

    - ffmpeg -h full | nv - (  search for all macroblock occurance for more. )

    - ffmpeg -flags2 +showall -debug vis_mb_type -i <input> -f null -  [ OLDER FFMPEG]

    - ffmpeg -debug mb_type -i /tmp/corrupted_bitstream.mp4 -f null -  [ newer ffmpeg version]
        ....
        [h264 @ 0x5612649f0f00] New frame, type: I
        [h264 @ 0x5612649f0f00] i  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I [h264 @ 0x5612649f0f00] I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  Inal_unit_type: 1(Coded slice of a non-IDR picture), nal_ref_idc: 0 [h264 @ 0x5612649f0f00]   I  New frame, type: B [h264 @ 0x561264a01c40] d  d cur_dts is invalid st:0 (0) [init:0 i_done:0 finish:0] (this is harmless if it occurs once at the start per stream) [h264 @ 0x561264a01c40]  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d [h264 @ 0x561264a01c40] d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d [h264 @ 0x561264a01c40] d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  cur_dts is invalid st:0 (0) [init:0 i_done:0 finish:0] (this is harmless if it occurs once at the start per stream) [h264 @ 0x5612649f0f00] I  I  I  I  Id cur_dts is invalid st:0 (0) [init:0 i_done:0 finish:0] (this is harmless if it occurs once at the start per stream) [h264 @ 0x5612649f0f00]   I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I [h264 @ 0x5612649f0f00] I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I cur_dts is invalid st:0 (0) [init:0 i_done:0 finish:0] (this is harmless if it occurs once at the start per stream) Last message repeated 2 times [h264 @ 0x561264a01c40]  d  nal_unit_type: 1(Coded slice of a non-IDR picture), nal_ref_idc: 2 [h264 @ 0x561264a161c0] New frame, type: B [h264 @ 0x561264a161c0] d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d  d   I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  Id  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I [h264 @ 0x5612649f0f00] I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I nal_unit_type: 1(Coded slice of a non-IDR picture), nal_ref_idc: 0 [h264 @ 0x5612649f0f00]  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I [h264 @ 0x5612649f0f00] I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  I  New frame, type: P [h264 @ 0x5612649c25c0] S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S  S what are all the III.. DDD... and SSS correspond to
        .....
    
        This is ffmpeg macroblock type visualization using d **debug mb_type** flags, specifically from the
        H.264 decoder. These letters codes represent the **type or states of individual macroblocks (MBs)
        within each decoded video frame.

    Macro Block Mode:
        Each letter ( like I,P,B.d, S) correspond to a specofic **macroblock mode or status**

        I = Intra-coded macroblock -> Independently coded using spatial information
        P = Predicted macroblock -> Uses motion prediction from previous frames
        B = Bi-predictive macroblock -> Uses motion prediction from both past and future frames
        S = Skipped macroblock -> No residual; prediction deemed accurate enough
        d = Decoding error /concealed block -> FFmpeg concealed error here (e.g., due to bitstream corruption)
        . = Possibly empty/ not used -> May indicate unused areas or placeholder output

        Additional Macroblocks ( not common ):
        i = Intra 16x16 block -> Specific intra coding Mode
        p = Predicted block -> Luma/Chroma predicted block
        b = Bi-directional predicted block -> Sub-block of a B-frame
        S = Skipped macroblock -> FFmpeg marks skipped macroblocks explicitly
        x = Invalid/unknown macroblock -> Not officially documented; possibly corrupt block
        = 

    When we see "dddd" it means that FFMpeg has detected damage and concealed them using neighboring blocks
    or default methods.


### Using above info for Error detection:

When we are inspecting corrupted or low-quality streams:

    - concentrations of **"d" macroblocks** indicate damaged  areas.
    - This information can be extracted programmatically 
    - Consider combining this with AVFrame.flags **AV_FRAME_FLAG_CORRUPT** for pre-frame indicators.

NOTE: 
    - using `ffmpeg -debug mb_type ...` with a **software decoder** like `h264` consume additional CPU
    1. **Macroblock-Level Analysis**
        * The decoder must **analyze and track the type of each macroblock** (`I`, `P`, `B`, `d`, etc.).
        * This involves inspecting motion vectors, prediction modes, and intra/inter coding decisions for each MB.

    2. **Debug Output is Verbose**
        * FFmpeg prints **thousands of characters per frame** (e.g., 120x68 macroblocks = \~8000 characters/frame).
        * Writing all that to **stdout/stderr** is **surprisingly expensive**, especially in large loops.

    3. **Unoptimized Debug Paths**
        * Debug modes are **not optimized for performance**. 
          They often bypass fast paths or SIMD routines to preserve inspection data.
        * FFmpeg may even disable certain multi-threading optimizations to maintain frame analysis consistency.



    4. **Redirect Output Away from Terminal to file can reduce terminal I/O:
    ```bash
        ffmpeg -debug mb_type -i input.mp4 -f null - 2>mb_debug.log
    ```
    This avoids expensive terminal rendering.

    5. **Use Short Segments**
        Only analyze critical parts of the video:
        ```bash
        ffmpeg -ss 00:01:00 -t 00:00:10 -debug mb_type -i input.mp4 -f null -
        ```

---

# HW decoders:
    

> ❌ **you generally can't access macroblock-level error info like `error_status_table[]` when using 
       HW-accelerated decoders like `h264_v4l2m2m`.**

Here’s why and what your alternatives are:

---
## Why Macroblock-Level Error Detection Doesn't Work with HW Decoders

### 1. **HW Decoders are Black Boxes**

* `h264_v4l2m2m`, `h264_vaapi`, `h264_nvdec`, etc,offload the decoding to a HW unit (VPU, GPU).
* These units **do not expose internal state**, such as macroblock prediction modes or error concealment 
  decisions.
* You only get the output frame — not how the hardware decoded it.

### 2. **No Access to `error_status_table`**

* That array is **specific to FFmpeg’s software H.264 decoder** (in `h264dec.c`).
* HW decoders bypass this code entirely.

### 3. **FFmpeg’s `AVFrame.error[]` and `AV_FRAME_FLAG_CORRUPT`**

* HW decoders might set `AV_FRAME_FLAG_CORRUPT` for gross decoding errors.
* But they do **not fill in `error[]` per-plane or per-macroblock** details.
* Error concealment is handled internally, and often **silently**.

---

## What Can You Do with Hardware Decoders?

### 1. **Detect Frame-Level Corruption**

You can still detect if a frame is entirely corrupt:

```c
if (frame->flags & AV_FRAME_FLAG_CORRUPT) {
    // Frame likely had a decoding problem
}
```

But this only tells you that *something went wrong* — not *where*.

---

### 2. **Use Software Decoder for Error Analysis**

If you want **detailed diagnostics** (like macroblock error maps), you must use:

```bash
ffmpeg -c:v h264 -debug mb_type -i input.mp4 -f null -
```

Only `-c:v h264` (software decoder) supports macroblock type output and error status tracking.

---

### 3. **Hybrid Approach**

If your goal is **diagnostics**, not playback performance:

* Use the software decoder for:

  * **first-pass analysis** (detect corruption, visualize error maps)
  * **flagging bad frames**
* Use hardware decoder for:

  * **real-time or efficient playback**

This hybrid strategy is common in video quality assurance (VQA) pipelines.

---

## Summary Table

| Feature                     | SW Decoder (`h264`) | Hardware Decoder (`h264_v4l2m2m`) |
| --------------------------- | ------------------- | --------------------------------- |
| Macroblock type logging     | Yes                 | No                                |
| `error_status_table[]`      | Yes                 | No                                |
| `AV_FRAME_FLAG_CORRUPT` set | Yes                 | Sometimes                         |
| Per-frame decoding info     | Rich                | Limited                           |
| Performance                 | Slower              | Fast (hardware-accelerated)       |

---



