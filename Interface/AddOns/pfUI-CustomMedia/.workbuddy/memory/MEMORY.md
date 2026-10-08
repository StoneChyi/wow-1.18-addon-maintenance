# pfUI-CustomMedia 项目长期备忘

## 客户端边界（2026-09-18 明确）
- **不要修改 MHTUI 整合包（D:\MHTUI 整合包（26.6.28日更新））**——用户明确说"不用管这个"。曾误按旧记录把 MHTUI 当实际游玩客户端做了修改，已全部还原（pfUI/backup/ 里有当时备份）。
- 开发与实测客户端是 **D:\twmoa_1172**（本工作区所在客户端）。

## 协作偏好
- 用户问"有没有办法/可以吗"这类问题时，**先给方案说明，不要直接动手改插件**；等用户确认要哪种再实现。
- 需求以"小步快跑"推进；改文件前 backup/ 时间戳备份、luaparse 校验（pfUI 惯例）。

## 1.12 兼容陷阱（本项目实测）
- **pfUI 模块内部函数是文件级 local，不进全局**（2026-09-18 实测）：第三方在 pfUI.gui.CreateGUIEntry 的 populate 里裸调 `CreateConfig` 报 nil。暴露点：`pfUI.gui.CreateConfig / CreateGUIEntry / Reload / UpdaterFunctions`（pfUI gui.lua ~619）。第三方取用一律 `local CreateConfig = pfUI.gui.CreateConfig`。
- **`GameFontDisableSmall` 在 1.12 客户端不存在**：`CreateFontString` 第三参用它会抛错、整个 lua 文件加载中止（症状：斜杠命令"无效"）。安全字体模板（pfUI/其他老插件验证过）：GameFontNormal、GameFontNormalSmall、GameFontWhite、GameFontHighlightSmall（Dewdrop/AtlasLoot 在用）。
- 健壮写法：斜杠命令注册放文件最前，窗口等重对象首次调用时 pcall 构建，失败打到聊天框。
- `SetTexture(r,g,b,a)` 颜色写法 1.12 可用（ShaguDPS 大量使用）；SetVertexColor、OnDragStart/OnDragStop、UISpecialFrames 均可用。
- 诊断工具：.workbuddy/tgavalid.py（RLE 流完整性）、tgaalpha.py（alpha 通道统计），用 python 3.13 绝对路径 + Windows 风格路径运行。
- Node 侧 luaparse 校验：NODE_PATH=C:/Users/Administrator/.workbuddy/binaries/node/workspace/node_modules，luaVersion:'5.1'。
