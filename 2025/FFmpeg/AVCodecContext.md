# AVCodecContext:

## What is `AVCodecContext`?

### TL;DR

`AVCodecContext` is the **central runtime object** for encoding or decoding.
It is created from an `AVCodec` and holds all **configuration, state, buffers**, and **errors** related to 
the codec.

---

## Where `AVCodecContext` Fits in FFmpeg's Pipeline

```text
   ┌────────────────────┐
   │   AVFormatContext  │ ← demuxes packets from file
   └────────────────────┘
             ↓
        AVPacket (compressed)
             ↓
   ┌────────────────────┐
   │   AVCodecContext   │ ← decodes/encodes
   └────────────────────┘
             ↓
         AVFrame (raw data)
```

---

## `AVCodecContext` in Simple Terms

| Think of it like...      | `AVCodecContext` role                                |
| ------------------------ | ---------------------------------------------------- |
| Decoder/Encoder instance | Holds state & logic per stream                       |
| Runtime machine          | Applies the `AVCodec` instructions                   |
| Worker class             | Accepts input (`AVPacket`), gives output (`AVFrame`) |

---

## Creating & Using `AVCodecContext`

```c
const AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
AVCodecContext *ctx = avcodec_alloc_context3(codec);
avcodec_open2(ctx, codec, NULL);
```

---

##  Key Fields of `AVCodecContext`

```c
typedef struct AVCodecContext {
    const AVCodec *codec;         // The codec used (H.264, etc.)
    enum AVCodecID codec_id;
    int width, height;
    int sample_rate;
    int channels;
    int flags;                    // e.g., AV_CODEC_FLAG2_SHOW_ALL
    int error_concealment;
    int err_recognition;
    int skip_frame;
    int skip_idct;
    int skip_loop_filter;
    int debug;                    // FF_DEBUG_* flags
    void *priv_data;              // Codec-specific state
    ...
} AVCodecContext;
```

---

##  Error Reporting Capabilities of `AVCodecContext`

###  1. **Return Codes from Decoding/Encoding Functions**

When calling `avcodec_send_packet()` or `avcodec_receive_frame()`, errors from decoding (bad bitstream, 
corruption, etc.) are returned via negative error codes:

```c
ret = avcodec_send_packet(ctx, &pkt);
if (ret < 0) {
    fprintf(stderr, "Error submitting packet: %s\n", av_err2str(ret));
}
```

Common error codes:

* `AVERROR_INVALIDDATA` – corrupted or invalid stream
* `AVERROR(EAGAIN)` – need more input
* `AVERROR_EOF` – end of stream

---

### 2. **Frame-Level Corruption Flags**

Once you decode a frame:

```c
ret = avcodec_receive_frame(ctx, frame);
if (ret >= 0 && (frame->flags & AV_FRAME_FLAG_CORRUPT)) {
    fprintf(stderr, "Decoded frame is corrupt!\n");
}
```

---

### 3. **Error Resilience Configuration**

Control how strict or lenient the decoder is:

```c
ctx->err_recognition = AV_EF_CRCCHECK | AV_EF_COMPLIANT | AV_EF_EXPLODE;
```

| Flag               | Meaning                       |
| ------------------ | ----------------------------- |
| `AV_EF_CRCCHECK`   | Check CRCs in streams         |
| `AV_EF_EXPLODE`    | Abort on minor issues         |
| `AV_EF_IGNORE_ERR` | Ignore known error conditions |

---

### 4. **Debug Output (Macroblocks, Skips, etc.)**

You can activate debug modes:

```c
ctx->debug = FF_DEBUG_MB_TYPE | FF_DEBUG_SKIP;
```

With FFmpeg CLI:

```bash
ffmpeg -debug mb_type -flags2 +showall -i input.mp4 -f null -
```

This will print macroblock types:

* `I` = Intra
* `P` = Predicted
* `B` = Bi-directional
* `d` = dropped/corrupt
* `S` = skipped

Only works for **software codecs** (e.g., `h264`, `mpeg2video`), not hardware.

---

### 5. **Hardware Decoder Error Reporting**

HW decoders (`h264_vaapi`, `h264_v4l2m2m`) use `AVCodecContext` too, but usually:

* Cannot report macroblock-level corruption
* May log decode failures generically
* Cannot set `AV_FRAME_FLAG_CORRUPT` reliably

---

## AVCodecContext Diagnostic Parameters Summary

| Field / API                            | Purpose                                  | Error Relevance          |
| -------------------------------------- | ---------------------------------------- | ------------------------ |
| `avcodec_send_packet()`                | Input compressed data                    | ✅ Detect invalid packets |
| `avcodec_receive_frame()`              | Get decoded frame                        | ✅ Detect decode errors   |
| `frame->flags & AV_FRAME_FLAG_CORRUPT` | Frame corruption detected                | ✅ Yes                    |
| `ctx->err_recognition`                 | Decoder error policy                     | ✅ Configurable           |
| `ctx->debug`                           | Macroblock/debug output                  | ✅ Yes (SW only)          |
| `ctx->skip_*`                          | Skip certain decoding stages             | ⚠️ Might hide errors     |
| `ctx->codec->capabilities`             | Check if codec supports error resilience | ⚠️ Indirect              |

---

## Typical Error Handling Flow with AVCodecContext

```c
// Submit packet
ret = avcodec_send_packet(codec_ctx, &pkt);
if (ret < 0) {
    fprintf(stderr, "Packet error: %s\n", av_err2str(ret));
    // might be corrupted or missing data
}

// Receive decoded frame
ret = avcodec_receive_frame(codec_ctx, frame);
if (ret == 0) {
    if (frame->flags & AV_FRAME_FLAG_CORRUPT) {
        fprintf(stderr, "Decoded frame is corrupt\n");
    }
}
```

---

## Limitations

| Limitation                       | Notes                                   |
| -------------------------------- | --------------------------------------- |
| Does not parse container/format  | That’s `AVFormatContext`'s job          |
| Frame-level errors only          | No per-pixel or per-block granularity   |
| HW decoders offer limited detail | Often return only generic failure codes |

---

## Summary: AVCodecContext and Error Reporting

| Feature                           | Can AVCodecContext Handle?    |
| --------------------------------- | ----------------------------- |
| Detect invalid compressed packets | ✅ via `avcodec_send_packet()` |
| Detect frame corruption           | ✅ via `frame->flags`          |
| Control error handling policy     | ✅ via `err_recognition`       |
| Log macroblock types              | ✅ with `debug` (SW only)      |
| Detect stream-level I/O errors    | ❌ use `AVFormatContext`       |
| Support HW decoding errors        | ⚠️ Limited                    |

---

