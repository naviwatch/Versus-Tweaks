local mod = get_mod("Versus Tweaks")

-- General gamemode setttings
GameModeSettings.versus = table.clone(GameModeSettings.base)
GameModeSettings.versus.key = "versus"
GameModeSettings.versus.class_name = "GameModeVersus"
GameModeSettings.versus.display_name = "dlc1_2_map_game_mode_versus"
GameModeSettings.versus.description_text = "game_mode_description_versus"
GameModeSettings.versus.lose_condition_time_dead = 7.5
GameModeSettings.versus.lose_condition_time = 7.5
GameModeSettings.versus.ai_specials_spawning_disabled = false
GameModeSettings.versus.horde_spawning_disabled = false
GameModeSettings.versus.show_horde_timer_pactsworn = true
GameModeSettings.versus.enable_horde_surge = false
GameModeSettings.versus.end_mission_rewards = true
GameModeSettings.versus.disable_difficulty_check = true
GameModeSettings.versus.hud_component_list_path = "scripts/ui/hud_ui/component_list_definitions/hud_component_list_versus"
GameModeSettings.versus.disable_rush_intervention = {
	all = false,
	hordes = false,
	specials = true,
}
GameModeSettings.versus.use_floating_damage_numbers = true
GameModeSettings.versus.damage_sound_param_cooldown = 3
GameModeSettings.versus.max_health_kd = 250
GameModeSettings.versus.healing_draught_heal_amount = 40 
GameModeSettings.versus.min_streak_font_size = 28
GameModeSettings.versus.max_streak_font_size = 40
GameModeSettings.versus.max_num_rewards_displayed = 7
GameModeSettings.versus.round_start_pact_sworn_spawn_delay = 5
GameModeSettings.versus.round_start_heroes_left_safe_zone_spawn_delay = 2
GameModeSettings.versus.object_sets = {
	versus = true,
	versus_dark_pact = true,
	versus_heroes = true,
}
GameModeSettings.versus.ping_mode = {
	world_markers = true,
	outlines = {
		item = true,
		unit = true,
	},
}

GameModeSettings.versus.positive_reinforcement_check = function (predicate, breed_attacker, breed_killed)
	return breed_killed.is_player or breed_killed.boss or breed_killed.special
end

