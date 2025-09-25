--- === ClipboardHistory ===
---
--- Persistent clipboard history with fuzzy search and optimized loading
---
--- Performance Features:
--- • Loads most recent items initially using fast Objective-C component
--- • Unlimited scalable SQLite database with FTS5 full-text search
--- • Smart memory buffer for instant access
--- • Native Objective-C SQLite integration for maximum performance

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ClipboardHistory"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.chooser = nil
obj.hotkeys = {}
obj.watcher = nil
obj.maxRecentEntries = 100 -- Maximum number of recent entries to load initially
obj.historyBuffer = {}     -- Memory buffer with most recent entries
obj.dbFile = nil
obj.currentQuery = ""
obj.clipboardMonitorTask = nil
obj.sqliteReaderBinary = nil
obj.clipboardMonitorBinary = nil

--- ClipboardHistory:init()
--- Method
--- Initialize the spoon
function obj:init()
  -- Set up database file path
  local spoonPath = hs.spoons.scriptPath()
  self.dbFile = spoonPath .. "/clipboard_history.db"

  -- Initialize chooser
  self:initializeChooser()

  return self
end

--- ClipboardHistory:initializeChooser()
--- Method
--- Initialize or reinitialize the chooser with fresh state
function obj:initializeChooser()
  -- Destroy existing chooser if it exists
  if self.chooser then
    self.chooser:delete()
    self.chooser = nil
  end

  -- Create new chooser
  self.chooser = hs.chooser.new(function(choice)
    if choice then
      if choice.isLoadMore then
        -- Load more entries and reopen chooser
        self:loadAllHistory()
        local query = self.chooser:query()
        self.chooser:query(query)
        hs.timer.doAfter(0, function()
          self:show()
        end)
      else
        -- Try to paste by default, fall back to copy only in specific cases
        local shouldJustCopy = self:shouldOnlyCopy()

        if shouldJustCopy then
          -- Just copy to clipboard without pasting
          self:copyToClipboard(choice)
        else
          -- Handle different content types for pasting
          self:pasteContent(choice)
        end
      end
    end
  end)

  self.chooser:rows(10)
  self.chooser:searchSubText(true)
  self.chooser:queryChangedCallback(function(query)
    self.currentQuery = query
    self:updateChoices()
  end)

  -- Reset to show only historyBuffer (most recent entries)
  self.currentQuery = ""
  self:initializeBuffer()
end

--- ClipboardHistory:start()
--- Method
--- Start monitoring clipboard changes
function obj:start()
  -- Set up clipboard watcher that triggers Objective-C monitor
  self.watcher = hs.pasteboard.watcher.new(function()
    self:onClipboardChange()
  end)
  self.watcher:start()

  -- Initialize buffer with first entries
  self:initializeBuffer()

  return self
end

--- ClipboardHistory:stop()
--- Method
--- Stop monitoring clipboard changes
function obj:stop()
  if self.watcher then
    self.watcher:stop()
    self.watcher = nil
  end
  if self.clipboardMonitorTask then
    self.clipboardMonitorTask:terminate()
    self.clipboardMonitorTask = nil
  end
  return self
end

--- ClipboardHistory:compileClipboardMonitor()
--- Method
--- Compile the SQLite clipboard monitor binary if needed
function obj:compileClipboardMonitor()
  if self.clipboardMonitorBinary then
    return self.clipboardMonitorBinary
  end

  local spoonPath = hs.spoons.scriptPath()
  local monitorPath = spoonPath .. "/clipboard_monitor_sqlite.m"
  local binaryPath = spoonPath .. "/clipboard_monitor_sqlite_bin"

  -- Check if Objective-C source exists
  local file = io.open(monitorPath, "r")
  if not file then
    return nil
  end
  file:close()

  -- Check if binary already exists and is newer than source
  local sourceAttr = hs.fs.attributes(monitorPath)
  local binaryAttr = hs.fs.attributes(binaryPath)

  if binaryAttr and sourceAttr and binaryAttr.modification >= sourceAttr.modification then
    self.clipboardMonitorBinary = binaryPath
    return binaryPath
  end

  -- Compile the binary
  local compileCmd = string.format(
    "/usr/bin/clang -framework Cocoa -framework Foundation -lsqlite3 -o %s %s",
    binaryPath, monitorPath)
  local result = os.execute(compileCmd)

  if result == 0 then
    self.clipboardMonitorBinary = binaryPath
    return binaryPath
  else
    return nil
  end
