local E=DPSMateX.Insights
local minima={"min","effectiveMin"}
local maxima={"max","effectiveMax"}
-- Fixed-size summaries only; no event history or time samples are added.
function E:RecordHealingOutcome(row,kind,total,effective)
    row.outcomes=row.outcomes or {}
    local o=row.outcomes[kind]
    if not o then o={count=0,total=0,effective=0};row.outcomes[kind]=o end
    o.count=o.count+1;o.total=o.total+total;o.effective=o.effective+effective
    o.min=math.min(o.min or total,total);o.max=math.max(o.max or total,total)
    o.effectiveMin=math.min(o.effectiveMin or effective,effective)
    o.effectiveMax=math.max(o.effectiveMax or effective,effective)
end

function E:MergeHealingOutcomes(target,source)
    if not source.outcomes then return end
    target.outcomes=target.outcomes or {}
    for kind,value in pairs(source.outcomes) do
        local out=target.outcomes[kind]
        if not out then out={count=0,total=0,effective=0};target.outcomes[kind]=out end
        out.count=out.count+value.count;out.total=out.total+value.total;out.effective=out.effective+value.effective
        for _,key in ipairs(minima) do
            if value[key]~=nil then out[key]=math.min(out[key] or value[key],value[key]) end
        end
        for _,key in ipairs(maxima) do
            if value[key]~=nil then out[key]=math.max(out[key] or value[key],value[key]) end
        end
    end
end
