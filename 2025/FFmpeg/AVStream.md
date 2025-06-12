# AVStream:


`AVStream`** purpose, structure, and role in **error detection, diagnostics, and stream management**.

---

## What is `AVStream`?

### TL;DR:

`AVStream` represents a **single media stream** (video, audio, subtitle, etc.) inside a media container 
(e.g., MP4, MKV, MPEG-TS).

It lives inside `AVFormatContext` and is used to:

* Identify stream type and metadata
* Provide codec parameters
* Handle timestamps, durations, and index
* Enable per-stream error control (e.g., discard, gaps)

---

## Where `AVStream` Fits in the FFmpeg Pipeline

```text
             Container (e.g., MP4, MKV)
                       ↓
         ┌────────────────────────┐
         │    AVFormatContext     │
         └────────────────────────┘
                     ↓
           ┌────────────┬────────────┬────────────┐
           │  AVStream  │  AVStream  │  AVStream  │
           │ (Video)    │ (Audio)    │ (Subtitle) │
           └────────────┴────────────┴────────────┘
```

Each `AVStream` describes a *logical track* in the file.

---

## `AVStream` Structure Overview

```c
typedef struct AVStream {
    int index;                        // stream index (0, 1, ...)
    AVCodecParameters *codecpar;     // codec info (before decoding)
    AVRational time_base;            // timebase of this stream
    int64_t duration;                // stream duration (in time_base units)
    int64_t start_time;              // when stream starts
    AVDiscard discard;               // discard policy
    AVDictionary *metadata;          // per-stream metadata
    int64_t nb_frames;               // number of frames (if known)
    AVRational avg_frame_rate;
    AVCodecContext *codec DEPRECATED; // do not use (deprecated)
    ...
} AVStream;
```

---

## Core Uses of `AVStream`

| Function              | Description                                          |
| --------------------- | ---------------------------------------------------- |
| Stream identification | Each stream has an index and type (video/audio/etc.) |
| Codec information     | Available through `codecpar`                         |
| Timing                | Controls frame timestamps and seeks                  |
| Metadata              | Title, language, disposition flags                   |
| Discarding            | Skips unwanted/broken streams                        |

---

## Real-World Usage Example

```c
for (unsigned i = 0; i < fmt_ctx->nb_streams; i++) {
    AVStream *stream = fmt_ctx->streams[i];
    AVCodecParameters *par = stream->codecpar;

    printf("Stream #%d: codec_id=%d, type=%d, bitrate=%ld\n",
        i, par->codec_id, par->codec_type, par->bit_rate);
}
```

---

## Error Reporting & Diagnostics via AVStream

### 1. **Detecting Missing/Invalid Codec Info**

Sometimes streams are present but **incomplete or broken**, e.g., missing codec parameters.

```c
if (!stream->codecpar || stream->codecpar->codec_id == AV_CODEC_ID_NONE) {
    fprintf(stderr, "Stream %d has no valid codec\n", stream->index);
}
```

---

### 2. **Handling Broken or Unwanted Streams**

Set `stream->discard` to drop broken streams:

```c
stream->discard = AVDISCARD_ALL;  // skip this stream completely
```

Use cases:

* Corrupted subtitle/audio stream
* User wants to decode video only
* Reduce CPU usage

---

### 3. **Stream Duration Mismatch / Timestamps Issues**

`AVStream` carries its **`time_base`, `duration`, `start_time`** — all of which can be invalid or missing 
in broken files.

```c
if (stream->duration <= 0 || stream->start_time == AV_NOPTS_VALUE) {
    fprintf(stderr, "Stream %d has invalid timing info\n", stream->index);
}
```

This is critical when synchronizing streams or performing seeks.

---

### 4. **Frame Rate Validation (Video)**

`avg_frame_rate` can be zero or nonsensical in some streams:

```c
if (stream->avg_frame_rate.num == 0) {
    fprintf(stderr, "Stream %d has unknown frame rate\n", stream->index);
}
```

This often causes playback or sync issues.

---

### 5. **Metadata Issues**

Useful for debugging or validating per-stream metadata:

```c
AVDictionaryEntry *lang = av_dict_get(stream->metadata, "language", NULL, 0);
if (lang) {
    printf("Stream %d language: %s\n", stream->index, lang->value);
} else {
    fprintf(stderr, "Stream %d has no language tag\n", stream->index);
}
```

---

## Summary Table: `AVStream` Fields & Their Relevance

| Field            | Description                       | Error/Diagnostic Use  |
| ---------------- | --------------------------------- | --------------------- |
| `codecpar`       | Codec ID, type, bitrate           | ✅ codec detection     |
| `time_base`      | Timing unit for this stream       | ✅ seek / sync errors  |
| `duration`       | Duration of the stream            | ✅ missing duration    |
| `discard`        | Discard policy                    | ✅ skip broken streams |
| `metadata`       | Title, language, etc.             | ✅ validation issues   |
| `avg_frame_rate` | Average framerate                 | ✅ playback issues     |
| `nb_frames`      | Total number of frames (if known) | ⚠️ may be zero        |
| `start_time`     | Stream start timestamp            | ✅ syncing             |

---

## Common Real-World Problems Detected via AVStream

| Problem                               | How AVStream Helps                       |
| ------------------------------------- | ---------------------------------------- |
| Stream has no codec info              | `codecpar->codec_id == AV_CODEC_ID_NONE` |
| Wrong/missing language tag            | `metadata["language"] == NULL`           |
| Duration mismatch between audio/video | Check `stream->duration`                 |
| Subtitle stream causes crash          | Use `discard = AVDISCARD_ALL`            |
| Framerate is zero                     | `avg_frame_rate.num == 0`                |
| Corrupt PTS timestamps                | `AV_NOPTS_VALUE` in `start_time`         |

---

## In FFmpeg CLI

```bash
ffmpeg -i input.ts
```

The stream info printed by FFmpeg is derived from `AVStream`:

```text
Stream #0:0: Video: h264 (High), yuv420p(progressive), 1280x720, 30 fps
Stream #0:1: Audio: aac, 48000 Hz, stereo, fltp
Stream #0:2: Subtitle: mov_text
```

If something is broken (e.g., missing codec or invalid frame rate), it shows up here.

---

## Summary: `AVStream` and Error Reporting

| What can be detected via `AVStream`?               | Supported?               |
| -------------------------------------------------- | ------------------------ |
| Missing codec info                                 | ✅                        |
| Invalid or corrupt timestamps                      | ✅                        |
| Invalid or missing frame rate                      | ✅                        |
| Per-stream metadata issues (language, title, etc.) | ✅                        |
| Skipping broken streams                            | ✅                        |
| Corrupted payload data                             | ❌ (handled by codec)     |
| Packet-level decoding errors                       | ❌ (use `AVCodecContext`) |

---
