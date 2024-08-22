const std = @import("std");

const base_template = @embedFile("base.html");
const header_template = @embedFile("components/header.html");
const home_template = @embedFile("home.html");

pub fn BaseTemplate(comptime title: []const u8, comptime head: []const u8, comptime body: []const u8) []const u8 {
    return std.fmt.comptimePrint(base_template, .{
        .title = title,
        .head = head,
        .body = body,
    });
}

pub fn HomeTemplate() []const u8 {
    return std.fmt.comptimePrint(
        comptime BaseTemplate("home | muki.gg", "", home_template),
        .{ .header = header_template },
    );
}
