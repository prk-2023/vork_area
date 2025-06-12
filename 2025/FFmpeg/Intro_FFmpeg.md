# FFMpeg libs:

A **high-level sequential flow** using the core structures in this folder :

---

##  FFmpeg Demuxing + Decoding Sequence (Input/Read Flow)

This is the most common use case: **Reading from a media file**, **extracting packets**, **decoding them into frames**.

### Structures Involved:

| Order | Structure           | Role                                   |
| ----- | ------------------- | -------------------------------------- |
| 1️⃣   | `AVFormatContext`   | Opens and manages the container format |
| 2️⃣   | `AVStream`          | Describes individual media streams     |
| 3️⃣   | `AVCodecParameters` | Stores codec info per stream           |
| 4️⃣   | `AVCodec`           | Represents the decoder type            |
| 5️⃣   | `AVCodecContext`    | Manages actual decoding process        |
| 6️⃣   | `AVPacket`          | Compressed data from file              |
| 7️⃣   | `AVFrame`           | Raw uncompressed decoded output        |

---

## Step-by-Step Flow Diagram

```text
            📁 Open media file
                ↓
    1. avformat_open_input() ─────▶ AVFormatContext
    2. avformat_find_stream_info()
                ↓
    3. for each AVStream (AVFormatContext->streams[i]):
        ↓
      a. Get AVCodecParameters
      b. Use avcodec_find_decoder()
      c. Allocate AVCodecContext → avcodec_alloc_context3()
      d. Fill AVCodecContext from parameters → avcodec_parameters_to_context()
      e. Open codec → avcodec_open2()
                ↓
    4. while (av_read_frame()):
        ↓
      a. Read AVPacket
      b. Check AVPacket.stream_index
      c. Send to decoder:
         avcodec_send_packet() → AVCodecContext
         avcodec_receive_frame() → AVFrame
                ↓
      d. Process AVFrame (display, encode, write, analyze)
```

---

## Key FFmpeg Function Flow

| Step | Function                          | Purpose                           |
| ---- | --------------------------------- | --------------------------------- |
| 1    | `avformat_open_input()`           | Opens media container             |
| 2    | `avformat_find_stream_info()`     | Reads and parses stream metadata  |
| 3    | `avcodec_find_decoder()`          | Locates the decoder type          |
| 4    | `avcodec_alloc_context3()`        | Creates decoding context          |
| 5    | `avcodec_parameters_to_context()` | Fills codec context from stream   |
| 6    | `avcodec_open2()`                 | Initializes the codec             |
| 7    | `av_read_frame()`                 | Reads next `AVPacket`             |
| 8    | `avcodec_send_packet()`           | Sends packet to decoder           |
| 9    | `avcodec_receive_frame()`         | Receives decoded `AVFrame`        |
| 10   | Process or display `AVFrame`      | Final output (write/display/etc.) |

---

## Visual Summary

```text
AVFormatContext
 └── AVStream[]
       └── AVCodecParameters → AVCodec
                                ↓
                            AVCodecContext
                                 ↑
                             AVPacket (compressed data)
                                 ↓
                             AVFrame (decoded output)
```

---

## Optional Error Detection Layers

You can check for errors at many levels:

| Component       | Error to Detect                       | Function/Field                      |
| --------------- | ------------------------------------- | ----------------------------------- |
| AVFormatContext | Invalid container, no streams         | `avformat_open_input()`             |
| AVStream        | No codec, bad metadata                | `AVStream->codecpar`                |
| AVCodec         | Unsupported codec                     | `avcodec_find_decoder()`            |
| AVCodecContext  | Decoding failure, corrupted bitstream | `avcodec_send_packet/receive_frame` |
| AVPacket        | Incomplete or invalid compressed data | `packet.size == 0` or flags         |
| AVFrame         | Corrupted output, missing macroblocks | `frame->flags`, debug flags         |

---

## Minimal Pseudo Code

