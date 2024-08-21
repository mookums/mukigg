const std = @import("std");
const zzz = @import("zzz");

pub fn BaseHandler(_: zzz.Request, response: *zzz.Response, context: zzz.Context) void {
    const template = comptime @embedFile("../templates/base.html");

    const body = std.fmt.allocPrint(context.allocator, template, .{
        "title | muki.gg",
        "",
        "<h1>Hello!</h1>",
    }) catch {
        response.set(.{
            .status = .@"Internal Server Error",
            .mime = zzz.Mime.HTML,
            .body = "",
        });

        return;
    };

    response.set(.{
        .status = .OK,
        .mime = zzz.Mime.HTML,
        .body = body,
    });
}
