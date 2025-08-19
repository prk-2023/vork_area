# Survey of GUI toolkits


## Intro:
Rust is a low level language suitable for making user interfaces the old fashion way with native APIs, Native APIs approach can be not practical when we target to support many platforms. 

Rust expressiveness and high level abstraction makes it ideal for building interactive and complex UIs. But Unfortunately there is little consensus on what the best abstractions are.

Current approach to build GUIs in Rust include interfacing with Electron and building GUIs with HTML ( or a framework on top of it) and while others have taken to using graphics APIs and various wrappers to emulate classical widgets.

A 2025 survey of Rust GUI libs is in the below URL:

Ref : https://www.boringcactus.com/2025/04/13/2025-survey-of-rust-gui-libraries.html 

---

## Summary of Your Requirements

| Area                | Your Need                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------- |
| **Platform**        | Linux only (Desktop + Embedded SBC + Web)                                                |
| **Device Features** | HDMI, GPU, aarch64 SBC (Yocto)                                                           |
| **Performance**     | High performance, low resource usage                                                     |
| **Licensing**       | Fully open source                                                                        |
| **Tech Stack**      | Pure Rust (preferred), WASM for web frontends                                            |
| **Deployment**      | Embedded app bundling + desktop binaries                                                 |
| **Use Case**        | GUI for profiling tools (eBPF via Aya), both local (GUI) and remote (WASM browser-based) |
| **Project Phase**   | Evaluation for long-term dev stack                                                       |

---

## Toolkit Recommendations (Ranked by Use Case)

### 1. **Slint (GPLv3)**

**Best overall fit for Embedded + Desktop GUI**

| Attribute            | Rating                             |
| -------------------- | ---------------------------------- |
| Maturity             | ⭐⭐⭐⭐☆ (4.5)                        |
| Rust-native fit      | 💡💡💡💡 (4)                       |
| Embedded suitability | ✅ Aarch64 + GPU + Yocto supported  |
| Declarative UI       | ✅ Yes                              |
| WASM support         | ✅ (Experimental but progressing)   |
| License fit          | ✅ (Open source — GPLv3)            |
| Lightweight          | ✅ (\~300–600 KB binaries possible) |

>  **Ideal for embedded UIs** where resources are tight, yet you want a modern, responsive UI. Active project with real-world Yocto deployment support.

---

### 2. **egui**

** Best for quick UIs, internal tools, and WASM dashboards**

| Attribute            | Rating                                             |
| -------------------- | -------------------------------------------------- |
| Maturity             | ⭐⭐⭐⭐ (4)                                           |
| Rust-native fit      | 💡💡💡💡💡 (5)                                     |
| Embedded suitability | ❌ (Not ideal for native embedded GUIs)             |
| WASM support         | ✅ First-class support                              |
| Lightweight          | ✅ (Reasonable for desktop, not ideal for embedded) |
| License fit          | ✅ MIT/Apache                                       |

>  **Ideal for web frontends** to present eBPF profiling data — deploys well to browsers via WASM, and you can share logic between native and web targets.

---

### 3. **fltk-rs**

** Best for stable, lightweight native desktop UIs**

| Attribute            | Rating                                                 |
| -------------------- | ------------------------------------------------------ |
| Maturity             | ⭐⭐⭐⭐☆ (4.5)                                            |
| Rust-native fit      | 💡💡💡 (3)                                             |
| Embedded suitability | ⚠️ Only if FLTK runs on target (static linking needed) |
| WASM support         | ❌ No                                                   |
| License fit          | ✅ LGPL                                                 |
| Lightweight          | ✅ Excellent for desktop apps (\~500KB binaries)        |

>  Good for **traditional desktop tools** with small memory footprint and static linking for portability.

---

### 4. **Iced**

**Possibly useful, but heavier and less embedded‑friendly**

| Attribute            | Rating                                         |
| -------------------- | ---------------------------------------------- |
| Maturity             | ⭐⭐⭐ (3)                                        |
| Rust-native fit      | 💡💡💡💡 (4)                                   |
| Embedded suitability | ⚠️ Too heavy for SBCs without GPU acceleration |
| WASM support         | ✅ Supported                                    |
| License fit          | ✅ MIT                                          |
| Declarative          | ✅                                              |

> Could work for **desktop apps**, but currently **not ideal for embedded** due to relatively heavy runtime and incomplete performance optimization.

