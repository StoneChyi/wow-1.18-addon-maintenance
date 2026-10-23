# WoW 1.18 插件维护记录

保存本项目当前使用的插件、个人修改及历史维护依据，便于后续优化、回退和整合包更新时迁移改动。

GitHub 公开仓库：[StoneChyi/wow-1.18-addon-maintenance](https://github.com/StoneChyi/wow-1.18-addon-maintenance)。用户于 2026-10-24 确认长期公开，便于其他玩家使用优化的插件。本地主分支 `main` 已关联 `origin/main`，维护历史及基线标签均已同步。公开读取和克隆无需仓库访问授权，推送仍需有写入权限的 GitHub 账号。

## 内容

- `Interface/AddOns`：现用插件的完整文件，包含个人修改和配套依赖。
- 根目录 DLL、`dlls.txt`、`dxvk.conf`：运行依赖的当前版本，可校验和回退；二进制不能逐段合并。
- `PluginHistory`：初始校验清单、插件索引、历史源码备份、补丁和维护说明。
- `Tools`：按插件保存提交、逐字节校验和相关验证工具。

账号与角色配置 `WTF`、登录资料 `Imports`、日志、缓存、截图和游戏数据均不纳入。

## 维护与更新

按插件查找修改历史见 [插件修改记录](PluginHistory/Plugins/README.md)：每个插件一个文件，每次修改单独记录，最新记录在前，包含具体内容、检查结果和提交入口。[待确认插件](PluginHistory/待确认插件.md)单独列出；仍需补充的历史和游戏验收见 [待补充清单](PluginHistory/待补充清单.md)。今后按[记录规范](PluginHistory/记录规范.md)和[模板](PluginHistory/记录模板.md)持续追加，生成索引后将代码与说明一起提交。

每项插件修改完成后先检查并更新对应修改说明，再按插件或关联功能建立明确范围的提交，运行上传审计后主动同步至上述公开 GitHub 仓库；单独补充说明也同样提交、同步，无需逐次确认。同步失败时保留本地提交并报告待同步状态。新整合包应先解压到独立目录，用经过核实的旧原包、个人使用版、新原包比较合并；缺少旧原包时依据历史备份人工迁移。Git 记录可以恢复已提交内容，不会阻止更新器覆盖现用目录。

标签 `baseline/current-2026-10-08` 保存初始化时的个人使用版，已包含早期修改，不是官方原版。使用方法和历史覆盖范围见 [维护说明](PluginHistory/README.md) 与 [初始化记录](PluginHistory/初始化记录-20261008.md)。

## 在另一台电脑恢复

克隆时先使用 `git clone --no-checkout` 获取仓库，然后把 `Tools/git-info-attributes` 从提交中取出并保存到 `.git/info/attributes`，再检出文件，避免第三方插件自带的规则转换原始换行。使用 Windows PowerShell 时以字节流写入该规则文件，避免重编码。完整复制现有仓库（包括 `.git`）也可保留该规则。

部分插件原有独立仓库的历史已导出为 `PluginHistory/Evidence/nested-repositories` 内的 bundle；主仓库保存其实际文件，不依赖子模块恢复。

第三方插件及资源的版权与许可归原作者，保留各插件现有许可文件。本仓库公开分享个人维护与优化结果，不改变第三方授权。

本机同步方式、上传检查和账号恢复说明见 [GitHub 同步说明](PluginHistory/GitHub同步说明.md)。
