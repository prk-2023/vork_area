// Better example then ./glib_timer_01.c 
//#include <stdio.h>
#include <glib.h>

typedef struct {
    GMainLoop *loop;
    const char *message;
} TimerData;

gboolean timer_callback(gpointer user_data) {
    TimerData *data = (TimerData *)user_data;
    g_print("Timer is triggered! The message is: %s\n", data->message);

    // Quit the main loop
    g_main_loop_quit(data->loop);
    return FALSE; // one-shot timer
}

int main() {
   // Create main loop
   GMainLoop *loop = g_main_loop_new(NULL, FALSE);
   g_print("Starting GLib main loop. This will run for 3 seconds.\n");

   // Prepare data to pass to callback
   TimerData data = {
      .loop = loop,
      .message = "Hello from timer callback",
   };

   // Set timer
   g_timeout_add(3000, timer_callback, &data);

   // Run loop
   g_main_loop_run(loop);

   g_print("Main loop has quit after 3 seconds.\n");

   // Clean up
   g_main_loop_unref(loop);
   return 0;
}
