const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const HomeTemplate = @import("../templates/lib.zig").HomeTemplate;

pub fn HomeHandler(_: http.Request, response: *http.Response, _: http.Context) void {
    const body = comptime HomeTemplate();

    response.set(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    });
}
