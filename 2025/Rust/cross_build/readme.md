# Setup Fedora aarch64 sysroot for cross-compilation.


Your outlined steps are very well thought out and **mostly correct** for setting up a Fedora **aarch64 sysroot** using Podman on x86\_64 Fedora for **Rust cross-compilation** (or general cross-compilation with `aarch64-linux-gnu-gcc`). Here's a review with **suggested improvements and clarifications**:

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
