-- Load Martillo
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup({
	leader_key = { "alt", "ctrl" },

	{
		"ActionsLauncher",
		opts = function()
			local window_mgmt = require("presets.window_management")
			local utilities = require("presets.utilities")
			local encoders = require("presets.encoders")
			local clipboard = require("presets.clipboard_history")
			local kill_process = require("presets.kill_process")

			return { actions = { window_mgmt, utilities, encoders, clipboard, kill_process } }
		end,
		actions = {
			{ "toggle_system_appearance", alias = "ta" },
			{ "toggle_caffeinate", alias = "tc" },
			{ "window_maximize", alias = "wm" },
			{ "timestamp", alias = "ct" },

			{ "window_center", keys = { { "<leader>", "return" } } },
			{ "window_almost_maximize", keys = { { "<leader>", "up" } } },
			{ "window_reasonable_size", keys = { { "<leader>", "down" } } },
			{ "window_left_two_thirds", keys = { { "<leader>", "left" } } },
			{ "window_right_two_thirds", keys = { { "<leader>", "right" } } },
			{ "window_left_third", alias = "wlt" },
			{ "window_right_third", alias = "wrt" },
			{ "window_center_third", alias = "wct" },

			{ "copy_ip", alias = "ci" },
			{ "network_status", alias = "cn" },
			{ "generate_uuid", alias = "gu" },
			{ "colors", alias = "cc" },
			{ "base64", alias = "cb" },
			{ "jwt", alias = "cj" },

			{ "clipboard_history", keys = { { "<leader>", "-" } } },
			{ "kill_process", alias = "kp", keys = { { "<leader>", "=" } } },
		},
		keys = {
			{ "<leader>", "space", desc = "Toggle Actions Launcher" },
		},
	},

	{
		"LaunchOrToggleFocus",
		keys = {
			{ "<leader>", "c", app = "Calendar" },
			{ "<leader>", "x", app = "Excalidraw" },
			{ "<leader>", "i", app = "Figma" },
			{ "<leader>", ";", app = "Ghostty" },
			{ "<leader>", "u", app = "Google Meet" },
			{ "<leader>", "h", app = "Helium" },
			{ "<leader>", "l", app = "Music" },
			{ "<leader>", "e", app = "Mail" },
			{ "<leader>", "m", app = "Messages" },
			{ "<leader>", "n", app = "Notes" },
			{ "<leader>", "p", app = "Passwords" },
			{ "<leader>", "d", app = "Postico 2" },
			{ "<leader>", "r", app = "Reminders" },
			{ "<leader>", "b", app = "Safari" },
			{ "<leader>", "s", app = "Slack" },
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
				{ match = { "*autarc.energy*" }, app = "Helium" },
				{ match = { "*fly.dev*" }, app = "Helium" },
				{ match = { "*meet.google*" }, app = "Helium" },
			},
		},
		config = function(spoon)
			spoon:start()
		end,
	},
})
