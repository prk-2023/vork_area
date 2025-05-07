CFLAGS = -DSPDLOG_FMT_EXTERNAL -Wall -I/usr/include/ffmpeg 
LDFLAG = -lavformat -lavcodec -lavutil -lpthread -lfmt

all:
	g++ main.cpp FFmpegDemuxer.cpp $(CFLAGS) $(LDFLAG) -o demuxer

clean: 
	rm -f demuxer
