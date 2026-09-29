pub const PacketId = enum(i16) {
    clear_all_activity_iceCream_levels_notify = -10057,
    sd_soldier_effect_notify = -10056,
    sd_soldier_info_notify = -10055,
    sd_shop_data_notify = -10054,
    sd_item_change_notify = -10053,
    sd_buff_card_add_notify = -10052,
    clear_all_activity_golden_spy_levels_notify = -10051,
    clear_all_activity_breakout_levels_notify = -10050,
    clear_story_set_notify = -10049,
    unlock_activity_story_notify = -10048,
    assist_add_build_notify = -10047,
    clear_all_activity_levels_notify = -10046,
    clear_all_activity_avg_notify = -10045,
    vs_add_fate_card_notify = -10044,
    char_gems_import_notify = -10043,
    char_gems_export_notify = -10042,
    clear_all_char_gem_instance_notify = -10040,
    change_npc_affinity_notify = -10039,
    tower_change_sub_note_skill_notify = -10038,
    world_class_quest_complete_notify = -10037,
    score_boss_level_reset_notify = -10036,
    score_boss_star_reward_reset_notify = -10035,
    char_up_change_notify = -10034,
    tower_growth_node_change_notify = -10033,
    st_harmony_skill_notify = -10032,
    clear_all_story_notify = -10031,
    story_complete_notify = -10030,
    infinity_tower_skip_floor_notify = -10029,
    infinity_tower_all_infos_notify = -10028,
    clear_all_equipment_instance_notify = -10027,
    st_import_build_notify = -10026,
    st_export_build_notify = -10025,
    st_add_new_case_notify = -10024,
    st_add_team_exp_notify = -10023,
    st_skip_floor_notify = -10022,
    st_clear_all_star_tower_notify = -10021,
    st_items_change_notify = -10020,
    char_affinity_final_notify = -10019,
    clear_all_skill_instance_notify = -10018,
    disc_reset_notify = -10017,
    clear_all_traveler_due_notify = -10016,
    clear_all_region_boss_level_notify = -10015,
    clear_all_week_boss_notify = -10014,
    clear_all_daily_instance_notify = -10013,
    refresh_agent_notify = -10012,
    star_tower_sub_note_skill_info_notify = -10011,
    vampire_survivor_talent_node_notify = -10010,
    add_vampire_season_score_notify = -10009,
    clear_all_vampire_survivor_notify = -10008,
    region_boss_level_final_notify = -10007,
    chars_final_notify = -10006,
    world_class_number_notify = -10005,
    char_change_notify = -10004,
    char_reset_notify = -10003,
    items_change_notify = -10001,
    sudo_failed_ack = -3,
    sudo_succeed_ack = -2,
    sudo_req = -1,
    ike_req = 1,
    ike_succeed_ack = 2,
    ike_failed_ack = 3,
    player_login_req = 4,
    player_login_succeed_ack = 5,
    player_login_failed_ack = 6,
    player_data_req = 1001,
    player_data_succeed_ack = 1002,
    player_data_failed_ack = 1003,
    player_reg_req = 1004,
    player_reg_failed_ack = 1005,
    player_name_edit_req = 1006,
    player_name_edit_succeed_ack = 1007,
    player_name_edit_failed_ack = 1008,
    player_head_icon_set_req = 1009,
    player_head_icon_set_succeed_ack = 1010,
    player_head_icon_set_failed_ack = 1011,
    player_ping_req = 1012,
    player_ping_succeed_ack = 1013,
    player_ping_failed_ack = 1014,
    player_learn_req = 1015,
    player_learn_succeed_ack = 1016,
    player_learn_failed_ack = 1017,
    player_destroy_req = 1018,
    player_destroy_succeed_ack = 1019,
    player_destroy_failed_ack = 1020,
    player_board_set_req = 1021,
    player_board_set_succeed_ack = 1022,
    player_board_set_failed_ack = 1023,
    player_world_class_reward_receive_req = 1024,
    player_world_class_reward_receive_succeed_ack = 1025,
    player_world_class_reward_receive_failed_ack = 1026,
    player_signature_edit_req = 1027,
    player_signature_edit_succeed_ack = 1028,
    player_signature_edit_failed_ack = 1029,
    player_title_edit_req = 1030,
    player_title_edit_succeed_ack = 1031,
    player_title_edit_failed_ack = 1032,
    player_chars_show_req = 1033,
    player_chars_show_succeed_ack = 1034,
    player_chars_show_failed_ack = 1035,
    player_skin_show_req = 1036,
    player_skin_show_succeed_ack = 1037,
    player_skin_show_failed_ack = 1038,
    player_gender_edit_req = 1039,
    player_gender_edit_succeed_ack = 1040,
    player_gender_edit_failed_ack = 1041,
    player_survey_req = 1042,
    player_survey_succeed_ack = 1043,
    player_survey_failed_ack = 1044,
    player_exit_req = 1045,
    player_exit_succeed_ack = 1046,
    player_exit_failed_ack = 1047,
    player_honor_edit_req = 1048,
    player_honor_edit_succeed_ack = 1049,
    player_honor_edit_failed_ack = 1050,
    player_world_class_advance_req = 1051,
    player_world_class_advance_succeed_ack = 1052,
    player_world_class_advance_failed_ack = 1053,
    player_music_set_req = 1054,
    player_music_set_succeed_ack = 1055,
    player_music_set_failed_ack = 1056,
    player_head_icon_info_req = 1057,
    player_head_icon_info_succeed_ack = 1058,
    player_head_icon_info_failed_ack = 1059,
    item_use_req = 1101,
    item_use_succeed_ack = 1102,
    item_use_failed_ack = 1103,
    gem_convert_req = 1104,
    gem_convert_succeed_ack = 1105,
    gem_convert_failed_ack = 1106,
    item_product_req = 1107,
    item_product_succeed_ack = 1108,
    item_product_failed_ack = 1109,
    fragments_convert_req = 1110,
    fragments_convert_succeed_ack = 1111,
    fragments_convert_failed_ack = 1112,
    daily_shop_reward_receive_req = 1113,
    daily_shop_reward_receive_succeed_ack = 1114,
    daily_shop_reward_receive_failed_ack = 1115,
    item_quick_growth_req = 1116,
    item_quick_growth_succeed_ack = 1117,
    item_quick_growth_failed_ack = 1118,
    daily_mall_reward_receive_req = 1119,
    daily_mall_reward_receive_succeed_ack = 1120,
    daily_mall_reward_receive_failed_ack = 1121,
    friend_list_get_req = 1201,
    friend_list_get_succeed_ack = 1202,
    friend_list_get_failed_ack = 1203,
    friend_uid_search_req = 1204,
    friend_uid_search_succeed_ack = 1205,
    friend_uid_search_failed_ack = 1206,
    friend_name_search_req = 1207,
    friend_name_search_succeed_ack = 1208,
    friend_name_search_failed_ack = 1209,
    friend_add_req = 1210,
    friend_add_succeed_ack = 1211,
    friend_add_failed_ack = 1212,
    friend_add_agree_req = 1213,
    friend_add_agree_succeed_ack = 1214,
    friend_add_agree_failed_ack = 1215,
    friend_all_agree_req = 1216,
    friend_all_agree_succeed_ack = 1217,
    friend_all_agree_failed_ack = 1218,
    friend_delete_req = 1219,
    friend_delete_succeed_ack = 1220,
    friend_delete_failed_ack = 1221,
    friend_invites_delete_req = 1222,
    friend_invites_delete_succeed_ack = 1223,
    friend_invites_delete_failed_ack = 1224,
    friend_star_set_req = 1225,
    friend_star_set_succeed_ack = 1226,
    friend_star_set_failed_ack = 1227,
    friend_receive_energy_req = 1228,
    friend_receive_energy_succeed_ack = 1229,
    friend_receive_energy_failed_ack = 1230,
    friend_send_energy_req = 1231,
    friend_send_energy_succeed_ack = 1232,
    friend_send_energy_failed_ack = 1233,
    friend_recommendation_get_req = 1234,
    friend_recommendation_get_succeed_ack = 1235,
    friend_recommendation_get_failed_ack = 1236,
    tower_growth_detail_req = 1301,
    tower_growth_detail_succeed_ack = 1302,
    tower_growth_detail_failed_ack = 1303,
    tower_growth_node_unlock_req = 1304,
    tower_growth_node_unlock_succeed_ack = 1305,
    tower_growth_node_unlock_failed_ack = 1306,
    tower_growth_group_node_unlock_req = 1307,
    tower_growth_group_node_unlock_succeed_ack = 1308,
    tower_growth_group_node_unlock_failed_ack = 1309,
    milkout_settle_req = 1401,
    milkout_settle_succeed_ack = 1402,
    milkout_settle_failed_ack = 1403,
    activity_gds_settle_req = 1501,
    activity_gds_settle_succeed_ack = 1502,
    activity_gds_settle_failed_ack = 1503,
    activity_soldier_quest_reward_receive_req = 1601,
    activity_soldier_quest_reward_receive_succeed_ack = 1602,
    activity_soldier_quest_reward_receive_failed_ack = 1603,
    player_formation_req = 2001,
    player_formation_succeed_ack = 2002,
    player_formation_failed_ack = 2003,
    char_upgrade_req = 2301,
    char_upgrade_succeed_ack = 2302,
    char_upgrade_failed_ack = 2303,
    char_advance_req = 2304,
    char_advance_succeed_ack = 2305,
    char_advance_failed_ack = 2306,
    char_skill_upgrade_req = 2307,
    char_skill_upgrade_succeed_ack = 2308,
    char_skill_upgrade_failed_ack = 2309,
    char_advance_reward_receive_req = 2313,
    char_advance_reward_receive_succeed_ack = 2314,
    char_advance_reward_receive_failed_ack = 2315,
    char_skin_set_req = 2316,
    char_skin_set_succeed_ack = 2317,
    char_skin_set_failed_ack = 2318,
    char_affinity_quest_reward_receive_req = 2322,
    char_affinity_quest_reward_receive_succeed_ack = 2323,
    char_affinity_quest_reward_receive_failed_ack = 2324,
    char_recruitment_req = 2325,
    char_recruitment_succeed_ack = 2326,
    char_recruitment_failed_ack = 2327,
    char_affinity_gift_send_req = 2328,
    char_affinity_gift_send_succeed_ack = 2329,
    char_affinity_gift_send_failed_ack = 2330,
    char_dating_landmark_select_req = 2401,
    char_dating_landmark_select_succeed_ack = 2402,
    char_dating_landmark_select_failed_ack = 2403,
    char_dating_gift_send_req = 2404,
    char_dating_gift_send_succeed_ack = 2405,
    char_dating_gift_send_failed_ack = 2406,
    char_dating_event_reward_receive_req = 2407,
    char_dating_event_reward_receive_succeed_ack = 2408,
    char_dating_event_reward_receive_failed_ack = 2409,
    char_archive_reward_receive_req = 2410,
    char_archive_reward_receive_succeed_ack = 2411,
    char_archive_reward_receive_failed_ack = 2412,
    char_dating_branch_a_select_req = 2413,
    char_dating_branch_a_select_succeed_ack = 2414,
    char_dating_branch_a_select_failed_ack = 2415,
    char_dating_branch_b_select_req = 2416,
    char_dating_branch_b_select_succeed_ack = 2417,
    char_dating_branch_b_select_failed_ack = 2418,
    char_gem_generate_req = 2501,
    char_gem_generate_succeed_ack = 2502,
    char_gem_generate_failed_ack = 2503,
    char_gem_refresh_req = 2504,
    char_gem_refresh_succeed_ack = 2505,
    char_gem_refresh_failed_ack = 2506,
    char_gem_replace_attribute_req = 2507,
    char_gem_replace_attribute_succeed_ack = 2508,
    char_gem_replace_attribute_failed_ack = 2509,
    char_gem_update_gem_lock_status_req = 2510,
    char_gem_update_gem_lock_status_succeed_ack = 2511,
    char_gem_update_gem_lock_status_failed_ack = 2512,
    char_gem_use_preset_req = 2513,
    char_gem_use_preset_succeed_ack = 2514,
    char_gem_use_preset_failed_ack = 2515,
    char_gem_rename_preset_req = 2516,
    char_gem_rename_preset_succeed_ack = 2517,
    char_gem_rename_preset_failed_ack = 2518,
    char_gem_equip_gem_req = 2519,
    char_gem_equip_gem_succeed_ack = 2520,
    char_gem_equip_gem_failed_ack = 2521,
    char_gem_overlock_revert_req = 2522,
    char_gem_overlock_revert_succeed_ack = 2523,
    char_gem_overlock_revert_failed_ack = 2524,
    char_gem_overlock_req = 2525,
    char_gem_overlock_succeed_ack = 2526,
    char_gem_overlock_failed_ack = 2527,
    char_favorite_set_req = 2601,
    char_favorite_set_succeed_ack = 2602,
    char_favorite_set_failed_ack = 2603,
    disc_strengthen_req = 3119,
    disc_strengthen_succeed_ack = 3120,
    disc_strengthen_failed_ack = 3121,
    disc_promote_req = 3122,
    disc_promote_succeed_ack = 3123,
    disc_promote_failed_ack = 3124,
    disc_limit_break_req = 3125,
    disc_limit_break_succeed_ack = 3126,
    disc_limit_break_failed_ack = 3127,
    disc_read_reward_receive_req = 3128,
    disc_read_reward_receive_succeed_ack = 3129,
    disc_read_reward_receive_failed_ack = 3130,
    disc_all_limit_break_req = 3131,
    disc_all_limit_break_succeed_ack = 3132,
    disc_all_limit_break_failed_ack = 3133,
    agent_apply_req = 3301,
    agent_apply_succeed_ack = 3302,
    agent_apply_failed_ack = 3303,
    agent_give_up_req = 3304,
    agent_give_up_succeed_ack = 3305,
    agent_give_up_failed_ack = 3306,
    agent_reward_receive_req = 3307,
    agent_reward_receive_succeed_ack = 3308,
    agent_reward_receive_failed_ack = 3309,
    quest_tour_guide_reward_receive_req = 4201,
    quest_tour_guide_reward_receive_succeed_ack = 4202,
    quest_tour_guide_reward_receive_failed_ack = 4203,
    quest_daily_reward_receive_req = 4204,
    quest_daily_reward_receive_succeed_ack = 4205,
    quest_daily_reward_receive_failed_ack = 4206,
    dictionary_reward_receive_req = 4207,
    dictionary_reward_receive_succeed_ack = 4208,
    dictionary_reward_receive_failed_ack = 4209,
    quest_tower_reward_receive_req = 4210,
    quest_tower_reward_receive_succeed_ack = 4211,
    quest_tower_reward_receive_failed_ack = 4212,
    quest_daily_active_reward_receive_req = 4213,
    quest_daily_active_reward_receive_succeed_ack = 4214,
    quest_daily_active_reward_receive_failed_ack = 4215,
    quest_tour_guide_group_reward_receive_req = 4216,
    quest_tour_guide_group_reward_receive_succeed_ack = 4217,
    quest_tour_guide_group_reward_receive_failed_ack = 4218,
    quest_weekly_reward_receive_req = 4219,
    quest_weekly_reward_receive_succeed_ack = 4220,
    quest_weekly_reward_receive_failed_ack = 4221,
    quest_weekly_active_reward_receive_req = 4222,
    quest_weekly_active_reward_receive_succeed_ack = 4223,
    quest_weekly_active_reward_receive_failed_ack = 4224,
    quest_assist_reward_receive_req = 4225,
    quest_assist_reward_receive_succeed_ack = 4226,
    quest_assist_reward_receive_failed_ack = 4227,
    quest_assist_group_reward_receive_req = 4228,
    quest_assist_group_reward_receive_succeed_ack = 4229,
    quest_assist_group_reward_receive_failed_ack = 4230,
    activity_task_reward_receive_req = 4301,
    activity_task_reward_receive_succeed_ack = 4302,
    activity_task_reward_receive_failed_ack = 4303,
    activity_task_group_reward_receive_req = 4304,
    activity_task_group_reward_receive_succeed_ack = 4305,
    activity_task_group_reward_receive_failed_ack = 4306,
    achievement_reward_receive_req = 4401,
    achievement_reward_receive_succeed_ack = 4402,
    achievement_reward_receive_failed_ack = 4403,
    achievement_info_req = 4404,
    achievement_info_succeed_ack = 4405,
    achievement_info_failed_ack = 4406,
    infinity_tower_info_req = 4501,
    infinity_tower_info_succeed_ack = 4502,
    infinity_tower_info_failed_ack = 4503,
    infinity_tower_apply_req = 4504,
    infinity_tower_apply_succeed_ack = 4505,
    infinity_tower_apply_failed_ack = 4506,
    infinity_tower_settle_req = 4507,
    infinity_tower_settle_succeed_ack = 4508,
    infinity_tower_settle_failed_ack = 4509,
    infinity_tower_daily_reward_receive_req = 4510,
    infinity_tower_daily_reward_receive_succeed_ack = 4511,
    infinity_tower_daily_reward_receive_failed_ack = 4512,
    infinity_tower_plot_reward_receive_req = 4513,
    infinity_tower_plot_reward_receive_succeed_ack = 4514,
    infinity_tower_plot_reward_receive_failed_ack = 4515,
    star_tower_apply_req = 4601,
    star_tower_apply_succeed_ack = 4602,
    star_tower_apply_failed_ack = 4603,
    star_tower_interact_req = 4607,
    star_tower_interact_succeed_ack = 4608,
    star_tower_interact_failed_ack = 4609,
    star_tower_info_req = 4610,
    star_tower_info_succeed_ack = 4611,
    star_tower_info_failed_ack = 4612,
    star_tower_give_up_req = 4613,
    star_tower_give_up_succeed_ack = 4614,
    star_tower_give_up_failed_ack = 4615,
    star_tower_build_whether_save_req = 4701,
    star_tower_build_whether_save_succeed_ack = 4702,
    star_tower_build_whether_save_failed_ack = 4703,
    star_tower_build_brief_list_get_req = 4704,
    star_tower_build_brief_list_get_succeed_ack = 4705,
    star_tower_build_brief_list_get_failed_ack = 4706,
    star_tower_build_detail_get_req = 4707,
    star_tower_build_detail_get_succeed_ack = 4708,
    star_tower_build_detail_get_failed_ack = 4709,
    star_tower_build_delete_req = 4710,
    star_tower_build_delete_succeed_ack = 4711,
    star_tower_build_delete_failed_ack = 4712,
    star_tower_build_name_set_req = 4713,
    star_tower_build_name_set_succeed_ack = 4714,
    star_tower_build_name_set_failed_ack = 4715,
    star_tower_build_lock_unlock_req = 4716,
    star_tower_build_lock_unlock_succeed_ack = 4717,
    star_tower_build_lock_unlock_failed_ack = 4718,
    star_tower_build_preference_set_req = 4719,
    star_tower_build_preference_set_succeed_ack = 4720,
    star_tower_build_preference_set_failed_ack = 4721,
    potential_preselection_list_req = 4722,
    potential_preselection_list_succeed_ack = 4723,
    potential_preselection_list_failed_ack = 4724,
    potential_preselection_import_req = 4725,
    potential_preselection_import_succeed_ack = 4726,
    potential_preselection_import_failed_ack = 4727,
    potential_preselection_name_set_req = 4728,
    potential_preselection_name_set_succeed_ack = 4729,
    potential_preselection_name_set_failed_ack = 4730,
    potential_preselection_preference_set_req = 4731,
    potential_preselection_preference_set_succeed_ack = 4732,
    potential_preselection_preference_set_failed_ack = 4733,
    potential_preselection_update_req = 4734,
    potential_preselection_update_succeed_ack = 4735,
    potential_preselection_update_failed_ack = 4736,
    potential_preselection_delete_req = 4737,
    potential_preselection_delete_succeed_ack = 4738,
    potential_preselection_delete_failed_ack = 4739,
    build_convert_detail_list_get_req = 4801,
    build_convert_detail_list_get_succeed_ack = 4802,
    build_convert_detail_list_get_failed_ack = 4803,
    build_convert_submit_req = 4804,
    build_convert_submit_succeed_ack = 4805,
    build_convert_submit_failed_ack = 4806,
    build_convert_group_reward_receive_req = 4807,
    build_convert_group_reward_receive_succeed_ack = 4808,
    build_convert_group_reward_receive_failed_ack = 4809,
    star_tower_book_potential_brief_list_get_req = 4901,
    star_tower_book_potential_brief_list_get_succeed_ack = 4902,
    star_tower_book_potential_brief_list_get_failed_ack = 4903,
    star_tower_book_char_potential_get_req = 4904,
    star_tower_book_char_potential_get_succeed_ack = 4905,
    star_tower_book_char_potential_get_failed_ack = 4906,
    star_tower_book_potential_reward_receive_req = 4907,
    star_tower_book_potential_reward_receive_succeed_ack = 4908,
    star_tower_book_potential_reward_receive_failed_ack = 4909,
    star_tower_book_event_reward_receive_req = 4913,
    star_tower_book_event_reward_receive_succeed_ack = 4914,
    star_tower_book_event_reward_receive_failed_ack = 4915,
    npc_affinity_book_get_req = 4916,
    npc_affinity_book_get_succeed_ack = 4917,
    npc_affinity_book_get_failed_ack = 4918,
    npc_affinity_plot_reward_receive_req = 4919,
    npc_affinity_plot_reward_receive_succeed_ack = 4920,
    npc_affinity_plot_reward_receive_failed_ack = 4921,
    resident_shop_get_req = 5010,
    resident_shop_get_succeed_ack = 5011,
    resident_shop_get_failed_ack = 5012,
    resident_shop_purchase_req = 5013,
    resident_shop_purchase_succeed_ack = 5014,
    resident_shop_purchase_failed_ack = 5015,
    mall_gem_list_req = 5101,
    mall_gem_list_succeed_ack = 5102,
    mall_gem_list_failed_ack = 5103,
    mall_gem_order_req = 5104,
    mall_gem_order_succeed_ack = 5105,
    mall_gem_order_failed_ack = 5106,
    mall_order_cancel_req = 5107,
    mall_order_cancel_succeed_ack = 5108,
    mall_order_cancel_failed_ack = 5109,
    mall_order_collect_req = 5110,
    mall_order_collect_succeed_ack = 5111,
    mall_order_collect_failed_ack = 5112,
    mall_monthlyCard_list_req = 5113,
    mall_monthlyCard_list_succeed_ack = 5114,
    mall_monthlyCard_list_failed_ack = 5115,
    mall_monthlyCard_order_req = 5116,
    mall_monthlyCard_order_succeed_ack = 5117,
    mall_monthlyCard_order_failed_ack = 5118,
    mall_package_list_req = 5119,
    mall_package_list_succeed_ack = 5120,
    mall_package_list_failed_ack = 5121,
    mall_package_order_req = 5122,
    mall_package_order_succeed_ack = 5123,
    mall_package_order_failed_ack = 5124,
    mall_shop_list_req = 5125,
    mall_shop_list_succeed_ack = 5126,
    mall_shop_list_failed_ack = 5127,
    mall_shop_order_req = 5128,
    mall_shop_order_succeed_ack = 5129,
    mall_shop_order_failed_ack = 5130,
    trace_hunt_info_req = 5201,
    trace_hunt_info_succeed_ack = 5202,
    trace_hunt_info_failed_ack = 5203,
    trace_hunt_apply_req = 5204,
    trace_hunt_apply_succeed_ack = 5205,
    trace_hunt_apply_failed_ack = 5206,
    trace_hunt_settle_req = 5207,
    trace_hunt_settle_succeed_ack = 5208,
    trace_hunt_settle_failed_ack = 5209,
    trace_hunt_recommend_req = 5210,
    trace_hunt_recommend_succeed_ack = 5211,
    trace_hunt_recommend_failed_ack = 5212,
    trace_hunt_boss_reward_receive_req = 5213,
    trace_hunt_boss_reward_receive_succeed_ack = 5214,
    trace_hunt_boss_reward_receive_failed_ack = 5215,
    trace_hunt_trace_req = 5216,
    trace_hunt_trace_succeed_ack = 5217,
    trace_hunt_trace_failed_ack = 5218,
    soldier_apply_req = 5301,
    soldier_apply_succeed_ack = 5302,
    soldier_apply_failed_ack = 5303,
    soldier_info_req = 5304,
    soldier_info_succeed_ack = 5305,
    soldier_info_failed_ack = 5306,
    soldier_interact_req = 5307,
    soldier_interact_succeed_ack = 5308,
    soldier_interact_failed_ack = 5309,
    soldier_give_up_req = 5310,
    soldier_give_up_succeed_ack = 5311,
    soldier_give_up_failed_ack = 5312,
    soldier_step_out_req = 5313,
    soldier_step_out_succeed_ack = 5314,
    soldier_step_out_failed_ack = 5315,
    soldier_partner_trace_req = 5316,
    soldier_partner_trace_succeed_ack = 5317,
    soldier_partner_trace_failed_ack = 5318,
    gacha_spin_req = 6001,
    gacha_spin_succeed_ack = 6002,
    gacha_spin_failed_ack = 6003,
    gacha_information_req = 6004,
    gacha_information_succeed_ack = 6005,
    gacha_information_failed_ack = 6006,
    gacha_histories_req = 6007,
    gacha_histories_succeed_ack = 6008,
    gacha_histories_failed_ack = 6009,
    gacha_guarantee_reward_receive_req = 6010,
    gacha_guarantee_reward_receive_succeed_ack = 6011,
    gacha_guarantee_reward_receive_failed_ack = 6012,
    gacha_newbie_spin_req = 6013,
    gacha_newbie_spin_succeed_ack = 6014,
    gacha_newbie_spin_failed_ack = 6015,
    gacha_newbie_save_req = 6016,
    gacha_newbie_save_succeed_ack = 6017,
    gacha_newbie_save_failed_ack = 6018,
    gacha_newbie_obtain_req = 6019,
    gacha_newbie_obtain_succeed_ack = 6020,
    gacha_newbie_obtain_failed_ack = 6021,
    gacha_newbie_info_req = 6022,
    gacha_newbie_info_succeed_ack = 6023,
    gacha_newbie_info_failed_ack = 6024,
    gacha_spin_sync_ack = 6025,
    gacha_reward_get_req = 6026,
    gacha_reward_get_succeed_ack = 6027,
    gacha_reward_get_failed_ack = 6028,
    tower_book_fate_card_detail_req = 6101,
    tower_book_fate_card_detail_succeed_ack = 6102,
    tower_book_fate_card_detail_failed_ack = 6103,
    tower_book_fate_card_reward_receive_req = 6104,
    tower_book_fate_card_reward_receive_succeed_ack = 6105,
    tower_book_fate_card_reward_receive_failed_ack = 6106,
    joint_drill_apply_req = 6201,
    joint_drill_apply_succeed_ack = 6202,
    joint_drill_apply_failed_ack = 6203,
    joint_drill_continue_req = 6204,
    joint_drill_continue_succeed_ack = 6205,
    joint_drill_continue_failed_ack = 6206,
    joint_drill_sync_req = 6207,
    joint_drill_sync_succeed_ack = 6208,
    joint_drill_sync_failed_ack = 6209,
    joint_drill_give_up_req = 6210,
    joint_drill_give_up_succeed_ack = 6211,
    joint_drill_give_up_failed_ack = 6212,
    joint_drill_retreat_req = 6213,
    joint_drill_retreat_succeed_ack = 6214,
    joint_drill_retreat_failed_ack = 6215,
    joint_drill_settle_req = 6216,
    joint_drill_settle_succeed_ack = 6217,
    joint_drill_settle_failed_ack = 6218,
    joint_drill_game_over_req = 6219,
    joint_drill_game_over_succeed_ack = 6220,
    joint_drill_game_over_failed_ack = 6221,
    joint_drill_sweep_req = 6222,
    joint_drill_sweep_succeed_ack = 6223,
    joint_drill_sweep_failed_ack = 6224,
    joint_drill_rank_req = 6225,
    joint_drill_rank_succeed_ack = 6226,
    joint_drill_rank_failed_ack = 6227,
    joint_drill_quest_reward_receive_req = 6228,
    joint_drill_quest_reward_receive_succeed_ack = 6229,
    joint_drill_quest_reward_receive_failed_ack = 6230,
    joint_drill_2_apply_req = 6301,
    joint_drill_2_apply_succeed_ack = 6302,
    joint_drill_2_apply_failed_ack = 6303,
    joint_drill_2_continue_req = 6304,
    joint_drill_2_continue_succeed_ack = 6305,
    joint_drill_2_continue_failed_ack = 6306,
    joint_drill_2_sync_req = 6307,
    joint_drill_2_sync_succeed_ack = 6308,
    joint_drill_2_sync_failed_ack = 6309,
    joint_drill_2_give_up_req = 6310,
    joint_drill_2_give_up_succeed_ack = 6311,
    joint_drill_2_give_up_failed_ack = 6312,
    joint_drill_2_retreat_req = 6313,
    joint_drill_2_retreat_succeed_ack = 6314,
    joint_drill_2_retreat_failed_ack = 6315,
    joint_drill_2_settle_req = 6316,
    joint_drill_2_settle_succeed_ack = 6317,
    joint_drill_2_settle_failed_ack = 6318,
    joint_drill_2_game_over_req = 6319,
    joint_drill_2_game_over_succeed_ack = 6320,
    joint_drill_2_game_over_failed_ack = 6321,
    plot_reward_receive_req = 7013,
    plot_reward_receive_succeed_ack = 7014,
    plot_reward_receive_failed_ack = 7015,
    daily_instance_apply_req = 7016,
    daily_instance_apply_succeed_ack = 7017,
    daily_instance_apply_failed_ack = 7018,
    daily_instance_settle_req = 7019,
    daily_instance_settle_succeed_ack = 7020,
    daily_instance_settle_failed_ack = 7021,
    daily_instance_raid_req = 7022,
    daily_instance_raid_succeed_ack = 7023,
    daily_instance_raid_failed_ack = 7024,
    char_gem_instance_apply_req = 7028,
    char_gem_instance_apply_succeed_ack = 7029,
    char_gem_instance_apply_failed_ack = 7030,
    char_gem_instance_settle_req = 7031,
    char_gem_instance_settle_succeed_ack = 7032,
    char_gem_instance_settle_failed_ack = 7033,
    char_gem_instance_sweep_req = 7034,
    char_gem_instance_sweep_succeed_ack = 7035,
    char_gem_instance_sweep_failed_ack = 7036,
    region_boss_level_apply_req = 7101,
    region_boss_level_apply_succeed_ack = 7102,
    region_boss_level_apply_failed_ack = 7103,
    region_boss_level_settle_req = 7104,
    region_boss_level_settle_succeed_ack = 7105,
    region_boss_level_settle_failed_ack = 7106,
    region_boss_level_sweep_req = 7107,
    region_boss_level_sweep_succeed_ack = 7108,
    region_boss_level_sweep_failed_ack = 7109,
    traveler_duel_level_apply_req = 7201,
    traveler_duel_level_apply_succeed_ack = 7202,
    traveler_duel_level_apply_failed_ack = 7203,
    traveler_duel_level_settle_req = 7204,
    traveler_duel_level_settle_succeed_ack = 7205,
    traveler_duel_level_settle_failed_ack = 7206,
    traveler_duel_info_req = 7207,
    traveler_duel_info_succeed_ack = 7208,
    traveler_duel_info_failed_ack = 7209,
    traveler_duel_quest_reward_receive_req = 7210,
    traveler_duel_quest_reward_receive_succeed_ack = 7211,
    traveler_duel_quest_reward_receive_failed_ack = 7212,
    traveler_duel_rank_req = 7213,
    traveler_duel_rank_succeed_ack = 7214,
    traveler_duel_rank_failed_ack = 7215,
    traveler_duel_rank_upload_req = 7216,
    traveler_duel_rank_upload_succeed_ack = 7217,
    traveler_duel_rank_upload_failed_ack = 7218,
    story_apply_req = 7301,
    story_apply_succeed_ack = 7302,
    story_apply_failed_ack = 7303,
    story_settle_req = 7304,
    story_settle_succeed_ack = 7305,
    story_settle_failed_ack = 7306,
    skill_instance_apply_req = 7401,
    skill_instance_apply_succeed_ack = 7402,
    skill_instance_apply_failed_ack = 7403,
    skill_instance_settle_req = 7404,
    skill_instance_settle_succeed_ack = 7405,
    skill_instance_settle_failed_ack = 7406,
    skill_instance_sweep_req = 7407,
    skill_instance_sweep_succeed_ack = 7408,
    skill_instance_sweep_failed_ack = 7409,
    week_boss_apply_req = 7410,
    week_boss_apply_succeed_ack = 7411,
    week_boss_apply_failed_ack = 7412,
    week_boss_settle_req = 7413,
    week_boss_settle_succeed_ack = 7414,
    week_boss_settle_failed_ack = 7415,
    tutorial_level_settle_req = 7501,
    tutorial_level_settle_succeed_ack = 7502,
    tutorial_level_settle_failed_ack = 7503,
    tutorial_level_reward_receive_req = 7504,
    tutorial_level_reward_receive_succeed_ack = 7505,
    tutorial_level_reward_receive_failed_ack = 7506,
    story_set_info_req = 7601,
    story_set_info_succeed_ack = 7602,
    story_set_info_failed_ack = 7603,
    story_set_reward_receive_req = 7604,
    story_set_reward_receive_succeed_ack = 7605,
    story_set_reward_receive_failed_ack = 7606,
    energy_buy_req = 8001,
    energy_buy_succeed_ack = 8002,
    energy_buy_failed_ack = 8003,
    energy_extract_req = 8004,
    energy_extract_succeed_ack = 8005,
    energy_extract_failed_ack = 8006,
    energy_info_req = 8007,
    energy_info_succeed_ack = 8008,
    energy_info_failed_ack = 8009,
    client_event_report_req = 8101,
    client_event_report_succeed_ack = 8102,
    client_event_report_failed_ack = 8103,
    vampire_survivor_apply_req = 8201,
    vampire_survivor_apply_succeed_ack = 8202,
    vampire_survivor_apply_failed_ack = 8203,
    vampire_survivor_area_change_req = 8204,
    vampire_survivor_area_change_succeed_ack = 8205,
    vampire_survivor_area_change_failed_ack = 8206,
    vampire_survivor_settle_req = 8207,
    vampire_survivor_settle_succeed_ack = 8208,
    vampire_survivor_settle_failed_ack = 8209,
    vampire_survivor_reward_select_req = 8210,
    vampire_survivor_reward_select_succeed_ack = 8211,
    vampire_survivor_reward_select_failed_ack = 8212,
    vampire_survivor_reward_chest_req = 8213,
    vampire_survivor_reward_chest_succeed_ack = 8214,
    vampire_survivor_reward_chest_failed_ack = 8215,
    vampire_survivor_quest_reward_receive_req = 8216,
    vampire_survivor_quest_reward_receive_succeed_ack = 8217,
    vampire_survivor_quest_reward_receive_failed_ack = 8218,
    vampire_survivor_extra_reward_select_req = 8222,
    vampire_survivor_extra_reward_select_succeed_ack = 8223,
    vampire_survivor_extra_reward_select_failed_ack = 8224,
    vampire_survivor_restart_req = 8225,
    vampire_survivor_restart_succeed_ack = 8226,
    vampire_survivor_restart_failed_ack = 8227,
    vampire_talent_detail_req = 8301,
    vampire_talent_detail_succeed_ack = 8302,
    vampire_talent_detail_failed_ack = 8303,
    vampire_talent_reset_req = 8304,
    vampire_talent_reset_succeed_ack = 8305,
    vampire_talent_reset_failed_ack = 8306,
    vampire_talent_unlock_req = 8307,
    vampire_talent_unlock_succeed_ack = 8308,
    vampire_talent_unlock_failed_ack = 8309,
    vampire_talent_show_req = 8310,
    vampire_talent_show_succeed_ack = 8311,
    vampire_talent_show_failed_ack = 8312,
    vampire_survivor_info_req = 8313,
    vampire_survivor_info_succeed_ack = 8314,
    vampire_survivor_info_failed_ack = 8315,
    activity_story_apply_req = 8316,
    activity_story_apply_succeed_ack = 8317,
    activity_story_apply_failed_ack = 8318,
    activity_story_settle_req = 8319,
    activity_story_settle_succeed_ack = 8320,
    activity_story_settle_failed_ack = 8321,
    activity_throw_gift_settle_req = 8322,
    activity_throw_gift_settle_succeed_ack = 8323,
    activity_throw_gift_settle_failed_ack = 8324,
    player_last_read_update_req = 8325,
    player_last_read_update_succeed_ack = 8326,
    player_last_read_update_failed_ack = 8327,
    activity_history_story_apply_req = 8328,
    activity_history_story_apply_succeed_ack = 8329,
    activity_history_story_apply_failed_ack = 8330,
    activity_history_story_settle_req = 8331,
    activity_history_story_settle_succeed_ack = 8332,
    activity_history_story_settle_failed_ack = 8333,
    activity_penguin_card_level_settle_req = 8401,
    activity_penguin_card_level_settle_succeed_ack = 8402,
    activity_penguin_card_level_settle_failed_ack = 8403,
    activity_penguin_card_quest_reward_receive_req = 8404,
    activity_penguin_card_quest_reward_receive_succeed_ack = 8405,
    activity_penguin_card_quest_reward_receive_failed_ack = 8406,
    activity_double_quest_reward_receive_req = 8407,
    activity_double_quest_reward_receive_succeed_ack = 8408,
    activity_double_quest_reward_receive_failed_ack = 8409,
    activity_ice_cream_level_settle_req = 8411,
    activity_ice_cream_level_settle_succeed_ack = 8412,
    activity_ice_cream_level_settle_failed_ack = 8413,
    activity_penguin_card_endless_level_save_req = 8416,
    activity_penguin_card_endless_level_save_succeed_ack = 8417,
    activity_penguin_card_endless_level_save_failed_ack = 8418,
    mail_list_req = 9001,
    mail_list_succeed_ack = 9002,
    mail_list_failed_ack = 9003,
    mail_read_req = 9004,
    mail_read_succeed_ack = 9005,
    mail_read_failed_ack = 9006,
    mail_recv_req = 9007,
    mail_recv_succeed_ack = 9008,
    mail_recv_failed_ack = 9009,
    mail_remove_req = 9010,
    mail_remove_succeed_ack = 9011,
    mail_remove_failed_ack = 9012,
    mail_pin_req = 9013,
    mail_pin_succeed_ack = 9014,
    mail_pin_failed_ack = 9015,
    activity_detail_req = 9101,
    activity_detail_succeed_ack = 9102,
    activity_detail_failed_ack = 9103,
    activity_periodic_reward_receive_req = 9104,
    activity_periodic_reward_receive_succeed_ack = 9105,
    activity_periodic_reward_receive_failed_ack = 9106,
    activity_periodic_final_reward_receive_req = 9107,
    activity_periodic_final_reward_receive_succeed_ack = 9108,
    activity_periodic_final_reward_receive_failed_ack = 9109,
    activity_login_reward_receive_req = 9110,
    activity_login_reward_receive_succeed_ack = 9111,
    activity_login_reward_receive_failed_ack = 9112,
    activity_tower_defense_story_reward_receive_req = 9113,
    activity_tower_defense_story_reward_receive_succeed_ack = 9114,
    activity_tower_defense_story_reward_receive_failed_ack = 9115,
    activity_tower_defense_quest_reward_receive_req = 9116,
    activity_tower_defense_quest_reward_receive_succeed_ack = 9117,
    activity_tower_defense_quest_reward_receive_failed_ack = 9118,
    activity_tower_defense_level_apply_req = 9119,
    activity_tower_defense_level_apply_succeed_ack = 9120,
    activity_tower_defense_level_apply_failed_ack = 9121,
    activity_tower_defense_level_settle_req = 9122,
    activity_tower_defense_level_settle_succeed_ack = 9123,
    activity_tower_defense_level_settle_failed_ack = 9124,
    activity_trekker_versus_apply_req = 9125,
    activity_trekker_versus_apply_succeed_ack = 9126,
    activity_trekker_versus_apply_failed_ack = 9127,
    activity_trekker_versus_settle_req = 9128,
    activity_trekker_versus_settle_succeed_ack = 9129,
    activity_trekker_versus_settle_failed_ack = 9130,
    activity_trekker_versus_reward_receive_req = 9131,
    activity_trekker_versus_reward_receive_succeed_ack = 9132,
    activity_trekker_versus_reward_receive_failed_ack = 9133,
    activity_trekker_versus_idle_refresh_req = 9134,
    activity_trekker_versus_idle_refresh_succeed_ack = 9135,
    activity_trekker_versus_idle_refresh_failed_ack = 9136,
    activity_trekker_versus_idle_reward_receive_req = 9137,
    activity_trekker_versus_idle_reward_receive_succeed_ack = 9138,
    activity_trekker_versus_idle_reward_receive_failed_ack = 9139,
    activity_trekker_versus_rank_boost_req = 9140,
    activity_trekker_versus_rank_boost_succeed_ack = 9141,
    activity_trekker_versus_rank_boost_failed_ack = 9142,
    activity_trekker_versus_schedule_reward_receive_req = 9143,
    activity_trekker_versus_schedule_reward_receive_succeed_ack = 9144,
    activity_trekker_versus_schedule_reward_receive_failed_ack = 9145,
    phone_contacts_info_req = 9201,
    phone_contacts_info_succeed_ack = 9202,
    phone_contacts_info_failed_ack = 9203,
    phone_contacts_report_req = 9204,
    phone_contacts_report_succeed_ack = 9205,
    phone_contacts_report_failed_ack = 9206,
    phone_contacts_top_req = 9207,
    phone_contacts_top_succeed_ack = 9208,
    phone_contacts_top_failed_ack = 9209,
    activity_share_reward_receive_req = 9210,
    activity_share_reward_receive_succeed_ack = 9211,
    activity_share_reward_receive_failed_ack = 9212,
    talent_unlock_req = 9301,
    talent_unlock_succeed_ack = 9302,
    talent_unlock_failed_ack = 9303,
    talent_reset_req = 9304,
    talent_reset_succeed_ack = 9305,
    talent_reset_failed_ack = 9306,
    talent_node_reset_req = 9307,
    talent_node_reset_succeed_ack = 9308,
    talent_node_reset_failed_ack = 9309,
    talent_background_set_req = 9310,
    talent_background_set_succeed_ack = 9311,
    talent_background_set_failed_ack = 9312,
    talent_group_unlock_req = 9313,
    talent_group_unlock_succeed_ack = 9314,
    talent_group_unlock_failed_ack = 9315,
    activity_trial_reward_receive_req = 9401,
    activity_trial_reward_receive_succeed_ack = 9402,
    activity_trial_reward_receive_failed_ack = 9403,
    activity_cg_read_req = 9501,
    activity_cg_read_succeed_ack = 9502,
    activity_cg_read_failed_ack = 9503,
    activity_levels_apply_req = 9601,
    activity_levels_apply_succeed_ack = 9602,
    activity_levels_apply_failed_ack = 9603,
    activity_levels_settle_req = 9604,
    activity_levels_settle_succeed_ack = 9605,
    activity_levels_settle_failed_ack = 9606,
    activity_levels_sweep_req = 9607,
    activity_levels_sweep_succeed_ack = 9608,
    activity_levels_sweep_failed_ack = 9609,
    activity_avg_reward_receive_req = 9701,
    activity_avg_reward_receive_succeed_ack = 9702,
    activity_avg_reward_receive_failed_ack = 9703,
    activity_shop_purchase_req = 9751,
    activity_shop_purchase_succeed_ack = 9752,
    activity_shop_purchase_failed_ack = 9753,
    battle_pass_info_req = 9801,
    battle_pass_info_succeed_ack = 9802,
    battle_pass_info_failed_ack = 9803,
    battle_pass_reward_receive_req = 9804,
    battle_pass_reward_receive_succeed_ack = 9805,
    battle_pass_reward_receive_failed_ack = 9806,
    battle_pass_level_buy_req = 9807,
    battle_pass_level_buy_succeed_ack = 9808,
    battle_pass_level_buy_failed_ack = 9809,
    battle_pass_order_req = 9810,
    battle_pass_order_succeed_ack = 9811,
    battle_pass_order_failed_ack = 9812,
    battle_pass_order_collect_req = 9813,
    battle_pass_order_collect_succeed_ack = 9814,
    battle_pass_order_collect_failed_ack = 9815,
    battle_pass_quest_reward_receive_req = 9816,
    battle_pass_quest_reward_receive_succeed_ack = 9817,
    battle_pass_quest_reward_receive_failed_ack = 9818,
    redeem_code_req = 9901,
    redeem_code_succeed_ack = 9902,
    redeem_code_failed_ack = 9903,
    system_failed_ack = 10000,
    player_new_notify = 10001,
    mail_state_notify = 10002,
    player_relogin_notify = 10003,
    token_expire_notify = 10004,
    player_ban_notify = 10005,
    quest_change_notify = 10006,
    week_boss_refresh_ticket_notify = 10007,
    agent_new_notify = 10008,
    world_class_change_notify = 10009,
    friend_energy_state_notify = 10010,
    signin_reward_change_notify = 10011,
    friend_state_notify = 10012,
    order_paid_notify = 10013,
    order_revoke_notify = 10014,
    star_tower_book_potential_notify = 10015,
    star_tower_book_event_notify = 10016,
    battle_pass_state_notify = 10017,
    world_class_reward_state_notify = 10018,
    char_advance_reward_state_notify = 10019,
    achievement_change_notify = 10020,
    achievement_state_notify = 10021,
    character_skin_gain_notify = 10022,
    character_skin_change_notify = 10023,
    handbook_change_notify = 10024,
    monthly_card_rewards_notify = 10025,
    quest_state_notify = 10026,
    mall_package_state_notify = 10027,
    dictionary_change_notify = 10028,
    activity_change_notify = 10029,
    activity_quest_change_notify = 10030,
    char_affinity_reward_state_notify = 10031,
    mail_overflow_notify = 10032,
    infinity_tower_rewards_state_notify = 10033,
    phone_chat_change_notify = 10034,
    character_fragments_overflow_change_notify = 10035,
    activity_login_rewards_notify = 10036,
    tower_book_fate_card_collect_notify = 10037,
    tower_book_fate_card_reward_notify = 10038,
    region_boss_level_challenge_ticket_notify = 10039,
    honor_change_notify = 10040,
    activity_mining_daily_reward_notify = 10041,
    activity_mining_supplement_reward_notify = 10042,
    activity_mining_energy_convert_notify = 10043,
    notice_change_notify = 10044,
    activity_state_change_notify = 10045,
    activity_joint_drill_refresh_ticket_notify = 10046,
    force_update_notify = 10047,
    player_head_icon_change_notify = 10048,
    activity_mining_enter_layer_notify = 10049,
    story_set_state_notify = 10050,
    vampire_survivor_new_season_notify = 10051,
    order_collected_notify = 10052,
    activity_end_item_change_notify = 10053,
    item_expired_change_notify = 10054,
    milkout_character_unlock_notify = 10055,
    activity_double_reward_times_notify = 10056,
    trace_hunt_new_control_notify = 10057,
    trace_hunt_state_notify = 10058,
    trace_hunt_item_change_notify = 10060,
    score_boss_reset_score_notify = 10061,
    activity_mining_apply_req = 11001,
    activity_mining_apply_succeed_ack = 11002,
    activity_mining_apply_failed_ack = 11003,
    activity_mining_dig_req = 11004,
    activity_mining_dig_succeed_ack = 11005,
    activity_mining_dig_failed_ack = 11006,
    activity_mining_move_to_next_layer_req = 11007,
    activity_mining_move_to_next_layer_succeed_ack = 11008,
    activity_mining_move_to_next_layer_failed_ack = 11009,
    activity_mining_story_reward_receive_req = 11010,
    activity_mining_story_reward_receive_succeed_ack = 11011,
    activity_mining_story_reward_receive_failed_ack = 11012,
    activity_mining_quest_reward_receive_req = 11013,
    activity_mining_quest_reward_receive_succeed_ack = 11014,
    activity_mining_quest_reward_receive_failed_ack = 11015,
    score_boss_apply_req = 11101,
    score_boss_apply_succeed_ack = 11102,
    score_boss_apply_failed_ack = 11103,
    score_boss_settle_req = 11104,
    score_boss_settle_succeed_ack = 11105,
    score_boss_settle_failed_ack = 11106,
    score_boss_rank_req = 11107,
    score_boss_rank_succeed_ack = 11108,
    score_boss_rank_failed_ack = 11109,
    score_boss_star_reward_receive_req = 11110,
    score_boss_star_reward_receive_succeed_ack = 11111,
    score_boss_star_reward_receive_failed_ack = 11112,
    score_boss_info_req = 11113,
    score_boss_info_succeed_ack = 11114,
    score_boss_info_failed_ack = 11115,
    activity_cookie_settle_req = 11201,
    activity_cookie_settle_succeed_ack = 11202,
    activity_cookie_settle_failed_ack = 11203,
    activity_cookie_quest_reward_receive_req = 11204,
    activity_cookie_quest_reward_receive_succeed_ack = 11205,
    activity_cookie_quest_reward_receive_failed_ack = 11206,
    _,
};

