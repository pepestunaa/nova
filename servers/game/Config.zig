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
