local _G = getfenv(0)

local revision = 1.2
local bars = {
   'Action',
   'BonusAction',
   'MultiBarBottomLeft',
   'MultiBarBottomRight',
   'MultiBarRight',
   'MultiBarLeft'
}

FLYOUT_DEFAULT_CONFIG = {
   ['REVISION'] = revision,
   ['BUTTON_SIZE'] = 28,
   ['BORDER_COLOR'] = { 0, 0, 0 },
   ['ARROW_SCALE'] = 5/9,
}

local ARROW_RATIO = 0.6  -- Height to width.

-- upvalues
local ActionButton_GetPagedID = ActionButton_GetPagedID
local ChatEdit_SendText = ChatEdit_SendText
local GetActionText = GetActionText
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellName = GetSpellName
local GetSpellTabInfo = GetSpellTabInfo
local GetScreenHeight = GetScreenHeight
local GetScreenWidth = GetScreenWidth
local HasAction = HasAction
local GetMacroIndexByName = GetMacroIndexByName
local GetMacroInfo = GetMacroInfo

local insert = table.insert
local rawset = rawset
local remove = table.remove
local sizeof = table.getn

local strfind = string.find
local strgsub = string.gsub
local strlower = string.lower
local strsub = string.sub

-- helper functions
local function strtrim(str)
   local _, e = strfind(str, '^%s*')
   local s, _ = strfind(str, '%s*$', e + 1)
   return strsub(str, e + 1, s - 1)
end


local function GetCurItemTexture(itemid)
      _,_,_,_,_,_,_,_,texture = GetItemInfo(itemid);
     return texture
end

function GetICurtemNameByID(itemid)
     name,_,_,_,_,_,_,_,_ = GetItemInfo(itemid);
     return name
end

function MPItemNumByName(itemID)
    local nitemid = tonumber(itemID)
    if not nitemid then return 0 end

    local itemName = GetICurtemNameByID(nitemid)
    if not itemName then return 0 end

    local count = 0

    local bag, slot
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, name = string.find(itemLink, "%[(.-)%]")
                if name == itemName then
                    _, itemCount = GetContainerItemInfo(bag, slot)
                    count = count + itemCount
                end
            end
        end
    end

    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local _, _, name = string.find(itemLink, "%[(.-)%]")
            if name == itemName then
                local itemCount = GetInventoryItemCount("player", slot)  -- 装备位通常返回 1
                count = count + itemCount
            end
        end
    end

    if count < 0 then count = count * -1 end
    return count
end


function MPItemCoolDownByName(itemID)
    local nitemid = tonumber(itemID)
    if not nitemid then return 0,0,0 end

    local itemName = GetICurtemNameByID(nitemid)
    if not itemName then return 0,0,0 end

    local bag, slot

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, name = string.find(itemLink, "%[(.-)%]")
                if name == itemName then
                    local start, duration, enable = GetContainerItemCooldown(bag, slot)
                    return start, duration, enable
                end
            end
        end
    end

    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local _, _, name = string.find(itemLink, "%[(.-)%]")
            if name == itemName then
                local start, duration, enable = GetInventoryItemCooldown("player", slot)
                return start, duration, enable
            end
        end
    end

    return 0,0,0
end

function MPUseItemByName(itemName)
    local bag, slot

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, name = string.find(itemLink, "%[(.-)%]")
                if name == itemName then
                    local startTime, duration, enable = GetContainerItemCooldown(bag, slot)
                    if enable == 1 and duration - (GetTime() - startTime) <= 1.5 then  -- 稍微放宽一点避免GCD误判
                        UseContainerItem(bag, slot)
                        return true
                    end
                end
            end
        end
    end


    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local _, _, name = string.find(itemLink, "%[(.-)%]")
            if name == itemName then
                local startTime, duration, enable = GetInventoryItemCooldown("player", slot)
                if enable == 1 and duration - (GetTime() - startTime) <= 1.5 then
                    UseInventoryItem(slot)
                    return true
                end
            end
        end
    end

    return false
end


