BINDING_HEADER_INTERACT = 'Interact'

StaticPopupDialogs['INTERACT_WARNING'] = {
   text = '|cffffd200Interact模组|cffffffff 检测到未加载！，请登录器加载该模组，如无需求请在插件管理器中禁用interact交互插件。',
   button1 = '确定',
   timeout = 0,
   whileDead = true,
}

if not InteractNearest then
   StaticPopup_Show('INTERACT_WARNING')
end

function Interact(autoloot)
    if not InteractNearest then
        StaticPopup_Show('INTERACT_WARNING')
        return
    end

    InteractNearest(autoloot)
end