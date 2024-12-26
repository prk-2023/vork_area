# RPMsg:

## 1. RPMsg framework:


The **RPMsg (Remote Processor Messaging)** framework is a communication mechanism in Linux that allows 
message passing between a main processor (e.g., ARM-based CPU) and a remote processor 
(e.g., a DSP, co-processor, or another ARM core) in a multi-processor system. 

RPMsg enables the Linux kernel to communicate with remote processors through a message-passing interface 
using **shared memory** and a **frame-based** protocol.

The **RPMsg frame** is the structure that contains the actual message to be exchanged between the 
Linux kernel and the remote processor.

### Overview of RPMsg Communication

1. **Remote Processor (Remote Core)**: 

    The remote processor runs firmware that interacts with the RPMsg framework in the Linux kernel. 
    This firmware typically sends and receives messages via the RPMsg framework to communicate with the 
    main processor (Linux).
   
2. **Linux Kernel (Master Processor)**: 

    The Linux kernel provides the RPMsg framework for message handling. 
    The kernel exposes RPMsg devices to user-space applications, which interact with the framework 
    using standard file operations (`open()`, `read()`, `write()`, `close()`).

3. **Shared Memory**: 

    The communication occurs via shared memory regions that both the remote processor and the Linux kernel 
    can access. 
    The memory space is mapped so that the remote processor can read from or write to specific memory 
    regions, and the Linux kernel can do the same.

4. **RPMsg Channels**: 

    Communication is done through **channels**, which are virtual communication endpoints. 
    These channels are represented by device files (e.g., `/dev/rpmsgX`) that allow user-space applications 
    or kernel modules to send/receive data.

### RPMsg Frame Structure

RPMsg uses frames to carry the data in the communication process. ( similar to Ethernet frame)
Each frame contains the following elements:

1. **Header**:
   - **Source Address**: Identifies the sender (e.g., remote processor or the Linux kernel).
   - **Destination Address**: Identifies the receiver (e.g., the opposite processor).
   - **Message ID**: A unique identifier for the message being sent.
   - **Channel ID**: An identifier for the RPMsg channel being used.

2. **Payload**:
   - The actual data or message content that needs to be communicated. 
     This is the information being exchanged between the processors.

3. **Metadata**:
   - Optionally, additional metadata related to the message, such as message size, type, or other custom 
     fields defined by the application.

The RPMsg message typically has a simple format, with both the header and the payload, enabling efficient 
communication between the processors.

### How RPMsg Frame Works in Communication

1. **Sending a Message from the Remote Processor**:
   - The remote processor writes a message into a shared memory region that is mapped to both the remote 
     processor's memory and the Linux kernel’s memory.
   - The message follows the RPMsg frame format, which includes a header 
     ( source address, destination address, message ID, etc.) and the payload (the actual data).
   - => The remote processor triggers an interrupt to notify Linux that a message is available for reading.
   - The Linux kernel RPMsg driver reads the frame from the shared memory region, processes the header, and 
     retrieves the payload.

2. **Sending a Message from the Linux Kernel**:
   - When the Linux kernel wants to send a message to the remote processor, it writes a message to the 
     shared memory region.
   - The message is structured as an RPMsg frame with a header and payload.
   - Once the message is written, the Linux kernel may trigger an interrupt to notify the remote processor 
     that a message is available.
   - The remote processor reads the message from shared memory, processes the header, and retrieves the 
     payload.

### RPMsg Communication Flow (Message Exchange)

1. **Setup**:
   - The communication starts with the kernel creating an RPMsg device file (e.g., `/dev/rpmsgX`), 
     which allows user-space applications to open and interact with the RPMsg channel.

   - The remote processor’s firmware creates a corresponding channel for communication. 
     Both sides must agree on the channel ID.

2. **Sending a Message (from Remote Processor to Linux Kernel)**:
   - The remote processor sends a message by writing data into the shared memory that the kernel can access.
   - The message follows the RPMsg frame format:
     - **Header**: Contains metadata like source, destination, message ID, and channel.
     - **Payload**: The actual data to be sent.
   - The kernel reads the message from shared memory, processes the header and payload, and handles the 
     message (e.g., passing it to user-space if needed).

