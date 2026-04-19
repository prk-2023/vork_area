# Rust & eBPF Presentation — Typst/Touying Template

A complete presentation template for "Introduction to Rust and eBPF with Rust",
built with [Typst](https://typst.app) and the
[Touying](https://touying-typ.github.io) slide framework (Metropolis theme).

## File

```
slides.typ    ← the single source file for the entire presentation
```

## Quick start

### Option A — Typst CLI (local)

```bash
# Install Typst
curl -fsSL https://typst.app/install.sh | sh
# or: cargo install typst-cli

# Compile to PDF (packages auto-downloaded on first run)
typst compile slides.typ slides.pdf

# Live preview (recompiles on save, ~milliseconds)
typst watch slides.typ slides.pdf
```

### Option B — VS Code + Tinymist (recommended for editing)

1. Install the **Tinymist Typst** extension from the VS Code marketplace
2. Open `slides.typ`
3. Click the preview button (or `Ctrl+Shift+P` → "Typst Preview")
4. Edits compile live as you type

### Option C — Typst web app

Upload `slides.typ` to [typst.app](https://typst.app) — packages are
pre-installed, no local setup needed.

## Fonts (optional but recommended)

The template uses **Fira Sans** / **Fira Code** for the Metropolis look.
Typst falls back gracefully to Noto Sans / JetBrains Mono if not installed.

```bash
# Ubuntu/Debian
sudo apt install fonts-firacode fonts-open-sans

# macOS (Homebrew)
brew install --cask font-fira-code font-fira-sans
```

## Packages used

| Package | Version | Purpose |
|---|---|---|
| `@preview/touying` | 0.7.1 | Slide framework |
| `@preview/numbly` | 0.1.0 | Section numbering |

Both are auto-downloaded by Typst from the Typst Universe registry.

## Customising the presentation

### Change colours

Edit the palette block near the top of `slides.typ`:

```typst
#let rust-orange   = rgb("#CE422B")  // Rust brand colour
#let ebpf-teal     = rgb("#0D7377")  // eBPF accent
#let kernel-purple = rgb("#4B3B8C")  // kernel section accent
```

### Change author / institution / date

```typst
config-info(
  title:       [Introduction to Rust and eBPF with Rust],
  author:      [Your Name],
  institution: [IC Design Division],
  date:        datetime.today(),
)
```

### Add/remove slides

Each `==` heading creates a new slide. Each `=` heading creates a section
divider slide (and an entry in the progress bar).

```typst
= New Section

== New Slide Title

Content goes here.
```

### Two-column layout

```typst
#cols[
  Left column content
][
  Right column content
]
```

### Coloured callout box

```typst
#callout[Important note here]
#callout(color: ebpf-teal)[eBPF-themed note]
```

### Focus / emphasis slide

```typst
#focus-slide[
  Your one big takeaway message here.
]
```

### Code blocks with syntax highlighting

Typst has built-in syntax highlighting for most languages:

```typst
```rust
fn main() {
    println!("Hello, Typst!");
}
` ``
```

## Presenting

### Typst web app
Click the **Present** button (appears automatically for 16:9 aspect ratio).

### Evince / Okular (Linux PDF viewers)
Open the compiled PDF and use fullscreen mode (`F11`).

### pympress (recommended for speaker notes)
```bash
pip install pympress
pympress slides.pdf
```

### Export to PPTX or HTML
```bash
# Requires touying-exporter (separate tool)
# https://github.com/touying-typ/touying-exporter
```

## Why Typst?

This presentation is itself an argument for Rust's broader ecosystem impact:

- Typst is written **entirely in Rust**
- Compiles presentations in **milliseconds** (vs. LaTeX seconds/minutes)
- Native code blocks with **syntax highlighting** — no external packages
- Git-friendly plain text source — **diffs are readable**
- One `.typ` file, no auxiliary files, no `\usepackage` dependency hell
