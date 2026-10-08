local stf = strfind
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local UN = UnitName
local strform = string.format
local flr = floor
local strgfind = string.gfind
local strfind = string.find
local GT = GetTime
local tnbr = tonumber

function MPOWA:PlayAnim(condition, key, anim)
	if self.SAVE[key][condition] then
		if self.frames[key][1][anim] and not self.frames[key][1][anim]:IsPlaying() then
			self.frames[key][1][anim]:Play()
		end
	end
end

function MPOWA:FHide(key)
	local p = self.SAVE[key]
	if p and self.frames[key] and self.frames[key][1]:IsVisible() and not self.testall and not p["test"] then
		if p["useendsound"] then
			-- 先检查是否有第二个自定义音频文件
			if p.customsound2 and p.customsound2 ~= "" then
				PlaySoundFile("Interface\\AddOns\\ModifiedPowerAuras\\Sounds\\soundfile\\"..p.customsound2, "master", "throttle=false")
			else
				-- 否则播放滑动模块选择的音频文件
				if p.endsound < 16 then
					PlaySound(self.SOUND[p.endsound], "master")
				else
					PlaySoundFile("Interface\\AddOns\\ModifiedPowerAuras\\Sounds\\"..self.SOUND[p.endsound], "master", "throttle=false")
				end
			end
		end
		if p["batmananimout"] and self.frames[key][1].batmananimout and not self.frames[key][1].batmananimout:IsPlaying() then
			self:PlayAnim("batmananimout", key, "batmananimout")
		elseif p["shrinkanim"] and self.frames[key][1].translateanim and not self.frames[key][1].translateanim:IsPlaying() 
				and self.frames[key][1].fadeout and not self.frames[key][1].fadeout:IsPlaying() 
				and self.frames[key][1].rotateanimout and not self.frames[key][1].rotateanimout:IsPlaying() 
				and self.frames[key][1].shrink and not self.frames[key][1].shrink:IsPlaying() then
			-- Add nil checks before playing animations
			if self.frames[key][1].translateanim then self:PlayAnim("translateanim", key, "translateanim") end
			if self.frames[key][1].fadeout then self:PlayAnim("fadeout", key, "fadeout") end
			if self.frames[key][1].rotateanimout then self:PlayAnim("rotateanimout", key, "rotateanimout") end
			if self.frames[key][1].shrink then self:PlayAnim("shrinkanim", key, "shrink") end
		else
			if p["growout"] and self.frames[key][1].fadeout and not self.frames[key][1].fadeout:IsPlaying() 
				and self.frames[key][1].rotateanimout and not self.frames[key][1].rotateanimout:IsPlaying() 
				and self.frames[key][1].growout and not self.frames[key][1].growout:IsPlaying() then
				-- Add nil checks before playing animations
				if self.frames[key][1].fadeout then self:PlayAnim("fadeout", key, "fadeout") end
				if self.frames[key][1].rotateanimout then self:PlayAnim("rotateanimout", key, "rotateanimout") end
				if self.frames[key][1].growout then self:PlayAnim("growout", key, "growout") end
			elseif p["escapeanimout"] and self.frames[key][1].rotateanimout and not self.frames[key][1].rotateanimout:IsPlaying() 
				and self.frames[key][1].escapeanimout and not self.frames[key][1].escapeanimout:IsPlaying() then
				if self.frames[key][1].rotateanimout then self:PlayAnim("rotateanimout", key, "rotateanimout") end
				if self.frames[key][1].escapeanimout then self:PlayAnim("escapeanimout", key, "escapeanimout") end
			else
				if p["fadeout"] and self.frames[key][1].translateanim and not self.frames[key][1].translateanim:IsPlaying() 
					and self.frames[key][1].rotateanimout and not self.frames[key][1].rotateanimout:IsPlaying() 
					and self.frames[key][1].fadeout and not self.frames[key][1].fadeout:IsPlaying() then
					if self.frames[key][1].fadeout then self:PlayAnim("fadeout", key, "fadeout") end
				elseif p["translateanim"] and self.frames[key][1].rotateanimout and not self.frames[key][1].rotateanimout:IsPlaying() 
					and self.frames[key][1].translateanim and not self.frames[key][1].translateanim:IsPlaying() then
					if self.frames[key][1].rotateanimout then self:PlayAnim("rotateanimout", key, "rotateanimout") end
					if self.frames[key][1].translateanim then self:PlayAnim("translateanim", key, "translateanim") end
				else
					if self.frames[key][1].flash and self.frames[key][1].flash:IsPlaying() then
						self.frames[key][1].flash:Stop()
						self.frames[key][1]:SetAlpha(tnbr(p["alpha"]))
					end
					if p["rotateanimout"] and self.frames[key][1].rotateanimout and not self.frames[key][1].rotateanimout:IsPlaying() then
						self:PlayAnim("rotateanimout", key, "rotateanimout")
					else
						self:AfterAnimationDynamicGroup(key)
						self.frames[key][1]:Hide()
					end
				end
			end
		end
	end