local function tblclear(tbl)
	if type(tbl) ~= 'table' then
		return
	end

	-- Clear array-type tables first so table.insert will start over at 1.
	for i = sizeof(tbl), 1, -1 do
		remove(tbl, i)
	end

	-- Remove any remaining associative table elements.
	-- Credit: https://stackoverflow.com/a/27287723
	for k in next, tbl do
		rawset(tbl, k, nil)
	end
end

local strSplitReturn = {}  -- Reusable table for strsplit() when fillTable parameter isn't used.
local function strsplit(str, delimiter, fillTable)
   fillTable = fillTable or strSplitReturn
   tblclear(fillTable)
   strgsub(str, '([^' .. delimiter .. ']+)', function(value)
      insert(fillTable, strtrim(value))
   end)

   return fillTable
end

-- credit: https://github.com/DanielAdolfsson/CleverMacro
local function GetSpellSlotByName(name)
   name = strlower(name)
   local b, _, rank = strfind(name, '%(%s*rank%s+(%d+)%s*%)')
   if b then name = (b > 1) and strtrim(strsub(name, 1, b - 1)) or '' end

   for tabIndex = GetNumSpellTabs(), 1, -1 do
      local _, _, offset, count = GetSpellTabInfo(tabIndex)
      for index = offset + count, offset + 1, -1 do
         local spell, subSpell = GetSpellName(index, 'spell')
         spell = strlower(spell)
         if name == spell and (not rank or subSpell == 'Rank ' .. rank) then
            return index
         end
      end
   end
end

local function GetSpellNameBySlot(slot) 
     for tabIndex = GetNumSpellTabs(), 1, -1 do
      local _, _, offset, count = GetSpellTabInfo(tabIndex)
      for index = offset + count, offset + 1, -1 do
         if index == slot then
		local spell, subSpell = GetSpellName(index, 'spell')
         	spell = strlower(spell)
		return spell
	 end
      end
   end
  return ""
end

local function GetCurItemInfo(itemid)
    nitemid = tonumber(itemid)
    if (type(nitemid) == "number") then
        name,_,_,_,_,_,_,_,texture = GetItemInfo(nitemid);
        if (not name) or (not texture) then
            return 0
        end
        return nitemid
    else
        return 0
    end
end

-- Returns <action>, <actionType>
local function GetFlyoutActionInfo(action)
   if GetSpellSlotByName(action) then
      return GetSpellSlotByName(action), 0
   elseif GetMacroIndexByName(action) ~= 0 then
      return GetMacroIndexByName(action), 1
   elseif GetCurItemInfo(action) ~= 0 then
      return tonumber(action),2
   end
end

local function GetFlyoutDirection(button)
   local horizontal = false
   local bar = button:GetParent()
   if bar:GetWidth() > bar:GetHeight() then
      horizontal = true
   end

   local direction = horizontal and 'TOP' or 'LEFT'

   local centerX, centerY = button:GetCenter()
   if centerX and centerY then
      if horizontal then
         local halfScreen = GetScreenHeight() / 2
         direction = centerY < halfScreen and 'TOP' or 'BOTTOM'
      else
         local halfScreen = GetScreenWidth() / 2
         direction = centerX > halfScreen and 'LEFT' or 'RIGHT'
      end
   end
   return direction
end

local function FlyoutBarButton_OnLeave()
   this.updateTooltip = nil
   GameTooltip:Hide()

   local focus = GetMouseFocus()
   if focus and focus:GetName() and not strfind(focus:GetName(), 'Flyout') then
      Flyout_Hide()
   end
end

local function FlyoutBarButton_OnEnter()
   -- 空槽位（action=0/nil）跳过 tooltip，避免 ActionButton_SetTooltip -> SetAction(0) 报 Usage 错误
   if (this.isotype and this.index) or (this.action and this.action > 0) then
      ActionButton_SetTooltip()
   end
   Flyout_Show(this)
end

