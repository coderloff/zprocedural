const std = @import("std");

const PathGenerator = @import("procedural-generation/path_generator.zig").PathGenerator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var generator = PathGenerator.init(allocator);
    defer generator.deinit();

    generator.generate_path(10, 10) catch |err| {
        std.debug.print("Error generating path: {}\n", .{err});
    };
}
