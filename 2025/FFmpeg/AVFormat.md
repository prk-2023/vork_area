# AVFormat:


**deep dive into `AVFormat` and `AVFormatContext`**, 

* Their roles in the FFmpeg pipeline
* Practical field usages
* Error detection capabilities
* Real-world examples

---

## What is `AVFormat` / `AVFormatContext`?

### TL;DR:

* `AVFormat` (or `AVInputFormat` / `AVOutputFormat`) defines a **container format**, like MP4, MKV, FLV, TS, AVI.
* `AVFormatContext` is an **instance** that holds **all the state** for a specific media file/stream:

  * The container format (e.g., is it MP4?)
  * The streams inside it (video, audio, subtitles…)
  * I/O context, options, timing, metadata, and more.

---

## 🏗️ Where `AVFormatContext` Fits in FFmpeg

```text
            File/Stream (MP4, MKV, etc.)
                     ↓
           ┌─────────────────────┐
           │  AVFormatContext    │
           └─────────────────────┘
             ↓             ↓
        AVInputFormat   AVStream[]
                           ↓
                     AVCodecParameters
```

* For input: it's tied to `AVInputFormat`
* For output: it's tied to `AVOutputFormat`

---

## 🔍 `AVFormatContext` Structure Overview

```c
typedef struct AVFormatContext {
    const AVClass *av_class;
    AVInputFormat *iformat;       // For input: describes the container
    AVOutputFormat *oformat;      // For output: describes the container
    void *priv_data;              // Format-specific private data

    AVIOContext *pb;              // I/O layer (file, stream, etc.)
    
    unsigned int nb_streams;      // Number of streams (video, audio, etc.)
    AVStream **streams;           // Array of pointers to AVStream

    char filename[1024];          // Source filename
    int64_t duration;             // Total duration (in AV_TIME_BASE units)
    int64_t start_time;
    int64_t bit_rate;
    
    AVDictionary *metadata;       // File-level metadata

    int flags;
    ...
} AVFormatContext;
```

---

## Core Responsibilities of `AVFormatContext`

| Role                   | Description                                  |
| ---------------------- | -------------------------------------------- |
| Container management   | Understands how to read/write MP4, MKV, etc. |
| Stream discovery       | Finds embedded media streams                 |
| Timestamp and duration | Calculates and manages stream timing         |
| I/O operations         | Works with `AVIOContext` to read/write data  |
| Metadata access        | Reads file-level metadata (title, author…)   |
| Format options         | Holds muxing/demuxing flags and behaviors    |

---

## Example: Opening a File and Reading Streams

```c
AVFormatContext *fmt_ctx = NULL;
if (avformat_open_input(&fmt_ctx, "input.mp4", NULL, NULL) < 0) {
    fprintf(stderr, "Could not open input file\n");
}
if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
    fprintf(stderr, "Failed to retrieve stream info\n");
}
av_dump_format(fmt_ctx, 0, "input.mp4", 0);  // logs container info
```

---

## Error Reporting & Diagnostics via `AVFormatContext`

### 1. **Input Container Errors**

```c
AVFormatContext *fmt_ctx;
if (avformat_open_input(&fmt_ctx, "file.ts", NULL, NULL) < 0) {
    fprintf(stderr, "Could not recognize or open container format\n");
}
```

Can detect:

* Unrecognized format (bad magic bytes)
* I/O errors (corrupt or inaccessible file)

---

### 2. **Stream Info Inference Failure**

```c
if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
    fprintf(stderr, "Could not find stream info - possibly corrupted\n");
}
```

Symptoms:

* File is playable but reports no video/audio streams
* Causes decoders to misbehave due to missing timing

---

### 3. **File-Level Metadata Inspection**

```c
AVDictionaryEntry *tag = NULL;
while ((tag = av_dict_get(fmt_ctx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
    printf("%s: %s\n", tag->key, tag->value);
}
```

Detects missing/incorrect:

* Title
* Author
* Encoding software

---

### 4. **Invalid Duration or Bitrate**

```c
if (fmt_ctx->duration <= 0 || fmt_ctx->bit_rate == 0) {
    fprintf(stderr, "Stream has invalid duration or bitrate\n");
}
```

Common with:

* Incomplete recordings
* Broken remuxing tools
* Fragmented MP4s (need special flags)

---

### 5. **Custom I/O Errors**

If using custom `AVIOContext` (e.g., reading from a network or memory), errors can be:

* Logged from `pb->error`
* Trapped in your `read_packet()` / `seek()` callbacks

---

##  Common Real-World Problems Detected via AVFormatContext

| Problem                            | Detection Method                        |
| ---------------------------------- | --------------------------------------- |
| Format not recognized              | `avformat_open_input()` fails           |
| No stream info (duration, streams) | `avformat_find_stream_info()` fails     |
| Invalid/missing file metadata      | Check `metadata`                        |
| Truncated/corrupted file           | Missing streams or broken `AVIOContext` |
| Zero duration or bitrate           | `duration == 0` or `bit_rate == 0`      |
| Missing timestamps                 | `start_time == AV_NOPTS_VALUE`          |

---

## Output Use Case Example

```c
avformat_alloc_output_context2(&fmt_ctx, NULL, "mp4", "output.mp4");

AVStream *out_stream = avformat_new_stream(fmt_ctx, NULL);
out_stream->time_base = (AVRational){1, 25};

if (!(fmt_ctx->oformat->flags & AVFMT_NOFILE)) {
    avio_open(&fmt_ctx->pb, "output.mp4", AVIO_FLAG_WRITE);
}

avformat_write_header(fmt_ctx, NULL);  // write container header
```

Here, `AVFormatContext` manages the entire output pipeline.

---

## Summary Table: Key Fields in `AVFormatContext`

| Field             | Description                           | Error Use           |
| ----------------- | ------------------------------------- | ------------------- |
| `iformat/oformat` | Container format handler              | ✅ Invalid container |
| `pb`              | I/O handler (file, memory, network)   | ✅ File access error |
| `streams`         | Array of AVStream\*                   | ✅ Missing streams   |
| `duration`        | File duration in AV\_TIME\_BASE units | ✅ Broken file       |
| `bit_rate`        | Global bitrate estimate               | ✅ Low/zero bitrate  |
| `metadata`        | Global metadata for the file          | ✅ Tag inspection    |

---

## Summary: `AVFormatContext` and Error Reporting

| Can Detect                             | Supported?                    |
| -------------------------------------- | ----------------------------- |
| Unknown or invalid container format    | ✅                             |
| No stream information                  | ✅                             |
| File-level metadata issues             | ✅                             |
| I/O problems (cannot read, seek, etc.) | ✅                             |
| Per-stream duration/timestamp mismatch | ✅ (indirect via streams)      |
| Corrupt codec data                     | ❌ (handled in AVCodecContext) |
| Frame-level data corruption            | ❌ (use AVFrame)               |

---

