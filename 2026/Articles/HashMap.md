# HashMaps: 


- **Definition**:
    HashMaps are a highly efficient data structure that store data in key-value pairs, allowing rapid
    retrieval, insertion, and deletion of data, usually in constant O(1) time. 
    They work by using *hash function* to map a key to a specific index in an underlying array (or "bucket"),
    acting like a digital dictionary where you look up a definition ( value ) using a word ( key ).

- E.g: locker room: 
    * In standard list ( or array ) you have to check every locker one by one to find the bag.
    * In a HashMap, You have a 'magic key' ( the **key** ) that tells you exactly which locker ( the
      **value** ) your stuff is in. No searching is required. 

- Core Concept:  Key-Value Pairs:

    A HashMap stores data in pairs. Every piece of data you save have a *unique Identifier*.
    - *Key*:  The unique label used to look up the data (e.g., a Student ID).
    - *Value*: The actual data associated with that key (e.g., "John Smith").

    | Key (Unique)|Value (Data)|
    | :--- | :--- |
    | user123 | Alice|
    | user456 | Bob  |
    | user789 | Charlie |

- How it Works: *Hashing* magic:
    How does the computer know exactly where to put *Alice*? 
    It uses a **Hash Function**
    1. *Input* : You give a map a Key (e.g: "user123" )
    2. *Hashing*: Hash function performs calculation on that string to produce a specific number ( an Index ).
    3. *Storage*: The Value is placed in a bucket at that specific index.

    Why is this cool? Because the math takes the same amount of time whether you have 10 items or 10 million
    items. This is known as O(1) or "Constant Time" complexity.

- e.g: Python has built in data type called *Dictionary* ( making it more easier for key:value storage )
```python 
# 1. Initialize (Create)
# Key: String (Item name), Value: Integer (Quantity)
inventory = {}

# 2. Add or Update data
inventory["Apples"] = 50
inventory["Bananas"] = 20

# 3. Retrieve data (Get)
# If the key doesn't exist, this would normally throw an error
count = inventory["Apples"] 
print(f"We have {count} apples.")

# 4. Remove data
del inventory["Bananas"]

# 5. Check if a key exists (Very common in Python)
if "Oranges" in inventory:
    print(inventory["Oranges"])
else:
    print("Oranges are not in stock!")

# 6. Get the number of items
print(len(inventory)) # Returns 1
```
- In Pyhton Hasing log ic is "abstracted away", giving performance benefit to the programmer.
    - The `hash()` function: python has built in `hash()` function, You can try this in code: 
      `print(hash("Alice"))` this will return a giant unique integer. 
    - The Map: It takes that giant integer and uses it as an address to jump straight to the correct spot 
      in memory.
    - The Result: Instead of searching through a list of 1,000 items (which takes 1,000 steps), Python 
      jumps to the address in 1 step.

- Dealing with *Collisions*:

    Sometimes, two different keys might result in the same index after going through the hash function. 
    This is called a Collision.

    The Fix: 
        Most HashMaps handle this using Chaining. 
        If two items land in the same bucket, the bucket simply turns into a small linked list, storing 
        both items at that index.

- eg:
```python 
# A dictionary where the Key is the Student Name 
# and the Value is ANOTHER dictionary of subjects.
gradebook = {
    "Alice": {"Math": 95, "History": 88, "CS": 98},
    "Bob":   {"Math": 76, "History": 92, "CS": 85},
    "Charlie": {"Math": 89, "History": 78, "CS": 92}
}
# To get Bob's Computer Science grade, you use two sets of brackets:
# First bracket gets the student, second gets the subject
bobs_cs_grade = gradebook["Bob"]["CS"]
print(f"Bob's CS Grade: {bobs_cs_grade}") # Output: 85

#  math average 
total_math = 0
student_count = len(gradebook)

for scores in gradebook.values():
    total_math += scores["Math"]

average = total_math / student_count
print(f"The class average for Math is: {average}")
```

# HashMaps in Rust:

- Unlike python Rust does not have inbuilt HashMap type. And it has to be included 
    `use std::collections::HashMap;`

- Basic Operations (Rust Syntax)
    Since Rust is statically types, Once you decide a HashMap stores `Strings` as keys and `u32` as values
    it stays that way.
    
```rust 
use std::collections::HashMap;

fn main() {
    // 1. Initialize (The 'mut' makes it changeable)
    let mut inventory = HashMap::new();

    // 2. Insert data
    // Note: .to_string() is needed because "Apples" is a string literal (&str)
    inventory.insert(String::from("Apples"), 50);
    inventory.insert(String::from("Bananas"), 20);

    // 3. Access data (Returns an 'Option')
    // Rust is obsessed with safety. It won't give you the value directly
    // in case the key doesn't exist.
    match inventory.get("Apples") {
        Some(count) => println!("We have {} apples.", count),
        None => println!("No apples found!"),
    }

    // 4. Remove data
    inventory.remove("Bananas");
}
```

