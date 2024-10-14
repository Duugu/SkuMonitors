---------------------------------------------------------------------------------------------------------------------------------------
local MODULE_NAME, MODULE_PART = "SkuMonitors", "aqCombat"
local L = SkuMonitors.L
local _G = _G

local sfind = string.find

SkuMonitors = SkuMonitors or LibStub("AceAddon-3.0"):NewAddon("SkuMonitors", "AceConsole-3.0", "AceEvent-3.0")

local aqCombatVoices = {
   "emma",
   "brian",
}

local aqCombatAudioOutputs = {
   ["vocalized"] = "1 "..L["vocalized"],
}
--[[
for x = 12, 61, 4 do
   aqCombatAudioOutputs["sound-synth"..(string.format("%02d", x))] = L["Synth"].." "..(string.format("%02d", x))
   aqCombatAudioOutputs["sound-synth"..(string.format("%02d", x))..";vocalized"] = L["Synth"].." "..(string.format("%02d", x)).." "..L["plus"].." "..L["vocalized"]
end
]]

for x = 1, 20 do
   aqCombatAudioOutputs["sound-combat-notification"..(string.format("%02d", x))] = L["combat notification"].." "..(string.format("%02d", x))
   aqCombatAudioOutputs["sound-combat-notification"..(string.format("%02d", x))..";vocalized"] = L["combat notification"].." "..(string.format("%02d", x)).." "..L["plus"].." "..L["vocalized"]
end

SkuMonitors.RaidTargetValues = {
	[1] = {name = L["Star"], color = L["Yellow"]},
	[2] = {name = L["Circle"], color = L["Orange"]},
	[3] = {name = L["Diamond"], color = L["Purple"]},
	[4] = {name = L["Triangle"], color = L["Green"]},
	[5] = {name = L["Moon"], color = L["Grey"]},
	[6] = {name = L["Square"], color = L["Blue"]},
	[7] = {name = L["Cross"], color = L["Red"]},
	[8] = {name = L["Skull"], color = L["White"]},
}

SkuMonitors.SkuRaidTargetIndex = {
	[1] = 8,
	[2] = 7,
	[3] = 6,
	[4] = 4,
	[5] = 3,
	[6] = 1,
	[7] = 2,
	[8] = 5,
}

local tAllPartyRaidUnits = {
   "player",
   "pet",
}

local tUnitsToTestOnGameRaidTargets = {
   "player",
   "pet",
   "focus",
   "target",
   "pettarget",
   "focustarget",
   "playertargettarget",
   "pettargettarget",
   "focustargettarget",
   "targettarget",
}
for x = 1, 4 do
   table.insert(tAllPartyRaidUnits, "party"..x)
   table.insert(tAllPartyRaidUnits, "partypet"..x)
   
   table.insert(tUnitsToTestOnGameRaidTargets, "party"..x)
   table.insert(tUnitsToTestOnGameRaidTargets, "partypet"..x)
   table.insert(tUnitsToTestOnGameRaidTargets, "party"..x.."target")
   table.insert(tUnitsToTestOnGameRaidTargets, "partypet"..x.."target")
   table.insert(tUnitsToTestOnGameRaidTargets, "party"..x.."targettarget")
   table.insert(tUnitsToTestOnGameRaidTargets, "partypet"..x.."targettarget")
end
for x = 1, 25 do
   table.insert(tAllPartyRaidUnits, "raid"..x)
   table.insert(tAllPartyRaidUnits, "raidpet"..x)

   table.insert(tUnitsToTestOnGameRaidTargets, "raid"..x)
   table.insert(tUnitsToTestOnGameRaidTargets, "raidpet"..x)
   table.insert(tUnitsToTestOnGameRaidTargets, "raid"..x.."target")
   table.insert(tUnitsToTestOnGameRaidTargets, "raidpet"..x.."target")
   table.insert(tUnitsToTestOnGameRaidTargets, "raid"..x.."targettarget")
   table.insert(tUnitsToTestOnGameRaidTargets, "raidpet"..x.."targettarget")
end
for x = 1, 40 do
   table.insert(tUnitsToTestOnGameRaidTargets, "nameplate"..x)
end

SkuMonitors.SkuRaidTargetRepo = {} --[unitGUID] = SkuRaidTargetIndex,
SkuMonitors.SkuRaidTargetRepoDead = {} --[unitGUID] = SkuRaidTargetIndex,

SkuMonitors.aq.combat = {}
SkuMonitors.threatTable = {}
SkuMonitors.inOutCombatQueue = {
   current = 0,
   combatIn = {},
   combatOut = {},
}

SkuMonitors.partyDeadCountCounter = 0

local aqCombatIsPartyOrRaidMemberCache = {}

local tCurrentUpdateRate = 1

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitorsAqCombatGetVoiceString(aString, aTable)
   print("SkuMonitorsAqCombatGetVoiceString", aString, aTable)
   local tResult = (aString:gsub('($%b{})', function(w) 
      local tFinalString = aTable[w:sub(3, -2)] or w
      print(w)
      print(w:sub(3, -2))
      print("tFinalString start", tFinalString)
      if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].global.numberOnly == true then
         if sfind(tFinalString, "raidpet") then
            tFinalString = string.gsub(tFinalString, "raidpet", "")
         elseif sfind(tFinalString, "raid") then
            tFinalString = string.gsub(tFinalString, "raid", "")
         elseif sfind(tFinalString, "partypet") then
            tFinalString = string.gsub(tFinalString, "partypet", "")
         elseif sfind(tFinalString, "party") then
            tFinalString = string.gsub(tFinalString, "party", "")
         end
      end

      if sfind(tFinalString, "nameplate") then
         tFinalString = "creature"
      end

      print("tFinalString end", tFinalString)
      return tFinalString
   end))

   print("result1", tResult)
   if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.notificationVolume == 1 then
      tResult = string.gsub(tResult,  ";", "-low%1")
      if string.sub(tResult, string.len(tResult)-3, string.len(tResult)) ~= "-low" then
         tResult = tResult.."-low"
      end
   end

   print("result2", tResult)
   if string.sub(tResult, 1, 5) == "-low;" then
      tResult = string.sub(tResult, 6)
   end
   if string.sub(tResult, 1, 1) == ";" then
      tResult = string.sub(tResult, 2)
   end

   print("result3", tResult)
   return tResult
end
 
---------------------------------------------------------------------------------------------------------------------------------------
local function SkuMonitorsAqCombatOutput(aPattern, aValuesTable, aQueueSettings, aSkuSetting, aExtraSound)
   print("SkuMonitorsAqCombatOutput", aPattern, aValuesTable, aQueueSettings, aSkuSetting, aExtraSound)
   if aValuesTable.Unit1 then
      if sfind(aValuesTable.Unit1, "nameplate") then
         aValuesTable.Unit1 = "creature"
      end
   end
   if aValuesTable.Unit2 then
      if sfind(aValuesTable.Unit2, "nameplate") then
         aValuesTable.Unit2 = "creature"
      end
   end

   local tVoice = aqCombatVoices[SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voice] or "brian"
   aValuesTable.voice = tVoice

   local tSound = ""
   if sfind(aExtraSound or aSkuSetting.sound, ";") then
      tSound = string.match(aExtraSound or aSkuSetting.sound, "(.+);(.+)")
   elseif sfind(aExtraSound or aSkuSetting.sound, "sound-") then
      aValuesTable = {
         voice = tVoice,
      }
      aPattern = "${sound}"
      tSound = aExtraSound or aSkuSetting.sound
   end
   aValuesTable.sound = tSound
   aPattern = string.gsub(aPattern, ";", ";${voice}-")

   if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voiceVolume == 1 then
      aPattern = string.gsub(aPattern, ";", "-low;")
      aPattern = aPattern.."-low"
   end

   if SkuMenu then
      SkuMenu.Voice:OutputString(SkuMonitorsAqCombatGetVoiceString(aPattern, aValuesTable), {wait = aQueueSettings.wait, overwrite = aQueueSettings.overwrite, instant = aQueueSettings.instant, doNotOverwrite = aQueueSettings.doNotOverwrite,}) 
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatCreatureGuidToUnitId(aUnitGUID)
   for i = 1, #tUnitsToTestOnGameRaidTargets do
      local tCreatureGUID = UnitGUID(tUnitsToTestOnGameRaidTargets[i])
      if UnitGUID(tUnitsToTestOnGameRaidTargets[i]) then
         if tCreatureGUID == aUnitGUID then
            return tUnitsToTestOnGameRaidTargets[i]
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatGroupGuidToUnitId(aUnitGUID)
   if aqCombatIsPartyOrRaidMemberCache[aUnitGUID] then
      return aqCombatIsPartyOrRaidMemberCache[aUnitGUID]
   end

   for i = 1, #tAllPartyRaidUnits do
      local tTargetUnitIdToTest = tAllPartyRaidUnits[i]
      local tCreatureGUID = UnitGUID(tTargetUnitIdToTest)
      if tCreatureGUID then
         if tCreatureGUID == aUnitGUID then
            return tTargetUnitIdToTest
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatGroupNameToUnitId(aName)
   for i = 1, #tAllPartyRaidUnits do
      local tTargetUnitIdToTest = tAllPartyRaidUnits[i]
      local tName = UnitName(tTargetUnitIdToTest)
      if tName then
         if tName == aName then
            return tTargetUnitIdToTest
         end
      end
   end
end


