extern "c" fn fputs(s: [*:0]const u8, stream: *anyopaque) c_int;

fn fakeFputs(s: [*:0]const u8, stream: *anyopaque) callconv(.c) c_int {
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
