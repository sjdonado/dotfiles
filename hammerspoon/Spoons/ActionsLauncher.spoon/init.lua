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
obj.singleActions = {}
obj.singleHandlers = {}
obj.originalChoices = {}
obj.uuidCounter = 0
obj.liveQueries = nil

--- ActionsLauncher:init()
--- Method
--- Initialize the spoon
function obj:init()
  -- LiveQueries will be set from config
  self.liveQueries = nil
  return self
end

--- ActionsLauncher:createChooser()
--- Method
--- Create a new chooser instance
function obj:createChooser()
  if self.chooser then
    self.chooser:delete()
    self.chooser = nil
  end

  self.chooser = hs.chooser.new(function(choice)
    if not choice or not choice.uuid then return end

    local handler = self.singleHandlers[choice.uuid]
    if not handler then return end

    local result = handler()
    if result and type(result) == "string" and result ~= "" then
      if choice.copyToClipboard then
        hs.pasteboard.setContents(result)
        hs.alert.show("Copied to clipboard: " .. result)
      else
        hs.alert.show(result)
      end
    end
  end)

  self.chooser:rows(10)
  self.chooser:width(50)
  self.chooser:searchSubText(true)
  self.chooser:placeholderText("Search actions...")

  -- Set up query change callback for interactive actions
  self.chooser:queryChangedCallback(function(query)
    self:handleQueryChange(query)
  end)

  -- Set initial choices
  self.chooser:choices(self.originalChoices)

  -- Automatically cleanup when chooser is hidden
  self.chooser:hideCallback(function()
    if self.chooser then
      self.chooser:delete()
      self.chooser = nil
    end
  end)
end

--- ActionsLauncher:setup(config)
--- Method
--- Setup the ActionsLauncher with actions and interactive options
---
--- Parameters:
---  * config - A table containing:
---    * single - A table of single-result action definitions (optional)
---    * live - A table of enabled live query IDs (optional)
function obj:setup(config)
  config = config or {}

  -- Setup actions
  self.singleActions = config.single or {}
  self.singleHandlers = {}

  -- Setup live queries directly from config
  self.liveQueries = config.live or {}

  -- Convert actions to chooser format and store handlers
  self.originalChoices = {}
  for i, action in ipairs(self.singleActions) do
    local uuid = action.id or tostring(i)
    self.singleHandlers[uuid] = action.handler

    self.originalChoices[i] = {
      text = action.name,
      subText = action.description or "",
      uuid = uuid,
      copyToClipboard = false
    }
  end

  return self
end

--- ActionsLauncher:show()
--- Method
--- Show the actions chooser
function obj:show()
  self:createChooser()
  self.chooser:show()
end

--- ActionsLauncher:hide()
--- Method
--- Hide the actions chooser
function obj:hide()
  if self.chooser then
    self.chooser:hide()
  end
end

--- ActionsLauncher:toggle()
--- Method
--- Toggle the actions chooser visibility
function obj:toggle()
  if self.chooser and self.chooser:isVisible() then
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

  if not self.liveQueries or #self.liveQueries == 0 then
    self:filterOriginalChoices(query)
    return
  end

  local context = {
    launcher = self,
    liveChoices = liveChoices,
    callbacks = self.singleHandlers,
    generateUUID = function() return self:generateUUID() end,
    createColorSwatch = function(r, g, b) return self:createColorSwatch(r, g, b) end
  }

  -- Handle all live queries
  for _, liveQuery in ipairs(self.liveQueries) do
    if liveQuery.enabled and
        ((liveQuery.query and liveQuery.query == query) or
          (liveQuery.pattern and liveQuery.pattern(query))) then
      liveQuery.handler(query, context)
      break
    end
  end

  -- Show results
  if #liveChoices > 0 then
    self.chooser:choices(liveChoices)
  else
    self:filterOriginalChoices(query)
  end
end

--- ActionsLauncher:filterOriginalChoices(query)
--- Method
--- Filter original choices based on query
---
--- Parameters:
---  * query - The search query
function obj:filterOriginalChoices(query)
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

--- ActionsLauncher:createColorSwatch(r, g, b)
--- Method
--- Create a small color swatch image for color previews
---
--- Parameters:
---  * r - Red component (0-255)
---  * g - Green component (0-255)
---  * b - Blue component (0-255)
---
--- Returns:
---  * An hs.image object representing the color swatch
function obj:createColorSwatch(r, g, b)
  local size = { w = 20, h = 20 }
  local canvas = hs.canvas.new(size)

  canvas[1] = {
    type = "rectangle",
    frame = { x = 0, y = 0, w = size.w, h = size.h },
    fillColor = { red = r / 255, green = g / 255, blue = b / 255, alpha = 1.0 },
    strokeColor = { red = 0.5, green = 0.5, blue = 0.5, alpha = 1.0 },
    strokeWidth = 1
  }

  local image = canvas:imageFromCanvas()
  canvas:delete()
  return image
end

--- ActionsLauncher:setQuery(query)
--- Method
--- Set the search query programmatically
---
--- Parameters:
---  * query - The query string to set
function obj:setQuery(query)
  if self.chooser then
    self.chooser:query(query)
  end
end

--- ActionsLauncher:replaceQuery(query)
--- Method
--- Set the search query and keep chooser open
---
--- Parameters:
---  * query - The query string to set
function obj:replaceQuery(query)
  if self.chooser then
    self.chooser:query(query)
    hs.timer.doAfter(0, function()
      self:show()
    end)
  end
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

return obj
