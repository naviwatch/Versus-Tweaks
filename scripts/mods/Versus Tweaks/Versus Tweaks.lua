local mod = get_mod("Versus Tweaks")

-- Text Localization
local _language_id = Application.user_setting("language_id")
local _localization_database = {}
local buff_perks = require("scripts/unit_extensions/default_player_unit/buffs/settings/buff_perk_names")

mod._quick_localize = function (self, text_id)
    local mod_localization_table = _localization_database
    if mod_localization_table then
        local text_translations = mod_localization_table[text_id]
        if text_translations then
            return text_translations[_language_id] or text_translations["en"]
        end
    end
end
mod:hook("Localize", function(func, text_id)
    local str = mod:_quick_localize(text_id)
    if str then return str end
    return func(text_id)
end)
function mod.add_text(self, text_id, text)
    if type(text) == "table" then
        _localization_database[text_id] = text
    else
        _localization_database[text_id] = {
            en = text
        }
    end
end
function mod.add_talent_text(self, talent_name, name, description)
    mod:add_text(talent_name, name)
    mod:add_text(talent_name .. "_desc", description)
end

-- Buff and Talent Functions
local function is_local(unit)
	local player = Managers.player:owner(unit)

	return player and not player.remote
end
local function merge(dst, src)
    for k, v in pairs(src) do
        dst[k] = v
    end
    return dst
end
function is_at_inn()
    local game_mode = Managers.state.game_mode
    if not game_mode then return nil end
    return game_mode:game_mode_key() == "inn"
end
function mod.modify_talent_buff_template(self, hero_name, buff_name, buff_data, extra_data)   
    local new_talent_buff = {
        buffs = {
            merge({ name = buff_name }, buff_data),
        },
    }
    if extra_data then
        new_talent_buff = merge(new_talent_buff, extra_data)
    elseif type(buff_data[1]) == "table" then
        new_talent_buff = {
            buffs = buff_data,
        }
        if new_talent_buff.buffs[1].name == nil then
            new_talent_buff.buffs[1].name = buff_name
        end
    end

    local original_buff = TalentBuffTemplates[hero_name][buff_name]
    local merged_buff = original_buff
    for i=1, #original_buff.buffs do
        if new_talent_buff.buffs[i] then
            merged_buff.buffs[i] = merge(original_buff.buffs[i], new_talent_buff.buffs[i])
        elseif original_buff[i] then
            merged_buff.buffs[i] = merge(original_buff.buffs[i], new_talent_buff.buffs)
        else
            merged_buff.buffs = merge(original_buff.buffs, new_talent_buff.buffs)
        end
    end

    TalentBuffTemplates[hero_name][buff_name] = merged_buff
    BuffTemplates[buff_name] = merged_buff
end
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end
function mod.set_talent(self, career_name, tier, index, talent_name, talent_data)
    local career_settings = CareerSettings[career_name]
    local hero_name = career_settings.profile_name
    local talent_tree_index = career_settings.talent_tree_index
    
    local talent_lookup = TalentIDLookup[talent_name]
    local talent_id
    if talent_lookup == nil then
        talent_id = #Talents[hero_name] + 1
    else
        talent_id = talent_lookup.talent_id
    end

    Talents[hero_name][talent_id] = merge({
        name = talent_name,
        description = talent_name .. "_desc",
        icon = "icons_placeholder",
        num_ranks = 1,
        buffer = "both",
        requirements = {},
        description_values = {},
        buffs = {},
        buff_data = {},
    }, talent_data)
    TalentTrees[hero_name][talent_tree_index][tier][index] = talent_name
    TalentIDLookup[talent_name] = {
        talent_id = talent_id,
        hero_name = hero_name
    }
    -- mod:echo("-----------------------")
    -- mod:echo("Buff: " .. dump(talent_data.buffs))
    -- mod:echo("Talent lookup for " .. hero_name .. ": " .. talent_name .. " => " .. talent_id)
