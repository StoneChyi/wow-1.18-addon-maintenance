# HideOutdoorWorldState

For the WoW 1.12 client. Hides outdoor world-state counters and capture bars by
applying the built-in HIDE_OUTDOOR_WORLD_STATE switch after saved variables load,
when entering the world, and when changing zones. This has the same scope as the
manual switch: all outdoor world-state displays, including Eastern Plaguelands
and Silithus. The standard client retains battleground displays.

Restart the game after installation and enable HideOutdoorWorldState in the
character selection screen's AddOns list. Hiding is enabled by default.

- `/outdoorui show`: restore outdoor world-state displays.
- `/outdoorui hide`: hide outdoor world-state displays again.

The choice is stored in the addon's own saved variable and reapplied on login.
To uninstall, first run `/outdoorui show`, then disable or remove this addon.

Validation: checked TOC references, event registration, saved-variable names,
and Lua 5.0-compatible syntax by inspection. Live client testing is still needed.
