from pathlib import Path
import re
root=Path(r'E:/1.18/Interface/AddOns')
def edit(path, fn):
    p=root/path
    data=p.read_bytes().decode('utf-8-sig').replace('\r\n','\n')
    result=fn(data)
    p.write_bytes(result.replace('\n','\r\n').encode('utf-8'))
def replace(data,old,new,count=1):
    assert data.count(old)>=count, old
    return data.replace(old,new,count)
def core(s):
    s=replace(s,'\tk = k or 1\n\tlocal Handler', '\tk = k or 1\n\tself:NormalizeEncounterScope(k)\n\tlocal Handler')
    s=replace(s,'\tlocal result = {\n\t\ttotal={','\tif self.Encounters and self.Encounters.ready and self.Encounters:Scope(k) then\n\t\treturn self.Encounters:GetCore(k, Handler.Hist)\n\tend\n\tlocal result = {\n\t\ttotal={')
    s=replace(s,'function DPSMateX:GetModeByArr(arr, k, Hist)\n','function DPSMateX:GetModeByArr(arr, k, Hist)\n\tk = k or 1\n\tself:NormalizeEncounterScope(k)\n\tif self.Encounters and self.Encounters.ready and self.Encounters:Scope(k) then return self.Encounters:GetCoreByArr(arr,k) end\n')
    s=replace(s,'function DPSMateX:GetModeName(k)\n\tk = k or 1','function DPSMateX:GetModeName(k)\n\tk = k or 1\n\tself:NormalizeEncounterScope(k)\n\tif self.Encounters and self.Encounters.ready and self.Encounters:Scope(k) then return self.Encounters:ScopeName(k) end')
    marker='local nampower_events = {'
    helper='''function DPSMateX:NormalizeEncounterScope(k)
    local options=self.Settings.windows[k].options[2]
    if not options.bossall and not options.trashall then return end
    if self.Encounters and self.Encounters.ready then self.Encounters:Normalize(k)
    else
        for key in pairs(options) do options[key]=false end
        options.currentfight=true
        local module=self.RegistredModules[self.Settings.windows[k].CurMode]
        if module then module.acceptNewValues=module.acceptNewValues or {};module.acceptNewValues[k]=true end
    end
end

function DPSMateX:GetSelectedEffectiveTime(k)
    local rows,duration,effective=self:GetMode(k)
    return type(effective)=="table" and effective or {}
end

'''
    s=replace(s,marker,helper+marker)
    s=replace(s,'\t\tif DPSMateX.Insights then DPSMateX.Insights:Reset() end','\t\tif DPSMateX.Encounters then DPSMateX.Encounters:Reset() end\n\t\tif DPSMateX.Insights then DPSMateX.Insights:Reset() end')
    s=replace(s,'\tif DPSMateX.Insights then DPSMateX.Insights:Initialize() end','\tif DPSMateX.Insights then\n\t\tDPSMateX.Insights:Initialize()\n\t\tif self:IsCombatActive() then DPSMateX.Insights:StartCombat() end\n\tend\n\tif DPSMateX.Encounters then DPSMateX.Encounters:Initialize() end')
    s=replace(s,'function DPSMateX.DB:ResetCurrentFight()\n','function DPSMateX.DB:ResetCurrentFight()\n\tif DPSMateX.Encounters then DPSMateX.Encounters:BeforeReset() end\n')
    s=replace(s,'.." "..DPSMateX.Pool.size())','.." "..DPSMateX.Pool.size()..((self.Encounters and self.Encounters.ready and self.Encounters:Scope(k)) and (" · "..self.Encounters:ScopeName(k)) or ""))')
    return s
edit(Path('DPSMateX/DPSMateX.lua'),core)
def builder(s):
    s=s.replace('if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end','if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end\n\t\tif DPSMateX.Encounters then DPSMateX.Encounters:Start() end')
    s=replace(s,'if DPSMateX.Insights then DPSMateX.Insights:EndCombat() end','if DPSMateX.Insights then DPSMateX.Insights:EndCombat() end\n\t\t\tif DPSMateX.Encounters then DPSMateX.Encounters:End() end')
    s=replace(s,'function DPSMateX.DB:OnUpdate()\n\tlocal arg1 = arg1','function DPSMateX.DB:OnUpdate()\n\tlocal arg1 = arg1\n\tif DPSMateX.Encounters then DPSMateX.Encounters:OnUpdate(arg1) end')
    s=replace(s,'\tif extension then extension:PrepareEvent(ev,a1,a2,a3,a4) end','\tif extension then extension:PrepareEvent(ev,a1,a2,a3,a4) end\n\tif DPSMateX.Encounters then DPSMateX.Encounters:PrepareEvent(ev,a1,a2,a3,a4) end')
    return s
