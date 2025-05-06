#include <crow.h>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>
#include <chrono>

using namespace std;

void run_transcoding_command(const string& command, string& output, string& error) {
    // Open a process to run FFmpeg or GStreamer commands
    FILE* process = popen(command.c_str(), "r");
    if (process == nullptr) {
        error = "Failed to start process.";
        return;
    }

    char buffer[128];
    while (fgets(buffer, sizeof(buffer), process) != nullptr) {
        output += buffer;
    }

    // Check for errors
    int return_code = pclose(process);
    if (return_code != 0) {
        error = "Process failed with code: " + to_string(return_code);
    }
}

void transcoding_handler(const crow::request& req, crow::response& res) {
    // Retrieve input parameters from the HTTP request
    auto input_file = req.url_params.get("input_file");
    auto output_file = req.url_params.get("output_file");
    auto use_hw_accel = req.url_params.get("hw_accel") != nullptr;

    // Validate parameters
    if (!input_file || !output_file) {
        res.code = 400;
        res.write("Missing required parameters (input_file, output_file).");
        return;
    }

    // Construct the FFmpeg or GStreamer command
    stringstream command;
    command << "ffmpeg"; // You can switch this with gstreamer based on request
    if (use_hw_accel) {
        command << " -hwaccel rkmpp";
    }
    command << " -i " << input_file << " -c:v h264_rkmpp -b:v 2M " << output_file;

    string output;
    string error;

    // Run the transcoding command
    thread transcoding_thread(run_transcoding_command, command.str(), ref(output), ref(error));
    transcoding_thread.join(); // Wait for transcoding to finish

    // Build the response
    if (!error.empty()) {
        res.code = 500;
        res.write("Transcoding failed: " + error);
    } else {
        res.code = 200;
        res.write("Transcoding successful.\n");
        res.write("Output:\n" + output);
    }
}

int main() {
    crow::SimpleApp app;

    // Define a POST endpoint to trigger transcoding
    CROW_ROUTE(app, "/transcode")
    .methods("POST"_method)(transcoding_handler);

    // Run the server on port 18080
    app.port(18080).multithreaded().run();

    return 0;
}
