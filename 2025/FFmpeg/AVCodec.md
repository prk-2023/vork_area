# AVCodec: 
---

## What is `AVCodec`?

### TL;DR

`AVCodec` is an **FFmpeg descriptor** — it describes a codec (like H.264, AAC, etc.), but 
**does not hold state**.

It’s essentially a **blueprint** or **plugin** that knows how to **encode** or **decode** specific formats.

---

## Where `AVCodec` Fits in the FFmpeg Stack

```text
          ┌──────────────┐
          │ AVFormatContext (Demuxer)      ──> Provides AVPacket
          └──────────────┘
                    ↓
          ┌──────────────┐
          │ AVCodecContext (Decoder Instance) ──> Holds state
          └──────────────┘
                    ↑
          ┌──────────────┐
          │ AVCodec (Blueprint / static)     ──> Describes capabilities
          └──────────────┘
```

---

## AVCodec in Simple Terms

| Think of it like...     | `AVCodec` role                            |
| ----------------------- | ----------------------------------------- |
| Class Definition        | Describes how decoding/encoding is done   |
| Plugin Module           | Registered codec module                   |
| Recipe or Specification | What formats it supports, features it has |

---

## AVCodec Structure (Key Fields)

```c
typedef struct AVCodec {
    const char *name;              // "h264", "aac", etc.
    enum AVMediaType type;        // AVMEDIA_TYPE_VIDEO, AUDIO, etc.
    enum AVCodecID id;            // e.g., AV_CODEC_ID_H264
    int capabilities;             // AV_CODEC_CAP_* flags
    const AVClass *priv_class;   // For options/config
    int (*init)(AVCodecContext *);     // Init callback
    int (*decode)(AVCodecContext *, AVFrame *, ...); // SW decoders
    int (*encode2)(AVCodecContext *, AVPacket *, ...); // Encoders
    const AVCodecHWConfig **hw_configs; // HW-accel supported
    ...
} AVCodec;
```

---

## Key Capabilities and Flags

```c
AV_CODEC_CAP_DRAW_HORIZ_BAND
AV_CODEC_CAP_TRUNCATED
AV_CODEC_CAP_FRAME_THREADS
AV_CODEC_CAP_SLICE_THREADS
AV_CODEC_CAP_HWACCEL
```

These determine **how** the codec behaves (threading, HW support, etc.).

---

## Example: AVCodec for H.264

```c
const AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);

printf("Codec: %s\n", codec->name); // "h264"
printf("Type: %d\n", codec->type);  // AVMEDIA_TYPE_VIDEO
printf("HW support? %s\n", codec->capabilities & AV_CODEC_CAP_HWACCEL ? "Yes" : "No");
```

---

## How `AVCodec` Is Used

You **never use `AVCodec` directly**. Instead:

1. Use `avcodec_find_decoder()` or `avcodec_find_encoder()`
2. Then allocate a working context: `AVCodecContext`
3. Initialize it with that codec: `avcodec_open2()`

### Example:

```c
const AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
AVCodecContext *ctx = avcodec_alloc_context3(codec);
avcodec_open2(ctx, codec, NULL);
```

---

## Difference Between `AVCodec` and `AVCodecContext`

| Feature            | `AVCodec`         | `AVCodecContext`                     |
| ------------------ | ----------------- | ------------------------------------ |
| Static or dynamic? | Static (shared)   | Dynamic (per use/stream)             |
| Holds state/data?  | ❌ No              | ✅ Yes                                |
| Thread-safe?       | ✅ Yes (read-only) | ❌ Only if synchronized               |
| Customizable?      | ❌ No              | ✅ Fully customizable (bitrate, etc.) |
| Needed to decode?  | ✅ As a blueprint  | ✅ As a runtime object                |

---

## HW Accelerated Codec Detection

Want to list codecs that support hardware acceleration?

```c
const AVCodec *codec = NULL;
while ((codec = av_codec_next(codec))) {
    if ((codec->capabilities & AV_CODEC_CAP_HWACCEL) &&
        codec->type == AVMEDIA_TYPE_VIDEO) {
        printf("HW-capable codec: %s\n", codec->name);
    }
}
```

---

## Related API Functions

| Function                         | Purpose                                    |
| -------------------------------- | ------------------------------------------ |
| `avcodec_find_decoder()`         | Find a decoder by codec ID                 |
| `avcodec_find_encoder()`         | Find an encoder by codec ID                |
| `avcodec_find_decoder_by_name()` | Find by string name (e.g., `"h264_cuvid"`) |
| `av_codec_next()`                | Iterate all registered codecs              |

---

## Example Use Cases

### Decode H.264 with software:

```c
const AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
// returns "h264" (software decoder)
```

### Decode H.264 with hardware (if available):

```c
const AVCodec *codec = avcodec_find_decoder_by_name("h264_v4l2m2m");
```