```c
avformat_open_input(&fmt_ctx, filename, NULL, NULL);
avformat_find_stream_info(fmt_ctx, NULL);

for (int i = 0; i < fmt_ctx->nb_streams; i++) {
    AVStream *stream = fmt_ctx->streams[i];
    AVCodec *dec = avcodec_find_decoder(stream->codecpar->codec_id);
    AVCodecContext *codec_ctx = avcodec_alloc_context3(dec);
    avcodec_parameters_to_context(codec_ctx, stream->codecpar);
    avcodec_open2(codec_ctx, dec, NULL);
}

while (av_read_frame(fmt_ctx, &pkt) >= 0) {
    if (pkt.stream_index == video_stream_index) {
        avcodec_send_packet(codec_ctx, &pkt);
        while (avcodec_receive_frame(codec_ctx, frame) == 0) {
            // Use frame here (e.g., display, encode, analyze)
        }
    }
    av_packet_unref(&pkt);
}
```
---

## Next Steps: What Can You Explore?

* **Error resilience**: Check which stream or frame is corrupted
* **Custom I/O**: Use your own `AVIOContext` for reading from memory/network
* **Timestamps & Synchronization**: Use `pts/dts` for sync
* **Filtering**: Insert `AVFilterGraph` to process video/audio
* **Multi-threading**: Use FFmpeg’s multithreaded decoding flags

---

# FFmpeg Encoding + Muxing Sequence (Output/Write Flow)

This covers how to **take raw frames, encode them, and write them to a container**.

---

## Core Structures

| Order | Structure         | Role                                         |
| ----- | ----------------- | -------------------------------------------- |
| 1️⃣   | `AVFormatContext` | Manage output container (file, stream, etc.) |
| 2️⃣   | `AVStream`        | Output stream info inside container          |
| 3️⃣   | `AVCodec`         | Encoder type                                 |
| 4️⃣   | `AVCodecContext`  | Encoder state and params                     |
| 5️⃣   | `AVFrame`         | Raw uncompressed input frames                |
| 6️⃣   | `AVPacket`        | Encoded compressed data packets              |
| 7️⃣   | `AVIOContext`     | (Optional) Custom I/O for output             |

---

## Step-by-Step Encoding Flow

```text
         Create and open output container
                    ↓
       1. avformat_alloc_output_context2() → AVFormatContext
       2. avformat_new_stream() for each media stream → AVStream
       3. Find encoder → avcodec_find_encoder()
       4. Allocate & setup AVCodecContext for encoder → avcodec_alloc_context3(), set params
       5. Open encoder → avcodec_open2()
       6. If needed, open AVIOContext for output file
       7. Write container header → avformat_write_header()
                    ↓
       8. For each raw input AVFrame:
           a. Send frame to encoder → avcodec_send_frame()
           b. Receive encoded AVPacket → avcodec_receive_packet()
           c. Write packet to output → av_interleaved_write_frame()
                    ↓
       9. Flush encoder (send NULL frame)
      10. Write trailer → av_write_trailer()
      11. Close & cleanup
```

---

## Key Functions Used

| Step | Function                           | Purpose                              |
| ---- | ---------------------------------- | ------------------------------------ |
| 1    | `avformat_alloc_output_context2()` | Allocate output format context       |
| 2    | `avformat_new_stream()`            | Create new output stream             |
| 3    | `avcodec_find_encoder()`           | Find encoder by codec id             |
| 4    | `avcodec_alloc_context3()`         | Allocate codec context               |
| 5    | Set parameters on codec\_ctx       | Set width, height, pix\_fmt, bitrate |
| 6    | `avcodec_open2()`                  | Open encoder                         |
| 7    | `avio_open()`                      | Open output file/stream (optional)   |
| 8    | `avformat_write_header()`          | Write container header               |
| 9    | `avcodec_send_frame()`             | Send raw frame to encoder            |
| 10   | `avcodec_receive_packet()`         | Get encoded packet from encoder      |
| 11   | `av_interleaved_write_frame()`     | Write packet to output               |
| 12   | `avcodec_send_frame(NULL)`         | Flush encoder                        |
| 13   | `av_write_trailer()`               | Write container trailer              |

