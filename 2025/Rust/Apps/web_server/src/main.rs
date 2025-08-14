use mime_guess::from_path;
use std::env;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::net::{SocketAddr, TcpListener};
use std::path::{Path, PathBuf};
use tiny_http::{Header, Request, Response, Server, StatusCode};

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
