local jester = require("jester")

local nnoremap = require("sjdonado.keymap").nnoremap

nnoremap("<leader>jr", function()
  exit_zenmode_if_needed()
  jester.run()
end)

nnoremap("<leader>jl", function()
  exit_zenmode_if_needed()
  jester.run_last()
end)

nnoremap("<leader>jf", function()
  exit_zenmode_if_needed()
  jester.run_file()
end)

nnoremap("<leader>jd", function()
  exit_zenmode_if_needed()
  jester.debug()
end)

nnoremap("<leader>jdl", function()
  exit_zenmode_if_needed()
  jester.debug_last()
end)
