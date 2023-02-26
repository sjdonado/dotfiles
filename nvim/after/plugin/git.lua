local gitsigns = require("gitsigns")
local gitconflict = require("git-conflict")

local nnoremap = require("sjdonado.keymap").nnoremap

gitconflict.setup({
	default_mappings = false,
})

gitsigns.setup({
	current_line_blame = false,
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Actions
		map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>")
		map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>")
		map("n", "<leader>hS", gs.stage_buffer)
		map("n", "<leader>hu", gs.undo_stage_hunk)
		map("n", "<leader>hR", gs.reset_buffer)
		map("n", "<leader>hp", gs.preview_hunk)
		map("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end)
		map("n", "<leader>hd", gs.diffthis)
		map("n", "<leader>hD", function()
			gs.diffthis("~")
		end)

		-- Text object
		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
	end,
})

nnoremap("<leader>gs", ":tab G<CR>")
nnoremap("<leader>cc", ":vert G commit<CR>")
nnoremap("<leader>ca", ":vert G commit --amend<CR>", { silent = true })

nnoremap("<leader>gm", ":G mergetool<CR>")
nnoremap("<leader>gms", ":GitConflictNextConflict<CR><cmd>vs<CR><cmd>wincmd h<CR>/=======<CR>ms")

nnoremap("<leader>co", ":GitConflictChooseOurs<CR>")
nnoremap("<leader>ct", ":GitConflictChooseTheirs<CR>")
nnoremap("<leader>cb", ":GitConflictChooseBoth<CR>")
nnoremap("<leader>c0", ":GitConflictChooseNone<CR>")
nnoremap("<leader>]x", ":GitConflictNextConflict<CR>")
nnoremap("<leader>[x", ":GitConflictPrevConflict<CR>")