---

### 5. **Tauri**

** Not a fit — uses web UI stack (HTML/JS)**

* You prefer pure Rust + WASM → this doesn’t align.
* Tauri is great if you're okay with JS/HTML frontends, but you've ruled that out for now.

---

## Toolkit-by-Use-Case Matrix

| Use Case / Toolkit         | Slint   | egui   | fltk-rs       | Iced     |
| -------------------------- | ------- | ------ | ------------- | -------- |
| Embedded GUI (Yocto)       | ✅ Best  | ❌      | ⚠️ Maybe      | ❌        |
| Desktop GUI (Low resource) | ✅ Good  | ✅ Good | ✅ Good        | ⚠️ Heavy |
| Web UI via WASM            | ⚠️ Some | ✅ Best | ❌             | ✅ OK     |
| Declarative UI             | ✅       | ❌      | ❌             | ✅        |
| Traditional UI             | ⚠️      | ❌      | ✅             | ❌        |
| Rust-native + Safe         | ✅       | ✅      | ⚠️ C bindings | ✅        |
| License (MIT/Apache OK)    | ❌ GPL   | ✅      | ✅             | ✅        |

---

## Recommendation (High Confidence)

For a **modern, embedded-to-desktop UI strategy with long-term viability in Rust**, I recommend:

###  **Primary Stack**

* **Slint** — For embedded GUI + desktop packaging (single binary, good Yocto support)
* **egui** — For fast development tools, profiling dashboards (desktop and WASM)

### Bonus (if needed)

* **fltk-rs** — For classic UI feel or where legacy desktop tool style is expected
* **Iced** — Watch for future improvements; not ideal now for embedded

---

Let me know if you'd like:

* Example project templates for Slint or egui
* WASM deployment workflow
* Yocto integration strategies for Rust GUI apps

------------------

# Learning Plan:

---

## Suggested Learning Plan (Expanded with Justified Additions)

### 0. **Toolchain & Environment Setup** *(Suggested Add-on)*

Before diving into GUI programming:

* Install Rust (stable + `wasm32-unknown-unknown` target)
* Setup for embedded cross-compilation if targeting Yocto/aarch64
* Familiarity with build tools: `cargo`, `cross`, `wasm-pack`, `trunk`, `cargo-generate`, etc.

> Optional: covers system setup, cross-compilation, and optimizing for deployment

---

### 1. **Fundamentals of GUI Programming with Rust**

* **Types of GUI paradigms**: Immediate-mode (egui), declarative (Slint/Iced), retained-mode (GTK)
* **Event loop models** in Rust: `tokio`, native threads, or internal loop control
* **Traits, ownership, and borrowing** in the context of GUI state handling
* **How GUI frameworks handle updates, drawing, and interaction**

> Goal: Understand how idiomatic Rust handles stateful, event-driven UI flows

---

### 2. **Using Slint with Rust: Concepts & Fundamentals**

* Declarative `.slint` language and its integration with Rust
* **Property bindings**, signals, slots, and model-based data flow
* Event handling and native rendering
* **Embedded optimization** techniques (e.g., static linking, OpenGL/GLES usage)
* Building and packaging for embedded devices (e.g., Yocto)

> Optional: How to strip down for size, and how to use Slint's CMake-free Rust-only mode

---

### 3. **Using egui with Rust: Concepts & Fundamentals**

* Immediate-mode UI model and how it maps to Rust's borrow checker
* Managing `App` state with struct lifetimes
* Integration with `eframe` (egui app runner)
* Persisting and loading data
* WASM + desktop dual-target development with shared logic

---

### 4. **WASM Fundamentals + Deployment Workflow**

* WASM in Rust (compilation, bindings, size optimization)
* Using `wasm-bindgen`, `wasm-pack`, or `trunk` for GUI projects
* Deploying egui or Slint in WASM (differences in support)
* Hosting: GitHub Pages, static file servers, embedded web servers
* Loading large data (profiling traces) into a WASM UI efficiently

---

## Optional Additions (If you want to go deeper)

### 5. **Security & Sandbox Considerations** (for WASM UIs)

* How WASM UIs handle sandboxed resources, local files, or backends

### 6. **Cross-Platform Distribution**

* AppImage, Flatpak, or other bundlers for Rust GUI desktop apps

---

## TL;DR – Your Path Looks Excellent

