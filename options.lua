local MODULE_NAME = "SkuMonitors"
local L = SkuMonitors.L



--------------------------------------------------------------------------------------------------------------------------------------
SkuMonitors.options = {
	name = MODULE_NAME,
	handler = SkuMonitors,
	type = "group",
	args = {
		vocalizeMenuNumbers = {
			order = 1,
			name = L["not available in combat"],
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
SkuMonitors.defaults = {
	vocalizeMenuNumbers = true,
}

