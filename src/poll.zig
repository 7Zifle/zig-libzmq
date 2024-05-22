const std = @import("std");

const zmq = @import("zmq.zig").c;
const c = @import("context.zig");
const s = @import("socket.zig");

pub const ZeroMQPollEvent = enum(i16) {
    PollIn = zmq.ZMQ_POLLIN,
    PollOut = zmq.ZMQ_POLLOUT,
    PollErr = zmq.ZMQ_POLLERR,
    PollPri = zmq.ZMQ_POLLPRI,
};

pub const ZeroMQPollItem = struct {
    /// The ZeroMQSocket that the event will poll on
    socket: *s.ZeroMQSocket,

    /// File descriptor associated with the socket
    fd: i32 = 0,

    /// Bitmask specifying the events to poll for on the socket.
    events: i16 = 0,

    /// Bitmask specifying the events that occurred on the socket during polling
    revents: i16 = 0,

    /// Produces a ZPollItem. At compile time events are merged to a single bitmask flag.
    pub fn build(socket: *s.ZeroMQSocket, fd: i32, comptime events: []const ZeroMQPollEvent) ZeroMQPollItem {
        comptime var flag: i16 = 0;
        inline for (events) |eventFlag| {
            flag |= @intFromEnum(eventFlag);
        }
        return .{
            .socket = socket,
            .fd = fd,
            .events = flag,
            .revents = 0,
        };
    }
};

/// The size indicates the number of poll items that the ZPoll can contain.
pub fn ZeroMQPoll(size: usize) type {
    return struct {
        const Self = @This();
        pollItems_: [size]zmq.zmq_pollitem_t = undefined,

        /// Sets up a new ZPoll instance
        pub fn init(poll_items: []const ZeroMQPollItem) Self {
            var zpoll = Self{};
            for (0.., poll_items) |i, item| {
                zpoll.pollItems_[i] = .{
                    .socket = item.socket.socket,
                    .fd = item.fd,
                    .events = item.events,
                    .revents = item.revents,
                };
            }
            return zpoll;
        }

        /// Gets the returned events bitmask
        pub fn returnedEvents(self: *Self, index: usize) i16 {
            return self.pollItems_[index].revents;
        }

        /// Verifies if all requested events are flagged at the given index in the returned events.
        /// At compile time events are merged to a single bitmask flag.
        pub fn eventsOccurred(self: *Self, index: usize, comptime events: []const ZeroMQPollEvent) bool {
            comptime var flag = 0;
            inline for (events) |eventFlag| {
                flag |= @intFromEnum(eventFlag);
            }
            return self.pollItems_[index].revents & flag != 0;
        }

        /// Perform polling on multiple ZeroMQ sockets to check for events.
        /// Equivalent to the zmq_poll function.
        pub fn poll(self: *Self, len: usize, timeout: i64) !void {
            const rc = zmq.zmq_poll(&self.pollItems_, @intCast(len), timeout);
            if (rc < 0) {
                return switch (zmq.zmq_errno()) {
                    zmq.ETERM => error.SocketTerminated,
                    zmq.EFAULT => error.ItemsInvalid,
                    zmq.EINTR => error.Interrupted,
                    else => return error.PollFailed,
                };
            }
        }
    };
}
test "ZeroMQPoll - 2 sockets" {
    var ctx = c.ZeroMQContext.init();
    defer ctx.deinit() catch unreachable;

    var router1 = try ctx.createSocket(.Router);
    defer router1.deinit();
    try router1.bind("inproc://test-socket1");

    var router2 = try ctx.createSocket(.Router);
    defer router2.deinit();
    try router2.bind("inproc://test-socket2");

    var req1 = try ctx.createSocket(.Req);
    defer req1.deinit();
    try req1.connect("inproc://test-socket1");
    _ = try req1.send(@constCast("hello"), .{});

    var req2 = try ctx.createSocket(.Req);
    defer req2.deinit();
    try req2.connect("inproc://test-socket2");
    _ = try req2.send(@constCast("hello"), .{});

    var poll = ZeroMQPoll(2).init(&[_]ZeroMQPollItem{
        ZeroMQPollItem.build(&router1, 0, &[_]ZeroMQPollEvent{.PollIn}),
        ZeroMQPollItem.build(&router2, 0, &[_]ZeroMQPollEvent{.PollIn}),
    });
    try poll.poll(1, 500);
    try std.testing.expect(poll.eventsOccurred(0, &[_]ZeroMQPollEvent{.PollIn}));
    try poll.poll(2, 500);
    try std.testing.expect(poll.eventsOccurred(1, &[_]ZeroMQPollEvent{.PollIn}));
}
