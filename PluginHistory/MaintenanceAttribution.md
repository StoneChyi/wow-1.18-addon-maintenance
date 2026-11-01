# 个人版插件维护署名

用户于 2026-11-02 确认统一署名为 **StoneChyi & Codex**，并要求现有维护过的插件及以后的插件维护持续使用。

署名表明当前个人使用版的修改与维护归属。第三方插件的原作者、版权及许可证继续有效；不会据此认定历史来源待确认的差异为本方原创，也不会把其他插件的关联皮肤适配当作本体功能修改。

## 统一格式

在插件根 TOC 及其现用版本变体中添加：

```text
## X-Maintained-By: StoneChyi & Codex
## X-Maintenance-Scope: Personal modifications; original authors and licenses retained
```

现有 `## Notes:` 与本地化 `## Notes-xxxx:` 均在保留原文后追加：

```text
 | Personal edition: StoneChyi & Codex
```

没有 Notes 时新增 `## Notes: Personal edition: StoneChyi & Codex`。这样可以从插件列表的说明中看到维护署名，无须增加运行脚本、聊天输出或游戏内持续绘制。插件已有的 `Author`、`License` 和版权文件保持原样；新建的原创功能界面可另外显示维护署名，但仍应明确原作者与个人维护者的关系。

## 2026-11-02 补记范围

依据本次操作前的 `maintenance-index.json`，有 64 项处于“经过版本迭代或修改的插件”：63 项有维护记录，1 项 AtlasQuest 仅有来源待确认的历史差异。实际目录中 HideOutdoorWorldState 已按用户早期要求移除，本次不重建。

- 本次批量处理其余 62 个现存目录的 64 份根 TOC；pfUI、pfUI-CustomMedia 各含一份额外的 TBC 变体。
- `hyx` 在同一项 PureDispel 重构中单独维护，另有对应插件记录；不由批量工具重复编辑。
- AtlasQuest 的本次变化仅是新增维护 metadata 及可见署名；保留 `snapshot_difference` 与旧差异作者未确认的事实。
- 42 项尚未确认个人修改的插件，以及 1 项仅确认关联皮肤适配的插件不在这次补记范围内。它们以后真的发生本体维护时，再按真实维护日期加入署名和对应记录。
- 现有初始化清单、历史 Evidence、原始备份及维护归属状态不因本次署名而被改写。

各插件页面以 2026-11-02 的独立条目记录本次 TOC metadata 维护。它不代表该日重新实现或验收早期功能。

## 工具与验证

```text
python Tools/plugin_attribution.py plan
python Tools/plugin_attribution.py apply --addon 插件目录
python Tools/plugin_attribution.py check
python Tools/tests/test_plugin_attribution.py
```

工具只选择维护清单中 `history_group=modified` 的现用插件根 TOC，排除已经移除的插件目录。默认可以统一核对全部范围，也可显式指定当前负责的插件；新增插件或开始维护原来未确认的插件时，先按实际情况更新维护清单和插件记录。

字节编辑保留编码、BOM、原有每条行尾与末尾换行状态；原有 Notes 的原始字节只在行尾追加署名，加载文件列表和顺序不变。发现不同维护者的已有同名 metadata、重复字段或 UTF-16/NUL 内容时停止并要求人工审查，不擅自覆盖。

本次 9 项自动检查通过，覆盖 UTF-8 BOM、GBK 说明、混合换行、无末尾换行、无 Notes、幂等、他人署名冲突保护及不支持编码的拒绝路径。64 份 TOC 的修改结果均与对操作前 Git 字节调用相同增量规则的结果一致。检查范围为 metadata、字节保留及加载顺序；没有进行登录游戏后的插件列表显示验收。

文件级 SHA-256、范围及原历史证据状态见[本次补记清单](Research/插件维护署名-20261102.json)。本项还需与各插件说明、生成索引及提交记录一起保存；后续提交与 GitHub 同步遵循仓库维护规则。

## 同次保存工具与规则

`Tools/plugin_git.py checkpoint` 新增 `--support`，每次只接受明确的单个 `Tools` 文件或根 `AGENTS.md`，拒绝目录、越界和账号设置路径。`--check-notes` 在按明确范围暂存后、提交前检查历史索引和说明覆盖，使新增模块可以通过依赖 Git 跟踪清单的校验。校验失败时停止提交，保留已审查的暂存内容供检查；原先“暂存区非空则拒绝开始”的保护继续生效。

本次5项工具检查通过，覆盖明确路径、排除目录/越界、提交前检查顺序及失败不提交。它只扩展明确范围的维护提交能力，不授权收录WTF、凭据、日志或其他任务的未审查修改。
