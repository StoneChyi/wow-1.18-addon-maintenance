-- upvalues
local strgfind = string.gfind

local function ShowColorPicker(r, g, b, callback)
   ColorPickerFrame:SetColorRGB(r, g, b)
   ColorPickerFrame.previousValues = {r, g, b}
   ColorPickerFrame.func, ColorPickerFrame.cancelFunc = callback, callback
   ColorPickerFrame:Hide()
   ColorPickerFrame:Show()
end

local function ColorPickerCallback(restore)
   local r, g, b
   if restore then
      r, g, b = unpack(restore)
   else
      r, g, b = ColorPickerFrame:GetColorRGB()
   end

   Flyout_Config['BORDER_COLOR'][1] = r
   Flyout_Config['BORDER_COLOR'][2] = g
   Flyout_Config['BORDER_COLOR'][3] = b
end

SLASH_FLYOUT1 = "/flyout"
SlashCmdList['FLYOUT'] = function(msg)
   local args = {}
   local i = 1
   for arg in strgfind(strlower(msg), "%S+") do
      args[i] = arg
      i = i + 1
   end

   if not args[1] then
      DEFAULT_CHAT_FRAME:AddMessage("/flyout size [数字||reset] - 设置菜单图标大小")
      DEFAULT_CHAT_FRAME:AddMessage("/flyout color [reset] - 调整菜单图标边框颜色")
      DEFAULT_CHAT_FRAME:AddMessage("/flyout arrow [数字||reset] - 调整菜单图标箭头大小")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
   elseif args[1] == 'size' then
      if args[2] then
         if type(tonumber(args[2])) == 'number' then
            Flyout_Config['BUTTON_SIZE'] = tonumber(args[2])
         elseif args[2] == 'reset' then
            Flyout_Config['BUTTON_SIZE'] = FLYOUT_DEFAULT_CONFIG['BUTTON_SIZE']
         end
         DEFAULT_CHAT_FRAME:AddMessage("菜单图标大小已设置为 " .. Flyout_Config['BUTTON_SIZE'] .. "。")
      end
   elseif args[1] == 'color' then
      if args[2] == 'reset' then
         Flyout_Config['BORDER_COLOR'][1] = FLYOUT_DEFAULT_CONFIG['BORDER_COLOR'][1]
         Flyout_Config['BORDER_COLOR'][2] = FLYOUT_DEFAULT_CONFIG['BORDER_COLOR'][2]
         Flyout_Config['BORDER_COLOR'][3] = FLYOUT_DEFAULT_CONFIG['BORDER_COLOR'][3]
         DEFAULT_CHAT_FRAME:AddMessage("菜单图标边框颜色已重置。")
      else
         ShowColorPicker(Flyout_Config['BORDER_COLOR'][1], Flyout_Config['BORDER_COLOR'][2], Flyout_Config['BORDER_COLOR'][3], ColorPickerCallback)
         DEFAULT_CHAT_FRAME:AddMessage("使用颜色选择器选择菜单图标边框颜色。选择完成后点击“确定”，或点击“取消”保留当前颜色。")
      end
   elseif args[1] == 'arrow' then
      if args[2] then
         if type(tonumber(args[2])) == 'number' then
            Flyout_Config['ARROW_SCALE'] = tonumber(args[2])
         elseif args[2] == 'reset' then
            Flyout_Config['ARROW_SCALE'] = FLYOUT_DEFAULT_CONFIG['ARROW_SCALE']
         end
         DEFAULT_CHAT_FRAME:AddMessage("菜单图标箭头大小已设置为 " .. Flyout_Config['ARROW_SCALE'] .. "。")
         Flyout_UpdateBars()
      end
   end
end