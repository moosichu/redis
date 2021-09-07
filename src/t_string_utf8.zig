const std = @import("std");

const redis = @cImport({
    @cInclude("server.h");
});

export fn utf8lenCommand(c: *redis.client) void {
    var o: *redis.robj = redis.lookupKeyReadOrReply(c, c.argv[1], redis.shared.czero) orelse return;
    if (redis.checkType(c, o, redis.OBJ_STRING) != 0) return;

    // Get the strlen
    const len = redis.stringObjectLen(o);

    // If the key encodes a number we're done.
    if (redis.getEncodingFromObj(o) == redis.OBJ_ENCODING_INT) {
        redis.addReplyLongLong(c, @intCast(i64, len));
        return;
    }

    // Not a number! Grab the bytes and count the codepoints.
    const str = @ptrCast([*]u8, redis.getPtrFromObj(o))[0..len];
    const cps = std.unicode.utf8CountCodepoints(str) catch {
        redis.addReplyError(c, "this aint utf8 chief");
        return;
    };

    redis.addReplyLongLong(c, @intCast(i64, cps));
}
