const std = @import("std");

const Point = @Vector(2, i8);
const Element = @import("element.zig").Element;
const Direction = @import("direction.zig").Direction;
const State = @import("state.zig").State;
const PathError = @import("path_error.zig").PathError;

const GridManager = @import("grid_manager.zig").GridManager;
const DirectionManager = @import("direction_manager.zig").DirectionManager;

pub const PathGenerator = struct {
    allocator: std.mem.Allocator,
    grid_manager: GridManager,
    direction_manager: DirectionManager,
    max_attempts: u8,

    pub fn init(allocator: std.mem.Allocator) PathGenerator {
        return PathGenerator{
            .allocator = allocator,
            .grid_manager = GridManager{},
            .direction_manager = DirectionManager{},
            .max_attempts = 100,
        };
    }

    pub fn deinit(self: *PathGenerator) void {
        self.grid_manager.deinit(self.allocator);
    }

    pub fn generate_path(self: *PathGenerator, width: u8, height: u8) !void {
        try self.grid_manager.init(self.allocator, width, height);

        for (0..self.max_attempts) |attempt| {
            std.debug.print("Attempt {d} to generate path...\n", .{attempt + 1});

            if (!try self.grid_manager.generate_start_end_points()) {
                std.debug.print("Attempt {d} failed to generate valid start/end points.\n", .{attempt + 1});
                continue;
            }

            try self.direction_manager.init_directions(self.grid_manager.start_point, self.grid_manager.end_point, &self.grid_manager);

            const first_section = self.grid_manager.start_point;
            const second_section = first_section + self.direction_manager.start_vector;
            const next_point = second_section + self.direction_manager.start_vector;

            const state = try self.grid_manager.place_elements(false, self.direction_manager.start_direction, self.grid_manager.start_point, first_section, second_section, next_point, &self.direction_manager);
            if (state == State.failed) continue;

            if (try self.generate_from(next_point, self.direction_manager.start_direction, 0)) {
                self.visualize_path();
                std.debug.print("Path generated successfully after {d} attempts.\n", .{attempt + 1});
                return;
            }
        }

        std.debug.print("Failed to generate path after {d} attempts.\n", .{self.max_attempts});
    }

    fn generate_from(self: *PathGenerator, current_position: Point, previous_direction: Direction, depth: u16) !bool {
        if (depth > @as(u16, self.grid_manager.width) * self.grid_manager.height) return PathError.infinite_recursion;

        const random_directions = self.direction_manager.get_random_directions();

        for (random_directions) |direction| {
            if (self.direction_manager.is_opposite(previous_direction, direction)) continue;

            const needs_joint = direction != previous_direction;
            const direction_vector = self.direction_manager.direction_to_vector(direction);

            const first_section = if (needs_joint) current_position + direction_vector else current_position;
            const second_section = first_section + direction_vector;
            const next_point = second_section + direction_vector;

            const state = try self.grid_manager.place_elements(needs_joint, direction, current_position, first_section, second_section, next_point, &self.direction_manager);

            if (state == State.failed) continue;
            if (state == State.success) return true;

            if (try self.generate_from(next_point, direction, depth + 1)) {
                return true;
            }

            // Backtrack
            self.grid_manager.backtrack(needs_joint, current_position, first_section, second_section);
        }

        return false;
    }

    fn visualize_path(self: *PathGenerator) void {
        for (0..self.grid_manager.height) |y| {
            for (0..self.grid_manager.width) |x| {
                const element = self.grid_manager.grid[x][y];
                switch (element) {
                    .none => std.debug.print(". ", .{}),
                    .section => std.debug.print("= ", .{}),
                    .joint => std.debug.print("* ", .{}),
                }
            }
            std.debug.print("\n", .{});
        }
    }
};