---

## Visual Summary (Encoding Flow)

```text
AVFormatContext (output container)
 └── AVStream[] (output streams)
       └── AVCodec + AVCodecContext (encoder)
            ↑                    ↓
         AVFrame (raw input) → AVPacket (encoded output)
                                ↓
                        av_interleaved_write_frame()
                                ↓
                       Output container (file/stream)
```

---

## Minimal Encoding Pseudo Code

```c
avformat_alloc_output_context2(&fmt_ctx, NULL, NULL, filename);
AVStream *out_stream = avformat_new_stream(fmt_ctx, NULL);

AVCodec *encoder = avcodec_find_encoder(codec_id);
AVCodecContext *codec_ctx = avcodec_alloc_context3(encoder);
codec_ctx->width = width;
codec_ctx->height = height;
codec_ctx->pix_fmt = AV_PIX_FMT_YUV420P;
codec_ctx->time_base = (AVRational){1, 25};
// Set other encoder parameters as needed
avcodec_open2(codec_ctx, encoder, NULL);

avformat_write_header(fmt_ctx, NULL);

while (get_raw_frame(frame)) {
    avcodec_send_frame(codec_ctx, frame);
    while (avcodec_receive_packet(codec_ctx, &pkt) == 0) {
        av_interleaved_write_frame(fmt_ctx, &pkt);
        av_packet_unref(&pkt);
    }
}

// Flush encoder
avcodec_send_frame(codec_ctx, NULL);
while (avcodec_receive_packet(codec_ctx, &pkt) == 0) {
    av_interleaved_write_frame(fmt_ctx, &pkt);
    av_packet_unref(&pkt);
}

av_write_trailer(fmt_ctx);
```

---

## Error and Status Checks

* `avformat_alloc_output_context2()`: fail to create container
* `avformat_new_stream()`: error creating output stream
* `avcodec_find_encoder()`: encoder not found
* `avcodec_open2()`: encoder init error
* `avcodec_send_frame() / avcodec_receive_packet()`: encoding errors or output not ready
* `av_interleaved_write_frame()`: disk write / I/O errors
* `av_write_trailer()`: finalize errors

---

## Next Steps & Advanced Topics

* Use **hardware-accelerated encoders** (e.g., VAAPI, NVENC)
* Implement **custom output sinks** with `AVIOContext`
* Use **filters (`AVFilterGraph`)** to process frames before encoding
* Handle **multiple audio/video streams**
* Use **timestamp and rate control** properly for sync & smooth playback

---


# Hardware Accelerated Decoding & Encoding Flow

**Hardware accelerated decoding and encoding** using the **`h264_v4l2m2m`** codec (the V4L2 mem2mem driver).
This uses a dedicated Video Processing Unit (VPU) for H.264 video.

---

## Using `h264_v4l2m2m` (V4L2 mem2mem driver)

---

## 1️⃣ What is `h264_v4l2m2m`?

* **`h264_v4l2m2m`** is a hw-accelerated codec in FFmpeg that interfaces with the Linux V4L2 mem2mem framework.
* It offloads **H.264 decoding or encoding** to a dedicated hw VPU (e.g.,in Raspberry Pi, certain Intel/ARM SoCs).
* Benefits:

  * **Low CPU usage**
  * **Efficient processing**
  * Suitable for embedded & real-time apps

---

## 2️⃣ Key FFmpeg Structures in HW Accel Context

| Structure         | Role                                                      |
| ----------------- | --------------------------------------------------------- |
| `AVFormatContext` | Container format handling (input/output)                  |
| `AVCodec`         | Codec reference for `h264_v4l2m2m`                        |
| `AVCodecContext`  | Codec instance, holds HW-specific options                 |
| `AVFrame`         | Raw frames (for decoding) or input frames (for encoding)  |
| `AVPacket`        | Compressed packets                                        |
| `AVBufferRef`     | Holds HW frames or buffers (used internally for HW accel) |

