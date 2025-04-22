use std::time::Instant;

fn main() {
    let mut arr = vec![0u8; 1_000_000];

    let now = Instant::now();
    for i in 0..arr.len() {
        arr[i] += 1;
    }
    println!("Sequential: {:?}", now.elapsed());

    let now = Instant::now();
    for _ in 0..arr.len() {
        let idx = rand::random::<usize>() % arr.len();
        arr[idx] += 1;
    }
    println!("Random: {:?}", now.elapsed());
}