GameModeSettings.versus.display_character_picking_view = true
GameModeSettings.versus.show_level_introduction = {
	inn = false,
	round_1 = false,
	round_2 = false,
}
GameModeSettings.versus.player_wounds = {
	dark_pact = 1,
	heroes = 1,
	spectators = 0,
}
GameModeSettings.versus.objectives = {
	capture_point = {
		capture_rate_multiplier = 1,
		capture_time = 60,
		num_sections = 1,
		scale = 1,
		score_for_completion = 0,
		score_per_section = 0,
		time_for_completion = 0,
		time_per_section = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_objective_completed_pactsworn",
			heroes = "versus_objective_completed_heroes",
		},
	},
	survive_event = {
		num_sections = 4,
		score_for_completion = 0,
		score_per_section = 0,
		survive_time = 100,
		time_for_completion = 100,
		time_per_section = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_objective_completed_pactsworn",
			heroes = "versus_objective_completed_heroes",
		},
	},
	interact = {
		scale = 1,
		score_for_completion = 0,
		time_for_completion = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_hud_checkpoint_reached_dark_pact",
			heroes = "versus_hud_checkpoint_reached_heroes",
		},
	},
	socket = {
		scale = 1,
		score_for_completion = 0,
		score_per_socket = 0,
		time_for_completion = 0,
		time_per_socket = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_objective_completed_pactsworn",
			heroes = "versus_objective_completed_heroes",
		},
	},
	payload = {
		num_sections = 10,
		scale = 1,
		score_for_completion = 0,
		score_per_section = 0,
		time_for_completion = 0,
		time_per_section = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_objective_completed_pactsworn",
			heroes = "versus_objective_completed_heroes",
		},
	},
	volume = {
		scale = 1,
		score_for_completion = 0,
		score_for_each_player_inside = 0,
		time_for_completion = 0,
		time_for_each_player_inside = 0,
		volume_type = "all_alive",
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_hud_checkpoint_reached_dark_pact",
			heroes = "versus_hud_checkpoint_reached_heroes",
		},
	},
	target = {
		num_sections = 1,
		scale = 1,
		score_for_completion = 0,
		score_per_section = 0,
		time_for_completion = 0,
		time_per_section = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_hud_checkpoint_reached_dark_pact",
			heroes = "versus_hud_checkpoint_reached_heroes",
		},
	},
	mission = {
		scale = 1,
		score_for_completion = 0,
		time_for_completion = 0,
		on_last_leaf_complete_sound_event = {
			dark_pact = "versus_hud_checkpoint_reached_dark_pact",
			heroes = "versus_hud_checkpoint_reached_heroes",
		},
	},
}
GameModeSettings.versus.surge_events = {
	events = {
		military_pvp = {
			{
				time = 60,
				terror_events = {
					"military_pvp_event_su01_01",
					"military_pvp_event_su01_02",
					"military_pvp_event_su01_03",
					"military_pvp_event_su01_04",
				},
			},
			{
				time = 55,
				terror_events = {
					"military_pvp_event_su02_01",
					"military_pvp_event_su02_02",
					"military_pvp_event_su02_03",
					"military_pvp_event_su02_04",
				},
			},
			{
				time = 55,
				terror_events = {
					"military_pvp_event_su03_01",
					"military_pvp_event_su03_02",
					"military_pvp_event_su03_03",
					"military_pvp_event_su03_04",
				},
			},
			{
				time = 50,
				terror_events = {
					"military_pvp_event_su04_01",
					"military_pvp_event_su04_02",
					"military_pvp_event_su04_03",
					"military_pvp_event_su04_04",
				},
			},
			{
				time = 45,
				terror_events = {
					"military_pvp_event_su05_01",
					"military_pvp_event_su05_02",
					"military_pvp_event_su05_03",
					"military_pvp_event_su05_04",
				},
			},
			{
				time = 45,
				terror_events = {
					"military_pvp_event_su06_01",
					"military_pvp_event_su06_02",
					"military_pvp_event_su06_03",
					"military_pvp_event_su06_04",
				},
			},
		},
		bell_pvp = {
			{
				time = 60,
				terror_events = {
					"bell_pvp_event_su01_01",
					"bell_pvp_event_su01_02",
					"bell_pvp_event_su01_03",
					"bell_pvp_event_su01_04",
				},
			},
			{
				time = 55,
				terror_events = {
					"bell_pvp_event_su02_01",
					"bell_pvp_event_su02_02",
					"bell_pvp_event_su02_03",
					"bell_pvp_event_su02_04",
				},
			},
			{
				time = 55,
				terror_events = {
					"bell_pvp_event_su03_01",
					"bell_pvp_event_su03_02",
					"bell_pvp_event_su03_03",
					"bell_pvp_event_su03_04",
				},
			},
			{
				time = 50,
				terror_events = {
					"bell_pvp_event_su04_01",
					"bell_pvp_event_su04_02",
					"bell_pvp_event_su04_03",
					"bell_pvp_event_su04_04",
				},
			},
			{
				time = 45,
				terror_events = {
					"bell_pvp_event_su05_01",
					"bell_pvp_event_su05_02",
					"bell_pvp_event_su05_03",
					"bell_pvp_event_su05_04",
				},
			},
			{
				time = 45,
				terror_events = {
					"bell_pvp_event_su06_01",
					"bell_pvp_event_su06_02",
					"bell_pvp_event_su06_03",
					"bell_pvp_event_su06_04",
				},
			},
		},
		farmlands_pvp = {
			{
				time = 60,
				terror_events = {
					"farmlands_pvp_event_su01_01",
					"farmlands_pvp_event_su01_02",
					"farmlands_pvp_event_su01_03",
					"farmlands_pvp_event_su01_04",
				},
			},
			{
				time = 55,
				terror_events = {
					"farmlands_pvp_event_su02_01",
					"farmlands_pvp_event_su02_02",
					"farmlands_pvp_event_su02_03",
					"farmlands_pvp_event_su02_04",
				},
			},
			{
				time = 55,
				terror_events = {
					"farmlands_pvp_event_su03_01",
					"farmlands_pvp_event_su03_02",
					"farmlands_pvp_event_su03_03",
					"farmlands_pvp_event_su03_04",
				},
			},
			{
				time = 50,
				terror_events = {
					"farmlands_pvp_event_su04_01",
					"farmlands_pvp_event_su04_02",
					"farmlands_pvp_event_su04_03",
					"farmlands_pvp_event_su04_04",
				},
			},
			{
				time = 45,
				terror_events = {
					"farmlands_pvp_event_su05_01",
					"farmlands_pvp_event_su05_02",
					"farmlands_pvp_event_su05_03",
					"farmlands_pvp_event_su05_04",
				},
			},
			{
				time = 45,
				terror_events = {
					"farmlands_pvp_event_su06_01",
					"farmlands_pvp_event_su06_02",
					"farmlands_pvp_event_su06_03",
					"farmlands_pvp_event_su06_04",
				},
			},
		},
	},
}
GameModeSettings.versus.move_dead_players_after_objective_completed = true
GameModeSettings.versus.allow_double_ping = true
GameModeSettings.versus.extended_social_wheel_time = true
GameModeSettings.versus.should_use_gamepad_social_wheel = true
GameModeSettings.versus.social_wheel_by_side = {
	dark_pact = "dark_pact",
	heroes = "versus_heroes",
}
GameModeSettings.versus.dark_pact_profile_order = {
	"vs_gutter_runner",
	"vs_packmaster",
	"vs_poison_wind_globadier",
	"vs_ratling_gunner",
	"vs_warpfire_thrower",
}
GameModeSettings.versus.dark_pact_boss_profiles = {
	"vs_chaos_troll",
}
GameModeSettings.versus.dark_pact_player_profile_to_ai_breed = {
	vs_chaos_troll = "chaos_troll",
	vs_gutter_runner = "skaven_gutter_runner",
	vs_packmaster = "skaven_pack_master",
	vs_poison_wind_globadier = "skaven_poison_wind_globadier",
	vs_ratling_gunner = "skaven_gutter_runner",
	vs_warpfire_thrower = "skaven_warpfire_thrower",
}
GameModeSettings.versus.party_fill_method = {
	distribute_party_even = "distribute_party_even",
	fill_first_party = "fill_first_party",
}
GameModeSettings.versus.fill_party_distribution = "distribute_party_even"
GameModeSettings.versus.dark_pact_profile_rules = {
	all = 10,
}
GameModeSettings.versus.dark_pact_picking_rules = {
	special_pick_options = 2,
}
GameModeSettings.versus.duplicate_hero_profiles_allowed = false
GameModeSettings.versus.duplicate_hero_careers_allowed = false
GameModeSettings.versus.allow_hotjoining_ongoing_game = true	
GameModeSettings.versus.allowed_hotjoin_states = table.set({
	"match_running_state",
	"pre_start_round_state",
	"party_lobby",
	"dedicated_server_waiting_for_fully_reserved",
})
GameModeSettings.versus.disable_host_migration = true
GameModeSettings.versus.shuffle_character_picking_order = "players_first"
GameModeSettings.versus.character_picking_settings = {
	closing_time = 2,
	parading_duration = 5,
	player_pick_time = 5,
	startup_time = 5,
}
GameModeSettings.versus.display_end_of_match_score_view = true
GameModeSettings.versus.end_of_match_view_display_screen_delay = 3
GameModeSettings.versus.display_parading_view = true
GameModeSettings.versus.parading_times = {
	local_player = 5,
	opponent_transition = 5,
	show_match_info = 4,
	team_transition = 0.5,
}
GameModeSettings.versus.party_names_lookup_by_id = {
	[0] = "undecided",
	"team_hammers",
	"team_skulls",
}
GameModeSettings.versus.pre_start_round_duration = 30
GameModeSettings.versus.initial_set_pre_start_duration = 45
GameModeSettings.versus.side_settings = {
	heroes = {
		observe_sides = {
			heroes = function ()
				return true
			end,
			dark_pact = function ()
				return false
			end,
		},
		spawn_at_players_on_side = {},
	},
	dark_pact = {
		observe_sides = {
			heroes = function ()
				return true
			end,
			dark_pact = function ()
				return true
			end,
		},
		spawn_at_players_on_side = {
			heroes = function ()
				return Managers.state.game_mode:is_round_started()
			end,
			dark_pact = function ()
				return true
			end,
		},
		allowed_interactions = {
			ghost_mode = {
				carousel_dark_pact_climb = true,
				carousel_dark_pact_spawner = true,
				carousel_dark_pact_tunnel = true,
				no_interaction_hud_only = true,
			},
			normal = {
				carousel_dark_pact_climb = true,
				carousel_dark_pact_tunnel = true,
				door = true,
				no_interaction_hud_only = true,
			},
		},
		spawn_times = {
			delayed_death_time = 2, -- 5
		},
	},
	spectators = {
		observe_sides = {
			heroes = function ()
				return true
			end,
			dark_pact = function ()
				return true
			end,
		},
	},
}
GameModeSettings.versus.dark_pact_minimum_spawn_time = 2.5

