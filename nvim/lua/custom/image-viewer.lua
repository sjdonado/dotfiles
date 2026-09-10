-- Floating image viewer with zoom and vertical scroll, drawn through snacks.image (Kitty
-- graphics protocol, i.e. Ghostty). Inline diagrams stay small by design and
-- snacks has no zoom, so large diagrams get a dedicated window instead.
--
-- snacks overlays the image row by row onto buffer lines, so the scratch
-- buffer is padded with blank lines and the viewport is pinned mid-buffer:
-- rows above the pinned top line are simply not drawn, which is what a
-- vertical pan is. Horizontal position is a window column snacks fixes from
-- the anchor, so it cannot go negative; zoom is therefore capped at the
-- window width and a diagram is read by scrolling it vertically.
-- ponytail: no leftward pan past the window edge; snacks has no API for it,
-- cropping the placeholder grid ourselves would be the upgrade path.
local M = {}

local ZOOM_MIN, ZOOM_STEP = 0.25, 1.25
local PAN_STEP = 2
local PAD_LINES, PAD_WIDTH = 2000, 400
local VIEW_ROW = 1000
local GRID_MAX = 297 -- snacks encodes cell positions as diacritics; that many exist

---@param n number
---@param lo integer
---@param hi integer
---@return number
local function clamp(n, lo, hi)
  return math.max(lo, math.min(hi, n))
end

---@class custom.ImageViewer
---@field buf integer
---@field win snacks.win
---@field placement snacks.image.Placement
---@field label string
---@field factor number
---@field base? { width: integer, height: integer } size as first fitted into the window
---@field natural? { width: integer, height: integer } size at 100% of the image's pixels
---@field padded boolean
---@field pos { row: integer, col: integer } col is always 0, see the header

-- Pin the viewport. snacks resets a non-inline placement's window to topline 1
-- and cursor line 1 on every update, and a cursor or mouse click would scroll
-- it too; either would break the anchor math in refresh.
---@param st custom.ImageViewer
local function pin(st)
  if st.win and st.win:valid() then
    vim.api.nvim_win_call(st.win.win, function()
      vim.fn.winrestview({ topline = VIEW_ROW, leftcol = 0, lnum = VIEW_ROW, col = 0 })
    end)
  end
end

---@param st custom.ImageViewer
local function refresh(st)
  if not (st.win:valid() and st.base and st.natural) then
    return
  end
  pin(st)
  local win_w = math.max(1, vim.api.nvim_win_get_width(st.win.win))
  local win_h = math.max(1, vim.api.nvim_win_get_height(st.win.win))

  -- snacks never upscales past the pixel size, never draws more than GRID_MAX
  -- cells a side, and this viewer never goes past the window width, so the
  -- factor is clamped to what can actually be drawn.
  local max_factor = math.max(1, math.min(st.natural.width / st.base.width, win_w / st.base.width, GRID_MAX / st.base.width, GRID_MAX / st.base.height))
  st.factor = clamp(st.factor, ZOOM_MIN, max_factor)
  local dw = math.max(1, math.floor(st.base.width * st.factor + 0.5))
  local dh = math.max(1, math.floor(st.base.height * st.factor + 0.5))
  st.pos.row = clamp(st.pos.row, math.max(1, VIEW_ROW - (dh - 1)), VIEW_ROW + (win_h - 1))

  local placement = st.placement
  placement.opts.width, placement.opts.height = dw, dh
  placement.opts.pos = { st.pos.row, st.pos.col }
  placement.opts.range = { st.pos.row, st.pos.col, st.pos.row + dh - 1, st.pos.col }
  placement:update()
  local shown = placement:state().loc
  st.win:set_title(('%s: %d%%'):format(st.label, math.floor(shown.width / st.natural.width * 100 + 0.5)))
end

---@param st custom.ImageViewer
local function close(st)
  st.win:close()
end

---@param st custom.ImageViewer
---@param mult number
local function zoom(st, mult)
  if not st.base then
    return vim.notify('Diagram still rendering, try again in a moment', vim.log.levels.WARN)
  end
  st.factor = st.factor * mult
  refresh(st)
end

---@param st custom.ImageViewer
local function reset(st)
  st.factor = 1
  st.pos = { row = VIEW_ROW, col = 0 }
  refresh(st)
end

---@param st custom.ImageViewer
---@param drow integer
local function pan(st, drow)
  st.pos.row = st.pos.row + drow
  refresh(st)
end

