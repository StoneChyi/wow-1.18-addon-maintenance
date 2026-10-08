# pfUI 技能栏监控初始化兼容修复

确认日期：2026-10-09。

## 目的与原因

用户反馈头像、小地图恢复原版样式，插件按钮收纳失效；删除 HideOutdoorWorldState 后仍然存在。游戏内执行已有技能栏的 UpdateConfig 得到 actionbar.lua:2436 的 GetOwner 不存在错误。技能栏模块初始化中断，使后续头像、小地图和按钮收纳模块未加载。

## 修改

- Interface/AddOns/pfUI/modules/actionbar.lua：技能栏监控配置改用客户端支持的 GameTooltip:IsOwned(button)，跳过缺失按钮，保留隐藏监控提示开关及其他窗口提示。
- Interface/AddOns/pfUI/tests/monitor-tooltip-owner.lua：离线读取真实配置函数，用 Lua 5.1 模拟旧客户端提示接口。
- 保留生产文件原始编码、BOM 状态和 LF 换行。未重置用户设置，未恢复用户已删除的 HideOutdoorWorldState。

## 验证

- 旧文件在缺少 GetOwner 的模拟环境中重现用户报错。
- 修改后通过监控自身提示、其他窗口提示、无所有者、关闭隐藏开关、停用监控、缺失按钮六项模拟检查。
- 完整 actionbar.lua 通过 Lua 5.1 语法检查；git diff --check 通过。
- 用户于 2026-10-09 执行 /reload 后明确确认：头像、小地图和按钮收纳三项都恢复正常。

## 范围与未确认事项

本次确认了上述初始化故障及恢复；隐藏东瘟疫之地哨塔计数的原始需求尚未在本次修复中重新实施。未将本次检查扩大解释为所有 pfUI 功能或全部监控方案已完成游戏实测。
