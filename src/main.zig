const std = @import("std");

const pathGenerator = @import("procedural-generation/pathGenerator.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.deinit();

    pathGenerator.generatePath(allocator, 10, 10) catch |err| {
        std.debug.print("Error generating path: {}\n", .{err});
    };
}
