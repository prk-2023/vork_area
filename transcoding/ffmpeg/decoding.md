# decoding using ffmpeg:

---
Steps to decode a media file using FFmpeg from reading the file to creating a decoded frame:

- **Step 1: Initialize FFmpeg**

    * Initialize FFmpeg library by calling **`avcodec_register_all()`** and **`avformat_network_init()`**.
    * This step is necessary to register all the codecs and formats available in FFmpeg.
    
- **Step 2: Open the Input File**

    * Open the input file using **`avformat_open_input()`**.
    * Pass the file path and a pointer to an **`AVFormatContext`** structure as arguments.
    * This structure will hold the format-specific information about the file.
    
- **Step 3: Find the Stream Information**

    * Use **`avformat_find_stream_info()`** to retrieve information about the streams in the file.
    * This function will populate the **`AVFormatContext`** structure with information about the streams.
    
- **Step 4: Find the Video Stream**

    * To find the video stream we need to iterate over the stream in the file using a loop and check the
      **codec_typ** field of the **AVStream** structure. 
    * Find the video stream by checking the **`codec_type`** field of the **`AVStream`** structure.
    * Store the index of the video stream in a variable.

    ```c 
        // Find the video stream
        int video_stream_index = -1;
        for (int i = 0; i < fmt_ctx->nb_streams; i++) {
            if (fmt_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                video_stream_index = i;
                break;
            }
        }
    ```
    fmt_ctx->nb_streams: gives the number of streams in the file.
    fmt_ctx->streams[i]: gives the i-th stream. We can then access the `codec` field of the AVStream struct,
                         to get the codec type and check if it's video stream using AVMEDIA_TYPE_VIDEO
    
- **Step 5: Allocate a Codec Context**

    * Allocate a codec context using **`avcodec_alloc_context3()`**.
    * Pass the codec type (e.g. `AV_CODEC_ID_H264`) as an argument.
    * This structure will hold the codec-specific information.
    
- **Step 6: Copy the Codec Parameters**

    * Copy the codec parameters from the **`AVStream`** structure to the codec context using **`avcodec_copy_context()`**.
    * This step is necessary to initialize the codec context with the correct parameters.

- **Step 7: Open the Codec**

    * Open the codec using **`avcodec_open2()`**.
    * Pass the codec context and a pointer to an **`AVCodec`** structure as arguments.
    * This step is necessary to initialize the codec.

- **Step 8: Read a Packet from the File**

    * Read a packet from the file using **`av_read_frame()`**.
    * Pass the **`AVFormatContext`** structure and a pointer to an **`AVPacket`** structure as arguments.
    * This structure will hold the packet data.

- **Step 9: Decode the Packet**

    * Decode the packet using **`avcodec_decode_video2()`**.
    * Pass the codec context, a pointer to an **`AVFrame`** structure, and the packet as arguments.
    * This step will decode the packet and store the decoded frame in the **`AVFrame`** structure.
    
- **Step 10: Check for a Decoded Frame**

    * Check if a decoded frame is available using the **`got_frame`** field of the **`AVFrame`** structure.
    * If a frame is available, proceed to the next step.

- **Step 11: Process the Decoded Frame**

    * Process the decoded frame as needed (e.g. convert to a different format, apply filters, etc.).
    * The decoded frame is stored in the **`AVFrame`** structure.

Here is some sample code to illustrate these steps:
```c
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>

int main() {
    // Initialize FFmpeg
    avcodec_register_all();
    avformat_network_init();

    // Open the input file
    AVFormatContext *fmt_ctx = NULL;
    if (avformat_open_input(&fmt_ctx, "input.mp4", NULL, NULL) < 0) {
        printf("Error opening input file\n");
        return -1;
    }

    // Find the stream information
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        printf("Error finding stream information\n");
        return -1;
    }

    // Find the video stream
    int video_stream_index = -1;
    for (int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }

    // Allocate a codec context
    AVCodecContext *codec_ctx = avcodec_alloc_context3(NULL);
    if (!codec_ctx) {
        printf("Error allocating codec context\n");
        return -1;
    }

    // Copy the codec parameters
    avcodec_copy_context(codec_ctx, fmt_ctx->streams[video_stream_index]->codec);

    // Open the codec
    AVCodec *codec = avcodec_find_decoder(codec_ctx->codec_id);
    if (!codec) {
        printf("Error finding codec\n");
        return -1;
    }
    if (avcodec_open2(codec_ctx, codec, NULL) < 0) {
        printf("Error opening codec\n");
        return -1;
    }

    // Read a packet from the file
    AVPacket packet;
    while (av_read_frame(fmt_ctx, &packet) >= 0) {
        // Decode the packet
        AVFrame *frame = av_frame_alloc();
        int got_frame = 0;
        if (avcodec_decode_video2(codec_ctx, frame, &got_frame, &packet) < 0) {
            printf("Error decoding packet\n");
            return -1;
        }

        // Check for a decoded frame
        if (got_frame) {
            // Process the decoded frame
            printf("Decoded frame\n");
        }

        // Release the frame
        av_frame_free(&frame);
    }

    // Release the codec context
    avcodec_close(codec_ctx);
    avcodec_free_context(&codec_ctx);

    // Release the format context
    avformat_close_input(&fmt_ctx);

    return 0;
}
```
Note that this is just a basic example, and you may need to add error checking and other features depending
on your specific use case.