3. **Sending a Message (from Linux Kernel to Remote Processor)**:
   - The kernel sends a message by writing the data into the shared memory region accessible by the 
     remote processor.
   - The message follows the same frame structure: header + payload.
   - The remote processor’s firmware reads the message from shared memory and processes it.

4. **Interrupt Handling**:
   - The kernel and remote processor use interrupts to notify each other when messages are ready to be read
     or written. This ensures asynchronous communication.

### Example of an RPMsg Frame

A simplified RPMsg frame might look like this:

#### 1. **Header Structure**:
The header could contain:
- **Source Address** (e.g., 0x100): The address of the sender (Linux or remote processor).
- **Destination Address** (e.g., 0x200): The address of the receiver (Linux or remote processor).
- **Message ID** (e.g., 0x01): A unique ID identifying this specific message.
- **Channel ID** (e.g., 0x01): The RPMsg channel to which this message belongs.
- **Length** (e.g., 32): The length of the payload.

Example header (in bytes):
```
[ Source Address (4 bytes) ][ Destination Address (4 bytes) ]
[ Message ID (2 bytes) ][ Channel ID (2 bytes) ]
[ Payload Length (2 bytes) ][ Reserved (2 bytes) ]
```

#### 2. **Payload**:
The payload is the actual message data sent between the processors. It could be any form of data, 
like a string, a structure, or binary data. 

For example:
```
"Hello from Linux Kernel" (or a structured data payload)
```

#### 3. **Interrupts for Notification**:
Both the Linux kernel and the remote processor can generate interrupts to notify the other party that 
new data is available to be read or that a message has been written into shared memory. 
This ensures asynchronous and real-time message passing.

### RPMsg Communication Use Cases

- **Firmware Communication**: 
    A remote processor like a DSP or another ARM core running firmware communicates with the Linux kernel 
    to send sensor data or other results.
- **Co-Processor Communication**: 
    For platforms with a co-processor (e.g., image processor or video accelerator), 
    RPMsg allows efficient communication between the Linux kernel and the co-processor.

- **Multi-Core Communication**: 
    RPMsg is used to allow communication between cores of a multi-core ARM processor or between different 
    heterogeneous cores in a multi-processor system.

### Summary of RPMsg Frame Workflow

1. **RPMsg Frame**: 
    The frame contains a header (src/dst, message ID, channel ID, etc.) and a payload (actual data).
2. **Shared Memory**: 
    Communication occurs through a shared memory region accessible by both the remote processor and the 
    Linux kernel.
3. **Interrupts**: 
    Interrupts notify each processor when new messages are available to be read or written.
4. **Asynchronous Communication**: 
    RPMsg enables efficient, real-time communication between the Linux kernel and remote processors 
    using frames with headers and payloads. 

The RPMsg framework provides an effective way for processors in a heterogeneous system to exchange messages,
making it suitable for embedded systems, multi-core SoCs, and systems with a main processor and co-processors.


##  2. RPMsg data path user <==> space
---

To send and receive **rpmsg (remote processor messaging)** packets between **user-space applications** and 
the **Linux kernel**, you typically use the **RPMsg framework** in Linux. 

This framework facilitates communication between different processors in a system 
(e.g., between an ARM CPU and a DSP or a coprocessor) using shared memory and message passing.

The general flow involves:

1. **Kernel-side rpmsg driver**: 
    The kernel provides an interface for communication with remote processors via RPMsg.
2. **User-space application**: 
    User-space applications can send and receive messages through RPMsg to/from the kernel.

### How it Works

#### 1. **RPMsg in the Kernel**:

The RPMsg framework is supported in the Linux kernel, and the kernel typically exposes this functionality 
via a **character device** interface (`/dev/rpmsgX`). 
The remote processor (e.g., a DSP or another ARM core) will use a specific RPMsg channel to send messages 
to the Linux kernel.

- **RPMsg device**: 
    A device representing the RPMsg communication channel is created by the kernel under `/dev/`.
  
  For example:
  ```bash
  /dev/rpmsg_chrdev0
  ```

#### 2. **User-Space Applications**:

User-space apps interact with the RPMsg framework using the **RPMsg character device** interface. 
This allows user-space apps to send and receive RPMsg messages just like they would interact with other 
types of character devices.

### Steps to Send/Receive RPMsg from User-Space:

#### A. **Enable RPMsg in the Kernel**
Before user-space applications can interact with RPMsg, the kernel needs to be properly configured. 
The kernel configuration should have the necessary RPMsg options enabled.

