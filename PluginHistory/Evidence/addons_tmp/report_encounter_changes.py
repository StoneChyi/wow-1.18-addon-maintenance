from pathlib import Path
import difflib
root=Path(r'E:/1.18')
backup=root/'addons_tmp/dpsmatex-encounters-backup-20261006'
changed=[]
for old in backup.rglob('*'):
    if not old.is_file(): continue
    relative=old.relative_to(backup);new=root/'Interface/AddOns'/relative
    before=old.read_text(encoding='utf-8-sig');after=new.read_text(encoding='utf-8-sig')
    if before!=after:
        changed.append(relative.as_posix())
        if 'Details' in old.name and not str(relative).startswith('DPSMateXInsights'):
            # Supported old details should change only effective-time access.
            import re
            expected=re.sub(r'DPSMateX.CombatTime\["effective"\]\[(key|curKey)\]',r'DPSMateX:GetSelectedEffectiveTime(\1)',before)
            assert after==expected, relative
report='''# DPSMateX 战斗分类实现记录（2026-10-06）

已新增独立 DPSMateXEncounters 模块，将 Boss汇总 / 小怪汇总接入原时间菜单。汇总独立于历史列表；Boss整场归类含失败尝试与增援，手动分段延续同一遭遇。未分类单独保存。原全程不被重新计算。

治疗与实际吸收、成功施放沿用 Insights。累计只保留金额、次数、技能和目标，不新增回放或曲线副本。详细使用方式与识别范围见 `Interface/AddOns/DPSMateXEncounters/README.md`。

验证：23组分类检查、27组 Insights 检查、锁窗回归通过；Lua与TOC检查通过；额外确认旧详情文件只修改有效时间访问。离线模拟不验证真实游戏帧率、排版及所有自定义首领。

未修改用户WTF/SavedVariables数据，未安装额外依赖。原文件备份为 `addons_tmp/dpsmatex-encounters-backup-20261006`。

## 修改的原文件

'''
report+='\n'.join('- '+name for name in changed)+'\n\n## 新模块\n\n'
report+='\n'.join('- '+p.relative_to(root).as_posix() for p in sorted((root/'Interface/AddOns/DPSMateXEncounters').glob('*')))+'\n'
(root/'addons_tmp/DPSMateX-Encounters-change-report-20261006.md').write_text(report,encoding='utf-8')
print(f'{len(changed)} original files changed; old detail edits restricted to effective-time routing. Backup verified.')
