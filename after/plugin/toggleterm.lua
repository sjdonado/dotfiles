local nnoremap = require("sjdonado.keymap").nnoremap

require("toggleterm").setup({
	size = 25,
})

local function has_term_buffer()
	local bufs = vim.api.nvim_list_bufs()
	for _, buf in ipairs(bufs) do
		if vim.api.nvim_buf_get_option(buf, "bufhidden") == "terminal" then
			return true
		end
	end
	return false
end

local function toggle()
	require("dapui").close({ "all" })

	if require("zen-mode.view").is_open() then
		require("zen-mode").close()
	end

	if has_term_buffer() then
		vim.cmd(":ToggleTermToggleAll<CR>")
	else
		vim.cmd(":ToggleTerm<CR>")
	end
end

nnoremap("<leader>;", function()
	toggle()
end)

function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
end

vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
