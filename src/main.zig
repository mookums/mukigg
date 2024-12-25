const std = @import("std");
const builtin = @import("builtin");

const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.io_uring);
const Runtime = tardy.Runtime;

const home_handler = @import("routes/home.zig").home_handler;
const post_handler = @import("routes/post.zig").post_handler;
const not_found_handler = @import("routes/not_found.zig").not_found_handler;

pub const std_options = .{
    .log_level = .info,
};

pub const Server = http.Server;
const Context = http.Context;
const Router = http.Router;
const Route = http.Route;

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

    var router = try Router.init(
        allocator,
        &.{
            Route.init("embed/bundle.js").embed_file(
                .{
                    .encoding = .gzip,
                    .mime = http.Mime.JS,
                },
                @embedFile("bundle/bundle.js.gz"),
            ).layer(),
            Route.init("/").get({}, home_handler).layer(),
            Route.init("/post/%s").get({}, post_handler).layer(),
        },
        .{
            .not_found = not_found_handler,
        },
    );

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
                var server = Server.init(rt.allocator, .{ .header_count_max = 64 });
                try server.bind(.{ .ip = .{ .host = p.addr, .port = p.port } });
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
