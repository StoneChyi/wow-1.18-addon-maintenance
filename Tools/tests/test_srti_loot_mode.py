"""SRTI loot switching and per-side tool ordering with strict WoW 1.12 UI contracts."""
import ast
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/SimpleRaidTargetIcons'
fixture = ROOT / 'PluginHistory/Evidence/addons_tmp/test_srti_tools.py'
tree = ast.parse(fixture.read_text(encoding='utf-8-sig'))
MOCK = next(ast.literal_eval(node.value) for node in tree.body
            if isinstance(node, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == 'MOCK' for t in node.targets))
FONT_CONTRACT = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')

STRICT_UI = r'''
local installFontContract = ...
local methods = getmetatable(UIParent)
installFontContract(methods, CreateFrame)
-- Existing mock frames stand in for client XML widgets with inherited font templates.
for _,obj in ipairs(frameObjects) do
    if obj.kind=='FontString' then obj:SetFontObject('GameFontNormal') end
end
local createFont = methods.CreateFontString
function methods:CreateFontString(name, layer, template)
    -- Additional real 1.12 template used by the original SRTI settings panel.
    if template=='GameFontNormalSmall' then template='GameFontNormal' end
    return createFont(self, name, layer, template)
end
local create = CreateFrame
function CreateFrame(kind, name, parent, template)
    local obj = create(kind, name, parent, template)
    if template=='OptionsCheckButtonTemplate' then
        getglobal(name..'Text'):SetFontObject('GameFontNormal')
    end
    return obj
end
function methods:RegisterEvent(name)
    self.events=self.events or {}; self.events[name]=true
end
function fireEvent(name)
    event=name
    for _,frame in ipairs(frameObjects) do
        if frame.events and frame.events[name] then frame:Fire('OnEvent') end
    end
end
function tick()
    time=time+.25; this=BananaFrame; Banana_OnUpdate()
end
function GetLootMethod() lootReads=lootReads+1; return lootMethod end
lootRequests={}
UIDROPDOWNMENU_MAXLEVELS=2; UIDROPDOWNMENU_MAXBUTTONS=32
function methods:UnlockHighlight() self.highlighted=false end
for level=1,2 do
    for index=1,32 do
        local name='DropDownList'..level..'Button'..index
        CreateFrame('Button',name,UIParent)
        CreateFrame('Texture',name..'Check',UIParent):Hide()
    end
end
function SetLootMethod(...)
    local args={...}
    assert((args[1]=='master' and table.getn(args)==2 and type(args[2])=='string')
        or (args[1]~='master' and table.getn(args)==1), 'invalid 1.12 SetLootMethod arguments')
    table.insert(lootRequests,args) -- Server acknowledgement is intentionally delayed.
end
function UIDropDownMenu_Initialize(frame, initializer, style)
    frame.initialize=initializer; frame.menuStyle=style
end
function CloseDropDownMenus() menuRows=nil end -- Vanilla keeps its cached menu name.
function ToggleDropDownMenu(level, value, frame, anchor, x, y)
    assert(level==1 and value==nil and frame.menuStyle=='MENU')
    assert(anchor and type(x)=='number' and type(y)=='number')
    UIDROPDOWNMENU_MENU_LEVEL=1
    if UIDROPDOWNMENU_OPEN_MENU==frame:GetName() and frame.rows then menuRows=frame.rows; return end
    UIDROPDOWNMENU_OPEN_MENU=frame:GetName()
    menuRows={}; frame.initialize(); frame.rows=menuRows
end
function UIDropDownMenu_AddButton(info, level)
    assert(level==1 and menuRows and table.getn(menuRows)<32, '1.12 dropdown item limit')
    local label=UIParent:CreateFontString(nil,'OVERLAY','GameFontNormal')
    label:SetText(info.text) -- Native menu labels inherit a font too.
    local index=table.getn(menuRows)+1
    local button=getglobal('DropDownList1Button'..index)
    local checked=info.checked
    local frame=getglobal(UIDROPDOWNMENU_OPEN_MENU)
    if frame.selectedName then
        if frame.selectedName==info.text then checked=1 end
    elseif frame.selectedID==index then checked=1 end
    button.checked=checked
    button.keepShownOnClick=info.keepShownOnClick
    if checked then getglobal(button:GetName()..'Check'):Show()
    else getglobal(button:GetName()..'Check'):Hide() end
    info.native=button
    table.insert(menuRows, info)
end
function menuItem(text)
    for _,row in ipairs(menuRows or {}) do if row.text==text then return row end end
    error('menu item missing: '..text)
end
function clickMenu(text)
    local row=menuItem(text)
    if row.disabled or row.isTitle then return false end
    local oldThis=this; this=row.native
    assert(row.func); row.func(row.arg1,row.arg2)
    -- 1.12 runs checkbox work after func(), even if that callback rebuilt the menu.
    if row.native.keepShownOnClick then
        row.native.checked=not row.native.checked
        local check=getglobal(row.native:GetName()..'Check')
        if row.native.checked then check:Show() else check:Hide() end
    else CloseDropDownMenus() end
    this=oldThis
    -- A queued rebuild runs on the next UI frame, after the native click handler returns.
    if SRTI_MenuRefresh and SRTI_MenuRefresh:GetScript('OnUpdate') then SRTI_MenuRefresh:Fire('OnUpdate') end
    return true
end
function assertNoMenuChecks()
    for _,row in ipairs(menuRows) do assert(not getglobal(row.native:GetName()..'Check'):IsShown(), 'residual check: '..row.text) end
end
function SendChatMessage() error('indicator must never send group messages') end
lootReads=0; lootMethod='group'
'''


