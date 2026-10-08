pfUI.addonskinner:RegisterSkin("aDF", function()
  -- Получаем необходимые функции pfUI
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinButton, SkinCheckbox, SkinDropDown, SkinSlider, SetHighlight, hooksecurefunc = 
    penv.StripTextures, penv.CreateBackdrop, penv.SkinButton, penv.SkinCheckbox, penv.SkinDropDown, penv.SkinSlider, penv.SetHighlight, penv.hooksecurefunc

  -- 1. Скинирование главного фрейма (aDF)
  if aDF then
    -- Удаляем стандартный бэкдроп и текстуры
    StripTextures(aDF)
    -- Применяем бэкдроп pfUI (альфа 0.75 для основного фрейма)
    CreateBackdrop(aDF, nil, nil, 0.75)
    
    -- Исправляем цвет бэкдропа, который задается в aDF:Init
    hooksecurefunc(aDF, "Init", function(self)
        -- Перезатираем SetBackdropColor, чтобы использовать цвет pfUI
        self:SetBackdropColor(0,0,0,0) 
    end)
  end

  -- 2. Скинирование кнопок дебаффов и тултипа.
  -- Используем hooksecurefunc, чтобы кнопки были созданы функцией aDF:Init.
  if aDF then
    hooksecurefunc(aDF, "Init", function()
      -- Скинируем все кнопки дебаффов (aDF_frames)
      for name, frame in pairs(aDF_frames) do
        -- Удаляем стандартный черный бэкдроп из aDF.Create_frame
        StripTextures(frame)
        -- Применяем бэкдроп pfUI для кнопок (альфа 0.9 для лучшей видимости)
        CreateBackdrop(frame, nil, nil, 0.9)
        -- Добавляем эффект наведения
        SetHighlight(frame)
        -- Иконка (frame.icon) и текст (frame.nr) остаются нетронутыми, т.к. они являются дочерними элементами.
      end
      
      -- Скинируем тултип, используемый аддоном
      if aDF_tooltip then
        StripTextures(aDF_tooltip)
        CreateBackdrop(aDF_tooltip, nil, nil, 0.85)
      end
    end)
  end
  
  -- 3. Скинирование окна опций (aDF.Options) и его элементов
  -- Используем hooksecurefunc, чтобы элементы были созданы функцией aDF.Options:Gui.
  if aDF.Options then
    hooksecurefunc(aDF.Options, "Gui", function(self)
      -- Скинируем сам фрейм опций
      StripTextures(self)
      CreateBackdrop(self, nil, nil, 0.75)
      
      -- Скинируем чекбоксы
      for name, frame in pairs(aDF_guiframes) do
        SkinCheckbox(frame, 20)
        -- Аддон добавляет свою иконку, которую нужно скрыть, чтобы не конфликтовать со скином
        if frame.Icon then
          frame.Icon:SetTexture(nil)
          frame.Icon:Hide()
        end
      end
      
      -- Скинируем Слайдер
      if self.Slider then
        SkinSlider(self.Slider)
      end
      
      -- Скинируем DropDown
      if self.dropdown then
        SkinDropDown(self.dropdown)
      end
      
      -- Скинируем кнопку "Done"
      if self.dbutton then
        StripTextures(self.dbutton)
        SkinButton(self.dbutton)
      end
      
      -- Скинируем кастомные разделительные линии
      if self.left and self.right then
        StripTextures(self.left)
        StripTextures(self.right)
      end
    end)
  end

  pfUI.addonskinner:UnregisterSkin("aDF")
end)