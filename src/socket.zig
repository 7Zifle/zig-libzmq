const std = @import("std");
const expect = std.testing.expect;

const zmq = @import("zmq.zig").c;
const c = @import("context.zig");

pub const ZeromMQSocketType = enum(i32) {
    Pub = zmq.ZMQ_PUB,
    Sub = zmq.ZMQ_SUB,
    XPub = zmq.ZMQ_XPUB,
    XSub = zmq.ZMQ_XSUB,
    Push = zmq.ZMQ_PUSH,
    Pull = zmq.ZMQ_PULL,
    Pair = zmq.ZMQ_PAIR,
    Stream = zmq.ZMQ_STREAM,
    Req = zmq.ZMQ_REQ,
    Rep = zmq.ZMQ_REP,
    Dealer = zmq.ZMQ_DEALER,
    Router = zmq.ZMQ_ROUTER,
};

pub const ZeroMQSocketOption = enum(i32) {
    Affinity = zmq.ZMQ_AFFINITY,
    Backlog = zmq.ZMQ_BACKLOG,
    BindToDevice = zmq.ZMQ_BINDTODEVICE,
    ConnectRID = zmq.ZMQ_CONNECT_RID,
    Conflate = zmq.ZMQ_CONFLATE,
    ConnectTimeout = zmq.ZMQ_CONNECT_TIMEOUT,
    CurvePublicKey = zmq.ZMQ_CURVE_PUBLICKEY,
    CurveServer = zmq.ZMQ_CURVE_SERVER,
    CurveServerKey = zmq.ZMQ_CURVE_SECRETKEY,
    GSSAPIPlanText = zmq.ZMQ_GSSAPI_PLAINTEXT,
    GSSAPIPrincipal = zmq.ZMQ_GSSAPI_PRINCIPAL,
    GSSAPIServer = zmq.ZMQ_GSSAPI_SERVER,
    GSSAPIServicePrincipal = zmq.ZMQ_GSSAPI_SERVICE_PRINCIPAL,
    GSSAPIServicePrincipalNameType = zmq.ZMQ_GSSAPI_SERVICE_PRINCIPAL_NAMETYPE,
    GSSAPIPrincipalNameType = zmq.ZMQ_GSSAPI_PRINCIPAL_NAMETYPE,
    HandshakeIVL = zmq.ZMQ_HANDSHAKE_IVL,
    HeartBeatIVL = zmq.ZMQ_HEARTBEAT_IVL,
    HeartBeatTimeout = zmq.ZMQ_HEARTBEAT_TIMEOUT,
    HeartBeatTTL = zmq.ZMQ_HEARTBEAT_TTL,
    Immediate = zmq.ZMQ_IMMEDIATE,
    InvertMatching = zmq.ZMQ_INVERT_MATCHING,
    IPv6 = zmq.ZMQ_IPV6,
    Linger = zmq.ZMQ_LINGER,
    MultiCastHops = zmq.ZMQ_MULTICAST_HOPS,
    MultiCastMaxTPDU = zmq.ZMQ_MULTICAST_MAXTPDU,
    PlainPassword = zmq.ZMQ_PLAIN_PASSWORD,
    PlainServer = zmq.ZMQ_PLAIN_SERVER,
    PlainUsername = zmq.ZMQ_PLAIN_USERNAME,
    UseFD = zmq.ZMQ_USE_FD,
    ProbeRouter = zmq.ZMQ_PROBE_ROUTER,
    Rate = zmq.ZMQ_RATE,
    ReceiveBuffer = zmq.ZMQ_RCVBUF,
    ReceiveHighWaterMark = zmq.ZMQ_RCVHWM,
    ReceiveTimout = zmq.ZMQ_RCVTIMEO,
    ReconnectIVL = zmq.ZMQ_RECONNECT_IVL,
    ReconnectIVLMax = zmq.ZMQ_RECONNECT_IVL_MAX,
    RecoveryIVL = zmq.ZMQ_RECOVERY_IVL,
    RequestCorrelate = zmq.ZMQ_REQ_CORRELATE,
    RequestRelaxed = zmq.ZMQ_REQ_RELAXED,
    RouterHandover = zmq.ZMQ_ROUTER_HANDOVER,
    RouterMandatory = zmq.ZMQ_ROUTER_MANDATORY,
    RouterRaw = zmq.ZMQ_ROUTER_RAW,
    RoutingId = zmq.ZMQ_ROUTING_ID,
    SendBufferSize = zmq.ZMQ_SNDBUF,
    SendHighWaterMark = zmq.ZMQ_SNDHWM,
    SendTimeout = zmq.ZMQ_SNDTIMEO,
    SocksProxy = zmq.ZMQ_SOCKS_PROXY,
    StreamNotify = zmq.ZMQ_STREAM_NOTIFY,
    Subscribe = zmq.ZMQ_SUBSCRIBE,
    TCPKeepAlive = zmq.ZMQ_TCP_KEEPALIVE,
    TCPKeepAliveCNT = zmq.ZMQ_TCP_KEEPALIVE_CNT,
    TCPKeepAliveIdle = zmq.ZMQ_TCP_KEEPALIVE_IDLE,
    TCPKeepAliveInterval = zmq.ZMQ_TCP_KEEPALIVE_INTVL,
    TCPMaxRetransmitTimeout = zmq.ZMQ_TCP_MAXRT,
    TypeOfService = zmq.ZMQ_TOS,
    Unsubscribe = zmq.ZMQ_UNSUBSCRIBE,
    XPubVerbose = zmq.ZMQ_XPUB_VERBOSE,
    XPubVerboser = zmq.ZMQ_XPUB_VERBOSER,
    XPubManual = zmq.ZMQ_XPUB_MANUAL,
    XPubNoDrop = zmq.ZMQ_XPUB_NODROP,
    XPubWelcomeMessage = zmq.ZMQ_XPUB_WELCOME_MSG,
    ZapDomain = zmq.ZMQ_ZAP_DOMAIN,
    IPCFilterGID = zmq.ZMQ_IPC_FILTER_GID,
    IPCFilterPID = zmq.ZMQ_IPC_FILTER_PID,
    IPCFilterUID = zmq.ZMQ_IPC_FILTER_UID,
    IPv4Only = zmq.ZMQ_IPV4ONLY,
    VMCIBufferSize = zmq.ZMQ_VMCI_BUFFER_SIZE,
    VMCIBufferMinSize = zmq.ZMQ_VMCI_BUFFER_MIN_SIZE,
    VMCIBufferMaxSize = zmq.ZMQ_VMCI_BUFFER_MAX_SIZE,
    VMCConnectTimeout = zmq.ZMQ_VMCI_CONNECT_TIMEOUT,
};

