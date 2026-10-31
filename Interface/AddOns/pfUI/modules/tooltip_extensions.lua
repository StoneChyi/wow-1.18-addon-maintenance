-- Shared tooltip execution: pfUI owns layout/context, Automaton supplies only
-- additional information and its original saved options.
pfUI:RegisterModule("tooltip-extensions", "vanilla", function()
  local integration = { title = "增强信息" }
  pfUI.automationIntegrations = pfUI.automationIntegrations or {}
  pfUI.automationIntegrations.Tooltip = integration
  local function Provider()
    return Automaton and Automaton.modules and Automaton.modules.Tooltip
  end
  function integration:Sync(enabled)
    local module = Provider()
    if not module or not module.db or not module.db.profile or not module.SetPfUIManaged then return false end
    local owner = pfUI.tooltip
    if owner then self:Attach(owner) end
    self.managed = enabled and owner and true or nil
    module:SetPfUIManaged(self.managed)
    if owner then owner.extension = self.managed and module or nil end
    if self.managed and not C.tooltip.automation_itemid_imported then
      if Automaton:IsModuleActive("Tooltip") and module.db.profile.showitemid then C.tooltip.itemid="1" end
      C.tooltip.automation_itemid_imported="1"
    end
    self:BuildGUI()
    return true
  end
  function integration:GetOptions()
    local module=Provider()
    if not module or not module._options then return { info={type="description",name="等待自动化提示信息模块完成加载。"} } end
    local options={}
    for key,opt in pairs(module._options) do options[key]=opt end
    options.showitemid={type="toggle",name="显示物品ID",order=11,
      get=function() return C.tooltip.itemid=="1" end,
      set=function(value) C.tooltip.itemid=value and "1" or "0" end,
      desc="与 pfUI 鼠标提示的物品ID开关共用设置，只显示一份。"}
    options.forceUnitTooltip={type="toggle",name="单位框始终显示提示",order=34,
      get=function() return module.db.profile.forceUnitTooltip~=false end,
      set=function(value) module.db.profile.forceUnitTooltip=value end,
      desc="保留原增强模块的单位框悬停提示；关闭后遵循各单位框自己的提示开关。"}
    options.info={type="description",name="pfUI 统一绘制提示。增强内容沿用原模块配置，独有信息继续保留。",order=0}
    if not self.managed then options.info.name="统一管理未启用，增强模块按独立模式运行；物品ID设置使用原模块。";options.showitemid=module._options.showitemid end
    return options
  end
  function integration:Refresh()
    if not self.content or not pfUI.automationOptions then return end
    pfUI.automationOptions:Render(self.content,{_options=self:GetOptions()},function() integration:Refresh() end)
  end
  function integration:BuildGUI()
    if self.guiReady or not pfUI.gui or not pfUI.automationOptions then return end
    local label=T["Tooltip"]
    pfUI.gui.CreateGUIEntry(label,self.title,function() integration.content=this;integration:Refresh() end)
    local area=pfUI.gui.frames[label][self.title].area
    local show,hide=area:GetScript("OnShow"),area:GetScript("OnHide")
    area:SetScript("OnShow",function() if show then show() end;integration:Refresh() end)
    area:SetScript("OnHide",function()
      if integration.content then pfUI.automationOptions:Suspend(integration.content) end
      if hide then hide() end
    end)
    self.guiReady=true
  end
  function integration:OpenSettings()
    if pfUI.ShowGUI then pfUI:ShowGUI() end
    self:BuildGUI()
    local menu=pfUI.gui and pfUI.gui.frames[T["Tooltip"]]
    if menu and menu[self.title] then menu:Click();menu[self.title]:Click();self:Refresh() end
  end
  integration.Open=integration.OpenSettings
  local oldShow=pfUI.ShowGUI
  if oldShow then function pfUI:ShowGUI() local result=oldShow(self);integration:BuildGUI();return result end end
  function integration:Attach(owner)
    if self.owner==owner then return end
    self.owner=owner
    function owner:ItemIDHandledElsewhere()
      local module=Provider()
      return module and module.active and not module.pfUIManaged and module.db.profile.showitemid
    end
    function owner:ShouldHideContent()
      return self.extension and self.extension:ShouldHideTooltip()
    end
    function owner:ForceUnitTooltip()
      return self.extension and self.extension.active and self.extension.db.profile.forceUnitTooltip~=false
    end
    function owner:RenderExtension(unit)
      local module=self.extension
      if not module or not module.active then return end
      local data=pfUI.api.libtooltip
      local signature=tostring(data.serial or 0)..":"..tostring(unit or data.kind or GameTooltipTextLeft1:GetText())
      if self.extensionSignature==signature then return end
      self.extensionSignature=signature
      if unit then module:EnhanceUnitTooltip(unit)
      elseif data:GetItemID() then
        if module:IsItemInWishList(data:GetItemID()) then GameTooltip:AddLine("|cff00FF00✓ 我的愿望|r");GameTooltip:Show() end
      else
        if not data.kind or data.kind=="SetText" then module:ShowObj() end
        if data.kind then module:AddSpellID(data.kind,data.args and data.args[1],data.args and data.args[2]) end
      end
    end
    function owner:ContentChanged()
      self.extensionSignature=nil
      self:Update()
    end
    local oldHide=owner:GetScript("OnHide")
    owner:SetScript("OnHide",function() owner.extensionSignature=nil;if oldHide then oldHide() end end)
  end
  if pfUI.tooltip then integration:Attach(pfUI.tooltip) end
  integration:BuildGUI()
end)
