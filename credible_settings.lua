---@class credible_settings
local M = {}

local path = "data/credible_settings/temp.txt"
ModTextFileSetContent(path, "empty")
local whoami = ModTextFileWhoSetContent(path)

local _require = require
---@param modname string
---@return any
function require(modname)
	return dofile_once(
		("mods/%s/lib/credible_settings/%s.lua"):format(whoami, modname:gsub("%.", "/"))
	)
end

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

---Run after `OnMagicNumbersAndWorldSeedInitialized` is declared
function M.install_hooks()
	local my_counter
	local version_key = "credible_settings.version"
	local old_credits_key = "credible_settings.old_credits"
	local counter_key = "credible_settings.counter"
	local winner_key = "credible_settings.negotiation_winner"

	---@type OnWorldInitialized
	local _OnWorldInitialized = OnWorldInitialized or function() end
	OnWorldInitialized = function()
		_OnWorldInitialized()

		if old_credits ~= blank then GlobalsSetValue(old_credits_key, old_credits) end

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

	local first_time = true
	---@type OnWorldPreUpdate
	local _OnWorldPreUpdate = OnWorldPreUpdate
	OnWorldPreUpdate = function()
		_OnWorldPreUpdate()
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
	end
end

require = _require
return M
