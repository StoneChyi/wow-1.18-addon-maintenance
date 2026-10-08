# StatCompare/SCOptions.lua

类型：modified；新增 3 行，删除 1 行。

基线：10-06 统一观察布局首次修改前
基线来源：E:\1.18\addons_tmp\inspect-layout-backup-20261006\Interface_AddOns_StatCompare_SCOptions.lua.original

当前 SHA-256：`0d192c93aed56be0ff72f50671703d88db42db56827c6302232d29dabc36f9ff`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 93 / 0 | 93 / 1 | insert | `StatCompare_Toggle（第86行）` |
| 351 / 1 | 352 / 2 | replace | `StatCompareShowSelfFrameOpt_OnClick（第346行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/StatCompare/SCOptions.lua
+++ b/StatCompare/SCOptions.lua
@@ -88,10 +88,11 @@
 		return
 	end
 	if(StatCompareOptFrame:IsVisible()) then
 		StatCompareOptFrame:Hide();
 	else
+		if SCEnsureLayoutButton then SCEnsureLayoutButton() end
 		StatCompareOptFrame:Show();
 		for i=1,2 do
 			getglobal("StatCompareOptTab"..i):UnlockHighlight();
 			getglobal("StatCompareOptSubFrame"..i):Hide();
 		end
@@ -346,11 +347,12 @@
 	local value = 0;
 
 	if(this:GetChecked()) then
 		value = 1;
 	end
-	StatCompare_SetSetting("ShowSelfFrame", value);	
+	StatCompare_SetSetting("ShowSelfFrame", value);
+	if SCRequestPanelLayout then SCRequestPanelLayout() end
 end
 
 function StatCompareShowBuffBonusOpt_OnClick()
 	local value = 0;
```
