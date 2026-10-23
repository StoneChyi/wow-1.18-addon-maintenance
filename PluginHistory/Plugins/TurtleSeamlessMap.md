# TurtleSeamlessMap 修改说明

[插件修改记录](README.md) · [记录规范](../记录规范.md) · [本页 Git 历史](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commits/main/PluginHistory/Plugins/TurtleSeamlessMap.md)

## 插件概况

- 插件：`TurtleSeamlessMap`，独立新增，版本 0.1.0。
- 维护状态：**有维护记录**。

## 当前维护摘要

独立接管常见默认地图入口，提供世界连续缩放、拖动和完整区域浏览。当前客户端 173 图页、3,551 张贴图提取检查通过；适配 ModernMapMarkers 标记与 Atlas 跳转、pfQuest 节点显示和点击。原插件文件未修改；实际游戏验收及美术接缝优化待补充。

2026-10-24 用户已确认长期公开分享，并授权同步首版提交及后续维护说明；此前因可见性变化等待授权的状态已解除。

## 逐次修改记录

<a id="change-TurtleSeamlessMap-20261024-02"></a>

### 2026-10-24｜确认公开分享与持续自动同步授权

- 记录编号：`TurtleSeamlessMap-20261024-02`
- 记录类型：范围确认
- 游戏验收：不适用（说明或停用记录）
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户明确授权上传当前公开仓库，要求以后保持公开，便于其他玩家使用优化的插件。
- 修改内容：将项目规则、仓库首页和 GitHub 同步说明更新为长期公开分享、检查后自动同步；解除 `TurtleSeamlessMap-20261024-01` 的可见性授权等待，纳入首版提交 `42868e892829bf92cd7c87fd197a4d438ef1031d` 及本条说明。
- 涉及文件：AGENTS.md、README.md、PluginHistory/README.md、PluginHistory/GitHub同步说明.md、本页、首版研究报告、maintenance-index.json 及生成索引。
- 关联功能：仅更改维护与发布授权，未改动插件代码、地图资源或游戏设置。
- 检查结果：审查目标仍为原仓库；按流程运行记录索引、覆盖和链接检查，并在推送前审计全部可达历史。实际同步结果以远端 main 是否包含本次提交为准。
- 游戏验收与未确认：本条不是游戏验收；首版加载、接缝、性能和第三方图层仍按上一条待验收事项处理。
- 替代关系：只替代上一条的公开上传授权等待，不改写当时尚未推送的历史事实。

<a id="change-TurtleSeamlessMap-20261024-01"></a>

### 2026-10-24｜新增独立连续地图与完整区域素材提取

- 记录编号：`TurtleSeamlessMap-20261024-01`
- 记录类型：修改
- 游戏验收：待游戏验收
- 对应提交：随本条记录一并提交（见本页 Git 历史）

- 修改原因：用户要求新建独立插件替代默认地图入口，先实现完整地图提取与整体连续缩放，并保留现有地图标记及任务标记能力。
- 修改内容：新增连续世界画布、鼠标支点缩放、平移、裁剪与贴图复用；173 个完整图页的搜索/浏览和原图模式；玩家定位、个人标记及浏览状态保存；ModernMapMarkers/Atlas 与 pfQuest 初步适配；原默认地图保留作回退。
- 涉及文件：新增插件的 TOC、MapData.lua、Geometry.lua、Core.lua、Compat.lua、Art、README 与 OpenMap 参考许可；新增 Tools/turtle_map_archive.py、Tools/build_turtle_seamless_map.py、Tools/tests/test_turtle_seamless_map.py；配套提取报告和资源指纹清单。
- 关联功能：ModernMapMarkers、Atlas、pfQuest/pfQuest-turtle、S_WorldMap、pfUI；第三方插件原文件未修改。只对明确接入的标记和任务操作作适配，不声称任意其他地图插件自动兼容。
- 检查结果：实际提取并解码 3,551 个 BLP，173 图页底图及探索覆盖层缺失为零；912 个派生贴片检查通过。14 组自动检查全部通过，含实际 Modern 数据映射与实际 pfQuest 点击函数；离线绘图预览已检查。模拟通过不等于游戏验证。
- 游戏验收与未确认：首次加载、材质显示、全区域拼接、帧率/内存及其他第三方图层待实际游戏验收；美术接缝、未映射区域和副本在独立完整图页显示。尚未完整接入旧会话手动旗标、团队图标、路线连线及全部视觉设置。
- 同步状态：核对到远端当前为公开仓库（`isPrivate=false`），与持续授权的私有同步范围不同；本次本地提交后暂不推送，等待明确同步方式。

## 早期历史汇总与维护依据

本插件于 2026-10-24 独立创建，不将 ModernMapMarkers 的既有功能或 OpenMap 项目算作本项目历史新增。

## 待补充

游戏内验收反馈；各区域接缝与色差；更多标记提供方适配。

## 依据

- [首版实现与验证报告](../Research/TurtleSeamlessMap-首版实现-20261024.md)
- [地图提取报告](../Research/TurtleSeamlessMap-地图提取-20261024.json)
- [地图资源指纹](../Research/TurtleSeamlessMap-地图资源清单-20261024.json)
- [插件目录](../../Interface/AddOns/TurtleSeamlessMap)
