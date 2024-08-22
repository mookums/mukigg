const std = @import("std");
const zzz = @import("zzz");

const HomeHandler = @import("routes/home.zig").HomeHandler;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var router = zzz.Router.init(allocator);
    // Basscss v8.0.2
    try router.serve_embedded_file("/embed/basscss.min.css", zzz.Mime.CSS, @embedFile("embed/basscss.min.css"));
    // Picocss v2.0.6
    try router.serve_embedded_file("/embed/pico.min.css", zzz.Mime.CSS, @embedFile("embed/pico.min.css"));
    // HTMX v2.0.2
    try router.serve_embedded_file("/embed/htmx.min.js", zzz.Mime.JS, @embedFile("embed/htmx.min.js"));

    try router.serve_route("/", zzz.Route.init().get(HomeHandler));

    var server = zzz.Server.init(.{
        .allocator = allocator,
        .threading = .{ .multi_threaded = .auto },
    }, router);

    try server.bind("0.0.0.0", 8080);
    try server.listen();
}
