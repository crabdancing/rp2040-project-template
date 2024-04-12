// #![no_std]

// #[cfg(test)]
// extern crate std;

// #[cfg(test)]
// mod tests {
//     #[test]
//     fn it_works() {
//         assert!(true);
//     }
// }
// fn main() {}

#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    // Here you could call your test functions manually
    loop {}
}
