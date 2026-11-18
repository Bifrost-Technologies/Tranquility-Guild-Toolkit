# Tranquility World Defense — implementation plan

Status: **first scouting/heatmap implementation shipped in 1.0.0-beta.8**, pending live client acceptance. Public unit-position calibration, optional scout approximations, short-lived guild reports and world-map overlays are implemented. Settlement alerts, death attribution and rally/contract integration below remain future milestones. This extends the guild toolkit; it does not add combat automation to Tranquility.

## Goal

Give admitted guild members a clear view of where Alliance settlements, guildmates and summoning camps need help. Show recent enemy and friendly activity on the world map, let officers organize a defense group, and turn an incident into a mercenary contract. A useful count includes its source, observation window and uncertainty.

The example Undercity overlay could read:

> Undercity approach — 25 unique Horde observed within 90 seconds by 3 guild scouts. Approximate observation area; latest sighting 12 seconds ago.

Only display that exact count when unique identities are actually readable and deduplicated. Otherwise use “25 reported,” “at least 8 seen,” or “enemy activity; count unavailable,” as appropriate. An addon must never present a guessed server population as a measured fact.

## First milestone: verify the actual client capabilities

Use a small diagnostics page on the supported Forever build before promising automatic density counts. Probe native API availability and whether returned data is public. Register optional events with protected calls and disable only the unavailable source. Never unwrap secret values or access forbidden frames.

The client-generated [map API declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua) limit player map lookups to self/party. Therefore an enemy nameplate does not imply a readable enemy world-map coordinate; use the scout's own location as an approximate observation area when needed. Do not plot a precise enemy coordinate in that case.

The [unit API declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) flag unit identities and death data as conditionally restricted. Unique-player counts and death attribution depend on readable public values. Missing identity means no reliable cross-scout identity deduplication; a player's death alone does not identify their killer or prove a PvP kill.

[Native nameplate code](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlates.lua) distinguishes regular and forbidden nameplate handling. Observe only permitted public nameplates and normal unit tokens. This source review guides the proposed adapter; it does not replace an actual client test or certify unrestricted access on every build.

## Window and navigation

Add **World Defense** to the Tranquility home panel with three pages:

| Page | Main content | Actions |
| --- | --- | --- |
| Alerts | Fresh incidents sorted by urgency, region, age and confidence | Show on map, mark responding, dismiss locally |
| War map | Enemy/friendly density circles and incident pins | Filter, inspect tooltip, set a native waypoint on click |
| Rally board | Guild leaders forming defense parties and open mercenary contracts | Volunteer, request a native invite, open the matching contract |

Use the existing WoW-style dark panels, gold section headings and readable faction colors. Keep a compact optional alert strip near the minimap. The panel must respect the same native rank and vault gate. Revocation hides it, stops collection and clears pending broadcasts.

Default controls: enemy activity on, friendlies off, death markers on, settlement attacks on, sound off, and reports limited to the current realm/map context. Settings include watched zones, freshness window, minimum count, circle opacity, friendly privacy, scout sharing, alert cooldown and a one-click mute. Opening the map must remain smooth.

## Colors and legend

| Data | Proposed display |
| --- | --- |
| 1–4 distinct enemies observed | Yellow outline and pale fill |
| 5–14 | Orange |
| 15–24 | Red |
| 25+ | Dark red fill with a brighter red outline |
| Friendly players | Pale blue → blue as activity increases |
| Responding guild party | Teal → green; separate rally icon |
| Recent player death | Skull with age and attribution status |
| Settlement attack | Shield/flame incident pin |
| Manual/unverified report | Dashed outline / distinct report icon |

Pair every color with a count/label so color is never the only signal. Fade old sightings, shrink stale confidence, and remove expired circles. Zoom-dependent clusters prevent whole continents becoming opaque. Circle size represents the observation footprint, not the exact location of every enemy. Use an approximate radius when only a scout position is known.

## Data sources and what they establish

1. **Public local sightings:** permitted player nameplates, target and mouseover. Check that the unit is a player, read faction/identity only when public, exclude pets/NPCs and deduplicate within a short observation window. A vanished plate is a stale sighting, not a confirmed departure from the region.
2. **Local death reports:** record the player's own death and own public map location. Add nearby enemy context only if already observed. Label unproven attribution “cause unknown.” Other deaths require an actual public event plus usable location context; never invent a global kill feed.
3. **Settlement defense notices:** test whether this build exposes the native zone-under-attack event or normal defense-channel notices. Handle localization and actual channel identity. If unavailable, keep manual reports usable. Do not auto-join channels or scrape private chat.
4. **Admitted guild scouts:** exchange bounded reports through native guild addon messages. Record authenticated native sender, report type and age. Guild membership authenticates the source, not the factual truth of its claim.
5. **Friendly presence:** opted-in guild clients share their own public location at a slow pace. Party coordinates may supplement this when actually available. Show the number of participating reporters; do not claim to count every Alliance player in a zone.
6. **Manual incident:** a guild member can report an attack at their current location or a deliberate map click. A manual headcount is clearly labeled reported, with a short expiry and moderation controls.

