local gitsigns = require("gitsigns")

local nnoremap = require("sjdonado.keymap").nnoremap
local vnoremap = require("sjdonado.keymap").vnoremap
local map = require("sjdonado.keymap").map
local nmap = require("sjdonado.keymap").nmap

gitsigns.setup({
  current_line_blame = false,
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    -- Actions
    map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { buffer = bufnr })
    map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { buffer = bufnr })
    nmap("<leader>hu", gs.undo_stage_hunk, { buffer = bufnr })
    nmap("<leader>hS", gs.stage_buffer, { buffer = bufnr })
    nmap("<leader>hR", gs.reset_buffer, { buffer = bufnr })
    nmap("<leader>hp", gs.preview_hunk, { buffer = bufnr })
    nmap("<leader>hb", function()
      gs.blame_line({ full = true })
    end)
  end,
})

-- openingh config
nnoremap("<leader>hor", ":OpenInGHRepo<CR>")
nnoremap("<leader>hof", ":OpenInGHFile<CR>")
vnoremap("<leader>hof", ":OpenInGHFile<CR>")