---

## 3️⃣ Important Differences From SW Decoding/Encoding

| Aspect                | Software (SW) Codec            | Hardware (HW) Codec (`h264_v4l2m2m`)                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------ |
| Frame buffers         | System memory (CPU RAM)        | Usually GPU/VPU memory, managed via DMA buffers                    |
| Data transfer         | CPU memory copies              | DMA buffer sharing, zero-copy where possible                       |
| Frame format          | `AV_PIX_FMT_YUV420P` (typical) | Hardware-specific pixel formats (e.g. `AV_PIX_FMT_V4L2M2M`)        |
| Access to macroblocks | Software parses MB data        | Limited or no direct access (driver handles MB parsing internally) |
| Error info            | SW debug logs, MB-level errors | Usually limited, relies on driver/hardware support                 |

---

## 4️⃣ Hardware-Accelerated Decoding Flow (`h264_v4l2m2m`)

```text
1. Open input container → avformat_open_input()
2. Find video stream → avformat_find_stream_info()
3. Find HW decoder → avcodec_find_decoder_by_name("h264_v4l2m2m")
4. Allocate and configure AVCodecContext:
    - Set HW device ctx (V4L2 device node, e.g. /dev/video0)
    - Set codec parameters (extradata, width, height)
5. Open codec → avcodec_open2()
6. Read compressed packets → av_read_frame()
7. Send packets to decoder → avcodec_send_packet()
8. Receive decoded frames → avcodec_receive_frame()
   - Frames stored in HW buffers, may need to map to system memory for display
9. (Optional) Use av_hwframe_transfer_data() to get system memory frames
10. Repeat until end of stream
11. Cleanup and close codec/container
```

---

## 5️⃣ Hardware-Accelerated Encoding Flow (`h264_v4l2m2m`)

```text
1. Allocate AVFormatContext for output
2. Create output stream → avformat_new_stream()
3. Find HW encoder → avcodec_find_encoder_by_name("h264_v4l2m2m")
4. Allocate & configure AVCodecContext:
    - Set encoder parameters (width, height, bitrate, framerate)
    - Set HW device ctx (same as decoder)
5. Open codec → avcodec_open2()
6. Write container header → avformat_write_header()
7. For each raw input AVFrame:
    - Convert AVFrame to HW format if needed
    - Send frame to encoder → avcodec_send_frame()
    - Receive encoded AVPacket → avcodec_receive_packet()
    - Write packet → av_interleaved_write_frame()
8. Flush encoder with NULL frame
9. Write trailer → av_write_trailer()
10. Cleanup and close codec/container
```

---

## 6️⃣ Example of Setting Up HW Device (V4L2 mem2mem) in FFmpeg

```c
AVBufferRef *hw_device_ctx = NULL;
int err = av_hwdevice_ctx_create(&hw_device_ctx, AV_HWDEVICE_TYPE_V4L2, "/dev/video0", NULL, 0);
if (err < 0) {
    fprintf(stderr, "Failed to create V4L2 hw device.\n");
    return err;
}
codec_ctx->hw_device_ctx = av_buffer_ref(hw_device_ctx);
```

* This initializes the V4L2 hardware device context pointing to the VPU device node.
* Assign this context to `AVCodecContext->hw_device_ctx`.

---

## 7️⃣ Important Notes on Error Reporting & Debugging in HW Context

* HW decoding/encoding is often a **black box**; detailed macroblock errors and mb\_type debug info are 
  **not exposed** by hardware drivers.
* You can rely on:

  * `AVERROR` return codes from FFmpeg API functions.
  * Status/error callbacks from driver (if exposed via V4L2 API).
  * Kernel logs (`dmesg`) for device-level errors.
