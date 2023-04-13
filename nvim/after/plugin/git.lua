local gitsigns = require("gitsigns")

local nnoremap = require("sjdonado.keymap").nnoremap

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
    map("n", "<leader>hu", gs.undo_stage_hunk)
    map("n", "<leader>hS", gs.stage_buffer)
    map("n", "<leader>hR", gs.reset_buffer)
    map("n", "<leader>hp", gs.preview_hunk)
    map("n", "<leader>hb", function()
      gs.blame_line({ full = true })
    end)
  end,
})

-- lazygit config
vim.g.lazygit_floating_window_scaling_factor = 1.0
vim.g.lazygit_use_neovim_remote = 1

nnoremap("<leader>gs", "gg :LazyGit<CR>")
