-- Define hyper key if not already defined
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Log when config loads
hs.alert.show("Hammerspoon config loaded")

-- Load the URLDispatcher Spoon
hs.loadSpoon("URLDispatcher")

-- Define a handler function to open YouTube URLs in Arc browser
-- Arc's bundle ID is "company.thebrowser.Browser"
local function openInArc(url)
	hs.urlevent.openURLWithBundle(url, "company.thebrowser.Browser")
end

-- Hotkey to open current Chrome tab in Arc
hs.hotkey.bind({ "cmd", "shift" }, "O", function()
	local script = [[
        tell application "Google Chrome"
            if it is running then
                set currentURL to URL of active tab of front window
                return currentURL
            end if
        end tell
 h   ]]

	local ok, url = hs.osascript.applescript(script)

	if ok and url then
		hs.urlevent.openURLWithBundle(url, "company.thebrowser.Browser")
		hs.alert.show("Opening in Arc")
	else
		hs.alert.show("Could not get Chrome URL")
	end
end)

-- Configure URLDispatcher using url_patterns
spoon.URLDispatcher.url_patterns = {
	{ "youtube%.com", openInArc },
	{ "youtu%.be", openInArc },
}

-- Set default handler for all other URLs - open in Chrome
spoon.URLDispatcher.default_handler = "com.google.Chrome"

-- Enable Slack redirect URL decoding (this is the default, but being explicit)
spoon.URLDispatcher.decode_slack_redir_urls = true

-- Start the URL dispatcher
spoon.URLDispatcher:start()

-- Close notifications
-- hs.hotkey.bind(hyper, "n", function()
-- 	hs.alert.show("Clearing notifications...")
--
-- 	-- Use macOS built-in shortcuts to clear notifications
-- 	-- Option+Shift+Click on notification center opens it and shows Clear All
-- 	hs.eventtap.keyStroke({ "cmd", "shift" }, "n", 0) -- Open Notification Center
-- 	hs.timer.doAfter(0.3, function()
-- 		-- Press Option to reveal "Clear All" button
-- 		hs.eventtap.keyStroke({ "alt" }, "c", 0) -- Clear All shortcut
-- 		hs.timer.doAfter(0.2, function()
-- 			hs.eventtap.keyStroke({ "cmd", "shift" }, "n", 0) -- Close Notification Center
-- 			hs.alert.show("Notifications cleared")
-- 		end)
-- 	end)
-- end)