- Rust handles Hashmaps differently then python in two major ways:
    1. *Ownership* : 
        When you insert a String into a *HashMap*, the *HashMap* now owns that string. 
        You cannot use that specific string variable later in the code because it has been "moved" into the
        Map's memory.
    2. The `Option` Type:
        In Python, a missing key crashes the program (`KeyError`).
        In Rust, the `.get()` method returns an `Option<&V>`.
        - It returns `Some(&value)` if it exists.
        - It returns `None` id it doesn't.
        This forces you to handle the "not found" case immediately. Adding stability to the program.

- **Common Pattern: Entry API **
    Rust has a very "smart" way to update values called the *Entry API*.
    It allows you to check for a key and set a default value all in one line. 
    This is the "gold standard" for Rust developers.

    Example: Counting words in a list

```rust 
    let mut counts = HashMap::new();
    let text = "apple banana apple";

    for word in text.split_whitespace() {
        // Look for the word; if it's not there, insert 0, then add 1 to the value
        let count = counts.entry(word).or_insert(0);
        *count += 1;
    }
    println!("{:?}", counts); // {"apple": 2, "banana": 1}
```

- Challenge: 
  Try to modify the "Entry API" code above to create a program that takes a list of numbers and counts how 
  many times each number appears.

- Cargo.toml
```toml
#... 
[[dependencies]
clap = { version = "4.0", features = ["derive"] }]
```
- main.rs

```rust 
use clap::Parser;
use std::collections::HashMap;

#[derive(Parser)]
struct Cli {
    /// The name of the item
    item: String,
    /// The quantity to add
    quantity: i32,
}

fn main() {
    // 1. Parse the arguments from the terminal
    let args = Cli::parse();

    // 2. Initialize the HashMap
    let mut inventory = HashMap::new();

    // 3. Add the user's input to the map
    inventory.insert(args.item.clone(), args.quantity);

    println!("Added {} units of {}.", args.quantity, args.item);
    
    // Check the map
    if let Some(q) = inventory.get(&args.item) {
        println!("Current inventory for {}: {}", args.item, q);
    }
}
```
- Ownership (The `clone()`):
    Notice `args.item.clone()`. 
    Because the `Cli struct` owns the string, and the *HashMap* needs to own its keys, we `clone` the data 
    so both can have a copy. This is a great "teachable moment" for Rust's memory model.

- Updated version of same program that takes in more then one key value inputs:
```rust 
use clap::Parser;
use std::collections::HashMap;

#[derive(Parser)]
struct Cli {
    /// Provide pairs: Item Quantity Item Quantity...
    /// Example: AyyGpples 50 Bananas 20
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
                println!("Error: '{}' is not a valid number for '{}'", chunk[1], chunk[0]);
            }
        }
    }

    println!("Current Inventory: {:?}", inventory);
}
```

- the above program can be extended to take in sub-commands like add, remove or list ( similar to git
  status, git commit, git pull ....)

```rust 
#[derive(Parser)]
enum Commands {
    Add { item: String, quantity: i32 },
    Remove { item: String },
    List,
}

#[derive(Parser)]
struct Cli {
    /// Example: Add AyyGpples 50 Bananas 20
    #[command(subcommand)]
    command: Commands,
}
```


# HashMaps in eBPF: ( two worlds )

In the world of `eBPF`, `HashMaps` are no longer just a data structure in your RAM—they become a 
communication bridge between the restricted, high-speed Linux Kernel and your User-space application.

Using the Aya framework (a pure-Rust eBPF library), we handle this "dual-world" data sharing using a 
shared memory area called a **BPF Map**.

1. The Architecture: Two Worlds, One Map
    - In eBPF, the "Map" lives in Kernel Memory. 
    - Both the eBPF program (running in the kernel) and your Rust application (running in user-space) have 
      "handles" to the same memory.

    - Kernel Side: The eBPF program updates the map (e.g., counting packets).
    - User Side: The Rust app reads the map to display statistics or change configurations.

2. The Kernel Side (eBPF Program)

