//----------------------------------------------
//
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

//This macro automatically generates the argument parsing logic.
#[derive(Parser, Debug)]
//Container attribute that defines top-level properties like the author, version, and a brief description.
#[command(author, version, about = "Tracepoint monitor using tracefs")]
struct Args {
    // List of tracepoints to enable (ex: sys_enter_open )
    tracepoints: Vec<String>,
}

const TRACEFS_BASE: &str = "/sys/kernel/debug/tracing";

fn enable_tracepoint(tp: &str) -> io::Result<()> {
    let path = format!("{TRACEFS_BASE}/events/syscalls/{tp}/enable");
    fs::write(path, "1")?;
    Ok(())
}

fn disable_tracepoint(tp: &str) -> io::Result<()> {
    let path = format!("{TRACEFS_BASE}/events/syscalls/{tp}/enable");
    fs::write(path, "0")?;
    Ok(())
}

fn main() -> io::Result<()> {
    let args = Args::parse();

    if args.tracepoints.is_empty() {
        eprintln!(
            "{}",
            "No tracepoints provided. Example: ./program sys_enter_open sys_enter_read".red()
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
    for tp in &args.tracepoints {
        enable_tracepoint(tp).map_err(|e| {
            eprintln!("{} {}", "Failed to enable tracepoint:".red(), tp);
            e
        })?;
        println!("{} {}", "Enabled tracepoint:".green(), tp);
    }

    let running = Arc::new(AtomicBool::new(true));
    let tracepoints_arc = Arc::new(args.tracepoints.clone());

    // Setup the ctrlc handler.
    let r = running.clone();
    let tp_clone = tracepoints_arc.clone();
    ctrlc::set_handler(move || {
        eprintln!("{}", "\nCaught signal, cleaning up...".yellow());
        for tp in tp_clone.iter() {
            let _ = disable_tracepoint(tp);
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

        // This is a common pattern to poll for new data without blocking forever.
        // It's not the most efficient, but it's simple and works.
        let mut line = String::new();
        match reader.read_line(&mut line) {
            Ok(0) => break, // End of file
            Ok(_) => {
                print!("{}", line.cyan());
            }
            Err(e) => {
                if e.kind() == io::ErrorKind::Interrupted {
                    continue; // The read was interrupted, try again
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
//-----------------------------------------------
// use clap::Parser; // CommandLineArgumentParser
// use colored::*;
// use signal_hook::consts::signal::*; // easy and safe signal handling
// use signal_hook::iterator::Signals;
// use std::{
//     fs::{self, File},               /* OpenOptions}, */
//     io::{self, BufRead, BufReader}, /* , Write}, */
//     path::PathBuf,
//     sync::{
//         atomic::{AtomicBool, Ordering},
//         Arc, /* AtomicReferenceCounting */
//     },
// };
//
// //This macro automatically generates the argument parsing logic.
// #[derive(Parser, Debug)]
// //Container attribute that defines top-level properties like the author, version, and a brief description.
// #[command(author, version, about = "Tracepoint monitor using tracefs")]
// struct Args {
//     // List of tracepoints to enable (ex: sys_enter_open )
//     tracepoints: Vec<String>,
// }
//
// const TRACEFS_BASE: &str = "/sys/kernel/debug/tracing";
//
// fn enable_tracepoint(tp: &str) -> io::Result<()> {
//     let path = format!("{TRACEFS_BASE}/events/syscalls/{tp}/enable");
//     fs::write(path, "1")?;
//     Ok(())
// }
//
// fn disable_tracepoint(tp: &str) -> io::Result<()> {
//     let path = format!("{TRACEFS_BASE}/events/syscalls/{tp}/enable");
//     fs::write(path, "0")?;
//     Ok(())
// }
//
// fn setup_signal_handler(running: Arc<AtomicBool>, tracepoints: Arc<Vec<String>>) {
//     let mut signals = Signals::new(&[SIGINT, SIGTERM, SIGHUP]).unwrap();
//     let tp_clone = tracepoints.clone();
//
//     std::thread::spawn(move || {
//         for _sig in signals.forever() {
//             eprintln!("{}", "Caught signal, cleaning up...".yellow());
//             for tp in tp_clone.iter() {
//                 let _ = disable_tracepoint(tp);
//             }
//             running.store(false, Ordering::SeqCst);
//             break;
//         }
//     });
// }
//
// fn main() -> io::Result<()> {
//     let args = Args::parse();
//
//     if args.tracepoints.is_empty() {
//         eprintln!(
//             "{}",
//             "No tracepoints provided. Example: ./program sys_enter_open sys_enter_read".red()
//         );
//         std::process::exit(1);
//     }
//
//     // Check access to tracefs
//     if !PathBuf::from(TRACEFS_BASE).exists() {
//         eprintln!(
//             "{}",
//             "tracefs is not mounted or accessible. Is debugfs mounted?".red()
//         );
//         std::process::exit(1);
//     }
//
//     // Enable tracepoints
//     for tp in &args.tracepoints {
//         enable_tracepoint(tp).map_err(|e| {
//             eprintln!("{} {}", "Failed to enable tracepoint:".red(), tp);
//             e
//         })?;
//         println!("{} {}", "Enabled tracepoint:".green(), tp);
//     }
//
//     let running = Arc::new(AtomicBool::new(true));
//     let tracepoints_arc = Arc::new(args.tracepoints.clone());
//
//     // Set up signal handler
//     setup_signal_handler(running.clone(), tracepoints_arc.clone());
//
//     // Open trace_pipe
//     let trace_pipe = File::open(format!("{TRACEFS_BASE}/trace_pipe"))?;
//     let reader = BufReader::new(trace_pipe);
//
//     println!("{}", "Listening to trace_pipe...".blue());
//
//     for line in reader.lines() {
//         if !running.load(Ordering::SeqCst) {
//             break;
//         }
//         let line = line?;
//         println!("{}", line.cyan());
//     }
//
//     // Cleanup on normal exit
//     println!("{}", "Cleaning up tracepoints...".yellow());
//     for tp in tracepoints_arc.iter() {
//         let _ = disable_tracepoint(tp);
//     }
//
//     Ok(())
// }
