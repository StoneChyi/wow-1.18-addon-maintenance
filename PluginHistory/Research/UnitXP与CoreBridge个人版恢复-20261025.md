# UnitXP 与 CoreBridge 个人版恢复

实施日期：2026-10-25（北京时间）。状态：已恢复，等待用户游戏验收。

用户明确要求恢复 corebridge.dll、UnitXP_SP3.dll 及对应插件。基准为今天之前最后保存的个人提交 `2b32b11814dc611bca97c0c125be773fd50fa71f`；不是官方原版或零点磁盘快照。

## 已部署范围

| 项目 | 恢复前 | 当前恢复状态 |
|---|---|---|
| UnitXP_SP3.dll | X2.2，424448 字节 | X2.0，410624 字节；SHA256 db035489a986631e8c2aacb3d26f8312912fcd577d8bd7d19ace02e2ea83a67d |
| corebridge.dll | 文件缺失 | 恢复旧文件 843986 字节；SHA256 61381c8f6f6e63ce1c16c1cc6af024e0cabe8107db1c0db549502bc704c296c3 |
| UnitXP_SP3_Addon | 版本 87 | 原本即为旧个人版，17 个已记录文件逐字节核对一致，未重写 |
| pfUI/modules/unitxp.lua | 新包已删除旧通知块 | 整个单独模块恢复旧个人版，包含系统通知；其他 pfUI 文件不回退 |
| CoreBridge 插件/加载状态 | 无独立目录，dlls.txt 无加载项 | 基准同样如此，因此只恢复 DLL 文件，保持旧的未启用状态 |

本机备份：`E:\1.18\CodexBackups\unitxp-corebridge-rollback-20261025-235532`，包含更新版 UnitXP、现用 pfUI 模块、完整配套设置插件、恢复目标及 manifest.json。CoreBridge 原本缺失的状态也写入清单。日志、WTF/角色设置、缓存均未重置。

## 真实验证

- 替换前确认 WoW 未运行；恢复后逐文件字节与 SHA256 核对通过。
- 17 个配套插件文件与基准一致，9 个 Lua 编译通过，11 个 TOC/XML 脚本引用存在；XML 材质文件未误当作插件脚本引用。
- 从实际恢复模块取通知代码，启用/关闭通知、缺少战场入口、UnitXP 抛异常四类模拟分支通过。未新增或修改 FontString，也没有把客户端字体前置条件实现为空操作。
- 其他 DLL 与加载清单、dxvk.conf 未改写。恢复后根目录全部 21 个 DLL 均与该个人提交逐字节相同；CoreBridge 仍不在加载清单中。
- 由于两个 DLL 恢复到已记录 blob，Git 不出现额外 DLL 差异；本次以说明记录实际部署，未先提交有问题的新 DLL 来制造回退差异。
- 没有自动启动游戏。实际启动速度、黑屏/崩溃、距离/视线/通知与其他依赖接口待用户测试，不能用离线检查代替游戏验收。

[UnitXP DLL](../Plugins/UnitXP_SP3.md) · [配套设置插件](../Plugins/UnitXP_SP3_Addon.md) · [CoreBridge](../Plugins/CoreBridge.md) · [pfUI](../Plugins/pfUI.md)
