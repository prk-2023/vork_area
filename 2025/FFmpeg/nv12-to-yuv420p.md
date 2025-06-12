# Format conversion of  Raw frames:


- Convert NV12 to YUV420P


To convert a decoded frame in **NV12** pixel format to **YUV420P**, you need to use **libswscale**.
The `libswscale` library provides scaling and pixel format conversion.

---

### Why convert NV12 → YUV420P?

* NV12 is a semi-planar format (Y plane + interleaved UV plane).
* YUV420P is planar: separate Y, U, and V planes.
* Some encoders or processing steps expect YUV420P.

---

### Steps to convert:

1. **Initialize a `SwsContext`** for conversion.
2. **Allocate a destination `AVFrame`** with YUV420P format.
3. For each decoded NV12 frame:

   * Use `sws_scale()` to convert the frame to YUV420P.
4. Use or encode the converted frame as needed.

---

### Example snippet:

```c
#include <libswscale/swscale.h>

// After decoding a frame in NV12 format (frame)
// Prepare a destination frame with YUV420P

AVFrame *dst_frame = av_frame_alloc();
dst_frame->format = AV_PIX_FMT_YUV420P;
dst_frame->width = frame->width;
dst_frame->height = frame->height;

int ret = av_frame_get_buffer(dst_frame, 32);
if (ret < 0) {
    fprintf(stderr, "Failed to allocate buffer for dst_frame\n");
    // handle error
}

struct SwsContext *sws_ctx = sws_getContext(
    frame->width, frame->height, frame->format,   // source width, height, format (NV12)
    dst_frame->width, dst_frame->height, dst_frame->format, // dest width, height, format (YUV420P)
    SWS_BILINEAR, NULL, NULL, NULL);

if (!sws_ctx) {
    fprintf(stderr, "Failed to initialize sws context\n");
    // handle error
}

// Convert (scale + convert pixel format)
sws_scale(sws_ctx, (const uint8_t * const*)frame->data, frame->linesize,
          0, frame->height, dst_frame->data, dst_frame->linesize);

// Now dst_frame contains YUV420P pixels, ready for encoding or processing.

// Free the sws context when done
sws_freeContext(sws_ctx);
```

---

### Summary:

* Use `sws_getContext()` to create a scaler/converter.
* Use `sws_scale()` to convert pixel formats.
* Allocate a new frame with `AV_PIX_FMT_YUV420P`.
* Don’t forget to free resources after.

---