def world(group='solo', enabled=1, option=None, failed_font=False, order=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute('function UnitIsPlayer(unit) return units[unit] and units[unit].isPlayer end')
    contract = lua.execute(FONT_CONTRACT)
    lua.execute(STRICT_UI, contract)
    if failed_font:
        lua.execute("failedFontPaths[STANDARD_TEXT_FONT]=true")
    for name in ('IconTextures.lua', 'Banana.lua', 'RaidTools.lua', 'Localization.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute(f'''
        BANANA_CONFIG.ENABLED={enabled}; BANANA_CONFIG.SHOW_EXTRA_INFO=0
        partyCount={2 if group == 'party' else 0}; raidCount={10 if group == 'raid' else 0}
    ''')
    if option is not None:
        lua.globals().BANANA_CONFIG.SHOW_LOOT_BUTTON = option
    if order is not None:
        lua.globals().BANANA_CONFIG.TOOL_ORDER = lua.table_from(order)
    lua.execute('''
        this=BananaFrame; Banana_OnLoad()
        -- Before addon initialization, no indicator or listeners may touch the UI.
        fireEvent('PARTY_LOOT_METHOD_CHANGED'); fireEvent('RAID_ROSTER_UPDATE')
        assert(SRTI_LootButton==nil)
        event='ADDON_LOADED'; arg1='SimpleRaidTargetIcons'; Banana_OnEvent()
    ''')
    return lua


groups = 0
for group in ('solo', 'party', 'raid'):
    for failed in (False, True):
        lua = world(group, failed_font=failed)
        lua.execute(f"assert(SRTI_LootButton:IsShown()=={str(group != 'solo').lower()})")
        lua.execute('''
            assert(BANANA_CONFIG.SHOW_LOOT_BUTTON==1 and BANANA_CONFIG.LOOT_BUTTON_SIDE=='RIGHT')
            assert(SRTI_LootButton:GetWidth()==36)
            if SRTI_LootButton:IsShown() then
                assert(SRTI_LootButton.label:GetText()=='队伍')
                assert(SRTI_LootButton.label:GetStringWidth()<=34)
            end
            -- Exercise health/name text too, including initialization with failed fonts.
            units.target={name='Fallback target',mark=8,hp=80,max=100}
            BANANA_CONFIG.SHOW_SHORT_NAME=1; Banana_UpdateStatus()
            assert(SRTI_Health8.text:GetText()=='80%')
            assert(SRTI_Health8.name:GetText()~='')
            BananaConfigFrame:Show(); BananaConfigFrame:Hide()
            -- Prove that the harness really enforces missing fonts and failed SetFont.
            local probe=UIParent:CreateFontString(nil,'OVERLAY')
            assert(not pcall(function() probe:SetText('') end))
            failedFontPaths.bad=true
            assert(not probe:SetFont('bad',12))
            assert(not pcall(function() probe:SetText('hidden') end))
            probe:SetFontObject('GameFontNormal'); probe:SetText('fallback works')
        ''')
        groups += 1

for group in ('party', 'raid'):
    lua = world(group, failed_font=True)
    lua.execute('''
        local modes={freeforall={'自由拾取','自由'},roundrobin={'轮流拾取','轮流'},master={'队长分配','队长'},
            group={'队伍拾取','队伍'},needbeforegreed={'需求优先','需求'}}
        SRTI_LootButton:Fire('OnEnter')
        for token,labels in pairs(modes) do
            lootMethod=token; fireEvent('PARTY_LOOT_METHOD_CHANGED')
            assert(SRTI_LootButton.label:GetText()==labels[2])
            assert(string.find(GameTooltip:GetText(),labels[1],1,true))
            assert(SRTI_LootButton.label:GetStringWidth()<=34)
            local count=table.getn(messages)
            SRTI_LootButton:Fire('OnClick','RightButton'); assert(table.getn(messages)==count)
            SRTI_LootButton:Fire('OnClick','LeftButton')
            assert(UIDROPDOWNMENU_OPEN_MENU=='SRTI_LootMenu')
            assert(menuItem(labels[1]).checked==1)
            assert(table.getn(lootRequests)==0 and table.getn(messages)==count)
        end
        lootMethod=nil; fireEvent('PARTY_LOOT_METHOD_CHANGED')
        assert(SRTI_LootButton.label:GetText()=='待定')
        lootMethod='unexpected'; tick(); assert(SRTI_LootButton.label:GetText()=='待定')
        lootMethod='master'; tick(); assert(SRTI_LootButton.label:GetText()=='队长')
        SRTI_LootButton:Fire('OnLeave'); assert(not GameTooltip:IsShown())
        -- Font fallback also works during repeated mode changes and hidden text paths.
        failedFontPaths[STANDARD_TEXT_FONT]=true
        BANANA_CONFIG.SHOW_HEALTH=0; BANANA_CONFIG.SHOW_SHORT_NAME=1
        units.target={name='Long target name',mark=8,hp=80,max=100}
        Banana_UpdateStatus(); BananaConfigFrame:Show(); BananaConfigFrame:Hide()
        assert(SRTI_Health8.name:IsShown())
    ''')
    groups += 1

lua = world()
lua.execute('''
    local soloAnchor=SRTI_SaveBtn.points[1][2]
    assert(soloAnchor==RaidTargetFrame8Button)
    assert(SRTI_Position_SAVE_BUTTON:GetText()=='第1位')
    partyCount=2; fireEvent('PARTY_MEMBERS_CHANGED')
    assert(SRTI_LootButton:IsShown() and SRTI_SaveBtn.points[1][2]==SRTI_LootButton)
    assert(SRTI_Position_SAVE_BUTTON:GetText()=='第2位')
    partyCount=0; raidCount=10; fireEvent('RAID_ROSTER_UPDATE'); assert(SRTI_LootButton:IsShown())
    SRTI_LootButton:Fire('OnEnter')
    raidCount=0; fireEvent('RAID_ROSTER_UPDATE')
    assert(not SRTI_LootButton:IsShown() and not GameTooltip:IsShown())
    assert(SRTI_SaveBtn.points[1][2]==soloAnchor)
    assert(SRTI_Position_SAVE_BUTTON:GetText()=='第1位')
    partyCount=2; fireEvent('PLAYER_ENTERING_WORLD'); assert(SRTI_LootButton:IsShown())
    SRTI_Option_SHOW_LOOT_BUTTON.checked=false; SRTI_Option_SHOW_LOOT_BUTTON:Fire('OnClick')
    assert(not SRTI_LootButton:IsShown() and BANANA_CONFIG.SHOW_LOOT_BUTTON==0)
    SRTI_Option_SHOW_LOOT_BUTTON.checked=true; SRTI_Option_SHOW_LOOT_BUTTON:Fire('OnClick')
    assert(SRTI_LootButton:IsShown())
    Banana_SetEnabled(false); assert(not SRTI_LootButton:IsShown())
    fireEvent('PARTY_LOOT_METHOD_CHANGED'); assert(not SRTI_LootButton:IsShown())
    Banana_SetEnabled(true); assert(SRTI_LootButton:IsShown())
    BANANA_CONFIG.SHOW_IN_PARTY=0; tick(); assert(not SRTI_LootButton:IsShown())
    raidCount=10; BANANA_CONFIG.SHOW_IN_RAID=0; fireEvent('RAID_ROSTER_UPDATE')
    assert(not SRTI_LootButton:IsShown())
    BANANA_CONFIG.SHOW_IN_RAID=1; fireEvent('RAID_ROSTER_UPDATE'); assert(SRTI_LootButton:IsShown())
''')
groups += 1

for enabled, option in ((0, 1), (1, 0)):
    lua = world('raid', enabled=enabled, option=option, failed_font=True)
    lua.execute('''
        assert(not SRTI_LootButton:IsShown())
        fireEvent('PARTY_LOOT_METHOD_CHANGED'); assert(not SRTI_LootButton:IsShown())
        SRTI_ApplyToolDefaults()
        assert(not SRTI_LootButton:IsShown())
        Banana_Default()
        assert(BANANA_CONFIG.SHOW_LOOT_BUTTON==1 and BANANA_CONFIG.LOOT_BUTTON_SIDE=='RIGHT')
        assert(SRTI_LootButton:IsShown())
    ''')
    groups += 1

lua = world('party')
lua.execute('''
    for layout=1,5 do
        for flip=0,1 do
            for _,side in ipairs({'LEFT','RIGHT'}) do
                BANANA_CONFIG.BUTTON_LAYOUT=layout; BANANA_CONFIG.FLIP=flip
                getglobal('SRTI_AllTools'..side):Fire('OnClick')
                assert(BANANA_CONFIG.LOOT_BUTTON_SIDE==side)
                local p=SRTI_LootButton.points[1]
                assert(p[1]==(side=='LEFT' and 'RIGHT' or 'LEFT'))
                assert(p[3]==(side=='LEFT' and 'LEFT' or 'RIGHT'))
                assert(p[4]==(side=='LEFT' and -4 or 4))
                assert(SRTI_LootButton:IsShown())
                for _,scale in ipairs({50,100,200}) do
                    BANANA_CONFIG.BUTTON_SCALE=scale; Banana_UpdateScale()
                    assert(SRTI_LootButton.scale==scale/100)
                end
            end
        end
    end
    SRTI_Side_LOOT_BUTTON_SIDE:Fire('OnClick'); assert(BANANA_CONFIG.LOOT_BUTTON_SIDE=='LEFT')
    assert(SRTI_ToolOptions:GetHeight()==486 and BananaConfigFrame:GetHeight()==557)
    local count=table.getn(frameObjects)
    SRTI_InitTools(); assert(table.getn(frameObjects)==count)
''')
groups += 1

for group in ('party', 'raid'):
    lua = world(group, failed_font=True)
    lua.execute('''
        for _,pair in ipairs({{'自由拾取','freeforall'},{'轮流拾取','roundrobin'},
            {'队伍拾取','group'},{'需求优先','needbeforegreed'}}) do
            SRTI_LootButton:Fire('OnClick','LeftButton')
            local previous=SRTI_LootButton.label:GetText()
            clickMenu(pair[1])
            local request=lootRequests[table.getn(lootRequests)]
            assert(request[1]==pair[2] and table.getn(request)==1)
            assert(SRTI_LootButton.label:GetText()==previous, 'optimistic display before acknowledgement')
            lootMethod=pair[2]; fireEvent('PARTY_LOOT_METHOD_CHANGED')
        end
        assert(table.getn(lootRequests)==4)
        SRTI_LootButton:Fire('OnClick','LeftButton')
        if raidCount>0 then raidLeader=false; raidOfficer=true else partyLeader=false end
        -- A stale enabled item must still fail the selection-time permission check.
        menuItem('自由拾取').func(); assert(table.getn(lootRequests)==4)
        SRTI_LootButton:Fire('OnClick','LeftButton')
        for i=2,6 do assert(menuRows[i].disabled==1) end
        assert(not clickMenu('队长分配') and table.getn(lootRequests)==4)
        raidLeader=true; partyLeader=true
        SRTI_LootButton:Fire('OnClick','LeftButton')
        partyCount=0; raidCount=0; fireEvent('RAID_ROSTER_UPDATE')
        assert(not UIDROPDOWNMENU_OPEN_MENU and not SRTI_LootButton:IsShown())
    ''')
    groups += 1

lua = world('party', failed_font=True)
lua.execute('''
    units.player={name='Self'}; units.party1={name='Member1'}; units.party2={name='Member2'}
    SRTI_LootButton:Fire('OnClick','LeftButton'); clickMenu('队长分配')
    assert(table.getn(lootRequests)==0 and UIDROPDOWNMENU_OPEN_MENU=='SRTI_LootMenu')
    local stale=menuItem('Member1').func
    units.party1={name='Replacement'}; stale()
    if SRTI_MenuRefresh:GetScript('OnUpdate') then SRTI_MenuRefresh:Fire('OnUpdate') end
    assert(table.getn(lootRequests)==0 and menuItem('Replacement'))
    clickMenu('Member2')
    assert(lootRequests[1][1]=='master' and lootRequests[1][2]=='Member2')
    assert(not UIDROPDOWNMENU_OPEN_MENU and SRTI_LootButton.label:GetText()=='队伍')
    lootMethod='master'; fireEvent('PARTY_LOOT_METHOD_CHANGED')
    assert(SRTI_LootButton.label:GetText()=='队长')
    SRTI_LootButton:Fire('OnClick','LeftButton'); clickMenu('队长分配'); clickMenu('Self')
    assert(lootRequests[2][2]=='Self')
''')
groups += 1

lua = world('raid', failed_font=True)
lua.execute('''
    raidCount=40
    for i=1,40 do units['raid'..i]={name='Raider'..i} end
    SRTI_LootButton:Fire('OnClick','LeftButton'); clickMenu('队长分配')
    for page=1,4 do
        assert(table.getn(menuRows)<=14) -- Below the native 32-row menu limit.
        assertNoMenuChecks()
        assert(menuItem('Raider'..((page-1)*10+1)))
        assert(menuItem('Raider'..(page*10)))
        if page<4 then clickMenu('下一页') end
    end
    clickMenu('上一页'); assert(menuItem('Raider21'))
    clickMenu('下一页'); clickMenu('Raider40')
    assert(lootRequests[1][1]=='master' and lootRequests[1][2]=='Raider40')
    SRTI_LootButton:Fire('OnClick','LeftButton'); clickMenu('队长分配')
    clickMenu('返回分配方式'); assert(menuItem('需求优先'))
''')
groups += 1

lua = world('party', failed_font=True)
lua.execute('''
    toolButtons={READY_BUTTON=SRTI_ReadyButton,COUNTDOWN_BUTTON=SRTI_CountdownButton,LOOT_BUTTON=SRTI_LootButton,
        SAVE_BUTTON=SRTI_SaveBtn,CLEAR_BUTTON=SRTI_ClearButton,RESET_BUTTON=SRTI_ResetButton,SETTINGS_BUTTON=SRTI_SettingsButton}
    function checkOrder(side)
        local previous=nil; local rank=0
        for _,id in ipairs(BANANA_CONFIG.TOOL_ORDER) do
            if BANANA_CONFIG[id..'_SIDE']==side and BANANA_CONFIG['SHOW_'..id]==1 then
                rank=rank+1
                assert(getglobal('SRTI_Position_'..id):GetText()=='第'..rank..'位')
                if previous then assert(toolButtons[id].points[1][2]==previous, 'wrong physical tool chain') end
                previous=toolButtons[id]
            end
        end
    end
    for layout=1,5 do
        for flip=0,1 do
            BANANA_CONFIG.BUTTON_LAYOUT=layout; BANANA_CONFIG.FLIP=flip
            for _,side in ipairs({'LEFT','RIGHT'}) do
                getglobal('SRTI_AllTools'..side):Fire('OnClick')
                for _,id in ipairs({'READY_BUTTON','SAVE_BUTTON','LOOT_BUTTON','RESET_BUTTON','CLEAR_BUTTON','COUNTDOWN_BUTTON','SETTINGS_BUTTON'}) do
                    getglobal('SRTI_Position_'..id):Fire('OnClick'); clickMenu('第1位（最靠近标记）')
                    assert(BANANA_CONFIG.TOOL_ORDER[1]==id); checkOrder(side)
                    getglobal('SRTI_Position_'..id):Fire('OnClick'); clickMenu('第2位')
                    assert(BANANA_CONFIG.TOOL_ORDER[2]==id); checkOrder(side)
                    getglobal('SRTI_Position_'..id):Fire('OnClick'); clickMenu('第7位')
                    assert(BANANA_CONFIG.TOOL_ORDER[7]==id); checkOrder(side)
                end
            end
        end
    end
    -- Moving one side must preserve the other side's relative order.
    SRTI_AllToolsRIGHT:Fire('OnClick')
    SRTI_Side_READY_BUTTON_SIDE:Fire('OnClick'); SRTI_Side_COUNTDOWN_BUTTON_SIDE:Fire('OnClick')
    local firstLeft=table.concat({SRTI_ReadyButton.points[1][2]:GetName(),SRTI_CountdownButton.points[1][2]:GetName()},':')
    SRTI_Position_CLEAR_BUTTON:Fire('OnClick'); clickMenu('第1位（最靠近标记）')
    assert(table.concat({SRTI_ReadyButton.points[1][2]:GetName(),SRTI_CountdownButton.points[1][2]:GetName()},':')==firstLeft)
    checkOrder('LEFT'); checkOrder('RIGHT')
    SRTI_Option_SHOW_SAVE_BUTTON.checked=false; SRTI_Option_SHOW_SAVE_BUTTON:Fire('OnClick')
    assert(SRTI_Position_SAVE_BUTTON:GetText()=='已关闭' and SRTI_Position_SAVE_BUTTON.disabled)
    checkOrder('RIGHT')
    SRTI_Option_SHOW_SAVE_BUTTON.checked=true; SRTI_Option_SHOW_SAVE_BUTTON:Fire('OnClick')
    assert(not SRTI_Position_SAVE_BUTTON.disabled); checkOrder('RIGHT')
    savedOrder=table.concat(BANANA_CONFIG.TOOL_ORDER,':')
    SRTI_ApplyToolDefaults(); Banana_Layout()
    assert(table.concat(BANANA_CONFIG.TOOL_ORDER,':')==savedOrder)
    BANANA_CONFIG.TOOL_ORDER={'CLEAR_BUTTON','invalid','CLEAR_BUTTON'}
    SRTI_ApplyToolDefaults()
    assert(table.getn(BANANA_CONFIG.TOOL_ORDER)==7 and BANANA_CONFIG.TOOL_ORDER[1]=='CLEAR_BUTTON')
    Banana_Default()
    assert(table.concat(BANANA_CONFIG.TOOL_ORDER,':')=='READY_BUTTON:COUNTDOWN_BUTTON:LOOT_BUTTON:SAVE_BUTTON:CLEAR_BUTTON:RESET_BUTTON:SETTINGS_BUTTON')
    assert(BananaConfigFrame:GetWidth()==704 and SRTI_ToolOptions:GetWidth()==380)
''')
groups += 1

persisted = lua.globals().savedOrder.split(':')
restored = world('party', order=persisted, failed_font=True)
assert list(restored.globals().BANANA_CONFIG.TOOL_ORDER.values()) == persisted
groups += 1

lua = world('party', failed_font=True)
lua.execute('''
    partyCount=1; units.player={name='Self'}; units.party1={name='Member1'}
    SRTI_LootButton:Fire('OnClick','LeftButton')
    assert(getglobal(menuItem('队伍拾取').native:GetName()..'Check'):IsShown())
    clickMenu('队长分配')
    assertNoMenuChecks() -- The old master-loot row is reused for the Back row here.
    clickMenu('返回分配方式')
    assert(getglobal(menuItem('队伍拾取').native:GetName()..'Check'):IsShown())
    for _,row in ipairs(menuRows) do
        if row.text~='队伍拾取' then assert(not getglobal(row.native:GetName()..'Check'):IsShown()) end
    end
    SRTI_LootMenu.selectedID=4; SRTI_LootMenu.selectedValue='stale'; SRTI_LootMenu.selectedName='stale'
    clickMenu('队长分配'); assertNoMenuChecks()
    assert(not SRTI_LootMenu.selectedID and not SRTI_LootMenu.selectedValue and not SRTI_LootMenu.selectedName)
    SRTI_Position_CLEAR_BUTTON:Fire('OnClick'); clickMenu('第1位（最靠近标记）')
    SRTI_Position_RESET_BUTTON:Fire('OnClick')
    local checks=0
    for _,row in ipairs(menuRows) do
        if getglobal(row.native:GetName()..'Check'):IsShown() then checks=checks+1 end
    end
    assert(checks==1, 'position menu must only check its own current position')
''')
groups += 1

lua = world('party', failed_font=True)
lua.execute('''
    local function queuePicker()
        SRTI_LootButton:Fire('OnClick','LeftButton')
        menuItem('队长分配').func()
        assert(SRTI_MenuRefresh:GetScript('OnUpdate'))
    end
    queuePicker(); Banana_SetEnabled(false); SRTI_MenuRefresh:Fire('OnUpdate')
    assert(not UIDROPDOWNMENU_OPEN_MENU and not SRTI_MenuRefresh:GetScript('OnUpdate'))
    Banana_SetEnabled(true)
    queuePicker(); partyCount=0; fireEvent('PARTY_MEMBERS_CHANGED'); SRTI_MenuRefresh:Fire('OnUpdate')
    assert(not UIDROPDOWNMENU_OPEN_MENU and not SRTI_MenuRefresh:GetScript('OnUpdate'))
    partyCount=2; fireEvent('PARTY_MEMBERS_CHANGED'); queuePicker()
    SRTI_Position_CLEAR_BUTTON:Fire('OnClick')
    assert(UIDROPDOWNMENU_OPEN_MENU=='SRTI_OrderMenu' and not SRTI_MenuRefresh:GetScript('OnUpdate'))
''')
groups += 1

print(f'PASS: {groups} SRTI behavior groups; compact modes, permission/acknowledgement checks, '
      '40-member master-loot pagination, native checkbox reuse/queue cancellation, '
      'per-side ordering across 20 layouts/sides, strict font fallback')
