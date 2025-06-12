# AVIOContext:


**`AVIOContext`** — the low-level I/O layer in FFmpeg.

---

## What is `AVIOContext`?

### TL;DR:

`AVIOContext` is FFmpeg’s **low-level byte stream handler**, used to read/write raw bytes to/from files, 
pipes, memory, or network.

It powers `AVFormatContext`'s ability to read or write data from:

* Local files (e.g. `.mp4`)
* Remote sources (e.g. HTTP, RTSP)
* In-memory buffers
* Custom sources (via callbacks)

---

## Where `AVIOContext` Fits in the Pipeline

```text
    FILE, SOCKET, BUFFER
          ↓
     ┌──────────────┐
     │ AVIOContext  │  ← Raw I/O layer
     └──────────────┘
            ↓
    ┌────────────────────┐
    │   AVFormatContext  │  ← Parses container format (MP4, MKV)
    └────────────────────┘
            ↓
       AVPacket, etc.
```

---

## Structure Overview

```c
typedef struct AVIOContext {
    unsigned char *buffer;       // Internal buffer
    int buffer_size;
    unsigned char *buf_ptr;      // Current read/write pointer
    unsigned char *buf_end;
    void *opaque;                // Opaque user data (for custom IO)
    int (*read_packet)(void *opaque, uint8_t *buf, int buf_size);
    int (*write_packet)(void *opaque, uint8_t *buf, int buf_size);
    int (*seek)(void *opaque, int64_t offset, int whence);
    int error;                   // Last I/O error code
    ...
} AVIOContext;
```

---

## Use Cases of `AVIOContext`

### 1. **Automatic File I/O (default use)**

You usually don't manage `AVIOContext` manually — `avformat_open_input()` sets it up for you when reading 
from disk or network.

```c
AVFormatContext *fmt_ctx;
avformat_open_input(&fmt_ctx, "video.mp4", NULL, NULL);
// fmt_ctx->pb is the AVIOContext internally used
```

---

### 2. **Custom Input/Output (advanced)**

You can create a custom `AVIOContext` to:

* Read from an encrypted stream
* Write to memory
* Interact with sockets or hardware

```c
unsigned char *avio_buffer = av_malloc(avio_buffer_size);
AVIOContext *avio_ctx = avio_alloc_context(avio_buffer, avio_buffer_size, 0,
                                           your_opaque_ptr,
                                           your_read_func, NULL, your_seek_func);
fmt_ctx->pb = avio_ctx;
```

---

## AVIOContext and Error Reporting

### 1. **Error Status Tracking**

Every I/O operation updates `AVIOContext->error`. This field holds the last I/O error as a negative `AVERROR` code:

```c
if (fmt_ctx->pb && fmt_ctx->pb->error < 0) {
    fprintf(stderr, "I/O error: %s\n", av_err2str(fmt_ctx->pb->error));
}
```

Common errors:

* `AVERROR_EOF` – end of stream
* `AVERROR(EIO)` – I/O failure
* `AVERROR(ETIMEDOUT)` – network timeout
* `AVERROR_INVALIDDATA` – corrupted bytes

---

### 2. **Custom I/O Function Error Detection**

If you register custom `read_packet()` or `seek()` callbacks, they must return:

* `>= 0` → success
* `<  0` → error (set in `pb->error`)

```c
int my_read(void *opaque, uint8_t *buf, int size) {
    int ret = read_from_socket(buf, size);
    if (ret < 0) {
        return AVERROR(EIO);
    }
    return ret;
}
```

---

### 3. **Timeouts and Retry Policies (Network Sources)**

Network protocols like HTTP, RTSP, or HLS use `AVIOContext` internally. FFmpeg provides options (via `AVFormatContext`) to tune these:

```bash
ffmpeg -timeout 1000000 -reconnect 1 -i rtsp://example.com
```

You can also set them via C:

```c
av_dict_set(&options, "timeout", "1000000", 0);  // in µs
```

These control how `AVIOContext` behaves on errors.

---

## Summary Table

| Field / Function                       | Purpose                             | Error Detection Use |
| -------------------------------------- | ----------------------------------- | ------------------- |
| `AVIOContext->error`                   | Stores last I/O error               | ✅ Direct            |
| `read_packet()` callback return code   | Controls error behavior             | ✅ Yes               |
| `avio_feof()`                          | Detect end-of-file                  | ✅ Yes               |
| `avio_seek()` return value             | Check if seek failed                | ✅ Yes               |
| `avio_read()` or `avio_read_partial()` | Low-level read, returns error codes | ✅ Yes               |
| `avio_write()`                         | Write, check for short write/error  | ✅ Yes               |

---

## Example: Error Handling with AVIOContext

```c
AVFormatContext *fmt_ctx = NULL;
avformat_open_input(&fmt_ctx, "broken.ts", NULL, NULL);

AVPacket pkt;
while (av_read_frame(fmt_ctx, &pkt) >= 0) {
    // ...
    av_packet_unref(&pkt);
}

if (fmt_ctx->pb && fmt_ctx->pb->error < 0) {
    fprintf(stderr, "Stream error: %s\n", av_err2str(fmt_ctx->pb->error));
}
```

---

## Summary: AVIOContext and Error Reporting

| Can it detect…              | AVIOContext Support        |
| --------------------------- | -------------------------- |
| File not found              | ✅ (via open failure)       |
| End-of-file                 | ✅ (`avio_feof()`)          |
| Network timeout             | ✅ (error codes)            |
| Short reads or broken pipes | ✅ (negative returns)       |
| Corrupt media data          | ❌ (handled by codec)       |
| Packet parsing issues       | ❌ (handled by demuxer)     |
| Per-frame decode issues     | ❌ (handled by codec/frame) |

---

## AVIOContext in FFmpeg CLI (Under the Hood)

```bash
ffmpeg -i input.mp4 -f null -
```

Under the hood:

* Opens `AVFormatContext`
* Initializes `AVIOContext`
* Reads raw bytes and populates `AVPacket`
* Errors in reading show up like:

  ```
  [avio @ 0x...] Failed to read 1024 bytes: I/O error
  ```
---
