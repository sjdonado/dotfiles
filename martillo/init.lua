-- Load Martillo
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup({
  -- LaunchOrToggleFocus: App switching hotkeys
  {
    "LaunchOrToggleFocus",
    keys = {
      { { "alt", "shift" }, "c",     app = "Calendar" },
      { { "alt", "shift" }, "g",     app = "ChatGPT" },
      { { "alt", "shift" }, "d",     app = "Chromium" },
      { { "alt", "shift" }, "x",     app = "Excalidraw" },
      { { "alt", "shift" }, "i",     app = "Figma" },
      { { "alt", "shift" }, "space", app = "Ghostty" },
      { { "alt", "shift" }, "u",     app = "Google Meet" },
      { { "alt", "shift" }, "l",     app = "Linear" },
      { { "alt", "shift" }, "e",     app = "Mail" },
      { { "alt", "shift" }, "m",     app = "Music" },
      { { "alt", "shift" }, "n",     app = "Notes" },
      { { "alt", "shift" }, "p",     app = "Plane" },
      { { "alt", "shift" }, ";",     app = "Postico 2" },
      { { "alt", "shift" }, "r",     app = "Reminders" },
      { { "alt", "shift" }, "b",     app = "Safari" },
      { { "alt", "shift" }, "s",     app = "Slack" },
      { { "alt", "shift" }, "t",     app = "Kagi Translate" },
      { { "alt", "shift" }, "h",     app = "Yaak" },
      { { "alt", "shift" }, "z",     app = "Zed" },
    },
  },

  -- ActionsLauncher: Command palette with actions
  {
    "ActionsLauncher",
    opts = function()
      return require("config.actions")
    end,
    keys = {
      { { "alt", "shift" }, "\\", desc = "Toggle Actions Launcher" },
    },
  },

  -- KillProcess: Process killer
  {
    "KillProcess",
    keys = {
      { { "alt", "shift" }, "=", desc = "Toggle Kill Process" },
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
      { { "alt", "shift" }, "-", desc = "Toggle Clipboard History" },
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
        { name = "googleToKagiHomepage", from = "*google.com*", to = "https://kagi.com/" },
        {
          name = "googleToKagiSearch",
          from = "*google.com*/search*",
          to = "https://kagi.com/search?q={query.q|encode}",
        },
      },
    },
    config = function(spoon)
      spoon:start()
    end,
  },
})