1. **Enable RPMsg support in kernel config**:
   In the Linux kernel configuration (`.config`), ensure the following are enabled:
   ```bash
   CONFIG_RPMSG=y
   CONFIG_RPMSG_CHAR=y
   CONFIG_RPMSG_MAESTRO=y  # Or any specific RPMsg transport for your platform
   ```
   
2. **Loading the RPMsg driver**:
   After compiling and booting the kernel with RPMsg support, the RPMsg driver should load automatically 
   when a new RPMsg device is detected. 
   You should see entries in `/dev/` as `/dev/rpmsg0` or `/dev/rpmsg_chrdevX`, depending on your system.

#### B. **Send RPMsg from User-Space**:

In user-space, RPMsg communication is done using standard file operations 
(`open()`, `read()`, `write()`, `ioctl()`).

1. **Opening the RPMsg device**:
   First, the user-space application opens the RPMsg device file for communication. 
   The device file represents the RPMsg channel to communicate with the kernel or remote processor.

   Example code to open the RPMsg device:
   ```c
   int fd = open("/dev/rpmsg0", O_RDWR);
   if (fd < 0) {
       perror("Failed to open RPMsg device");
       return -1;
   }
   ```

2. **Sending a message to the kernel**:
   After opening the device, the user-space application can use the `write()` system call to send data to 
   the RPMsg device. 
   The RPMsg kernel driver will pass the message to the remote processor (e.g., DSP, co-processor).

   Example code to send data:
   ```c
   const char *msg = "Hello from userspace";
   ssize_t bytes_written = write(fd, msg, strlen(msg));
   if (bytes_written < 0) {
       perror("Failed to write to RPMsg device");
   }
   ```

#### C. **Receive RPMsg in User-Space**:
The user-space application can read incoming messages from the RPMsg device using the `read()` system call.

1. **Reading a message**:
   Example code to read a message from the RPMsg device:
   ```c
   char buffer[256];
   ssize_t bytes_read = read(fd, buffer, sizeof(buffer));
   if (bytes_read < 0) {
       perror("Failed to read from RPMsg device");
   } else {
       buffer[bytes_read] = '\0';  // Null-terminate the message
       printf("Received message: %s\n", buffer);
   }
   ```

#### D. **Close the RPMsg device**:
After communication is complete, the user-space application closes the RPMsg device.

Example code to close the RPMsg device:
```c
close(fd);
```

### RPMsg Channels

The RPMsg framework operates on **channels**. 
A channel is an endpoint for communication between processors. 
Each RPMsg channel typically represents a unique device on the remote processor.

- **RPMsg channel name**: 
    The RPMsg framework in Linux uses channel names, which are usually derived from the remote processor 
    and the message ID.

- **Binding the RPMsg driver to the channel**: 
    The kernel RPMsg driver binds the appropriate channel to a device file like `/dev/rpmsg0`. 

### Example of a User-Space Application

Here is a simplified example of a user-space application that interacts with an RPMsg device:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#define RPMSG_DEVICE "/dev/rpmsg0"  // Path to the RPMsg device

