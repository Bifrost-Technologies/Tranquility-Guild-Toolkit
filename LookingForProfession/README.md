# Looking For Profession Finder (LFP)

Standalone Forever / Interface 16001 beta. Install `LookingForProfession` in
Interface/AddOns and open `/lfp`. No guild addon is required.

For Tranquility, also install `Tranquility_LFP` alongside the existing Tranquility
addon. Open Profession finder from its home menu or `/tq lfp`. For the personal
edition, install `TitansGuild_LFP` alongside TitansGuild and use `/tglfp` or its
new home button. All editions use one shared finder and saved database.

## Search

Choose Guild only or Public cities on the left. Click the profession and city
buttons to cycle choices; enter levels 1-60. Guild only imports online guild
roster members in approved hubs. Request a roster refresh, then import after
it updates. Public cities prepares a WHO command to copy/run in native chat;
after results arrive, import the snapshot. Only exact selected-city results
are retained. Questing zones, instances, missing locations, and out-of-range
players are excluded. WHO and roster snapshots can be incomplete or stale;
refresh before contacting someone. No background WHO or automatic whispers.

Click a candidate to prepare a profession question, send it yourself, then
record the selected profession after confirmation. Unknown remains unknown.
Records are local, scoped by realm/faction and full character name; they can
be forgotten. Multiple professions per player are supported. A recorded
profession is not proof of recipe ownership, current skill, or availability.

## Recipe and item data

Open your profession window, then Scan open recipes. This indexes the visible
recipe outputs available through the legacy trade-skill API, their profession,
and cached item-use levels. Expand categories/clear recipe filters and scan
again for broader coverage; retry uncached items. Enter an indexed item ID to
select its profession and see its required use level. Search levels remain
explicit: item use level cannot determine the level of a qualified crafter.
This is an observed local index, not a complete scraped recipe database or a
remote profession inspection API. English profession/zone names are required
in this beta. Unsupported client APIs show an unavailable status.

## Validation

Run `lua tests/lfp.lua` from the repository root. The tests cover filtering,
identity, recipe data, both WHO formats, roster handling, and UI construction.
Live Forever-client behavior and appearance still require in-game validation.

Theme: dark gray and blue; recorded professions use green. See
`docs/ADDON-THEME.md` for the standard for future addons.
