local M = {}

M.map = function(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { noremap = false }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function bind(op, outer_opts)
  outer_opts = outer_opts or { noremap = true }
  return function (lhs, rhs, opts)
    M.map(op, lhs, rhs, opts)
  end
end

M.nmap = bind("n", { noremap = false })
M.nnoremap = bind("n")
M.vnoremap = bind("v")
M.xnoremap = bind("x")
M.inoremap = bind("i")
M.tnoremap = bind("t")

return M
