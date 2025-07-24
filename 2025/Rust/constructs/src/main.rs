mod logic;
mod models;
mod traits;

use logic::DefaultCycle;
use models::Intersection;
use std::thread::sleep;
use std::time::Duration;

fn main() {
    let mut inter = Intersection::new(1);

    for _ in 0..6 {
        inter.display();
        inter.cycle(DefaultCycle);
        sleep(Duration::from_secs(1));
    }
}
