const generated = @import("generated/assets/achievement");

//

pub const CollectionKind = generated.CollectionKind;
pub const Entry = generated.Entry;
pub const Group = generated.Group;
pub const collection_groups = generated.collection_groups;
pub const collection_entry_count = generated.collection_entry_count;

pub fn get(id: u32) ?Entry {
    for (collection_groups) |group| {
        for (group.entries) |entry| {
            if (entry.id == id)
                return entry;
        }
    }

    return null;
}
