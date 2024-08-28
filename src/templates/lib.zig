const std = @import("std");

const base_template = @embedFile("base.html");
const header_template = @embedFile("components/header.html");
const footer_template = @embedFile("components/footer.html");

const BaseFields = struct {
    title: []const u8 = "",
    head: []const u8 = "",
    body: []const u8 = "",
};
pub fn BaseTemplate(comptime fields: BaseFields) []const u8 {
    return std.fmt.comptimePrint(base_template, fields);
}

const home_template = @embedFile("home.html");

pub fn HomeTemplate() []const u8 {
    return std.fmt.comptimePrint(
        comptime BaseTemplate(.{
            .title = "home | muki.gg",
            .body = home_template,
        }),
        .{
            .header = header_template,
            .footer = footer_template,
        },
    );
}

const posts_template = @embedFile("posts.html");

pub fn PostsTemplate(allocator: std.mem.Allocator, posts: []const u8) []const u8 {
    return std.fmt.allocPrint(
        allocator,
        comptime BaseTemplate(.{
            .title = "posts | muki.gg",
            .body = posts_template,
        }),
        .{
            .header = header_template,
            .footer = footer_template,
            .posts = posts,
        },
    ) catch unreachable;
}
