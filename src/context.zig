const std = @import("std");
const expect = std.testing.expect;

const zmq = @import("zmq.zig").c;
const s = @import("socket.zig");

pub const ZeroMqContextOptions = enum(i32) {
    IOThreads = zmq.ZMQ_IO_THREADS,
    MaxSockets = zmq.ZMQ_MAX_SOCKETS,
    MaxMessageSize = zmq.ZMQ_MAX_MSGSZ,
    SocketLimit = zmq.ZMQ_SOCKET_LIMIT,
    IPv6 = zmq.ZMQ_IPV6,
    Blocky = zmq.ZMQ_BLOCKY,
    ThreadSchedulePolicy = zmq.ZMQ_THREAD_SCHED_POLICY,
    ThreadNamePrefix = zmq.ZMQ_THREAD_NAME_PREFIX,
    MessageTSize = zmq.ZMQ_MSG_T_SIZE,
};

pub const ZeroMQContext = struct {
    context: *anyopaque,
    pub fn init() ZeroMQContext {
        return .{
            .context = zmq.zmq_ctx_new().?,
        };
    }
    pub fn deinit(self: *ZeroMQContext) !void {
        return switch (zmq.zmq_ctx_destroy(self.context)) {
            0 => {},
            zmq.EMFILE => error.TooManyOpenedFiles,
            else => error.UnknownError,
        };
    }
    pub fn get(self: *ZeroMQContext, comptime optionName: ZeroMqContextOptions) !i32 {
        const value = zmq.zmq_ctx_get(self.context, @intFromEnum(optionName));
        if (value < 0) {
            return switch (value) {
                zmq.EINVAL => error.UnknownOption,
                zmq.EFAULT => error.InvalidContext,
                else => error.UnknownError,
            };
        }
        return value;
    }
    pub fn set(self: *ZeroMQContext, comptime optionName: ZeroMqContextOptions, optionValue: i32) !void {
        const value = zmq.zmq_ctx_set(self.context, @intFromEnum(optionName), optionValue);
        if (value == -1) {
            return switch (zmq.zmq_errno()) {
                zmq.EINVAL => error.UnknownOption,
                else => error.UnknownError,
            };
        }
    }
    pub fn createSocket(self: *ZeroMQContext, comptime socketType: s.ZeromMQSocketType) !s.ZeroMQSocket {
        return try s.ZeroMQSocket.init(self.context, socketType);
    }
};

test "ZeroMQContext - Can configure context" {
    var ctx = ZeroMQContext.init();
    defer ctx.deinit() catch unreachable;

    try ctx.set(.MaxSockets, 256);

    const maxSockets = try ctx.get(.MaxSockets);
    try expect(maxSockets == 256);
}

test "ZeroMQContext - Can create socket" {
    var ctx = ZeroMQContext.init();
    defer ctx.deinit() catch unreachable;

    var socket = try ctx.createSocket(.Router);
    defer socket.deinit();
}
