local gui_options = require "src.gui_options"
local vivid = require "lib.vivid.vivid"
---@class credible_settings.button
local M = {}

local hovered_last = false
local menu_open = false

local function hue_to_interval(deg)
	return (deg / 360) % 1
end

---@param gui gui
---@param id fun(): integer
---@param internal_frame integer
---@param msg string
---@param x number
---@param y number
---@return boolean menu_open
local function draw_rainbow(gui, id, internal_frame, msg, x, y)
	local shift = x
	local wiggles = 0

	local hue = internal_frame
	local tallest_char = 0
	for char in msg:gmatch(".") do
		local width, height = GuiGetTextDimensions(gui, char)
		tallest_char = math.max(tallest_char, height)
		hue = hue + width
		local r, g, b = vivid.HSVtoRGB(hue_to_interval(hue), hovered_last and 1 or 0.2, 1)
		GuiColorSetForNextWidget(gui, r, g, b, 1)
		local dy = wiggles * math.sin((width / 2 + shift + internal_frame) / 20)
		GuiText(gui, shift, y + dy, char)
		shift = shift + width
	end

	local box_x, box_y, box_w, box_h = x, y - wiggles, shift, tallest_char + 2 * wiggles
	GuiOptionsAdd(gui, gui_options.AlwaysClickable)
	GuiOptionsAdd(gui, gui_options.ForceFocusable)
	GuiImageNinePiece(
		gui,
		id(),
		box_x,
		box_y,
		box_w,
		box_h,
		1,
		"data/debug/empty.png",
		"data/debug/empty.png"
	)
	local clicked, _, hovered = GuiGetPreviousWidgetInfo(gui)
	GuiOptionsClear(gui)
	hovered_last = hovered
	if clicked then menu_open = not menu_open end

	return menu_open
end

---@param gui gui
---@param id fun(): integer
---@param rainbow boolean
---@param internal_frame integer
---@return boolean menu_open
function M.draw_button(gui, id, rainbow, internal_frame)
	local w, _ = GuiGetScreenDimensions(gui)
	-- 293 is correct for english default config.xml w kbm
	local y = tonumber(GlobalsGetValue("credible_settings.button_y", "293")) or 0

	local text = "Credible Settings"

	if rainbow then
		GuiZSet(gui, -100000)
		local text_w = GuiGetTextDimensions(gui, text)
		draw_rainbow(gui, id, internal_frame, text, w / 2 - text_w / 2, y)
	else
		GuiColorSetForNextWidget(gui, 0, 0, 0, 0)
		GuiOptionsAddForNextWidget(gui, gui_options.Align_HorizontalCenter)
		local clicked = GuiButton(gui, id(), w / 2, y, text)
		menu_open = menu_open ~= clicked -- no builtin xor :(
	end
	return menu_open
end

return M
