# Transcoding : rtk

OMX : encoder h264 and h265:

static OMX_BUFFERHEADERTYPE *get_buffer(pthread_mutex_t *mutex, pthread_cond_t *cond, int *array_size,
                                        OMX_BUFFERHEADERTYPE **array, int wait) {
    OMX_BUFFERHEADERTYPE *buffer;
    pthread_mutex_lock(mutex);
    if (wait) {
        while (!*array_size)
            pthread_cond_wait(cond, mutex);
    }
    if (*array_size > 0) {
        buffer = array[0];
        (*array_size)--;
        memmove(&array[0], &array[1], (*array_size) * sizeof(OMX_BUFFERHEADERTYPE *));
    } else {
    buffer = NULL;
    }
    pthread_mutex_unlock(mutex);
    return buffer;
}

**get_buffer**

This function retrieves a buffer from a pool of available buffers. It takes the following parameters:

* `mutex`: a pointer to a mutex (lock) to synchronize access to the buffer pool
* `cond`: a pointer to a condition variable to wait for buffers to become available
* `array_size`: a pointer to the size of the buffer pool
* `array`: a pointer to the buffer pool
* `wait`: a flag indicating whether to wait for a buffer to become available (1) or return immediately (0)

The function:

1. Locks the mutex to ensure exclusive access to the buffer pool.
2. If `wait` is 1, waits for a buffer to become available using the condition variable.
3. If a buffer is available, removes it from the pool and returns it.
4. If no buffer is available and `wait` is 0, returns NULL.
5. Unlocks the mutex.

---

