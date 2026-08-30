const gameplay = @import("../gameplay.zig");
const handbook_view = @import("../view/handbook.zig");
const Player = @import("../store/Player.zig");
const player_view = @import("../view/player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");
const monthly_card = @import("mall_monthly_card.zig");

//

pub fn player_data_req(scope: *Scope) !void {
    const log = scope.logger(.player_data_req);

    _ = try scope.source.read(proto.pb.Nil);
    if (!scope.player.is_registered) {
        try scope.sink.sendEmpty(.player_new_notify);
        log.info("sent new-player notification", .{});
        return;
    }

    try gameplay.missions.login(scope.mutation(), scope.gpa, scope.now);
    _ = gameplay.energy.refresh(scope.mutation(), scope.now);
    _ = try gameplay.handbook.ensureDefaultSkins(scope.mutation(), scope.gpa);

    try response.send(scope);
    const today = gameplay.mall.cardDay(scope.now);
    const rewards = try gameplay.mall.grantMonthlyDaily(scope.mutation(), scope.gpa, today);
    try monthly_card.daily_rewards.send(scope, rewards, today);
}

pub const response = struct {
    pub fn send(scope: *Scope) !void {
        const player: *const Player = scope.player;
        const now = scope.now;
        const active_tower_formation = if (player.star_tower_run.active)
            player.getFormation(player.star_tower_run.formation_id)
        else
            null;
        var active_tower_char_ids: [Player.max_formation_characters]u32 = undefined;
        const active_tower_char_count: usize = if (active_tower_formation) |formation| blk: {
            @memcpy(active_tower_char_ids[0..formation.character_count], formation.character_ids[0..formation.character_count]);
            break :blk formation.character_count;
        } else 0;
        const resources = try scope.arena.alloc(proto.pb.Res, player.resources.slice().len);
        const items = try scope.arena.alloc(proto.pb.Item, player.items.slice().len);
        const titles = try scope.arena.alloc(proto.pb.Title, player.titles.slice().len);
        const honors = try scope.arena.alloc(proto.pb.HonorInfo, player.basic.honor_ids.len);
        var profile_characters: [Player.Basic.profile_char_slot_count]proto.pb.CharShow = undefined;
        const honor_list = try scope.arena.alloc(u32, 0);
        const discs = try scope.arena.alloc(proto.pb.Disc, player.discs.slice().len);
        const formations = try scope.arena.alloc(proto.pb.FormationInfo, player.formations.slice().len);
        const formation_characters = try scope.arena.alloc(
            [Player.max_formation_characters]u32,
            player.formations.slice().len,
        );
        const formation_discs = try scope.arena.alloc(
            [Player.max_formation_discs]u32,
            player.formations.slice().len,
        );
        const quests = try scope.arena.alloc(proto.pb.Quest, player.quests.slice().len);
        const quest_progress = try scope.arena.alloc(proto.pb.QuestProgress, player.quests.slice().len);
        const daily_active_ids_buffer = try scope.arena.alloc(u32, tables.quest.daily_active.len);
        const weekly_active_ids_buffer = try scope.arena.alloc(u32, tables.quest.weekly_active.len);
        const daily_active_ids = gameplay.missions.activeIds(player, .daily, daily_active_ids_buffer);
        const weekly_active_ids = gameplay.missions.activeIds(player, .weekly, weekly_active_ids_buffer);
        const assists = try scope.arena.alloc(proto.pb.AssistInfo, player.assists.slice().len);
        const tutorial_levels = try scope.arena.alloc(proto.pb.TutorialLevel, player.tutorials.slice().len);
        const story_evidences = try scope.arena.alloc(u32, player.story_evidences.slice().len);
        const stories = try scope.arena.alloc(proto.pb.Story, player.stories.slice().len);
        const story_major_choices = try scope.arena.alloc(proto.pb.StoryChoice, player.story_choices.slice().len);
        const story_personality_choices = try scope.arena.alloc(proto.pb.StoryChoice, player.story_choices.slice().len);
        var active_activity_entries: [tables.activity.list.len]tables.activity.Entry = undefined;
        var activities: [tables.activity.list.len]proto.pb.Activity = undefined;
        var activity_states: [tables.activity.list.len]proto.pb.ActivityState = undefined;
        const dictionaries = try scope.arena.alloc(proto.pb.DictionaryEntry, player.dictionaries.slice().len);
        const dictionary_tabs = try scope.arena.alloc(proto.pb.DictionaryTab, player.dictionaries.slice().len);
        const dictionary_seen = try scope.arena.alloc(bool, player.dictionaries.slice().len);
        @memset(dictionary_seen, false);
        const newbies = try scope.arena.alloc(proto.pb.NewbieInfo, player.guides.slice().len);
        const tower_book_reward_char_ids = try scope.arena.alloc(
            u32,
            tables.star_tower_book.potential_rewards.len,
        );
        var tower_book_reward_char_count: usize = 0;
        const tower_book_event_reward_ids = try scope.arena.alloc(u32, player.quests.slice().len);
        var tower_book_event_reward_count: usize = 0;
        for (player.guides.slice(), 0..) |guide, index| {
            newbies[index] = .{
                .GroupId = guide.group_id,
                .StepId = guide.step_id,
            };
        }
        const chars = try scope.arena.alloc(proto.pb.Char, player.characters.count());
        const character_buffers = try scope.arena.alloc(player_view.CharacterBuffers, player.characters.count());
        const board = try scope.arena.alloc(u32, player.board.slice().len);
        var handbook_bitmaps: [tables.handbook.type_count][tables.handbook.max_bitmap_len]u8 = undefined;
        var handbook_infos: [tables.handbook.type_count]proto.pb.HandbookInfo = undefined;
        var handbook_count: usize = 0;

        for (&handbook_bitmaps) |*bitmap| @memset(bitmap, 0);
        for (player.resources.slice(), 0..) |resource, index| resources[index] = .{
            .Tid = resource.id,
            .Qty = resource.quantity,
        };
        for (player.items.slice(), 0..) |item, index| items[index] = .{
            .Id = item.id,
            .Tid = item.template_id,
            .Qty = item.quantity,
            .Expire = item.expires_at,
        };
        for (player.titles.slice(), 0..) |title, index| titles[index] = .{
            .TitleId = title.id,
        };
        for (honors, player.basic.honor_ids) |*honor, id|
            honor.* = .{ .Id = id };
        for (&profile_characters, player.basic.profile_char_ids) |*show, id|
            show.* = if (player.characters.get(id)) |character|
                player_view.charShow(id, character)
            else
                .{};
        for (player.discs.slice(), 0..) |*disc, index|
            discs[index] = player_view.disc(disc);
        for (player.formations.slice(), 0..) |formation, index| {
            const character_count: usize = formation.character_count;
            const disc_count: usize = formation.disc_count;
            @memcpy(formation_characters[index][0..character_count], formation.character_ids[0..character_count]);
            @memcpy(formation_discs[index][0..disc_count], formation.disc_ids[0..disc_count]);
            formations[index] = .{
                .Number = formation.number,
                .CharIds = .fromOwnedSlice(formation_characters[index][0..character_count]),
                .DiscIds = .fromOwnedSlice(formation_discs[index][0..disc_count]),
                .PreselectionId = formation.preselection_id,
            };
        }
        for (player.quests.slice(), 0..) |quest, index| {
            quest_progress[index] = .{
                .Cur = quest.progress_current,
                .Max = quest.progress_max,
            };
            quests[index] = .{
                .Id = quest.id,
                .Status = if (quest.claimed) 2 else if (quest.progress_current >= quest.progress_max) 1 else 0,
                .Expire = quest.expires_at,
                .Type = @enumFromInt(quest.quest_type),
                .Progress = .fromOwnedSlice(quest_progress[index .. index + 1]),
            };

            if (quest.quest_type == @intFromEnum(tables.quest.Type.tower_event) and
                !quest.claimed and
                quest.progress_current >= quest.progress_max)
            {
                tower_book_event_reward_ids[tower_book_event_reward_count] = quest.id;
                tower_book_event_reward_count += 1;
            }
        }
        for (tables.star_tower_book.potential_rewards) |definition| {
            if (player.hasTowerBookPotentialReward(definition.id) or
                player.towerBookPotentialCount(definition.character_id) < definition.potential_count)
                continue;
            var already_added = false;
            for (tower_book_reward_char_ids[0..tower_book_reward_char_count]) |character_id| {
                if (character_id != definition.character_id)
                    continue;
                already_added = true;
                break;
            }
            if (already_added)
                continue;
            if (tower_book_reward_char_count == tower_book_reward_char_ids.len) break;
            tower_book_reward_char_ids[tower_book_reward_char_count] = definition.character_id;
            tower_book_reward_char_count += 1;
        }
        for (player.assists.slice(), 0..) |assist, index| assists[index] = .{
            .Attribute = assist.attribute_id,
            .Group = assist.group_id,
        };
        for (player.tutorials.slice(), 0..) |level, index| tutorial_levels[index] = .{
            .LevelId = level.level_id,
            .Passed = level.passed,
            .RewardReceived = level.reward_received,
        };
        for (player.story_evidences.slice(), 0..) |evidence, index|
            story_evidences[index] = evidence.id;
        var story_major_choice_count: usize = 0;
        var story_personality_choice_count: usize = 0;
        for (player.stories.slice(), 0..) |story, story_index| {
            const major_start = story_major_choice_count;
            const personality_start = story_personality_choice_count;
            var major_count: usize = 0;
            var personality_count: usize = 0;
            for (player.story_choices.slice()) |choice| {
                if (choice.story_index != story.index)
                    continue;

                const out = proto.pb.StoryChoice{
                    .Group = choice.group,
                    .Value = choice.value,
                };
                if (choice.personality) {
                    story_personality_choices[story_personality_choice_count] = out;
                    story_personality_choice_count += 1;
                    personality_count += 1;
                } else {
                    story_major_choices[story_major_choice_count] = out;
                    story_major_choice_count += 1;
                    major_count += 1;
                }
            }
            stories[story_index] = .{
                .Idx = story.index,
                .Major = .fromOwnedSlice(story_major_choices[major_start..][0..major_count]),
                .Personality = .fromOwnedSlice(story_personality_choices[personality_start..][0..personality_count]),
            };
        }
        const active_activities = gameplay.activity.active(now, player.basic.created_at, &active_activity_entries);
        var activity_state_count: usize = 0;
        for (active_activities, 0..) |activity, index| activities[index] = .{
            .Id = activity.id,
            .StartTime = activity.start_at,
            .EndTime = activity.end_at,
        };
        for (active_activities) |activity| {
            if (!gameplay.activity.showsNew(activity))
                continue;
            activity_states[activity_state_count] = .{ .Id = activity.id, .RedDot = true };
            activity_state_count += 1;
        }
        var dictionary_count: usize = 0;
        var dictionary_tab_count: usize = 0;
        for (player.dictionaries.slice(), 0..) |first, first_index| {
            if (dictionary_seen[first_index])
                continue;

            const tab_start = dictionary_count;
            for (player.dictionaries.slice(), 0..) |entry, index| {
                if (entry.tab_id != first.tab_id)
                    continue;
                dictionary_seen[index] = true;
                dictionaries[dictionary_count] = .{
                    .Index = entry.index,
                    .Status = entry.status,
                };
                dictionary_count += 1;
            }
            dictionary_tabs[dictionary_tab_count] = .{
                .TabId = first.tab_id,
                .Entries = .fromOwnedSlice(dictionaries[tab_start..dictionary_count]),
            };
            dictionary_tab_count += 1;
        }
        for (player.board.slice(), 0..) |entry, index| board[index] = entry.handbook_id;
        for (&handbook_bitmaps, 0..) |*bitmap, handbook_type| {
            if (handbook_view.info(player, handbook_type, bitmap)) |info| {
                handbook_infos[handbook_count] = info;
                handbook_count += 1;
            }
        }

        var character_count: usize = 0;
        var character_iterator = player.characters.iterator();
        while (character_iterator.next()) |character| {
            chars[character_count] = player_view.character(
                character.id(),
                character.value,
                &character_buffers[character_count],
            );
            character_count += 1;
        }

        const message: proto.pb.PlayerInfo = .{
            .Acc = .{
                .Id = player.uid.?,
                .NickName = player.nickname(),
                .HeadIcon = player.basic.head_icon,
                .TitlePrefix = player.basic.title_prefix,
                .TitleSuffix = player.basic.title_suffix,
                .Signature = player.basic.signature.view(),
                .Chars = .fromOwnedSlice(&profile_characters),
                .SkinId = player.basic.profile_skin_id,
                .CreateTime = player.basic.created_at,
                .Gender = player.basic.gender == .male,
                .Newbies = .fromOwnedSlice(newbies[0..player.guides.slice().len]),
            },
            .Res = .fromOwnedSlice(resources[0..player.resources.slice().len]),
            .Items = .fromOwnedSlice(items[0..player.items.slice().len]),
            .Chars = .fromOwnedSlice(chars[0..character_count]),
            .Formation = .{ .Info = .fromOwnedSlice(formations[0..player.formations.slice().len]) },
            .Board = .fromOwnedSlice(board[0..player.board.slice().len]),
            .Handbook = .fromOwnedSlice(handbook_infos[0..handbook_count]),
            .Titles = .fromOwnedSlice(titles[0..player.titles.slice().len]),
            .HonorList = .fromOwnedSlice(honor_list),
            .Honors = .fromOwnedSlice(honors),
            .Discs = .fromOwnedSlice(discs[0..player.discs.slice().len]),
            .Dictionaries = .fromOwnedSlice(dictionary_tabs[0..dictionary_tab_count]),
            .Activities = .fromOwnedSlice(activities[0..active_activities.len]),
            .Energy = .{
                .Energy = .{
                    .Primary = @intFromEnum(player.basic.primary_energy),
                    .IsPrimary = true,
                    .UpdateTime = player.basic.energy_updated_at,
                    .NextDuration = gameplay.energy.nextDuration(player, now),
                },
            },
            .WorldClass = .{ .Cur = @intFromEnum(player.basic.level) },
            .Agent = .{},
            .Achievements = &player.progress.achievement_bits,
            .Quests = .{
                .List = .fromOwnedSlice(quests[0..player.quests.slice().len]),
            },
            .DailyActiveIds = .fromOwnedSlice(daily_active_ids),
            .Assists = .fromOwnedSlice(assists[0..player.assists.slice().len]),
            .TourGuideQuestGroup = player.progress.tour_guide_quest_group,
            .TutorialLevels = .fromOwnedSlice(tutorial_levels[0..player.tutorials.slice().len]),
            .WeeklyActiveIds = .fromOwnedSlice(weekly_active_ids),
            .DailyMallRewardStatus = gameplay.mall.dailyMallRewardAvailable(scope.player, now),
            .TowerTicket = player.progress.tower_ticket,
            .State = .{
                .Mail = .{ .New = false },
                .BattlePass = .{},
                .WorldClassReward = .{},
                .FriendEnergy = .{},
                .MallPackage = .{},
                .Achievement = .{},
                .TravelerDuelQuest = .{},
                .StarTower = if (player.star_tower_run.active) .{
                    .Id = player.star_tower_run.tower_id,
                    .ReConnection = 1,
                    .CharIds = .fromOwnedSlice(active_tower_char_ids[0..active_tower_char_count]),
                    .Floor = player.star_tower_run.floor,
                    .Sweep = player.star_tower_run.sweep,
                } else .{},
                .StarTowerBook = .{
                    .CharIds = .fromOwnedSlice(tower_book_reward_char_ids[0..tower_book_reward_char_count]),
                    .EventIds = .fromOwnedSlice(tower_book_event_reward_ids[0..tower_book_event_reward_count]),
                },
                .ScoreBoss = .{},
                .Activities = .fromOwnedSlice(activity_states[0..activity_state_count]),
                .TraceHunt = .{},
                .StorySet = true,
            },
            .Phone = .{},
            .Story = .{
                .BuildId = player.progress.story_build_id,
                .Evidences = .fromOwnedSlice(story_evidences[0..player.story_evidences.slice().len]),
                .Stories = .fromOwnedSlice(stories[0..player.stories.slice().len]),
            },
            .VampireSurvivorRecord = .{},
            .HuntPermit = .{},
            .TraceRequest = .{},
            .LastRead = .{},
            .ServerTs = now,
        };

        try scope.sink.sendProto(.player_data_succeed_ack, &message);
    }
};
