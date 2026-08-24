const generated = @import("generated/assets/achievement");

//

pub const CollectionKind = generated.CollectionKind;
pub const Entry = generated.Entry;
pub const CollectionGroup = generated.CollectionGroup;
pub const ProgressKind = generated.ProgressKind;
pub const Progression = generated.Progression;
pub const collection_groups = generated.collection_groups;
pub const character_progressions = generated.character_progressions;
pub const collection_entry_count = generated.collection_entry_count;
pub const tracked_entry_count = generated.tracked_entry_count;

pub fn collectionEntries(group: CollectionGroup) []const Entry {
    return generated.collectionEntries(group);
}

pub fn entry(index: u8) Entry {
    return generated.entry(index);
}

pub fn get(id: u32) ?Entry {
    return generated.get(id);
}