end

--- ClipboardHistory:onClipboardChange()
--- Method
--- Handle clipboard content changes using cached Objective-C component
function obj:onClipboardChange()
  -- Cancel any existing monitoring task
  if self.clipboardMonitorTask then
    self.clipboardMonitorTask:terminate()
    self.clipboardMonitorTask = nil
  end

  local binaryPath = self:compileClipboardMonitor()
  if not binaryPath then
    return
  end

  -- Run the SQLite clipboard monitor from spoon directory
  local spoonPath = hs.spoons.scriptPath()
  local sqliteMonitorPath = spoonPath .. "/clipboard_monitor_sqlite_bin"
  local command = string.format("cd %s && %s", spoonPath, sqliteMonitorPath)

  self.clipboardMonitorTask = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
    self.clipboardMonitorTask = nil

    if exitCode == 0 and stdOut then
      -- Parse the new entry from stdout and add to buffer
      self:addToBuffer(stdOut)
    else
      print("ClipboardHistory: SQLite monitor failed:", stdErr or "unknown error")
    end
  end, { "-c", command })

  self.clipboardMonitorTask:start()
end

--- ClipboardHistory:compileSqliteReader()
--- Method
--- Compile the SQLite reader binary if needed
function obj:compileSqliteReader()
  if self.sqliteReaderBinary then
    return self.sqliteReaderBinary
  end

  local spoonPath = hs.spoons.scriptPath()
  local sqliteReaderPath = spoonPath .. "/sqlite_reader.m"
  local binaryPath = spoonPath .. "/sqlite_reader_bin"

  -- Check if Objective-C source exists
  local file = io.open(sqliteReaderPath, "r")
  if not file then
    return nil
  end
  file:close()

  -- Check if binary already exists and is newer than source
  local sourceAttr = hs.fs.attributes(sqliteReaderPath)
  local binaryAttr = hs.fs.attributes(binaryPath)

  if binaryAttr and sourceAttr and binaryAttr.modification >= sourceAttr.modification then
    self.sqliteReaderBinary = binaryPath
    return binaryPath
  end

  -- Compile the binary
  local compileCmd = string.format("/usr/bin/clang -framework Foundation -lsqlite3 -o %s %s",
    binaryPath,
    sqliteReaderPath)
  local result = os.execute(compileCmd)

  if result == 0 then
    self.sqliteReaderBinary = binaryPath
    return binaryPath
  else
    return nil
  end
end

--- ClipboardHistory:initializeBuffer()
--- Method
--- Initialize buffer with first entries from SQLite database
function obj:initializeBuffer()
  local binaryPath = self:compileSqliteReader()
  if not binaryPath then
    self.historyBuffer = {}
    return
  end

  -- Load first entries using SQLite reader
  local command = string.format("%s %s recent %d", binaryPath, self.dbFile, self.maxRecentEntries)

  local handle = io.popen(command, "r")
  if handle then
    local output = handle:read("*all")
    local success, exitCode = handle:close()

    if output and output ~= "" then
      -- Clean the output
      output = output:gsub("^%s+", ""):gsub("%s+$", "")

      if output:match("^%[") then
        local parseSuccess, data = pcall(hs.json.decode, output)
        if parseSuccess and data and type(data) == "table" then
          self.historyBuffer = data
        else
          self.historyBuffer = {}
        end
      else
        self.historyBuffer = {}
      end
    else
      self.historyBuffer = {}
    end
  else
    self.historyBuffer = {}
  end
end

--- ClipboardHistory:addToBuffer(newEntryStr)
--- Method
--- Add new entry to buffer from clipboard monitor output
function obj:addToBuffer(newEntryStr)
  if not newEntryStr or newEntryStr == "" then
    return
  end

  -- Parse the new entry (SQLite monitor outputs the entry with action info)
  local success, newEntry = pcall(hs.json.decode, newEntryStr)
  if success and newEntry and type(newEntry) == "table" then
    if newEntry.action == "moved" then
      -- Find and move existing entry to top
      for i = 1, #self.historyBuffer do
        if self.historyBuffer[i] and self.historyBuffer[i].id == newEntry.id then
          local existingEntry = table.remove(self.historyBuffer, i)
          existingEntry.timestamp = newEntry.timestamp
          existingEntry.time = newEntry.time
          table.insert(self.historyBuffer, 1, existingEntry)
          break
        end
      end
    elseif newEntry.action == "added" then
      -- Add new entry to beginning of buffer
      table.insert(self.historyBuffer, 1, newEntry)

      -- Keep only recent entries
      if #self.historyBuffer > self.maxRecentEntries then
        table.remove(self.historyBuffer)
      end
    end

    -- No need to save - SQLite handles persistence
  end
