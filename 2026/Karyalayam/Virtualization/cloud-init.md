# Cloud-Init Tutorial

## Automatically Configuring Virtual Machines on First Boot

## Introduction

When deploying virtual machines (VMs) in cloud environments or private data centers, manually configuring 
each VM can be slow, repetitive, and error-prone. 

Tasks such as creating users, configuring networking, installing software, and setting hostnames must be 
repeated for every new instance.

- **Cloud-Init** solves this problem by automatically configuring a VM the very first time it boots.

- Instead of building a different VM image for every server, administrators create a single **generic cloud
  image** and supply a configuration file. During the first boot, `Cloud-Init` reads this configuration 
  and customizes the VM automatically.

- This makes VM deployment fast, repeatable, and fully automated.

---

## ToC:

* 01. What `Cloud-Init` is
* 02. Why `Cloud-Init` is important
* 03. How `Cloud-Init` works
* 04. `Cloud-Init` boot stages
* 05. `Cloud-Init` configuration files
* 06. How `Cloud-Init` automatically configures a VM
* 07. A complete `Cloud-Init` example
* 08. How `Cloud-Init` integrates with Infrastructure as Code (IaC)

---

## 01. What is Cloud-Init?

It's an open-source initialization package installed in many Linux cloud images such as Ubuntu, Debian, 
CentOS, Rocky Linux, and Fedora.

It runs automatically **only during the first boot** of a virtual machine.

Its job is to initialize the operating system by reading configuration data and applying it to the new VM.

Typical tasks include:

* Setting the hostname
* Creating users
* Installing SSH keys
* Configuring networking
* Installing packages
* Running shell scripts
* Writing configuration files
* Starting services

After completing these tasks, the VM is ready for use without requiring manual setup.

---

## 02. Why Do We Need Cloud-Init?

Imagine you need to deploy 100 Ubuntu virtual machines.

Without `Cloud-Init`, you would have to:

1. Create the VM.
2. Log into the VM.
3. Create users.
4. Configure SSH.
5. Install software.
6. Configure networking.
7. Start services.
8. Repeat the process 100 times.

This process is time-consuming and inconsistent.

With `Cloud-Init`:

1. Create the VM.
2. Provide a `Cloud-Init` configuration file.
3. Boot the VM.
4. `Cloud-Init` performs all configuration automatically.

The VM is ready within minutes.

---

## 03. How Cloud-Init Works

The flow diag illustrates the overall process:

```
          Generic Ubuntu Cloud Image
                     │
                     ▼
             Create Virtual Machine
                     │
                     ▼
      Attach Cloud-Init Configuration
       (User Data, Meta Data, Network)
                     │
                     ▼
               First VM Boot
                     │
                     ▼
             Cloud-Init Starts
                     │
                     ▼
      Reads Configuration Files
                     │
                     ▼
        Configures the Operating System
                     │
                     ▼
             VM Ready for Use
```

Notice that the operating system image never changes.

Only the `Cloud-Init` configuration changes from one VM to another.

---

## 04. Cloud-Init Boot Process

Cloud-Init runs automatically during the first boot in several stages.

### Stage 1 – Detect Data Source

`Cloud-Init` first determines where its configuration information is stored.

Examples include:

* AWS EC2 Metadata Service
* Azure Metadata Service
* Google Cloud Platform
* OpenStack
* VMware
* NoCloud ISO
* ConfigDrive

---

### Stage 2 – Read Configuration

`Cloud-Init` loads configuration files such as:

* user-data
* meta-data
* network-config

These files describe how the VM should be configured.

---

## Stage 3 – Configure the System

Cloud-Init begins configuring the operating system.

Typical actions include:

* Create users
* Configure SSH
* Configure hostname
* Configure network
* Resize disks
* Install software
* Write configuration files

---

### Stage 4 – Execute Commands

Finally, Cloud-Init runs any commands or scripts provided by the administrator.

