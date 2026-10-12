"""Current SRTI loot indicator behavior, including strict WoW 1.12 font prerequisites."""
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
function SetLootMethod() error('indicator must never change loot settings') end
function SendChatMessage() error('indicator must never send group messages') end
lootReads=0; lootMethod='group'
'''


def world(group='solo', enabled=1, option=None, failed_font=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
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
            assert(SRTI_LootButton:GetWidth()==82)
            if SRTI_LootButton:IsShown() then
                assert(SRTI_LootButton.label:GetText()=='队伍拾取')
                assert(SRTI_LootButton.label:GetStringWidth()<=74)
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
        local modes={freeforall='自由拾取',roundrobin='轮流拾取',master='队长分配',
            group='队伍拾取',needbeforegreed='需求优先'}
        SRTI_LootButton:Fire('OnEnter')
        for token,label in pairs(modes) do
            lootMethod=token; fireEvent('PARTY_LOOT_METHOD_CHANGED')
            assert(SRTI_LootButton.label:GetText()==label)
            assert(string.find(GameTooltip:GetText(),label,1,true))
            assert(SRTI_LootButton.label:GetStringWidth()<=74)
            local count=table.getn(messages)
            SRTI_LootButton:Fire('OnClick','RightButton'); assert(table.getn(messages)==count)
            SRTI_LootButton:Fire('OnClick','LeftButton')
            assert(string.find(messages[count+1],label,1,true))
        end
        lootMethod=nil; fireEvent('PARTY_LOOT_METHOD_CHANGED')
        assert(SRTI_LootButton.label:GetText()=='等待同步')
        lootMethod='unexpected'; tick(); assert(SRTI_LootButton.label:GetText()=='等待同步')
        lootMethod='master'; tick(); assert(SRTI_LootButton.label:GetText()=='队长分配')
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
    partyCount=2; fireEvent('PARTY_MEMBERS_CHANGED')
    assert(SRTI_LootButton:IsShown() and SRTI_SaveBtn.points[1][2]==SRTI_LootButton)
    partyCount=0; raidCount=10; fireEvent('RAID_ROSTER_UPDATE'); assert(SRTI_LootButton:IsShown())
    SRTI_LootButton:Fire('OnEnter')
    raidCount=0; fireEvent('RAID_ROSTER_UPDATE')
    assert(not SRTI_LootButton:IsShown() and not GameTooltip:IsShown())
    assert(SRTI_SaveBtn.points[1][2]==soloAnchor)
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

print(f'PASS: {groups} SRTI loot indicator groups; five methods, group lifecycle/events, '
      'saved toggles, 20 layout/side combinations, three scales, strict font failures/fallback')
