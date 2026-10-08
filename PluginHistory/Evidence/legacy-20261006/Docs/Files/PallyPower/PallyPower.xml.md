# PallyPower/PallyPower.xml

类型：modified；新增 4 行，删除 4 行。

基线：10-06 团队功能扩展前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\pallypower-extension\original\PallyPower\PallyPower.xml

当前 SHA-256：`562b0bbd58cb307360b01f5372e703b6b519e382eb588c9fe5f14452a6d82be8`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 133 / 1 | 133 / 1 | replace | `文件顶部 / 表定义` |
| 1298 / 1 | 1298 / 1 | replace | `文件顶部 / 表定义` |
| 1529 / 2 | 1529 / 2 | replace | `文件顶部 / 表定义` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/PallyPower/PallyPower.xml
+++ b/PallyPower/PallyPower.xml
@@ -128,11 +128,11 @@
                     </Anchors>
                 </Texture>
             </Layer>
         </Layers>
         <Scripts>
-            <OnLoad>PallyPowerBuffButton_OnLoad(this); this:RegisterForClicks("LeftButtonUp", "RightButtonUp")</OnLoad>
+            <OnLoad>PallyPowerBuffButton_OnLoad(this); this:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")</OnLoad>
             <OnClick>PallyPowerBuffButton_OnClick(this, arg1)</OnClick>
             <OnEnter>PallyPowerBuffButton_OnEnter(this)</OnEnter>
             <OnLeave>PallyPowerBuffButton_OnLeave(this)</OnLeave>
         </Scripts>
     </Button>
@@ -1293,11 +1293,11 @@
                                 <AbsDimension x="7" y="-50"/>
                             </Offset>
                         </Anchor>
                     </Anchors>
                 </FontString>
-                <FontString name="$parentOption3" inherits="GameFontHighlight" text="PALLYPOWER_OPTIONS_FEEDBACK_CHAT"
+                <FontString name="$parentOption3" inherits="GameFontHighlight" text="屏幕提示（不写入聊天框）"
                             justifyH="LEFT">
                     <Size>
                         <AbsDimension x="200" y="16"/>
                     </Size>
                     <Anchors>
@@ -1524,12 +1524,12 @@
                             <AbsDimension x="-5" y="-75"/>
                         </Offset>
                     </Anchor>
                 </Anchors>
                 <Scripts>
-                    <OnShow>if (PP_PerUser.chatfeedback) then this:SetChecked(true) else this:SetChecked(false) end</OnShow>
-                    <OnClick>PP_PerUser.chatfeedback = this:GetChecked()</OnClick>
+                    <OnShow>if (PP_PerUser.screenfeedback ~= 0) then this:SetChecked(true) else this:SetChecked(false) end</OnShow>
+                    <OnClick>PP_PerUser.screenfeedback = this:GetChecked() and 1 or 0</OnClick>
                 </Scripts>
             </CheckButton>
             <CheckButton name="$parentSmart" inherits="OptionsCheckButtonTemplate">
                 <Size>
                     <AbsDimension x="20" y="20"/>
```
