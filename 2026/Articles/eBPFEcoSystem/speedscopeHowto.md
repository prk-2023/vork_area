# Echosystem for eBPF:

This document covers :
Technologies of profiling, tracing, eBPF, Security, XDP profiling, visualization .. All come in a domain of
"Observability, Networking and Security" Generally they fall under eBPF/perf ecosystem. 

## Visualization: 


### 1. Speedscope

* [speedscope.app](www.speedscope.app):
    Its a fast, interactive, web-based tool for viewing and analyzing performance profiles. 
    The source code is open-sourced and available on GitHub under the repository jlfwong/speedscope.

* https://github.com/jlfwong/speedscope

It help developers visualize and navigate large profiling datasets (like CPU or memory usage) through 
interactive flamegraphs. 

Its main appeal is its language-agnostic and runs entires on the browser, this means the data does not leave
your machine. 

- Key Features :

* **Fast & Interactive:** 
    Handles massive profiles (100MB+) smoothly at 60fps. You can zoom, pan, and search with keyboard 
    shortcuts.

* **Three Powerful Views:**

1. **🕰 Time Order:** 

    Visualizes call stacks chronologically. 
    Great for seeing the sequence of events (e.g., "first it fetched data, then it parsed JSON").

2. **⬅️ Left Heavy:** Groups identical stacks together and sorts them by total time. 
   This is the classic "flamegraph" view used to find performance bottlenecks.
   
3. **🥪 Sandwich:** 
    A table view of all functions. 
    Clicking a function shows a "sandwich" of its callers and callees, making it easy to see *why* a 
    specific function was called.

