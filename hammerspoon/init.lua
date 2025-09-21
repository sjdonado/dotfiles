hs.loadSpoon("LaunchOrToggleFocus")
spoon.LaunchOrToggleFocus:bindApps({
  calendar   = { hotkey = { { "alt", "shift" }, "c" }, app = "Calendar" },
  chatgpt    = { hotkey = { { "alt", "shift" }, "g" }, app = "ChatGPT" },
  chromium   = { hotkey = { { "alt", "shift" }, "d" }, app = "Chromium" },
  excalidraw = { hotkey = { { "alt", "shift" }, "x" }, app = "Excalidraw" },
  figma      = { hotkey = { { "alt", "shift" }, "i" }, app = "Figma" },
  ghostty    = { hotkey = { { "alt", "shift" }, ";" }, app = "Ghostty" },
  googlemeet = { hotkey = { { "alt", "shift" }, "u" }, app = "Google Meet" },
  linear     = { hotkey = { { "alt", "shift" }, "l" }, app = "Linear" },
  mail       = { hotkey = { { "alt", "shift" }, "m" }, app = "Mail" },
  notes      = { hotkey = { { "alt", "shift" }, "n" }, app = "Notes" },
  postico    = { hotkey = { { "alt", "shift" }, "e" }, app = "Postico 2" },
  reminders  = { hotkey = { { "alt", "shift" }, "r" }, app = "Reminders" },
  safari     = { hotkey = { { "alt", "shift" }, "b" }, app = "Safari" },
  slack      = { hotkey = { { "alt", "shift" }, "s" }, app = "Slack" },
  spotify    = { hotkey = { { "alt", "shift" }, "y" }, app = "Spotify" },
  translate  = { hotkey = { { "alt", "shift" }, "t" }, app = "Kagi Translate" },
  yaak       = { hotkey = { { "alt", "shift" }, "h" }, app = "Yaak" },
  zed        = { hotkey = { { "alt", "shift" }, "space" }, app = "Zed" },
})

hs.loadSpoon("KillProcess")
spoon.KillProcess:bindHotkeys({
  show = { { "alt", "shift" }, "=" }
})

hs.loadSpoon("WindowManager")
spoon.WindowManager:bindHotkeys({
  left_half = { { "cmd", "shift" }, "left" },
  right_half = { { "cmd", "shift" }, "right" },
  top_half = { { "cmd", "shift" }, "up" },
  bottom_half = { { "cmd", "shift" }, "down" },
  center = { { "cmd", "shift" }, "return" },
  maximize = { { "cmd", "shift" }, "m" },
  almost_max = { { "cmd", "shift" }, "a" },
  reasonable = { { "cmd", "shift" }, "r" }
})

-- Auto-reload config when init.lua changes
local function reloadConfig(files)
  local doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
      break
    end
  end
  if doReload then
    hs.reload()
  end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon Config Loaded")
