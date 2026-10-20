const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const victim = b.addExecutable(.{
        .name = "victim",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/victim.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    victim.root_module.link_libc = true;
    b.installArtifact(victim);

    const inject = b.addLibrary(.{
        .name = "inject",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/inject.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    inject.root_module.link_libc = true;
    b.installArtifact(inject);

    const hack_echo = b.addLibrary(.{
        .name = "hack_echo",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/hack_echo.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    hack_echo.root_module.link_libc = true;
    b.installArtifact(hack_echo);
}
