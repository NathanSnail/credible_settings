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

---Run after `OnMagicNumbersAndWorldSeedInitialized` is declared
function M.install_hooks()
	local my_counter
	local version_key = "credible_settings.version"
	local counter_key = "credible_settings.counter"

	---@type OnWorldInitialized
	local _OnModPostInit = OnModPostInit
	OnModPostInit = function()
		_OnModPostInit()

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

	local _OnMagicNumbersAndWorldSeedInitialized = OnMagicNumbersAndWorldSeedInitialized
	OnMagicNumbersAndWorldSeedInitialized = function()
		_OnMagicNumbersAndWorldSeedInitialized()

		-- the first mod with the highest version wins
		if tostring(my_counter) ~= GlobalsGetValue(counter_key, "") then return end

		local credits_path = "data/credits.txt"
		local old_credits = ModTextFileGetContent(credits_path)
		ModTextFileSetContent(credits_path, ("\n"):rep(100))
	end
end

require = _require
return M
