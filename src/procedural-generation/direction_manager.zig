const std = @import("std");
const Direction = @import("direction.zig").Direction;
const Point = @Vector(2, i8);

const GridManager = @import("grid_manager.zig").GridManager;

pub const DirectionManager = struct {
    start_direction: Direction = undefined,
    end_direction: Direction = undefined,
    start_vector: Point = undefined,
    rng: std.Random.DefaultPrng = undefined,

    pub fn init_directions(self: *DirectionManager, start_point: Point, end_point: Point, grid: *const GridManager) !void {
        self.start_direction = self.calculate_start_direction(start_point, grid);
        self.end_direction = self.calculate_end_direction(end_point, grid);
        self.start_vector = self.direction_to_vector(self.start_direction);
        self.rng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));

        std.debug.print("Generated directions: Start = {}, End = {}.\n", .{ self.start_direction, self.end_direction });
    }

    fn calculate_start_direction(self: *const DirectionManager, start_point: Point, grid: *const GridManager) Direction {
        _ = self;
        if (start_point[0] == 0) return Direction.right;
        if (start_point[0] == grid.width - 1) return Direction.left;
        if (start_point[1] == 0) return Direction.down;
        if (start_point[1] == grid.height - 1) return Direction.up;
        return Direction.down;
    }

    fn calculate_end_direction(self: *const DirectionManager, end_point: Point, grid: *const GridManager) Direction {
        _ = self;
        if (end_point[0] == 0) return Direction.left;
        if (end_point[0] == grid.width - 1) return Direction.right;
        if (end_point[1] == 0) return Direction.down;
        if (end_point[1] == grid.height - 1) return Direction.up;
        return Direction.up;
    }

    pub fn direction_to_vector(self: *const DirectionManager, direction: Direction) Point {
        _ = self;
        return switch (direction) {
            .right => Point{ 1, 0 },
            .left => Point{ -1, 0 },
            .up => Point{ 0, -1 },
            .down => Point{ 0, 1 },
        };
    }

    pub fn is_opposite(self: *const DirectionManager, first_direction: Direction, second_direction: Direction) bool {
        _ = self;
        return (first_direction == Direction.up and second_direction == Direction.down) or
            (first_direction == Direction.down and second_direction == Direction.up) or
            (first_direction == Direction.left and second_direction == Direction.right) or
            (first_direction == Direction.right and second_direction == Direction.left);
    }

    pub fn get_random_directions(self: *DirectionManager) [4]Direction {
        var directions = [_]Direction{ Direction.right, Direction.left, Direction.up, Direction.down };
        self.shuffle_directions(&directions);
        return directions;
    }

    fn shuffle_directions(self: *DirectionManager, directions: *[4]Direction) void {
        const random = self.rng.random();
        var i: usize = directions.len - 1;
        while (i > 0) : (i -= 1) {
            const j = random.intRangeAtMost(usize, 0, i);
            const temp = directions[i];
            directions[i] = directions[j];
            directions[j] = temp;
        }
    }
};
