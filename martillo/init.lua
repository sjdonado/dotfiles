-- Load Martillo
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup({
  -- LaunchOrToggleFocus: App switching hotkeys
  {
    "LaunchOrToggleFocus",
    keys = {
      { "<leader>", "c",  app = "Calendar" },
      { "<leader>", "\\", app = "ChatGPT" },
      { "<leader>", "d",  app = "Chromium" },
      { "<leader>", "x",  app = "Excalidraw" },
      { "<leader>", "i",  app = "Figma" },
      { "<leader>", "g",  app = "Ghostty" },
      { "<leader>", "u",  app = "Google Meet" },
      { "<leader>", "l",  app = "Linear" },
      { "<leader>", "e",  app = "Mail" },
      { "<leader>", "m",  app = "Music" },
      { "<leader>", "n",  app = "Notes" },
      { "<leader>", "p",  app = "Postico 2" },
      { "<leader>", "r",  app = "Reminders" },
      { "<leader>", "b",  app = "Safari" },
      { "<leader>", "s",  app = "Slack" },
      { "<leader>", "t",  app = "Kagi Translate" },
      { "<leader>", "h",  app = "Yaak" },
      { "<leader>", ";",  app = "Zed" },
    },
  },

  -- ActionsLauncher: Command palette with actions
  {
    "ActionsLauncher",
    opts = function()
      return require("config.actions")
    end,
    keys = {
      { "<leader>", "space", desc = "Toggle Actions Launcher" },
    },
  },

  -- KillProcess: Process killer
  {
    "KillProcess",
    keys = {
      { "<leader>", "=", desc = "Toggle Kill Process" },
    },
  },

  -- WindowManager: Window manipulation
  {
    "WindowManager",
    keys = {
      { "<leader>", "left",   "left_half",   desc = "Move window to left half" },
      { "<leader>", "right",  "right_half",  desc = "Move window to right half" },
      { "<leader>", "up",     "top_half",    desc = "Move window to top half" },
      { "<leader>", "down",   "bottom_half", desc = "Move window to bottom half" },
      { "<leader>", "return", "center",      desc = "Center window" },
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
      spoon:start()
    end,
    keys = {
      { "<leader>", "-", desc = "Toggle Clipboard History" },
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
}, {
  leader_key = { "alt", "ctrl" },
})
