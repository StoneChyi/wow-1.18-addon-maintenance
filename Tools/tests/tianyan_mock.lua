
now = 100
inCombat = false
units = {}
frames = {}
messages = {}
SlashCmdList = {}
local methods = {}
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown ~= false end
function methods:GetFont() return 'font', 10 end
function methods:SetUnit(unit) self.unit = unit end
function methods:GetNumChildren() return 0 end
function methods:GetNumRegions() return 0 end
function methods:GetPoint() return 'CENTER', UIParent, 'CENTER', 200, 200 end
function methods:GetCenter() return 0, 0 end
local function object()
    local o = {scripts={}, events={}, fonts={}}
    return setmetatable(o, {__index=function(t,key)
        return methods[key] or function() end
    end})
end
function methods:CreateFontString()
    local font = object()
    table.insert(self.fonts, font)
    return font
end
function methods:CreateTexture() return object() end
UIParent = object()
WorldFrame = object()
Minimap = object()
GameTooltip = object()
DEFAULT_CHAT_FRAME = {AddMessage=function(self,msg) table.insert(messages,msg) end}
function CreateFrame(kind, name, parent, template)
    local frame = object()
    frame.kind = kind; frame.name = name; frame.parent = parent
    table.insert(frames, frame)
    if name then _G[name] = frame end
    return frame
end
function getglobal(name)
    if name == 'TYScanTipTextLeft1' then
        return {GetText=function()
            local unit = units[TYScanTip.unit]
            return unit and unit.owner or nil
        end}
    end
    return _G[name]
end
function GetTime() return now end
function UnitExists(unit) return unit=='player' or units[unit]~=nil end
function UnitName(unit) return unit=='player' and 'TestPlayer' or units[unit] and units[unit].name end
function UnitIsDead(unit) return units[unit] and units[unit].dead or false end
function UnitCanAttack(player, unit) return false end
function UnitIsUnit(a,b) return a==b end
function GetUnitGUID(unit) return units[unit] and units[unit].guid end
function UnitAffectingCombat(unit) return inCombat end
function SetCVar() end
function GetCVar() return '1' end
function SetSummons(list)
    units = {}
    for i,summon in ipairs(list) do
        local info = {name=summon.name, guid=summon.guid, owner=summon.owner or 'TestPlayer'}
        units['nameplate'..i] = info
        units[summon.guid] = info
    end
end
function Emit(name)
    event = name
    for _,f in ipairs(frames) do
        if f.events[name] and f.scripts.OnEvent then this=f; f.scripts.OnEvent() end
    end
end
function Tick(seconds, legacyElapsed)
    now = now + seconds
    for _,f in ipairs(frames) do
        if f.scripts.OnUpdate then this=f; arg1=legacyElapsed or 0; f.scripts.OnUpdate() end
    end
end
function HasText(text)
    for _,font in ipairs(TYBar.fonts) do
        if type(font.text)=='string' and string.find(font.text,text,1,true) then return true end
    end
    return false
end
function Snapshot(t)
    local parts={}
    for key,value in pairs(t) do
        local k=type(key)=='number' and tostring(key) or string.format('%q',key)
        local v
        if type(value)=='table' then v=Snapshot(value)
        elseif type(value)=='string' then v=string.format('%q',value)
        else v=tostring(value) end
        table.insert(parts,'['..k..']='..v)
    end
    return '{'..table.concat(parts,',')..'}'
end

MockMethods=methods; MockObject=object

PLAYER='0x0000000000000001'
OTHER='0x0000000000000002'
ownersEnabled=true
childReads=0; regionReads=0
children={}; tooltipLines={}
function GetUnitGUID(unit)
    if unit=='player' then return PLAYER end
    local base=string.match(unit,'^(.*)owner$')
    if base then
        local info=units[base]
        return ownersEnabled and info and info.ownerGuid or nil
    end
    return units[unit] and units[unit].guid
end
function UnitIsPlayer(unit) return unit=='player' or (units[unit] and units[unit].player) end
function UnitCanAttack(player,unit) return units[unit] and units[unit].hostile or false end
function UnitIsUnit(a,b)
    local ga=a=='player' and PLAYER or units[a] and units[a].guid
    local gb=b=='player' and PLAYER or units[b] and units[b].guid
    return a==b or (ga and ga==gb) or false
end
function WorldFrame:GetChildren() childReads=childReads+1; return unpack(children) end
function GameTooltip:AddLine(text) table.insert(tooltipLines,text) end
function AddUnit(guid,name,owner,token,text)
    local info={guid=guid,name=name,ownerGuid=owner,owner=text or 'TestPlayer'}
    units[guid]=info
    if token then units[token]=info end
    return info
end
function RemoveUnit(guid)
    for token,info in pairs(units) do if info.guid==guid then units[token]=nil end end
end
function EmitArgs(name,...)
    local args={...}; arg1=args[1]; arg2=args[2]; arg3=args[3]; Emit(name)
end
function Plate(name,owner,guid)
    local frame={shown=true,unit=nil,guid=guid}
    function frame:IsShown() return self.shown end
    function frame:GetName(flag) if flag==1 then return self.guid end end
    function frame:GetRegions()
        regionReads=regionReads+1
        local texture={GetObjectType=function() return 'Texture' end,GetTexture=function() return 'Interface\\Tooltips\\Nameplate-Border' end}
        local label={GetObjectType=function() return 'FontString' end,GetText=function() return self.label end}
        local ownerText={GetObjectType=function() return 'FontString' end,GetText=function() return self.ownerText end}
        return texture,label,ownerText
    end
    frame.label=name; frame.ownerText=owner
    table.insert(children,frame)
    return frame
end

function methodsUnused() end
function MockMethods:RegisterEvent(name)
    if unavailableEvents and unavailableEvents[name] then error('unsupported event') end
    self.events[name]=true
end
function GetNampowerVersion() return 4,6,2 end
function GetCursorPosition() return 300,300 end
function UIParent:GetEffectiveScale() return 1 end
function GetUnitField(unit, field)
    local info=units[unit]
    return info and info[field]
end
function SetCVar() error('TianYan must not rewrite global CVars') end
