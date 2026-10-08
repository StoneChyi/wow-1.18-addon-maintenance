module 'aux.tabs.post'

local aux = require 'aux'
local info = require 'aux.util.info'
local money = require 'aux.util.money'
local gui = require 'aux.gui'
local listing = require 'aux.gui.listing'
local item_listing = require 'aux.gui.item_listing'
local search_tab = require 'aux.tabs.search'

function aux.handle.INIT_UI()
    local THEME_PADDING = gui.is_blizzard() and 6.5 or 2.5

    frame = CreateFrame('Frame', nil, aux.frame)
    frame:SetAllPoints()
    frame:SetScript('OnUpdate', on_update)
    frame:Hide()

    frame.content = CreateFrame('Frame', nil, frame)
    frame.content:SetPoint('TOP', frame, 'TOP', 0, -8)
    frame.content:SetPoint('BOTTOMLEFT', aux.frame.content, 'BOTTOMLEFT', 0, 0)
    frame.content:SetPoint('BOTTOMRIGHT', aux.frame.content, 'BOTTOMRIGHT', 0, 0)

    frame.inventory = gui.panel(frame.content)
    frame.inventory:SetWidth(212)
    frame.inventory:SetPoint('TOPLEFT', 0, 0)
    frame.inventory:SetPoint('BOTTOMLEFT', 0, 0)

    frame.parameters = gui.panel(frame.content)
    frame.parameters:SetHeight(221)
    frame.parameters:SetPoint('TOPLEFT', frame.inventory, 'TOPRIGHT', THEME_PADDING, 0)
    frame.parameters:SetPoint('TOPRIGHT', 0, 0)

    frame.bid_listing = gui.panel(frame.content)
    frame.bid_listing:SetHeight(228)
    frame.bid_listing:SetWidth(271.5)
    frame.bid_listing:SetPoint('BOTTOMLEFT', frame.inventory, 'BOTTOMRIGHT', THEME_PADDING, 0)

    frame.buyout_listing = gui.panel(frame.content)
    frame.buyout_listing:SetPoint('TOPLEFT', frame.parameters, 'BOTTOMLEFT', 0, -THEME_PADDING)
    frame.buyout_listing:SetPoint('BOTTOMRIGHT', 0, 0)

    do
        local checkbox = gui.checkbox(frame.inventory)
        checkbox:SetPoint('TOPLEFT', 49, -15)
        checkbox:SetScript('OnClick', function()
            refresh = true
        end)
        local label = gui.label(checkbox, gui.font_size.small)
        label:SetPoint('LEFT', checkbox, 'RIGHT', 4, 1)
        label:SetText('显示隐藏物品')
        show_hidden_checkbox = checkbox
    end

    gui.horizontal_line(frame.inventory, -45)

    do
        local f = CreateFrame('Frame', nil, frame.inventory)
        f:SetPoint('TOPLEFT', 0, -51)
        f:SetPoint('BOTTOMRIGHT', 0, 0)
        inventory_listing = item_listing.new(
            f,
            function()
                if arg1 == 'LeftButton' then
                    update_item(this.item_record)
                elseif arg1 == 'RightButton' then
                    aux.set_tab(1)
                    search_tab.set_filter(strlower(info.item(this.item_record.item_id).name) .. '/exact')
                    search_tab.execute(nil, false)
                end
            end,
            function(item_record)
                return item_record == selected_item
            end
        )
    end

    bid_listing = listing.new(frame.bid_listing)
    bid_listing:SetColInfo{
    {name='拍卖数', width=.17, align='CENTER'},
    {name='剩余\n时间', width=.11, align='CENTER'},
    {name='组叠\n大小', width=.11, align='CENTER'},
    {name='竞拍\n(每件)', width=.4, align='RIGHT'},
    {name='价格\n对比', width=.21, align='CENTER'},
}
    bid_listing:SetSelection(function(data)
        return data.record == get_bid_selection() or data.record.historical_value and get_bid_selection() and get_bid_selection().historical_value
    end)
    bid_listing:SetHandler('OnClick', function(table, row_data, column, button)
        if button == 'RightButton' and row_data.record == get_bid_selection() or row_data.record.historical_value and get_bid_selection() and get_bid_selection().historical_value then
            set_bid_selection()
        else
            set_bid_selection(row_data.record)
        end
        refresh = true
    end)
    bid_listing:SetHandler('OnDoubleClick', function(table, row_data, column, button)
        stack_size_slider:SetValue(row_data.record.stack_size)
        refresh = true
    end)

    buyout_listing = listing.new(frame.buyout_listing)
    buyout_listing:SetColInfo{
	{name='拍卖数', width=.17, align='CENTER'},
	{name='剩余\n时间', width=.11, align='CENTER'},
	{name='组叠\n大小', width=.12, align='CENTER'},
	{name='竞拍\n(每件)', width=.4, align='RIGHT'},
	{name='价格\n对比', width=.20, align='CENTER'},
}
    buyout_listing:SetSelection(function(data)
        return data.record == get_buyout_selection() or data.record.historical_value and get_buyout_selection() and get_buyout_selection().historical_value
    end)
    buyout_listing:SetHandler('OnClick', function(table, row_data, column, button)
        if button == 'RightButton' and row_data.record == get_buyout_selection() or row_data.record.historical_value and get_buyout_selection() and get_buyout_selection().historical_value then
            set_buyout_selection()
        else
            set_buyout_selection(row_data.record)
        end
        refresh = true
    end)
    buyout_listing:SetHandler('OnDoubleClick', function(table, row_data, column, button)
        stack_size_slider:SetValue(row_data.record.stack_size)
        refresh = true
    end)

    do
        status_bar = gui.status_bar(frame)
        status_bar:SetWidth(265)
        status_bar:SetHeight(25)
        status_bar:SetPoint('TOPLEFT', aux.frame.content, 'BOTTOMLEFT', 0, -6)
        status_bar:update_status(1, 1)
        status_bar:set_text('')
    end
    do
        local btn = gui.button(frame.parameters)
        btn:SetPoint('TOPLEFT', status_bar, 'TOPRIGHT', 5, 0)
        btn:SetText('出售')
        btn:SetScript('OnClick', post_auctions)
        post_button = btn
    end
    do
        local btn = gui.button(frame.parameters)
        btn:SetPoint('TOPLEFT', post_button, 'TOPRIGHT', 5, 0)
        btn:SetText('刷新')
        btn:SetScript('OnClick', refresh_button_click)
        refresh_button = btn
    end
    do
        item = gui.item(frame.parameters)
        item:SetPoint('TOPLEFT', 10, -6)
        item.button:SetScript('OnEnter', function()
            if selected_item then
                info.set_tooltip(selected_item.itemstring, this, 'ANCHOR_RIGHT')
            end
        end)
        item.button:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)
    end
    do
        local slider = gui.slider(frame.parameters)
        slider:SetValueStep(1)
        slider:SetPoint('TOPLEFT', 13, -73)
        slider:SetWidth(190)
        slider:SetScript('OnValueChanged', function()
            quantity_update(true)
        end)
        slider.editbox.change = function()
            slider:SetValue(this:GetNumber())
            quantity_update(true)
            if selected_item then
                local settings = read_settings()
                write_settings(settings)
            end
        end
        slider.editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                unit_buyout_price_input:SetFocus()
            elseif stack_count_slider.editbox:IsVisible() then
                stack_count_slider.editbox:SetFocus()
            else
                unit_start_price_input:SetFocus()
            end
        end)
        slider.editbox:SetNumeric(true)
        slider.editbox:SetMaxLetters(3)
        slider.label:SetText('组叠大小')
        stack_size_slider = slider
    end
    do
        local slider = gui.slider(frame.parameters)
        slider:SetValueStep(1)
        slider:SetPoint('TOPLEFT', stack_size_slider, 'BOTTOMLEFT', 0, gui.is_blizzard() and -25 or -32)
        slider:SetWidth(190)
        slider:SetScript('OnValueChanged', function()
            quantity_update()
        end)
        slider.editbox.change = function()
            slider:SetValue(this:GetNumber())
            quantity_update()
        end
        slider.editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                stack_size_slider.editbox:SetFocus()
            else
                unit_start_price_input:SetFocus()
            end
        end)
        slider.editbox:SetNumeric(true)
        slider.label:SetText('组数')
        stack_count_slider = slider
    end
    do
        local dropdown = gui.dropdown(frame.parameters)
        dropdown:SetPoint('TOPLEFT', stack_count_slider, 'BOTTOMLEFT', 0, gui.is_blizzard() and -10 or -22)
        dropdown:SetWidth(90)
        local label = gui.label(dropdown, gui.font_size.small)
        label:SetPoint('BOTTOMLEFT', dropdown, 'TOPLEFT', -2, -3)
        label:SetText('时限')
        UIDropDownMenu_Initialize(dropdown, initialize_duration_dropdown)
        dropdown:SetScript('OnShow', function()
            UIDropDownMenu_Initialize(this, initialize_duration_dropdown)
        end)
        duration_dropdown = dropdown
    end
    do
        local checkbox = gui.checkbox(frame.parameters)
        checkbox:SetPoint('TOPRIGHT', -83, -6)
        checkbox:SetScript('OnClick', function()
            local settings = read_settings()
            settings.hidden = this:GetChecked()
            write_settings(settings)
            refresh = true
        end)
        local label = gui.label(checkbox, gui.font_size.small)
        label:SetPoint('LEFT', checkbox, 'RIGHT', 4, 1)
        label:SetText('隐藏此物品')
        hide_checkbox = checkbox
    end
    do
        local editbox = gui.editbox(frame.parameters)
        editbox:SetPoint('TOPRIGHT', -71, -60)
        editbox:SetWidth(180)
        editbox:SetHeight(22)
        editbox:SetAlignment('RIGHT')
        editbox:SetFontSize(17)
        editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                stack_count_slider.editbox:SetFocus()
            else
                unit_buyout_price_input:SetFocus()
            end
        end)
        editbox.formatter = function() return money.to_string(get_unit_start_price(), true) end
        editbox.char = function() set_bid_selection(); set_buyout_selection(); set_unit_start_price(money.from_string(this:GetText())) end
        editbox.change = function() refresh = true end
        editbox.enter = function() this:ClearFocus() end
        editbox.focus_loss = function()
            this:SetText(money.to_string(get_unit_start_price(), true, nil, nil, true))
        end
        do
            local label = gui.label(editbox, gui.font_size.small)
            label:SetPoint('BOTTOMLEFT', editbox, 'TOPLEFT', -2, 1)
            label:SetText('初始价')
        end
        do
            local label = gui.label(editbox, 14)
            label:SetPoint('LEFT', editbox, 'RIGHT', 8, 0)
            label:SetWidth(50)
            label:SetJustifyH('CENTER')
            start_price_percentage = label
        end
        unit_start_price_input = editbox
    end
    do
        local editbox = gui.editbox(frame.parameters)
        editbox:SetPoint('TOPRIGHT', unit_start_price_input, 'BOTTOMRIGHT', 0, -19)
        editbox:SetWidth(180)
        editbox:SetHeight(22)
        editbox:SetAlignment('RIGHT')
        editbox:SetFontSize(17)
        editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                unit_start_price_input:SetFocus()
            else
                stack_size_slider.editbox:SetFocus()
            end
        end)
        editbox.formatter = function() return money.to_string(get_unit_buyout_price(), true) end
        editbox.char = function() set_buyout_selection(); set_unit_buyout_price(money.from_string(this:GetText())) end
        editbox.change = function() refresh = true end
        editbox.enter = function() this:ClearFocus() end
        editbox.focus_loss = function()
            this:SetText(money.to_string(get_unit_buyout_price(), true, nil, nil, true))
        end
        do
            local label = gui.label(editbox, gui.font_size.small)
            label:SetPoint('BOTTOMLEFT', editbox, 'TOPLEFT', -2, 1)
            label:SetText('一口价')
        end
        do
            local label = gui.label(editbox, 14)
            label:SetPoint('LEFT', editbox, 'RIGHT', 8, 0)
            label:SetWidth(50)
            label:SetJustifyH('CENTER')
            buyout_price_percentage = label
        end
        unit_buyout_price_input = editbox
    end
    do
        local label = gui.label(frame.parameters, gui.font_size.medium)
        label:SetPoint('TOPLEFT', unit_buyout_price_input, 'BOTTOMLEFT', -180, -24)
        deposit = label
    end
    do
        local label = gui.label(frame.parameters, gui.font_size.medium)
        label:SetPoint('TOPLEFT', unit_buyout_price_input, 'BOTTOMLEFT', -180, -48)
        vendor_price_label = label
    end
    do
        local label = gui.label(frame.parameters, gui.font_size.medium)
        label:SetPoint('TOPLEFT', unit_buyout_price_input, 'BOTTOMLEFT', 0, -24)
        stack_total_label = label
        
        local bg = frame.parameters:CreateTexture(nil, 'BACKGROUND')
        bg:SetPoint('TOPLEFT', label, 'TOPLEFT', -5, 5)
        bg:SetPoint('BOTTOMRIGHT', label, 'BOTTOMRIGHT', 5, -5)
        bg:SetTexture(1, 1, 0, 0.3)
        stack_total_bg = bg
    end
    do
        local label = gui.label(frame.parameters, gui.font_size.small)
        label:SetPoint('TOPLEFT', vendor_price_label, 'BOTTOMLEFT', -84, -12)
        label:SetText(aux.color.light_gray'点击下方搜索框价格将自动填入到一口价，手动输入如11.2233即代表11金22银33铜')
        price_input_tip = label
    end

    function aux.handle.LOAD()
        if aux.account_data.post_bid then
            frame.bid_listing:SetPoint('TOPLEFT', frame.parameters, 'BOTTOMLEFT', 0, -THEME_PADDING)
            frame.bid_listing:SetPoint('BOTTOMLEFT', frame.inventory, 'BOTTOMRIGHT', THEME_PADDING, 0)
            frame.bid_listing:SetWidth(271.5 - (THEME_PADDING / 2))

            frame.buyout_listing:ClearAllPoints()
            frame.buyout_listing:SetPoint('TOPLEFT', frame.bid_listing, 'TOPRIGHT', THEME_PADDING, 0)
            frame.buyout_listing:SetPoint('BOTTOMRIGHT', 0, 0)
        else
            frame.bid_listing:Hide()
            buyout_listing:SetColInfo{
			{name='拍卖数', width=.15, align='CENTER'},
			{name='剩余时间', width=.15, align='CENTER'},
			{name='组叠大小', width=.15, align='CENTER'},
			{name='一口价 (每件)', width=.4, align='RIGHT'},
			{name='价格对比', width=.15, align='CENTER'},
		}
        end
    end
end