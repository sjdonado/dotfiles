-- Floating image viewer with zoom and pan, drawn through snacks.image (Kitty
-- graphics protocol, i.e. Ghostty). Inline diagrams are fitted to the window,
-- and snacks can neither upscale nor show part of an image, so the viewer
-- re-renders on every change: it crops the visible region out of the source
-- pixels with ImageMagick, resizes that to the window, and places the result.
-- Zooming therefore shows the source's extra pixels as detail, and panning
-- works in both directions.
-- ponytail: snacks keeps one Lua-side Image record per frame file for the
-- session (its table is private); the terminal side is freed per frame.
local M = {}

local ZOOM_STEP = 1.25
local MAX_PIXEL_SCALE = 4 -- zooming in stops once a source pixel would span this many screen pixels
local PAN_FRACTION = 0.25 -- of the visible region per key press
local SCROLL_FRACTION = 0.1 -- per wheel tick; a trackpad sends many

---@param n number
---@param lo number
---@param hi number
---@return number
local function clamp(n, lo, hi)
  return math.max(lo, math.min(hi, n))
end

---@class custom.ImageViewer
---@field buf integer
---@field win snacks.win
---@field src string source raster, cropped from directly
---@field size { width: integer, height: integer } source pixels
---@field label string
---@field zoom number 1 means the whole image fits the window
---@field center { x: number, y: number } source pixel at the window center
---@field frames { placement: snacks.image.Placement, img: snacks.Image, file: string }[] oldest first
---@field tmp string
---@field last? string crop and resize geometry of the frame on screen
---@field generation integer
---@field busy boolean
---@field dirty boolean

-- Poll snacks' async converter. Its own callbacks only reach placements.
---@param img snacks.Image
---@param cb fun(ok: boolean)
local function when_ready(img, cb)
  local timer = assert(vim.uv.new_timer())
  local waited, done = 0, false
  timer:start(0, 50, vim.schedule_wrap(function()
    if done then
      return
    end
    waited = waited + 50
    local ready, failed = img:ready(), img:failed() or waited > 30000
    if ready or failed then
      done = true
      timer:stop()
      timer:close()
      cb(ready and not failed)
    end
  end))
end

-- The window in pixels, less one text row: the image hangs below the
-- buffer's only line, so that line's row is not available to it.
---@param st custom.ImageViewer
---@return { width: number, height: number }
local function box(st)
  local size = require('snacks.image.terminal').size()
  return {
    width = math.max(1, vim.api.nvim_win_get_width(st.win.win)) * size.cell_width,
    height = math.max(1, vim.api.nvim_win_get_height(st.win.win) - 1) * size.cell_height,
  }
end

-- The visible region in source pixels for the current zoom and center. Also
-- pulls the center back inside the image, so callers see a settled state.
---@param st custom.ImageViewer
local function region(st)
  local b = box(st)
  local fit = math.min(b.width / st.size.width, b.height / st.size.height)
  local scale = fit * st.zoom
  local w = math.min(st.size.width, b.width / scale)
  local h = math.min(st.size.height, b.height / scale)
  local x = clamp(st.center.x - w / 2, 0, st.size.width - w)
  local y = clamp(st.center.y - h / 2, 0, st.size.height - h)
  st.center = { x = x + w / 2, y = y + h / 2 }
  return {
    x = math.floor(x),
    y = math.floor(y),
    width = math.max(1, math.floor(w + 0.5)),
    height = math.max(1, math.floor(h + 0.5)),
    fit = fit,
    box = b,
  }
end

-- Free a frame's file, its snacks sidecar, and the terminal's copy.
---@param img snacks.Image
---@param file string
local function discard(img, file)
  img:del()
  vim.fn.delete(file)
  if img._convert then
    vim.fn.delete(img._convert:tmpfile('png.info'))
  end
end

-- Release every frame but the newest.
---@param st custom.ImageViewer
---@param keep integer
local function retire(st, keep)
  while #st.frames > keep do
    local frame = table.remove(st.frames, 1)
    frame.placement:close()
    discard(frame.img, frame.file)
  end
end

