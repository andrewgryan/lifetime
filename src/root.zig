const eql = std.mem.eql;
const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn bufGreet(b: []u8, salute: []const u8, name: []const u8) ![]u8 {
    return std.fmt.bufPrint(b, "{s}, {s}", .{ salute, name });
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test "string substitution" {
    var b: [12]u8 = undefined;
    _ = try bufGreet(&b, "hello", "world");
    const actual = &b;
    const expected = "hello, world";
    try testing.expect(eql(u8, actual, expected));
}

fn getParam(prefix: []const u8, path: []const u8) []const u8 {
    return path[prefix.len..];
}

test "path parameter" {
    const actual = getParam("/", "/foo");
    const expected = "foo";
    try testing.expect(eql(u8, actual, expected));
}
