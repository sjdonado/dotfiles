--- === WindowManager ===
---
--- Window management functions - like Raycast Window Management

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowManager"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.hotkeys = {}
obj.logger = hs.logger.new('WindowManager', 'info')

--- WindowManager:init()
--- Method
--- Initialize the spoon
function obj:init()
  return self
end

--- WindowManager:getFocusedWindow()
--- Method
--- Get the focused window with retry logic
---
--- Returns:
---  * The focused window object or nil if no window is available after retries
function obj:getFocusedWindow()
  local win = hs.window.focusedWindow()
  if win then return win end

  -- Retry logic - sometimes the focused window isn't immediately available
  local maxRetries = 3
  local retryDelay = 0.05 -- 50ms

  for i = 1, maxRetries do
    hs.timer.usleep(retryDelay * 1000000) -- Convert to microseconds
    win = hs.window.focusedWindow()
    if win then return win end
  end

  return nil
end

--- WindowManager:moveWindow(direction)
--- Method
--- Move and resize the focused window
---
--- Parameters:
---  * direction - A string indicating the direction/action: "left", "right", "up", "down", "max", "center", "almost_max", "reasonable"
function obj:moveWindow(direction)
  local win = self:getFocusedWindow()
  if not win then return end

  local screen = win:screen()
  local frame = screen:frame()
  local winFrame = win:frame()

  if direction == "left" then
    winFrame.x = frame.x
    winFrame.y = frame.y
    winFrame.w = frame.w / 2
    winFrame.h = frame.h
  elseif direction == "right" then
    winFrame.x = frame.x + frame.w / 2
    winFrame.y = frame.y
    winFrame.w = frame.w / 2
    winFrame.h = frame.h
  elseif direction == "up" then
    winFrame.x = frame.x
    winFrame.y = frame.y
    winFrame.w = frame.w
    winFrame.h = frame.h / 2
  elseif direction == "down" then
    winFrame.x = frame.x
    winFrame.y = frame.y + frame.h / 2
    winFrame.w = frame.w
    winFrame.h = frame.h / 2
  elseif direction == "max" then
    winFrame = frame
  elseif direction == "center" then
    winFrame.x = frame.x + (frame.w - winFrame.w) / 2
    winFrame.y = frame.y + (frame.h - winFrame.h) / 2
  elseif direction == "almost_max" then
    -- Almost Maximize: 90% of screen, centered
    winFrame.w = frame.w * 0.9
    winFrame.h = frame.h * 0.9
    winFrame.x = frame.x + (frame.w - winFrame.w) / 2
    winFrame.y = frame.y + (frame.h - winFrame.h) / 2
  elseif direction == "reasonable" then
    -- Reasonable Size: 70% of screen, centered
    winFrame.w = frame.w * 0.6
    winFrame.h = frame.h * 0.7
    winFrame.x = frame.x + (frame.w - winFrame.w) / 2
    winFrame.y = frame.y + (frame.h - winFrame.h) / 2
  end

  win:setFrame(winFrame, 0)
end

--- WindowManager:bindHotkeys(mapping)
--- Method
--- Bind hotkeys for WindowManager
---
--- Parameters:
---  * mapping - A table containing hotkey mappings. Supported keys:
---    * left_half, right_half, top_half, bottom_half - Window halves
---    * maximize, center, almost_max, reasonable - Window sizing
function obj:bindHotkeys(mapping)
  local def = {
    left_half = hs.fnutils.partial(self.moveWindow, self, "left"),
    right_half = hs.fnutils.partial(self.moveWindow, self, "right"),
    top_half = hs.fnutils.partial(self.moveWindow, self, "up"),
    bottom_half = hs.fnutils.partial(self.moveWindow, self, "down"),
    maximize = hs.fnutils.partial(self.moveWindow, self, "max"),
    center = hs.fnutils.partial(self.moveWindow, self, "center"),
    almost_max = hs.fnutils.partial(self.moveWindow, self, "almost_max"),
    reasonable = hs.fnutils.partial(self.moveWindow, self, "reasonable")
  }
  hs.spoons.bindHotkeysToSpec(def, mapping)
  return self
end

return obj
