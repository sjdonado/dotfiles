--- === ActionsLauncher ===
---
--- A customizable action palette for Hammerspoon that allows you to define and execute various actions
--- through a searchable interface using callback functions.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ActionsLauncher"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.hotkeys = {}
obj.chooser = nil
obj.actions = {}
obj.callbacks = {}
obj.liveConfig = {
  timestamp = true,
  base64 = true,
  jwt = true
}
obj.originalChoices = {}
obj.uuidCounter = 0

--- ActionsLauncher:init()
--- Method
--- Initialize the spoon
function obj:init()
  self.chooser = hs.chooser.new(function(choice)
    if choice and choice.uuid and self.callbacks[choice.uuid] then
      local result = self.callbacks[choice.uuid]()
      if result and type(result) == "string" and result ~= "" then
        if choice.copyToClipboard then
          hs.pasteboard.setContents(result)
          hs.alert.show("Copied to clipboard: " .. result)
        else
          hs.alert.show(result)
        end
      end
    end
  end)

  self.chooser:placeholderText("Search actions...")
  self.chooser:searchSubText(true)
  self.chooser:rows(10)

  -- Set up query change callback for interactive actions
  self.chooser:queryChangedCallback(function(query)
    self:handleQueryChange(query)
  end)

  return self
end

--- ActionsLauncher:setup(config)
--- Method
--- Setup the ActionsLauncher with actions and interactive options
---
--- Parameters:
---  * config - A table containing:
---    * actions - A table of action definitions (optional)
---    * live - A table of live action feature flags (optional):
---      * timestamp - Enable Unix timestamp conversion (default: true)
---      * base64 - Enable Base64 decoding (default: true)
---      * jwt - Enable JWT token decoding (default: true)
function obj:setup(config)
  config = config or {}

  -- Setup actions
  self.actions = config.actions or {}
  self.callbacks = {}

  -- Setup live action features
  if config.live then
    self.liveConfig.timestamp = config.live.timestamp ~= false
    self.liveConfig.base64 = config.live.base64 ~= false
    self.liveConfig.jwt = config.live.jwt ~= false
  end

  -- Convert actions to chooser format and store callbacks
  local choices = {}
  for i, action in ipairs(self.actions) do
    local uuid = tostring(i) -- Simple UUID based on index

    -- Store the callback with the UUID
    self.callbacks[uuid] = action.callback

    -- Create chooser choice
    table.insert(choices, {
      text = action.name,
      subText = action.description or "",
      uuid = uuid,
      copyToClipboard = false
    })
  end

  self.originalChoices = choices
  self.chooser:choices(choices)
  return self
end

--- ActionsLauncher:show()
--- Method
--- Show the actions chooser
function obj:show()
  self.chooser:show()
end

--- ActionsLauncher:hide()
--- Method
--- Hide the actions chooser
function obj:hide()
  self.chooser:hide()
end

--- ActionsLauncher:toggle()
--- Method
--- Toggle the actions chooser visibility
function obj:toggle()
  if self.chooser:isVisible() then
    self:hide()
  else
    self:show()
  end
end

