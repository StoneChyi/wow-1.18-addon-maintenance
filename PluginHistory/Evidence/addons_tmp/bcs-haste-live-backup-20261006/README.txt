Paladin floating haste now uses measured melee attack speed, matching BCS SetMeleeAttackSpeed. Other classes retain casting haste.
Haste uses the existing 0.2-second display tick. Weapon baseline cached by equipped item link and invalidated on player inventory changes.
/mb haste adds melee haste, current displayed value and haste aura names/stacks/tooltip wording.
No character-panel opening, equipment UI, positions or layering changes.
Tests use real Lua source with mocked game APIs; live client validation required.
