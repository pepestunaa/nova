const Player = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const List = @import("List.zig").List;
const Characters = @import("player/Characters.zig");
const StarTower = @import("player/StarTower.zig");
const State = @import("player/State.zig");
const tables = @import("../tables.zig");

//

pub const max_characters = State.max_characters;
pub const max_formation_characters = State.max_formation_characters;
pub const max_formation_discs = State.max_formation_discs;
pub const max_achievements = State.max_achievements;
pub const max_tower_book_potentials = tables.potential.count;
pub const max_tower_book_potential_rewards = tables.star_tower_book.potential_rewards.len;
pub const max_star_tower_builds = State.max_star_tower_builds;

pub const Achievement = State.Achievement;
pub const Acquisition = State.Acquisition;
pub const Assist = State.Assist;
pub const Basic = State.Basic;
pub const BoardEntry = State.BoardEntry;
pub const Character = State.Character;
pub const Clear = State.Clear;
pub const DictionaryEntry = State.DictionaryEntry;
pub const Disc = State.Disc;
pub const Formation = State.Formation;
pub const GachaBanner = State.GachaBanner;
pub const GachaHistory = State.GachaHistory;
pub const GachaStorage = State.GachaStorage;
pub const Guide = State.Guide;
pub const HandbookUnlock = State.HandbookUnlock;
pub const Item = State.Item;
pub const NewbieGacha = State.NewbieGacha;
pub const NpcAffinity = State.NpcAffinity;
pub const PeriodicCampaign = State.PeriodicCampaign;
pub const PeriodicQuest = State.PeriodicQuest;
pub const Progress = State.Progress;
pub const Quest = State.Quest;
pub const ResearchProject = StarTower.ResearchProject;
pub const Resource = State.Resource;
pub const StarTowerBuild = State.StarTowerBuild;
pub const StarTowerRun = State.StarTowerRun;
pub const Story = State.Story;
pub const StoryChoice = State.StoryChoice;
pub const StoryEvidence = State.StoryEvidence;
pub const Title = State.Title;
pub const TowerBookPotential = State.TowerBookPotential;
pub const TowerBookPotentialReward = State.TowerBookPotentialReward;
pub const TowerGrowth = State.TowerGrowth;
pub const TutorialLevel = State.TutorialLevel;

pub const AchievementTable = List(Achievement);
pub const AcquisitionTable = List(Acquisition);
pub const AssistTable = List(Assist);
pub const BoardTable = List(BoardEntry);
pub const CharacterTable = Characters.Table;
pub const ClearTable = List(Clear);
pub const DictionaryTable = List(DictionaryEntry);
pub const DiscTable = List(Disc);
pub const FormationTable = List(Formation);
pub const GachaBannerTable = List(GachaBanner);
pub const GachaHistoryTable = List(GachaHistory);
pub const GachaStorageTable = List(GachaStorage);
pub const GuideTable = List(Guide);
pub const HandbookTable = List(HandbookUnlock);
pub const ItemTable = List(Item);
pub const NpcAffinityTable = List(NpcAffinity);
pub const PeriodicQuestTable = List(PeriodicQuest);
pub const QuestTable = List(Quest);
pub const ResourceTable = List(Resource);
pub const StarTowerBuildTable = List(StarTowerBuild);
pub const StoryChoiceTable = List(StoryChoice);
pub const StoryEvidenceTable = List(StoryEvidence);
pub const StoryTable = List(Story);
pub const TitleTable = List(Title);
pub const TowerBookPotentialRewardTable = List(TowerBookPotentialReward);
pub const TowerBookPotentialTable = List(TowerBookPotential);
pub const TutorialTable = List(TutorialLevel);

uid: ?u64 = null,
is_registered: bool = false,
basic: Basic = .{},
progress: Progress = .{},
tower_growth: TowerGrowth = .{},
research_project: ResearchProject = .{},
characters: CharacterTable = .{},
guides: GuideTable,
board: BoardTable,
handbook: HandbookTable,
resources: ResourceTable,
items: ItemTable,
titles: TitleTable,
discs: DiscTable,
formations: FormationTable,
acquisitions: AcquisitionTable,
achievements: AchievementTable,
dictionaries: DictionaryTable,
quests: QuestTable,
assists: AssistTable,
tutorials: TutorialTable,
stories: StoryTable,
story_choices: StoryChoiceTable,
story_evidences: StoryEvidenceTable,
periodic_campaign: PeriodicCampaign = .{},
periodic_quests: PeriodicQuestTable,
npc_affinities: NpcAffinityTable,
tower_book_potentials: TowerBookPotentialTable,
tower_book_potential_rewards: TowerBookPotentialRewardTable,
clears: ClearTable,
star_tower_run: StarTowerRun = .{},
star_tower_map_param: StarTower.MapParam = .{},
star_tower_client_data: StarTower.ClientData = .{},
pending_star_tower_build: StarTowerBuild = .{},
star_tower_builds: StarTowerBuildTable = .{},
newbie_gacha: NewbieGacha = .{},
gacha_banners: GachaBannerTable,
gacha_storages: GachaStorageTable,
gacha_histories: GachaHistoryTable,