pub const MessageName = struct {
    id: PacketId,
    message_name: []const u8,
};

pub const message_names = [_]MessageName{
    .{
        .id = .clear_all_activity_iceCream_levels_notify,
        .message_name = "GmClearAllActivityIceCreamLevelsNotify",
    },
    .{
        .id = .sd_soldier_effect_notify,
        .message_name = "SoldierEffectNtf",
    },
    .{
        .id = .sd_soldier_info_notify,
        .message_name = "SoldierInfo",
    },
    .{
        .id = .sd_shop_data_notify,
        .message_name = "ShopCaseData",
    },
    .{
        .id = .sd_item_change_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .sd_buff_card_add_notify,
        .message_name = "SoldierCard",
    },
    .{
        .id = .clear_all_activity_golden_spy_levels_notify,
        .message_name = "ActivityGDS",
    },
    .{
        .id = .clear_all_activity_breakout_levels_notify,
        .message_name = "Milkout",
    },
    .{
        .id = .clear_story_set_notify,
        .message_name = "StorySetInfoResp",
    },
    .{
        .id = .unlock_activity_story_notify,
        .message_name = "ActivityStoryChapter",
    },
    .{
        .id = .assist_add_build_notify,
        .message_name = "AssistAddBuildNotify",
    },
    .{
        .id = .clear_all_activity_levels_notify,
        .message_name = "GmClearAllActivityLevelsNotify",
    },
    .{
        .id = .clear_all_activity_avg_notify,
        .message_name = "GmClearAllActivityAvgNotify",
    },
    .{
        .id = .vs_add_fate_card_notify,
        .message_name = "CardInfo",
    },
    .{
        .id = .char_gems_import_notify,
        .message_name = "GmImportCharGemsNotify",
    },
    .{
        .id = .char_gems_export_notify,
        .message_name = "String",
    },
    .{
        .id = .clear_all_char_gem_instance_notify,
        .message_name = "GmClearAllCharGemInstance",
    },
    .{
        .id = .change_npc_affinity_notify,
        .message_name = "NPCAffinityInfo",
    },
    .{
        .id = .tower_change_sub_note_skill_notify,
        .message_name = "TowerChangeData",
    },
    .{
        .id = .world_class_quest_complete_notify,
        .message_name = "Quests",
    },
    .{
        .id = .score_boss_level_reset_notify,
        .message_name = "ScoreBossInfo",
    },
    .{
        .id = .score_boss_star_reward_reset_notify,
        .message_name = "Nil",
    },
    .{
        .id = .char_up_change_notify,
        .message_name = "GmCharUpNotify",
    },
    .{
        .id = .tower_growth_node_change_notify,
        .message_name = "GmTowerGrowthNodesNotify",
    },
    .{
        .id = .st_harmony_skill_notify,
        .message_name = "GmHarmonySkillNotify",
    },
    .{
        .id = .clear_all_story_notify,
        .message_name = "GmStory",
    },
    .{
        .id = .story_complete_notify,
        .message_name = "GmStory",
    },
    .{
        .id = .infinity_tower_skip_floor_notify,
        .message_name = "InfinityTowerLevelInfo",
    },
    .{
        .id = .infinity_tower_all_infos_notify,
        .message_name = "GmAllInfinityTowerInfos",
    },
    .{
        .id = .clear_all_equipment_instance_notify,
        .message_name = "GmClearAllEquipmentInstance",
    },
    .{
        .id = .st_import_build_notify,
        .message_name = "StarTowerBuildInfo",
    },
    .{
        .id = .st_export_build_notify,
        .message_name = "String",
    },
    .{
        .id = .st_add_new_case_notify,
        .message_name = "StarTowerRoomCase",
    },
    .{
        .id = .st_add_team_exp_notify,
        .message_name = "STAddTeamExpNtf",
    },
    .{
        .id = .st_skip_floor_notify,
        .message_name = "StarTowerInfo",
    },
    .{
        .id = .st_clear_all_star_tower_notify,
        .message_name = "GmSTClearAllStarTower",
    },
    .{
        .id = .st_items_change_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_affinity_final_notify,
        .message_name = "CharAffinity",
    },
    .{
        .id = .clear_all_skill_instance_notify,
        .message_name = "GmClearAllSkillInstance",
    },
    .{
        .id = .disc_reset_notify,
        .message_name = "Disc",
    },
    .{
        .id = .clear_all_traveler_due_notify,
        .message_name = "GmClearAllTravelerDue",
    },
    .{
        .id = .clear_all_region_boss_level_notify,
        .message_name = "GmClearAllRegionBossLevel",
    },
    .{
        .id = .clear_all_week_boss_notify,
        .message_name = "WeekBossLevels",
    },
    .{
        .id = .clear_all_daily_instance_notify,
        .message_name = "GmClearAllDailyInstance",
    },
    .{
        .id = .refresh_agent_notify,
        .message_name = "AgentInfos",
    },
    .{
        .id = .star_tower_sub_note_skill_info_notify,
        .message_name = "StarTowerSubNoteSkillInfo",
    },
    .{
        .id = .vampire_survivor_talent_node_notify,
        .message_name = "VampireTalentDetailResp",
    },
    .{
        .id = .add_vampire_season_score_notify,
        .message_name = "UI32",
    },
    .{
        .id = .clear_all_vampire_survivor_notify,
        .message_name = "GmClearAllVampireSurvivor",
    },
    .{
        .id = .region_boss_level_final_notify,
        .message_name = "RegionBossLevel",
    },
    .{
        .id = .chars_final_notify,
        .message_name = "Chars",
    },
    .{
        .id = .world_class_number_notify,
        .message_name = "GmWorldClass",
    },
    .{
        .id = .char_change_notify,
        .message_name = "Char",
    },
    .{
        .id = .char_reset_notify,
        .message_name = "Char",
    },
    .{
        .id = .items_change_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .sudo_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .sudo_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .sudo_req,
        .message_name = "SudoCommand",
    },
    .{
        .id = .ike_req,
        .message_name = "IKEReq",
    },
    .{
        .id = .ike_succeed_ack,
        .message_name = "IKEResp",
    },
    .{
        .id = .ike_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_login_req,
        .message_name = "LoginReq",
    },
    .{
        .id = .player_login_succeed_ack,
        .message_name = "LoginResp",
    },
    .{
        .id = .player_login_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_data_req,
        .message_name = "Nil",
    },
    .{
        .id = .player_data_succeed_ack,
        .message_name = "PlayerInfo",
    },
    .{
        .id = .player_data_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_reg_req,
        .message_name = "PlayerReg",
    },
    .{
        .id = .player_reg_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_name_edit_req,
        .message_name = "PlayerNameEditReq",
    },
    .{
        .id = .player_name_edit_succeed_ack,
        .message_name = "PlayerNameEditResp",
    },
    .{
        .id = .player_name_edit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_head_icon_set_req,
        .message_name = "PlayerHeadIconSetReq",
    },
    .{
        .id = .player_head_icon_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_head_icon_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_ping_req,
        .message_name = "Ping",
    },
    .{
        .id = .player_ping_succeed_ack,
        .message_name = "Pong",
    },
    .{
        .id = .player_ping_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_learn_req,
        .message_name = "NewbieInfo",
    },
    .{
        .id = .player_learn_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_learn_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_destroy_req,
        .message_name = "Nil",
    },
    .{
        .id = .player_destroy_succeed_ack,
        .message_name = "PlayerDestroy",
    },
    .{
        .id = .player_destroy_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_board_set_req,
        .message_name = "PlayerBoardSetReq",
    },
    .{
        .id = .player_board_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_board_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_world_class_reward_receive_req,
        .message_name = "PlayerWorldClassRewardReq",
    },
    .{
        .id = .player_world_class_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .player_world_class_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_signature_edit_req,
        .message_name = "PlayerSignatureEditReq",
    },
    .{
        .id = .player_signature_edit_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_signature_edit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_title_edit_req,
        .message_name = "PlayerTitleEditReq",
    },
    .{
        .id = .player_title_edit_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_title_edit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_chars_show_req,
        .message_name = "PlayerCharsShowReq",
    },
    .{
        .id = .player_chars_show_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_chars_show_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_skin_show_req,
        .message_name = "PlayerSkinShowReq",
    },
    .{
        .id = .player_skin_show_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_skin_show_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_gender_edit_req,
        .message_name = "Nil",
    },
    .{
        .id = .player_gender_edit_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_gender_edit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_survey_req,
        .message_name = "PlayerSurveyReq",
    },
    .{
        .id = .player_survey_succeed_ack,
        .message_name = "PlayerSurveyResp",
    },
    .{
        .id = .player_survey_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_exit_req,
        .message_name = "Nil",
    },
    .{
        .id = .player_exit_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_exit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_honor_edit_req,
        .message_name = "PlayerHonorEditReq",
    },
    .{
        .id = .player_honor_edit_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_honor_edit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_world_class_advance_req,
        .message_name = "Nil",
    },
    .{
        .id = .player_world_class_advance_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .player_world_class_advance_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_music_set_req,
        .message_name = "I64",
    },
    .{
        .id = .player_music_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_music_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_head_icon_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .player_head_icon_info_succeed_ack,
        .message_name = "PlayerHeadIconInfoResp",
    },
    .{
        .id = .player_head_icon_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .item_use_req,
        .message_name = "ItemUseReq",
    },
    .{
        .id = .item_use_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .item_use_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gem_convert_req,
        .message_name = "UI32",
    },
    .{
        .id = .gem_convert_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .gem_convert_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .item_product_req,
        .message_name = "ItemProductReq",
    },
    .{
        .id = .item_product_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .item_product_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .fragments_convert_req,
        .message_name = "Nil",
    },
    .{
        .id = .fragments_convert_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .fragments_convert_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .daily_shop_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .daily_shop_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .daily_shop_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .item_quick_growth_req,
        .message_name = "ItemGrowthReq",
    },
    .{
        .id = .item_quick_growth_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .item_quick_growth_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .daily_mall_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .daily_mall_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .daily_mall_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_list_get_req,
        .message_name = "Nil",
    },
    .{
        .id = .friend_list_get_succeed_ack,
        .message_name = "FriendListGetResp",
    },
    .{
        .id = .friend_list_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_uid_search_req,
        .message_name = "FriendUIdSearchReq",
    },
    .{
        .id = .friend_uid_search_succeed_ack,
        .message_name = "FriendUIdSearchResp",
    },
    .{
        .id = .friend_uid_search_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_name_search_req,
        .message_name = "FriendNameSearchReq",
    },
    .{
        .id = .friend_name_search_succeed_ack,
        .message_name = "FriendNameSearchResp",
    },
    .{
        .id = .friend_name_search_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_add_req,
        .message_name = "FriendAddReq",
    },
    .{
        .id = .friend_add_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .friend_add_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_add_agree_req,
        .message_name = "FriendAddAgreeReq",
    },
    .{
        .id = .friend_add_agree_succeed_ack,
        .message_name = "FriendAddAgreeResp",
    },
    .{
        .id = .friend_add_agree_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_all_agree_req,
        .message_name = "Nil",
    },
    .{
        .id = .friend_all_agree_succeed_ack,
        .message_name = "FriendAllAgreeResp",
    },
    .{
        .id = .friend_all_agree_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_delete_req,
        .message_name = "FriendDeleteReq",
    },
    .{
        .id = .friend_delete_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .friend_delete_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_invites_delete_req,
        .message_name = "FriendInvitesDeleteReq",
    },
    .{
        .id = .friend_invites_delete_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .friend_invites_delete_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_star_set_req,
        .message_name = "FriendStarSetReq",
    },
    .{
        .id = .friend_star_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .friend_star_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_receive_energy_req,
        .message_name = "FriendReceiveEnergyReq",
    },
    .{
        .id = .friend_receive_energy_succeed_ack,
        .message_name = "FriendReceiveEnergyResp",
    },
    .{
        .id = .friend_receive_energy_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_send_energy_req,
        .message_name = "FriendSendEnergyReq",
    },
    .{
        .id = .friend_send_energy_succeed_ack,
        .message_name = "FriendSendEnergyResp",
    },
    .{
        .id = .friend_send_energy_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .friend_recommendation_get_req,
        .message_name = "Nil",
    },
    .{
        .id = .friend_recommendation_get_succeed_ack,
        .message_name = "FriendRecommendationGetResp",
    },
    .{
        .id = .friend_recommendation_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tower_growth_detail_req,
        .message_name = "Nil",
    },
    .{
        .id = .tower_growth_detail_succeed_ack,
        .message_name = "TowerGrowthDetailResp",
    },
    .{
        .id = .tower_growth_detail_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tower_growth_node_unlock_req,
        .message_name = "UI32",
    },
    .{
        .id = .tower_growth_node_unlock_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .tower_growth_node_unlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tower_growth_group_node_unlock_req,
        .message_name = "UI32",
    },
    .{
        .id = .tower_growth_group_node_unlock_succeed_ack,
        .message_name = "TowerGrowthGroupNodeUnlockResp",
    },
    .{
        .id = .tower_growth_group_node_unlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .milkout_settle_req,
        .message_name = "MilkoutSettleReq",
    },
    .{
        .id = .milkout_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .milkout_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_gds_settle_req,
        .message_name = "ActivityGDSSettleReq",
    },
    .{
        .id = .activity_gds_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_gds_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_soldier_quest_reward_receive_req,
        .message_name = "ActivitySoldierQuestRewardReceiveReq",
    },
    .{
        .id = .activity_soldier_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_soldier_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_formation_req,
        .message_name = "PlayerFormationReq",
    },
    .{
        .id = .player_formation_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_formation_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_upgrade_req,
        .message_name = "CharUpgradeReq",
    },
    .{
        .id = .char_upgrade_succeed_ack,
        .message_name = "CharUpgradeResp",
    },
    .{
        .id = .char_upgrade_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_advance_req,
        .message_name = "UI32",
    },
    .{
        .id = .char_advance_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_advance_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_skill_upgrade_req,
        .message_name = "CharSkillUpgradeReq",
    },
    .{
        .id = .char_skill_upgrade_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_skill_upgrade_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_advance_reward_receive_req,
        .message_name = "CharAdvanceRewardReceiveReq",
    },
    .{
        .id = .char_advance_reward_receive_succeed_ack,
        .message_name = "CharAdvanceRewardReceiveResp",
    },
    .{
        .id = .char_advance_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_skin_set_req,
        .message_name = "CharSkinSetReq",
    },
    .{
        .id = .char_skin_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_skin_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_affinity_quest_reward_receive_req,
        .message_name = "CharAffinityQuestRewardReceiveReq",
    },
    .{
        .id = .char_affinity_quest_reward_receive_succeed_ack,
        .message_name = "CharAffinityQuestRewardReceiveResp",
    },
    .{
        .id = .char_affinity_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_recruitment_req,
        .message_name = "UI32",
    },
    .{
        .id = .char_recruitment_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_recruitment_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_affinity_gift_send_req,
        .message_name = "CharAffinityGiftSendReq",
    },
    .{
        .id = .char_affinity_gift_send_succeed_ack,
        .message_name = "CharAffinityGiftSendResp",
    },
    .{
        .id = .char_affinity_gift_send_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_dating_landmark_select_req,
        .message_name = "CharDatingLandmarkSelectReq",
    },
    .{
        .id = .char_dating_landmark_select_succeed_ack,
        .message_name = "CharDatingLandmarkSelectResp",
    },
    .{
        .id = .char_dating_landmark_select_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_dating_gift_send_req,
        .message_name = "CharDatingGiftSendReq",
    },
    .{
        .id = .char_dating_gift_send_succeed_ack,
        .message_name = "CharDatingGiftSendResp",
    },
    .{
        .id = .char_dating_gift_send_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_dating_event_reward_receive_req,
        .message_name = "CharDatingEventRewardReceiveReq",
    },
    .{
        .id = .char_dating_event_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_dating_event_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_archive_reward_receive_req,
        .message_name = "CharArchiveRewardReceiveReq",
    },
    .{
        .id = .char_archive_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_archive_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_dating_branch_a_select_req,
        .message_name = "CharDatingBranchASelectReq",
    },
    .{
        .id = .char_dating_branch_a_select_succeed_ack,
        .message_name = "CharDatingBranchASelectResp",
    },
    .{
        .id = .char_dating_branch_a_select_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_dating_branch_b_select_req,
        .message_name = "CharDatingBranchBSelectReq",
    },
    .{
        .id = .char_dating_branch_b_select_succeed_ack,
        .message_name = "CharDatingBranchBSelectResp",
    },
    .{
        .id = .char_dating_branch_b_select_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_generate_req,
        .message_name = "CharGemGenerateReq",
    },
    .{
        .id = .char_gem_generate_succeed_ack,
        .message_name = "CharGemGenerateResp",
    },
    .{
        .id = .char_gem_generate_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_refresh_req,
        .message_name = "CharGemRefreshReq",
    },
    .{
        .id = .char_gem_refresh_succeed_ack,
        .message_name = "CharGemRefreshResp",
    },
    .{
        .id = .char_gem_refresh_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_replace_attribute_req,
        .message_name = "CharGemReplaceAttributeReq",
    },
    .{
        .id = .char_gem_replace_attribute_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_gem_replace_attribute_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_update_gem_lock_status_req,
        .message_name = "CharGemUpdateGemLockStatusReq",
    },
    .{
        .id = .char_gem_update_gem_lock_status_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_gem_update_gem_lock_status_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_use_preset_req,
        .message_name = "CharGemUsePresetReq",
    },
    .{
        .id = .char_gem_use_preset_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_gem_use_preset_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_rename_preset_req,
        .message_name = "CharGemRenamePresetReq",
    },
    .{
        .id = .char_gem_rename_preset_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_gem_rename_preset_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_equip_gem_req,
        .message_name = "CharGemEquipGemReq",
    },
    .{
        .id = .char_gem_equip_gem_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_gem_equip_gem_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_overlock_revert_req,
        .message_name = "CharGemOverlockRevertReq",
    },
    .{
        .id = .char_gem_overlock_revert_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_gem_overlock_revert_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_overlock_req,
        .message_name = "CharGemOverlockReq",
    },
    .{
        .id = .char_gem_overlock_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_gem_overlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_favorite_set_req,
        .message_name = "UI32",
    },
    .{
        .id = .char_favorite_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .char_favorite_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .disc_strengthen_req,
        .message_name = "DiscStrengthenReq",
    },
    .{
        .id = .disc_strengthen_succeed_ack,
        .message_name = "DiscStrengthenResp",
    },
    .{
        .id = .disc_strengthen_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .disc_promote_req,
        .message_name = "DiscPromoteReq",
    },
    .{
        .id = .disc_promote_succeed_ack,
        .message_name = "DiscPromoteResp",
    },
    .{
        .id = .disc_promote_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .disc_limit_break_req,
        .message_name = "DiscLimitBreakReq",
    },
    .{
        .id = .disc_limit_break_succeed_ack,
        .message_name = "DiscLimitBreakResp",
    },
    .{
        .id = .disc_limit_break_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .disc_read_reward_receive_req,
        .message_name = "DiscReadRewardReceiveReq",
    },
    .{
        .id = .disc_read_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .disc_read_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .disc_all_limit_break_req,
        .message_name = "Nil",
    },
    .{
        .id = .disc_all_limit_break_succeed_ack,
        .message_name = "DiscAllLimitBreakResp",
    },
    .{
        .id = .disc_all_limit_break_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .agent_apply_req,
        .message_name = "AgentApplyReq",
    },
    .{
        .id = .agent_apply_succeed_ack,
        .message_name = "AgentApplyResp",
    },
    .{
        .id = .agent_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .agent_give_up_req,
        .message_name = "AgentGiveUpReq",
    },
    .{
        .id = .agent_give_up_succeed_ack,
        .message_name = "AgentGiveUpResp",
    },
    .{
        .id = .agent_give_up_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .agent_reward_receive_req,
        .message_name = "AgentRewardReceiveReq",
    },
    .{
        .id = .agent_reward_receive_succeed_ack,
        .message_name = "AgentRewardReceiveResp",
    },
    .{
        .id = .agent_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_tour_guide_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .quest_tour_guide_reward_receive_succeed_ack,
        .message_name = "TourGuideQuestRewardResp",
    },
    .{
        .id = .quest_tour_guide_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_daily_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .quest_daily_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .quest_daily_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .dictionary_reward_receive_req,
        .message_name = "DictRewardReq",
    },
    .{
        .id = .dictionary_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .dictionary_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_tower_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .quest_tower_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .quest_tower_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_daily_active_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .quest_daily_active_reward_receive_succeed_ack,
        .message_name = "QuestDailyActiveRewardReceiveResp",
    },
    .{
        .id = .quest_daily_active_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_tour_guide_group_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .quest_tour_guide_group_reward_receive_succeed_ack,
        .message_name = "TourGuideQuestGroupRewardResp",
    },
    .{
        .id = .quest_tour_guide_group_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_weekly_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .quest_weekly_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .quest_weekly_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_weekly_active_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .quest_weekly_active_reward_receive_succeed_ack,
        .message_name = "QuestWeeklyActiveRewardReceiveResp",
    },
    .{
        .id = .quest_weekly_active_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_assist_reward_receive_req,
        .message_name = "AssistQuestReceiveReq",
    },
    .{
        .id = .quest_assist_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .quest_assist_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .quest_assist_group_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .quest_assist_group_reward_receive_succeed_ack,
        .message_name = "AssistGroupRewardResp",
    },
    .{
        .id = .quest_assist_group_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_task_reward_receive_req,
        .message_name = "ActivityTaskRewardReceiveReq",
    },
    .{
        .id = .activity_task_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_task_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_task_group_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_task_group_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_task_group_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .achievement_reward_receive_req,
        .message_name = "AchievementRewardReq",
    },
    .{
        .id = .achievement_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .achievement_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .achievement_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .achievement_info_succeed_ack,
        .message_name = "Achievements",
    },
    .{
        .id = .achievement_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .infinity_tower_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .infinity_tower_info_succeed_ack,
        .message_name = "InfinityTowerInfoResp",
    },
    .{
        .id = .infinity_tower_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .infinity_tower_apply_req,
        .message_name = "InfinityTowerApplyReq",
    },
    .{
        .id = .infinity_tower_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .infinity_tower_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .infinity_tower_settle_req,
        .message_name = "InfinityTowerSettleReq",
    },
    .{
        .id = .infinity_tower_settle_succeed_ack,
        .message_name = "InfinityTowerSettleResp",
    },
    .{
        .id = .infinity_tower_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .infinity_tower_daily_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .infinity_tower_daily_reward_receive_succeed_ack,
        .message_name = "InfinityTowerDailyRewardReceiveResp",
    },
    .{
        .id = .infinity_tower_daily_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .infinity_tower_plot_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .infinity_tower_plot_reward_receive_succeed_ack,
        .message_name = "InfinityTowerPlotRewardReceiveResp",
    },
    .{
        .id = .infinity_tower_plot_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_apply_req,
        .message_name = "StarTowerApplyReq",
    },
    .{
        .id = .star_tower_apply_succeed_ack,
        .message_name = "StarTowerApplyResp",
    },
    .{
        .id = .star_tower_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_interact_req,
        .message_name = "StarTowerInteractReq",
    },
    .{
        .id = .star_tower_interact_succeed_ack,
        .message_name = "StarTowerInteractResp",
    },
    .{
        .id = .star_tower_interact_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_info_succeed_ack,
        .message_name = "StarTowerInfo",
    },
    .{
        .id = .star_tower_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_give_up_req,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_give_up_succeed_ack,
        .message_name = "StarTowerGiveUpResp",
    },
    .{
        .id = .star_tower_give_up_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_whether_save_req,
        .message_name = "StarTowerBuildWhetherSaveReq",
    },
    .{
        .id = .star_tower_build_whether_save_succeed_ack,
        .message_name = "StarTowerBuildWhetherSaveResp",
    },
    .{
        .id = .star_tower_build_whether_save_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_brief_list_get_req,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_build_brief_list_get_succeed_ack,
        .message_name = "StarTowerBuildBriefListGetResp",
    },
    .{
        .id = .star_tower_build_brief_list_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_detail_get_req,
        .message_name = "StarTowerBuildDetailGetReq",
    },
    .{
        .id = .star_tower_build_detail_get_succeed_ack,
        .message_name = "StarTowerBuildDetailGetResp",
    },
    .{
        .id = .star_tower_build_detail_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_delete_req,
        .message_name = "StarTowerBuildDeleteReq",
    },
    .{
        .id = .star_tower_build_delete_succeed_ack,
        .message_name = "StarTowerBuildDeleteResp",
    },
    .{
        .id = .star_tower_build_delete_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_name_set_req,
        .message_name = "StarTowerBuildNameSetReq",
    },
    .{
        .id = .star_tower_build_name_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_build_name_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_lock_unlock_req,
        .message_name = "StarTowerBuildLockUnlockReq",
    },
    .{
        .id = .star_tower_build_lock_unlock_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_build_lock_unlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_build_preference_set_req,
        .message_name = "StarTowerBuildPreferenceSetReq",
    },
    .{
        .id = .star_tower_build_preference_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_build_preference_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .potential_preselection_list_req,
        .message_name = "Nil",
    },
    .{
        .id = .potential_preselection_list_succeed_ack,
        .message_name = "PotentialPreselectionList",
    },
    .{
        .id = .potential_preselection_list_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .potential_preselection_import_req,
        .message_name = "PotentialPreselectionImportReq",
    },
    .{
        .id = .potential_preselection_import_succeed_ack,
        .message_name = "PotentialPreselection",
    },
    .{
        .id = .potential_preselection_import_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .potential_preselection_name_set_req,
        .message_name = "PotentialPreselectionNameSetReq",
    },
    .{
        .id = .potential_preselection_name_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .potential_preselection_name_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .potential_preselection_preference_set_req,
        .message_name = "PotentialPreselectionPreferenceSetReq",
    },
    .{
        .id = .potential_preselection_preference_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .potential_preselection_preference_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .potential_preselection_update_req,
        .message_name = "PotentialPreselectionUpdateReq",
    },
    .{
        .id = .potential_preselection_update_succeed_ack,
        .message_name = "PotentialPreselection",
    },
    .{
        .id = .potential_preselection_update_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .potential_preselection_delete_req,
        .message_name = "PotentialPreselectionDeleteReq",
    },
    .{
        .id = .potential_preselection_delete_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .potential_preselection_delete_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .build_convert_detail_list_get_req,
        .message_name = "Nil",
    },
    .{
        .id = .build_convert_detail_list_get_succeed_ack,
        .message_name = "BuildConvertDetailListGetResp",
    },
    .{
        .id = .build_convert_detail_list_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .build_convert_submit_req,
        .message_name = "BuildConvertSubmitReq",
    },
    .{
        .id = .build_convert_submit_succeed_ack,
        .message_name = "BuildConvertSubmitResp",
    },
    .{
        .id = .build_convert_submit_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .build_convert_group_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .build_convert_group_reward_receive_succeed_ack,
        .message_name = "BuildConvertGroupRewardReceiveResp",
    },
    .{
        .id = .build_convert_group_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_book_potential_brief_list_get_req,
        .message_name = "Nil",
    },
    .{
        .id = .star_tower_book_potential_brief_list_get_succeed_ack,
        .message_name = "StarTowerBookPotentialBriefListResp",
    },
    .{
        .id = .star_tower_book_potential_brief_list_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_book_char_potential_get_req,
        .message_name = "UI32",
    },
    .{
        .id = .star_tower_book_char_potential_get_succeed_ack,
        .message_name = "StarTowerBookPotentialGetResp",
    },
    .{
        .id = .star_tower_book_char_potential_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_book_potential_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .star_tower_book_potential_reward_receive_succeed_ack,
        .message_name = "StarTowerBookPotentialRewardReceiveResp",
    },
    .{
        .id = .star_tower_book_potential_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .star_tower_book_event_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .star_tower_book_event_reward_receive_succeed_ack,
        .message_name = "StarTowerBookEventRewardReceiveResp",
    },
    .{
        .id = .star_tower_book_event_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .npc_affinity_book_get_req,
        .message_name = "Nil",
    },
    .{
        .id = .npc_affinity_book_get_succeed_ack,
        .message_name = "NPCAffinityBookGetResp",
    },
    .{
        .id = .npc_affinity_book_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .npc_affinity_plot_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .npc_affinity_plot_reward_receive_succeed_ack,
        .message_name = "NPCAffinityPlotRewardReceiveResp",
    },
    .{
        .id = .npc_affinity_plot_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .resident_shop_get_req,
        .message_name = "ResidentShopGetReq",
    },
    .{
        .id = .resident_shop_get_succeed_ack,
        .message_name = "ResidentShopGetResp",
    },
    .{
        .id = .resident_shop_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .resident_shop_purchase_req,
        .message_name = "ResidentShopPurchaseReq",
    },
    .{
        .id = .resident_shop_purchase_succeed_ack,
        .message_name = "ResidentShopPurchaseResp",
    },
    .{
        .id = .resident_shop_purchase_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_gem_list_req,
        .message_name = "Nil",
    },
    .{
        .id = .mall_gem_list_succeed_ack,
        .message_name = "MallGemList",
    },
    .{
        .id = .mall_gem_list_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_gem_order_req,
        .message_name = "String",
    },
    .{
        .id = .mall_gem_order_succeed_ack,
        .message_name = "OrderInfo",
    },
    .{
        .id = .mall_gem_order_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_order_cancel_req,
        .message_name = "String",
    },
    .{
        .id = .mall_order_cancel_succeed_ack,
        .message_name = "String",
    },
    .{
        .id = .mall_order_cancel_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_order_collect_req,
        .message_name = "String",
    },
    .{
        .id = .mall_order_collect_succeed_ack,
        .message_name = "CollectResp",
    },
    .{
        .id = .mall_order_collect_failed_ack,
        .message_name = "CollectResp",
    },
    .{
        .id = .mall_monthlyCard_list_req,
        .message_name = "Nil",
    },
    .{
        .id = .mall_monthlyCard_list_succeed_ack,
        .message_name = "MallMonthlyCardList",
    },
    .{
        .id = .mall_monthlyCard_list_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_monthlyCard_order_req,
        .message_name = "String",
    },
    .{
        .id = .mall_monthlyCard_order_succeed_ack,
        .message_name = "OrderInfo",
    },
    .{
        .id = .mall_monthlyCard_order_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_package_list_req,
        .message_name = "Nil",
    },
    .{
        .id = .mall_package_list_succeed_ack,
        .message_name = "MallPackageList",
    },
    .{
        .id = .mall_package_list_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_package_order_req,
        .message_name = "String",
    },
    .{
        .id = .mall_package_order_succeed_ack,
        .message_name = "MallPackageOrder",
    },
    .{
        .id = .mall_package_order_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_shop_list_req,
        .message_name = "Nil",
    },
    .{
        .id = .mall_shop_list_succeed_ack,
        .message_name = "MallShopProductList",
    },
    .{
        .id = .mall_shop_list_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mall_shop_order_req,
        .message_name = "MallShopOrderReq",
    },
    .{
        .id = .mall_shop_order_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .mall_shop_order_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .trace_hunt_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .trace_hunt_info_succeed_ack,
        .message_name = "TraceHuntInfo",
    },
    .{
        .id = .trace_hunt_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .trace_hunt_apply_req,
        .message_name = "TraceHuntApplyReq",
    },
    .{
        .id = .trace_hunt_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .trace_hunt_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .trace_hunt_settle_req,
        .message_name = "TraceHuntSettleReq",
    },
    .{
        .id = .trace_hunt_settle_succeed_ack,
        .message_name = "TraceHuntSettleResp",
    },
    .{
        .id = .trace_hunt_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .trace_hunt_recommend_req,
        .message_name = "Nil",
    },
    .{
        .id = .trace_hunt_recommend_succeed_ack,
        .message_name = "TraceHuntRecommendResp",
    },
    .{
        .id = .trace_hunt_recommend_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .trace_hunt_boss_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .trace_hunt_boss_reward_receive_succeed_ack,
        .message_name = "TraceHuntBossRewardReceiveResp",
    },
    .{
        .id = .trace_hunt_boss_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .trace_hunt_trace_req,
        .message_name = "I32",
    },
    .{
        .id = .trace_hunt_trace_succeed_ack,
        .message_name = "TraceHuntTraceResp",
    },
    .{
        .id = .trace_hunt_trace_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .soldier_apply_req,
        .message_name = "SoldierApplyReq",
    },
    .{
        .id = .soldier_apply_succeed_ack,
        .message_name = "SoldierApplyResp",
    },
    .{
        .id = .soldier_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .soldier_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .soldier_info_succeed_ack,
        .message_name = "SoldierInfo",
    },
    .{
        .id = .soldier_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .soldier_interact_req,
        .message_name = "SoldierInteractReq",
    },
    .{
        .id = .soldier_interact_succeed_ack,
        .message_name = "SoldierInteractResp",
    },
    .{
        .id = .soldier_interact_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .soldier_give_up_req,
        .message_name = "Nil",
    },
    .{
        .id = .soldier_give_up_succeed_ack,
        .message_name = "SoldierGiveUpResp",
    },
    .{
        .id = .soldier_give_up_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .soldier_step_out_req,
        .message_name = "SoldierStepOutReq",
    },
    .{
        .id = .soldier_step_out_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .soldier_step_out_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .soldier_partner_trace_req,
        .message_name = "SoldierPartnerTraceReq",
    },
    .{
        .id = .soldier_partner_trace_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .soldier_partner_trace_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_spin_req,
        .message_name = "GachaSpinReq",
    },
    .{
        .id = .gacha_spin_succeed_ack,
        .message_name = "GachaSpinResp",
    },
    .{
        .id = .gacha_spin_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_information_req,
        .message_name = "Nil",
    },
    .{
        .id = .gacha_information_succeed_ack,
        .message_name = "GachaInformationResp",
    },
    .{
        .id = .gacha_information_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_histories_req,
        .message_name = "UI32",
    },
    .{
        .id = .gacha_histories_succeed_ack,
        .message_name = "GachaHistories",
    },
    .{
        .id = .gacha_histories_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_guarantee_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .gacha_guarantee_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .gacha_guarantee_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_newbie_spin_req,
        .message_name = "UI32",
    },
    .{
        .id = .gacha_newbie_spin_succeed_ack,
        .message_name = "GachaNewbieSpinResp",
    },
    .{
        .id = .gacha_newbie_spin_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_newbie_save_req,
        .message_name = "GachaNewbieSaveReq",
    },
    .{
        .id = .gacha_newbie_save_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .gacha_newbie_save_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_newbie_obtain_req,
        .message_name = "GachaNewbieObtainReq",
    },
    .{
        .id = .gacha_newbie_obtain_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .gacha_newbie_obtain_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_newbie_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .gacha_newbie_info_succeed_ack,
        .message_name = "GachaNewbieInfoResp",
    },
    .{
        .id = .gacha_newbie_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .gacha_spin_sync_ack,
        .message_name = "GachaSpinSyncResp",
    },
    .{
        .id = .gacha_reward_get_req,
        .message_name = "UI32",
    },
    .{
        .id = .gacha_reward_get_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .gacha_reward_get_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tower_book_fate_card_detail_req,
        .message_name = "Nil",
    },
    .{
        .id = .tower_book_fate_card_detail_succeed_ack,
        .message_name = "TowerBookFateCardDetailResp",
    },
    .{
        .id = .tower_book_fate_card_detail_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tower_book_fate_card_reward_receive_req,
        .message_name = "TowerBookFateCardRewardReq",
    },
    .{
        .id = .tower_book_fate_card_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .tower_book_fate_card_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_apply_req,
        .message_name = "JointDrillApplyReq",
    },
    .{
        .id = .joint_drill_apply_succeed_ack,
        .message_name = "JointDrillApplyResp",
    },
    .{
        .id = .joint_drill_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_continue_req,
        .message_name = "JointDrillContinueReq",
    },
    .{
        .id = .joint_drill_continue_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_continue_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_sync_req,
        .message_name = "JointDrillSyncReq",
    },
    .{
        .id = .joint_drill_sync_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_sync_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_give_up_req,
        .message_name = "JointDrillGiveUpReq",
    },
    .{
        .id = .joint_drill_give_up_succeed_ack,
        .message_name = "JointDrillSettle",
    },
    .{
        .id = .joint_drill_give_up_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_retreat_req,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_retreat_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_retreat_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_settle_req,
        .message_name = "JointDrillSettleReq",
    },
    .{
        .id = .joint_drill_settle_succeed_ack,
        .message_name = "JointDrillSettle",
    },
    .{
        .id = .joint_drill_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_game_over_req,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_game_over_succeed_ack,
        .message_name = "JointDrillSettle",
    },
    .{
        .id = .joint_drill_game_over_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_sweep_req,
        .message_name = "JointDrillSweepReq",
    },
    .{
        .id = .joint_drill_sweep_succeed_ack,
        .message_name = "JointDrillSweepResp",
    },
    .{
        .id = .joint_drill_sweep_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_rank_req,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_rank_succeed_ack,
        .message_name = "JointDrillRankInfo",
    },
    .{
        .id = .joint_drill_rank_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_quest_reward_receive_req,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .joint_drill_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_apply_req,
        .message_name = "JointDrill2ApplyReq",
    },
    .{
        .id = .joint_drill_2_apply_succeed_ack,
        .message_name = "JointDrill2ApplyResp",
    },
    .{
        .id = .joint_drill_2_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_continue_req,
        .message_name = "JointDrill2ContinueReq",
    },
    .{
        .id = .joint_drill_2_continue_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_2_continue_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_sync_req,
        .message_name = "JointDrill2SyncReq",
    },
    .{
        .id = .joint_drill_2_sync_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_2_sync_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_give_up_req,
        .message_name = "JointDrill2GiveUpReq",
    },
    .{
        .id = .joint_drill_2_give_up_succeed_ack,
        .message_name = "JointDrillSettle",
    },
    .{
        .id = .joint_drill_2_give_up_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_retreat_req,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_2_retreat_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_2_retreat_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_settle_req,
        .message_name = "JointDrill2SettleReq",
    },
    .{
        .id = .joint_drill_2_settle_succeed_ack,
        .message_name = "JointDrillSettle",
    },
    .{
        .id = .joint_drill_2_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .joint_drill_2_game_over_req,
        .message_name = "Nil",
    },
    .{
        .id = .joint_drill_2_game_over_succeed_ack,
        .message_name = "JointDrillSettle",
    },
    .{
        .id = .joint_drill_2_game_over_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .plot_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .plot_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .plot_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .daily_instance_apply_req,
        .message_name = "DailyInstanceApplyReq",
    },
    .{
        .id = .daily_instance_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .daily_instance_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .daily_instance_settle_req,
        .message_name = "DailyInstanceSettleReq",
    },
    .{
        .id = .daily_instance_settle_succeed_ack,
        .message_name = "DailyInstanceSettleResp",
    },
    .{
        .id = .daily_instance_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .daily_instance_raid_req,
        .message_name = "DailyInstanceRaidReq",
    },
    .{
        .id = .daily_instance_raid_succeed_ack,
        .message_name = "DailyInstanceRaidResp",
    },
    .{
        .id = .daily_instance_raid_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_instance_apply_req,
        .message_name = "CharGemInstanceApplyReq",
    },
    .{
        .id = .char_gem_instance_apply_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .char_gem_instance_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_instance_settle_req,
        .message_name = "CharGemInstanceSettleReq",
    },
    .{
        .id = .char_gem_instance_settle_succeed_ack,
        .message_name = "CharGemInstanceSettleResp",
    },
    .{
        .id = .char_gem_instance_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .char_gem_instance_sweep_req,
        .message_name = "CharGemInstanceSweepReq",
    },
    .{
        .id = .char_gem_instance_sweep_succeed_ack,
        .message_name = "CharGemInstanceSweepResp",
    },
    .{
        .id = .char_gem_instance_sweep_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .region_boss_level_apply_req,
        .message_name = "RegionBossLevelApplyReq",
    },
    .{
        .id = .region_boss_level_apply_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .region_boss_level_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .region_boss_level_settle_req,
        .message_name = "RegionBossLevelSettleReq",
    },
    .{
        .id = .region_boss_level_settle_succeed_ack,
        .message_name = "RegionBossLevelSettleResp",
    },
    .{
        .id = .region_boss_level_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .region_boss_level_sweep_req,
        .message_name = "RegionBossLevelSweepReq",
    },
    .{
        .id = .region_boss_level_sweep_succeed_ack,
        .message_name = "RegionBossLevelSweepResp",
    },
    .{
        .id = .region_boss_level_sweep_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .traveler_duel_level_apply_req,
        .message_name = "TravelerDuelLevelApplyReq",
    },
    .{
        .id = .traveler_duel_level_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .traveler_duel_level_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .traveler_duel_level_settle_req,
        .message_name = "TravelerDuelLevelSettleReq",
    },
    .{
        .id = .traveler_duel_level_settle_succeed_ack,
        .message_name = "TravelerDuelLevelSettleResp",
    },
    .{
        .id = .traveler_duel_level_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .traveler_duel_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .traveler_duel_info_succeed_ack,
        .message_name = "TravelerDuelInfo",
    },
    .{
        .id = .traveler_duel_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .traveler_duel_quest_reward_receive_req,
        .message_name = "TravelerDuelQuestRewardReceiveReq",
    },
    .{
        .id = .traveler_duel_quest_reward_receive_succeed_ack,
        .message_name = "TravelerDuelQuestRewardReceiveResp",
    },
    .{
        .id = .traveler_duel_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .traveler_duel_rank_req,
        .message_name = "Nil",
    },
    .{
        .id = .traveler_duel_rank_succeed_ack,
        .message_name = "TravelerDuelRankInfo",
    },
    .{
        .id = .traveler_duel_rank_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .traveler_duel_rank_upload_req,
        .message_name = "TravelerDuelBattleSamples",
    },
    .{
        .id = .traveler_duel_rank_upload_succeed_ack,
        .message_name = "RankChange",
    },
    .{
        .id = .traveler_duel_rank_upload_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .story_apply_req,
        .message_name = "StoryApplyReq",
    },
    .{
        .id = .story_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .story_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .story_settle_req,
        .message_name = "StorySettleReq",
    },
    .{
        .id = .story_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .story_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .skill_instance_apply_req,
        .message_name = "SkillInstanceApplyReq",
    },
    .{
        .id = .skill_instance_apply_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .skill_instance_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .skill_instance_settle_req,
        .message_name = "SkillInstanceSettleReq",
    },
    .{
        .id = .skill_instance_settle_succeed_ack,
        .message_name = "SkillInstanceSettleResp",
    },
    .{
        .id = .skill_instance_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .skill_instance_sweep_req,
        .message_name = "SkillInstanceSweepReq",
    },
    .{
        .id = .skill_instance_sweep_succeed_ack,
        .message_name = "SkillInstanceSweepResp",
    },
    .{
        .id = .skill_instance_sweep_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .week_boss_apply_req,
        .message_name = "WeekBossApplyReq",
    },
    .{
        .id = .week_boss_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .week_boss_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .week_boss_settle_req,
        .message_name = "WeekBossSettleReq",
    },
    .{
        .id = .week_boss_settle_succeed_ack,
        .message_name = "WeekBossLevelSettleResp",
    },
    .{
        .id = .week_boss_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tutorial_level_settle_req,
        .message_name = "UI32",
    },
    .{
        .id = .tutorial_level_settle_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .tutorial_level_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .tutorial_level_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .tutorial_level_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .tutorial_level_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .story_set_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .story_set_info_succeed_ack,
        .message_name = "StorySetInfoResp",
    },
    .{
        .id = .story_set_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .story_set_reward_receive_req,
        .message_name = "StorySetRewardReceiveReq",
    },
    .{
        .id = .story_set_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .story_set_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .energy_buy_req,
        .message_name = "UI32",
    },
    .{
        .id = .energy_buy_succeed_ack,
        .message_name = "EnergyBuyResp",
    },
    .{
        .id = .energy_buy_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .energy_extract_req,
        .message_name = "UI32",
    },
    .{
        .id = .energy_extract_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .energy_extract_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .energy_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .energy_info_succeed_ack,
        .message_name = "Energy",
    },
    .{
        .id = .energy_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .client_event_report_req,
        .message_name = "Events",
    },
    .{
        .id = .client_event_report_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .client_event_report_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_apply_req,
        .message_name = "VampireSurvivorApplyReq",
    },
    .{
        .id = .vampire_survivor_apply_succeed_ack,
        .message_name = "VampireSurvivorApplyResp",
    },
    .{
        .id = .vampire_survivor_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_area_change_req,
        .message_name = "VampireSurvivorAreaChangeReq",
    },
    .{
        .id = .vampire_survivor_area_change_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_survivor_area_change_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_settle_req,
        .message_name = "VampireSurvivorSettleReq",
    },
    .{
        .id = .vampire_survivor_settle_succeed_ack,
        .message_name = "VampireSurvivorSettleResp",
    },
    .{
        .id = .vampire_survivor_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_reward_select_req,
        .message_name = "VampireSurvivorRewardSelectReq",
    },
    .{
        .id = .vampire_survivor_reward_select_succeed_ack,
        .message_name = "VampireSurvivorRewardSelectResp",
    },
    .{
        .id = .vampire_survivor_reward_select_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_reward_chest_req,
        .message_name = "VampireSurvivorRewardChestReq",
    },
    .{
        .id = .vampire_survivor_reward_chest_succeed_ack,
        .message_name = "VampireSurvivorRewardChestResp",
    },
    .{
        .id = .vampire_survivor_reward_chest_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_quest_reward_receive_req,
        .message_name = "VampireSurvivorQuestRewardReceiveReq",
    },
    .{
        .id = .vampire_survivor_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .vampire_survivor_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_extra_reward_select_req,
        .message_name = "VampireSurvivorRewardSelectReq",
    },
    .{
        .id = .vampire_survivor_extra_reward_select_succeed_ack,
        .message_name = "VampireSurvivorRewardSelectResp",
    },
    .{
        .id = .vampire_survivor_extra_reward_select_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_restart_req,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_survivor_restart_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_survivor_restart_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_talent_detail_req,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_talent_detail_succeed_ack,
        .message_name = "VampireTalentDetailResp",
    },
    .{
        .id = .vampire_talent_detail_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_talent_reset_req,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_talent_reset_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_talent_reset_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_talent_unlock_req,
        .message_name = "UI32",
    },
    .{
        .id = .vampire_talent_unlock_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_talent_unlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_talent_show_req,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_talent_show_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_talent_show_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .vampire_survivor_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .vampire_survivor_info_succeed_ack,
        .message_name = "VampireSurvivorInfoResp",
    },
    .{
        .id = .vampire_survivor_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_story_apply_req,
        .message_name = "ActivityStoryApplyReq",
    },
    .{
        .id = .activity_story_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .activity_story_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_story_settle_req,
        .message_name = "ActivityStorySettleReq",
    },
    .{
        .id = .activity_story_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_story_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_throw_gift_settle_req,
        .message_name = "ActivityThrowGiftSettleReq",
    },
    .{
        .id = .activity_throw_gift_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_throw_gift_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_last_read_update_req,
        .message_name = "LastRead",
    },
    .{
        .id = .player_last_read_update_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .player_last_read_update_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_history_story_apply_req,
        .message_name = "ActivityHistoryStoryApplyReq",
    },
    .{
        .id = .activity_history_story_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .activity_history_story_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_history_story_settle_req,
        .message_name = "ActivityHistoryStorySettleReq",
    },
    .{
        .id = .activity_history_story_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_history_story_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_penguin_card_level_settle_req,
        .message_name = "ActivityPenguinCardSettleReq",
    },
    .{
        .id = .activity_penguin_card_level_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_penguin_card_level_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_penguin_card_quest_reward_receive_req,
        .message_name = "ActivityPenguinCardQuestReceiveReq",
    },
    .{
        .id = .activity_penguin_card_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_penguin_card_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_double_quest_reward_receive_req,
        .message_name = "ActivityDoubleQuestRewardReq",
    },
    .{
        .id = .activity_double_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_double_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_ice_cream_level_settle_req,
        .message_name = "ActivityIceCreamLevelSettleReq",
    },
    .{
        .id = .activity_ice_cream_level_settle_succeed_ack,
        .message_name = "ActivityIceCreamLevelSettleSucceed",
    },
    .{
        .id = .activity_ice_cream_level_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_penguin_card_endless_level_save_req,
        .message_name = "ActivityPenguinCardEndlessLevelSaveReq",
    },
    .{
        .id = .activity_penguin_card_endless_level_save_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .activity_penguin_card_endless_level_save_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mail_list_req,
        .message_name = "Nil",
    },
    .{
        .id = .mail_list_succeed_ack,
        .message_name = "Mails",
    },
    .{
        .id = .mail_list_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mail_read_req,
        .message_name = "MailRequest",
    },
    .{
        .id = .mail_read_succeed_ack,
        .message_name = "UI32",
    },
    .{
        .id = .mail_read_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mail_recv_req,
        .message_name = "MailRequest",
    },
    .{
        .id = .mail_recv_succeed_ack,
        .message_name = "MailRecvResp",
    },
    .{
        .id = .mail_recv_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mail_remove_req,
        .message_name = "MailRequest",
    },
    .{
        .id = .mail_remove_succeed_ack,
        .message_name = "MailRemoveResp",
    },
    .{
        .id = .mail_remove_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .mail_pin_req,
        .message_name = "MailPinRequest",
    },
    .{
        .id = .mail_pin_succeed_ack,
        .message_name = "MailPinRequest",
    },
    .{
        .id = .mail_pin_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_detail_req,
        .message_name = "Nil",
    },
    .{
        .id = .activity_detail_succeed_ack,
        .message_name = "ActivityResp",
    },
    .{
        .id = .activity_detail_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_periodic_reward_receive_req,
        .message_name = "ActivityPeriodicRewardReq",
    },
    .{
        .id = .activity_periodic_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_periodic_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_periodic_final_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_periodic_final_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_periodic_final_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_login_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_login_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_login_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_tower_defense_story_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_tower_defense_story_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_tower_defense_story_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_tower_defense_quest_reward_receive_req,
        .message_name = "ActivityTowerDefenseQuestReceiveReq",
    },
    .{
        .id = .activity_tower_defense_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_tower_defense_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_tower_defense_level_apply_req,
        .message_name = "ActivityTowerDefenseLevelApplyReq",
    },
    .{
        .id = .activity_tower_defense_level_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .activity_tower_defense_level_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_tower_defense_level_settle_req,
        .message_name = "ActivityTowerDefenseLevelSettleReq",
    },
    .{
        .id = .activity_tower_defense_level_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_tower_defense_level_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_apply_req,
        .message_name = "ActivityTrekkerVersusApplyReq",
    },
    .{
        .id = .activity_trekker_versus_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .activity_trekker_versus_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_settle_req,
        .message_name = "ActivityTrekkerVersusSettleReq",
    },
    .{
        .id = .activity_trekker_versus_settle_succeed_ack,
        .message_name = "ActivityTrekkerVersusSettleResp",
    },
    .{
        .id = .activity_trekker_versus_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_trekker_versus_reward_receive_succeed_ack,
        .message_name = "ActivityTrekkerVersusRewardReceiveResp",
    },
    .{
        .id = .activity_trekker_versus_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_idle_refresh_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_trekker_versus_idle_refresh_succeed_ack,
        .message_name = "TrekkerVersusShow",
    },
    .{
        .id = .activity_trekker_versus_idle_refresh_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_idle_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_trekker_versus_idle_reward_receive_succeed_ack,
        .message_name = "ActivityTrekkerVersusIdleRewardReceiveResp",
    },
    .{
        .id = .activity_trekker_versus_idle_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_rank_boost_req,
        .message_name = "ActivityTrekkerVersusRankBoostReq",
    },
    .{
        .id = .activity_trekker_versus_rank_boost_succeed_ack,
        .message_name = "ActivityTrekkerVersusRankBoostResp",
    },
    .{
        .id = .activity_trekker_versus_rank_boost_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trekker_versus_schedule_reward_receive_req,
        .message_name = "ActivityTrekkerVersusScheduleRewardReceiveReq",
    },
    .{
        .id = .activity_trekker_versus_schedule_reward_receive_succeed_ack,
        .message_name = "ActivityTrekkerVersusScheduleRewardReceiveResp",
    },
    .{
        .id = .activity_trekker_versus_schedule_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .phone_contacts_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .phone_contacts_info_succeed_ack,
        .message_name = "PhoneContactsInfoResp",
    },
    .{
        .id = .phone_contacts_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .phone_contacts_report_req,
        .message_name = "PhoneContactsReportReq",
    },
    .{
        .id = .phone_contacts_report_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .phone_contacts_report_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .phone_contacts_top_req,
        .message_name = "UI32",
    },
    .{
        .id = .phone_contacts_top_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .phone_contacts_top_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_share_reward_receive_req,
        .message_name = "ActivityShareRewardReq",
    },
    .{
        .id = .activity_share_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_share_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .talent_unlock_req,
        .message_name = "UI32",
    },
    .{
        .id = .talent_unlock_succeed_ack,
        .message_name = "TalentUnlockResp",
    },
    .{
        .id = .talent_unlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .talent_reset_req,
        .message_name = "TalentResetReq",
    },
    .{
        .id = .talent_reset_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .talent_reset_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .talent_node_reset_req,
        .message_name = "UI32",
    },
    .{
        .id = .talent_node_reset_succeed_ack,
        .message_name = "TalentNodeResetResp",
    },
    .{
        .id = .talent_node_reset_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .talent_background_set_req,
        .message_name = "TalentBackgroundSetReq",
    },
    .{
        .id = .talent_background_set_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .talent_background_set_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .talent_group_unlock_req,
        .message_name = "UI32",
    },
    .{
        .id = .talent_group_unlock_succeed_ack,
        .message_name = "TalentGroupUnlockResp",
    },
    .{
        .id = .talent_group_unlock_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_trial_reward_receive_req,
        .message_name = "ActivityTrialRewardReceiveReq",
    },
    .{
        .id = .activity_trial_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_trial_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_cg_read_req,
        .message_name = "UI32",
    },
    .{
        .id = .activity_cg_read_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_cg_read_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_levels_apply_req,
        .message_name = "ActivityLevelsApplyReq",
    },
    .{
        .id = .activity_levels_apply_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_levels_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_levels_settle_req,
        .message_name = "ActivityLevelsSettleReq",
    },
    .{
        .id = .activity_levels_settle_succeed_ack,
        .message_name = "ActivityLevelsSettleResp",
    },
    .{
        .id = .activity_levels_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_levels_sweep_req,
        .message_name = "ActivityLevelsSweepReq",
    },
    .{
        .id = .activity_levels_sweep_succeed_ack,
        .message_name = "ActivityLevelsSweepResp",
    },
    .{
        .id = .activity_levels_sweep_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_avg_reward_receive_req,
        .message_name = "ActivityAvgRewardReceiveReq",
    },
    .{
        .id = .activity_avg_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_avg_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_shop_purchase_req,
        .message_name = "ActivityShopPurchaseReq",
    },
    .{
        .id = .activity_shop_purchase_succeed_ack,
        .message_name = "ActivityShopPurchaseResp",
    },
    .{
        .id = .activity_shop_purchase_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .battle_pass_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .battle_pass_info_succeed_ack,
        .message_name = "BattlePassInfo",
    },
    .{
        .id = .battle_pass_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .battle_pass_reward_receive_req,
        .message_name = "BattlePassRewardReceiveReq",
    },
    .{
        .id = .battle_pass_reward_receive_succeed_ack,
        .message_name = "BattlePassRewardReceiveResp",
    },
    .{
        .id = .battle_pass_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .battle_pass_level_buy_req,
        .message_name = "UI32V",
    },
    .{
        .id = .battle_pass_level_buy_succeed_ack,
        .message_name = "BattlePassLevelBuyResp",
    },
    .{
        .id = .battle_pass_level_buy_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .battle_pass_order_req,
        .message_name = "BattlePassOrderReq",
    },
    .{
        .id = .battle_pass_order_succeed_ack,
        .message_name = "OrderInfo",
    },
    .{
        .id = .battle_pass_order_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .battle_pass_order_collect_req,
        .message_name = "String",
    },
    .{
        .id = .battle_pass_order_collect_succeed_ack,
        .message_name = "BattlePassOrderCollectResp",
    },
    .{
        .id = .battle_pass_order_collect_failed_ack,
        .message_name = "CollectResp",
    },
    .{
        .id = .battle_pass_quest_reward_receive_req,
        .message_name = "UI32",
    },
    .{
        .id = .battle_pass_quest_reward_receive_succeed_ack,
        .message_name = "BattlePassQuestRewardResp",
    },
    .{
        .id = .battle_pass_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .redeem_code_req,
        .message_name = "String",
    },
    .{
        .id = .redeem_code_succeed_ack,
        .message_name = "RedeemCodeResp",
    },
    .{
        .id = .redeem_code_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .system_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .player_new_notify,
        .message_name = "Nil",
    },
    .{
        .id = .mail_state_notify,
        .message_name = "MailState",
    },
    .{
        .id = .player_relogin_notify,
        .message_name = "Error",
    },
    .{
        .id = .token_expire_notify,
        .message_name = "Error",
    },
    .{
        .id = .player_ban_notify,
        .message_name = "Error",
    },
    .{
        .id = .quest_change_notify,
        .message_name = "Quest",
    },
    .{
        .id = .week_boss_refresh_ticket_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .agent_new_notify,
        .message_name = "NewAgent",
    },
    .{
        .id = .world_class_change_notify,
        .message_name = "WorldClassUpdate",
    },
    .{
        .id = .friend_energy_state_notify,
        .message_name = "FriendEnergyState",
    },
    .{
        .id = .signin_reward_change_notify,
        .message_name = "SigninRewardUpdate",
    },
    .{
        .id = .friend_state_notify,
        .message_name = "FriendState",
    },
    .{
        .id = .order_paid_notify,
        .message_name = "OrderStateChange",
    },
    .{
        .id = .order_revoke_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .star_tower_book_potential_notify,
        .message_name = "StarTowerBookPotentialChange",
    },
    .{
        .id = .star_tower_book_event_notify,
        .message_name = "StarTowerBookEventChange",
    },
    .{
        .id = .battle_pass_state_notify,
        .message_name = "BattlePassState",
    },
    .{
        .id = .world_class_reward_state_notify,
        .message_name = "WorldClassRewardState",
    },
    .{
        .id = .char_advance_reward_state_notify,
        .message_name = "CharAdvanceRewardState",
    },
    .{
        .id = .achievement_change_notify,
        .message_name = "Achievement",
    },
    .{
        .id = .achievement_state_notify,
        .message_name = "AchievementState",
    },
    .{
        .id = .character_skin_gain_notify,
        .message_name = "Skin",
    },
    .{
        .id = .character_skin_change_notify,
        .message_name = "SkinChange",
    },
    .{
        .id = .handbook_change_notify,
        .message_name = "HandbookInfo",
    },
    .{
        .id = .monthly_card_rewards_notify,
        .message_name = "MonthlyCardRewards",
    },
    .{
        .id = .quest_state_notify,
        .message_name = "QuestState",
    },
    .{
        .id = .mall_package_state_notify,
        .message_name = "MallPackageState",
    },
    .{
        .id = .dictionary_change_notify,
        .message_name = "Dictionary",
    },
    .{
        .id = .activity_change_notify,
        .message_name = "Activity",
    },
    .{
        .id = .activity_quest_change_notify,
        .message_name = "ActivityQuest",
    },
    .{
        .id = .char_affinity_reward_state_notify,
        .message_name = "CharAffinityRewardState",
    },
    .{
        .id = .mail_overflow_notify,
        .message_name = "Nil",
    },
    .{
        .id = .infinity_tower_rewards_state_notify,
        .message_name = "UI32",
    },
    .{
        .id = .phone_chat_change_notify,
        .message_name = "UI32",
    },
    .{
        .id = .character_fragments_overflow_change_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_login_rewards_notify,
        .message_name = "ActivityLogin",
    },
    .{
        .id = .tower_book_fate_card_collect_notify,
        .message_name = "TowerBookFateCardCollectNotify",
    },
    .{
        .id = .tower_book_fate_card_reward_notify,
        .message_name = "TowerBookFateCardRewardChangeNotify",
    },
    .{
        .id = .region_boss_level_challenge_ticket_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .honor_change_notify,
        .message_name = "HonorChangeNotify",
    },
    .{
        .id = .activity_mining_daily_reward_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_mining_supplement_reward_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_mining_energy_convert_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .notice_change_notify,
        .message_name = "NoticeChangeNotify",
    },
    .{
        .id = .activity_state_change_notify,
        .message_name = "ActivityState",
    },
    .{
        .id = .activity_joint_drill_refresh_ticket_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .force_update_notify,
        .message_name = "UI64",
    },
    .{
        .id = .player_head_icon_change_notify,
        .message_name = "PlayerHeadIconChangeNotify",
    },
    .{
        .id = .activity_mining_enter_layer_notify,
        .message_name = "ActivityMiningEnterLayerNotify",
    },
    .{
        .id = .story_set_state_notify,
        .message_name = "UI32",
    },
    .{
        .id = .vampire_survivor_new_season_notify,
        .message_name = "UI32",
    },
    .{
        .id = .order_collected_notify,
        .message_name = "OrderCollected",
    },
    .{
        .id = .activity_end_item_change_notify,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .item_expired_change_notify,
        .message_name = "ItemTpl",
    },
    .{
        .id = .milkout_character_unlock_notify,
        .message_name = "MilkoutCharacterUnlockNotify",
    },
    .{
        .id = .activity_double_reward_times_notify,
        .message_name = "ActivityDoubleRewardTimesNotify",
    },
    .{
        .id = .trace_hunt_new_control_notify,
        .message_name = "Nil",
    },
    .{
        .id = .trace_hunt_state_notify,
        .message_name = "TraceHuntState",
    },
    .{
        .id = .trace_hunt_item_change_notify,
        .message_name = "TraceHuntItem",
    },
    .{
        .id = .score_boss_reset_score_notify,
        .message_name = "Nil",
    },
    .{
        .id = .activity_mining_apply_req,
        .message_name = "ActivityMiningApplyReq",
    },
    .{
        .id = .activity_mining_apply_succeed_ack,
        .message_name = "ActivityMiningApplyResp",
    },
    .{
        .id = .activity_mining_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_mining_dig_req,
        .message_name = "ActivityMiningDigReq",
    },
    .{
        .id = .activity_mining_dig_succeed_ack,
        .message_name = "ActivityMiningDigResp",
    },
    .{
        .id = .activity_mining_dig_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_mining_move_to_next_layer_req,
        .message_name = "ActivityMiningMoveToNextLayerReq",
    },
    .{
        .id = .activity_mining_move_to_next_layer_succeed_ack,
        .message_name = "ActivityMiningMoveToNextLayerResp",
    },
    .{
        .id = .activity_mining_move_to_next_layer_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_mining_story_reward_receive_req,
        .message_name = "ActivityMiningStoryRewardReceiveReq",
    },
    .{
        .id = .activity_mining_story_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_mining_story_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_mining_quest_reward_receive_req,
        .message_name = "ActivityMiningQuestRewardReceiveReq",
    },
    .{
        .id = .activity_mining_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_mining_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .score_boss_apply_req,
        .message_name = "ScoreBossApplyReq",
    },
    .{
        .id = .score_boss_apply_succeed_ack,
        .message_name = "Nil",
    },
    .{
        .id = .score_boss_apply_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .score_boss_settle_req,
        .message_name = "ScoreBossSettleReq",
    },
    .{
        .id = .score_boss_settle_succeed_ack,
        .message_name = "ScoreBossSettleResp",
    },
    .{
        .id = .score_boss_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .score_boss_rank_req,
        .message_name = "Nil",
    },
    .{
        .id = .score_boss_rank_succeed_ack,
        .message_name = "ScoreBossRankInfo",
    },
    .{
        .id = .score_boss_rank_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .score_boss_star_reward_receive_req,
        .message_name = "ScoreBossStarRewardReceiveReq",
    },
    .{
        .id = .score_boss_star_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .score_boss_star_reward_receive_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .score_boss_info_req,
        .message_name = "Nil",
    },
    .{
        .id = .score_boss_info_succeed_ack,
        .message_name = "ScoreBossInfo",
    },
    .{
        .id = .score_boss_info_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_cookie_settle_req,
        .message_name = "ActivityCookieSettleReq",
    },
    .{
        .id = .activity_cookie_settle_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_cookie_settle_failed_ack,
        .message_name = "Error",
    },
    .{
        .id = .activity_cookie_quest_reward_receive_req,
        .message_name = "ActivityCookieQuestRewardReceiveReq",
    },
    .{
        .id = .activity_cookie_quest_reward_receive_succeed_ack,
        .message_name = "ChangeInfo",
    },
    .{
        .id = .activity_cookie_quest_reward_receive_failed_ack,
        .message_name = "Error",
    },
};

