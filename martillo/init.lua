-- Load Martillo
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup({
	leader_key = { "alt", "ctrl" },

	{
		"ActionsLauncher",
		opts = function()
			local window = require("bundle.window_management")
			local utilities = require("bundle.utilities")
			local converter = require("bundle.converter")
			local screen = require("bundle.screen")
			local network = require("bundle.network")
			local clipboard = require("bundle.clipboard_history")
			local kill_process = require("bundle.kill_process")
			local safari_tabs = require("bundle.safari_tabs")
			local martillo = require("bundle.martillo")

			return {
				actions = {
					window,
					utilities,
					converter,
					screen,
					network,
					clipboard,
					kill_process,
					safari_tabs,
					martillo,
				},
			}
		end,
		actions = {
			{ "toggle_system_appearance", alias = "ta" },
			{ "toggle_caffeinate", alias = "tc" },
			{ "window_maximize", alias = "wm" },
			{ "screen_ruler", alias = "ru" },

			{ "window_center", keys = { { "<leader>", "return" } } },
			{ "window_almost_maximize", keys = { { "<leader>", "up" } } },
			{ "window_reasonable_size", keys = { { "<leader>", "down" } } },
			{ "window_left_two_thirds", keys = { { "<leader>", "left" } } },
			{ "window_right_two_thirds", keys = { { "<leader>", "right" } } },
			{ "window_left_third", alias = "wlt" },
			{ "window_right_third", alias = "wrt" },
			{ "window_center_third", alias = "wct" },

			{ "generate_uuid", alias = "gu" },

			{ "converter_time", alias = "ct" },
			{ "converter_colors", alias = "cc" },
			{ "converter_base64", alias = "cb" },
			{ "converter_jwt", alias = "cj" },

			{ "network_copy_ip", alias = "ni" },
			{ "network_speed_test", alias = "ns" },

			{ "clipboard_history", keys = { { "<leader>", "-" } } },
			{ "kill_process", keys = { { "<leader>", "=" } } },
			{ "safari_tabs", keys = { { "alt", "tab" } } },

			{ "screen_confetti", alias = "cf" },

			{ "martillo_reload", alias = "mr" },
			{ "martillo_update", alias = "mu" },
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