* FFmpeg debug flags like `-debug mb_type` **do NOT work** with HW decoders.
* For corruption or decoding errors, you get **frame drop**, **decoder stalls**, or **stream errors** reported at API level.
* Frame metadata or side-data may sometimes contain error flags if supported.

---

## 8️⃣ How to Check If HW Decoding is Working

* Check `AVCodecContext->hw_frames_ctx` and frame pixel formats (`AV_PIX_FMT_V4L2M2M`).
* Use `ffmpeg -hwaccels` to list supported hardware acceleration methods.
* Use `-hwaccel v4l2m2m` in `ffmpeg` CLI to enable HW decoding.

---

## 9️⃣ Summary

| Step          | FFmpeg API Calls / Concepts                        | HW-specific notes                             |
| ------------- | -------------------------------------------------- | --------------------------------------------- |
| Open input    | `avformat_open_input()`                            | Same as SW, container agnostic                |
| Find codec    | `avcodec_find_decoder_by_name("h264_v4l2m2m")`     | Must explicitly request HW decoder            |
| Setup codec   | Set `hw_device_ctx`, open codec                    | Pass device node path (e.g. `/dev/video0`)    |
| Decode frames | `avcodec_send_packet()`, `avcodec_receive_frame()` | Output frames in HW memory, may need transfer |
| Encode frames | `avcodec_send_frame()`, `avcodec_receive_packet()` | Input frames usually converted to HW format   |
| Write output  | `av_interleaved_write_frame()`                     | Container-agnostic                            |

---

**minimal example code** snippet showing how to setup and use `h264_v4l2m2m` decoder or encoder! 

* Open input file
* Setup HW device context for V4L2 mem2mem
* Find and open the HW decoder
* Read packets, send to decoder, receive frames
* Transfer HW frames to system memory (optional)
* Clean up

---

