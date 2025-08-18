use iced::widget::{button, column, row, text, Column};

// State of the app
#[derive(Default)]
struct Counter {
    value: i32,
}
// Possible user interactions to the app ( increment or decrement )

#[derive(Debug, Clone, Copy)]
pub enum Message {
    Increment,
    Decrement,
}

// implement the actual counting
impl Counter {
    pub fn view(&self) -> Column<Message> {
        // we use column : a simple vertical layout
        column![
            //Increment button ( to produce increment)
            button("+").on_press(Message::Increment),
            // Show the value of the counter
            text(self.value).size(50),
            //Decrement button ( to produce decrement to the counter)
            button("-").on_press(Message::Decrement),
        ]
    }
}
// Implement any produced message and change the state accordingly in logic
impl Counter {
    // ...

    pub fn update(&mut self, message: Message) {
        match message {
            Message::Increment => {
                self.value += 1;
            }
            Message::Decrement => {
                self.value -= 1;
            }
        }
    }
}
fn main() -> iced::Result {
    iced::run("A Cool Counter", Counter::update, Counter::view)
}
