enum Direction {
    Up,
    Down,
    Right,
    Left,
}
enum State {
    Start,
    Processing,
    Done,
}
fn main() {
    for number in 1..5 {
        println!("Number : {}", number);
    }
    let mut n = 3;
    while n != 0 {
        println!("Number : {}", n);
        n -= 1;
    }

    let dirs = Direction::Left;

    match dirs {
        Direction::Up => println!("Going up"),
        Direction::Down => println!("Going down"),
        Direction::Right => println!("Going right"),
        Direction::Left => println!("Going left"),
    }
    let mut state = State::Start;

    loop {
        state = match state {
            State::Start => {
                println!("--> Starting...");
                State::Processing
            }
            State::Processing => {
                println!("-=> Processing...");
                State::Done
            }
            State::Done => {
                println!( --> "Finished!");
                break;
            }
        };
    }
}
