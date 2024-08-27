const std = @import("std");

pub fn build(b: *std.Build) void {
    const tls = b.option(bool, "tls", "Enables TLS for Server") orelse true;
    const port = b.option(u16, "port", "Host on a given port") orelse 9862;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zzz = b.dependency("zzz", .{
        .target = target,
        .optimize = optimize,
    }).module("zzz");

    const exe = b.addExecutable(.{
        .name = "website",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const options = b.addOptions();
    options.addOption(bool, "tls", tls);
    options.addOption(u16, "port", port);
    exe.root_module.addOptions("config", options);

    exe.root_module.addImport("zzz", zzz);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const watch_cmd = b.addSystemCommand(&.{
        "sh",
        "-c",
        "find src/ | entr -cr zig build -Dtls=false -Dport=9862 run",
    });
    watch_cmd.step.dependOn(b.getInstallStep());
    const watch_step = b.step("watch", "Run the app and watch for changes");
    watch_step.dependOn(&watch_cmd.step);
}
