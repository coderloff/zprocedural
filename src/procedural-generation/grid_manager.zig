const std = @import("std");
const Point = @Vector(2, i8);
const Element = @import("element.zig").Element;
const Direction = @import("direction.zig").Direction;
const State = @import("state.zig").State;
const PathError = @import("path_error.zig").PathError;

const DirectionManager = @import("direction_manager.zig").DirectionManager;

pub const GridManager = struct {
    width: u8 = 0,
    height: u8 = 0,
    grid: [][]Element = &[_][]Element{},
    start_point: Point = undefined,
    end_point: Point = undefined,
    rng: std.Random.DefaultPrng = undefined,

    pub fn init(self: *GridManager, allocator: std.mem.Allocator, width: u8, height: u8) !void {
        if (width <= 0 or height <= 0) return PathError.invalid_dimensions;
        if (width > 255 or height > 255) return PathError.dimensions_too_large;

        self.width = width;
        self.height = height;
        self.grid = allocator.alloc([]Element, width) catch return PathError.out_of_memory;

        for (self.grid) |*row| {
            row.* = try allocator.alloc(Element, height);
        }

        self.rng = std.Random.DefaultPrng.init(@abs(std.time.milliTimestamp()));
        self.clear();

        std.debug.print("Grid initialized with dimensions {}x{}.\n", .{ width, height });
    }

    pub fn deinit(self: *GridManager, allocator: std.mem.Allocator) void {
        for (self.grid) |row| {
            allocator.free(row);
        }
        if (self.grid.len > 0) {
            allocator.free(self.grid);
        }
        self.grid = &[_][]Element{};
    }

    pub fn generate_start_end_points(self: *GridManager) !bool {
        self.clear();

        self.start_point = try self.get_random_border_point();
        self.end_point = try self.get_random_border_point();

        std.debug.print("Start point: {}, End point: {}.\n", .{ self.start_point, self.end_point });
        return !(self.start_point[0] == self.end_point[0] and self.start_point[1] == self.end_point[1]);
    }

    pub fn place_elements(self: *GridManager, needs_joint: bool, direction: Direction, current_position: Point, first_section: Point, second_section: Point, next_point: Point, direction_helper: *const DirectionManager) !State {
        if (!self.is_inside_grid(current_position) or !self.is_inside_grid(first_section) or !self.is_inside_grid(second_section)) {
            return State.failed;
        }
        if (!try self.is_cell_empty(current_position) or !try self.is_cell_empty(first_section) or !try self.is_cell_empty(second_section)) {
            return State.failed;
        }

        if (needs_joint and self.grid[@intCast(current_position[0])][@intCast(current_position[1])] == Element.joint) {
            return State.failed;
        }

        if (second_section[0] == self.end_point[0] and second_section[1] == self.end_point[1]) {
            if (direction != direction_helper.end_direction) return State.failed;

            self.set_elements(needs_joint, current_position, first_section, second_section);
            return State.success;
        }

        if (!self.is_inside_grid(next_point) or !try self.is_cell_empty(next_point)) {
            return State.failed;
        }

        self.set_elements(needs_joint, current_position, first_section, second_section);
        return State.in_progress;
    }

    fn set_elements(self: *GridManager, needs_joint: bool, current_position: Point, first_section: Point, second_section: Point) void {
        if (needs_joint) {
            self.grid[@intCast(current_position[0])][@intCast(current_position[1])] = Element.joint;
        }
        self.grid[@intCast(first_section[0])][@intCast(first_section[1])] = Element.section;
        self.grid[@intCast(second_section[0])][@intCast(second_section[1])] = Element.section;
    }

    pub fn backtrack(self: *GridManager, needs_joint: bool, current_position: Point, first_section: Point, second_section: Point) void {
        if (needs_joint) {
            self.grid[@intCast(current_position[0])][@intCast(current_position[1])] = Element.none;
        }
        self.grid[@intCast(first_section[0])][@intCast(first_section[1])] = Element.none;
        self.grid[@intCast(second_section[0])][@intCast(second_section[1])] = Element.none;
    }

    pub fn is_inside_grid(self: *const GridManager, point: Point) bool {
        return point[0] >= 0 and point[0] < self.width and point[1] >= 0 and point[1] < self.height;
    }

    pub fn is_cell_empty(self: *const GridManager, point: Point) !bool {
        if (!self.is_inside_grid(point)) return PathError.index_out_of_bounds;
        return self.grid[@intCast(point[0])][@intCast(point[1])] == Element.none;
    }

    fn get_random_border_point(self: *GridManager) !Point {
        const random = self.rng.random();
        const side: u8 = random.intRangeAtMost(u8, 0, 3); // 0: Top, 1: Right, 2: Bottom, 3: Left

        return switch (side) {
            0 => Point{ random.intRangeAtMost(i8, 0, @intCast(self.width - 1)), 0 }, // Top border
            1 => Point{ @intCast(self.width - 1), random.intRangeAtMost(i8, 0, @intCast(self.height - 1)) }, // Right border
            2 => Point{ random.intRangeAtMost(i8, 0, @intCast(self.width - 1)), @intCast(self.height - 1) }, // Bottom border
            3 => Point{ 0, random.intRangeAtMost(i8, 0, @intCast(self.height - 1)) }, // Left border
            else => return PathError.invalid_dimensions,
        };
    }

    fn clear(self: *GridManager) void {
        for (0..self.width) |i| {
            for (0..self.height) |j| {
                self.grid[i][j] = Element.none;
            }
        }
    }
};
