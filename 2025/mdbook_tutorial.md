# mdbook:

**mdBook** is an open-source tool (written in Rust) for creating modern, book-style documentation from Markdown files.
It’s similar to GitBook, but faster, lightweight, and great for Rust projects (though it works for anything).

You write chapters in Markdown, and mdBook builds a static website with navigation, search, theming, and more.

---

# 🌱 mdBook Tutorial — Step-by-Step

## 1. **Install mdBook**

### **Option A — Using Cargo (Rust’s package manager)**

If you have Rust installed:

```bash
cargo install mdbook
```

### **Option B — Download a prebuilt binary**

Go to the mdBook releases page on GitHub and download a binary for your OS.
(If you'd like, I can fetch the exact link.)

Check installation:

```bash
mdbook --version
```

---

## 2. **Create a New Book**

Use:

```bash
mdbook init my-book
```

You’ll get a folder structure:

```
my-book/
 ├── book.toml        # configuration
 ├── src/
 │    ├── SUMMARY.md  # table of contents
 │    ├── chapter_1.md
 │    └── ...
```

### **SUMMARY.md** defines the navigation

Example:

```markdown
# Summary

- [Introduction](index.md)
- [Getting Started](getting-started.md)
- [Advanced Topics](advanced.md)
```

Add new chapters by adding entries to `SUMMARY.md`.

---

## 3. **Write Chapters in Markdown**

For example, create `src/getting-started.md`:

```markdown
# Getting Started

This is how you begin...
```

mdBook supports code blocks, callouts, footnotes, and more.

---

## 4. **Serve the Book Locally**

Run:

```bash
mdbook serve
```

Then open the local URL (usually: [http://localhost:3000](http://localhost:3000)).
It auto-reloads when you edit files.

---

## 5. **Build the Static Site**

To produce a `book/` folder with HTML:

```bash
mdbook build
```

The `book/` folder can be deployed anywhere (GitHub Pages, Netlify, etc.).

---

## 6. **Basic Customization**

### **Edit `book.toml`**

Example:

```toml
[book]
title = "My Documentation"
author = "Your Name"

[output.html]
default-theme = "ayu"
git-repository-url = "https://github.com/username/repo"
```

Themes available: `light`, `rust`, `coal`, `ayu`.

---

## 7. **Useful Plugins (Optional)**

mdBook supports plugins such as:

* **mdbook-mermaid** — diagrams
* **mdbook-toc** — auto table-of-contents
* **mdbook-katex** — math rendering
* **mdbook-admonish** — colored callouts

Example install:

```bash
cargo install mdbook-mermaid
```

Enable in `book.toml`:

```toml
[preprocessor.mermaid]
```

---

## 8. **Deploying to GitHub Pages**

```bash
mdbook build
cd book
git init
git add .
git commit -m "Deploy"
git branch -M gh-pages
git remote add origin <YOUR-REPO-URL>
git push -f origin gh-pages
```

Then set GitHub Pages to use the **gh-pages** branch.

---

# 🎉 That’s It!

You now know how to:

✔ Install mdBook
✔ Create a book
✔ Edit chapters
✔ Serve locally with live reload
✔ Build your site
✔ Customize and add plugins
✔ Deploy it online

If you want, I can also:

📌 Create a ready-to-copy directory template
📌 Write a full `book.toml` example
📌 Show advanced features (admonitions, custom themes, search tweaks)
📌 Help you set up GitHub Actions for automatic deployment

What would you like next?