local death_time = GameModeSettings.versus.side_settings.dark_pact.spawn_times.delayed_death_time

GameModeSettings.versus.dark_pact_respawn_timers = {
	{
		max = 1,
		min = 1,
	},
	{
		max = 3,
		min = 3,
	},
	{
		max = 10, -- 14
		min = 6, -- 8
	},
	{
		max = 15, -- 20
		min = 9, -- 12
	},
}
GameModeSettings.versus.dark_pact_bot_respawn_timers = {
	[0] = 0,
	0,
	5,
	10,
	30,
}
GameModeSettings.versus.dark_pact_catch_up_distance = 40
GameModeSettings.versus.dark_pact_minimum_spawn_distance = 10
GameModeSettings.versus.boss_minimum_spawn_distance = 20
GameModeSettings.versus.dark_pact_minimum_spawn_distance_vertical = 3.5
GameModeSettings.versus.forced_difficulty = "versus_base"
GameModeSettings.versus.difficulties = {}
GameModeSettings.versus.power_level_override = 300
GameModeSettings.versus.additional_game_end_reasons = {
	"round_end",
	"party_one_won",
	"party_two_won",
	"party_one_won_early",
	"party_two_won_early",
	"draw",
}
GameModeSettings.versus.disable_achievements = true
GameModeSettings.versus.use_level_jumps = true
GameModeSettings.versus.hide_level_jumps = false
GameModeSettings.versus.show_selected_jump = true
GameModeSettings.versus.specified_pickups = true
GameModeSettings.versus.use_keep_decorations = false
GameModeSettings.versus.round_almost_over_time_breakpoint = 30
GameModeSettings.versus.distance_to_winning_objective_breakpoint = 20
GameModeSettings.versus.max_num_players = 8