static int omx_encode_frame(AVCodecContext *avctx, AVPacket *pkt, const AVFrame *frame, int *got_packet) {
    OMXCodecContext *s = avctx->priv_data;
    int ret = 0;
    OMX_BUFFERHEADERTYPE *buffer;
    OMX_ERRORTYPE err;


    if (frame) {
        uint8_t *dst[4];
        int linesize[4];
        buffer = get_buffer(&s->input_mutex, &s->input_cond,
                    &s->num_free_in_buffers, s->free_in_buffers, 1);

        buffer->nFilledLen = av_image_fill_arrays(dst, linesize, buffer->pBuffer, avctx->pix_fmt,
                                    s->stride, s->plane_size, 1);

        if (s->rma_func->rma_CheckValidBuffer(s->handle, frame->rma_data) == 0) {
            RMA_BUFFERINFO *copy_buffer;
            copy_buffer = (RMA_BUFFERINFO *)frame->rma_data;
            s->rma_func->rma_Memcpy(s->handle, buffer, copy_buffer, copy_buffer->nAllocLen);
        } else {
            av_image_copy(dst, linesize, (const uint8_t **)frame->data, frame->linesize, avctx->pix_fmt, 
                                avctx->width, avctx->height);
        }
        buffer->nFlags = OMX_BUFFERFLAG_ENDOFFRAME;
        buffer->nOffset = 0;
        // Convert the timestamps to microseconds; some encoders can ignore
        // the framerate and do VFR bit allocation based on timestamps.
        buffer->nTimeStamp = to_omx_ticks(
        av_rescale_q(frame->pts, avctx->time_base, AV_TIME_BASE_Q));
        err = OMX_EmptyThisBuffer(s->handle, buffer);
        if (err != OMX_ErrorNone) {
            append_buffer(&s->input_mutex, &s->input_cond, &s->num_free_in_buffers,
                s->free_in_buffers, buffer);
            av_log(avctx, AV_LOG_ERROR, "OMX_EmptyThisBuffer failed: %x\n", err);
            return AVERROR_UNKNOWN;
        }

    } else if (!s->eos_sent) {
        buffer = get_buffer(&s->input_mutex, &s->input_cond,&s->num_free_in_buffers, s->free_in_buffers, 1);
        buffer->nFilledLen = 0;
        buffer->nFlags = OMX_BUFFERFLAG_EOS;
        buffer->pAppPrivate = buffer->pOutputPortPrivate = NULL;
        err = OMX_EmptyThisBuffer(s->handle, buffer);
        if (err != OMX_ErrorNone) {
            append_buffer(&s->input_mutex,&s->input_cond,&s->num_free_in_buffers,s->free_in_buffers,buffer);
            av_log(avctx, AV_LOG_ERROR, "OMX_EmptyThisBuffer failed: %x\n", err);
            return AVERROR_UNKNOWN;
        }
        s->eos_sent = 1;
    }

    while (!*got_packet && ret == 0 && !s->got_eos) {
        // If not flushing, just poll the queue if there's finished packets.
        // If flushing, do a blocking wait until we either get a completed
        // packet, or get EOS.

        buffer = get_buffer(&s->output_mutex, &s->output_cond,
                            &s->num_done_out_buffers, s->done_out_buffers, !frame);
        if (!buffer)
            break;

        if (buffer->nFlags & OMX_BUFFERFLAG_EOS)
            s->got_eos = 1;

        if (buffer->nFlags & OMX_BUFFERFLAG_CODECCONFIG && avctx->flags & AV_CODEC_FLAG_GLOBAL_HEADER) {
            if ((ret = av_reallocp(&avctx->extradata,
                                    avctx->extradata_size + buffer->nFilledLen +
                                    AV_INPUT_BUFFER_PADDING_SIZE)) < 0) {
                avctx->extradata_size = 0;
                goto end;
            }
            memcpy(avctx->extradata + avctx->extradata_size,
                    buffer->pBuffer + buffer->nOffset, buffer->nFilledLen);
            avctx->extradata_size += buffer->nFilledLen;
            memset(avctx->extradata + avctx->extradata_size, 0,
                     AV_INPUT_BUFFER_PADDING_SIZE);
        } else {
            if (!(buffer->nFlags & OMX_BUFFERFLAG_ENDOFFRAME) || !pkt->data) {
                // If the output packet isn't preallocated, just concatenate everything
                // in our own buffer
                int newsize = s->output_buf_size + buffer->nFilledLen +
                                      AV_INPUT_BUFFER_PADDING_SIZE;
                if ((ret = av_reallocp(&s->output_buf, newsize)) < 0) {
                    s->output_buf_size = 0;
                    goto end;
                }
                memcpy(s->output_buf + s->output_buf_size,
                        buffer->pBuffer + buffer->nOffset, buffer->nFilledLen);
                s->output_buf_size += buffer->nFilledLen;
                
                if (buffer->nFlags & OMX_BUFFERFLAG_ENDOFFRAME) {
                    if ((ret = av_packet_from_data(pkt, s->output_buf, s->output_buf_size)) < 0) {
                        av_freep(&s->output_buf);
                        s->output_buf_size = 0;
                        goto end;
                    }
                    s->output_buf = NULL;
                    s->output_buf_size = 0;
                }
            } else {
                // End of frame, and the caller provided a preallocated frame
                if ((ret = ff_alloc_packet2(avctx, pkt, s->output_buf_size + buffer->nFilledLen, 0)) < 0) {
                    av_log(avctx, AV_LOG_ERROR, "Error getting output packet of size %d.\n",
                            (int)(s->output_buf_size + buffer->nFilledLen));
                    goto end;
                }
                memcpy(pkt->data, s->output_buf, s->output_buf_size);
                memcpy(pkt->data + s->output_buf_size,
                buffer->pBuffer + buffer->nOffset, buffer->nFilledLen);
                av_freep(&s->output_buf);
                s->output_buf_size = 0;
            }
            if (buffer->nFlags & OMX_BUFFERFLAG_ENDOFFRAME) {
                pkt->pts =av_rescale_q(from_omx_ticks(buffer->nTimeStamp),AV_TIME_BASE_Q,avctx->time_base);
                // We don't currently enable B-frames for the encoders, so set
                // pkt->dts = pkt->pts. (The calling code behaves worse if the encoder 
                // doesn't set the dts).
                pkt->dts = pkt->pts;
                if (buffer->nFlags & OMX_BUFFERFLAG_SYNCFRAME)
                    pkt->flags |= AV_PKT_FLAG_KEY;
                    
                *got_packet = 1;      
            }
        }

        end:
            err = OMX_FillThisBuffer(s->handle, buffer);
            if (err != OMX_ErrorNone) {
                append_buffer(&s->output_mutex, &s->output_cond, &s->num_done_out_buffers,
                                s->done_out_buffers, buffer);
                av_log(avctx, AV_LOG_ERROR, "OMX_FillThisBuffer failed: %x\n", err);
                ret = AVERROR_UNKNOWN;
            }
    }
    return ret;
}


