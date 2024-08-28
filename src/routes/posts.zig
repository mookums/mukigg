const std = @import("std");
const log = std.log.scoped(.PostsHandler);
const zzz = @import("zzz");
const http = zzz.HTTP;

const posts = @import("../posts/gen.zig").posts;
const PostsTemplate = @import("../templates/lib.zig").PostsTemplate;

pub fn PostsHandler(_: http.Request, response: *http.Response, ctx: http.Context) void {
    const post_entry_fmt =
        \\<li>
        \\<p>
        \\<a href=\"/posts/{[id]d}\">
        \\{[title]s}
        \\</a>
        \\</p>
        \\</li>"
    ;

    var post_list = std.ArrayList(u8).init(ctx.allocator);

    for (0..posts.len) |i| {
        const backward_index = posts.len - i - 1;
        log.debug("Index: {d}", .{backward_index});
        const link = std.fmt.allocPrint(
            ctx.allocator,
            post_entry_fmt,
            .{ .id = backward_index, .title = posts[backward_index].title },
        ) catch unreachable;
        post_list.appendSlice(link) catch unreachable;
    }

    const body = PostsTemplate(ctx.allocator, post_list.toOwnedSlice() catch unreachable);

    response.set(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    });
}