end

--- ClipboardHistory:loadAllHistory()
--- Method
--- Load all clipboard history entries from SQLite database
function obj:loadAllHistory()
  local binaryPath = self:compileSqliteReader()
  if not binaryPath then
    return
  end

  -- Load all entries from SQLite
  local command = string.format("%s %s recent 10000", binaryPath, self.dbFile)

  local handle = io.popen(command, "r")
  if handle then
    local output = handle:read("*all")
    handle:close()

    if output and output ~= "" then
      output = output:gsub("^%s+", ""):gsub("%s+$", "")
      if output:match("^%[") then
        local parseSuccess, data = pcall(hs.json.decode, output)
        if parseSuccess and data and type(data) == "table" then
          self.historyBuffer = data
        end
      end
    end
  end
end

--- ClipboardHistory:updateChoices()
--- Method
--- Update chooser choices based on current query and loaded history
function obj:updateChoices()
  local choices = {}

  -- Apply fuzzy search if query exists
  local filteredEntries = {}
  if self.currentQuery == "" then
    -- No query, show all entries from buffer
    filteredEntries = self.historyBuffer
  else
    -- Apply fuzzy search
    local query = self.currentQuery:lower()

    local function fuzzyMatch(str, pattern)
      local i = 1
      for j = 1, #pattern do
        i = str:find(pattern:sub(j, j), i)
        if not i then return false end
        i = i + 1
      end
      return true
    end

    -- Use FTS5 search with prefix matching for consistent results
    local binaryPath = self:compileSqliteReader()
    if binaryPath then
      -- Use prefix matching with * for partial word matches
      local searchQuery = query:gsub('%s+', '* ') .. '*'
      local command = string.format("%s %s search \"%s\"", binaryPath, self.dbFile,
        searchQuery:gsub('"', '\\"'))
      local handle = io.popen(command, "r")
      if handle then
        local output = handle:read("*all")
        handle:close()

        if output and output ~= "" then
          output = output:gsub("^%s+", ""):gsub("%s+$", "")
          if output:match("^%[") then
            local parseSuccess, searchResults = pcall(hs.json.decode, output)
            if parseSuccess and searchResults and type(searchResults) == "table" then
              filteredEntries = searchResults
            end
          end
        end
      end
    end

    -- Fallback to local buffer search if FTS5 fails, with prefix matching
    if #filteredEntries == 0 then
      for _, entry in ipairs(self.historyBuffer) do
        local searchableContent = (entry.content or ""):lower()
        local searchableType = (entry.type or ""):lower()
        local searchablePreview = (entry.preview or ""):lower()

        -- Check if any word starts with the query (prefix matching)
        local function hasWordStartingWith(text, pattern)
          return text:find('%f[%w]' .. pattern:gsub('[%-%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')) ~= nil
        end

        if hasWordStartingWith(searchableContent, query) or
            hasWordStartingWith(searchableType, query) or
            hasWordStartingWith(searchablePreview, query) or
            fuzzyMatch(searchableContent, query) or
            searchableContent:find(query, 1, true) then
          table.insert(filteredEntries, entry)
        end
      end
    end
  end

  -- Helper function to get file extension
  local function getFileExtension(filePath)
    if not filePath then return nil end
    return filePath:match("%.([^%.]+)$")
  end

  -- Helper function to determine file type from extension
  local function getFileTypeFromExtension(extension)
    if not extension then return "file" end
    extension = extension:lower()

    local imageExts = { "png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp", "svg", "ico" }
    local videoExts = { "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "3gp", "mpg", "mpeg" }
    local audioExts = { "mp3", "wav", "flac", "aac", "ogg", "m4a", "wma" }
    local docExts = { "pdf", "doc", "docx", "txt", "rtf", "pages" }
    local codeExts = { "js", "html", "css", "py", "lua", "swift", "java", "cpp", "c", "rb", "go",
      "rs" }

    for _, ext in ipairs(imageExts) do
      if extension == ext then return "image" end
    end
    for _, ext in ipairs(videoExts) do
      if extension == ext then return "video" end
    end
    for _, ext in ipairs(audioExts) do
      if extension == ext then return "audio" end
    end
    for _, ext in ipairs(docExts) do
      if extension == ext then return "document" end
    end
    for _, ext in ipairs(codeExts) do
      if extension == ext then return "code" end
    end

    return "file"
  end

  -- Helper function to create file type icon image
  local function getFileTypeIcon(fileType, extension)
    -- Create a simple colored square icon for different file types
    local iconSize = { w = 64, h = 64 }
    local canvas = hs.canvas.new(iconSize)

    -- Use Hammerspoon's consistent blue color for all file types
    local hammerspoonBlue = { red = 0.0, green = 0.47, blue = 1.0, alpha = 1.0 }

    local symbols = {
      image = "🖼",
      video = "🎬",
      audio = "🎵",
      document = "📄",
      code = "⌨",
      file = "📁"
    }

    local color = hammerspoonBlue
    local symbol = symbols[fileType] or symbols.file

    -- Draw background rectangle
    canvas[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = color,
      roundedRectRadii = { xRadius = 8, yRadius = 8 }
    }

    -- Draw symbol
    canvas[2] = {
      type = "text",
      text = symbol,
      textAlignment = "center",
      textSize = 32,
      textColor = { white = 1.0, alpha = 1.0 },
      frame = { x = 0, y = 12, w = 64, h = 40 }
    }

    return canvas:imageFromCanvas()
  end

  -- Convert to chooser format
  for i, entry in ipairs(filteredEntries) do
    local preview = entry.preview or entry.content or ""

    -- Truncate preview if too long
    if string.len(preview) > 80 then
      preview = string.sub(preview, 1, 77) .. "..."
    end

    -- Format date for display
    local dateDisplay = ""
    if entry.timestamp then
      local timestamp = tonumber(entry.timestamp) or 0
      local today = os.time()
      local daysDiff = math.floor((today - timestamp) / 86400)

      if daysDiff == 0 then
        dateDisplay = "Today"
      elseif daysDiff == 1 then
        dateDisplay = "Yesterday"
      else
        dateDisplay = os.date("%b %d", timestamp)
      end
    end

    -- Add size info to subtext if available
    local subText = string.format("%s • %s %s",
      entry.type or "Unknown",
      dateDisplay,
      entry.time or "")

    if entry.size and entry.size ~= "" then
      subText = string.format("%s • %s • %s %s",
        entry.type or "Unknown",
        entry.size,
        dateDisplay,
        entry.time or "")
    end

    -- Create choice entry
    local choiceEntry = {
      text = preview,
      subText = subText,
      content = entry.content,
      timestamp = entry.timestamp,
      type = entry.type
    }

    -- Handle different content types for preview
    if entry.type == "File path" and entry.content then
      -- For file paths, determine the actual file type and add appropriate preview
      local filePath = entry.content
      local extension = getFileExtension(filePath)
      local fileType = getFileTypeFromExtension(extension)
      local fileIcon = getFileTypeIcon(fileType, extension)

      -- Set the file type icon as image instead of text
      choiceEntry.image = fileIcon

      -- Check if file exists
      local file = io.open(filePath, "r")
      if file then
        file:close()

        if fileType == "image" then
          -- Try to load image preview
          local image = hs.image.imageFromPath(filePath)
          if image then
            -- Resize image to a reasonable size for preview (max 64x64)
            local size = image:size()
            if size.w > 64 or size.h > 64 then
              local scale = math.min(64 / size.w, 64 / size.h)
              image = image:setSize({ w = size.w * scale, h = size.h * scale })
            end
            choiceEntry.image = image
          end
        elseif fileType == "video" then
          -- For videos, try to generate a thumbnail or use a default video icon
          -- Hammerspoon doesn't have built-in video thumbnail generation,
          -- but we can use the system to generate one
          local tempThumbPath = os.tmpname() .. ".jpg"
          local thumbnailCmd = string.format(
            'qlmanage -t -s 64 -o "%s" "%s" 2>/dev/null && mv "%s"/*.jpg "%s" 2>/dev/null',
            os.tmpname(), filePath, os.tmpname(), tempThumbPath
          )

          -- Try to generate thumbnail using Quick Look
          local result = os.execute(thumbnailCmd)
          if result == 0 then
            local thumbImage = hs.image.imageFromPath(tempThumbPath)
            if thumbImage then
              choiceEntry.image = thumbImage
              -- Clean up temp file after a delay
              hs.timer.doAfter(1, function()
                os.remove(tempThumbPath)
              end)
            end
          else
            -- Fallback to video icon image
            choiceEntry.image = fileIcon
          end
        else
          -- For other file types, we could add specific icons or handling
          -- For now, just use the file icon
        end
      else
        -- File doesn't exist, create a broken file icon
        local iconSize = { w = 64, h = 64 }
        local canvas = hs.canvas.new(iconSize)
        canvas[1] = {
          type = "rectangle",
          action = "fill",
          fillColor = { red = 0.0, green = 0.47, blue = 1.0, alpha = 1.0 },
          roundedRectRadii = { xRadius = 8, yRadius = 8 }
        }
        canvas[2] = {
          type = "text",
          text = "❌",
          textAlignment = "center",
          textSize = 32,
          textColor = { white = 1.0, alpha = 1.0 },
          frame = { x = 0, y = 12, w = 64, h = 40 }
        }
        choiceEntry.image = canvas:imageFromCanvas()
        choiceEntry.text = preview .. " (file not found)"
      end
    elseif entry.type and entry.type:find("image") and entry.content then
      -- Handle clipboard images (existing logic)
      local imagePath = entry.content
      local file = io.open(imagePath, "r")
      if file then
        file:close()
        local image = hs.image.imageFromPath(imagePath)
        if image then
          -- Resize image to a reasonable size for preview (max 64x64)
          local size = image:size()
          if size.w > 64 or size.h > 64 then
            local scale = math.min(64 / size.w, 64 / size.h)
            image = image:setSize({ w = size.w * scale, h = size.h * scale })
          end
          choiceEntry.image = image
        end
      end
    end

    table.insert(choices, choiceEntry)
  end

  -- Add "Load more" item if we might have more entries and no search query
  if self.currentQuery == "" and #self.historyBuffer == self.maxRecentEntries then
    local binaryPath = self:compileSqliteReader()
    local totalEntries = 0

    if binaryPath then
      local command = string.format("%s %s count", binaryPath, self.dbFile)
      local handle = io.popen(command, "r")
      if handle then
        local output = handle:read("*all")
        handle:close()
        local success, data = pcall(hs.json.decode, output)
        if success and data and data.count then
          totalEntries = data.count
        end
      end
    end

    if totalEntries > self.maxRecentEntries then
      local remainingCount = totalEntries - self.maxRecentEntries
      table.insert(choices, {
        text = "📥 Load more (" .. remainingCount .. " more entries)",
        subText = "Load remaining clipboard history entries",
        isLoadMore = true
      })
    end
  end

  self.chooser:choices(choices)
end

--- ClipboardHistory:show()
--- Method
--- Show the clipboard history chooser
function obj:show()
  if #self.historyBuffer == 0 then
    hs.alert.show("📋 Clipboard history is empty", 1)
    return
  end

  self.currentQuery = ""
  self:updateChoices()
  self.chooser:show()
end

--- ClipboardHistory:hide()
--- Method
--- Hide the clipboard history chooser
function obj:hide()
  self.chooser:hide()
end

--- ClipboardHistory:toggle()
--- Method
--- Toggle the clipboard history chooser visibility with fresh initialization
function obj:toggle()
  if self.chooser and self.chooser:isVisible() then
    self:hide()
  else
    -- Reinitialize chooser for fresh start (resets scroll, search, shows recent entries)
    self:initializeChooser()
    self:show()
  end
end

--- ClipboardHistory:shouldOnlyCopy()
--- Method
--- Check if we should only copy (not paste) - be conservative, only copy when certain we shouldn't paste
function obj:shouldOnlyCopy()
  local app = hs.application.frontmostApplication()
  if not app then
    return true -- No app, just copy
  end

  local appName = app:name()

  -- Don't paste in certain apps where it might be disruptive
  local copyOnlyApps = {
    "Finder",
    "System Preferences",
    "System Settings",
    "Activity Monitor",
    "Console"
  }

  for _, copyApp in ipairs(copyOnlyApps) do
    if appName == copyApp then
      return true
    end
  end

  -- For all other cases, try to paste
  return false
end

--- ClipboardHistory:copyToClipboard(choice)
--- Method
--- Copy content to clipboard without pasting
function obj:copyToClipboard(choice)
  if choice.type == "File path" then
    -- For file paths, check if we should copy as path or file:// URI
    local filePath = choice.content

    -- Check if file exists
    local file = io.open(filePath, "r")
    if file then
      file:close()
      -- File exists, copy as file:// URI for drag and drop compatibility
      if not filePath:match("^file://") then
        filePath = "file://" .. filePath
      end
      hs.pasteboard.setContents(filePath)
    else
      -- File doesn't exist, copy as plain text path
      hs.pasteboard.setContents(choice.content)
    end
  elseif choice.type and choice.type:find("image") then
    -- For clipboard images, copy the file path or recreate the image data
    local imagePath = choice.content
    local file = io.open(imagePath, "r")
    if file then
      file:close()
      -- If it's a temp file, try to set the actual image data
      local imageData = hs.image.imageFromPath(imagePath)
      if imageData then
        hs.pasteboard.setContents(imageData)
      else
        -- Fallback to file path
        local fileURL = imagePath
        if not fileURL:match("^file://") then
          fileURL = "file://" .. fileURL
        end
        hs.pasteboard.setContents(fileURL)
      end
    else
      hs.pasteboard.setContents(choice.content)
    end
  else
    -- For text and other types, set the content normally
    hs.pasteboard.setContents(choice.content)
  end

  -- Show a silent notification that content was copied
  hs.alert.show("📋 Copied to clipboard", 0.5)
end

--- ClipboardHistory:pasteContent(choice)
--- Method
--- Paste content based on its type
function obj:pasteContent(choice)
  -- Copy content to clipboard without showing alert
  if choice.type == "File path" then
    local filePath = choice.content
    local file = io.open(filePath, "r")
    if file then
      file:close()
      if not filePath:match("^file://") then
        filePath = "file://" .. filePath
      end
      hs.pasteboard.setContents(filePath)
    else
      hs.pasteboard.setContents(choice.content)
    end
  elseif choice.type and choice.type:find("image") then
    local imagePath = choice.content
    local file = io.open(imagePath, "r")
    if file then
      file:close()
      local imageData = hs.image.imageFromPath(imagePath)
      if imageData then
        hs.pasteboard.setContents(imageData)
      else
        local fileURL = imagePath
        if not fileURL:match("^file://") then
          fileURL = "file://" .. fileURL
        end
        hs.pasteboard.setContents(fileURL)
      end
    else
      hs.pasteboard.setContents(choice.content)
    end
  else
    hs.pasteboard.setContents(choice.content)
  end

  hs.timer.doAfter(0, function()
    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
  end)
end

--- ClipboardHistory:saveHistory()
--- Method
--- No-op since SQLite handles persistence automatically
function obj:saveHistory()
  -- SQLite handles persistence automatically, no action needed
end

--- ClipboardHistory:clear()
--- Method
--- Clear clipboard history
function obj:clear()
  self.historyBuffer = {}
  -- Clear SQLite database
  local binaryPath = self:compileSqliteReader()
  if binaryPath then
    local command = string.format(
      "sqlite3 %s 'DELETE FROM clipboard_history; DELETE FROM clipboard_fts;'", self.dbFile)
    os.execute(command)
  end
  hs.alert.show("🗑️ Clipboard history cleared", 1)
end

--- ClipboardHistory:delete()
--- Method
--- Clean up the spoon
function obj:delete()
  self:stop()
  if self.chooser then
    self.chooser:delete()
    self.chooser = nil
  end
  -- Clean up compiled binaries
  if self.sqliteReaderBinary then
    os.remove(self.sqliteReaderBinary)
    self.sqliteReaderBinary = nil
  end
  if self.clipboardMonitorBinary then
    os.remove(self.clipboardMonitorBinary)
    self.clipboardMonitorBinary = nil
  end
end

--- ClipboardHistory:bindHotkeys(mapping)
--- Method
--- Bind hotkeys for ClipboardHistory
---
--- Parameters:
---  * mapping - A table containing hotkey mappings. Supported keys:
---    * show - Show the clipboard history chooser (default: no hotkey)
---    * toggle - Toggle the clipboard history chooser visibility (default: no hotkey)
---    * clear - Clear clipboard history (default: no hotkey)
function obj:bindHotkeys(mapping)
  local def = {
    show = hs.fnutils.partial(self.show, self),
    toggle = hs.fnutils.partial(self.toggle, self),
    clear = hs.fnutils.partial(self.clear, self)
  }
  hs.spoons.bindHotkeysToSpec(def, mapping)
  return self
end

return obj