```c
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/hwcontext.h>
#include <libavutil/imgutils.h>
#include <libavutil/error.h>

static enum AVPixelFormat get_hw_format(AVCodecContext *ctx, const enum AVPixelFormat *pix_fmts) {
    for (const enum AVPixelFormat *p = pix_fmts; *p != -1; p++) {
        if (*p == AV_PIX_FMT_V4L2M2M) // HW accelerated pixel format for V4L2 mem2mem
            return *p;
    }
    fprintf(stderr, "Failed to get HW surface format.\n");
    return AV_PIX_FMT_NONE;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input file>\n", argv[0]);
        return -1;
    }

    const char *input = argv[1];
    int ret;

    // Register all formats and codecs
    av_register_all();

    // Open input file
    AVFormatContext *fmt_ctx = NULL;
    if ((ret = avformat_open_input(&fmt_ctx, input, NULL, NULL)) < 0) {
        fprintf(stderr, "Cannot open input file: %s\n", av_err2str(ret));
        return ret;
    }

    if ((ret = avformat_find_stream_info(fmt_ctx, NULL)) < 0) {
        fprintf(stderr, "Failed to get stream info: %s\n", av_err2str(ret));
        avformat_close_input(&fmt_ctx);
        return ret;
    }

    // Find the first video stream
    int video_stream_index = -1;
    for (unsigned i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }
    if (video_stream_index < 0) {
        fprintf(stderr, "No video stream found.\n");
        avformat_close_input(&fmt_ctx);
        return -1;
    }

    AVStream *video_stream = fmt_ctx->streams[video_stream_index];

    // Find the h264_v4l2m2m decoder
    AVCodec *decoder = avcodec_find_decoder_by_name("h264_v4l2m2m");
    if (!decoder) {
        fprintf(stderr, "Hardware decoder h264_v4l2m2m not found.\n");
        avformat_close_input(&fmt_ctx);
        return -1;
    }

    AVCodecContext *codec_ctx = avcodec_alloc_context3(decoder);
    if (!codec_ctx) {
        fprintf(stderr, "Failed to allocate codec context.\n");
        avformat_close_input(&fmt_ctx);
        return AVERROR(ENOMEM);
    }

    // Copy codec parameters from input stream to codec context
    if ((ret = avcodec_parameters_to_context(codec_ctx, video_stream->codecpar)) < 0) {
        fprintf(stderr, "Failed to copy codec parameters: %s\n", av_err2str(ret));
        goto end;
    }

    // Set callback to choose HW pixel format
    codec_ctx->get_format = get_hw_format;

    // Create HW device context (V4L2 device node)
    ret = av_hwdevice_ctx_create(&codec_ctx->hw_device_ctx, AV_HWDEVICE_TYPE_V4L2, "/dev/video0", NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Failed to create V4L2 HW device context: %s\n", av_err2str(ret));
        goto end;
    }

    // Open codec
    if ((ret = avcodec_open2(codec_ctx, decoder, NULL)) < 0) {
        fprintf(stderr, "Failed to open codec: %s\n", av_err2str(ret));
        goto end;
    }

    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    AVFrame *sw_frame = av_frame_alloc(); // frame in system memory

    if (!pkt || !frame || !sw_frame) {
        fprintf(stderr, "Could not allocate packet or frames\n");
        ret = AVERROR(ENOMEM);
        goto end;
    }

    // Read packets and decode
    while (av_read_frame(fmt_ctx, pkt) >= 0) {
        if (pkt->stream_index == video_stream_index) {
            ret = avcodec_send_packet(codec_ctx, pkt);
            if (ret < 0) {
                fprintf(stderr, "Error sending packet: %s\n", av_err2str(ret));
                break;
            }

            while (ret >= 0) {
                ret = avcodec_receive_frame(codec_ctx, frame);
                if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
                    break;
                else if (ret < 0) {
                    fprintf(stderr, "Error during decoding: %s\n", av_err2str(ret));
                    goto end;
                }

                // HW frame is in frame->format == AV_PIX_FMT_V4L2M2M
                // To use it in system memory, transfer it:
                if (frame->format == AV_PIX_FMT_V4L2M2M) {
                    if ((ret = av_hwframe_transfer_data(sw_frame, frame, 0)) < 0) {
                        fprintf(stderr, "Error transferring HW frame to system memory: %s\n", av_err2str(ret));
                        goto end;
                    }
                    // Now sw_frame contains system memory frame (e.g., AV_PIX_FMT_NV12)
                    printf("Got frame %d (converted to system memory)\n", codec_ctx->frame_number);
                    av_frame_unref(sw_frame);
                } else {
                    // Frame is already in system memory
                    printf("Got frame %d\n", codec_ctx->frame_number);
                }
                av_frame_unref(frame);
            }
        }
        av_packet_unref(pkt);
    }

end:
    av_packet_free(&pkt);
    av_frame_free(&frame);
    av_frame_free(&sw_frame);
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&fmt_ctx);

    return ret < 0 ? 1 : 0;
}
```

---

### How to compile (assuming pkg-config):

```bash
gcc -o hw_decode_v4l2 hw_decode_v4l2.c $(pkg-config --cflags --libs libavformat libavcodec libavutil)
```

---

### Notes:

* Make sure `/dev/video0` corresponds to your VPU device node supporting V4L2 mem2mem.
* Hardware decoder `h264_v4l2m2m` must be present in your FFmpeg build.
* `av_hwframe_transfer_data()` copies or maps hardware frames to system memory for further processing/display.
* This example does **not** render frames — it just decodes and transfers frames.

---

**encoding example** :


**hardware-accelerated encoding** using `h264_v4l2m2m` with FFmpeg libraries.

This example will:

* Open an input video file (software-decoded frames)
* Setup hardware encoder `h264_v4l2m2m` with V4L2 mem2mem device
* Transfer input frames to hardware frames
* Encode frames and write raw H264 output to a file

---

