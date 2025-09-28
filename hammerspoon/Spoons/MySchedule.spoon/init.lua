--- === MySchedule ===
---
--- Display upcoming calendar events in the menu bar with countdown timer (optimized version)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MySchedule"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.menubar = nil
obj.timer = nil
obj.updateInterval = 180 -- Update every 3 minutes
obj.cachedEvents = {}    -- Cache for events
obj.lastUpdate = 0       -- Timestamp of last update
obj.loadingTask = nil    -- Current loading task
obj.isLoading = false    -- Loading state
obj.eventkitBinary = nil -- Cached EventKit fetcher binary
obj.logger = hs.logger.new('MySchedule', 'info')

--- MySchedule:init()
--- Method
--- Initialize the spoon
function obj:init()
  self.menubar = hs.menubar.new(true, "MySchedule")
  if self.menubar then
    self.menubar:setTitle("Loading...")
    self.menubar:setTooltip("My Schedule - Loading calendar events...")
  end
  -- Trigger permission dialog if needed
  self:triggerCalendarPermissions()
  return self
end

--- MySchedule:start()
--- Method
--- Start the schedule monitoring
function obj:start()
  if self.menubar then
    self:loadEventsAsync()

    -- Set up timer to update every 3 minutes
    self.timer = hs.timer.doEvery(self.updateInterval, function()
      self:loadEventsAsync()
    end)
  end
  return self
end

--- MySchedule:stop()
--- Method
--- Stop the schedule monitoring
function obj:stop()
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end
  if self.loadingTask then
    self.loadingTask:terminate()
    self.loadingTask = nil
  end
  self.isLoading = false
  -- Clear cached binary reference (don't delete - it's managed by init.lua)
  self.eventkitBinary = nil
  return self
end

--- MySchedule:updateSchedule()
--- Method
--- Update the menu bar with current schedule information
function obj:updateSchedule()
  self.logger:d("updateSchedule called")
  local events = self.cachedEvents
  self.logger:d("updateSchedule - using " .. #events .. " cached events")

  local nextEvent = self:findNextEvent(events)
  self.logger:d("updateSchedule - nextEvent: " .. (nextEvent and nextEvent.title or "nil"))

  if nextEvent then
    local timeUntil = self:formatTimeUntil(nextEvent.startTimestamp)
    local title = string.format("%s • %s", nextEvent.title, timeUntil)
    self.logger:d("Setting menu bar title to: " .. title)

    -- Truncate if too long for menu bar
    if string.len(title) > 50 then
      title = string.sub(nextEvent.title, 1, 30) .. "... - " .. timeUntil
    end

    self.menubar:setTitle(title)
    self.menubar:setTooltip(string.format("%s\n%s", nextEvent.title, nextEvent.timeRange))
  else
    if not self.isLoading then
      self.logger:d("No next event, setting 'No events'")
      self.menubar:setTitle("No events")
      self.menubar:setTooltip("No upcoming events found")
    else
      self.logger:d("Still loading, keeping loading state")
    end
  end

  -- Update menu
  self:setMenu(nextEvent, events)
  self.logger:d("updateSchedule completed")
end

--- MySchedule:loadEventsAsync()
--- Method
--- Load events asynchronously using parallel AppleScript execution
function obj:loadEventsAsync()
  if self.isLoading then
    return
  end

  self.isLoading = true
  -- Only show "Loading..." if we don't have cached events
  if self.menubar and #self.cachedEvents == 0 then
    self.menubar:setTitle("Loading...")
  end

  -- Cancel any existing task
  if self.loadingTask then
    self.loadingTask:terminate()
    self.loadingTask = nil
  end

  -- Use native EventKit APIs through Objective-C for maximum performance
  self:loadEventsWithEventKit()
end

--- MySchedule:triggerCalendarPermissions()
--- Method
--- Trigger calendar permissions dialog through AppleScript
function obj:triggerCalendarPermissions()
  -- Use AppleScript to trigger calendar access which will show permission dialog
  hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
    -- Permissions dialog should have appeared, no need to handle result
  end, { "-e", "tell application \"Calendar\" to return count of calendars" }):start()
end

--- MySchedule:compile()
--- Method
--- Compile the EventKit fetcher binary
function obj:compile()
  local spoonPath = hs.spoons.scriptPath()
  local objcSourcePath = spoonPath .. "/eventkit_fetcher.m"
  local binaryPath = spoonPath .. "/eventkit_fetcher_bin"

  self.logger:i("🔨 Compiling EventKit fetcher...")

  -- Check if Objective-C source exists
  local file = io.open(objcSourcePath, "r")
  if not file then
    error("❌ Source file not found: " .. objcSourcePath)
  end
  file:close()

  -- Check if binary already exists and is newer than source
  local sourceAttr = hs.fs.attributes(objcSourcePath)
  local binaryAttr = hs.fs.attributes(binaryPath)

  if binaryAttr and sourceAttr and binaryAttr.modification >= sourceAttr.modification then
    self.logger:i("✅ Binary up to date")
    self.eventkitBinary = binaryPath
    return
  end

  -- Compile the binary synchronously
  local compileCmd = string.format(
    "/usr/bin/clang -fobjc-arc -framework EventKit -framework Foundation -o %s %s",
    binaryPath, objcSourcePath)

  local output, success = hs.execute(compileCmd)
  if not success then
    error("❌ Failed to compile EventKit fetcher. Command: " ..
      compileCmd .. "\nOutput: " .. (output or "no output"))
  end

  -- Verify binary was created
  local finalBinaryAttr = hs.fs.attributes(binaryPath)
  if not finalBinaryAttr then
    error("❌ Binary was not created: " .. binaryPath)
  end

  self.eventkitBinary = binaryPath
  self.logger:i("✅ Binary compiled successfully")
