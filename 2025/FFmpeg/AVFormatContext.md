# AVFormatContext: 

`AVFormatContext` what it is, how it fits into FFmpeg’s architecture, and how it can be used (directly or 
indirectly) for **error reporting**.

---

## What is `AVFormatContext`?

### TL;DR

`AVFormatContext` is FFmpeg’s **main container-level context** — it manages demuxing (reading) or muxing 
(writing) of media files and streams.

It understands formats like `.mp4`, `.ts`, `.mkv`, `.mov`, `.flv`, etc.

---

## Where AVFormatContext Fits

```text
 ┌────────────────────┐
 │   AVFormatContext  │  ← Reads/Writes files, formats
 └────────────────────┘
           │
     provides AVPacket (compressed data)
           ↓
 ┌────────────────────┐
 │   AVCodecContext   │  ← Decodes packets to frames
 └────────────────────┘
           ↓
 ┌────────────────────┐
 │      AVFrame       │  ← Holds raw decoded data
 └────────────────────┘
```

---

## Key Fields of `AVFormatContext`

```c
typedef struct AVFormatContext {
    const AVInputFormat  *iformat;  // Demuxer (e.g., mov, matroska)
    const AVOutputFormat *oformat;  // Muxer (for encoding)
    AVIOContext          *pb;       // Byte stream (file/network I/O)
    AVStream            **streams;  // Array of media streams
    unsigned int          nb_streams;
    AVDictionary         *metadata;
    int64_t               duration;
    int                   bit_rate;
    int                   flags;
    ...
} AVFormatContext;
```

---

## How AVFormatContext is Used

### 1. Open Input (Demuxer)

```c
AVFormatContext *fmt_ctx = NULL;
avformat_open_input(&fmt_ctx, "input.mp4", NULL, NULL);
avformat_find_stream_info(fmt_ctx, NULL);
```

### 2. Read Packets

```c
AVPacket pkt;
while (av_read_frame(fmt_ctx, &pkt) >= 0) {
    // Feed pkt to decoder
    av_packet_unref(&pkt);
}
```

---

## Error Detection & Reporting with AVFormatContext

Unlike `AVFrame` or `AVCodecContext`, `AVFormatContext` is **less granular** in reporting decode-level 
errors, but it's still crucial for:

---

### 1. **File/Stream-Level Errors**

* Corrupt headers
* Truncated files
* Invalid metadata or index
* Unreadable byte streams

FFmpeg will log errors like:

```
[mov,mp4,m4a,3gp,3g2,mj2 @ 0x...] moov atom not found
```

You can detect these via return codes:

```c
int ret = avformat_open_input(&fmt_ctx, "broken.mp4", NULL, NULL);
if (ret < 0) {
    char errbuf[256];
    av_strerror(ret, errbuf, sizeof(errbuf));
    fprintf(stderr, "Could not open input: %s\n", errbuf);
}
```

---

### 2. **Stream Information Problems**

```c
ret = avformat_find_stream_info(fmt_ctx, NULL);
if (ret < 0) {
    fprintf(stderr, "Failed to retrieve stream info\n");
}
```

This could mean:

* Missing keyframe info
* Unparseable stream headers
* Misaligned timestamps

---

### 3. **AVIOContext Errors (I/O Layer)**

If the input is a network stream or custom source, `fmt_ctx->pb` (`AVIOContext`) may give I/O errors:

```c
if (fmt_ctx->pb && fmt_ctx->pb->error < 0) {
    fprintf(stderr, "I/O error occurred: %d\n", fmt_ctx->pb->error);
}
```

---

### 4. **Missing or Malformed Packets**

During `av_read_frame()`, errors can be returned:

```c
while ((ret = av_read_frame(fmt_ctx, &pkt)) >= 0) {
    // handle pkt
}
if (ret != AVERROR_EOF) {
    fprintf(stderr, "Error reading frame: %s\n", av_err2str(ret));
}
```

Examples:

* Missing packets in transport stream
* Bitstream parsing failures
* Broken interleaving

---

### 5. **Stream Format Warnings**

Use `av_dump_format()` to print info. In verbose logs, FFmpeg may warn:

```
Invalid NAL size 0
PTS discontinuity
CRC mismatch
```

Enable verbose logging:

```c
av_log_set_level(AV_LOG_DEBUG);
```

---

## AVFormatContext — Limitations in Error Reporting

| Can detect…                         | ✅                             |
| ----------------------------------- | ----------------------------- |
| File not found, or unreadable       | ✅                             |
| Corrupt headers                     | ✅                             |
| Packet stream discontinuity         | ✅ (via return codes)          |
| Stream codec mismatch               | ✅                             |
| Packet corruption                   | ❌ (Decoder’s job)             |
| Macroblock corruption / concealment | ❌ (AVFrame/CodecContext only) |

---

## Example: Error Reporting with AVFormatContext

```c
AVFormatContext *fmt_ctx = NULL;

int ret = avformat_open_input(&fmt_ctx, "broken.mp4", NULL, NULL);
if (ret < 0) {
    char errbuf[128];
    av_strerror(ret, errbuf, sizeof(errbuf));
    fprintf(stderr, "Error opening input: %s\n", errbuf);
    return -1;
}

ret = avformat_find_stream_info(fmt_ctx, NULL);
if (ret < 0) {
    fprintf(stderr, "Failed to retrieve stream info\n");
    return -1;
}

AVPacket pkt;
while ((ret = av_read_frame(fmt_ctx, &pkt)) >= 0) {
    // ... decode
    av_packet_unref(&pkt);
}
if (ret != AVERROR_EOF) {
    fprintf(stderr, "Error reading packet: %s\n", av_err2str(ret));
}
```

---

## Summary

| Feature                       | Description                                       | Error Detection |
| ----------------------------- | ------------------------------------------------- | --------------- |
| `avformat_open_input()`       | Open file or stream                               | ✅               |
| `avformat_find_stream_info()` | Parses headers, finds codecs                      | ✅               |
| `av_read_frame()`             | Reads packets, returns EOF or errors              | ✅               |
| `AVIOContext` errors          | Low-level I/O errors (files, sockets)             | ✅               |
| Bitstream/macroblock decoding | ❌ Decoder’s responsibility                        | ❌               |
| Granular corruption info      | ❌ Only available in `AVFrame` or `AVCodecContext` | ❌               |

---

