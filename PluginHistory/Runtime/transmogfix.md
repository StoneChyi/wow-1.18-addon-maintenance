# transmogfix 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Runtime/transmogfix.md)

## 插件概况

- 组件：`transmogfix`，根目录运行依赖。
- 维护状态：**有维护记录**

## 当前维护摘要

按用户要求由作者版 0.5.0 更新至独立发布版 0.7.0；游戏启动和功能待验收。

## 逐次修改记录

<a id="change-transmogfix-20261028-01"></a>

### 2026-10-28｜更新作者版独立 DLL 至 0.7.0

- 记录编号：`transmogfix-20261028-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求仅更新 `transmogfix.dll` 与 `weirdperformance.dll`。
- 修改内容：从作者 WeirdUtils 0.5.0 独立文件更新至 [0.7.0 发布文件](https://codeberg.org/MarcelineVQ/WeirdUtils/releases/tag/v0.7.0)；0.7.1 发布仅包含整合 DLL 和 worldmarkers 独立 DLL。
- 涉及文件：`transmogfix.dll`、本页及生成索引。更新前文件留在本机 `PluginHistory/staging/weirdutils-update-20261028/backup`，更新前 Git 提交也可回退。
- 关联功能：幻化装备耐久变化引起的外观刷新；保留加载清单及其他 DLL，未更改账号设置。
- 检查结果：旧文件 SHA-256 `ab83eef058fb5bde0869423d6b976bbb0eeeb0b60df2cb51a741965d3767514b`；安装文件 SHA-256 `cd9e4c6ce033b0923cf045269f590f5e0b886bd03f43bd81406670d781452210`，与此前从作者发布页下载的文件一致；发布 API 未提供官方摘要。静态检查为 x86 PE32 DLL，只导入 KERNEL32；安装前进程检查未见游戏客户端。
- 游戏验收与未确认：没有运行游戏验证实际加载、启动性能或功能；性能模块与其他组件存在潜在重叠，不推定冲突。

## 早期历史汇总与维护依据

<details>
<summary>展开早期原始说明与证据</summary>

更新前文件与作者 0.5.0 发布文件摘要一致；此前个人使用和最早安装时间未确认。

## 待补充

完全重启后的 DLL 加载、幻化、插件计时及性能表现。

## 依据

- [作者 WeirdUtils 0.7.0 发布页](https://codeberg.org/MarcelineVQ/WeirdUtils/releases/tag/v0.7.0)
- [仓库内 DLL](../../transmogfix.dll)

</details>
