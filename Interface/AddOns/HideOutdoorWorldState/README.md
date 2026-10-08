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

## Compatibility fix in 1.1.0

Version 1.0.0 called WorldStateAlwaysUpFrame_Update during VARIABLES_LOADED and
world-entry events. That function also calls UIParent_ManageFramePositions, so
its effects extend beyond hiding world-state displays. This is a possible cause
of startup layout interference, not a confirmed diagnosis of the reported pfUI
failure; the available FrameXML log contains no direct traceback for it.

Automatic hiding now only writes the switch and hides existing AlwaysUpFrame
and WorldStateCaptureBar rows on the first update after entering the world or a
world-state event. It never calls the native updater during automatic startup or
zone handling, changes pfUI settings, or alters minimap/player frames. There is
no continuously running update handler. Battleground rows are left alone.
An explicit `/outdoorui show` rebuilds native world-state UI once after login to
restore current values; hide/show choices remain saved across restarts.

Validation: offline regression tests cover initialization, deferred event order,
zone transitions, battleground preservation, saved choices and commands.
Tests use Lua 5.1 with the client's legacy event globals; the addon uses the Lua
5.0 language subset. Live client validation is still required for pfUI layouts.
Run from the workspace root:
`lua Interface/AddOns/HideOutdoorWorldState/tests/lifecycle.lua`.
