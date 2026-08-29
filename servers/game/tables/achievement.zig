const generated = @import("generated/assets/achievement");

//

pub const ClientReport = generated.ClientReport;
pub const ClientReportKind = generated.ClientReportKind;
pub const CollectionGroup = generated.CollectionGroup;
pub const CollectionKind = generated.CollectionKind;
pub const Entry = generated.Entry;
pub const Progression = generated.Progression;
pub const ProgressKind = generated.ProgressKind;
pub const client_report_count = generated.client_report_count;
pub const client_reports = generated.client_reports;
pub const collection_entry_count = generated.collection_entry_count;
pub const collection_groups = generated.collection_groups;
pub const progressions = generated.progressions;
pub const tracked_entry_count = generated.tracked_entry_count;

pub fn collectionEntries(group: CollectionGroup) []const Entry {
    return generated.collectionEntries(group);
}

pub fn entry(entry_index: u8) Entry {
    return generated.entry(entry_index);
}

pub fn get(id: u32) ?Entry {
    return generated.get(id);
}

pub fn index(id: u32) ?u8 {
    return generated.index(id);
}

pub fn clientReportIndex(id: u32) ?u8 {
    return generated.clientReportIndex(id);
}
