# Tranquility: PvP

Optional guild PvP command center. Requires the bundled Tranquility core, native Dedicated Member-or-higher rank and vault admission. Enable this folder in the character-selection AddOns menu. Open `/tranq pvp`; `/tranq defense` remains an alias.

- **Radar:** current reconnaissance diagnostics and recent enemy/friendly concentrations.
- **Heatmap:** fast-fading world-map circles and source/uncertainty legend.
- **Danger alerts:** configurable count/radius warnings as you approach recent concentrations. Alerts and sound are opt-in. Reports older than 15 seconds cannot trigger warnings.
- **Settings:** scouting, guild sharing, exact-only or optional scout fallback, and friendly display.

Uses only public native unit positions, normal visible unit tokens and admitted guild scout reports. Cannot enumerate an entire layer, expose hidden enemy data, render through-wall skeletons, target or attack automatically. Layer context is not independently verified. No recent sightings does not guarantee safety.

Data expires after 20 seconds and remains in memory. Disable this sub-addon to remove the collector and warnings independently of the rest of the guild toolkit. Future candidates include defense-channel alerts, explicit rally/mercenary links and manual incident reports; those are not advertised as implemented here.
