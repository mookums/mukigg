const std = @import("std");
const builtin = @import("builtin");
const zzz = @import("zzz");
const http = zzz.HTTP;

const Server = @import("../main.zig").Server;
const Context = Server.Context;

const posts = @import("../posts/gen.zig").posts;

const Post = @import("../post.zig").Post;
const RouteHandlerFn = http.RouteHandlerFn;
const PostTemplate = @import("../templates/lib.zig").PostTemplate;
const NotFoundTemplate = @import("../templates/lib.zig").NotFoundTemplate;

const post_bodies: [posts.len][]const u8 = blk: {
    var handlers = [_][]const u8{undefined} ** posts.len;

    for (posts, 0..) |post, i| {
        handlers[i] = PostTemplate(post);
    }

    break :blk handlers;
};

pub fn PostHandler(ctx: *Context, _: void) !void {
    const post_id = ctx.captures[0].string;

    for (posts, 0..) |post, i| {
        if (std.mem.eql(u8, post.id, post_id)) {
            // Add caching headers.
            try ctx.response.headers.add("ETag", post.etag);

            if (comptime builtin.mode != .Debug) {
                try ctx.response.headers.add("Cache-Control", "max-age=604800");
            }

            if (ctx.request.headers.get("If-None-Match")) |etag| {
                if (std.mem.eql(u8, post.etag, etag)) {
                    ctx.response.set(.{
                        .status = .@"Not Modified",
                        .mime = http.Mime.HTML,
                        .body = "",
                    });
                    return;
                }
            }

            try ctx.respond(.{
                .status = .OK,
                .mime = http.Mime.HTML,
                .body = post_bodies[i],
            });
            return;
        }
    }

    try ctx.respond(.{
        .status = .@"Not Found",
        .mime = http.Mime.HTML,
        .body = NotFoundTemplate("<h2 class=\"center\">404 | post not found</h2>"),
    });
}