---------------------------------------------------------------------------------------------------------------------------------------
local tAqCombatGetUnitIndexFromUnitGUIDCache = {}
local function aqCombatGetUnitIndexFromUnitGUID(aUnitGUID)
   if aUnitGUID == nil then
      return
   end   

   if tAqCombatGetUnitIndexFromUnitGUIDCache[aUnitGUID] then
      return tAqCombatGetUnitIndexFromUnitGUIDCache[aUnitGUID]
   end

   local unit_type = strsplit("-", aUnitGUID)
   if unit_type == "Creature" or unit_type == "Vehicle" then
      local _, _, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", aUnitGUID)
      tAqCombatGetUnitIndexFromUnitGUIDCache[aUnitGUID] = npc_id
      return npc_id
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
local tUnitClassificationCache = {}
local tKeysRank
local function aqCombatCheckElite(aUnitGUID, aTargetUnitIdToTest)
   if aUnitGUID == nil and aTargetUnitIdToTest == nil then
      return
   end

   local beginTime6 = debugprofilestop() 

   if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.ignoreNonElite == true then   

      if aUnitGUID and tUnitClassificationCache[aUnitGUID] then
         return tUnitClassificationCache[aUnitGUID]
      end


      if aTargetUnitIdToTest == nil then
         local tUnitId = SkuMonitors:aqCombatCreatureGuidToUnitId(aUnitGUID)
         if tUnitId then
            aTargetUnitIdToTest = tUnitId
         end
      end

      if aTargetUnitIdToTest ~= nil  then
         aUnitGUID = UnitGUID(aTargetUnitIdToTest)
         local tUnitClassification = UnitClassification(aTargetUnitIdToTest)
         --SkuMonitors.PerformanceData["aqCombatCheckElite"] = ((--SkuMonitors.PerformanceData["aqCombatCheckElite"] or 0) + (debugprofilestop() - beginTime6)) / 2

         if aUnitGUID then
            if (tUnitClassification == "elite" or tUnitClassification == "rareelite" or tUnitClassification == "worldboss") then
               tUnitClassificationCache[aUnitGUID] = true
            else
               tUnitClassificationCache[aUnitGUID] = false
            end
            return tUnitClassificationCache[aUnitGUID]
         end
      end
         
      local index = aqCombatGetUnitIndexFromUnitGUID(aUnitGUID)
      if index then




         if SkuDB then
            local tData = SkuDB.NpcData.Data[index]
            if tData then
               if tData[tKeysRank] then
                  --SkuMonitors.PerformanceData["aqCombatCheckElite1"] = ((--SkuMonitors.PerformanceData["aqCombatCheckElite1"] or 0) + (debugprofilestop() - beginTime6)) / 2
                  if 
                     tData[tKeysRank] ~= 1 and
                     tData[tKeysRank] ~= 2 and
                     tData[tKeysRank] ~= 3
                  then
                     tUnitClassificationCache[aUnitGUID] = false
                  else
                     tUnitClassificationCache[aUnitGUID] = true
                  end
                  return tUnitClassificationCache[aUnitGUID]
               end
            end
         end
      end

      local tUnitId = SkuMonitors:aqCombatCreatureGuidToUnitId(aUnitGUID)
      if tUnitId then
         aUnitGUID = UnitGUID(aTargetUnitIdToTest)
         local t = UnitClassification(tUnitId)
         if aUnitGUID and t then
            --SkuMonitors.PerformanceData["aqCombatCheckElite2"] = ((--SkuMonitors.PerformanceData["aqCombatCheckElite2"] or 0) + (debugprofilestop() - beginTime6)) / 2
            if t ~= "worldboss" and t ~= "rareelite" and t ~= "elite" then
               tUnitClassificationCache[aUnitGUID] = false
            else
               tUnitClassificationCache[aUnitGUID] = true
            end
            return tUnitClassificationCache[aUnitGUID]
         end
      end
   else
      --SkuMonitors.PerformanceData["aqCombatCheckElite3"] = ((--SkuMonitors.PerformanceData["aqCombatCheckElite3"] or 0) + (debugprofilestop() - beginTime6)) / 2
      return true
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatIsPartyOrRaidMember(aUnitId, aUnitGUID)
   local beginTime2 = debugprofilestop()   

   if aUnitId then
      local aUnitIdGuid = UnitGUID(aUnitId)
      
      if not aUnitIdGuid then
         return
      end

      if aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] then
         return aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid]
      end
      
      if UnitGUID("player") == aUnitIdGuid then
         aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] = "player"
         ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
         return "player"
      end
      if UnitGUID("pet") == aUnitIdGuid then
         aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] = "pet"
         ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
         return "pet"
      end
      for x = 1, 4 do
         if UnitGUID("party"..x) == aUnitIdGuid then
            aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] = "party"..x
            ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
            return "party"..x
         end
         if UnitGUID("partypet"..x) == aUnitIdGuid then
            aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] = "partypet"..x
            ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
            return "partypet"..x
         end
      end
      for x = 1, 40 do
         if UnitGUID("raid"..x) == aUnitIdGuid then
            aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] = "raid"..x
            ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
            return "raid"
         end
         if UnitGUID("raidpet"..x) == aUnitIdGuid then
            aqCombatIsPartyOrRaidMemberCache[aUnitIdGuid] = "raidpet"..x
            ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
            return "raidpet"..x
         end
      end

      if UnitIsEnemy("player", aUnitId) ~= true then
         ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
         return
      end
      

      return --"unknown"
   elseif aUnitGUID then
      for q = 1, #tAllPartyRaidUnits do
         local tPartyUnitToTest = tAllPartyRaidUnits[q]
         local tPartyGuid = UnitGUID(tPartyUnitToTest)
         if tPartyGuid == aUnitGUID then
            aqCombatIsPartyOrRaidMemberCache[aUnitGUID] = tPartyUnitToTest
            ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember2"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember2"] or 0) + (debugprofilestop() - beginTime2)) / 2                     
            return tPartyUnitToTest
         end
      end
   end

   ----SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember3"] = ((--SkuMonitors.PerformanceData["aqCombatIsPartyOrRaidMember3"] or 0) + (debugprofilestop() - beginTime2)) / 2                              
end

