from pathlib import Path

path = Path('E:/1.18/Interface/AddOns/CatPotion/Window.lua')
source = path.read_text(encoding='utf8')
start = source.index('    ui.profileMenuEntries = {}')
end = source.index('    ui.profileSwitchButton = CreateHeaderButton', start)
block = source[start:end]
assert 'local function CreateProfileMenu(' not in source, 'refactor already applied'
block = block.replace('nil, window)', 'nil, parent)')
block = block.replace('window:GetEffectiveScale()', 'parent:GetEffectiveScale()')
block = block.replace('window:GetScale()', 'parent:GetScale()')
block = block.replace('addon.SwitchPotionWindowProfile(profileId, targetId)', 'onSelect(targetId)')
old_label = '''                entry.text:SetText(target.name .. (id == profileId and "（当前）" or
                    (addon.ToBoolean(target.windowVisible) and "（已开启）" or "")))
                entry.text:SetTextColor(id == profileId and 1 or 0.86, 0.82, id == profileId and 0.2 or 0.92)'''
assert old_label in block
block = block.replace(old_label, '''                local text, red, green, blue = getAppearance(id, target)
                entry.text:SetText(text)
                entry.text:SetTextColor(red, green, blue)''')
factory = '''-- 小窗切换菜单与聊天快捷条共用分页和边缘定位，避免入口间行为不一致。
local function CreateProfileMenu(ui, parent, onSelect, getAppearance)
''' + block.rstrip() + '\nend\n\n'
replacement = '''    CreateProfileMenu(ui, window, function(targetId)
        addon.SwitchPotionWindowProfile(profileId, targetId)
    end, function(id, target)
        local text = target.name .. (id == profileId and "（当前）" or
            (addon.ToBoolean(target.windowVisible) and "（已开启）" or ""))
        return text, id == profileId and 1 or 0.86, 0.82, id == profileId and 0.2 or 0.92
    end)

'''
source = source[:start] + replacement + source[end:]
marker = 'local function CreateProfileWindow(profileId)'
assert source.count(marker) == 1
source = source.replace(marker, factory + marker, 1)
source = source.replace('        for _, other in pairs(addon.Windows) do other.profileMenu:Hide() end',
                        '        addon.HidePotionProfileMenus()', 1)
path.write_text(source, encoding='utf8', newline='\r\n')
