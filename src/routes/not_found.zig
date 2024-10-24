const std = @import("std");

const zzz = @import("zzz");
const http = zzz.HTTP;

const NotFoundTemplate = @import("../templates/lib.zig").NotFoundTemplate;

pub fn NotFoundHandler(_: http.Request, response: *http.Response, _: http.Context) void {
    response.set(.{
        .status = .@"Not Found",
        .mime = http.Mime.HTML,
        .body = NotFoundTemplate("<h2 class=\"center\">nothing yet...</h2>"),
    });
}
