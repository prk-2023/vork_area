#[derive(Debug, Clone, Copy)]

pub enum TrafficLight {
    Red,
    Green,
    Yellow,
}

#[derive(Debug)]
pub struct Intersection {
    pub id: u32,
    pub light: TrafficLight,
}
