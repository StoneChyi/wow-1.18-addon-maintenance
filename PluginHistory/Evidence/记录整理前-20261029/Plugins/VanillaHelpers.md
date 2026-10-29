# VanillaHelpers 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/VanillaHelpers.md)

## 插件概况

- 组件：`VanillaHelpers`，根目录运行依赖；不属于 `Interface/AddOns` 插件目录，不纳入原有 105 项或新增插件统计。
- 维护状态：**有维护记录**

## 当前维护摘要

恢复仓库保存的 VanillaHelpers.dll，撤下本次外部更新带入的 TexBridge 扩展版。回退文件与仓库原始字节一致；启动黑屏、Alt+Tab 和退出耗时尚待回退后游戏验收。

## 逐次修改记录

<a id="change-VanillaHelpers-20261025-01"></a>

### 2026-10-25｜按用户要求回退到仓库旧版

- 记录编号：`VanillaHelpers-20261025-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户更新 `D:\下载\dxvk.zip` 后反馈启动期间黑屏但能进入游戏、Alt+Tab 无法切换、关闭额外等待约 10 秒；随后明确要求按仓库旧版回退。
- 修改内容：从维护前提交 [`78f1c4d1`](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/78f1c4d182430951859788857ac4e612fa233822) 读取原始 blob 并恢复 `VanillaHelpers.dll`，不重写配置、不部署其他候选 DLL。本次更新原先未提交，恢复后这些运行文件与 HEAD 相同，回退事实由本记录保留。
- 涉及文件：`VanillaHelpers.dll`；本页、[回退报告](../Research/DXVK与VanillaHelpers-回退-20261025.md)及运行依赖索引。索引工具增加独立运行依赖列表，原插件集合及历史证据保留。
- 关联功能：DXVK 图形转换、着色器编译、窗口切换；VanillaHelpers 内存与纹理扩展。三个更新文件一起撤回，不能用回退结果区分单独责任。
- 检查结果：回退前确认游戏进程未运行；先将三个更新文件及相关诊断日志备份到本地忽略目录，再逐字节恢复；恢复后 SHA-256 与仓库 blob 一致，配置保持仓库编码及换行。`UnitXP_SP3.dll`、`wsloot.dll` 和 `dlls.txt` 回退前后哈希一致。完整哈希见回退报告；维护索引及覆盖、链接检查另行执行并记录于报告。
- 游戏验收与未确认：本次没有启动游戏；尚不能宣称黑屏、Alt+Tab 或退出慢已修复。现有日志属于更新版，不能作为旧版验收。退出约 10 秒的根因仍未定案。

## 早期历史汇总与维护依据

本页从 2026-10-25 开始记录根目录组件维护。恢复来源为仓库保存的个人使用版，不据此称为官方干净原包；没有伪造以前的修改或验收记录。

## 待补充

完整重启游戏，检查启动、Alt+Tab 和退出耗时；用户反馈应以实际确认日期新增记录。

## 依据

- [本次核对与回退报告](../Research/DXVK与VanillaHelpers-回退-20261025.md)
- [2026-10-07 退出崩溃排查](../Evidence/reports/退出崩溃排查-20261007.md)：历史排查线索，不代表本次 10 秒延迟已经定因。
