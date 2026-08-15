# `cloud-init`

Ref: 
[1. Cloud Init Official docs ](https://docs.cloud-init.io/en/0.7.8/index.html)

## Introduction:

`cloud-init` : Industry standard multi-distribution tool used for cross-platform initialization of cloud
instances and VM's. 

It acts as first boot configuration engine, allowing a single, generic OS image to be dynamically
customized the instance it boots up.

In-depth Overview:
    - Architecture
    - Core concepts
    - Execution stages
    - typical use cases

### Key features**:

- Traditionally, if you wanted a customized VM image ( with specific user accounts, SSH Keys and unique
hostname, custom network routing and pre-installed packages ), you had to manually build, snapshot, 
and store a unique disk image for every variation. 

- `cloud-init` decouples the **OS** from the configuration. You maintain one pristine, lightweight image (
  ex: a vanilaa Alpine, Ubuntu, or Fedora image ) and pass a tiny text file containing instructions to the
  VM upon creation. 

### Key components: MetaData, DataSouces, and User-Data. 

`cloud-init` relies on three primary pillars during boot: 

1. *Data Sources*: How `cloud-init` finds its data. `cloud-init` automatically detects what environment it
   is running (ex: Openstack, Proxmox, VMware, or an local iso/no-cloud drive ). It queries standard
   locations, such as the local hypervisor config drive, or cloud meta-data service ( commonly reachable
   via the magic IP:`169.254.169.254` ) 
   Ref: [cloud-init documentation](https://docs.cloud-init.io/en/0.7.8/topics/datasources.html#:~:text=%C2%B6%20Datasources%20are%20sources%20of%20configuration%20data,that%20created%20the%20configuration%20drive%20(aka%20metadata).)

2.  *Meta Data*: Information about the instance supplied by the platform itself( ex: instance ID, Local
    IP, assigned Hostname )

3. *User Data*: Instructions provided by the user. This is usually written in YAML using the
   `#cloud-config` syntax, or as a raw shell script.


### How It works: The Boot Stages: 

`cloud-init` breaks down its execution down into distinct *`systemd` driven* boot stages to ensure
networking, storage, and software packages are handled in the correct chronological order:

1. *Generator Stage* ( `cloud-init-local` ): Runs early, determines if `cloud-init` should execute and
   search for local datasources.

2. *Local Stage* ( `cloud-init-local.service` ): Applies early networking configurations and sets up
   fallback DHCP mechanisms. 

3. *Network Stage* ( `cloud-init.service` ): Waits for network connectivity to be fully active, then
   fetches remote meta-data and user-data. 

4. *Config Stage* ( `cloud-config.service` ): Executes core configuration modules. ( ex: creating users,
   writing configuration files, expanding the root file-system )

5. *Final Stage* ( `cloud-final.service` ): Runs at the tail end of the boot sequence. This is where
   package installation ( `packages:` module ) and user-defined custom scripts ( `runcmd` ) are executed. 

### Anatomy of the User-data Sccript ( `#cloud-config` )

A standard `cloud-init` config file is structured in YAML. A typical script can handle multiple
administrative tasks simultaneously:

```yaml 

#cloud-config 
# set the systems hostname:
hostname: k8s-worker-01

# Manage users and SSH access
users:
  - name: devops
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD...
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash

# Automatically expand the root partition/filesystem to fill available disk space
resize_rootfs: true 

# Declare required software packages to install on first boot
packages:
  - curl
  - iperf3
  - apt-transport-https

# Run custom commands or scripts sequentially
runcmd:
  - [ echo, "Node successfully initialized!" ]
  - [ systemctl, enable, --now, ssh ]

```

### Strengths and Limitations:

- Advantages:
    * True Portability ("Write Once, Run Anywhere"): The exact same configuration payload can initialize a
      VM on a local KVM/Proxmox hypervisor, an OpenStack private cloud, or public clouds like AWS and
      Azure.  
    * Stateless Base Images: Eliminates "image fatigue." You don't need to rebuild heavy QCOW2 images
      every time a minor script or user key changes.
    * Deep Ecosystem Integration: Native support in Infrastructure-as-Code tools like Terraform, OpenTofu,
      Ansible, and Kubernetes provisioning frameworks (like Cluster API).

- Limitations: 
    * First-Boot Dependency: Because execution happens during boot, any syntax errors in your YAML
      configuration will cause cloud-init to fail, which can lock you out of SSH access unless a serial
      console is available.
    * Boot Time Overhead: Running package managers (apt, apk, dnf) or heavy setup scripts on every first
      boot can extend the time it takes for a virtual machine to become fully ready.

### Key Configuration Points for Network & package success:

Note: If the configuration relies on package managers ( `packages:` module, `apt`, `apk add`, `dnf`) the
virtual machine must have active network and internet access ( or local, mirror repository ) during the
first boot stage. 

Few Key points to keep in mind:

1. *Network Configuration First ( `networking:` module ):

-  If you are running in an environment where DHCP isn't automatically handing out IP addr or gateway
   routes (common in certain private hypervisors or isolated VLANs), you must explicitly define network
   settings in your `cloud-init` block. If `cloud-init` can't talk to the outside world, the package
   installation step will time out and fail.

```yaml 
#cloud-config
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
```

2. *Handling Air-Gapped or Offline Environments* : 

- If your infrastructure is completely offline (no internet access), putting packages: in your
  `cloud-init` will cause the boot sequence to hang or fail. For offline environments, you must shift away
  from runtime package installation and use build-time tools (like `virt-builder` or pre-baked QCOW2
  images) to include those packages beforehand.

3. *Error Handling and Logs*: 

- As `cloud-init` runs in the background during boot, if a package installation fails due to a network glitch, you won't see it on a standard login screen. You always check the logs inside the VM at:
    * `/var/log/cloud-init.log`: Detailed execution steps 
    * `/var/log/cloud-init-output.log`: std output and error message from your `runcmd` or package
      installations. 


## Complete Life Cycle for handling VM provisioning: 

**Step 1**: Obtain the Base Image:
    - Classic Cloud Images (Alpine, Debian, Fedora Cloud): These are typically downloaded directly via URL
      (wget, curl) or fetched via virt-builder rather than pulled from a container registry.
    - Modern Container-Native Images (bootc): If you are using Fedora/CentOS bootable containers, you pull
      the base image via Podman (podman pull) and use bootc-image-builder to compile it directly into a
      QCOW2 disk image. 

**Step 2**: Creating the Overlay ( Copy-on-write )
    - Isolate the base image as read-only and generate a lightweight delta overlay for your specific VM
      instance: `qemu-img create -f qcow2 -F qcow2 -b base-image.qcow2 vm-overlay.qcow2`

**Step 3**: Defining Cloud-Init Configurations
    - You write your flat text YAML files (user-data, meta-data, and optional network-config) to dictate
      hostnames, SSH public keys, users, and runtime scripts.

**Step 4**: Building the Seed ISO:
    - you use `cloud-localds` ( or `genisoimage` ) to build the YAML configs into a small, virtial ISO
      seed drive that the hypervisor will attach to the VM on its first boot:
      `cloud-localds seed.iso user-data meta-data`

**Step 5**: Build time customization ( fedora only )
    - If we want to skit packae installation entirely and pre-bake tools into the image beforehand, you
      leverage `virt-customize`

