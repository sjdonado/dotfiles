local dap = require("dap")
local dapui = require("dapui")

dapui.setup({
  layouts = {
    {
      elements = {
        { id = "breakpoints", size = 0.15 },
        "stacks",
        "scopes",
        "watches",
      },
      size = 40, -- 40 columns
      position = "left",
    },
    {
      elements = {
        "console",
        "repl",
      },
      size = 0.25, -- 25% of total lines
      position = "bottom",
    },
  },
  controls = {
    enabled = false
  }
})

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
--[[ dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end ]]

require("sjdonado.debugger.node")

local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap

nnoremap("<leader>dt", function()
    dapui.toggle()
end)
nnoremap("<F8>", function()
    dap.continue()
end)
nnoremap("<F10>", function()
    dap.step_over()
end)
nnoremap("<F7>", function()
    dap.step_into()
end)
nnoremap("<F9>", function()
    dap.step_out()
end)

nnoremap("<Leader>b", function()
    dap.toggle_breakpoint()
end)
nnoremap("<Leader>B", function()
    dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end)
nnoremap("<leader>rc", function()
    dap.run_to_cursor()
end)

