#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

#define STACK_SIZE 1024*1024

static char child_stack[STACK_SIZE];

int child_fn(void *arg) {
    // In a new PID namespace, this will print 1
    printf("Child: My PID inside the namespace is %d\n", getpid());
    return 0;
}

int main() {
    printf("Parent: My PID is %d\n", getpid());

    // CLONE_NEWPID creates the process in a new PID hierarchy
    pid_t pid = clone(child_fn, child_stack + STACK_SIZE, CLONE_NEWPID | SIGCHLD, NULL);
    
    if (pid == -1) {
        perror("clone");
        exit(1);
    }

    printf("Parent: I see the child as PID %d\n", pid);
    
    waitpid(pid, NULL, 0);
    printf("Parent: Child has finished.\n");
    return 0;
}
