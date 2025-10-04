---@class credible_settings
local M = {}

local path = "data/credible_settings/temp.txt"
ModTextFileSetContent(path, "empty")
local whoami = ModTextFileWhoSetContent(path)

local function get_path_name(modname)
	return ("mods/%s/lib/credible_settings/%s"):format(whoami, modname)
end

local _require = require
---@param modname string
---@return any
function require(modname)
	return dofile_once(get_path_name(modname:gsub("%.", "/")) .. ".lua")
end

local button = require "src.button"

local credible_settings_version = 1

local menus = {}

---@param name string The name of your settings menu
---@param source string The file to run to generate your settings gui
function M.add_menu(name, source)
	table.insert(menus, { name = name, source = source })
end

local credits_path = "data/credits.txt"
local old_credits = ModTextFileGetContent(credits_path)
local blank = ("\n"):rep(100)
ModTextFileSetContent(credits_path, blank)
local first = old_credits ~= blank

if first then
	ModMagicNumbersFileAdd(get_path_name("src/magic_numbers.xml"))
	local translations = ModTextFileGetContent("data/translations/common.csv")
	translations = translations .. ModTextFileGetContent(get_path_name("src/translations.csv"))
	translations = translations:gsub("\r", ""):gsub("\n\n+", "\n")
	ModTextFileSetContent("data/translations/common.csv", translations)
end

---Run after `OnMagicNumbersAndWorldSeedInitialized` is declared
function M.install_hooks()
	local my_counter
	local version_key = "credible_settings.version"
	local old_credits_key = "credible_settings.old_credits"
	local counter_key = "credible_settings.counter"
	local winner_key = "credible_settings.negotiation_winner"
	local won = false

	---@type OnWorldInitialized
	local _OnWorldInitialized = OnWorldInitialized or function() end
	OnWorldInitialized = function()
		_OnWorldInitialized()

		if first then GlobalsSetValue(old_credits_key, old_credits) end

		local version = tonumber(GlobalsGetValue(version_key, "0")) or 0
		if version < credible_settings_version then
			GlobalsSetValue(version_key, tostring(credible_settings_version))
		else
			return
		end

		local counter = tonumber(GlobalsGetValue(counter_key, "0")) or 0
		counter = counter + 1
		my_counter = counter
		GlobalsSetValue(counter_key, tostring(counter))
	end

	local gui
	local internal_frame = 0
	local paused = false
	local _id = 2
	local menu_open = false
	local function id()
		_id = _id + 1
		return _id
	end
	local _OnPausePreUpdate = OnPausePreUpdate or function() end
	OnPausePreUpdate = function()
		if not won then return end
		_OnPausePreUpdate()
		gui = gui or GuiCreate()
		internal_frame = internal_frame + 1
		_id = 2
		GuiStartFrame(gui)

		if not menu_open then menu_open = button.draw_button(gui, id, true, internal_frame) end
	end
	local _OnPausedChanged = OnPausedChanged or function() end
	OnPausedChanged = function(is_paused, is_inventory_pause)
		if not won then return end
		_OnPausedChanged(is_paused, is_inventory_pause)
		paused = is_paused
	end

	local first_time = true
	---@type OnWorldPreUpdate
	local _OnWorldPreUpdate = OnWorldPreUpdate or function() end
	OnWorldPreUpdate = function()
		_OnWorldPreUpdate()
		if not paused and gui then GuiStartFrame(gui) end
		if not first_time then return end
		-- world updates before it exists ??
		if GlobalsGetValue(counter_key, "") == "" then return end
		first_time = false

		-- the first mod with the highest version wins
		if
			tostring(my_counter) ~= GlobalsGetValue(counter_key, "")
			and whoami ~= GlobalsGetValue(winner_key, "")
		then
			return
		end
		GlobalsSetValue(winner_key, whoami)
		won = true
	end
end

require = _require
return M
