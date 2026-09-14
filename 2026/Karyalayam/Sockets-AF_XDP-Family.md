#  Network Sockets: From Computer Networks to Application Communication

- Explain why computer networks were developed.
- Describe the historical development that led to network sockets.
- Explain the roles of IP addresses, ports, TCP, and UDP.
- Define a network socket.
- Describe how a client and server communicate using sockets.
- Explain the basic lifecycle of a TCP socket.
- Distinguish between TCP and UDP sockets.

--- 

## 1. The Problem: How Can Programs Communicate?

Early computers were mostly independent machines.

A program running on one computer could communicate with other programs on the same computer using
mechanisms such as:

- Files
- Pipes
- Shared memory
- Device interfaces

Extending the idea what should be used of a program running on Computer A communicate with a program 
running on Computer B?

For example:

```
    Computer A                         Computer B
    +-------------+                   +-------------+
    | Application |                   | Application |
    +-------------+                   +-------------+
           |                                  |
           |          Network                 |
           +----------------------------------+
```

This created the need for computer networks.

## 2. The Development of Computer Networks

### 2.1 Packet Switching

One important development was packet switching.

Instead of sending an entire message as one continuous stream, data could be divided into smaller pieces called packets.

For example:

```
    Original message:
    HELLO WORLD

            ↓

    Packets:

    +-------+-------+-------+
    | HELLO | WORLD |  ...  |
    +-------+-------+-------+
```

These packets could travel through a network and be reassembled at the destination.
Packet switching became an important foundation for modern computer networking.

## 3. ARPANET

In late 1960s, researchers developed ARPANET, one of the important predecessors of today's Internet.

ARPANET began operation in 1969. with a purpose to included connecting geographically separated computers 
and allowing them to communicate over a packet-switched network.

Conceptually:


```
    Computer A
         |
         |
       Network
      /       \
    Computer B Computer C

```

This solved an important problem:
Computers can communicate with other computers over a network.
But another problem remained:
How should different networks communicate with each other?

## 4. TCP/IP

During the 1970s, researchers developed the protocols that became TCP/IP.

TCP/IP provided a standardized way for computers and networks to communicate.

The basic idea can be represented as:

```
    Application
         ↓
      TCP/UDP
         ↓
        I P
         ↓
    Network Technology
```

Each layer has a different responsibility.

**IP **: is primarily concerned with:

- Where should this packet go?
    An IP address identifies a network endpoint.
    For example:
    `192.168.1.10`

## 5. A New Problem: Which Application?

Suppose one computer has the IP address: `192.168.1.10`

But that computer is running many applications:

```
    192.168.1.10
          |
          +---- Web server
          |
          +---- SSH server
          |
          +---- Database
          |
          +---- Game server
```

The IP address tells us which machine, but not necessarily which application should receive the data.
This led to the concept of ports.

## 6. Ports

A port identifies a communication endpoint associated with an application or service.

For example:

```
192.168.1.10:22
192.168.1.10:80
192.168.1.10:443
```

Think of it this way:


```
    IP address
        ↓
    Which machine?
        Port
        ↓
    Which service/application endpoint?

```


A useful analogy is:


```
IP address = building address
Port       = room number

```


So:

`192.168.1.10:80`


can be understood approximately as:

"Go to port 80 on the machine with IP address 192.168.1.10."

## 7. TCP: Reliable Communication

IP provides packet delivery between network endpoints, but applications often need more than that.

Packets can potentially:  Get lost, Arrive out of order, Be duplicated

TCP provides a reliable, ordered byte stream to applications.

Conceptually:

```
    Application
         |
         | reliable byte stream
         ↓
        TCP
         ↓
         IP
         ↓
       Network
```

Instead of the application handling packet loss and ordering itself, TCP handles these problems.

The application can think in terms of:

    `send("Hello")`

Rather than manually managing individual network packets.

## 8. The Need for an Application Interface

At this point, we have:

```
Application
     ↓
    TCP
     ↓
     IP
     ↓
   Network
```

```

But how does a program actually tell the operating system:

"I want to communicate with another computer using TCP"?
The operating system provides a programming interface for networking.
This is where sockets come in.

## 9. What Is a Socket?

A network **socket** is a programming interface/end point that an application uses to communicate through the
operating system's networking stack.

A simplified view is:

```
    Application
         |
         | Socket API
         ↓
    Operating System
         |
         | TCP / UDP
         ↓
         IP
         ↓
    Network
```

The application does not normally need to directly manipulate Ethernet frames, Wi-Fi signals, or IP packet
headers.

Instead, it interacts with a socket.

For example:

```
    Application
        |
        | send()
        ↓
     Socket
        |
        ↓
     TCP
        |
        ↓
     IP
        |
        ↓
     Network
```


The socket provides the application with a convenient abstraction for network communication.

## 10. Why Are Sockets Called "Sockets"?

The idea of sockets became particularly influential through the Berkeley sockets API, developed for Unix
systems at the University of California, Berkeley in the early 1980s.

Unix already used file descriptors to represent resources such as files.

Sockets could fit naturally into this model.

For example:

```
    File descriptor 3 → File
    File descriptor 4 → Socket
    File descriptor 5 → Socket
```

This allowed programs to use familiar operations for reading and writing data.

The idea was powerful:

A network connection could be treated by the application as a communication endpoint that could be read from
and written to.

## 11. The Client-Server Model

Sockets are commonly used in a client-server architecture.

For example:

```
Client                              Server

Browser                             Web Server
   |                                    |
   |       Socket connection            |
   +------------------------------------+

```

The client initiates communication.

The server waits for clients and responds to them.

## 12. TCP Server Socket Lifecycle

A typical TCP server follows this sequence:

```
    socket()
       ↓
    bind()
       ↓
    listen()
       ↓
    accept()
       ↓
    send() / recv()
       ↓
    close()

```

Let's examine each step.

### 12.1 socket()

The server asks the operating system to create a socket.

```
    socket()
       ↓
    [ Socket ]

```

### 12.2 bind()

The server associates the socket with a local address and port.

For example:

    192.168.1.10:8080

### 12.3 listen()

The server tells the operating system:

"I am waiting for incoming TCP connections."

### 12.4 accept()

A client attempts to connect.

The server accepts the connection.

The server can then communicate with that client.

Multiple clients can connect:

``` 
                    Server
                      |
                Listening socket
                      |
          +-----------+-----------+
          |           |           |
       Client A    Client B    Client C
```

### 12.5 send() / recv()

The client and server exchange data.

For example:
```
Client                         Server

send("Hello")  ------------>

               <------------ send("Hi")
```

### 12.6 close()

When communication is finished, the socket is closed.

```
    send/receive
        ↓
      close()

## 13. TCP Client Socket Lifecycle

A TCP client typically follows:

```
    socket()
       ↓
    connect()
       ↓
  send() / recv()
       ↓
    close()

```

For example:

```
Client                         Server

socket()
   |
   | connect()
   +-------------------------->
   |
   |     TCP connection
   |<-------------------------->
   |
   | send("Hello")
   +-------------------------->
   |
   |<--------------------------+
   |      response
```

## 14. TCP Connection: The Four-Tuple

A TCP connection is commonly identified by four values:

- Source IP
- Source Port
- Destination IP
- Destination Port


For example:
```
192.168.1.5:53124
       |
       |
       ↓
142.250.10.20:443
```

The four values are:
```
Source IP:        192.168.1.5
Source Port:      53124

Destination IP:   142.250.10.20
Destination Port: 443

This allows one computer to have many simultaneous connections to the same server.

For example:

192.168.1.5:53124 → 142.250.10.20:443
192.168.1.5:53125 → 142.250.10.20:443
192.168.1.5:53126 → 142.250.10.20:443


The destination is the same, but the source ports are different.

## 15. TCP vs UDP

Sockets can be used with different transport protocols.

The two important examples are TCP and UDP.


|Feature | TCP | UDP |
| :--- | :--- | :--- |
|Connection-oriented | Yes | No|
|Reliable delivery	| Yes | No guarantee |
|Ordered data	| Yes	|No guarantee |
|Data model | Byte stream	| Datagram/message |
|Typical use |Web, SSH, file transfer	| DNS, real-time applications, games|
|Overhead	| Higher | Lower |

Conceptually:



```
                 Socket API
                     |
            +--------+--------+
            |                 |
           TCP               UDP
            |                 |
     Reliable stream      Datagrams
```

## 16. TCP Socket vs UDP Socket

**TCP** : A TCP socket provides a connection-oriented communication mechanism.

Client                         Server

connect()
   |
   +---------------------------->
   |
   |<==========================>|
   |       TCP connection       |
   |
send()/recv()

**UDP** :

A UDP socket sends individual datagrams.

```
Client                         Server

sendto("Hello")  ------------>
sendto("World")  ------------>

```
There is no TCP-style connection establishment.

## 17. Example: A Web Browser

When you open a website, many layers work together.

Suppose a browser wants to communicate with a web server.

Conceptually:

```
    Web Browser
         |
         | Socket API
         ↓
        TCP
         |
         ↓
         IP
         |
         ↓
     Wi-Fi / Ethernet
         |
         ↓
     Internet
         |
         ↓
    Web Server
```

The browser can think about:

"Send this request."


The operating system and networking stack handle much of the complexity underneath.

## 18. The Historical Story in One Diagram

The development can be understood as a sequence of problems and solutions:

```
Problem:
Computers need to communicate
          ↓
