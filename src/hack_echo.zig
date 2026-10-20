extern "c" fn fputs(s: [*:0]const u8, stream: *anyopaque) c_int;

var fired = false;

fn fakeFputs(s: [*:0]const u8, stream: *anyopaque) callconv(.c) c_int {
    if (fired) return @intCast(0);
    fired = true;
    _ = s;
    return fputs("hacked\n", stream);
}

const Interpose = extern struct {
    replacement: *const anyopaque,
    original: *const anyopaque,
};

export const _interpose_fputs: Interpose linksection("__DATA,__interpose") = .{
    .replacement = @ptrCast(&fakeFputs),
    .original = @ptrCast(&fputs),
};
