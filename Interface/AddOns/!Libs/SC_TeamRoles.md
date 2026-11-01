# 统一天赋与团队职责服务 v1

个人修改与维护：StoneChyi & Codex。保留插件原作者、天赋数据来源和MIT许可。

现有共享库中提供三个幂等加载文件：SC_TeamRoleData.lua（九职业静态结构）、SC_TeamRoles.lua（v1只读桥）、SC_TeamRoleService.lua（唯一查询、缓存和识别服务）。它们由七个现有插件TOC前置加载，无新增插件目录，也不依赖净界窗口或pfUI管理窗口显隐。原数据许可见SC_TeamRoleData-LICENSE.txt。

## 使用

在pfUI设置的“团队职责”入口或 `/scroles` 打开管理窗口。其他插件的修正入口转到同一处。自动读取完整天赋；混合、未识别、过期或异常信息不视为已确认职责。角色为TANK/HEALER/DAMAGER，MELEE/RANGED为独立作战方式。主坦顺位由明确修正提供，不根据天赋或血量自动编排。

临时修正和顺位只存当前组队会话内存；离队、换身份及重载后不继承旧名单。无可靠数据仍可普通治疗，职责限定宏不把未知当作非坦克。净界的忽略规则只影响驱散，不传播为治疗忽略。

## 消费者兼容API

`SC_TeamRolesProvider` 由共享service实现，保留apiVersion=1。

- `SC_TeamRoles:IsReady()`：服务可查询，不代表所有队员均已确认。
- `GetRole(unit)`：返回可靠职责、可选坦克顺位、来源；未知为nil。
- `IsTank(unit)`：true=坦克，false=已确认治疗/输出，nil=未知。
- `GetTankOrder(unit)`：有效坦克顺位或nil。
- `WarnUnavailable(addon)`：职责限定操作无数据时，每插件每次加载最多一次提示。

GetRole等只读缓存，不发送请求，不修改目标，不施法。消费者不保存第二份职责名单。

## 服务API

全局 `SC_TeamRolesService`，全部以冒号调用：

- `Acquire(owner)` / `Release(owner)`：启用或释放实际职责需求，同owner幂等。
- `Subscribe(owner, callback)` / `Unsubscribe(owner)`：数据变化通知；订阅本身不启动查询。
- `GetInfo(unitOrName)` / `GetRoster()`：返回只读记录/当前团队数组。记录可含过期信息供界面显示，不可据此绕过可靠性检查。
- `Peek(name,key,class)`：返回record、usable；无需重复Unit API，适用于已有身份校验的名单扫描。
- `IsFresh(recordOrUnit)`：检查新鲜度和身份。
- `Request(unit,owner,callback,force,priority)`：向唯一队列请求；callback(record,reason)。同目标合并，手动观察优先。失败回调record为nil。
- `Cancel(owner)`：仅撤此调用者的回调，不取消其他订阅或团队仍需的在途结果。
- `Refresh(unitOrName或nil)`：刷新一人或本队，战斗中不发送新请求。
- `SetOverride(unitOrName,role,style)`：本队修正，role=nil恢复自动。
- `SetTankOrder(unitOrName,order或nil)`：设置/清除坦克顺位。
- `GetDiagnostics()`：手动读取队列、完成、未知、错误及请求计数。
- `EnsureNativeGuard()` / `GetNativeMessageHandler()`：核心拥有原生回复保护；StatCompare只对有效可见会话同步重放，不为后台结果打开天赋页。

记录包含name/unit/key/class、role/style、confidence/provisional/source、queryState/time、overrideRole/overrideStyle/order。完整天赋tabs[tree]={points,count,message}、talents[tree][index]={rank,maximum,tier,column,message}只保留当前40人及1名额外观察目标，不写账号配置。

## 资源与协议

全局最多1个在途请求，间隔1.5秒；职责缓存180秒，观察页新鲜度30秒。完整三树节点、位置、等级、点数校验才发布，兼容实机制表符前缀和END附字段，未知扩展消息不终止会话。12秒超时后跳过该人，连续3次失败暂停60秒；旧会话有隔离期。协议没有请求编号，不能承诺绝对区分任意迟到的同名回复。

战斗中不发新请求，可接收在途结果并使用有效快照；脱战处理到期刷新。按原生队伍事件核对身份，空闲每5秒只做内存到期检查，不逐帧轮询全团Unit API。无需求/无待处理请求时关闭驱动；没有CVar修改、长期承伤采集、独立DLL或第二套本地职责同步。

离线行为/字体/原生解析器模拟与Lua5.0编译不等同实际服务器、界面和资源验收。
