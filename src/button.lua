local gui_options = require "lib.noita_enums.gui_options"
local vivid = require "lib.vivid.vivid"
---@class credible_settings.button
local M = {}

local hovered_last = false
local last_frame_clicked = 0

local function hue_to_interval(deg)
	return (deg / 360) % 1
end

---@param gui gui
---@param id fun(): integer
---@param internal_frame integer
---@param msg string
---@param x number
---@param y number
---@return boolean clicked
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

	local box_x, box_y, box_w, box_h = x, y - wiggles, shift - x, tallest_char + 2 * wiggles
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

	-- TODO: find a proper solution
	-- for some reason the first time you click it triggers multiple times
	return clicked
end

---@param gui gui
---@param id fun(): integer
---@param rainbow boolean
---@param internal_frame integer
---@return boolean clicked, boolean entered_other_ui
function M.draw_button(gui, id, rainbow, internal_frame)
	local w, h = GuiGetScreenDimensions(gui)
	-- 293 is correct for english default config.xml w kbm
	local y = 0.01
		* (tonumber(MagicNumbersGetValue("UI_PAUSE_MENU_LAYOUT_TOP_EDGE_PERCENTAGE")) or 0)
		* h
	local _, img_h = GuiGetImageDimensions(gui, "data/ui_gfx/pause_menu/help_keyboardmouse.png")
	y = y + img_h + (tonumber(GlobalsGetValue("credible_settings.button_y", "0")) or 0)
	local texts = {
		"paused",
		"continue",
		"newgame",
		"progress",
		"options",
		"mods",
		"releasenotes",
		"credits",
		"saveandquit",
	}

	local credits_y, credits_text
	for _, v in ipairs(texts) do
		local text = GameTextGetTranslatedOrNot("$menu_" .. v)
		local _, txt_h = GuiGetTextDimensions(gui, text)
		GuiOptionsAddForNextWidget(gui, gui_options.Align_HorizontalCenter)
		GuiOptionsAddForNextWidget(gui, gui_options.NoSound)
		GuiAnimateBegin(gui)
		GuiAnimateAlphaFadeIn(gui, id(), 0, 0, false)
		-- TODO: for some reason widget colour doesn't work, make it work
		local clicked = GuiButton(gui, id(), w / 2, y, text)
		GuiAnimateBegin(gui)
		if clicked and v ~= "credits" and v ~= "paused" then return false, true end
		if v == "credits" then
			credits_y = y
			credits_text = text
		end
		y = y + txt_h
	end

	local clicked
	if rainbow then
		GuiZSet(gui, -100000)
		local text_w = GuiGetTextDimensions(gui, credits_text)
		clicked = draw_rainbow(gui, id, internal_frame, credits_text, w / 2 - text_w / 2, credits_y)
	else
		GuiColorSetForNextWidget(gui, 0, 0, 0, 0)
		GuiOptionsAddForNextWidget(gui, gui_options.Align_HorizontalCenter)
		clicked = GuiButton(gui, id(), w / 2, credits_y, credits_text)
	end
	return clicked, false
end

---@param gui gui
---@param id fun(): integer
---@return boolean clicked
function M.return_button(gui, id)
	local w, h = GuiGetScreenDimensions(gui)
	local x, y = w * 0.04, h * 0.93
	local clicked = GuiButton(gui, x, y, GameTextGetTranslatedOrNot("$menu_return"), id())
	return clicked
end

return M
