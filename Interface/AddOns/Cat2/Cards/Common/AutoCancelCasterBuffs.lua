-- 自动取消法系Buff：先用本轮快照筛选，再合并扫描；所有配置共用执行间隔。
local card = {
    id = "common_auto_cancel_caster_buffs",
    name = "自动取消法系Buff",
    description = "自动取消法系增益效果，如：奥术智慧、精神祷言等",
    details = "自动取消奥术光辉、奥术智慧、精神祷言、神圣之灵、智慧祝福和强效智慧祝福。每秒最多检查一次，快照中没有这些效果时不扫描Buff槽位；存在时合并为一次扫描后取消。不阻断后续卡片。",
    sort = 52,
    category = "common",
    icons = {
        "Interface\\Icons\\Spell_Holy_DispelMagic",
    },
}

function card.RefreshRuntimeData()
end

local EXECUTION_INTERVAL = 1
local nextExecutionTime = 0
local casterBuffs = {
    ["奥术光辉"] = true,
    ["奥术智慧"] = true,
    ["精神祷言"] = true,
    ["神圣之灵"] = true,
    ["智慧祝福"] = true,
    ["强效智慧祝福"] = true,
}

function card.Execute(context)
    local now = GetTime()
    if now < nextExecutionTime then return false end
    nextExecutionTime = now + EXECUTION_INTERVAL
    local player = Cat2.PlayerInformation.temporary
    if type(player.buff) ~= "table" then return false end
    for name in pairs(casterBuffs) do
        if player.buff[name] then
            Cat2.CancelBuffsByName(casterBuffs)
            break
        end
    end
    return false
end

Cat2.RegisterCard(card)
