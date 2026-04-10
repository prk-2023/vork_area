/*
 * This version does three things:
 * - Creates a new PID Namespace (CLONE_NEWPID).
 * - Creates a new Mount Namespace (CLONE_NEWNS).
 * - Mounts a fresh, isolated /proc inside the child so it can't see the rest of the system.
 */
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <unistd.h>

#define STACK_SIZE 1024*1024
static char child_stack[STACK_SIZE];

int child_fn(void *arg) {
    printf("Child: My PID is %d\n", getpid());

    // Mount a private /proc for this namespace
    // This ensures 'ps' only shows processes inside this namespace
    if (mount("proc", "/proc", "proc", 0, NULL) == -1) {
        perror("mount");
    }

    printf("Child: Listing processes inside my namespace:\n");
    // Execute 'ps' to show that only PID 1 (and ps itself) exist here
    system("ps aux");

    return 0;
}

int main() {
    // We add CLONE_NEWNS to allow the child to have its own mount points
    pid_t pid = clone(child_fn, child_stack + STACK_SIZE, 
                      CLONE_NEWPID | CLONE_NEWNS | SIGCHLD, NULL);
    
    if (pid == -1) {
        perror("clone");
        exit(1);
    }

    waitpid(pid, NULL, 0);
    return 0;
}
