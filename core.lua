---@diagnostic disable: undefined-field, undefined-doc-name, undefined-doc-param

SkuMonitors = SkuMonitors or LibStub("AceAddon-3.0"):NewAddon("SkuMonitors", "AceConsole-3.0", "AceEvent-3.0")
SkuMonitors.L = LibStub("AceLocale-3.0"):GetLocale("SkuMonitors", false)

local L = SkuMonitors.L

local options = {
	name = "SkuMonitors",
	handler = SkuMonitors,
	type = "group",
	args = {},
}

local defaults = {
	profile = {
	}
}

--------------------------------------------------------------------------------------------------------------------------------------
local SkuMonitorsOptions = {
	name = "Health",
	handler = SkuMonitors,
	type = "group",
	args = {
		vocalizeMenuNumbers = {
			order = 1,
			name = "not available in combat",
			desc = "",
			type = "toggle",
			set = function(info,val)
				--SkuMonitors.db.profile[MODULE_NAME].vocalizeMenuNumbers = val
			end,
			get = function(info)
				--return SkuMonitors.db.profile[MODULE_NAME].vocalizeMenuNumbers
			end
		},
	},
}
---------------------------------------------------------------------------------------------------------------------------------------
local SkuMonitorsDefaults = {
	vocalizeMenuNumbers = true,
}

local CleuBase = {
	timestamp = 1,
	subevent = 2,
	hideCaster =3 ,
	sourceGUID = 4,
	sourceName = 5,
	sourceFlags = 6,
	sourceRaidFlags = 7,
	destGUID = 8,
	destName = 9,
	destFlags = 10,
	destRaidFlags = 11,
	spellId = 12,
	spellName = 13,
	spellSchool = 14,
	unitHealthPlayer = 35,
	unitPowerPlayer = 36,
	buffListTarget = 37,
	dbuffListTarget = 38,
	itemID = 40,
	missType = 41,
--key = 50
--combo = 51
}

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:SlashFunc(input, aSilent)
	print("SkuMonitors:SlashFunc(input)", input, aSilent)
	--SkuMonitors.AceConfigDialog:Open("SkuMonitors")

	if not input then
		return
	end

	input = input:gsub( ", ", ",")
	input = input:gsub( " ,", ",")

	input = string.lower(input)
	local sep, fields = ",", {}
	local pattern = string.format("([^%s]+)", sep)
	input:gsub(pattern, function(c) fields[#fields+1] = c end)

	if fields then
		if fields[1] == "version" then
			local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("SkuMonitors")
			print(title)
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:OnInitialize()
	print("SkuMonitors OnInitialize")
	options.args["Health"] = SkuMonitorsOptions
	defaults.profile["Health"] = SkuMonitorsDefaults


	SkuMonitors:RegisterChatCommand("skumonitors", "SlashFunc")
	SkuMonitors.AceConfig = LibStub("AceConfig-3.0")
	SkuMonitors.AceConfig:RegisterOptionsTable("SkuMonitors", options, {"taop"})
	SkuMonitors.db = LibStub("AceDB-3.0"):New("SkuMonitorsOptionsDB", defaults, true)
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(SkuMonitors.db)

	SkuMonitors.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	SkuMonitors.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
	SkuMonitors.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")

	SkuMonitors:RegisterEvent("PLAYER_ENTERING_WORLD")
	SkuMonitors:RegisterEvent("PLAYER_LOGIN")
	SkuMonitors:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	SkuMonitors:AqOnInitialize()
	SkuMonitors:aqCombatOnInitialize()
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:OnProfileChanged()
	print("SkuMonitors OnProfileChanged")
end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:OnProfileCopied()
	print("SkuMonitors OnProfileCopied")
end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:OnProfileReset()
	print("SkuMonitors OnProfileReset")
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:OnEnable()
	print("SkuMonitors OnEnable")


--[[

	if not SkuMonitors.db.profile["SkuMonitors"].overviewPages then
		SkuMonitors.db.profile["SkuMonitors"].overviewPages = {}
	end

	for x = 1, 4 do
		if not SkuMonitors.db.profile["SkuMonitors"].overviewPages[x] then
			SkuMonitors.db.profile["SkuMonitors"].overviewPages[x] = {}
		end
		for i, v in pairs(overviewSectionsAll) do
			if not SkuMonitors.db.profile["SkuMonitors"].overviewPages[x].overviewSections then
				SkuMonitors.db.profile["SkuMonitors"].overviewPages[x].overviewSections = {}
			end
			if not SkuMonitors.db.profile["SkuMonitors"].overviewPages[x].overviewSections[i] then
				SkuMonitors.db.profile["SkuMonitors"].overviewPages[x].overviewSections[i] = {pos = 999, locName = v.locName, }
				if overviewSectionsDefaults[x][i] then
					SkuMonitors.db.profile["SkuMonitors"].overviewPages[x].overviewSections[i].pos = overviewSectionsDefaults[x][i].pos
				end
			end
			SkuMonitors.db.profile["SkuMonitors"].overviewPages[x].overviewSections[i].locName = v.locName
		end

	end
	]]

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:OnDisable()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:PLAYER_ENTERING_WORLD(...)
	local event, isInitialLogin, isReloadingUi = ...
	print("SkuMonitors PLAYER_ENTERING_WORLD")
end







---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:profileChangedHandler()


end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:profileCopiedHandler()


end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:profileResetHandler()


end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:getKeyBindsHandler()
	return
	{
		["SKU_MONITORS_TEST_KEY"] = {
			key = "SHIFT-CTRL-A",
			desc = "SkuMonitors test",
			handler = function()
				print("SKU_MONITORS_TEST_KEY handler")
			end,
		}
	}

end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:setKeyBindsHandler()


end










---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:PLAYER_LOGIN(...)
	local event, isInitialLogin, isReloadingUi = ...
	print("SkuMonitors PLAYER_LOGIN", SkuMonitors)

	SkuMonitors:Monitor_PLAYER_LOGIN(...)
	SkuMonitors:aqCombatOnLogin(...)

	if SkuMenu then
		local pluginName = "Sku Monitors"
		local pluginTable = {
			menuBuilder = SkuMonitors.MonitorMenuBuilder,
			getKeyBindsHandler = SkuMonitors.getKeyBindsHandler,
			setKeyBindsHandler = SkuMonitors.setKeyBindsHandler,
			profileChangedHandler = SkuMonitors.setKeyBindsHandler,
			profileCopiedHandler = SkuMonitors.profileCopiedHandler,
			profileResetHandler = SkuMonitors.profileResetHandler,
		}
		SkuMenu:RegisterPlugin(pluginName, pluginTable)
	end


end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:UpdateCurrentTalentSet()
	if GetActiveTalentGroup then
		SkuMonitors.talentSet = GetActiveTalentGroup()
	else
		SkuMonitors.talentSet = GetActiveSpecGroup()
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:COMBAT_LOG_EVENT_UNFILTERED(aEventName, aCustomEventData)
	local tEventData = aCustomEventData or {CombatLogGetCurrentEventInfo()}
	--print("COMBAT_LOG_EVENT_UNFILTERED", tEventData[CleuBase.subevent])

	--SkuAuras:RoleChecker(aEventName, tEventData)

	if tEventData[CleuBase.subevent] == "UNIT_DIED" then
		SkuDispatcher:TriggerSkuEvent("SKU_UNIT_DIED", tEventData[8], tEventData[9])
	end

	if tEventData[CleuBase.subevent] == "SPELL_CAST_START" then
		SkuDispatcher:TriggerSkuEvent("SKU_SPELL_CAST_START", tEventData)
	end
end