const std = @import("std");
const Vector2Int = @Vector(2, i8);

const Element = @import("element.zig").Element;
const Direction = @import("direction.zig").Direction;
const State = @import("state.zig").State;

const directionManager = @import("directionManager.zig");

var _width: u8 = 0;
var _height: u8 = 0;
var _grid: [][]Element = &[_][]Element{};

var _startPoint: Vector2Int = undefined;
var _endPoint: Vector2Int = undefined;

var prng: std.Random.DefaultPrng = undefined;
var random: std.Random = undefined;

const GridError = error{
    InvalidDimensions,
    DimensionsTooLarge,
    OutOfMemory,
    NotInitialized,
    IndexOutOfBounds,
};

pub fn initializeGrid(allocator: std.mem.Allocator, width: u8, height: u8) !void {
    if (width <= 0 or height <= 0) {
        return GridError.InvalidDimensions;
    }
    if (width > 255 or height > 255) {
        return GridError.DimensionsTooLarge;
    }

    _width = width;
    _height = height;
    _grid = allocator.alloc([]Element, _width) catch {
        return GridError.OutOfMemory;
    };

    for (_grid) |*row| {
        row.* = try allocator.alloc(Element, _height);
    }

    prng = std.Random.DefaultPrng.init(@abs(std.time.milliTimestamp()));
    random = prng.random();

    std.debug.print("Grid initialized with dimensions {}x{}.\n", .{ _width, _height });
}

pub fn deinitializeGrid(allocator: std.mem.Allocator) void {
    for (_grid) |*row| {
        allocator.free(row.*);
    }
    allocator.free(_grid);
    _grid = &[_][]Element{};
}

pub fn generateGrid() !bool {
    clearGrid();

    _startPoint = try getRandomBorderPoint();
    _endPoint = try getRandomBorderPoint();

    std.debug.print("Start point: {}, End point: {}.\n", .{ _startPoint, _endPoint });
    if (_startPoint[0] == _endPoint[0] and _startPoint[1] == _endPoint[1]) return false;

    return true;
}

pub fn placeElements(needsJoint: bool, direction: Direction, currentPosition: Vector2Int, firstSection: Vector2Int, secondSection: Vector2Int, nextPoint: Vector2Int) !State {
    if (!isInsideGrid(currentPosition) or !isInsideGrid(firstSection) or !isInsideGrid(secondSection)) return State.Failed;
    if (!try isCellEmpty(currentPosition) or !try isCellEmpty(firstSection) or !try isCellEmpty(secondSection)) return State.Failed;

    if (needsJoint and _grid[@intCast(currentPosition[0])][@intCast(currentPosition[1])] == Element.Joint) return State.Failed; // Joint already exists

    if (secondSection[0] == _endPoint[0] and secondSection[1] == _endPoint[1]) {
        if (direction != directionManager.getEndDirection()) return State.Failed; // Ensure the direction matches the end direction

        setElements(needsJoint, currentPosition, firstSection, secondSection);
        return State.Success;
    }

    if (!isInsideGrid(nextPoint)) return State.Failed; // Next point is out of bounds
    if (!try isCellEmpty(nextPoint)) return State.Failed; // Next point is not empty

    setElements(needsJoint, currentPosition, firstSection, secondSection);
    // std.debug.print("Placed elements at current position: {}, first section: {}, second section: {}.\n", .{ currentPosition, firstSection, secondSection });

    return State.InProgress;
}

pub fn setElements(needsJoint: bool, currentPosition: Vector2Int, firstSection: Vector2Int, secondSection: Vector2Int) void {
    if (needsJoint) _grid[@intCast(currentPosition[0])][@intCast(currentPosition[1])] = Element.Joint;
    _grid[@intCast(firstSection[0])][@intCast(firstSection[1])] = Element.Section;
    _grid[@intCast(secondSection[0])][@intCast(secondSection[1])] = Element.Section;
}

pub fn backtrack(needsJoint: bool, currentPosition: Vector2Int, firstSection: Vector2Int, secondSection: Vector2Int) void {
    if (needsJoint) _grid[@intCast(currentPosition[0])][@intCast(currentPosition[1])] = Element.None;
    _grid[@intCast(firstSection[0])][@intCast(firstSection[1])] = Element.None;
    _grid[@intCast(secondSection[0])][@intCast(secondSection[1])] = Element.None;
}

pub fn isInsideGrid(point: Vector2Int) bool {
    return point[0] >= 0 and point[0] < _width and point[1] >= 0 and point[1] < _height;
}

pub fn isCellEmpty(point: Vector2Int) !bool {
    if (point[0] < 0 or point[0] >= _width or point[1] < 0 or point[1] >= _height) {
        return GridError.IndexOutOfBounds;
    }
    return _grid[@intCast(point[0])][@intCast(point[1])] == Element.None;
}

pub fn getRandomBorderPoint() !Vector2Int {
    const side: u8 = random.intRangeAtMost(u8, 0, 3); // 0: Top, 1: Right, 2: Bottom, 3: Left

    return switch (side) {
        0 => Vector2Int{ random.intRangeAtMost(i8, 0, @intCast(_width - 1)), 0 }, // Top border
        1 => Vector2Int{ @intCast(_width - 1), random.intRangeAtMost(i8, 0, @intCast(_height - 1)) }, // Right border
        2 => Vector2Int{ random.intRangeAtMost(i8, 0, @intCast(_width - 1)), @intCast(_height - 1) }, // Bottom border
        3 => Vector2Int{ 0, random.intRangeAtMost(i8, 0, @intCast(_height - 1)) }, // Left border
        else => return GridError.InvalidDimensions,
    };
}

pub fn getWidth() u8 {
    return _width;
}

pub fn getHeight() u8 {
    return _height;
}

pub fn getGrid() [][]Element {
    return _grid;
}

pub fn getStartPoint() Vector2Int {
    return _startPoint;
}

pub fn getEndPoint() Vector2Int {
    return _endPoint;
}

pub fn getCell(point: Vector2Int) !Element {
    if (point[0] < 0 or point[0] >= _width or point[0] < 0 or point[0] >= _height) {
        return GridError.IndexOutOfBounds;
    }
    return _grid[@intCast(point[0])][@intCast(point[1])];
}

pub fn setCell(point: Vector2Int, value: Element) !void {
    if (point[0] < 0 or point[0] >= _width or point[0] < 0 or point[0] >= _height) {
        return GridError.IndexOutOfBounds;
    }
    _grid[@intCast(point[0])][@intCast(point[1])] = value;
}

pub fn clearGrid() void {
    for (0.._width) |i| {
        for (0.._height) |j| {
            _grid[i][j] = Element.None;
        }
    }
}