pub fn init(uid: ?u64) Player {
    return .{
        .uid = uid,
        .guides = .{},
        .board = .{},
        .handbook = .{},
        .resources = .{},
        .items = .{},
        .titles = .{},
        .discs = .{},
        .formations = .{},
        .acquisitions = .{},
        .achievements = .{},
        .dictionaries = .{},
        .quests = .{},
        .assists = .{},
        .tutorials = .{},
        .stories = .{},
        .story_choices = .{},
        .story_evidences = .{},
        .periodic_quests = .{},
        .npc_affinities = .{},
        .tower_book_potentials = .{},
        .tower_book_potential_rewards = .{},
        .clears = .{},
        .gacha_banners = .{},
        .gacha_storages = .{},
        .gacha_histories = .{},
    };
}

pub fn deinit(player: *Player, allocator: Allocator) void {
    player.guides.deinit(allocator);
    player.board.deinit(allocator);
    player.handbook.deinit(allocator);
    player.resources.deinit(allocator);
    player.items.deinit(allocator);
    player.titles.deinit(allocator);
    player.discs.deinit(allocator);
    player.formations.deinit(allocator);
    player.acquisitions.deinit(allocator);
    player.achievements.deinit(allocator);
    player.dictionaries.deinit(allocator);
    player.quests.deinit(allocator);
    player.assists.deinit(allocator);
    player.tutorials.deinit(allocator);
    player.stories.deinit(allocator);
    player.story_choices.deinit(allocator);
    player.story_evidences.deinit(allocator);
    player.periodic_quests.deinit(allocator);
    player.npc_affinities.deinit(allocator);
    player.tower_book_potentials.deinit(allocator);
    player.tower_book_potential_rewards.deinit(allocator);
    player.clears.deinit(allocator);
    player.star_tower_builds.deinit(allocator);
    player.star_tower_map_param.deinit(allocator);
    player.star_tower_client_data.deinit(allocator);
    player.gacha_banners.deinit(allocator);
    player.gacha_storages.deinit(allocator);
    player.gacha_histories.deinit(allocator);
}

pub fn reset(player: *Player, allocator: Allocator) void {
    const uid = player.uid;
    player.deinit(allocator);
    player.* = .init(uid);
}

pub fn nickname(player: *const Player) []const u8 {
    return player.basic.nickname.view();
}

/// Unlocks a configured Gallery entry.
pub fn unlockHandbook(player: *Player, allocator: Allocator, handbook_id: u32) !bool {
    if (tables.handbook.get(handbook_id) == null)
        return false;

    for (player.handbook.slice()) |unlock| {
        if (unlock.handbook_id == handbook_id) return false;
    }

    try player.handbook.append(allocator, .{ .handbook_id = handbook_id });

    return true;
}

/// Unlocks a Trekker's base skin through its type-1 Gallery entry, which the
/// client uses as the source of skin ownership.
pub fn unlockDefaultSkin(player: *Player, allocator: Allocator, character_id: u32) !bool {
    const entry = tables.handbook.defaultSkin(character_id) orelse
        return false;

    return player.unlockHandbook(allocator, entry.id);
}

pub fn unlockAdvanceSkin(player: *Player, allocator: Allocator, character_id: u32) !bool {
    const entry = tables.handbook.advanceSkin(character_id) orelse
        return false;

    return player.unlockHandbook(allocator, entry.id);
}

pub fn addResource(player: *Player, allocator: Allocator, id: u32, quantity: i32) !void {
    if (quantity == 0)
        return;

    for (player.resources.entries[0..player.resources.len]) |*resource| {
        if (resource.id != id)
            continue;
        resource.quantity +|= quantity;

        return;
    }

    try player.resources.append(allocator, .{ .id = id, .quantity = quantity });
}

pub fn resourceQuantity(player: *const Player, id: u32) i32 {
    for (player.resources.slice()) |resource| {
        if (resource.id == id)
            return resource.quantity;
    }

    return 0;
}

pub fn consumeResource(player: *Player, id: u32, quantity: i32) error{InsufficientResources}!void {
    if (quantity < 0) unreachable;

    for (player.resources.entries[0..player.resources.len]) |*resource| {
        if (resource.id != id)
            continue;
        if (resource.quantity < quantity)
            return error.InsufficientResources;

        resource.quantity -= quantity;
        return;
    }

    return error.InsufficientResources;
}

