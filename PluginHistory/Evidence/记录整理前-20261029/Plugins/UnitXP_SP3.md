# UnitXP_SP3 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/UnitXP_SP3.md)

## 插件概况

- 组件：`UnitXP_SP3`
- 维护状态：**有维护记录**

## 当前维护摘要

已由 X2.2 恢复至已记录个人版 X2.0；配套设置插件 87 原本即与旧版一致，pfUI 的 UnitXP 模块也恢复到旧个人版。实际启动待用户验收。

## 逐次修改记录

<a id="change-UnitXP_SP3-20261025-01"></a>

### 2026-10-25｜按用户要求恢复此前个人版

- 记录编号：`UnitXP_SP3-20261025-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户明确要求 UnitXP DLL 与对应插件回到今天之前的个人版。
- 修改内容：先备份 X2.2，恢复旧 DLL 410624 字节，SHA256 `db035489a986631e8c2aacb3d26f8312912fcd577d8bd7d19ace02e2ea83a67d`。
- 涉及文件：根目录 `UnitXP_SP3.dll`；关联 `UnitXP_SP3_Addon` 与 `pfUI/modules/unitxp.lua`。
- 检查结果：DLL 与个人提交 2b32b11814dc611bca97c0c125be773fd50fa71f 原字节相同；17 个配套插件文件相同，9 个 Lua 编译和 11 个 TOC/XML 脚本引用、4 类通知分支检查通过。没有将模拟当作 DLL 实机验收。
- 游戏验收与未确认：没有自动启动游戏；启动速度、黑屏及依赖此 DLL 的各插件实际功能待用户测试。
- 详细依据：[本次恢复报告](../Research/UnitXP与CoreBridge个人版恢复-20261025.md)。

## 早期历史汇总与维护依据

此前文件来自已记录个人使用版；本条不追认最早作者、官方原版身份或历史验收。

## 待补充

实际启动与功能验收；早期作者及官方源码对应关系不作追认。

## 依据

- [本次恢复报告](../Research/UnitXP与CoreBridge个人版恢复-20261025.md)
