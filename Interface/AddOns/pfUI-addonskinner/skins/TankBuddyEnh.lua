--  TankBuddyEnh 皮肤 (TankBuddy Enhanced / MT助手)
--  目标插件：TankBuddyEnh (TankBuddyEnhFrame 及其子面板)
--
--  美化范围：
--    - 主面板 TankBuddyEnhFrame：替换 DialogBox backdrop 为 pfUI 风格背景
--    - 子面板 TB_Title / TB_RemoveBuffsFrame / TB_CheckButtons /
--      TB_CustomChannelFrame / TB_HelpFrame：统一 pfUI 风格边框
--    - 所有 OptionsButtonTemplate 按钮（Close / Help / Test / Copy /
--      Paste / CloseCustom）：pfUI 风格
--    - 所有 OptionsCheckButtonTemplate 复选框（含 myCheckButtons 频道矩阵）：pfUI 风格
--    - 所有输入框（EditBox，带 ChatInputBorder 纹理）：pfUI 风格输入框
--    - 标题文本染成 pfUI 金色
--    - 右侧 TB_Tab1..TB_Tab11 标签按钮：隐藏 SpellBook-SkillLineTab 矩形外框，
--      用 pfUI 边框替代；技能图标 (NormalTexture) 保留并重新居中
-- ============================================

local addon = "TankBuddyEnh"

-- 调试标志（全局，方便 /run print 验证）
_G.TBENH_RAN  = _G.TBENH_RAN  or 0
_G.TBENH_OK   = _G.TBENH_OK   or false
_G.TBENH_ERR  = _G.TBENH_ERR  or nil

local skinned = false

-- 把输入框（ChatInputBorder 风格的边框纹理）转成 pfUI 输入框
local function SkinEditBox(edit)
  if not edit then return end
  pcall(function()
    pfUI.api.StripTextures(edit)        -- 移除 ChatInputBorder 左右/中段纹理
    pfUI.api.CreateBackdrop(edit, nil, true)  -- legacy=true：边框画在框自身上
  end)
end

-- pfUI 风格按钮 + 修复可能因 XML 直接写全局名导致的文字异常
local function SkinButtonSafe(b, key)
  if not b then return end
  pcall(function()
    pfUI.api.SkinButton(b)
    -- 若 XML 把 text 直接当成字面量 "TB_GUI_xxx"（未解析全局），
    -- 则补上当前本地化的真实文字。
    if key and b:GetText() == key then
      b:SetText(_G[key] or b:GetText())
    end
  end)
end

local function SkinCheckboxSafe(cb)
  if not cb then return end
  pcall(function() pfUI.api.SkinCheckbox(cb) end)
end

-- 右侧 Tab 按钮：
-- - BACKGROUND 层有 48×48 的 SpellBook-SkillLineTab 矩形外框（难看，隐藏）
-- - NormalTexture 被 lua 用 SetNormalTexture(技能图标) 覆盖，不要碰
-- - 加 pfUI 边框，技能图标居中
local function SkinTabButton(btn)
  if not btn or btn.pfui_skinned then return end
  pcall(function()
    -- 隐藏 SpellBook-SkillLineTab 矩形外框（遍历 regions 找纹理路径匹配）
    local regions = { btn:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.IsObjectType and region:IsObjectType("Texture") then
        local tex = region:GetTexture()
        if type(tex) == "string" and string.find(tex, "SpellBook-SkillLineTab", 1, true) then
          region:Hide()
          region:SetAlpha(0)
        end
      end
    end

    -- pfUI 边框（不 StripTextures，会保留 NormalTexture 上的技能图标）
    pfUI.api.CreateBackdrop(btn)

    -- 技能图标（NormalTexture）居中并裁掉外圈杂边。
    -- 注意：TB_TabTemplate 的按钮 frame 实际是 24×24（BACKGROUND 层那张
    -- 48×48 的 SpellBook 矩形外框已被上面 Hide），所以这里只留 2px 内缩，
    -- 图标为 20×20 居中，再 SetTexCoord(.08,.92) 裁源纹理一圈杂边。
    local nt = btn:GetNormalTexture()
    if nt then
      nt:SetTexCoord(.08, .92, .08, .92)
      nt:ClearAllPoints()
      nt:SetPoint("TOPLEFT",     btn, "TOPLEFT",     2, -2)
      nt:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2,  2)
    end

    -- 隐藏 Blizzard 高亮纹理（避免与 pfUI 边框叠加闪烁）
    local ht = btn:GetHighlightTexture()
    if ht then ht:SetAlpha(0) end
  end)
  btn.pfui_skinned = true
end

local function SkinPanel(frame, transp)
  if not frame then return end
  pcall(function()
    frame:SetBackdrop(nil)              -- 清掉原 DialogBox 边框 + 平铺背景
    pfUI.api.StripTextures(frame)
    pfUI.api.CreateBackdrop(frame, nil, nil, transp or .85)
  end)
end

