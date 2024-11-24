local mod = get_mod("Versus Tweaks")

-- Functions for applying BreedPacks

mod.continue_when_condition_chaos = function(threshold, time)
	return {
		"continue_when",
		duration = time,
		condition = function (t)
			return count_event_breed("chaos_berzerker") < threshold and count_event_breed("chaos_raider") < threshold and (count_event_breed("chaos_marauder") + count_event_breed("chaos_marauder_with_shield")) < 2*threshold and count_event_breed("chaos_fanatic") < 2*threshold and count_event_breed("chaos_warrior") < threshold
		end
	}
end

mod.continue_when_condition_skaven = function(threshold, time)
	return {
		"continue_when",
		duration = time,
		condition = function (t)
			return count_event_breed("chaos_berzerker") < threshold and count_event_breed("chaos_raider") < threshold and (count_event_breed("chaos_marauder") + count_event_breed("chaos_marauder_with_shield")) < 2*threshold and count_event_breed("chaos_fanatic") < 2*threshold and count_event_breed("chaos_warrior") < threshold
		end
	}
end

mod.calculate_breed_pack_weights = function(scaling_data, breed_packs)
	local weighted_packs = {}
	for _, pack in pairs(breed_packs) do -- Select a Pack
		for breed_name, breed_table in pairs(pack.members) do -- Iterate through Pack Members
			for _, scale_data in pairs(scaling_data) do -- Iterate through classes of enemies.
				for _, scale_breed_name in pairs(scale_data.breeds) do  -- On a selected class, check each breed
					if string.find(tostring(breed_name), scale_breed_name) then -- If the breed is in the breed class:
						pack.spawn_weight = pack.spawn_weight + scale_data.scale_factor
					end
				end
			end
		end
		table.insert(weighted_packs,pack)
	end
	return weighted_packs
end

function scale_horde_composition(HordeCompositions,faction,scaling_data)
	for horde_name, horde_comp_data in pairs(HordeCompositions) do
		local isfaction = false
		if string.find(tostring(horde_name), faction) then
			for sub_var_name, horde_subvariant in pairs(horde_comp_data) do
				for value, more_data in pairs(horde_subvariant) do
					if value == "breeds" then
						for breed_index,breed_data in pairs(more_data) do
							if type(breed_data) == "table" then
								local name_of_enemy = tostring(more_data[breed_index-1])
								for i,enemy_count in pairs(breed_data) do
									if type(enemy_count) == "number" then
										for _, scaling_data in pairs(scaling_data) do 
											for _, enemy_name in pairs(scaling_data.breeds) do 
												if name_of_enemy == enemy_name then -- If enemy name matches scaling factor name. Apply scaling.
													breed_data[i] = math.floor(enemy_count * scaling_data.scale_factor)
													if breed_data[i] == 0 then
														breed_data[i] = 1
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

mod.is_mod_mutator_enabled = function(mod_name, mutator_name)
	local other_mod = get_mod(mod_name)
	local mod_is_enabled = false
	local mutator_is_enabled = false
	if other_mod then
	  local omutator = other_mod:persistent_table(mutator_name)
	  mod_is_enabled = other_mod:is_enabled()
	  mutator_is_enabled = omutator.active
	end
	return mod_is_enabled and mutator_is_enabled
end

-- Functions for applying BreedPacks

mod.calc_num_in_packs = function(breed_packs, roaming_set_name)
	local num_breed_packs = #breed_packs

	for i = 1, num_breed_packs do
		local pack = breed_packs[i]
		local size = #pack.members

		fassert(InterestPointUnits[size], "The %d pack in BreedPacks[%s] is of size %d. There are no InterestPointUnits matching this size.", i, roaming_set_name, size)

		pack.members_n = size
	end

	return num_breed_packs
end