GameModeSettings.versus.party_settings = {
	heroes = {
		game_participating = true,
		name = "heroes",
		num_slots = 4,
		party_id = 1,
		using_bots = true,
		tags = {
			heroes = true,
		},
		party_relations = {
			enemy = {
				"dark_pact",
			},
		},
	},
	dark_pact = {
		game_participating = true,
		name = "dark_pact",
		num_slots = 4,
		party_id = 2,
		using_bots = false,
		tags = {
			dark_pact = true,
		},
		party_relations = {
			enemy = {
				"heroes",
			},
		},
	},
	spectators = {
		game_participating = false,
		name = "spectators",
		num_slots = 4,
		party_id = 3,
		using_bots = false,
		tags = {
			spectators = true,
		},
		party_relations = {},
	},
}
GameModeSettings.versus.game_mode_states = {
	"initial_state",
	"waiting_for_players_to_join",
	"dedicated_server_abort_game",
	"character_selection_state",
	"player_team_parading_state",
	"pre_start_round_state",
	"match_running_state",
	"post_round_state",
}
GameModeSettings.versus.experience = {
	challenges = 0,
	complete_match = 0,
	first_win_of_the_day = 0,
	hero_kills = 0,
	lose_match = 0,
	rounds_played = 0,
	special_kills = 0,
	win_match = 0,
}

