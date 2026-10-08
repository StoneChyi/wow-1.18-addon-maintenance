# SimpleRaidTargetIcons 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

完善标记条生命显示、团队工具和透明图标。

## 记录中的修改

- 增加血条/百分比、短姓名、掉血黄色缓冲区、三档宽度和猎人印记开关；兼容不同布局、缩放及反向排列。
- 增加就位、倒数、清标、重置副本、设置等工具，各自开关及左右位置；重置含游戏确认和权限检查。
- 接入去外描边的透明图集，保存原图，标记条、侧边和圆环保持一致。
- 修正 Banana 初始化前 OnUpdate 扫描、重复加载事件和旧禁用配置；GUID 保存/还原支持 SuperWoW。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [Banana.lua](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.lua)
- [Banana.xml](../../Interface/AddOns/SimpleRaidTargetIcons/Banana.xml)
- [IconTextures.lua](../../Interface/AddOns/SimpleRaidTargetIcons/IconTextures.lua)
- [RaidTools.lua](../../Interface/AddOns/SimpleRaidTargetIcons/RaidTools.lua)
- [SimpleRaidTargetIcons.lua](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)
- [SimpleRaidTargetIcons.toc](../../Interface/AddOns/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc)
- [img/srti_icons_borderless.png](../../Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.png)
- [img/srti_icons_borderless.tga](../../Interface/AddOns/SimpleRaidTargetIcons/img/srti_icons_borderless.tga)

## 关联插件

[S_ChatBar](S_ChatBar.md)。更新时同时检查对应入口与数据口径。

## 已回退方案及更新注意

原标记 GUID 不保证跨副本重置还原；PNG 与客户端 TGA、图集坐标必须配套。

## 验证与范围

维护报告记录 Lua/XML、素材透明通道/坐标和多组客户端模拟通过；明确没有运行中游戏实测。本次未重新执行。

## 待补充

服务器就位/重置响应、实际血条和缩放效果待游戏确认。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/SimpleRaidTargetIcons)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-20261007.md)
- [PluginHistory/Evidence/reports/SimpleRaidTargetIcons-borderless-icons-20261007.md](../../PluginHistory/Evidence/reports/SimpleRaidTargetIcons-borderless-icons-20261007.md)
- [PluginHistory/Evidence/reports/CatPotion-魔法橘子沙漏与标记报错修复-20261007.md](../../PluginHistory/Evidence/reports/CatPotion-%E9%AD%94%E6%B3%95%E6%A9%98%E5%AD%90%E6%B2%99%E6%BC%8F%E4%B8%8E%E6%A0%87%E8%AE%B0%E6%8A%A5%E9%94%99%E4%BF%AE%E5%A4%8D-20261007.md)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.lua](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.lua)
- [PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.toc](../../PluginHistory/Evidence/addons_tmp/srti-borderless-backup-20261007/SimpleRaidTargetIcons.toc)
- [PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/RaidTools.lua](../../PluginHistory/Evidence/addons_tmp/srti-layout-health-backup-20261007/RaidTools.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/ChatBar.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/ChatBar.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Banana.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/BananaConfig.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/BananaConfig.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Bindings.xml](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Bindings.xml)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Localization.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/Localization.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.lua)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/SimpleRaidTargetIcons.toc)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/helper_version.ini](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/helper_version.ini)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIGlow.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIGlow.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIRing.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/SRTIRing.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/blank.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/blank.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/cross.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/cross.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/diamond.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/diamond.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/huntermark.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/huntermark.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/moon.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/moon.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/nipple.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/nipple.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/skull.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/skull.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/square.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/square.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_mark.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_mark.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_save.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/srti_save.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/star.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/star.tga)
- [PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/triangle.tga](../../PluginHistory/Evidence/addons_tmp/srti-tools-backup-20261007/SimpleRaidTargetIcons/img/triangle.tga)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