mod.generate_breed_pack_by_size = function(breed_packs, roaming_set_name)
	local num_breed_packs = mod.calc_num_in_packs(breed_packs, roaming_set_name)

	assert("BreedPack of size have no matching interestpoint of that size.")

	local breed_pack_by_size = {}
	local by_size = {}

	for i = 1, num_breed_packs do
		local pack = breed_packs[i]
		local size = pack.members_n

		if not by_size[size] then
			by_size[size] = {
				packs = {},
				weights = {}
			}
		end

		local slot = by_size[size]
		local packs = slot.packs
		packs[#packs + 1] = pack
		slot.weights[#slot.weights + 1] = pack.spawn_weight
	end

	for size, slot in pairs(by_size) do
		local prob, alias = LoadedDice.create(slot.weights, false)
		breed_pack_by_size[size] = {
			packs = slot.packs,
			prob = prob,
			alias = alias
		}
	end

	return breed_pack_by_size
end

mod.get_with_override = function(settings, key, difficulty, fallback_difficulty)
	local overrides = settings.difficulty_overrides
	local override_settings = overrides and (overrides[difficulty] or overrides[fallback_difficulty])

	return override_settings and override_settings[key] or settings[key]
end

mod.add_breeds_from_breed_packs = function(breed_packs, difficulty, output)
	return
end


mod.add_breeds_from_special_settings = function(special_settings, difficulty, fallback_difficulty, output)
	local breeds = mod.get_with_override(special_settings, "breeds", difficulty, fallback_difficulty)

	for i = 1, #breeds do
		local breed_name = breeds[i]
		output[breed_name] = true
	end

	local rush_intervention = mod.get_with_override(special_settings, "rush_intervention", difficulty, fallback_difficulty)
	local rush_intervention_breeds = rush_intervention.breeds

	for i = 1, #rush_intervention_breeds do
		local breed_name = rush_intervention_breeds[i]
		output[breed_name] = true
	end

	local speed_running_intervention = mod.get_with_override(special_settings, "speed_running_intervention", difficulty, fallback_difficulty) or SpecialsSettings.default.speed_running_intervention
	local speed_running_intervention_breeds = speed_running_intervention.breeds

	for i = 1, #speed_running_intervention_breeds do
		local breed_name = speed_running_intervention_breeds[i]
		output[breed_name] = true
	end

	local speed_running_intervention_vector_horde_breeds = speed_running_intervention.vector_horde_breeds

	for i = 1, #speed_running_intervention_vector_horde_breeds do
		local breed_name = speed_running_intervention_vector_horde_breeds[i]
		output[breed_name] = true
	end
	
end

mod.add_breeds_from_pack_spawning_settings = function(pack_spawning_settings, difficulty, fallback_difficulty, output)
	local roaming_set = mod.get_with_override(pack_spawning_settings, "roaming_set", difficulty, fallback_difficulty)
	local breed_packs_name = roaming_set.breed_packs
	local breed_packs = BreedPacks[breed_packs_name]

	mod.add_breeds_from_breed_packs(breed_packs, difficulty, output)

	local PACK_OVERRIDE_BREED_INDEX = 1
	local breed_packs_override = roaming_set.breed_packs_override

	for i = 1, #breed_packs_override do
		local pack_override_data = breed_packs_override[i]
		local pack_override_name = pack_override_data[PACK_OVERRIDE_BREED_INDEX]
		local pack_override = BreedPacks[pack_override_name]

		mod.add_breeds_from_breed_packs(pack_override, difficulty, output)
	end
end

mod.add_breeds_from_boss_settings = function(boss_settings, difficulty, fallback_difficulty, output)
	local difficulty_rank = DifficultySettings[difficulty].rank

	for key, _ in pairs(boss_settings) do
		local settings = mod.get_with_override(boss_settings, key, difficulty, fallback_difficulty)

		if type(settings) == "table" then
			local event_lookup = settings.event_lookup

			for _, lookup in pairs(event_lookup) do
				for i = 1, #lookup do
					local event_name = lookup[i]
					local terror_event_lookup = GenericTerrorEvents
					local event = terror_event_lookup[event_name]

					ConflictUtils.add_breeds_from_event(event_name, event, difficulty, difficulty_rank, output, terror_event_lookup)
				end
			end
		end
	end
end

mod.add_breeds_from_horde_settings = function(horde_settings, difficulty, fallback_difficulty, output)
	return
end

mod.ConflictUtils_find_conflict_director_breeds = function (conflict_director, difficulty, output)
	local fallback_difficulty = DifficultySettings[difficulty].fallback_difficulty

	--[[
	if not conflict_director.boss.disabled then
		mod.add_breeds_from_boss_settings(conflict_director.boss, difficulty, fallback_difficulty, output)
	end
	--]]

	if not conflict_director.specials.disabled then
		mod.add_breeds_from_special_settings(conflict_director.specials, difficulty, fallback_difficulty, output)
	end

	--[[
	if not conflict_director.pack_spawning.disabled then
		mod.add_breeds_from_pack_spawning_settings(conflict_director.pack_spawning, difficulty, fallback_difficulty, output)
	end
	--]]

	--[[
	if not conflict_director.horde.disabled then
		mod.add_breeds_from_horde_settings(conflict_director.horde, difficulty, fallback_difficulty, output)
	end
	--]]

	return output
end

-- Apply them proper
local difficulties = Difficulties
local start_time = os.clock()
for conflict_director_name, data in pairs(ConflictDirectors) do
    data.name = conflict_director_name
    data.contained_breeds = {}

    for i = 1, #difficulties do
        local difficulty = difficulties[i]
        local difficulty_breeds = {}

        mod.ConflictUtils_find_conflict_director_breeds(data, difficulty, difficulty_breeds)

        data.contained_breeds[difficulty] = difficulty_breeds
    end
end

local trash_weight = 1.4
local shielded_trash_weight = 0.5
local elite_weight = 1
local shielded_elite_weight = 0.4
local berzerker_weight = 1.2
local super_armor_weight = 0.25

local trash_entities = {"beastmen_ungor","beastmen_gor","skaven_slave","skaven_clan_rat","chaos_fanatic","chaos_marauder"}
local shielded_trash_entities = {"chaos_marauder_with_shield","skaven_clan_rat_with_shield"}
local elite_entities = {"beastmen_bestigor","chaos_raider","skaven_storm_vermin_commander","skaven_storm_vermin_with_shield"}
local shielded_elite_entities = {"skaven_storm_vermin_with_shield"}
local berzerker_entities = {"chaos_berzerker","skaven_plague_monk"}
local super_armor_entities = {"chaos_warrior","skaven_storm_vermin"}

local scaling_data = {
{
	scale_factor = trash_weight,
	breeds = trash_entities,
},
{
	scale_factor = shielded_trash_weight,
	breeds = shielded_trash_entities,
},
{
	scale_factor = elite_weight,
	breeds = elite_entities,
},
{
	scale_factor = shielded_elite_weight,
	breeds = shielded_elite_entities,
},
{
	scale_factor = berzerker_weight,
	breeds = berzerker_entities,
},
{
	scale_factor = super_armor_weight,
	breeds = super_armor_entities,
}
}

dense_standard = {
	-- Size 1 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_storm_vermin_commander
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_raider
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_berzerker
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_plague_monk
		}
	},
	-- Size 2 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	-- 3 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_berzerker
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	-- 4 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	-- 6 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	-- 8 Enemy Breed Packs (double 4 enemy packs)
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_loot_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.skaven_loot_rat,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	}
}

