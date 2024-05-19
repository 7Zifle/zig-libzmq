const std = @import("std");
const zmq = @cImport(@cInclude("zmq.h"));

pub fn main() !void {
    const context = zmq.zmq_ctx_new() orelse undefined;
    defer _ = zmq.zmq_ctx_destroy(context);

    const server = zmq.zmq_socket(context, zmq.ZMQ_REP);
    defer _ = zmq.zmq_close(server);
    _ = zmq.zmq_bind(server, "inproc://test-socket");

    const client = zmq.zmq_socket(context, zmq.ZMQ_REQ);
    defer _ = zmq.zmq_close(client);
    _ = zmq.zmq_connect(client, "inproc://test-socket");

    _ = zmq.zmq_send(client, "test", 4, 0);

    var msg: [4]u8 = undefined;
    _ = zmq.zmq_recv(server, &msg, msg.len, 0);

    std.debug.print("msg: {any}", .{msg});
}
