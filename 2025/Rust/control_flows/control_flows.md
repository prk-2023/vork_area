# Control flow and Constructs:

Control Flow Constructs
---

In Rust, control flow is managed through various structures, like if, else, while, for, loop, match and if 
let. 

The if and else structures are used to execute different blocks of code based on certain conditions. 
Similar to other languages, while and for are used for looping over a block of code. 

The while loop repeats a block of code until the condition is false, and the for loop is used to iterate 
over a collection of values, such as an array or a range. The loop keyword tells Rust to execute a block 
of code over and over again forever or until you explicitly tell it to stop. 

Rust's match structure, which is similar to switch statements in other languages, is a powerful tool used 
for pattern matching: it checks through different cases defined by the programmer and executes the block 
where the match is found. 

The if let syntax lets you combine if and let into a less verbose way to handle values that match one 
pattern while ignoring the rest.


Let's now *expand* each of them with *detailed explanations, syntax, variations, and practical examples* 
for deep understanding when and how to use them in real-world Rust programs.


## `if` / `else if` / `else`

Used to conditionally execute blocks of code.

###  Basic usage:

```rust
fn main() {
    let number = 7;

    if number < 10 {
        println!("Less than 10");
    } else if number == 10 {
        println!("Exactly 10");
    } else {
        println!("Greater than 10");
    }
}
```

### Used as an expression:

```rust
fn main() {
    let is_even = true;
    let message = if is_even { "Even" } else { "Odd" };
    println!("{}", message);
}
```

> Tip: Both branches of an `if` expression must return the same type.

## `loop`

Repeats code *indefinitely* unless `break` is used.

### Basic usage:

```rust
fn main() {
    let mut count = 0;

    loop {
        count += 1;
        println!("Count: {}", count);
        if count == 5 {
            break;
        }
    }
}
```

### Returning a value from a loop:

```rust
fn main() {
    let result = loop {
        let x = 5;
        break x * 2;
    };
    println!("Result is: {}", result);
}
```

> `loop` is useful for state machines or retry-until-success logic.

## `while`

Repeats a block while a condition is `true`.

### Example:

```rust
fn main() {
    let mut n = 3;

    while n != 0 {
        println!("{}!", n);
        n -= 1;
    }

    println!("Liftoff!");
}
```

> Good for looping with external or mutable conditions.

## `for` (with ranges or iterators)

More idiomatic and safer than `while`.

###  Loop over a range:

```rust
fn main() {
    for number in 1..5 {
        println!("Number: {}", number);
    }
}
```

> `1..5` is exclusive; use `1..=5` to include 5.

###  Loop over a collection:

```rust
fn main() {
    let names = ["Alice", "Bob", "Carol"];

    for name in names.iter() {
        println!("Hello, {}", name);
    }
}
```

---

## `match`

Used for exhaustive **pattern matching**.

###  Basic example:

```rust
fn main() {
    let number = 3;

    match number {
        1 => println!("One"),
        2 | 3 => println!("Two or Three"),
        4..=10 => println!("Between 4 and 10"),
        _ => println!("Something else"),
    }
}
```

### Matching enums:

```rust
enum Direction {
    Up,
    Down,
    Left,
    Right,
}

fn main() {
    let dir = Direction::Left;

    match dir {
        Direction::Up => println!("Going up!"),
        Direction::Down => println!("Going down!"),
        Direction::Left => println!("Going left!"),
        Direction::Right => println!("Going right!"),
    }
}
```

> `match` forces you to **handle all cases** (either explicitly or using `_`).

##  `if let`

Used when you want to match *only one pattern* and ignore the rest — *less verbose* than `match`.

```rust
fn main() {
    let some_value = Some(5);

    if let Some(x) = some_value {
        println!("The value is: {}", x);
    }
}
```

> Cleaner than writing a full `match` when you only care about one arm.

## `while let`

Loop as long as a pattern continues to match.

### Example with `Option`:

```rust
fn main() {
    let mut values = vec![Some(1), Some(2), None];

    while let Some(Some(val)) = values.pop() {
        println!("Got: {}", val);
    }
}
```

## Real-World Use Cases

### Control flow for input validation:

```rust
fn validate(input: Option<&str>) {
    if let Some(name) = input {
        println!("Hello, {name}");
    } else {
        println!("Input missing!");
    }
}
```

### State machine using `loop + match`:

```rust
enum State {
    Start,
    Processing,
    Done,
}

fn main() {
    let mut state = State::Start;

    loop {
        state = match state {
            State::Start => {
                println!("Starting...");
                State::Processing
            }
            State::Processing => {
                println!("Processing...");
                State::Done
            }
            State::Done => {
                println!("Finished!");
                break;
            }
        };
    }
}
```

## Summary Table

| Construct     | Use Case                            | Notes                                      |
| ------------- | ----------------------------------- | ------------------------------------------ |
| `if` / `else` | Conditional logic                   | Can be used as expressions                 |
| `loop`        | Infinite looping                    | Must use `break` to exit                   |
| `while`       | Loop with external condition        | Precondition checked before each iteration |
| `for`         | Iterate over ranges or collections  | Idiomatic and safe                         |
| `match`       | Pattern matching (like `switch`)    | Exhaustive and powerful                    |
| `if let`      | Match one pattern in a clean way    | Shorter version of `match`                 |
| `while let`   | Loop while a pattern keeps matching | Used with iterators or `Option`, `Result`  |


## Key Concepts Across Control Flows:

- Expressions Vs Statements: 
    * Rust distinguishes between expressions (which return a value) and statements (which perform an action 
      and don't return a value). 
    * Control flow constructs like if, loop, match are expressions, which makes for very ergonomic and
      powerful code.

- Type Cohesion:
    * When control flow constructs are used as expressions (e.g., in a let binding), all possible branches
      must evaluate to the same type. The compiler enforces this strictly.

- Borrowing and Ownership: 
    * Control flow interacts heavily with Rust's ownership and borrowing rules. Understanding how values are
      moved, copied, or borrowed within different branches or loop iterations is crucial to avoid common 
      errors.



