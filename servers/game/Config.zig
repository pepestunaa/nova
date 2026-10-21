recv_buffer_size: usize,
send_buffer_size: usize,
listen_address: []const u8,
sdk_server_address: []const u8,
session_ttl_seconds: i64,
skip_tutorial: bool,
/// Guide groups the bundled guide table does not contain. The client runs a
/// guide for every group it knows, so groups introduced by a newer client have
/// to be listed here to keep the client from asking for data the server does
/// not implement.
extra_guide_groups: []const u32,
/// Gallery (Handbook) types whose bitmap is sent to the client. The
/// 1.13.0.143 client resolves the gallery rows of every type it caches and
/// logs an error for each skin its own table does not contain.
gallery_types: []const u32,
/// Logs every request the client sends, with its numeric ID, its protocol
/// name and the payload size. Needed to see which requests a feature uses
/// when the protocol table does not cover the client version.
trace_packets: bool,
shop: Shop,
server_garble_key: []const u8,

pub const Shop = struct {
    enable: bool,
    show_historical_packages: bool,
    daily_mall_rewards: [2]Reward,
};

pub const Reward = struct {
    id: u32,
    quantity: i32,
};
