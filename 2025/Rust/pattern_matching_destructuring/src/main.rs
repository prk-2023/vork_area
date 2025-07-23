#[allow(unused_variables)]
#[allow(dead_code)]
fn main() {
    // Full pattern matching:
    let num = 7;
    // `|` OR pattern as below
    // `_` catch-all wildcard as below.
    match num {
        1 => println!("One!"),
        2 | 3 | 5 | 7 | 11 => println!("prime numbers"),
        13..19 => println!("A teen prime?"),
        _ => println!("Not a number .."),
    }
    //tuple
    let pair = (0, -3);
    match pair {
        (0, y) => println!("first element is 0,and y: {} ", y),
        (x, 0) => println!("first element is 0,and x: {} ", x),
        _ => println!("No Zeros"),
    }

    //Struct
    struct Point {
        x: i32,
        y: i32,
    }

    let p = Point { x: 0, y: 0 };
    match p {
        Point { x: 0, y } => println!("On Y axis at {}", y),
        Point { x, y: 0 } => println!("On X axis at {}", x),
        Point { x, y } => println!("Point at ({},{})", x, y),
    }

    // Enum:
    enum Message {
        Quit,
        Move { x: i32, y: i32 },
        Write(String),
    }
    let msg = Message::Move { x: 10, y: 20 };
    match msg {
        Message::Quit => println!("quit"),
        Message::Move { x, y } => println!("Move to ({},{})", x, y),
        Message::Write(s) => println!("Text: {}", s),
    }

    // if let Syntatic sugar
    let some_value = Some(7);
    if let Some(x) = some_value {
        println!("Got {}", x);
    } else {
        println!("None");
    }
    //or this can also be written as
    match some_value {
        Some(x) => println!("Got {}", x),
        _ => println!("None"),
    }

    //while let
    let mut stack = vec![1, 2, 3];
    while let Some(top) = stack.pop() {
        println!("Popped: {}", top);
    }

    //Destructuring with 'let'
    let (a, b) = (1, 2);
    println!("a = {}, b = {}", a, b);

    //Nested Example:
    let ((x1, y1), (x2, y2)) = ((0, 1), (2, 3));
    println!("({}, {}) to ({}, {})", x1, y1, x2, y2);

    // match guard
    let x = Some(4);

    match x {
        Some(n) if n < 5 => println!("Small number "),
        Some(n) => println!("Big number: {}", n),
        None => (),
    }

    //match by reference
    let name = String::from("Rust");

    match &name {
        r if r == "Rust" => println!("Found rust"),
        _ => println!("something else"),
    }

    // advance patterns
    // Ignore values:
    let (x, _) = (5, 10); // this ignores second value

    //Nested Enums:
    enum Color {
        Rgb(u8, u8, u8),
        Cmyk { c: u8, m: u8, y: u8, k: u8 },
    }
    let color = Color::Cmyk {
        c: 0,
        m: 128,
        y: 255,
        k: 0,
    };
    match color {
        Color::Rgb(r, g, b) => println!("rgb {} {} {}", r, g, b),
        Color::Cmyk { c, .. } => println!("C component {}", c),
    }
}