**omx_encode_frame**

This function encodes a video frame using the OMX API. It takes the following parameters:

* `avctx`: a pointer to an AVCodecContext structure, which contains information about the codec and the
  encoding process.

* `pkt`: a pointer to an AVPacket structure, which will contain the encoded frame

* `frame`: a pointer to an AVFrame structure, which contains the input frame to be encoded

* `got_packet`: a pointer to an integer indicating whether a packet was successfully encoded (1) or not (0)

The function:

1. Retrieves a buffer from the input buffer pool using `get_buffer`.
2. If a frame is provided, fills the buffer with the frame data and sets the necessary flags 
    (e.g., `OMX_BUFFERFLAG_ENDOFFRAME`).
3. If no frame is provided, sets the buffer to indicate the end of the stream (EOS).
4. Submits the buffer to the OMX encoder using `OMX_EmptyThisBuffer`.
5. Waits for the encoder to finish processing the buffer and retrieve the encoded packet.
6. If the packet is successfully encoded, copies the packet data to the `pkt` structure and sets the
   necessary flags (e.g., `AV_PKT_FLAG_KEY`).
7. Returns the result of the encoding process (0 on success, a negative error code on failure).

The code is well-structured and follows good practices for concurrent programming using mutexes and 
condition variables.

In the `omx_encode_frame` function, `av_image_fill_arrays` and `av_image_copy` are used to manipulate the 
input frame data. Here's a breakdown of their roles:

**av_image_fill_arrays**
    `av_image_fill_arrays` is a function from the FFmpeg library that fills the `dst` and `linesize` arrays
    with the necessary information to access the input frame data.

    * `dst`: an array of pointers to the planes of the output image (in this case, the buffer)
    * `linesize`: an array of integers representing the line size of each plane in the output image

The function takes the following parameters:

    * `dst`: the array of pointers to the planes of the output image
    * `linesize`: the array of integers representing the line size of each plane in the output image
    * `buffer`: the buffer containing the input frame data
    * `pix_fmt`: the pixel format of the input frame
    * `stride`: the stride (i.e., the number of bytes between each line) of the input frame
    * `plane_size`: the size of each plane in the input frame
    * `align`: the alignment of the input frame data (in this case, 1, which means the data is not aligned)

The function returns the size of the input frame data in bytes.

In the `omx_encode_frame` function, `av_image_fill_arrays` is used to fill the `dst` and `linesize` 
arrays with the necessary information to access the input frame data in the buffer.

**av_image_copy**

`av_image_copy` is a func from the FFmpeg library that copies the input frame data from the `frame` 
structure to the `dst` array.

The function takes the following parameters:

* `dst`: the array of pointers to the planes of the output image
* `linesize`: the array of integers representing the line size of each plane in the output image
* `src`: the array of pointers to the planes of the input image (in this case, the `frame` structure)
* `src_linesize`: the array of integers representing the line size of each plane in the input image
* `pix_fmt`: the pixel format of the input frame
* `width`: the width of the input frame
* `height`: the height of the input frame

The function copies the input frame data from the `frame` structure to the `dst` array, taking into account 
the pixel format, line size, and other parameters.

In the `omx_encode_frame` function, `av_image_copy` is used to copy the input frame data from the `frame` 
structure to the buffer, which is then submitted to the OMX encoder.

**RMA_BUFFERINFO**

In the `omx_encode_frame` function, there is a check for 
    `s->rma_func->sbc_CheckValidBuffer(s->handle, frame->sbc_data) == 0`. 

If this condition is true, the function uses `s->rma_func->rma_Memcpy` to copy the input frame data from the
`frame` structure to the buffer.