end

function MPOWA:AfterAnimationDynamicGroup(key)
	local p = self.SAVE[key]
	if p then
		if p["isdynamicgroup"] then
			self:ApplyDynamicGroup(key)
		elseif p["groupnumber"] and tnbr(p["groupnumber"]) > 0 then
			self:ApplyDynamicGroup(tnbr(p["groupnumber"]))
		end
	end
end

function MPOWA:FShow(key)
	local p = self.SAVE[key]
	if p and self.frames[key] and self.frames[key][1] and not self.frames[key][1]:IsVisible() and p["used"] then
		if p["usebeginsound"] then
			-- 先检查是否有自定义音频文件
			if p.customsound and p.customsound ~= "" then
				PlaySoundFile("Interface\\AddOns\\ModifiedPowerAuras\\Sounds\\soundfile\\"..p.customsound, "Master", "throttle=false")
			else
				-- 否则播放滑动模块选择的音频文件
				if p.beginsound < 16 then
					PlaySound(self.SOUND[p.beginsound], "master")
				else
					PlaySoundFile("Interface\\AddOns\\ModifiedPowerAuras\\Sounds\\"..self.SOUND[p.beginsound], "master", "throttle=false")
				end
			end
		end
		if p["isdynamicgroup"] then
			self:ApplyDynamicGroup(key)
		elseif p["groupnumber"] and tnbr(p["groupnumber"]) > 0 then
			self:ApplyDynamicGroup(tnbr(p["groupnumber"]))
		end
		self.frames[key][1]:Show()
		if p["batmananimin"] and self.frames[key][1].batmananimin and not self.frames[key][1].batmananimin:IsPlaying() then
			self:PlayAnim("batmananimin", key, "batmananimin")
		elseif p["sizeanim"] and self.frames[key][1].fadein and not self.frames[key][1].fadein:IsPlaying() 
				and self.frames[key][1].rotateanimin and not self.frames[key][1].rotateanimin:IsPlaying()
				and self.frames[key][1].sizein and not self.frames[key][1].sizein:IsPlaying() then
			if self.frames[key][1].fadein then self:PlayAnim("fadein", key, "fadein") end
			if self.frames[key][1].rotateanimin then self:PlayAnim("rotateanimin", key, "rotateanimin") end
			if self.frames[key][1].sizein then self:PlayAnim("sizeanim", key, "sizein") end
		else
			if p["growin"] and self.frames[key][1].fadein and not self.frames[key][1].fadein:IsPlaying() 
				and self.frames[key][1].rotateanimin and not self.frames[key][1].rotateanimin:IsPlaying()
				and self.frames[key][1].growin and not self.frames[key][1].growin:IsPlaying() then
				if self.frames[key][1].fadein then self:PlayAnim("fadein", key, "fadein") end
				if self.frames[key][1].rotateanimin then self:PlayAnim("rotateanimin", key, "rotateanimin") end
				if self.frames[key][1].growin then self:PlayAnim("growin", key, "growin") end
			elseif p["escapeanimin"] and self.frames[key][1].rotateanimin and not self.frames[key][1].rotateanimin:IsPlaying() 
				and self.frames[key][1].escapeanimin and not self.frames[key][1].escapeanimin:IsPlaying() then
				if self.frames[key][1].rotateanimin then self:PlayAnim("rotateanimin", key, "rotateanimin") end
				if self.frames[key][1].escapeanimin then self:PlayAnim("escapeanimin", key, "escapeanimin") end
			else
				if p["fadein"] and self.frames[key][1].rotateanimin and not self.frames[key][1].rotateanimin:IsPlaying() 
					and self.frames[key][1].fadein and not self.frames[key][1].fadein:IsPlaying() then
					if self.frames[key][1].rotateanimin then self:PlayAnim("rotateanimin", key, "rotateanimin") end
					if self.frames[key][1].fadein then self:PlayAnim("fadein", key, "fadein") end
				elseif p["rotateanimin"] and self.frames[key][1].rotateanimin and not self.frames[key][1].rotateanimin:IsPlaying() then
					if self.frames[key][1].rotateanimin then self:PlayAnim("rotateanimin", key, "rotateanimin") end
				end
			end
		end
	end
