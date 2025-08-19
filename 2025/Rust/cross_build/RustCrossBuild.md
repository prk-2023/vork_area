# History:

Noticed that cross compiling Rust packages to aarch64 failed on Fedora and passed on debian.
The root cause is the way packages are bundled in debian and fedora differ. 

Debian provides a convenient, all-in-one solution for developers who want to start cross-compiling simple things quickly.

Fedora requires to pull the sysroot for aarch64 along with the installation of cross toolchain via dnf. 
This adds in additional steps but give a better control on what extra can be packed into the sysroot. 

Since we can not directly install aarch64 packages on fedora_x86_64 host, as the installation of 
`glibc-devel.aarch64` conflicts with the native `x86_64` version. 

The RPM database will prevent you from installing two different architectures of the same package.

Instead we can use podman to install and pull the sysroot from the container:

Let's get this right. Here are the **actual, working solutions** for Fedora.

### The Core Problem Reiterated

The `aarch64-linux-gnu-gcc` package on Fedora is a **cross-compiler**, but it lacks a **target sysroot** (the `aarch64` version of `libc`, headers, and other libraries). 

Fedora's packaging system prevents installing a second architecture of core system libraries like `glibc-devel` directly on the host.

---

### Solution 1: Use the `sysroot` from a Fedora Docker/Podman Container (Your Idea)

This is a clean and official method. You use a container to get the pure `aarch64` filesystem and then point your cross-compiler to it.

1.  **Pull the Fedora AArch64 container image:**
    ```bash
    podman pull --arch=arm64 registry.fedoraproject.org/fedora:latest
    ```
    *The `--arch=arm64` flag is crucial to get the AArch64 image.*

2.  **Create a container and copy out the entire root filesystem:**
    ```bash
    # Create a temporary container and copy its rootfs to a directory on your host
    container_id=$(podman create --arch=arm64 registry.fedoraproject.org/fedora:latest)
    podman cp $container_id:/ ./fedora-aarch64-sysroot
    podman rm $container_id

    # (Optional) Install development packages inside the sysroot for more headers/libs
    # This is more complex and might require using systemd-nspawn or chroot, but for basic libc, the base image is often sufficient.
    ```

3.  **Use the `--sysroot` flag with your cross-compiler:**
    ```bash
    aarch64-linux-gnu-gcc --sysroot=/path/to/fedora-aarch64-sysroot hello.c -o hello
    ```

**Pros:** Very clean, official, and reproducible.
**Cons:** The sysroot is minimal (base Fedora). Adding `-devel` packages is trickier.

---

### Solution 2: Use a Pre-Built Toolchain (Often the Easiest)

Download a comprehensive toolchain that includes both the compiler *and* a matching sysroot. Linaro and ARM themselves provide these.