end
function mod.add_talent(self, career_name, tier, index, new_talent_name, new_talent_data)
    local career_settings = CareerSettings[career_name]
    local hero_name = career_settings.profile_name
    local talent_tree_index = career_settings.talent_tree_index
  
    local new_talent_index = #Talents[hero_name] + 1

    Talents[hero_name][new_talent_index] = merge({
        name = new_talent_name,
        description = new_talent_name .. "_desc",
        icon = "icons_placeholder",
        num_ranks = 1,
        buffer = "both",
        requirements = {},
        description_values = {},
        buffs = {},
        buff_data = {},
    }, new_talent_data)

    TalentTrees[hero_name][talent_tree_index][tier][index] = new_talent_name
    TalentIDLookup[new_talent_name] = {
        talent_id = new_talent_index,
        hero_name = hero_name
    }
end
function mod.modify_talent(self, career_name, tier, index, new_talent_data)
    local career_settings = CareerSettings[career_name]
    local hero_name = career_settings.profile_name
    local talent_tree_index = career_settings.talent_tree_index

    local old_talent_name = TalentTrees[hero_name][talent_tree_index][tier][index]
    local old_talent_id_lookup = TalentIDLookup[old_talent_name]
    local old_talent_id = old_talent_id_lookup.talent_id
    local old_talent_data = Talents[hero_name][old_talent_id]

    Talents[hero_name][old_talent_id] = merge(old_talent_data, new_talent_data)
end
function mod.add_talent_buff_template(self, hero_name, buff_name, buff_data, extra_data)
    local new_talent_buff = {
        buffs = {
            merge({ name = buff_name }, buff_data),
        },
    }
    if extra_data then
        new_talent_buff = merge(new_talent_buff, extra_data)
    elseif type(buff_data[1]) == "table" then
        new_talent_buff = {
            buffs = buff_data,
        }
        if new_talent_buff.buffs[1].name == nil then
            new_talent_buff.buffs[1].name = buff_name
        end
    end
    TalentBuffTemplates[hero_name][buff_name] = new_talent_buff
    BuffTemplates[buff_name] = new_talent_buff
    local index = #NetworkLookup.buff_templates + 1
    NetworkLookup.buff_templates[index] = buff_name
    NetworkLookup.buff_templates[buff_name] = index
end
function mod.add_buff_template(self, buff_name, buff_data, extra_data)
    local new_buff = {
        buffs = {
            merge({ name = buff_name }, buff_data),
        },
    }
    if extra_data then
        new_buff = merge(new_buff, extra_data)
    end
    BuffTemplates[buff_name] = new_buff
    local index = #NetworkLookup.buff_templates + 1
    NetworkLookup.buff_templates[index] = buff_name
    NetworkLookup.buff_templates[buff_name] = index
end
function mod.add_buff(self, owner_unit, buff_name)
    if Managers.state.network ~= nil then
        local network_manager = Managers.state.network
        local network_transmit = network_manager.network_transmit

        local unit_object_id = network_manager:unit_game_object_id(owner_unit)
        local buff_template_name_id = NetworkLookup.buff_templates[buff_name]
        local is_server = Managers.player.is_server

        if is_server then
            local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")

            buff_extension:add_buff(buff_name)
            network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
        else
            network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
        end
    end
end
function mod.add_buff_function(self, name, func)
    BuffFunctionTemplates.functions[name] = func
end
function mod.add_proc_function(self, name, func)
    ProcFunctions[name] = func
end
function mod.add_explosion_template(self, explosion_name, data)
    ExplosionTemplates[explosion_name] = merge({ name = explosion_name}, data)
    local index = #NetworkLookup.explosion_templates + 1
    NetworkLookup.explosion_templates[index] = explosion_name
    NetworkLookup.explosion_templates[explosion_name] = index
end

-- Damage Profile Templates
NewDamageProfileTemplates = NewDamageProfileTemplates or {}

