usingnamespace (@cImport({
    @cInclude("server.h");
}));

const std = @import("std");

export fn utf8lenCommand(c: *client) void {
    const o = lookupKeyReadOrReply(c, c.argv[1], shared.czero) orelse return;
    if (checkType(c, o, OBJ_STRING) != 0) return;
    const bytes_len = stringObjectLen(o);
    const bytes_ptr = @ptrCast([*]const u8, redisObjectGetPtr(o));
    const bytes = bytes_ptr[0..bytes_len];
    const utf8_len = std.unicode.utf8CountCodepoints(bytes) catch |err| return switch (err) {
        error.Utf8ExpectedContinuation => addReplyError(c, "Expected UTF-8 Continuation"),
        error.Utf8OverlongEncoding => addReplyError(c, "Overlong UTF-8 Encoding"),
        error.Utf8EncodesSurrogateHalf => addReplyError(c, "UTF-8 Encodes Surrogate Half"),
        error.Utf8CodepointTooLarge => addReplyError(c, "UTF-8 Codepoint too large"),
        error.TruncatedInput => addReplyError(c, "UTF-8 Truncated Input"),
        error.Utf8InvalidStartByte => addReplyError(c, "Invalid UTF-8 Start Byte"),
    };
    addReplyLongLong(c, @intCast(c_longlong, utf8_len));
}
