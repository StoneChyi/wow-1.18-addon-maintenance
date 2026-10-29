# CoreBridge 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/CoreBridge.md)

## 插件概况

- 组件：`CoreBridge`
- 维护状态：**有维护记录**

## 当前维护摘要

已恢复旧个人版 corebridge.dll 文件；旧个人版没有独立 CoreBridge 插件目录，dlls.txt 也未启用它，因此保持原有未启用状态。

## 逐次修改记录

<a id="change-CoreBridge-20261025-01"></a>

### 2026-10-25｜按用户要求恢复此前个人版

- 记录编号：`CoreBridge-20261025-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户明确要求恢复此前缺失的 CoreBridge DLL 与对应旧个人版状态。
- 修改内容：从个人提交 2b32b11814dc611bca97c0c125be773fd50fa71f 恢复根目录 DLL，843986 字节；SHA256 `61381c8f6f6e63ce1c16c1cc6af024e0cabe8107db1c0db549502bc704c296c3`。
- 涉及文件：根目录 `corebridge.dll`；不新增独立插件，不改 dlls.txt。
- 关联功能：旧 DLL 含内置 Lua/节流功能；恢复文件不等于已运行或已启用它。旧记录涉及节流兼容性，不能借本次恢复声称问题已解决。
- 检查结果：DLL 字节与旧提交一致；基准中不存在 CoreBridge 插件目录，当前也不存在；加载清单与旧提交相同且没有 CoreBridge 项。全体 21 个根目录 DLL 已与该基准一致。
- 游戏验收与未确认：本次没有加载 DLL 或启动游戏，不宣称 CoreBridge 功能通过实机测试。
- 详细依据：[本次恢复报告](../Research/UnitXP与CoreBridge个人版恢复-20261025.md)。

## 早期历史汇总与维护依据

此前文件来自已记录个人使用版；本条不追认最早作者、官方原版身份或历史验收。

## 待补充

实际启动与功能验收；早期作者及官方源码对应关系不作追认。

## 依据

- [本次恢复报告](../Research/UnitXP与CoreBridge个人版恢复-20261025.md)