local function create_weights()
	local crash = nil

	for id, setting in pairs(PackSpawningSettings) do
		setting.name = id

		if not setting.disabled then
			roaming_set = setting.roaming_set
			roaming_set.name = id
			local weights = {}
			local breed_packs_override = roaming_set.breed_packs_override

			if breed_packs_override then
				for i = 1, #breed_packs_override, 1 do
					weights[i] = breed_packs_override[i][2]
				end

				roaming_set.breed_packs_override_loaded_dice = {
					LoadedDice.create(weights)
				}
			end
		end
	end

	-- Adjustment for the new difficulty system of horde compositions from 1.4 - I am not copypasting each composition 3 times. Or 4, doesn't matter.
	for event, composition in pairs(HordeCompositions) do
		if not composition[1][1] then
			local temp_table = table.clone(composition)
			table.clear_array(composition, #composition)
			composition[1] = temp_table
			composition[2] = temp_table
			composition[3] = temp_table
			composition[4] = temp_table
			composition[5] = temp_table
			composition[6] = temp_table
			composition[7] = temp_table
		elseif not composition[6] then
			composition[6] = composition[5]
			composition[7] = composition[5]
		end
	end

	local weights = {}
	local crash = nil

	for key, setting in pairs(HordeSettings) do
        setting.name = key

        if setting.compositions then
            for name, composition in pairs(setting.compositions) do
                for i = 1, #composition, 1 do
                    table.clear_array(weights, #weights)

                    local compositions = composition[i]

                    for j, variant in ipairs(compositions) do
                        weights[j] = variant.weight
                        local breeds = variant.breeds
                        
                        if breeds then
                            for k = 1, #breeds, 2 do
                                local breed_name = breeds[k]
                                local breed = Breeds[breed_name]

                                if not breed then
                                    print(string.format("Bad or non-existing breed in HordeCompositions table %s : '%s' defined in HordeCompositions.", name, tostring(breed_name)))

                                    crash = true
                                elseif not breed.can_use_horde_spawners then
                                    variant.must_use_hidden_spawners = true
                                end
                            end
                        end
                    end

                    compositions.loaded_probs = {
                        LoadedDice.create(weights)
                    }

                    fassert(not crash, "Found errors in HordeComposition table %s - see above. ", name)
                    fassert(compositions.loaded_probs, "Could not create horde composition probablitity table, make sure the table '%s' in HordeCompositions is correctly structured and has an entry for each difficulty.", name)
                end
            end
        end

		if setting.compositions_pacing then
			for name, composition in pairs(setting.compositions_pacing) do
				table.clear_array(weights, #weights)

				for i, variant in ipairs(composition) do
					weights[i] = variant.weight
					local breeds = variant.breeds

					for j = 1, #breeds, 2 do
						local breed_name = breeds[j]
						local breed = Breeds[breed_name]

						if not breed then
							print(string.format("Bad or non-existing breed in HordeCompositionsPacing table %s : '%s' defined in HordeCompositionsPacing.", name, tostring(breed_name)))

							crash = true
						elseif not breed.can_use_horde_spawners then
							variant.must_use_hidden_spawners = true
						end
					end
				end

				composition.loaded_probs = {
					LoadedDice.create(weights)
				}

				fassert(not crash, "Found errors in HordeCompositionsPacing table %s - see above. ", name)
				fassert(composition.loaded_probs, "Could not create horde composition probablitity table, make sure the table '%s' in HordeCompositionsPacing is correctly structured.", name)
			end
		end
	end
end

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
GameModeSettings.versus.max_num_rewards_displayed = 0
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
	heroes = 2,
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
GameModeSettings.versus.pre_start_round_duration = 15
GameModeSettings.versus.initial_set_pre_start_duration = 20
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
GameModeSettings.versus.dark_pact_minimum_spawn_time = 0

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
	10,
}
GameModeSettings.versus.dark_pact_catch_up_distance = 40
GameModeSettings.versus.dark_pact_minimum_spawn_distance = 10
GameModeSettings.versus.boss_minimum_spawn_distance = 20
GameModeSettings.versus.dark_pact_minimum_spawn_distance_vertical = 3.5
GameModeSettings.versus.forced_difficulty = "versus_base"
GameModeSettings.versus.difficulties = {}
GameModeSettings.versus.power_level_override = 300
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

------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------

-- Special bot timers
SpecialsSettings.default.max_specials = 4
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
		10, -- 32
		15 -- 60
	}
}
local default_override = table.clone(SpecialsSettings.default)
SpecialsSettings.default.difficulty_overrides.hard = default_override
SpecialsSettings.default.difficulty_overrides.harder = default_override
SpecialsSettings.default.difficulty_overrides.hardest = default_override
SpecialsSettings.default.difficulty_overrides.cataclysm = default_override
SpecialsSettings.default.difficulty_overrides.cataclysm_2 = default_override
SpecialsSettings.default.difficulty_overrides.cataclysm_3 = default_override
SpecialsSettings.default.difficulty_overrides.versus_base = default_override

