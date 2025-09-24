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
  mail       = { hotkey = { { "alt", "shift" }, "e" }, app = "Mail" },
  music      = { hotkey = { { "alt", "shift" }, "m" }, app = "Music" },
  notes      = { hotkey = { { "alt", "shift" }, "n" }, app = "Notes" },
  postico    = { hotkey = { { "alt", "shift" }, "p" }, app = "Postico 2" },
  reminders  = { hotkey = { { "alt", "shift" }, "r" }, app = "Reminders" },
  safari     = { hotkey = { { "alt", "shift" }, "b" }, app = "Safari" },
  slack      = { hotkey = { { "alt", "shift" }, "s" }, app = "Slack" },
  translate  = { hotkey = { { "alt", "shift" }, "t" }, app = "Kagi Translate" },
  yaak       = { hotkey = { { "alt", "shift" }, "h" }, app = "Yaak" },
  zed        = { hotkey = { { "alt", "shift" }, "space" }, app = "Zed" },
})

hs.loadSpoon("ActionsLauncher")
spoon.ActionsLauncher:setup({
  actions = {
    -- Window Management Actions
    {
      name = "Maximize Window",
      callback = function() spoon.WindowManager:moveWindow("max") end,
      description = "Maximize window to full screen"
    },
    {
      name = "Center Window",
      callback = function() spoon.WindowManager:moveWindow("center") end,
      description = "Center window in current position"
    },
    {
      name = "Almost Maximize",
      callback = function() spoon.WindowManager:moveWindow("almost_max") end,
      description = "Resize window to 90% of screen, centered"
    },
    {
      name = "Reasonable Size",
      callback = function() spoon.WindowManager:moveWindow("reasonable") end,
      description = "Resize window to reasonable size (50%x70%), centered"
    },

    -- System Actions
    {
      name = "Toggle Caffeinate",
      callback = function()
        spoon.ActionsLauncher.executeShell(
          "if pgrep caffeinate > /dev/null; then pkill caffeinate && echo 'Caffeinate disabled'; else nohup caffeinate -disu > /dev/null 2>&1 & echo 'Caffeinate enabled'; fi",
          "Toggle Caffeinate")
      end,
      description = "Toggle system sleep prevention"
    },
    {
      name = "Toggle System Appearance",
      callback = function()
        spoon.ActionsLauncher.executeAppleScript([[
          tell application "System Events"
            tell appearance preferences
              set dark mode to not dark mode
              if dark mode then
                return "Dark mode enabled"
              else
                return "Light mode enabled"
              end if
            end tell
          end tell
        ]], "Toggle System Appearance")
      end,
      description = "Toggle between light and dark mode"
    },

    -- Utility Actions
    {
      name = "Copy IP",
      callback = function()
        spoon.ActionsLauncher.executeShell(
          "curl -s ifconfig.me | pbcopy && curl -s ifconfig.me",
          "Copy IP")
      end,
      description = "Copy public IP address to clipboard"
    },
    {
      name = "Paste Text Without Formatting",
      callback = function()
        local clipboard = hs.pasteboard.getContents()
        if clipboard then
          hs.pasteboard.setContents(clipboard)
          hs.eventtap.event.newKeyEvent({ "cmd" }, "v", true):post()
          hs.eventtap.event.newKeyEvent({ "cmd" }, "v", false):post()
        else
          return "No text in clipboard"
        end
      end,
      description = "Paste clipboard text without formatting"
    },
  },
  live = {
    timestamp = true,
    base64 = true,
    jwt = true
  }
})

spoon.ActionsLauncher:bindHotkeys({
  toggle = { { "alt", "shift" }, "\\" } -- Use Alt+Shift+/ to toggle the actions palette
})

hs.loadSpoon("KillProcess")
spoon.KillProcess:bindHotkeys({
  toggle = { { "alt", "shift" }, "=" }
})

hs.loadSpoon("WindowManager")
spoon.WindowManager:bindHotkeys({
  left_half = { { "cmd", "shift" }, "left" },
  right_half = { { "cmd", "shift" }, "right" },
  top_half = { { "cmd", "shift" }, "up" },
  bottom_half = { { "cmd", "shift" }, "down" },
  center = { { "cmd", "shift" }, "return" },
})

hs.loadSpoon("MySchedule")
spoon.MySchedule:start()

hs.loadSpoon("ClipboardHistory")
spoon.ClipboardHistory:start()
spoon.ClipboardHistory:bindHotkeys({
  toggle = { { "alt", "shift" }, "-" }
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