WHO results are optional manual context, never a substitute for battlefield proximity. Do not run automated repeated WHO scans to infer enemy density.

## Counts, deduplication and confidence

Suggested live observation TTL: 90 seconds; warning fade after 45 seconds. Death incidents remain up to 5 minutes; manual and settlement reports up to 3 minutes unless corroborated. All are configurable within bounded limits.

When a public unique identifier is available, count it once across all scouts in the same map/context and observation window. Keep the most recent observation, and avoid counting the same moving player in several nearby cells. Purge raw identities after TTL and retain only anonymous aggregates for a short local history.

When IDs are inaccessible, do not sum three scouts' overlapping sightings. Show a conservative maximum local count or a labeled range/report count, with reduced confidence. “5 seen locally + 20 reported” is clearer than pretending there are exactly 25 unique players.

Realm, map and accessible instance context must match before aggregation. Layers/shards are not generally provable from map ID; label unknown context and keep distant/uncorroborated scout pools separate. Existing phase hints are hints, not authoritative layer IDs.

An incident's confidence rises with distinct scouts and corroborating native notices; it drops with age, contradictory reports and unknown location/identity. Confidence scoring is a design heuristic, never proof that a player attacked anyone.

## Transport and abuse controls

Use a new versioned, bounded packet family on the existing guild transport. Suggested fields: version, report ID, native sender attribution, type, map, quantized scout coordinate, faction category, observation time, count semantics, optional short-lived public identity and uncertainty radius. No executable text, arbitrary serialization or broad whisper distribution.

Validate native guild membership/rank/vault admission, allowed message types, payload lengths, numeric bounds, timestamps, map context, per-sender rates and duplicate IDs. Reject future/stale reports and cap reports per sender. A sender cannot claim another scout's identity or another player's private coordinates.

Let officers mute unreliable reporters, remove an incident and flag suspicious repeated reports. Do not automatically ban players or accuse named enemies of misconduct. The feature is for ordinary faction defense and coordinated play, not persistent player tracking or harassment.

Proposed performance budget: event-driven collection, 2-second aggregation while active, at most one coalesced outbound packet per scout every 5 seconds, and a low-priority queue shared fairly with LFG and jobs. Cache map geometry, pool pins/circles, update only changed cells, and stop rendering while the map is closed. Cap 300 active observations, 100 incident clusters and 50 drawn circles; degrade by clustering, not by stalling the UI. Do not write SavedVariables for every sighting.

## Connect incidents to real guild activity

Click **Create defense group** to open the existing guild LFG builder with a PvP activity/location preset. Players opt in; native invites still require actual leadership and normal client permissions. Offer a rally point and a simple “On my way” status.

Click **Post mercenary contract** to fill the existing player-funded contract with the location/objective and per-participant reward. Example: guard the summoning circle, 5g per accepted mercenary. The requester reviews each participant and manually pays them; sightings, deaths and “responding” flags are not automatic proof of contract delivery.

Summoning providers can opt to mark a camp as needing guards, linking its Uber camp reference to a rally point without broadcasting customer identities or private order notes. No navigation, automatic movement, attacking, targeting or looting is added.

## Build order and acceptance tests

**Phase 1 — capability adapter and manual defense board:** validate APIs on the exact client, add admitted-member manual reports, rally points, TTLs and map pins. Ship useful alerts even if automatic identities are unavailable.

**Phase 2 — safe observations:** public local sightings, local deaths, optional native defense notices, exact deduplication where possible and explicit uncertainty elsewhere.

**Phase 3 — guild scout sharing and map density:** authenticated reports, separate friendly opt-in, pooled overlays, confidence labels and expiry. Test multiple scouts viewing the same players and different map/layer contexts.

**Phase 4 — LFG/contract integration and polish:** rally invites, camp-defense presets, reporter moderation, accessibility, profiling and release documentation with real client screenshots.

Required tests: outsiders/entry Members cannot view or broadcast; rank revocation clears the view; secret values are rejected before comparison; pets/NPCs never count; identical sightings never inflate counts; overlapping anonymous scout totals are not added; stale/future/replayed packets fail; unsupported events disable only their source; zero observations show “no recent reports,” not “zone safe”; faction filters and colors stay distinct; map closed means no redraw work; a 40-scout stress test stays within packet, memory and frame budgets.

The release description must describe only capabilities verified on that client. A “25 Horde” dark-red circle is a target outcome for sufficient observations, not a promise of server-wide radar.
