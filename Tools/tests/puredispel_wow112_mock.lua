-- Strict WoW 1.12 surface for PureDispel behavior checks; no renderer emulation.
local installFonts = ...
objects = {}; calls = {}; now = 100; units = {}; books = {spell={},pet={}}
partyCount=0; raidCount=0; playerClass='PALADIN'; shift=false; control=false
BOOKTYPE_SPELL='spell'; BOOKTYPE_PET='pet'; UISpecialFrames={}; SlashCmdList={}
STANDARD_TEXT_FONT='Fonts\\FZXHLJW.TTF'; SUPERWOW_VERSION='test'; messages={}; casts={}
function record(name,...) calls[name]=(calls[name] or 0)+1 end
methods={}
function newObject(kind,name,parent)
 local obj=setmetatable({kind=kind,name=name,parent=parent,scripts={},events={},shown=true,width=0,height=0,level=1,scale=1,points={},alpha=1,children={}}, {__index=methods})
 if name then assert(not _G[name],'duplicate UI name: '..name);_G[name]=obj end
 if parent then table.insert(parent.children,obj) end
 table.insert(objects,obj);return obj
end
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:UnregisterEvent(name) self.events[name]=nil end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:SetParent(parent)
 assert(parent and parent.children,'SetParent requires a frame')
 if self.parent then
  for i,child in ipairs(self.parent.children) do
   if child==self then table.remove(self.parent.children,i);break end
  end
 end
 self.parent=parent;table.insert(parent.children,self)
end
function methods:GetObjectType() return self.kind end
function methods:SetWidth(v) assert(type(v)=='number' and v>=0);self.width=v;record('width') end
function methods:SetHeight(v) assert(type(v)=='number' and v>=0);self.height=v;record('height') end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...)
 local p={...};assert(table.getn(p)>=3,'SetPoint requires 1.12 offsets');self.point=p;self.points[p[1]]=p;record('point')
end
function methods:GetPoint() return unpack(self.point or {'CENTER',UIParent,'CENTER',0,0}) end
function methods:ClearAllPoints() self.points={};self.point=nil end
function methods:SetAllPoints(value) self.allPoints=value end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetToplevel(v) assert(type(v)=='boolean');self.toplevel=v end
function methods:GetFrameStrata() return self.strata or 'MEDIUM' end
function methods:SetFrameLevel(v) assert(v>=0);self.level=v end
function methods:GetFrameLevel() return self.level end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetCenter() return 600,400 end
function methods:GetLeft() return 450 end
function methods:GetRight() return 450+self.width end
function methods:GetTop() return 650 end
function methods:GetBottom() return 650-self.height end
function methods:EnableMouse(v) self.mouse=v end
function methods:EnableMouseWheel(v) self.wheel=v end
function methods:EnableKeyboard(v) self.keyboard=v end
function methods:RegisterForDrag(...) self.drag={...} end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:SetMovable(v) self.movable=v end
function methods:SetUserPlaced(v) self.userPlaced=v end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function invoke(object,script,value)
 local oldThis,oldArg,oldEvent=this,arg1,event;this=object;arg1=value
 local ok,err=pcall(function() if object.scripts[script] then object.scripts[script]() end end)
 this,arg1,event=oldThis,oldArg,oldEvent;if not ok then error(err) end
end
function methods:Show() local previous=self.shown;self.shown=true;record('show');if not previous then invoke(self,'OnShow') end end
function methods:Hide() local previous=self.shown;self.shown=false;record('hide');if previous then invoke(self,'OnHide') end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetAlpha(v) assert(v>=0 and v<=1);self.alpha=v;record('alpha') end
function methods:GetAlpha() return self.alpha end
function methods:SetBackdrop(spec) self.backdropSpec=spec end
function methods:GetBackdrop() return self.backdropSpec end
function methods:SetBackdropColor(...) self.bgColor={...};record('bg') end
function methods:SetBackdropBorderColor(...) self.borderColor={...};record('border') end
function methods:SetNormalTexture(v) self.normalTexture=v end
function methods:SetPushedTexture(v) self.pushedTexture=v end
function methods:SetDisabledTexture(v) self.disabledTexture=v end
function methods:SetHighlightTexture(v) self.highlightTexture=v end
function methods:GetCheckedTexture() return self.checkedTexture end
function methods:SetCheckedTexture(v) self.checkedTexture=v end
function methods:SetTexture(...) self.texture={...};record('texture') end
function methods:SetTexCoord(...) self.texCoord={...} end
function methods:SetVertexColor(...) self.vertex={...};record('vertex') end
function methods:SetBlendMode(v) self.blend=v end
function methods:SetTextColor(...) self.textColor={...};record('textColor') end
function methods:SetShadowColor(...) self.shadow={...} end
function methods:SetShadowOffset(...) end
function methods:SetJustifyH(v) self.justifyH=v end
function methods:SetJustifyV(v) self.justifyV=v end
function methods:GetText() return self.text or '' end
function methods:GetStringWidth() return string.len(self.text or '')*5 end
function methods:GetStringHeight() return 20 end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetMinMaxValues(a,b) self.low,self.high=a,b end
function methods:SetValueStep(v) self.step=v end
function methods:SetValue(v)
 v=math.max(self.low or v,math.min(self.high or v,v));local old=self.value;self.value=v
 if old~=v then invoke(self,'OnValueChanged',v) end
