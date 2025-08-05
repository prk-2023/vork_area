/* 
 * Event-Driven Ping-Pong (GLib Main Loop)
 * Using GLib’s:  `GSource`, `GMainLoop`, and timeout fun's 
 *   to make it easy to build event-driven systems. 
 * Example: simulate Ping-Pong by alternating between two callbacks using
 * a timer and state machine.
 */

#include <glib.h>

typedef struct {
    GMainLoop *loop;
    int count;
    gboolean ping_turn;
} PingPongData;

gboolean ping_pong_callback(gpointer user_data) {
    PingPongData *data = (PingPongData*)user_data;

    if (data->ping_turn) {
        g_print("Ping\n");
    } else {
        g_print("Pong\n");
    }

    data->ping_turn = !data->ping_turn;
    data->count++;

    if (data->count >= 6) { // 3 cycles (Ping, Pong)x3
        g_main_loop_quit(data->loop);
        return FALSE;
    }

    return TRUE; // Continue timer
}

int main() {
    GMainLoop *loop = g_main_loop_new(NULL, FALSE);

    PingPongData data = {
        .loop = loop,
        .count = 0,
        .ping_turn = TRUE
    };

    g_print("Starting Ping-Pong (Event-Driven) for 3 cycles...\n");

    // 1 second interval
    g_timeout_add(1000, ping_pong_callback, &data);

    g_main_loop_run(loop);

    g_print("Ping-Pong (Event-Driven) Complete.\n");

    g_main_loop_unref(loop);
    return 0;
}

/* 
 * - Uses GLib’s main loop (`GMainLoop`) to trigger a timeout callback every second.
 *   Alternates between printing "Ping" and "Pong".
 * - Stops after 3 full cycles.
 */

