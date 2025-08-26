#![no_std]
#![no_main]

use aya_ebpf::helpers::bpf_probe_read_user;
use aya_ebpf::{macros::tracepoint, programs::TracePointContext};
use aya_log_ebpf::info;

#[repr(C)]
struct sockaddr {
    sa_family: u16,
    sa_data: [u8; 14],
}
#[tracepoint]
pub fn enter_bind(ctx: TracePointContext) -> u32 {
    match try_enter_bind(ctx) {
        Ok(ret) => ret,
        Err(ret) => ret,
    }
}

// fn try_enter_bind(ctx: TracePointContext) -> Result<u32, u32> {
//     info!(&ctx, "=>tracepoint sys_enter_bind called");
//     Ok(0)
// }
fn try_enter_bind(ctx: TracePointContext) -> Result<u32, u32> {
    let fd: i32 = unsafe {
        match ctx.read_at::<i32>(16) {
            Ok(v) => v,
            Err(_) => return Err(1),
        }
    };

    let umyaddr_ptr: u64 = unsafe {
        match ctx.read_at::<u64>(24) {
            Ok(v) => v,
            Err(_) => return Err(2),
        }
    };

    let addrlen: i32 = unsafe {
        match ctx.read_at::<i32>(32) {
            Ok(v) => v,
            Err(_) => return Err(3),
        }
    };

    info!(
        &ctx,
        "bind(fd={}, umyaddr=0x{:x}, addrlen={})", fd, umyaddr_ptr, addrlen
    );

    Ok(0)
}

#[tracepoint]
pub fn exit_bind(ctx: TracePointContext) -> u32 {
    match try_exit_bind(ctx) {
        Ok(ret) => ret,
        Err(ret) => ret,
    }
}

fn try_exit_bind(ctx: TracePointContext) -> Result<u32, u32> {
    info!(&ctx, "tracepoint sys_exit_bind called==>");
    Ok(0)
}
#[cfg(not(test))]
#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[unsafe(link_section = "license")]
#[unsafe(no_mangle)]
static LICENSE: [u8; 13] = *b"Dual MIT/GPL\0";
