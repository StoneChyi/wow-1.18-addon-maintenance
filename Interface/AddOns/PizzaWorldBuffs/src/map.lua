local PWB = PizzaWorldBuffs
PWB.map = {}

setfenv(1, PWB:GetEnv())

local frame = CreateFrame('Frame', 'PizzaWorldBuffsMap', UIParent)

--        SW            OG
-- Ony:   67.3, 84.4    51.9, 78.8
-- Nef:   70.6, 80.4    52.8, 78.7
-- Rend:  -             52.3, 82.8
-- Zan:   STV 15.0, 15.5（尤亚姆巴岛）
-- 贴图: img\<boss><confidence>.tga，R=兽人头 / Z=哈卡之心，与 O/N 同规格自绘
local pins = {
  A = {
    O = {
      frame = CreateFrame('Button', 'PizzaHeadPinAllyOny', WorldMapButton),
      x = .673,
      y = .844,
    },
    N = {
      frame = CreateFrame('Button', 'PizzaHeadPinAllyNef', WorldMapButton),
      x = .706,
      y = .804,
    },
  },
  H = {
    O = {
      frame = CreateFrame('Button', 'PizzaHeadPinHordeOny', WorldMapButton),
      x = .514,
      y = .788,
    },
    N = {
      frame = CreateFrame('Button', 'PizzaHeadPinHordeNef', WorldMapButton),
      x = .533,
      y = .787,
    },
    R = {
      frame = CreateFrame('Button', 'PizzaHeadPinHordeRend', WorldMapButton),
      x = .523,
      y = .828, -- 雷德头同样交给奥格瑞玛萨尔，下移避开 O/N（pin 18px，x 需错开 >0.02）
    },
  },
  N = {
    Z = {
      frame = CreateFrame('Button', 'PizzaHeadPinNeutralZan', WorldMapButton),
      x = .15,
      y = .155, -- 尤亚姆巴岛，荆棘谷地图西北角
    },
  },
}

function PWB.map.updatePins()
  local pinSize = 18

  for faction, factionPins in pairs(pins) do
    for boss, pin in pairs(factionPins) do
      pin.frame.faction = faction
      pin.frame.boss = boss

      if not PWB_config.mapHeads or not PWB.utils.hasTimer(faction, boss) then
        pin.frame:Hide()
      else
        pin.frame:ClearAllPoints()
        pin.frame:SetFrameStrata('FULLSCREEN')
        pin.frame:SetFrameLevel(4)
        pin.frame:SetWidth(pinSize)
        pin.frame:SetHeight(pinSize)
        pin.frame:EnableMouse(true)

        local mapWidth = WorldMapButton:GetWidth()
        local mapHeight = WorldMapButton:GetHeight()
        local pinX = pin.x * mapWidth
        local pinY = pin.y * mapHeight

        pin.frame:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', pinX, -pinY)
        if not pin.frame.tex then
          pin.frame.tex = pin.frame:CreateTexture(pin.frame:GetName() .. 'Tex', 'BACKGROUND')
          pin.frame.tex:SetAllPoints(pin.frame)
        end

        local timer = PWB_timers[faction][boss]
        local confidence = PWB.utils.getTimerConfidence(timer.witness, timer.receivedFrom)
        pin.frame.tex:SetTexture('Interface\\AddOns\\PizzaWorldBuffs\\img\\' .. boss .. confidence)
        pin.frame.tex:Hide()
        pin.frame.tex:Show()

        pin.frame:SetScript('OnEnter', function()
          GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
          local titleColor = this.faction == 'A' and PWB.Colors.alliance or this.faction == 'H' and PWB.Colors.horde or PWB.Colors.primary
          local titleName = this.boss == 'Z' and PWB.Bosses[this.boss] or PWB.Bosses[this.boss] .. '的头'
          GameTooltip:SetText(titleColor .. titleName)
          local timerColor = PWB.utils.getTimerColor(timer.witness, timer.receivedFrom)
          local h, m = PWB.core.getTimeLeft(timer)
          GameTooltip:AddLine(PWB.Colors.secondary .. '剩余时间: ' .. timerColor .. PWB.utils.toString(h, m))
          local witness = timer.witness == PWB.me and '你' or timer.witness
          GameTooltip:AddLine(PWB.Colors.secondary .. '人证: ' .. PWB.Colors.primary .. witness)
          GameTooltip:Show()
        end)

        pin.frame:SetScript('OnLeave', function()
          GameTooltip:Hide()
        end)

        pin.frame:SetScript('OnMouseDown', function ()
          if IsShiftKeyDown() then
            if arg1 ~= 'LeftButton' and arg1 ~= 'RightButton' and arg1 ~= 'MiddleButton' and arg1 ~= 'Button4' then return end
            PWB.share.share(arg1, 'timer', PWB_timers[this.faction][this.boss])
          end
        end)
      end
    end
  end
end
function PWB.map.showPins(zone)
  if not PWB_config.mapHeads then return end
  if zone ~= T['Stormwind City'] and zone ~= T['SWC'] and zone ~= T['Orgrimmar'] and zone ~= T['OG'] and zone ~= T['STV'] then return end

  local faction = (zone == T['Stormwind City'] or zone == T['SWC']) and 'A' or 'H'
  if zone == T['STV'] then faction = 'N' end
  for boss, pin in pairs(pins[string.sub(faction, 1, 1)]) do
    if PWB.utils.hasTimer(faction, boss) then
      pin.frame:Show()
    end
  end
end

function PWB.map.hidePins()
  for faction, factionPins in pairs(pins) do
    for boss, pin in pairs(factionPins) do
      pin.frame:Hide()
    end
  end
end

frame:SetScript('OnUpdate', function ()
  local now = GetTime()

  if (this.tick or 1) > now then return else this.tick = now + 1 end

  PWB.map.updatePins()
end)

frame:RegisterEvent('WORLD_MAP_UPDATE')
frame:SetScript('OnEvent', function() 
  if event == 'WORLD_MAP_UPDATE' then
    PWB.map.hidePins()
    PWB.map.showPins(PWB.utils.getCurrentMapZoneName())
  end
end)
