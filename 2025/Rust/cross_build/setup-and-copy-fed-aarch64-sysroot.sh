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
