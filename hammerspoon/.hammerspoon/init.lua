---@diagnostic disable: undefined-global
-- Press Cmd+Q twice to quit
local quitModal = hs.hotkey.modal.new("cmd", "q")
function quitModal:entered()
	hs.alert.show("Press Cmd+Q again to quit", 1)
	hs.timer.doAfter(1, function()
		quitModal:exit()
	end)
end

local function doQuit()
	local res = hs.application.frontmostApplication():selectMenuItem("^Quit.*$")
	quitModal:exit()
end
quitModal:bind("cmd", "q", doQuit)
quitModal:bind("", "escape", function()
	quitModal:exit()
end)

-- Storage for formatted clipboard content
-- local storedFormattedContent = {}

-- Just add a hotkey for plain text paste, leave default paste alone
-- hs.hotkey.bind({"cmd", "option"}, "v", function()
--     -- Get plain text and paste it
--     local plainText = hs.pasteboard.getContents()
--     if plainText then
--         -- Temporarily store current clipboard
--         local rtf = hs.pasteboard.readDataForUTI("public.rtf")
--         local html = hs.pasteboard.readDataForUTI("public.html")
--
--         -- Set to plain text only
--         hs.pasteboard.setContents(plainText)
--
--         -- Paste
--         hs.eventtap.keyStroke({"cmd"}, "v")
--
--         -- Restore formatted clipboard after paste
--         hs.timer.doAfter(0.1, function()
--             if rtf then
--                 hs.pasteboard.writeDataForUTI("public.rtf", rtf)
--             elseif html then
--                 hs.pasteboard.writeDataForUTI("public.html", html)
--             end
--         end)
--     end
-- end)
