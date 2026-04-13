# `mdbook` Howto:


## Introduction :

- `mdbook` is a Rust-based tool for creating books/docs from Markdown files. It’s simple and great for 
    - Developer docs
    - Tutorials
    - Knowledge bases

- With `mdbook` can generate "static websites (HTML)" and "Printable formats (PDFs)" via extra tools.

### Installation:

```bash
cargo install mdbook
```

- There are many plugins and extensions and install the those that are required, the plugins can be
  registered in to a project via `book.toml`.

- Examples: `mdbook-pdf`, `mdbook-mermaid`, `mdbook-gruvbox`, `mdbook-mermaid`

- Register the plugin: add to `book.toml`
    ```toml 
    [preprocessor.mermaid]
    ```

## Create a New Book project:

- you can create a book project and a starting template using the below command:

```bash 
$ mdbook init my-docs
$ cd my-docs
$ dust -b -r 
 12K └─┬ .
8.0K   ├─┬ src
4.0K   │ ├── chapter_1.md
4.0K   │ └── SUMMARY.md
4.0K   ├── book.toml
  0B   └── book
```

- `src/`: contains all the markdown contents.
- `SUMMARY.md`: 
    - Controls side-bar navigation. 
    - Chapter Order.
```bash 

$ cat src/SUMMARY.md
# Summary
- [Introduction](./chapter_1.md)
- [Getting Started](./getting_started.md)
```

### Create a New chapter:

- Create a new chapter:
```bash 
$ touch src/getting_started.md 
```
### Add content to the new file:

```bash 
#add content to this new file:
$ cat src/getting_started.md 
# Getting Started

Welcome to the guide.

## Installation

Steps go here...
```

### Register the file in SUMMARY.md 

- Add the file name to SUMMARY.md
```bash 
- [Getting Started](./getting_started.md)
```

### Build and Serve website:

- `mdbook build` 
- output goes to book/ folder 

### Run local dev server:

```bash
$ mdbook serve
```
- open `http://localhost:3000`

## Customize Configuration:

Edit `book.toml`

```bash 
$ nv book.toml 
[book]
title = "My Documentation"
authors = ["Your Name"]
language = "en"

[output.html]
default-theme = "light"
preferred-dark-theme = "navy"
```
### Add Features (Optional but Useful)

- Enable search: 

    - Add custom `CSS`:

    ```bash 
    [output.html]
    additional-css = ["theme/custom.css"]
    ```

#### Generate PDF: 

- `mdbook` doesn’t natively export PDF, but you can do it with plugins.

- `cargo install mdbook-pdf`

- Add to config :
    ```bash 
    [output.pdf]
    ```

- **build**:
    ```bash 
    mdbook build
    ```
    A pdf will appear in book/

#### Alternative better way to generate pdf ( via pandoc not mdbook)

- To generate pdf with additional control use `pandocs` ( install via dnf or apt )
- `pandoc src/*.md -o my-book.pdf`
