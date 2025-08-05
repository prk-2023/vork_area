#include "myobject.h"
#include <stdio.h>

struct _MyObject {
    GObject parent_instance;
    gchar *name;
};

typedef enum {
    PROP_0,
    PROP_NAME,
    N_PROPERTIES
} MyObjectProperty;

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL };

enum {
    SIGNAL_GREETED,
    N_SIGNALS
};
static guint signals[N_SIGNALS] = { 0 };

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

static void my_object_set_property(GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_free(self->name);
            self->name = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_get_property(GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_value_set_string(value, self->name);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_finalize(GObject *object) {
    MyObject *self = MY_OBJECT(object);
    g_free(self->name);
    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}
// This is where we define the behaviour of the class 
static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->set_property = my_object_set_property;
    object_class->get_property = my_object_get_property;
    object_class->finalize = my_object_finalize;

    obj_properties[PROP_NAME] =
        g_param_spec_string("name", "Name", "Name of the object", NULL,
                            G_PARAM_READWRITE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);

    signals[SIGNAL_GREETED] = g_signal_new(
        "greeted",
        G_TYPE_FROM_CLASS(klass),
        G_SIGNAL_RUN_LAST,
        0, NULL, NULL,
        NULL,
        G_TYPE_NONE, 1,
        G_TYPE_STRING);
}

static void my_object_init(MyObject *self) {
    self->name = g_strdup("Default");
}

void my_object_greet(MyObject *self) {
    g_print("Hello, %s!\n", self->name);
    g_signal_emit(self, signals[SIGNAL_GREETED], 0, self->name);
}
