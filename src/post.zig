const std = @import("std");

pub const Post = struct {
    title: []const u8,
    body: []const u8,
    etag: []const u8,

    pub fn load(comptime id: u32) Post {
        const body = @embedFile(std.fmt.comptimePrint("posts/{d}/body.html", .{id}));

        return Post{
            .title = @embedFile(
                std.fmt.comptimePrint(
                    "posts/{d}/title.html",
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
