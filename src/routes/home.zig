const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const Context = http.Context;
const Respond = http.Respond;

const posts = @import("../posts/gen.zig").posts;

const HomeTemplate = @import("../templates/lib.zig").HomeTemplate;
const PostEntryTemplate = @import("../templates/lib.zig").PostEntryTemplate;

pub fn home_handler(_: *const Context, _: void) !Respond {
    const body = comptime blk: {
        var entries: []const u8 = &.{};

        for (posts) |post| {
            entries = std.fmt.comptimePrint(
                "{s}\n{s}",
                .{ entries, PostEntryTemplate(post) },
            );
        }

        break :blk HomeTemplate(entries);
    };

    return Respond{ .standard = .{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    } };
}
