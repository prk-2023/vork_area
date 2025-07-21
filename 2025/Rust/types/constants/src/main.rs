// Part 1 (global and local scope of "static" and "const" )
/* Compile-time constant */
const MAX_USERS: u32 = 1000;

/* Immutable global */
static SERVER_NAME: &str = "RustServer";

/* Mutable global (unsafe)
 * This creates a static global shared and rusts #[deny(static_mut_refs)] lint catches this and
 * precents from compilation, as this is dangerous, allows other part of code to modify this
 * creating race conditions.
 * To compile use #[allow(static_mut_refs)]
 */
static mut GLOBAL_COUNTER: u32 = 0;

// Part 2 (safe Global Mutability with "static")
use std::sync::Mutex;
static USER_COUNT: Mutex<u32> = Mutex::new(0);

// Part 3:  Using `lazy_static`
// When we want a static global that requires runtime initialization, like a HashMap or struct
// This macro, it is possible to have statics that require code to be executed at runtime in order
// to be initialized.
// Includes anything requiring heap allocations, like vectors or hash maps, as well as anything that
// requires function calls to be computed.
use lazy_static::lazy_static;
use std::collections::HashMap;

lazy_static! {
    static ref CONFIG: HashMap<&'static str, &'static str> = {
        let mut m = HashMap::new();
        m.insert("host", "localhost");
        m.insert("port", "8080");
        m
    };
}
//----
#[allow(static_mut_refs)]
#[allow(unused_variables)]
fn main() {
    {
        /* Part 1 */
        const DISCOUNT_RATE: f64 = 0.1; // Local const
        println!("Max users: {}", MAX_USERS);
        println!("Server: {}", SERVER_NAME);
        println!("Discount: {}", DISCOUNT_RATE);

        unsafe {
            GLOBAL_COUNTER += 1;
            println!("Global counter: {}", GLOBAL_COUNTER);
        }
    }

    {
        /* Part 2 */
        let mut count = USER_COUNT.lock().unwrap();
        *count += 1;
        println!("User count: {}", count);
    }
    {
        /* Part 3  Using `lazy_static` */
        println!("Server host: {}", CONFIG.get("host").unwrap());
        println!("Server port: {}", CONFIG.get("port").unwrap());
    }
    { /* Part 4: embedded and rust
         read the types.md document for no_std exampled)
          */
    }
}

/*
 * HashMap: Its a data struct that stored "key-value" pairs.
 * Allows for efficient retrieval of a value by its associate key.
 * Core Idea: A hash function converts the key into an index of array, where the value is stored.
 * This provides average O(1) (constant time) complexity for insertion, deletion, and lookup
 * operations.
 *
 * In Rust hash maps are provided by the std::collections::HashMap typs
 *
 * - to create a new hashmap:
 *      let mut scores = HashMap::new();
 *
 * - insert key-val pairs use insert() method
 *
 *      scores.insert(String::from("Blue"), 10);
 *      scores.insert(String::from("Yellow"), 50);
 *
 *  Keys and values can be of various types, but typically they are "String" or "numeric types".
 *  Keys must implement the Eq and Hash traits.
 *
 * - Access a value use get() method. This returns Option<&V> ==> it might return Some(&value) if the key
 *   exists, or None if it doesn't.
 *
 *      let team_name = String::from("Blue");
 *      let score     = scores.get(&team_name);
 *      match score = {
 *          Some(s)   => println! ("Score for {}: {}", team_name, s),
 *          None      => println! ("{} team not found.", team_name),println!(),
 *      }
 *  NOTE: You can also use square brackets [] if you are sure the key exists, If they do not exit
 *  then this will panic.
 *
 * - Iterate Over Key-Value Pairs: loop thorough hash-map "for" loop:
 *
 *      for (key, value) in &scores {
 *          println!("{}: {}", key, value);
 *      }
 *
 * - update values:
 *   Overwriting: Simply call insert() with an existing key to overwrite its value.
 *
 *      scores.insert(String::from("Blue"), 25); // Overwrites 10 with 25
 *
 *
 * - Conditional Insertion (entry): The entry() method with or_insert() is useful for inserting a value
 *   only if the key isn't already present.
 *
 *      scores.entry(String::from("Green")).or_insert(30); // Inserts 30 if "Green" isn't there
 *      scores.entry(String::from("Blue")).or_insert(75);  // Does nothing because "Blue" already exists
 *
 *   or_insert() returns a mutable reference to the value, allowing you to modify it in place.
 *
 * - Updating based on old value:
 *
 *      let text = "hello world wonderful world";
 *      let mut map = HashMap::new();
 *      for word in text.split_whitespace() {
 *          let count = map.entry(word).or_insert(0);
 *          *count += 1; // Dereference and increment the count
 *      }
 *      println!("{:?}", map); // Output: {"world": 2, "hello": 1, "wonderful": 1}
 *
 * */
