# GUI Programming with Rust:

Rust can be used to write **several types/classes of GUI programs**, depending on factors like architecture, rendering method, platform target, and external libraries. 

There’s no *fixed* number of GUI "classes" in Rust, but we can break it down into broad **categories** or **types** based on:

---

### 1. **Native GUI Wrappers**

These use native platform APIs (like WinAPI on Windows, Cocoa on macOS):

* **Examples**:

  * [`druid`](https://github.com/linebender/druid)
  * [`native-windows-gui`](https://github.com/gabdube/native-windows-gui)
  * [`azul`](https://github.com/fschutt/azul)

==> *Best for lightweight, OS-native feel.*

---

### 2. **Cross-Platform Abstractions**

Provide consistent UI across platforms, abstracting over OS differences.

* **Examples**:

  * [`egui`](https://github.com/emilk/egui)
  * [`iced`](https://github.com/iced-rs/iced)
  * [`slint`](https://github.com/slint-ui/slint)

==> *Good for building apps that look and behave the same everywhere.*

---

### 3. **Web-Based GUIs (WASM)**

Use Rust + WebAssembly to create GUI apps running in browsers.

* **Examples**:

  * [`Yew`](https://yew.rs/)
  * [`Leptos`](https://github.com/leptos-rs/leptos)
  * [`Sycamore`](https://github.com/sycamore-rs/sycamore)

==> *Useful for SPAs, dashboards, and front-end web apps.*

---

### 4. **Game Engine GUIs / Immediate Mode GUIs**

Mainly for games or simulations, often using OpenGL/Vulkan backends.

* **Examples**:

  * [`bevy`](https://bevyengine.org/) (game engine with UI)
  * [`imgui-rs`](https://github.com/imgui-rs/imgui-rs)

==> *Ideal for tooling, debugging UIs, and in-game interfaces.*

---

### 5. **Embedded GUI Development**

Targeting microcontrollers or low-power devices.

* **Examples**:

  * [`embedded-graphics`](https://github.com/embedded-graphics/embedded-graphics)
  * \[`slint` embedded support)

==> *Suited for IoT devices, displays, and appliances.*

---

### Summary Table

| Class/Type           | Description                               | Example Crates          |
| -------------------- | ----------------------------------------- | ----------------------- |
| Native GUI           | Wraps platform-native APIs                | `native-windows-gui`    |
| Cross-platform GUI   | Abstracts platform differences            | `iced`, `egui`, `slint` |
| Web-based GUI (WASM) | GUI in the browser via WebAssembly        | `Yew`, `Leptos`         |
| Game/UI Frameworks   | For games & real-time UIs                 | `bevy`, `imgui-rs`      |
| Embedded GUIs        | For low-level devices or microcontrollers | `embedded-graphics`     |

---

### Conclusion

There isn’t a fixed *number* of GUI program types, but Rust supports **at least 5 major categories**, each with different use-cases and libraries. 

The ecosystem is rapidly growing, with more cross-platform and web-focused tools emerging.

---

### Additinal Info:

Rendering: This factor does play a significant role in determining the computational resource required from the host CPU to support graphics in a GUI program, it's not the sole deciding factor where other factors like **architecture of the GUI programs, the platform target and the specific external libraries used, also contribute significantly to the overall resource consumption:

Factors Affecting CPU resource usage in GUIs:

- SW Rendering : CPU is responsible to draw out every single pixel on the screen, ==> naturally demand higher CPU resource. ( only advantage is cross platform ).

- HW Accelerated Rendering (GPU Based): GPU to offload graphical computation from CPU. GPUs are specialized for parallel processing of visual data. While CPU is still involved in setting up commands for the GPU and manage the scene graph, heavy lifting of drawing pixels on screen is done by the GPU, leading to lower CPU utilization for rendering itself. This is often achieved thorough APIs like OpenGL, DirectX or Valkan.

- GUI Architecture: (Immediate Mode vs Retained Mode)
    1. Immediate Mode GUIs: Redraws the entire UI every frame.
       Simple to implement but can be CPU intensive if not optimized.
    2. Retained Mode GUIs: Maintain a "scene graph" or a hierarchy of UI elements. 
       When an element changes only that element needs to be redrawn, i.e intelligently manages updates resulting in more efficient CPU usage.

- Event Handling and Layout Management:
    - Complexity of event processing ( mouse(movement, clicks), keyboard (inputs)) and layout calculations how elements are arranged on screen directly imact CPU usage.

- Platform Target:
    - Native toolkits: 
        win32 API   : microsoft
        Cocoa       : macOS
        GTK/QT      : Linux 

    - Web-based GUIs: ( Electron, Tauri ):
        These rely on rendering engines like Chromium, which are powerful but can be resource-intensive due to overhead of running full blown web-browser env.

- External Libs/Frameworks:
    - The choice of Rust GUI library ( Druid, iced, GTK-RS, QT-RS) significantly impact resource usage.  Each library has its own design philosophy, rendering backend (software vs. GPU), and level of optimization. Some are designed for high performance and low resource consumption, while others might prioritize ease of use or a specific programming paradigm.
    - Additional libraries for animations, data processing or complex visual effect will also contribute to the over all CPU load.

### Design Selection of GUI type:

The choice of GUI in Rust—or any language, really—depends on a mix of:

* **Rendering method:** native widgets vs custom drawing vs web-based rendering
* **Target platform:** Windows, macOS, Linux, web (WASM), embedded devices
* **GUI architecture:** immediate mode vs retained mode, declarative vs imperative
* **Event handling model:** how input/events are processed (e.g., callback-based, reactive streams)
* **External libraries/frameworks:** maturity, ecosystem, community support, and your project's specific needs

By blending these factors, you pick the right tool for the job, balancing performance, developer productivity, and user experience.



## Example :

---

### Context:

* **Platform:** IoT / edge / embedded (resource-constrained, possibly no OS or limited OS)
* **App:** Profiling tool using **Rust Aya** (eBPF for tracing/profiling on Linux-based systems)
* **Requirement:** Display profiling results (likely on a small screen or via remote UI)

---

### Key Considerations for GUI Design:

1. **Platform Constraints**

   * Embedded or edge devices often have limited CPU, memory, and possibly no GPU acceleration.
   * Display might be small (e.g., LCD/OLED) or absent, or you might output to a remote UI.

2. **Rendering Method**

   * Native UI frameworks may be limited or unavailable.
   * Custom lightweight rendering or simple graphical output may be needed.

3. **Target Display Mode**

   * Local UI on device screen
   * Remote UI on desktop/browser (e.g., via web or networked app)

4. **Event Handling**

   * Minimal, likely focused on periodic updates rather than complex user interaction.

5. **External Dependencies**

   * Minimize dependencies for embedded environments.
   * Possibly use no\_std or minimal std environment.

---

### Recommended Approach:

#### **If the device has a local display:**

* Use **`embedded-graphics`** for lightweight 2D graphics on embedded screens.

  * This crate supports drawing basic shapes, text, and images on a variety of embedded displays.
  * Low resource footprint, no OS dependency.

* Combine with **`slint`** if the device supports it for slightly richer UI, but it depends on platform capabilities.

* Profiling results could be summarized in charts, graphs, or simple text displays.

---

#### **If the device is headless but you want remote UI:**

* Expose profiling data over the network (e.g., REST API or WebSocket).

* Use a **WebAssembly (WASM)** frontend written in Rust (e.g., **Yew** or **Leptos**) for the remote browser UI.

  * This decouples the heavy UI rendering from the constrained device.

* Alternatively, create a **cross-platform GUI desktop app** (e.g., using `iced`) that connects remotely to the device to fetch and display data.

---

### Summary Flowchart

| Scenario                             | Suggested GUI Approach                                             | Reason                          |
| ------------------------------------ | ------------------------------------------------------------------ | ------------------------------- |
| Embedded device with local display   | `embedded-graphics` or `slint`                                     | Lightweight, minimal deps       |
| Headless embedded device + remote UI | Rust WASM (`Yew`, `Leptos`) web app or cross-platform GUI (`iced`) | Offloads rendering, flexible UI |

---

### Extra Notes:

* For **Aya**, profiling data collection is separate from GUI; focus on clean data serialization to feed your chosen UI.
* Optimize for performance and low resource use on embedded side; heavy UI logic is better offloaded when possible.

---

## Sketch out a minimal example for a remote web-based UI.

Here’s a **minimal sketch** for a remote web-based UI in Rust using **Aya** for profiling on the backend, and **Yew** for the frontend web UI.

---

### Overview:

* **Backend:** Rust app with Aya collects profiling data, exposes it via a REST API.
* **Frontend:** Yew app fetches this data and displays it in the browser.

---

### Step 1: Backend - Expose Profiling Data via REST API

