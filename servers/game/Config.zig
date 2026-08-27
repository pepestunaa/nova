recv_buffer_size: usize,
send_buffer_size: usize,
listen_address: []const u8,
sdk_server_address: []const u8,
session_ttl_seconds: i64,
skip_tutorial: bool,
shop: Shop,
server_garble_key: []const u8,

pub const Shop = struct {
    enable: bool,
    show_historical_packages: bool,
};
