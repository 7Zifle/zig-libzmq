const zmq = @import("zmq.zig").c;
const c = @import("context.zig");
const s = @import("socket.zig");

pub const ZPollEvent = enum(i16) {
    PollIn = zmq.ZMQ_POLLIN,
    PollOut = zmq.ZMQ_POLLOUT,
    PollErr = zmq.ZMQ_POLLERR,
    PollPri = zmq.ZMQ_POLLPRI,
};

pub const ZPollItem = struct {
    /// The ZSocket that the event will poll on
    socket: *s.ZeroMQSocket,

    /// File descriptor associated with the socket
    fd: i32 = 0,

    /// Bitmask specifying the events to poll for on the socket.
    events: i16 = 0,

    /// Bitmask specifying the events that occurred on the socket during polling
    revents: i16 = 0,

    /// Produces a ZPollItem. At compile time events are merged to a single bitmask flag.
    pub fn build(socket: *s.ZeroMQSocket, fd: i32, comptime events: []const ZPollEvent) ZPollItem {
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
pub fn ZPoll(size: usize) type {
    return struct {
        const Self = @This();
        pollItems_: [size]zmq.zmq_pollitem_t = undefined,

        /// Sets up a new ZPoll instance
        pub fn init(poll_items: []const ZPollItem) Self {
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
        pub fn eventsOccurred(self: *Self, index: usize, comptime events: []const ZPollEvent) bool {
            comptime var flag = 0;
            inline for (events) |eventFlag| {
                flag |= @intFromEnum(eventFlag);
            }
            return self.pollItems_[index].revents & flag != 0;
        }

        /// Perform polling on multiple ZeroMQ sockets to check for events.
        /// Equivalent to the zmq_poll function.
        pub fn poll(self: *Self, len: usize, timeout: i64) !void {
            const rc = c.zmq_poll(&self.pollItems_, @intCast(len), timeout);
            if (rc < 0) {
                return switch (c.zmq_errno()) {
                    c.ETERM => error.ZSocketTerminated,
                    c.EFAULT => error.ItemsInvalid,
                    c.EINTR => error.Interrupted,
                    else => return error.PollFailed,
                };
            }
        }
    };
}
