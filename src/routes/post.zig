const std = @import("std");

const zzz = @import("zzz");
const http = zzz.HTTP;

const posts = @import("../posts/gen.zig").posts;

const Post = @import("../post.zig").Post;
const RouteHandlerFn = http.RouteHandlerFn;
const PostTemplate = @import("../templates/lib.zig").PostTemplate;

const post_bodies: [posts.len][]const u8 = blk: {
    var handlers = [_][]const u8{undefined} ** posts.len;

    for (posts, 0..) |post, i| {
        handlers[i] = PostTemplate(post);
    }

    break :blk handlers;
};

pub fn PostHandler(request: http.Request, response: *http.Response, ctx: http.Context) void {
    const post_id = ctx.captures[0].String;

    for (posts, 0..) |post, i| {
        if (std.mem.eql(u8, post.id, post_id)) {
            if (request.headers.get("If-None-Match")) |etag| {
                if (std.mem.eql(u8, post.etag, etag)) {
                    response.set(.{
                        .status = .@"Not Modified",
                        .mime = http.Mime.HTML,
                        .body = "",
                    });
                    return;
                }
            }

            response.set(.{
                .status = .OK,
                .mime = http.Mime.HTML,
                .body = post_bodies[i],
            });
            return;
        }
    }

    response.set(.{
        .status = .@"Not Found",
        .mime = http.Mime.HTML,
        .body = "",
    });
}
