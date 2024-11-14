const std = @import("std");
const builtin = @import("builtin");

const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = @import("tardy");
const Tardy = tardy.Tardy(.io_uring);
const Runtime = tardy.Runtime;

const config = @import("config");

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
                .cert_name = "CERTIFICATE",
                .cert = .{ .file = .{ .path = "/etc/letsencrypt/live/muki.gg/cert.pem" } },
                .key_name = "PRIVATE KEY",
                .key = .{ .file = .{ .path = "/etc/letsencrypt/live/muki.gg/privkey.pem" } },
            },
        };
    } else {
        break :blk .plain;
    }
};

pub const Server = http.Server(encryption);
const Context = Server.Context;
const Router = Server.Router;
const Route = Server.Route;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const addr = std.process.getEnvVarOwned(allocator, "ADDR") catch "0.0.0.0";
    defer allocator.free(addr);
    const port_env = std.process.getEnvVarOwned(allocator, "PORT") catch "8080";
    defer allocator.free(port_env);
    const port = try std.fmt.parseInt(u16, port_env, 10);

    var t = try Tardy.init(.{
        .allocator = allocator,
        .threading = .auto,
    });
    defer t.deinit();

    var router = Router.init(allocator);
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

    try router.serve_route("/", Route.init().get({}, HomeHandler));
    try router.serve_route("/post/%s", Route.init().get({}, PostHandler));
    router.serve_not_found(Route.init().get({}, NotFoundHandler));

    const EntryParams = struct {
        router: *const Router,
        addr: []const u8,
        port: u16,
    };

    const params: EntryParams = .{
        .router = &router,
        .addr = addr,
        .port = port,
    };

    try t.entry(
        &params,
        struct {
            fn entry(rt: *Runtime, p: *const EntryParams) !void {
                var server = Server.init(.{ .allocator = rt.allocator });
                try server.bind(p.addr, p.port);
                try server.serve(p.router, rt);
            }
        }.entry,
        {},
        struct {
            fn exit(rt: *Runtime, _: void) !void {
                try Server.clean(rt);
            }
        }.exit,
    );
}
