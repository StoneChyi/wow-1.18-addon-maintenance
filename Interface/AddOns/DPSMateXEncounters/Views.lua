local D,C=DPSMateX,DPSMateX.Encounters
local names={boss="Boss汇总",trash="小怪汇总"}

function C:Scope(key)
    local w=D.Settings.windows[key or 1]
    if not w then return end
    local options=w.options[2]
    if options.bossall then return "boss" end
    if options.trashall then return "trash" end
end

function C:ValidateScope(key,selection)
    if selection~="bossall" and selection~="trashall" then return selection end
    if self.ready and self.available and self.supported[D.Settings.windows[key].CurMode] then return selection end
    local mode=D.Settings.windows[key].CurMode
    self.warnings=self.warnings or {}
    if not self.warnings[mode] then
        self.warnings[mode]=true
        D:SendMessage(self.available and "此模块只支持原有战斗范围，已切换到当前战斗。" or "战斗分类需要Nampower扩展，已切换到当前战斗。")
    end
    return "currentfight"
end

function C:Normalize(key)
    local scope=self:Scope(key)
    if scope and self:ValidateScope(key,scope.."all")=="currentfight" then
        D.Options:ToggleSegment(key,"currentfight")
        return nil
    end
    return scope
end

-- Cache only the category that a visible window requests. No duplicate timelines.
function C:View(scope,category)
    local base=self.db.buckets[scope]
    local f=self.db.current
    if not f or f.settled or f.kind~=scope then return base end
    local stamp=math.floor(GetTime())
    local cacheKey=scope..":"..(category or "insights")
    local cached=self.cache[cacheKey]
    if cached and cached.stamp==stamp then return cached.value end
    local view=self:NewBucket()
    local function merge(source)
        if category then self:MergeCore(view.core,{[category]=source.core[category] or {}},view)
        else self:MergeInsights(view,source,view) end
        for name,value in pairs(source.effective or {}) do view.effective[name]=(view.effective[name] or 0)+value end
        view.detailTrimmed=view.detailTrimmed or source.detailTrimmed
    end
    merge(base);merge(f.pending)
    if category then
        local schema=self.schemas[category]
        local rows=f.frozen and f.frozen.core[category] or (schema and D.DBCache[schema.path][2])
        self:MergeCore(view.core,{[category]=rows or {}},view)
    else
        local E=D.Insights
        if E and E.ready then self:MergeInsights(view,E.db.current,view) end
    end
    local effective=f.frozen and f.frozen.effective or D.CombatTime.effective[2]
    for name,value in pairs(effective) do view.effective[name]=(view.effective[name] or 0)+value end
    view.duration=base.duration+self:Elapsed(f);view.fightCount=base.fightCount+1
    view.active=f.active;view.scopeName=names[scope]
    local count=0;for _ in pairs(self.cache) do count=count+1 end
    if count>=self.limits.views then self.cache={} end
    self.cache[cacheKey]={stamp=stamp,value=view}
    return view
end

function C:GetCore(key,category)
    local view=self:View(self:Scope(key),category)
    return view.core[category] or {},math.max(1.5,view.duration),view.effective
end

function C:GetCoreByArr(arr,key)
    for category,schema in pairs(self.schemas) do
        if D.DBCache[schema.path]==arr then return self:GetCore(key,category) end
    end
    local view=self:View(self:Scope(key),"unsupported")
    return {},math.max(1.5,view.duration),view.effective
end

function C:GetInsights(key,kind)
    if kind=="playback" then return {unsupported=true},0,{} end
    local scope=self:Scope(key)
    local view=self:View(scope)
    view.scopeName=names[scope]
    return view,math.max(1,view.duration),view.effective
end

function C:ScopeName(key)
    local scope=self:Scope(key)
    local b=self.db.buckets[scope];local f=self.db.current
    local count=b.fightCount+((f and not f.settled and f.kind==scope) and 1 or 0)
    return names[scope].."（"..count.."场）"
end