table.merge_recursive(SpecialsSettings.default_light, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.skaven, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.skaven_light, SpecialsSettings.skaven)
table.merge_recursive(SpecialsSettings.chaos, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.chaos_light, SpecialsSettings.default)
table.merge_recursive(SpecialsSettings.beastmen, SpecialsSettings.default)
mod:echo("Done")

-- Threat values to prevent stuff from NOT spawning
PacingSettings.default.delay_horde_threat_value.versus_base = 100
PacingSettings.default.delay_specials_threat_value.versus_base = math.huge
PacingSettings.chaos.delay_horde_threat_value.versus_base = 100
PacingSettings.chaos.delay_specials_threat_value.versus_base = math.huge

-- Manual no beastmen
DefaultConflictDirectorSet = {
	"skaven",
	"chaos",
	"default"
}

-- Player breed tweaks
-- Fix max stagger duration not applying, gas and hook not given for balancing purposes 
PlayerBreeds.vs_warpfire_thrower.max_stagger_duration = 0.4
PlayerBreeds.vs_ratling_gunner.max_stagger_duration = 0.4

-- Warpfire
PlayerBreeds.vs_warpfire_thrower.shoot_warpfire_attack_range = 15 -- 10
PlayerBreeds.vs_warpfire_thrower.shoot_warpfire_close_attack_range = 12 -- 7

-- Horde abilities
local settings = require("scripts/settings/versus_horde_ability_settings")
settings.cooldown = 150 -- 300
settings.max_num_horde_units_per_player = 50	
settings.team_size_difference_recharge_modifier = {
	[0] = 1, -- 4
	1.75, -- 3
	2.75, -- 2 
	3.75, -- 1 person
}
settings.enable_activation_in_ghost_mode = false -- true
settings.recharge_boosts = {
	actions = {
		gutter_runner_pinned = 6,
		hero_downed = 10,
		pack_master_grab = 6,
		pack_master_hoist = 24,
	},
	damage_sources = {
		vomit_face = 1.4,
		vs_chaos_troll_axe = 0.4,
		vs_gutter_runner = 1.2,
		vs_packmaster = 1.2,
		vs_poison_wind_globadier = 1,
		vs_ratling_gunner_gun = 0.35,
		vs_warpfire_thrower = 0.35, -- 0.15
	}
}

-- New breed packs for suffering
mod:dofile("scripts/mods/Versus Tweaks/breed_pack_linesman")

PackSpawningSettings.default.roaming_set = {
	breed_packs = "dense_standard",
	breed_packs_peeks_overide_chance = {
		0.3,
		0.4
	},
	breed_packs_override = {
		{
			"skaven",
			4,
			0.035
		},
		{
			"plague_monks",
			2,
			0.035
		},
		{
			"marauders",
			4,
			0.03
		},
		{
			"marauders_elites",
			2,
			0.03
		}
	}
}

PackSpawningSettings.skaven.roaming_set = {
	breed_packs = "dense_skaven",
	breed_packs_peeks_overide_chance = {
		0.3,
		0.4
	},
	breed_packs_override = {
		{
			"skaven",
			4,
			0.035
		},
		{
			"shield_rats",
			2,
			0.035
		},
		{
			"plague_monks",
			2,
			0.035
		}
	}
}

