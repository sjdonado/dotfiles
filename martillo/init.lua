-- Load Martillo
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup {
  -- LaunchOrToggleFocus: App switching hotkeys
  {
    "LaunchOrToggleFocus",
    opts = {
      calendar   = { hotkey = { { "alt", "shift" }, "c" }, app = "Calendar" },
      chatgpt    = { hotkey = { { "alt", "shift" }, "g" }, app = "ChatGPT" },
      chromium   = { hotkey = { { "alt", "shift" }, "d" }, app = "Chromium" },
      excalidraw = { hotkey = { { "alt", "shift" }, "x" }, app = "Excalidraw" },
      figma      = { hotkey = { { "alt", "shift" }, "i" }, app = "Figma" },
      ghostty    = { hotkey = { { "alt", "shift" }, "space" }, app = "Ghostty" },
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
      zed        = { hotkey = { { "alt", "shift" }, ";" }, app = "Zed" },
    },
  },

  -- ActionsLauncher: Command palette with actions
  {
    "ActionsLauncher",
    opts = function()
      return require("config.actions")
    end,
    keys = {
      { { "alt", "shift" }, "\\", desc = "Toggle Actions Launcher" }
    },
  },

  -- KillProcess: Process killer
  {
    "KillProcess",
    keys = {
      { { "alt", "shift" }, "=", desc = "Toggle Kill Process" }
    },
  },

  -- WindowManager: Window manipulation
  {
    "WindowManager",
    keys = {
      { { "cmd", "shift" }, "left",   "left_half",   desc = "Move window to left half" },
      { { "cmd", "shift" }, "right",  "right_half",  desc = "Move window to right half" },
      { { "cmd", "shift" }, "up",     "top_half",    desc = "Move window to top half" },
      { { "cmd", "shift" }, "down",   "bottom_half", desc = "Move window to bottom half" },
      { { "cmd", "shift" }, "return", "center",      desc = "Center window" },
    },
  },

  -- MySchedule: Personal scheduling
  {
    "MySchedule",
    config = function(spoon)
      spoon:compile()
      spoon:start()
    end,
  },

  -- ClipboardHistory: Clipboard manager
  {
    "ClipboardHistory",
    config = function(spoon)
      spoon:compile()
      spoon:start()
    end,
    keys = {
      { { "alt", "shift" }, "-", desc = "Toggle Clipboard History" }
    },
  },

  -- BrowserRedirect: Smart browser routing
  {
    "BrowserRedirect",
    opts = {
      defaultBrowser = "Safari",
      redirect = {
        { match = { "*localhost*", "*127.0.0.1*", "*0.0.0.0*" }, browser = "Chromium" },
        { match = { "*autarc.energy*" },                         browser = "Chromium" },
        { match = { "*fly.dev*" },                               browser = "Chromium" },
        { match = { "*linear*" },                                browser = "Linear" },
      },
      mapper = {
        { name = "googleToKagiHomepage", from = "*google.com*",         to = "https://kagi.com/" },
        { name = "googleToKagiSearch",   from = "*google.com*/search*", to = "https://kagi.com/search?q={query.q|encode}" }
      },
    },
    config = function(spoon)
      spoon:start()
    end,
  },
}
