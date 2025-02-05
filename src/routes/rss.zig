const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const Context = http.Context;
const Respond = http.Respond;

const posts = @import("../posts/gen.zig").posts;

pub fn rss_handler(_: *const Context, _: void) !Respond {
    const start_chunk =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        \\<channel>
        \\<title>muki.gg</title>
        \\<atom:link href="https://muki.gg/rss.xml" rel="self" type="application/rss+xml"/>
        \\<link>https://muki.gg</link>
        \\<description></description>
        \\<language>en-us</language>
    ;

    const end_chunk =
        \\</channel>
        \\</rss>
    ;

    const item_fmt =
        \\<item>
        \\<title>{[title]s}</title>
        \\<link>{[link]s}</link>
        \\<guid>{[guid]s}</guid>
        \\</item>
    ;

    const body = comptime blk: {
        var items: []const u8 = &.{};
        for (posts) |post| {
            const link = std.fmt.comptimePrint("https://muki.gg/post/{s}", .{post.id});
            const item = std.fmt.comptimePrint(item_fmt, .{
                .title = post.name,
                .link = link,
                .guid = link,
            });

            items = std.fmt.comptimePrint("{s}\n{s}", .{ items, item });
        }

        break :blk std.fmt.comptimePrint("{s}{s}{s}", .{ start_chunk, items, end_chunk });
    };

    return Respond{ .standard = .{
        .status = .OK,
        .mime = http.Mime.XML,
        .body = body,
    } };
}
