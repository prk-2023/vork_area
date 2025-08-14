# Simple web server in Rust ( similar to the one in python -m http.server )

Use Cargo to create a new proj with and fill the below dependencies :

```toml
[dependencies] 
tiny_http = "0.12.0"
mime_guess = "2.0.5"
```

- tiny_http: This is a small, easy-to-use HTTP server library. It handles the low-level details of networking, like accepting connections and parsing HTTP requests, so the application code can focus on handling the logic.
- mime_guess: This library helps determine the MIME type of a file based on its file extension (e.g., .html -> text/html, .jpg -> image/jpeg). This is crucial for web servers to correctly tell browsers what kind of content they are receiving.

```rust 
use mime_guess::from_path;
use std::env;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::net::{SocketAddr, TcpListener};
use std::path::{Path, PathBuf};
use tiny_http::{Header, Request, Response, Server, StatusCode};
```

1. Below function searches for an open port starting from start_port up to 9000. 
   It tries to bind a TcpListener to each port. 
   If successful, it creates a tiny_http::Server from the listener and returns a tuple containing the port number and the server instance. 

   If no port is found, it returns None.

```rust 
fn find_available_port(start_port: u16) -> Option<(u16, Server)> {
    for port in start_port..9000 {
        let addr = format!("0.0.0.0:{}", port);
        if let Ok(listener) = TcpListener::bind(&addr) {
            if let Ok(server) = Server::from_listener(listener, None) {
                return Some((port, server));
            }
        }
    }
    None
}
```
2.  Below function simply prints information about an incoming request to the console. 
    It logs the client's IP address, the HTTP method (like GET), and the requested URL.
```rust
fn log_request(request: &Request, client_addr: Option<SocketAddr>) {
    let method = request.method();
    let url = request.url();
    println!(
        "[{}] {} {}",
        client_addr
            .map(|addr| addr.to_string())
            .unwrap_or_else(|| "unknown".to_string()),
        method,
        url
    );
}
``` 

3. Below function generates an HTML string for a directory listing. 
   It reads the contents of a directory and creates a list of clickable links for each file and subdirectory, similar to what you'd see in a browser.
```rust 
/// Generate HTML directory listing similar to Python's http.server
fn generate_directory_listing(path: &Path, url_path: &str) -> String {
    let mut listing = format!(
        "<html><body><h1>Directory listing for /{}</h1><ul>",
        url_path
    );

    if let Ok(entries) = fs::read_dir(path) {
        for entry in entries.flatten() {
            if let Ok(file_name) = entry.file_name().into_string() {
                let file_path = if url_path.is_empty() {
                    file_name.clone()
                } else {
                    format!("{}/{}", url_path, file_name)
                };
                listing.push_str(&format!(
                    "<li><a href=\"{}\">{}</a></li>",
                    file_path, file_name
                ));
            }
        }
    }

    listing.push_str("</ul></body></html>");
    listing
}
```

4. Below function  is the core request-handling function.
    - First it logs incoming request.
    - It constructs the full file system path by combining the server's root directory (root_dir) and the URL path from the request.
    - It checks if the path points to a directory. If it does, it first looks for an index.html file inside. If index.html exists, it serves that file. If not, it generates and serves an HTML directory listing using the generate_directory_listing function.
    - If the path points to a file that exists, it opens the file, reads its content into a buffer, and determines the correct MIME type (e.g., text/html, image/jpeg) using the mime_guess crate. It then sends the file content and the correct MIME type back to the client as the response.
    - If the path does not exist, it responds with a 404 Not Found error.
    - If there's an error reading the file, it responds with a 500 Internal Server Error.

```rust 
fn handle_request(request: Request, root_dir: &Path) {
    let client_addr = request.remote_addr().copied();
    log_request(&request, client_addr);

    let url_path = request.url().trim_start_matches('/');
    let mut path = root_dir.join(url_path);

    if path.is_dir() {
        let index_path = path.join("index.html");
        if index_path.exists() {
            path = index_path;
        } else {
            let html = generate_directory_listing(&path, url_path);
            let response = Response::from_string(html)
                .with_header(Header::from_bytes(b"Content-Type", b"text/html").unwrap());
            let _ = request.respond(response);
            return;
        }
    }

    if path.exists() && path.is_file() {
        match File::open(&path) {
            Ok(mut file) => {
                let mut content = Vec::new();
                if file.read_to_end(&mut content).is_ok() {
                    let mime = from_path(&path).first_or_octet_stream();
                    let response = Response::from_data(content).with_header(
                        Header::from_bytes(b"Content-Type", mime.to_string().as_bytes()).unwrap(),
                    );
                    let _ = request.respond(response);
                } else {
                    let _ = request.respond(Response::empty(StatusCode(500)));
                }
            }
            Err(_) => {
                let _ = request.respond(Response::empty(StatusCode(500)));
            }
        }
    } else {
        let _ = request.respond(Response::from_string("404 Not Found").with_status_code(404));
    }
}
```

5. Entry point of the program:
    - It sets a starting port 8000 
    - It determines the root directory for the server. It first checks for a cmd-line argument (the env::args().nth(1) part). If no argument is provided, it defaults to the current working directory.
    - It calls find_available_port to find a port to listen on.
    - It prints a message to the console indicating the server's URL and the directory it's serving.
    - It enters a loop that continuously waits for incoming requests (server.incoming_requests()). For each request received, it calls the handle_request function to process it.

```rust 
fn main() {
    let start_port = 8000;
    let root_dir = env::args()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| env::current_dir().expect("Failed to get current directory"));

    let (port, server) =
        find_available_port(start_port).expect("Could not find a free port in the range 8000-9000");

    println!(
        "Serving HTTP at http://localhost:{} from {:?}",
        port, root_dir
    );

    for request in server.incoming_requests() {
        handle_request(request, &root_dir);
    }
}
```