pub const ResponseIds = struct {
    success: PacketId,
    failure: PacketId,
};

const RequestResponses = struct {
    request: PacketId,
    responses: ResponseIds,
};

const request_responses = [_]RequestResponses{
    .{
        .request = .ike_req,
        .responses = .{
            .success = .ike_succeed_ack,
            .failure = .ike_failed_ack,
        },
    },
    .{
        .request = .player_login_req,
        .responses = .{
            .success = .player_login_succeed_ack,
            .failure = .player_login_failed_ack,
        },
    },
    .{
        .request = .player_data_req,
        .responses = .{
            .success = .player_data_succeed_ack,
            .failure = .player_data_failed_ack,
        },
    },
    .{
        .request = .player_reg_req,
        .responses = .{
            .success = .player_data_succeed_ack,
            .failure = .player_reg_failed_ack,
        },
    },
    .{
        .request = .player_name_edit_req,
        .responses = .{
            .success = .player_name_edit_succeed_ack,
            .failure = .player_name_edit_failed_ack,
        },
    },
    .{
        .request = .player_head_icon_set_req,
        .responses = .{
            .success = .player_head_icon_set_succeed_ack,
            .failure = .player_head_icon_set_failed_ack,
        },
    },
    .{
        .request = .player_ping_req,
        .responses = .{
            .success = .player_ping_succeed_ack,
            .failure = .player_ping_failed_ack,
        },
    },
    .{
        .request = .player_learn_req,
        .responses = .{
            .success = .player_learn_succeed_ack,
            .failure = .player_learn_failed_ack,
        },
    },
    .{
        .request = .player_destroy_req,
        .responses = .{
            .success = .player_destroy_succeed_ack,
            .failure = .player_destroy_failed_ack,
        },
    },
    .{
        .request = .player_board_set_req,
        .responses = .{
            .success = .player_board_set_succeed_ack,
            .failure = .player_board_set_failed_ack,
        },
    },
    .{
        .request = .player_world_class_reward_receive_req,
        .responses = .{
            .success = .player_world_class_reward_receive_succeed_ack,
            .failure = .player_world_class_reward_receive_failed_ack,
        },
    },
    .{
        .request = .player_signature_edit_req,
        .responses = .{
            .success = .player_signature_edit_succeed_ack,
            .failure = .player_signature_edit_failed_ack,
        },
    },
    .{
        .request = .player_title_edit_req,
        .responses = .{
            .success = .player_title_edit_succeed_ack,
            .failure = .player_title_edit_failed_ack,
        },
    },
    .{
        .request = .player_chars_show_req,
        .responses = .{
            .success = .player_chars_show_succeed_ack,
            .failure = .player_chars_show_failed_ack,
        },
    },
    .{
        .request = .player_skin_show_req,
        .responses = .{
            .success = .player_skin_show_succeed_ack,
            .failure = .player_skin_show_failed_ack,
        },
    },
    .{
        .request = .player_gender_edit_req,
        .responses = .{
            .success = .player_gender_edit_succeed_ack,
            .failure = .player_gender_edit_failed_ack,
        },
    },
    .{
        .request = .player_survey_req,
        .responses = .{
            .success = .player_survey_succeed_ack,
            .failure = .player_survey_failed_ack,
        },
    },
    .{
        .request = .player_exit_req,
        .responses = .{
            .success = .player_exit_succeed_ack,
            .failure = .player_exit_failed_ack,
        },
    },
    .{
        .request = .player_honor_edit_req,
        .responses = .{
            .success = .player_honor_edit_succeed_ack,
            .failure = .player_honor_edit_failed_ack,
        },
    },
    .{
        .request = .player_world_class_advance_req,
        .responses = .{
            .success = .player_world_class_advance_succeed_ack,
            .failure = .player_world_class_advance_failed_ack,
        },
    },
    .{
        .request = .player_music_set_req,
        .responses = .{
            .success = .player_music_set_succeed_ack,
            .failure = .player_music_set_failed_ack,
        },
    },
    .{
        .request = .player_head_icon_info_req,
        .responses = .{
            .success = .player_head_icon_info_succeed_ack,
            .failure = .player_head_icon_info_failed_ack,
        },
    },
    .{
        .request = .item_use_req,
        .responses = .{
            .success = .item_use_succeed_ack,
            .failure = .item_use_failed_ack,
        },
    },
    .{
        .request = .gem_convert_req,
        .responses = .{
            .success = .gem_convert_succeed_ack,
            .failure = .gem_convert_failed_ack,
        },
    },
    .{
        .request = .item_product_req,
        .responses = .{
            .success = .item_product_succeed_ack,
            .failure = .item_product_failed_ack,
        },
    },
    .{
        .request = .fragments_convert_req,
        .responses = .{
            .success = .fragments_convert_succeed_ack,
            .failure = .fragments_convert_failed_ack,
        },
    },
    .{
        .request = .daily_shop_reward_receive_req,
        .responses = .{
            .success = .daily_shop_reward_receive_succeed_ack,
            .failure = .daily_shop_reward_receive_failed_ack,
        },
    },
    .{
        .request = .item_quick_growth_req,
        .responses = .{
            .success = .item_quick_growth_succeed_ack,
            .failure = .item_quick_growth_failed_ack,
        },
    },
    .{
        .request = .daily_mall_reward_receive_req,
        .responses = .{
            .success = .daily_mall_reward_receive_succeed_ack,
            .failure = .daily_mall_reward_receive_failed_ack,
        },
    },
    .{
        .request = .friend_list_get_req,
        .responses = .{
            .success = .friend_list_get_succeed_ack,
            .failure = .friend_list_get_failed_ack,
        },
    },
    .{
        .request = .friend_uid_search_req,
        .responses = .{
            .success = .friend_uid_search_succeed_ack,
            .failure = .friend_uid_search_failed_ack,
        },
    },
    .{
        .request = .friend_name_search_req,
        .responses = .{
            .success = .friend_name_search_succeed_ack,
            .failure = .friend_name_search_failed_ack,
        },
    },
    .{
        .request = .friend_add_req,
        .responses = .{
            .success = .friend_add_succeed_ack,
            .failure = .friend_add_failed_ack,
        },
    },
    .{
        .request = .friend_add_agree_req,
        .responses = .{
            .success = .friend_add_agree_succeed_ack,
            .failure = .friend_add_agree_failed_ack,
        },
    },
    .{
        .request = .friend_all_agree_req,
        .responses = .{
            .success = .friend_all_agree_succeed_ack,
            .failure = .friend_all_agree_failed_ack,
        },
    },
    .{
        .request = .friend_delete_req,
        .responses = .{
            .success = .friend_delete_succeed_ack,
            .failure = .friend_delete_failed_ack,
        },
    },
    .{
        .request = .friend_invites_delete_req,
        .responses = .{
            .success = .friend_invites_delete_succeed_ack,
            .failure = .friend_invites_delete_failed_ack,
        },
    },
    .{
        .request = .friend_star_set_req,
        .responses = .{
            .success = .friend_star_set_succeed_ack,
            .failure = .friend_star_set_failed_ack,
        },
    },
    .{
        .request = .friend_receive_energy_req,
        .responses = .{
            .success = .friend_receive_energy_succeed_ack,
            .failure = .friend_receive_energy_failed_ack,
        },
    },
    .{
        .request = .friend_send_energy_req,
        .responses = .{
            .success = .friend_send_energy_succeed_ack,
            .failure = .friend_send_energy_failed_ack,
        },
    },
    .{
        .request = .friend_recommendation_get_req,
        .responses = .{
            .success = .friend_recommendation_get_succeed_ack,
            .failure = .friend_recommendation_get_failed_ack,
        },
    },
    .{
        .request = .tower_growth_detail_req,
        .responses = .{
            .success = .tower_growth_detail_succeed_ack,
            .failure = .tower_growth_detail_failed_ack,
        },
    },
    .{
        .request = .tower_growth_node_unlock_req,
        .responses = .{
            .success = .tower_growth_node_unlock_succeed_ack,
            .failure = .tower_growth_node_unlock_failed_ack,
        },
    },
    .{
        .request = .tower_growth_group_node_unlock_req,
        .responses = .{
            .success = .tower_growth_group_node_unlock_succeed_ack,
            .failure = .tower_growth_group_node_unlock_failed_ack,
        },
    },
    .{
        .request = .milkout_settle_req,
        .responses = .{
            .success = .milkout_settle_succeed_ack,
            .failure = .milkout_settle_failed_ack,
        },
    },
    .{
        .request = .activity_gds_settle_req,
        .responses = .{
            .success = .activity_gds_settle_succeed_ack,
            .failure = .activity_gds_settle_failed_ack,
        },
    },
    .{
        .request = .activity_soldier_quest_reward_receive_req,
        .responses = .{
            .success = .activity_soldier_quest_reward_receive_succeed_ack,
            .failure = .activity_soldier_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .player_formation_req,
        .responses = .{
            .success = .player_formation_succeed_ack,
            .failure = .player_formation_failed_ack,
        },
    },
    .{
        .request = .char_upgrade_req,
        .responses = .{
            .success = .char_upgrade_succeed_ack,
            .failure = .char_upgrade_failed_ack,
        },
    },
    .{
        .request = .char_advance_req,
        .responses = .{
            .success = .char_advance_succeed_ack,
            .failure = .char_advance_failed_ack,
        },
    },
    .{
        .request = .char_skill_upgrade_req,
        .responses = .{
            .success = .char_skill_upgrade_succeed_ack,
            .failure = .char_skill_upgrade_failed_ack,
        },
    },
    .{
        .request = .char_advance_reward_receive_req,
        .responses = .{
            .success = .char_advance_reward_receive_succeed_ack,
            .failure = .char_advance_reward_receive_failed_ack,
        },
    },
    .{
        .request = .char_skin_set_req,
        .responses = .{
            .success = .char_skin_set_succeed_ack,
            .failure = .char_skin_set_failed_ack,
        },
    },
    .{
        .request = .char_affinity_quest_reward_receive_req,
        .responses = .{
            .success = .char_affinity_quest_reward_receive_succeed_ack,
            .failure = .char_affinity_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .char_recruitment_req,
        .responses = .{
            .success = .char_recruitment_succeed_ack,
            .failure = .char_recruitment_failed_ack,
        },
    },
    .{
        .request = .char_affinity_gift_send_req,
        .responses = .{
            .success = .char_affinity_gift_send_succeed_ack,
            .failure = .char_affinity_gift_send_failed_ack,
        },
    },
    .{
        .request = .char_dating_landmark_select_req,
        .responses = .{
            .success = .char_dating_landmark_select_succeed_ack,
            .failure = .char_dating_landmark_select_failed_ack,
        },
    },
    .{
        .request = .char_dating_gift_send_req,
        .responses = .{
            .success = .char_dating_gift_send_succeed_ack,
            .failure = .char_dating_gift_send_failed_ack,
        },
    },
    .{
        .request = .char_dating_event_reward_receive_req,
        .responses = .{
            .success = .char_dating_event_reward_receive_succeed_ack,
            .failure = .char_dating_event_reward_receive_failed_ack,
        },
    },
    .{
        .request = .char_archive_reward_receive_req,
        .responses = .{
            .success = .char_archive_reward_receive_succeed_ack,
            .failure = .char_archive_reward_receive_failed_ack,
        },
    },
    .{
        .request = .char_dating_branch_a_select_req,
        .responses = .{
            .success = .char_dating_branch_a_select_succeed_ack,
            .failure = .char_dating_branch_a_select_failed_ack,
        },
    },
    .{
        .request = .char_dating_branch_b_select_req,
        .responses = .{
            .success = .char_dating_branch_b_select_succeed_ack,
            .failure = .char_dating_branch_b_select_failed_ack,
        },
    },
    .{
        .request = .char_gem_generate_req,
        .responses = .{
            .success = .char_gem_generate_succeed_ack,
            .failure = .char_gem_generate_failed_ack,
        },
    },
    .{
        .request = .char_gem_refresh_req,
        .responses = .{
            .success = .char_gem_refresh_succeed_ack,
            .failure = .char_gem_refresh_failed_ack,
        },
    },
    .{
        .request = .char_gem_replace_attribute_req,
        .responses = .{
            .success = .char_gem_replace_attribute_succeed_ack,
            .failure = .char_gem_replace_attribute_failed_ack,
        },
    },
    .{
        .request = .char_gem_update_gem_lock_status_req,
        .responses = .{
            .success = .char_gem_update_gem_lock_status_succeed_ack,
            .failure = .char_gem_update_gem_lock_status_failed_ack,
        },
    },
    .{
        .request = .char_gem_use_preset_req,
        .responses = .{
            .success = .char_gem_use_preset_succeed_ack,
            .failure = .char_gem_use_preset_failed_ack,
        },
    },
    .{
        .request = .char_gem_rename_preset_req,
        .responses = .{
            .success = .char_gem_rename_preset_succeed_ack,
            .failure = .char_gem_rename_preset_failed_ack,
        },
    },
    .{
        .request = .char_gem_equip_gem_req,
        .responses = .{
            .success = .char_gem_equip_gem_succeed_ack,
            .failure = .char_gem_equip_gem_failed_ack,
        },
    },
    .{
        .request = .char_gem_overlock_revert_req,
        .responses = .{
            .success = .char_gem_overlock_revert_succeed_ack,
            .failure = .char_gem_overlock_revert_failed_ack,
        },
    },
    .{
        .request = .char_gem_overlock_req,
        .responses = .{
            .success = .char_gem_overlock_succeed_ack,
            .failure = .char_gem_overlock_failed_ack,
        },
    },
    .{
        .request = .char_favorite_set_req,
        .responses = .{
            .success = .char_favorite_set_succeed_ack,
            .failure = .char_favorite_set_failed_ack,
        },
    },
    .{
        .request = .disc_strengthen_req,
        .responses = .{
            .success = .disc_strengthen_succeed_ack,
            .failure = .disc_strengthen_failed_ack,
        },
    },
    .{
        .request = .disc_promote_req,
        .responses = .{
            .success = .disc_promote_succeed_ack,
            .failure = .disc_promote_failed_ack,
        },
    },
    .{
        .request = .disc_limit_break_req,
        .responses = .{
            .success = .disc_limit_break_succeed_ack,
            .failure = .disc_limit_break_failed_ack,
        },
    },
    .{
        .request = .disc_read_reward_receive_req,
        .responses = .{
            .success = .disc_read_reward_receive_succeed_ack,
            .failure = .disc_read_reward_receive_failed_ack,
        },
    },
    .{
        .request = .disc_all_limit_break_req,
        .responses = .{
            .success = .disc_all_limit_break_succeed_ack,
            .failure = .disc_all_limit_break_failed_ack,
        },
    },
    .{
        .request = .agent_apply_req,
        .responses = .{
            .success = .agent_apply_succeed_ack,
            .failure = .agent_apply_failed_ack,
        },
    },
    .{
        .request = .agent_give_up_req,
        .responses = .{
            .success = .agent_give_up_succeed_ack,
            .failure = .agent_give_up_failed_ack,
        },
    },
    .{
        .request = .agent_reward_receive_req,
        .responses = .{
            .success = .agent_reward_receive_succeed_ack,
            .failure = .agent_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_tour_guide_reward_receive_req,
        .responses = .{
            .success = .quest_tour_guide_reward_receive_succeed_ack,
            .failure = .quest_tour_guide_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_daily_reward_receive_req,
        .responses = .{
            .success = .quest_daily_reward_receive_succeed_ack,
            .failure = .quest_daily_reward_receive_failed_ack,
        },
    },
    .{
        .request = .dictionary_reward_receive_req,
        .responses = .{
            .success = .dictionary_reward_receive_succeed_ack,
            .failure = .dictionary_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_tower_reward_receive_req,
        .responses = .{
            .success = .quest_tower_reward_receive_succeed_ack,
            .failure = .quest_tower_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_daily_active_reward_receive_req,
        .responses = .{
            .success = .quest_daily_active_reward_receive_succeed_ack,
            .failure = .quest_daily_active_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_tour_guide_group_reward_receive_req,
        .responses = .{
            .success = .quest_tour_guide_group_reward_receive_succeed_ack,
            .failure = .quest_tour_guide_group_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_weekly_reward_receive_req,
        .responses = .{
            .success = .quest_weekly_reward_receive_succeed_ack,
            .failure = .quest_weekly_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_weekly_active_reward_receive_req,
        .responses = .{
            .success = .quest_weekly_active_reward_receive_succeed_ack,
            .failure = .quest_weekly_active_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_assist_reward_receive_req,
        .responses = .{
            .success = .quest_assist_reward_receive_succeed_ack,
            .failure = .quest_assist_reward_receive_failed_ack,
        },
    },
    .{
        .request = .quest_assist_group_reward_receive_req,
        .responses = .{
            .success = .quest_assist_group_reward_receive_succeed_ack,
            .failure = .quest_assist_group_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_task_reward_receive_req,
        .responses = .{
            .success = .activity_task_reward_receive_succeed_ack,
            .failure = .activity_task_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_task_group_reward_receive_req,
        .responses = .{
            .success = .activity_task_group_reward_receive_succeed_ack,
            .failure = .activity_task_group_reward_receive_failed_ack,
        },
    },
    .{
        .request = .achievement_reward_receive_req,
        .responses = .{
            .success = .achievement_reward_receive_succeed_ack,
            .failure = .achievement_reward_receive_failed_ack,
        },
    },
    .{
        .request = .achievement_info_req,
        .responses = .{
            .success = .achievement_info_succeed_ack,
            .failure = .achievement_info_failed_ack,
        },
    },
    .{
        .request = .infinity_tower_info_req,
        .responses = .{
            .success = .infinity_tower_info_succeed_ack,
            .failure = .infinity_tower_info_failed_ack,
        },
    },
    .{
        .request = .infinity_tower_apply_req,
        .responses = .{
            .success = .infinity_tower_apply_succeed_ack,
            .failure = .infinity_tower_apply_failed_ack,
        },
    },
    .{
        .request = .infinity_tower_settle_req,
        .responses = .{
            .success = .infinity_tower_settle_succeed_ack,
            .failure = .infinity_tower_settle_failed_ack,
        },
    },
    .{
        .request = .infinity_tower_daily_reward_receive_req,
        .responses = .{
            .success = .infinity_tower_daily_reward_receive_succeed_ack,
            .failure = .infinity_tower_daily_reward_receive_failed_ack,
        },
    },
    .{
        .request = .infinity_tower_plot_reward_receive_req,
        .responses = .{
            .success = .infinity_tower_plot_reward_receive_succeed_ack,
            .failure = .infinity_tower_plot_reward_receive_failed_ack,
        },
    },
    .{
        .request = .star_tower_apply_req,
        .responses = .{
            .success = .star_tower_apply_succeed_ack,
            .failure = .star_tower_apply_failed_ack,
        },
    },
    .{
        .request = .star_tower_interact_req,
        .responses = .{
            .success = .star_tower_interact_succeed_ack,
            .failure = .star_tower_interact_failed_ack,
        },
    },
    .{
        .request = .star_tower_info_req,
        .responses = .{
            .success = .star_tower_info_succeed_ack,
            .failure = .star_tower_info_failed_ack,
        },
    },
    .{
        .request = .star_tower_give_up_req,
        .responses = .{
            .success = .star_tower_give_up_succeed_ack,
            .failure = .star_tower_give_up_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_whether_save_req,
        .responses = .{
            .success = .star_tower_build_whether_save_succeed_ack,
            .failure = .star_tower_build_whether_save_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_brief_list_get_req,
        .responses = .{
            .success = .star_tower_build_brief_list_get_succeed_ack,
            .failure = .star_tower_build_brief_list_get_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_detail_get_req,
        .responses = .{
            .success = .star_tower_build_detail_get_succeed_ack,
            .failure = .star_tower_build_detail_get_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_delete_req,
        .responses = .{
            .success = .star_tower_build_delete_succeed_ack,
            .failure = .star_tower_build_delete_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_name_set_req,
        .responses = .{
            .success = .star_tower_build_name_set_succeed_ack,
            .failure = .star_tower_build_name_set_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_lock_unlock_req,
        .responses = .{
            .success = .star_tower_build_lock_unlock_succeed_ack,
            .failure = .star_tower_build_lock_unlock_failed_ack,
        },
    },
    .{
        .request = .star_tower_build_preference_set_req,
        .responses = .{
            .success = .star_tower_build_preference_set_succeed_ack,
            .failure = .star_tower_build_preference_set_failed_ack,
        },
    },
    .{
        .request = .potential_preselection_list_req,
        .responses = .{
            .success = .potential_preselection_list_succeed_ack,
            .failure = .potential_preselection_list_failed_ack,
        },
    },
    .{
        .request = .potential_preselection_import_req,
        .responses = .{
            .success = .potential_preselection_import_succeed_ack,
            .failure = .potential_preselection_import_failed_ack,
        },
    },
    .{
        .request = .potential_preselection_name_set_req,
        .responses = .{
            .success = .potential_preselection_name_set_succeed_ack,
            .failure = .potential_preselection_name_set_failed_ack,
        },
    },
    .{
        .request = .potential_preselection_preference_set_req,
        .responses = .{
            .success = .potential_preselection_preference_set_succeed_ack,
            .failure = .potential_preselection_preference_set_failed_ack,
        },
    },
    .{
        .request = .potential_preselection_update_req,
        .responses = .{
            .success = .potential_preselection_update_succeed_ack,
            .failure = .potential_preselection_update_failed_ack,
        },
    },
    .{
        .request = .potential_preselection_delete_req,
        .responses = .{
            .success = .potential_preselection_delete_succeed_ack,
            .failure = .potential_preselection_delete_failed_ack,
        },
    },
    .{
        .request = .build_convert_detail_list_get_req,
        .responses = .{
            .success = .build_convert_detail_list_get_succeed_ack,
            .failure = .build_convert_detail_list_get_failed_ack,
        },
    },
    .{
        .request = .build_convert_submit_req,
        .responses = .{
            .success = .build_convert_submit_succeed_ack,
            .failure = .build_convert_submit_failed_ack,
        },
    },
    .{
        .request = .build_convert_group_reward_receive_req,
        .responses = .{
            .success = .build_convert_group_reward_receive_succeed_ack,
            .failure = .build_convert_group_reward_receive_failed_ack,
        },
    },
    .{
        .request = .star_tower_book_potential_brief_list_get_req,
        .responses = .{
            .success = .star_tower_book_potential_brief_list_get_succeed_ack,
            .failure = .star_tower_book_potential_brief_list_get_failed_ack,
        },
    },
    .{
        .request = .star_tower_book_char_potential_get_req,
        .responses = .{
            .success = .star_tower_book_char_potential_get_succeed_ack,
            .failure = .star_tower_book_char_potential_get_failed_ack,
        },
    },
    .{
        .request = .star_tower_book_potential_reward_receive_req,
        .responses = .{
            .success = .star_tower_book_potential_reward_receive_succeed_ack,
            .failure = .star_tower_book_potential_reward_receive_failed_ack,
        },
    },
    .{
        .request = .star_tower_book_event_reward_receive_req,
        .responses = .{
            .success = .star_tower_book_event_reward_receive_succeed_ack,
            .failure = .star_tower_book_event_reward_receive_failed_ack,
        },
    },
    .{
        .request = .npc_affinity_book_get_req,
        .responses = .{
            .success = .npc_affinity_book_get_succeed_ack,
            .failure = .npc_affinity_book_get_failed_ack,
        },
    },
    .{
        .request = .npc_affinity_plot_reward_receive_req,
        .responses = .{
            .success = .npc_affinity_plot_reward_receive_succeed_ack,
            .failure = .npc_affinity_plot_reward_receive_failed_ack,
        },
    },
    .{
        .request = .resident_shop_get_req,
        .responses = .{
            .success = .resident_shop_get_succeed_ack,
            .failure = .resident_shop_get_failed_ack,
        },
    },
    .{
        .request = .resident_shop_purchase_req,
        .responses = .{
            .success = .resident_shop_purchase_succeed_ack,
            .failure = .resident_shop_purchase_failed_ack,
        },
    },
    .{
        .request = .mall_gem_list_req,
        .responses = .{
            .success = .mall_gem_list_succeed_ack,
            .failure = .mall_gem_list_failed_ack,
        },
    },
    .{
        .request = .mall_gem_order_req,
        .responses = .{
            .success = .mall_gem_order_succeed_ack,
            .failure = .mall_gem_order_failed_ack,
        },
    },
    .{
        .request = .mall_order_cancel_req,
        .responses = .{
            .success = .mall_order_cancel_succeed_ack,
            .failure = .mall_order_cancel_failed_ack,
        },
    },
    .{
        .request = .mall_order_collect_req,
        .responses = .{
            .success = .mall_order_collect_succeed_ack,
            .failure = .mall_order_collect_failed_ack,
        },
    },
    .{
        .request = .mall_monthlyCard_list_req,
        .responses = .{
            .success = .mall_monthlyCard_list_succeed_ack,
            .failure = .mall_monthlyCard_list_failed_ack,
        },
    },
    .{
        .request = .mall_monthlyCard_order_req,
        .responses = .{
            .success = .mall_monthlyCard_order_succeed_ack,
            .failure = .mall_monthlyCard_order_failed_ack,
        },
    },
    .{
        .request = .mall_package_list_req,
        .responses = .{
            .success = .mall_package_list_succeed_ack,
            .failure = .mall_package_list_failed_ack,
        },
    },
    .{
        .request = .mall_package_order_req,
        .responses = .{
            .success = .mall_package_order_succeed_ack,
            .failure = .mall_package_order_failed_ack,
        },
    },
    .{
        .request = .mall_shop_list_req,
        .responses = .{
            .success = .mall_shop_list_succeed_ack,
            .failure = .mall_shop_list_failed_ack,
        },
    },
    .{
        .request = .mall_shop_order_req,
        .responses = .{
            .success = .mall_shop_order_succeed_ack,
            .failure = .mall_shop_order_failed_ack,
        },
    },
    .{
        .request = .trace_hunt_info_req,
        .responses = .{
            .success = .trace_hunt_info_succeed_ack,
            .failure = .trace_hunt_info_failed_ack,
        },
    },
    .{
        .request = .trace_hunt_apply_req,
        .responses = .{
            .success = .trace_hunt_apply_succeed_ack,
            .failure = .trace_hunt_apply_failed_ack,
        },
    },
    .{
        .request = .trace_hunt_settle_req,
        .responses = .{
            .success = .trace_hunt_settle_succeed_ack,
            .failure = .trace_hunt_settle_failed_ack,
        },
    },
    .{
        .request = .trace_hunt_recommend_req,
        .responses = .{
            .success = .trace_hunt_recommend_succeed_ack,
            .failure = .trace_hunt_recommend_failed_ack,
        },
    },
    .{
        .request = .trace_hunt_boss_reward_receive_req,
        .responses = .{
            .success = .trace_hunt_boss_reward_receive_succeed_ack,
            .failure = .trace_hunt_boss_reward_receive_failed_ack,
        },
    },
    .{
        .request = .trace_hunt_trace_req,
        .responses = .{
            .success = .trace_hunt_trace_succeed_ack,
            .failure = .trace_hunt_trace_failed_ack,
        },
    },
    .{
        .request = .soldier_apply_req,
        .responses = .{
            .success = .soldier_apply_succeed_ack,
            .failure = .soldier_apply_failed_ack,
        },
    },
    .{
        .request = .soldier_info_req,
        .responses = .{
            .success = .soldier_info_succeed_ack,
            .failure = .soldier_info_failed_ack,
        },
    },
    .{
        .request = .soldier_interact_req,
        .responses = .{
            .success = .soldier_interact_succeed_ack,
            .failure = .soldier_interact_failed_ack,
        },
    },
    .{
        .request = .soldier_give_up_req,
        .responses = .{
            .success = .soldier_give_up_succeed_ack,
            .failure = .soldier_give_up_failed_ack,
        },
    },
    .{
        .request = .soldier_step_out_req,
        .responses = .{
            .success = .soldier_step_out_succeed_ack,
            .failure = .soldier_step_out_failed_ack,
        },
    },
    .{
        .request = .soldier_partner_trace_req,
        .responses = .{
            .success = .soldier_partner_trace_succeed_ack,
            .failure = .soldier_partner_trace_failed_ack,
        },
    },
    .{
        .request = .gacha_spin_req,
        .responses = .{
            .success = .gacha_spin_succeed_ack,
            .failure = .gacha_spin_failed_ack,
        },
    },
    .{
        .request = .gacha_information_req,
        .responses = .{
            .success = .gacha_information_succeed_ack,
            .failure = .gacha_information_failed_ack,
        },
    },
    .{
        .request = .gacha_histories_req,
        .responses = .{
            .success = .gacha_histories_succeed_ack,
            .failure = .gacha_histories_failed_ack,
        },
    },
    .{
        .request = .gacha_guarantee_reward_receive_req,
        .responses = .{
            .success = .gacha_guarantee_reward_receive_succeed_ack,
            .failure = .gacha_guarantee_reward_receive_failed_ack,
        },
    },
    .{
        .request = .gacha_newbie_spin_req,
        .responses = .{
            .success = .gacha_newbie_spin_succeed_ack,
            .failure = .gacha_newbie_spin_failed_ack,
        },
    },
    .{
        .request = .gacha_newbie_save_req,
        .responses = .{
            .success = .gacha_newbie_save_succeed_ack,
            .failure = .gacha_newbie_save_failed_ack,
        },
    },
    .{
        .request = .gacha_newbie_obtain_req,
        .responses = .{
            .success = .gacha_newbie_obtain_succeed_ack,
            .failure = .gacha_newbie_obtain_failed_ack,
        },
    },
    .{
        .request = .gacha_newbie_info_req,
        .responses = .{
            .success = .gacha_newbie_info_succeed_ack,
            .failure = .gacha_newbie_info_failed_ack,
        },
    },
    .{
        .request = .gacha_reward_get_req,
        .responses = .{
            .success = .gacha_reward_get_succeed_ack,
            .failure = .gacha_reward_get_failed_ack,
        },
    },
    .{
        .request = .tower_book_fate_card_detail_req,
        .responses = .{
            .success = .tower_book_fate_card_detail_succeed_ack,
            .failure = .tower_book_fate_card_detail_failed_ack,
        },
    },
    .{
        .request = .tower_book_fate_card_reward_receive_req,
        .responses = .{
            .success = .tower_book_fate_card_reward_receive_succeed_ack,
            .failure = .tower_book_fate_card_reward_receive_failed_ack,
        },
    },
    .{
        .request = .joint_drill_apply_req,
        .responses = .{
            .success = .joint_drill_apply_succeed_ack,
            .failure = .joint_drill_apply_failed_ack,
        },
    },
    .{
        .request = .joint_drill_continue_req,
        .responses = .{
            .success = .joint_drill_continue_succeed_ack,
            .failure = .joint_drill_continue_failed_ack,
        },
    },
    .{
        .request = .joint_drill_sync_req,
        .responses = .{
            .success = .joint_drill_sync_succeed_ack,
            .failure = .joint_drill_sync_failed_ack,
        },
    },
    .{
        .request = .joint_drill_give_up_req,
        .responses = .{
            .success = .joint_drill_give_up_succeed_ack,
            .failure = .joint_drill_give_up_failed_ack,
        },
    },
    .{
        .request = .joint_drill_retreat_req,
        .responses = .{
            .success = .joint_drill_retreat_succeed_ack,
            .failure = .joint_drill_retreat_failed_ack,
        },
    },
    .{
        .request = .joint_drill_settle_req,
        .responses = .{
            .success = .joint_drill_settle_succeed_ack,
            .failure = .joint_drill_settle_failed_ack,
        },
    },
    .{
        .request = .joint_drill_game_over_req,
        .responses = .{
            .success = .joint_drill_game_over_succeed_ack,
            .failure = .joint_drill_game_over_failed_ack,
        },
    },
    .{
        .request = .joint_drill_sweep_req,
        .responses = .{
            .success = .joint_drill_sweep_succeed_ack,
            .failure = .joint_drill_sweep_failed_ack,
        },
    },
    .{
        .request = .joint_drill_rank_req,
        .responses = .{
            .success = .joint_drill_rank_succeed_ack,
            .failure = .joint_drill_rank_failed_ack,
        },
    },
    .{
        .request = .joint_drill_quest_reward_receive_req,
        .responses = .{
            .success = .joint_drill_quest_reward_receive_succeed_ack,
            .failure = .joint_drill_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_apply_req,
        .responses = .{
            .success = .joint_drill_2_apply_succeed_ack,
            .failure = .joint_drill_2_apply_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_continue_req,
        .responses = .{
            .success = .joint_drill_2_continue_succeed_ack,
            .failure = .joint_drill_2_continue_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_sync_req,
        .responses = .{
            .success = .joint_drill_2_sync_succeed_ack,
            .failure = .joint_drill_2_sync_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_give_up_req,
        .responses = .{
            .success = .joint_drill_2_give_up_succeed_ack,
            .failure = .joint_drill_2_give_up_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_retreat_req,
        .responses = .{
            .success = .joint_drill_2_retreat_succeed_ack,
            .failure = .joint_drill_2_retreat_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_settle_req,
        .responses = .{
            .success = .joint_drill_2_settle_succeed_ack,
            .failure = .joint_drill_2_settle_failed_ack,
        },
    },
    .{
        .request = .joint_drill_2_game_over_req,
        .responses = .{
            .success = .joint_drill_2_game_over_succeed_ack,
            .failure = .joint_drill_2_game_over_failed_ack,
        },
    },
    .{
        .request = .plot_reward_receive_req,
        .responses = .{
            .success = .plot_reward_receive_succeed_ack,
            .failure = .plot_reward_receive_failed_ack,
        },
    },
    .{
        .request = .daily_instance_apply_req,
        .responses = .{
            .success = .daily_instance_apply_succeed_ack,
            .failure = .daily_instance_apply_failed_ack,
        },
    },
    .{
        .request = .daily_instance_settle_req,
        .responses = .{
            .success = .daily_instance_settle_succeed_ack,
            .failure = .daily_instance_settle_failed_ack,
        },
    },
    .{
        .request = .daily_instance_raid_req,
        .responses = .{
            .success = .daily_instance_raid_succeed_ack,
            .failure = .daily_instance_raid_failed_ack,
        },
    },
    .{
        .request = .char_gem_instance_apply_req,
        .responses = .{
            .success = .char_gem_instance_apply_succeed_ack,
            .failure = .char_gem_instance_apply_failed_ack,
        },
    },
    .{
        .request = .char_gem_instance_settle_req,
        .responses = .{
            .success = .char_gem_instance_settle_succeed_ack,
            .failure = .char_gem_instance_settle_failed_ack,
        },
    },
    .{
        .request = .char_gem_instance_sweep_req,
        .responses = .{
            .success = .char_gem_instance_sweep_succeed_ack,
            .failure = .char_gem_instance_sweep_failed_ack,
        },
    },
    .{
        .request = .region_boss_level_apply_req,
        .responses = .{
            .success = .region_boss_level_apply_succeed_ack,
            .failure = .region_boss_level_apply_failed_ack,
        },
    },
    .{
        .request = .region_boss_level_settle_req,
        .responses = .{
            .success = .region_boss_level_settle_succeed_ack,
            .failure = .region_boss_level_settle_failed_ack,
        },
    },
    .{
        .request = .region_boss_level_sweep_req,
        .responses = .{
            .success = .region_boss_level_sweep_succeed_ack,
            .failure = .region_boss_level_sweep_failed_ack,
        },
    },
    .{
        .request = .traveler_duel_level_apply_req,
        .responses = .{
            .success = .traveler_duel_level_apply_succeed_ack,
            .failure = .traveler_duel_level_apply_failed_ack,
        },
    },
    .{
        .request = .traveler_duel_level_settle_req,
        .responses = .{
            .success = .traveler_duel_level_settle_succeed_ack,
            .failure = .traveler_duel_level_settle_failed_ack,
        },
    },
    .{
        .request = .traveler_duel_info_req,
        .responses = .{
            .success = .traveler_duel_info_succeed_ack,
            .failure = .traveler_duel_info_failed_ack,
        },
    },
    .{
        .request = .traveler_duel_quest_reward_receive_req,
        .responses = .{
            .success = .traveler_duel_quest_reward_receive_succeed_ack,
            .failure = .traveler_duel_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .traveler_duel_rank_req,
        .responses = .{
            .success = .traveler_duel_rank_succeed_ack,
            .failure = .traveler_duel_rank_failed_ack,
        },
    },
    .{
        .request = .traveler_duel_rank_upload_req,
        .responses = .{
            .success = .traveler_duel_rank_upload_succeed_ack,
            .failure = .traveler_duel_rank_upload_failed_ack,
        },
    },
    .{
        .request = .story_apply_req,
        .responses = .{
            .success = .story_apply_succeed_ack,
            .failure = .story_apply_failed_ack,
        },
    },
    .{
        .request = .story_settle_req,
        .responses = .{
            .success = .story_settle_succeed_ack,
            .failure = .story_settle_failed_ack,
        },
    },
    .{
        .request = .skill_instance_apply_req,
        .responses = .{
            .success = .skill_instance_apply_succeed_ack,
            .failure = .skill_instance_apply_failed_ack,
        },
    },
    .{
        .request = .skill_instance_settle_req,
        .responses = .{
            .success = .skill_instance_settle_succeed_ack,
            .failure = .skill_instance_settle_failed_ack,
        },
    },
    .{
        .request = .skill_instance_sweep_req,
        .responses = .{
            .success = .skill_instance_sweep_succeed_ack,
            .failure = .skill_instance_sweep_failed_ack,
        },
    },
    .{
        .request = .week_boss_apply_req,
        .responses = .{
            .success = .week_boss_apply_succeed_ack,
            .failure = .week_boss_apply_failed_ack,
        },
    },
    .{
        .request = .week_boss_settle_req,
        .responses = .{
            .success = .week_boss_settle_succeed_ack,
            .failure = .week_boss_settle_failed_ack,
        },
    },
    .{
        .request = .tutorial_level_settle_req,
        .responses = .{
            .success = .tutorial_level_settle_succeed_ack,
            .failure = .tutorial_level_settle_failed_ack,
        },
    },
    .{
        .request = .tutorial_level_reward_receive_req,
        .responses = .{
            .success = .tutorial_level_reward_receive_succeed_ack,
            .failure = .tutorial_level_reward_receive_failed_ack,
        },
    },
    .{
        .request = .story_set_info_req,
        .responses = .{
            .success = .story_set_info_succeed_ack,
            .failure = .story_set_info_failed_ack,
        },
    },
    .{
        .request = .story_set_reward_receive_req,
        .responses = .{
            .success = .story_set_reward_receive_succeed_ack,
            .failure = .story_set_reward_receive_failed_ack,
        },
    },
    .{
        .request = .energy_buy_req,
        .responses = .{
            .success = .energy_buy_succeed_ack,
            .failure = .energy_buy_failed_ack,
        },
    },
    .{
        .request = .energy_extract_req,
        .responses = .{
            .success = .energy_extract_succeed_ack,
            .failure = .energy_extract_failed_ack,
        },
    },
    .{
        .request = .energy_info_req,
        .responses = .{
            .success = .energy_info_succeed_ack,
            .failure = .energy_info_failed_ack,
        },
    },
    .{
        .request = .client_event_report_req,
        .responses = .{
            .success = .client_event_report_succeed_ack,
            .failure = .client_event_report_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_apply_req,
        .responses = .{
            .success = .vampire_survivor_apply_succeed_ack,
            .failure = .vampire_survivor_apply_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_area_change_req,
        .responses = .{
            .success = .vampire_survivor_area_change_succeed_ack,
            .failure = .vampire_survivor_area_change_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_settle_req,
        .responses = .{
            .success = .vampire_survivor_settle_succeed_ack,
            .failure = .vampire_survivor_settle_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_reward_select_req,
        .responses = .{
            .success = .vampire_survivor_reward_select_succeed_ack,
            .failure = .vampire_survivor_reward_select_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_reward_chest_req,
        .responses = .{
            .success = .vampire_survivor_reward_chest_succeed_ack,
            .failure = .vampire_survivor_reward_chest_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_quest_reward_receive_req,
        .responses = .{
            .success = .vampire_survivor_quest_reward_receive_succeed_ack,
            .failure = .vampire_survivor_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_extra_reward_select_req,
        .responses = .{
            .success = .vampire_survivor_extra_reward_select_succeed_ack,
            .failure = .vampire_survivor_extra_reward_select_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_restart_req,
        .responses = .{
            .success = .vampire_survivor_restart_succeed_ack,
            .failure = .vampire_survivor_restart_failed_ack,
        },
    },
    .{
        .request = .vampire_talent_detail_req,
        .responses = .{
            .success = .vampire_talent_detail_succeed_ack,
            .failure = .vampire_talent_detail_failed_ack,
        },
    },
    .{
        .request = .vampire_talent_reset_req,
        .responses = .{
            .success = .vampire_talent_reset_succeed_ack,
            .failure = .vampire_talent_reset_failed_ack,
        },
    },
    .{
        .request = .vampire_talent_unlock_req,
        .responses = .{
            .success = .vampire_talent_unlock_succeed_ack,
            .failure = .vampire_talent_unlock_failed_ack,
        },
    },
    .{
        .request = .vampire_talent_show_req,
        .responses = .{
            .success = .vampire_talent_show_succeed_ack,
            .failure = .vampire_talent_show_failed_ack,
        },
    },
    .{
        .request = .vampire_survivor_info_req,
        .responses = .{
            .success = .vampire_survivor_info_succeed_ack,
            .failure = .vampire_survivor_info_failed_ack,
        },
    },
    .{
        .request = .activity_story_apply_req,
        .responses = .{
            .success = .activity_story_apply_succeed_ack,
            .failure = .activity_story_apply_failed_ack,
        },
    },
    .{
        .request = .activity_story_settle_req,
        .responses = .{
            .success = .activity_story_settle_succeed_ack,
            .failure = .activity_story_settle_failed_ack,
        },
    },
    .{
        .request = .activity_throw_gift_settle_req,
        .responses = .{
            .success = .activity_throw_gift_settle_succeed_ack,
            .failure = .activity_throw_gift_settle_failed_ack,
        },
    },
    .{
        .request = .player_last_read_update_req,
        .responses = .{
            .success = .player_last_read_update_succeed_ack,
            .failure = .player_last_read_update_failed_ack,
        },
    },
    .{
        .request = .activity_history_story_apply_req,
        .responses = .{
            .success = .activity_history_story_apply_succeed_ack,
            .failure = .activity_history_story_apply_failed_ack,
        },
    },
    .{
        .request = .activity_history_story_settle_req,
        .responses = .{
            .success = .activity_history_story_settle_succeed_ack,
            .failure = .activity_history_story_settle_failed_ack,
        },
    },
    .{
        .request = .activity_penguin_card_level_settle_req,
        .responses = .{
            .success = .activity_penguin_card_level_settle_succeed_ack,
            .failure = .activity_penguin_card_level_settle_failed_ack,
        },
    },
    .{
        .request = .activity_penguin_card_quest_reward_receive_req,
        .responses = .{
            .success = .activity_penguin_card_quest_reward_receive_succeed_ack,
            .failure = .activity_penguin_card_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_double_quest_reward_receive_req,
        .responses = .{
            .success = .activity_double_quest_reward_receive_succeed_ack,
            .failure = .activity_double_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_ice_cream_level_settle_req,
        .responses = .{
            .success = .activity_ice_cream_level_settle_succeed_ack,
            .failure = .activity_ice_cream_level_settle_failed_ack,
        },
    },
    .{
        .request = .activity_penguin_card_endless_level_save_req,
        .responses = .{
            .success = .activity_penguin_card_endless_level_save_succeed_ack,
            .failure = .activity_penguin_card_endless_level_save_failed_ack,
        },
    },
    .{
        .request = .mail_list_req,
        .responses = .{
            .success = .mail_list_succeed_ack,
            .failure = .mail_list_failed_ack,
        },
    },
    .{
        .request = .mail_read_req,
        .responses = .{
            .success = .mail_read_succeed_ack,
            .failure = .mail_read_failed_ack,
        },
    },
    .{
        .request = .mail_recv_req,
        .responses = .{
            .success = .mail_recv_succeed_ack,
            .failure = .mail_recv_failed_ack,
        },
    },
    .{
        .request = .mail_remove_req,
        .responses = .{
            .success = .mail_remove_succeed_ack,
            .failure = .mail_remove_failed_ack,
        },
    },
    .{
        .request = .mail_pin_req,
        .responses = .{
            .success = .mail_pin_succeed_ack,
            .failure = .mail_pin_failed_ack,
        },
    },
    .{
        .request = .activity_detail_req,
        .responses = .{
            .success = .activity_detail_succeed_ack,
            .failure = .activity_detail_failed_ack,
        },
    },
    .{
        .request = .activity_periodic_reward_receive_req,
        .responses = .{
            .success = .activity_periodic_reward_receive_succeed_ack,
            .failure = .activity_periodic_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_periodic_final_reward_receive_req,
        .responses = .{
            .success = .activity_periodic_final_reward_receive_succeed_ack,
            .failure = .activity_periodic_final_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_login_reward_receive_req,
        .responses = .{
            .success = .activity_login_reward_receive_succeed_ack,
            .failure = .activity_login_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_tower_defense_story_reward_receive_req,
        .responses = .{
            .success = .activity_tower_defense_story_reward_receive_succeed_ack,
            .failure = .activity_tower_defense_story_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_tower_defense_quest_reward_receive_req,
        .responses = .{
            .success = .activity_tower_defense_quest_reward_receive_succeed_ack,
            .failure = .activity_tower_defense_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_tower_defense_level_apply_req,
        .responses = .{
            .success = .activity_tower_defense_level_apply_succeed_ack,
            .failure = .activity_tower_defense_level_apply_failed_ack,
        },
    },
    .{
        .request = .activity_tower_defense_level_settle_req,
        .responses = .{
            .success = .activity_tower_defense_level_settle_succeed_ack,
            .failure = .activity_tower_defense_level_settle_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_apply_req,
        .responses = .{
            .success = .activity_trekker_versus_apply_succeed_ack,
            .failure = .activity_trekker_versus_apply_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_settle_req,
        .responses = .{
            .success = .activity_trekker_versus_settle_succeed_ack,
            .failure = .activity_trekker_versus_settle_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_reward_receive_req,
        .responses = .{
            .success = .activity_trekker_versus_reward_receive_succeed_ack,
            .failure = .activity_trekker_versus_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_idle_refresh_req,
        .responses = .{
            .success = .activity_trekker_versus_idle_refresh_succeed_ack,
            .failure = .activity_trekker_versus_idle_refresh_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_idle_reward_receive_req,
        .responses = .{
            .success = .activity_trekker_versus_idle_reward_receive_succeed_ack,
            .failure = .activity_trekker_versus_idle_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_rank_boost_req,
        .responses = .{
            .success = .activity_trekker_versus_rank_boost_succeed_ack,
            .failure = .activity_trekker_versus_rank_boost_failed_ack,
        },
    },
    .{
        .request = .activity_trekker_versus_schedule_reward_receive_req,
        .responses = .{
            .success = .activity_trekker_versus_schedule_reward_receive_succeed_ack,
            .failure = .activity_trekker_versus_schedule_reward_receive_failed_ack,
        },
    },
    .{
        .request = .phone_contacts_info_req,
        .responses = .{
            .success = .phone_contacts_info_succeed_ack,
            .failure = .phone_contacts_info_failed_ack,
        },
    },
    .{
        .request = .phone_contacts_report_req,
        .responses = .{
            .success = .phone_contacts_report_succeed_ack,
            .failure = .phone_contacts_report_failed_ack,
        },
    },
    .{
        .request = .phone_contacts_top_req,
        .responses = .{
            .success = .phone_contacts_top_succeed_ack,
            .failure = .phone_contacts_top_failed_ack,
        },
    },
    .{
        .request = .activity_share_reward_receive_req,
        .responses = .{
            .success = .activity_share_reward_receive_succeed_ack,
            .failure = .activity_share_reward_receive_failed_ack,
        },
    },
    .{
        .request = .talent_unlock_req,
        .responses = .{
            .success = .talent_unlock_succeed_ack,
            .failure = .talent_unlock_failed_ack,
        },
    },
    .{
        .request = .talent_reset_req,
        .responses = .{
            .success = .talent_reset_succeed_ack,
            .failure = .talent_reset_failed_ack,
        },
    },
    .{
        .request = .talent_node_reset_req,
        .responses = .{
            .success = .talent_node_reset_succeed_ack,
            .failure = .talent_node_reset_failed_ack,
        },
    },
    .{
        .request = .talent_background_set_req,
        .responses = .{
            .success = .talent_background_set_succeed_ack,
            .failure = .talent_background_set_failed_ack,
        },
    },
    .{
        .request = .talent_group_unlock_req,
        .responses = .{
            .success = .talent_group_unlock_succeed_ack,
            .failure = .talent_group_unlock_failed_ack,
        },
    },
    .{
        .request = .activity_trial_reward_receive_req,
        .responses = .{
            .success = .activity_trial_reward_receive_succeed_ack,
            .failure = .activity_trial_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_cg_read_req,
        .responses = .{
            .success = .activity_cg_read_succeed_ack,
            .failure = .activity_cg_read_failed_ack,
        },
    },
    .{
        .request = .activity_levels_apply_req,
        .responses = .{
            .success = .activity_levels_apply_succeed_ack,
            .failure = .activity_levels_apply_failed_ack,
        },
    },
    .{
        .request = .activity_levels_settle_req,
        .responses = .{
            .success = .activity_levels_settle_succeed_ack,
            .failure = .activity_levels_settle_failed_ack,
        },
    },
    .{
        .request = .activity_levels_sweep_req,
        .responses = .{
            .success = .activity_levels_sweep_succeed_ack,
            .failure = .activity_levels_sweep_failed_ack,
        },
    },
    .{
        .request = .activity_avg_reward_receive_req,
        .responses = .{
            .success = .activity_avg_reward_receive_succeed_ack,
            .failure = .activity_avg_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_shop_purchase_req,
        .responses = .{
            .success = .activity_shop_purchase_succeed_ack,
            .failure = .activity_shop_purchase_failed_ack,
        },
    },
    .{
        .request = .battle_pass_info_req,
        .responses = .{
            .success = .battle_pass_info_succeed_ack,
            .failure = .battle_pass_info_failed_ack,
        },
    },
    .{
        .request = .battle_pass_reward_receive_req,
        .responses = .{
            .success = .battle_pass_reward_receive_succeed_ack,
            .failure = .battle_pass_reward_receive_failed_ack,
        },
    },
    .{
        .request = .battle_pass_level_buy_req,
        .responses = .{
            .success = .battle_pass_level_buy_succeed_ack,
            .failure = .battle_pass_level_buy_failed_ack,
        },
    },
    .{
        .request = .battle_pass_order_req,
        .responses = .{
            .success = .battle_pass_order_succeed_ack,
            .failure = .battle_pass_order_failed_ack,
        },
    },
    .{
        .request = .battle_pass_order_collect_req,
        .responses = .{
            .success = .battle_pass_order_collect_succeed_ack,
            .failure = .battle_pass_order_collect_failed_ack,
        },
    },
    .{
        .request = .battle_pass_quest_reward_receive_req,
        .responses = .{
            .success = .battle_pass_quest_reward_receive_succeed_ack,
            .failure = .battle_pass_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .redeem_code_req,
        .responses = .{
            .success = .redeem_code_succeed_ack,
            .failure = .redeem_code_failed_ack,
        },
    },
    .{
        .request = .activity_mining_apply_req,
        .responses = .{
            .success = .activity_mining_apply_succeed_ack,
            .failure = .activity_mining_apply_failed_ack,
        },
    },
    .{
        .request = .activity_mining_dig_req,
        .responses = .{
            .success = .activity_mining_dig_succeed_ack,
            .failure = .activity_mining_dig_failed_ack,
        },
    },
    .{
        .request = .activity_mining_move_to_next_layer_req,
        .responses = .{
            .success = .activity_mining_move_to_next_layer_succeed_ack,
            .failure = .activity_mining_move_to_next_layer_failed_ack,
        },
    },
    .{
        .request = .activity_mining_story_reward_receive_req,
        .responses = .{
            .success = .activity_mining_story_reward_receive_succeed_ack,
            .failure = .activity_mining_story_reward_receive_failed_ack,
        },
    },
    .{
        .request = .activity_mining_quest_reward_receive_req,
        .responses = .{
            .success = .activity_mining_quest_reward_receive_succeed_ack,
            .failure = .activity_mining_quest_reward_receive_failed_ack,
        },
    },
    .{
        .request = .score_boss_apply_req,
        .responses = .{
            .success = .score_boss_apply_succeed_ack,
            .failure = .score_boss_apply_failed_ack,
        },
    },
    .{
        .request = .score_boss_settle_req,
        .responses = .{
            .success = .score_boss_settle_succeed_ack,
            .failure = .score_boss_settle_failed_ack,
        },
    },
    .{
        .request = .score_boss_rank_req,
        .responses = .{
            .success = .score_boss_rank_succeed_ack,
            .failure = .score_boss_rank_failed_ack,
        },
    },
    .{
        .request = .score_boss_star_reward_receive_req,
        .responses = .{
            .success = .score_boss_star_reward_receive_succeed_ack,
            .failure = .score_boss_star_reward_receive_failed_ack,
        },
    },
    .{
        .request = .score_boss_info_req,
        .responses = .{
            .success = .score_boss_info_succeed_ack,
            .failure = .score_boss_info_failed_ack,
        },
    },
    .{
        .request = .activity_cookie_settle_req,
        .responses = .{
            .success = .activity_cookie_settle_succeed_ack,
            .failure = .activity_cookie_settle_failed_ack,
        },
    },
    .{
        .request = .activity_cookie_quest_reward_receive_req,
        .responses = .{
            .success = .activity_cookie_quest_reward_receive_succeed_ack,
            .failure = .activity_cookie_quest_reward_receive_failed_ack,
        },
    },
};

/// Returns the success and failure packets associated with a request.
pub fn responsesFor(request: PacketId) ?ResponseIds {
    const needle = @intFromEnum(request);
    var low: usize = 0;
    var high: usize = request_responses.len;
    while (low < high) {
        const middle = low + (high - low) / 2;
        const candidate = request_responses[middle];
        const candidate_id = @intFromEnum(candidate.request);
        if (needle < candidate_id) {
            high = middle;
        } else if (needle > candidate_id) {
            low = middle + 1;
        } else {
            return candidate.responses;
        }
    }

    return null;
}