`RMA_BUFFERINFO` is a structure that contains information about the input frame data, including the buffer 
size and offset. The `rma_Memcpy` function is used to copy the input frame data from the `frame` structure 
to the buffer, taking into account the buffer size and offset.

The `RMA_BUFFERINFO` structure and the `rma_Memcpy` function are specific to the rtk OMX encoder being
used, and are used to handle the input frame data in a way that is compatible with the encoder.


The av_image_copy() function copies the input frame data from the frame structure to the dst array.
However, the "dst" array is not actually used to store the output image data. 
Instead, the "dst" array is used as a temporary buffer to hold the input frame data while it is being copied
to the OMX encoder's buffer.

The OMX encoder's "buffer" is actually stored in the buffer variable, which is a pointer to an 
OMX_BUFFERHEADERTYPE structure. 
This structure contains the actual buffer data, as well as other metadata such as the buffer size and offset.

When the av_image_copy function copies the input frame data to the dst array, it is actually copying the 
data to a temporary buffer that is used to hold the data while it is being copied to the OMX encoder's buffer.

The OMX encoder's buffer is then submitted to the encoder using the OMX_EmptyThisBuffer function,
which processes the buffer and generates the encoded output.

summarize:(av_image_copy)
    - The dst array is used as a temporary buffer to hold the input frame data while it is being copied to
      the OMX encoder's buffer.
    - The OMX encoder's buffer is stored in the buffer variable, which is a pointer to an
      OMX_BUFFERHEADERTYPE structure.
    - The input frame data is copied to the dst array using the av_image_copy function, and then copied to
      the OMX encoder's buffer.

The OMX encoder's buffer is then submitted to the encoder using the OMX_EmptyThisBuffer function, which
generate the encoded frame.

data flow:
+---------------+
|  Input Frame  |
+---------------+
       |
       |
       v
+-----------------+
|  av_image_copy  |
|  (dst array)    |
+-----------------+
       |
       |
       v
+------------------+
|  OMX Encoder's   |
|  Buffer (buffer) |
+------------------+
       |
       |
       v
+----------------------+
|  OMX_EmptyThisBuffer |
|  (encoder processes  |
|   the buffer)        |
+----------------------+
       |
       |
       v
+---------------+
|Encoded Output |
+---------------+



---

The `dst` array is used as a temporary buffer to hold the input frame data while it is being copied to the 
OMX encoder's buffer. This buffer is then used to construct the final buffer that is sent to the 
OMX encoder to compress the frame.

The OMX encoder then processes the buffer and generates the compressed frame data, which is stored in 
another buffer.

Finally, the compressed frame data is copied to the `AVPacket` `pkt` structure, which is used to store 
the compressed frame data along with other metadata such as the packet's timestamp, duration, and flags.

So, the flow of data is:

1. Input frame data is copied to the `dst` array, which is used as a temporary buffer.
2. The `dst` array is used to construct the final buffer that is sent to the OMX encoder.
3. The OMX encoder processes the buffer and generates the compressed frame data, which is stored in another buffer.
4. The compressed frame data is copied to the `AVPacket` `pkt` structure.

Here's a more detailed example of the flow of data:
```
+---------------+
|  Input Frame  |
|  (YUV data)   |
+---------------+
       |
       |
       v
+-----------------+
|  av_image_copy  |
|  (dst array)    |
|  (temporary     |
|   buffer)       |
+-----------------+
       |
       |
       v
+-------------------+
|  Construct OMX    |
|  Encoder Buffer   |
|  (from dst array) |
+-------------------+
       |
       |
       v
+-------------------+
|  OMX Encoder      |
|  (compress frame) |
+-------------------+
       |
       |
       v
+--------------------+
|  Compressed Frame  |
|  (in OMX buffer)   |
+--------------------+
       |
       |
       v
+--------------------+
|  Copy to AVPacket  |
|  (pkt structure)   |
+--------------------+
       |
       |
       v
+---------------------+
|  AVPacket pkt       |
|  (compressed frame) |
+---------------------+
```
---
