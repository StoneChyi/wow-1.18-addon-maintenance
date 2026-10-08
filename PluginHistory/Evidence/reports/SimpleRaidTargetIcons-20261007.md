# SimpleRaidTargetIcons 更新说明

已经修改当前游戏目录内的插件。进入游戏执行 `/reload`，然后点击聊天快捷栏的“标”或输入 `/srti`。

## 新增功能

- 标记栏、侧边目标标记和快捷标记圆环统一改用去掉外部黑色描边的透明图集。骷髅眼窝等内部细节保留；原图标文件保留。
- 猎人印记图标有独立显示开关；关闭后图标及其血条隐藏，工具按钮贴齐其余标记。
- 每个工具（包括“存 / 还原”）可以分别选择放在标记左侧或右侧；提供“工具全部放左侧 / 右侧”按钮。位置按屏幕方向计算，反向排列标记时也保持所选左右侧。
- 血条重新设计为高对比的实色填充、黑色底槽和四分位刻度；高度增加，百分比独立显示在血条上方。
- 掉血时当前血条立即缩短，黄色区段短暂保留刚损失的生命，再收缩消失。回血、换目标、目标消失、死亡或关闭血条时清理该区段。
- 血条宽度可在 36、44、52 间切换，默认 44；标记间距和名字限宽随之调整。
- “存 / 还原”按钮有独立开关，隐藏后保留原有标记记录。
- 标记目标存在且可读取时，图标下显示血条及百分比。目标消失时隐藏；死亡时显示零血量。
- 短姓名默认关闭；开启后限制在图标宽度内，长名字省略，悬停显示完整姓名和生命读数。
- 左侧增加“位”（就位确认）、“倒”（5 秒开怪倒数）。右侧增加“清”（清除标记）、“重”（重置副本）、“设”（设置）。每项可分别关闭。
- 重置副本在游戏内确认后执行，并检查战斗、副本内状态及队长权限；就位和倒数检查队伍及权限。
- 聊天快捷栏新增“标”进入设置；原 AutoMarker 的“标”改为“自”。聊天栏骰子右键菜单可隐藏新入口。
- 新按钮跟随整体缩放、布局反向及分组显示条件。多行布局自动为血条和短姓名增加行间距。
- 调整按钮位置和血条尺寸后恢复已保存的拖动位置。

## 使用与兼容

- 血条默认开启、姓名默认关闭。设置右栏可以调整这些选项。
- 保留原来的标记、寻标、拖动、保存和还原操作。
- 有 SuperWoW 时使用 `mark1` 至 `mark8` 读取标记单位；没有它时显示当前目标、鼠标指向、队伍成员及其目标等可读取单位的生命。
- 保存标记兼容 SuperWoW 从 `UnitExists` 第二返回值提供 GUID 的方式，不再必须存在 `UnitGUID` 函数。
- 保存的是单位 GUID。重置副本产生新单位时，旧记录不保证可以还原，需重新保存。
- 生命读数取自客户端提供的值；原生客户端有时只提供敌方单位的百分比。

## 修改与回退

修改文件：

- `Interface/AddOns/SimpleRaidTargetIcons/Banana.lua`
- `Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc`
- 新增 `Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua`
- 新增 `Interface/AddOns/SimpleRaidTargetIcons/IconTextures.lua`，以及 `img/srti_icons_borderless.png` 与客户端使用的 `img/srti_icons_borderless.tga`
- `Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua` 的快捷标记菜单也接入新图集
- `Interface/AddOns/S_ChatBar/ChatBar.lua`

修改前备份在 `E:/1.18/addons_tmp/srti-tools-backup-20261007`。如需回退，关闭游戏后，用备份里的 `SimpleRaidTargetIcons` 恢复原插件，并将备份的 `ChatBar.lua` 放回 `Interface/AddOns/S_ChatBar`。

本次按钮位置、血条重设计和猎人印记开关修改前的增量备份在 `E:/1.18/addons_tmp/srti-layout-health-backup-20261007`，包含当时的 `Banana.lua` 和 `RaidTools.lua`。

图标去黑边修改前的增量备份在 `E:/1.18/addons_tmp/srti-borderless-backup-20261007`，包含当时的 `Banana.lua`、`SimpleRaidTargetIcons.lua` 和 `.toc`。图像处理方式与最终提示词见 [图标处理记录](SimpleRaidTargetIcons-borderless-icons-20261007.md)。

## 验证

通过 Lua 语法及 XML 解析检查，并以模拟客户端验证加载、原配置开关、目标血量变化、死亡/消失、中文截断、各布局与缩放、分组隐藏、权限检查、倒数结束/取消、GUID 保存/还原，以及聊天栏旧配置迁移和按钮点击。

追加验证了黄色掉血区段的保留、衰减及清理；三个血条宽度、姓名限宽；五种布局及反向排列下的单独/批量左右位置；猎人图标隐藏与重新贴齐；调整设置后保存位置恢复。

去黑边图集已做视觉检查，并验证客户端素材为 256×256、未压缩的 32 位 RGBA TGA，透明通道有效；九个图标的贴图坐标为正方形窗口，各自居中，避免拉伸。上述模拟功能测试继续通过。

未在运行中的游戏内验证实际画面、服务器重置与就位响应。需要重载后检查实际游戏效果。

参考： [SuperWoW 项目文档](https://github.com/balakethelock/SuperWoW)；团队工具排列参考用户提出的露露插件形式，按 1.12 客户端已有能力实现。
