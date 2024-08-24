const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const HomeHandler = @import("routes/home.zig").HomeHandler;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var router = http.Router.init(allocator);
    defer router.deinit();

    // Basscss v8.0.2
    try router.serve_embedded_file("/embed/basscss.min.css", http.Mime.CSS, @embedFile("embed/basscss.min.css"));
    // Picocss v2.0.6
    try router.serve_embedded_file("/embed/pico.min.css", http.Mime.CSS, @embedFile("embed/pico.min.css"));

    try router.serve_route("/", http.Route.init().get(HomeHandler));

    var server = http.Server.init(.{ .allocator = allocator }, null);
    defer server.deinit();

    try server.bind("0.0.0.0", 8080);
    try server.listen(.{ .router = &router });
}
