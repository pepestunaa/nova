const raw_list = @import("tables/GachaNewbie");

//

pub const id = raw_list[0].id;
pub const max_spins = raw_list[0].spin_count;
pub const max_saved_results = raw_list[0].save_count;
pub const cards_per_spin = 10;

comptime {
    if (raw_list.len != 1)
        @compileError("expected only one GachaNewbie definition");
}
