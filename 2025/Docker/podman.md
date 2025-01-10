# Podman

### Installation:

```
# debian
`sudo apt install -y podman podman-docker podman-compose buildah skopeo`
# Fedora
`sudo dnf install -y podman podman-docker podman-compose buildah skopeo`
```

- podman: Installs the Podman engine.
- podman-docker: Provides Docker CLI commands that internally use Podman.
- podman-compose: Equivalent of Docker Compose for Podman.
- buildah: Tool for building OCI and Docker container images.
- skopeo: Tool for inspecting and moving container images between registries.

### Config image storage location

Customize the image location storage area:a
Ex : /home/daybreak/.config/containers/storage.conf
```
[storage]
driver = "overlay"
graphroot = "/home/daybreak/container_images/storage"
runroot = "/home/daybreak/container_images/run"
```

### Info

Podman offers set of tools that function similarly to Docker and can replace Docker for managing containers.

Podman is available in Debian’s official repositories, so you can install it directly using `apt`:

For a full replacement of docker with podmand, we need to install, podman and  podman-related tools.

- `podman-docker`: This package provides a symbolic link from Docker commands 
(e.g., `docker`, `docker-compose`) to their equivalent Podman commands. 
It allows you to use Docker CLI commands with Podman.

- `podman-compose`: This is the Podman equivalent of Docker Compose, allowing you to define and run 
multi-container applications.

Install these tools using the following commands:

```bash
sudo apt install -y podman-docker podman-compose
```
Verify Podman and its tools are installed correctly by checking their versions:

```bash
podman --version
podman-compose --version
```

You can also check that the Docker CLI commands are working by running:

```bash
docker --version  # Should use Podman under the hood
```

### Enable Podman for rootless containers (optional)

By default, Podman can run containers without requiring root privileges (rootless). 
To enable rootless containers, you may want to configure the user and ensure Podman is set up to use 
rootless containers by default. You can verify this by running:

```bash
podman info
```

Look for the "rootless" section in the output to ensure it is configured correctly.

###  Docker Compose Replacement (optional)
If you need Docker Compose-like functionality, you can use `podman-compose`, which functions similarly to 
Docker Compose but uses Podman underneath.

```bash
podman-compose up
```

### Additional tools (optional):
You might also want to install additional tools that integrate with Podman or provide useful functionality, 
such as:

- **Buildah**: A tool for building OCI and Docker container images (alternative to Docker build).
- **Skopeo**: A tool for inspecting and moving container images between registries.

To install these, you can run:

```bash
sudo apt install -y buildah skopeo
```
