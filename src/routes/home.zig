const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const Server = @import("../main.zig").Server;
const Context = Server.Context;

const posts = @import("../posts/gen.zig").posts;

const HomeTemplate = @import("../templates/lib.zig").HomeTemplate;
const PostEntryTemplate = @import("../templates/lib.zig").PostEntryTemplate;

pub fn HomeHandler(ctx: *Context) void {
    const body = comptime blk: {
        var entries: []const u8 = ""[0..];

        for (posts) |post| {
            entries = std.fmt.comptimePrint(
                "{s}\n{s}",
                .{ entries, PostEntryTemplate(post) },
            );
        }

        break :blk HomeTemplate(entries);
    };

    ctx.respond(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    }) catch unreachable;
}
