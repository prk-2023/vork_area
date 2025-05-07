#include "FFmpegDemuxer.h"
#include <iostream>
#include <chrono>
#include <thread>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>

int main(int argc, char* argv[]) {
   if (argc < 2) {
      std::cerr << "Usage: ./demuxer <input.mp4>" << std::endl;
      return -1;
   }
   //log
   auto logger = spdlog::basic_logger_mt("demux_logger", "demux_log.txt");
   spdlog::set_default_logger(logger);
   spdlog::set_level(spdlog::level::debug); // Show all logs 
   spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%l] %v");

   std::string inputFile = argv[1];
   
   FFmpegDemuxer demuxer(inputFile);
   std::cout << "Preparing demuxer..." << std::endl;
   spdlog::info("Preparing demuxer...");

   if (!demuxer.prepare()) {
      std::cerr << "Failed to prepare demuxer." << std::endl;
      spdlog::info("Failed to prepare demuxer...");
      return -1;
   }
   // Show media info
   demuxer.getMediaInfo();
   std::cout << "Starting demuxer thread..." << std::endl;
   spdlog::info("Starting demuxer thread...");

   demuxer.startThread();
   demuxer.resume(); // Start reading packets
   std::cout << "Reading for 5 seconds..." << std::endl;
   spdlog::info("Reading for 5 seconds...");

   std::this_thread::sleep_for(std::chrono::seconds(5));
   std::cout << "Stopping demuxer..." << std::endl;
   demuxer.pause();
   demuxer.stopThread();
   std::cout << "Demuxing complete." << std::endl;
   return 0;
}
