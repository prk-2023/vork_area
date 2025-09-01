
# Trace syscall events
./trace_pipe syscalls sys_enter_openat sys_exit_openat

# Trace scheduler events
./trace_pipe sched sched_switch sched_wakeup

# Trace memory events
./trace_pipe maple_tree ma_read ma_write



-------------------

Generalizing your trace_point monitoring tool to accept both **subsystem** and **event name** makes it more 
powerful and usable across all tracepoints, not just `syscalls`.

---

## What you want:

Update the CLI so users can run the program like this:

```bash
./trace_pipe maple_tree ma_write ma_read
./trace_pipe sched sched_switch
./trace_pipe syscalls sys_enter_openat sys_exit_openat
```

That is:

* The **first argument** is the **subsystem** (e.g., `syscalls`, `sched`, `maple_tree`)
* The **remaining arguments** are **event names** from that subsystem

---

## Changes to make:

### 1. Update CLI struct

* Take `subsystem` as a separate argument
* Take `events` as a `Vec<String>`

### 2. Change `enable_tracepoint` and `disable_tracepoint` to include the subsystem path

---

## Updated `src/main.rs`

```rust
use clap::Parser;
use colored::*;
use ctrlc;
use std::{
    fs::{self, File},
    io::{self, BufRead, BufReader},
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};

// Automatically generate argument parsing
#[derive(Parser, Debug)]
#[command(author, version, about = "Tracepoint monitor using tracefs")]
struct Args {
    /// Subsystem name (e.g., syscalls, sched, maple_tree)
    subsystem: String,

    /// List of trace events to enable (e.g., sys_enter_open, ma_write)
    events: Vec<String>,
}

const TRACEFS_BASE: &str = "/sys/kernel/debug/tracing";

fn enable_tracepoint(subsystem: &str, event: &str) -> io::Result<()> {
    let path = format!("{TRACEFS_BASE}/events/{subsystem}/{event}/enable");
    fs::write(path, "1")?;
    Ok(())
}

fn disable_tracepoint(subsystem: &str, event: &str) -> io::Result<()> {
    let path = format!("{TRACEFS_BASE}/events/{subsystem}/{event}/enable");
    fs::write(path, "0")?;
    Ok(())
}

fn main() -> io::Result<()> {
    let args = Args::parse();

    if args.events.is_empty() {
        eprintln!(
            "{}",
            "No trace events provided. Example: ./program syscalls sys_enter_open sys_enter_read".red()
        );
        std::process::exit(1);
    }

    // Check access to tracefs
    if !PathBuf::from(TRACEFS_BASE).exists() {
        eprintln!(
            "{}",
            "tracefs is not mounted or accessible. Is debugfs mounted?".red()
        );
        std::process::exit(1);
    }

    // Enable tracepoints
    for event in &args.events {
        enable_tracepoint(&args.subsystem, event).map_err(|e| {
            eprintln!(
                "{} {}:{}",
                "Failed to enable tracepoint:".red(),
                &args.subsystem,
                event
            );
            e
        })?;
        println!("{} {}:{}", "Enabled tracepoint:".green(), &args.subsystem, event);
    }

    let running = Arc::new(AtomicBool::new(true));
    let subsystem = args.subsystem.clone();
    let events_arc = Arc::new(args.events.clone());

    // Setup Ctrl+C handler
    let r = running.clone();
    let ev_clone = events_arc.clone();
    let sub_clone = subsystem.clone();
    ctrlc::set_handler(move || {
        eprintln!("{}", "\nCaught signal, cleaning up...".yellow());
        for event in ev_clone.iter() {
            let _ = disable_tracepoint(&sub_clone, event);
        }
        r.store(false, Ordering::SeqCst);
    })
    .expect("Error setting Ctrl-C handler");

    // Open trace_pipe
    let trace_pipe = File::open(format!("{TRACEFS_BASE}/trace_pipe"))?;
    let mut reader = BufReader::new(trace_pipe);

    println!("{}", "Listening to trace_pipe...".blue());

    loop {
        if !running.load(Ordering::SeqCst) {
            break;
        }

        let mut line = String::new();
        match reader.read_line(&mut line) {
            Ok(0) => break, // End of file
            Ok(_) => {
                print!("{}", line.cyan());
            }
            Err(e) => {
                if e.kind() == io::ErrorKind::Interrupted {
                    continue;
                } else {
                    return Err(e);
                }
            }
        }
    }

    // Cleanup on normal exit
    println!("{}", "Program terminated gracefully.".green());

    Ok(())
}
```

---

## Usage Examples

```bash
# Trace syscall events
./trace_pipe syscalls sys_enter_openat sys_exit_openat

# Trace scheduler events
./trace_pipe sched sched_switch sched_wakeup

# Trace memory events
./trace_pipe maple_tree ma_read ma_write
```

---

Next example trace_point3 :

* Auto-discovery of valid events
* Filtering by PID or command
* Output to file instead of stdout

This version is now **generic and reusable** for any trace event.
