# GitHub 同步说明

2026-10-09 已创建并首次同步私有仓库：

[StoneChyi/wow-1.18-addon-maintenance](https://github.com/StoneChyi/wow-1.18-addon-maintenance)

账号为 `StoneChyi`，远程名为 `origin`，主分支为 `main`。本地插件文件、真实提交历史、历史维护依据及 `baseline/current-2026-10-08`、`baseline/bootstrap-2026-10-08` 两个已有标签均已上传。恢复插件时使用完整的 `baseline/current-2026-10-08`，bootstrap 标签仅保留最初初始化检查点。

## 后续同步

1. 按 `AGENTS.md` 完成插件修改、检查和独立本地提交。
2. 核对仓库状态与远端目标，审查本次提交。使用 Python 执行 `Tools/audit_github_upload.py` 可检查所有可达历史中的常见令牌和私钥模式、排除目录及 GitHub 文件大小限制；不能保证发现所有敏感数据。
3. 运行 `git push origin main` 同步已提交记录。新建的标签应审查后明确指定推送；不要强制推送或覆盖已有基线。
4. 如果远端存在本地没有的提交，先检查并整合，再推送。存在未提交改动时不要为了同步而覆盖或撤销它们。

仓库保存全部现用插件及依赖，避免遗漏早期自定义改动。`WTF`、账号/角色设置、`Imports` 登录资料、日志、缓存、游戏数据和截图仍排除在代码仓库之外。第三方插件保留原有版权与许可。

## 本机登录与网络

本次通过 GitHub 官方 CLI 的设备授权完成登录，没有通过聊天传递密码或令牌。凭据由官方工具管理，Git 的凭据助手只在本仓库配置；没有把令牌写进源码或远程地址。

官方 CLI 便携程序保存在已忽略的 `PluginHistory/staging/github-cli`，不上传。删除或移动它后，需要重新配置凭据助手，或安装并登录 GitHub 官方 CLI。

本机已有系统代理，GitHub 工具需要使用同一代理才能连接。Git 代理仅配置在此仓库的 GitHub 地址范围，未修改系统代理、hosts 或全局 Git 设置。代理停用或地址改变时，需相应更新本仓库配置。

另一台电脑需要单独登录有仓库访问权限的 GitHub 账号，不能从源码恢复登录凭据。检出插件文件前恢复 `.git/info/attributes` 规则，方法见仓库首页；原始编码与换行应保持不变。