end

function MPOWA:Flash(elapsed, cat, timeLeft)
	-- 增强的安全检查
	if not self or not self.SAVE or not cat or not self.frames or not self.SAVE[cat] or not self.frames[cat] or not self.frames[cat][1] then
		return
	end
	
	local s = self.SAVE[cat]
	local frame = self.frames[cat][1]
	
	-- 所有必要对象都存在才继续
	if not s or not frame or not s.flashanim or not frame.flash then
		return
	end
	
	-- 确保timeLeft是有效数字
	timeLeft = tnbr(timeLeft) or 0
	local flashStart = tnbr(s.flashanimstart) or 0
	local alpha = tnbr(s.alpha) or 1
	
	-- 判断是否应该播放动画
	local shouldPlay = timeLeft < flashStart
	
	-- 动画控制逻辑
	if shouldPlay then
		-- 确保frame是可见的
		if not frame:IsVisible() then
			return
		end
		
		if not frame.flash:IsPlaying() then
			-- 保存原始透明度并设置动画起始透明度
			frame:SetAlpha(alpha)
			frame.flash:Play()
		end
	else
		-- 停止动画并恢复透明度
		if frame.flash:IsPlaying() then
			frame.flash:Stop()
			-- 恢复到配置的透明度
			frame:SetAlpha(alpha)
		end
	end
end

function MPOWA:AddAnimFlash(frame)
	if frame and self.frames[frame] and self.frames[frame][1] and not self.frames[frame][1].flash then
		-- 创建动画组，但不使用系统的BOUNCE循环
		self.frames[frame][1].flash = self.frames[frame][1]:CreateAnimationGroup()
		-- 设置为单次播放模式
		self.frames[frame][1].flash:SetLooping("NONE")
		
		-- 存储动画状态
		self.frames[frame][1].flash.isBouncing = false
		self.frames[frame][1].flash.originalAlpha = tnbr(self.SAVE[frame]["alpha"]) or 1
		
		-- 自定义BOUNCE循环逻辑
		self.frames[frame][1].flash:SetScript("OnFinished", function(animGroup)
			if self and self.frames[frame] and self.frames[frame][1] then
				local f = self.frames[frame][1]
				local currentAlpha = f:GetAlpha()
				local targetAlpha
				-- 设置changeValue为-1.0以确保可以达到完全透明(0)
				local changeValue = -1.0
				
				-- 切换动画方向（BOUNCE效果）
				if animGroup.isBouncing then
					-- 恢复到原始透明度
					targetAlpha = animGroup.originalAlpha
					animGroup.isBouncing = false
				else
					-- 减少透明度到0
					targetAlpha = 0
					animGroup.isBouncing = true
				end
				
				-- 清除现有动画
				animGroup:Stop()
				animGroup:ClearAllPoints()
				
				-- 创建新的Alpha动画
				local anim = animGroup:CreateAnimation("Alpha")
				anim:SetStartDelay(0)
				-- 设置半程动画持续时间为0.5秒，以确保完整循环为1秒
				anim:SetDuration(0.5)
				
				-- 设置正确的透明度变化值
				if animGroup.isBouncing then
					anim:SetChange(changeValue)
				else
					anim:SetChange(-changeValue) -- 反向变化
				end
				
				-- 如果动画还在进行中（没有被停止），继续播放
				if f.flash and f.flash._isPlaying then
					animGroup:Play()
				end
			end
		end)
		
		-- 创建初始Alpha动画
		local anim = self.frames[frame][1].flash:CreateAnimation("Alpha")
		-- 设置为-1.0以确保可以达到完全透明(0)
		anim:SetChange(-1.0)
		-- 设置半程动画持续时间为0.5秒
		anim:SetDuration(0.5)
		
		-- 重写Play和Stop方法以添加控制标志
		local originalPlay = self.frames[frame][1].flash.Play
		local originalStop = self.frames[frame][1].flash.Stop
		
		self.frames[frame][1].flash.Play = function(self)
			self._isPlaying = true
			self.isBouncing = false
			if self:GetParent() then
				self:GetParent():SetAlpha(self.originalAlpha)
			end
			return originalPlay(self)
		end
		
		self.frames[frame][1].flash.Stop = function(self)
			self._isPlaying = false
			if self:GetParent() and self.originalAlpha then
				self:GetParent():SetAlpha(self.originalAlpha)
			end
			return originalStop(self)
		end
	end