---@param st custom.ImageViewer
local function render(st)
  if not st.win:valid() then
    return
  end
  if st.busy then
    st.dirty = true
    return
  end
  local r = region(st)
  local crop = ('%dx%d+%d+%d'):format(r.width, r.height, r.x, r.y)
  local resize = ('%dx%d'):format(math.floor(r.box.width), math.floor(r.box.height))
  if crop .. ' ' .. resize == st.last then
    return -- a clamped pan or zoom: the frame on screen already is this view
  end
  st.busy, st.dirty = true, false
  st.generation = st.generation + 1
  local out = ('%s-%d.png'):format(st.tmp, st.generation)
  local function finish()
    st.busy = false
    if st.dirty and st.win:valid() then
      render(st)
    end
  end
  vim.system({ 'magick', st.src, '-crop', crop, '+repage', '-resize', resize, out }, {}, function(res)
    vim.schedule(function()
      if not st.win:valid() then
        vim.fn.delete(out)
        return finish()
      end
      if res.code ~= 0 then
        vim.fn.delete(out)
        vim.notify('magick: ' .. vim.trim(res.stderr or 'failed'), vim.log.levels.ERROR)
        return finish()
      end
      -- Place only once snacks has identified the file: a placement created
      -- before that shows a spinner and clears every other image in the buffer.
      local img = require('snacks.image.image').new(out)
      when_ready(img, function(ok)
        if not (ok and st.win:valid()) then
          discard(img, out)
          return finish()
        end
        local placement = require('snacks.image.placement').new(st.buf, out, {
          pos = { 1, 0 },
          inline = false,
          -- snacks refits the frame from its .info dpi and would overrun the
          -- reserved box by a row; these caps keep it inside.
          max_width = vim.api.nvim_win_get_width(st.win.win),
          max_height = math.max(1, vim.api.nvim_win_get_height(st.win.win) - 1),
          on_update = function()
            retire(st, 1) -- the new frame is on screen; older ones can go
          end,
        })
        st.frames[#st.frames + 1] = { placement = placement, img = img, file = out }
        st.last = crop .. ' ' .. resize
        -- Percent of the source's own pixels on screen; 100 is one to one.
        st.win:set_title(('%s: %d%%'):format(st.label, math.floor(r.fit * st.zoom * 100 + 0.5)))
        finish()
      end)
    end)
  end)
end

---@param st custom.ImageViewer
---@param mult number
local function zoom(st, mult)
  if not st.win:valid() then
    return
  end
  local r = region(st)
  st.zoom = clamp(st.zoom * mult, 1, math.max(1, MAX_PIXEL_SCALE / r.fit))
  render(st)
end

---@param st custom.ImageViewer
---@param dx number fraction of the visible width
---@param dy number fraction of the visible height
local function pan(st, dx, dy)
  if not st.win:valid() then
    return
  end
  local r = region(st)
  st.center.x = st.center.x + dx * r.width
  st.center.y = st.center.y + dy * r.height
  render(st)
end

---@param st custom.ImageViewer
local function reset(st)
  st.zoom = 1
  st.center = { x = st.size.width / 2, y = st.size.height / 2 }
  render(st)
end

---@param file string raster on disk
---@param label string
---@return custom.ImageViewer?
local function show(file, label)
  local ok, size = pcall(require('snacks.image.util').dim, file)
  if not ok then
    vim.notify('Could not read ' .. label .. ': ' .. tostring(size), vim.log.levels.ERROR)
    return nil
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local group = vim.api.nvim_create_augroup('custom-image-viewer-' .. buf, { clear = true })
  ---@type custom.ImageViewer
  local st = {
    buf = buf,
    src = file,
    size = size,
    label = label,
    zoom = 1,
    center = { x = size.width / 2, y = size.height / 2 },
    frames = {},
    tmp = vim.fn.tempname(),
    generation = 0,
    busy = false,
    dirty = false,
  }
  st.win = require('snacks.win')({
    buf = buf,
    relative = 'editor',
    position = 'float',
    width = 0.9,
    height = 0.85,
    border = 'rounded',
    title = label,
    footer_pos = 'right',
    footer_keys = { '+', '-', '0', 'h', 'j', 'k', 'l', 'q' },
    enter = true,
    backdrop = 60,
    wo = { wrap = false },
    bo = { modifiable = false },
    on_close = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
      retire(st, 0)
      -- snacks only wipes buffers it created itself; this one is ours.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
    keys = {
      q = { function() st.win:close() end, desc = 'Close' },
      ['<Esc>'] = { function() st.win:close() end, desc = 'Close' },
      ['+'] = { function() zoom(st, ZOOM_STEP) end, desc = 'Zoom in' },
      ['='] = { function() zoom(st, ZOOM_STEP) end, desc = 'Zoom in' },
      ['-'] = { function() zoom(st, 1 / ZOOM_STEP) end, desc = 'Zoom out' },
      ['_'] = { function() zoom(st, 1 / ZOOM_STEP) end, desc = 'Zoom out' },
      ['0'] = { function() reset(st) end, desc = 'Reset' },
      h = { function() pan(st, -PAN_FRACTION, 0) end, desc = 'Pan' },
      j = { function() pan(st, 0, PAN_FRACTION) end, desc = 'Pan' },
      k = { function() pan(st, 0, -PAN_FRACTION) end, desc = 'Pan' },
      l = { function() pan(st, PAN_FRACTION, 0) end, desc = 'Pan' },
      ['<Left>'] = { function() pan(st, -PAN_FRACTION, 0) end, desc = 'Pan' },
      ['<Down>'] = { function() pan(st, 0, PAN_FRACTION) end, desc = 'Pan' },
      ['<Up>'] = { function() pan(st, 0, -PAN_FRACTION) end, desc = 'Pan' },
      ['<Right>'] = { function() pan(st, PAN_FRACTION, 0) end, desc = 'Pan' },
      -- Wheel and trackpad: vertical scroll pans, horizontal scroll pans
      -- sideways, and Ctrl plus wheel zooms.
      ['<ScrollWheelUp>'] = { function() pan(st, 0, -SCROLL_FRACTION) end, desc = 'Pan' },
      ['<ScrollWheelDown>'] = { function() pan(st, 0, SCROLL_FRACTION) end, desc = 'Pan' },
      ['<ScrollWheelLeft>'] = { function() pan(st, -SCROLL_FRACTION, 0) end, desc = 'Pan' },
      ['<ScrollWheelRight>'] = { function() pan(st, SCROLL_FRACTION, 0) end, desc = 'Pan' },
      ['<C-ScrollWheelUp>'] = { function() zoom(st, ZOOM_STEP) end, desc = 'Zoom in' },
      ['<C-ScrollWheelDown>'] = { function() zoom(st, 1 / ZOOM_STEP) end, desc = 'Zoom out' },
    },
  })
  -- The crop is baked for one window size; a resize of this window needs a
  -- new one. WinResized fires for every window in the tab, so filter.
  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    callback = function(ev)
      if ev.event == 'VimResized' or vim.tbl_contains(vim.v.event.windows or {}, st.win.win) then
        render(st)
      end
    end,
  })
  render(st)
  return st
