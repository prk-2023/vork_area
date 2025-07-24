// use crate::models::{Intersection, TrafficLight};
// use crate::traits::SingleCycle;
//
// pub struct DefaultCycle;
//
// impl SingleCycle for DefaultCycle {
//     fn next_light(current: TrafficLight) -> TrafficLight {
//         match current {
//             TrafficLight::Red => TrafficLight::Green,
//             TrafficLight::Green => TrafficLight::Yellow,
//             TrafficLight::Yellow => TrafficLight::Red,
//         }
//     }
// }
// impl Intersection {
//     pub fn new(id: u32) -> Self {
//         Self {
//             id,
//             light: TrafficLight::Red,
//         }
//     }
//     pub fn cycle<T: SingleCycle>(&mut self, _logic: T) {
//         self.light = T::next_light(self.light)
//     }
//     pub fn display(&self) {
//         println!("Intersection {}: {:?}", self.id, self, light);
//     }
// }
use crate::models::{Intersection, TrafficLight};
use crate::traits::SingnalCycle;

pub struct DefaultCycle;

impl SingnalCycle for DefaultCycle {
    fn next_light(current: TrafficLight) -> TrafficLight {
        match current {
            TrafficLight::Red => TrafficLight::Green,
            TrafficLight::Green => TrafficLight::Yellow,
            TrafficLight::Yellow => TrafficLight::Red,
        }
    }
}

impl Intersection {
    pub fn new(id: u32) -> Self {
        Self {
            id,
            light: TrafficLight::Red,
        }
    }

    pub fn cycle<T: SingnalCycle>(&mut self, _logic: T) {
        self.light = T::next_light(self.light);
    }

    pub fn display(&self) {
        println!("Intersection {}: {:?}", self.id, self.light);
    }
}
