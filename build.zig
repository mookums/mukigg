const std = @import("std");

const PostJson = struct {
    name: []const u8,
    id: []const u8,
    date: []const u8,
    publish: bool,

    pub fn compare(lhs: PostJson, rhs: PostJson) !std.math.Order {
        var lhs_iter = std.mem.tokenizeScalar(u8, lhs.date, '-');
        var rhs_iter = std.mem.tokenizeScalar(u8, rhs.date, '-');

        const lhs_year = try std.fmt.parseUnsigned(usize, lhs_iter.next().?, 10);
        const rhs_year = try std.fmt.parseUnsigned(usize, rhs_iter.next().?, 10);
        const year_order = std.math.order(lhs_year, rhs_year);
        if (year_order != .eq) return year_order;

        const lhs_month = try std.fmt.parseUnsigned(usize, lhs_iter.next().?, 10);
        const rhs_month = try std.fmt.parseUnsigned(usize, rhs_iter.next().?, 10);
        const month_order = std.math.order(lhs_month, rhs_month);
        if (month_order != .eq) return month_order;

        const lhs_day = try std.fmt.parseUnsigned(usize, lhs_iter.next().?, 10);
        const rhs_day = try std.fmt.parseUnsigned(usize, rhs_iter.next().?, 10);
        return std.math.order(lhs_day, rhs_day);
    }
};

pub fn build(b: *std.Build) !void {
    const tls = b.option(bool, "tls", "Enables TLS for Server") orelse true;
    const port = b.option(u16, "port", "Host on a given port") orelse 9862;
    const dev = b.option(bool, "dev", "Enables Development Mode") orelse false;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .cpu_model = .baseline,
        .os_tag = .linux,
        .abi = .musl,
    });
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
        .strip = false,
    });

    {
        // Generate the Posts File.
        var posts_dir = try std.fs.cwd().openDir(
            "./src/posts/",
            .{ .iterate = true },
        );
        defer posts_dir.close();

        var posts = std.ArrayList(u8).init(b.allocator);
        defer posts.deinit();

        var postjsons = std.ArrayList(PostJson).init(b.allocator);
        defer postjsons.deinit();

        var iter = posts_dir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind == .directory) {
                // read the post json
                const pj_slice = try std.fs.cwd().readFileAlloc(
                    b.allocator,
                    try std.fmt.allocPrint(
                        b.allocator,
                        "./src/posts/{s}/{s}",
                        .{ entry.name, "post.json" },
                    ),
                    1024 * 1024,
                );
                defer b.allocator.free(pj_slice);

                // parse the post json
                const pj_parse = try std.json.parseFromSlice(
                    PostJson,
                    b.allocator,
                    pj_slice,
                    .{},
                );
                defer pj_parse.deinit();

                const pj_clone = PostJson{
                    .name = try b.allocator.dupe(u8, pj_parse.value.name),
                    .id = try b.allocator.dupe(u8, pj_parse.value.id),
                    .date = try b.allocator.dupe(u8, pj_parse.value.date),
                    .publish = pj_parse.value.publish,
                };

                try postjsons.append(pj_clone);
            }
        }

        // sort by date so newest are higher.
        std.sort.pdq(PostJson, postjsons.items, {}, struct {
            fn less_than(_: void, lhs: PostJson, rhs: PostJson) bool {
                return (PostJson.compare(lhs, rhs) catch unreachable) == .gt;
            }
        }.less_than);

        for (postjsons.items) |pj| {
            // if not published and we aren't developing,
            // just skip these.
            if (!pj.publish and !dev) {
                continue;
            }

            // format the post.load line
            const formatted = switch (dev and !pj.publish) {
                true => try std.fmt.allocPrint(
                    b.allocator,
                    "    Post.load(\"{s}\", \"{s} [Work In Progress]\", \"{s}\"),\n",
                    .{ pj.id, pj.name, pj.date },
                ),
                false => try std.fmt.allocPrint(
                    b.allocator,
                    "    Post.load(\"{s}\", \"{s}\", \"{s}\"),\n",
                    .{ pj.id, pj.name, pj.date },
                ),
            };

            defer b.allocator.free(formatted);

            // add to set
            try posts.appendSlice(formatted);
        }

        const file_fmt =
            \\const std = @import("std");
            \\const Post = @import("../post.zig").Post;
            \\
            \\pub const posts = [_]Post{{
            \\{s}}};
            \\
        ;

        const contents = try std.fmt.allocPrint(
            b.allocator,
            file_fmt,
            .{try posts.toOwnedSlice()},
        );

        const file = try posts_dir.createFile("gen.zig", .{
            .truncate = true,
            .lock = .exclusive,
        });
        defer file.close();

        try file.writeAll(contents);
    }

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
        "find src/ -type f | entr -d -cr zig build -Dtls=false -Dport=9862 -Ddev=true run",
    });
    watch_cmd.step.dependOn(b.getInstallStep());
    const watch_step = b.step("watch", "Run the app and watch for changes");
    watch_step.dependOn(&watch_cmd.step);
}
