# structs of FFmpeg 


## Other Useful FFmpeg Structures (You May Not Have Covered Yet)


### 1. **`AVCodecParameters`**

🔹 Describes codec-related metadata for a stream **without initializing the codec**.

Used mainly during probing (`avformat_open_input`) before you call `avcodec_open2()`.

| Key info includes                   |
| ----------------------------------- |
| Codec ID, format, bit rate          |
| Resolution, sample rate             |
| Extradata (e.g., SPS/PPS for H.264) |

🔍 **Useful for:**
Probing stream properties, and checking for invalid/incomplete stream descriptions before decoding.

---

### 2. **`AVFilterContext` / `AVFilterGraph`**

🔹 Used in filtering pipelines (`libavfilter`) – resize, crop, overlay, audio filters.

| Example filters                             |
| ------------------------------------------- |
| `scale`, `crop`, `volume`, `drawbox`, `fps` |

**Relevant for error cases like:**

* Invalid pixel formats
* Unsupported filter graph configurations
* Failed negotiation between filters

---

### 4. **`AVFrameSideData`**

🔹 Attached to `AVFrame`, it holds auxiliary metadata.

| Common types                                                              |
| ------------------------------------------------------------------------- |
| `AV_FRAME_DATA_MOTION_VECTORS` – motion info (for analysis/visualization) |
| `AV_FRAME_DATA_REGIONS_OF_INTEREST`                                       |
| `AV_FRAME_DATA_QP_TABLE_DATA` – QP table from decoder                     |

**Helpful for:**
Detailed analysis (e.g., macroblock QP differences, motion vector anomalies).

---

### 5. **`AVDictionary`**

Key-value store for metadata, used everywhere (streams, formats, options).

```c
AVDictionaryEntry *tag = NULL;
while ((tag = av_dict_get(metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
    printf("%s: %s\n", tag->key, tag->value);
}
```

**Useful for errors like:**

* Missing metadata
* Incorrect stream-level language tags
* User-defined error info in custom applications

---

### 6. **`SwsContext`**

From **libswscale**, used for pixel format or resolution conversion (e.g., YUV → RGB).

**Failure scenarios:**

* Unsupported pixel formats
* Allocation errors during scaling

---

### 7. **`SwrContext`**

From **libswresample**, used for audio format conversions (sample rate, layout, format).

**Relevant for errors like:**

* Invalid audio layout
* Resampling failure

---

## Summary Table: Less Common but Useful FFmpeg Structures

| Structure           | Main Use                     | Error Diagnostics?        |
| ------------------- | ---------------------------- | ------------------------- |
| `AVStream`          | Per-stream info              | ✅ timestamps, discard     |
| `AVCodecParameters` | Codec info (before decoding) | ✅ invalid stream config   |
| `AVFilterGraph`     | Video/audio filtering        | ✅ filter negotiation      |
| `AVFrameSideData`   | Extra info on motion/QP etc. | ✅ analysis/quality issues |
| `AVDictionary`      | Metadata/options             | ⚠️ limited, but useful    |
| `SwsContext`        | Pixel conversion (YUV↔RGB)   | ✅ format/resolution error |
| `SwrContext`        | Audio format conversion      | ✅ layout, rate mismatch   |

---

## Optional (Specialized) Structures

* `AVProgram` – represents a group of streams in MPEG-TS
* `AVChapter` – chapter markers in MP4, MKV
* `AVIndexEntry` – seeking and timestamp index
* `AVRational` – timebase representation
* `AVHWDeviceContext` – used when interacting with GPU (VAAPI, CUDA, etc.)
* `AVBufferRef` – reference-counted memory used in `AVFrame`, `AVPacket`

---

## Final Recommendation

If your focus is:

* **Decoding accuracy / quality control** → Look deeper into `AVStream`, `AVFrameSideData`, `AVCodecParameters`
* **Performance & efficiency** → Explore `SwsContext`, `SwrContext`, and hardware-related contexts
* **I/O robustness** → Master `AVIOContext`, `AVDictionary`, and custom `read_packet()` behavior

