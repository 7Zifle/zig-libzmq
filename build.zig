const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const unitTests = b.addTest(.{
        .name = "zig-libzmq",
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    unitTests.linkSystemLibrary("zmq");
    unitTests.linkLibC();

    b.installArtifact(unitTests);

    const ut_cmd = b.addRunArtifact(unitTests);
    ut_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        ut_cmd.addArgs(args);
    }
    const ut_step = b.step("test", "Test the library");
    ut_step.dependOn(&ut_cmd.step);
}
