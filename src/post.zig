const std = @import("std");

pub const Post = struct {
    id: []const u8,
    title: []const u8,
    body: []const u8,
    etag: []const u8,

    pub fn load(comptime id: []const u8) Post {
        const body = @embedFile(std.fmt.comptimePrint("posts/{s}/body.html", .{id}));

        return Post{
            .id = id,
            .title = @embedFile(
                std.fmt.comptimePrint(
                    "posts/{s}/title.html",
                    .{id},
                ),
            ),
            .body = body,
            .etag = comptime std.fmt.comptimePrint(
                "\"{d}\"",
                .{std.hash.Wyhash.hash(0, body)},
            ),
        };
    }
};