```rust 
use aya_ebpf::{macros::map, maps::HashMap};

#[map]
// Key: IPv4 address (u32), Value: Packet count (u32)
static mut PACKET_STATS: HashMap<u32, u32> = HashMap::with_max_entries(1024, 0);

pub fn handle_packet(ctx: XdpContext) -> u32 {
    let source_addr: u32 = 0x01010101; // Simplified IP
    
    // Look up the current count or start at 0
    let mut count = unsafe { PACKET_STATS.get_ptr_mut(&source_addr) };
    
    if let Some(c) = count {
        unsafe { *c += 1 }; // Update in-place in kernel memory
    } else {
        unsafe { PACKET_STATS.insert(&source_addr, &1, 0) };
    }
    
    xdp_action::XDP_PASS
}
```

3. The User-Space Side (Aya 0.13.x)
    Aya makes this very clean by providing a HashMap type that mirrors the one in the kernel.

```rust 
use aya::maps::HashMap;
use aya::Bpf;

fn main() -> Result<(), anyhow::Error> {
    // 1. Load the eBPF bytecode
    let mut bpf = Bpf::load(include_bytes_raw!("path/to/ebpf.o"))?;

    // 2. Get a handle to the "PACKET_STATS" map defined in the kernel
    // We specify the types so Rust knows how to interpret the bytes
    let mut stats: HashMap<_, u32, u32> = HashMap::try_from(bpf.map_mut("PACKET_STATS").unwrap())?;

    // 3. Read data from the "Kernel World"
    let target_ip: u32 = 0x01010101;
    if let Some(count) = stats.get(&target_ip, 0)? {
        println!("The kernel saw {} packets from this IP!", count);
    }

    Ok(())
}
```

4. How the "Magic" Happens (The System Call)
    Since user-space cannot touch kernel memory directly for security reasons, 
    Aya uses the `bpf()` system call under the hood:

    - Aya calls `bpf_map_lookup_elem`.
    - The Kernel finds the value in the hash table.
    - The Kernel copies that value back into your Rust application's memory.

The *eBPF Maps* is the "Mailbox": kernel drops a letter (data) in the box, and user-space application picks
it up later. 

Note Unlike python or Std Rust, you **must** tell the kernel how big the map is upfront ( eg: 1024, entries)
because kernel memory is precious and cannot "auto-grow" easily. 

Aya's Role acts like the "translator" making sure the raw-bytes in the kernel look like nice Rust integers
and structs in your app.

5. Per-CPU Maps: 
    These are specialized HashMaps that prevent data corruption when multiple CPU cores are updating the 
    same counter at the same time.

    - In high-performance networking or system monitoring, you'll encounter a problem: Race Conditions. 
      If four different CPU cores see a packet at the exact same microsecond and try to update the same 
      counter in a standard HashMap, they will fight over the memory address, causing a bottleneck or 
      incorrect data. This is where Per CPU Maps come in:

      1. The Concept: Individual Lanes:
      Instead of one giant "Locker Room" (HashMap) for the whole kernel, a Per-CPU Map creates a private
      "Locker" for every single core on your processor.

      - Core 0 has its own version of the map.
      - Core 1 has its own version of the map.

      They never have to wait for each other. This is Lockless and incredibly fast.

      2. Kernel side:
      In your eBPF code, you change the map type to `PerCpuHashMap`. 
      The kernel handles the "which core am I on?" logic automatically.

      ```rust 
      use aya_ebpf::{macros::map, maps::PerCpuHashMap};
      #[map]
      static mut CPU_STATS: PerCpuHashMap<u32, u64> = PerCpuHashMap::with_max_entries(1024, 0);
      
      pub fn handle_packet(ctx: XdpContext) -> u32 {
          let key = 1; // Example metric ID
              
          // This lookup only returns the value for the CURRENT CPU core
          let val = unsafe { CPU_STATS.get_ptr_mut(&key) };
          if let Some(v) = val { 
             unsafe { *v += 1 };
          } else {
             unsafe { CPU_STATS.insert(&key, &1, 0) };
          }
          xdp_action::XDP_PASS
      }
      ```
      3. The User-Space Side (Aya 0.13.x):
      This is the tricky part: When you read a Per-CPU map from user-space, you don't get a single number
      back. You get a collection of numbers (one for each core).

      You must sum them up to get the total count.
      ```rust 
      use aya::maps::PerCpuHashMap;
      // ---snip---
      let key = 1;
      // .get_all() returns a 'PerCpuValues' object 
      if let Some(cpu_values) = stats.get_all(&key, 0)? {
        // Sum the values from all cores
        let total: u64 = cpu_values.iter().sum();
        println!("Total packets across all cores: {}", total);

        // You can also see individual core performance:
        for (cpu_id, val) in cpu_values.iter().enumerate() {
           println!("Core {}: saw {} packets", cpu_id, val);
        }
      }
      ```