pub fn getFormation(player: *const Player, number: u32) ?*const Formation {
    for (player.formations.slice()) |*entry| {
        if (entry.number == number)
            return entry;
    }

    return null;
}

pub fn npcAffinity(player: *const Player, npc_id: u32) u32 {
    for (player.npc_affinities.slice()) |entry| {
        if (entry.npc_id == npc_id)
            return entry.affinity;
    }

    return 0;
}

pub fn addNpcAffinity(player: *Player, allocator: Allocator, npc_id: u32, increase: u32) !u32 {
    if (npc_id == 0 or increase == 0)
        return player.npcAffinity(npc_id);

    for (player.npc_affinities.entries[0..player.npc_affinities.len]) |*entry| {
        if (entry.npc_id != npc_id)
            continue;
        entry.affinity +|= increase;

        return entry.affinity;
    }

    try player.npc_affinities.append(
        allocator,
        .{ .npc_id = npc_id, .affinity = increase },
    );

    return increase;
}

/// Adds a Potential to the Monolith Log or upgrades its existing entry.
/// Returns whether the Log changed.
pub fn recordTowerBookPotential(player: *Player, allocator: Allocator, id: u32, level: u8) !bool {
    for (player.tower_book_potentials.entries[0..player.tower_book_potentials.len]) |*entry| {
        if (entry.id != id)
            continue;
        if (level <= entry.level)
            return false;
        entry.level = level;

        return true;
    }

    try player.tower_book_potentials.append(allocator, .{ .id = id, .level = level });

    return true;
}

pub fn towerBookPotentialCount(player: *const Player, character_id: u32) u32 {
    var count: u32 = 0;

    for (player.tower_book_potentials.slice()) |entry| {
        if (tables.potential.characterId(entry.id) == character_id) count += 1;
    }

    return count;
}

pub fn hasTowerBookPotentialReward(player: *const Player, id: u32) bool {
    for (player.tower_book_potential_rewards.slice()) |entry| {
        if (entry.id == id)
            return true;
    }

    return false;
}

pub fn claimTowerBookPotentialReward(player: *Player, allocator: Allocator, id: u32) !void {
    if (player.hasTowerBookPotentialReward(id))
        return;
    try player.tower_book_potential_rewards.append(allocator, .{ .id = id });
}

pub fn hasClaimedClearReward(player: *const Player, kind: Clear.Kind, id: u32) bool {
    for (player.clears.slice()) |entry| {
        if (entry.kind == kind and entry.id == id)
            return entry.reward_claimed;
    }

    return false;
}

pub fn setClearRewardClaimed(player: *Player, allocator: Allocator, kind: Clear.Kind, id: u32) !void {
    for (player.clears.entries[0..player.clears.len]) |*entry| {
        if (entry.kind != kind or entry.id != id)
            continue;
        entry.reward_claimed = true;

        return;
    }

    try player.clears.append(allocator, .{ .kind = kind, .id = id, .reward_claimed = true });
}

pub fn itemQuantity(player: *const Player, template_id: u32) i32 {
    for (player.items.slice()) |item| {
        if (item.template_id == template_id)
            return item.quantity;
    }

    return 0;
}

pub fn addItem(player: *Player, allocator: Allocator, template_id: u32, quantity: i32) !void {
    if (quantity == 0)
        return;

    for (player.items.entries[0..player.items.len]) |*item| {
        if (item.template_id != template_id)
            continue;
        item.quantity +|= quantity;

        return;
    }

    try player.items.append(allocator, .{
        .id = template_id,
        .template_id = template_id,
        .quantity = quantity,
    });
}

pub fn consumeItem(player: *Player, template_id: u32, quantity: i32) error{InsufficientItems}!void {
    if (quantity < 0) unreachable;

    var index: usize = 0;
    while (index < player.items.len) : (index += 1) {
        const item = &player.items.entries[index];
        if (item.template_id != template_id)
            continue;

        if (item.quantity < quantity)
            return error.InsufficientItems;

        if (item.quantity == quantity)
            _ = player.items.swapRemove(index)
        else
            item.quantity -= quantity;

        return;
    }

    return error.InsufficientItems;
}

pub fn setFormation(
    player: *Player,
    allocator: Allocator,
    number: u32,
    character_ids: []const u32,
    disc_ids: []const u32,
    preselection_id: u64,
) error{ TooManyCharacters, TooManyDiscs, TooManyFormations }!void {
    if (character_ids.len > max_formation_characters)
        return error.TooManyCharacters;
    if (disc_ids.len > max_formation_discs)
        return error.TooManyDiscs;

    var formation: Formation = .{
        .number = number,
        .character_count = @intCast(character_ids.len),
        .disc_count = @intCast(disc_ids.len),
        .preselection_id = preselection_id,
    };
    @memcpy(formation.character_ids[0..character_ids.len], character_ids);
    @memcpy(formation.disc_ids[0..disc_ids.len], disc_ids);

    for (player.formations.entries[0..player.formations.len]) |*existing| {
        if (existing.number != number)
            continue;
        existing.* = formation;

        return;
    }
    player.formations.append(allocator, formation) catch
        return error.TooManyFormations;
}

