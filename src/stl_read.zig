const std = @import("std");
const lib_vec = @import("vec.zig");
const lib_triangle = @import("triangle.zig");

const vec_def: lib_vec.Vec_Def = .{ .T = f32, .N = 3 };
pub const T_Type = lib_triangle.Triangle(vec_def);

fn read_token(reader: anytype, token: *std.ArrayList(u8)) !void {
    token.clearRetainingCapacity();
    // Skip leading whitespace
    while (true) {
        const c = try reader.readByte();
        if (std.ascii.isWhitespace(c)) continue;
        try token.append(c);
        break;
    }
    // Read until whitespace
    while (true) {
        const c = try reader.readByte();
        if (std.ascii.isWhitespace(c)) break;
        try token.append(c);
    }
}

pub fn stl_read(ator: std.mem.Allocator, filepath: []const u8) !std.ArrayList(T_Type) {
    const cwd = std.fs.cwd();
    const input_mesh_file = try cwd.openFile(filepath, .{ .mode = .read_only });
    defer input_mesh_file.close();

    const input_mesh_r = input_mesh_file.reader();
    var input_mesh_br = std.io.bufferedReader(input_mesh_r);
    var input_mesh_br_r = input_mesh_br.reader();

    try input_mesh_r.skipBytes(80, .{});
    const num_tris = @as(u64, try input_mesh_r.readInt(u32, .little));
    const expected_binary_size = num_tris * 50 + 84;
    const file_size = try input_mesh_file.getEndPos();

    var tris = std.ArrayList(T_Type).init(ator);

    if (expected_binary_size == file_size) {
        std.debug.print("Binary\n", .{});
        std.debug.print("TODO: Implement binary .stl reader\n", .{});
    } else {
        std.debug.print("ASCII\n", .{});
        try input_mesh_file.seekTo(0);
        // Recreate buffered reader after seeking file, otherwise it will read from the old position
        input_mesh_br = std.io.bufferedReader(input_mesh_r);
        input_mesh_br_r = input_mesh_br.reader();

        var token = std.ArrayList(u8).init(ator);
        defer token.deinit();

        outer: while (true) {
            read_token(input_mesh_br_r, &token) catch break :outer;
            if (std.mem.eql(u8, token.items, "loop")) {
                var t: T_Type = .{ .vertices = undefined };
                for (0..3) |vi| {
                    // read "vertex"
                    read_token(input_mesh_br_r, &token) catch break :outer;
                    for (0..3) |ci| {
                        read_token(input_mesh_br_r, &token) catch break :outer;
                        const c = try std.fmt.parseFloat(f32, token.items);
                        t.vertices[vi].components[ci] = c;
                    }
                }
                try tris.append(t);
            }
        }
    }
    return tris;
}