**You’ve got the right structure.** Just add:

* A setup phase (cross-compilation, WASM, packaging)
* A security/distribution phase if you're planning to ship and maintain apps

---

Would you like to start with **"1. Fundamentals of GUI Programming with Rust"** now? I can walk through the concepts, structure, and examples for idiomatic GUI app design in Rust.
----------------------------

# 1. Fundamentals of GUI Programming with Rust

This section gives you a foundational understanding of how GUI applications work in Rust, what programming paradigms are commonly used, and how Rust's language features influence GUI architecture.

---

## 1.1 What Is a GUI Program?

A **Graphical User Interface (GUI)** program allows user interaction via visual components — windows, buttons, sliders, etc.

### Core Concepts:

* **Event Loop**: Central loop that waits for user input (mouse, keyboard) and dispatches actions.
* **UI State**: Holds the current values of visible elements and logic behind them.
* **Rendering**: Drawing the visual interface (typically via GPU) based on UI state.
* **Callbacks / Signals / Events**: User interactions trigger these to update state.

---

## 1.2 GUI Paradigms in Rust

Rust GUI libraries generally fall into **three categories**:

### A. **Immediate-Mode GUI (e.g., egui)**

* UI is **reconstructed every frame** based on current state.
* Easy to reason about and write.
* Good for **tools, dashboards, games, visualizations**.

```rust
egui::CentralPanel::default().show(ctx, |ui| {
    if ui.button("Click me").clicked() {
        println!("Hello");
    }
});
```

> Pros: Simple, flexible, fast for prototyping
> Cons: Can get tricky for large or deeply stateful UIs

---

### B. **Declarative UI (e.g., Slint, Iced)**

* UI is defined **separately** (markup or Rust code) and reacts to state changes.
* Inspired by **Elm, React**, etc.
* Preferred for **structured, scalable apps**.

```rust
// Slint example
export component HelloWorldWindow := Window {
    Text { text: "Hello World"; }
}
```
> Pros: Clean structure, scales well
> Cons: Learning curve, sometimes limited by abstraction

---

### C. **Bindings to Retained-Mode Toolkits (e.g., gtk-rs, fltk-rs)**

* Traditional GUI model: UI is constructed once and updated imperatively.
* Feels like working in C++ or Java-style UIs.

```rust
let button = gtk::Button::with_label("Click me");
button.connect_clicked(move |_| {
    println!("Clicked");
});
```

> Pros: Mature and stable
> Cons: Verbose, less “Rusty”, potential FFI issues

---

## 1.3 Core Rust Concepts That Influence GUI Programming

### Ownership & Borrowing

Rust’s safety features can **conflict with traditional GUI patterns** that pass mutable state around.

Example:

* Can’t borrow mutable state across an event loop unless using `Rc<RefCell<T>>` or `Arc<Mutex<T>>` patterns.

```rust
let shared_state = Rc::new(RefCell::new(MyState::new()));
```

### Concurrency (Threads, `tokio`, async)

Many GUIs in Rust are **single-threaded** due to rendering constraints, but background work (e.g., file I/O, eBPF data collection) is done via threads or async tasks.

### Crate Ecosystem

You'll commonly use:

* `egui`, `iced`, `slint`, `gtk`, `fltk` – GUI toolkits
* `tokio`, `async-std` – async runtimes
* `serde`, `ron`, `bincode` – data serialization for state
* `wasm-bindgen`, `trunk`, `wasm-pack` – WASM builds

---

## 1.4 A Minimal Rust GUI Flow (Abstracted)

Regardless of the toolkit, a GUI app usually follows this high-level flow:

```text
+-------------------+
| Initialize system |
+-------------------+
          ↓
+-------------------------+
| Create GUI window/layout|
+-------------------------+
          ↓
+------------------------------+
| Setup state + event handlers|
+------------------------------+
          ↓
+----------------------+
| Enter event loop     |
|  - Wait for input    |
|  - Update state      |
|  - Redraw UI         |
+----------------------+
```

---

## 1.5 Practical Tips for Rust GUI Devs

* Use `Rc<RefCell<T>>` for shared, mutable state in single-threaded GUIs.
* Use `Arc<Mutex<T>>` or channels for multi-threaded/background processing.
* Structure your logic cleanly — separate core logic from UI.
* Prefer crates with **active development and community support**.
* Always measure **binary size** and **memory usage** early — especially on embedded targets.

