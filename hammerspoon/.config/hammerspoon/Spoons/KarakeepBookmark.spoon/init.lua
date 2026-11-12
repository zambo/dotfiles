--- === KarakeepBookmark ===
---
--- Bookmarks the current browser tab with `karakeep bookmarks add --link <url>`.
--- The hotkey is only active while a supported browser is the frontmost app.

local obj = {}
obj.__index = obj

obj.name = "KarakeepBookmark"
obj.version = "0.1"
obj.license = "MIT"

--- KarakeepBookmark.karakeep
--- Path to the karakeep CLI (Hammerspoon's PATH does not include Homebrew).
obj.karakeep = "/opt/homebrew/bin/karakeep"

--- KarakeepBookmark.browsers
--- Bundle ID -> AppleScript snippet returning the active tab URL.
--- Firefox is not listed: it has no AppleScript support.
local chromium = 'tell application id "%s" to return URL of active tab of front window'
local function chromiumScript(id)
	return chromium:format(id)
end

obj.browsers = {
	["company.thebrowser.Browser"] = chromiumScript("company.thebrowser.Browser"), -- Arc
	["com.google.Chrome"] = chromiumScript("com.google.Chrome"),
	["com.brave.Browser"] = chromiumScript("com.brave.Browser"),
	["com.microsoft.edgemac"] = chromiumScript("com.microsoft.edgemac"),
	["com.vivaldi.Vivaldi"] = chromiumScript("com.vivaldi.Vivaldi"),
	["com.apple.Safari"] = 'tell application id "com.apple.Safari" to return URL of current tab of front window',
}

obj.defaultHotkeys = {
	bookmark = { { "cmd", "alt", "ctrl", "shift" }, "k" },
}

function obj:bookmark()
	local app = hs.application.frontmostApplication()
	local script = app and self.browsers[app:bundleID()]
	if not script then
		return
	end

	local ok, url = hs.osascript.applescript(script)
	if not ok or type(url) ~= "string" or url == "" then
		hs.alert.show("Could not get browser URL")
		return
	end

	local task = hs.task.new(self.karakeep, function(exitCode, _, stdErr)
		if exitCode == 0 then
			hs.alert.show("Saved to Karakeep")
		else
			hs.alert.show("Karakeep failed: " .. (stdErr ~= "" and stdErr or exitCode))
		end
	end, { "bookmarks", "add", "--link", url })
	task:start()
end

--- KarakeepBookmark:bindHotkeys(mapping)
--- Expects { bookmark = { mods, key } }.
function obj:bindHotkeys(mapping)
	local spec = mapping.bookmark
	self.hotkey = hs.hotkey.new(spec[1], spec[2], function()
		self:bookmark()
	end)
	return self
end

function obj:_sync(app)
	if not self.hotkey then
		return
	end
	if app and self.browsers[app:bundleID()] then
		self.hotkey:enable()
	else
		self.hotkey:disable()
	end
end

function obj:start()
	if not self.hotkey then
		self:bindHotkeys(self.defaultHotkeys)
	end
	self.watcher = hs.application.watcher.new(function(_, event, app)
		if event == hs.application.watcher.activated then
			self:_sync(app)
		end
	end)
	self.watcher:start()
	self:_sync(hs.application.frontmostApplication())
	return self
end

function obj:stop()
	if self.watcher then
		self.watcher:stop()
	end
	if self.hotkey then
		self.hotkey:disable()
	end
	return self
end

return obj
