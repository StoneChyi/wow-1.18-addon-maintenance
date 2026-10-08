# 头像右键菜单优化（2026-10-06）

菜单增强选项来自 PlayerLinkEnhance 1.7；pfUI 的 modules/skin.lua 为共享下拉菜单添加半透明背景，api/unitframes.lua 负责头像右键打开菜单。

优化已合并进原本由 XML 加载的 PlayerLinkEnhance.lua，版本标识为 1.8.3-compact；不依赖新增 Lua 文件。

- “观察装备”固定为第一个可操作项目，蓝色文字、20 行高。
- “邀请入队”独立分组，绿色文字、20 行高，与观察选项之间留出其他常用功能和分隔空隙。
- 一般菜单项目 18 行高，1 间隙；不同分组增加 4 空隙；最低菜单宽度 140，长文字自动撑开；保留客户端默认字号。
- 使用 85% 不透明度（15% 透明度）的背景和整行高亮；保留禁用状态及团队标记子菜单。
- 屏蔽、移出小队/团队、离队增加确认；确认保存玩家名字，并在执行时重新核对成员和权限。
- 保留其他插件注册的菜单选项；关闭时还原共享下拉框，避免影响设置等菜单。

参考：[ElvUI 菜单高亮实现](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Modules/Skins/Skins.lua)与[正式服菜单分组接口说明](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua)。使用旧客户端接口实现，未安装正式服插件。

模拟检查覆盖功能回调、观察/邀请分隔、点击区域不重叠、其他菜单还原、确认取消及切换目标、成员位置变动及权限变化、标记子菜单和构建失败后的恢复。尚未在游戏内验证。

游戏中输入 `/reload` 后检查头像右键菜单；`/plemenu` 可显示优化代码的加载状态。

恢复：关闭游戏，将本目录 PlayerLinkEnhance 子目录里的三个原始文件复制回 E:/1.18/Interface/AddOns/PlayerLinkEnhance 并覆盖。恢复后的原始 TOC 不会加载 SaferMenu.lua，因此无需删除新增文件。
