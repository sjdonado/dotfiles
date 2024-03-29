local Terminal = require("toggleterm.terminal").Terminal

local sjdonado_zenmode = require("sjdonado.zen-mode")
local sjdonado_dap = require("sjdonado.dap.init")

local nnoremap = require("sjdonado.keymap").nnoremap
local tnoremap = require("sjdonado.keymap").tnoremap

local function toggle(term)
  return function()
    sjdonado_dap.exit_dapui_if_open()
    sjdonado_zenmode.exit_zenmode_if_open()

    local terms = require("toggleterm.terminal").get_all()
    for _, otherterm in pairs(terms) do
      if otherterm:is_open() and otherterm ~= term then
        otherterm:close()
      end
    end

    term:toggle()
  end
end

local function close_all()
  for _, term in pairs(require("toggleterm.terminal").get_all()) do
    term:close()
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

      vim.api.nvim_command("wincmd =")
    end,
    on_close = function(term)
      vim.cmd("stopinsert")
    end,
  })

  nnoremap(opts.keymap, toggle(term))

  local actions = {}

  actions.toggle = toggle(term)

  return actions
end

nnoremap("<leader>tt", close_all, { silent = true })

return M
