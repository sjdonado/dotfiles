local M = {}

function M.root_has_file(file_pattern)
  local root_path = vim.loop.cwd()

  local files = vim.fn.glob(root_path .. "/" .. file_pattern, true, true)
  for _, f in ipairs(files) do
    if vim.loop.fs_stat(f) then
      return true
    end
  end

  return false
end

return M