end
function methods:GetValue() return self.value or 0 end
function methods:SetOrientation(v) self.orientation=v end
function methods:SetThumbTexture(v) self.thumb=v end
function methods:SetAutoFocus(v) self.autoFocus=v end
function methods:ClearFocus() self.focus=false end
function methods:SetFocus() self.focus=true end
function methods:SetNumeric(v) self.numeric=v end
function methods:SetMultiLine(v) self.multi=v end
function methods:SetMaxLetters(v) self.maxLetters=v end
function methods:SetTextInsets(...) self.insets={...} end
function methods:HighlightText(...) end
function methods:Enable() self.disabled=false end
function methods:Disable() self.disabled=true end
function methods:SetOwner(owner,anchor) self.owner,self.anchor=owner,anchor end
function methods:IsOwned(owner) return self.owner==owner end
function methods:ClearLines() self.lines={} end
function methods:AddLine(...) self.lines=self.lines or {};table.insert(self.lines,{...}) end
function methods:AddDoubleLine(...) self:AddLine(...) end
function methods:SetUnitDebuff(unit,index)
 record('tooltip');local a=units[unit] and units[unit].auras[index]
 local text=_G[(self.name or '')..'TextLeft1'];if text then text:SetText(a and a.name or '') end
end
function methods:CreateTexture(name,layer) return newObject('Texture',name,self) end
function methods:SetScrollChild(child) self.scrollChild=child end
function methods:SetVerticalScroll(v) self.verticalScroll=v end
function methods:SetHitRectInsets(...) self.hitInsets={...} end
installFonts(methods,newObject)
local strictSetText=methods.SetText
function methods:SetText(v)
 strictSetText(self,v)
 if self.name=='XinTooltipScannerTextLeft1' then record('scannerText') else record('text') end
end
function methods:GetFont() if self.font then return unpack(self.font) end end
function CreateFrame(kind,name,parent,template)
 local obj=newObject(kind,name,parent)
 if template=='GameTooltipTemplate' then obj:CreateFontString(name..'TextLeft1','OVERLAY','GameFontNormal')
 elseif template=='OptionsSliderTemplate' then
  for _,s in ipairs({'Text','Low','High'}) do obj:CreateFontString(name..s,'OVERLAY','GameFontNormal') end
 elseif template=='InputBoxTemplate' then obj:SetFontObject(GameFontNormal)
 elseif template=='UICheckButtonTemplate' or template=='OptionsCheckButtonTemplate' then if name then obj:CreateFontString(name..'Text','OVERLAY','GameFontNormal') end
 elseif template then
  assert(template=='UIPanelButtonTemplate' or template=='UIPanelCloseButton' or template=='UIDropDownMenuTemplate' or template=='FauxScrollFrameTemplate', 'Unknown template: '..template)
 end
 return obj
end
UIParent=CreateFrame('Frame','UIParent');UIParent.width=1920;UIParent.height=1080
WorldFrame=UIParent;GameTooltip=CreateFrame('GameTooltip','GameTooltip',nil,'GameTooltipTemplate')
DEFAULT_CHAT_FRAME={AddMessage=function(_,text)table.insert(messages,text)end}
function getglobal(name) return _G[name] end
function GetScreenWidth() return UIParent.width end
function GetScreenHeight() return UIParent.height end
function GetCursorPosition() return cursorX or 600,cursorY or 400 end
function MouseIsOver(frame) return frame.hover or false end
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return control end
function IsAltKeyDown() return false end
function IsAddOnLoaded(name) return name=='hyx' or name=='pfUI' end
function GetTime() return now end
function UnitName(unit) return units[unit] and units[unit].name end
function UnitExists(unit) if units[unit] then return 1,units[unit].guid end end
function UnitGUID(unit) return units[unit] and units[unit].guid end
function UnitClass(unit) local c=unit=='player' and playerClass or (units[unit] and units[unit].class or 'WARRIOR');return c,c end
function UnitIsUnit(a,b) return units[a] and units[b] and units[a].name==units[b].name end
function UnitIsConnected(unit) return units[unit] and not units[unit].offline end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead end
function UnitIsFriend(a,b) return units[a] and units[b] and not units[b].hostile end
function UnitCanAttack(a,b) return units[b] and units[b].hostile end
function UnitDebuff(unit,index)
 record('aura');local a=units[unit] and units[unit].auras[index]
 if a then return a.texture or ('icon'..a.kind),a.stacks or 1,a.kind,a.id end