end

--- MySchedule:getEventKitBinary()
--- Method
--- Get the pre-compiled EventKit fetcher binary path
function obj:getEventKitBinary()
  if self.eventkitBinary then
    return self.eventkitBinary
  end

  local spoonPath = hs.spoons.scriptPath()
  local binaryPath = spoonPath .. "/eventkit_fetcher_bin"

  -- Check if binary exists (should be compiled by init.lua)
  local binaryAttr = hs.fs.attributes(binaryPath)
  if binaryAttr then
    self.eventkitBinary = binaryPath
    return binaryPath
  end

  -- Binary not found
  self.logger:e("EventKit binary not found at: " .. binaryPath)
  return nil
end

--- MySchedule:loadEventsWithEventKit()
--- Method
--- Load events using cached native EventKit binary
function obj:loadEventsWithEventKit()
  local binaryPath = self:getEventKitBinary()
  if not binaryPath then
    self.isLoading = false
    self.cachedEvents = {}
    self:updateSchedule()
    return
  end

  -- Run the cached binary
  local command = binaryPath

  self.loadingTask = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
      self.isLoading = false
      self.loadingTask = nil

      if exitCode == 0 and stdOut then
        if stdOut:find("ACCESS_DENIED") then
          hs.alert.show(
            "Calendar access denied. Please grant Hammerspoon calendar access in System Preferences > Privacy & Security > Calendar")
          self.cachedEvents = {}
        else
          self.logger:d("EventKit fetch completed")
          self:parseEventKitResult(stdOut)
        end
      else
        self.logger:e("EventKit failed: " .. (stdErr or "unknown error"))
        -- If compilation failed, it might be a permission issue
        if stdErr and stdErr:find("permission") then
          hs.alert.show(
            "Please grant Hammerspoon calendar access in System Preferences > Privacy & Security > Calendar")
        end
        self.cachedEvents = {}
        self.lastUpdate = os.time()
      end

      self:updateSchedule()
    end,
    { "-c", command })

  self.loadingTask:start()
end

