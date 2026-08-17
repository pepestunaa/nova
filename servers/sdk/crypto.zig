//! Encrypts the SDK metadata returned from `/meta/*.html`.

const std = @import("std");
const Io = std.Io;

//

pub const key_length = 16;
pub const block_length = 16;
pub const Key = [key_length]u8;

pub const Error = error{OutputTooSmall};

/// Encrypts with AES-128-CBC and PKCS#7 padding, prefixing the result with a
/// random IV.
pub fn encryptCbcPkcs7(
    io: Io,
    output: []u8,
    plaintext: []const u8,
    key: *const Key,
) Error![]const u8 {
    const padding_length = block_length - (plaintext.len % block_length);
    const encrypted_length = plaintext.len + padding_length;
    const total_length = block_length + encrypted_length;
    if (output.len < total_length)
        return error.OutputTooSmall;

    var source: std.Random.IoSource = .{ .io = io };
    source.interface().bytes(output[0..block_length]);
    var previous: [block_length]u8 = output[0..block_length].*;
    const aes = std.crypto.core.aes.Aes128.initEnc(key.*);

    var offset: usize = 0;
    while (offset < encrypted_length) : (offset += block_length) {
        var block: [block_length]u8 = @splat(@intCast(padding_length));
        const remaining = plaintext.len - @min(plaintext.len, offset);
        const copied = @min(block_length, remaining);
        if (copied != 0)
            @memcpy(block[0..copied], plaintext[offset..][0..copied]);
        for (&block, previous) |*byte, previous_byte|
            byte.* ^= previous_byte;

        const encrypted_block = output[block_length + offset ..][0..block_length];
        aes.encrypt(encrypted_block, &block);
        previous = encrypted_block.*;
    }

    return output[0..total_length];
}
