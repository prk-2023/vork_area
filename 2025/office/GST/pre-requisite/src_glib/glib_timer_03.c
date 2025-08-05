/*
 * Simulate a ping-pong msg exchange 
 * alternating between two messages every second, repeating 3 times, 
 * and then quitting the program.
 * We use 
 * - A GLib main loop
 * - A shared counter to limit the repetitions
 * - A timeout callback scheduled every 1 second (1000 ms)
 * Alternating messages: **Ping**, **Pong**, **Ping**, etc.
 */

//#include <stdio.h>
#include <glib.h>

typedef struct {
    GMainLoop *loop;
    int count;
    const char *messages[2];
} PingPongData;

gboolean ping_pong_callback(gpointer user_data) {
    PingPongData *data = (PingPongData *)user_data;

    // Alternate between "Ping" and "Pong"
    const char *msg = data->messages[data->count % 2];
    g_print("%s\n", msg);

    data->count++;

    // After 6 messages (i.e., 3 Ping-Pong cycles), stop
    if (data->count >= 6) {
        g_main_loop_quit(data->loop);
        return FALSE; // Stop timer
    }
    return TRUE; // Continue timer
}

int main() {
    GMainLoop *loop = g_main_loop_new(NULL, FALSE);

    PingPongData data = {
        .loop = loop,
        .count = 0,
        .messages = {"Ping", "Pong"}
    };

    g_print("Starting Ping-Pong exchange every 1 second...\n");

    // Start timeout: 1000 ms interval
    g_timeout_add(1000, ping_pong_callback, &data);

    g_main_loop_run(loop);

    g_print("Ping-Pong complete. Exiting.\n");

    g_main_loop_unref(loop);
    return 0;
}
/* Optional Enhancements:
 *
 * - Dynamically adjust the number of cycles with a CLI arg.
 * - Replace `g_timeout_add()` with `g_timeout_add_seconds()` for simplicity (but `g_timeout_add()` is more precise).
 *   - Use a GLib `GTimer` if you need actual elapsed time tracking.

 * ==> Next example multi-threaded and event driver
 */
