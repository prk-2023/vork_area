#ifndef FFMPEG_DEMUXER_H
#define FFMPEG_DEMUXER_H

#include <string>
#include <vector>
#include <thread>
#include <mutex>
#include <atomic>
#include <condition_variable>
//log
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
}

enum class Status {
    NONE,
    PAUSED,
    PLAYING,
    PREPARED
};

struct StreamContext {
    int streamIndex;
    AVCodecContext* codecContext;
    AVStream* avStream;
    // Additional stream-specific info
};

class FFmpegDemuxer {
public:
    FFmpegDemuxer(const std::string& uri);
    ~FFmpegDemuxer();

    bool prepare();
    void startThread();
    void stopThread();
    void pause();
    void resume();
    void seek(int64_t timestamp);
    void setParameter(const std::string& param, const std::string& value);
    
    void addSinkBin(AVFormatContext* sinkBin);
    void removeSinkBin(AVFormatContext* sinkBin);
    void removeAllSinkBins();
    
    bool openAvformat();
    void closeAvformat();
    void onAvformatInterrupt();
    bool fillMediaInfo();
    void pushPacket(AVPacket* packet);
    void readPushPacket();
    void removePacket();
    void doSeek(int64_t timestamp);
    
    // Parser-related functions
    void parseGopDuration();
    void parseIndexEntries();
    void parseSegmentDuration();
    
    void getMediaInfo(); // To get media info details

private:
    void threadLoop();
    
    std::string uri;
    Status status;
    std::vector<StreamContext> streamContexts;
    AVFormatContext* avContext;
    AVPacket currentPacket;
    std::thread threadExecutor;
    std::mutex mutex;
    std::condition_variable condVar;
    std::atomic<bool> stopThreadFlag;
};

#endif // FFMPEG_DEMUXER_H
