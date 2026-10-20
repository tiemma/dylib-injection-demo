extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;
extern "c" fn getpid() c_int;
extern "c" fn getuid() u32;

fn onLoad() callconv(.c) void {
    _ = printf("\x1b[31m[inject] constructor fired inside pid=%d BEFORE main()\x1b[0m\n", getpid());
    _ = printf("\x1b[31m[inject] arbitrary code now runs with the victim's privileges\x1b[0m\n");
}

const InitFn = *const fn () callconv(.c) void;
export const _dylib_demo_init: InitFn linksection("__DATA,__mod_init_func") = &onLoad;

fn fakeGetuid() callconv(.c) u32 {
    _ = printf("\x1b[31m[inject] getuid() hijacked -> returning 0 (root)\x1b[0m\n");
    return 0;
}

const Interpose = extern struct {
    replacement: *const anyopaque,
    original: *const anyopaque,
};

export const _interpose_getuid: Interpose linksection("__DATA,__interpose") = .{
    .replacement = @ptrCast(&fakeGetuid),
    .original = @ptrCast(&getuid),
};