int main() {
    int fd = open(RPMSG_DEVICE, O_RDWR);
    if (fd < 0) {
        perror("Failed to open RPMsg device");
        return -1;
    }

    // Sending a message to the remote processor
    const char *msg = "Hello from userspace";
    ssize_t bytes_written = write(fd, msg, strlen(msg));
    if (bytes_written < 0) {
        perror("Failed to write to RPMsg device");
        close(fd);
        return -1;
    }

    printf("Message sent to RPMsg device\n");

    // Reading a message from the RPMsg device
    char buffer[256];
    ssize_t bytes_read = read(fd, buffer, sizeof(buffer));
    if (bytes_read < 0) {
        perror("Failed to read from RPMsg device");
        close(fd);
        return -1;
    }

    buffer[bytes_read] = '\0';  // Null-terminate the message
    printf("Received message: %s\n", buffer);

    // Close the RPMsg device
    close(fd);

    return 0;
}
```
### Key Concepts in RPMsg:

- **RPMsg channels**: 
    Communication between processors is done over channels, which are represented by files in `/dev/rpmsgX`.

- **RPMsg device files**: 
    The kernel exposes RPMsg channels as character devices (`/dev/rpmsgX`), which user-space applications 
    can open and use.

- **Transport**: RPMsg typically uses shared memory or other transport mechanisms to send messages between 
    the processors. The transport layer is platform-specific and configured in the kernel.

### Summary:

- User-space applications can send and receive RPMsg packets by interacting with the kernel RPMsg driver 
  via file operations on `/dev/rpmsgX` devices.

- The kernel must be configured with RPMsg support, and the user-space application uses standard file 
  I/O (`open()`, `write()`, `read()`, and `close()`) to send and receive messages.


## 3. Additional points:
  ---

RPMsg, being designed for efficient communication between processors (such as an ARM-based Linux kernel 
and a remote processor like a DSP or a co-processor), typically has some constraints on the size of the 
payload, but it does not handle packet fragmentation in the same way that regular network protocols like 
TCP/IP do. 

Here's a breakdown of the key details:

### 1. **Limitations on RPMsg Payload Size**
   - **Memory Constraints**: 
   The size of the RPMsg payload is constrained by the amount of available shared mem between the processors. 
   The communication takes place via shared memory regions, and the size of the payload you can send is 
   typically determined by the size of the region allocated for RPMsg communication.

   - **Protocol Overhead**: 
   Each RPMsg frame has a header that contains metadata such as source, destination, message ID, and 
   channel information. Payload size must fit within the available memory after accounting for this header.
   - **Device-Specific Limits**: 
   Some platforms or devices may impose further limits based on hardware and kernel configurations. 
   The shared memory area could be limited in size, and that would restrict the max size of each message.
   
   **In practice**, the payload size for a typical RPMsg message is likely to be in the range of a few kilobytes, depending on the platform, memory configuration, and any kernel-imposed limits.

### 2. **No Automatic Fragmentation Handling**
   Unlike network IP or TCP, **RPMsg does not provide automatic fragmentation and reassembly of large msgs**. 

   This means that:
   - If you need to send a message that exceeds the maximum frame size, the application or driver is 
     responsible for breaking the message into smaller chunks.
   - **Manual Segmentation**: The user-space application or the kernel-side RPMsg driver must manually 
     handle the fragmentation and reassembly of large messages into multiple smaller RPMsg frames. 
     This is typically done at a higher level in the application.
   
   Here's what that typically involves:
   - **Splitting Large Messages**: 
   When sending a large message, the sender needs to break the message into smaller, manageable chunks that 
   fit into the RPMsg frame size limit.
   - **Sending Chunks**: Each chunk is sent as a separate RPMsg frame.
   - **Reassembling the Message**: 
   The receiver must track the fragments and reassemble them into the original message. 
   This requires some protocol or coordination between the sender and receiver, such as keeping track of 
   fragment order and ensuring all fragments are received.
   
### 3. **Shared Memory Management and Buffer Allocation**

   - The shared memory used for RPMsg communication is usually allocated and mapped by the kernel, and the 
   remote processor also has access to it. 
   The memory region is often partitioned into small blocks or buffers, with each RPMsg frame using one of 
   these buffers.

   - **Buffer Size**: The size of each buffer is typically configurable, and it determines the maximum 
   payload size for an individual RPMsg message. 
   If you want to send larger payloads, you'd need to either increase the buffer size or handle 
   fragmentation at a higher level.

### 4. **No Built-in Retransmission or Error Recovery**
   - RPMsg is a lightweight communication protocol that operates at the frame level. 
   It **does not have built-in error recovery or retransmission** mechanisms, like TCP does. 
   Therefore, if a message is lost, the higher-level application needs to handle retransmissions or ensure 
   reliability in some other way.

### Summary:

- **Payload Size Limit**: The maximum size of the RPMsg payload is typically constrained by the 
    shared memory available and the frame size. It depends on the platform and the configuration.
- **No Automatic Fragmentation**: RPMsg does not handle automatic fragmentation and reassembly. 
    Large msgs need to be manually segmented into smaller frames by the sender, 
    and the receiver must handle reassembly.
- **No Error Recovery**: 
    RPMsg does not include built-in error recovery or retransmission mechanisms, so applications using 
    RPMsg must handle these aspects if needed.

In essence, RPMsg is designed for lightweight, efficient communication, but when dealing with larger 
messages, the application or kernel driver must take care of breaking down messages and reassembling them.