---------------------------------------------------------------------------------------------------------------------------------------
local tthreatWarningNotFirstHigherThanLastWarning = 0
local tthreatWarningIsFirstSecondHigherThanLastWarning = 0
local tOorIntervalTime = -2
local function aqCombatCreateControlFrame()
   local f = _G["SkuMonitorsaqCombatControl"] or CreateFrame("Frame", "SkuMonitorsaqCombatControl", UIParent)
   local ttime = 0
   f:SetScript("OnUpdate", function(self, time)
      ttime = ttime + time
      if ttime < (0.1 * tCurrentUpdateRate) then
         return
      end
      if not SkuMonitors.db.char[MODULE_NAME].aq then
         return
      end
      local tCurrentSettings = SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet]
      tCurrentUpdateRate = (21 - tCurrentSettings.combat.updateRate)
      if tCurrentSettings.combat.friendly.outOfRangeEnabled.value == true and tCurrentSettings.combat.enabled == true then
         local beginTime1 = debugprofilestop()

         if tCurrentSettings.combat.friendly.oorUnitName ~= L["Nothing selected"] then
            local tUniId = SkuMonitors:aqCombatGroupNameToUnitId(tCurrentSettings.combat.friendly.oorUnitName)
            if tUniId then
               local _, tMinRange = SkuMonitors.RangeCheck:GetRange(tUniId)
               if tMinRange and tMinRange > tCurrentSettings.combat.friendly.oorAt then
                  local tDoOutput = false
                  if tCurrentSettings.combat.friendly.oorInterval == 0 then
                     if tOorIntervalTime ~= -1 then
                        tDoOutput = true
                        tOorIntervalTime = -1
                     end
                  else
                     if tOorIntervalTime < 0 then
                        tDoOutput = true
                        tOorIntervalTime = GetTimePreciseSec() 
                     else
                        if GetTimePreciseSec() - tOorIntervalTime > tCurrentSettings.combat.friendly.oorInterval then
                           tDoOutput = true
                           tOorIntervalTime = GetTimePreciseSec() 
                        end
                     end
                  end
                  if tDoOutput == true then
                     local tSetting = tCurrentSettings.combat.friendly.outOfRangeEnabled
                     SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tUniId,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                  end
               else
                  tOorIntervalTime = -2
               end
            end
         end
         --SkuMonitors.PerformanceData["combat.friendly.outOfRangeEnabled"] = ((--SkuMonitors.PerformanceData["combat.friendly.outOfRangeEnabled"] or 0) + (debugprofilestop() - beginTime1)) / 2

      end
            
      --clearnup lost guids from SkuMonitors.SkuRaidTargetRepo?

      if tCurrentSettings.combat.enabled == true then
         local beginTime2 = debugprofilestop()

         for i = 1, #tUnitsToTestOnGameRaidTargets do
            local tTargetUnitIdToTest = tUnitsToTestOnGameRaidTargets[i]
            local tCreatureGUID = UnitGUID(tTargetUnitIdToTest)
            if tCreatureGUID then
               if aqCombatCheckElite(tCreatureGUID, tTargetUnitIdToTest) == true then
                  if tCreatureGUID and SkuMonitors.threatTable[tCreatureGUID] ~= false then
                     local t = SkuMonitors:aqCombatIsPartyOrRaidMember(tTargetUnitIdToTest)
                     if t == nil then
                        -- is mob
                        for q = 1, #tAllPartyRaidUnits do
                           local tPartyUnitToTest = tAllPartyRaidUnits[q]
                           local isTanking, status, scaledPercentage, rawPercentage, threatValue = UnitDetailedThreatSituation(tPartyUnitToTest, tTargetUnitIdToTest)
                           if status then
                              local tPartyGuid = UnitGUID(tPartyUnitToTest)
                              if UnitIsDeadOrGhost(tPartyUnitToTest) ~= true then
                                 SkuMonitors:aqCombat_CREATURE_ADDED_TO_COMBAT(tCreatureGUID, tTargetUnitIdToTest, UnitName(tTargetUnitIdToTest), UnitGUID(tPartyUnitToTest), tPartyUnitToTest, UnitName(tPartyUnitToTest))

                                 local tPlayerGUID = UnitGUID("player")
                                 if tCreatureGUID == UnitGUID("target") and tPartyGuid == tPlayerGUID then
                                    if SkuMonitors.threatTable[tCreatureGUID] then
                                       if SkuMonitors.threatTable[tCreatureGUID][tPartyGuid] then
                                          if SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].isTanking == true and SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].wasTanking ~= true then
                                             if tCurrentSettings.combat.hostile.warnIfTargetSwitchingToYou.value == true then
                                                local tSetting = tCurrentSettings.combat.hostile.warnIfTargetSwitchingToYou
                                                SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                                             end
                                             SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].wasTanking = true
                                          elseif SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].isTanking ~= true and SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].wasTanking == true then
                                             if tCurrentSettings.combat.hostile.warnIfTargetSwitchingToParty.value == true then
                                                local tSetting = tCurrentSettings.combat.hostile.warnIfTargetSwitchingToParty
                                                SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                                             end
                                             SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].wasTanking = false                                      
                                          end
                                       end
                                    end
                                 end

                                 SkuMonitors.threatTable[tCreatureGUID].name = UnitName(tTargetUnitIdToTest) 
                                 SkuMonitors.threatTable[tCreatureGUID].lastUpdate = GetTimePreciseSec() 
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid] = SkuMonitors.threatTable[tCreatureGUID][tPartyGuid] or {}
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].lastUpdate = GetTimePreciseSec()
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].isTanking = isTanking
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].status = status
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].scaledPercentage = scaledPercentage
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].rawPercentage = rawPercentage
                                 SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].threatValue = threatValue                
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
         --SkuMonitors.PerformanceData["combat num in c"] = ((--SkuMonitors.PerformanceData["combat num in c"] or 0) + (debugprofilestop() - beginTime2)) / 2         

      end

      if SkuMonitors.aqCombatCheckThreat then
         if tCurrentSettings.combat.enabled == true then
            local beginTime3 = debugprofilestop()

            local tPlayerGUID = UnitGUID("player")
            local tTargetGUID = UnitGUID("target")

            if tTargetGUID then
               if aqCombatCheckElite(tTargetGUID, "target") == true then               
                  if SkuMonitors.threatTable[tTargetGUID] then
                     if SkuMonitors.threatTable[tTargetGUID][tPlayerGUID] and SkuMonitors.threatTable[tTargetGUID][tPlayerGUID].isTanking ~= nil then
                        --Threat warning if you are first place (tanking) and second place threat percentage is higher than
                        if SkuMonitors.threatTable[tTargetGUID][tPlayerGUID].scaledPercentage >= 100 then
                           tthreatWarningNotFirstHigherThanLastWarning = 0
                           if tCurrentSettings.combat.hostile.threatWarningIsFirstSecondHigherThan.value > 0 then
                              local tWarnUnitId, tWarnPercent = nil, 0
                              for i, v in pairs(SkuMonitors.threatTable[tTargetGUID]) do
                                 if type(v) == "table" then
                                    if i ~= tPlayerGUID then
                                       if v.scaledPercentage then
                                          if v.scaledPercentage > tCurrentSettings.combat.hostile.threatWarningIsFirstSecondHigherThan.value then
                                             if v.scaledPercentage < 110 then
                                                if tWarnPercent < v.scaledPercentage then
                                                   tWarnUnitId = i
                                                   tWarnPercent = v.scaledPercentage
                                                end
                                             end
                                          end
                                       end
                                    end
                                 end
                              end
                              
                              if tWarnUnitId then
                                 if tCurrentSettings.combat.hostile.threatWarningInterval > 0 then
                                    if tthreatWarningIsFirstSecondHigherThanLastWarning == -1 or GetTimePreciseSec() - tthreatWarningIsFirstSecondHigherThanLastWarning > tCurrentSettings.combat.hostile.threatWarningInterval then
                                       tthreatWarningIsFirstSecondHigherThanLastWarning = GetTimePreciseSec() 
                                       local tSetting = tCurrentSettings.combat.hostile.threatWarningIsFirstSecondHigherThan
                                       SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tAllPartyRaidUnits[x],}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                                    end
                                 else
                                    if tthreatWarningIsFirstSecondHigherThanLastWarning > -1  then
                                       local tSetting = tCurrentSettings.combat.hostile.threatWarningIsFirstSecondHigherThan
                                       SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tAllPartyRaidUnits[x],}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                                       tthreatWarningIsFirstSecondHigherThanLastWarning = -1
                                    end
                                 end
                              else
                                 tthreatWarningIsFirstSecondHigherThanLastWarning = 0
                              end
                           end

                        --Threat warning if you are not first place (not tanking) and your threat percentage is higher than
                        --elseif SkuMonitors.threatTable[tTargetGUID][tPlayerGUID].isTanking == false then
                        else
                           tthreatWarningIsFirstSecondHigherThanLastWarning = 0
                           if tCurrentSettings.combat.hostile.threatWarningNotFirstHigherThan.value > 0  then
                              if SkuMonitors.threatTable[tTargetGUID][tPlayerGUID].scaledPercentage > tCurrentSettings.combat.hostile.threatWarningNotFirstHigherThan.value then
                                 if tCurrentSettings.combat.hostile.threatWarningInterval > 0 then
                                    if tthreatWarningNotFirstHigherThanLastWarning == -1 or GetTimePreciseSec() - tthreatWarningNotFirstHigherThanLastWarning > tCurrentSettings.combat.hostile.threatWarningInterval then
                                       tthreatWarningNotFirstHigherThanLastWarning = GetTimePreciseSec() 
                                       local tSetting = tCurrentSettings.combat.hostile.threatWarningNotFirstHigherThan
                                       SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tAllPartyRaidUnits[x],}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                                    end
                                 else
                                    if tthreatWarningNotFirstHigherThanLastWarning > -1  then
                                       local tSetting = tCurrentSettings.combat.hostile.threatWarningNotFirstHigherThan
                                       SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tAllPartyRaidUnits[x],}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                                       tthreatWarningNotFirstHigherThanLastWarning = -1
                                    end
                                 end
                              else
                                 tthreatWarningNotFirstHigherThanLastWarning = 0
                              end
                           end
                        end
                     end
                  end
               end
            end
            --SkuMonitors.PerformanceData["combat threat 2"] = ((--SkuMonitors.PerformanceData["combat threat 2"] or 0) + (debugprofilestop() - beginTime3)) / 2                     

         end

         --[[
         for q = 1, #tAllPartyRaidUnits do
            local tPartyUnitToTest = tAllPartyRaidUnits[q]
            local tPartyGuid = UnitGUID(tPartyUnitToTest)
            if tPartyGuid then
               --print(tPartyUnitToTest)
               for tCreatureGUID, tvalue in pairs(SkuMonitors.threatTable) do
                  if tvalue ~= false and tvalue[tPartyGuid] then
                     --print("  ", tvalue.name, tvalue[tPartyGuid].status, tvalue[tPartyGuid].scaledPercentage)
                  end
               end
            end
         end
         ]]
      end

      ttime = 0
   end)

   ---
   local f = _G["SkuMonitorsaqCombatQueueControl"] or CreateFrame("Frame", "SkuMonitorsaqCombatQueueControl", UIParent)
   local ttime1 = 0
   local ttime2 = 0
   f:SetScript("OnUpdate", function(self, time)
      if not SkuMonitors.db.char[MODULE_NAME].aq then
         return
      end
      local tCurrentSettings = SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet]

      if tCurrentSettings.combat.enabled == true then
         local beginTime = debugprofilestop()
         if tCurrentSettings.combat.hostile.relativeNumberUnitsInCombat.value > 1 then
            ttime2 = ttime2 + time
            if ttime2 > (0.1 * tCurrentUpdateRate) then
               tCurrentUpdateRate = (21 - tCurrentSettings.combat.updateRate)

               local tPlayerGUID = UnitGUID("player")
               local tChanged = false
               local tCount = 0
               for creatureGUID, value in pairs(SkuMonitors.inOutCombatQueue.combatIn) do
                  if aqCombatCheckElite(creatureGUID) == true then
                     if tCurrentSettings.combat.hostile.relativeNumberUnitsInCombat.value == 4 then
                        if SkuMonitors.threatTable[creatureGUID] then
                           if SkuMonitors.threatTable[creatureGUID][tPlayerGUID] then   
                              if SkuMonitors.threatTable[creatureGUID][tPlayerGUID].status then
                                 if SkuMonitors.threatTable[creatureGUID][tPlayerGUID].isTanking == true then
                                    SkuMonitors.inOutCombatQueue.current = SkuMonitors.inOutCombatQueue.current + 1
                                    tChanged = true
                                 end
                              end
                           end
                        end

                     elseif tCurrentSettings.combat.hostile.relativeNumberUnitsInCombat.value == 3 then
                        local tAdded
                        for q = 1, #tAllPartyRaidUnits do
                           local tPartyUnitToTest = tAllPartyRaidUnits[q]
                           local tPartyGuid = UnitGUID(tPartyUnitToTest)
                           if SkuMonitors.threatTable[creatureGUID] then
                              if SkuMonitors.threatTable[creatureGUID][tPartyGuid] then   
                                 if SkuMonitors.threatTable[creatureGUID][tPartyGuid].status then
                                    if SkuMonitors.threatTable[creatureGUID][tPartyGuid].isTanking == true then
                                       if not tAdded then
                                          tAdded = creatureGUID
                                          SkuMonitors.inOutCombatQueue.current = SkuMonitors.inOutCombatQueue.current + 1
                                       end

                                       tChanged = true
                                    end
                                 elseif SkuMonitors:aqCombatIsPartyOrRaidMember(SkuMonitors.inOutCombatQueue.combatIn[creatureGUID]) then
                                    if not tAdded then
                                       tAdded = creatureGUID
                                       SkuMonitors.inOutCombatQueue.current = SkuMonitors.inOutCombatQueue.current + 1
                                    end

                                    tChanged = true
                                 end
                              end
                           end
                        end
                     
                     elseif tCurrentSettings.combat.hostile.relativeNumberUnitsInCombat.value == 2 then
                        SkuMonitors.inOutCombatQueue.current = SkuMonitors.inOutCombatQueue.current + 1
                        tChanged = true
                     end

                     SkuMonitors.inOutCombatQueue.combatIn[creatureGUID] = nil
                  end
               end
               
               for creatureGUID, _ in pairs(SkuMonitors.inOutCombatQueue.combatOut) do
                  if aqCombatCheckElite(creatureGUID) == true then
                     SkuMonitors.inOutCombatQueue.current = SkuMonitors.inOutCombatQueue.current - 1
                     tChanged = true
                     SkuMonitors.inOutCombatQueue.combatOut[creatureGUID] = nil
                  end
               end

               if SkuMonitors.inOutCombatQueue.current < 0 then
                  SkuMonitors.inOutCombatQueue.current = 0
               end

               if tChanged == true then
                  local tSetting = tCurrentSettings.combat.hostile.relativeNumberUnitsInCombat
                  SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {number1 = SkuMonitors.inOutCombatQueue.current,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
               end

               ttime2 = 0
            end

         elseif tCurrentSettings.combat.hostile.unitsAddedToCombat.value > 1 or tCurrentSettings.combat.hostile.unitsLeavingCombat.value > 1 then
            ttime1 = ttime1 + time

            if ttime1 > (1.0) then
               tCurrentUpdateRate = (21 - tCurrentSettings.combat.updateRate)

               local tCountIn = 0

               local tPlayerGUID = UnitGUID("player")
               local tChanged = false

               local tCount = 0
               for creatureGUID, value in pairs(SkuMonitors.inOutCombatQueue.combatIn) do
                  if aqCombatCheckElite(creatureGUID) == true then
                     if tCurrentSettings.combat.hostile.unitsAddedToCombat.value == 4 then
                        if SkuMonitors.threatTable[creatureGUID] then
                           if SkuMonitors.threatTable[creatureGUID][tPlayerGUID] then   
                              if SkuMonitors.threatTable[creatureGUID][tPlayerGUID].status then
                                 if SkuMonitors.threatTable[creatureGUID][tPlayerGUID].isTanking == true then
                                    tCountIn = tCountIn + 1
                                    tChanged = true
                                 end
                              end
                           end
                        end

                     elseif tCurrentSettings.combat.hostile.unitsAddedToCombat.value == 3 then
                        local tAdded
                        for q = 1, #tAllPartyRaidUnits do
                           local tPartyUnitToTest = tAllPartyRaidUnits[q]
                           local tPartyGuid = UnitGUID(tPartyUnitToTest)
                           if SkuMonitors.threatTable[creatureGUID] then
                              if SkuMonitors.threatTable[creatureGUID][tPartyGuid] then   
                                 if SkuMonitors.threatTable[creatureGUID][tPartyGuid].status then
                                    if SkuMonitors.threatTable[creatureGUID][tPartyGuid].isTanking == true then
                                       if not tAdded then
                                          tAdded = creatureGUID
                                          tCountIn = tCountIn + 1
                                          tChanged = true
                                       end
                                    end
                                 elseif SkuMonitors:aqCombatIsPartyOrRaidMember(SkuMonitors.inOutCombatQueue.combatIn[creatureGUID]) then
                                    if not tAdded then
                                       tAdded = creatureGUID
                                       tCountIn = tCountIn + 1
                                       tChanged = true
                                    end
                                 end
                              end
                           end
                        end
                     
                     elseif tCurrentSettings.combat.hostile.unitsAddedToCombat.value == 2 then
                        tCountIn = tCountIn + 1
                        tChanged = true
                     end

                     SkuMonitors.inOutCombatQueue.combatIn[creatureGUID] = nil
                  end
               end

               local tCountOut = 0
               for unitGUID, _ in pairs(SkuMonitors.inOutCombatQueue.combatOut) do
                  if aqCombatCheckElite(unitGUID) == true then
                     tCountOut = tCountOut + 1
                  end
               end

               SkuMonitors.inOutCombatQueue.current = SkuMonitors.inOutCombatQueue.current + tCountIn - tCountOut

               if SkuMonitors.inOutCombatQueue.current < 0 then
                  SkuMonitors.inOutCombatQueue.current = 0
               end
               
               SkuMonitors.inOutCombatQueue.combatOut = {}

               if tCountIn > 0 and tCurrentSettings.combat.hostile.unitsAddedToCombat.value > 1 then
                  local tSetting = tCurrentSettings.combat.hostile.unitsAddedToCombat
                  SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {number1 = tCountIn, action1 = "in",}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
               end
               if tCountOut > 0 and tCurrentSettings.combat.hostile.unitsLeavingCombat.value > 1 then
                  local tSetting = tCurrentSettings.combat.hostile.unitsLeavingCombat
                  SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {number1 = tCountOut, action1 = "out",}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
               end

               ttime1 = 0
            end

         end

         --SkuMonitors.PerformanceData["aqCombatQueue onupdate"] = ((--SkuMonitors.PerformanceData["aqCombatQueue onupdate"] or 0) + (debugprofilestop() - beginTime)) / 2
      end
   end)   
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_CREATURE_REMOVED_FROM_COMBAT(aCreatureGuid, aCreatureUnitId, aCreatureName)
   --print("aqCombat_CREATURE_REMOVED_FROM_COMBAT", aCreatureGuid, aCreatureUnitId, aCreatureName)
   if SkuMonitors.threatTable[aCreatureGuid] == nil then
      return
   end
   SkuMonitors.inOutCombatQueue.combatOut[aCreatureGuid] = true
   SkuMonitors.threatTable[aCreatureGuid] = false
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_CREATURE_ADDED_TO_COMBAT(aCreatureGuid, aCreatureUnitId, aCreatureName, aPartyGuid, aPartyUnitId, aPartyName)
   --print("aqCombat_CREATURE_ADDED_TO_COMBAT", aCreatureGuid, aCreatureUnitId, aCreatureName, aPartyGuid, aPartyUnitId, aPartyName)
   if SkuMonitors.threatTable[aCreatureGuid] then
      return
   end
   SkuMonitors.threatTable[aCreatureGuid] = SkuMonitors.threatTable[aCreatureGuid] or {}
   SkuMonitors.inOutCombatQueue.combatIn[aCreatureGuid] = aPartyUnitId
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatOnInitialize()
   --tKeysRank = SkuDB.NpcData.Keys.rank

	aqCombatCreateControlFrame()

   SkuDispatcher:RegisterEventCallback("COMBAT_LOG_EVENT_UNFILTERED", SkuMonitors.aqCombat_COMBAT_LOG_EVENT_UNFILTERED)
   SkuDispatcher:RegisterEventCallback("SKU_UNIT_DIED", SkuMonitors.aqCombat_SKU_UNIT_DIED)
   SkuDispatcher:RegisterEventCallback("SKU_SPELL_CAST_START", SkuMonitors.aqCombat_SKU_SPELL_CAST_START)
   
   SkuDispatcher:RegisterEventCallback("PLAYER_ENTERING_WORLD", SkuMonitors.aqCombat_PLAYER_ENTERING_WORLD)
   SkuDispatcher:RegisterEventCallback("RAID_TARGET_UPDATE", SkuMonitors.aqCombatCheckGameRaidTargets)
	SkuDispatcher:RegisterEventCallback("PLAYER_REGEN_DISABLED", SkuMonitors.aqCombat_PLAYER_REGEN_DISABLED)
	SkuDispatcher:RegisterEventCallback("PLAYER_REGEN_ENABLED", SkuMonitors.aqCombat_PLAYER_REGEN_ENABLED)
	--SkuDispatcher:RegisterEventCallback("UNIT_THREAT_LIST_UPDATE", SkuMonitors.aqCombatUNIT_THREAT_LIST_UPDATE)
	--SkuDispatcher:RegisterEventCallback("UNIT_THREAT_SITUATION_UPDATE", SkuMonitors.aqCombatUNIT_THREAT_SITUATION_UPDATE)

	SkuDispatcher:RegisterEventCallback("PLAYER_TARGET_CHANGED", SkuMonitors.aqCombatPLAYER_TARGET_CHANGED)
   SkuDispatcher:RegisterEventCallback("GROUP_ROSTER_UPDATE", SkuMonitors.aqCombat_GROUP_ROSTER_UPDATE)
   SkuDispatcher:RegisterEventCallback("GROUP_FORMED", SkuMonitors.aqCombat_GROUP_ROSTER_UPDATE)
   SkuDispatcher:RegisterEventCallback("GROUP_JOINED", SkuMonitors.aqCombat_GROUP_ROSTER_UPDATE)

   
   hooksecurefunc("SetRaidTarget", function(aUnit, aIconIndex)
      if aIconIndex == 0 then
         local tGUID = UnitGUID(aUnit)
         if tGUID then
            SkuMonitors:aqCombatSetSkuRaidTarget(tGUID)
         end
      end
   end)
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatOnLogin()
	SkuMonitors.db.char = SkuMonitors.db.char or {}
	SkuMonitors.db.char[MODULE_NAME] = SkuMonitors.db.char[MODULE_NAME] or {}
	SkuMonitors.db.char[MODULE_NAME].aq = SkuMonitors.db.char[MODULE_NAME].aq or {}

   
   for x = 1, 2 do
      SkuMonitors.db.char[MODULE_NAME].aq[x].combat = SkuMonitors.db.char[MODULE_NAME].aq[x].combat or {}

      if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.enabled == nil then
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.enabled = false
      end

      if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.updateRate == nil then
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.updateRate = 20
      end

      if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.voice == nil then
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.voice = 1
      end

      if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.notificationVolume == nil then
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.notificationVolume = 1
      end

      if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.voiceVolume == nil then
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.voiceVolume = 2
      end
      

      --hostile
         if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile == nil then
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile = {}
         end

         --ignoreNonElite
            if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.ignoreNonElite == nil then
               SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.ignoreNonElite = true
            end

         --threat
            --Output target of target on target change
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatOutputTot = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatOutputTot or 
            {
               value = 1,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatOutputTot.voiceOutput = "${sound};target;${unit1}"

            --Threat warning if you are not first place (not tanking) and your threat percentage is higher than
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningNotFirstHigherThan = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningNotFirstHigherThan or 
            {
               value = 0,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningNotFirstHigherThan.voiceOutput = "${sound};threat;high"

            --Threat warning if you are first place (tanking) and second place threat percentage is higher than
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningIsFirstSecondHigherThan = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningIsFirstSecondHigherThan or
            {
               value = 0,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningIsFirstSecondHigherThan.voiceOutput = "${sound};threat;low"

            --threatWarningInterval
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningInterval = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.threatWarningInterval or 0

            --Warning if your target is switching from you to party member
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.warnIfTargetSwitchingToParty = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.warnIfTargetSwitchingToParty or 
            {
               value = false,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.warnIfTargetSwitchingToParty.voiceOutput = "${sound};target;lost"
            
            --Warning if your target is switching from party member to you
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.warnIfTargetSwitchingToYou = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.warnIfTargetSwitchingToYou or 
            {
               value = false,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.warnIfTargetSwitchingToYou.voiceOutput = "${sound};target;gained"
            
         --casting
            --Output your target casting
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.yourTargetCasting = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.yourTargetCasting or 
            {
               value = 0,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.yourTargetCasting.voiceOutput = "${sound};target;casting"
            
            --Output all enemies casting
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.allEnemiesCasting = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.allEnemiesCasting or 
            {
               value = 0,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.allEnemiesCasting.voiceOutput = "${sound};creature;casting"
            
            --minimumCastDuration
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.minimumCastDuration = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.minimumCastDuration or 0

         
         --deaths
            --ignore dead units not in combat
            if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.deathsIgnoreUnitsNotInCombat == nil then
               SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.deathsIgnoreUnitsNotInCombat = true
            end

            --Output dead units
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.outputDeadUnits = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.outputDeadUnits or 
            {
               value = 1,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.outputDeadUnits.voiceOutput = "${sound};${unit1};dead"


         --units in combat
            --Announce enemies entering combat
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.unitsAddedToCombat = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.unitsAddedToCombat or 
            {
               value = 1,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.unitsAddedToCombat.voiceOutput = "${sound};${number1};${action1}"

            --Announce enemies leaving combat
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.unitsLeavingCombat = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.unitsLeavingCombat or 
            {
               value = 1,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.unitsLeavingCombat.voiceOutput = "${sound};${number1};${action1}"

            if SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.shortUnitsAddedOrLeavingToCombatMessages == nil then
               SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.shortUnitsAddedOrLeavingToCombatMessages = false
            end

            --Announce relative number of enemies in combat
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.relativeNumberUnitsInCombat = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.relativeNumberUnitsInCombat or 
            {
               value = 1,
               sound = "vocalized",
            }
            SkuMonitors.db.char[MODULE_NAME].aq[x].combat.hostile.relativeNumberUnitsInCombat.voiceOutput = "${sound};${number1}"

      --friendly
      SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly or {}
         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.partyDead = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.partyDead or
         {
            value = false,
            sound = "vocalized",
         }
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.partyDead.voiceOutput = "${sound};${unit1};dead"

         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.partyDeadCount = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.partyDeadCount or
         {
            value = false,
            sound = "vocalized",
         }
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.partyDeadCount.voiceOutput = "${sound};${number1};dead"

         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.outOfRangeEnabled = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.outOfRangeEnabled or
         {
            value = false,
            sound = "vocalized",
         }
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.outOfRangeEnabled.voiceOutput = "${sound};${unit1};leaving"

         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.ignoreDeadPartyPets = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.ignoreDeadPartyPets or true

         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.oorAt = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.oorAt or 10

         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.oorUnitName = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.oorUnitName or L["Nothing selected"]

         --
         SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.oorInterval = SkuMonitors.db.char[MODULE_NAME].aq[x].combat.friendly.oorInterval or 0

   end
end

---------------------------------------------------------------------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_GROUP_ROSTER_UPDATE()
   aqCombatIsPartyOrRaidMemberCache = {}
   
   if UnitGUID("player") then
      aqCombatIsPartyOrRaidMemberCache[UnitGUID("player")] = "player"
   end

   if UnitGUID("pet") then
      aqCombatIsPartyOrRaidMemberCache[UnitGUID("pet")] = "pet"
   end

   for x = 1, 4 do
      if UnitGUID("party"..x) then
         aqCombatIsPartyOrRaidMemberCache[UnitGUID("party"..x)] = "party"..x
      end
      if UnitGUID("partypet"..x) then
         aqCombatIsPartyOrRaidMemberCache[UnitGUID("partypet"..x)] = "partypet"..x
      end
   end

   for x = 1, 40 do
      if UnitGUID("raid"..x) then
         aqCombatIsPartyOrRaidMemberCache[UnitGUID("raid"..x)] = "raid"..x
      end
      if UnitGUID("raidpet"..x) then
         aqCombatIsPartyOrRaidMemberCache[UnitGUID("raidpet"..x)] = "raidpet"..x
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatPLAYER_TARGET_CHANGED(aEvent, a, b, c, d)
   if not SkuMonitors.db.char[MODULE_NAME].aq then
      return
   end   
   local tCurrentSettings = SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet]
   if tCurrentSettings.combat.enabled == true then
      if tCurrentSettings.combat.hostile.threatOutputTot.value > 1 then
         if UnitExists("playertargettarget") then
            local tOutput = tCurrentSettings.combat.hostile.threatOutputTot.voiceOutput
            for x = 1, #tAllPartyRaidUnits do
               if UnitGUID(tAllPartyRaidUnits[x]) == UnitGUID("playertargettarget") then
                  if aqCombatCheckElite(UnitGUID("playertargettarget")) == true then
                     if tCurrentSettings.combat.hostile.threatOutputTot.value == 2 then
                        SkuMonitorsAqCombatOutput(tOutput, {unit1 = tAllPartyRaidUnits[x],}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tCurrentSettings.combat.hostile.threatOutputTot)
                     elseif tCurrentSettings.combat.hostile.threatOutputTot.value == 3 then
                        if UnitGUID(tAllPartyRaidUnits[x]) ~= UnitGUID("player") then
                           SkuMonitorsAqCombatOutput(tOutput, {unit1 = tAllPartyRaidUnits[x],}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tCurrentSettings.combat.hostile.threatOutputTot)
                        end
                     end
                     break
                  end
               end
            end
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatUNIT_THREAT_LIST_UPDATE(aEven, aUnitId)
   --print("TankingUNIT_THREAT_LIST_UPDATE", aEven, aUnitId)
   --for i = 1, #tUnitsToTestOnGameRaidTargets do
      --local tguid = UnitGUID(tUnitsToTestOnGameRaidTargets[i])
      --if tguid then
         --local isTanking, status, scaledPercentage, rawPercentage, threatValue = UnitDetailedThreatSituation("player", aUnitId)
         --if status then
            --print(" ", "player", aUnitId, isTanking, status, scaledPercentage, rawPercentage, threatValue)

         --end
      --end
   --end

   --local isTanking, status, scaledPercentage, rawPercentage, threatValue = UnitDetailedThreatSituation("player", aUnitId)
   --if status == nil then
      --print(" unit left combat", aUnitId)
   --end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatUNIT_THREAT_SITUATION_UPDATE(aEven, aUnitId)
   --print("TankingUNIT_THREAT_SITUATION_UPDATE", aEven, aUnitId)
   --for i = 1, #tUnitsToTestOnGameRaidTargets do
      --local tguid = UnitGUID(tUnitsToTestOnGameRaidTargets[i])
      --if tguid then
         --local isTanking, status, scaledPercentage, rawPercentage, threatValue = UnitDetailedThreatSituation("player", aUnitId)
         --if status then
            --print(" ", "player", aUnitId, isTanking, status, scaledPercentage, rawPercentage, threatValue)
         --end
      --end
   --end
end

---------------------------------------------------------------------------------------------------------------------------------------
local function tAddHelper(event, tCreatureGUID, tMobName, tPartyGuid, tPartyname)
   if 
      sfind(event, "_DAMAGE") or 
      sfind(event, "_MISSED") or 
      sfind(event, "_APPLIED") or 
      sfind(event, "_CAST_SUCCESS") or 
      sfind(event, "_CAST_START") or 
      sfind(event, "_CAST_FAILED")
   then      
      C_Timer.After(0.5, function()
         local tMobUnitId = SkuMonitors:aqCombatCreatureGuidToUnitId(tCreatureGUID)
         local tPartyUnitId = SkuMonitors:aqCombatCreatureGuidToUnitId(tPartyGuid)

         --local isTanking, status, scaledPercentage, rawPercentage, threatValue
         
         if tMobUnitId and tPartyUnitId then
            --isTanking, status, scaledPercentage, rawPercentage, threatValue = UnitDetailedThreatSituation(tPartyUnitId, tMobUnitId)
         
            if UnitIsDeadOrGhost(tMobUnitId) ~= true then
               SkuMonitors:aqCombat_CREATURE_ADDED_TO_COMBAT(tCreatureGUID, tMobUnitId, tMobName, tPartyGuid, tPartyUnitId, tPartyname)

               SkuMonitors.threatTable[tCreatureGUID].name = tMobName
               SkuMonitors.threatTable[tCreatureGUID].lastUpdate = GetTimePreciseSec() 

               if SkuMonitors.threatTable[tCreatureGUID][tPartyGuid] == nil then
                  SkuMonitors.threatTable[tCreatureGUID][tPartyGuid] = {
                     isTanking = nil,
                     wasTanking = nil,
                     status = nil,
                     scaledPercentage = nil,
                     rawPercentage = nil,
                     threatValue = nil,
                  }
               end

               SkuMonitors.threatTable[tCreatureGUID][tPartyGuid].lastUpdate = GetTimePreciseSec()
               SkuMonitors.aqCombatCheckThreat = true
            end
         end
      end)
   end
end

local tGUIDCache = {creatures = {}, nonCreatures = {}}
local tNonCreatureGUIDCache = {}
function SkuMonitors:aqCombat_COMBAT_LOG_EVENT_UNFILTERED()
   local arg1, event, arg3, sourceGUID, sourceName, arg6, arg7, targetGUID, targetName = CombatLogGetCurrentEventInfo()

   if sourceGUID and targetGUID then
      if SkuMonitors:aqCombatIsPartyOrRaidMember(nil, sourceGUID) then
         if not tGUIDCache.nonCreatures[targetGUID] then
            if sfind(targetGUID, "Creature-") then
               tGUIDCache.creatures[targetGUID] = true
            else
               tGUIDCache.nonCreatures[targetGUID] = true
            end
         end
         if tGUIDCache.creatures[targetGUID] then
            tAddHelper(event, targetGUID, targetName, sourceGUID, sourceName)
         end
      elseif SkuMonitors:aqCombatIsPartyOrRaidMember(nil, targetGUID) then
         if not tGUIDCache.creatures[sourceGUID] then
            if sfind(sourceGUID, "Creature-") then
               tGUIDCache.creatures[sourceGUID] = true
            else
               tGUIDCache.nonCreatures[sourceGUID] = true
            end
         end

         if tGUIDCache.creatures[sourceGUID] then
            tAddHelper(event, sourceGUID, sourceName, targetGUID, targetName)
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_SKU_SPELL_CAST_START(aEvent, aEventData)
   --[[
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
   ]]

   if not SkuMonitors.db.char[MODULE_NAME].aq then
      return
   end
   local tCurrentSettings = SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet]

   if tCurrentSettings.combat.enabled == true then
      if aqCombatCheckElite(aEventData[4]) == true then
         if tCurrentSettings.combat.hostile.yourTargetCasting.value > 1 then
            local tUnitGUID = aEventData[4]
            if tUnitGUID and tUnitGUID == UnitGUID("target") then
               local tTargetTargetGuid = UnitGUID("targettarget")
               if tTargetTargetGuid then
                  local name, rank, icon, castTime
                  if aEventData[12] then
                     name, rank, icon, castTime = GetSpellInfo(aEventData[12])
                  end
                  if castTime == nil or (castTime > (tCurrentSettings.combat.hostile.minimumCastDuration * 1000)) then
                     if tCurrentSettings.combat.hostile.yourTargetCasting.value == 2 then
                        if tTargetTargetGuid == UnitGUID("player") then
                           local tSetting = tCurrentSettings.combat.hostile.yourTargetCasting
                           SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                        end
                     elseif tCurrentSettings.combat.hostile.yourTargetCasting.value == 3 then
                        if SkuMonitors:aqCombatIsPartyOrRaidMember(nil, tTargetTargetGuid) then
                           local tSetting = tCurrentSettings.combat.hostile.yourTargetCasting
                           SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                        end
                     end
                  end
               end
            end
         end

         if tCurrentSettings.combat.hostile.allEnemiesCasting.value > 1 then
            local tUnitGUID = aEventData[4]
            if tUnitGUID then
               if SkuMonitors:aqCombatGroupGuidToUnitId(tUnitGUID) == nil then
                  local name, rank, icon, castTime
                  if aEventData[12] then
                     name, rank, icon, castTime = GetSpellInfo(aEventData[12])
                  end
                  if castTime == nil or (castTime > (tCurrentSettings.combat.hostile.minimumCastDuration * 1000)) then
                     if tCurrentSettings.combat.hostile.allEnemiesCasting.value == 2 then
                        if SkuMonitors.threatTable[tUnitGUID] then
                           local tSetting = tCurrentSettings.combat.hostile.allEnemiesCasting
                           SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                        end
                     elseif tCurrentSettings.combat.hostile.allEnemiesCasting.value == 3 then
                        local tSetting = tCurrentSettings.combat.hostile.allEnemiesCasting
                        SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                     end
                  end
               end
            end
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_SKU_UNIT_DIED(aEvent, aUnitGUID, aUnitName)
   --print("aqCombat_SKU_UNIT_DIED", aUnitGUID, aUnitName)
   if not SkuMonitors.db.char[MODULE_NAME].aq then
      return
   end   
   local tCurrentSettings = SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet]

   if tCurrentSettings.combat.enabled == true then
      if aqCombatCheckElite(aUnitGUID) == true then
         if tCurrentSettings.combat.hostile.outputDeadUnits.value > 1 then
            if (tCurrentSettings.combat.hostile.deathsIgnoreUnitsNotInCombat == true and SkuMonitors.threatTable[aUnitGUID] ~= nil) or tCurrentSettings.combat.hostile.deathsIgnoreUnitsNotInCombat == false then
               local tCreateUnitId = SkuMonitors:aqCombatCreatureGuidToUnitId(aUnitGUID)
               if tCreateUnitId == nil then
                  tCreateUnitId = "creature"
               end

               if tCurrentSettings.combat.hostile.outputDeadUnits.value == 2 then
                  local tSetting = tCurrentSettings.combat.hostile.outputDeadUnits
                  SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tCreateUnitId,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
               elseif tCurrentSettings.combat.hostile.outputDeadUnits.value == 3 then
                  if SkuMonitors.threatTable[aUnitGUID] and SkuMonitors.threatTable[aUnitGUID][UnitGUID("player")] then
                     if SkuMonitors.threatTable[aUnitGUID][UnitGUID("player")].scaledPercentage >= 100 then
                        local tSetting = tCurrentSettings.combat.hostile.outputDeadUnits
                        SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tCreateUnitId,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                     end
                  end
               elseif tCurrentSettings.combat.hostile.outputDeadUnits.value == 4 then
                  if SkuMonitors.threatTable[aUnitGUID] then
                     local tSetting = tCurrentSettings.combat.hostile.outputDeadUnits
                     SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tCreateUnitId,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
                  end
               end
            end
         end
      end
   end

   if SkuMonitors.SkuRaidTargetRepo[aUnitGUID] then
      local tIndex = SkuMonitors.SkuRaidTargetRepo[aUnitGUID]
      SkuMonitors.SkuRaidTargetRepoDead[aUnitGUID] = tIndex
      SkuMonitors.SkuRaidTargetRepo[aUnitGUID] = nil
   end

   if tCurrentSettings.combat.enabled == true then
      if SkuMonitors:aqCombatIsPartyOrRaidMember(nil, aUnitGUID) == nil then
         if sfind(aUnitGUID, "Creature-") then
            SkuMonitors:aqCombat_CREATURE_REMOVED_FROM_COMBAT(aUnitGUID, nil, aUnitName)
         end
      else
         local tPartyUnitId = SkuMonitors:aqCombatGroupGuidToUnitId(aUnitGUID)
         if tPartyUnitId == nil then
            tPartyUnitId = ""
         end
         
         if 
            tCurrentSettings.combat.friendly.ignoreDeadPartyPets == false or
            tPartyUnitId == "" or
            (
               tCurrentSettings.combat.friendly.ignoreDeadPartyPets == true and
               sfind(tPartyUnitId, "pet") == nil and
               UnitIsOtherPlayersPet(tPartyUnitId) == false and
               aUnitGUID ~= UnitGUID("pet")
            )
         then
            if tPartyUnitId == "" or UnitIsDeadOrGhost(tPartyUnitId) == true then
               SkuMonitors.partyDeadCountCounter = SkuMonitors.partyDeadCountCounter + 1
               if tCurrentSettings.combat.friendly.partyDeadCount.value == true then
                  local tSetting = tCurrentSettings.combat.friendly.partyDeadCount
                  SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {number1 = SkuMonitors.partyDeadCountCounter,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
               end

               if tCurrentSettings.combat.friendly.partyDead.value == true then
                  local tSetting = tCurrentSettings.combat.friendly.partyDead
                  SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = tPartyUnitId,}, {wait = true, overwrite = false, instant = true, doNotOverwrite = true}, tSetting)
               end
            end
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_PLAYER_REGEN_DISABLED()
   SkuMonitors.aqCombatCheckThreat = true
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_PLAYER_REGEN_ENABLED()
   SkuMonitors.partyDeadCountCounter = 0
   SkuMonitors.aqCombatCheckThreat = nil
   SkuMonitors:aqCombatClearSkuRaidTargets()

   SkuMonitors.threatTable = {}
   SkuMonitors.inOutCombatQueue = {
      current = 0,
      combatIn = {},
		combatOut = {},
   }
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombat_PLAYER_ENTERING_WORLD()
	SkuMonitors:UpdateCurrentTalentSet()

end

---------------------------------------------------------------------------------------------------------------------------------------
-- Sku raid target
---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatGetSkuRaidTarget(aUnitGUID)
   for i, v in pairs(SkuMonitors.SkuRaidTargetRepo) do
      if i == aUnitGUID then
         return v
      end
   end
   for i, v in pairs(SkuMonitors.SkuRaidTargetRepoDead) do
      if i == aUnitGUID then
         return v, true
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatSetSkuRaidTarget(aUnitGUID, aRaidTargetId)
   if not aUnitGUID then
      return
   end

   if aRaidTargetId == nil then
      --clear
      if SkuMonitors.SkuRaidTargetRepo[aUnitGUID] then
         SkuMonitors.SkuRaidTargetRepo[aUnitGUID] = nil
         return true
      end
      if SkuMonitors.SkuRaidTargetRepoDead[aUnitGUID] then
         SkuMonitors.SkuRaidTargetRepoDead[aUnitGUID] = nil
         return true
      end
   elseif aRaidTargetId == 0 then
      for x = 1, #SkuMonitors.SkuRaidTargetIndex do
         local tAvailable = true
         for i, v in pairs(SkuMonitors.SkuRaidTargetRepo) do
            if v == SkuMonitors.SkuRaidTargetIndex[x] then
               tAvailable = false
            end
         end
         for i, v in pairs(SkuMonitors.SkuRaidTargetRepoDead) do
            if v == SkuMonitors.SkuRaidTargetIndex[x] then
               tAvailable = false
            end
         end
         if tAvailable == true then
            SkuMonitors.SkuRaidTargetRepo[aUnitGUID] = SkuMonitors.SkuRaidTargetIndex[x]
            return SkuMonitors.SkuRaidTargetIndex[x]
         end
      end
   elseif aRaidTargetId > 0 then
      --raid target index
      SkuMonitors.SkuRaidTargetRepo[aUnitGUID] = nil
      SkuMonitors.SkuRaidTargetRepoDead[aUnitGUID] = nil
      SkuMonitors.SkuRaidTargetRepo[aUnitGUID] = aRaidTargetId
      return aRaidTargetId
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatClearSkuRaidTargets()
   SkuMonitors.SkuRaidTargetRepo = {}
   SkuMonitors.SkuRaidTargetRepoDead = {}
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatCheckGameRaidTargets()
   for i = 1, #tUnitsToTestOnGameRaidTargets do
      local tguid = UnitGUID(tUnitsToTestOnGameRaidTargets[i])
      if tguid then
         local tRti = GetRaidTargetIndex(tUnitsToTestOnGameRaidTargets[i])
         if tRti then
            SkuMonitors.SkuRaidTargetRepo[tguid] = nil
            SkuMonitors.SkuRaidTargetRepoDead[tguid] = nil
            return
         end
      end
   end
end

---------------------------------------------------------------------------------------------------------------------------------------
-- combat monitor Menu
local function tSoundMenuBuilder(self, aSetting)
   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Audio"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.filterable = true   
   tNewMenuEntry.isSelect = true
   tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
      for i, v in pairs(aqCombatAudioOutputs) do
         if aSetting.sound == i then
            return v
         end
      end
   end

   tNewMenuEntry.OnAction = function(self, aValue, aName)
      for i, v in pairs(aqCombatAudioOutputs) do
         if aName == v then
            aSetting.sound = i
         end
      end
   end
   tNewMenuEntry.BuildChildren = function(self)
      local tSortedList = {}
      for k, v in SkuSpairs(aqCombatAudioOutputs, function(t,a,b) 
         return a > b
      end) do 
         tSortedList[#tSortedList+1] = v
      end      

      for i = 1, #tSortedList do
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {tSortedList[i]}, SkuGenericMenuItem)
         tNewMenuEntry.OnEnter = function(self, aValue, aName)
            aName = SkuMenu.currentMenuPosition.name
            local tSetting = aSetting
            for i, v in pairs(aqCombatAudioOutputs) do
               if aName == v then
                  C_Timer.After(0.2, function()
                     SkuMenu.Voice:StopOutputEmptyQueue(true, true)
                     C_Timer.After(0.01, function()
                        SkuMonitorsAqCombatOutput(tSetting.voiceOutput, {unit1 = "party1", unit2 = "party2", action1 = "out", number1 = "1"}, {wait = false, overwrite = true}, tSetting, i)
                        C_Timer.After(1.0, function()
                           SkuMenu.Voice:OutputStringBTtts(SkuMenu.currentMenuPosition.name, false, true, 0.2, true, nil, nil, 2)
                        end)
                     end)
                  end)
               end
            end
         end            
      end
   end  
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuMonitors:aqCombatMenuBuilder()
	if not SkuMenu then
		return
	end

   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Enabled"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.filterable = true
   tNewMenuEntry.isSelect = true
   tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
      if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.enabled == true then
         return L["Yes"]
      else
         return L["No"]
      end
   end
   tNewMenuEntry.OnAction = function(self, aValue, aName)
      if aName == L["No"] then
         SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.enabled = false
      elseif aName == L["Yes"] then
         SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.enabled = true
      end
   end
   tNewMenuEntry.BuildChildren = function(self)
      SkuMenu:InjectMenuItems(self, {L["No"]}, SkuGenericMenuItem)
      SkuMenu:InjectMenuItems(self, {L["Yes"]}, SkuGenericMenuItem)
   end

   ---
   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Update rate (performance)"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.filterable = true
   tNewMenuEntry.isSelect = true
   tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
      return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.updateRate
   end
   tNewMenuEntry.OnAction = function(self, aValue, aName)
      SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.updateRate = tonumber(aName)
      tCurrentUpdateRate = (21 - SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.updateRate)
   end
   tNewMenuEntry.BuildChildren = function(self)
      for x = 1, 20 do
         SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
      end
   end   

   ----
   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Voice"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.filterable = true
   tNewMenuEntry.isSelect = true
   tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
      return aqCombatVoices[SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voice]
   end
   tNewMenuEntry.OnAction = function(self, aValue, aName)
      for x = 1, #aqCombatVoices do
         if aqCombatVoices[x] == aName then
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voice = x
         end
      end
   end
   tNewMenuEntry.BuildChildren = function(self)
      for x = 1, #aqCombatVoices do
         SkuMenu:InjectMenuItems(self, {aqCombatVoices[x]}, SkuGenericMenuItem)
      end
   end

   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Notification volume"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.filterable = true
   tNewMenuEntry.isSelect = true
   tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
      if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.notificationVolume == 1 then
         return L["Low"]
      else
         return L["High"]
      end
   end
   tNewMenuEntry.OnAction = function(self, aValue, aName)
      if aName == L["Low"] then
         SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.notificationVolume = 1
      elseif aName == L["High"] then
         SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.notificationVolume = 2
      end
   end
   tNewMenuEntry.BuildChildren = function(self)
      SkuMenu:InjectMenuItems(self, {L["Low"]}, SkuGenericMenuItem)
      SkuMenu:InjectMenuItems(self, {L["High"]}, SkuGenericMenuItem)
   end

   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Voice volume"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.filterable = true
   tNewMenuEntry.isSelect = true
   tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
      if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voiceVolume == 1 then
         return L["Low"]
      else
         return L["High"]
      end
   end
   tNewMenuEntry.OnAction = function(self, aValue, aName)
      if aName == L["Low"] then
         SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voiceVolume = 1
      elseif aName == L["High"] then
         SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.voiceVolume = 2
      end
   end
   tNewMenuEntry.BuildChildren = function(self)
      SkuMenu:InjectMenuItems(self, {L["Low"]}, SkuGenericMenuItem)
      SkuMenu:InjectMenuItems(self, {L["High"]}, SkuGenericMenuItem)
   end



   ----
   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Hostile"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.BuildChildren = function(self)
      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["ignore non-elite"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.filterable = true
      tNewMenuEntry.isSelect = true
      tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
         if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.ignoreNonElite == true then
            return L["Yes"]
         else
            return L["No"]
         end
      end
      tNewMenuEntry.OnAction = function(self, aValue, aName)
         if aName == L["No"] then
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.ignoreNonElite = false
         elseif aName == L["Yes"] then
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.ignoreNonElite = true
         end
      end
      tNewMenuEntry.BuildChildren = function(self)
         SkuMenu:InjectMenuItems(self, {L["No"]}, SkuGenericMenuItem)
         SkuMenu:InjectMenuItems(self, {L["Yes"]}, SkuGenericMenuItem)
      end      

      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Threat"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.BuildChildren = function(self)
         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Output target of target on target change"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot.value == 1 then
                  return L["Never"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot.value == 2 then
                  return L["Always"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot.value == 3 then
                  return L["If target of target isn't you"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Never"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot.value = 1
               elseif aName == L["Always"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot.value = 2
               elseif aName == L["If target of target isn't you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot.value = 3
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Never"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Always"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["If target of target isn't you"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatOutputTot)
         end

         ---
			local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Threat warning if you are not first place (not tanking) and your threat percentage is higher than"]}, SkuGenericMenuItem)
			tNewMenuEntry.dynamic = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.filterable = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningNotFirstHigherThan.value == 0 then
                  return L["Off"]
               else
                  return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningNotFirstHigherThan.value
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if tonumber(aName) then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningNotFirstHigherThan.value = tonumber(aName)
               else
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningNotFirstHigherThan.value = 0
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               for x = 1, 150 do
                  SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
               end
            end
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningNotFirstHigherThan)
         end

         ---
			local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Threat warning if you are first place (tanking) and second place threat percentage is higher than"]}, SkuGenericMenuItem)
			tNewMenuEntry.dynamic = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.filterable = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningIsFirstSecondHigherThan.value == 0 then
                  return L["Off"]
               else
                  return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningIsFirstSecondHigherThan.value
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if tonumber(aName) then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningIsFirstSecondHigherThan.value = tonumber(aName)
               else
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningIsFirstSecondHigherThan.value = 0
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               for x = 1, 150 do
                  SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
               end
            end   
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningIsFirstSecondHigherThan)
         end

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Theat warning repeating interval (0 is once)"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningInterval
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.threatWarningInterval = tonumber(aName)
         end
         tNewMenuEntry.BuildChildren = function(self)
            for x = 0, 30 do
               SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
            end
         end         

         ----
			local tNewSubMenuEntry = SkuMenu:InjectMenuItems(self, {L["Warning if your target is switching from you"]}, SkuGenericMenuItem)
			tNewSubMenuEntry.dynamic = true
         tNewSubMenuEntry.filterable = true
         tNewSubMenuEntry.BuildChildren = function(self)
            local tNewSubMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewSubMenuEntry.dynamic = true
            tNewSubMenuEntry.isSelect = true
            tNewSubMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToParty.value == true then
                  return L["On"]
               else
                  return L["Off"]
               end
            end
            tNewSubMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToParty.value = false
               elseif aName == L["On"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToParty.value = true
               end
            end
            tNewSubMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["On"]}, SkuGenericMenuItem)
            end

			   tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToParty)
         end

         ----
			local tNewSubMenuEntry = SkuMenu:InjectMenuItems(self, {L["Warning if your target is switching to you"]}, SkuGenericMenuItem)
			tNewSubMenuEntry.dynamic = true
         tNewSubMenuEntry.filterable = true
         tNewSubMenuEntry.BuildChildren = function(self)
            local tNewSubMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewSubMenuEntry.dynamic = true
            tNewSubMenuEntry.isSelect = true
            tNewSubMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToYou.value == true then
                  return L["On"]
               else
                  return L["Off"]
               end
            end
            tNewSubMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToYou.value = false
               elseif aName == L["On"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToYou.value = true
               end
            end
            tNewSubMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["On"]}, SkuGenericMenuItem)
            end

			   tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.warnIfTargetSwitchingToYou)
         end         
      end

      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Casting"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.BuildChildren = function(self)
         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Output your target casting"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting.value == 1 then
                  return L["Off"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting.value == 2 then
                  return L["If cast target is you"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting.value == 3 then
                  return L["If cast target is any party member"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting.value = 1
               elseif aName == L["If cast target is you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting.value = 2
               elseif aName == L["If cast target is any party member"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting.value = 3
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["If cast target is you"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["If cast target is any party member"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.yourTargetCasting)
         end
         
         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Output all enemies casting"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting.value == 1 then
                  return L["Off"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting.value == 2 then
                  return L["Only in combat"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting.value == 3 then
                  return L["All"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting.value = 1
               elseif aName == L["Only in combat"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting.value = 2
               elseif aName == L["All"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting.value = 3
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Only in combat"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["All"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.allEnemiesCasting)
         end

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Minimum cast time"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.minimumCastDuration
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.minimumCastDuration = tonumber(aName)
         end
         tNewMenuEntry.BuildChildren = function(self)
            for x = 0, 30 do
               SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
            end
         end
      end         

      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Deaths"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.BuildChildren = function(self)
         ----
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["ignore dead units not in combat"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.deathsIgnoreUnitsNotInCombat == true then
               return L["Yes"]
            else
               return L["No"]
            end
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            if aName == L["No"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.deathsIgnoreUnitsNotInCombat = false
            elseif aName == L["Yes"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.deathsIgnoreUnitsNotInCombat = true
            end
         end
         tNewMenuEntry.BuildChildren = function(self)
            SkuMenu:InjectMenuItems(self, {L["No"]}, SkuGenericMenuItem)
            SkuMenu:InjectMenuItems(self, {L["Yes"]}, SkuGenericMenuItem)
         end  

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Output dead units"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value == 1 then
                  return L["Never"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value == 2 then
                  return L["Always"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value == 3 then
                  return L["If unit was attacking you"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value == 4 then
                  return L["If unit was attacking any party member"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Never"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value = 1
               elseif aName == L["Always"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value = 2
               elseif aName == L["If unit was attacking you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value = 3
               elseif aName == L["If unit was attacking any party member"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits.value = 4
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Never"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Always"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["If unit was attacking you"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["If unit was attacking any party member"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.outputDeadUnits)
         end         
      end         

      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Units in combat"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.BuildChildren = function(self)
         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Announce enemies entering combat"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value == 1 then
                  return L["Off"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value == 2 then
                  return L["All enemies"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value == 3 then
                  return L["Enemies attacking party or you"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value == 4 then
                  return L["Enemies attacking you"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value = 1
               elseif aName == L["All enemies"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value = 2
               elseif aName == L["Enemies attacking party or you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value = 3
               elseif aName == L["Enemies attacking you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat.value = 4
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               --SkuMenu:InjectMenuItems(self, {L["All enemies"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Enemies attacking party or you"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Enemies attacking you"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsAddedToCombat)
         end   

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Announce enemies leaving combat"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value == 1 then
                  return L["Off"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value == 2 then
                  return L["All enemies"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value == 3 then
                  return L["Enemies attacking party or you"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value == 4 then
                  return L["Enemies attacking you"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value = 1
               elseif aName == L["All enemies"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value = 2
               elseif aName == L["Enemies attacking party or you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value = 3
               elseif aName == L["Enemies attacking you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat.value = 4
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               --SkuMenu:InjectMenuItems(self, {L["All enemies"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Enemies attacking party or you"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Enemies attacking you"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.unitsLeavingCombat)
         end            

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Announce relative number of enemies in combat"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value == 1 then
                  return L["Off"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value == 2 then
                  return L["All enemies"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value == 3 then
                  return L["Enemies attacking party or you"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value == 4 then
                  return L["Enemies attacking you"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value = 1
               elseif aName == L["All enemies"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value = 2
               elseif aName == L["Enemies attacking party or you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value = 3
               elseif aName == L["Enemies attacking you"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat.value = 4
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               --SkuMenu:InjectMenuItems(self, {L["All enemies"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Enemies attacking party or you"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["Enemies attacking you"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.relativeNumberUnitsInCombat)
         end          
         
         --[[
         ----
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Announce only numbers for entering or leaving combat notifications"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.shortUnitsAddedOrLeavingToCombatMessages == true then
               return L["Yes"]
            else
               return L["No"]
            end
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            if aName == L["No"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.shortUnitsAddedOrLeavingToCombatMessages = false
            elseif aName == L["Yes"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.hostile.shortUnitsAddedOrLeavingToCombatMessages = true
            end
         end
         tNewMenuEntry.BuildChildren = function(self)
            SkuMenu:InjectMenuItems(self, {L["No"]}, SkuGenericMenuItem)
            SkuMenu:InjectMenuItems(self, {L["Yes"]}, SkuGenericMenuItem)
         end               
         ]]

      end      
   end
   
   ----
   local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Friendly"]}, SkuGenericMenuItem)
   tNewMenuEntry.dynamic = true
   tNewMenuEntry.BuildChildren = function(self)
      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Announce deaths"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.filterable = true
      tNewMenuEntry.BuildChildren = function(self)
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDead.value == false then
               return L["Off"]
            elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDead.value == true then
               return L["On"]
            end
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            if aName == L["Off"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDead.value = false
            elseif aName == L["On"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDead.value = true
            end
         end
         tNewMenuEntry.BuildChildren = function(self)
            SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
            SkuMenu:InjectMenuItems(self, {L["On"]}, SkuGenericMenuItem)
         end     
         tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDead)
      end

      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Count deaths up"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.filterable = true
      tNewMenuEntry.BuildChildren = function(self)
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDeadCount.value == false then
               return L["Off"]
            elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDeadCount.value == true then
               return L["On"]
            end
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            if aName == L["Off"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDeadCount.value = false
            elseif aName == L["On"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDeadCount.value = true
            end
         end
         tNewMenuEntry.BuildChildren = function(self)
            SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
            SkuMenu:InjectMenuItems(self, {L["On"]}, SkuGenericMenuItem)
         end     
         tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.partyDeadCount)
      end

      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Ignore dead party pets"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.filterable = true
      tNewMenuEntry.isSelect = true
      tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
         if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.ignoreDeadPartyPets == true then
            return L["Yes"]
         else
            return L["No"]
         end
      end
      tNewMenuEntry.OnAction = function(self, aValue, aName)
         if aName == L["No"] then
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.ignoreDeadPartyPets = false
         elseif aName == L["Yes"] then
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.ignoreDeadPartyPets = true
         end
      end
      tNewMenuEntry.BuildChildren = function(self)
         SkuMenu:InjectMenuItems(self, {L["No"]}, SkuGenericMenuItem)
         SkuMenu:InjectMenuItems(self, {L["Yes"]}, SkuGenericMenuItem)
      end

      ----
      local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Distance to party member"]}, SkuGenericMenuItem)
      tNewMenuEntry.dynamic = true
      tNewMenuEntry.BuildChildren = function(self)
         ----
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Announce out of range"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.BuildChildren = function(self)
            local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Setting"]}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.isSelect = true
            tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
               if SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.outOfRangeEnabled.value == false then
                  return L["Off"]
               elseif SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.outOfRangeEnabled.value == true then
                  return L["On"]
               end
            end
            tNewMenuEntry.OnAction = function(self, aValue, aName)
               if aName == L["Off"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.outOfRangeEnabled.value = false
               elseif aName == L["On"] then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.outOfRangeEnabled.value = true
               end
            end
            tNewMenuEntry.BuildChildren = function(self)
               SkuMenu:InjectMenuItems(self, {L["Off"]}, SkuGenericMenuItem)
               SkuMenu:InjectMenuItems(self, {L["On"]}, SkuGenericMenuItem)
            end     
            tSoundMenuBuilder(self, SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.outOfRangeEnabled)
         end

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Out of range at"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorAt
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorAt = tonumber(aName)
         end
         tNewMenuEntry.BuildChildren = function(self)
            for x = 1, 100 do
               SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
            end
         end

         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Set unit for out of range"].." ("..L["current"]..": "..(SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorUnitName or L["Nothing selected"])..")"}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            if aName == L["Current target"] then
               if UnitName("target") and UnitIsPlayer("target") then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorUnitName = UnitName("target")
               end
            elseif aName == L["Clear"] then
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorUnitName = L["Nothing selected"]
            elseif aName == L["Current focus target"] then
               if UnitName("focus") and UnitIsPlayer("focus") then
                  SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorUnitName = UnitName("focus")
               end
            elseif sfind(aName, L["Party"]) then
               local tName = strsplit(";", aName)
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorUnitName = tName
            elseif sfind(aName, L["Raid"]) then
               local tName = strsplit(";", aName)
               SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorUnitName = tName
            end
				C_Timer.After(0.001, function()
					SkuMenu.currentMenuPosition:OnUpdate(SkuMenu.currentMenuPosition)
				end)				

         end
         tNewMenuEntry.BuildChildren = function(self)
            SkuMenu:InjectMenuItems(self, {L["Clear"]}, SkuGenericMenuItem)
            SkuMenu:InjectMenuItems(self, {L["Current target"]}, SkuGenericMenuItem)
            SkuMenu:InjectMenuItems(self, {L["Current focus target"]}, SkuGenericMenuItem)
            for x = 1, 4 do
               if UnitName("party"..x) then
                  SkuMenu:InjectMenuItems(self, {UnitName("party"..x)..";"..L["Party"].." "..x}, SkuGenericMenuItem)
               end
            end
            for x = 1, 40 do
               if UnitName("raid"..x) then
                  SkuMenu:InjectMenuItems(self, {UnitName("raid"..x)..";"..L["Raid"].." "..x}, SkuGenericMenuItem)
               end
            end
         end     
         
         ---
         local tNewMenuEntry = SkuMenu:InjectMenuItems(self, {L["Repeating interval (0 is once)"]}, SkuGenericMenuItem)
         tNewMenuEntry.dynamic = true
         tNewMenuEntry.filterable = true
         tNewMenuEntry.isSelect = true
         tNewMenuEntry.GetCurrentValue = function(self, aValue, aName)
            return SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorInterval
         end
         tNewMenuEntry.OnAction = function(self, aValue, aName)
            SkuMonitors.db.char[MODULE_NAME].aq[SkuMonitors.talentSet].combat.friendly.oorInterval = tonumber(aName)
         end
         tNewMenuEntry.BuildChildren = function(self)
            for x = 0, 30 do
               SkuMenu:InjectMenuItems(self, {x}, SkuGenericMenuItem)
            end
         end         
      end
   end
end