-- 撕裂（血腥气息，四星）技能卡片；保留原割裂（四星）的当前机制。
local card = {
    id = "rogue_rupture_bloody_4",
    name = "割裂（血腥气息，四星）",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，血腥气息余|cff6bc7e0{refreshRemainingSeconds}秒|r时补割裂",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。目标拥有4连击点，且玩家身上的血腥气息不存在或剩余时间低于卡片设定值时施放割裂。默认续杯时间为3秒，需要存在有效目标。未加载SuperWoW或角色低于60级时，只能判断血腥气息是否存在，无法按精确剩余秒数续杯。成功执行时会阻断本轮后续卡片。",
    sort = 45.4,
    category = "class",
    classes = {
        ROGUE = 1,
    },
    icons = {
        "Interface\\Icons\\Ability_Rogue_Rupture",
        "Interface\\Icons\\INV_Misc_Bone_09",
    },
    optionSchema = {
        {
            key = "minimumTargetHealth",
            type = "number",
            label = "目标血量",
            shortLabel = "血量",
            default = 100,
            minimum = 0,
            maximum = 1000000,
            integer = true,
        },
        {
            key = "refreshRemainingSeconds",
            type = "number",
            label = "剩余时间",
            shortLabel = "剩余",
            unit = "秒",
            default = 3,
            minimum = 0,
            maximum = 30,
            integer = false,
        },
    },
}

function card.RefreshRuntimeData()
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100
    if (context.playerInformation.temporary.targetHealth or 0) <= minimumTargetHealth then
        return false
    end

    local player = Cat2.PlayerInformation.temporary
    local refreshSeconds = context:GetStepOption(step, "refreshRemainingSeconds") or 3

    if not player.targetExists then
        return false
    end

    if player.targetCombo == 4 and not Cat2.GetRogueBloody(refreshSeconds) then
        Cat2.Cast("割裂")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
