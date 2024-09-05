const std = @import("std");

const zzz = @import("zzz");
const http = zzz.HTTP;

const posts = @import("../posts/gen.zig").posts;

const PostTemplate = @import("../templates/lib.zig").PostTemplate;

pub fn PostHandler(_: http.Request, response: *http.Response, ctx: http.Context) void {
    const post_id = ctx.captures[0].String;

    for (posts) |post| {
        if (std.mem.eql(u8, post.id, post_id)) {
            response.set(.{
                .status = .OK,
                .mime = http.Mime.HTML,
                .body = PostTemplate(ctx.allocator, post),
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
