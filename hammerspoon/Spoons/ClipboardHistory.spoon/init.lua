--- === ClipboardHistory ===
---
--- Persistent clipboard history with fuzzy search

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
obj.history = {}
obj.historyFile = nil
obj.currentQuery = ""
obj.clipboardMonitorTask = nil

--- ClipboardHistory:init()
--- Method
--- Initialize the spoon
function obj:init()
  -- Set up history file path
  local spoonPath = hs.spoons.scriptPath()
  self.historyFile = spoonPath .. "/clipboard_history.json"

  -- Initialize chooser
  self.chooser = hs.chooser.new(function(choice)
    if choice then
      -- Move the selected entry to the top (most recent)
      self:moveToTop(choice.originalIndex)

      -- Check if there's an active input field
      if self:hasActiveInput() then
        -- Handle different content types for pasting
        self:pasteContent(choice)
      else
        -- Just copy to clipboard without pasting
        self:copyToClipboard(choice)
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

--- ClipboardHistory:start()
--- Method
--- Start monitoring clipboard changes
function obj:start()
  -- Set up clipboard watcher that triggers Objective-C monitor
  self.watcher = hs.pasteboard.watcher.new(function()
    self:onClipboardChange()
  end)
  self.watcher:start()

  -- Initial load of history
  self:loadHistory()

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

--- ClipboardHistory:onClipboardChange()
--- Method
--- Handle clipboard content changes using Objective-C component
function obj:onClipboardChange()
  -- Cancel any existing monitoring task
  if self.clipboardMonitorTask then
    self.clipboardMonitorTask:terminate()
    self.clipboardMonitorTask = nil
  end

  local spoonPath = hs.spoons.scriptPath()
  local objcPath = spoonPath .. "/clipboard_monitor.m"
  local tmpFile = os.tmpname()

  -- Check if Objective-C component exists
  local file = io.open(objcPath, "r")
  if not file then
    return
  end
  file:close()

  -- Compile and run the clipboard monitor
  local command = string.format(
    "/usr/bin/clang -framework Cocoa -framework Foundation -o %s %s && cd %s && %s",
    tmpFile, objcPath, hs.spoons.scriptPath(), tmpFile)

  self.clipboardMonitorTask = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
    os.remove(tmpFile)
    self.clipboardMonitorTask = nil

    if exitCode == 0 then
      -- Reload history from file after successful update
      self:loadHistory()
    else
      print("ClipboardHistory: Objective-C monitor failed:", stdErr or "unknown error")
    end
  end, { "-c", command })

  self.clipboardMonitorTask:start()
end

--- ClipboardHistory:loadHistory()
--- Method
--- Load clipboard history from JSON file
function obj:loadHistory()
  local file = io.open(self.historyFile, "r")
  if file then
    local content = file:read("*all")
    file:close()

    local success, data = pcall(hs.json.decode, content)
    if success and data then
      self.history = data
    else
      self.history = {}
    end
  else
    self.history = {}
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
    -- No query, show all entries
    filteredEntries = self.history
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

    for _, entry in ipairs(self.history) do
      local searchableContent = (entry.content or ""):lower()
      local searchableType = (entry.type or ""):lower()
      local searchablePreview = (entry.preview or ""):lower()

      if fuzzyMatch(searchableContent, query) or
          fuzzyMatch(searchableType, query) or
          fuzzyMatch(searchablePreview, query) or
          searchableContent:find(query, 1, true) or
          searchableType:find(query, 1, true) or
          searchablePreview:find(query, 1, true) then
        table.insert(filteredEntries, entry)
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

    -- Color schemes for different file types
    local colors = {
      image = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 },
      video = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 },
      audio = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 },
      document = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 },
      code = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 },
      file = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 }
    }

    local symbols = {
      image = "🖼",
      video = "🎬",
      audio = "🎵",
      document = "📄",
      code = "⌨",
      file = "📁"
    }

    local color = colors[fileType] or colors.file
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
    local dateDisplay = entry.date or ""
    local today = os.date("%Y-%m-%d")
    local yesterday = os.date("%Y-%m-%d", os.time() - 24 * 60 * 60)

    if entry.date == today then
      dateDisplay = "Today"
    elseif entry.date == yesterday then
      dateDisplay = "Yesterday"
    elseif entry.date then
      dateDisplay = os.date("%b %d", entry.timestamp or os.time())
    end

    -- Find original index in full history
    local originalIndex = nil
    for j, historyEntry in ipairs(self.history) do
      if historyEntry.content == entry.content and
          historyEntry.timestamp == entry.timestamp then
        originalIndex = j
        break
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
      type = entry.type,
      originalIndex = originalIndex
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
          fillColor = { red = 0.6, green = 0.6, blue = 0.6, alpha = 1.0 },
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

  self.chooser:choices(choices)