1.  **Download a toolchain.** For example, get the **AArch64 target (aarch64-linux-gnu)** GCC toolchain from ARM's developer pages or Linaro.
    *   [ARM GNU Toolchain](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain)
    *   [Linaro Toolchain](https://www.linaro.org/downloads/)

2.  **Extract it somewhere** (e.g., `/opt/`):
    ```bash
    sudo tar xf gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz -C /opt/
    ```

3.  **Add the `bin/` directory to your `PATH` and use the compiler:**
    ```bash
    export PATH=/opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin:$PATH
    aarch64-none-linux-gnu-gcc hello.c -o hello # Notice the different prefix
    ```
    These toolchains are completely self-contained with their own integrated sysroot, so no extra flags are needed.

**Pros:** "Just works," most reliable, often highly optimized.
**Cons:** Manual download and management, separate from Fedora's package manager.

---

### Solution 3: Cross-Compile `glibc` Yourself (Most Complex)

This is how projects like Buildroot and Yocto do it. You use the cross-compiler to build `glibc` for the target, which creates a clean sysroot.

1.  Install the compiler and source:
    ```bash
    sudo dnf install aarch64-linux-gnu-gcc git wget
    ```

2.  Download the `glibc` source code.

3.  Configure and compile it, using `CC=aarch64-linux-gnu-gcc` and `--prefix` to specify where to install the result (your new sysroot).
    This process is complex and has many dependencies.

**Pros:** Ultimate control over version and configuration.
**Cons:** Very time-consuming and complex, easy to get wrong.

---

### Recommendation

For 95% of users, **Solution 2 (Pre-Built Toolchain)** is the best choice. 
It's the path of least resistance and is designed explicitly for this purpose.

Your idea, **Solution 1 (Podman)**, is fantastic for when you want to match the host's Fedora versions exactly or are working in a 
container-centric environment.

-------------

# verify the proposed approach:

Your outlined steps are very well thought out and **mostly correct** for setting up a Fedora **aarch64 sysroot** using Podman on x86\_64 Fedora for **Rust cross-compilation** (or general cross-compilation with `aarch64-linux-gnu-gcc`). 


Here's a review with **suggested improvements and clarifications**:

---

## ✅ Reviewed Steps with Comments

---

### **Step 1: Install tools**

```bash
sudo dnf install podman aarch64-linux-gnu-gcc
```

✅ Correct. You might also consider installing:

```bash
sudo dnf install qemu-user-static

# or only for aarch64

sudo dnf install qemu-user-static-aarch64 
```

* This allows Podman to **run aarch64 containers** via QEMU user emulation (especially necessary for `dnf install` inside the container in step 4).

---

### **Step 2: Pull the correct image**

```bash
podman pull --arch=arm64 registry.fedoraproject.org/fedora:latest
```

✅ This works and ensures you pull the `aarch64` variant of the Fedora image. You can also specify a version tag like `fedora:40` if needed.

---

### **Step 3: Extract the base root filesystem**

```bash
container_id=$(podman create --arch=arm64 registry.fedoraproject.org/fedora:latest)
podman cp "$container_id:/" ./fedora-aarch64-sysroot
podman rm "$container_id"
```

✅ This extracts the full root filesystem.

🔎 **Alternative tip:** You can use `--name` instead of capturing `container_id` if you want more readable or repeatable commands.

---

### **Step 4: Install development packages into the sysroot**

```bash
podman run --rm --privileged \
    --volume $(pwd)/fedora-aarch64-sysroot:/sysroot:rw \
    --arch=arm64 registry.fedoraproject.org/fedora:latest \
    /bin/bash -c \
    'dnf install -y --installroot /sysroot glibc-devel glibc-headers kernel-headers --releasever $(rpm -E %fedora) && \
     chroot /sysroot /bin/bash -c "dnf clean all"'
```

✅ Excellent idea to install into the sysroot using `--installroot`.

🟨 **Minor caution**:

* Fedora's `dnf` sometimes needs `/dev`, `/proc`, and `/sys` mounted in the chroot to properly resolve dependencies.
* Consider using `--setopt=install_weak_deps=False` if you want to minimize installed packages.
* Ensure `qemu-user-static` is correctly registered via `binfmt_misc` for this to succeed (especially on older Fedora versions). Run:

  ```bash
  podman run --rm --privileged tonistiigi/binfmt --install all
  ```

💡 **Optional hardening**:
You could use `dnf --releasever=40` to lock to a version, avoiding mismatch from `%fedora` if your host is ahead.

---

### **Step 5: Compile and test**

```bash
aarch64-linux-gnu-gcc --sysroot=$(pwd)/fedora-aarch64-sysroot hello.c -o hello
file hello
```

✅ Works perfectly for simple C programs.

---

## ✅ Summary: Everything Looks Good

Your workflow is valid and will:

* Create an ARM64-compatible sysroot.
* Allow compilation of binaries for `aarch64`.
* Be reusable for **Rust cross-compilation** by pointing `target.aarch64-unknown-linux-gnu.linker` to `aarch64-linux-gnu-gcc`.

---

## 🔧 Optional Rust Configuration Example (`.cargo/config.toml`)

If you're planning to use this for Rust:

```toml
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
rustflags = ["--sysroot=/path/to/fedora-aarch64-sysroot"]
```

> Replace `/path/to/` accordingly.

---

Would you like me to help convert this setup into a `Makefile` or a script for reuse?

Here's a short and clear explanation of each step:

---------------------------

### **Step 3: Extract the base root filesystem**

```bash
container_id=$(podman create --arch=arm64 registry.fedoraproject.org/fedora:latest)
podman cp "$container_id:/" ./fedora-aarch64-sysroot
podman rm "$container_id"
```

🔹 **What it does:**

* Creates a **stopped aarch64 container** from the Fedora image (but doesn’t run it).
* **Copies the entire root filesystem (`/`)** from the container to a local directory `./fedora-aarch64-sysroot`.
* **Removes** the temporary container afterward.

📦 Result: You get a local copy of Fedora's aarch64 root filesystem — like a lightweight ARM64 chroot.

---

### **Step 4: Install development packages into the sysroot**

```bash
podman run --rm --privileged \
    --volume $(pwd)/fedora-aarch64-sysroot:/sysroot:rw \
    --arch=arm64 registry.fedoraproject.org/fedora:latest \
    /bin/bash -c \
    'dnf install -y --installroot /sysroot glibc-devel glibc-headers kernel-headers --releasever $(rpm -E %fedora) && \
     chroot /sysroot /bin/bash -c "dnf clean all"'
```

🔹 **What it does:**

* Runs an aarch64 Fedora container with your local `fedora-aarch64-sysroot` mounted at `/sysroot`.
* Installs development libraries (`glibc-devel`, `headers`, etc.) **into that sysroot** using `dnf --installroot`.
* Uses `chroot` to enter the sysroot and run `dnf clean all` inside, to remove cached metadata and save space.

🛠️ Purpose: Prepares the sysroot with necessary development headers for cross-compilation (e.g., with Rust or GCC).

----------------------------------

# Putting all to gather:

Here's a **reusable shell script** that automates all 5 steps of your workflow to prepare a Fedora AArch64 sysroot for cross-compilation.

---

### ✅ `setup-fedora-aarch64-sysroot.sh`

```bash
#!/usr/bin/env bash

set -euo pipefail

SYSROOT_DIR="${1:-fedora-aarch64-sysroot}"
FEDORA_VERSION="${2:-latest}"
IMAGE="registry.fedoraproject.org/fedora:$FEDORA_VERSION"
ARCH="arm64"

echo ">>> Installing required host tools..."
sudo dnf install -y podman aarch64-linux-gnu-gcc qemu-user-static-aarch64

echo ">>> Pulling Fedora $ARCH image..."
podman pull --arch="$ARCH" "$IMAGE"

echo ">>> Creating and extracting container root filesystem to '$SYSROOT_DIR'..."
container_id=$(podman create --arch="$ARCH" "$IMAGE")
rm -rf "$SYSROOT_DIR"
podman cp "$container_id:/." "$SYSROOT_DIR"
podman rm "$container_id"

echo ">>> Installing development packages into sysroot..."
podman run --rm --privileged \
    -v "$(pwd)/$SYSROOT_DIR:/sysroot:rw" \
    --arch="$ARCH" "$IMAGE" \
    /bin/bash -c "
        dnf install -y --installroot=/sysroot \
            glibc-devel glibc-headers kernel-headers \
            --releasever=\$(rpm -E %fedora) && \
        chroot /sysroot dnf clean all
    "

echo ">>> Done! Sysroot prepared at: $SYSROOT_DIR"
echo ">>> Example compile:"
echo "    aarch64-linux-gnu-gcc --sysroot=\$(pwd)/$SYSROOT_DIR hello.c -o hello"
```

---

### 📦 Usage

1. **Make it executable**:

   ```bash
   chmod +x setup-fedora-aarch64-sysroot.sh
   ```

2. **Run it (optional args: target directory and Fedora version)**:

   ```bash
   ./setup-fedora-aarch64-sysroot.sh my-sysroot 40
   ```

   * `my-sysroot` is the output sysroot directory.
   * `40` is the Fedora release (or use `latest`).

---

### 🧪 Test Compilation

After the script finishes, compile a test program:

```c
// hello.c
#include <stdio.h>
int main() {
    printf("Hello from AArch64!\n");
    return 0;
}
```

```bash
aarch64-linux-gnu-gcc --sysroot=$(pwd)/my-sysroot hello.c -o hello
file hello
```

---

Let me know if you want a Rust `.cargo/config.toml` generator for this setup too.


--------------
# Example config.toml for rust cross builds:

Here’s a matching `.cargo/config.toml` snippet that works with the sysroot you generated using the script — perfect for **Rust cross-compilation to AArch64** using the GNU toolchain (`aarch64-unknown-linux-gnu`):

---

### ✅ `.cargo/config.toml`

```toml
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
rustflags = [
  "--sysroot=/absolute/path/to/fedora-aarch64-sysroot"
]
```

> 🔁 Replace `/absolute/path/to/fedora-aarch64-sysroot` with the actual path where your sysroot was extracted (e.g., `$(pwd)/fedora-aarch64-sysroot`).

---

### 🛠️ Example with full integration:

Assuming the script output is in `fedora-aarch64-sysroot` inside your project:

```toml
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
rustflags = [
  "--sysroot=${CARGO_MANIFEST_DIR}/fedora-aarch64-sysroot"
]
```

This makes it portable inside a Rust project.

---

### 📦 Add the target if you haven’t:

```bash
rustup target add aarch64-unknown-linux-gnu
```

---

### 🚀 Build for AArch64

```bash
cargo build --target=aarch64-unknown-linux-gnu
```

---

Let me know if you want to automate Rust toolchain setup or sysroot detection in the script.


