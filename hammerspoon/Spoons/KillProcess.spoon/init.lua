--- === KillProcess ===
---
--- Kill processes with fuzzy search - like Raycast Kill Process
---
--- Download: https://github.com/sjdonado/dotfiles/hammerspoon/Spoons
--- Author: sjdonado
--- License: MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "KillProcess"
obj.version = "1.0"
obj.author = "Custom"
obj.homepage = "https://github.com/hammerspoon/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.chooser = nil
obj.hotkeys = {}

--- KillProcess:init()
--- Method
--- Initialize the spoon
function obj:init()
  self.chooser = hs.chooser.new(function(choice)
    if choice then
      local result = hs.dialog.blockAlert("Kill Process",
        string.format("Are you sure you want to kill '%s' (PID: %d)?", choice.name, choice.pid),
        "Kill", "Cancel")

      if result == "Kill" then
        local success = hs.execute(string.format("kill %d", choice.pid))
        if success then
          hs.alert.show(string.format("🔪 Killed: %s", choice.name), 2)
        else
          hs.alert.show(string.format("❌ Failed to kill: %s", choice.name), 2)
        end
      end
    end
  end)

  self.chooser:rows(15)
  self.chooser:searchSubText(true)
  self.chooser:queryChangedCallback(function(query)
    if query == "" then
      self.chooser:choices(self:getProcessList())
    else
      -- Enable fuzzy search by filtering choices
      local allProcesses = self:getProcessList()
      local filteredProcesses = {}
      query = query:lower()

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
          table.insert(filteredProcesses, process)
        end
      end

      self.chooser:choices(filteredProcesses)
    end
  end)

  return self
end

--- KillProcess:getProcessList()
--- Method
--- Get list of running processes
function obj:getProcessList()
  local output = hs.execute("ps -axo pid,pcpu,pmem,comm | sort -k2 -nr | head -50")
  local processes = {}

  for line in output:gmatch("[^\r\n]+") do
    local pid, cpu, mem, fullPath = line:match("(%d+)%s+([%d%.]+)%s+([%d%.]+)%s+(.+)")
    if pid and tonumber(pid) > 1 then -- Skip header and kernel processes
      -- Extract just the process name from the full path
      local processName = fullPath:match("([^/]+)$") or fullPath
      -- Remove .app extension if present
      processName = processName:gsub("%.app$", "")

      table.insert(processes, {
        text = processName,
        subText = string.format("PID: %s | CPU: %s%% | Memory: %s%%", pid, cpu, mem),
        pid = tonumber(pid),
        cpu = tonumber(cpu),
        mem = tonumber(mem),
        name = processName,
        fullPath = fullPath
      })
    end
  end

  return processes
end

--- KillProcess:show()
--- Method
--- Show the process chooser
function obj:show()
  self.chooser:choices(self:getProcessList())
  self.chooser:show()
end

--- KillProcess:bindHotkeys(mapping)
--- Method
--- Bind hotkeys for KillProcess
---
--- Parameters:
---  * mapping - A table containing hotkey mappings. Supported keys:
---    * show - Show the process chooser (default: no hotkey)
function obj:bindHotkeys(mapping)
  local def = {
    show = hs.fnutils.partial(self.show, self)
  }
  hs.spoons.bindHotkeysToSpec(def, mapping)
  return self
end

return obj
