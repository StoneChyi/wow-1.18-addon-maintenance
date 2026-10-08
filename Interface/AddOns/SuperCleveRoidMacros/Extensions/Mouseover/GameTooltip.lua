--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}
local Extension = CleveRoids.RegisterExtension("GameTooltipMouseover")

-- Tooltip-based mouseover (lowest priority fallback)
function Extension.SetUnit(_, unit)
  if unit and unit ~= "" then
    CleveRoids.SetMouseoverFrom("tooltip", unit)
    CleveRoids.mouseoverUnit = unit -- 修复部分团队框架BUG by 武藤纯子酱 2026.7.17
  end
end

function Extension.OnClose()
  CleveRoids.ClearMouseoverFrom("tooltip")
  -- Also clear native source when tooltip closes to prevent sticky highlights
  -- The native source may have been set from hovering units in the 3D world
  --CleveRoids.ClearMouseoverFrom("native") -- 注释掉，避免鼠标提示里2个装等显示的BUG by 武藤纯子酱 2026.2.11
  CleveRoids.mouseoverUnit = nil -- 当关闭框架的时候清空mouseoverUnit by 武藤纯子酱 2026.7.24
end

-- Native UPDATE_MOUSEOVER_UNIT handler (priority 2)
-- This works even when tooltips are hidden by other addons
-- NOTE: We skip when selfTriggered is set to prevent TRP tooltip conflicts.
-- When we call SetMouseoverUnit ourselves, it triggers UPDATE_MOUSEOVER_UNIT,
-- which would add a redundant "native" source that persists after the real
-- source (pfUI, etc.) clears - causing TRP to show stale profile info.
function Extension.UPDATE_MOUSEOVER_UNIT()
  -- Skip if we ourselves triggered this event by calling SetMouseoverUnit
  if CleveRoids.__mo and CleveRoids.__mo.selfTriggered then
    CleveRoids.__mo.selfTriggered = false
    return
  end

  if UnitExists("mouseover") then
    CleveRoids.SetMouseoverFrom("native", "mouseover")
  else
    --CleveRoids.ClearMouseoverFrom("native") -- 注释掉，避免鼠标提示里2个装等显示的BUG by 武藤纯子酱 2026.2.11
  end
end

-- Clear mouseover when tooltip is set to a non-unit (spell, item, action, etc.)
-- This prevents TurtleRP from showing stale RP profile info for spells/items.
-- TurtleRP hooks GameTooltip:OnShow and checks UnitIsPlayer("mouseover") -
-- if that returns true (from a stale unit frame hover), it overwrites the tooltip.
-- By clearing mouseover when non-unit tooltips are shown, we prevent this.
function Extension.OnNonUnitTooltip()
  -- When a non-unit tooltip is shown (spell, item, action), clear the tooltip source
  -- BUT check if GameTooltip's internally stored unit (from a prior SetUnit call)
  -- is still valid. If so, the tooltip IS showing a unit (with additional info),
  -- so don't clear - the unit frame hover is still active.
  -- This prevents buff/debuff/item tooltips on unit frames from breaking mouseover.
  if CleveRoids.__mo and CleveRoids.__mo.sources["tooltip"] then -- 修复部分团队框架BUG by 武藤纯子酱 2026.7.17
    local tooltipUnit = CleveRoids.__mo.sources["tooltip"]
    if UnitExists(tooltipUnit) then
      return  -- Unit frame hover is still active, don't clear
    end
  end
  CleveRoids.ClearMouseoverFrom("tooltip")
end

function Extension.OnLoad()
  Extension.HookMethod(_G["GameTooltip"], "SetUnit", "SetUnit")
  Extension.HookMethod(_G["GameTooltip"], "Hide", "OnClose")
  Extension.HookMethod(_G["GameTooltip"], "FadeOut", "OnClose")
  Extension.RegisterEvent("UPDATE_MOUSEOVER_UNIT", "UPDATE_MOUSEOVER_UNIT")

  -- Hook non-unit tooltip methods to clear stale mouseover state.
  -- This prevents TurtleRP from showing RP profiles for spells/items.
  Extension.HookMethod(_G["GameTooltip"], "SetSpell", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetBagItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetInventoryItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetAction", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetQuestLogItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetLootItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetMerchantItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetCraftItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetTradeSkillItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetTrainerService", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetHyperlink", "OnNonUnitTooltip")

  -- Additional tooltip methods that can cause sticky mouseover state
  -- Pet action bar, stance bar, buffs/debuffs, and other UI elements
  Extension.HookMethod(_G["GameTooltip"], "SetPetAction", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetShapeshift", "OnNonUnitTooltip")
--  Extension.HookMethod(_G["GameTooltip"], "SetUnitBuff", "OnNonUnitTooltip") -- 注释掉，避免团队框架BUG by 武藤纯子酱 2026.7.17
--  Extension.HookMethod(_G["GameTooltip"], "SetUnitDebuff", "OnNonUnitTooltip") -- 注释掉，避免团队框架BUG by 武藤纯子酱 2026.7.17
--  Extension.HookMethod(_G["GameTooltip"], "SetPlayerBuff", "OnNonUnitTooltip") -- 注释掉，避免团队框架BUG by 武藤纯子酱 2026.7.17

  -- Auction and mail tooltips (guild bank doesn't exist in 1.12.1)
  Extension.HookMethod(_G["GameTooltip"], "SetAuctionItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetAuctionSellItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetInboxItem", "OnNonUnitTooltip")
  Extension.HookMethod(_G["GameTooltip"], "SetSendMailItem", "OnNonUnitTooltip")

  -- Note: SetOwner and SetText are NOT hooked because they're used for ALL tooltips
  -- including unit tooltips. Hooking them would incorrectly clear mouseover for units.
end

_G["CleveRoids"] = CleveRoids

