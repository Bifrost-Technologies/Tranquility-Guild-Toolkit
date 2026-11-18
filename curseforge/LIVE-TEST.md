# Client acceptance record — 1.0.0-beta.4

Status: **NOT YET RUN IN GAME.** Offline tests cannot establish absence of
taint or client-specific protected-action restrictions. Keep this file in the
submission working folder; do not claim completed checks without observing
them. Candidate game: Forever 1.60.1.70938, Interface 16001.

1. With WoW closed, back up SavedVariables. Install the ZIP's thirteen addon folders
   into `Interface/AddOns`. For the first test, disable all unrelated addons
   so the observed behavior is attributable to this suite's own files.
2. Log in and manually `/reload`. Confirm no blocked-action warning or Lua
   error. `/tranq` and the TQ launcher should open Home. Escape should close
   each panel. Open, move and close every panel. Verify launcher preference
   survives a manual reload.
3. Keep only the core enabled and reload; Home must work and describe optional
   tools as disabled. Test each optional addon alone with the core, then the
   full suite. Disable DB and Loot separately and verify Auctions still opens.
4. Run a WHO query in Blizzard chat yourself. Import it. Compare each displayed
   guild field to native WHO; nil/restricted fields must not be classified as
   guildless. Check accents, realm suffixes and pagination. Select a consenting
   test guildmate/alt, send greeting and invite manually, and check the command
   text. No send may occur on selection. Mark contacted/ignored, reload, import
   again and verify they are skipped. Never test bulk unsolicited messages.
5. At an auctioneer, search a known item manually. Read current results and
   verify per-unit price, not stack price. Incomplete pages must be rejected.
   Test manual copper entry, ignored items and stale samples. Prior-day history
   needs real separate days; do not present a fabricated market baseline.
6. Loot an open-world item and a dungeon item, observe a group-roll offer and
   verify seen/received/roll distinctions. Unknown sources stay unknown. Reload
   and confirm the journal persists. Cross-check auction source lookup.
7. In a consenting party, assign tank/healer and start dungeon monitoring.
   Inspect local verbose output. One mob must not trigger the 3-mob flash.
   Verify restricted stats are unavailable. Send one party summary by clicking;
   a second click within 15 seconds must be refused. Closing stops monitoring.
8. As a warlock with Ritual learned, open Summons out of combat. A party member
   in your zone is skipped even if far away. Unknown zones are skipped. Each
   ritual must require a physical click; verify failure recovery, 10-second
   preparation cooldown, combat stop and close stop. No secure attributes may
   be changed in combat.
9. Inspect a nearby consenting player. Verify incomplete item data is labeled;
   target changes cannot attach someone else's gear. Inspect cooldown is five
   seconds. Scores must not claim gold or skill. New login clears snapshots.
10. Sample WHO in Regions and confirm actual result zones, not a guessed query
    label. Compare phase labels with a peer in the same city/realm; local chat
    shortcuts and member counts must not be used as world-layer IDs.
11. In Help, test DELETE confirmation for each saved module. Confirm data is
    cleared and modules remain usable. Logout/login and confirm persistence
    of retained data and deletion of removed data.
12. Repeat login/reload with normal guild addons enabled. Record any conflict,
    warning, Lua stack, enabled addon versions and reproduction steps. Resolve
    all public-edition warnings before promoting a stable release.

Tester / date / client build: __________________

Observed results and unresolved issues: __________________


## Companion and warning checks

- Test TranquilityLFG with two consenting Tranquility guild members: queue several activities, role/filter changes, native invite permissions, expiry, leave and reload. Verify no visible guild-chat advertisement and deny non-member queue access.
- Verify Dungeon XP warnings begin enabled, remain rate limited and stop after /tranqxp off for the session; clicked dungeon summaries remain separate.
- Disable Uber and verify toolkit/LFG/basic summons remain usable. Enable the bundled Uber 0.4.0-beta.1 and verify launch buttons, native mailbox/delivery and its own documented live checks.
- Confirm optional companions' exact reviewed versions and pending/approved state before publication. A different file's approval is not recorded as this bundle passing.

## New in the guild group finder

The group finder now has three dedicated pages: Dungeons, Battlegrounds and Arena partners. Battlegrounds distinguish casual/ranked planning and 10/15/40-player teams. Arena listings support 2v2, 3v3 and 5v5. Native bracket ratings and honor ranks are shown where available; remote figures are client reports, not independently certified ranks. Unsupported game modes remain planning categories rather than native matchmaking queues.

An active-addon directory is separate from the ready queue. Discovery begins enabled and can be switched off in My profile. Available members may receive deliberate leader invitations; only freshly READY, activity-matching players are considered by auto formation. Green flags identify volunteering leaders, and only the solo player or actual native leader's client controls invites.

The leader's group builder proposes correct roles and level ranges while optionally reducing estimated loot competition. It models level-dependent armor proficiency, healing/spell/strength/agility/defense intent and up to eight desired item IDs per member. Holy and Protection Paladins are not treated as identical loot profiles. Shared caster armor or exact matching desired items carry stronger penalties. Soft warnings count same-armor/likely competing party members; leaders may confirm an intentional duplicate. Local observed dungeon loot sources can be reviewed when the Loot journal has them. No complete Forever drop tables or guaranteed exclusive needs are claimed.

Dungeon teams use one tank, one healer and three DPS; flexible declared roles can fill gaps. PvP tank/healer targets can be customized. A leader-only carry toggle permits the below-range leader above the chosen entry floor, while every other selected player must meet the normal range. The entry floor is a planning setting, not verified native dungeon access.

Auto formation starts only after the leader queues and explicitly arms it. It sends one invitation at a time, waits for native group changes, and skips unanswered invitations after 25 seconds with a five-minute backoff. Combat skips invite ticks; native failures, lost leadership, leaving queue/guild or missing profiles stop formation. Pause is always available. It does not enter Blizzard activity queues or bypass group/raid permissions.

The new Discord lounge displays public-channel snapshots from a configured trusted in-game officer. The supplied invite identifies Tranquility Server #general. Members without Discord can read imported snapshots and queue replies, but replies are not marked Posted until the optional existing bot confirms an actual send and the officer imports its acknowledgement. WoW cannot directly connect to Discord; the relay uses explicit text handoff, not a live feed. The bot's local credentials/intents are not yet configured. Core/LFG use does not require the external companion. See DISCORD-MIRROR-SETUP.md for the owner setup and limits.