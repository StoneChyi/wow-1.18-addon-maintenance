Formula review and fallback repair. Independent equipment factors multiply as (product - 1) * 100.
Distinct active set bonuses count once across set pieces; inactive grey bonuses are excluded.
Scan each independent aura once, including multiple auras with identical tooltip wording.
For Zeal, read the per-stack haste from the current Crusader Strike spell tooltip, then multiply by aura applications. The aura tooltip total may omit talented +2%. If skill data is unavailable, retain the already-stacked aura tooltip amount.
Separate cached melee formula from legacy casting/general formula; ignore casting-only auras in melee mode.
The floating paladin stat continues using real attack-speed ratio as primary data (including millisecond rounding); only its fallback now uses the melee formula, without switching to cast-speed coefficients.
The /mb haste diagnostic includes skill-derived Zeal per-stack haste.
Existing batching and refresh intervals retained. Tests run against real Lua source with mocked game APIs; live client validation required.
