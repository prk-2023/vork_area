# HowTo use mdbook to host markdown files with MathJax:


To use **mdBook** to view Markdown files with MathJax support (for rendering LaTeX equations), follow these steps:

### 1. **Install mdBook**

If you don’t have `mdBook` installed on your Linux system yet, you can install it using the following commands:

```bash
cargo install mdbook
```

Make sure you have **Rust** and **Cargo** installed on your system before running this command. If you don't have them, you can install them by following the instructions at [rust-lang.org](https://www.rust-lang.org/learn/get-started).

Alternatively, you can install `mdBook` via other methods, such as downloading from GitHub releases, but using Cargo is the recommended way if you have Rust installed.

### 2. **Create a New Book (or Use an Existing One)**

Once `mdBook` is installed, create a new book:

```bash
mdbook init my-book
cd my-book
```

This creates a new directory `my-book` with the initial structure of a book. Inside this directory, you'll find the following files:
- `book.toml` (configuration file)
- `src/` (folder for the book content)

### 3. **Configure MathJax in `book.toml`**

Open the `book.toml` file and ensure MathJax support is enabled. Add the following under `[output.html]` to activate MathJax rendering for LaTeX equations:

```toml
[output.html]
mathjax = true
```

This configuration tells `mdBook` to use **MathJax** for rendering LaTeX equations when the book is compiled to HTML.

### 4. **Add LaTeX Equations in Markdown Files**

Inside the `src/` folder, you can add Markdown files (e.g., `chapter_1.md`) and include your LaTeX equations.

For inline equations (like \( a = b + c \)), use single dollar signs (`$`):
```markdown
This is an inline equation: $a = b + c$.
```

For block equations (like a larger equation in its own block), use double dollar signs (`$$`):
```markdown
This is a block equation:
$$
\nabla \times \mathbf{B} = \mu_0 \left( \mathbf{J} + \epsilon_0 \frac{\partial \mathbf{E}}{\partial t} \right)
$$
```

### 5. **Build the Book**

After adding your content, you can build the book using the following command:

```bash
mdbook build
```

This will generate an HTML version of your book in the `book/` directory.

### 6. **Serve the Book Locally (Optional)**

To preview the book with MathJax rendering, you can start a local server:

```bash
mdbook serve
```

This will start a local server (typically accessible at `http://localhost:3000`) where you can view your book with rendered LaTeX equations in real-time.

### 7. **Viewing the Book**

Once the build is complete, you can open the `book/index.html` file in your browser to view the rendered book with MathJax LaTeX equations.

Alternatively, if you used `mdbook serve`, you can visit `http://localhost:3000` in your web browser to view the book interactively.

### Example File Structure

After following the above steps, your project should look like this:

```
my-book/
│
├── book.toml           # Configuration file
├── src/                # Folder containing Markdown files
│   ├── SUMMARY.md      # Table of contents (index)
│   └── chapter_1.md   # Example Markdown file with LaTeX equations
└── book/               # Output folder with generated HTML files
    └── index.html      # Generated HTML book
```

### Summary

1. **Install mdBook** using `cargo install mdbook`.
2. **Create a new book** with `mdbook init <book-name>`.
3. **Enable MathJax** by editing `book.toml` to include `mathjax = true`.
4. **Add LaTeX equations** in your Markdown files with `$` for inline and `$$` for block equations.
5. **Build the book** using `mdbook build`.
6. **Serve the book locally** with `mdbook serve` and view the LaTeX-rendered content in your browser.

Now, your `mdBook` will render LaTeX equations correctly using MathJax, and you can view and interact with your book locally!