pub const ZeroMQSocket = struct {
    socket: *anyopaque,
    pub fn init(ctx: ?*anyopaque, comptime socketType: ZeromMQSocketType) !ZeroMQSocket {
        if (zmq.zmq_socket(ctx, @intFromEnum(socketType))) |s| {
            return .{
                .socket = s,
            };
        } else {
            return switch (zmq.zmq_errno()) {
                zmq.EINVAL => error.UknownSocketType,
                zmq.EFAULT => error.InvalidContext,
                zmq.EMFILE => error.MaxSocketsReached,
                zmq.ETERM => error.ContextShutdown,
                else => error.UnknownError,
            };
        }
    }
    pub fn setOption(self: *ZeroMQSocket, comptime socketOption: ZeroMQSocketOption, value: *anyopaque, valueSize: usize) !void {
        if (zmq.zmq_setsockopt(self.socket, @intFromEnum(socketOption), value, valueSize) != 0) {
            return switch (zmq.zmq_errno()) {
                zmq.EINVAL => error.UnknownOptionName,
                zmq.ETERM => error.SocketTerminated,
                zmq.ENOTSOCK => error.InvalidSocket,
                zmq.EINTR => error.Interrupted,
                else => error.UnknownError,
            };
        }
    }
    pub fn getOption(self: *ZeroMQSocket, comptime socketOption: ZeroMQSocketOption, value: *anyopaque, valueSize: usize) !void {
        if (zmq.zmq_getsockopt(self.socket, @intFromEnum(socketOption), value, @constCast(&valueSize)) != 0) {
            return switch (zmq.zmq_errno()) {
                zmq.EINVAL => error.UnknownOptionName,
                zmq.ETERM => error.SocketTerminated,
                zmq.ENOTSOCK => error.InvalidSocket,
                zmq.EINTR => error.Interrupted,
                else => error.UnknownError,
            };
        }
    }
    pub fn deinit(self: *ZeroMQSocket) void {
        _ = zmq.zmq_close(self.socket);
    }
};

test "ZeroMQSocket - Can create and set options" {
    var context = c.ZeroMQContext.init();
    defer context.deinit() catch unreachable;

    var socket = try context.createSocket(.Req);
    defer socket.deinit();

    try socket.setOption(.RoutingId, @constCast("testroutingid"), 13);

    var retRoutingId: [13]u8 = undefined;
    try socket.getOption(.RoutingId, &retRoutingId, 13);

    try expect(std.mem.eql(u8, &retRoutingId, "testroutingid"));
}
