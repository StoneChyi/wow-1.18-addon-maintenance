"""Regressions for the 1.12 RAID_TARGET_ICON prefix collision and pooled checks."""
import ast
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

fixture = ROOT / 'PluginHistory/Evidence/addons_tmp/test_safer_unit_menu.py'
tree = ast.parse(fixture.read_text(encoding='utf-8-sig'))
MOCK = next(ast.literal_eval(node.value.args[0]) for node in tree.body
            if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call)
            and isinstance(node.value.func, ast.Attribute)
            and node.value.func.attr == 'execute')
LEGACY_CHECKS = [ast.literal_eval(node.value.args[0]) for node in tree.body
                 if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call)
                 and isinstance(node.value.func, ast.Attribute)
                 and node.value.func.attr == 'execute'
                 and isinstance(node.value.args[0], ast.Constant)][-1]
FONT_CONTRACT = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')
ADDON = ROOT / 'Interface/AddOns/PlayerLinkEnhance/PlayerLinkEnhance.lua'

NATIVE_CONTRACT = r'''
local installFontContract = ...
local methods = getmetatable(DropDownList1).__index
local originalCreate = CreateFrame
function CreateFrame(kind, name, parent)
    local obj = originalCreate(kind, name, parent)
    obj.kind = kind
    return obj
end
installFontContract(methods, CreateFrame)
function methods:LockHighlight() self.locked = true end
function methods:UnlockHighlight() self.locked = false end
for level = 1, 3 do
    for i = 1, 32 do
        local name = 'DropDownList' .. level .. 'Button' .. i
        local text = getglobal(name .. 'NormalText')
        text.kind = 'FontString'
        text:SetFontObject('GameFontHighlightSmall')
        CreateFrame('Texture', name .. 'Check', getglobal(name)):Hide()
    end
end
local originalAdd = UIDropDownMenu_AddButton
function UIDropDownMenu_AddButton(info, level)
    originalAdd(info, level)
    local list = getglobal('DropDownList' .. (level or 1))
    local button = getglobal(list:GetName() .. 'Button' .. list.numButtons)
    button.notCheckable = info.notCheckable
    local text = getglobal(button:GetName() .. 'NormalText')
    text:SetText(info.text or '') -- Must inherit a valid font before any SetText.
    -- Native 1.12 can infer selection even when info.checked is nil/false.
    if dropdown.selectedValue == info.value and info.value then info.checked = 1 end
    button.checked = info.checked
    if info.checked then
        button:LockHighlight()
        getglobal(button:GetName() .. 'Check'):Show()
    else
        button:UnlockHighlight()
        getglobal(button:GetName() .. 'Check'):Hide()
    end
end
UnitPopupMenus.RAID_TARGET_ICON = {}
for i = 1, 8 do
    table.insert(UnitPopupMenus.RAID_TARGET_ICON, 'RAID_TARGET_' .. i)
end
table.insert(UnitPopupMenus.RAID_TARGET_ICON, 'RAID_TARGET_NONE')
function UnitPopup_ShowMenu(dropdown, which, unit, name)
    dropdown.name, dropdown.unit, dropdown.which = name or UnitName(unit), unit, which
    if UIDROPDOWNMENU_MENU_LEVEL == 1 then
        UIDropDownMenu_AddButton({text=dropdown.name, isTitle=1, notCheckable=1})
    end
    for index, value in ipairs(UnitPopupMenus[which]) do
        local info = {text=value, value=value, func=UnitPopup_OnClick,
            notCheckable=which ~= 'RAID_TARGET_ICON' and 1 or nil,
            hasArrow=value=='RAID_TARGET_ICON' and 1 or nil}
        -- Mirrors UnitPopup.lua's 1.12 prefix test: ICON matches it as well.
        if string.sub(value, 1, 12) == 'RAID_TARGET_' and targetMark == index then
            info.checked = 1
        end
        if value == 'RAID_TARGET_ICON' then headerRequestedChecked = info.checked end
        if which == 'RAID_TARGET_ICON' then info.icon = 'raid-icon' end
        UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    end
end
function CheckVisible(button) return getglobal(button:GetName() .. 'Check').shown end
function AssertHeaderClear()
    local button = Find('RAID_TARGET_ICON')
    assert(button and button.hasArrow, 'marker submenu arrow was lost')
    assert(button.notCheckable, 'marker header must remain noncheckable')
    assert(not button.checked and not CheckVisible(button) and not button.locked,
        'RAID_TARGET_ICON submenu header has a spurious check')
end
'''