For example:

* Install Docker
* Start Nginx
* Configure Apache
* Download application files

The VM is now fully initialized.

---

## Cloud-Init Configuration Files

Cloud-Init mainly works with three files.

---

### 1. user-data

This file contains the configuration instructions.

Example:

```yaml
#cloud-config

hostname: webserver01

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-ed25519 AAAAB3Nza...

package_update: true

packages:
  - nginx
  - git

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
```

This configuration:

* Sets the hostname
* Creates a user
* Adds an SSH key
* Updates packages
* Installs Nginx and Git
* Starts the Nginx service

---

### 2. meta-data

Meta-data identifies the VM.

Example:

```yaml
instance-id: vm-001
local-hostname: webserver01
```

It provides information such as:

* Instance ID
* Hostname

---

### 3. network-config

Configures networking.

Example:

```yaml
version: 2

ethernets:
  eth0:
    dhcp4: true
```

For a static IP:

```yaml
version: 2

ethernets:
  eth0:
    addresses:
      - 192.168.1.100/24
    gateway4: 192.168.1.1
```

---

## Example: Building a Web Server Automatically

Suppose you download an Ubuntu Cloud Image.

Instead of manually installing software, you create this Cloud-Init file:

```yaml
#cloud-config

hostname: web01

package_update: true

packages:
  - nginx

write_files:
  - path: /var/www/html/index.html
    content: |
      Welcome to my Cloud-Init Web Server!

runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
```

When the VM boots for the first time, Cloud-Init automatically:

* Sets the hostname to **web01**
* Updates package repositories
* Installs Nginx
* Creates a web page
* Enables Nginx
* Starts the web server

No manual login is required.

---

## Using One Image for Multiple VMs

One of Cloud-Init's greatest strengths is image reuse.

```
               Ubuntu Cloud Image
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
   VM-1           VM-2           VM-3

Hostname        Hostname       Hostname
web01           db01           app01

Install         Install        Install
Nginx           MySQL          Docker

Different Cloud-Init files
Same VM Image
```

A single operating system image can create hundreds of unique servers.

---

## Cloud-Init in Private Virtualization

Cloud-Init is commonly used with:

* KVM
* QEMU
* VMware
* Proxmox
* OpenStack
* Hyper-V (supported distributions)

Typical deployment process:

```
Download Ubuntu Cloud Image
            │
            ▼
Create Virtual Disk (QCOW2)
            │
            ▼
Create Cloud-Init ISO
      │
      ├── user-data
      ├── meta-data
      └── network-config
            │
            ▼
    Attach ISO to VM
            │
            ▼
        Boot VM
            │
            ▼
Cloud-Init Reads ISO
            │
            ▼
VM Configured Automatically
```

---

## Cloud-Init with Terraform

Cloud-Init is frequently used together with Terraform.

```
Terraform
    │
    ▼
Creates Virtual Machine
    │
    ▼
Passes Cloud-Init YAML
    │
    ▼
Cloud-Init Configures Operating System
    │
    ▼
Application Ready
```

Terraform creates infrastructure, while Cloud-Init configures the operating system inside the VM.

---

## Advantages of Cloud-Init

Cloud-Init provides several benefits:

* Fully automated VM initialization
* Consistent server configuration
* Faster deployment
* Reusable operating system images
* Reduced manual errors
* Easy integration with Infrastructure as Code tools
* Works across multiple cloud providers
* Supports custom scripts and automation

---

## Summary

Cloud-Init is an initialization framework that automatically configures Linux virtual machines during
their first boot. Rather than maintaining many customized VM images, administrators use a generic cloud
image and provide configuration files that describe how each instance should be customized. Cloud-Init
reads these files, configures the operating system, installs software, creates users, configures
networking, and executes initialization scripts before the VM becomes available. This approach enables
rapid, consistent, and scalable deployment of virtual machines across cloud platforms and on-premises
virtualization environments.