--- MySchedule:parseEventKitResult(result)
--- Method
--- Parse EventKit result data
function obj:parseEventKitResult(result)
  self.logger:d("Parsing EventKit data")
  local now = os.time()

  if result and string.find(result, "COUNT:") then
    local countStr = string.match(result, "COUNT:(%d+)")
    local eventCount = tonumber(countStr) or 0
    self.logger:d("Found " .. eventCount .. " events")

    if eventCount > 0 then
      local eventData = string.match(result, "COUNT:%d+%|%|(.+)")
      if eventData then
        local events = {}
        local eventStrings = {}
        for eventStr in string.gmatch(eventData .. "||", "(.-)||") do
          if eventStr ~= "" then
            table.insert(eventStrings, eventStr)
          end
        end

        for _, singleEvent in ipairs(eventStrings) do
          local parts = {}
          for part in string.gmatch(singleEvent, "([^|]+)") do
            table.insert(parts, part)
          end

          if #parts >= 5 then
            local title = parts[1]
            local timeDiff = tonumber(parts[2]) or 0
            local timeRange = parts[3]
            local eventDescription = parts[4] ~= "" and parts[4] or ""
            local isRecurring = parts[5] == "true"

            -- Filter reasonable events (today or close)
            if timeDiff > -3600 and timeDiff < 86400 then
              local startTimestamp = now + timeDiff
              local meetingURL = self:extractMeetingURL(eventDescription)

              self.logger:d("Including event: " .. title .. " timeDiff: " .. timeDiff)
              table.insert(events, {
                title = title,
                startTimestamp = startTimestamp,
                timeRange = timeRange,
                timeDiff = timeDiff,
                isRecurring = isRecurring,
                meetingURL = meetingURL
              })
            end
          end
        end

        self.cachedEvents = events
        self.lastUpdate = now
        self.logger:d("Cached " .. #events .. " processed events")
      end
    else
      self.cachedEvents = {}
      self.lastUpdate = now
    end
  end
end

--- MySchedule:findNextEvent(events)
--- Method
--- Find the next upcoming event (prioritize events with positive timeDiff, fallback to closest event)
function obj:findNextEvent(events)
  if #events == 0 then
    self.logger:d("findNextEvent - No events provided")
    return nil
  end

  self.logger:d("findNextEvent - Processing " .. #events .. " events:")

  -- Sort events by timeDiff (closest to current time first)
  local sortedEvents = {}
  for _, event in ipairs(events) do
    table.insert(sortedEvents, event)
  end
  table.sort(sortedEvents, function(a, b) return a.timeDiff < b.timeDiff end)

  -- Debug: Print all events with their time differences
  for i, event in ipairs(sortedEvents) do
    self.logger:d(string.format("Event %d: '%s' (in %d seconds) - %s",
      i, event.title, event.timeDiff, event.timeRange))
  end

  -- Find first event that hasn't ended yet (within reasonable past threshold)
  for i, event in ipairs(sortedEvents) do
    -- Show events that are upcoming or recently started (within 30 minutes past)
    if event.timeDiff >= -1800 then -- -1800 seconds = 30 minutes ago
      self.logger:d("Selected event: " .. event.title .. " (timeDiff: " .. event.timeDiff .. ")")
      return event
    end
  end

  -- If all events are old, return the most recent one
  if #sortedEvents > 0 then
    local lastEvent = sortedEvents[#sortedEvents]
    self.logger:d("All events are old, using most recent: " .. lastEvent.title)
    return lastEvent
  end

  self.logger:d("No events found at all")
  return nil
end

--- MySchedule:formatTimeUntil(timestamp)
--- Method
--- Format the time until an event
function obj:formatTimeUntil(timestamp)
  local now = os.time()
  local seconds = timestamp - now

  if seconds < -3600 then -- More than 1 hour past
    return "ended"
  elseif seconds < 0 then
    return "now"
  elseif seconds < 60 then
    return "in <1m"
  elseif seconds < 3600 then
    local minutes = math.floor(seconds / 60)
    return string.format("in %dm", minutes)
  elseif seconds < 86400 then
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if minutes > 0 then
      return string.format("in %dh %dm", hours, minutes)
    else
      return string.format("in %dh", hours)
    end
  else
    local days = math.floor(seconds / 86400)
    return string.format("in %dd", days)
  end
end

--- MySchedule:setMenu(nextEvent, events)
--- Method
--- Set up the dropdown menu with event details
function obj:setMenu(nextEvent, events)
  local menu = {}

  -- Today's events section
  table.insert(menu, {
    title = "Today's Events",
    disabled = true
  })

  if #events == 0 then
    table.insert(menu, {
      title = "  No events today",
      disabled = true
    })
  else
    for _, event in ipairs(events) do
      local eventTitle = event.title

      -- Truncate long titles
      if string.len(eventTitle) > 35 then
        eventTitle = string.sub(eventTitle, 1, 32) .. "..."
      end

      table.insert(menu, {
        title = "  " .. event.timeRange .. " " .. eventTitle,
        fn = function()
          if event.meetingURL then
            hs.urlevent.openURL(event.meetingURL)
            hs.alert.show("Joining meeting: " .. event.title)
          else
            hs.alert.show("No meeting URL found for: " .. event.title)
          end
        end
      })
    end
  end

  table.insert(menu, {
    title = "-"
  })

  table.insert(menu, {
    title = "Open Calendar",
    fn = function()
      hs.application.launchOrFocus("Calendar")
    end
  })

  table.insert(menu, {
    title = "Grant Calendar Access",
    fn = function()
      hs.execute("open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars'")
      hs.alert.show("Manually grant 'Full Calendar access' and restart Hammerspoon")
    end
  })

  table.insert(menu, {
    title = "Refresh",
    fn = function()
      self:loadEventsAsync()
    end
  })

  self.menubar:setMenu(menu)
end

--- MySchedule:setUpdateInterval(seconds)
--- Method
--- Set the update interval
function obj:setUpdateInterval(seconds)
  self.updateInterval = seconds
  if self.timer then
    self.timer:stop()
    self.timer = hs.timer.doEvery(self.updateInterval, function()
      self:loadEventsAsync()
    end)
  end
  return self
end

--- MySchedule:extractMeetingURL(text)
--- Method
--- Extract meeting URL from event description text
function obj:extractMeetingURL(text)
  local patterns = {
    "https://[%w%-%.]*zoom%.us/[%w%-%._~:/?#%%@!$&'()*+,;=]*",
    "https://meet%.google%.com/[%w%-%._~:/?#%%@!$&'()*+,;=]*",
    "https://[%w%-%.]*teams%.microsoft%.com/[%w%-%._~:/?#%%@!$&'()*+,;=]*",
    "https://[%w%-%.]*webex%.com/[%w%-%._~:/?#%%@!$&'()*+,;=]*",
    "https://[%w%-%.]*gotomeeting%.com/[%w%-%._~:/?#%%@!$&'()*+,;=]*"
  }

  for _, pattern in ipairs(patterns) do
    local url = string.match(text, pattern)
    if url then
      return url
    end
  end

  return nil
end

--- MySchedule:delete()
--- Method
--- Clean up the spoon
function obj:delete()
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end
  if self.loadingTask then
    self.loadingTask:terminate()
    self.loadingTask = nil
  end
  if self.menubar then
    self.menubar:delete()
    self.menubar = nil
  end
  -- Clear cached binary reference (don't delete - it's managed by init.lua)
  self.eventkitBinary = nil
  self.isLoading = false
end

return obj
