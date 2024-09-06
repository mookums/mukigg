const std = @import("std");
const builtin = @import("builtin");
const zzz = @import("zzz");

const config = @import("config");
const http = zzz.HTTP;

const HomeHandler = @import("routes/home.zig").HomeHandler;
const PostHandler = @import("routes/post.zig").PostHandler;

pub const std_options = .{
    .log_level = .info,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var router = http.Router.init(allocator);
    defer router.deinit();

    // Basscss v8.0.2
    try router.serve_embedded_file("/embed/basscss.min.css", http.Mime.CSS, @embedFile("embed/basscss.min.css"));
    try router.serve_embedded_file("/embed/muki.css", http.Mime.CSS, @embedFile("embed/muki.css"));

    // Prism for Code Highlighting
    //
    // Currently:
    // - Default Theme
    // - Toolbar
    // - Copy to Clipboard Button
    // - Normalize Whitespace
    // - Zig Syntax Support
    try router.serve_embedded_file("/embed/prism.css", http.Mime.CSS, @embedFile("embed/prism.css"));
    try router.serve_embedded_file("/embed/prism.js", http.Mime.JS, @embedFile("embed/prism.js"));

    try router.serve_route("/", http.Route.init().get(HomeHandler));
    try router.serve_route("/post/%s", http.Route.init().get(PostHandler));

    // In debug mode, just use HTTP.
    const encryption = blk: {
        if (comptime config.tls) {
            break :blk .{
                .tls = .{
                    .cert = .{
                        .file = .{ .path = "/etc/letsencrypt/live/muki.gg/cert.pem" },
                    },
                    .cert_name = "CERTIFICATE",
                    .key = .{
                        .file = .{ .path = "/etc/letsencrypt/live/muki.gg/privkey.pem" },
                    },
                    .key_name = "PRIVATE KEY",
                },
            };
        } else {
            break :blk .plain;
        }
    };

    var server = http.Server(encryption).init(.{
        .allocator = allocator,
        .threading = .{ .multi_threaded = .auto },
    }, null);
    defer server.deinit();

    try server.bind("0.0.0.0", config.port);
    try server.listen(.{
        .router = &router,
    });
}
