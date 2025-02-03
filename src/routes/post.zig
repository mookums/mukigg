const std = @import("std");
const builtin = @import("builtin");
const zzz = @import("zzz");
const http = zzz.HTTP;

const Context = http.Context;
const Respond = http.Respond;

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

pub fn post_handler(ctx: *const Context, _: void) !Respond {
    const post_id = ctx.captures[0].string;

    for (posts, 0..) |post, i| {
        if (std.mem.eql(u8, post.id, post_id)) {
            var headers = std.ArrayList([2][]const u8).init(ctx.allocator);
            defer headers.deinit();

            // Add caching headers.
            try headers.append(.{ "ETag", post.etag });

            if (comptime builtin.mode != .Debug) try headers.append(.{ "Cache-Control", "max-age=604800" });

            if (ctx.request.headers.get("If-None-Match")) |etag| {
                if (std.mem.eql(u8, post.etag, etag)) {
                    return Respond{ .standard = .{
                        .status = .@"Not Modified",
                        .mime = http.Mime.HTML,
                        .body = "",
                        .headers = try headers.toOwnedSlice(),
                    } };
                }
            }

            return Respond{ .standard = .{
                .status = .OK,
                .mime = http.Mime.HTML,
                .body = post_bodies[i],
                .headers = try headers.toOwnedSlice(),
            } };
        }
    }
    return Respond{ .standard = .{
        .status = .@"Not Found",
        .mime = http.Mime.HTML,
        .body = NotFoundTemplate("<h2 class=\"center\">404 | post not found</h2>"),
    } };
}
