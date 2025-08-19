# Code Commentary 

1. 
```
//Example showing some UI controls like Label, TextEdit, Slider, Button.
use eframe::egui;
```
This line imports the egui module from the eframe crate, making its functionalities available for use.

2. 
```
struct MyApp {
    name: String,
    age: u32,
}
```
Struct hold the application State data that can change and be interacted with through the UI.
In this case Name(string) and age(i32)


3.
```
impl Default for MyApp {
    fn default() -> Self {
        Self {
            name: "daybreak..".to_owned(),
            age: 42,
        }
    }
}
```
This block implements the Default trait for MyApp. 
This means you can create a default instance of MyApp without explicitly providing values for its fields. 
When MyApp::default() is called, it will initialize name to "daybreak.." and age to 42.

4. impl eframe::App for MyApp

```
impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("My egui Application");
            ui.horizontal(|ui| {
                let name_label = ui.label("Your name: ");
                ui.text_edit_singleline(&mut self.name)
                    .labelled_by(name_label.id);
            });
            ui.add(egui::Slider::new(&mut self.age, 0..=120).text("age"));
            if ui.button("Increment").clicked() {
                self.age += 1;
            }
            ui.label(format!("Hello '{}', age {}", self.name, self.age));

            ui.image(egui::include_image!("/home/daybreak/Pictures/rust_up.jpg"));
        });
    }
}
```
This is the most important part of the UI application. 
It implements the eframe::App trait for MyApp. 

The eframe::App trait requires an update method, which is where the GUI is drawn and updated in response to 
user input.
- fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame): 
    This method is called repeatedly by egui to redraw the UI.

- "&mut self": Allows the MyApp's state (name, age) to be modified.

- "ctx: &egui::Context": Provides access to the egui context, which is used for all UI operations.

- "_frame: &mut eframe::Frame": The frame provides information about the window and allows controlling it 
  (e.g., closing the window). It's prefixed with _ because it's not used in this specific example.
  
- "egui::CentralPanel::default().show(ctx, |ui| { ... });": 
    This creates a central panel that occupies most of the application window. 
    The closure |ui| { ... } is where you define the UI elements to be placed within this panel. 
    The ui object is an instance of egui::Ui and provides methods for adding various widgets.

- ui.heading("My egui Application");: Displays a large, bold heading at the top of the panel.

- ui.horizontal(|ui| { ... });: Arranges the contained UI elements horizontally.
    - let name_label = ui.label("Your name: ");: 
      Displays a label "Your name: ". 
      The name_label variable holds the label's Response, which includes its ID.

    - ui.text_edit_singleline(&mut self.name).labelled_by(name_label.id);: Creates a single-line text input field 
        - &mut self.name: Binds the text field to the name field of MyApp. 
          Any text typed into the field will update self.name, and any changes to self.name will update the text field.
        - .labelled_by(name_label.id): Associates this text edit field with the name_label, which can improve accessibility.

- ui.add(egui::Slider::new(&mut self.age, 0..=120).text("age"));: Adds a slider widget.
    - &mut self.age: Binds the slider's value to the age field of MyApp.
    - 0..=120: Sets the minimum and maximum values for the slider (from 0 to 120, inclusive).
    - .text("age"): Adds a label "age" next to the slider.

- if ui.button("Increment").clicked() { self.age += 1; }: Creates a button with the text "Increment".
    - .clicked(): Returns true if the button was clicked.
    - self.age += 1;: If the button is clicked, the age field is incremented by 1.

- ui.label(format!("Hello '{}', age {}", self.name, self.age));: Displays a label that dynamically updates to show the current name and age values using a formatted string.

- ui.image(egui::include_image!("/home/daybreak/Pictures/rust_up.jpg"));: Displays an image within the UI.
    - egui::include_image!: macro that embeds the image file directly into the app's binary at compile time. This is a common way to include assets in egui applications. The path /home/daybreak/Pictures/rust_up.jpg is a specific file path on the user's system.

5. main () entry point of the app:

