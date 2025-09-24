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
  single = {
    -- Window Management Actions
    {
      id = "maximize_window",
      name = "Maximize Window",
      handler = function() spoon.WindowManager:moveWindow("max") end,
      description = "Maximize window to full screen"
    },
    {
      id = "almost_maximize",
      name = "Almost Maximize",
      handler = function() spoon.WindowManager:moveWindow("almost_max") end,
      description = "Resize window to 90% of screen, centered"
    },
    {
      id = "reasonable_size",
      name = "Reasonable Size",
      handler = function() spoon.WindowManager:moveWindow("reasonable") end,
      description = "Resize window to reasonable size (50%x70%), centered"
    },

    -- System Actions
    {
      id = "toggle_caffeinate",
      name = "Toggle Caffeinate",
      handler = function()
        spoon.ActionsLauncher.executeShell(
          "if pgrep caffeinate > /dev/null; then pkill caffeinate && echo 'Caffeinate disabled'; else nohup caffeinate -disu > /dev/null 2>&1 & echo 'Caffeinate enabled'; fi",
          "Toggle Caffeinate")
      end,
      description = "Toggle system sleep prevention"
    },
    {
      id = "toggle_system_appearance",
      name = "Toggle System Appearance",
      handler = function()
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
      id = "copy_ip",
      name = "Copy IP",
      handler = function()
        spoon.ActionsLauncher.executeShell(
          "curl -s ifconfig.me | pbcopy && curl -s ifconfig.me",
          "Copy IP")
      end,
      description = "Copy public IP address to clipboard"
    },
    {
      id = "generate_uuid",
      name = "Generate UUID",
      handler = function()
        spoon.ActionsLauncher.executeShell(
          "uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '\\n' | pbcopy && pbpaste",
          "Generate UUID")
      end,
      description = "Generate UUID v4 and copy to clipboard"
    },
    {
      id = "network_status",
      name = "Network Status",
      handler = function()
        spoon.ActionsLauncher:replaceQuery("Network Status")
      end,
      description = "Check network connectivity and status"
    },
  },
  live = {
    {
      id = "timestamp",
      enabled = true,
      pattern = function(query)
        return string.match(query, "^%d+$") and
            (string.len(query) == 10 or string.len(query) == 13)
      end,
      handler = function(query, context)
        local timestamp = tonumber(query)
        if timestamp then
          -- Convert to seconds if it's milliseconds
          if string.len(query) == 13 then
            timestamp = timestamp / 1000
          end

          local isoString = os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)
          local uuid = context.generateUUID()

          table.insert(context.liveChoices, {
            text = "Unix Timestamp → ISO String",
            subText = isoString,
            uuid = uuid,
            copyToClipboard = true
          })

          context.callbacks[uuid] = function()
            return isoString
          end
        end
      end
    },

    {
      id = "base64",
      enabled = true,
      pattern = function(query)
        return string.match(query, "^[A-Za-z0-9+/]*={0,2}$") and string.len(query) >= 4 and
            string.len(query) % 4 == 0
      end,
      handler = function(query, context)
        local success, decoded = pcall(function()
          return hs.base64.decode(query)
        end)

        if success and decoded and decoded ~= "" then
          local uuid = context.generateUUID()
          table.insert(context.liveChoices, {
            text = "Base64 → Plain Text",
            subText = decoded,
            uuid = uuid,
            copyToClipboard = true
          })

          context.callbacks[uuid] = function()
            return decoded
          end
        end
      end
    },

    {
      id = "jwt",
      enabled = true,
      pattern = function(query)
        local jwtParts = {}
        for part in string.gmatch(query, "[^%.]+") do
          table.insert(jwtParts, part)
        end
        return #jwtParts == 3
      end,
      handler = function(query, context)
        local jwtParts = {}
        for part in string.gmatch(query, "[^%.]+") do
          table.insert(jwtParts, part)
        end

        -- Decode JWT header (first part)
        local headerSuccess, header = pcall(function()
          local paddedHeader = jwtParts[1]
          -- Convert URL-safe Base64 to standard Base64
          paddedHeader = paddedHeader:gsub("-", "+"):gsub("_", "/")
          -- Add padding if needed for base64 decoding
          local padding = 4 - (string.len(paddedHeader) % 4)
          if padding < 4 then
            paddedHeader = paddedHeader .. string.rep("=", padding)
          end
          return hs.base64.decode(paddedHeader)
        end)

        -- Decode JWT payload (second part)
        local payloadSuccess, payload = pcall(function()
          local paddedPayload = jwtParts[2]
          -- Convert URL-safe Base64 to standard Base64
          paddedPayload = paddedPayload:gsub("-", "+"):gsub("_", "/")
          -- Add padding if needed for base64 decoding
          local padding = 4 - (string.len(paddedPayload) % 4)
          if padding < 4 then
            paddedPayload = paddedPayload .. string.rep("=", padding)
          end
          return hs.base64.decode(paddedPayload)
        end)

        -- Add header option if successful
        if headerSuccess and header and header ~= "" then
          local headerUuid = context.generateUUID()
          table.insert(context.liveChoices, {
            text = "JWT → Decoded Header",
            subText = header,
            uuid = headerUuid,
            copyToClipboard = true
          })

          context.callbacks[headerUuid] = function()
            return header
          end
        end

        -- Add payload option if successful
        if payloadSuccess and payload and payload ~= "" then
          local payloadUuid = context.generateUUID()
          table.insert(context.liveChoices, {
            text = "JWT → Decoded Payload",
            subText = payload,
            uuid = payloadUuid,
            copyToClipboard = true
          })

          context.callbacks[payloadUuid] = function()
            return payload
          end
        end
      end
    },

    {
      id = "colors",
      enabled = true,
      pattern = function(query)
        -- Check for RGB format: rgb(255,128,64) or 255,128,64
        local r, g, b = string.match(query, "rgb%s*%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%)")
        if r and g and b then return true end

        r, g, b = string.match(query, "^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
        if r and g and b then return true end

        -- Check for HEX format: #ff8040 or ff8040
        local hex = string.match(query,
          "^#?([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])$")
        return hex ~= nil
      end,
      handler = function(query, context)
        -- Handle RGB to HEX conversion
        local r, g, b = string.match(query, "rgb%s*%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%)")
        if not r then
          r, g, b = string.match(query, "^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
        end

        if r and g and b then
          r, g, b = tonumber(r), tonumber(g), tonumber(b)
          if r and g and b and r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
            local hex = string.format("#%02x%02x%02x", r, g, b)
            local uuid = context.generateUUID()

            table.insert(context.liveChoices, {
              text = "RGB → HEX",
              subText = hex,
              uuid = uuid,
              copyToClipboard = true,
              image = context.createColorSwatch(r, g, b)
            })

            context.callbacks[uuid] = function()
              return hex
            end
          end
          return
        end

        -- Handle HEX to RGB conversion
        local hex = string.match(query,
          "^#?([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])$")
        if hex then
          local rHex = string.sub(hex, 1, 2)
          local gHex = string.sub(hex, 3, 4)
          local bHex = string.sub(hex, 5, 6)

          local r = tonumber(rHex, 16)
          local g = tonumber(gHex, 16)
          local b = tonumber(bHex, 16)

          if r and g and b then
            local rgb = string.format("rgb(%d, %d, %d)", r, g, b)
            local uuid = context.generateUUID()

            table.insert(context.liveChoices, {
              text = "HEX → RGB",
              subText = rgb,
              uuid = uuid,
              copyToClipboard = true,
              image = context.createColorSwatch(r, g, b)
            })

            context.callbacks[uuid] = function()
              return rgb
            end
          end
        end
      end
    },

    {
      id = "networkstatus",
      enabled = true,
      query = "Network Status",
      handler = function(query, context)
        -- Check if we have cached results
        if _G.networkTestCache and _G.networkTestCache.timestamp and
            (os.time() - _G.networkTestCache.timestamp) < 30 then
          -- Show cached results (fresh for 30 seconds)
          for _, result in ipairs(_G.networkTestCache.results) do
            table.insert(context.liveChoices, result)
          end
          return
        end

        -- Check if test is already running
        if _G.networkTestRunning then
          table.insert(context.liveChoices, {
            text = "⏳ Loading...",
            subText = "Checking network status, please wait...",
            uuid = "network_loading"
          })
          return
        end

        -- Start new test
        _G.networkTestRunning = true
        table.insert(context.liveChoices, {
          text = "⏳ Loading...",
          subText = "Checking network status, please wait...",
          uuid = "network_loading"
        })

        -- Start the actual network test
        local networkTestTask = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
          _G.networkTestRunning = false

          local networkTestChoices = {}

          if exitCode ~= 0 then
            table.insert(networkTestChoices, {
              text = "❌ Network Test Failed",
              subText = "Unable to reach network",
              uuid = "network_error"
            })
            table.insert(networkTestChoices, {
              text = "🔄 Try Again",
              subText = "Retry the network test",
              uuid = "network_retry"
            })

            context.callbacks["network_retry"] = function()
              _G.networkTestCache = nil
              context.launcher:replaceQuery("Network Status")
              return ""
            end
          else
            -- Parse ping result
            local pingLatency = "Unable to measure"
            local pingLine = stdOut:match(
              "round%-trip min/avg/max/stddev = [%d%.]+/([%d%.]+)/[%d%.]+/[%d%.]+ ms")
            if pingLine then
              pingLatency = string.format("%.1f ms", tonumber(pingLine))
            end

            -- Get connection status
            local status = pingLatency ~= "Unable to measure" and "✅ Connected" or "❌ Disconnected"

            -- Create result items
            table.insert(networkTestChoices, {
              text = "Network Status",
              subText = status,
              uuid = "network_status"
            })

            table.insert(networkTestChoices, {
              text = "Latency",
              subText = pingLatency,
              uuid = "network_ping"
            })

            table.insert(networkTestChoices, {
              text = "Run Again",
              subText = "Check network status again",
              uuid = "network_rerun"
            })

            -- Store callback for rerun
            context.callbacks["network_rerun"] = function()
              _G.networkTestCache = nil
              context.launcher:replaceQuery("Network Status")
              return ""
            end
          end

          -- Cache results
          _G.networkTestCache = {
            results = networkTestChoices,
            timestamp = os.time()
          }

          -- Trigger a refresh by setting the query again
          context.launcher:replaceQuery("Network Status")
        end, { "-c", "ping -c 3 -W 2000 1.1.1.1" })

        networkTestTask:start()
      end
    }
  }
})

spoon.ActionsLauncher:bindHotkeys({
  toggle = { { "alt", "shift" }, "\\" }
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
