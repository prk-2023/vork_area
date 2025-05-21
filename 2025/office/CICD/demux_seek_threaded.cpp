#include <cstring>
#include <iostream>
#include <string>
#include <thread>
#include <atomic>
#include <mutex>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libavutil/time.h>
#include <libavutil/error.h>
#include <libavutil/md5.h>
}

#include <sys/select.h> // for select(), fd_set
#include <sys/time.h>   // for timeval
#include <fcntl.h>      // for file control options (not used here but often helpful)

#define SEEK_STEP 5 // seconds

enum DecoderType {
   SOFTWARE,
   HARDWARE
};

struct termios originalTermSettings;
// Function to save the original terminal settings
void saveTerminalSettings() {
    tcgetattr(STDIN_FILENO, &originalTermSettings); // Save the current terminal settings
}

// Function to restore terminal settings to their original state
void restoreTerminalSettings() {
    tcsetattr(STDIN_FILENO, TCSANOW, &originalTermSettings); // Restore original settings
}

void cleanupKeyboard() {
    restoreTerminalSettings(); // Restore terminal settings on cleanup
}

class FFmpegDemuxSeeker {
public:
   FFmpegDemuxSeeker(const std::string& filename, DecoderType decoder_type = SOFTWARE )
       : fmt_ctx(nullptr), codec_ctx(nullptr), video_stream_index(-1),
         current_pos(0), duration(0), frame_number(0),
         quit_flag(false), seek_requested(false), seek_offset(0),
         decoder_type(decoder_type) {

       if (avformat_open_input(&fmt_ctx, filename.c_str(), nullptr, nullptr) < 0)
           throw std::runtime_error("Failed to open file");

       if (avformat_find_stream_info(fmt_ctx, nullptr) < 0)
           throw std::runtime_error("Failed to find stream info");

       for (unsigned i = 0; i < fmt_ctx->nb_streams; i++) {
           if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
               video_stream_index = i;
               break;
           }
       }

       if (video_stream_index == -1)
           throw std::runtime_error("No video stream found");

       // const AVCodec* codec = avcodec_find_decoder(fmt_ctx->streams[video_stream_index]->codecpar->codec_id);
       // if (!codec)
       //     throw std::runtime_error("Unsupported codec");
       // Choose codec based on the requested decoder type:
       const AVCodec *codec = nullptr;
       if (decoder_type == SOFTWARE) { 
          codec = avcodec_find_decoder(fmt_ctx->streams[video_stream_index]->codecpar->codec_id);
       } else if ( decoder_type == HARDWARE) {
          codec = avcodec_find_decoder_by_name("h264_v4l2m2m");
          if (!codec) {
             std::cerr << "[Error] v4l2_m2m decoder not found, falling back to SW decoder";
             //fallback
             codec = avcodec_find_decoder(fmt_ctx->streams[video_stream_index]->codecpar->codec_id); 
          }
       }
       if (!codec)
          throw std::runtime_error("Unsupported codec");

       codec_ctx = avcodec_alloc_context3(codec);
       avcodec_parameters_to_context(codec_ctx, fmt_ctx->streams[video_stream_index]->codecpar);
       if (avcodec_open2(codec_ctx, codec, nullptr) < 0)
           throw std::runtime_error("Failed to open codec");

       duration = fmt_ctx->duration;
       std::cout << "Loaded: " << filename << ", duration: " << (duration / AV_TIME_BASE) << " sec\n";
       // Print general format-level info
       std::cout << "Input file: " << fmt_ctx->url << "\n";
       AVCodecParameters* codecpar = nullptr;
       AVStream* video_stream = nullptr;
       int video_stream_index = -1;
       
       // Find the best video stream
       for (unsigned int i = 0; i < fmt_ctx->nb_streams; ++i) {
          if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
             video_stream = fmt_ctx->streams[i];
             codecpar = video_stream->codecpar;
             video_stream_index = i;
             break;
          }
       }
       if (!video_stream || !codecpar)
          throw std::runtime_error("No video stream found");
       const char* codec_name = codec ? codec->long_name : "unknown";

       // Duration (in seconds)
       double duration_sec = (fmt_ctx->duration != AV_NOPTS_VALUE)
          ? fmt_ctx->duration * av_q2d(AV_TIME_BASE_Q)
          : 0;

       // Bitrate (in kbps)
       int64_t bitrate = fmt_ctx->bit_rate;

       std::cout << "Video stream index: " << video_stream_index << "\n";
       std::cout << "Encoded format: " << codec_name << "\n";
       std::cout << "Codec ID: " << codecpar->codec_id << "\n";
       std::cout << "Resolution: " << codecpar->width << "x" << codecpar->height << "\n";
       std::cout << "Pixel format: " << av_get_pix_fmt_name((AVPixelFormat)codecpar->format) << "\n";
       std::cout << "Duration: " << duration_sec << " seconds\n";
       std::cout << "Overall Bitrate:(includes all streams) " << (bitrate / 1000) << " kbps\n";
       std::cout << "Video stream Bitrate: " << (codecpar->bit_rate / 1000) << " kbps\n";
       std::cout << "Decoder used : " << (codec->name) << "\n";

   }

   ~FFmpegDemuxSeeker() {
       if (codec_ctx)
           avcodec_free_context(&codec_ctx);
       if (fmt_ctx)
           avformat_close_input(&fmt_ctx);
   }

   void run() {
       std::thread demux_thread(&FFmpegDemuxSeeker::demuxLoop, this);
       std::thread input_thread(&FFmpegDemuxSeeker::inputLoop, this);

       demux_thread.join();
       input_thread.join();
   }

