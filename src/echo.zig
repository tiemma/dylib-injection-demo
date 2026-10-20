const std = @import("std");

extern "c" fn fputs(s: [*:0]const u8, stream: *anyopaque) c_int;
extern "c" var __stdoutp: *anyopaque;

pub fn main(init: std.process.Init.Minimal) u8 {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;

    var it = std.process.Args.Iterator.init(init.args);
    _ = it.next();

    var first = true;
    while (it.next()) |arg| {
        if (!first) {
            buf[len] = ' ';
            len += 1;
        }
        first = false;
        @memcpy(buf[len .. len + arg.len], arg);
        len += arg.len;
    }
    buf[len] = '\n';
    len += 1;
    buf[len] = 0;

    _ = fputs(@ptrCast(&buf), __stdoutp);
    return 0;
}
