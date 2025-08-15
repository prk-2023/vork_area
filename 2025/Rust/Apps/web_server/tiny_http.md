# tiny_http  : Crate 


#### 1. Add crate to `Cargo.toml`

Add the dependency under `[dependencies]`. Example for `tiny_http`:

```toml
[dependencies]
tiny_http = "0.12"
```

#### 2. Import in your Rust code

Use the crate with `use`:

```rust
use tiny_http::Server;
```

#### 3. Use it in `main.rs` or your modules

Crates often come with modules/types/functions ready to use — check the docs to explore.

---

## tiny\_http Crate — Tutorial & Overview

### What is `tiny_http`?

`tiny_http` is a **minimal and synchronous HTTP server** crate in Rust — great for learning, building quick servers, testing, or small web services.

* No async required.
* Good for serving files, creating RESTful endpoints, or prototyping.

---

### Step-by-Step Tutorial

#### 1. Add it to `Cargo.toml`

```toml
[dependencies]
tiny_http = "0.12"
```

#### 2. Basic HTTP Server Example

```rust
use tiny_http::{Server, Response};

fn main() {
    // Start the server on localhost:8000
    let server = Server::http("0.0.0.0:8000").unwrap();

    println!("Server running on http://localhost:8000");

    // Infinite loop to handle requests
    for request in server.incoming_requests() {
        println!("Received request: {:?}", request);

        let response = Response::from_string("Hello from tiny_http!");
        let _ = request.respond(response);
    }
}
```

 Run it with:

```bash
cargo run
```

Then go to `http://localhost:8000` in your browser.

---

### 🔧 What You Should Know About `tiny_http`

#### 🔹 Server Binding

```rust
let server = Server::http("0.0.0.0:8000").unwrap();
```

This starts listening on port 8000 for all interfaces.

#### 🔹 Receiving Requests

```rust
for request in server.incoming_requests() {
    // handle request here
}
```

This blocks until a request is received (synchronous).

#### 🔹 Working with Request Details

```rust
let method = request.method(); // GET, POST, etc.
let url = request.url();       // path like "/"
let headers = request.headers();
```

#### 🔹 Sending a Response

```rust
let response = Response::from_string("OK");
request.respond(response).unwrap();
```

You can send:

* Strings
* Static files
* Custom headers

#### 🔹 Serving Files (Example)

```rust
use std::fs::File;
use tiny_http::{Response, Header};

let file = File::open("index.html").unwrap();
let response = Response::from_file(file)
    .with_header(Header::from_bytes("Content-Type", "text/html").unwrap());

request.respond(response).unwrap();
```

---

### 📚 Where to Learn More

* Crates.io: [tiny\_http](https://crates.io/crates/tiny_http)
* Docs.rs: [tiny\_http Documentation](https://docs.rs/tiny_http/latest/tiny_http/)
* GitHub repo: [tiny\_http GitHub](https://github.com/tiny-http/tiny-http)

---

### 🧠 Summary

* `tiny_http` is great for **simple, blocking HTTP servers** in Rust.
* No async/complex setup required.
* You can handle requests, respond with strings or files, and serve static content.
* Perfect for quick tools, internal APIs, or learning HTTP basics in Rust.

Let me know if you want examples of routing, POST handling, or serving a static directory.
