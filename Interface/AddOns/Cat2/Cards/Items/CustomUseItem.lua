-- 按完整名称使用背包物品。
local card = {
    id = "item_custom_use_item",
    name = "「自定义」使用物品",
    description = "物品可用时使用|cff6bc7e0{itemName}|r",
    details = "填写物品完整名称，默认留空。背包中存在同名物品、未锁定且冷却完成时尝试使用。名称为空或没有可用物品时跳过。不阻断本轮后续卡片。",
    sort = 130.1,
    category = "item",
    icons = { "Interface\\Icons\\INV_Misc_QuestionMark" },
    optionSchema = {
        { key = "itemName", type = "string", label = "物品名称", shortLabel = "物品", default = "" },
    },
}

function card.Execute(context, step)
    local itemName = context:GetStepOption(step, "itemName")
    if type(itemName) ~= "string" then return false end
    itemName = string.gsub(string.gsub(itemName, "^%s+", ""), "%s+$", "")
    if itemName == "" then return false end

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local _, _, name = string.find(link or "", "%[(.-)%]")
            if name == itemName then
                local _, count, locked = GetContainerItemInfo(bag, slot)
                local startTime, duration, enabled = GetContainerItemCooldown(bag, slot)
                if (count or 0) > 0 and locked ~= true and locked ~= 1 and enabled ~= nil
                    and enabled ~= false and enabled ~= 0 and
                    ((duration or 0) <= 0 or (startTime or 0) + duration <= GetTime()) then
                    UseContainerItem(bag, slot)
                    return false
                end
            end
        end
    end
    return false
end

Cat2.RegisterCard(card)
