package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup({
	leader_key = { "alt", "ctrl" },

	{
		"ActionsLauncher",
		actions = {
			{ "toggle_system_appearance", alias = "ta" },
			{ "toggle_caffeinate",        alias = "tc" },
			{ "system_information",       alias = "si" },
			{ "screen_ruler",             alias = "ru" },

			{ "window_maximize",          alias = "wm" },
			{ "window_cinema",          alias = "wc" },
			{ "window_left_two_thirds",   alias = "wl2" },
			{ "window_right_two_thirds",  aliast = "wr2" },
			{ "window_left_third",        alias = "wl3" },
			{ "window_right_third",       aliast = "wr3" },
			{ "window_left_fourth",       alias = "wl4" },
			{ "window_right_fourth",      alias = "wr4" },
			{ "window_almost_maximize",   keys = { { "<leader>", "up" } } },
			{ "window_reasonable_size",   keys = { { "<leader>", "down" } } },
			{ "window_center",            keys = { { "<leader>", "return" } } },
			{ "window_left",              keys = { { "<leader>", "left" } } },
			{ "window_right",             keys = { { "<leader>", "right" } } },

			{ "clipboard_history",        keys = { { "<leader>", "-" } } },
			{ "kill_process",             keys = { { "<leader>", "=" } } },
			{ "safari_tabs",              keys = { { "alt", "tab" } } },

			{ "generate_uuid",            alias = "gu" },
			{ "word_count",               alias = "wc" },

			{ "converter_time",           alias = "ct" },
			{ "converter_colors",         alias = "cc" },
			{ "converter_base64",         alias = "cb" },
			{ "converter_jwt",            alias = "cj" },

			{ "network_ip_geolocation",   alias = "ni" },
			{ "network_speed_test",       alias = "ns" },

			{ "keyboard_lock",            alias = "kl" },
			{ "keyboard_keep_alive",      alias = "ka" },

			{ "screen_confetti",          alias = "cf" },
			{ "f1_standings",             alias = "f1" },
			{ "idonthavespotify",         alias = "idhs" },

			{ "martillo_reload",          alias = "mr" },
			{ "martillo_update",          alias = "mu" },
		},
		keys = {
			{ "<leader>", "space" },
		},
	},

	{
		"LaunchOrToggleFocus",
		keys = {
			{ "<leader>", "c", app = "Calendar" },
			{ "<leader>", "f", app = "Finder" },
			{ "<leader>", ";", app = "Ghostty" },
			{ "<leader>", "h", app = "Helium" },
			{ "<leader>", "l", app = "Music" },
			{ "<leader>", "e", app = "Mail" },
			{ "<leader>", "m", app = "Messages" },
			{ "<leader>", "n", app = "Notes" },
			{ "<leader>", "p", app = "Passwords" },
			{ "<leader>", "r", app = "Reminders" },
			{ "<leader>", "b", app = "Safari" },
			{ "<leader>", "t", app = "Kagi Translate" },
			{ "<leader>", "y", app = "Yaak" },
		},
	},

	{
		"MySchedule",
		config = function(spoon)
			spoon:compile()
			spoon:start()
		end,
	},

	{
		"BrowserRedirect",
		opts = {
			default_app = "Safari",
			redirect = {
				{ match = { "*localhost*", "*127.0.0.1*", "*0.0.0.0*" }, app = "Helium" },
				{ match = { "*meet.google*" },                           app = "Helium" },
			},
		},
		config = function(spoon)
			spoon:start()
		end,
	},
})
