local jester = require("jester")

local nnoremap = require("sjdonado.keymap").nnoremap

nnoremap("<leader>jr", function()
  jester.run()
end)
nnoremap("<leader>jl", function()
  jester.run_last()
end)
nnoremap("<leader>jf", function()
  jester.run_file()
end)
nnoremap("<leader>jd", function()
  jester.debug()
end)
nnoremap("<leader>jdl", function()
  jester.debug_last()
end)
