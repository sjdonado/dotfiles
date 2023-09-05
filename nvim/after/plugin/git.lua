local gitsigns = require("gitsigns")

local fugitive = require("sjdonado.fugitive")

local map = require("sjdonado.keymap").map
local nmap = require("sjdonado.keymap").nmap
local nnoremap = require("sjdonado.keymap").nnoremap
local vnoremap = require("sjdonado.keymap").vnoremap

gitsigns.setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  current_line_blame = false,
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    -- Navigation
    nmap("]c", function()
      if vim.wo.diff then
        return "]c"
      end
      vim.schedule(function()
        gs.next_hunk()
      end)
      return "<Ignore>"
    end, { expr = true })

    nmap("[c", function()
      if vim.wo.diff then
        return "[c"
      end
      vim.schedule(function()
        gs.prev_hunk()
      end)
      return "<Ignore>"
    end, { expr = true })

    -- Actions
    map({ "n", "v" }, "<leader>hs", gs.stage_hunk, { buffer = bufnr })
    map({ "n", "v" }, "<leader>hr", gs.reset_hunk, { buffer = bufnr })
    nmap("<leader>hu", gs.undo_stage_hunk, { buffer = bufnr })
    nmap("<leader>hS", gs.stage_buffer, { buffer = bufnr })
    nmap("<leader>hR", gs.reset_buffer, { buffer = bufnr })
    nmap("<leader>hp", gs.preview_hunk, { buffer = bufnr })
    nmap("<leader>hb", function()
      gs.blame_line({ full = true })
    end)
  end,
})

-- vim fugitive
nmap("<C-g>", fugitive.create_or_switch_to_git_tab)
nmap("<leader>gf", ":Git fetch<CR>", { silent = true })
nmap("<leader>gp", ":Git pull<CR>", { silent = true })
nmap("<leader>gP", ":Git push<CR>", { silent = true })

-- openingh config
nnoremap("<leader>gr", ":OpenInGHRepo<CR>", { silent = true })
nnoremap("<leader>gF", ":OpenInGHFile<CR>", { silent = true })
vnoremap("<leader>gF", ":OpenInGHFileLines<CR>", { silent = true })
