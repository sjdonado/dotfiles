local dap = require("dap")
local dapui = require("dapui")

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.2 },
				{ id = "repl", size = 0.4 },
				{ id = "console", size = 0.4 },
			},
			size = 0.25,
			position = "bottom",
		},
	},
	controls = {
		enabled = false,
	},
})

require("nvim-dap-virtual-text").setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end

require("sjdonado.dap.node")
require("sjdonado.dap.go")

local M = {}

M.dap = dap
M.dapui = dapui

return M