pub fn formationMatches(
    player: *const Player,
    number: u32,
    character_ids: []const u32,
    disc_ids: []const u32,
    preselection_id: u64,
) bool {
    for (player.formations.slice()) |*formation| {
        if (formation.number != number)
            continue;

        return formation.preselection_id == preselection_id and
            std.mem.eql(
                u32,
                formation.character_ids[0..formation.character_count],
                character_ids,
            ) and
            std.mem.eql(
                u32,
                formation.disc_ids[0..formation.disc_count],
                disc_ids,
            );
    }

    return false;
}

pub fn ensureCharacterDefaultSkins(player: *Player, allocator: Allocator) !bool {
    var changed = false;
    var iterator = player.characters.iterator();
    while (iterator.next()) |character|
        changed = (try player.unlockDefaultSkin(allocator, character.id())) or changed;

    return changed;
}

pub fn learn(player: *Player, allocator: Allocator, group_id: u32, step_id: i32) Allocator.Error!void {
    for (player.guides.entries[0..player.guides.len]) |*guide| {
        if (guide.group_id == group_id) {
            guide.step_id = step_id;

            return;
        }
    }

    try player.guides.append(allocator, .{ .group_id = group_id, .step_id = step_id });
}

pub fn guideStep(player: *const Player, group_id: u32) ?i32 {
    for (player.guides.slice()) |guide| {
        if (guide.group_id == group_id)
            return guide.step_id;
    }

    return null;
}

/// Completes the supplied tutorial groups when new-player tutorial skipping is
/// enabled.
pub fn completeGuides(player: *Player, allocator: Allocator, group_ids: []const u32) Allocator.Error!void {
    player.guides.clear();
    for (group_ids) |group_id| try player.learn(allocator, group_id, -1);
}

pub fn periodicQuestStatus(player: *const Player, quest_id: u32) PeriodicQuest.Status {
    for (player.periodic_quests.slice()) |quest| {
        if (quest.id == quest_id)
            return quest.status;
    }

    return .uncompleted;
}

pub fn setStarTowerMapParam(player: *Player, allocator: Allocator, bytes: []const u8) Allocator.Error!void {
    try player.star_tower_map_param.ensureTotalCapacity(allocator, bytes.len);
    player.star_tower_map_param.len = bytes.len;
    @memcpy(player.star_tower_map_param.mutableSlice(), bytes);
}

pub fn setStarTowerClientData(
    player: *Player,
    allocator: Allocator,
    data_len: u32,
    bytes: []const u8,
    data_version: u32,
) Allocator.Error!void {
    try player.star_tower_client_data.ensureTotalCapacity(allocator, bytes.len);
    player.star_tower_client_data.len = bytes.len;
    @memcpy(player.star_tower_client_data.mutableSlice(), bytes);
    player.star_tower_run.client_data_declared_len = data_len;
    player.star_tower_run.client_data_version = data_version;
}

pub fn resetStarTowerRun(player: *Player) void {
    player.star_tower_run.reset();
    player.star_tower_map_param.clear();
    player.star_tower_client_data.clear();
}

//

test "formation comparison distinguishes unchanged and changed requests" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    const characters = [_]u32{ 1, 2, 3 };
    const discs = [_]u32{ 10, 11 };
    try player.setFormation(
        testing.allocator,
        2,
        &characters,
        &discs,
        7,
    );

    try testing.expect(player.formationMatches(2, &characters, &discs, 7));
    try testing.expect(!player.formationMatches(3, &characters, &discs, 7));
    try testing.expect(!player.formationMatches(2, characters[0..2], &discs, 7));
    try testing.expect(!player.formationMatches(2, &characters, discs[0..1], 7));
    try testing.expect(!player.formationMatches(2, &characters, &discs, 8));
}

test "tutorial lookup observes updates without adding duplicate groups" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);

    try testing.expectEqual(@as(?i32, null), player.guideStep(4));
    try player.learn(testing.allocator, 4, 2);
    try testing.expectEqual(@as(?i32, 2), player.guideStep(4));
    try player.learn(testing.allocator, 4, 2);
    try testing.expectEqual(@as(usize, 1), player.guides.len);
    try player.learn(testing.allocator, 4, 3);
    try testing.expectEqual(@as(?i32, 3), player.guideStep(4));
    try testing.expectEqual(@as(usize, 1), player.guides.len);
}