end

function MPOWA:AddAnimGrowOut(frame)
	if frame and self.frames[frame] and self.frames[frame][1] and not self.frames[frame][1].growout then
		self.frames[frame][1].growout = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].growout:SetLooping("NONE")
		self.frames[frame][1].growout:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].growout:Stop()
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		local scale = self.frames[frame][1].growout:CreateAnimation("Scale")
		scale:SetScale(tnbr(self.SAVE[frame]["scalefactor"]), tnbr(self.SAVE[frame]["scalefactor"]))
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimFadeIn(frame)
	if not self.frames[frame][1].fadein then
		self.frames[frame][1].fadein = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].fadein:SetLooping("NONE")
		self.frames[frame][1].fadein:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].fadein:Stop()
			MPOWA.frames[frame][1]:SetAlpha(tnbr(self.SAVE[frame]["alpha"]))
			MPOWA.frames[frame][1]:Show()
		end)
		
		local anim = self.frames[frame][1].fadein:CreateAnimation("Alpha")
		anim:SetChange(tnbr(self.SAVE[frame]["fadealpha"]))
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimFadeOut(frame)
	if not self.frames[frame][1].fadeout then
		self.frames[frame][1].fadeout = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].fadeout:SetLooping("NONE")
		self.frames[frame][1].fadeout:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].fadeout:Stop()
			MPOWA.frames[frame][1]:SetAlpha(tnbr(self.SAVE[frame]["alpha"]))
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		
		local anim = self.frames[frame][1].fadeout:CreateAnimation("Alpha")
		anim:SetChange(-tnbr(self.SAVE[frame]["fadealpha"]))
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimRotateOut(frame)
	if not self.frames[frame][1].rotateanimout then
		self.frames[frame][1].rotateanimout = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].rotateanimout:SetLooping("NONE")
		self.frames[frame][1].rotateanimout:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].rotateanimout:Stop()
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		
		local anim = self.frames[frame][1].rotateanimout:CreateAnimation("Rotation")
		anim:SetDegrees(360)
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimTranslate(frame)
	if not self.frames[frame][1].translateanim then
		self.frames[frame][1].translateanim = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].translateanim:SetLooping("NONE")
		self.frames[frame][1].translateanim:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].translateanim:Stop()
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		
		local anim = self.frames[frame][1].translateanim:CreateAnimation("Translation")
		anim:SetOffset(tnbr(self.SAVE[frame]["translateoffsetx"]),tnbr(self.SAVE[frame]["translateoffsetx"]))
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimEscapeOut(frame)
	if not self.frames[frame][1].escapeanimout then
		self.frames[frame][1].escapeanimout = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].escapeanimout:SetLooping("BOUNCE")
		self.frames[frame][1].escapeanimout:SetScript("OnLoop", function()
			self.frames[frame][1].escapeanimout:Finish()
		end)
		self.frames[frame][1].escapeanimout:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].escapeanimout:Stop()
			MPOWA.frames[frame][1]:SetAlpha(tnbr(self.SAVE[frame]["alpha"]))
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		
		local alpha = self.frames[frame][1].escapeanimout:CreateAnimation("Alpha")
		alpha:SetChange(-.5)
		alpha:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
		
		local scale = self.frames[frame][1].escapeanimout:CreateAnimation("Scale")
		scale:SetScale(tnbr(self.SAVE[frame]["scalefactor"]), tnbr(self.SAVE[frame]["scalefactor"]))
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimShrink(frame)
	if not self.frames[frame][1].shrink then
		self.frames[frame][1].shrink = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].shrink:SetLooping("NONE")
		self.frames[frame][1].shrink:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].shrink:Stop()
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		
		local scale = self.frames[frame][1].shrink:CreateAnimation("Scale")
		scale:SetScale(-tnbr(self.SAVE[frame]["scalefactor"]), -tnbr(self.SAVE[frame]["scalefactor"]))
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimRotateShrinkFadeOut(frame)
	if not self.frames[frame][1].batmananimout then
		self.frames[frame][1].batmananimout = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].batmananimout:SetLooping("NONE")
		self.frames[frame][1].batmananimout:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].batmananimout:Stop()
			MPOWA.frames[frame][1]:SetAlpha(tnbr(self.SAVE[frame]["alpha"]))
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Hide()
			MPOWA:AfterAnimationDynamicGroup(frame)
		end)
		
		local scale = self.frames[frame][1].batmananimout:CreateAnimation("Scale")
		scale:SetScale(-10, -10)
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
		
		local anim = self.frames[frame][1].batmananimout:CreateAnimation("Rotation")
		anim:SetDegrees(1081)
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
		
		local alpha = self.frames[frame][1].batmananimout:CreateAnimation("Alpha")
		alpha:SetChange(-tnbr(self.SAVE[frame]["fadealpha"]))
		alpha:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimGrowIn(frame)
	if not self.frames[frame][1].growin then
		self.frames[frame][1].growin = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].growin:SetLooping("NONE")
		self.frames[frame][1].growin:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].growin:Stop()
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Show()
		end)
		
		local scale = self.frames[frame][1].growin:CreateAnimation("Scale")
		scale:SetScale(tnbr(self.SAVE[frame]["scalefactor"]), tnbr(self.SAVE[frame]["scalefactor"]))
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimRotateIn(frame)
	if not self.frames[frame][1].rotateanimin then
		self.frames[frame][1].rotateanimin = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].rotateanimin:SetLooping("NONE")
		self.frames[frame][1].rotateanimin:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].rotateanimin:Stop()
			MPOWA.frames[frame][1]:Show()
		end)
		
		local anim = self.frames[frame][1].rotateanimin:CreateAnimation("Rotation")
		anim:SetDegrees(-360)
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimRotateShrinkFadeIn(frame)
	if not self.frames[frame][1].batmananimin then
		self.frames[frame][1].batmananimin = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].batmananimin:SetLooping("BOUNCE")
		self.frames[frame][1].batmananimin:SetScript("OnLoop", function()
			self.frames[frame][1].batmananimin:Finish()
		end)
		self.frames[frame][1].batmananimin:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].batmananimin:Stop()
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Show()
		end)
		
		local scale = self.frames[frame][1].batmananimin:CreateAnimation("Scale")
		scale:SetScale(-10, -10)
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
		
		local anim = self.frames[frame][1].batmananimin:CreateAnimation("Rotation")
		anim:SetDegrees(1080.5)
		anim:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimSizeIn(frame)
	if not self.frames[frame][1].sizein then
		self.frames[frame][1].sizein = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].sizein:SetLooping("BOUNCE")
		self.frames[frame][1].sizein:SetScript("OnLoop", function()
			self.frames[frame][1].sizein:Finish()
		end)
		self.frames[frame][1].sizein:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].sizein:Stop()
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Show()
		end)
		
		local scale = self.frames[frame][1].sizein:CreateAnimation("Scale")
		scale:SetScale(-tnbr(self.SAVE[frame]["scalefactor"]), -tnbr(self.SAVE[frame]["scalefactor"]))
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end