# Formats, functions and more...

- avformat_open_input(AVFormatContext **ps const char * url, AVInputFormat *fmt, AVDictionary **option)

Opens an input stream and read the header ( continer header )
The codecs are not opened. The stream must be closed with the avformat_close_input().

    arguments:
    - ps: ptr to user-supplied AVFormatContext ( allocated by avformat_alloc_context() ), Maybe ptr to NULL,
      in which case an AVFormatContextis allocated by this function and written into `ps`
    - url: Urp of the stream to open.
    - fmt: if not NULL then this parameter forces a specific input format. else its autodetected.
    - options: a dictionary filled with AVFormatContext and demuxer-private options. may be NULL

- avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options)
    Read packets of a media file to get stream information.
    
    This is useful for file formats with no headers such as MPEG. 
    This function also computes the real framerate in case of MPEG-2 repeat frame mode. 
    The logical file position is not changed by this function; 
    examined packets may be buffered for later processing.

    arguments:
    - ic: media file handler

    return:
        >=0 if OK, AVERROR_xxx on error

- AVCodecContext *avcodec_alloc_context3(const AVCodec *codec):

    Allocate an AVCodecContext and set its fields to default values.
    ( resulting struct should be freed with avcodec_free_context() )

    arguments:
    codec: if non-NULL, allocate private data and initialize defaults for the given codec. 
    It is illegal to then call avcodec_open2() with a different codec. 
    If NULL, then the codec-specific defaults won't be initialized, 
    which may result in suboptimal default settings 
    (this is important mainly for encoders, e.g. libx264).

    return: 
    An AVCodecContext filled with default values or NULL on failure.

FFMpeg important Structures
---

- AVFrame: 
    `AVFrame` struct is  fundamental data structure that represents a single frame of video or audio data.
    It is used to store and manipulate the raw data of a frame, as well as metadata associated with that
    frame.


    - Key components of the `AVFrame` structure:

    **Data** : 
    * `data`: an array of pointers to the raw data of the frame. 
    The number of pointers in the array depends on the number of planes in the frame 
    (e.g. Y, U, V for YUV 4:2:0 video).
    * `linesize`: an array of integers that represent the size of each plane in the frame.

    **Metadata**
    * `pts`: the presentation timestamp of the frame, which represents the time at which the frame should be
      displayed.
    * `pkt_pts`: the pkt timestamp of the frame, which represents the time at which the frame was received.
    * `pkt_dts`: the packet decode timestamp of the frame, which represents the time at which the frame
      should be decoded.
    * `duration`: the duration of the frame, which represents the time between the start of the frame and
      the start of the next frame.
    * `key_frame`: a flag that indicates whether the frame is a keyframe (i.e. an I-frame).
    * `pict_type`: the type of picture (I, P, B, etc.) represented by the frame.

    **Other**
    * `width` and `height`: the width and height of the frame.
    * `format`: the format of the frame (e.g. YUV 4:2:0, RGB, etc.).
    * `sample_aspect_ratio`: the sample aspect ratio of the frame.
    * `color_range`: the color range of the frame (e.g. limited, full).
    * `color_primaries`: the color primaries of the frame (e.g. BT.709, BT.2020).
    * `color_trc`: the color transfer characteristic of the frame (e.g. BT.709, BT.2020).
    * `color_space`: the color space of the frame (e.g. YUV, RGB).

    **Audio-specific fields**
    * `nb_samples`: the number of audio samples in the frame.
    * `channel_layout`: the channel layout of the audio frame (e.g. mono, stereo, 5.1).
    * `sample_rate`: the sample rate of the audio frame.

    **Other flags**
    * `interlaced_frame`: a flag that indicates whether the frame is interlaced.
    * `top_field_first`: a flag that indicates whether the top field of an interlaced frame is first.
    * `repeat_pict`: a flag that indicates whether the frame should be repeated.


The `AVFrame` structure is used throughout FFmpeg to represent frames of video and audio data. 
It is used by the decoder to store the decoded frame, and by the encoder to store the encoded frame. 
It is also used by filters to manipulate the frame data.

Here is an example of how to access the data in an `AVFrame` structure:
```c
AVFrame *frame = ...;

// Get the width and height of the frame
int width = frame->width;
int height = frame->height;

// Get the format of the frame
enum AVPixelFormat format = frame->format;

// Get the data pointers for each plane
uint8_t *y_plane = frame->data[0];
uint8_t *u_plane = frame->data[1];
uint8_t *v_plane = frame->data[2];

// Get the linesize for each plane
int y_linesize = frame->linesize[0];
int u_linesize = frame->linesize[1];
int v_linesize = frame->linesize[2];
```
Note that the `AVFrame` structure is a complex data structure, and accessing its fields requires a good 
understanding of the underlying data formats and structures.
    

