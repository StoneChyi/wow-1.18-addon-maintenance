# 统一团队职责读取接口 v1

个人修改与维护：StoneChyi & Codex。保留现有库的原作者与许可。

`SC_TeamRoles.lua` 是 NotGrid、QuickHeal、GoubayuHeal 共用的被动查询桥，不包含职责编辑、名单保存、识别扫描、网络协议、窗口或计时器。三个插件通过 TOC 直接加载同一文件；重复加载保留同一个接口及提示状态，不要求启用 `!Libs` 的整套库。

当前未安装职责提供者时，所有职责均为未知。旧插件名单不作为后备，不能把未知当作输出或非坦克。普通治疗继续运行；明确要求职责范围的调用缺少有效数据时停止，不扩大治疗范围。

未来统一服务可公开以下对象，方法使用冒号调用：

```lua
SC_TeamRolesProvider = {
    apiVersion = 1,
    IsReady = function(self) return true end, -- 可省略；必须无副作用
    GetRole = function(self, unit)
        -- 仅返回当前队伍中身份匹配、未过期的结果；未知返回 nil。
        -- role: "TANK" / "HEALER" / "DAMAGER"
        -- tankOrder: 坦克顺位 1..40，未知可为 nil；其余职责不用顺位。
        -- source: 可选来源说明。
        return nil
    end,
}
```

提供者负责当前队伍身份校验、数据来源与失效机制。`GetRole` 必须只读缓存，不能在查询时发起网络请求、修改目标或施法。桥不复制提供者的数据，也不在各插件保存第二份名单。替换／撤销提供者后立即按新对象查询。

消费者使用：

- `SC_TeamRoles:IsReady()`：提供者是否可查询，不表示每名队员都有已知职责。
- `SC_TeamRoles:GetRole(unit)`：返回职责、可选坦克顺位、来源；不存在的单位、异常、无效职责均返回 nil。
- `SC_TeamRoles:IsTank(unit)`：坦克为 true，已确认治疗／输出为 false，未知为 nil。
- `SC_TeamRoles:GetTankOrder(unit)`：返回有效的坦克顺位，否则 nil。
- `SC_TeamRoles:WarnUnavailable(addon)`：用户执行职责限定操作失败时使用，每插件每次加载最多提示一次，不在后台输出。

普通治疗不因未知职责而跳过该队员；职责限定模式只能接受符合条件的已知队员。桥校验格式并保护异常，不代表服务端职责或数据真实性已经得到验证。

后续职责管理端应集中提供识别、必要修正、队伍生命周期和协议同步。此桥没有跨客户端同步能力，也不为任何旧分工系统提供自动迁移或私有协议后备。
