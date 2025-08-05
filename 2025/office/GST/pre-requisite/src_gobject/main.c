#include "myobject.h"
#include <glib-object.h>
#include <stdio.h>

static void greeted_callback(MyObject *self, gchar *name, gpointer user_data) {
    g_print("Signal received: greeted %s\n", name);
}

int main() {
#if !GLIB_CHECK_VERSION(2,36,0)
    g_type_init(); // Required for older GLib versions
#endif

    //GObject way to create new instance. ( we can pass val directly to it)
    MyObject *obj = g_object_new(MY_TYPE_OBJECT, "name", "Alice", NULL);

    // connect a function "greeted_callback" to a signal  "greeted"
    g_signal_connect(obj, "greeted", G_CALLBACK(greeted_callback), NULL);

    my_object_greet(obj);

    g_object_unref(obj);

    return 0;
}
