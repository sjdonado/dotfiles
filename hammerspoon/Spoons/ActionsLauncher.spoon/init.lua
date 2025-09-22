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

--- ActionsLauncher:init()
--- Method
--- Initialize the spoon
function obj:init()
  self.chooser = hs.chooser.new(function(choice)
    if choice and choice.uuid and self.callbacks[choice.uuid] then
      local result = self.callbacks[choice.uuid]()
      if result and type(result) == "string" and result ~= "" then
        hs.alert.show(result)
      end
    end
  end)

  self.chooser:placeholderText("Search actions...")
  self.chooser:searchSubText(true)
  self.chooser:rows(10)

  return self
end

--- ActionsLauncher:defineActions(actions)
--- Method
--- Define the available actions
---
--- Parameters:
---  * actions - A table containing action definitions. Each action should have:
---    * name - The display name of the action
---    * callback - The function to execute when the action is selected
---    * description - Optional description for the action
function obj:defineActions(actions)
  self.actions = actions
  self.callbacks = {}

  -- Convert actions to chooser format and store callbacks
  local choices = {}
  for i, action in ipairs(actions) do
    local uuid = tostring(i) -- Simple UUID based on index

    -- Store the callback with the UUID
    self.callbacks[uuid] = action.callback

    -- Create chooser choice
    table.insert(choices, {
      text = action.name,
      subText = action.description or "",
      uuid = uuid
    })
  end

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
