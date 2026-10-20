const std = @import("std");

extern "c" fn getuid() u32;
extern "c" fn getpid() c_int;
extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;

pub fn main() void {
    _ = printf("\n[victim] AcmeVault 1.0 starting up\n");
    _ = printf("[victim] pid=%d\n", getpid());

    const uid = getuid();
    _ = printf("[victim] identity check: getuid() = %u\n", uid);

    if (uid == 0) {
        _ = printf("[victim] >>> ACCESS GRANTED: unlocking the vault\n");
        _ = printf("[victim] secret := \"the launch codes are 0000\"\n");
    } else {
        _ = printf("[victim] >>> ACCESS DENIED: run as root to unlock\n");
    }
    _ = printf("[victim] done\n\n");
}
