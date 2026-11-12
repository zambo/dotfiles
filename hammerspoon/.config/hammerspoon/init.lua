-- Define hyper key if not already defined
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Log when config loads
hs.alert.show("Hammerspoon config loaded")

-- Save the current browser tab to Karakeep (only active in browsers)
hs.loadSpoon("KarakeepBookmark")
spoon.KarakeepBookmark:bindHotkeys({ bookmark = { hyper, "k" } })
spoon.KarakeepBookmark:start()

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
