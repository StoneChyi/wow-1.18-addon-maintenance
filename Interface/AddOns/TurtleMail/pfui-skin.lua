-- TurtleMail 的 pfUI 美化代码
-- 由 TurtleMail.lua 的 ADDON_LOADED 调用 m.pfui_skin() 注册，pfUI 加载皮肤时执行回调
TurtleMail = TurtleMail or {}
local m = TurtleMail

function TurtleMail.pfui_skin()
  -- 注册过就不重复；pfUI 未就绪时由 PLAYER_LOGIN / MAIL_SHOW 再次触发，
  -- 否则只在 ADDON_LOADED 试一次，pfUI 晚一拍加载就永远错过皮肤
  if m.pfui_skin_registered then return end
  if not ( m.api.IsAddOnLoaded( "pfUI" ) and m.api.pfUI and m.api.pfUI.api and m.api.pfUI.env and m.api.pfUI.env.C ) then
    return
  end
  m.pfui_skin_registered = true
  m.api.pfUI:RegisterSkin( "TurtleMail", "vanilla", function()
      -- Don't apply our skin when Mailbox skin is disabled because it doesn't make sense.
      if m.api.pfUI.env.C.disabled and (m.api.pfUI.env.C.disabled[ "skin_TurtleMail" ] == "1" or m.api.pfUI.env.C.disabled[ "skin_Mailbox" ] == "1") then
        m.info( "|cffffd100pfUI 已关闭 Mailbox/TurtleMail 皮肤，TurtleMail 保持原版外观（pfUI 设置-皮肤里可开启）|r" )
        return
      end
      m.pfui_skin_enabled = true
      local rawborder, border = m.api.pfUI.api.GetBorderSize()
      local bpad = rawborder > 1 and border - m.api.pfUI.api.GetPerfectPixel() or m.api.pfUI.api.GetPerfectPixel()

      --Inbox
      m.api.pfUI.api.SkinButton( m.api.TurtleMailOpenMailButton )
	  m.api.pfUI.api.SkinButton(m.api.TurtleMailOpenAllMailButton)
      m.api.pfUI.api.SkinButton(m.api.TurtleMailOpenSelectedMailButton)
      m.api.pfUI.api.SkinButton(m.api.TurtleMailFilterMenuButton)
      m.api.pfUI.api.SkinButton(m.api.TurtleMailBatchTakeButton)
      m.api.pfUI.api.SkinButton(m.api.TurtleMailBatchDeleteButton)
      m.api.pfUI.api.SkinButton(m.api.TurtleMailBatchReturnButton)
      if m.api.TurtleMailPanelToggleButton then
        m.api.pfUI.api.SkinButton( m.api.TurtleMailPanelToggleButton )
        -- pfUI 下右侧空间充足，回到 4px 间距（原版皮肤下贴紧大按钮防溢出）
        if m.api.TurtleMailOpenAllMailButton then
          m.api.TurtleMailPanelToggleButton:ClearAllPoints()
          m.api.TurtleMailPanelToggleButton:SetPoint( "LEFT", m.api.TurtleMailOpenAllMailButton, "RIGHT", 4, 0 )
        end
      end

      -- 面板建好时 pfUI 未必就绪，可能走了 fallback SetBackdrop，这里补成 pfUI 底纹
      if m.batch_panel and not m.batch_panel.pfUI_backdrop then
        pcall( function()
          m.api.pfUI.api.CreateBackdrop( m.batch_panel, 4 )
          m.batch_panel.pfUI_backdrop = true
        end )
      end

      -- 自绘勾选框是普通 Button+自带贴图，不能走 pfUI 的 SkinCheckbox
      -- （它会 StripTextures 清掉自绘方框/对勾），手动换成 pfUI 风格：清空贴图 + backdrop 方框，对勾保留原贴图
      for i = 1, 10 do
        local cb = m.api[ "TurtleMailBatchFilter" .. i ]
        if cb and not cb.pfUI_styled then
          cb.pfUI_styled = true
          pcall( function()
            local box = getglobal( cb:GetName() .. "Box" )
            if box then box:SetTexture( "" ) end
            m.api.pfUI.api.CreateBackdrop( cb, nil, true )
          end )
        end
      end
      local cbAll = m.api.TurtleMailSelectAllCB
      if cbAll and not cbAll.pfUI_styled then
        cbAll.pfUI_styled = true
        pcall( function()
          local box = getglobal( cbAll:GetName() .. "Box" )
          if box then box:SetTexture( "" ) end
          m.api.pfUI.api.CreateBackdrop( cbAll, nil, true )
        end )
      end
      -- 自绘勾选框换装后必须重锚一次，等 pfUI 的 Mailbox backdrop 撑开
      if m.batch_reanchor then m.batch_reanchor() end

      --Sendmail
      m.api.MailHorizontalBarLeft:SetTexture( "" )      m.api.MailHorizontalBarRight:SetTexture( "" )

      for i = 1, 21 do
        local button = m.api[ "MailAttachment" .. i ]
        m.api.pfUI.api.StripTextures( button )
        m.api.pfUI.api.SkinButton( button, nil, nil, nil, nil, true )
        local orig = button.SetNormalTexture
        button.SetNormalTexture = function( self, tex )
          orig( self, tex )

          if button.item then
            m.api.pfUI.api.HandleIcon( self, self:GetNormalTexture() )

            local link = m.api.GetContainerItemLink( button.item[ 1 ], button.item[ 2 ] )
            if link then
              local _, _, linkstr = string.find( link, "(item:%d+:%d+:%d+:%d+)" )
              local _, _, quality = m.api.GetItemInfo( linkstr )
              local r, g, b = m.api.GetItemQualityColor( quality )
              self:SetBackdropBorderColor( r, g, b, 1 )
            end
          else
            self:SetBackdropBorderColor( m.api.pfUI.api.GetStringColor( m.api.pfUI_config.appearance.border.color ) )
          end
        end
      end

      --Log
      m.api.pfUI.api.SkinTab( m.api.MailFrameTab3 )
      m.api.MailFrameTab3:ClearAllPoints()
      m.api.MailFrameTab3:SetPoint( "LEFT", m.api.MailFrameTab2, "RIGHT", border * 2 + 1, 0 )

      m.api.TurtleMailLogTitleText:ClearAllPoints()
      m.api.TurtleMailLogTitleText:SetPoint( "TOP", m.api.MailFrame.backdrop, "TOP", 0, -10 )

      m.api.pfUI.api.CreateBackdrop( m.api.TurtleMailLogScrollFrame )

      m.api.TurtleMailLogScrollFrame:SetHeight( 307 )
      m.api.TurtleMailLogScrollFrame:ClearAllPoints()
      m.api.TurtleMailLogScrollFrame:SetPoint( "TOPLEFT", 23, -90 )
      m.api.TurtleMailLogScrollFrame:SetWidth( 299 )
      m.api.TurtleMailLogEntriesFrame:ClearAllPoints()
      m.api.TurtleMailLogEntriesFrame:SetPoint( "TOPLEFT", 23, -90 )
      m.api.TurtleMailLogEntriesFrame:SetWidth( 299 )

      m.api.pfUI.api.StripTextures( m.api.TurtleMailLogItem10 )
      m.api.pfUI.api.SkinScrollbar( m.api.TurtleMailLogScrollFrameScrollBar )
      m.api.TurtleMailLogScrollFrameScrollBar:SetPoint( "TOPLEFT", m.api.TurtleMailLogScrollFrame, "TOPRIGHT", 6, -14 )
      m.api.TurtleMailLogScrollFrameScrollBar:SetPoint( "BOTTOMLEFT", m.api.TurtleMailLogScrollFrame, "BOTTOMRIGHT", 6, 14 )

      m.api.pfUI.api.SkinButton( m.api.TurtleMailLogSentButton )
      m.api.pfUI.api.SkinButton( m.api.TurtleMailLogReceivedButton )
      m.api.TurtleMailLogReceivedButton:ClearAllPoints()
      m.api.TurtleMailLogReceivedButton:SetPoint( "RIGHT", m.api.TurtleMailLogSentButton, "LEFT", -2 * bpad, 0 )

      m.api.pfUI.api.SkinButton( m.api.TurtleMailLogFiltersButton )
      m.api.TurtleMailLogFiltersButton:SetPoint( "TOPLEFT", 21, -58 )
      m.api.TurtleMailLogFiltersButton:GetFontString():SetFont( m.api.pfUI.font_default, 12 )
      m.api.TurtleMailLogFiltersButton:GetFontString():SetPoint( "TOPLEFT", 4, -4.5 )
      m.api.TurtleMailLogFiltersButton:SetWidth( 50 )
      m.api.TurtleMailLogFiltersButton:SetHeight( 20 )
      m.api.TurtleMailLogFiltersButtonArrow:SetPoint( "RIGHT", -4, -1 )
      m.api.TurtleMailLogFiltersButtonArrow:SetWidth( 8.5 )
      m.api.TurtleMailLogFiltersButtonArrow:SetHeight( 8.5 )
      m.api.TurtleMailLogFiltersButtonArrow:SetTexture( m.api.pfUI.media[ "img:down" ] )

      m.api.pfUI.api.StripTextures( m.api.TurtleMailLogStartTime )
      m.api.pfUI.api.SkinButton( m.api.TurtleMailLogStartTime )
      m.api.pfUI.api.SkinArrowButton( m.api.TurtleMailLogStartTimeButton, "down", 16 )
      m.api.TurtleMailLogStartTime:SetPoint( "TOPLEFT", 77, -58 )
      m.api.TurtleMailLogStartTimeText:SetPoint( "LEFT", 5, 0 )
      m.api.TurtleMailLogStartTimeButton:SetPoint( "LEFT", m.api.TurtleMailLogStartTime, "RIGHT", -19, 0 )
      m.api.TurtleMailLogStartTimeTitle:SetPoint( "TOPLEFT", 1, 13 )
      m.api.TurtleMailLogStartTimeTitle:SetFont( m.api.pfUI.font_default, 10 )
      m.api.TurtleMailLogStartTimeTitle:SetText( L[ "Period start" ] )

      m.api.pfUI.api.StripTextures( m.api.TurtleMailLogEndTime )
      m.api.pfUI.api.SkinButton( m.api.TurtleMailLogEndTime )
      m.api.pfUI.api.SkinArrowButton( m.api.TurtleMailLogEndTimeButton, "down", 16 )
      m.api.TurtleMailLogEndTime:SetPoint( "TOPLEFT", 163, -58 )
      m.api.TurtleMailLogEndTimeText:SetPoint( "LEFT", 5, 0 )
      m.api.TurtleMailLogEndTimeButton:SetPoint( "LEFT", m.api.TurtleMailLogEndTime, "RIGHT", -19, 0 )
      m.api.TurtleMailLogEndTimeTitle:SetPoint( "TOPLEFT", 1, 13 )
      m.api.TurtleMailLogEndTimeTitle:SetFont( m.api.pfUI.font_default, 10 )
      m.api.TurtleMailLogEndTimeTitle:SetText( L[ "Period end" ] )

      m.api.pfUI.api.SkinDropDown( m.api.TurtleMailLogPlayersDropDown, nil, nil, nil, true )
      m.api.UIDropDownMenu_SetWidth( 90, m.api.TurtleMailLogPlayersDropDown )
      m.api.TurtleMailLogPlayersDropDown:SetScale( 1 )
      m.api.TurtleMailLogPlayersDropDown:SetPoint( "TOPLEFT", 224, -54 )
      m.api.TurtleMailLogPlayersDropDown.backdrop:SetPoint( "TOPLEFT", 26, -4 )
      m.api.TurtleMailLogPlayersDropDown.backdrop:SetPoint( "BOTTOMRIGHT", -20, 8 )
      m.api.TurtleMailLogPlayersDropDown.button.backdrop:SetWidth( 16 )
      m.api.TurtleMailLogPlayersDropDown.button.backdrop:SetHeight( 16 )

      local label = m.api.TurtleMailLogFrame:CreateFontString( nil, "BACKGROUND", "GameFontNormal" )
      label:SetFont( m.api.pfUI.font_default, 10 )
      label:SetPoint( "TOPLEFT", 251, -45 )
      label:SetText( L[ "Players" ] )

      -- 美化 COD 复选框（带 pfUISkinned 防重复）
      if m.api.TurtleMailCODCheckButton and not m.api.TurtleMailCODCheckButton.pfUISkinned then
        m.api.TurtleMailCODCheckButton.pfUISkinned = true
        m.api.pfUI.api.SkinCheckbox(m.api.TurtleMailCODCheckButton)
      end

      -- 美化收件箱每封邮件左侧的勾选框（与自动到付复选框一致）
      for i = 1, 7 do
        local cb = m.api[ "TurtleMailBoxItem" .. i .. "CB" ]
        if cb and not cb.pfUISkinned then
          cb.pfUISkinned = true
          m.api.pfUI.api.SkinCheckbox( cb )
        end
      end

      -- 美化发件箱的 发送钱币/付款取信 单选按钮与 每封都到付 复选框
      --（pfUI 没有单选按钮美化，套用复选框样式：方框底 + 保留原单选圆点勾选纹理）
      for _, btn in { m.api.SendMailSendMoneyButton, m.api.SendMailCODButton, m.api.SendMailCODAllButton } do
        if btn and not btn.pfUISkinned then
          btn.pfUISkinned = true
          m.api.pfUI.api.SkinCheckbox( btn )
        end
      end

      -- 美化 MailTo 下拉按钮
      local mailToBtn = m.api.MailToDropDownMenu
      if mailToBtn and not mailToBtn.pfUISkinned then
        mailToBtn.pfUISkinned = true
        m.api.pfUI.api.SkinArrowButton(mailToBtn, "down", 16)
        -- 缩短收件人输入框：shrink 为缩短量（想改长度只动这个数），把按钮连同框右缘一起拉离邮资。
        -- 边框是左/中/右三段固定宽度贴图，中间段必须同步缩，否则边框和输入区错位
        local shrink = 22
        m.api.SendMailNameEditBox:SetWidth( m.api.SendMailNameEditBox:GetWidth() - shrink )
        m.api.SendMailNameEditBoxMiddle:SetWidth( m.api.SendMailNameEditBoxMiddle:GetWidth() - shrink )
        -- 按钮与输入框贴在一起：锚到右边框贴图的右缘（边框比框体短 14px，锚框体会有缝）；
        -- x 微调：0 为贴合，负值向框上重叠，正值留缝
        mailToBtn:ClearAllPoints()
        mailToBtn:SetPoint("LEFT", m.api.SendMailNameEditBoxRight, "RIGHT", 15, 0)
      end

      -- 美化收件人自动补全建议框（输入名字后弹出的玩家列表，Tab 切换）
      if m.api.MailAutoCompleteBox then
        -- 去掉原生 tooltip 背景/边框，换成 pfUI 背景
        -- 这里用 legacy 模式（第三个参数 true），让 pfUI 直接替换原生 SetBackdrop，
        -- 避免非 legacy 模式下原生 tooltip 背景纹理残留导致的指令行黄底问题
        m.api.pfUI.api.CreateBackdrop(m.api.MailAutoCompleteBox, nil, true, .75)
        for i = 1, (m.api.MAIL_AUTOCOMPLETE_MAX_BUTTONS or 5) do
          local btn = m.api["MailAutoCompleteButton" .. i]
          if btn then
            m.api.pfUI.api.SkinButton(btn)
          end
        end
        if m.api.MailAutoCompleteInstructions then
          m.api.MailAutoCompleteInstructions:SetFont(m.api.pfUI.font_default, 10)
          -- 指令行"按 Tab 键"补一层与按钮一致的背景条：
          -- 按钮区是 box 背景 + 按钮背景两层叠加，指令行只有 box 一层，会比按钮区浅，需补齐
          if not m.api.MailAutoCompleteInstructions.bg then
            local bg = m.api.CreateFrame("Frame", nil, m.api.MailAutoCompleteBox)
            bg:SetPoint("BOTTOMLEFT", m.api.MailAutoCompleteBox, "BOTTOMLEFT", 1, 1)
            bg:SetPoint("BOTTOMRIGHT", m.api.MailAutoCompleteBox, "BOTTOMRIGHT", -1, 1)
            bg:SetHeight(20)
            m.api.pfUI.api.CreateBackdrop(bg, nil, true)
            m.api.MailAutoCompleteInstructions:SetParent(bg)
            m.api.MailAutoCompleteInstructions:ClearAllPoints()
            m.api.MailAutoCompleteInstructions:SetPoint("LEFT", bg, "LEFT", 14, 0)
            m.api.MailAutoCompleteInstructions.bg = bg
          end
        end
      end
    end )
end
