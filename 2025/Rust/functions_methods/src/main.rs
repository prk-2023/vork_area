//use rand::seq::{IndexedRandom, SliceRandom};
use rand::seq::IndexedRandom;
// use rand::seq::IndexedRandom;
use rand::Rng;

fn main() {
    let mut tup = min_max_swap(3, 4);
    println!("{:?}", tup);

    let mut rng = rand::rng();

    let x = rng.random_range(1..100);
    let y = rng.random_range(1..100);
    tup = min_max_swap(x, y);

    println!("({},{})", tup.0, tup.1);
    println!("{:?}", tup);

    let quarks = ["up", "down", "charm", "strange", "top", "bottom"];

    if let Some(pick) = pick_from_list(&quarks) {
        println!("Random Quark pick: {}", pick);
    } else {
        println!("The list is empty");
    }

    for n in 9..10 {
        {
            let series = pingala(n);
            println!("First {} Pingala  numbers: {:?}", n, series);
        }
    }

    //factorial( total possibilities), permutations and combitations
    let mut n = rng.random_range(1..100);
    let mut r = rng.random_range(1..100);
    println!("Factorial of {} = {}", n, factorial(n));

    if n > r {
        println!("Permutations P({}, {}) = {}", n, r, permutations(n, r));
        println!("Combinations C({}, {}) = {}", n, r, combinations(n, r));
    } else {
        println!("WARN! r can not be larger then n");
    }
}

fn factorial(n: i32) -> i32 {
    (1..=n).product()
}

fn permutations(n: i32, r: i32) -> i32 {
    factorial(n) / factorial(n - r)
}

fn combinations(n: i32, r: i32) -> i32 {
    factorial(n) / (factorial(r) * factorial(n - r))
}

fn min_max_swap(x: i32, y: i32) -> (i32, i32) {
    if x < y {
        (x, y)
    } else {
        (y, x)
    }
}
// The outer &'a indicates the slice input itself lives for at least the duration of 'a
// inner &'a str indicates the string slices within the input slice also live for at least the duration
// of 'a.
// Option<&'a str>: specifies that the returned &str (if Some) will also live for at least the duration
// of 'a
fn pick_from_list<'a>(input: &'a [&'a str]) -> Option<&'a str> {
    let mut rng = rand::rng(); // Correct for 0.9.2
    input.choose(&mut rng).copied()
}

fn pingala(n: usize) -> Vec<u64> {
    let mut fib = Vec::with_capacity(n);
    if n == 0 {
        return fib;
    }
    fib.push(0);
    if n == 1 {
        return fib;
    }
    fib.push(1);

    for i in 2..n {
        let next = fib[i - 1] + fib[i - 2];
        fib.push(next);
    }
    fib
}

/* crate: rand ( version 0.9.2)
 * The [`rand`](https://docs.rs/rand/0.9.2/rand/) crate is standard random number generation lib.
 * It provides tools to generate random values, sample from ranges or collections, shuffle data,
 * and work with statistical distributions.
 *
 * ### ✨ Key Features
 *  - Generate *random numbers* (integers, floats, etc.)
 *  - Select *random elements* from slices
 *  - *Shuffle* arrays or vectors
 *  - Support for *custom RNGs* (e.g. seeded or cryptographic RNGs)
 *  - Works with *ranges and distributions*
 *
 *  The `rand` crate is powerful, flexible, and widely used in games, simulations,
 *  security applications, and anywhere you need *randomness* in Rust.
 *
 *  `rand` crate version 0.9.2 :
 *
 *  The `rand` crate is Rust's standard library for
 *      - *random number generation*
 *      - **sampling**,
 *      - **shuffling**, and more.
 *
 * To use add to `Cargo.toml`: to be fetched from crates.io
 *
 * ```toml
 * [dependencies]
 * rand = "0.9.2"
 * ```
 *
 * Import the Required Traits:
 *
 * In your Rust file:
 * ```rust
 * use rand::Rng;              // For RNG methods like `.random()` and `.random_range()`
 * use rand::seq::SliceRandom; // For `.choose()` and `.shuffle()` on slices
 * ```
 *
 * Create a Random Number Generator
 * ```rust
 * let mut rng = rand::rng(); // Recommended method (thread-local generator)
 * // Deprecated alternative:
 * // let mut rng = rand::thread_rng(); //Deprecated in 0.9.0
 * ```
 * Generating Random Values
 *
 * a. Generate a single random number:
 * ```rust
 * let x: u8 = rng.random();
 * let y: f64 = rng.random();
 * ```
 *
 * b. Generate a number within a range:
 * ```rust
 * let n = rng.random_range(1..100); // Ok
 * //let n = rng.gen_range(1..100); // Deprecated: Use `random_range` instead
 * ```
 *
 * Picking and Shuffling from Collections
 * a. Pick a random item from a slice:
 *
 * ```rust
 * let items = ["apple", "banana", "cherry"];
 * if let Some(pick) = items.choose(&mut rng) {
 *     println!("Random pick: {}", pick);
 * }
 * ```
 *
 * b. Shuffle a collection:
 * ```rust
 * let mut nums = vec![1, 2, 3, 4, 5];
 * nums.shuffle(&mut rng);
* println!("Shuffled: {:?}", nums);
* ```
*
* Why `rand::rng()`?
* Starting with version `0.9.0`, the old `rand::thread_rng()` was *renamed to `rng()`* to avoid conflicts
* with the future `gen` keyword in Rust 2024.
*
* The new API is cleaner, avoids future keyword collisions, and is more Rust-idiomatic.
*
* Example
* ```rust
* use rand::Rng;
* use rand::seq::SliceRandom;
* fn main() {
*    let mut rng = rand::rng();
*    let a = rng.random_range(1..10);
*    let b = rng.random_range(1..10);
*
*    let (low, high) = if a < b { (a, b) } else { (b, a) };
*    println!("Range: {} to {}", low, high);
*
*    let fruits = ["apple", "banana", "cherry"];
*    if let Some(fruit) = fruits.choose(&mut rng) {
*       println!("Random fruit: {}", fruit);
*    }
* }
* ```
* Summary of Deprecated → Updated

|  Deprecated (Old)          |  New Replacement               |
| -------------------------- |------------------------------- |
| `rand::thread_rng()`       | `rand::rng()`                  |
| `rng.gen()`                | `rng.random()`                 |
| `rng.gen_range(start..end)`| `rng.random_range(start..end)` |
*/
