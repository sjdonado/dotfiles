--- === KillProcess ===
---
--- Kill processes with fuzzy search - like Raycast Kill Process

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "KillProcess"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.chooser = nil
obj.hotkeys = {}
obj.refreshTimer = nil
obj.currentQuery = ""

--- KillProcess:init()
--- Method
--- Initialize the spoon
function obj:init()
  self.chooser = hs.chooser.new(function(choice)
    if choice then
      local success = hs.execute(string.format("kill %d", choice.pid))
      if success then
        hs.alert.show(string.format("🔪 Killed: %s", choice.name), 2)
      else
        hs.alert.show(string.format("❌ Failed to kill: %s", choice.name), 2)
      end
    end
  end)

  self.chooser:rows(10)
  self.chooser:searchSubText(true)
  self.chooser:queryChangedCallback(function(query)
    self.currentQuery = query
    self:updateChoices()
  end)

  return self
end

--- KillProcess:updateChoices()
--- Method
--- Update choices based on current query
function obj:updateChoices()
  -- Get current selection before updating
  local currentIndex = self.chooser:selectedRow()
  local currentSelection = self.chooser:selectedRowContents()

  local allProcesses = self:getProcessList()
  local newChoices = {}

  if self.currentQuery == "" then
    newChoices = allProcesses
  else
    -- Enable fuzzy search by filtering choices
    local query = self.currentQuery:lower()

    for _, process in ipairs(allProcesses) do
      local name = process.text:lower()
      local subText = process.subText:lower()

      -- Simple fuzzy matching: check if all characters of query appear in order
      local function fuzzyMatch(str, pattern)
        local i = 1
        for j = 1, #pattern do
          i = str:find(pattern:sub(j, j), i)
          if not i then return false end
          i = i + 1
        end
        return true
      end

      if fuzzyMatch(name, query) or fuzzyMatch(subText, query) or name:find(query, 1, true) then
        table.insert(newChoices, process)
      end
    end
  end

  -- Update choices
  self.chooser:choices(newChoices)

  -- Try to maintain selection on the same process (by PID)
  if currentSelection then
    local newIndex = currentIndex
    for i, process in ipairs(newChoices) do
      if process.pid == currentSelection.pid then
        newIndex = i
        break
      end
    end
    -- Restore selection, ensuring it's within bounds
    if newIndex and newIndex <= #newChoices and newIndex > 0 then
      self.chooser:selectedRow(newIndex)
    end
  end
end

--- KillProcess:getProcessList()
--- Method
--- Get list of running processes
function obj:getProcessList()
  -- Get process info with RSS (memory in KB) instead of percentage
  local output = hs.execute("ps -axo pid,pcpu,rss,comm | tail -n +2")
  local processes = {}

  for line in output:gmatch("[^\r\n]+") do
    local pid, cpu, rss, fullPath = line:match("(%d+)%s+([%d%.]+)%s+(%d+)%s+(.+)")
    if pid and tonumber(pid) > 1 then -- Skip header and kernel processes
      -- Extract just the process name from the full path
      local processName = fullPath:match("([^/]+)$") or fullPath
      -- Remove .app extension if present
      processName = processName:gsub("%.app$", "")

      -- Convert RSS (KB) to MB or GB for display
      local memKB = tonumber(rss)
      local memDisplay
      if memKB >= 1024 * 1024 then -- >= 1GB
        memDisplay = string.format("%.1f GB", memKB / (1024 * 1024))
      else
        memDisplay = string.format("%.1f MB", memKB / 1024)
      end

      table.insert(processes, {
        text = processName,
        subText = string.format("PID: %s | CPU: %s%% | Memory: %s", pid, cpu, memDisplay),
        pid = tonumber(pid),
        cpu = tonumber(cpu),
        mem = memKB, -- Store raw KB for sorting
        memDisplay = memDisplay,
        name = processName,
        fullPath = fullPath
      })
    end
  end

  -- Sort by memory usage (descending)
  table.sort(processes, function(a, b) return a.mem > b.mem end)

  return processes
end

--- KillProcess:show()
--- Method
--- Show the process chooser
function obj:show()
  self.currentQuery = ""
  self:updateChoices()
  self.chooser:show()

  -- Start refresh timer to update every 2 seconds
  if self.refreshTimer then
    self.refreshTimer:stop()
  end
  self.refreshTimer = hs.timer.doEvery(2, function()
    if self.chooser:isVisible() then
      -- Update choices while preserving current query/filter
      self:updateChoices()
    else
      -- Stop timer when chooser is not visible
      if self.refreshTimer then
        self.refreshTimer:stop()
        self.refreshTimer = nil
      end
    end
  end)
end

--- KillProcess:hide()
--- Method
--- Hide the process chooser
function obj:hide()
  self.chooser:hide()
  -- Stop refresh timer
  if self.refreshTimer then
    self.refreshTimer:stop()
    self.refreshTimer = nil
  end
end

--- KillProcess:toggle()
--- Method
--- Toggle the process chooser visibility
function obj:toggle()
  if self.chooser:isVisible() then
    self:hide()
  else
    self:show()
  end
end

--- KillProcess:bindHotkeys(mapping)
--- Method
--- Bind hotkeys for KillProcess
---
--- Parameters:
---  * mapping - A table containing hotkey mappings. Supported keys:
---    * show - Show the process chooser (default: no hotkey)
---    * toggle - Toggle the process chooser visibility (default: no hotkey)
function obj:bindHotkeys(mapping)
  local def = {
    show = hs.fnutils.partial(self.show, self),
    toggle = hs.fnutils.partial(self.toggle, self)
  }
  hs.spoons.bindHotkeysToSpec(def, mapping)
  return self
end

return obj
