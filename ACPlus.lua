
 --NAMESPACE
local addon_name, addon = ... 


local playerDamage,playerHealing,playerDamageTaken,playerInterupts,playerDeaths = 0,0,0,0,0

dungeon_tables = {
}

current_table = {
}

local temp = {}

function on_combat_start()
   print("Combat start!")
   combat()
end

print("step two")

function on_combat_end()
   save_current_table(temp_table)
end

function save_current_table(temp_table)
   print("Saving")
   combat_score = {
      ["Healing"] = playerHealing,
      ["Damage"] = playerDamage,
      ["Damage Taken"] = playerDamageTaken,
      ["Interupts"] = playerInterupts,
      ["Player Deaths"] = playerDeaths
   }
   table.insert(temp_table, combat_score)
   table.insert(current_table, temp_table)
   for i,v in ipairs(current_table) do
      print(i,v["Damage"] .. " total damage, " .. v["Healing"] .. " total healing, " .. v["Damage Taken"] .. " total damage taken")
   end
   print("Table Saved!")
end

function set_player_names_and_guid(temp_table)
   local playerGUID,party1,party2,party3,party4 = UnitGUID("player"),UnitGUID("party1"),UnitGUID("party2"),UnitGUID("party3"),UnitGUID("party4")
   local playerName,partyName1,partyName2,partyName3,partyName4 = UnitName("player"),UnitName("party1"),UnitName("party2"),UnitName("party3"),UnitName("party4")
  local temp_table = {
      ["Player GUID"] = playerGUID,
      ["Player Name"] = playerName,
      ["Party1 GUID"] = party1,
      ["Party1 Name"] = partyName1,
      ["Party2 GUID"] = party2,
      ["Party2 Name"] = partyName2,
      ["Party3 GUID"] = party3,
      ["Party3 Name"] = partyName3,
      ["Party4 Name"] = partyName4,
      ["Party4 GUID"] = party4,
   }
   return temp_table
end

function save_table()
   print("Saving Dungeon Table")
   local temp = {
      ["Healing"] = 0,
      ["Damage"] = 0,
      ["Damage Taken"] = 0,
      ["Interupts"] = 0
   }
   for i,v in ipairs(current_table) do
      temp[1] = temp[1] + v["Damage"]
      temp[2] = temp[2] + v["Healing"]
      temp[3] = temp[3] + v["Damage Taken"]
      temp[4] = temp[4] + v["Interupts"] 
   end
   table.insert(dungeon_tables, temp)
   print("Table Saved!")
end

function on_challengemode_start()
   set_player_names_and_guid(temp)
   addon.register_event("PLAYER_REGEN_DISABLED", on_combat_start)
   addon.register_event("PLAYER_REGEN_ENABLED", on_combat_end)
   addon.register_event("PLAYER_DEATH",on_player_death)
end

function on_challengemode_end()
   addon.unregister_event("PLAYER_REGEN_DISABLED", on_combat_start)
   addon.unregister_event("PLAYER_REGEN_ENABLED", on_combat_end)
   addon.unregister_event("PLAYER_DEATH", on_player_death)
   save_table()
   wipe_table(current_table)
   reset_scores()
end

function on_challenge_mode_reset()
   wipe_table(current_table)
   reset_scores()
end


function wipe_table(table_to_wipe)
   for i,v in ipairs(table_to_wipe) do
      table.remove( current_table, table_to_wipe)
   end
end


function reset_scores()
   playerDamage,playerHealing,playerDamageTaken,playerInterupts,playerDeaths = 0,0,0,0,0
end


function on_player_death()
   playerDeaths = playerDeaths + 1
end


local event_listeners = {}

local function on_event(_, event, ...)
   if not event_listeners[event] then
     return
   end
 
   for callback, _ in pairs(event_listeners[event]) do
     callback(...)
   end
end

local listener_frame = CreateFrame("Frame", addon_name .. "Listener")


listener_frame:SetScript("OnEvent", on_event)


function addon.register_event(event, callback)
   if not event_listeners[event] then
     listener_frame:RegisterEvent(event)
     event_listeners[event] = {[callback] = true}
   else
     event_listeners[event][callback] = true
   end
end

 -- ---------------------------------------------------------------------------------------------------------------------
function addon.unregister_event(event, callback)
   if not event_listeners[event] then
     return
   end
 
   event_listeners[event][callback] = nil
 
   local count = 0
   for _ in pairs(event_listeners[event]) do
     count = count + 1
   end
 
   if count == 0 then
     event_listeners[event] = nil
     listener_frame:UnregisterEvent(event)
   end
end

addon.register_event("CHALLENGE_MODE_START", on_challengemode_start)
addon.register_event("CHALLENGE_MODE_COMPLETED", on_challengemode_end)