local function UpdateBarButton(slot)
   local button = Flyout_GetActionButton(slot)
   if button then
      local arrow = _G[button:GetName() .. 'FlyoutArrow']
      if arrow then
         arrow:Hide()
      end

      if HasAction(slot) then
         button.sticky = false

         local macro = GetActionText(slot)
         if macro then
            local _, _, body = GetMacroInfo(GetMacroIndexByName(macro))
            local s, e = strfind(body, '/flyout')
            if s and s == 1 and e == 7 then
               if not button.preFlyoutOnEnter then
                  button.preFlyoutOnEnter = button:GetScript('OnEnter')
                  button.preFlyoutOnLeave = button:GetScript('OnLeave')
               end

               -- Identify sticky menus.
               if strfind(body, '%[sticky%]') then
                  body = strgsub(body, '%[sticky%]', '')
                  button.sticky = true
               end

               if strfind(body, '%[icon%]') then
                  body = strgsub(body, '%[icon%]', '')
               end

               body = strsub(body, e + 1)

               if not button.flyoutActions then
                  button.flyoutActions = {}
               end

               strsplit(body, ';', button.flyoutActions)

               Flyout_UpdateFlyoutArrow(button)

               button:SetScript('OnLeave', FlyoutBarButton_OnLeave)
               button:SetScript('OnEnter', FlyoutBarButton_OnEnter)
            end
         end

      else
         -- Reset button to pre-Flyout condition.
         button.flyoutActionType = nil
         button.flyoutAction = nil
         if button.preFlyoutOnEnter then
            button:SetScript('OnEnter', button.preFlyoutOnEnter)
            button:SetScript('OnLeave', button.preFlyoutOnLeave)
            button.preFlyoutOnEnter = nil
            button.preFlyoutOnLeave = nil
         end
      end
   end
end

local function HandleEvent()
   if event == 'VARIABLES_LOADED' then
      if not Flyout_Config or (Flyout_Config['REVISION'] == nil or Flyout_Config['REVISION'] ~= revision) then
         Flyout_Config = {}
      end
      -- Initialize defaults if not present.
      for key, value in pairs(FLYOUT_DEFAULT_CONFIG) do
         if not Flyout_Config[key] then
            Flyout_Config[key] = value
         end
      end
   elseif event == 'ACTIONBAR_SLOT_CHANGED' then
      Flyout_Hide(true)  -- Keep sticky menus open.
      UpdateBarButton(arg1)
   else
      Flyout_Hide()
      Flyout_UpdateBars()
   end
end

local handler = CreateFrame('Frame')
handler:RegisterEvent('VARIABLES_LOADED')
handler:RegisterEvent('PLAYER_ENTERING_WORLD')
handler:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
handler:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
handler:SetScript('OnEvent', HandleEvent)

-- globals
function Flyout_OnClick(button)
   if not button or not button.flyoutActionType or not button.flyoutAction then
      return
   end

   if arg1 == nil or arg1 == 'LeftButton' then
      if button.flyoutActionType == 0 then
         CastSpell(button.flyoutAction, 'spell')
      elseif button.flyoutActionType == 1 then
         Flyout_ExecuteMacro(button.flyoutAction)
      elseif button.flyoutActionType == 2 then
	itemName = GetICurtemNameByID(tonumber(button.flyoutAction))
	index = GetMacroIndexByName(itemName)
	if index ~= 0 then
		Flyout_ExecuteMacro(index)
	else
		MPUseItemByName(itemName)
	end	   
      end
   else
 	Flyout_Hide(true)
   end
end

function Flyout_ExecuteMacro(macro)
   local _, _, body = GetMacroInfo(macro)
   local commands = strsplit(body, '\n')
   for i = 1, sizeof(commands) do
      ChatFrameEditBox:SetText(commands[i])
      ChatEdit_SendText(ChatFrameEditBox)
   end
end