Solution:
Computer networks
          ↓
Problem:
How should data travel efficiently?
          ↓
Solution:
Packet switching
          ↓
Problem:
How can different networks communicate?
          ↓
Solution:
TCP/IP
          ↓
Problem:
How do we identify the destination machine?
          ↓
Solution:
IP addresses
          ↓
Problem:
How do we identify the application?
          ↓
Solution:
Ports
          ↓
Problem:
How does an application use the network?
          ↓
Solution:
Socket API
          ↓
Modern network applications
```

## 19. Historical Timeline
Period	Development	Importance
1960s	Packet-switching research	Efficient computer communication
1969	ARPANET begins operation	Important early computer network
1970s	TCP/IP development	Internetworking
1980s	Berkeley sockets	Application programming interface for networking
1983	ARPANET adopts TCP/IP	Major milestone toward the modern Internet
1990s onward	Web and Internet expansion	Sockets become fundamental to network applications
20. Putting Everything Together

The complete picture looks like this:

```
+-----------------------------------+
|          Application              |
|       Browser / Game / Chat       |
+-----------------------------------+
                 |
                 | Socket API
                 ↓
+-----------------------------------+
|        Operating System           |
|                                   |
|          TCP / UDP                |
+-----------------------------------+
                 |
                 ↓
+-----------------------------------+
|                IP                 |
+-----------------------------------+
                 |
                 ↓
+-----------------------------------+
|       Ethernet / Wi-Fi            |
+-----------------------------------+
                 |
                 ↓
              Network
                 |
                 ↓
              Internet
                 |
                 ↓
        Remote Computer

```

The key relationships are:

- IP address → identifies the network destination
- Port       → identifies a service/endpoint
- TCP/UDP    → provides transport communication
- Socket     → provides the application's interface
               to network communication

## 21. A Simple Mental Model

Remember these four ideas:

IP
Where?
    192.168.1.10

Port
Which service/endpoint?
    :443

TCP/UDP
    How should data be transported?

    TCP → reliable stream
    UDP → datagrams

----

Socket
How does my program communicate using the network?
```
Application
     ↓
  Socket
     ↓
 TCP/UDP
```


## summing up:

- Computer networks were developed so computers could communicate.
- Packet switching allowed information to be divided into packets and transported through networks.
- ARPANET was an important early packet-switched network and a predecessor of today's Internet.
- TCP/IP provided protocols for communication across interconnected networks.
- IP addresses identify network destinations.


Ports help identify communication endpoints associated with applications or services.

TCP provides reliable, ordered byte-stream communication.

UDP provides connectionless datagram communication without TCP's reliability guarantees.

Sockets provide applications with an interface for network communication.

The socket abstraction allowed programmers to communicate over networks without needing to directly manage
the underlying networking hardware and protocols.

--- 

## Socket Demo:

Example server listens on port 5000 and client connects and exhanges a few messages and then closes the 
connection 

```
./socket_demo server
./socket_demo client 127.0.0.1
```

```c
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 5000
#define BUFFER_SIZE 1024