---

## Summary Table

| Field            | Description                                |
| ---------------- | ------------------------------------------ |
| `name`           | Codec name (e.g., "h264", "aac")           |
| `id`             | Codec ID enum (e.g., `AV_CODEC_ID_H264`)   |
| `type`           | `AVMEDIA_TYPE_VIDEO`, etc.                 |
| `capabilities`   | Flags like `AV_CODEC_CAP_FRAME_THREADS`    |
| `decode/encode2` | Pointers to actual encode/decode functions |
| `hw_configs`     | List of supported HW acceleration methods  |

---

## Summary

* `AVCodec` = static descriptor for codecs
* Used to create `AVCodecContext`, which does the real work
* Required for both software and hardware encoders/decoders
* Does **not** carry state or media data — only metadata + function pointers
* Paired with `AVPacket`/`AVFrame` for actual I/O

---

# Error repoting:

If any **error detection** can be performed using **`AVCodec`**, and how it compares to `AVCodecContext` or 
`AVFrame`.

---

## Can `AVCodec` Be Used for Error Detection?

> ** No — `AVCodec` itself cannot detect runtime errors.**

---

###  Why?

Because `AVCodec` is a **static descriptor** — it tells you:

* What codec is supported (`AV_CODEC_ID_H264`)
* What media types are handled (`VIDEO`, `AUDIO`)
* Whether it supports hardware acceleration or threading
* Pointers to encode/decode functions

But it **does not**:

* Process any media
* Store any decoding state
* Track or report errors

---

## What You *Can* Infer from `AVCodec` (Indirectly Related to Errors)

### 1. **Whether a Codec Supports Error Recovery**

Check if a codec has `AV_CODEC_CAP_DR1`, `AV_CODEC_CAP_TRUNCATED`, or `AV_CODEC_CAP_SLICE_THREADS`, which 
hint at robustness:

| Capability                   | Description                                            | Error Related?         |
| ---------------------------- | ------------------------------------------------------ | ---------------------- |
| `AV_CODEC_CAP_TRUNCATED`     | Can handle truncated bitstreams (missing data)         | Partial                |
| `AV_CODEC_CAP_FRAME_THREADS` | Can decode with multiple threads (improves resilience) | Indirectly             |
| `AV_CODEC_CAP_HWACCEL`       | Can use HW acceleration                                | No error info directly |

 These do **not detect errors**, but **inform how well the codec might deal with imperfect input**.

---

### 2. **Whether It’s a Robust Decoder**

You can check the codec name:

* `"h264"` → standard software decoder, with full FFmpeg error reporting
* `"h264_cuvid"` → GPU decoder (less informative)
* `"h264_v4l2m2m"` → VPU decoder (least insight into bitstream errors)

This helps you choose a codec based on the level of error diagnostics you want.

---

## What `AVCodec` Cannot Do

| Task                             | `AVCodec` Support?            |
| -------------------------------- | ----------------------------- |
| Report corrupted macroblocks     | ❌                             |
| Set or check frame corrupt flags | ❌                             |
| Log decoding issues              | ❌ (done via `AVCodecContext`) |
| Detect malformed bitstreams      | ❌ (done during decode)        |

---

##  What To Use for Error Detection Instead

| Task                          | Use This FFmpeg Object                                          |
| ----------------------------- | --------------------------------------------------------------- |
| Detect corrupt frames         | `AVFrame` (`AV_FRAME_FLAG_CORRUPT`)                             |
| Handle decode return codes    | `AVCodecContext` + return values from `avcodec_receive_frame()` |
| Enable debug printing         | `AVCodecContext->debug = FF_DEBUG_MB_TYPE`, etc.                |
| Monitor macroblock errors     | Use software codec with `-debug mb_type`                        |
| Detect invalid data in packet | Return code from `avcodec_send_packet()` or `av_log()` output   |

---

##  Example: Using `AVCodec` in Setup Only

```c
const AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
AVCodecContext *ctx = avcodec_alloc_context3(codec);

if (!(codec->capabilities & AV_CODEC_CAP_TRUNCATED)) {
    printf("Warning: This codec does not tolerate truncated streams.\n");
}

avcodec_open2(ctx, codec, NULL);
```

This warns you early that the codec is not suitable for error-prone streams — but again, this is **not error
detection**, it's **capability awareness**.

---

## Summary

| Feature                       | `AVCodec`                                      | Error Related? |
| ----------------------------- | ---------------------------------------------- | -------------- |
| Static codec descriptor       | ✅                                              | ❌              |
| Detects malformed data        | ❌                                              |                |
| Reports corrupt frames        | ❌                                              |                |
| Offers hints about resilience | ✅ (via flags)                                  | ✅ Indirect     |
| Real error handling occurs in | `AVCodecContext`, `AVFrame`, decoder internals | ✅ Yes          |


