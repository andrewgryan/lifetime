const std = @import("std");
const zap = @import("zap");
const koino = @import("koino");
const eql = std.mem.eql;

const index = @embedFile("./templates/index.html");

fn handle_markdown(r: zap.Request) !void {
    // Memory allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Parse markdown from Request
    r.parseBody() catch |err| {
        std.log.err("Parse body error: {any}. Expected if body empty.", .{err});
    };
    const param = try r.getParamStr(allocator, "content", false);
    const markdown = param.?.str;

    // Write to file
    const file = try std.fs.cwd().createFile("public/article.md", .{});
    try file.writeAll(markdown);
    defer file.close();

    const body = try markdownToHTML(allocator, markdown);

    r.sendBody(body) catch return;
}

fn markdownToHTML(allocator: std.mem.Allocator, markdown: []const u8) ![]u8 {

    // Convert markdown into HTML
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const options = koino.Options{};
    var p = try koino.parser.Parser.init(allocator, options);
    try p.feed(markdown);

    var doc = try p.finish();
    p.deinit();

    defer doc.deinit();

    var chars = std.ArrayList(u8).init(allocator);
    defer chars.deinit();

    try koino.html.print(chars.writer(), arena.allocator(), p.options, doc);

    return try chars.toOwnedSlice();
}

fn handleIndex(r: zap.Request) !void {
    // Memory allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Read markdown
    const max_bytes = 1000000;
    const file = try std.fs.cwd().openFile("public/article.md", .{});
    defer file.close();
    const text = try file.readToEndAlloc(allocator, max_bytes);

    // HTML representation
    const html = try markdownToHTML(allocator, text);

    // Substitute text
    const body = try std.fmt.allocPrint(allocator, index, .{ text, html });
    defer allocator.free(body);
    // sendBody
    return r.sendBody(body);
    // return r.sendFile("public/index.html");
}

fn on_request(r: zap.Request) void {
    if (r.path) |path| {
        if (eql(u8, path, "/")) {
            handleIndex(r) catch return;
            return;
        }
        if (eql(u8, path, "/render")) {
            handle_markdown(r) catch return;
            return;
        }
        if (eql(u8, path, "/article")) {
            r.sendFile("public/article.md") catch return;
            return;
        }

        // Page
        if (std.mem.startsWith(u8, path, "/page")) {
            if (r.method) |method| {
                r.sendBody(method) catch return;
            }
            return;
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
