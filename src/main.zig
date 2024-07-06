const std = @import("std");
const zap = @import("zap");
const eql = std.mem.eql;

fn on_request(r: zap.Request) void {
    if (r.path) |path| {
        if (eql(u8, path, "/edit")) {
            r.sendFile("public/edit.html") catch return;
        }
    }

    r.setStatus(.not_found);
    r.sendBody("<h1>404 - File not found</h1>") catch return;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .public_folder = "public",
        .log = true,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Starting server on 0.0.0.0:3000\n", .{});

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
