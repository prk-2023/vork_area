# Echosystem for eBPF:

This document covers :
Technologies of profiling, tracing, eBPF, Security, XDP profiling, visualization .. All come in a domain of
"Observability, Networking and Security" Generally they fall under eBPF/perf ecosystem. 

## Visualization: 

### 0. Folder Stack format:

    The **Folded Stack** format is the universal "lingua franca" of profiling. 
    It was popularized by Brendan Gregg (the inventor of Flame Graphs) specifically to take the messy, 
    multi-line output of tools like eBPF, `perf`, and `dtrace` and turn them into something a computer can 
    easily parse and visualize.

=> More @ [FolderStack log format](./eBPFEcoSystem/FolderStack.md)

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

=> For more: [speedscopeHowto.md](./eBPFEcoSystem/speedscopeHowto.md)
