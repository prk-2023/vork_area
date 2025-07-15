use std::io::{self, Write};

fn main() {
    let mut lines: Vec<String> = Vec::new();

    println!("Mini Text Editor");
    println!("Type your text line by line. Type 'EXIT' to finish.\n");

    loop {
        print!("> ");
        // Flush stdout so the prompt appears immediately
        io::stdout().flush().unwrap();

        let mut input = String::new();
        // Borrow input line as mutable reference to be filled
        io::stdin()
            .read_line(&mut input)
            .expect("Failed to read line");

        // Remove trailing newline and carriage return
        let input = input.trim_end();

        if input == "EXIT" {
            break;
        }

        // Clone the string to store in Vec (ownership transferred)
        lines.push(input.to_string());
    }

    println!("\n--- Contents ---");
    for (i, line) in lines.iter().enumerate() {
        println!("{}: {}", i + 1, line);
    }
}