function Flyout_Hide(keepOpenIfSticky)
   local i = 1
   local button = _G['FlyoutButton' .. i]
   while button do
      i = i + 1

      if not keepOpenIfSticky or (keepOpenIfSticky and not button.sticky) then
         button:Hide()
         button:GetNormalTexture():SetTexture(nil)
         button:GetPushedTexture():SetTexture(nil)
      end
      -- Un-highlight if no longer needed.
      if button.flyoutActionType ~= 0 or not IsCurrentCast(button.flyoutAction, 'spell') then
         button:SetChecked(false)
      end

      button = _G['FlyoutButton' .. i]
   end

   -- Restore arrow to original strata (it was moved to FULLSCREEN in Flyout_Show())
   if _G['FlyoutButton1'] and not _G['FlyoutButton1']:IsVisible() and _G['FlyoutButton1'].flyoutParent then
      local arrow = _G[_G['FlyoutButton1'].flyoutParent:GetName() .. 'FlyoutArrow']
      arrow:SetFrameStrata(arrow.flyoutOriginalStrata)
   end
end

-- Reusable variables for FlyoutBarButton_UpdateCooldown().
local cooldownStart, cooldownDuration, cooldownEnable

local function FlyoutBarButton_UpdateCooldown(button, reset)
   button = button or this

   if button.flyoutActionType == 0 then
      cooldownStart, cooldownDuration, cooldownEnable = GetSpellCooldown(button.flyoutAction, BOOKTYPE_SPELL)
      if cooldownStart > 0 and cooldownDuration > 0 then
         -- Start/Duration check is needed to get the shine animation.
         CooldownFrame_SetTimer(button.cooldown, cooldownStart, cooldownDuration, cooldownEnable)
      elseif reset then
         -- When switching flyouts, need to hide cooldown if it shouldn't be visible.
         button.cooldown:Hide()
      end
   elseif button.flyoutActionType == 1 then
	button.cooldown:Hide()
   elseif button.flyoutActionType == 2 then
	cooldownStart, cooldownDuration, cooldownEnable = MPItemCoolDownByName(tonumber(button.flyoutAction));
	if cooldownStart > 0 and cooldownDuration > 0 then
         	CooldownFrame_SetTimer(button.cooldown, cooldownStart, cooldownDuration, cooldownEnable)
      	elseif reset then
         	button.cooldown:Hide()
        end
   else
   	button.cooldown:Hide()
   end
end

local Teleport = {
    ['传送：奥格瑞玛'] = true,
    ['传送：幽暗城'] = true,
    ['传送：雷霆崖'] = true,
    ['传送：斯通纳德'] = true,
    ['传送：暴风城'] = true,
    ['传送：铁炉堡'] = true,
    ['传送：达纳苏斯'] = true,
    ['传送：阿尔萨拉斯'] = true,
    ['传送：塞拉摩'] = true,
}
local Portal = {
    ['传送门：奥格瑞玛'] = true,
    ['传送门：幽暗城'] = true,
    ['传送门：雷霆崖'] = true,
    ['传送门：斯通纳德'] = true,
    ['传送门：暴风城'] = true,
    ['传送门：铁炉堡'] = true,
    ['传送门：达纳苏斯'] = true,
    ['传送门：阿尔萨拉斯'] = true,
    ['传送门：塞拉摩'] = true,
}
local function FlyoutButton_OnUpdateCount()
    local text = getglobal(this:GetName().."Count")
    if not text then return end

    local count = 0
    local name

    if this.flyoutActionType == 0 then
        name = GetSpellNameBySlot(tonumber(this.flyoutAction))
        if name == '野性赐福' then
            count = MPItemNumByName(17026)
        elseif name == '翡翠祝福' then
            count = MPItemNumByName(61199)
        elseif name == '奥术光辉' then
            count = MPItemNumByName(17020)
        elseif name == '制造邪能石' then
            count = MPItemNumByName(6265)
        elseif name == '制造虚空石' then
            count = MPItemNumByName(6265)
        elseif name == '制造火焰石' then
            count = MPItemNumByName(6265)
        elseif name == '制造愤怒石' then
            count = MPItemNumByName(6265)
        elseif name == '制造法术石' then
            count = MPItemNumByName(6265)
        elseif name == '召唤小鬼' then
            count = MPItemNumByName(6265)
        elseif name == '召唤魅魔' then
            count = MPItemNumByName(6265)
        elseif name == '召唤虚空行者' then
            count = MPItemNumByName(6265)
        elseif name == '召唤地狱猎犬' then
            count = MPItemNumByName(6265)
        elseif Teleport[name] then
            count = MPItemNumByName(17031)  -- 传送符文
        elseif Portal[name] then
            count = MPItemNumByName(17032)  -- 传送门符文
        end

    elseif this.flyoutActionType == 2 then
        count = MPItemNumByName(this.flyoutAction)
    end

    if count > 1 then
        text:SetText(count)
        text:Show()
    else
        text:SetText("")
        text:Hide() 
    end