```c
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/hwcontext.h>
#include <libavutil/imgutils.h>
#include <libavutil/error.h>

static enum AVPixelFormat get_hw_format(AVCodecContext *ctx, const enum AVPixelFormat *pix_fmts) {
    for (const enum AVPixelFormat *p = pix_fmts; *p != -1; p++) {
        if (*p == AV_PIX_FMT_V4L2M2M)
            return *p;
    }
    fprintf(stderr, "Failed to get HW surface format.\n");
    return AV_PIX_FMT_NONE;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <input file> <output h264 file>\n", argv[0]);
        return -1;
    }

    const char *input = argv[1];
    const char *output = argv[2];
    int ret;

    av_register_all();

    AVFormatContext *fmt_ctx = NULL;
    if ((ret = avformat_open_input(&fmt_ctx, input, NULL, NULL)) < 0) {
        fprintf(stderr, "Cannot open input file: %s\n", av_err2str(ret));
        return ret;
    }

    if ((ret = avformat_find_stream_info(fmt_ctx, NULL)) < 0) {
        fprintf(stderr, "Failed to get stream info: %s\n", av_err2str(ret));
        avformat_close_input(&fmt_ctx);
        return ret;
    }

    // Find video stream
    int video_stream_index = -1;
    for (unsigned i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }
    if (video_stream_index < 0) {
        fprintf(stderr, "No video stream found.\n");
        avformat_close_input(&fmt_ctx);
        return -1;
    }

    AVStream *video_stream = fmt_ctx->streams[video_stream_index];

    // Find software decoder for input (e.g. libx264)
    AVCodec *decoder = avcodec_find_decoder(video_stream->codecpar->codec_id);
    if (!decoder) {
        fprintf(stderr, "Decoder not found.\n");
        avformat_close_input(&fmt_ctx);
        return -1;
    }

    AVCodecContext *dec_ctx = avcodec_alloc_context3(decoder);
    if (!dec_ctx) {
        fprintf(stderr, "Failed to allocate decoder context.\n");
        avformat_close_input(&fmt_ctx);
        return AVERROR(ENOMEM);
    }

    if ((ret = avcodec_parameters_to_context(dec_ctx, video_stream->codecpar)) < 0) {
        fprintf(stderr, "Failed to copy decoder params: %s\n", av_err2str(ret));
        goto end_dec;
    }

    if ((ret = avcodec_open2(dec_ctx, decoder, NULL)) < 0) {
        fprintf(stderr, "Failed to open decoder: %s\n", av_err2str(ret));
        goto end_dec;
    }

    // Setup encoder
    AVCodec *encoder = avcodec_find_encoder_by_name("h264_v4l2m2m");
    if (!encoder) {
        fprintf(stderr, "HW encoder h264_v4l2m2m not found.\n");
        ret = AVERROR_ENCODER_NOT_FOUND;
        goto end_dec;
    }

    AVCodecContext *enc_ctx = avcodec_alloc_context3(encoder);
    if (!enc_ctx) {
        fprintf(stderr, "Failed to allocate encoder context.\n");
        ret = AVERROR(ENOMEM);
        goto end_dec;
    }

    // Set encoder parameters (match input)
    enc_ctx->width = dec_ctx->width;
    enc_ctx->height = dec_ctx->height;
    enc_ctx->time_base = av_inv_q(video_stream->r_frame_rate);
    enc_ctx->framerate = video_stream->r_frame_rate;
    enc_ctx->pix_fmt = AV_PIX_FMT_V4L2M2M; // HW format

    enc_ctx->get_format = get_hw_format;

    // Create HW device context for V4L2
    ret = av_hwdevice_ctx_create(&enc_ctx->hw_device_ctx, AV_HWDEVICE_TYPE_V4L2, "/dev/video0", NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Failed to create HW device context: %s\n", av_err2str(ret));
        goto end_enc;
    }

    if ((ret = avcodec_open2(enc_ctx, encoder, NULL)) < 0) {
        fprintf(stderr, "Failed to open encoder: %s\n", av_err2str(ret));
        goto end_enc;
    }

    FILE *outfile = fopen(output, "wb");
    if (!outfile) {
        fprintf(stderr, "Could not open output file.\n");
        ret = AVERROR(errno);
        goto end_enc;
    }

    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    AVFrame *hw_frame = av_frame_alloc();

    if (!pkt || !frame || !hw_frame) {
        fprintf(stderr, "Could not allocate packet or frames\n");
        ret = AVERROR(ENOMEM);
        goto end_file;
    }

    // Read, decode, transfer, encode loop
    while (av_read_frame(fmt_ctx, pkt) >= 0) {
        if (pkt->stream_index == video_stream_index) {
            ret = avcodec_send_packet(dec_ctx, pkt);
            if (ret < 0) {
                fprintf(stderr, "Error sending packet to decoder: %s\n", av_err2str(ret));
                break;
            }

            while (ret >= 0) {
                ret = avcodec_receive_frame(dec_ctx, frame);
                if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
                    break;
                else if (ret < 0) {
                    fprintf(stderr, "Error during decoding: %s\n", av_err2str(ret));
                    goto end_file;
                }

                // Allocate hw_frame with same params as encoder expects
                hw_frame->format = enc_ctx->pix_fmt;
                hw_frame->width = enc_ctx->width;
                hw_frame->height = enc_ctx->height;

                if ((ret = av_frame_get_buffer(hw_frame, 0)) < 0) {
                    fprintf(stderr, "Failed to allocate hw_frame buffer: %s\n", av_err2str(ret));
                    goto end_file;
                }

                // Transfer software frame to hardware frame
                ret = av_hwframe_transfer_data(hw_frame, frame, 0);
                if (ret < 0) {
                    fprintf(stderr, "Error transferring data to HW frame: %s\n", av_err2str(ret));
                    goto end_file;
                }

                // Send hw_frame to encoder
                ret = avcodec_send_frame(enc_ctx, hw_frame);
                if (ret < 0) {
                    fprintf(stderr, "Error sending frame to encoder: %s\n", av_err2str(ret));
                    goto end_file;
                }

                while (ret >= 0) {
                    ret = avcodec_receive_packet(enc_ctx, pkt);
                    if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
                        break;
                    else if (ret < 0) {
                        fprintf(stderr, "Error during encoding: %s\n", av_err2str(ret));
                        goto end_file;
                    }

                    fwrite(pkt->data, 1, pkt->size, outfile);
                    av_packet_unref(pkt);
                }

                av_frame_unref(frame);
                av_frame_unref(hw_frame);
            }
        }
        av_packet_unref(pkt);
    }

    // Flush encoder
    avcodec_send_frame(enc_ctx, NULL);
    while (avcodec_receive_packet(enc_ctx, pkt) == 0) {
        fwrite(pkt->data, 1, pkt->size, outfile);
        av_packet_unref(pkt);
    }

end_file:
    fclose(outfile);
end_enc:
    avcodec_free_context(&enc_ctx);
end_dec:
    avcodec_free_context(&dec_ctx);
    avformat_close_input(&fmt_ctx);
    av_packet_free(&pkt);
    av_frame_free(&frame);
    av_frame_free(&hw_frame);

    return ret < 0 ? 1 : 0;
}
```

---

### Compile with:

```bash
gcc -o hw_encode_v4l2 hw_encode_v4l2.c $(pkg-config --cflags --libs libavformat libavcodec libavutil)
```

---

### Notes:

* The input file is decoded in software using a normal decoder, then frames are transferred to HW surfaces 
  for encoding.
* Encoder expects frames in `AV_PIX_FMT_V4L2M2M` format.
* Output is raw H264 bitstream written to file — you can play it with `ffplay output.h264`.
* Modify `/dev/video0` if your V4L2 mem2mem device is on a different node.
* You can adjust encoder parameters via `enc_ctx->...` for bitrate, preset, etc.
---

