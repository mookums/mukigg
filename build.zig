const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bundle = b.option(bool, "bundle", "Rebuild the bundled JS") orelse false;
    const dev = b.option(bool, "dev", "Enables Development Mode") orelse false;
    _ = dev;

    const gen_posts_exe = b.addExecutable(.{
        .name = "gen-posts",
        .root_source_file = b.path("src/tools/gen_posts.zig"),
        .target = target,
        .optimize = optimize,
    });

    const gen_posts_run = b.addRunArtifact(gen_posts_exe);
    const gen_posts_step = b.step("gen-posts", "Generate posts file");
    gen_posts_step.dependOn(&gen_posts_run.step);

    const zzz = b.dependency("zzz", .{
        .target = target,
        .optimize = optimize,
    }).module("zzz");

    const fetch_cmd = b.addSystemCommand(&.{ "sh", "-c", "pnpm install" });
    const fetch_step = b.step("fetch", "Fetch pnpm packages");
    fetch_step.dependOn(&fetch_cmd.step);

    // bundling our web assets
    const bundle_cmd = b.addSystemCommand(&.{ "sh", "-c", "pnpm bundle" });
    const bundle_step = b.step("bundle", "Run the bundler");
    bundle_step.dependOn(&bundle_cmd.step);
    bundle_step.dependOn(fetch_step);

    const exe = b.addExecutable(.{
        .name = "mukigg",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
    });

    if (bundle) exe.step.dependOn(bundle_step);
    exe.step.dependOn(gen_posts_step);

    exe.root_module.addImport("zzz", zzz);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(&exe.step);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const watch_cmd = b.addSystemCommand(&.{
        "sh",
        "-c",
        "find src/ -type f -not -path 'src/bundle/*' -not -path 'src/posts/gen.zig' | ADDR='127.0.0.1' PORT=9862 entr -d -cr zig build -Dbundle=true -Ddev=true run",
    });
    const watch_step = b.step("watch", "Run the app and watch for changes");
    watch_step.dependOn(&watch_cmd.step);
}
