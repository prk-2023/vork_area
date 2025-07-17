use chrono::{DateTime, Local};

fn print_vec(numbers: &Vec<i32>) {
    for i in numbers {
        print!("{}", i);
    }
    println!("");
}
fn add_one(numbers: &mut Vec<i32>) {
    numbers.push(32);
}

fn main() {
    let mut numbers = vec![1, 1, 1];
    // We pass a reference
    print_vec(&numbers);
    // We pass a mutable reference
    add_one(&mut numbers);
    // We pass a reference again
    print_vec(&numbers);
    // --
    let local: DateTime<Local> = Local::now();
    // let dt2: DateTime<Local> = Local.timestamp_opt(0, 0).unwrap();
    println!("Today is {}", local.format("%A"));
}
