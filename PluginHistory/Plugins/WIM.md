# WIM 修改说明

整理日期：2026-10-09。状态：**有维护记录**。

[返回全部插件索引](README.md) · [待补充清单](../待补充清单.md)

核对基准：仓库提交 `4feabd85022b` 中的个人使用版。它已包含早期修改，不是官方原版；本页是历史整理，不表示今天重新实施了下面的功能。

## 修改目的

保持私聊界面可见，同时避免收到消息抢按键。

## 记录中的修改

- 早期增加单/多窗口设置和发送密语路由，修正联系人关闭对象、会话切换及消息多时的性能。
- 2026-10-08 联系人面板提升前景层级，打开或切换依附窗口时置前，保留原拖动边界。
- 收到消息不自动夺取输入焦点；手动进入私聊后发送可继续输入，关闭、点击外部或 ESC 释放焦点。
- 单窗口其他来信不切走正在编辑的会话，改为未读提示；旧配置迁移及中英文设置文本同步。

历史笔记可能来自迁移前的客户端目录。下列入口已核对为本仓库保存的文件；这能定位维护对象，不能代替每一项修改与官方原版的完整差异。

## 主要维护入口

以下是重点入口及有文件级变更依据的文件，不表示每个文件的每一行都是个人修改。

- [WIM.lua](../../Interface/AddOns/WIM/WIM.lua)
- [WIM.xml](../../Interface/AddOns/WIM/WIM.xml)
- [WIM_Hooks.lua](../../Interface/AddOns/WIM/WIM_Hooks.lua)
- [WIM_Options.lua](../../Interface/AddOns/WIM/WIM_Options.lua)
- [WIM_contact.lua](../../Interface/AddOns/WIM/WIM_contact.lua)
- [localization.cn.lua](../../Interface/AddOns/WIM/localization.cn.lua)
- [localization.lua](../../Interface/AddOns/WIM/localization.lua)

## 已回退方案及更新注意

早期自动聚焦设置与 10-08 的防抢焦点目标冲突时，以后者及配置迁移为准。

## 验证与范围

10-08 输入焦点完成报告记录语法及模拟测试通过，联系人置前未做游戏验收。本次未重新执行插件测试。

## 待补充

战斗按键、连续回复、ESC/外部点击和其他界面覆盖情况请补充游戏验收。

## 依据

- [初始化插件清单（历史快照，未改写其原始证据标记）](../../PluginHistory/addon-catalog.json)
- [历史归档来源与校验索引](../../PluginHistory/history-index.json)
- [仓库内插件目录（目录缺失时查看核对基准提交）](../../Interface/AddOns/WIM)
- [Interface/AddOns/WIM/.workbuddy/memory/2026-09-15.md](../../Interface/AddOns/WIM/.workbuddy/memory/2026-09-15.md)
- [Interface/AddOns/WIM/.workbuddy/memory/2026-09-18.md](../../Interface/AddOns/WIM/.workbuddy/memory/2026-09-18.md)
- [PluginHistory/Research/维护聊天摘录-20261009.json](../../PluginHistory/Research/%E7%BB%B4%E6%8A%A4%E8%81%8A%E5%A4%A9%E6%91%98%E5%BD%95-20261009.json)
- [PluginHistory/Evidence/CodexBackups/WIM/contacts-20261008](../../PluginHistory/Evidence/CodexBackups/WIM/contacts-20261008)
- [PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008](../../PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008)
- [PluginHistory/Evidence/addons_tmp/test_wim_input_focus.py](../../PluginHistory/Evidence/addons_tmp/test_wim_input_focus.py)
- [PluginHistory/Evidence/CodexBackups/WIM/contacts-20261008/WIM.lua](../../PluginHistory/Evidence/CodexBackups/WIM/contacts-20261008/WIM.lua)
- [PluginHistory/Evidence/CodexBackups/WIM/contacts-20261008/WIM_contact.lua](../../PluginHistory/Evidence/CodexBackups/WIM/contacts-20261008/WIM_contact.lua)
- [PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/WIM.lua](../../PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/WIM.lua)
- [PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/WIM.xml](../../PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/WIM.xml)
- [PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/localization.cn.lua](../../PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/localization.cn.lua)
- [PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/localization.lua](../../PluginHistory/Evidence/CodexBackups/WIM/input-focus-20261008/localization.lua)

没有完整官方原版、没有依据的改动日期与作者均不作推断；阶段备份只用于审查，不宜整份覆盖新版。
