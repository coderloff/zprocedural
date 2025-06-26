const std = @import("std");

const State = @import("state.zig").State;
const Direction = @import("direction.zig").Direction;
const Vector2Int = @Vector(2, i8);

const gridManager = @import("gridManager.zig");
const directionManager = @import("directionManager.zig");

var _attempts: u8 = 100;

const PathError = error{
    GridNotInitialized,
    OutOfAttempts,
    InfiniteRecursion,
};

pub fn generatePath(allocator: std.mem.Allocator, width: u8, height: u8) !void {
    gridManager.initializeGrid(allocator, width, height) catch |err| {
        std.debug.print("Error initializing grid: {}\n", .{err});
        return err;
    };

    defer gridManager.deinitializeGrid(allocator);

    for (0.._attempts) |attempt| {
        std.debug.print("Attempt {d} to generate path...\n", .{attempt + 1});

        if (!try gridManager.generateGrid()) {
            std.debug.print("Attempt {d} failed to generate a valid grid.\n", .{attempt});
            continue;
        }

        directionManager.initializeDirections(gridManager.getStartPoint(), gridManager.getEndPoint()) catch |err| {
            std.debug.print("Error initializing directions: {}\n", .{err});
            return err;
        };

        const firstSection = gridManager.getStartPoint();
        const secondSection = firstSection + directionManager.getStartVector();
        const nextPoint = secondSection + directionManager.getStartVector();

        const state = try gridManager.placeElements(false, directionManager.getStartDirection(), gridManager.getStartPoint(), firstSection, secondSection, nextPoint);
        if (state == State.Failed) continue;

        if (try generateFrom(nextPoint, directionManager.getStartDirection(), 0)) {
            visualizePath();
            std.debug.print("Path generated successfully after {d} attempts.\n", .{attempt + 1});
            return;
        }
    }

    std.debug.print("Failed to generate path after multiple attempts.", .{});
}

fn generateFrom(currentPosition: Vector2Int, previousDirection: Direction, depth: u8) !bool {
    if (depth > gridManager.getWidth() * gridManager.getHeight()) return PathError.InfiniteRecursion; // Prevent infinite recursion

    const randomDirections = directionManager.getRandomDirections();

    for (randomDirections) |direction| {
        if (directionManager.isOpposite(previousDirection, direction)) continue; // Skip opposite direction

        const needsJoint = direction != previousDirection;

        const directionVector = directionManager.directionToVector(direction);

        const firstSection = switch (needsJoint) {
            true => currentPosition + directionVector,
            false => currentPosition,
        };
        const secondSection = firstSection + directionVector;
        const nextPoint = secondSection + directionVector;

        const state = try gridManager.placeElements(needsJoint, direction, currentPosition, firstSection, secondSection, nextPoint);

        if (state == State.Failed) continue else if (state == State.Success) return true;

        if (try generateFrom(nextPoint, direction, depth + 1))
            return true; // Path found

        // If we reach here, it means the path was not successful, so we can backtrack
        gridManager.backtrack(needsJoint, currentPosition, firstSection, secondSection);
    }

    return false; // No valid path found in this direction
}

fn visualizePath() void {
    const grid = gridManager.getGrid();
    for (0..gridManager.getHeight()) |y| {
        for (0..gridManager.getWidth()) |x| {
            const element = grid[@intCast(x)][@intCast(y)];
            switch (element) {
                .None => std.debug.print(". ", .{}),
                .Section => std.debug.print("= ", .{}),
                .Joint => std.debug.print("* ", .{}),
            }
        }
        std.debug.print("\n", .{});
    }
}
