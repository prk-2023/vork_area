// use clap::Parser;
// use std::collections::HashMap;
//
// #[derive(Parser)]
// struct Cli {
//     /// The name of the item
//     item: String,
//     /// The quantity to add
//     quantity: u32,
// }
//
// fn main() {
//     // 1. Parse the arguments from the terminal
//     let args = Cli::parse();
//
//     // 2. Initialize the HashMap
//     let mut inventory = HashMap::new();
//
//     // 3. Add the user's input to the map
//     inventory.insert(args.item.clone(), args.quantity);
//
//     println!("Added {} units of {}.", args.quantity, args.item);
//
//     // Check the map
//     if let Some(q) = inventory.get(&args.item) {
//         println!("Current inventory for {}: {}", args.item, q);
//     }
// }

// cargo run -- "Red Apples" 100
//
use clap::Parser;
use std::collections::HashMap;

#[derive(Parser)]
struct Cli {
    /// Provide pairs: Item Quantity Item Quantity...
    /// Example: Apples 50 Bananas 20
    #[arg(num_args = 1..)]
    items_and_counts: Vec<String>,
}

fn main() {
    let args = Cli::parse();
    let mut inventory = HashMap::new();

    // Iterate through the vector in chunks of 2
    for chunk in args.items_and_counts.chunks(2) {
        if chunk.len() == 2 {
            let item = chunk[0].clone();
            // Try to parse the second string into an i32
            if let Ok(quantity) = chunk[1].parse::<i32>() {
                inventory.insert(item, quantity);
            } else {
                println!(
                    "Error: '{}' is not a valid number for '{}'",
                    chunk[1], chunk[0]
                );
            }
        }
    }

    println!("Current Inventory: {:?}", inventory);
}

// cargo run -- Apples 50 Bananas 20 Oranges 100