---

## Recommended Before Next Step:

* Build and run a “Hello World” in 2–3 toolkits (e.g., Slint and egui)
* Practice passing state into the GUI and handling user input
* Explore how layout and rendering are handled in your toolkit of choice

---

### Up Next: **Using Slint with Rust — Concepts and Fundamentals**

Would you like me to continue with that?
-----------------------------

#  2. Using Slint with Rust: Concepts and Fundamentals

**Slint** is a modern, declarative GUI toolkit for Rust (and C++) with:

* First-class **embedded support**
* Declarative UI defined in `.slint` files
* Tight integration with Rust logic
* Support for desktop, embedded Linux, and WebAssembly (WASM)

It's an excellent choice for your use case (Desktop + Embedded with GPU, Yocto, Rust-only).

---

## 2.1 Slint Architecture at a Glance

```
┌───────────────────────────────┐
│        .slint UI files        │  ← Declarative UI
└────────────┬──────────────────┘
             ↓
┌───────────────────────────────┐
│      Slint Runtime Engine     │  ← Rendering, event loop
└────────────┬──────────────────┘
             ↓
┌───────────────────────────────┐
│        Rust Application       │  ← Logic + state management
└───────────────────────────────┘
```

---

## 2.2 Basic Project Structure

```
my_project/
├── Cargo.toml
├── build.rs
├── src/
│   ├── main.rs
│   └── my_ui.slint
```

### Add to `Cargo.toml`:

```toml
[dependencies]
slint = "1.5"

[build-dependencies]
slint-build = "1.5"
```

---

### `build.rs`:

Registers `.slint` files at build time:

```rust
fn main() {
    slint_build::compile("src/my_ui.slint").unwrap();
}
```
---

### `src/my_ui.slint` (UI):

```slint
export component MainWindow := Window {
    width: 300px;
    height: 200px;
    Text {
        text: "Hello, World!";
        vertical-alignment: center;
        horizontal-alignment: center;
    }
}
```

---

### `src/main.rs` (Rust logic):

```rust
slint::include_modules!();

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let app = MainWindow::new()?;
    app.run()?;
    Ok(())
}
```

---

## 2.3 Key Concepts in Slint

### Components

Defined in `.slint`, similar to React components or QML:

* `Window`: main application window
* `Text`, `Button`, `Slider`, etc.

### Properties

Bindable fields that can be read/written from Rust:

```slint
export component MainWindow := Window {
    in-out property <string> title: "My App";
}
```

Access in Rust:

```rust
let app = MainWindow::new()?;
app.set_title("New Title".into());
```

### Callbacks & Signals

React to UI actions:

```slint
Button {
    text: "Click me";
    clicked => { root.clicked_signal(); }
}

callback clicked_signal();
```

Rust:

```rust
app.on_clicked_signal(|| {
    println!("Button clicked!");
});
```

### Model Binding (Lists, Tables)

Slint supports list views with models for dynamic data:

* Bind Rust `Vec<T>` or `ModelRc<T>` into ListView

---

## 2.4 Desktop & Embedded Support

### 🖥️ Desktop

* Works with software renderer or OpenGL
* Cross-platform (Linux, macOS, Windows)

### Embedded

* Supports OpenGL ES, LinuxFB, DRM/KMS, and custom backends
* Slint can be built **without a windowing system**, suitable for Yocto
* Binary size ≈ 300–600 KB depending on features

> Slint officially supports **cross-compiling to aarch64** for embedded devices

---

## 2.5 Slint + Rust Advantages

| Feature                | Benefit                               |
| ---------------------- | ------------------------------------- |
| Declarative UI         | Clean separation of logic and layout  |
| Tight Rust integration | Strong type safety, easy data flow    |
| Embedded-ready         | OpenGL ES, no X11 required            |
| Dual targeting         | Build same app for desktop + embedded |
| WASM support           | Experimental but usable               |

---

## 2.6 Limitations to Know

* **GPLv3** for free version — you must open source your app
* WASM support is still **early** — not as stable as egui’s
* Some widgets/features may be limited compared to mature toolkits

---

## You’re Ready to:

* Define UIs in `.slint`
* Wire up business logic in Rust
* Build for x86\_64 or aarch64 (Yocto support is strong)
* Optionally explore WASM deployment

---