edit(Path('DPSMateX/DPSMateX_DataBuilder.lua'),builder)
def options(s):
    s=replace(s,'\t\t\tlocal bossname = DPSMateX.BabbleBoss:Contains(name)','\t\t\tlocal encounter=DPSMateX.Encounters\n\t\t\tlocal fight=encounter and encounter.ready and encounter.db.current\n\t\t\tlocal classifiedBoss=fight and fight.kind=="boss"\n\t\t\tif classifiedBoss and fight.name and not segname then name=fight.name end\n\t\t\tlocal bossname = classifiedBoss or DPSMateX.BabbleBoss:Contains(name)')
    s=replace(s,'\tDPSMateX.Options.Options[3]["args"]["deletesegment"]["args"] = {}','\tif DPSMateX.Encounters and DPSMateX.Encounters.ready then DPSMateX.Encounters:InstallMenus() end\n\tDPSMateX.Options.Options[3]["args"]["deletesegment"]["args"] = {}')
    s=replace(s,'function DPSMateX.Options:ToggleSegment(k, obj)\n','function DPSMateX.Options:ToggleSegment(k, obj)\n\tif DPSMateX.Encounters then obj=DPSMateX.Encounters:ValidateScope(k,obj)\n\telseif obj=="bossall" or obj=="trashall" then obj="currentfight" end\n')
    s=replace(s,'(obj == "total" or obj == "currentfight")','(obj == "total" or obj == "currentfight" or obj == "bossall" or obj == "trashall")')
    return s
edit(Path('DPSMateX/DPSMateX_Options.lua'),options)
edit(Path('DPSMateXInsights/Core.lua'),lambda s:replace(s,'    local s = self.db.current\n    local options = D.Settings.windows[key].options[2]','    if D.Encounters and D.Encounters.ready and D.Encounters:Normalize(key) then return D.Encounters:GetInsights(key,kind) end\n    local s = self.db.current\n    local options = D.Settings.windows[key].options[2]'))
edit(Path('DPSMateXInsights/Modules.lua'),lambda s:replace(s,'module.Kind=="playback" and D.Settings.windows[parent.Key].options[2].total','module.Kind=="playback" and (D.Settings.windows[parent.Key].options[2].total or D.Settings.windows[parent.Key].options[2].bossall or D.Settings.windows[parent.Key].options[2].trashall)'))
def details(s):
    s=replace(s,'    w.title:SetText(self.names[w.kind].." — "..(w.person or "团队总览"))','    if s.aggregate and (w.view=="graph" or w.view=="audit") then w.view=w.person and "skills" or "players" end\n    w.title:SetText(self.names[w.kind].." — "..(w.person or "团队总览")..(s.scopeName and (" · "..s.scopeName) or ""))')
    s=replace(s,'and s~=self.db.total','and s~=self.db.total and not s.aggregate')
    s=replace(s,'    w.note:SetText(note)','    if s.aggregate then note="累计范围，"..(s.fightCount or 0).."场战斗"..(s.detailTrimmed and "；超出明细上限的内容归入其他，总数保留" or "") end\n    w.note:SetText(note)')
    s=replace(s,'(view=="audit") or (view=="graph" and w.kind=="healing")','(view=="audit" and not s.aggregate) or (view=="graph" and w.kind=="healing" and not s.aggregate)')
    return s
edit(Path('DPSMateXInsights/Details.lua'),details)
supported={'Damage','DamageTotal','DamageTaken','DamageTakenTotal','EDD','EDDTotal','EDT','EDTTotal','FF','FFTotal','FFT','FFTTotal','Healing','HealingTotal','EHealing','EHealingTotal','Overhealing','OverhealingTotal','HealingTaken','HealingTakenTotal','EHealingTaken','EHealingTakenTotal','OverhealingTaken','OverhealingTakenTotal'}
for addon in ('DPSMateX','DPSMateXExtend','DPSMateXExtendMore'):
    for p in (root/addon).rglob('*Details*.lua'):
        s=p.read_bytes().decode('utf-8-sig').replace('\r\n','\n')
        if not any('Modules.Details'+name+' =' in s for name in supported): continue
        result=re.sub(r'DPSMateX.CombatTime\["effective"\]\[(key|curKey)\]',r'DPSMateX:GetSelectedEffectiveTime(\1)',s)
        if result!=s: p.write_bytes(result.replace('\n','\r\n').encode('utf-8'))
print('Core hooks and supported detail adapters updated.')
