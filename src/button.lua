local gui_options = require "src.gui_options"
---@class credible_settings.button
local M = {}

---@param gui gui
---@param id fun(): integer
function M.draw_button(gui, id)
	GuiOptionsAddForNextWidget(gui, gui_options.Align_HorizontalCenter)
	GuiText(gui, 0, 100, "Credible Settings")
end

return M
