CFLAGS = -DSPDLOG_FMT_EXTERNAL -Wall -I/usr/include/ffmpeg
LDFLAG = -lavformat -lavcodec -lavutil -lpthread -lfmt

all:
	g++ demux_seek_threaded.cpp -o ffmpeg_seeker $(CFLAGS) $(LDFLAG) 

clean:
	rm -rf ffmpeg_seeker