local function SkinAddon()
  _G.TBENH_RAN = (_G.TBENH_RAN or 0) + 1

  -- 与 GUI 的「Disable Skin XXX」语义保持一致（"1" = 禁用）
  local disabled = false
  pcall(function()
    if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
      disabled = true
    end
  end)
  if disabled then return end

  if not pfUI or not pfUI.api then return end

  local frame = _G["TankBuddyEnhFrame"]
  if not frame then return end
  if frame.pfui_skinned then return end

  -- 主面板
  SkinPanel(frame, .85)

  -- 标题块（TB_Title）
  local title = _G["TB_Title"]
  SkinPanel(title, .9)
  if _G["TitleText"]  then pcall(function() _G["TitleText"]:SetTextColor(1, .82, .2, 1) end) end
  if _G["HeaderText"] then pcall(function() _G["HeaderText"]:SetTextColor(1, .82, .2, 1) end) end

  -- 移除 Buff 子面板
  SkinPanel(_G["TB_RemoveBuffsFrame"], .85)

  -- 频道矩阵子面板
  SkinPanel(_G["TB_CheckButtons"], .85)

  -- 自定义频道弹窗
  SkinPanel(_G["TB_CustomChannelFrame"], .9)

  -- 帮助弹窗
  SkinPanel(_G["TB_HelpFrame"], .9)

  -- 通用选项复选框（TB_GeneralOptions 内）
  SkinCheckboxSafe(_G["TB_EnableCheckButton"])
  SkinCheckboxSafe(_G["TB_DisableInBGCheckButton"])
  SkinCheckboxSafe(_G["TB_BossOnlyCheckButton"])

  -- 移除 Buff 子面板内复选框
  SkinCheckboxSafe(_G["TB_AlwaysRemoveCheckButton"])
  SkinCheckboxSafe(_G["TB_DefensiveBearCheckButton"])

  -- 嘲讽恢复复选框（隐藏，随 tab 显示）
  SkinCheckboxSafe(_G["TB_MBRecoveryCheckButton"])

  -- 频道矩阵复选框（myCheckButtons，共 15 个）
  SkinCheckboxSafe(_G["TB_RaidCTRaidCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidRaidWarningCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidRaidCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidGuildCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidPartyCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidYellCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidSayCheckButton"])
  SkinCheckboxSafe(_G["TB_RaidCustomCheckButton"])
  SkinCheckboxSafe(_G["TB_PartyGuildCheckButton"])
  SkinCheckboxSafe(_G["TB_PartyPartyCheckButton"])
  SkinCheckboxSafe(_G["TB_PartyYellCheckButton"])
  SkinCheckboxSafe(_G["TB_PartySayCheckButton"])
  SkinCheckboxSafe(_G["TB_PartyCustomCheckButton"])
  SkinCheckboxSafe(_G["TB_AloneYellCheckButton"])
  SkinCheckboxSafe(_G["TB_AloneSayCheckButton"])
  SkinCheckboxSafe(_G["TB_AloneCustomCheckButton"])

  -- 输入框
  SkinEditBox(_G["TB_EditboxBroadcastDuration"])
  SkinEditBox(_G["TB_EditboxAlwaysRemoveBuffs"])
  SkinEditBox(_G["TB_EditboxRemoveBuffsInDefensiveBear"])
  SkinEditBox(_G["TB_MBRecoveryEditboxText"])
  SkinEditBox(_G["TB_EditboxText"])
  SkinEditBox(_G["TB_EditboxCustom"])

  -- 按钮（OptionsButtonTemplate，带文字）
  SkinButtonSafe(_G["TB_ButtonClose"], "TB_GUI_Close")
  SkinButtonSafe(_G["TB_ButtonHelp"], "TB_GUI_Help")
  SkinButtonSafe(_G["TB_ButtonTest"], "TB_GUI_Test")
  SkinButtonSafe(_G["TB_ButtonCopy"], "TB_GUI_Copy")
  SkinButtonSafe(_G["TB_ButtonPaste"], "TB_GUI_Paste")
  SkinButtonSafe(_G["TB_ButtonCloseCustom"], "TB_GUI_Close")

  -- 右侧 11 个 Tab 标签按钮（SpellBook 风格矩形外框 → pfUI 小边框）
  for i = 1, 11 do
    SkinTabButton(_G["TB_Tab" .. i])
  end

  -- 把 TB_Tab1（其余 10 个 Tab 从它向下级联）的 TOPLEFT 紧贴主面板右边，
  -- 消除 XML 原 offset (-3, -10) 留下的 3px 压重叠。其它 Tab 的位置不变。
  local tab1 = _G["TB_Tab1"]
  if tab1 then
    pcall(function()
      tab1:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -10)
    end)
  end

  frame.pfui_skinned = true
  skinned = true
  _G.TBENH_OK = true
end

-- (1) 尝试登记到 addonskinner（供 GUI 列表 / 统一禁用），pcall 防 nil 报错
pcall(function()
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    pfUI.addonskinner:RegisterSkin(addon, SkinAddon)
  end
end)

-- (2) 自包含触发器：不依赖 addonskinner 加载器时序，确保皮肤一定执行
local trig = CreateFrame("Frame")
trig:RegisterEvent("ADDON_LOADED")
trig:RegisterEvent("VARIABLES_LOADED")
trig:RegisterEvent("PLAYER_LOGIN")
trig:SetScript("OnEvent", function()
  -- addonskinner 若此时才就绪，补登记一次
  pcall(function()
    if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
      pfUI.addonskinner:RegisterSkin(addon, SkinAddon)
    end
  end)

  if event == "ADDON_LOADED" and arg1 ~= addon then return end
  if IsAddOnLoaded(addon) then
    pcall(SkinAddon)
    trig:UnregisterAllEvents()
  end

  -- 所有插件均已加载（PLAYER_LOGIN）后，关闭兜底轮询
  if event == "PLAYER_LOGIN" and not skinned then
    trig:SetScript("OnUpdate", nil)
  end
end)

-- (3) OnUpdate 兜底轮询：万一 ADDON_LOADED 时序异常，确保主面板被美化
trig:SetScript("OnUpdate", function()
  if not pfUI or not pfUI.api then return end
  if _G["TankBuddyEnhFrame"] then
    pcall(SkinAddon)
    trig:SetScript("OnUpdate", nil)
  end
end)
