const std = @import("std");

const zzz = @import("zzz");
const http = zzz.HTTP;

const Server = @import("../main.zig").Server;
const Context = Server.Context;

const NotFoundTemplate = @import("../templates/lib.zig").NotFoundTemplate;

pub fn not_found_handler(ctx: *Context) !void {
    try ctx.respond(.{
        .status = .@"Not Found",
        .mime = http.Mime.HTML,
        .body = NotFoundTemplate("<h2 class=\"center\">nothing yet...</h2>"),
    });
}
