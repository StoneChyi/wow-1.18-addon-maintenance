Floating melee haste precision repair. Only BCS_PropertiesPanel.lua changed.
Prefer GetItemStatsField(itemID, delay) / 1000 for original weapon speed; keep cached tooltip fallback for old clients.
Normalize +/- 1 millisecond only when both attack times lie at millisecond boundaries (0.25 microsecond float tolerance). No fixed percentage deadband.
Tests reproduce original 0.05% using 2.000 versus 1.999 seconds, verify raw delays, continuous small modifiers, fast weapons, Zeal and fallback paths.
This is display normalization at the native timer resolution; a real modifier indistinguishable from the same one-millisecond quantization cannot be separated using this ratio alone.
In-game validation of the user weapon still required.