dense_skaven = {
	-- Size 1 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_storm_vermin_commander
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_plague_monk
		}
	},
	-- Size 2 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},	
	-- 3 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	-- 4 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	-- 6 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	-- 8 Enemy Breed Packs (double 4 enemy packs)
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_loot_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	}
}

dense_chaos = {
	-- Size 1 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_raider
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_berzerker
		}
	},
	-- Size 2 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_berzerker
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_raider
		}
	},
	-- 3 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat,
			Breeds.skaven_clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.skaven_plague_monk,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_berzerker
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},	-- 4 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},	-- 6 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_warrior,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder
		}
	},
	-- 8 Enemy Breed Packs (double 4 enemy packs)
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_raider,
			Breeds.chaos_raider,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_warrior,
			Breeds.chaos_raider,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.skaven_loot_rat,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield,
			Breeds.chaos_marauder_with_shield
		}
	}
}

dense_beastmen = {
	-- Size 1 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.beastmen_bestigor
		}
	},
	{
		spawn_weight = 0,
		members_n = 1,
		members = {
			Breeds.chaos_berzerker
		}
	},
	-- Size 2 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 2,
		members = {
			Breeds.chaos_berzerker,
			Breeds.skaven_clan_rat_with_shield
		}
	},	
	-- 3 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.beastmen_gor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.beastmen_gor,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_raider,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_berzerker,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_gor
		}
	},
	{
		spawn_weight = 0,
		members_n = 3,
		members = {
			Breeds.chaos_berzerker,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor
		}
	},
	-- 4 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_gor,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_gor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.beastmen_bestigor,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.clan_rat
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.chaos_berzerker,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.chaos_berzerker,
			Breeds.chaos_marauder,
			Breeds.skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.skaven_storm_vermin,
			Breeds.chaos_marauder,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_gor,
			Breeds.skaven_skaven_clan_rat_with_shield
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 4,
		members = {
			Breeds.chaos_berzerker,
			Breeds.skaven_plague_monk,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor
		}
	},
	-- 6 Enemy Packs
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.skaven_clan_rat,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.chaos_warrior,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.chaos_marauder,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.chaos_warrior,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.skaven_skaven_clan_rat_with_shield,
			Breeds.beastmen_ungor_archer,
			Breeds.chaos_marauder
		}
	},
	{
		spawn_weight = 0,
		members_n = 6,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.skaven_skaven_clan_rat_with_shield,
			Breeds.skaven_skaven_clan_rat_with_shield,
			Breeds.beastmen_bestigor,
			Breeds.skaven_skaven_clan_rat_with_shield
		}
	},
	-- 8 Enemy Breed Packs (double 4 enemy packs)
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_gor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_gor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_with_shield,
			Breeds.chaos_warrior,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin_commander,
			Breeds.skaven_storm_vermin,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor_archer,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.skaven_storm_vermin,
			Breeds.skaven_storm_vermin,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.chaos_berzerker,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor,
			Breeds.beastmen_gor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.skaven_skaven_clan_rat_with_shield,
			Breeds.skaven_skaven_clan_rat_with_shield,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_loot_rat,
			Breeds.beastmen_ungor_archer,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	},
	{
		spawn_weight = 0,
		members_n = 8,
		members = {
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.beastmen_bestigor,
			Breeds.skaven_clan_rat_with_shield,
			Breeds.skaven_loot_rat,
			Breeds.beastmen_ungor_archer,
			Breeds.beastmen_ungor,
			Breeds.beastmen_ungor
		}
	}
}

