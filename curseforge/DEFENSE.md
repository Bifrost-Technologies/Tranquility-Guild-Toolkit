## PvP sub-addon (beta.9)

Enable **Tranquility: PvP** in the AddOns menu, then open `/tranq pvp` (the old `/tranq defense` alias still works). Radar, Heatmap, Danger alerts and Settings have separate pages. The collector is no longer part of the core addon and can be disabled independently. Existing scouting settings remain in TranquilityDB.defense.

Danger alerts default off. Configure 1–100 observed enemies and a 50–1,000-yard range; default thresholds are 5 enemies / 300 yards. Only reports no older than 15 seconds trigger warnings. Moving outside the radius clears the warning; sound is opt-in with a 30-second cooldown. Exact public coordinates are preferred; approximate reports and unverified layer context remain explicitly described. These are ordinary map observations, not X-ray skeletons, wall outlines or a complete layer population query.

# World defense: nearby enemy sightings

Open **`/tranq defense`** or the World defense heatmap home button. Native Dedicated Member-or-higher guild membership and vault admission are required. Enable scouting, then enable guild sharing on participating scouts. Both start off. The addon collects no permanent enemy history.

## Best available position method

1. Read native public unit/world positions for permitted nameplate/target/mouseover player units. Calibrate the coordinate axes against the player's known native map/world position before plotting any enemy result. Require matching physical map context, valid projected map bounds and reasonable distance.
2. If exact data is missing/restricted, use an explicitly approximate observation around the scout **only if Allow scout-centered approximation is enabled**. Turn that off for exact-only operation. Protected/secret values are rejected before comparison or arithmetic; forbidden nameplates are not inspected.
3. Share bounded native guild addon reports among admitted members. This is information seen by participating clients, not a server-wide radar. Same-realm/faction transport and layers limit coverage. No readable identity means no claimed cross-scout unique headcount.

The Forever client declares [UnitPosition](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) and [native map/world conversion](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua) functions. Declarations alone do not prove enemy data will be returned in every live context. The panel's diagnostics show exact positions, approximations and unavailable/restricted observations on the actual client. Enemy map positions are never fabricated from screen pixels or memory reads.

## Reading the map

- Yellow, orange, red and dark red indicate increasing enemy counts: 1–4, 5–14, 15–24 and 25+.
- Optional friendly players use blue, teal and green.
- `~` marks scout-centered or otherwise approximate density. Tooltips explain the count and age.
- Sightings fade immediately and disappear fully after 20 seconds without a fresh observation. A vanished nameplate is stale evidence, not proof the enemy left the zone.
- Public identity reports deduplicate repeat observations; mixed identity methods and anonymous scout pools use conservative maxima. Overlapping scouts' counts are never blindly added. Adjacent approximate blobs may overlap; do not sum them into a realm population.
- Coordinates may project onto a parent world map where the native map rectangle is available. Unmappable regions stay hidden on that view.

Open the world map to see pooled heat circles. Rendering stops when the map is closed. No recent sightings means no recent reports, not that the area is safe. The implementation limits retained observations, aggregate pools, payload sizes, sender rates and visible pins. Reports remain self-reported observations; admitted guildmates can still be mistaken or dishonest.

## Acceptance still needed in-game

Check the exact client build with two admitted guild scouts and a visible enemy player. Confirm precise public coordinates where available, the fallback label when unavailable, a repeated shared sighting counting once, the 20-second fade, faction filters and map zoom/pan. Test an entry Member cannot collect or share and revocation clears overlays. Repeat in normal world areas and instances: availability can differ.

This version does not implement a universal kill feed, automatically attribute PvP deaths, bypass combat restrictions, scan WHO, navigate, target or attack enemies. Defense-channel alerts and mercenary/rally integration remain planned features.
