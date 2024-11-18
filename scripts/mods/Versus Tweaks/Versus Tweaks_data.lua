local mod = get_mod("Versus Tweaks")

local menu = {
	name = "Versus Tweaks",
	description = mod:localize("mod_description"),
	is_togglable = true,
}

menu.options = {}
menu.options.widgets = {
	{
		setting_id    = "player_bots",
		type          = "checkbox",
		title		  = "player_bots",
		tooltip       = "pb",
		default_value = true
	},
	{
		setting_id    = "special_bots",
		type          = "checkbox",
		title		  = "special_bots",
		tooltip       = "sb",
		default_value = true
	},
}

return menu
