-- A size test shared by every consumer that would otherwise walk a huge buffer:
-- treesitter parses it, a language server reads and indexes it, indent-blankline
-- redraws it. None of that pays off on a minified bundle or a dumped fixture,
-- and all of it is felt as lag the moment the file opens.
--
-- 150KB is roughly where a treesitter parse stops being free on this machine and
-- well above any hand-written source file. Measured on file size rather than line
-- count because the check has to run before the buffer is read.
local M = { limit = 150 * 1024 }

---@param buf integer
---@return boolean
function M.is_big(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return false
  end
  local stat = vim.uv.fs_stat(name)
  return stat ~= nil and stat.size > M.limit
end

return M
