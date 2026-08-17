const std = @import("std");
const Io = std.Io;
const fatal = std.process.fatal;

const raw_list = @import("error_code");

//

pub fn main(init: std.process.Init) void {
    var output_buffer: [4096]u8 = undefined;
    var output = Io.File.writerStreaming(.stdout(), init.io, &output_buffer);

    output.interface.writeAll(
        \\pub const Code = enum(i32) {
        \\
    ) catch
        fatal("couldn't write header", .{});

    inline for (raw_list) |entry| {
        output.interface.writeAll("    ") catch
            fatal("couldn't indent error tag", .{});
        writeTag(&output.interface, entry.title) catch
            fatal("couldn't write error tag", .{});
        output.interface.print(" = {d},\n", .{entry.id}) catch
            fatal("couldn't write error id", .{});
    }

    output.interface.writeAll("};\n") catch
        fatal("couldn't write footer", .{});
    output.interface.flush() catch
        fatal("couldn't flush output", .{});
}

fn writeTag(writer: *Io.Writer, title: []const u8) Io.Writer.Error!void {
    const name = if (std.mem.startsWith(u8, title, "Err"))
        title[3..]
    else
        title;
    for (name, 0..) |byte, index| {
        if (std.ascii.isUpper(byte)) {
            if (index != 0 and std.ascii.isLower(name[index - 1])) try writer.writeByte('_');
            try writer.writeByte(std.ascii.toLower(byte));
        } else {
            try writer.writeByte(byte);
        }
    }
}