```
fn main() -> eframe::Result {
    env_logger::init(); // Log to stderr (if you run with `RUST_LOG=debug`).
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 240.0]),
        ..Default::default()
    };
    eframe::run_native(
        "My egui App",
        options,
        Box::new(|cc| {
            // This gives us image support:
            egui_extras::install_image_loaders(&cc.egui_ctx);

            Ok(Box::<MyApp>::default())
        }),
    )
}
```

- env_logger::init();: Initializes the env_logger crate, which allows for logging messages to the console (stderr). This is useful for debugging, especially when running with RUST_LOG=debug environment variable.

- let options = eframe::NativeOptions { ... };: Configures the native window for the egui application.
    - viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 240.0]),: Sets the initial inner size of the application window to 320 pixels wide by 240 pixels high.

    - ..Default::default(): Uses default values for all other NativeOptions fields not explicitly specified.

- eframe::run_native(...): This function starts the egui application.
    - "My egui App": The title of the application window.
    - options: The NativeOptions configured above.
    - Box::new(|cc| { ... }): A closure that is called when the application starts up. It receives a CreationContext (cc).
        - egui_extras::install_image_loaders(&cc.egui_ctx);: 
        This is crucial for displaying images. It initializes image loaders within the egui context, allowing egui to decode and display various image formats.
        - Ok(Box::<MyApp>::default()): Creates a new instance of MyApp using its Default implementation, boxes it (required by eframe::run_native), and returns it wrapped in an Ok result.



6. Main Event Loop:

    The main event loop is part of the eframe library's internal architecture. 
    When you call eframe::run_native, it starts this continuous loop. 
    This loop is responsible for:
    - Polling Events: Checking for user input (mouse clicks, keyboard presses, window resizing, etc.) from the OS.

    - Updating Application State: If an event occurs, it might trigger changes to your application's data.

    - Calling update: For every frame, the eframe loop calls your MyApp's update method. This is where you, the developer, tell egui what widgets to display and how they should behave based on the current application state and user interactions from the previous frame.

7. callback inside event loop:
    - "fn update ()" is the callback function that is called repeatedly 
    - &mut self: allows you to modify the state of the app. (self.name & self.age) here

    - ctx: &egui::Context: This provides the drawing context, allowing you to create and interact with egui widgets. All UI elements (labels, text edits, sliders, buttons) are added to the ui object, which is derived from ctx.

   Actual looping mechanism and event handling are managed by **eframe's run_native** function.

# Cross compile 

1. install cross tool chains 
   $ sudo apt install gcc-aarch64-linux-gnu libc6-dev-arm64-cross

2. $ rustup target add aarch64-unknown-linux-gnu
   This installs the pre-compiled Rust standard libraries (core, std, etc...) for the aarch64-unknown-linux-gnu target, which is required to build any Rust code for that architecture.

3. .cargo/config.toml file in a Rust project is used to configure Cargo, Rust’s build system and package manager.

    - .cargo/config.toml typically: 
        - Specifies the target architecture (e.g., aarch64-unknown-linux-gnu)
        - Points to the correct linker (because your host system’s linker can’t produce binaries for AArch64)
        - Provides target-specific settings (like custom runners, rustflags, sysroot)

$ mkdir .cargo; cd .cargo; touch config.toml

[build]
target = "aarch64-unknown-linux-gnu"

[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"

Cargo and rustc look for how to use the cross-compiler, including:
* cross-compiler ( linker )

[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"

- tells cargo to use this cross-linker instead of the default system linker.
- linker knows how to link object files and libs for the arch (ex aarch64 target architecture )
* C/C++ libraries and headers:
- The linker ( aarch64-linux-gnu-gcc ) automatically uses the correct **sysroot** i.e the path to:
    - cross-compiled std libs
    - c headers for the target platform 
- these are typically installed via system packages like: 

sudo apt install gcc-aarch64-linux-gnu
sudo apt install libc6-dev-arm64-cross


4. Build for aarch64,

    cargo build --target aarch64-unknown-linux-gnu
