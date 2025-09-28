--- === BrowserRedirect ===
---
--- Intelligent URL routing to different browsers based on patterns
--- Uses hybrid approach: URL scheme handling + browser extension communication
--- Includes customizable link mapping interface

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "BrowserRedirect"
obj.version = "1.0"
obj.author = "sjdonado"
obj.homepage = "https://github.com/sjdonado/dotfiles/hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.default_browser = "Safari"
obj.redirect = {}
obj.mapper = {}
obj.isActive = false
obj.originalDefaultBrowser = nil
obj.extensionServer = nil
obj.lastProcessedURL = nil
obj.lastProcessedTime = 0
obj.redirectLookup = {}
obj.mapperLookup = {}
obj.logger = hs.logger.new('BrowserRedirect', 'info')

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
---    * default_browser - Default browser name (string)
---    * redirect - Array of redirect rules with 'match' patterns and 'browser' name
---    * mapper - Array of URL transformation functions
function obj:setup(config)
  if not config then
    return self
  end

  self.default_browser = config.default_browser or "Safari"
  self.redirect = config.redirect or {}
  self.mapper = config.mapper or {}

  -- Build optimized lookup tables
  self:_buildLookupTables()

  return self
end

--- BrowserRedirect:_buildLookupTables()
--- Method
--- Build optimized lookup tables for O(1) pattern matching
function obj:_buildLookupTables()
  self.redirectLookup = {}
  self.mapperLookup = {}

  -- Build redirect lookup table
  for _, rule in ipairs(self.redirect) do
    if rule and rule.match and rule.browser then
      local patterns = type(rule.match) == "table" and rule.match or { rule.match }
      for _, pattern in ipairs(patterns) do
        -- Store exact matches and wildcard patterns separately
        if pattern:find("*") then
          -- For wildcard patterns, we still need to check them sequentially
          self.redirectLookup["__wildcards"] = self.redirectLookup["__wildcards"] or {}
          table.insert(self.redirectLookup["__wildcards"], {
            pattern = pattern,
            browser = rule.browser
          })
        else
          -- Exact matches for O(1) lookup
          self.redirectLookup[pattern] = rule.browser
        end
      end
    end
  end

  -- Build mapper lookup table
  for _, mapper in ipairs(self.mapper) do
    if mapper.from then
      if mapper.from:find("*") then
        self.mapperLookup["__wildcards"] = self.mapperLookup["__wildcards"] or {}
        table.insert(self.mapperLookup["__wildcards"], mapper)
      else
        self.mapperLookup[mapper.from] = mapper
      end
    end
  end

  -- Count exact redirects
  local exactRedirects = 0
  for k, v in pairs(self.redirectLookup) do
    if k ~= "__wildcards" then exactRedirects = exactRedirects + 1 end
  end

  -- Count exact mappers
  local exactMappers = 0
  for k, v in pairs(self.mapperLookup) do
    if k ~= "__wildcards" then exactMappers = exactMappers + 1 end
  end

  self.logger:i(string.format(
    "Built lookup tables - %d exact redirects, %d wildcard redirects, %d exact mappers, %d wildcard mappers",
    exactRedirects,
    self.redirectLookup["__wildcards"] and #self.redirectLookup["__wildcards"] or 0,
    exactMappers,
    self.mapperLookup["__wildcards"] and #self.mapperLookup["__wildcards"] or 0))
end

--- BrowserRedirect:start()
--- Method
--- Start hybrid URL interception system
function obj:start()
  if self.isActive then
    return self
  end

  self.logger:i("Starting hybrid URL interception")

  -- Start URL scheme handler (for external URLs)
  self:_startURLSchemeHandler()

  -- Start browser extension server (for in-browser URLs)
  self:_startExtensionServer()

  self.isActive = true
  self.logger:i("All URL interception methods started")

  return self
end

--- BrowserRedirect:stop()
--- Method
--- Stop all URL interception methods
function obj:stop()
  if not self.isActive then
    return self
  end

  self.isActive = false

  -- Stop extension server
  if self.extensionServer then
    self.extensionServer:stop()
    self.extensionServer = nil
  end

  -- Restore original default browser if we had one
  if self.originalDefaultBrowser then
    hs.execute(string.format(
      "defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.html;LSHandlerRoleAll=%s;}'",
      self.originalDefaultBrowser))
    hs.execute(string.format(
      "defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=http;LSHandlerRoleAll=%s;}'",
      self.originalDefaultBrowser))
    hs.execute(string.format(
      "defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=https;LSHandlerRoleAll=%s;}'",
      self.originalDefaultBrowser))
  end

  self.logger:i("All URL interception stopped")
  return self
end

--- BrowserRedirect:_startURLSchemeHandler()
--- Method
--- Start URL scheme handler for external URLs
function obj:_startURLSchemeHandler()
  -- Store original default browser
  local output = hs.execute(
    "defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A3 LSHandlerURLScheme | grep http -A2 | grep LSHandlerRoleAll -A1 | tail -1 | cut -d'\"' -f2")
  if output and output ~= "" then
    self.originalDefaultBrowser = output:gsub("%s+", "")
  end

  -- Register URL scheme handlers
  hs.urlevent.setDefaultHandler('http')
  hs.urlevent.setDefaultHandler('https')

  -- Set up URL event callback
  hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    if fullURL then
      self:_handleURL(fullURL, "external")
    end
  end

  self.logger:d("URL scheme handler started")
end

--- BrowserRedirect:_startExtensionServer()
--- Method
--- Start HTTP server to receive URLs from browser extensions
function obj:_startExtensionServer()
  self.extensionServer = hs.httpserver.new(false, false)

  self.extensionServer:setCallback(function(method, path, headers, body)
    if method == "POST" and path == "/redirect" then
      local success, data = pcall(hs.json.decode, body)
      if success and data.url then
        self:_handleURL(data.url, "browser-extension")
        return "200", {}, hs.json.encode({ status = "success" })
      end
    end
    return "404", {}, "Not found"
  end)

  -- Start server on a random available port
  self.extensionServer:setPort(0)
  local success = self.extensionServer:start()

  if success then
    local port = self.extensionServer:getPort()
    self.logger:i(string.format("Extension server started on port %d", port))
    self.logger:i("Configure browser extensions to send URLs to: http://localhost:" ..
    port .. "/redirect")
  else
    self.logger:e("Failed to start extension server")
  end
end

--- BrowserRedirect:_handleURL(url, source)
--- Method
--- Handle intercepted URL and route to appropriate browser
---
--- Parameters:
---  * url - The intercepted URL
---  * source - Source of the URL ("external", "pasteboard", "browser-extension")
function obj:_handleURL(url, source)
  if not url then
    return
  end

  -- Debounce rapid URL processing
  local currentTime = hs.timer.secondsSinceEpoch()
  if self.lastProcessedURL == url and (currentTime - self.lastProcessedTime) < 2 then
    return
  end

  self.lastProcessedURL = url
  self.lastProcessedTime = currentTime

  self.logger:d(string.format("Intercepted URL from %s: %s", source or "unknown", url))

  -- Debug redirect rules
  self.logger:d("Redirect rules: " .. #self.redirect)
  for i, rule in ipairs(self.redirect) do
    self.logger:d(string.format("Rule %d: match='%s' browser='%s'",
      i, rule.match or "nil", rule.browser or "nil"))
  end

  -- Transform the URL if it matches any mappers
  local transformedURL = self:_transformURL(url)
  local targetBrowser = self:_findTargetBrowser(transformedURL)

  self.logger:i(string.format("Routing to %s", targetBrowser))

  -- For browser extension sources, close current tab first
  if source == "browser-extension" then
    hs.timer.doAfter(0.01, function()
      hs.eventtap.keyStroke({ "cmd" }, "w") -- Close current tab
    end)
  end

  -- Open URL in target browser
  hs.timer.doAfter(source == "browser-extension" and 0.2 or 0, function()
    local success = self:_openInBrowser(transformedURL, targetBrowser)
    if not success then
      self.logger:w("Failed to open in target browser, using system default")
      hs.urlevent.openURLWithBundle(transformedURL, self.default_browser)
    end
  end)
end

--- BrowserRedirect:_openInBrowser(url, browserName)
--- Method
--- Open URL in specific browser
---
--- Parameters:
---  * url - The URL to open
---  * browserName - Name of the browser
---
--- Returns:
---  * Boolean - Success status
function obj:_openInBrowser(url, browserName)
  -- Browser bundle ID mapping
  local browserBundles = {
    ["Safari"] = "com.apple.Safari",
    ["Google Chrome"] = "com.google.Chrome",
    ["Chromium"] = "org.chromium.Chromium",
    ["Firefox"] = "org.mozilla.firefox",
    ["Arc"] = "company.thebrowser.Browser",
    ["Microsoft Edge"] = "com.microsoft.edgemac",
    ["Opera"] = "com.operasoftware.Opera",
    ["Brave Browser"] = "com.brave.Browser"
  }

  local bundleID = browserBundles[browserName]
  if bundleID then
    return hs.urlevent.openURLWithBundle(url, bundleID)
  else
    -- Try to open with application name directly
    local openCmd = string.format('open -a "%s" "%s"', browserName, url)
    local output, success = hs.execute(openCmd)
    return success
  end
end

--- BrowserRedirect:_transformURL(url)
--- Method
--- Transform URL based on configured mappers
---
--- Parameters:
---  * url - The original URL to transform
---
--- Returns:
---  * String - The transformed URL or original if no mapping found
function obj:_transformURL(url)
  -- First check exact matches for O(1) lookup
  local exactMapper = self.mapperLookup[url]
  if exactMapper then
    if exactMapper.to then
      self.logger:d(string.format("Exact transform: %s -> %s", url, exactMapper.to))
      return exactMapper.to
    elseif exactMapper.transform then
      return exactMapper.transform(exactMapper, url)
    end
  end

  -- Then check wildcard patterns
  if self.mapperLookup["__wildcards"] then
    for _, mapper in ipairs(self.mapperLookup["__wildcards"]) do
      if mapper.from and mapper.to then
        -- Pattern-based transformation
        if self:_matchesURLPattern(url, mapper.from) then
          local transformedURL = self:_transformURLPattern(url, mapper.from, mapper.to)
          self.logger:d(string.format("Transforming URL: %s -> %s", url, transformedURL))
          return transformedURL
        end
      elseif mapper.matches and mapper.transform then
        -- Function-based transformation
        if mapper.matches(mapper, url) then
          return mapper.transform(mapper, url)
        end
      end
    end
  end

  return url
end

--- BrowserRedirect:_matchesURLPattern(url, pattern)
--- Method
--- Check if URL matches a wildcard pattern
---
--- Parameters:
---  * url - The URL to check
---  * pattern - The pattern to match (supports * wildcards and {param} extractions)
---
--- Returns:
---  * Boolean - True if URL matches the pattern
function obj:_matchesURLPattern(url, pattern)
  -- Convert pattern to Lua pattern
  local luaPattern = pattern:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
  luaPattern = luaPattern:gsub("%*", ".*")
  luaPattern = luaPattern:gsub("{[^}]+}", "(.-)")
  luaPattern = "^" .. luaPattern .. "$"

  return url:match(luaPattern) ~= nil
end

--- BrowserRedirect:_transformURLPattern(url, fromPattern, toPattern)
--- Method
--- Transform URL using pattern matching and substitution
---
--- Parameters:
---  * url - The original URL
---  * fromPattern - The pattern to match against (with {param} placeholders)
---  * toPattern - The target pattern (with {param} references)
---
--- Returns:
---  * String - The transformed URL
function obj:_transformURLPattern(url, fromPattern, toPattern)
  -- Extract parameter names from the from pattern
  local paramNames = {}
  for param in fromPattern:gmatch("{([^}]+)}") do
    table.insert(paramNames, param)
  end

  -- Create Lua pattern for matching and capturing
  local luaPattern = fromPattern:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
  luaPattern = luaPattern:gsub("%*", ".*")
  luaPattern = luaPattern:gsub("{[^}]+}", "(.-)")
  luaPattern = "^" .. luaPattern .. "$"

  -- Extract parameter values
  local params = {}
  local captures = { url:match(luaPattern) }
  for i, value in ipairs(captures) do
    if paramNames[i] then
      params[paramNames[i]] = value
    end
  end

  -- Parse URL for query parameters if needed
  local urlParts = hs.http.urlParts(url)
  if urlParts and urlParts.query then
    if type(urlParts.query) == "table" then
      for key, value in pairs(urlParts.query) do
        params["query." .. key] = value
      end
    elseif type(urlParts.query) == "string" then
      -- Parse query string manually
      for pair in urlParts.query:gmatch("([^&]+)") do
        local key, value = pair:match("([^=]+)=?(.*)")
        if key then
          params["query." .. key] = value or ""
        end
      end
    end
  end

  -- Transform the target pattern
  local result = toPattern
  for param, value in pairs(params) do
    local placeholder = "{" .. param .. "}"
    local encodePlaceholder = "{" .. param .. "|encode}"

    if result:find(encodePlaceholder, 1, true) then
      result = result:gsub(encodePlaceholder:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1"),
        hs.http.encodeForQuery(value or ""))
    else
      result = result:gsub(placeholder:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1"), value or "")
    end
  end

  return result
end

--- BrowserRedirect:_findTargetBrowser(url)
--- Method
--- Find the target browser for a given URL based on redirect rules
---
--- Parameters:
---  * url - The URL to find a browser for
---
--- Returns:
---  * String - The target browser name
function obj:_findTargetBrowser(url)
  if not url then
    return self.default_browser
  end

  -- First check exact matches for O(1) lookup
  local exactBrowser = self.redirectLookup[url]
  if exactBrowser then
    self.logger:d(string.format("Exact match found: %s -> %s", url, exactBrowser))
    return exactBrowser
  end

  -- Then check wildcard patterns
  if self.redirectLookup["__wildcards"] then
    for _, rule in ipairs(self.redirectLookup["__wildcards"]) do
      self.logger:d(string.format("Checking wildcard pattern '%s' against URL '%s'",
        rule.pattern, url))
      if self:_matchesPattern(url, rule.pattern) then
        self.logger:d(string.format("Wildcard pattern matched! Returning browser: %s",
          rule.browser))
        return rule.browser
      end
    end
  end

  return self.default_browser
end

--- BrowserRedirect:_matchesPattern(url, pattern)
--- Method
--- Check if URL matches a given pattern (supports wildcards)
---
--- Parameters:
---  * url - The URL to check
---  * pattern - The pattern to match against
---
--- Returns:
---  * Boolean - True if URL matches the pattern
function obj:_matchesPattern(url, pattern)
  if not url or not pattern or type(url) ~= "string" or type(pattern) ~= "string" then
    self.logger:w(string.format("Invalid input - url: %s, pattern: %s", tostring(url),
      tostring(pattern)))
    return false
  end

  local luaPattern = pattern:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
  luaPattern = luaPattern:gsub("%*", ".*")
  luaPattern = "^" .. luaPattern .. "$"

  local matches = url:match(luaPattern) ~= nil
  self.logger:d(string.format("Pattern '%s' -> Lua pattern '%s' matches URL '%s': %s",
    pattern, luaPattern, url, tostring(matches)))

  return matches
end

--- BrowserRedirect:_isValidURL(str)
--- Method
--- Check if string is a valid HTTP/HTTPS URL
---
--- Parameters:
---  * str - String to check
---
--- Returns:
---  * Boolean - True if valid URL
function obj:_isValidURL(str)
  if not str or type(str) ~= "string" then
    return false
  end

  return str:match("^https?://") ~= nil
end

--- BrowserRedirect:addRedirect(rule)
--- Method
--- Add a redirect rule
---
--- Parameters:
---  * rule - A table with 'match' pattern and 'browser' name
function obj:addRedirect(rule)
  if not rule.match or not rule.browser then
    self.logger:e("Redirect rule must have 'match' and 'browser' fields")
    return self
  end

  table.insert(self.redirect, rule)
  self:_buildLookupTables()
  return self
end

--- BrowserRedirect:removeRedirect(pattern)
--- Method
--- Remove redirect rule by pattern
---
--- Parameters:
---  * pattern - The pattern to remove
function obj:removeRedirect(pattern)
  for i = #self.redirect, 1, -1 do
    if self.redirect[i].match == pattern then
      table.remove(self.redirect, i)
    end
  end
  self:_buildLookupTables()
  return self
end

--- BrowserRedirect:addMapper(mapper)
--- Method
--- Add a URL mapper
---
--- Parameters:
---  * mapper - A mapper configuration
function obj:addMapper(mapper)
  table.insert(self.mapper, mapper)
  self:_buildLookupTables()
  return self
end

--- BrowserRedirect:removeMapper(name)
--- Method
--- Remove mapper by name
---
--- Parameters:
---  * name - The name of the mapper to remove
function obj:removeMapper(name)
  for i = #self.mapper, 1, -1 do
    if self.mapper[i].name == name then
      table.remove(self.mapper, i)
    end
  end
  self:_buildLookupTables()
  return self
end

--- BrowserRedirect:getStats()
--- Method
--- Get statistics about redirect rules and mappers
---
--- Returns:
---  * Table - Statistics about the current configuration
function obj:getStats()
  return {
    redirectRules = #self.redirect,
    mappers = #self.mapper,
    isActive = self.isActive,
    originalDefaultBrowser = self.originalDefaultBrowser,
    extensionServerPort = self.extensionServer and self.extensionServer:getPort() or nil,
    lastProcessedURL = self.lastProcessedURL
  }
end

return obj
