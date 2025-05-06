
#include <crow.h>
#include <crow/mustache.h>
#include <cstdlib>  // For system()
#include <sstream>
#include <fstream>

int main() {
    crow::SimpleApp app;

    // Serve the HTML template with mustache
    CROW_ROUTE(app, "/")
    ([] {
        auto page = crow::mustache::load("myindex2.html");
        return page.render();
    });

    // Handle command execution (POST endpoint)
    CROW_ROUTE(app, "/run").methods("POST"_method)
    ([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        if (!body || !body.has("cmd")) {
            return crow::response(400, "Invalid request");
        }

        std::string cmd = body["cmd"].s();

        // Run the command and capture output
        std::array<char, 128> buffer;
        std::string result;
        std::shared_ptr<FILE> pipe(popen(cmd.c_str(), "r"), pclose);
        if (!pipe) return crow::response(500, "Failed to run command");

        while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
            result += buffer.data();
        }

        return crow::response(result);
    });

    // Start server
    app.port(18080).multithreaded().run();
}
