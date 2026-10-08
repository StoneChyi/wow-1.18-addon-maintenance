# StatCompare/StatCompare.xml

类型：modified；新增 4 行，删除 4 行。

基线：10-06 统一观察布局首次修改前
基线来源：E:\1.18\addons_tmp\inspect-layout-backup-20261006\Interface_AddOns_StatCompare_StatCompare.xml.original

当前 SHA-256：`4a7d98a2afdf3ce998e8a8e5dcf2ffa8c3931848a4f504e6f7447b015e3be90a`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 37 / 1 | 37 / 1 | replace | `文件顶部 / 表定义` |
| 46 / 1 | 46 / 1 | replace | `文件顶部 / 表定义` |
| 190 / 1 | 190 / 1 | replace | `文件顶部 / 表定义` |
| 199 / 1 | 199 / 1 | replace | `文件顶部 / 表定义` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/StatCompare/StatCompare.xml
+++ b/StatCompare/StatCompare.xml
@@ -32,20 +32,20 @@
 		<Scripts>
 			<OnLoad>
 				this:RegisterForDrag("LeftButton");
 			</OnLoad>
 			<OnDragStart>
-				if arg1 == "LeftButton" then
+				if arg1 == "LeftButton" and SCGetPanelLayoutMode() == "free" then
 					this:StartMoving();
 				end
 			</OnDragStart>
 			<OnDragStop>
 				this:StopMovingOrSizing();
 				StatCompare_SaveFramePosition(this:GetName());
 			</OnDragStop>
 			<OnMouseDown>
-				if arg1 == "LeftButton" and not this.isMoving then
+				if arg1 == "LeftButton" and not this.isMoving and SCGetPanelLayoutMode() == "free" then
 					this:StartMoving();
 					this.isMoving = true;
 				end
 			</OnMouseDown>
 			<OnMouseUp>
@@ -185,20 +185,20 @@
 		<Scripts>
 			<OnLoad>
 				this:RegisterForDrag("LeftButton");
 			</OnLoad>
 			<OnDragStart>
-				if arg1 == "LeftButton" then
+				if arg1 == "LeftButton" and SCGetPanelLayoutMode() == "free" then
 					this:StartMoving();
 				end
 			</OnDragStart>
 			<OnDragStop>
 				this:StopMovingOrSizing();
 				StatCompare_SaveFramePosition(this:GetName());
 			</OnDragStop>
 			<OnMouseDown>
-				if arg1 == "LeftButton" and not this.isMoving then
+				if arg1 == "LeftButton" and not this.isMoving and SCGetPanelLayoutMode() == "free" then
 					this:StartMoving();
 					this.isMoving = true;
 				end
 			</OnMouseDown>
 			<OnMouseUp>
```