local tableFrame = CreateFrame("FRAME","TableFrame")
tableFrame:RegisterEvent("ADDON_LOADED")
tableFrame:RegisterEvent("PLAYER_LOGOUT")

function tableFrame:OnEvent(event, args1)
   if event == "ADDON_LOADED" then
      print(args1)
   end
end

tableFrame:SetScript("OnEvent",tableFrame.OnEvent);

local damageEvents = {
    SWING_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    RANGE_DAMAGE = true,
    SPELL_BUILDING_DAMAGE = true,
}

local healingEvents = {
   SWING_HEAL = true,
   SPELL_HEAL = true,
   SPELL_PERIODIC_HEAL = true,
   RANGE_HEAL = true,
   SPELL_BUILDING_HEAL = true,
   SWING_HEAL_ABSORBED = true,
   SPELL_HEAL_ABSORBED = true,
   SPELL_PERIODIC_HEAL_ABSORBED = true,
   RANGE_HEAL_ABSORBED = true,
   SPELL_BUILDING_HEAL_ABSORBED = true,
   SWING_LEECH = true,
   SPELL_LEECH = true,
   SPELL_PERIODIC_LEECH = true,
   RANGE_LEECH = true,
   SPELL_BUILDING_LEECH = true,
   SWING_DRAIN = true,
   SPELL_DRAIN = true,
   SPELL_PERIODIC_DRAIN = true,
   RANGE_DRAIN = true,
   SPELL_BUILDING_DRAIN = true,
}

local interuptEvents = {
   SWING_INTERRUPT = true,
   SPELL_INTERRUPT = true,
   SPELL_PERIODIC_INTERRUPT = true,
   RANGE_INTERRUPT = true,
   SPELL_BUILDING_INTERRUPT = true,
}

function combat()
   local f = CreateFrame("Frame")
   f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   f:SetScript("OnEvent", function(self, event)
      self:OnEvent(event, CombatLogGetCurrentEventInfo())
   end)

   print("step twentione")

   function f:OnEvent(event, ...)
      local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
      local spellId, spellName, spellSchool
      local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand

      if subevent == "SWING_DAMAGE" then
         amount, overkill = select(12, ...)
      elseif subevent == "SPELL_DAMAGE" then
         spellId, spellName, spellSchool, amount, overkill = select(12, ...)
      elseif subevent == "SPELL_PERIODIC_DAMAGE" then
         spellId, spellName, spellSchool, amount,overkill = select(12, ...)
      elseif subevent == "RANGE_DAMAGE" then
         spellId, spellName, spellSchool, amount,overkill = select(12, ...)
      elseif subevent == "SPELL_BUILDING_DAMAGE" then
         spellId, spellName, spellSchool, amount, overkill = select(12, ...)
      elseif subevent == "SPELL_HEAL" then
         spellId, spellName, spellSchool, amount, overhealing = select(12, ...)
      elseif subevent == "SPELL_PERIODIC_HEAL" then
         spellId, spellName, spellSchool, amount,overhealing = select(12, ...)
      elseif subevent == "RANGE_HEAL" then
         spellId, spellName, spellSchool, amount,overhealing = select(12, ...)
      elseif subevent == "SPELL_BUILDING_HEAL" then
         spellId, spellName, spellSchool, amount, overhealing = select(12, ...)
      elseif subevent == "SWING_HEAL" then
          amount, overhealing = select(12, ...)
      elseif subevent == "SPELL_HEAL_ABSORBED" then
         spellId, spellName, spellSchool, extraGUID, extraName = select(12, ...)
      elseif subevent == "SPELL_PERIODIC_HEAL_ABSORBED" then
         spellId, spellName, spellSchool, extraGUID, extraName = select(12, ...)
      elseif subevent == "RANGE_HEAL_ABSORBED" then
         spellId, spellName, spellSchool, extraGUID, extraName = select(12, ...)
      elseif subevent == "SPELL_BUILDING_HEAL_ABSORBED" then
         spellId, spellName, spellSchool, extraGUID, extraName = select(12, ...)
      elseif subevent == "SWING_HEAL_ABSORBED" then
         spellId, spellName, spellSchool, extraGUID, extraName = select(12, ...)
      end
      if damageEvents[subevent] and sourceGUID == playerGUID then
         if not overkill == -1 then
            playerDamage = playerDamage + (amount - overkill)
         else
            playerDamage = playerDamage + amount
         end
      end
      if healingEvents[subevent] and sourceGUID == playerGUID then
         playerHealing = playerHealing + (amount - overhealing)
      end
      if damageEvents[subevent] and destGUID == playerGUID then
         if not overkill == -1 then
            playerDamageTaken = playerDamageTaken + (amount - overkill)
         else
            playerDamageTaken = playerDamageTaken + amount
         end
      end
      if interuptEvents[subevent] and sourceGUID == playerGUID then
         playerInterupts = playerInterupts + 1
      end
   end
end
 