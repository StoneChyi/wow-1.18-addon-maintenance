# Cursive

> [!IMPORTANT]
>
> **This addon requires you to have Nampower >= 2.40.0 installed.**

![image](https://github.com/pepopo978/Cursive/assets/149287158/801511af-29c7-4baf-b1ac-5e8c52f0f846)

Cursive combines ShaguScan unit scanning with curse tracking similar to DotTimer and the ability to automatically curse
targets similar to Decursive.

### Recommended setup

Move the Cursive label to the desired position on the screen. You can turn on 'Show Frame Background' in the settings to
help with this. Once you have it where you want it, turn off 'Show Frame Background' and turn on 'Allow clickthrough'
so that it doesn't block your clicks when it's not displaying mobs.

## Commands

`/cursive` for commands, minimap icon to edit options.

### Curse

`/cursive curse <spellName:str>|<guid?:str>|<options?:comma separated str>`: Casts spell if not already on target/guid

EXAMPLE: `/cursive curse Corruption|target` will attempt to cast Corruption on your target if it's not already on them
and they aren't cc'ed.

### Multicurse

`/cursive multicurse <spellName:str>|<priority?:str>|<options?:comma separated str>`: Picks target based on priority and
casts spell if not already on target and they aren't cc'ed.

EXAMPLE: `/cursive multicurse Corruption|HIGHEST_HP` will attempt to cast Corruption picking the target with the highest
HP that doesn't already have it and will warn you if it does nothing.

### Target

`/cursive target <spellName:str>|<priority?:str>|<options?:comma separated str>`: Targets unit based on priority if spell in range and not already on target

EXAMPLE: `/cursive target Icicles|HIGHEST_HP` will target the enemy with the highest HP in range of the spell Icicles.

can also do it only if you don't have a target already:
`/run if not UnitName("target") then SlashCmdList.CURSIVE("target Icicles|HIGHEST_HP") end`

There is also 
`/script targetGuid = Cursive:GetTarget("str", "str", {})`: Returns guid of the unit that would be targeted based on priority and options.

EXAMPLE: `/script targetGuid = Cursive:GetTarget("Corruption", "HIGHEST_HP", {})` will return guid of the enemy with the highest HP in range of the spell Corruption that doesn't already have Corruption.

## Priority Options

- HIGHEST_HP - Target highest HP enemy without a curse first.
- LOWEST_HP - Target lowest HP enemy without a curse first.
- RAID_MARK - Target largest raid mark enemy without a curse first. Priority is as follows:
	- Skull = 8 (1st priority)
	- Cross = 7
	- Square = 6
	- Moon = 5
	- Triangle = 4
	- Diamond = 3
	- Circle = 2
	- Star = 1 (8th priority)
	- No mark = 0
- RAID_MARK_SQUARE - Target largest raid mark but ignore Skull and Cross. Priority is as follows:
	- Square = 6 (1st priority)
	- Moon = 5
	- Triangle = 4
	- Diamond = 3
	- Circle = 2
	- Star = 1
	- No mark = 0
	- Cross = -1
	- Skull = -2 (9th priority)
- INVERSE_RAID_MARK - Target lowest raid mark enemy without a curse first. (reverse of RAID_MARK)

- HIGHEST_HP_RAID_MARK - Target highest HP enemy with a raid (use raid mark priorities for identical hp), then highest
  HP enemy without a mark.
- HIGHEST_HP_RAID_MARK_SQUARE - Same as HIGHEST_HP_RAID_MARK but with RAID_MARK_SQUARE priority for marked enemies.
- HIGHEST_HP_INVERSE_RAID_MARK - Same as HIGHEST_HP_RAID_MARK but with INVERSE_RAID_MARK priority for marked enemies.

## Command Options

All commands can take the following options separated by commas:

- `warnings` : "Display text warnings when a curse fails to cast.",
- `resistsound` : "Play a sound when a curse is resisted.",
- `expiringsound` : "Play a sound when a curse is about to expire.",
- `allowooc` : "Allow out of combat targets to be multicursed. Would only consider using this solo to avoid potentially
  griefing raids/dungeons by pulling unintended mobs.",
- `priotarget` : "Always prioritize current target when choosing target for multicurse. Does not affect 'curse'
  command.",
- `ignoretarget` : "Ignore the current target when choosing target for multicurse. Does not affect 'curse' command.",
- `playeronly` : "Only choose players and ignore npcs when choosing target for multicurse. Does not affect 'curse'
  command.",
- `istapped` : "Only choose mobs tagged by other players when choosing target for multicurse. Does not affect 'curse'
  command.",
- `minhp=<number>` : "Minimum HP for a target to be considered.",
- `distance=<number>` : "Target distance limit. Without UnitXP, `1`/`2`/`3` are tiers meaning 28/11.11/9.9 yards;
  with UnitXP, the value is used directly as a yard value.",
- `refreshtime=<number>` : "Time threshold at which to allow refreshing a curse. Default is 0 seconds.",
- `name=<str>` : "Filter targets by name. Can be a partial match. If no match is found, the command will do nothing.",
- `ignorespellid=<number>` : "Ignore targets with the specified spell id already on them. Useful for ignoring targets
  that already have a shared debuff.",
- `ignorespelltexture=<str>` : "Ignore targets with the specified spell texture already on them. Useful for ignoring
  targets that already have a shared debuff.",
- `malediction=<0|1>` : "For Warlocks with the Malediction talent: when checking if Curse of Recklessness, Curse of
  the Elements, or Curse of Shadow is already on a target, check for Curse of Agony instead. Default is 1 (enabled).
  Set `malediction=0` to disable and check for the original curse.",

EXAMPLE: `/cursive multicurse Corruption|HIGHEST_HP|warnings,resistsound,expiringsound,minhp=10000,refreshtime=2`

EXAMPLE:
`/cursive multicurse Curse of Recklessness|RAID_MARK|name=Touched Warrior,ignorespelltexture=Spell_Shadow_UnholyStrength,resistsound,expiringsound`

## Macro examples

You can just put multiple commands in a macro like this
```
/cursive curse Curse of Recklessness|target|refreshtime=1
/cursive curse Corruption|target|refreshtime=3
/cursive curse Siphon Life|target|refreshtime=1
```
but the game won't always execute them in the order you want

if you want more control of the order you can do something like
```
/script if not Cursive:Curse("Curse of Recklessness", "target", {refreshtime=1}) then if not Cursive:Curse("Corruption", "target", {refreshtime=3}) then Cursive:Curse("Siphon Life", "target", {refreshtime=1}) end end
```
This also works for Multicurse:
```
/script if not Cursive:Multicurse("Curse of Recklessness", "HIGHEST_HP", {refreshtime=1}) then if not Cursive:Multicurse("Corruption", "HIGHEST_HP", {refreshtime=3}) then Cursive:Multicurse("Siphon Life", "HIGHEST_HP", {refreshtime=1}) end end
```

Example with more options
`/script Cursive:Multicurse("Curse of Recklessness", "HIGHEST_HP", {warnings=1,resistsound=1,expiringsound=1,refreshtime=2})`

All cursive commands will return true only if it attempted to cast or it found a target.

## Shared Debuffs

Shared debuffs applied by other players will appear greyed out on targets.

Currently only Faerie Fire is supported as I felt it warranted special handling.  It works by looking for other players casting faerie fire and then checking if the mob has the debuff, so if someone refreshes faerie fire and gets resisted it will incorrectly restart the timer.  However, it should still correctly remove faerie fire if it falls off that target.  I didn't want to impact performance to handle this edge case.

## Accessing curse data in other addons

Cursive data can be accessed in other addons 

You can check if curse is active with
`Cursive.curses:HasCurse(lowercaseSpellNameNoRank, targetGuid, minRemaining, malediction)`

For example `Cursive.curses:HasCurse("corruption", GetUnitGUID("target"), 3, false)` or `Cursive.curses:HasCurse(Cursive.utils.GetLowercaseSpellNameNoRank("Corruption (Rank 2)"), GetUnitGUID("target"), 3, false)` will check if Corruption is on the current target with at least 3 seconds remaining.  It won't specifically check for rank 2 just wanted to show that HasCurse only works with the lowercase spell name without rank.

You can get raw curse data using 
`Cursive.curses:GetCurseData(spellName, guid)`

GetCurseData does not require the spellName to already be lowercase / no rank.

Curse data is a table with the following structure:
```
{
		rank = int,
		duration = float,
		start = float,
		spellID = int,
		targetGuid = string,
		currentPlayer = bool,
}
```

Here's an example that gets the time left on Corruption on the current target:
```
/run _, guid = UnitExists("target"); local data = Cursive.curses:GetCurseData("Corruption", guid); print(Cursive.curses:TimeRemaining(data))
```

## Important info

If you have my latest nampower, it will use the SpellInRange function from that to provide improved range checking.

Otherwise, all commands will prioritize targets within 28 yards of you first to have a better chance of being in range.

All commands will ignore targets with the following CCs on them:

- Sleep
- Entangling Roots
- Shackle Undead
- Polymorph
- Turn Undead
- Blind
- Sap
- Gouge
- Freezing Trap
- Banish

All commands will also ignore spell-immune mobs the same way they ignore crowd controlled mobs. Currently this is only used for `Blackwing Spellbinder` in BWL.

Multicurse will only ever target enemies that are already in combat (except if you target a mob directly first) to
prevent pulling things you didn't intend like marked patrols.

For Warlocks with the Malediction talent, when checking if Curse of Recklessness, Curse of the Elements, or Curse of Shadow is already on a target, the addon will instead check for Curse of Agony to allow you to refresh agony using them. This is enabled by default and can be disabled per-command with `malediction=0`. Don't use the `refreshtime` option with this as the server won't refresh Curse of Agony if it is still on the mob.

Special spells such as `Rake` that deal direct damage but also apply a bleed DoT are handled differently from normal debuffs. When one lands, Cursive starts a 1 second timer then checks that the bleed aura actually appeared on the target. If it did not, Cursive removes the curse.

If that verification failure happened while the target was not at the client buff/debuff cap, the addon assumes that mob name is bleed-immune and caches it in memory. Future casts against mobs with that same name will skip bleed tracking so you do not keep getting `Rake` timers for 1 second on bleed-immune targets.

Missed spells (miss/resist/dodge/parry/block/evade/immune/deflect/absorb/reflect) never apply their debuff, so Cursive listens to Nampower's `SPELL_MISS_SELF` / `SPELL_MISS_OTHER` events and cancels the icon for any non-zero `missInfo`. On a miss it sets a short guard so a delayed/scheduled application (e.g. the `AURA_CAST_ON_OTHER` path, which is what makes reflected spells show up wrongly) cannot re-add it, then verifies the target's actual aura about 0.3s later and removes the icon only if the debuff is genuinely absent. This keeps the icon when you refresh an already-active DoT and the refresh misses (the old DoT is still ticking).

Mobs with raid marks will be displayed first.

Mobs will the top 3 max hps will always display next. I may make this configurable in the future.

There is an option "always show current target" that will display your current target in the last slot if they aren't already being displayed.

### Clickable Target Name Column

When "Show Target Name" is enabled, the target name column on each bar is clickable (Nampower >= 2.37, uses
`SetMouseoverUnit`-style extended unit tokens, implemented with Nampower's `GUID .. "target"` extended unit token via
`TargetUnit`):

- Left click: target the unit's current target.
- Right click: target it and auto-attack (same as main bar behavior, only when out of combat).
- Hover: shows the unit's target in the tooltip.

There is also a "Target Name Background" toggle (default off): when enabled, the target name column gets a gray
semi-transparent background with a black border.

You can ignore mobs based on their unit name using the ignored mob list filter.  It is comma separated and you need to press enter to get it to save.  For example can do:
`whelp,scarab` to ignore all mobs with those strings in their name.

### Sort By Distance

The "Sort By Distance" option (default off) orders every displayed bar, including raid-marked units, by distance.
Distances use UnitXP's `distanceBetween` when available and fall back to `CheckInteractDistance` bands otherwise.
When this is enabled the raid-mark-first and top-3-max-HP ordering is skipped so the list is a strict distance sort,
and the "always show current target" placement is not applied.

The "Distance Sort Mode" dropdown (only enabled while sorting is on) chooses the direction: `Nearest -> Farthest`
(default) or `Farthest -> Nearest`.

### Full Buff/Debuff Slot Emphasis

The "Emphasize Full Buff/Debuff Slots" option (default off) highlights a bar when the unit's buff and debuff slots are
both completely full (no empty aura slot), i.e. a new DoT can no longer land. The detection reads the raw Nampower
`aura` unit field and treats the slots as full when every entry is occupied.

The "Full Slots Emphasis Style" dropdown chooses how the emphasis is drawn:

- `Border`: the health bar border turns bright magenta (the default).
- `Health Bar`: the health bar fill turns bright magenta.
- `Fade`: the whole bar is drawn semi-transparent.

The style option is only enabled while the emphasis toggle is on.

