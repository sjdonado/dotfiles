local gitsigns = require("gitsigns")
local git_conflict = require("git-conflict")

local neogit = require("neogit")

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

git_conflict.setup({})

neogit.setup({
  signs = {
    item = { "", "" },
  },
})
nmap("<C-g>", function()
  neogit.open()
end, { silent = true })

-- openingh config
nnoremap("<leader>ho", ":OpenInGHRepo<CR>", { silent = true })
nnoremap("<leader>hf", ":OpenInGHFile<CR>", { silent = true })
vnoremap("<leader>hF", ":OpenInGHFileLines<CR>", { silent = true })
