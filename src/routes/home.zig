const std = @import("std");
const zzz = @import("zzz");

const HomeTemplate = @import("../templates/lib.zig").HomeTemplate;

pub fn HomeHandler(_: zzz.Request, response: *zzz.Response, _: zzz.Context) void {
    const body = HomeTemplate();

    response.set(.{
        .status = .OK,
        .mime = zzz.Mime.HTML,
        .body = body,
    });
}
