-- Load Martillo
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.martillo/?.lua"

return require("martillo").setup({
  -- Global configuration
  leader_key = { "alt", "ctrl" },

  -- LaunchOrToggleFocus: App switching hotkeys
  {
    "LaunchOrToggleFocus",
    keys = {
      { "<leader>", "c", app = "Calendar" },
      { "<leader>", "d", app = "Chromium" },
      { "<leader>", "x", app = "Excalidraw" },
      { "<leader>", "i", app = "Figma" },
      { "<leader>", ";", app = "Ghostty" },
      { "<leader>", "u", app = "Google Meet" },
      { "<leader>", "l", app = "Linear" },
      { "<leader>", "e", app = "Mail" },
      { "<leader>", "m", app = "Music" },
      { "<leader>", "n", app = "Notes" },
      { "<leader>", "p", app = "Postico 2" },
      { "<leader>", "r", app = "Reminders" },
      { "<leader>", "b", app = "Safari" },
      { "<leader>", "s", app = "Slack" },
      { "<leader>", "t", app = "Kagi Translate" },
      { "<leader>", "h", app = "Yaak" },
    },
  },

  -- ActionsLauncher: Command palette with window management actions
  {
    "ActionsLauncher",
    opts = function()
      return require("config.actions")
    end,
    actions = {
      static = {
        -- Window management actions
        { "window_left_third", keys = { { "<leader>", "left" } } },
        { "window_right_third", keys = { { "<leader>", "right" } } },
        { "window_almost_maximize", keys = { { "<leader>", "up" } } },
        { "window_reasonable_size", keys = { { "<leader>", "down" } } },
        { "window_center", keys = { { "<leader>", "return" } } },
        { "window_maximize", alias = "wm" },
        -- System actions
        { "toggle_caffeinate", alias = "tc" },
        { "toggle_system_appearance", alias = "ta" },
        { "copy_ip", alias = "gi" },
        { "generate_uuid", alias = "gu" },
        { "network_status" },
      },
      dynamic = {
        "timestamp",
        "colors",
        "base64",
        "jwt",
      },
    },
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

  -- MySchedule: Calendar integration that displays today's events in the menu bar
  {
    "MySchedule",
    config = function(spoon)
      spoon:compile()
      spoon:start()
    end,
  },

  -- BrowserRedirect: Smart browser routing
  {
    "BrowserRedirect",
    opts = {
      defaultBrowser = "Safari",
      redirect = {
        { match = { "*localhost*", "*127.0.0.1*", "*0.0.0.0*" }, browser = "Chromium" },
        { match = { "*autarc.energy*" }, browser = "Chromium" },
        { match = { "*fly.dev*" }, browser = "Chromium" },
        { match = { "*linear*" }, browser = "Linear" },
      },
    },
    config = function(spoon)
      spoon:start()
    end,
  },
})
