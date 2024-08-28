const std = @import("std");
const builtin = @import("builtin");
const zzz = @import("zzz");

const config = @import("config");
const http = zzz.HTTP;

const HomeHandler = @import("routes/home.zig").HomeHandler;
const PostsHandler = @import("routes/posts.zig").PostsHandler;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var router = http.Router.init(allocator);
    defer router.deinit();

    // Basscss v8.0.2
    try router.serve_embedded_file("/embed/basscss.min.css", http.Mime.CSS, @embedFile("embed/basscss.min.css"));
    // Picocss v2.0.6
    try router.serve_embedded_file("/embed/pico.min.css", http.Mime.CSS, @embedFile("embed/pico.min.css"));

    try router.serve_route("/", http.Route.init().get(HomeHandler));
    try router.serve_route("/posts", http.Route.init().get(PostsHandler));

    // In debug mode, just use HTTP.
    const encryption = blk: {
        if (comptime config.tls) {
            break :blk .{
                .tls = .{
                    .cert = "/etc/letsencrypt/live/muki.gg/cert.pem",
                    .key = "/etc/letsencrypt/live/muki.gg/privkey.pem",
                },
            };
        } else {
            break :blk .plain;
        }
    };

    var server = http.Server.init(.{
        .allocator = allocator,
        .threading = .{ .multi_threaded = .auto },
        .encryption = encryption,
    }, null);
    defer server.deinit();

    try server.bind("0.0.0.0", config.port);
    try server.listen(.{
        .router = &router,
    });
}
