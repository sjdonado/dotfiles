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
obj.refreshIntervalSeconds = 1
obj.currentQuery = ""
obj.currentChoices = {}
obj.logger = hs.logger.new('KillProcess', 'info')

-- Configuration options
obj.maxResults = 1000 -- Maximum number of results to show

--- KillProcess:init()
--- Method
--- Initialize the spoon
function obj:init()
  return self
end

--- KillProcess:createChooser()
--- Method
--- Create a new chooser instance
function obj:createChooser()
  if self.chooser then
    self.chooser:delete()
  end

  self.chooser = hs.chooser.new(function(choice)
    if choice then
      local success = hs.execute(string.format("kill %d", choice.pid))
      if success then
        hs.alert.show(string.format("Killed: %s", choice.name), 2)
      else
        hs.alert.show(string.format("❌ Failed to kill: %s", choice.name), 2)
      end
    end
  end)

  self.chooser:rows(10)
  self.chooser:width(40)
  self.chooser:searchSubText(true)
  self.chooser:queryChangedCallback(function(query)
    self.currentQuery = query
  end)

  -- Set choices to use a function for real-time updates
  self.chooser:choices(function()
    return self:getFilteredChoices()
  end)

  -- Automatically cleanup when chooser is hidden
  self.chooser:hideCallback(function()
    if self.refreshTimer then
      self.refreshTimer:stop()
      self.refreshTimer = nil
    end
    if self.chooser then
      self.chooser:delete()
      self.chooser = nil
    end
  end)
end

