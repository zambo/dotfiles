hs.console.printStyledtext("[hyper_caps] Loaded hyper_caps.lua\n")
-- Hyper key configuration
-- Convert Caps Lock to Hyper (Cmd+Opt+Ctrl+Shift) when held
-- Send Control+Option+; when tapped
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Create a modal hotkey to track Caps Lock state
local capsLockModal = hs.hotkey.modal.new()

-- Flag to track if any key was pressed while holding Caps Lock
local keysPressed = false
-- Track if modal is active
local modalActive = false

-- Listen for Caps Lock down event
hs.eventtap
	.new({ hs.eventtap.event.types.flagsChanged }, function(event)
		local flags = event:getFlags()

		if flags.capslock then
			-- Caps Lock is pressed down
			hs.console.printStyledtext("[hyper_caps] Caps Lock pressed\n")
			keysPressed = false
			if not modalActive then
				capsLockModal:enter()
				modalActive = true
				hs.console.printStyledtext("[hyper_caps] Entered modal\n")
			end
			return true -- Suppress the caps lock event
		else
			-- Caps Lock is released
			if modalActive then
				capsLockModal:exit()
				modalActive = false
				hs.console.printStyledtext("[hyper_caps] Exited modal\n")
				-- If no keys were pressed, send Control+Option+;
				if not keysPressed then
					hs.console.printStyledtext("[hyper_caps] Sending ctrl+alt+;\n")
					hs.eventtap.keyStroke({ "ctrl", "alt" }, ";")
				else
					hs.console.printStyledtext("[hyper_caps] Key(s) pressed during modal, not sending ctrl+alt+;\n")
				end
				return true
			end
		end

		return false
	end)
	:start()

-- Bind all letter keys to hyper combinations while in modal
local letters = "abcdefghijklmnopqrstuvwxyz"
for i = 1, #letters do
	local key = letters:sub(i, i)
	capsLockModal:bind({}, key, function()
		keysPressed = true
		hs.console.printStyledtext(string.format("[hyper_caps] Hyper+%s\n", key))
		hs.eventtap.keyStroke(hyper, key)
	end)
end

-- Add number and symbol keys as needed
local otherKeys = {
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"0",
	"space",
	"return",
	"delete",
	"tab",
	"left",
	"right",
	"up",
	"down",
}
for _, key in ipairs(otherKeys) do
	capsLockModal:bind({}, key, function()
		keysPressed = true
		hs.console.printStyledtext(string.format("[hyper_caps] Hyper+%s\n", key))
		hs.eventtap.keyStroke(hyper, key)
	end)
end
