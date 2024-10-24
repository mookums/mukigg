const std = @import("std");
const builtin = @import("builtin");
const zzz = @import("zzz");

const config = @import("config");
const http = zzz.HTTP;

const HomeHandler = @import("routes/home.zig").HomeHandler;
const PostHandler = @import("routes/post.zig").PostHandler;
const NotFoundHandler = @import("routes/not_found.zig").NotFoundHandler;

pub const std_options = .{
    .log_level = .info,
};

const encryption = blk: {
    if (config.tls) {
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

const http_server = http.Server(encryption, .io_uring);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var router = http.Router.init(allocator);
    defer router.deinit();

    // Basscss v8.0.2
    try router.serve_embedded_file("/embed/basscss.min.css", http.Mime.CSS, @embedFile("embed/basscss.min.css"));

    // Prism for Code Highlighting
    //
    // Currently:
    // - Default Theme
    // - Normalize Whitespace
    // - Zig Syntax Support
    try router.serve_embedded_file("/embed/prism.css", http.Mime.CSS, @embedFile("embed/prism.css"));
    try router.serve_embedded_file("/embed/prism.js", http.Mime.JS, @embedFile("embed/prism.js"));

    try router.serve_route("/", http.Route.init().get(HomeHandler));
    try router.serve_route("/post/%s", http.Route.init().get(PostHandler));
    try router.serve_route("/about", http.Route.init().get(NotFoundHandler));
    try router.serve_route("/resume", http.Route.init().get(NotFoundHandler));
    try router.serve_route("/links", http.Route.init().get(NotFoundHandler));

    // In debug mode, just use HTTP.

    var server = http_server.init(.{
        .allocator = allocator,
        .threading = .auto,
    });
    defer server.deinit();

    try server.bind("0.0.0.0", config.port);
    try server.listen(.{
        .router = &router,
    });
}
