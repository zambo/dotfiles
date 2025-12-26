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
    ]]

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