def runtime(legacy=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    legacy_show = lua.globals().UnitPopup_ShowMenu
    lua.execute(NATIVE_CONTRACT, lua.execute(FONT_CONTRACT))
    if legacy:
        lua.globals().UnitPopup_ShowMenu = legacy_show
    lua.execute(ADDON.read_text(encoding='utf-8-sig'))
    lua.execute('PlayerLinkEnhance_OnLoad()')
    return lua


cases = [
    ('self menu prefix collision', '''
        targetMark=1;Open('SELF')
        assert(UnitPopupMenus.SELF[1]=='RAID_TARGET_ICON' and headerRequestedChecked==1,
            'fixture must reproduce the native prefix collision after sorting')
        AssertHeaderClear()
    '''),
    ('all marks and primary menu contexts', '''
        for _,which in ipairs({'SELF','PLAYER','PARTY'}) do
            for mark=0,8 do
                targetMark=mark>0 and mark or nil;Open(which);AssertHeaderClear()
            end
        end
    '''),
    ('selected metadata cannot check header', '''
        dropdown.selectedValue='RAID_TARGET_ICON';Open('SELF');AssertHeaderClear()
    '''),
    ('real marker child checks survive', '''
        for mark=1,8 do
            targetMark=mark;Open('RAID_TARGET_ICON',2)
            for i=1,8 do
                local button=Find('RAID_TARGET_'..i,2)
                assert(CheckVisible(button)==(i==mark), 'wrong real marker check')
                assert(button.icon=='raid-icon')
            end
        end
    '''),
    ('real markers in a first-level NPC menu', '''
        targetMark=8;Open('RAID_TARGET_ICON')
        assert(CheckVisible(Find('RAID_TARGET_8')))
        assert(not CheckVisible(Find('RAID_TARGET_1')))
    '''),
    ('pooled checked settings reused by header', '''
        UIDropDownMenu_AddButton({text='title',isTitle=1})
        UIDropDownMenu_AddButton({text='setting',value='setting',checked=1})
        assert(CheckVisible(DropDownList1Button2))
        targetMark=1;Open('SELF');AssertHeaderClear()
    '''),
    ('later settings still display their checks', '''
        targetMark=1;Open('SELF');CloseDropDownMenus()
        DropDownList1.numButtons=0;DropDownList1.maxWidth=0
        UIDropDownMenu_AddButton({text='setting',value='setting',checked=1})
        assert(CheckVisible(DropDownList1Button1) and DropDownList1Button1.checked)
    '''),
    ('OnShow also clears a late stale header check', '''
        Open('SELF');local button=Find('RAID_TARGET_ICON')
        button.checked=1;button:LockHighlight()
        getglobal(button:GetName()..'Check'):Show()
        DropDownList1:Fire('OnShow');AssertHeaderClear()
    '''),
    ('unmarked target does not gain marker checks', '''
        targetMark=nil;Open('RAID_TARGET_ICON',2)
        for i=1,8 do assert(not CheckVisible(Find('RAID_TARGET_'..i,2))) end
    '''),
    ('font preconditions and failed SetFont are enforced', '''
        local label=UIParent and UIParent:CreateFontString() or
            CreateFrame('FontString',nil,DropDownList1)
        assert(not pcall(function() label:SetText('') end))
        failedFontPaths['missing-font']=true
        assert(not label:SetFont('missing-font',12))
        assert(not pcall(function() label:SetText('preview') end))
        label:SetFontObject('GameFontHighlightSmall');label:SetText('ready')
    '''),
]

for name, script in cases:
    try:
        runtime().execute(script)
    except Exception as error:
        raise AssertionError(name) from error
runtime(legacy=True).execute(LEGACY_CHECKS)
print(f'PASS: {len(cases)} Lua 5.1 behavior groups plus archived menu regressions;')
print('simulated WoW 1.12 selection and strict fonts; game unverified.')
