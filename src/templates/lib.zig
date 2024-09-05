const std = @import("std");

const base_template = @embedFile("base.html");
const header_template = @embedFile("components/header.html");

const BaseFields = struct {
    title: []const u8 = "",
    head: []const u8 = "",
    body: []const u8 = "",
};

pub fn BaseTemplate(comptime fields: BaseFields) []const u8 {
    return std.fmt.comptimePrint(base_template, fields);
}

const home_template = @embedFile("home.html");

pub fn HomeTemplate(comptime post_entries: []const u8) []const u8 {
    const no_posts = post_entries.len == 0;
    const entries = if (no_posts) "<li>no posts! come back later :p</li>" else post_entries;

    return std.fmt.comptimePrint(
        BaseTemplate(.{
            .title = "home | muki.gg",
            .body = home_template,
        }),
        .{
            .header = header_template,
            .posts = entries,
        },
    );
}

const Post = @import("../post.zig").Post;
const post_entry_template = @embedFile("components/post_entry.html");

pub fn PostEntryTemplate(comptime post: Post) []const u8 {
    return std.fmt.comptimePrint(post_entry_template, .{
        .id = post.id,
        .name = post.name,
        .date = post.date,
    });
}

const post_template = @embedFile("post.html");

pub fn PostTemplate(comptime post: Post) []const u8 {
    return std.fmt.comptimePrint(
        BaseTemplate(
            .{
                .title = std.fmt.comptimePrint("{s} | {s}", .{ post.name, "muki.gg" }),
                .body = post_template,
            },
        ),
        .{
            .header = header_template,
            .body = post.body,
        },
    );
}
