pub const PathError = error{
    grid_not_initialized,
    out_of_attempts,
    infinite_recursion,
    invalid_dimensions,
    dimensions_too_large,
    out_of_memory,
    index_out_of_bounds,
};
