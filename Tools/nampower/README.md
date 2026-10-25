# nampower 启动初始化优化（候选源码）

**2026-10-25 实际启动失败，候选已撤回。** SHA256 `f226779f...` 的候选在本机两次启动时，首个挂钩的 GetThreadContext 返回错误 31，最终触发 ERROR #132。现用 DLL 已恢复旧版。下面的独立通过结果不构成游戏兼容性保证；本目录保留用于诊断，不应继续部署此候选。

保留 4.6.1 功能和原有挂钩检查，用当前进程 PSS 线程快照替代每次扫描全系统线程。不能将独立测试通过视为游戏验收；本目录不包含部署脚本。

## 修改范围

- `include/process_threads.hpp`：C++14 线程 ID 枚举；动态解析 5 个 PSS 接口，仅优化当前进程。每次新快照；失败先清理并丢弃部分结果，再完整 Toolhelp 回退；保留退出线程的原校验语义。
- `patches/patcher_aux.hpp`：调用新枚举并保留当前线程排除、原 `IsExecutingInRange` 和 hadesmem 错误边界。编译开关关闭时仍用实际原 `ThreadList` 迭代器。
- `include/startup_metrics.hpp` 与 `prepare_sources.py`：固定容量、线程局部的启动计时，逐挂钩汇总在初始化结束后输出。原路径的 `enum_samples=0` 表示没有单独测量枚举，不能解释为零耗时。
- `tests/`：真实 C++ 可注入边界测试、原生枚举基准、实际 hadesmem 校验路径测试，以及计时开关/异常恢复/边界测试。

不改变 59 个挂钩的地址、顺序、施法队列、事件/Lua 注册；不删除线程检查、不增加全线程暂停，不修饰当前并发改写和异常回滚仍需后续评估的事实。

## 本机材料

编译器、SDK、依赖源码、日志和候选输出均在 `E:\1.18\PluginHistory\staging\nampower-build-20261025`。

- `artifacts/original/nampower.dll`：原校验路径的计时基准构建。
- `artifacts/pss/nampower.dll`：PSS 优化候选。
- 两者旁均有 PDB、MAP、输入内容清单与许可证。
- `build-时间/`：每次独立干净构建；不复用旧对象或库。

根目录现用 `nampower.dll` 保持原有文件，本工具不覆盖它。候选源码来源为公开 4.6.1 镜像，不宣称可逐字节重建用户原 DLL。

## 固定来源与许可

`build-pins.json` 固定来源与校验信息。nampower 源码提交 `2c7f51cd436e9b0ce88271e84ce5a77c19f2c23b`；hadesmem v1.7.0；其固定 asmjit `f7de7b8d...` 与 udis86 `0dc7184b...` 源码以 `/MT` 重编；Boost 1.80。保留第三方许可于 `licenses/`，发布候选时一并保留。

便携编译器使用微软官方 MSVC 14.43 host x64/target x86 VSIX 与 SDK NuGet 10.0.22621.3233，纯 ZIP 解压，不运行系统安装器、不修改全局 PATH。当前机器的 SDK 最小输入不包括全部开发组件。

完整源码 ZIP 以 SHA256 校验。按需 Range 解压的编译器/SDK/Boost仅检查 HTTPS、中央目录、成员大小和 CRC；没有下载整包，因此不能声称验证了整包 SHA256。构建时另外记录本地所有输入文件内容摘要。

## 重建

需要 Windows x64、Python 3.10+、PowerShell；所有输出指定到 E 盘。网络代理使用现有环境，或显式给 bootstrap 的 `--proxy` 参数；不会更改系统代理。首次下载前阅读 `build-pins.json` 中微软许可。

```powershell
python Tools/nampower/bootstrap.py --workspace E:\1.18\PluginHistory\staging\nampower-build-new --accept-msvc-license
python Tools/nampower/prepare_sources.py --workspace E:\1.18\PluginHistory\staging\nampower-build-new --variant original --generation reviewed
python Tools/nampower/prepare_sources.py --workspace E:\1.18\PluginHistory\staging\nampower-build-new --variant pss --generation reviewed
Tools/nampower/build.ps1 -Workspace E:\1.18\PluginHistory\staging\nampower-build-new -PreparedGeneration reviewed -Python python
```

准备目录拒绝覆盖；修改公共头后用新的 generation 重新准备。构建前验证共享头和补丁内容绑定，保存实际源码/依赖/工具链的输入清单。时间戳与 PDB 等意味着这里不承诺 bit-identical 输出。

`build.ps1 -TestsOnly` 仅编译无 Boost 测试。`-IntegrationOnly` 单独编译校验路径测试并保存独立清单，不覆盖旧 DLL 的构建清单。原生 `process_threads_test.exe` 无参数跑边界组，`--live` 跑同机独立基准；游戏候选只能在明确的备份、替换与回退范围内另行验收。

## 限制

旧 Windows 的 API 缺失由故障注入验证，尚未实机测试；并发线程可能在快照之后变化，不能把捕获 ID 当作安全改写代码的充分条件。原有线程上下文检查的限制、最终异常处理及成组恢复问题仍然存在。本轮没有声称修复黑屏或崩溃。
