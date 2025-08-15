// pub fn add(left: u64, right: u64) -> u64 {
//     left + right
// }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}

pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
pub fn multiply(a: i32, b: i32) -> i32 {
    a * b
}
