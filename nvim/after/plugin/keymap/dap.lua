local dap = require("sjdonado.dap").dap
local dapui = require("sjdonado.dap").dapui

local nnoremap = require("sjdonado.keymap").nnoremap

nnoremap("<leader>dt", function()
  dapui.toggle()
end)
nnoremap("<leader>dx", function()
  dap.clear_breakpoints()
  dapui.close()
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

nnoremap("<Leader>db", function()
  dap.toggle_breakpoint()
end)
nnoremap("<Leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end)
nnoremap("<leader>dC", function()
  dap.run_to_cursor()
end)
