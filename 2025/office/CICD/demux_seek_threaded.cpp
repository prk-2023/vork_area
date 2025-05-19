
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
}

#define SEEK_STEP 5 // seconds

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

void initKeyboard() {
    termios term;
    tcgetattr(STDIN_FILENO, &term);
    term.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &term);
    fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
}

char getKey() {
    char ch = 0;
    read(STDIN_FILENO, &ch, 1);
    return ch;
}
class FFmpegSeeker {
public:
    FFmpegSeeker(const std::string& filename)
        : fmt_ctx(nullptr), codec_ctx(nullptr), video_stream_index(-1),
          current_pos(0), duration(0), frame_number(0),
          quit_flag(false), seek_requested(false), seek_offset(0) {

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

        const AVCodec* codec = avcodec_find_decoder(fmt_ctx->streams[video_stream_index]->codecpar->codec_id);
        if (!codec)
            throw std::runtime_error("Unsupported codec");

        codec_ctx = avcodec_alloc_context3(codec);
        avcodec_parameters_to_context(codec_ctx, fmt_ctx->streams[video_stream_index]->codecpar);
        if (avcodec_open2(codec_ctx, codec, nullptr) < 0)
            throw std::runtime_error("Failed to open codec");

        duration = fmt_ctx->duration;
        std::cout << "Loaded: " << filename << ", duration: " << (duration / AV_TIME_BASE) << " sec\n";
    }

    ~FFmpegSeeker() {
        if (codec_ctx)
            avcodec_free_context(&codec_ctx);
        if (fmt_ctx)
            avformat_close_input(&fmt_ctx);
    }

    void run() {
        std::thread demux_thread(&FFmpegSeeker::demuxLoop, this);
        std::thread input_thread(&FFmpegSeeker::inputLoop, this);

        demux_thread.join();
        input_thread.join();
    }

private:
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
            char c = getch();
            if (c == 'q') {
                quit_flag = true;
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

    void printFrameInfo(AVFrame* frame) {
        char pict_type_char = av_get_picture_type_char(frame->pict_type);
        char pict_type_str[] = { pict_type_char, '\0' };

        double timestamp = (frame->pts != AV_NOPTS_VALUE)
            ? frame->pts * av_q2d(fmt_ctx->streams[video_stream_index]->time_base)
            : -1;

        std::cout << "Frame #" << frame_number++
                  << " | Type: " << pict_type_str
                  << " | PTS: " << frame->pts
                  << " | Timestamp: " << timestamp << "s"
                  << " | Resolution: " << frame->width << "x" << frame->height
                  << "\n";
        //update the current_pos here
        if (frame->pts != AV_NOPTS_VALUE) {
           current_pos = av_rescale_q(frame->pts,
                 fmt_ctx->streams[video_stream_index]->time_base,
                 AV_TIME_BASE_Q);
        }
    }

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
};


int main(int argc, char* argv[]) {
    saveTerminalSettings();
    if (argc < 2) {
        std::cerr << "Usage: ./ffmpeg_seeker <input_file>\n";
        return 1;
    }

    try {
        FFmpegSeeker seeker(argv[1]);
        seeker.run();
    } catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << "\n";
        return 1;
    }
    cleanupKeyboard();
    return 0;
}