private:
   DecoderType decoder_type;
   AVFormatContext* fmt_ctx;
   AVCodecContext* codec_ctx;
   int video_stream_index;
   int64_t current_pos;
   int64_t duration;
   int64_t frame_number;

   std::atomic<bool> quit_flag;
   std::atomic<bool> seek_requested;
   std::mutex seek_mutex;
   int64_t seek_offset; // in microseconds

   void demuxLoop() {
       AVPacket* packet = av_packet_alloc();
       AVFrame* frame = av_frame_alloc();

       while (!quit_flag) {
           if (seek_requested) {
               std::lock_guard<std::mutex> lock(seek_mutex);
               int64_t new_pos = current_pos + seek_offset;
               if (new_pos < 0) new_pos = 0;
               if (new_pos > duration) new_pos = duration;
               current_pos = new_pos;

               int64_t ts = av_rescale_q(current_pos, AV_TIME_BASE_Q,
                                         fmt_ctx->streams[video_stream_index]->time_base);
               if (av_seek_frame(fmt_ctx, video_stream_index, ts, AVSEEK_FLAG_BACKWARD) < 0) {
                   std::cerr << "[Seek] Failed\n";
               } else {
                   avcodec_flush_buffers(codec_ctx);
                   std::cout << "[Seek] Jumped to " << current_pos / AV_TIME_BASE << " sec\n";
               }

               seek_requested = false;
           }

           int ret = av_read_frame(fmt_ctx, packet);
           if (ret < 0) {
               if (ret == AVERROR_EOF) {
                   std::cout << "[EOF reached]\n";
                   quit_flag = true;
               } else {
                   char errbuf[AV_ERROR_MAX_STRING_SIZE];
                   std::cerr << "[Error reading frame: "
                             << av_make_error_string(errbuf, AV_ERROR_MAX_STRING_SIZE, ret)
                             << "]\n";
               }
               break;
           }

           if (packet->stream_index == video_stream_index) {
               if (avcodec_send_packet(codec_ctx, packet) == 0) {
                   while (avcodec_receive_frame(codec_ctx, frame) == 0) {
                       printFrameInfo(frame);
                   }
               }
           }
           av_packet_unref(packet);
           usleep(5000); // reduce CPU usage
       }

       av_frame_free(&frame);
       av_packet_free(&packet);
   }

   void inputLoop() {
       std::cout << "Controls:\n"
                 << "  s - Seek forward 5s\n"
                 << "  a - Seek backward 5s\n"
                 << "  q - Quit\n";

       while (!quit_flag) {
           //char c = getch(); // blocking 
           char c = getch_select(); //non-blocking
           if (c == 'q') {
               quit_flag = true;
               std::cout << "[Quit]\n";
               break;
           } else if (c == 's') {
               requestSeek(SEEK_STEP * AV_TIME_BASE);
           } else if (c == 'a') {
               requestSeek(-SEEK_STEP * AV_TIME_BASE);
           }
       }
   }

   void requestSeek(int64_t offset) {
       std::lock_guard<std::mutex> lock(seek_mutex);
       seek_offset = offset;
       seek_requested = true;
   }

   // void printFrameInfo(AVFrame* frame) {
   //     char pict_type_char = av_get_picture_type_char(frame->pict_type);
   //     char pict_type_str[] = { pict_type_char, '\0' };
   //
   //     double timestamp = (frame->pts != AV_NOPTS_VALUE)
   //         ? frame->pts * av_q2d(fmt_ctx->streams[video_stream_index]->time_base)
   //         : -1;
   //
   //     std::cout << "Frame #" << frame_number++
   //               << " | Type: " << pict_type_str
   //               << " | PTS: " << frame->pts
   //               << " | Timestamp: " << timestamp << "s"
   //               << " | Resolution: " << frame->width << "x" << frame->height
   //               << "\n";
   //     //update the current_pos here
   //     if (frame->pts != AV_NOPTS_VALUE) {
   //        current_pos = av_rescale_q(frame->pts,
   //              fmt_ctx->streams[video_stream_index]->time_base,
   //              AV_TIME_BASE_Q);
   //     }
   // }

   void printFrameInfo(AVFrame* frame) {
       // Initialize MD5 context
       AVMD5* md5 = av_md5_alloc();
       if (!md5) {
           std::cerr << "Failed to allocate MD5 context\n";
           return;
       }

       av_md5_init(md5);

       // Hash the pixel data
       // int frame_size = 0;
       for (int plane = 0; plane < AV_NUM_DATA_POINTERS && frame->data[plane]; plane++) {
           int linesize = frame->linesize[plane];
           int height = (plane == 0 || frame->format == AV_PIX_FMT_GRAY8) ? frame->height : frame->height / 2;

           for (int y = 0; y < height; y++) {
               av_md5_update(md5, frame->data[plane] + y * linesize, linesize);
               // frame_size += linesize; //accumulated size
           }
       }

       uint8_t digest[16];
       av_md5_final(md5, digest);
       av_free(md5);

       // Format MD5 as hex string
       char md5string[33];
       for (int i = 0; i < 16; i++) {
           snprintf(md5string + i * 2, 3, "%02x", digest[i]);
       }

       char pict_type_char = av_get_picture_type_char(frame->pict_type);

       double timestamp = (frame->pts != AV_NOPTS_VALUE)
           ? frame->pts * av_q2d(fmt_ctx->streams[video_stream_index]->time_base)
           : -1;

       // int buffer_size = av_image_get_buffer_size((AVPixelFormat)frame->format,
       //                                         frame->width, frame->height, 1);

       const char* pix_fmt_name = av_get_pix_fmt_name(static_cast<AVPixelFormat>(frame->format));

       std::cout << "Frame #" << frame_number++
                 << " | Type: " << pict_type_char
                 << " | PTS: " << frame->pts
                 << " | DTS: " << frame->pkt_dts
                 << " | Timestamp: " << timestamp << "s"
                 << " | Resolution: " << frame->width << "x" << frame->height
                 //<< " | Frame Size: " << frame_size << " bytes"
                 //<< " | Estimated Buffer Size: " << buffer_size << " bytes"
                 << " | Pixel fmt: " << (pix_fmt_name ? pix_fmt_name : "unknown")
                 << " | Decoded frm MD5: " << md5string
                 << "\n";

       // Update the current_pos here
       if (frame->pts != AV_NOPTS_VALUE) {
           current_pos = av_rescale_q(frame->pts,
                 fmt_ctx->streams[video_stream_index]->time_base,
                 AV_TIME_BASE_Q);
       }
   }

   //blocking
   char getch() {
       char buf = 0;
       struct termios old = {0};
       tcgetattr(STDIN_FILENO, &old);
       old.c_lflag &= ~(ICANON | ECHO);
       tcsetattr(STDIN_FILENO, TCSANOW, &old);
       read(STDIN_FILENO, &buf, 1);
       tcsetattr(STDIN_FILENO, TCSANOW, &old);
       return buf;
   }

   // Non-blocking use select()
   // Returns: ascii value of character pressed, or -1 if no input within timeout
   char getch_select(int timeout_ms = 0) {
       struct termios oldt, newt;
       tcgetattr(STDIN_FILENO, &oldt);         // get current terminal settings
       newt = oldt;
       newt.c_lflag &= ~(ICANON | ECHO);       // disable canonical mode and echo
       tcsetattr(STDIN_FILENO, TCSANOW, &newt);// apply new settings immediately

       fd_set readfds;
       FD_ZERO(&readfds);
       FD_SET(STDIN_FILENO, &readfds);

       struct timeval tv;
       tv.tv_sec = timeout_ms / 1000;
       tv.tv_usec = (timeout_ms % 1000) * 1000;

       char ch = -1;
       int ret = select(STDIN_FILENO + 1, &readfds, NULL, NULL,
                        (timeout_ms >= 0 ? &tv : NULL)); // NULL means wait indefinitely

       if (ret > 0 && FD_ISSET(STDIN_FILENO, &readfds)) {
           char buf;
           if (read(STDIN_FILENO, &buf, 1) == 1) {
               ch = static_cast<unsigned char>(buf);
           }
       }
       tcsetattr(STDIN_FILENO, TCSANOW, &oldt); // restore original terminal settings
       return ch;
   }
};


int main(int argc, char* argv[]) {
    saveTerminalSettings();
    if (argc < 3) {
        std::cerr << "Usage: ./ffmpeg_seeker <input_file> <Decoder Type:HW/SW>\n";
        return 1;
    }
    DecoderType decoder;
    if (strncmp(argv[2],"SW", 2) == 0)
       decoder = SOFTWARE;
    else if ( strncmp(argv[2], "HW", 2) == 0)
       decoder = HARDWARE;
    else 
       decoder = SOFTWARE; //default 
                                       //
    try {
        FFmpegDemuxSeeker demux_seeker(argv[1], decoder);
        demux_seeker.run();
    } catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << "\n";
        return 1;
    }
    cleanupKeyboard();
    return 0;
}
