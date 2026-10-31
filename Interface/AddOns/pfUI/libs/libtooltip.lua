-- One content dispatcher shared by pfUI layout, item prices and extensions.
setfenv(1, pfUI:GetEnvironment())
if pfUI.api.libtooltip then return end
local tip = GameTooltip
local lib = CreateFrame("Frame", "pfLibTooltip", tip)
pfUI.api.libtooltip = lib
local function Pack(...) return arg end
    local function UnpackRange(values, first, last)
      if first <= last then return values[first], UnpackRange(values, first+1, last) end
    end
function lib:Clear()
  self.itemID, self.itemLink, self.itemCount, self.unit, self.kind = nil,nil,nil,nil,nil
end
lib:SetScript("OnHide", function() if not lib.setting then lib:Clear() end end)
function lib:GetItemID()
  if not self.itemLink then return end
  if not self.itemID then
    local _,_,id = string.find(self.itemLink,"item:(%d+)")
    self.itemID = tonumber(id)
  end
  return self.itemID
end
function lib:GetItemLink() return self.itemLink end
function lib:GetItemCount() return self.itemCount end
local readers = {
  SetHyperlink = function(a) if a and string.find(a,"item:%d+") then return a end end,
  SetBagItem = function(a,b) if a and b then local _,count=GetContainerItemInfo(a,b);return GetContainerItemLink(a,b),count end end,
  SetQuestLogItem = function(a,b) return GetQuestLogItemLink(a,b) end,
  SetQuestItem = function(a,b) return GetQuestItemLink(a,b) end,
  SetLootItem = function(a) return GetLootSlotLink(a) end,
  SetInventoryItem = function(a,b) return GetInventoryItemLink(a,b) end,
  SetLootRollItem = function(a) return GetLootRollItemLink(a) end,
  SetMerchantItem = function(a) return GetMerchantItemLink(a) end,
  SetCraftItem = function(a,b) return GetCraftReagentItemLink(a,b) end,
  SetCraftSpell = function(a) return GetCraftItemLink(a) end,
  SetTradeSkillItem = function(a,b) if b then return GetTradeSkillReagentItemLink(a,b) else return GetTradeSkillItemLink(a) end end,
  SetTradePlayerItem = function(a) return GetTradePlayerItemLink(a) end,
  SetTradeTargetItem = function(a) return GetTradeTargetItemLink(a) end,
  SetAuctionItem = function(a,b) local _,_,count=GetAuctionItemInfo(a,b);return GetAuctionItemLink(a,b),count end,
  SetAuctionSellItem = function() local name,_,count=GetAuctionSellItemInfo();return GetItemLinkByName(name),count end,
  SetInboxItem = function(a) local name,_,count=GetInboxItem(a);return GetItemLinkByName(name),count end,
}
local methods = { "SetHyperlink","SetBagItem","SetQuestLogItem","SetQuestItem","SetLootItem","SetInventoryItem",
  "SetLootRollItem","SetMerchantItem","SetCraftItem","SetCraftSpell","SetTradeSkillItem","SetTradePlayerItem",
  "SetTradeTargetItem","SetAuctionItem","SetAuctionSellItem","SetInboxItem","SetUnit","SetAction","SetPetAction",
  "SetShapeshift","SetSpell","SetTrackingSpell","SetPlayerBuff","SetPlayerDebuff","SetUnitBuff","SetUnitDebuff","SetText" }
local function Install(method)
  local original = tip[method]
  if type(original) ~= "function" then return end
  tip[method] = function(...)
    -- Internal nested setters belong to the outer content transaction.
    if lib.setting or (pfUI.tooltip and pfUI.tooltip.updating) then return original(UnpackRange(arg,1,arg.n)) end
    lib:Clear()
    lib.serial = (lib.serial or 0)+1
    lib.kind = method
    lib.args = { arg[2],arg[3],arg[4] }
    if method == "SetUnit" then lib.unit=arg[2] end
    local reader = readers[method]
    if reader then lib.itemLink,lib.itemCount=reader(arg[2],arg[3]) end
    local owner = pfUI.tooltip
    if owner and owner.ShouldHideContent and owner:ShouldHideContent() then tip:Hide();return end
    lib.setting = true
    -- Keep original errors visible and always clear the transaction guard.
    local result = Pack(pcall(original,UnpackRange(arg,1,arg.n)))
    lib.setting = nil
    if not result[1] then error(result[2]) end
    if owner and owner.ContentChanged then owner:ContentChanged() end
    return UnpackRange(result,2,result.n)
  end
end
for _,method in ipairs(methods) do Install(method) end
