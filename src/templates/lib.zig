const std = @import("std");

const base_template = @embedFile("base.html");
const header_template = @embedFile("components/header.html");
const home_template = @embedFile("home.html");

const BaseFields = struct {
    title: []const u8 = "",
    head: []const u8 = "",
    body: []const u8 = "",
};
pub fn BaseTemplate(comptime fields: BaseFields) []const u8 {
    return std.fmt.comptimePrint(base_template, fields);
}

pub fn HomeTemplate() []const u8 {
    return std.fmt.comptimePrint(
        comptime BaseTemplate(.{
            .title = "home | muki.gg",
            .body = home_template,
        }),
        .{ .header = header_template },
    );
}
