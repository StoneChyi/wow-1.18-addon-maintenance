from pathlib import Path

root = Path(r'E:\1.18\Interface\AddOns\PlayerLinkEnhance')
backup = Path(r'E:\1.18\addons_tmp\unit-menu-backup-20261006')
main_path = root / 'PlayerLinkEnhance.lua'
module_path = root / 'SaferMenu.lua'
module = module_path.read_text(encoding='utf-8-sig')
main = main_path.read_text(encoding='utf-8-sig')
marker = '-- PLE_SAFER_MENU_BEGIN'
if marker in main:
    main = main[:main.index(marker)].rstrip() + '\n'
if 'Retail-inspired spacing' not in module:
    module = (backup / 'SaferMenu-before-consolidation.lua').read_text(encoding='utf-8-sig')
else:
    (backup / 'SaferMenu-before-consolidation.lua').write_text(module, encoding='utf-8')

diagnostic = '''
SLASH_PLEMENU1 = "/plemenu"
SlashCmdList.PLEMENU = function()
    DEFAULT_CHAT_FRAME:AddMessage(PLE_SAFER_MENU_LOADED and
        "头像菜单优化已加载：观察装备置顶，邀请入队独立分组。" or
        "头像菜单优化未加载。请查看插件错误提示。", 1, .85, .25)
end
'''
main += '\n' + marker + '\n' + diagnostic + '\n' + module
main += '\nPLE_SAFER_MENU_LOADED = "1.8.1-inline"\n-- PLE_SAFER_MENU_END\n'
main_path.write_bytes(main.replace('\r\n', '\n').replace('\n', '\r\n').encode('utf-8'))
# Keep a harmless file for clients that still use their cached TOC entry.
module_path.write_bytes(b'-- Menu improvements are now included in PlayerLinkEnhance.lua.\r\n')
toc_path = root / 'PlayerLinkEnhance.toc'
toc = toc_path.read_text(encoding='utf-8-sig')
toc = '\n'.join(line for line in toc.splitlines() if line.strip() != 'SaferMenu.lua') + '\n'
toc = toc.replace('1.8-safer-menu', '1.8.1-inline')
toc_path.write_bytes(toc.replace('\n', '\r\n').encode('utf-8'))
print('Menu code consolidated into the existing XML-loaded Lua file; TOC uses CRLF.')
