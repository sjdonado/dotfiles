local dap = require("dap")
local dapui = require("dapui")

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "breakpoints", size = 0.15 },
				"stacks",
				"scopes",
				"watches",
			},
			size = 40, -- 40 columns
			position = "left",
		},
		{
			elements = {
				"console",
				"repl",
			},
			size = 0.25, -- 25% of total lines
			position = "bottom",
		},
	},
	controls = {
		enabled = false,
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end

require("sjdonado.dap.node")
require("sjdonado.dap.go")

local M = {}

M.dap = dap
M.dapui = dapui

return M