### Up Next: **3. Using egui with Rust – Concepts and Fundamentals**

Would you like to continue with that now?
---------------------------------

# 3. Using egui with Rust: Concepts and Fundamentals

**egui** (pronounced *“e-gui”*) is a **pure Rust**, immediate-mode GUI library that is:

* Extremely easy to get started with
* Great for desktop tools, dashboards, and profiling UIs
* Designed to be **cross-platform** and **WASM-friendly**
* License: **MIT / Apache-2.0** — fully open source and permissive

---

## 3.1 Immediate-Mode GUI: What Does That Mean?

Unlike traditional GUI frameworks that **retain UI state** in memory, egui **recomputes the entire UI every frame**.

Think of it like this:

> “Each frame, you describe what the UI should look like **right now**, based on the current state.”

This leads to:

* **Simpler logic**: No separate event handler code
* **More dynamic UIs**: You can update layout based on any state change
* **No layout memory bugs**: UI is re-rendered from scratch every frame

---

## 3.2 Getting Started with `eframe` (egui app wrapper)

**`eframe`** is the standard crate used to build egui apps.

### Add to `Cargo.toml`

```toml
[dependencies]
eframe = "0.27"
```

---

### Minimal `main.rs`

```rust
use eframe::egui;

fn main() -> Result<(), eframe::Error> {
    let options = eframe::NativeOptions::default();
    eframe::run_native(
        "Hello egui",
        options,
        Box::new(|_cc| Box::new(MyApp::default())),
    )
}

#[derive(Default)]
struct MyApp {
    counter: i32,
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("Hello, egui!");
            if ui.button("Increment").clicked() {
                self.counter += 1;
            }
            ui.label(format!("Counter: {}", self.counter));
        });
    }
}
```

> This creates a native window with a button and counter.

---

## 3.3 Core Concepts

### Widgets

Everything is a function call: `ui.button()`, `ui.label()`, `ui.checkbox()`, etc.

### State

You own and manage all state — no event handler bindings required.

```rust
if ui.button("Click").clicked() {
    self.do_something();
}
```

### Layout

egui automatically lays out widgets. You can control layout with `ui.horizontal()`, `ui.vertical()`, and `Grid`.

### Panels

* `CentralPanel`: main content
* `SidePanel`, `TopPanel`, `BottomPanel`: docking areas
* `Window`, `Popup`, `ContextMenu`: floating or modal content

---

## 3.4 Pros and Cons of egui

| Pros                          | Cons                                                  |
| ------------------------------- | ------------------------------------------------------- |
| Extremely fast to prototype     | Not suited for deeply complex UIs                       |
| Cross-platform & WASM-ready     | UI rebuild every frame (can be inefficient in huge UIs) |
| Simple, ergonomic API           | No native look-and-feel                                 |
| Fully in Rust, no C bindings    | Immediate mode can feel alien at first                  |
| Great for devtools + dashboards | Less ideal for traditional form-based apps              |

---

## 3.5 WASM Support

egui has **excellent WASM support** using:

* [`trunk`](https://trunkrs.dev/) – Rust-native bundler for WebAssembly
* Or [`wasm-bindgen`](https://rustwasm.github.io/docs/wasm-bindgen/) + `wasm-pack` (more manual)

We’ll cover this in full detail in the **next section (WASM deployment workflow)**.

---

## 3.6 egui Ecosystem Extras

* `egui_extras`: tables, file pickers, etc.
* `eframe`: handles window creation, persistence, and native/WASM dual-target
* `eframe-template`: GitHub starter template for egui + WASM projects

---

## 📌 Summary: When to Use egui

| Use Case                      | Suitability                |
| ----------------------------- | -------------------------- |
| Embedded Linux                | ❌ Not ideal                |
| Desktop profiling dashboard   | ✅ Excellent                |
| WASM (web frontend for data)  | ✅ Best fit                 |
| Interactive tools & utilities | ✅ Great                    |
| Declarative layout            | ❌ No (immediate mode only) |

---

### Up Next: **4. WASM Fundamentals + Deployment Workflow (with egui & Slint)**
--------------------------------------------

# 4. WASM Fundamentals + Deployment Workflow (egui & Slint)

You want to build **web apps** in Rust (e.g., for visualizing eBPF profiling data) — and **WASM** (WebAssembly) is the best path forward for this. Both **egui** and **Slint** support WASM to varying degrees.

This section covers:

1. What WASM is & how Rust compiles to it
2. Project setup & build tools (`trunk`, `wasm-pack`, etc.)
3. egui WASM deployment
4. Slint WASM caveats
5. Deployment options (static hosting, embedded server, etc.)

---

## 4.1 What is WebAssembly (WASM)?

**WebAssembly** is a binary format that runs at near-native speed in web browsers.

> Think of it as compiling Rust code into a format the browser can execute — **without JavaScript**.

* Safe & sandboxed
* Supported by all modern browsers
* Great for GUI apps with shared logic across desktop & web

---

## 4.2 Building for WASM in Rust

You need the right **target** and **tooling**.

### Install the WASM target:

```sh
rustup target add wasm32-unknown-unknown
```

---

## 4.3 Tools for WASM GUI Projects

### `trunk` (Recommended for egui)

* Zero-config web bundler for Rust + WASM
* Handles HTML, CSS, JS, WASM in one build step

```sh
cargo install trunk
```

---

## 4.4 egui: WASM Project Template & Workflow

egui has first-class WASM support via [`eframe`](https://github.com/emilk/egui/tree/master/crates/eframe).

### Create Project

Use the starter template (from GitHub):

```sh
cargo generate --git https://github.com/emilk/eframe-template
cd eframe-template
```

Or create manually:

### ➕ Add to `Cargo.toml`:

```toml
[dependencies]
eframe = "0.27"

[lib]
crate-type = ["cdylib"]

[profile.release]
opt-level = "z"
lto = true
```

---

### 📄 `index.html`:

Create this in root:

```html
<!DOCTYPE html>
<html>
  <head><meta charset="utf-8"><title>egui app</title></head>
  <body>
    <canvas id="the_canvas_id"></canvas>
    <script type="module">import init from "./pkg/your_project.js"; init();</script>
  </body>
</html>
```

---

### Build and Serve:

```sh
trunk serve --release
```

Then open [http://127.0.0.1:8080](http://127.0.0.1:8080)

> You now have a Rust + egui app running in the browser.

---

##  4.5 Slint and WASM: Current State

Slint supports WASM via WebGL rendering but **has caveats**:

| Limitation           | Status                                                  |
| -------------------- | ------------------------------------------------------- |
| Rendering            | WebGL (needs browser GPU support)                       |
| Touch support        | ✅ Good                                                  |
| Dynamic data updates | ✅ via Rust bindings                                     |
| App size             | ⚠️ \~1MB+ after optimizations                           |
| Interop with JS/HTML | ⚠️ Limited compared to JS libraries                     |
| Status (Aug 2025)    | **Usable, but not production-mature** for all scenarios |

> 🛠️ Slint WASM is **best for simple UI views or embedded web GUIs**, but **egui is preferred for complex WASM dashboards** today.

---

## 4.6 Deployment Options

### GitHub Pages

Perfect for open-source:

```sh
trunk build --release
# Push /dist/ to gh-pages branch
```

### Static Hosting

Any static file server (Nginx, Netlify, Vercel, etc.) works.

### 🔧 Embedded HTTP Server

Bundle the WASM + HTML into your app using `include_bytes!` or embed static files using crates like:

* [`rust-embed`](https://crates.io/crates/rust-embed)
* \[`axum` + `tower_http::ServeDir`]

> Great for a single binary that serves a GUI dashboard.

---

## 🧠 Final Thoughts on Rust + WASM GUI

| Feature                | egui                 | Slint                       |
| ---------------------- | -------------------- | --------------------------- |
| WASM Maturity          | ✅ Excellent          | ⚠️ Usable, still evolving   |
| Dashboard UI           | ✅ Ideal              | ⚠️ May be heavy or overkill |
| Embedded UI in browser | ✅ Good               | ✅ Fits simple use cases     |
| Web deployment         | ✅ Trunk or wasm-pack | ⚠️ Manual setup             |

---

## ✅ You're Ready To:

* Build and deploy egui web apps for profiling dashboards
* Experiment with Slint for web if you're already using it on embedded
* Use `trunk`, `wasm-bindgen`, and static hosting tools

---

### Would you like a **template project** next for:

* [ ] egui desktop + WASM dual-target?
* [ ] Slint with embedded build setup (Yocto)?
* [ ] Something else?

Let me know what you'd like to see next.

Want to proceed?