function C:InstallMenus()
    local options=D.Options.Options[2]
    if not options or not options.args then return end
    for scope,name in pairs(names) do
        local id=scope.."all"
        options.args[id]={order=scope=="boss" and 25 or 26,type="toggle",name=name,
            desc="累计已识别的"..name.."，与历史记录独立保存。",
            disabled=function() return not C.available end,
            get=function() return D.Settings.windows[D.Options.Dewdrop:GetOpenedParent().Key].options[2][id] end,
            set=function() D.Options:ToggleDrewDrop(2,id,D.Options.Dewdrop:GetOpenedParent()) end}
    end
end

C.detailTitles={
    DetailsAbsorbs={"DPSMateX_Details_Absorbs_Title","DPSMateX_Details_CompareAbsorbs_Title"},
    DetailsAbsorbsTaken={"DPSMateX_Details_AbsorbsTaken_Title","DPSMateX_Details_CompareAbsorbsTaken_Title"},
    DetailsAbsorbsTakenTotal={"DPSMateX_Details_AbsorbsTakenTotal_Title"},
    DetailsAbsorbsTotal={"DPSMateX_Details_AbsorbsTotal_Title"},
    DetailsAurasTotal={"DPSMateX_Details_AurasTotal_Title"},
    DetailsCCBreaker={"DPSMateX_Details_CCBreaker_Title","DPSMateX_Details_CompareCCBreaker_Title"},
    DetailsCCBreakerTotal={"DPSMateX_Details_CCBreakerTotal_Title"},
    DetailsCasts={"DPSMateX_Details_Casts_Title","DPSMateX_Details_CompareCasts_Title"},
    DetailsCastsTotal={"DPSMateX_Details_CastsTotal_Title"},
    DetailsCureDisease={"DPSMateX_Details_CompareCureDisease_Title","DPSMateX_Details_CureDisease_Title"},
    DetailsCureDiseaseReceived={"DPSMateX_Details_CompareCureDiseaseReceived_Title","DPSMateX_Details_CureDiseaseReceived_Title"},
    DetailsCureDiseaseTotal={"DPSMateX_Details_CureDisease_Total_Title"},
    DetailsCurePoison={"DPSMateX_Details_CompareCurePoison_Title","DPSMateX_Details_CurePoison_Title"},
    DetailsCurePoisonReceived={"DPSMateX_Details_CompareCurePoisonReceived_Title","DPSMateX_Details_CurePoisonReceived_Title"},
    DetailsCurePoisonTotal={"DPSMateX_Details_CurePoison_Total_Title"},
    DetailsDamage={"DPSMateX_Details_CompareDamage_Title","DPSMateX_Details_Title"},
    DetailsDamageTaken={"DPSMateX_Details_CompareDamageTaken_Title","DPSMateX_Details_DamageTaken_Title"},
    DetailsDamageTakenTotal={"DPSMateX_Details_DamageTakenTotal_Title"},
    DetailsDamageTotal={"DPSMateX_Details_DamageTotal_Title"},
    DetailsDeaths={"DPSMateX_Details_CompareDeaths_Title","DPSMateX_Details_Deaths_Title"},
    DetailsDeathsTotal={"DPSMateX_Details_Deaths_Total_Title"},
    DetailsDecurses={"DPSMateX_Details_CompareDecurses_Title","DPSMateX_Details_Decurses_Title"},
    DetailsDecursesReceived={"DPSMateX_Details_CompareDecursesReceived_Title","DPSMateX_Details_DecursesReceived_Title"},
    DetailsDecursesTotal={"DPSMateX_Details_Decurses_Total_Title"},
    DetailsDispels={"DPSMateX_Details_CompareDispels_Title","DPSMateX_Details_Dispels_Title"},
    DetailsDispelsReceived={"DPSMateX_Details_CompareDispelsReceived_Title","DPSMateX_Details_DispelsReceived_Title"},
    DetailsDispelsTotal={"DPSMateX_Details_Dispels_Total_Title"},
    DetailsEDD={"DPSMateX_Details_CompareEDD_Title","DPSMateX_Details_EDD_Title"},
    DetailsEDDTotal={"DPSMateX_Details_EDDTotal_Title"},
    DetailsEDT={"DPSMateX_Details_CompareEDT_Title","DPSMateX_Details_EDT_Title"},
    DetailsEDTTotal={"DPSMateX_Details_EDTTotal_Title"},
    DetailsEHealing={"DPSMateX_Details_CompareEHealing_Title","DPSMateX_Details_EHealing_Title"},
    DetailsEHealingTaken={"DPSMateX_Details_CompareEHealingTaken_Title","DPSMateX_Details_EHealingTaken_Title"},
    DetailsEHealingTakenTotal={"DPSMateX_Details_EHealingTakenTotal_Title"},
    DetailsEHealingTotal={"DPSMateX_Details_EHealingTotal_Title"},
    DetailsFF={"DPSMateX_Details_CompareFF_Title","DPSMateX_Details_FF_Title"},
    DetailsFFT={"DPSMateX_Details_CompareFFT_Title","DPSMateX_Details_FFT_Title"},
    DetailsFFTTotal={"DPSMateX_Details_FFTTotal_Title"},
    DetailsFFTotal={"DPSMateX_Details_FFTotal_Title"},
    DetailsFails={"DPSMateX_Details_CompareFails_Title","DPSMateX_Details_Fails_Title"},
    DetailsFailsTotal={"DPSMateX_Details_FailsTotal_Title"},
    DetailsHABTotal={"DPSMateX_Details_HABTotal_Title"},
    DetailsHealing={"DPSMateX_Details_CompareHealing_Title","DPSMateX_Details_Healing_Title"},
    DetailsHealingAndAbsorbs={"DPSMateX_Details_CompareHealingAndAbsorbs_Title","DPSMateX_Details_HealingAndAbsorbs_Title"},
    DetailsHealingTaken={"DPSMateX_Details_CompareHealingTaken_Title","DPSMateX_Details_HealingTaken_Title"},
    DetailsHealingTakenTotal={"DPSMateX_Details_HealingTakenTotal_Title"},
    DetailsHealingTotal={"DPSMateX_Details_HealingTotal_Title"},
    DetailsInterrupts={"DPSMateX_Details_CompareInterrupts_Title","DPSMateX_Details_Interrupts_Title"},
    DetailsInterruptsTotal={"DPSMateX_Details_Interrupts_Total_Title"},
    DetailsLiftMagic={"DPSMateX_Details_CompareLiftMagic_Title","DPSMateX_Details_LiftMagic_Title"},
    DetailsLiftMagicReceived={"DPSMateX_Details_CompareLiftMagicReceived_Title","DPSMateX_Details_LiftMagicReceived_Title"},
    DetailsLiftMagicTotal={"DPSMateX_Details_LiftMagic_Total_Title"},
    DetailsOHealingTaken={"DPSMateX_Details_CompareOHealingTaken_Title","DPSMateX_Details_OHealingTaken_Title"},
    DetailsOverhealing={"DPSMateX_Details_CompareOverhealing_Title","DPSMateX_Details_Overhealing_Title"},
    DetailsOverhealingTakenTotal={"DPSMateX_Details_OverhealingTakenTotal_Title"},
    DetailsOverhealingTotal={"DPSMateX_Details_OverhealingTotal_Title"},
    DetailsProcs={"DPSMateX_Details_CompareProcs_Title","DPSMateX_Details_Procs_Title"},
    DetailsProcsTotal={"DPSMateX_Details_ProcsTotal_Title"},
    DetailsSunderArmor={"DPSMateX_Details_CompareSunderArmor_Title","DPSMateX_Details_SunderArmor_Title"},
    DetailsSunderArmorTotal={"DPSMateX_Details_SunderArmorTotal_Title"},
}

function C:InstallDetailHooks()
    for name,module in pairs(D.Modules or {}) do
        if string.find(name,"^Details") and not module.encounterHooked then
            module.encounterHooked=true
            local moduleName=name
            for _,method in ipairs({"UpdateDetails","UpdateCompare"}) do
                local old=module[method]
                if old then module[method]=function(self,user,key,...)
                    self.encounterKey=key or 1
                    old(self,user,key,unpack(arg))
                    local titles=C.detailTitles and C.detailTitles[moduleName]
                    if titles and C:Scope(self.encounterKey) then
                        for _,titleName in ipairs(titles) do
                            local title=getglobal(titleName)
                            if title and not string.find(title:GetText() or "","汇总",1,true) then
                                title:SetText((title:GetText() or "").." · "..C:ScopeName(self.encounterKey))
                            end
                        end
                    end
                end end
            end

        end
    end
end
