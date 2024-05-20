const std = @import("std");
const expect = std.testing.expect;

const zmq = @import("zmq.zig").c;
const c = @import("context.zig");

pub const ZeroMQMessage = struct {
    msg: *zmq.zmq_msg_t,
    fn cleanup(data: ?*anyopaque, hint: ?*anyopaque) callconv(.C) void {
        _ = hint;
        std.c.free(data);
    }
    fn init(data: []u8) !ZeroMQMessage {
        const msg: *zmq.zmq_msg_t = undefined;
        _ = zmq.zmq_msg_init_data(
            msg,
            data.ptr,
            data.len,
            cleanup,
            null,
        );

        return .{
            .msg = msg,
        };
    }
};

test "test message" {
    var testData: [8]u8 = undefined;
    const msg = try ZeroMQMessage.init(&testData);
    defer std.c.free(msg.msg);
}
