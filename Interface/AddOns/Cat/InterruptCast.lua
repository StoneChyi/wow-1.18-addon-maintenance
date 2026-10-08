-- -------------------------------------
-- 乌龟服 - 全自动读条打断一键宏
-- 发布日期：2026-05-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 必要条件：SuperWoW
--
-- 打断宏，必须开启SuperWoW
--
-- -------------------------------------
--
-- 功能配置：

-- 以下功能开关：1开启 0关闭
local AUTO_StopCasting = 1			-- 是否自动使用终止自己的施法，以便于打断

-- -------------------------------------

-- 打断的目标、技能列表
local MPInterruptList = {
    
    --这里添加你要打断的技能，格式 {"目标名","技能名"},

    {"克尔苏加德","寒冰箭"},
    {"麦迪文","暗影箭"}
}


function MPINTCastList()

    -- 确认有目标
    if not UnitExists("target") then
        return
    end

    -- 获取目标名称
	local targetName = UnitName(unit)
	if not targetName then
		return
	end

    -- 确认目标正在读条
    local cast,name = MPTargetCast()
    if not cast then
        return
    end

    for i = 1, MPInterruptList do
        if MPInterruptList[i][1] and MPInterruptList[i][2] then

            -- 检测目标名称是否在列表中
            if targetName==MPInterruptList[i][1] then
                -- 检测技能名称是否在列表中
                if string.find(name, MPInterruptList[i][2]) then
                    MPIntCastSpell()
                    return
                end
            end

        end
    end

end


function MPINTCast(spellname)

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."未加载SuperWow，自动打断读条功能无效。|r")
        return false
    end

    -- 确认有目标
    if not UnitExists("target") then
        return false
    end

    -- 确认目标正在读条
    local cast,name = MPTargetCast()
    if not cast then
        return false
    end


    -- 确认读条法术是指定法术
    if spellname then
        --print(name)
        if not string.find(name, spellname) then
            --DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."不打断 ["..name.."]。|r")
            return false
        end
        --DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."尝试打断 ["..spellname.."]。|r")
    end

    MPIntCastSpell()

    return true
end

-- 根据职业施放打断技能
function MPIntCastSpell()

    local _, englishClass = UnitClass("player")

    -- 全职业打断技能判断
    if englishClass == "WARRIOR" then
        -- 战士：拳击（狂暴/武器）或盾击（防护）

        -- 防止自己正在读条
        if MPInterruptCastSaved.StopCasting==1 then
            SpellStopCasting()
        end

        if MPGetShape(1) or MPGetShape(3) then
            CastSpellByName("拳击")
        elseif MPGetShape(2) then
            CastSpellByName("盾击")
        end

    elseif englishClass == "ROGUE" then
        -- 盗贼：脚踢

        -- 防止自己正在读条
        if MPInterruptCastSaved.StopCasting==1 then
            SpellStopCasting()
        end

        CastSpellByName("脚踢")

        -- 要有投掷武器的时候才尝试
        if IsRangedThrownWeapon() then
            CastSpellByName("致命投掷")
        end

    elseif englishClass == "MAGE" then
        -- 法师：法术反制

        -- 防止自己正在读条
        if MPInterruptCastSaved.StopCasting==1 then
            SpellStopCasting()
        end

        CastSpellByName("法术反制")

    elseif englishClass == "HUNTER" then
        -- 猎人：无打断技能
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."猎人：无打断技能|r")

    elseif englishClass == "PRIEST" then
        -- 牧师：沉默

        -- 防止自己正在读条
        if MPInterruptCastSaved.StopCasting==1 then
            SpellStopCasting()
        end

        CastSpellByName("沉默")

    elseif englishClass == "WARLOCK" then
        -- 术士：法术封锁

        -- 防止自己正在读条
        if MPInterruptCastSaved.StopCasting==1 then
            SpellStopCasting()
        end

        CastSpellByName("法术封锁")

    elseif englishClass == "DRUID" then
        -- 德鲁伊：无打断技能（熊形态击晕不算真正打断）
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."德鲁伊：无打断技能|r")

    elseif englishClass == "PALADIN" then
        -- 圣骑士：无打断技能（1.12版本）
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."圣骑士：无打断技能|r")

    elseif englishClass == "SHAMAN" then
        -- 萨满：大地震击

        -- 防止自己正在读条
        if MPInterruptCastSaved.StopCasting==1 then
            SpellStopCasting()
        end

        CastSpellByName("大地震击(等级 "..MPInterruptCastSaved.Shaman_Value..")")

    else
        print("未知职业")
    end

end


