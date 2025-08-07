#include "myobject.h"
#include <stdio.h>

struct _MyObject {
    GObject parent_instance;
};

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

static void my_object_class_init(MyObjectClass *klass) {
    // Nothing to override for now
}

static void my_object_init(MyObject *self) {
    g_print("MyObject initialized!\n");
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}
