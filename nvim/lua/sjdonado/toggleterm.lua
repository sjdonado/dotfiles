local Terminal = require("toggleterm.terminal").Terminal

local sjdonado_zenmode = require("sjdonado.zen-mode")

local nnoremap = require("sjdonado.keymap").nnoremap
local tnoremap = require("sjdonado.keymap").tnoremap

local function toggle(term)
  return function()
    require("sjdonado.dap.init").dapui.close({ "all" })
    sjdonado_zenmode.exit_zenmode_if_needed()

    local terms = require("toggleterm.terminal").get_all()
    for _, otherterm in pairs(terms) do
      if otherterm:is_open() and otherterm ~= term then
        otherterm:close()
      end
    end

    term:toggle()
  end
end

local M = {}

function M.create_terminal(opts)
  local count = opts.count or 0
  local direction = opts.direction or "horizontal"
  local keymap = opts.keymap or ""

  local start_in_insert = true
  if opts.start_in_insert ~= nil then
    start_in_insert = opts.start_in_insert
  end

  local term = Terminal:new({
    count = count,
    direction = direction,
    on_open = function(term)
      if start_in_insert == true then
        vim.cmd("startinsert")
      end
      nnoremap(keymap, toggle(term), { buffer = term.bufnr, silent = true })
      tnoremap("<esc>", "<C-\\><C-n>", { buffer = term.bufnr, silent = true })
    end,
    on_close = function(term)
      vim.cmd("stopinsert")
    end,
  })

  nnoremap(opts.keymap, toggle(term))

  return term
end

return M