end

--- ClipboardHistory:show()
--- Method
--- Show the clipboard history chooser
function obj:show()
  self:loadHistory() -- Refresh from file

  if #self.history == 0 then
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
--- Toggle the clipboard history chooser visibility
function obj:toggle()
  if self.chooser:isVisible() then
    self:hide()
  else
    self:show()
  end
end

--- ClipboardHistory:hasActiveInput()
--- Method
--- Check if there's an active input field or text field
function obj:hasActiveInput()
  local app = hs.application.frontmostApplication()
  if not app then
    return false
  end

  local window = app:focusedWindow()
  if not window then
    return false
  end

  local element = hs.uielement.focusedElement()
  if not element then
    return false
  end

  local role = element:attributeValue("AXRole")
  local subrole = element:attributeValue("AXSubrole")
  local focused = element:attributeValue("AXFocused")
  local editable = element:attributeValue("AXEditable")

  -- Check if element is focused first
  if not focused then
    return false
  end

  -- Check for all possible text input and editable field roles
  local textInputRoles = {
    "AXTextField",
    "AXTextArea",
    "AXSecureTextField",
    "AXComboBox",
    "AXTextView",
    "AXRichText",
    "AXWebArea",
    "AXTokenField",
    "AXDatePicker",
    "AXIncrementor",
    "AXSlider",
    "AXColorWell",
    "AXPopUpButton",
    "AXCell",
    "AXStepper",
    "AXSpinButton"
  }

  local textInputSubroles = {
    "AXSearchField",
    "AXSecureTextField",
    "AXNumberField",
    "AXEmailField",
    "AXURLField",
    "AXPasswordField",
    "AXDateField",
    "AXTimeField",
    "AXTextArea",
    "AXRichTextField",
    "AXComboBoxTextField",
    "AXAutoComplete",
    "AXSearchTextField",
    "AXTokenField",
    "AXStandardWindow",
    "AXDialog",
    "AXSheet"
  }

  -- Check if element is explicitly marked as editable
  if editable then
    return true
  end

  -- Check role against known text input roles
  if role then
    for _, inputRole in ipairs(textInputRoles) do
      if role == inputRole then
        return true
      end
    end
  end

  -- Check subrole against known text input subroles
  if subrole then
    for _, inputSubrole in ipairs(textInputSubroles) do
      if subrole == inputSubrole then
        return true
      end
    end
  end

  -- Additional check for web content and rich text areas
  if role == "AXWebArea" or role == "AXTextView" or role == "AXRichText" then
    return true
  end

  -- Check for content-editable web elements
  local description = element:attributeValue("AXDescription")
  if description and (description:find("edit") or description:find("input") or description:find("text")) then
    return true
  end

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
  -- First copy to clipboard
  self:copyToClipboard(choice)

  -- Then trigger paste command
  hs.eventtap.keyStroke({ "cmd" }, "v", 0)
end

--- ClipboardHistory:moveToTop(index)
--- Method
--- Move entry at index to the top (most recent position) and save to JSON
function obj:moveToTop(index)
  if not index or index < 1 or index > #self.history then
    return
  end

  local entry = table.remove(self.history, index)
  if entry then
    -- Update timestamp and time
    entry.timestamp = os.time()
    entry.date = os.date("%Y-%m-%d")
    entry.time = os.date("%H:%M")

    -- Insert at the beginning
    table.insert(self.history, 1, entry)

    -- Save to JSON file
    self:saveHistory()
  end
end

--- ClipboardHistory:saveHistory()
--- Method
--- Save current history to JSON file
function obj:saveHistory()
  local success, jsonString = pcall(hs.json.encode, self.history)
  if success then
    local file = io.open(self.historyFile, "w")
    if file then
      file:write(jsonString)
      file:close()
    end
  end
end

--- ClipboardHistory:clear()
--- Method
--- Clear clipboard history
function obj:clear()
  self.history = {}
  self:saveHistory()
  hs.alert.show("🗑️ Clipboard history cleared", 1)
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

--- ClipboardHistory:delete()
--- Method
--- Clean up the spoon
function obj:delete()
  self:stop()
  if self.chooser then
    self.chooser:delete()
    self.chooser = nil
  end
end

return obj
