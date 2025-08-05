/* 
 * Multi-threaded Ping-Pong (with GLib)
 * 2 threads: one for Ping, one for Pong.  
 * They’ll alternate printing messages using a shared condition variable and mutex. 
 * Using GLib provided: `GThread`, `GMutex`, and `GCond`
 */

#include <glib.h>

#define CYCLES 3

typedef struct {
    GMutex mutex;
    GCond cond;
    gboolean ping_turn;
    int count;
} PingPongSync;

void* ping_thread_func(gpointer user_data) {
    PingPongSync *sync = (PingPongSync*)user_data;

    for (int i = 0; i < CYCLES; ++i) {
        g_mutex_lock(&sync->mutex);

        while (!sync->ping_turn) {
            g_cond_wait(&sync->cond, &sync->mutex);
        }

        g_usleep(1000000); // Sleep 1 second
        g_print("Ping\n");
        sync->ping_turn = FALSE;
        g_cond_signal(&sync->cond);
        g_mutex_unlock(&sync->mutex);

        //g_usleep(1000000); // Sleep 1 second
    }

    return NULL;
}

void* pong_thread_func(gpointer user_data) {
    PingPongSync *sync = (PingPongSync*)user_data;

    for (int i = 0; i < CYCLES; ++i) {
        g_mutex_lock(&sync->mutex);

        while (sync->ping_turn) {
            g_cond_wait(&sync->cond, &sync->mutex);
        }

        g_usleep(1000000); // Sleep 1 second
        g_print("Pong\n");
        sync->ping_turn = TRUE;
        g_cond_signal(&sync->cond);
        g_mutex_unlock(&sync->mutex);

        //g_usleep(1000000); // Sleep 1 second
    }

    return NULL;
}

int main() {
    PingPongSync sync = {
        .ping_turn = TRUE,
        .count = 0
    };

    g_mutex_init(&sync.mutex);
    g_cond_init(&sync.cond);

    GThread *ping_thread = g_thread_new("ping", ping_thread_func, &sync);
    GThread *pong_thread = g_thread_new("pong", pong_thread_func, &sync);

    g_thread_join(ping_thread);
    g_thread_join(pong_thread);

    g_mutex_clear(&sync.mutex);
    g_cond_clear(&sync.cond);

    g_print("Ping-Pong (Multi-threaded) Complete.\n");

    return 0;
}

/* 
 * Uses 2 threads to alternate printing `Ping` and `Pong`.
 * Shared mutex & condition variable ensure proper synchronization.
 * Each message is printed 3 times, 1 second apart.
 */