PackSpawningSettings.chaos.roaming_set = {
	breed_packs = "dense_chaos",
	breed_packs_peeks_overide_chance = {
		0.3,
		0.4
	},
	breed_packs_override = {
		{
			"marauders_and_warriors",
			4,
			0.03
		},
		{
			"marauders_shields",
			2,
			0.03
		},
		{
			"marauders_elites",
			2,
			0.03
		},
		{
			"marauders_berzerkers",
			2,
			0.03
		}
	}
}

-- Ambience
local co = 0.12
PackSpawningSettings.default.area_density_coefficient = co
PackSpawningSettings.default_light.area_density_coefficient = co
PackSpawningSettings.skaven.area_density_coefficient = co
PackSpawningSettings.skaven_light.area_density_coefficient = co
PackSpawningSettings.chaos.area_density_coefficient = co
PackSpawningSettings.chaos_light.area_density_coefficient = co
PackSpawningSettings.beastmen.area_density_coefficient = co
PackSpawningSettings.beastmen_light.area_density_coefficient = co
PackSpawningSettings.skaven_beastmen.area_density_coefficient = co
PackSpawningSettings.chaos_beastmen.area_density_coefficient = co

PackSpawningSettings.default.difficulty_overrides = nil
PackSpawningSettings.skaven.difficulty_overrides = nil
PackSpawningSettings.skaven_light.difficulty_overrides = nil
PackSpawningSettings.chaos.difficulty_overrides = nil
PackSpawningSettings.beastmen.difficulty_overrides = nil
PackSpawningSettings.skaven_beastmen.difficulty_overrides = nil
PackSpawningSettings.chaos_beastmen.difficulty_overrides = nil

-- Horde ability comp shit
HordeCompositions.versus_horde_ability_skaven = {
	{
		{
			name = "horde_ability",
			weight = 3,
			breeds = {
				"skaven_plague_monk",
				3,
				"skaven_slave",
				5,
				"skaven_clan_rat",
				10,
				"skaven_storm_vermin_commander",
				2,
			},
		},
		{
			name = "horde_ability",
			weight = 3,
			breeds = {
				"skaven_storm_vermin_commander",
				3,
				"skaven_slave",
				5,
				"skaven_clan_rat",
				10,
				"skaven_plague_monk",
				2,
			},
		},
	},
}

HordeCompositions.versus_horde_ability_chaos = {
	{
		{
			name = "horde_ability",
			weight = 3,
			breeds = {
				"chaos_berzerker",
				3,
				"chaos_fanatic",
				5,
				"chaos_marauder",
				10,
				"chaos_raider",
				2,
				"chaos_warrior",
				1
			},
		},
		{
			name = "horde_ability",
			weight = 3,
			breeds = {
				"chaos_raider",
				3,
				"chaos_fanatic",
				5,
				"chaos_marauder",
				10,
				"chaos_berzerker",
				2,
				"chaos_warrior",
				1
			},
		},
	},
}

--------------------------------
--------------------------------
-------------------------------

--- Balancing
-- Unchained
PlayerCharacterStateOverchargeExploding.on_exit = function (self, unit, input, dt, context, t, next_state)
	if not Managers.state.network:game() or not next_state then
		return
	end

	CharacterStateHelper.play_animation_event(unit, "cooldown_end")
	CharacterStateHelper.play_animation_event_first_person(self.first_person_extension, "cooldown_end")

	local career_extension = ScriptUnit.extension(unit, "career_system")
	local career_name = career_extension:career_name()

	if self.falling and next_state ~= "falling" then
		ScriptUnit.extension(unit, "whereabouts_system"):set_no_landing()
	end
end

--Explosion kill credit fix
mod:hook_safe(PlayerProjectileHuskExtension, "init", function(self, extension_init_data)
    self.owner_unit = extension_init_data.owner_unit
end)