-- Runs once the image is ready. snacks' progress spinner empties the buffer
-- while the image converts, so the padding has to be written afterwards, and
-- the anchor stays at line 1 until then because a placement whose anchor is
-- past the last line deletes itself.
---@param st custom.ImageViewer
local function on_ready(st)
  if st.padded or not st.win:valid() then
    return
  end
  st.padded = true
  local pad = {}
  for _ = 1, PAD_LINES do
    pad[#pad + 1] = string.rep(' ', PAD_WIDTH)
  end
  vim.bo[st.buf].modifiable = true
  vim.api.nvim_buf_set_lines(st.buf, 0, -1, false, pad)
  vim.bo[st.buf].modifiable = false
  -- Natural size the way snacks measures it (vector sources go by dpi, not
  -- by the rendered pixels), and before base so a failure leaves refresh off.
  local img = st.placement.img
  st.natural = require('snacks.image.util').fit(img.file, { width = math.huge, height = math.huge }, { info = img.info })
  local loc = st.placement:state().loc
  st.base = { width = loc.width, height = loc.height }
  -- Not inside the update that called us: refresh updates again.
  vim.schedule(function()
    refresh(st)
  end)
end

---@param src string
---@param label? string
---@return custom.ImageViewer?
local function open_now(src, label)
  if not require('snacks.image').supports_terminal() then
    vim.notify('Terminal cannot show images, opening externally', vim.log.levels.WARN)
    return vim.ui.open(src)
  end
  -- snacks downloads http(s) sources itself; only local paths need to exist.
  if not require('snacks.image.convert').is_url(src) and vim.fn.filereadable(src) == 0 then
    vim.notify('Image not found: ' .. src, vim.log.levels.ERROR)
    return nil
  end
  label = (label == nil or label == '') and vim.fn.fnamemodify(src, ':t') or label

  local buf = vim.api.nvim_create_buf(false, true)
  ---@type custom.ImageViewer
  local st = { buf = buf, label = label, factor = 1, padded = false, pos = { row = VIEW_ROW, col = 0 } }
  st.win = require('snacks.win')({
    buf = buf,
    relative = 'editor',
    position = 'float',
    width = 0.9,
    height = 0.85,
    border = 'rounded',
    title = label,
    footer_pos = 'right',
    footer_keys = { '+', '-', '0', 'j', 'k', 'q' },
    enter = true,
    backdrop = 60,
    wo = { wrap = false },
    bo = { modifiable = false },
    on_close = function()
      if st.placement then
        st.placement:close()
      end
      -- snacks only wipes buffers it created itself; this one is ours.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
    keys = {
      q = { function() close(st) end, desc = 'Close' },
      ['<Esc>'] = { function() close(st) end, desc = 'Close' },
      ['+'] = { function() zoom(st, ZOOM_STEP) end, desc = 'Zoom in' },
      ['='] = { function() zoom(st, ZOOM_STEP) end, desc = 'Zoom in' },
      ['-'] = { function() zoom(st, 1 / ZOOM_STEP) end, desc = 'Zoom out' },
      ['_'] = { function() zoom(st, 1 / ZOOM_STEP) end, desc = 'Zoom out' },
      ['0'] = { function() reset(st) end, desc = 'Reset zoom and pan' },
      j = { function() pan(st, -PAN_STEP) end, desc = 'Scroll down' },
      k = { function() pan(st, PAN_STEP) end, desc = 'Scroll up' },
      ['<Down>'] = { function() pan(st, -PAN_STEP) end, desc = 'Scroll down' },
      ['<Up>'] = { function() pan(st, PAN_STEP) end, desc = 'Scroll up' },
    },
  })
  st.placement = require('snacks.image.placement').new(buf, src, {
    pos = { 1, 0 },
    inline = false,
    conceal = true,
    on_update = function()
      on_ready(st)
      pin(st)
    end,
  })
  return st
end

---@param src string
---@param label? string
---@param cb? fun(st: custom.ImageViewer?)
function M.open(src, label, cb)
  -- Detect first: the terminal probe snacks starts on FileType may still be
  -- in flight, and env() would then cache the terminal as unsupported for
  -- the whole session.
  require('snacks.image.terminal').detect(function()
    local st = open_now(src, label)
    if cb then
      cb(st)
    end
  end)
end

---Open the image under the cursor: a mermaid diagram or a plain reference.
function M.open_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  require('snacks.image.doc').find(buf, function(matches)
    for _, match in ipairs(matches) do
      if match.src and match.src ~= '' then
        local label = match.type == 'chart' and 'mermaid diagram' or nil
        return M.open(match.src, label)
      end
    end
    vim.notify('No image under cursor', vim.log.levels.WARN)
  end, { from = row, to = row })
end

return M