--- KillProcess:getFilteredChoices()
--- Method
--- Get filtered choices based on current query with priority-based search
function obj:getFilteredChoices()
  local allProcesses = self:getProcessList()
  local choices = {}

  -- Safety check
  if not allProcesses or #allProcesses == 0 then
    return {}
  end

  -- No search query - return all processes
  if not self.currentQuery or self.currentQuery == "" then
    for _, process in ipairs(allProcesses) do
      if process then
        table.insert(choices, process)
      end
    end
    return choices
  end

  -- Search filtering
  local query = self.currentQuery:lower()
  local prefixMatches = {}
  local wordPrefixMatches = {}
  local containsMatches = {}

  -- Helper functions for different match types
  local function fuzzyMatch(str, pattern)
    if not str or not pattern then return false end
    local i = 1
    for j = 1, #pattern do
      i = str:find(pattern:sub(j, j), i)
      if not i then return false end
      i = i + 1
    end
    return true
  end

  -- Check if text starts with query (exact prefix match)
  local function hasPrefixMatch(text, pattern)
    if not text or not pattern then return false end
    local success, result = pcall(function()
      return text:find("^" .. pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")) ~= nil
    end)
    return success and result or false
  end

  -- Check if any word starts with query (word prefix match)
  local function hasWordStartingWith(text, pattern)
    if not text or not pattern or pattern == "" then return false end
    local success, result = pcall(function()
      return text:find('%f[%w]' .. pattern:gsub('[%-%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')) ~= nil
    end)
    return success and result or false
  end

  -- Categorize matches by priority
  for _, process in ipairs(allProcesses) do
    if not process then goto continue end

    local name = (process.text or ""):lower()
    local subText = (process.subText or ""):lower()
    local fullPath = (process.fullPath or ""):lower()

    local matched = false

    -- Priority 1: Exact prefix matches (process name starts with query)
    if hasPrefixMatch(name, query) then
      table.insert(prefixMatches, process)
      matched = true
      -- Priority 2: Word prefix matches (any word in name/path starts with query)
    elseif hasWordStartingWith(name, query) or hasWordStartingWith(fullPath, query) then
      table.insert(wordPrefixMatches, process)
      matched = true
    end

    -- Priority 3: Contains matches (if not already matched as prefix)
    if not matched then
      if name:find(query, 1, true) or subText:find(query, 1, true) or
          fullPath:find(query, 1, true) or fuzzyMatch(name, query) then
        table.insert(containsMatches, process)
      end
    end

    ::continue::
  end

  -- Sort each priority group by memory usage (descending)
  local function sortByMemory(a, b)
    return (a and a.mem or 0) > (b and b.mem or 0)
  end

  table.sort(prefixMatches, sortByMemory)
  table.sort(wordPrefixMatches, sortByMemory)
  table.sort(containsMatches, sortByMemory)

  -- Combine results: prefix matches first, then word prefix matches, then contains matches
  for _, process in ipairs(prefixMatches) do
    table.insert(choices, process)
  end
  for _, process in ipairs(wordPrefixMatches) do
    table.insert(choices, process)
  end
  for _, process in ipairs(containsMatches) do
    table.insert(choices, process)
  end

  return choices
end

--- KillProcess:getProcessList()
--- Method
--- Get list of running processes
function obj:getProcessList()
  -- Get ALL processes including kernel tasks and parent info
  local success, output = pcall(hs.execute, "ps -axo pid,ppid,pcpu,rss,command")
  if not success or not output then
    self.logger:e("Failed to execute ps command: " .. tostring(output))
    return {}
  end

  local processes = {}
  local appProcesses = {} -- Map app names to their processes
  local lineCount = 0
  local processedCount = 0

  for line in output:gmatch("[^\r\n]+") do
    lineCount = lineCount + 1

    -- Skip header line
    if not line:match("^%s*PID") then
      -- Parse: PID PPID %CPU RSS COMMAND (handle all processes including 0 memory ones)
      local pid, ppid, cpu, rss, command = line:match("^%s*(%d+)%s+(%d+)%s+([%d%.]+)%s+(%d+)%s+(.*)")

      -- Also try to capture processes that might have 0 or missing RSS
      if not pid then
        pid, ppid, cpu, command = line:match("^%s*(%d+)%s+(%d+)%s+([%d%.]+)%s+%-%s+(.*)")
        rss = "0"
      end

      if pid and cpu and tonumber(pid) and tonumber(pid) >= 0 then
        processedCount = processedCount + 1

        local pidNum = tonumber(pid)
        local ppidNum = tonumber(ppid) or 0

        -- Get base app name for grouping
        local baseAppName = self:getBaseAppName(command)

        -- Store process info for app grouping
        if not appProcesses[baseAppName] then
          appProcesses[baseAppName] = {}
        end
        table.insert(appProcesses[baseAppName], {
          pid = pidNum,
          ppid = ppidNum,
          command = command,
          cpu = cpu,
          rss = rss
        })

        -- Extract process name with app grouping logic
        local processName = self:extractProcessName(command, baseAppName, appProcesses[baseAppName])

        -- Ensure we have a valid process name
        if processName and processName ~= "" then
          -- Get memory usage (allow 0 memory processes)
          local memKB = tonumber(rss) or 0

          -- Convert RSS (KB) to MB or GB for display
          local memDisplay
          if memKB >= 1024 * 1024 then -- >= 1GB
            memDisplay = string.format("%.1f GB", memKB / (1024 * 1024))
          elseif memKB >= 1024 then    -- >= 1MB
            memDisplay = string.format("%.0f MB", memKB / 1024)
          else
            memDisplay = string.format("%.0f KB", memKB)
          end

          -- Create process entry with safe values
          local pidNum = tonumber(pid)
          local cpuNum = tonumber(cpu)

          if pidNum and cpuNum then
            table.insert(processes, {
              text = processName or "Unknown",
              subText = string.format("PID: %s | PPID: %s | CPU: %s%% | Memory: %s | %s",
                pid, ppid, cpu, memDisplay, command or ""),
              pid = pidNum,
              ppid = ppidNum,
              cpu = tonumber(cpu),
              mem = memKB, -- Store raw KB for sorting
              memDisplay = memDisplay,
              name = processName,
              fullPath = command
            })
          end
        end
      end
    end
  end

  -- Debug logging
  self.logger:d(string.format("Processed %d lines, found %d valid processes, returning %d processes",
    lineCount, processedCount, #processes))

  -- Limit results to maxResults
  if #processes > self.maxResults then
    local limitedProcesses = {}
    for i = 1, self.maxResults do
      table.insert(limitedProcesses, processes[i])
    end
    processes = limitedProcesses
  end

  -- Sort by memory usage (descending)
  table.sort(processes, function(a, b) return a.mem > b.mem end)

  return processes
end

--- KillProcess:show()
--- Method
--- Show the process chooser
function obj:show()
  self:createChooser()
  self.currentQuery = ""
  self.chooser:show()

  if self.refreshTimer then
    self.refreshTimer:stop()
  end
  self.refreshTimer = hs.timer.doEvery(self.refreshIntervalSeconds, function()
    if self.chooser and self.chooser:isVisible() then
      self.chooser:refreshChoicesCallback()
    end
  end)
end

--- KillProcess:hide()
--- Method
--- Hide the process chooser
function obj:hide()
  if self.chooser then
    self.chooser:hide()
  end
end

--- KillProcess:toggle()
--- Method
--- Toggle the process chooser visibility
function obj:toggle()
  if self.chooser and self.chooser:isVisible() then
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

--- KillProcess:configure(options)
--- Method
--- Configure the spoon with custom options
---
--- Parameters:
---  * options - A table containing configuration options:
---    * maxResults - Maximum number of results to show (default: 1000)
---    * refreshIntervalSeconds - How often to refresh the process list (default: 1)
function obj:configure(options)
  if options.maxResults then
    self.maxResults = options.maxResults
  end
  if options.refreshIntervalSeconds then
    self.refreshIntervalSeconds = options.refreshIntervalSeconds
  end
  return self
end

--- KillProcess:extractProcessName(command, baseAppName, appProcessList)
--- Method
--- Extract a clean process name from the command string, with helper suffix for auxiliary app processes
function obj:extractProcessName(command, baseAppName, appProcessList)
  if not command or command == "" then
    return "Unknown"
  end

  -- Handle IP address network processes that belong to an app (e.g., Spotify network processes)
  if command:match("^%d+%.%d+%.%d+%.%d+$") then
    -- If we have app context from the grouping, use it
    if baseAppName and baseAppName ~= "Unknown" and baseAppName ~= command then
      return baseAppName .. " - Network"
    else
      return "Network (" .. command .. ")"
    end
  end

  -- Get the base process name first
  local processName = self:getSimpleProcessName(command)

  -- If this app has multiple processes, determine which is main and which are helpers
  if appProcessList and #appProcessList > 1 then
    local isMainProcess = self:isMainAppProcess(command, baseAppName, appProcessList)

    -- If it's the main process, return early without any suffix
    if isMainProcess then
      return processName
    end

    -- This is a helper process - add appropriate suffix
    -- Don't add suffix if process name already contains Helper, Daemon, etc.
    if processName:match("[Hh]elper") or processName:match("[Dd]aemon") or
        processName:match("%(Helper%)") or processName:match("%(Daemon%)") then
      return processName
    end

    -- Determine if it's a helper or daemon based on process characteristics
    if processName:match("daemon") or processName:match("service") or processName:match("worker") or
        processName:match("monitor") or processName:match("mgr") then
      return processName .. " (Daemon)"
    else
      -- Mark as helper for auxiliary app processes
      return processName .. " (Helper)"
    end
  end

  return processName
end

--- KillProcess:getSimpleProcessName(command)
--- Method
--- Extract a simple process name from the command string
function obj:getSimpleProcessName(command)
  if not command or command == "" then
    return "Unknown"
  end

  -- Handle IP addresses (return the IP for grouping)
  if command:match("^%d+%.%d+%.%d+%.%d+$") then
    return command
  end

  -- Handle Electron apps (app.asar)
  if command:match("app%.asar") then
    local pathAppName = command:match("/([^/]+)%.app/") or command:match("([A-Z][%w%s]+)")
    if pathAppName then
      return pathAppName .. " - Electron"
    end
    return "Electron App"
  end

  -- Handle bracketed process names like [kernel_task]
  local bracketName = command:match("^%[(.+)%]$")
  if bracketName then
    return bracketName
  end

  -- Extract process name from full path
  local processName = command:match("([^/]+)$") or command:match("^(%S+)") or command

  -- Remove .app extension if present
  processName = processName:gsub("%.app$", "")

  -- Remove common executable suffixes
  processName = processName:gsub("%.bin$", "")

  -- Handle processes with arguments by taking only the first part
  processName = processName:match("^([^%s]+)") or processName

  -- XPC services
  if processName:match("%.xpc$") then
    processName = processName:gsub("%.xpc$", " (XPC)")
  end

  return processName
end

--- KillProcess:getBaseAppName(command)
--- Method
--- Extract base application name for grouping processes
function obj:getBaseAppName(command)
  if not command or command == "" then
    return "Unknown"
  end

  -- Handle IP address processes - look for app context
  if command:match("^%d+%.%d+%.%d+%.%d+$") then
    -- Look for app bundle in the path or environment
    local appName = command:match("([^/]+)%.app/")
    if appName then
      return appName
    end
    -- Check if the IP appears to be launched from an app directory
    local pathAppName = command:match("/([^/]+)%.app/") or command:match("/Applications/([^/]+)/")
    if pathAppName then
      return pathAppName
    end
    -- Return the IP as fallback for grouping
    return command
  end

  -- Extract app name from .app bundle path
  local appName = command:match("([^/]+)%.app/")
  if appName then
    return appName
  end

  -- For IP address processes, return as is for grouping
  if command:match("^%d+%.%d+%.%d+%.%d+$") then
    return command
  end

  -- For non-app processes, use the executable name
  local execName = command:match("([^/]+)$") or command:match("^(%S+)") or command

  -- Clean up the name
  execName = execName:gsub("%.app$", "")
  execName = execName:gsub("%.bin$", "")
  execName = execName:match("^([^%s]+)") or execName

  return execName
end

--- KillProcess:isMainAppProcess(command, baseAppName, appProcessList)
--- Method
--- Determine if this is the main process for an application
function obj:isMainAppProcess(command, baseAppName, appProcessList)
  if not command or not appProcessList or #appProcessList <= 1 then
    return true
  end

  -- Main process detection priority:
  -- 1. The one that's directly in the .app/Contents/MacOS/ path (highest priority)
  -- 2. The one without "Helper", "GPU", "Renderer", "Content", etc. in the name
  -- 3. The one that matches the base app name exactly

  -- Debug logging
  self.logger:d(string.format("Checking if main process for: %s (baseApp: %s)",
    command, tostring(baseAppName)))

  -- First check if this is the main executable path - this is the strongest indicator
  if command:match("%.app/Contents/MacOS/[^/]+$") then
    self.logger:d("Detected as main process: MacOS path match")
    return true
  end

  -- Check if this looks like a helper process based on command content
  if command:match("[Hh]elper") or command:match("GPU") or command:match("Renderer") or
      command:match("Content") or command:match("Utility") or command:match("Network") or
      command:match("--type=") or command:match("--variation") then
    self.logger:d("Detected as helper process: keyword match")
    return false
  end

  -- Check if the command is exactly the app name or contains the app directly
  local simpleName = self:getSimpleProcessName(command)
  if simpleName == baseAppName then
    return true
  end

  -- For single word app names, check if command contains just the app name
  if baseAppName and command:match("/" .. baseAppName .. "$") then
    return true
  end

  -- If we can't determine and it doesn't have helper indicators, assume it's main
  return true
end

return obj
