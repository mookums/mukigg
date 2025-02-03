const std = @import("std");

const zzz = @import("zzz");
const http = zzz.HTTP;

const Context = http.Context;
const Respond = http.Respond;

const NotFoundTemplate = @import("../templates/lib.zig").NotFoundTemplate;

pub fn not_found_handler(_: *const Context, _: void) !Respond {
    return Respond{ .standard = .{
        .status = .@"Not Found",
        .mime = http.Mime.HTML,
        .body = NotFoundTemplate("<h2 class=\"center\">nothing yet...</h2>"),
    } };
}