--- ActionsLauncher:handleQueryChange(query)
--- Method
--- Handle query changes for live actions
---
--- Parameters:
---  * query - The current search query
function obj:handleQueryChange(query)
  if not query or query == "" then
    self.chooser:choices(self.originalChoices)
    return
  end

  local liveChoices = {}

  -- Check if query is a Unix timestamp (10 or 13 digits)
  if self.liveConfig.timestamp and string.match(query, "^%d+$") and (string.len(query) == 10 or string.len(query) == 13) then
    local timestamp = tonumber(query)
    if timestamp then
      -- Convert to seconds if it's milliseconds
      if string.len(query) == 13 then
        timestamp = timestamp / 1000
      end

      local isoString = os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)
      local uuid = self:generateUUID()
      table.insert(liveChoices, {
        text = "Unix Timestamp → ISO String",
        subText = isoString,
        uuid = uuid,
        copyToClipboard = true
      })

      -- Store the callback for this conversion
      self.callbacks[uuid] = function()
        return isoString
      end
    end
  end

  -- Check if query is Base64 (basic check for valid Base64 characters and length)
  if self.liveConfig.base64 and string.match(query, "^[A-Za-z0-9+/]*={0,2}$") and string.len(query) >= 4 and string.len(query) % 4 == 0 then
    local success, decoded = pcall(function()
      return hs.base64.decode(query)
    end)

    if success and decoded and decoded ~= "" then
      local uuid = self:generateUUID()
      table.insert(liveChoices, {
        text = "Base64 → Plain Text",
        subText = decoded,
        uuid = uuid,
        copyToClipboard = true
      })

      -- Store the callback for this conversion
      self.callbacks[uuid] = function()
        return decoded
      end
    end
  end

  -- Check if query is a JWT token (has 3 parts separated by dots)
  if self.liveConfig.jwt then
    local jwtParts = {}
    for part in string.gmatch(query, "[^%.]+") do
      table.insert(jwtParts, part)
    end

    if #jwtParts == 3 then
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
        local headerUuid = self:generateUUID()
        table.insert(liveChoices, {
          text = "JWT → Decoded Header",
          subText = header,
          uuid = headerUuid,
          copyToClipboard = true
        })

        -- Store the callback for header conversion
        self.callbacks[headerUuid] = function()
          return header
        end
      end

      -- Add payload option if successful
      if payloadSuccess and payload and payload ~= "" then
        local payloadUuid = self:generateUUID()
        table.insert(liveChoices, {
          text = "JWT → Decoded Payload",
          subText = payload,
          uuid = payloadUuid,
          copyToClipboard = true
        })

        -- Store the callback for payload conversion
        self.callbacks[payloadUuid] = function()
          return payload
        end
      end
    end
  end

  -- If we found live action matches, show only those, otherwise show filtered original choices
  if #liveChoices > 0 then
    self.chooser:choices(liveChoices)
  else
    -- Filter original choices based on query
    local filteredChoices = {}
    local lowerQuery = string.lower(query)

    for _, choice in ipairs(self.originalChoices) do
      if string.find(string.lower(choice.text), lowerQuery, 1, true) or
          string.find(string.lower(choice.subText or ""), lowerQuery, 1, true) then
        table.insert(filteredChoices, choice)
      end
    end

    self.chooser:choices(filteredChoices)
  end
end

--- ActionsLauncher:generateUUID()
--- Method
--- Generate a unique identifier for live actions
---
--- Returns:
---  * A unique string identifier
function obj:generateUUID()
  self.uuidCounter = self.uuidCounter + 1
  return "interactive_" .. tostring(self.uuidCounter) .. "_" .. tostring(os.time())
end

--- ActionsLauncher:bindHotkeys(mapping)
--- Method
--- Bind hotkeys for ActionsLauncher
---
--- Parameters:
---  * mapping - A table containing hotkey mappings. Supported keys:
---    * show - Show the actions chooser
---    * toggle - Toggle the actions chooser
function obj:bindHotkeys(mapping)
  local def = {
    show = function() self:show() end,
    toggle = function() self:toggle() end
  }
  hs.spoons.bindHotkeysToSpec(def, mapping)
  return self
end

--- ActionsLauncher.executeShell(command, actionName)
--- Function
--- Execute a shell command with error handling and user feedback
---
--- Parameters:
---  * command - The shell command to execute
---  * actionName - The name of the action (for user feedback)
function obj.executeShell(command, actionName)
  local task = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      local output = stdOut and stdOut:gsub("%s+$", "") or ""
      if output ~= "" then
        hs.alert.show(output)
      else
        hs.alert.show(actionName .. " completed")
      end
    else
      hs.alert.show(actionName .. " failed: " .. (stdErr or "Unknown error"))
    end
  end, { "-c", command })
  task:start()
end

--- ActionsLauncher.executeAppleScript(script, actionName)
--- Function
--- Execute an AppleScript with error handling and user feedback
---
--- Parameters:
---  * script - The AppleScript to execute
---  * actionName - The name of the action (for user feedback)
function obj.executeAppleScript(script, actionName)
  local success, result = hs.applescript.applescript(script)
  if success then
    if result ~= "" then
      hs.alert.show(result)
    else
      hs.alert.show(actionName .. " completed")
    end
  else
    hs.alert.show(actionName .. " failed: " .. (result or "Unknown error"))
  end
  return result
end

return obj
