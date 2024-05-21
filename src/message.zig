const std = @import("std");
const expect = std.testing.expect;

const zmq = @import("zmq.zig").c;
const c = @import("context.zig");

pub const ZeroMQMessageProperty = enum(i32) {
    More = zmq.ZMQ_MORE,
    SourceFD = zmq.ZMQ_SRCFD,
    Shared = zmq.ZMQ_SHARED,
};

pub const ZeroMQMessage = struct {
    msg: zmq.zmq_msg_t,
    fn cleanup(data: ?*anyopaque, hint: ?*anyopaque) callconv(.C) void {
        _ = hint;
        std.c.free(data);
    }
    pub fn init(data: []u8) !ZeroMQMessage {
        var msg: zmq.zmq_msg_t = std.mem.zeroes(zmq.zmq_msg_t);
        if (zmq.zmq_msg_init_data(&msg, data.ptr, data.len, cleanup, null) == -1) {
            return switch (zmq.zmq_errno()) {
                zmq.ENOMEM => error.InsufficientStorage,
                else => error.UnknownError,
            };
        }
        return .{
            .msg = msg,
        };
    }
    pub fn set(self: *ZeroMQMessage, comptime property: ZeroMQMessageProperty, value: i32) !void {
        if (zmq.zmq_msg_set(&self.msg, @intFromEnum(property), value) == -1) {
            return switch (zmq.zmq_errno()) {
                zmq.EINVAL => error.UnknownProperty,
                else => error.UnknownError,
            };
        }
    }
    pub fn get(self: *ZeroMQMessage, comptime property: ZeroMQMessageProperty) !i32 {
        const value = zmq.zmq_msg_get(&self.msg, @intFromEnum(property));
        if (value == -1) {
            return switch (zmq.zmq_errno()) {
                zmq.EINVAL => error.UnknownProperty,
                else => error.UnknownError,
            };
        }
        return value;
    }
};