-- Huntsman
mod:add_proc_function("gs_heal_on_ranged_kill", function (owner_unit, buff, params)
	if not Managers.state.network.is_server then
			return
		end

	if ALIVE[owner_unit] then
		local killing_blow_data = params[1]

		if not killing_blow_data then
			return
		end

		local attack_type = killing_blow_data[DamageDataIndex.ATTACK_TYPE]

		if attack_type and (attack_type == "projectile" or attack_type == "instant_projectile") then
			local breed = params[2]

			if breed and breed.bloodlust_health and not breed.is_hero then
				local heal_amount = (breed.bloodlust_health * 0.25) or 0

				DamageUtils.heal_network(owner_unit, owner_unit, heal_amount, "heal_from_proc")
			end
		end
	end
end)
mod:modify_talent_buff_template("empire_soldier", "markus_huntsman_passive_temp_health_on_headshot", {
	mechanism_overrides = {
		versus = {
			bonus = nil,
			event = "on_kill",
			buff_func = "gs_heal_on_ranged_kill"
		}
	}
})

mod:modify_talent("es_huntsman", 4, 3, {
	mechanism_overrides = {
		versus = {
			description = "gs_hs_4_3_desc"
		}
	}
})
mod:add_text("gs_hs_4_3_desc", "Ranged kills restore thp equal to a quarter of bloodlust.")

-- Footknight
-- comrades 50% dr changed to 20% dr (overriding adventure)
mod:modify_talent_buff_template("empire_soldier", "markus_knight_guard_defence_buff", {
    mechanism_overrides = {
		versus = {
			multiplier = -0.3,
		}
	}
})
mod:modify_talent("es_knight", 4, 3, {
	mechanism_overrides = {
		versus = {
			description_values = {
				{
					value_type = "percent",
					value = 0.1
				},
				{
					value_type = "percent",
					value = 0.3
				},
				{
					value_type = "percent",
					value = 0.1
				}
			},
		}
	}
})

-- numb to pain 1 sec instead of 3
mod:modify_talent_buff_template("empire_soldier", "markus_knight_ability_invulnerability_buff", {
    mechanism_overrides = {
		versus = {
			duration = 1,
		}
	}
})
mod:modify_talent("es_knight", 6, 1, {
	mechanism_overrides = {
		versus = {
			description_values = {
				{
					value = 1
				}
			},
		}
	}
})

-- Hero time 5s ICD
mod:add_buff_function("markus_hero_time_vt", function(unit, buff, params)
	local player_unit = unit

	if Unit.alive(player_unit) then
		local t = Managers.time:time("game")
		local cooldown_timer = buff.cooldown_timer

		if not cooldown_timer or cooldown_timer <= t then
			local template = buff.template
			local internal_cooldown = template.internal_cooldown
			local cooldown_removed = template.cooldown_reduction
			local career_extension = ScriptUnit.extension(owner_unit, "career_system")

			career_extension:reduce_activated_ability_cooldown_percent(cooldown_removed)

			buff.cooldown_timer = t + internal_cooldown
		end
	end
end)

mod:modify_talent_buff_template("empire_soldier", "markus_knight_movement_speed_on_incapacitated_allies_buff", {
	mechanism_overrides = {
		versus = {
			add_buff_func = "markus_hero_time_vt",
			cooldown_reduction = 1,
			internal_cooldown = 5
		}
	}
})

-- Bountyhunter
-- Salvaged ammo actually gives ammo on special and elite kill
mod:modify_talent_buff_template("witch_hunter", "victor_bountyhunter_restore_ammo_on_elite_kill", {
	mechanism_overrides = {
		versus = {
			event = "on_kill_elite_special"
		}
	}
})

-- Ironbreaker
mod:modify_talent_buff_template("dwarf_ranger", "bardin_ironbreaker_gromril_delay_short", {
	mechanism_overrides = {
		versus = {
			duration = 20
		}
	}
})

-- WP
DLCSettings.bless.buff_templates.victor_priest_nuke_dot.buffs[1].mechanism_overrides.versus = {
    damage_profile = "victor_priest_nuke_dot_vs",
    duration = 1.5, -- 5
    time_between_dot_damages = 1, -- 0.7
    update_start_delay = 1 -- 0.7
}
DamageProfileTemplates.victor_priest_nuke_dot_vs.armor_modifier.attack[3] = 1.0



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

create_weights()

mod:echo("VERSUS TWEAKS v0.2")

