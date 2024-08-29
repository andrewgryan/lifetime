const eql = std.mem.eql;
const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test "string substitution" {
    var b: [12]u8 = undefined;
    _ = try std.fmt.bufPrint(&b, "{s}, {s}", .{ "hello", "world" });
    const actual = &b;
    const expected = "hello, world";
    try testing.expect(eql(u8, actual, expected));
}
