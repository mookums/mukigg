const std = @import("std");

pub const Post = struct {
    id: []const u8,
    date: []const u8,
    name: []const u8,
    body: []const u8,
    etag: []const u8,

    pub fn load(
        comptime id: []const u8,
        comptime name: []const u8,
        comptime date: []const u8,
    ) Post {
        const body = @embedFile(std.fmt.comptimePrint("posts/{s}/index.html", .{id}));

        return Post{
            .id = id,
            .date = date,
            .name = name,
            .body = body,
            .etag = comptime std.fmt.comptimePrint(
                "\"{d}\"",
                .{std.hash.Wyhash.hash(0, body)},
            ),
        };
    }
};