end
function GetSpellName(slot,book) return books[book][slot] end
function GetSpellCooldown(slot,book) local c=cooldowns and cooldowns[book..slot] or {};return c.start or 0,c.duration or 0,c.enabled or 1 end
function IsSpellUsable() if oom then return nil,1 end;if unusable then return 0,0 end;return 1,nil end
function IsSpellInRange(name,unit) return units[unit] and units[unit].nativeRange end
function UnitXP(command,source,unit)
 if xpError then error('UnitXP not loaded') end
 if command=='distanceBetween' then record('distance');xpSource=source;return units[unit] and units[unit].distance end
 if command=='inSight' then record('sight');return units[unit] and units[unit].sight end
end
function GetNumRaidMembers() return raidCount end
function GetNumPartyMembers() return partyCount end
function GetRaidRosterInfo(i) local u=units['raid'..i];if u then return u.name,0,math.floor((i-1)/5)+1,60,u.class or 'WARRIOR',u.class or 'WARRIOR' end end
function CastSpellByName(name,unit) table.insert(casts,{name=name,unit=unit}) end
function TargetUnit(unit) lastTarget=units.target;units.target=units[unit] end
function TargetLastTarget() units.target=lastTarget end
function ClearTarget() units.target=nil end
function CastSpell(slot,book) table.insert(casts,{name=books[book][slot],unit=units.target and units.target.name});targeting=true end
function SpellIsTargeting() return targeting end
function SpellTargetUnit(unit) resolved=unit;targeting=false end
function SpellStopTargeting() targeting=false end
function PlaySound() end
function UIDropDownMenu_Initialize(frame,fn) frame.initialize=fn end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info) end
function UIDropDownMenu_SetSelectedID() end
function UIDropDownMenu_SetText(text,frame) frame.text=text end
function UIDropDownMenu_GetText(frame) return frame.text end
function UIDropDownMenu_SetWidth() end
function ToggleDropDownMenu() end
function CloseDropDownMenus() end
function FauxScrollFrame_Update() end
function FauxScrollFrame_GetOffset(frame) return frame.offset or 0 end
function AddUnit(unit,name,kind,distance)
 units[unit]={name=name,guid='guid:'..name,auras=kind and {{name='Debuff-'..kind,kind=kind}} or {},distance=distance or 10,sight=true,class='WARRIOR'}
end
function FireEvent(name,unit)
 local oldEvent,oldArg,oldThis=event,arg1,this;event=name;arg1=unit
 local n=table.getn(objects)
 for i=1,n do local obj=objects[i];if obj.events[name] and obj.scripts.OnEvent then this=obj;obj.scripts.OnEvent() end end
 event,arg1,this=oldEvent,oldArg,oldThis
end
function Tick(dt)
 dt=dt or .3;now=now+dt;local n=table.getn(objects)
 for i=1,n do local obj=objects[i];if obj.scripts.OnUpdate and obj:IsVisible() then invoke(obj,'OnUpdate',dt) end end
end
function ResetCalls() calls={} end
function SetPfUI()
 pfUI_config={global={font_size='12'},appearance={border={background='0,0,0,0.8',color='0.2,0.2,0.2,0.9'}}}
 pfUI={font_default='test-pf-font.ttf',api={}}
 function pfUI.api.GetStringColor(value)
  local _,_,r,g,b,a=string.find(value,'([^,]+),([^,]+),([^,]+),([^,]+)');return tonumber(r),tonumber(g),tonumber(b),tonumber(a)
 end
 function pfUI.api.GetPerfectPixel() return 1 end
 function pfUI.api.GetBorderSize() return 1,1 end
 function pfUI.api.CreateBackdrop(frame,inset,legacy,transp)
  local r,g,b,a=pfUI.api.GetStringColor(pfUI_config.appearance.border.background)
  if transp and transp<a then a=transp end
  if legacy then frame:SetBackdropColor(r,g,b,a);frame:SetBackdropBorderColor(pfUI.api.GetStringColor(pfUI_config.appearance.border.color))
  else frame.backdrop=frame.backdrop or CreateFrame('Frame',nil,frame);frame.backdrop:SetBackdropColor(r,g,b,a);frame.backdrop:SetBackdropBorderColor(pfUI.api.GetStringColor(pfUI_config.appearance.border.color)) end
 end
 function pfUI.api.SkinButton(frame) frame:SetFont(pfUI.font_default,12,'OUTLINE');pfUI.api.CreateBackdrop(frame,nil,true) end
 function pfUI.api.SkinCloseButton(frame) pfUI.api.SkinButton(frame) end
end
AddUnit('player','Self',nil,0);books.spell={'清洁术'}
