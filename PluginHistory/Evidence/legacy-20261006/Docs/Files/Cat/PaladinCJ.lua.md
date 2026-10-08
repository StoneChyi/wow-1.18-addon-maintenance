# Cat/PaladinCJ.lua

类型：modified；新增 28 行，删除 33 行。

基线：10-05 惩戒第五档首次修改前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\cat-ret-tests\original\PaladinCJ.lua

当前 SHA-256：`e2674133017ab6a25664a1954e68fae7daa731f15f3fb2b80cf67fa78525244f`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 97 / 21 | 97 / 4 | replace | `CastConsecration（第96行）` |
| 119 / 10 | 102 / 1 | replace | `CastConsecration（第96行）` |
| 130 / 2 | 104 / 1 | replace | `CastConsecration（第96行）` |
| 219 / 0 | 192 / 2 | insert | `MPPaladinCJSpell（第191行）` |
| 398 / 0 | 373 / 10 | insert | `MPPaladinCJSpell（第191行）` |
| 486 / 0 | 471 / 6 | insert | `MPPaladinCJSpell（第191行）` |
| 521 / 0 | 512 / 4 | insert | `MPPaladinCJSpell（第191行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/Cat/PaladinCJ.lua
+++ b/Cat/PaladinCJ.lua
@@ -92,45 +92,18 @@
 		CastSpellByName("奉献")
 	end
 end
 
 local function CastConsecration()
-
-	if CatPaladinSeal:IsVisible() then
-		if MPPaladinSealSaved.Consecration==1 and MPGetTargetDistance()  and FX then
-			if MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Level==0 then
-				Consecration()
-			else
-				CastSpellByName("奉献(等级 "..MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Level..")")
-			end
-			return true
-		elseif MPPaladinSealSaved.Consecration==2 then
-			-- 是否踩奉献
-			if MPPaladinCJSaved[MPPaladinCJConfig].Consecration==1 and MPGetTargetDistance()  and FX then
-
-				if MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Level==0 then
-					Consecration()
-				else
-					CastSpellByName("奉献(等级 "..MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Level..")")
-				end
-				return true
-			end
-		end
-	else
-		-- 是否踩奉献
-		if MPPaladinCJSaved[MPPaladinCJConfig].Consecration==1 and MPGetTargetDistance()  and FX then
-
-			if MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Level==0 then
-				Consecration()
-			else
-				CastSpellByName("奉献(等级 "..MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Level..")")
-			end
-			return true
-		end
-	end
-
-	return false
+	local saved = MPPaladinCJSaved[MPPaladinCJConfig]
+	if saved.Consecration~=1 or not MPGetTargetDistance() or not FX then return false end
+	if saved.Consecration_Level==0 then
+		Consecration()
+	else
+		CastSpellByName("奉献(等级 "..saved.Consecration_Level..")")
+	end
+	return true
 end
 
 local function Exorcism()
 	if Mana<MPPaladinExorcismLevel6 then
 		CastSpellByName("驱邪术(等级 1)")
@@ -214,10 +187,12 @@
 
 
 
 
 function MPPaladinCJSpell()
+	if type(MPCatPaladinTankLeave) == "function" then MPCatPaladinTankLeave() end
+	MPCatPaladinApplyControl("RET", MPPaladinCJConfig)
 	if MP_Nampower then
 		SetCVar("NP_QueueCastTimeSpells", 0)
 	end
 
 	HasTarget = UnitExists("target")
@@ -393,10 +368,20 @@
 		elseif MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 4 then
 
 			-- 只打十字军打击
 			CrusaderStrike()
 
+
+		elseif MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 5 then
+
+			-- 先叠满三层狂热，之后主打神圣打击；剩余十秒时优先补狂热。
+			if not MPGetCrusaderStrike() or MPPaladinFrenzyLayer < 3
+				or (GetTime() - MPPaladinFrenzyDuration) >= 20 then
+				CrusaderStrike()
+			else
+				HolyStrike()
+			end
 		end
 
 
 	end
 
@@ -481,10 +466,16 @@
 				if not MPSeal("十字军圣印") then SealCrusader() return end
 				if MPSeal("十字军圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
 
 				return
 
+			elseif MPPaladinSealSaved.Justice==4 and not MPBuff("公正审判", "target") then
+				-- 公正审判：先准备圣印，再沿用审判的蓝量与公共冷却限制。
+				if not MPSeal("公正圣印") then MPCastWithoutNampower("公正圣印") return end
+				if SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
+				return
+
 			end
 		end
 
 		-- 通过小窗参数 - 圣印
 
@@ -516,10 +507,14 @@
 			-- 保持命令圣印
 			if not MPSeal("命令圣印") then SealCommand() return end
 			if SP and Mana>=76 and GCD>1.4 then
 				if (MPSeal("正义圣印") or MPSeal("命令圣印")) then CastSpellByName("审判") return end
 			end
+
+		elseif MPPaladinSealSaved.Seal==6 then
+			-- 保持公正圣印；是否施放公正审判由上面的审判选项决定。
+			if not MPSeal("公正圣印") then MPCastWithoutNampower("公正圣印") return end
 
 		elseif MPPaladinSealSaved.Seal==0 then
 
 			-- 输出
```
