local lualine = require("lualine")
local nvimwebdevicons = require("nvim-web-devicons")

local null_ls_helper = require("sjdonado.helpers.null-ls")
local table_helper = require("sjdonado.helpers.table")

nvimwebdevicons.setup({
	override = {
		zsh = {
			icon = "",
			color = "#428850",
			cterm_color = "65",
			name = "Zsh",
		},
	},
	color_icons = true,
})

local function lsp_clients(msg)
	msg = msg or ""
	local buf_clients = vim.lsp.buf_get_clients()
	if next(buf_clients) == nil then
		if type(msg) == "boolean" or #msg == 0 then
			return ""
		end
		return msg
	end

	local buf_ft = vim.bo.filetype
	local buf_client_names = {}

	for _, client in pairs(buf_clients) do
		if client.name ~= "null-ls" then
			table.insert(buf_client_names, client.name)
		end
	end

	local supported_formatters = null_ls_helper.registered_formatters(buf_ft)
	vim.list_extend(buf_client_names, supported_formatters)

	local supported_linters = null_ls_helper.registered_linters(buf_ft)
	vim.list_extend(buf_client_names, supported_linters)

	local supported_hovers = null_ls_helper.registered_hovers(buf_ft)
	vim.list_extend(buf_client_names, supported_hovers)

	return table.concat(table_helper.remove_duplicates(buf_client_names), " ")
end

local buffers = {
	{
		"buffers",
		show_filename_only = false,
		mode = 4, -- Shows buffer name + buffer number
	},
}

local sections = {
	lualine_a = { "mode" },
	lualine_b = { "branch", "diff" },
	lualine_c = buffers,
	lualine_x = {
		{ "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
		{
			lsp_clients,
			icon = " ",
			color = { gui = "bold" },
		},
		{ "encoding" },
	},
	lualine_y = { "progress" },
	lualine_z = { "location" },
}
local inactive_sections = {
	lualine_a = {},
	lualine_b = {},
	lualine_c = buffers,
	lualine_x = { "location" },
	lualine_y = {},
	lualine_z = {},
}

local M = {}

M.load = function()
	lualine.setup({
		sections = sections,
		inactive_sections = inactive_sections,
	})
end

return M