end

---@param src string image path, URL, or anything snacks can convert
---@param label? string
---@param cb? fun(st: custom.ImageViewer?)
function M.open(src, label, cb)
  cb = cb or function() end
  if vim.fn.executable('magick') == 0 then
    return cb(vim.notify('ImageMagick (magick) is required for the image viewer', vim.log.levels.ERROR))
  end
  -- Detect first: the terminal probe snacks starts on FileType may still be
  -- in flight, and env() would then cache the terminal as unsupported for
  -- the whole session.
  require('snacks.image.terminal').detect(function()
    if not require('snacks.image').supports_terminal() then
      vim.notify('Terminal cannot show images, opening externally', vim.log.levels.WARN)
      local job, err = vim.ui.open(src)
      if not job then
        vim.notify('Could not open externally: ' .. tostring(err), vim.log.levels.ERROR)
      end
      return cb(nil)
    end
    local is_url = require('snacks.image.convert').is_url(src)
    if not is_url and vim.fn.filereadable(src) == 0 then
      vim.notify('Image not found: ' .. src, vim.log.levels.ERROR)
      return cb(nil)
    end
    label = (label == nil or label == '') and vim.fn.fnamemodify(src, ':t') or label
    -- A local PNG is cropped as is: snacks' conversion would first scale it
    -- down to 1920x1080, which is exactly the detail the viewer is for.
    -- ponytail: other rasters take that downscale, since the size probe used
    -- here reads PNG headers only; measure with magick identify to lift it.
    if not is_url and vim.fn.fnamemodify(src, ':e'):lower() == 'png' then
      return cb(show(src, label))
    end
    -- Anything else (jpg, svg, pdf, url, a mermaid source) goes through
    -- snacks' converter and lands as the same cached PNG the inline renderer
    -- uses.
    when_ready(require('snacks.image.image').new(src), function(ok)
      if not ok then
        vim.notify('Could not render ' .. label .. ', see :checkhealth snacks', vim.log.levels.ERROR)
        return cb(nil)
      end
      cb(show(require('snacks.image.image').new(src).file, label))
    end)
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