* **Privacy-Focused:** 
    It is a single-page application (SPA). 
    When you "upload" a file to [speedscope.app](https://www.speedscope.app), it is processed locally in 
    your browser; no data is sent to a server.

---

- Supported Formats & Languages

Speedscope is incredibly versatile and supports imports from:

* **JavaScript:** Chrome DevTools, Firefox, Node.js, and Safari.
* **Python:** `py-spy`, `pyinstrument`.
* **Ruby:** `stackprof`, `rbspy`.
* **Go:** `pprof`.
* **Native/Systems:** Linux `perf`, macOS `Instruments.app`.
* **Custom:** 
    It has a well-documented 
    [JSON schema](https://github.com/jlfwong/speedscope/wiki/Importing-from-custom-sources) 
    so you can write your own exporters.

=> For more: [speedscopeHowto.md](./speedscopeHowto.md)

- 📖 How to Use It
1. **Web:** Visit [speedscope.app](https://www.speedscope.app) and drag-and-drop your profile file 
   (e.g., `.cpuprofile`, `.json`, `.perf`).
2. **CLI:** You can install it locally via npm to open files directly from your terminal:
```bash
npm install -g speedscope
speedscope path/to/profile.json

```


3. **VS Code:** 
    There is a 
    [Speedscope extension](https://marketplace.visualstudio.com/items?itemName=evg656e.speedscope) 
    that lets you view profiles and jump directly to the source code from the flamegraph.


- How to generate a profile for a specific language (like Python, rust ) that you can use with speedscope?

Generate profiles for Python and Rust is straightforward because both ecosystems have mature sampling 
profilers that can export directly to the `.json` format used by **speedscope**.

* For Python: Using `py-spy`:
    - `py-spy` is the tool for Python. It is a sampling profiler that doesn't require you to modify your 
      code or even restart your running program:
      
      1. Install py-spy `pip install py-spy`

      2. To Generate the Profile : Run your script through `py-spy` and specify the `speedscope` format.

      ```bash
      # Record a new process until it finishes
      $ py-spy record --format speedscope -o profile.json -- python my_script.py
      # OR: Attach to an already running process by PID
      py-spy record --pid 12345 --format speedscope -o profile.json
      ```

      > **Tip:** If your Python script uses C-extensions (like NumPy or Pandas), add the `--native` flag to 
        see the native call stack as well.
    
* For Rust: Using `cargo-flamegraph` or `pprof` :
    - `cargo-flamegraph` is the standard for Rust, it usually outputs `.svg`. 
      To get a speedscope-compatible file, the cleanest way is to use the `pprof` crate or convert a `perf` 
      script.

    - **Option A**: Using `cargo-flamegraph` (Manual Conversion)

    - `cargo-flamegraph` uses `perf` (Linux) or `dtrace` (macOS) under the hood:
    
      1. **Install:** `cargo install flamegraph`
      2. **Generate:** `cargo flamegraph --bin my_app`
      3. **Convert:** Since `cargo-flamegraph` outputs a collapsed stack file (usually `flamegraph.txt` or 
         similar in the background), you can often pipe that directly into the speedscope CLI.


    - **Option B**: Using `pprof` crate (Programmatic)

      This is the most "Speedscope-native" way for Rust. 
      It allows your app to profile itself and export the exact JSON format needed.


      1. **Add to `Cargo.toml`:**
      ```toml
      [dependencies]
      pprof = { version = "0.13", features = ["flamegraph"] }
      ```

      2. **Add to `main.rs`:**
      ```rust
      fn main() {
        let guard = pprof::ProfilerGuard::new(100).unwrap();
        // ... your code ...
        if let Ok(report) = guard.report().build() {
                let file = std::fs::File::create("profile.json").unwrap();
        report.flamegraph_speedscope(file).unwrap();
        };
      }
      ```

- **How to View the Result**

Once you have your `profile.json` from either language:

1. Go to **[speedscope.app](https://www.speedscope.app/)**.
2. Drag and drop your `profile.json` file.
3. Switch to the **"Left Heavy"** tab to see the total time spent in each function.


#### Low-level Performance analysis using with Linux :

- On Linux systems, **speedscope** is an excellent companion for low-level performance analysis because it 
  can ingest the raw output of kernel-level tools like `perf` and eBPF-based profilers.

1. Using with Linux `perf`: 
    - `perf` is the standard tool for hardware-level profiling. 
    - Speedscope cannot read the binary `perf.data` file directly, so you must convert it to a 
      "collapsed stack" or "script" format.

**Record data:** 

    ```bash 
    # Profile at 99Hz to avoid lockstep with timer interrupts
    perf record -F 99 -a -g -- sleep 60
    ```
    - `-a`: system wide profiling
    - `-F 99`: sample at 999 Hz frequency (a high frequency for detailed data).
    - `-g`: record call graphs (stack traces).
    - `-- sleep 60`: runs for 60 seconds, replace sleep 60 with your command to profile a specific app.

    - This generates the `perf` data file `perf.data`


**Export to script format:** 
    ```bash
    $ perf script -i perf.data > profile-linux-out-perf.txt 
    ```

**Visualize:** 
    - open browser ( go to => https:://speedscope.app) 

    - Drag `profile-linux-out-perf.txt` or out.perf` directly into speedscope. 
    It will parse the text and reconstruct the flamegraph.


2. Using with eBPF (bcc/bpftrace)

eBPF allows for extremely low-overhead profiling with deep visibility into kernel and user-space 
interactions, these often produce data in a **folder stack** format or a format that can be converted to 
the speedscope JSON format. 

The most common tool for this is `profile` from the **bcc** toolkit.

- **Record and collapse stacks:**
 ```bash
 #Capture user and kernel stacks for 30 seconds at 49Hz
 sudo /usr/share/bcc/tools/profile -F 49 -df 30 > out.folded
 ```
- **Visualize:** Speedscope supports the "folded" format generated by bcc. Simply upload `out.folded`.

- Many modern eBPF tools (like py-spy for Python or integrated solutions like Grafana Alloy) provide direct
  output options for the speedscope format (a specific JSON file).

- For custom eBPF scripts, you may need a post-processing script to format the output into a "folded stack" 
  or the speedscope JSON specification.

- Format the output (if necessary): 
    Ensure the output is in a format speedscope supports. 
    The "folded stack" format (lines of stack;trace;goes;here count) is common and easily readable by tools 
    that then generate the final file.

- Visualize in speedscope: 
    Similar to the perf method, load the generated file (often a .speedscope.json or .txt file) into the 
    speedscope web interface via drag-and-drop or by browsing for the fil

3. The "Sandwich" View

    While the Flamegraph (Left Heavy) helps you see the big picture, the **Sandwich View** is arguably 
    speedscope's most powerful feature for surgical performance tuning. 
    It solves the problem of "fragmented time," where a single utility function (like a JSON parser or 
    string formatter) is called from 50 different places and doesn't look significant in any one flamegraph
    branch.

4. How it works:

* **Total Time:** 
    How much time was spent in this function AND everything it called.
* **Self Time:** 
    How much time was spent *exactly* in this function's code (excluding children).
* **The "Sandwich":** 
    When you click a function, the top list shows its **Callers** (who called it) and the bottom list shows 
    its **Callees** (what it called).

#### How to interpret the **"Sandwich"** view in speedscope to find specific bottlenecks?

The **Sandwich View** is where you go when the `Flamegraph` feels too "busy" to give you a straight answer. 
It acts like a pivot table for your performance data, aggregating all the time spent in a specific function 
regardless of where it was called.

1. Identify the "Heavy Lifters" (Self Time)

Start by sorting the table by **Self Time**.

* **What it means:** 
    High Self Time indicates a function that is doing heavy computation internally 
    (e.g., a complex math loop, data transformation, or a regex).

* **The Fix:** 
    You need to optimize the **logic inside this specific function**.

2. Identify the "Expensive Middlemen" (Total Time)

Sort the table by **Total Time**.

* **What it means:** 
    These functions might not do much work themselves, but they are responsible for triggering a massive 
    tree of expensive operations below them.

* **The Fix:** 
    You need to look at the **Callees** (the bottom half of the sandwich) to see which child is dragging 
    it down, or consider **caching** the result of this function so it doesn't have to run as often.

3. Analyze the "Bread" of the Sandwich

Once you click a function, the view splits into three sections. This is how you "read" the bottleneck:

- **Top Section: The Callers (Who is responsible?)**

If you find a utility function like `calculate_hash()` taking up 20% of your CPU, look here.

* If **one caller** is responsible for 90% of those calls, you have a specific module that is being inefficient.
* If the time is **evenly split** across 50 different callers, you have a "death by a thousand cuts" 
  scenario where the function itself needs to be faster.

- **Bottom Section: The Callees (Where is the time going?)**

This shows you what this function spends its time doing.

* If you are looking at your `main()` function, the callees list basically tells you which high-level 
  features of your app are the most expensive.

4. Navigating Back and Forth
    The most effective way to use this is to **double-click** a function in the Callees list. 
    This "pivots" the view, making that child function the new center of the sandwich. 
    This allows you to follow the "trail of heat" down the call stack until you hit the function where 
    **Total Time ≈ Self Time**. That is your bottleneck.

5. Summary Table for Quick Diagnosis

| If you see... | It usually means... | Action Item |
| --- | --- | --- |
| **High Self Time** | The function is a "leaf" doing hard work. | Optimize the code inside. |
| **High Total, Low Self** | The function is a "branch" calling others. | Look at the Callees list. |
| **High Call Count** | The function is being "spammed." | Implement caching or memoization. |