end

local function FlyoutButton_OnUpdate()
   -- Update tooltip.
   if GetMouseFocus() == this and (not this.lastUpdate or GetTime() - this.lastUpdate > 1) then
      this:GetScript('OnEnter')()
      this.lastUpdate = GetTime()
   end
   FlyoutBarButton_UpdateCooldown(this)
   FlyoutButton_OnUpdateCount(this)
end

function Flyout_Show(button)
   if not button.flyoutActions then return end
   local direction = GetFlyoutDirection(button)
   local size = Flyout_Config['BUTTON_SIZE']
   local offset = size

   -- Put arrow above the flyout buttons.
   _G[button:GetName() .. 'FlyoutArrow']:SetFrameStrata('FULLSCREEN')

   for i, n in button.flyoutActions do
      local b = _G['FlyoutButton' .. i]
      if not b then
         b = CreateFrame('CheckButton', 'FlyoutButton' .. i, UIParent, 'FlyoutButtonTemplate')
         b:SetID(i)
      end

      b.flyoutParent = button

      -- Things that only need to happen once.
      if not b.cooldown then
         b.cooldown = _G['FlyoutButton' .. i .. 'Cooldown']
         b:SetScript('OnUpdate', FlyoutButton_OnUpdate)
      end

      b.sticky = button.sticky
      local texture = nil

      b.flyoutAction, b.flyoutActionType = GetFlyoutActionInfo(n)

      if b.flyoutActionType == 0 then
         texture = GetSpellTexture(b.flyoutAction, 'spell')
      elseif b.flyoutActionType == 1 then
         _, texture = GetMacroInfo(b.flyoutAction)
      elseif b.flyoutActionType == 2 then
         texture = GetCurItemTexture(b.flyoutAction)
      end

      if texture then
         b:ClearAllPoints()
         b:SetWidth(size)
         b:SetHeight(size)
         b.cooldown:SetScale(size / b.cooldown:GetWidth())  -- Scale cooldown so it will stay centered on the button.
         b:SetBackdropColor(Flyout_Config['BORDER_COLOR'][1], Flyout_Config['BORDER_COLOR'][2], Flyout_Config['BORDER_COLOR'][3])
         b:Show()

         b:GetNormalTexture():SetTexture(texture)
         b:GetPushedTexture():SetTexture(texture)  -- Without this, icons disappear on click.

         -- Highlight professions and channeled casts.
         if b.flyoutActionType == 0 and IsCurrentCast(b.flyoutAction, 'spell') then
            b:SetChecked(true)
         end

         -- Force an instant update.
         this.lastUpdate = nil
         FlyoutBarButton_UpdateCooldown(b, true)

         if direction == 'BOTTOM' then
            b:SetPoint('BOTTOM', button, 0, -offset)
         elseif direction == 'LEFT' then
            b:SetPoint('LEFT', button, -offset, 0)
         elseif direction == 'RIGHT' then
            b:SetPoint('RIGHT', button, offset, 0)
         else
            b:SetPoint('TOP', button, 0, offset)
         end

         offset = offset + size
      end

   end
end

function Flyout_GetActionButton(action)
   for i = 1, sizeof(bars) do
      for j = 1, 12 do
         local button = _G[bars[i] .. 'Button' .. j]
         local slot = ActionButton_GetPagedID(button)
         if slot == action and button:IsVisible() then
            return button
         end
      end
   end
