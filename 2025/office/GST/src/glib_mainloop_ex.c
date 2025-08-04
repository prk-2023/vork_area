#include <glib-2.0/glib.h>

struct _MyObject {
   GObject parent_instance;
   gint count;
}
G_DEF_TYPE(MyObject, my_object, G_TYPE_OBJECT)

//Initalize
static void my_object_class_init()


gboolean quit_loop ( gpointer data) {
   GMainLoop *loop = (GMainLoop *)data;
   g_print("timeout reached ...quiting loop \n");
   g_main_loop_quit(loop);
   return FALSE; // Do not call again
}

void my_object_print(MyObject *self) {
   g_print("MyObject count: %d\n", self->count);
}
int main () {
   //GMainLoop is a opaque data type that represents main event loop of GLib or GTK application
   GMainLoop *loop = g_main_loop_new(NULL, FALSE);
   g_timeout_add_seconds(3, quit_loop, loop);
   g_print("Start main loop will quite in 3 sec\n");
   g_main_loop_run(loop);
   g_main_loop_unref(loop);
   return 0;
}