void run_server(void)
{
    int server_fd;
    int client_fd;

    struct sockaddr_in server_addr;
    struct sockaddr_in client_addr;

    socklen_t client_len = sizeof(client_addr);

    char buffer[BUFFER_SIZE];

    /*
     * 1. Create a socket
     *
     * AF_INET     = IPv4
     * SOCK_STREAM = TCP
     */
    server_fd = socket(AF_INET, SOCK_STREAM, 0);

    if (server_fd < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    /*
     * Allow the port to be reused after the program exits.
     */
    int opt = 1;

    setsockopt(
        server_fd,
        SOL_SOCKET,
        SO_REUSEADDR,
        &opt,
        sizeof(opt)
    );

    /*
     * 2. Configure the server address.
     */
    memset(&server_addr, 0, sizeof(server_addr));

    server_addr.sin_family = AF_INET;

    /*
     * Listen on all local IPv4 interfaces.
     */
    server_addr.sin_addr.s_addr = INADDR_ANY;

    /*
     * Convert port number to network byte order.
     */
    server_addr.sin_port = htons(PORT);

    /*
     * 3. Bind socket to IP address + port.
     */
    if (bind(
        server_fd,
        (struct sockaddr *)&server_addr,
        sizeof(server_addr)
    ) < 0) {
        perror("bind");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    /*
     * 4. Put socket into listening mode.
     */
    if (listen(server_fd, 5) < 0) {
        perror("listen");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    printf("Server listening on port %d...\n", PORT);

    /*
     * 5. Wait for a client.
     */
    client_fd = accept(
        server_fd,
        (struct sockaddr *)&client_addr,
        &client_len
    );

    if (client_fd < 0) {
        perror("accept");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    printf("Client connected!\n");

    /*
     * 6. Receive data from the client.
     */
    ssize_t bytes_received =
        recv(client_fd, buffer, BUFFER_SIZE - 1, 0);

    if (bytes_received > 0) {
        buffer[bytes_received] = '\0';

        printf("Client says: %s\n", buffer);
    }

    /*
     * 7. Send response to client.
     */
    const char *message = "Hello from C server!";

    send(
        client_fd,
        message,
        strlen(message),
        0
    );

    /*
     * 8. Close the connection.
     */
    close(client_fd);
    close(server_fd);

    printf("Connection closed.\n");
}

void run_client(const char *server_ip)
{
    int sock_fd;

    struct sockaddr_in server_addr;

    char buffer[BUFFER_SIZE];

    /*
     * 1. Create TCP socket.
     */
    sock_fd = socket(AF_INET, SOCK_STREAM, 0);

    if (sock_fd < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    /*
     * 2. Configure server address.
     */
    memset(&server_addr, 0, sizeof(server_addr));

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);

    /*
     * Convert text IP address into binary form.
     */
    if (inet_pton(
        AF_INET,
        server_ip,
        &server_addr.sin_addr
    ) <= 0) {
        perror("inet_pton");
        close(sock_fd);
        exit(EXIT_FAILURE);
    }

    /*
     * 3. Connect to server.
     */
    if (connect(
        sock_fd,
        (struct sockaddr *)&server_addr,
        sizeof(server_addr)
    ) < 0) {
        perror("connect");
        close(sock_fd);
        exit(EXIT_FAILURE);
    }

    printf("Connected to server!\n");

    /*
     * 4. Send message.
     */
    const char *message = "Hello from C client!";

    send(
        sock_fd,
        message,
        strlen(message),
        0
    );

    /*
     * 5. Receive response.
     */
    ssize_t bytes_received =
        recv(sock_fd, buffer, BUFFER_SIZE - 1, 0);

    if (bytes_received > 0) {
        buffer[bytes_received] = '\0';

        printf("Server says: %s\n", buffer);
    }

    /*
     * 6. Close socket.
     */
    close(sock_fd);

    printf("Connection closed.\n");
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage:\n");
        printf("  %s server\n", argv[0]);
        printf("  %s client <server-ip>\n", argv[0]);
        return EXIT_FAILURE;
    }

    if (strcmp(argv[1], "server") == 0) {

        run_server();

    } else if (strcmp(argv[1], "client") == 0) {

        if (argc < 3) {
            printf("Please provide server IP address.\n");
            return EXIT_FAILURE;
        }

        run_client(argv[2]);

    } else {

        printf("Unknown mode: %s\n", argv[1]);
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
```
Important C functions:
- socket() : Create a socket
- bind()   : Assign local address/port
- listen() : Wait for connections
- accept() : Accept a client
- connect(): Connect to a server
- send()   : Send bytes
- recv()   : Receive bytes
- close()  : Close socket

Sequence to Remember:
```text 

    SERVER               CLIENT        
    -------              ------              
    socket()             socket()      
       ↓                    ↓          
    bind()               connect()     
       ↓                    ↓          
    listen()             send()/recv() 
       ↓                    ↓          
    accept()             close()       
       ↓
    send()/recv()
       ↓
    close()
```

--- 

Python version:

```py 

import socket
import sys

HOST = "0.0.0.0"
PORT = 5000


def run_server():
    # 1. Create a TCP socket.
    server_socket = socket.socket(
        socket.AF_INET,
        socket.SOCK_STREAM
    )

    # Allow reuse of the port.
    server_socket.setsockopt(
        socket.SOL_SOCKET,
        socket.SO_REUSEADDR,
        1
    )

    # 2. Bind socket to local address and port.
    server_socket.bind((HOST, PORT))

    # 3. Start listening.
    server_socket.listen(5)

    print(f"Server listening on port {PORT}...")

    # 4. Accept a client connection.
    client_socket, client_address = server_socket.accept()

    print(f"Client connected from {client_address}")

    # 5. Receive data.
    data = client_socket.recv(1024)

    print("Client says:", data.decode())

    # 6. Send response.
    message = "Hello from Python server!"

    client_socket.sendall(
        message.encode()
    )

    # 7. Close connection.
    client_socket.close()
    server_socket.close()

    print("Connection closed.")


def run_client(server_ip):
    # 1. Create a TCP socket.
    client_socket = socket.socket(
        socket.AF_INET,
        socket.SOCK_STREAM
    )

    # 2. Connect to server.
    client_socket.connect(
        (server_ip, PORT)
    )

    print("Connected to server!")

    # 3. Send message.
    message = "Hello from Python client!"

    client_socket.sendall(
        message.encode()
    )

    # 4. Receive response.
    data = client_socket.recv(1024)

    print("Server says:", data.decode())

    # 5. Close socket.
    client_socket.close()

    print("Connection closed.")


def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 socket_demo.py server")
        print("  python3 socket_demo.py client <server-ip>")
        return

    mode = sys.argv[1]

    if mode == "server":
        run_server()

    elif mode == "client":

        if len(sys.argv) < 3:
            print("Please provide server IP address.")
            return

        server_ip = sys.argv[2]

        run_client(server_ip)

    else:
        print("Unknown mode:", mode)


if __name__ == "__main__":
    main()
```
- $python3 socket_demo.py server
- $python3 socket_demo.py client 127.0.0.1

The Python code maps almost directly to the conceptual model:
```
Server:         client:
-------         ------- 
socket()        socket() 
  ↓               ↓ 
bind()          connect()
   ↓
listen()
   ↓
accept()
```
- In python socket.AF_INET  = means IPv4 
  socket.SOCK_STREAM = means tcp-ip based stream.

=> socket.socket( socket.AF_INET, socket.SOCK_STREAM )  means create an IPv4 TCP socket.

--- 

Rust version:
-------------
For Rust we can use standard library and no external networking framework is required for basic TCP communication:

```rust 

use std::env;
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};

const PORT: u16 = 5000;


fn run_server() -> std::io::Result<()> {

    // 1. Bind a TCP listener to port 5000.
    let listener = TcpListener::bind(
        ("0.0.0.0", PORT)
    )?;

    println!(
        "Server listening on port {}...",
        PORT
    );

    // 2. Accept a client connection.
    let (mut stream, address) =
        listener.accept()?;

    println!(
        "Client connected from {}",
        address
    );

    // 3. Receive data.
    let mut buffer = [0u8; 1024];

    let bytes_read =
        stream.read(&mut buffer)?;

    let message =
        String::from_utf8_lossy(
            &buffer[..bytes_read]
        );

    println!(
        "Client says: {}",
        message
    );

    // 4. Send response.
    let response =
        "Hello from Rust server!";

    stream.write_all(
        response.as_bytes()
    )?;

    // 5. Connection closes when stream goes
    //    out of scope.

    println!("Connection closed.");

    Ok(())
}


fn run_client(server_ip: &str) -> std::io::Result<()> {

    // 1. Connect to the server.
    let address =
        format!("{}:{}", server_ip, PORT);

    let mut stream =
        TcpStream::connect(&address)?;

    println!(
        "Connected to server!"
    );

    // 2. Send message.
    let message =
        "Hello from Rust client!";

    stream.write_all(
        message.as_bytes()
    )?;

    // 3. Receive response.
    let mut buffer = [0u8; 1024];

    let bytes_read =
        stream.read(&mut buffer)?;

    let response =
        String::from_utf8_lossy(
            &buffer[..bytes_read]
        );

    println!(
        "Server says: {}",
        response
    );

    // 4. Stream closes when it goes
    //    out of scope.

    println!("Connection closed.");

    Ok(())
}


fn main() -> std::io::Result<()> {

    let args: Vec<String> =
        env::args().collect();

    if args.len() < 2 {
        println!("Usage:");
        println!("  cargo run -- server");
        println!(
            "  cargo run -- client <server-ip>"
        );

        return Ok(());
    }

    match args[1].as_str() {

        "server" => {
            run_server()?;
        }

        "client" => {

            if args.len() < 3 {
                println!(
                    "Please provide server IP address."
                );

                return Ok(());
            }

            run_client(&args[2])?;
        }

        _ => {
            println!(
                "Unknown mode: {}",
                args[1]
            );
        }
    }

    Ok(())
}
```
The Rust standard library provides:

- `TcpListener` : for server 
  Conceptually:

  `TcpListener -> bind() -> listen () -> accept() `

  And 
  `TcpStream` represents the established TCp connection. 

  Client uses :
  `TcpStream::connect(...)` Communication happens through:

  `streame.write_all(..)`
  `stream.read(..)`

The ownership system helps to manage the lifetime of the connection. 
When the stream goes out of scope its resources are cleaned up automatically. 


|Concept | C | Python | Rust |
| :--- | :--- | :--- | :--- |
| Create socket | socket() | socket.socket() | TcpStream/TcpListener |
| Server address | sockaddr_in | (host, port) | ("host", port) |
| Bind | bind() | bind() | TcpListener::bind() |
| Listen |	listen() | listen() | Built into TcpListener |
| Accept |	accept() | accept() | listener.accept() |
| Client  connect	| connect()	| connect() |	TcpStream::connect() |
| Send | send() | sendall() | write_all() |
| Receive | recv() | recv() | read() |
| Close | close() | close() | Automatic via ownership |


---

# Network Sockets — Part 2

## Understanding Address Families

Continuation of: Network Sockets — From Computer Networks to Application Communication

In  above socket: It provides an interface through which an application can communicate using the OS 
                   networking stack.

We saw code such as:
`socket(AF_INET, SOCK_STREAM, 0);`

This section explains an important question:

What exactly is AF_INET?

And more generally:

What is an address family?

### 1. A Quick Review: What Is a Socket?

A socket is a programming interface and communication endpoint that an application uses to communicate through the operating system's networking subsystem.

Conceptually:
```
+---------------------------+
|       Application         |
|   Browser / Server / App  |
+-------------+-------------+
              |
              | Socket API
              ↓
+---------------------------+
|      Operating System     |
|                           |
|       TCP / UDP           |
|          IP               |
+-------------+-------------+
              |
              ↓
           Network
```

The socket API allows an application to request communication services without directly dealing with the physical network hardware.

### 2. Creating a Socket

In C, a socket is commonly created using:

`socket(domain, type, protocol);`


For example:

`socket(AF_INET, SOCK_STREAM, 0);`


There are three important pieces:
```
             socket()
                │
       ┌────────┼────────┐
       ↓        ↓        ↓
     domain    type    protocol
       │        │        │
       ↓        ↓        ↓
   AF_INET  SOCK_STREAM   0
```

These answer three different questions.

Domain / Address Family

What communication/addressing domain should this socket belong to?

Example:
```
    AF_INET → IPv4
```

Socket Type

What style of communication should the socket provide?

Example:
```
SOCK_STREAM → stream communication
SOCK_DGRAM  → datagram communication
```
Protocol

Which specific protocol should be used?

For example:
```
TCP
UDP
```

When protocol is 0, the operating system normally selects the appropriate default protocol for the selected
family and socket type.

### 3. What Is an Address Family?

An address family identifies the communication or addressing domain in which a socket operates.

A common beginner definition is:

"An address family tells the operating system what kind of network address a socket uses."

That is useful initially, but it is incomplete.

A better definition is:

An address family (AF_*) identifies the communication/addressing namespace that a socket belongs to and
tells the operating system how addresses and communication for that socket are handled.

This is why address families are not limited to IPv4 and IPv6.

### 4. Why Do We Need Address Families?

Consider these two addresses:

- IPv4:
    192.168.1.10

and 

- IPv6:
    2001:db8::1

They are both Internet addresses, but they use different addressing systems.
The operating system needs to know which system it is dealing with.

Therefore:

```
AF_INET
   ↓
IPv4 addressing
```

and:
```
AF_INET6
   ↓
IPv6 addressing
```

The address family acts somewhat like a type for the communication endpoint.

### 5. AF_INET — IPv4

The most common address family encountered by beginners is:

`AF_INET`

It means:

`Address Family — Internet Protocol version 4`

For example:

`socket(AF_INET, SOCK_STREAM, 0);`


means approximately:

Create a socket in the IPv4 addressing domain using stream communication.

An IPv4 address looks like:

192.168.1.10


In C, an IPv4 socket address is commonly represented by:

`struct sockaddr_in`


The relationship is:

```
AF_INET
   ↓
IPv4
   ↓
struct sockaddr_in
```

### 6. AF_INET6 — IPv6

For IPv6, we use:

```
AF_INET6

```

For example:

`socket(AF_INET6, SOCK_STREAM, 0);`

This means:

Create a stream socket using the IPv6 addressing domain.

An IPv6 address might look like:

`2001:db8::1`

The corresponding C structure is:

`struct sockaddr_in6`


The relationship is:
```
AF_INET6
    ↓
  IPv6
    ↓
struct sockaddr_in6
```

### 7. AF_INET vs AF_INET6
	
| | AF_INET	| AF_INET6|
| :--- | :--- | :--- |
| Address system | IPv4 | IPv6 |
| Address size 32 |  bits	| 128 bits |
| Example |	192.168.1.10 | 2001:db8::1 |
| C structure |	sockaddr_in | sockaddr_in6 |
| Typical use | Internet networking	 | Internet networking |

Remember:
```
AF_INET  → IPv4
AF_INET6 → IPv6
```

Do not think:
```
AF_INET  → TCP
AF_INET6 → UDP
```

That is incorrect.

The address family and transport protocol are separate concepts.

### 8. Address Family Is NOT the Same as Protocol

Consider:

`socket(AF_INET, SOCK_STREAM, 0);`

There are three separate concepts.

```
AF_INET
   ↓
IPv4 addressing

SOCK_STREAM
   ↓
Stream communication

0
   ↓
Choose appropriate default protocol
   ↓
TCP
```

So the complete interpretation is:

Create an IPv4 socket providing stream communication, with the operating system selecting the default
protocol normally TCP.

### 9. A Better Mental Model

When students see:

`socket(AF_INET, SOCK_STREAM, 0);`


They should mentally expand it to:

```
                   socket()
                      │
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
  Address Family   Socket Type    Protocol
        │             │             │
        ↓             ↓             ↓
    AF_INET      SOCK_STREAM        TCP
        │
        ↓
      IPv4

```

The three components answer:

- Address Family → Which communication/addressing domain?
- Socket Type    → What communication style?
- Protocol       → Which transport/network protocol?

### 10. What Is a Socket Address?

Once the socket has been created, we need to specify an actual endpoint.

For an IPv4 TCP server, an endpoint might be:

`192.168.1.10:5000`

This contains:
```
192.168.1.10
       ↓
IPv4 address

5000
       ↓
Port
```

The address family tells us how to interpret the address:

```
AF_INET
   ↓
192.168.1.10
   ↓
IPv4 address
```

The port identifies the transport endpoint:
```
5000
   ↓
Port
```

Together:

`192.168.1.10:5000`


represent a network endpoint.

### 11. How This Appears in C

For IPv4, we commonly use:

struct sockaddr_in server_addr;


A simplified view is:

struct sockaddr_in
+----------------------------+
| Address Family             |
| AF_INET                    |
+----------------------------+
| IPv4 Address               |
| 192.168.1.10               |
+----------------------------+
| Port                       |
| 5000                       |
+----------------------------+


For example:
```

struct sockaddr_in server_addr;

server_addr.sin_family = AF_INET;
server_addr.sin_port = htons(5000);
```

The family says:
```
sin_family = AF_INET
                  ↓
             "This is IPv4"
```

### 12. Why Does sockaddr_in Contain the Family?

The operating system needs to know how to interpret the address structure.

Conceptually:
```
sockaddr_in
+-----------------------+
| sin_family = AF_INET  |
+-----------------------+
| IPv4 address          |
+-----------------------+
| Port                  |
+-----------------------+
```

For IPv6:
```
sockaddr_in6
+-------------------------+
| sin6_family = AF_INET6 |
+-------------------------+
| IPv6 address            |
+-------------------------+
| Port                    |
+-------------------------+
```

Therefore:
```
AF_INET
    ↓
sockaddr_in
    ↓
IPv4 address information
```

and:
```
AF_INET6
    ↓
sockaddr_in6
    ↓
IPv6 address information
```

### 13. Address Families Are Broader Than Internet Addresses

At this point, it is tempting to think:

```
Address Family
      ↓
   IP version
```

But this is too narrow.

There are many other address families.

For example:
```
Address Families
       │
       ├── AF_INET
       │      └── IPv4
       │
       ├── AF_INET6
       │      └── IPv6
       │
       ├── AF_UNIX
       │      └── Local process communication
       │
       ├── AF_PACKET
       │      └── Link-layer packet access
       │
       ├── AF_XDP
       │      └── High-performance XDP packet processing
       │
       └── Other specialized families
```

The exact families available depend on the operating system.

Linux provides many families that may not exist on other operating systems.

### 14. AF_UNIX — Local Communication

`AF_UNIX`, also commonly called `AF_LOCAL`, is used for communication between processes on the same machine.

For example:

`socket(AF_UNIX, SOCK_STREAM, 0);`


No IP address is required.

Conceptually:
```
Process A
    │
    │
    │ Unix socket
    ↓
 Operating System
    ↑
    │ Unix socket
    │
Process B
```
This is called inter-process communication (IPC).

It demonstrates an important idea:

A socket does not necessarily mean Internet communication.

Sockets can provide different types of communication depending on the address family.

### 15. AF_PACKET — Link-Layer Packet Access

Linux also provides:

`AF_PACKET`

This allows applications to work with packets at the link layer.

For example, an Ethernet frame can contain:
```
+----------+----------+----------+
| Ethernet |   IP     |   TCP    |
| Header   | Packet   | Segment  |
+----------+----------+----------+
```

With ordinary TCP application programming, an application normally sees a byte stream:

```
Application
     ↓
TCP socket
     ↓
TCP
     ↓
IP
     ↓
Ethernet
```

With AF_PACKET, an application can work much closer to the Ethernet/link layer:
```
Application
     ↓
AF_PACKET
     ↓
Ethernet frames
```

This is useful for packet capture, network analysis, and specialized networking programs.

### 16. AF_XDP — High-Performance Packet Processing

Linux also provides:

`AF_XDP`

This is associated with XDP — eXpress Data Path.

`AF_XDP` is designed for applications that need very high-performance packet processing.

A traditional path might look approximately like:

```
Network Card
     ↓
Driver
     ↓
Linux Networking Stack
     ↓
TCP / UDP
     ↓
Socket
     ↓
Application
```

With XDP/AF_XDP, packets can be processed much closer to the network driver:

```
Network Card
     ↓
Driver
     ↓
XDP
     ↓
AF_XDP
     ↓
Application
```
This is useful in specialized applications such as:

- High-performance packet processing
- Network monitoring
- Packet filtering
- DDoS mitigation
- Load balancing
- Network appliances

Important

`AF_XDP` should not be thought of simply as:

"another version of AF_INET."

Instead:
```
AF_INET
   ↓
IPv4 Internet networking
```
whereas:
```
AF_XDP
   ↓
XDP packet-processing interface
```

AF_XDP is particularly important when teaching Linux high-performance networking.

### 17. AF_PACKET vs AF_XDP

These two are worth comparing.

| | AF_PACKET | AF_XDP |
| :---  | :---  | :--- |
| Platform | Linux | Linux |
| Main purpose | Link-layer packet access | High-performance XDP packet processing |
| Typical data | Packets / frames | XDP packets |
| Abstraction level | Link layer | XDP/driver-adjacent |
| Typical applications | Packet capture, network tools | High-performance packet processing |
| TCP stream | No | No |
| UDP stream | No | No |


Both are very different from a normal TCP socket:

`socket(AF_INET, SOCK_STREAM, 0);`

### 18. AF_NETLINK — Kernel Communication

Linux also provides:

`AF_NETLINK`

Netlink sockets are commonly used for communication between userspace and the Linux kernel.

Conceptually:
```
Userspace Application
         │
         │ Netlink
         ↓
       Kernel
```

They are heavily used for networking configuration and state.

For example, Linux networking tools can use Netlink to work with:

- Network interfaces
- IP addresses
- Routing


---- 

# AF_XDP : 

The mental model is substantially different from the TCP socket example. 
You need to understand **XDP → UMEM → rings → XSKMAP → NIC queues** before looking at code.

Also checked the current Linux kernel documentation so the terminology and architecture below match the 
current AF_XDP interface.  [+1]

## AF_XDP: High-Performance Packet Processing with Linux Sockets

### Learning Objectives

After this lesson, you should be able to:

- Explain why AF_XDP exists.
- Distinguish AF_XDP from ordinary TCP/UDP sockets.
- Explain the relationship between XDP and AF_XDP.
- Explain what an XSK is.
- Explain UMEM and why it is central to AF_XDP.
- Explain the RX, TX, FILL, and COMPLETION rings.
- Explain how an XDP program redirects packets to an AF_XDP socket.
- Explain the role of `XSKMAP`.
- Explain copy mode versus zero-copy mode.
- Understand the relationship between NIC queues and AF_XDP sockets.
- Describe the basic AF\_XDP packet receive and transmit paths.
- Understand why AF\_XDP can achieve very high packet-processing performance.

---

## 1. Why Do We Need AF_XDP?

Before learning AF_XDP, remember the traditional socket model.

For a normal TCP application:

```
    Application
         ↓
    TCP socket
         ↓
        TCP
         ↓
         IP
         ↓
    Network driver
         ↓
        NIC
         ↓
      Network
```

For example, a web server may use:

```
socket(AF_INET, SOCK_STREAM, 0);

```

 The application sees a convenient stream of bytes:

```
    Application

    "GET / HTTP/1.1..."
           ↓
         TCP
           ↓
          IP
           ↓
         NIC
```

This abstraction is extremely useful.

However, it is not ideal for every type of networking application.

Some applications want to process **individual packets at extremely high speed**.

Examples include:

- Packet filters
- Network monitoring systems
- DDoS mitigation
- Load balancers
- Firewalls
- Packet forwarding applications
- Network appliances
- High-frequency packet processing
- Custom networking stacks
- High-performance user-space networking

These applications may not want:

```
    packet
       ↓
    many layers of kernel networking
       ↓
    TCP/UDP processing
       ↓
    socket buffering
       ↓
    application
```

 They may want much earlier access to the packet.

 This is one of the problems addressed by **XDP and AF_XDP**.

---

## 2. What Is XDP?

XDP stands for:

> **eXpress Data Path**

XDP allows an eBPF program to run very early in the Linux networking receive path.

Conceptually:

```
                     Network
                        ↓
                       NIC
                        ↓
                     Driver
                        ↓
                       XDP
                        ↓
             ┌──────────┼──────────┐
             │          │          │
          DROP        PASS       REDIRECT
             │          │          │
             ↓          ↓          ↓
           Drop      Linux      AF_XDP
                    network       socket
                      stack
```

The XDP program can inspect a packet and make an early decision.

For example:

```
Packet arrives
      ↓
   XDP program
      ↓
   Is source IP blocked?
      │
   ┌──┴──┐
   │     │
  Yes    No
   │     │
 DROP    PASS
```

 Or:

```
Packet arrives
      ↓
   XDP program
      ↓
   REDIRECT
      ↓
 AF_XDP socket
      ↓
User-space application
```

The Linux kernel documentation describes AF_XDP as an address family optimized for high-performance packet
processing and explains that XDP can redirect ingress frames into an AF_XDP socket.  [+1]

---

## 3. What Is AF_XDP?

 `AF_XDP` is a Linux socket address family specifically designed for high-performance packet processing.

 A socket can be created using:

```
socket(AF_XDP, SOCK_RAW, 0);
```

The important difference from our previous TCP example is that:

```
socket(AF_INET, SOCK_STREAM, 0);
```

means roughly:

```
    IPv4
      +
    stream
      +
    TCP
```

while:

```
socket(AF_XDP, SOCK_RAW, 0);
```

means:

```
XDP socket domain
       +
raw packet-oriented communication
```

 It is **not a TCP socket**.

 It is **not a UDP socket**.

 It operates much closer to the packet-processing path.

---

## 4. The Big Picture

The most important diagram is:

```
                         NETWORK
                            │
                            ↓
                           NIC
                            │
                            ↓
                         DRIVER
                            │
                            ↓
                          XDP
                            │
                ┌───────────┴───────────┐
                │                       │
             XDP_PASS              XDP_REDIRECT
                │                       │
                ↓                       ↓
       Linux networking             AF_XDP
            stack                   socket
                │                       │
                ↓                       ↓
          TCP / UDP                 User space
                │
                ↓
          Normal socket
```

 This is the key difference:

> **AF_XDP provides a path from XDP directly into user-space packet processing.**

---

## 5. What Is an XSK?

 An AF_XDP socket is often called an:

> **XSK**

Think of:

```
XSK = AF_XDP socket
```

So:

```
    AF_XDP
       ↓
    socket()
       ↓
    XSK
```
The XSK is the communication endpoint between the XDP/kernel side and the user-space application.

---

## 6. AF_XDP Is Not Just `socket()` + `recv()`

This is one of the most important differences from the TCP example.

With a normal TCP socket, students learn:

```
socket()
bind()
listen()
accept()
recv()
send()
close()
```

With AF_XDP, the application works with **memory buffers and rings**.

Conceptually:

```
User Space
┌─────────────────────────────────────┐
│                                     │
│ Application                         │
│                                     │
│   RX Ring       TX Ring             │
│      │             │                │
│      └──────┬──────┘                │
│             │                       │
│            UMEM                     │
│             │                       │
└─────────────┼───────────────────────┘
              │
              ↓
            Kernel
              │
              ↓
             XDP
              │
              ↓
             NIC
```

This architecture is designed to minimize expensive data movement and system-call overhead.

---

## 7. The Four Important Rings

AF_XDP uses four types of rings:

```
                  AF_XDP
                     │
        ┌────────────┼────────────┐
        │            │            │
        ↓            ↓            ↓
      UMEM          RX           TX
        │
    ┌───┴───┐
    ↓       ↓
  FILL  COMPLETION
```

The four rings are:

1. **FILL ring**
2. **COMPLETION ring**
3. **RX ring**
4. **TX ring**

The Linux documentation specifies that FILL and COMPLETION belong to the UMEM, while RX and TX are
associated with individual AF\_XDP sockets.  Linux Kernel Documentation

---

## 8. First: Understand UMEM

UMEM is one of the most important concepts in AF_XDP.

Think of UMEM as:

> **A region of memory containing packet buffers that are shared between the kernel/XDP side and the
> user-space application.**

Conceptually:

```
UMEM
┌─────────────────────────────────────┐
│                                     │
│ Frame 0                             │
├─────────────────────────────────────┤
│ Frame 1                             │
├─────────────────────────────────────┤
│ Frame 2                             │
├─────────────────────────────────────┤
│ Frame 3                             │
├─────────────────────────────────────┤
│ ...                                 │
├─────────────────────────────────────┤
│ Frame N                             │
└─────────────────────────────────────┘
```

Each frame is a fixed-size chunk of the UMEM.

The application and kernel exchange **ownership of these buffers** rather than repeatedly allocating and
copying packet memory.

The kernel documentation describes UMEM as a virtually contiguous memory region divided into equally sized
frames/chunks.  Linux Kernel Documentation

---

## 9. Why Is UMEM Important?

Imagine a network card receives:

```
Packet A
```

A traditional architecture might involve multiple buffers and copies as the packet moves through the stack.
AF_XDP tries to make packet ownership transfer much more efficient.

Conceptually:

```
          UMEM
┌──────────────────────┐
│ Packet buffer        │
└──────────────────────┘
       ↑          ↑
       │          │
     Kernel     User
```

Instead of saying:

> "Copy this packet into another application buffer."

the system can exchange a reference to the buffer.

 That is a major part of AF\_XDP's performance model.

---

## 10. What Is a Descriptor?

The rings generally don't contain the entire packet.

They contain **descriptors** that refer to packet buffers.

Conceptually:

```
Descriptor

┌──────────────────────┐
│ address / offset     │
│ length               │
│ options              │
└──────────────────────┘
```

The descriptor tells the application/kernel something like:

> "The packet data is at this location in UMEM and has this length."

The RX and TX descriptors use `struct xdp_desc`; its address refers to an offset into UMEM.  Linux Kernel
Documentation

---

## 11. The FILL Ring

The FILL ring is associated with receiving packets.

Its job is essentially:
 > **User space tells the kernel which UMEM buffers are available for receiving packets.**

Imagine:

```
User Space
    │
    │ "Here are free buffers."
    ↓
 FILL ring
    │
    ↓
 Kernel / NIC
```

 For example:

```
FILL

[frame 0]
[frame 1]
[frame 2]
[frame 3]
```

The kernel can use those buffers for incoming packets.

The Linux documentation describes the FILL ring as transferring ownership of UMEM frames from user space to
the kernel.  Linux Kernel Documentation

---

## 12. The RX Ring

After packets arrive, descriptors referring to received packet buffers appear on the RX ring.

Conceptually:

```
NIC
 ↓
XDP
 ↓
UMEM buffer
 ↓
RX descriptor
 ↓
RX ring
 ↓
User application
```

For example:

```
RX ring

+----------------+
| addr = frame 2 |
| len  = 128     |
+----------------+

+----------------+
| addr = frame 7 |
| len  = 512     |
+----------------+
```

The application consumes these descriptors and then accesses the corresponding packet data in UMEM.
The RX ring therefore answers:

> **"Which packet buffers contain packets that are ready for the application?"**

---

## 13. The TX Ring

The TX ring works in the opposite direction.
The application prepares packet data in a UMEM frame and places a descriptor into the TX ring.

```
Application
     │
     │ prepare packet
     ↓
   UMEM
     │
     ↓
  TX ring
     │
     ↓
    XDP
     │
     ↓
    NIC
     │
     ↓
 Network
```
So the TX ring answers:

> **"Which packet buffers should the kernel/NIC transmit?"**

---

## 14. The COMPLETION Ring

After transmitting a packet, the kernel needs to tell user space:

> "You can reuse this UMEM buffer now."

That's the job of the COMPLETION ring.

```
User
 │
 │ packet buffer
 ↓
TX ring
 │
 ↓
Kernel / NIC
 │
 │ transmission processing
 ↓
COMPLETION ring
 │
 ↓
User
 │
 ↓
buffer reusable
```

The completion entry means the frame has been returned to user-space ownership; importantly, a completion
does **not by itself guarantee that the packet successfully reached its destination**.  Linux Kernel
Documentation

---

## 15. The Complete Receive Path

Now combine the pieces.

Suppose a packet arrives:

```
                  Network
                     │
                     ↓
                    NIC
                     │
                     ↓
                  Driver
                     │
                     ↓
                    XDP
                     │
                     │ redirect
                     ↓
                 XSKMAP
                     │
                     ↓
                  AF_XDP
                     │
                     ↓
                  RX ring
                     │
                     ↓
              descriptor
                     │
                     ↓
                   UMEM
                     │
                     ↓
              User application
```

There is an important relationship:

```
RX descriptor
      │
      ↓
UMEM address
      │
      ↓
actual packet data
```

The descriptor tells the application where the packet is.

---

## 16. But Who Decides Which XSK Gets the Packet?

This is where **XSKMAP** comes in.

`XSKMAP` is a special eBPF map:

```
BPF_MAP_TYPE_XSKMAP
```

It allows an XDP program to redirect packets to particular AF\_XDP sockets.

Conceptually:

```
                  XDP
                   │
                   ↓
                XSKMAP
          ┌────────┼────────┐
          │        │        │
          ↓        ↓        ↓
        XSK 0    XSK 1    XSK 2
          │        │        │
          ↓        ↓        ↓
        App 0    App 1    App 2
```

The XDP program can choose an index:

```
packet
   ↓
XDP program
   ↓
queue_id
   ↓
XSKMAP[index]
   ↓
AF_XDP socket
```

The kernel verifies that the socket selected in the map is actually bound to the appropriate device and
queue; otherwise the redirect does not succeed.  Linux Kernel Documentation+1

---

## 17\. A Simple XDP Program

 A conceptual XDP program can look like:

```
SEC("xdp_sock")
int xdp_sock_prog(struct xdp_md *ctx)
{
    int index = ctx->rx_queue_index;

    if (bpf_map_lookup_elem(&xsks_map, &index))
        return bpf_redirect_map(
            &xsks_map,
            index,
            0
        );

    return XDP_PASS;
}
```

The important idea is:

```
Packet arrives
      ↓
Get RX queue
      ↓
Look up socket in XSKMAP
      ↓
Found?
  ┌───┴───┐
 YES      NO
  │        │
  ↓        ↓
REDIRECT  PASS
```

This is the basic bridge between **XDP and AF\_XDP**. The Linux kernel documentation provides this same
architectural pattern.  Linux Kernel Documentation

---

## 18. Why Does the RX Queue Matter?

 Modern NICs often have multiple hardware receive queues.

 For example:

```
                    NIC
                     │
          ┌──────────┼──────────┐
          │          │          │
        Queue 0    Queue 1    Queue 2
          │          │          │
          ↓          ↓          ↓
        XSK 0      XSK 1      XSK 2
          │          │          │
          ↓          ↓          ↓
        CPU 0      CPU 1      CPU 2
```

This makes it possible to distribute packet processing across CPUs.

For high-performance applications, this is extremely important.

Instead of:

```
One NIC
   ↓
One CPU
   ↓
One application
```

we can have:

```
                NIC
                 │
      ┌──────────┼──────────┐
      ↓          ↓          ↓
   Queue 0    Queue 1    Queue 2
      │          │          │
      ↓          ↓          ↓
    CPU 0      CPU 1      CPU 2
      │          │          │
      ↓          ↓          ↓
   Worker 0   Worker 1   Worker 2
```

---

# 19\. AF\_XDP and CPU Parallelism

This is one of the reasons AF\_XDP is useful for high-performance networking.

Suppose we have:

```
8 CPU cores
8 NIC queues
8 AF_XDP sockets
```

We can conceptually arrange:

```
Queue 0 → XSK 0 → CPU 0
Queue 1 → XSK 1 → CPU 1
Queue 2 → XSK 2 → CPU 2
Queue 3 → XSK 3 → CPU 3
Queue 4 → XSK 4 → CPU 4
Queue 5 → XSK 5 → CPU 5
Queue 6 → XSK 6 → CPU 6
Queue 7 → XSK 7 → CPU 7
```

This is much more scalable than forcing all packet processing through one execution context.

---

## 20\. Copy Mode vs Zero-Copy Mode

 AF\_XDP can operate in two important modes:

```
AF_XDP
   │
   ├── Copy mode
   │
   └── Zero-copy mode
```

### Copy Mode

In copy mode, packet data is copied into user-space memory.

Conceptually:

```
NIC
 ↓
Kernel
 ↓
copy
 ↓
UMEM
 ↓
Application
```

 This is easier to support because it doesn't require specialized driver support.

---

# 21\. Zero-Copy Mode

In zero-copy mode, the goal is to avoid copying packet data between kernel and user space.

Conceptually:

```
NIC
 │
 ↓
UMEM
 │
 ↓
Application
```

The exact implementation depends on NIC/driver capabilities.

The Linux documentation notes that AF\_XDP attempts to use zero-copy when available, while falling back to copy mode when appropriate; applications can also explicitly request `XDP_COPY` or `XDP_ZEROCOPY`.  Kernel.org

This is one of the major performance advantages of AF\_XDP.

---

 # 22\. Why Is Zero-Copy Difficult?

 Because the hardware and driver need to support the necessary memory model.

 Not every NIC supports AF\_XDP zero-copy.

 Therefore:

```
Application
     │
     ↓
AF_XDP
     │
     ├── NIC supports zero-copy
     │          ↓
     │      zero-copy
     │
     └── otherwise
                ↓
             copy mode
```

You should therefore **never teach students that AF\_XDP automatically means zero-copy**.

The more accurate statement is:

> **AF\_XDP supports zero-copy when the required driver/device support is available; otherwise it can operate in copy mode.**

---

 # 23\. Why Rings Instead of `recv()`?

This is a key design decision.

A traditional socket application might do:

```
recv(fd, buffer, size, 0);
```

 This involves a system-call-oriented interface.

 AF\_XDP instead exposes memory-mapped rings.

 Conceptually:

```
Traditional socket:

Application
    │
    │ recv()
    ↓
 Kernel
    │
    ↓
 packet
```

 AF\_XDP:

```
Application
    │
    │ access ring
    ↓
RX ring
    │
    ↓
UMEM
```

The rings can be accessed from user space after being configured/mapped, reducing the amount of syscall
interaction required in the packet-processing data path. The kernel documentation describes the rings as
being configured with `setsockopt()` and mapped into user space with `mmap()`.  Linux Kernel Documentation

---

## 24\. Single Producer / Single Consumer

The AF\_XDP rings are designed as **single-producer/single-consumer (SPSC)** rings.

That means, conceptually:

```
Producer ───────→ Ring ───────→ Consumer
```

 For example:

```
Kernel ─────→ RX Ring ─────→ Application
```

 or:

```
Application ─────→ TX Ring ─────→ Kernel
```

This design avoids the overhead of general-purpose multi-producer/multi-consumer synchronization.

The kernel documentation explicitly describes the AF\_XDP rings as single-producer/single-consumer.  Linux Kernel Documentation

---

## 25. Ownership Is the Key Concept

The most useful way to understand AF\_XDP is through **buffer ownership**.

Imagine:
```
          UMEM FRAME
              │
       Who owns it?
              │
     ┌────────┴────────┐
     │                 │
  USER SPACE         KERNEL
```

The rings effectively transfer ownership.

For receive:

```
User
 │
 │ buffer available
 ↓
FILL
 │
 ↓
Kernel
 │
 │ packet arrives
 ↓
RX
 │
 ↓
User
```

 For transmit:

```
User
 │
 │ packet ready
 ↓
TX
 │
 ↓
Kernel / NIC
 │
 │ done processing
 ↓
COMPLETION
 │
 ↓
User
```

This ownership model is arguably more important than memorizing the four ring names.

---

## 26. The Complete AF\_XDP Architecture

Now combine everything:

```
                              NETWORK
                                 │
                                 ↓
                                NIC
                                 │
                          ┌──────┴──────┐
                          │ RX queues   │
                          └──────┬──────┘
                                 │
                                 ↓
                              DRIVER
                                 │
                                 ↓
                                XDP
                                 │
                         XDP program
                                 │
                                 ↓
                              XSKMAP
                                 │
                  ┌──────────────┼──────────────┐
                  ↓              ↓              ↓
                XSK 0          XSK 1          XSK 2
                  │              │              │
                  ↓              ↓              ↓
                RX ring        RX ring        RX ring
                  │              │              │
                  └──────────────┼──────────────┘
                                 │
                               UMEM
                                 │
                  ┌──────────────┴──────────────┐
                  │                             │
               FILL ring                 COMPLETION ring
                  │                             │
                  └──────────────┬──────────────┘
                                 │
                           User application
                                 │
                              TX ring
                                 │
                                 ↓
                              Kernel
                                 │
                                 ↓
                                NIC
```

---

## 27. AF_XDP Packet Receive Sequence

 Let's follow one packet from beginning to end.

#### Step 1 — Application prepares buffers

The application creates UMEM:

```
UMEM

Frame 0
Frame 1
Frame 2
Frame 3
...
```

#### Step 2 — Application puts available frames into FILL

```
FILL

Frame 0
Frame 1
Frame 2
Frame 3
```

#### Step 3 — Packet arrives

```
Network
   ↓
NIC
   ↓
Driver
   ↓
XDP
```

#### Step 4 — XDP redirects packet

 The XDP program uses `XSKMAP`.

```
XDP
 ↓
XSKMAP[queue_id]
 ↓
XSK
```

#### Step 5 — Kernel places packet into an available UMEM frame

```
UMEM

Frame 0 → packet
Frame 1
Frame 2
Frame 3
```

#### Step 6 — RX descriptor is produced

```
RX ring

[address = Frame 0]
[length  = packet length]
```

#### Step 7 — Application consumes descriptor

 The application obtains:

```
address
length
```

 and accesses the packet in UMEM.

---

## 28. AF_XDP Packet Transmit Sequence

Now reverse the direction.

### Step 1

Application obtains a free UMEM frame.

```
UMEM
   ↓
Frame 10
```

### Step 2

Application writes a packet into it.

```
Frame 10

+-----------------------------+
| Ethernet | IP | UDP | Data |
+-----------------------------+
```

### Step 3

Application creates a TX descriptor.

```
TX descriptor

address = Frame 10
length  = packet length
```

### Step 4

Descriptor goes into TX ring.

```
Application
     ↓
  TX ring
```

 ### Step 5

 Kernel processes it.

```
TX ring
   ↓
Kernel / driver
   ↓
NIC
```

### Step 6

When the frame is available for reuse, its address appears on COMPLETION.

```
COMPLETION
    ↓
Frame 10
```

The application can then reuse that buffer.

---

## 29. What Does `bind()` Mean for AF_XDP?

This is different from the TCP example.

For TCP we might say:

```
bind()
   ↓
IP address + port
```

For AF\_XDP, the socket is bound to a **network device and queue ID**.
Conceptually:

```
AF_XDP socket
      │
      ↓
   bind()
      │
      ├── Network device
      │      ↓
      │    eth0
      │
      └── Queue ID
             ↓
           Queue 3
```

For example:

```
eth0 + queue 3
```

This means:

> This AF\_XDP socket is associated with queue 3 of `eth0`.

The Linux documentation specifies that an XSK is bound to a device and a specific queue ID, and traffic
begins flowing after the bind is completed.  Linux Kernel Documentation

---

## 30. AF_XDP Does Not Use Ports Like TCP Does

This is another important distinction.

With TCP:

```
192.168.1.10:5000
```

is meaningful.

With AF_XDP, the fundamental binding is more like:

```
eth0 + queue 3
```

The application can inspect the Ethernet/IP/TCP/UDP headers itself if it needs them.

For example:

```
Ethernet frame
        │
        ↓
+------------------+
| Ethernet header  |
+------------------+
| IP header        |
+------------------+
| UDP header       |
+------------------+
| Application data |
+------------------+
```

AF_XDP gives the application access to the packet.

It doesn't turn the packet into a TCP byte stream for you.

---

 # 31\. AF\_XDP and TCP Are at Very Different Levels

 Compare:

```
TCP socket

Application
     ↓
"Hello World"
     ↓
TCP socket
     ↓
TCP
     ↓
IP
     ↓
Ethernet
```

 with:

```
AF_XDP

Application
     ↓
Ethernet frame
     ↓
AF_XDP
     ↓
XDP
     ↓
NIC
```

With AF_XDP, the application is much closer to the packet.

Therefore the application may need to understand:

- Ethernet headers
- IP headers
- TCP headers
- UDP headers
- Checksums
- Packet lengths
- Packet buffers
- Queues
- Buffer ownership

 This is powerful but much more complicated.

---

## 32. AF\_XDP Is Not "Faster TCP"

This is an important conceptual warning.

It is tempting to say:

> "AF\_XDP is a faster version of TCP sockets."

That is incorrect.

AF\_XDP is better described as:

> **A high-performance packet-processing interface that allows user-space applications to receive and transmit packets through XDP.**

The application can implement its own higher-level networking logic if needed.

For example:

```
AF_XDP
   ↓
Ethernet
   ↓
IPv4
   ↓
UDP
   ↓
Custom application protocol
```

The application could implement processing directly at these levels.

---

## 33. XDP Actions

An XDP program can make several kinds of decisions.

Conceptually:

```
Packet
  ↓
XDP program
  │
  ├── XDP_DROP
  │
  ├── XDP_PASS
  │
  ├── XDP_TX
  │
  └── XDP_REDIRECT
```

### `XDP_DROP`

Discard the packet immediately.

```
Packet → XDP → DROP
```

### `XDP_PASS`

Continue into the normal networking stack.

```
Packet → XDP → Linux networking stack
```

### `XDP_TX`

Transmit the packet back out through the interface.

```
Packet
  ↓
XDP
  ↓
XDP_TX
  ↓
NIC
```

#### `XDP_REDIRECT`

 Redirect the packet elsewhere, including to AF_XDP through an XSKMAP.

```
Packet
  ↓
XDP
  ↓
REDIRECT
  ↓
XSKMAP
  ↓
AF_XDP
```

---

## 34. Where Does eBPF Fit?

 XDP programs are normally implemented using **eBPF**.

 So the architecture is:

```
                    Linux
                      │
                  eBPF program
                      │
                      ↓
                     XDP
                      │
             ┌────────┴────────┐
             │                 │
           DROP              REDIRECT
                               │
                               ↓
                             XSKMAP
                               │
                               ↓
                            AF_XDP
                               │
                               ↓
                          Application
```

 This gives us two cooperating components:

```
XDP/eBPF
    +
AF_XDP user application
```

 Neither part alone represents the complete architecture.

---

## 35. AF_XDP Requires Two Sides

 This is an important practical point.

 An AF_XDP application generally requires:

```
                AF_XDP system
                     │
          ┌──────────┴──────────┐
          │                     │
          ↓                     ↓
      XDP program          User program
          │                     │
          ↓                     ↓
       XSKMAP                 XSK
          │                     │
          └──────────┬──────────┘
                     │
                    UMEM
```

 The XDP program decides where packets go.

 The user application consumes/produces packet data.

 The kernel documentation explicitly notes that using AF\_XDP requires both a user-space application and an
 XDP program.  Linux Kernel Documentation

---

## 36. Why Use libbpf?

It is possible to interact with the AF\_XDP interface directly through the Linux UAPI.

But doing everything manually is complicated.

For example, you need to manage:

```
UMEM
RX ring
TX ring
FILL ring
COMPLETION ring
mmap()
setsockopt()
bind()
XSKMAP
XDP program
descriptor ownership
memory barriers
```

The Linux documentation recommends using **libbpf** to make AF\_XDP setup and ring operations easier.  Kernel.org

Therefore, for a practical programming course, a good progression is:

```
Level 1
Understand architecture

        ↓

Level 2
Use libbpf

        ↓

Level 3
Write XDP program

        ↓

Level 4
Use AF_XDP from C

        ↓

Level 5
Study raw UAPI/ring implementation
```

---

## 37. AF_XDP Setup — Conceptual Sequence

A simplified setup looks like:

```
1. Create AF_XDP socket
          ↓
2. Allocate UMEM
          ↓
3. Register UMEM
          ↓
4. Configure FILL ring
          ↓
5. Configure COMPLETION ring
          ↓
6. Configure RX ring
          ↓
7. Configure TX ring
          ↓
8. mmap rings into user space
          ↓
9. Load XDP program
          ↓
10. Create/configure XSKMAP
          ↓
11. Put XSK into XSKMAP
          ↓
12. bind() XSK to device + queue
          ↓
13. Start packet processing
```

This is a conceptual sequence; real programs often use libbpf to simplify many of these operations.

---

## 38. A Minimal Conceptual Data Path

For receiving:

```
           USER SPACE
┌─────────────────────────────┐
│                             │
│       Application           │
│           ↑                 │
│           │                 │
│        RX ring              │
│           ↑                 │
│           │                 │
│          UMEM               │
│                             │
└───────────┬─────────────────┘
            │
            │
       KERNEL / XDP
            │
            ↓
           NIC
```

For transmitting:

```
           USER SPACE
┌─────────────────────────────┐
│                             │
│       Application           │
│           │                 │
│        TX ring              │
│           │                 │
│          UMEM               │
│                             │
└───────────┬─────────────────┘
            │
            ↓
       KERNEL / XDP
            │
            ↓
           NIC
            │
            ↓
         NETWORK
```

---

## 39. Multi-Buffer Packets

Modern AF\_XDP also supports packets that occupy multiple UMEM frames.

For example, a large packet could be represented as:

```
Frame 10
┌──────────────────┐
│ packet data      │
└──────────────────┘
        +
Frame 11
┌──────────────────┐
│ packet data      │
└──────────────────┘
        +
Frame 12
┌──────────────────┐
│ packet data      │
└──────────────────┘
```

Together:

```
Frame 10 + Frame 11 + Frame 12
             ↓
        One packet
```

This is useful for large packets such as jumbo frames.

AF\_XDP supports this through multi-buffer support and descriptor flags such as `XDP_PKT_CONTD`.  Kernel.org

For an introductory course, however, I recommend teaching **single-buffer packets first**.

---

## 40. Shared UMEM

Multiple AF\_XDP sockets can share the same UMEM.

Conceptually:

```
                    UMEM
                     │
           ┌─────────┼─────────┐
           │         │         │
          XSK 0     XSK 1     XSK 2
           │         │         │
         RX/TX     RX/TX     RX/TX
          rings      rings      rings
```

The sockets have their own RX/TX rings while the UMEM can be shared.

This can be useful when building multi-queue or multi-worker architectures.

The kernel documentation provides detailed rules for shared UMEM and notes that the FILL/COMPLETION rings
are associated with the relevant UMEM/netdev/queue arrangement.  Kernel.org

---

## 41. AF_XDP Performance Model

Why can AF\_XDP be fast?

Several ideas work together:

```
                    Performance
                        │
       ┌────────────────┼────────────────┐
       ↓                ↓                ↓
     XDP             UMEM             Rings
       │                │                │
 Early packet       Shared packet      Low-overhead
 processing         buffers            ownership
       │                │                │
       └────────────────┼────────────────┘
                        ↓
                  AF_XDP socket
                        ↓
                 User application
```

Important techniques include:

- Early packet processing with XDP
- Memory-mapped rings
- UMEM packet buffers
- Batch processing
- Per-queue processing
- CPU parallelism
- Optional zero-copy operation
- Reduced syscall frequency
- Avoidance of unnecessary packet copies

---

## 42. Why Batch Processing Matters

Suppose an application receives 1 packet.

```
process packet
```

Now suppose it receives 64 packets.
Instead of treating every packet as a completely independent operation, the application can process
descriptors in batches:

```
RX ring

[packet 1]
[packet 2]
[packet 3]
...
[packet 64]
```

 Then:

```
dequeue batch
      ↓
process batch
      ↓
return buffers
```

This can reduce per-packet overhead.

This is one reason ring-based packet-processing architectures are attractive for high packet rates.

---

## 43. `need_wakeup`

AF\_XDP has a mechanism called:

```
XDP_USE_NEED_WAKEUP
```

The basic idea is:

> The application should perform an explicit wake-up syscall only when the kernel indicates that one is needed.

This can reduce unnecessary syscalls.

For example:

```
Application
    │
    ↓
TX ring
    │
    ↓
need_wakeup?
    │
 ┌──┴──┐
No     Yes
 │       │
 ↓       ↓
continue send/poll
```

The kernel documentation recommends enabling this mode because it can reduce syscall overhead, especially in
certain CPU-sharing arrangements.  Linux Kernel Documentation

---

## 44. AF_XDP vs AF_PACKET vs Normal Socket

This is a useful comparison for students.

 |  | TCP socket | AF\_PACKET | AF\_XDP |
| --- | --- | --- | --- |
| Main abstraction | Byte stream | Packet/frame | High-performance packet |
| Typical family | `AF_INET` | `AF_PACKET` | `AF_XDP` |
| TCP processing | Kernel | Application/kernel as appropriate | Application if desired |
| IP processing | Kernel | Application can inspect | Application can inspect |
| XDP integration | Indirect | Not the primary purpose | Core purpose |
| UMEM | No | No | Yes |
| RX/TX rings | Normal socket buffers | Packet socket mechanisms | Dedicated rings |
| Zero-copy design | Not the defining model | Not the defining model | Supported |
| Typical use | Web, SSH, APIs | Packet capture/tools | High-performance packet processing |

---

## 45. AF_XDP vs DPDK

 Students will eventually encounter **DPDK**.

 Both are used for high-performance packet processing, but they are not the same technology.

 Conceptually:

```
High-performance packet processing
            │
      ┌─────┴─────┐
      │           │
   AF_XDP       DPDK
      │           │
 Linux kernel   User-space
 XDP path       networking
```

AF_XDP integrates with Linux's XDP/eBPF infrastructure.

DPDK takes a different architectural approach and provides its own large set of user-space networking
components.

This is a topic worth covering separately rather than treating AF\_XDP as "Linux's version of DPDK."

---

## 46. What Happens to TCP/UDP?

A common misconception is:

> "If I use AF\_XDP, Linux will give me TCP packets."

Not automatically.

AF_XDP delivers packet data.

If a UDP packet arrives:

```
Ethernet
   ↓
IPv4
   ↓
UDP
   ↓
Data
```

the application can inspect those headers itself.

For example:

```
packet
  │
  ├── Ethernet header
  │
  ├── IPv4 header
  │
  ├── UDP header
  │
  └── payload
```

 The application can decide:

```
Is this UDP?
       ↓
Is destination port 4242?
       ↓
Process packet
```

This is fundamentally different from:

```
recv(fd, buffer, 1024, 0);
```

on a normal UDP/TCP socket.

---

## 47. A Useful Layer Diagram

For ordinary web communication:

```
Application
     ↓
HTTP
     ↓
TCP
     ↓
IP
     ↓
Ethernet
     ↓
NIC
```

For AF_XDP:

```
Application
     ↓
AF_XDP
     ↓
XDP/eBPF
     ↓
Driver
     ↓
NIC
```

The application can potentially implement its own packet processing:

```
Application
     ↓
Ethernet parser
     ↓
IP parser
     ↓
UDP/TCP parser
     ↓
Application protocol
```

This is why AF\_XDP is powerful — and why it requires considerably more networking knowledge.

---

## 48. Important Terminology

Students should know these terms:

| Term | Meaning |
| --- | --- |
| XDP | eXpress Data Path |
| eBPF | Programmable kernel execution mechanism used by XDP |
| AF\_XDP | Linux socket family for high-performance XDP packet processing |
| XSK | AF\_XDP socket |
| UMEM | Memory region containing packet buffers |
| RX ring | Descriptors for received packets |
| TX ring | Descriptors for packets to transmit |
| FILL ring | Buffers supplied by user space for receiving |
| COMPLETION ring | Transmitted buffers returned for reuse |
| XSKMAP | eBPF map used to redirect packets to XSKs |
| Queue | NIC receive/transmit queue |
| XDP\_PASS | Continue packet through normal networking stack |
| XDP\_DROP | Drop packet |
| XDP\_REDIRECT | Redirect packet, including to AF\_XDP |
| XDP\_TX | Transmit packet back through XDP path |
| XDP\_SKB | Generic XDP mode using SKBs |
| XDP\_DRV | Driver/native XDP mode |
| Zero-copy | Packet data can be accessed without the usual copy into user-space buffers |
| Copy mode | Packet data is copied into user-space UMEM |

---

## 49. The Most Important Diagram to Remember

 If students remember only one diagram from this lesson, use this:

```
                         NIC
                          │
                          ↓
                       Driver
                          │
                          ↓
                         XDP
                          │
                 ┌────────┴────────┐
                 │                 │
              XDP_PASS       XDP_REDIRECT
                 │                 │
                 ↓                 ↓
          Linux network          XSKMAP
              stack                 │
                 │                  ↓
                 ↓               AF_XDP
            TCP / UDP               │
                 │             ┌────┴────┐
                 ↓             │         │
          Normal socket       RX/TX    UMEM
                              rings      │
                                │        │
                                └────┬───┘
                                     ↓
                                Application
```

 This diagram explains why AF\_XDP is fundamentally different from the socket examples we studied earlier.

---

## 50. The Mental Model

 For normal sockets:

```
"I want to communicate with another application."
                ↓
             socket
                ↓
           TCP / UDP
                ↓
              IP
```

For AF\_XDP:

```
"I want to process packets at very high speed."
                ↓
               XDP
                ↓
          XSKMAP / XSK
                ↓
             UMEM
                ↓
          user application
```

---

## 51. Summary

AF_XDP is a specialized Linux socket family for high-performance packet processing.

The core architecture is:

```
XDP
 ↓
XSKMAP
 ↓
AF_XDP socket
 ↓
RX/TX rings
 ↓
UMEM
 ↓
User application
```

The four rings are:

```
FILL
  ↓
provides receive buffers

RX
  ↓
provides received packet descriptors

TX
  ↓
provides packets to transmit

COMPLETION
  ↓
returns transmitted buffers
```

 The key memory concept is:

```
             UMEM
              │
     ┌────────┼────────┐
     │        │        │
  Frame 0  Frame 1  Frame 2 ...
```

 The key routing concept is:

```
XDP program
     ↓
  XSKMAP
     ↓
   XSK
```

 And the key performance concepts are:

```
Early processing
       +
Shared packet buffers
       +
Memory-mapped rings
       +
Batching
       +
Multi-queue processing
       +
Optional zero-copy
       ↓
High-performance packet processing
```

---

## 52. Questions for Students

### Conceptual Questions

 1. What problem does AF\_XDP solve?
2. What is the difference between AF\_XDP and `AF_INET`?
3. What is an XSK?
4. What is UMEM?
5. Why does AF\_XDP use rings?
6. What is the purpose of the FILL ring?
7. What is the purpose of the RX ring?
8. What is the purpose of the TX ring?
9. What is the purpose of the COMPLETION ring?
10. What is XSKMAP?
11. Why does an XDP program need to redirect packets to an XSK?
12. What is the relationship between an XDP program and an AF\_XDP application?
13. What is the difference between copy mode and zero-copy mode?
14. Why is the NIC queue important?
15. Why might an application use multiple AF\_XDP sockets?

---

### Trace the Packet

 Given:

```
NIC
 ↓
Driver
 ↓
XDP
 ↓
XSKMAP
 ↓
AF_XDP
 ↓
RX ring
 ↓
UMEM
 ↓
Application
```

 Explain what happens to the packet at each step.

---

### Compare the APIs

 Compare:

```
socket(AF_INET, SOCK_STREAM, 0);
```

with:

```
socket(AF_XDP, SOCK_RAW, 0);
```

 What does each socket represent?

---

### Design Question

Suppose a server has:

```
8 CPU cores
8 NIC RX queues
```

Design an AF\_XDP architecture that distributes packets across all eight cores.

Draw:

```
NIC
 │
 ├── Queue 0 → ?
 ├── Queue 1 → ?
 ├── Queue 2 → ?
 ...
 └── Queue 7 → ?
```

 Explain where you would place:

- XSKs
- UMEM
- RX rings
- TX rings
- XSKMAP
- Worker threads

---

## 53. Final Takeaway

The most important distinction is:

> **Traditional sockets hide most of the packet-processing machinery from the application. AF\_XDP
> deliberately exposes a high-performance packet-processing path to user space.**

Traditional TCP:

```
Application
     ↓
Socket
     ↓
TCP
     ↓
IP
     ↓
NIC
```

 AF\_XDP:

```
Application
     ↑
    UMEM
     ↑
   RX/TX rings
     ↑
    XSK
     ↑
   XSKMAP
     ↑
    XDP
     ↑
   Driver
     ↑
    NIC
```

Once students understand **UMEM + rings + XSKMAP + XDP**, the AF\_XDP API becomes much easier to understand.

### Suggested teaching sequence

I would teach this after the TCP/UDP socket handout in this order:

1. **Normal TCP socket** — application thinks in bytes.
2. **UDP socket** — application thinks in datagrams.
3. **Raw/packet sockets** — application gets closer to packets.
4. **XDP** — packet processing moves very early in the Linux path.
5. **AF\_XDP** — connect that early XDP path to user space.
6. **UMEM and rings** — understand the performance mechanism.
7. **XSKMAP** — understand how packets are directed to applications.
8. **NIC queues + multiple XSKs** — understand scaling.
9. **Copy vs zero-copy** — understand the performance tradeoff.
10. **libbpf implementation** — finally write the program.

That progression prevents AF_XDP from looking like a collection of mysterious Linux constants and makes it
the logical next step after students understand ordinary sockets.

