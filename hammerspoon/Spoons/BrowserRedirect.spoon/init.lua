--- === BrowserRedirect ===
---
--- Intelligent URL routing to different browsers based on patterns
--- Simple Lua implementation using `open -a` command

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "BrowserRedirect"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.defaultBrowser = "Safari"
obj.handlers = {}
obj.isActive = false

--- BrowserRedirect:init()
--- Method
--- Initialize the spoon
function obj:init()
  return self
end

--- BrowserRedirect:setup(config)
--- Method
--- Setup the BrowserRedirect with configuration
---
--- Parameters:
---  * config - A table containing:
---    * defaultBrowser - Default browser name (string)
---    * handlers - Array of handler tables with 'match' patterns and 'browser' name
function obj:setup(config)
  if not config then
    return self
  end

  self.defaultBrowser = config.defaultBrowser or "Safari"
  self.handlers = config.handlers or {}

  return self
end

--- BrowserRedirect:start()
--- Method
--- Start URL interception by registering URL scheme handlers
function obj:start()
  if self.isActive then
    return self
  end

  -- Register URL event handlers
  hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
    self:handleURL(fullURL)
  end

  hs.urlevent.httpsCallback = function(scheme, host, params, fullURL, senderPID)
    self:handleURL(fullURL)
  end

  self.isActive = true

  return self
end

--- BrowserRedirect:stop()
--- Method
--- Stop URL interception
function obj:stop()
  if not self.isActive then
    return self
  end

  -- Clear URL callbacks
  hs.urlevent.httpCallback = nil
  hs.urlevent.httpsCallback = nil

  self.isActive = false
  hs.alert.show("BrowserRedirect: URL routing stopped", 1)

  return self
end

--- BrowserRedirect:handleURL(url)
--- Method
--- Handle incoming URL and redirect to appropriate browser
---
--- Parameters:
---  * url - The full URL to handle
function obj:handleURL(url)
  if not url then
    return
  end

  local targetBrowser = self:findMatchingBrowser(url)

  -- Open URL in the determined browser
  local openCmd = string.format('open -a "%s" "%s"', targetBrowser, url)
  local output, success = hs.execute(openCmd)

  if not success then
    -- Fallback to system default
    hs.urlevent.openURL(url)
  end
end

--- BrowserRedirect:findMatchingBrowser(url)
--- Method
--- Find the appropriate browser for a given URL based on configured handlers
---
--- Parameters:
---  * url - The URL to match against patterns
---
--- Returns:
---  * String - The name of the browser to use
function obj:findMatchingBrowser(url)
  local cleanURL = url:lower()

  for _, handler in ipairs(self.handlers) do
    if handler.match and handler.browser then
      for _, pattern in ipairs(handler.match) do
        if self:matchesPattern(cleanURL, pattern:lower()) then
          print(string.format("BrowserRedirect: %s -> %s", url, handler.browser))
          return handler.browser
        end
      end
    end
  end

  return self.defaultBrowser
end

--- BrowserRedirect:matchesPattern(url, pattern)
--- Method
--- Check if URL matches a given pattern (supports wildcards)
---
--- Parameters:
---  * url - The URL to check (should be lowercase)
---  * pattern - The pattern to match against (should be lowercase, supports * wildcards)
---
--- Returns:
---  * Boolean - True if the URL matches the pattern
function obj:matchesPattern(url, pattern)
  -- Convert shell-style wildcards to Lua pattern
  local luaPattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special chars
  luaPattern = luaPattern:gsub("%%%*", ".*")                              -- Convert * to .*

  return url:match(luaPattern) ~= nil
end

--- BrowserRedirect:addHandler(patterns, browser)
--- Method
--- Add a new URL handler dynamically
---
--- Parameters:
---  * patterns - Array of pattern strings to match
---  * browser - Browser name to use for matching URLs
function obj:addHandler(patterns, browser)
  if not patterns or not browser then
    return self
  end

  table.insert(self.handlers, {
    match = patterns,
    browser = browser
  })

  return self
end

--- BrowserRedirect:removeHandler(browser)
--- Method
--- Remove all handlers for a specific browser
---
--- Parameters:
---  * browser - Browser name to remove handlers for
function obj:removeHandler(browser)
  if not browser then
    return self
  end

  local originalCount = #self.handlers
  self.handlers = hs.fnutils.filter(self.handlers, function(handler)
    return handler.browser ~= browser
  end)

  return self
end

--- BrowserRedirect:listHandlers()
--- Method
--- Print current configuration for debugging
function obj:listHandlers()
  print("BrowserRedirect Configuration:")
  print(string.format("  Default browser: %s", self.defaultBrowser))
  print(string.format("  Active: %s", self.isActive and "Yes" or "No"))
  print(string.format("  Handlers (%d):", #self.handlers))

  for i, handler in ipairs(self.handlers) do
    local patterns = table.concat(handler.match or {}, ", ")
    print(string.format("    %d. %s -> %s", i, patterns, handler.browser or "unknown"))
  end

  return self
end

--- BrowserRedirect:testURL(url)
--- Method
--- Test which browser would handle a given URL (for debugging)
---
--- Parameters:
---  * url - URL to test
function obj:testURL(url)
  if not url then
    return self
  end

  local targetBrowser = self:findMatchingBrowser(url)
  print(string.format("BrowserRedirect: Test result - %s would open in %s", url, targetBrowser))

  return self
end

return obj
