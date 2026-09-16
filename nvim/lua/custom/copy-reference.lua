-- Copy a code reference (`path`, `path:12`, `path:12-40`) to the clipboard, in
-- the notation an agent can resolve.
--
-- Paths are relative to the git root rather than the cwd: an agent's cwd is the
-- repo root, while nvim's may be a subdirectory, and a cwd-relative path
-- silently points at nothing.

local M = {}

-- Path relative to the git root, else relative to cwd. `vim.fs.root` walks up
-- from the buffer, so it is correct for a file outside the cwd too.
local function relative_path()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    return nil
  end
  local root = vim.fs.root(file, '.git')
  if root then
    return vim.fs.relpath(root, file) or vim.fn.fnamemodify(file, ':~:.')
  end
  return vim.fn.fnamemodify(file, ':~:.')
end

local function copy(ref)
  vim.fn.setreg('+', ref)
  vim.notify(ref)
end

--- Copy `path:12` for the cursor line.
function M.line()
  local path = relative_path()
  if not path then
    return vim.notify('buffer has no file', vim.log.levels.WARN)
  end
  copy(('%s:%d'):format(path, vim.fn.line '.'))
end

--- Copy `path:12-40` for the visual selection, collapsing to `path:12` when the
--- selection covers a single line. `line('v')` is the anchor and `line('.')` the
--- cursor, so the anchor is the larger number whenever the selection was made
--- upwards; sort rather than assuming a direction.
function M.range()
  local path = relative_path()
  if not path then
    return vim.notify('buffer has no file', vim.log.levels.WARN)
  end
  local first, last = vim.fn.line 'v', vim.fn.line '.'
  if first > last then
    first, last = last, first
  end
  if first == last then
    return copy(('%s:%d'):format(path, first))
  end
  copy(('%s:%d-%d'):format(path, first, last))
end

-- No path-only mapping: nvim-tree's `Y` already copies a relative path, so the
-- line and range forms are the only ones that add anything.
vim.keymap.set('n', '<leader>y', M.line, { desc = 'Yank line reference' })
vim.keymap.set('x', '<leader>y', M.range, { desc = 'Yank range reference' })

return M