dense_standard = mod.calculate_breed_pack_weights(scaling_data, dense_standard)
dense_chaos = mod.calculate_breed_pack_weights(scaling_data, dense_chaos)
dense_skaven = mod.calculate_breed_pack_weights(scaling_data, dense_skaven)
dense_beastmen = mod.calculate_breed_pack_weights(scaling_data, dense_beastmen)

dense_standard.roof_spawning_allowed = BreedPacks.standard.roof_spawning_allowed
dense_standard.patrol_overrides = BreedPacks.standard.patrol_overrides
dense_skaven.roof_spawning_allowed = BreedPacks.skaven.roof_spawning_allowed
dense_skaven.patrol_overrides = BreedPacks.skaven.patrol_overrides
dense_chaos.roof_spawning_allowed = BreedPacks.marauders_elites.roof_spawning_allowed
dense_chaos.patrol_overrides = BreedPacks.marauders_elites.patrol_overrides
dense_beastmen.roof_spawning_allowed = BreedPacks.chaos_beastmen.roof_spawning_allowed
dense_beastmen.patrol_overrides = BreedPacks.chaos_beastmen.patrol_overrides

BreedPacks.dense_standard = dense_standard
BreedPacks.dense_skaven = dense_skaven
BreedPacks.dense_chaos = dense_chaos
BreedPacks.dense_beastmen = dense_beastmen

BreedPacksBySize = {}

for roaming_set_name, breed_packs in pairs(BreedPacks) do
	BreedPacksBySize[roaming_set_name] = mod.generate_breed_pack_by_size(breed_packs, roaming_set_name)
end

