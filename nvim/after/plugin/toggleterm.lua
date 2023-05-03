local Terminal = require("toggleterm.terminal").Terminal

local nnoremap = require("sjdonado.keymap").nnoremap

require("toggleterm").setup({
  start_in_insert = true,
  size = function(term)
    if term.direction == "horizontal" then
      return 25
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
})

local function toggle(term)
  return function()
    require("sjdonado.dap.init").dapui.close({ "all" })
    exit_zenmode_if_needed()

    term:toggle()
  end
end

local function create_terminal(opts)
  local term = Terminal:new({
    cmd = "zsh",
    count = opts.count,
    direction = opts.direction,
    on_open = function(term)
      nnoremap(opts.keymap, toggle(term), { buffer = term.bufnr, silent = true })
    end,
    on_close = function(term)
      vim.cmd("stopinsert")
    end,
  })

  nnoremap(opts.keymap, toggle(term))

  return term
end

create_terminal({ direction = "horizontal", keymap = "<leader>;", count = 1 })
create_terminal({ direction = "vertical", keymap = "<leader>'", count = 2 })