end

function Flyout_UpdateBars()
   for _, barName in ipairs(bars) do
      for j = 1, 12 do
         local button = _G[barName .. 'Button' .. j]
         if button then
            local slot = ActionButton_GetPagedID(button)
            UpdateBarButton(slot)
         end
      end
   end
end

function Flyout_UpdateFlyoutArrow(button)
   if not button then return end

   local direction = GetFlyoutDirection(button)

   local arrow = _G[button:GetName() .. 'FlyoutArrow']
   if not arrow then
      arrow = CreateFrame('Frame', button:GetName() .. 'FlyoutArrow', button)
      arrow:SetPoint('TOPLEFT', button)
      arrow:SetPoint('BOTTOMRIGHT', button)
      arrow.flyoutOriginalStrata = arrow:GetFrameStrata()
      arrow.texture = arrow:CreateTexture(arrow:GetName() .. 'Texture', 'ARTWORK')
      arrow.texture:SetTexture('Interface\\ChatFrame\\ChatFrameExpandArrow')
   end

   arrow:Show()
   arrow.texture:ClearAllPoints()

   local arrowWideDimension = (button:GetWidth() or 36) * Flyout_Config['ARROW_SCALE']
   local arrowShortDimension = arrowWideDimension * ARROW_RATIO

   if direction == 'BOTTOM' then
      arrow.texture:SetWidth(arrowWideDimension)
      arrow.texture:SetHeight(arrowShortDimension)
      arrow.texture:SetTexCoord(0, 0.565, 0.315, 0)
      arrow.texture:SetPoint('BOTTOM', arrow, 0, -6)
   elseif direction == 'LEFT' then
      arrow.texture:SetWidth(arrowShortDimension)
      arrow.texture:SetHeight(arrowWideDimension)
      arrow.texture:SetTexCoord(0, 0.315, 0.375, 1)
      arrow.texture:SetPoint('LEFT', arrow, -6, 0)
   elseif direction == 'RIGHT' then
      arrow.texture:SetWidth(arrowShortDimension)
      arrow.texture:SetHeight(arrowWideDimension)
      arrow.texture:SetTexCoord(0.315, 0, 0.375, 1)
      arrow.texture:SetPoint('RIGHT', arrow, 6, 0)
   else
      arrow.texture:SetWidth(arrowWideDimension)
      arrow.texture:SetHeight(arrowShortDimension)
      arrow.texture:SetTexCoord(0, 0.565, 0, 0.315)
      arrow.texture:SetPoint('TOP', arrow, 0, 6)
   end
end

hooksecurefunc("UseAction", function(slot, checkCursor, onSelf)
    local button = Flyout_GetActionButton(slot)
    if not button or not button.flyoutActions or not button.flyoutActions[1] then
        return
    end

    local mouseFocus = GetMouseFocus()
    local mouseFocusName = mouseFocus and mouseFocus:GetName() or ""

    if mouseFocus and strfind(mouseFocusName, "^FlyoutButton%d+$") then
        Flyout_OnClick(mouseFocus)
        if not button.sticky then
            Flyout_Hide()
        end
        return
    end

    if mouseFocus == button and arg1 ~= "RightButton" and not button.sticky then
        local firstAction = button.flyoutActions[1]
        local action, actionType = GetFlyoutActionInfo(firstAction)

        if actionType == 0 then        -- 技能
            CastSpell(action, "spell")
        elseif actionType == 1 then    -- 宏
            Flyout_ExecuteMacro(action)
        elseif actionType == 2 then    -- 物品
            local itemName = GetICurtemNameByID(tonumber(firstAction))
            if itemName and itemName ~= "" then
                local macroIdx = GetMacroIndexByName(itemName)
                if macroIdx ~= 0 then
                    Flyout_ExecuteMacro(macroIdx)
                else
                    MPUseItemByName(itemName)
                end
            end
        end

        Flyout_Hide()
        return
    end

    if not button.sticky then
        Flyout_Show(button)
    end
end)