function MPOWA:AddAnimEscapeIn(frame)
	if not self.frames[frame][1].escapeanimin then
		self.frames[frame][1].escapeanimin = self.frames[frame][1]:CreateAnimationGroup()
		self.frames[frame][1].escapeanimin:SetLooping("BOUNCE")
		self.frames[frame][1].escapeanimin:SetScript("OnLoop", function()
			self.frames[frame][1].escapeanimin:Finish()
		end)
		self.frames[frame][1].escapeanimin:SetScript("OnFinished", function() 
			MPOWA.frames[frame][1].escapeanimin:Stop()
			MPOWA.frames[frame][1]:SetAlpha(tnbr(self.SAVE[frame]["alpha"]))
			MPOWA.frames[frame][1]:SetWidth(64)
			MPOWA.frames[frame][1]:SetHeight(64)
			MPOWA.frames[frame][1]:Show()
		end)
		
		local alpha = self.frames[frame][1].escapeanimin:CreateAnimation("Alpha")
		alpha:SetChange(-.5)
		alpha:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
		
		local scale = self.frames[frame][1].escapeanimin:CreateAnimation("Scale")
		scale:SetScale(tnbr(self.SAVE[frame]["scalefactor"]), tnbr(self.SAVE[frame]["scalefactor"]))
		scale:SetDuration(tnbr(self.SAVE[frame]["animduration"]))
	end
end