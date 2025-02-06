const std = @import("std");
const builtin = @import("builtin");

const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.io_uring);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;

const RateLimitConfig = http.Middlewares.RateLimitConfig;
const RateLimiting = http.Middlewares.RateLimiting;
const Compression = http.Middlewares.Compression;

const home_handler = @import("routes/home.zig").home_handler;
const post_handler = @import("routes/post.zig").post_handler;
const not_found_handler = @import("routes/not_found.zig").not_found_handler;
const rss_handler = @import("routes/rss.zig").rss_handler;

pub const std_options = .{ .log_level = .info };

pub const Server = http.Server;
const Context = http.Context;
const Router = http.Router;
const Route = http.Route;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const addr = try std.process.getEnvVarOwned(allocator, "ADDR");
    defer allocator.free(addr);
    const port_env = try std.process.getEnvVarOwned(allocator, "PORT");
    defer allocator.free(port_env);
    const port = try std.fmt.parseInt(u16, port_env, 10);

    var t = try Tardy.init(allocator, .{ .threading = .auto });
    defer t.deinit();

    var config = RateLimitConfig.init(allocator, 5, 30, null);
    defer config.deinit();

    var router = try Router.init(
        allocator,
        &.{
            RateLimiting(&config),
            Route.init("embed/bundle.js").embed_file(
                .{ .encoding = .gzip, .mime = http.Mime.JS },
                @embedFile("bundle/bundle.js.gz"),
            ).layer(),
            Route.init("embed/bundle.css").embed_file(
                .{ .encoding = .gzip, .mime = http.Mime.CSS },
                @embedFile("bundle/bundle.css.gz"),
            ).layer(),

            Compression(.{ .gzip = .{} }),

            Route.init("/").get({}, home_handler).layer(),
            Route.init("/post/%s").get({}, post_handler).layer(),
            Route.init("/muki.asc").embed_file(
                .{ .mime = http.Mime.BIN },
                @embedFile("static/muki.asc"),
            ).layer(),
            Route.init("/rss.xml").get({}, rss_handler).layer(),
        },
        .{
            .not_found = not_found_handler,
        },
    );

    var socket = try Socket.init(.{ .tcp = .{ .host = addr, .port = port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(1024);

    const EntryParams = struct { router: *const Router, socket: Socket };

    try t.entry(
        EntryParams{ .router = &router, .socket = socket },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                var server = Server.init(rt.allocator, .{
                    .stack_size = 1024 * 1024 * 4,
                    .header_count_max = 64,
                });
                try server.serve(rt, p.router, p.socket);
            }
        }.entry,
    );
}
