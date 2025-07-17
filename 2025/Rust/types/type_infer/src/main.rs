use std::any::type_name;

fn print_type_of<T>(_: &T) {
    println!("{}", type_name::<T>());
}
#[allow(dead_code)]
fn main() {
    let add = |x, y| x + y;

    let result = add(4.0, 5.0);
    println!("{result}");

    trait Shape {
        fn area(&self) -> f64;
    }

    struct Circle {
        radius: f64,
    }

    impl Shape for Circle {
        fn area(&self) -> f64 {
            (3.14) * self.radius * self.radius
        }
    }

    fn print_area(s: &dyn Shape) {
        println!("Area: {}", s.area());
    }

    let c = Circle { radius: 5.0 };
    print_area(&c);
    print_type_of(&c); // prints: i32

    let x = 42;
    print_type_of(&x); // prints: i32

    let s = "hello";
    print_type_of(&s); // prints: &str

    struct Point<T> {
        x: T,
        y: T,
    }

    let p3: Point<f64> = Point { x: 1f64, y: 2f64 }; // Here explicit T = f64
    print_type_of(&p3);

    let b: Option<f64> = None; //needs explicit type
    print_type_of(&b);

    let x = square(3.0);
    println!("{x}");

    // str::parse() returns "Result<T,_>" we need specify to avoid compiler ambiguity.
    let x: Result<i32, _> = "12".parse();
    //or
    let four: u32 = "4".parse().unwrap();
    println!("{} and {four}", x.unwrap());

    let maybe_num = Some(42).unwrap();
    println!("{}", square(maybe_num));

    print_it(123);
    print_it("hello");
}
// we need to Copy of x as x is required twice in Mul, and first move moves the ownership
// if we remove copy compiler throws error
fn square<T: std::ops::Mul<Output = T> + Copy>(x: T) -> T {
    x * x
}
fn print_it<T: std::fmt::Display>(item: T) {
    println!("{}", item);
}
