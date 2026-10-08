# Cat/PaladinMeleeHeal.lua

类型：modified；新增 18 行，删除 0 行。

基线：10-06 骑士控制扩展前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\cat-paladin-controls\original\Cat\PaladinMeleeHeal.lua

当前 SHA-256：`b933e9e16b1835e2ee4956b0ce67ceb65b955e05ca56350f3b8a9f6fc2ee0eaf`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 190 / 0 | 190 / 6 | insert | `MPPaladinAutoMeleeHealth（第79行）` |
| 208 / 0 | 214 / 12 | insert | `MPPaladinAutoMeleeHealth（第79行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/Cat/PaladinMeleeHeal.lua
+++ b/Cat/PaladinMeleeHeal.lua
@@ -185,10 +185,16 @@
 		if not MPSeal("十字军圣印") then SealCrusader() return end
 		if MPSeal("十字军圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
 
 		return
 
+	elseif MPPaladinSealSaved.Justice==4 and not MPBuff("公正审判", "target") then
+		-- 公正审判：先准备圣印，再沿用审判的蓝量与公共冷却限制。
+		if not MPSeal("公正圣印") then MPCastWithoutNampower("公正圣印") return end
+		if SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
+		return
+
 	end
 
 	-- 通过小窗参数 - 圣印
 
 	if MPPaladinSealSaved.Seal==1 then
@@ -203,10 +209,22 @@
 
 	elseif MPPaladinSealSaved.Seal==3 then
 
 		-- 保持十字军圣印
 		if not MPSeal("十字军圣印") then SealCrusader() return end
+
+	elseif MPPaladinSealSaved.Seal==4 then
+		if not MPSeal("正义圣印") then SealJustice() return end
+		if SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
+
+	elseif MPPaladinSealSaved.Seal==5 then
+		if not MPSeal("命令圣印") then SealCommand() return end
+		if SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
+
+	elseif MPPaladinSealSaved.Seal==6 then
+		-- 保持公正圣印；是否施放公正审判由上面的审判选项决定。
+		if not MPSeal("公正圣印") then MPCastWithoutNampower("公正圣印") return end
 
 	elseif MPPaladinSealSaved.Seal==0 then
 
 		-- 输出
```
