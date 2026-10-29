# DXVK 与 VanillaHelpers 回退记录

- 实施日期：2026-10-25（北京时间）。
- 目的：用户更新补丁后出现启动黑屏、Alt+Tab 失效和退出额外等待约 10 秒，明确要求按仓库旧版回退。
- 组件记录：[DXVK](../Runtime/DXVK.md#change-DXVK-20261025-01)、[VanillaHelpers](../Runtime/VanillaHelpers.md#change-VanillaHelpers-20261025-01)。
- 对应提交：随本条记录一并提交（见组件页 Git 历史）。

## 来源与范围

旧文件来自提交 [`78f1c4d1`](https://github.com/StoneChyi/wow-1.18-addon-maintenance/commit/78f1c4d182430951859788857ac4e612fa233822)，与其历史中的个人使用版一致。`d3d9.dll` 的内嵌版本为 `v2.5.3`；当前外部更新文件内嵌版本为 `3.1.1`。不以 Windows DLL 通用版本资源作为 DXVK 版本依据。

更新包 `D:\下载\dxvk.zip` 含三个文件，当前新 DLL 与压缩包内对应 DLL 哈希一致。新 `d3d9.dll` 含异步补丁配置键；新 VanillaHelpers 含旧版没有的 TexBridge 纹理桥接及 D3D9 Reset 探测代码。缺少构建来源与源码，不能完整确认自定义分支的全部变更，也不能只用上游发行说明代替该包的具体改动。

只恢复 `d3d9.dll`、`dxvk.conf`、`VanillaHelpers.dll`。其他 DLL 改动、插件、游戏设置、加载清单和缓存均保持原状。

## 回退前备份与字节校验

回退前确认没有 WoW / VanillaFixes / twloader 进程；备份目录为 `E:\1.18\PluginHistory\staging\dxvk-before-rollback-20261025-185724`，含三个更新文件、诊断日志副本及 `manifest.json`。该目录在 `PluginHistory/staging` 忽略范围，仅本地保留，不纳入提交或上传。

| 文件 | 更新版字节数 | 更新版 SHA-256 | 恢复后字节数 | 恢复后 SHA-256 |
| --- | ---: | --- | ---: | --- |
| `d3d9.dll` | 7,897,102 | `e1ed848685878a1faad2613a82e7d70b178ce33b052b7a45be8e06aa7078b50d` | 4,284,430 | `3d6b529dc4f7f55639aad580e81b2939ab1489cdbb9f1550dce74e41656bbf5b` |
| `dxvk.conf` | 3,969 | `b918fe987ed4a5e13fab9b0353764e249c35e2f0d72b57d6e8432feb385033ad` | 865 | `8fda9365b1fde5536e367b9064ae19065dbb8cd1229a61d4dea67a0f12f7c508` |
| `VanillaHelpers.dll` | 354,816 | `89d767733cf692d110e44a8982cfad8ae2308ffeee76cef1aa19bc1e93cec0c8` | 254,976 | `1e74ddf6484c23482550d5f9e5f9d291085c4ac538d3b3ed9d87155521841196` |

三个恢复文件均与来源提交逐字节一致；`dxvk.conf` 直接恢复 Git blob，保留旧配置的编码、BOM 状态与换行。更新版从未纳入本仓库提交，因此回退后运行文件没有新增差异；本次提交记录实际回退、检查和运行依赖索引，不为制造回退 diff 而先提交有问题的新二进制。

`UnitXP_SP3.dll` 和 `wsloot.dll` 是任务开始前已有的其他未提交修改，回退后哈希保持一致，不夹带入本次提交。`dlls.txt` 也保持原样。

## 已知线索及判断边界

- 更新配置设置 `dxvk.allowFse = true`；[上游说明](https://github.com/doitsujin/dxvk/blob/v3.1.1/dxvk.conf)警告可能破坏 Alt+Tab。这是切换异常的首要排查线索，但本次直接执行整组回退，没有单项实测，不能认定已经证明因果。
- 更新配置从 2 个编译线程变为自动选择的 8 个，并关闭图形管线库；部分配置键在当前二进制中没有对应键，不能因为日志回显而认为其功能生效。不能把关闭日志等中文注释当作已证实效果。
- 更新版图形日志成功初始化 RTX 4060 Ti / Vulkan，没有发现设备丢失错误。旧版和新版 DLL 都是 x86，未发现用错 64 位 DLL 的证据。
- 更新 VanillaHelpers 的 TexBridge 日志指出 `TextureServer64.exe` 不存在、跳过桥接挂钩，处理计数为零。配套组件缺失属实，但不能据此认定退出约 10 秒就是等待该程序导致。日志中的 15000 ms 重新探测时间也不等于已测得退出阻塞时间。
- 现有 `dlls.txt` 的 `dxvk` 无效项及以 twloader 加载 VanillaHelpers 的方式是早已有的排查线索，未在本次回退顺带修改。

## 验证与待验收

- 已通过：三文件原始字节与 SHA-256 校验、其他两个外部 DLL 及加载清单回退前后哈希核对。
- 文档验证：维护索引 build / check、覆盖及本地链接检查全部通过（107 个插件页、2 个运行依赖页、1,956 个本地链接）；现有新增插件边界回归 10 项通过；Python 语法、原插件清单和统计保持不变、已有文件 BOM 与 LF 保留、三个恢复文件与 HEAD 一致及其他 DLL 哈希保持均通过。
- 公开同步：提交前审查差异、未跟踪与删除文件；推送前运行所有可达历史上传审计，并核对目标与公开状态。备份和诊断日志不上传。
- 游戏验收：**未执行**。请完整重启游戏，分别检查启动黑屏、Alt+Tab、关闭游戏额外等待是否消失。现有日志是回退前诊断数据，不作为旧版实测依据。
