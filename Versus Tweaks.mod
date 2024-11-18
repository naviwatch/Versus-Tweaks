return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Versus Tweaks` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Versus Tweaks", {
			mod_script       = "scripts/mods/Versus Tweaks/Versus Tweaks",
			mod_data         = "scripts/mods/Versus Tweaks/Versus Tweaks_data",
			mod_localization = "scripts/mods/Versus Tweaks/Versus Tweaks_localization",
		})
	end,
	packages = {
		"resource_packages/Versus Tweaks/Versus Tweaks",
	},
}
