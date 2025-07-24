use crate::models::TrafficLight;

pub trait SingnalCycle {
    fn next_light(current: TrafficLight) -> TrafficLight;
}
