/*
 * Demo prog for event-driver nature of GLib, GMainLoop runs continuously waits for events. 
 * we add a timer that will trigger a function after certain amount of time.
 */
#include <stdio.h>
#include <glib.h>

gboolean timer_callback(gpointer data) {
   g_print("Timer is triggred! that dat pointer is : %s \n", (char*)data);
   //this is one-short timer and has to stop the main loop, we need to quite it.
   GMainLoop *loop = (GMainLoop*)data;
   g_main_loop_quit(loop);
   return FALSE;
}

//int main( int argc, char *argv[]) {
int main() {
   //1. create a main loop
   GMainLoop *loop = g_main_loop_new(NULL, FALSE);
   g_print("Starting GLib main loop  this will run for 3 seconds\n");

   //2. Add timeout source to the loop 
   //timer callback will be called after 3000 ms ( or 3 secs )
   //the last arg is the user data which we'll pass the main loop itself.
   //g_timeout_add (3000, timer_callback, loop);

   g_timeout_add (3000, timer_callback, loop);

   //3. Run the main loop ( this is blocking until g_main_loop_quit() is called.)
   g_main_loop_run(loop);

   g_print("Main Loop has quite after 3 sec \n");
   //4. cleanup:
   g_main_loop_unref(loop);
   return 0;
}

//gcc -o my_prog glib_timer.c `pkg-config --cflags --libs glib-2.0` -Wall
//
//
//1. g_main_loop_new() : creates an instance of main loop
//2. g_timeout_add() : starts a timed event source to the loop. it takes timeout in ms a function call and
//some user data to pass to that function 
//3. g_main_loop_run() : starts the loop , which will wait for events ( in this case its our added timer 
//4. timer_callback() : UDF which gets executed after 3 sec. it prints a message then calls
//g_mail_loop_unref() which singnals the loop to stop running. 
//5. g_main_loop_unref(): free the memory associated with the loop. 
//
