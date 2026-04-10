To compile and test this code, you need to use the `gcc` compiler on a Linux machine. Because `clone()` and namespaces are low-level kernel features, there are specific requirements for permissions and headers.

### 1. Save the Code

Save your code into a file named `pid_ns.c`.

### 2. Compile the Code

Open your terminal and run the following command:

```bash
gcc pid_ns.c -o pid_ns

```

* **Note:** If you get errors about `CLONE_NEWPID` being undefined, you may need to add `#define _GNU_SOURCE` at the very top of your `.c` file (before any `#include` lines) to expose the modern Linux-specific features in the headers.

---

### 3. Run the Test (with Sudo)

Creating a new PID namespace is a privileged operation. If you run it as a normal user, it will likely fail with "Operation not permitted."

Run it with `sudo`:

```bash
sudo ./pid_ns

```

**Expected Output:**

```text
Parent process
Child process in new PID namespace

```

---

### 4. How to verify it's actually working

The code you provided prints a message, but it doesn't "prove" it's in a new namespace. To see the isolation in action, modify your `child_fn` to print its own PID:

```c
int child_fn(void *arg) {
    printf("Child PID inside namespace: %d\n", getpid());
    return 0;
}

```

When you run the modified version:

1. The **Parent** will see the child's PID as a normal high number (e.g., `5432`).
2. The **Child** will print **`PID: 1`**.

### Troubleshooting Tips

* **Permissions:** If you don't want to use `sudo`, you can use **User Namespaces** by adding the `CLONE_NEWUSER` flag, though this requires more complex setup for ID mapping.
* **Waitpid:** Ensure you have `#include <sys/wait.h>` and `#include <unistd.h>` at the top to avoid compiler warnings about `waitpid` and `getpid`.
* **Stack Direction:** On most modern systems (x86), the stack grows down. The code correctly passes `child_stack + STACK_SIZE` to point to the "top" (end) of the memory block.

**Would you like me to provide the updated version of the code that prints the PIDs from both perspectives?**


----------------------------------------------------------
Here is the updated code. I’ve added the necessary headers (`#define _GNU_SOURCE` and `<unistd.h>`) and updated the logic so you can actually see the "magic" of the PID namespace isolation.

### The Updated Code (`pid_ns.c`)

```c
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

```

---

### How to Compile and Run

1. **Compile:**
```bash
gcc pid_ns.c -o pid_ns

```


2. **Run with root privileges:**
```bash
sudo ./pid_ns

```



### What you will see

When you run this, you'll notice a discrepancy that proves the isolation is working:

* The **Parent** will report the child has a normal system PID (e.g., `12345`).
* The **Child** will report its PID is **1**.

### Why this is significant

In Linux, **PID 1** is reserved for the `init` process (like systemd). By making the child PID 1 inside its own namespace, you are effectively telling that process it is the "ancestor" of its own private world. If this child were to spawn its own children, they would see this process as their parent, completely unaware of the main operating system running outside.

---

**Would you like to try mounting a private `/proc` filesystem next so that commands like `top` or `ps` only show the child's processes?**
---------------------------------------------------------------
To make this work, we need to add the **`CLONE_NEWNS`** flag. By default, even if a child has its own PID namespace, it still looks at the parent's `/proc` directory. Since tools like `ps` and `top` read from `/proc` to see what is running, they will still see every process on your computer unless we give the child its own private mount.

### The Improved Code (`pid_proc_ns.c`)

This version does three things:

1. Creates a new **PID Namespace** (`CLONE_NEWPID`).
2. Creates a new **Mount Namespace** (`CLONE_NEWNS`).
3. Mounts a fresh, isolated `/proc` inside the child so it can't see the rest of the system.

```c
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

```

---

### How to Test

1. **Compile:**
```bash
gcc pid_proc_ns.c -o pid_proc_ns

```


2. **Run with sudo:**
```bash
sudo ./pid_proc_ns

```



### What to Look For

When the `ps aux` command runs:

* **Normal System:** Usually shows hundreds of processes.
* **This Child Process:** Will only show **two** entries: its own process (PID 1) and the `ps` command itself.

---

### ⚠️ A Critical Warning

When the child mounts `/proc`, it might overlap with your host's `/proc` if not handled carefully in a real-world scenario. Because we used `CLONE_NEWNS`, this mount is **private** to the child and won't break your main system's `ps` command. However, in professional container runtimes (like Docker), the child usually performs a `pivot_root` or `chroot` first to ensure it's operating in a completely different file directory.

**Would you like to see how to add Network isolation next, so the child has its own private "localhost" and network interfaces?**

-----------------------------------------------------------------

In Rust, you don't typically use `clone()` directly because it's a very low-level and "unsafe" C-style system call. Instead, the idiomatic way is to use the **`nix`** crate, which provides a much safer, more "Rust-like" wrapper around Linux namespaces.

### 1. Project Setup

First, add the `nix` dependency to your `Cargo.toml`:

```toml
[dependencies]
nix = { version = "0.27", features = ["sched", "mount"] }

```

### 2. The Rust Implementation

This code replicates the C logic: it creates a new PID and Mount namespace, mounts `/proc`, and executes a command to show the isolation.

```rust
use nix::sched::{clone, CloneFlags};
use nix::sys::wait::waitpid;
use nix::mount::{mount, MsFlags};
use std::process::Command;

fn child_fn() -> isize {
    println!("Child: My PID is {}", std::process::id());

    // Mount a private /proc for this namespace
    // None means we use the default source/data
    let source: Option<&str> = Some("proc");
    let target = "/proc";
    let fstype: Option<&str> = Some("proc");
    
    if let Err(e) = mount(source, target, fstype, MsFlags::empty(), None::<&str>) {
        eprintln!("Child: Failed to mount /proc: {}", e);
        return 1;
    }

    println!("Child: Listing isolated processes:");
    let mut child = Command::new("ps")
        .arg("aux")
        .spawn()
        .expect("Failed to execute ps");

    child.wait().expect("ps failed");
    0
}

fn main() {
    println!("Parent: My PID is {}", std::process::id());

    // Define the stack for the child
    const STACK_SIZE: usize = 1024 * 1024;
    let mut stack = [0u8; STACK_SIZE];

    // Combine flags: New PID, New Mount (NS), and send SIGCHLD on exit
    let flags = CloneFlags::CLONE_NEWPID | CloneFlags::CLONE_NEWNS;

    // nix::sched::clone takes a closure and the stack
    match unsafe { clone(Box::new(child_fn), &mut stack, flags, Some(nix::libc::SIGCHLD)) } {
        Ok(pid) => {
            println!("Parent: Child created with PID {}", pid);
            waitpid(pid, None).expect("Wait failed");
            println!("Parent: Child finished.");
        }
        Err(e) => eprintln!("Parent: Clone failed: {}", e),
    }
}

```

---

### 3. Key Differences in Rust

* **Memory Safety**: In C, we manually calculated `child_stack + STACK_SIZE`. In Rust, the `nix` crate handles the stack pointer logic for you (though you still provide the buffer).
* **The `unsafe` Block**: Since `clone` creates a new process and manipulates the stack, it is inherently `unsafe`. Rust requires you to acknowledge this.
* **Closures**: Instead of a function pointer and a `void*` argument, Rust uses a closure (`Box::new(child_fn)`), which is more flexible for passing data.

---

### 4. How to Test

1. **Build**: `cargo build`
2. **Run with sudo**: `sudo ./target/debug/your_project_name`

### Why use a library instead of `std::process`?

The standard library `std::process::Command` is designed for portability (Windows/Linux/macOS). Since Namespaces are **Linux-only**, they aren't in the standard library. The `nix` crate is the industry standard for system-level programming in Rust when you need to talk directly to the Linux kernel.

**Would you like to see how to do this using a "User Namespace" so you can run the program without needing `sudo`?**
----------------------------------------------------
