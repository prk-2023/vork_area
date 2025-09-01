use clap::Parser;
use colored::*;
use ctrlc;
use std::{
    fs::{self, File},
    io::{self, BufRead, BufReader, Write},
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};

#[derive(Parser, Debug)]
#[command(author, version, about = "Tracepoint monitor using tracefs")]
struct Args {
    /// Subsystem name (e.g., syscalls, sched, maple_tree)
    #[arg()]
    subsystem: Option<String>,

    /// Trace events to monitor (e.g., sys_enter_open, sched_switch)
    #[arg()]
    events: Vec<String>,

    /// List available events in a subsystem and exit
    #[arg(long)]
    list: Option<String>,

    /// Optional PID filter (only show events from this PID)
    #[arg(long)]
    pid: Option<u32>,
}

const TRACEFS_BASE: &str = "/sys/kernel/debug/tracing";

fn list_events(subsystem: &str) -> io::Result<()> {
    let path = format!("{TRACEFS_BASE}/events/{subsystem}");
    let entries = fs::read_dir(&path)?;

    println!("Available events in subsystem '{}':", subsystem);
    for entry in entries {
        let entry = entry?;
        if entry.file_type()?.is_dir() {
            if let Some(name) = entry.file_name().to_str() {
                println!("  {}", name);
            }
        }
    }

    Ok(())
}

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

fn apply_pid_filter(pid: u32) -> io::Result<()> {
    let path = format!("{TRACEFS_BASE}/set_ftrace_pid");
    let mut file = File::create(path)?;
    writeln!(file, "{}", pid)?;
    println!("{} {}", "Applied PID filter for:".blue(), pid);
    Ok(())
}

fn main() -> io::Result<()> {
    let args = Args::parse();

    // List mode
    if let Some(subsystem) = args.list.as_deref() {
        return list_events(subsystem);
    }

    let subsystem = args.subsystem.as_deref().unwrap_or("");
    if subsystem.is_empty() || args.events.is_empty() {
        eprintln!(
            "{}",
            "Usage: ./trace_pipe <subsystem> <event1> <event2> ...
Use --list <subsystem> to see available events."
                .red()
        );
        std::process::exit(1);
    }

    if !PathBuf::from(TRACEFS_BASE).exists() {
        eprintln!(
            "{}",
            "tracefs is not mounted or accessible. Is debugfs mounted?".red()
        );
        std::process::exit(1);
    }

    // Optional PID filter
    if let Some(pid) = args.pid {
        apply_pid_filter(pid)?;
    }

    for event in &args.events {
        enable_tracepoint(subsystem, event).map_err(|e| {
            eprintln!(
                "{} {}:{}",
                "Failed to enable tracepoint:".red(),
                subsystem,
                event
            );
            e
        })?;
        println!("{} {}:{}", "Enabled tracepoint:".green(), subsystem, event);
    }

    let running = Arc::new(AtomicBool::new(true));
    let subsystem = subsystem.to_string();
    let events_arc = Arc::new(args.events.clone());

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

    let trace_pipe = File::open(format!("{TRACEFS_BASE}/trace_pipe"))?;
    let mut reader = BufReader::new(trace_pipe);

    println!("{}", "Listening to trace_pipe...".blue());

    loop {
        if !running.load(Ordering::SeqCst) {
            break;
        }

        let mut line = String::new();
        match reader.read_line(&mut line) {
            Ok(0) => break,
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

    println!("{}", "Program terminated gracefully.".green());

    Ok(())
}
