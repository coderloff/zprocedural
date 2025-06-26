const std = @import("std");
const Vector2Int = @Vector(2, i8);

const Direction = @import("direction.zig").Direction;

const gridManager = @import("gridManager.zig");

var _startDirection: Direction = undefined;
var _endDirection: Direction = undefined;
var _startVector: Vector2Int = undefined;

// pub fn initializeDirections(startDirection: Direction, endDirection: Direction) !void {
//     _startDirection = startDirection; // Example initialization
//     _endDirection = endDirection; // Example initialization
//     std.debug.print("Directions initialized: Start = {}, End = {}.\n", .{ startDirection, endDirection });
// }

pub fn initializeDirections(startPoint: Vector2Int, endPoint: Vector2Int) !void {
    _startDirection = setStartDirection(startPoint);
    _endDirection = setEndDirection(endPoint);
    _startVector = directionToVector(_startDirection);

    std.debug.print("Generated directions: Start = {}, End = {}.\n", .{ _startDirection, _endDirection });
}

pub fn setStartDirection(startPoint: Vector2Int) Direction {
    // Example logic to determine start direction based on startPoint

    if (startPoint[0] == 0) return Direction.Right;
    if (startPoint[0] == gridManager.getWidth() - 1) return Direction.Left;
    if (startPoint[1] == 0) return Direction.Up;
    if (startPoint[1] == gridManager.getHeight() - 1) return Direction.Down;
    return Direction.Down; // Fallback case
}

pub fn setEndDirection(startPoint: Vector2Int) Direction {
    // Example logic to determine start direction based on startPoint

    if (startPoint[0] == 0) return Direction.Left;
    if (startPoint[0] == gridManager.getWidth() - 1) return Direction.Right;
    if (startPoint[1] == 0) return Direction.Down;
    if (startPoint[1] == gridManager.getHeight() - 1) return Direction.Up;
    return Direction.Up; // Fallback case
}

pub fn directionToVector(direction: Direction) Vector2Int {
    return switch (direction) {
        .Right => Vector2Int{ 1, 0 },
        .Left => Vector2Int{ -1, 0 },
        .Up => Vector2Int{ 0, -1 },
        .Down => Vector2Int{ 0, 1 },
    };
}

pub fn isOpposite(firstDirection: Direction, secondDirection: Direction) bool {
    return (firstDirection == Direction.Up and secondDirection == Direction.Down) or
        (firstDirection == Direction.Down and secondDirection == Direction.Up) or
        (firstDirection == Direction.Left and secondDirection == Direction.Right) or
        (firstDirection == Direction.Right and secondDirection == Direction.Left);
}

pub fn getStartDirection() Direction {
    return _startDirection;
}

pub fn getEndDirection() Direction {
    return _endDirection;
}

pub fn getStartVector() Vector2Int {
    return _startVector;
}

pub fn getRandomDirections() [4]Direction {
    var directions = [_]Direction{
        Direction.Right,
        Direction.Left,
        Direction.Up,
        Direction.Down,
    };
    shuffleDirections(&directions) catch |err| {
        std.debug.print("Error shuffling directions: {}\n", .{err});
        return [_]Direction{};
    };
    return directions;
}

// Fisher-Yates shuffle to randomize directions using pointer
pub fn shuffleDirections(directions: *[4]Direction) !void {
    if (directions.len == 0) {
        return error.EmptyDirections;
    }
    if (directions.len < 2) {
        return error.InsufficientDirections;
    }

    var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    const random = prng.random();
    var i: usize = directions.len - 1;
    while (i > 0) : (i -= 1) {
        const j = random.intRangeAtMost(usize, 0, i);
        const temp = directions[i];
        directions[i] = directions[j];
        directions[j] = temp;
    }
}

// const DirectionManager = struct {
//     directions: []Direction,

//     pub fn init(allocator: std.mem.Allocator) !DirectionManager {
//         var manager = DirectionManager{
//             .directions = try allocator.alloc(Direction, 0),
//         };
//         return manager;
//     }

//     pub fn addDirection(self: *DirectionManager, direction: Direction) !void {
//         self.directions = try std.mem.append(self.directions, direction);
//     }

//     pub fn getDirections(self: *const DirectionManager) []const Direction {
//         return self.directions;
//     }

//     pub fn clear(self: *DirectionManager) void {
//         self.directions = &[_]Direction{};
//     }
// };
