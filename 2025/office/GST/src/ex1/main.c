#include "myobject.h"

int main() {
    MyObject *obj = my_object_new();
    g_print("Created a MyObject instance: %p\n", obj);

    g_object_unref(obj);
    return 0;
}
