# DimInfo 传送线条图标

本次维护原创的一套单色线稿：`hearth` 回旋纹、`verdant` 叶片、`time` 沙漏、`guild` 旗帜。

- 四种图标共享 32×32 画布、2.4 单位线宽、圆角线端和透明背景；游戏中以 16×16 显示，不绘制底板或方形边框。
- `.tga` 为旧客户端读取的未压缩 32 位 RGBA 贴图（8 位 Alpha）；白色线稿由 Lua 按当前状态统一染色。`.svg` 为可编辑矢量源。
- 不引用或复制物品原图，无运行时图片生成依赖；物品名称、冷却和可用状态仍来自客户端。
- 规范几何定义在 `tools/render_teleport_icons.py`，改动后生成 SVG 与 TGA，避免两个格式分别修改后不一致。

从仓库根目录运行（制作资源时需要 Python + Pillow，游戏运行不需要）：

```text
python Interface/AddOns/diminfo/tools/render_teleport_icons.py
python Interface/AddOns/diminfo/tools/render_teleport_icons.py --check
```

新增贴图的客户端加载情况需在游戏内验收；若重载界面仍未显示，完整退出并重新启动游戏后检查。