-- Special bot timers
SpecialsSettings.default.max_specials = 3
SpecialsSettings.default.spawn_method = "specials_by_slots"
SpecialsSettings.default.methods = {}
SpecialsSettings.default.methods.specials_by_slots = {
	max_of_same = 2,
	coordinated_attack_cooldown_multiplier = 0.5,
	chance_of_coordinated_attack = 0.5,
	select_next_breed = "get_random_breed",
	after_safe_zone_delay = {
		5,
		20
	},
	spawn_cooldown = {
		12, -- 32
		15 -- 60
	}
}
local default_override = table.clone(SpecialsSettings.default)
SpecialsSettings.default.difficulty_overrides.versus_base = default_override
table.merge_recursive(SpecialsSettings.default_light, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.skaven, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.skaven_light, SpecialsSettings.skaven)
table.merge_recursive(SpecialsSettings.chaos, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.chaos_light, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.beastmen, SpecialsSettings.default)

-- Horde abilities
local settings = require("scripts/settings/versus_horde_ability_settings")
settings.cooldown = 60 -- 300
settings.enable_activation_in_ghost_mode = false -- true

-- Ambience
PackSpawningSettings.default.area_density_coefficient = 0.165
PackSpawningSettings.default_light.area_density_coefficient = 0.165
PackSpawningSettings.skaven.area_density_coefficient = 0.165
PackSpawningSettings.skaven_light.area_density_coefficient = 0.165
PackSpawningSettings.chaos.area_density_coefficient = 0.165
PackSpawningSettings.chaos_light.area_density_coefficient = 0.165
PackSpawningSettings.beastmen.area_density_coefficient = 0.165
PackSpawningSettings.beastmen_light.area_density_coefficient = 0.165
PackSpawningSettings.skaven_beastmen.area_density_coefficient = 0.165
PackSpawningSettings.chaos_beastmen.area_density_coefficient = 0.165

PackSpawningSettings.default.difficulty_overrides = nil
PackSpawningSettings.skaven.difficulty_overrides = nil
PackSpawningSettings.skaven_light.difficulty_overrides = nil
PackSpawningSettings.chaos.difficulty_overrides = nil
PackSpawningSettings.beastmen.difficulty_overrides = nil
PackSpawningSettings.skaven_beastmen.difficulty_overrides = nil
PackSpawningSettings.chaos_beastmen.difficulty_overrides = nil

-- Weapons
-- Fireball QQ back to official
Weapons.staff_fireball_fireball_template_1_vs.actions.action_one.default.allowed_chain_actions = {
	{
		action = "action_wield",
		input = "action_wield",
		start_time = 0.3,
		sub_action = "default",
	},
	{
		action = "action_one",
		input = "action_one",
		release_required = "action_one_hold",
		start_time = 0.75,
		sub_action = "default",
	},
	{
		action = "action_two",
		input = "action_two_hold",
		start_time = 0.6,
		sub_action = "default",
	},
	{
		action = "weapon_reload",
		input = "weapon_reload",
		start_time = 0.3,
		sub_action = "default",
	},
}


mod:echo("VERSUS TWEAKS")
