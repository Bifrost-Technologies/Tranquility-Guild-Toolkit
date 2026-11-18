# Tranquility — release checklist

## Package identity

- Toolkit 1.0.0-beta.10; Forever Interface 16001. Companion versions: TranquilityLFG 0.3.0-beta.1 and Uber 0.5.0-beta.1.
- Thirteen direct addon roots: eleven toolkit folders plus TranquilityLFG and Uber. No extra enclosing toolkit folder.
- Native generic/Camelot TOCs match their addon folders. Core/module dependencies refer to bundled folders.
- Only declared source, documentation and MIT notices are uploaded. No local account data, credentials, executable helpers or design-preview assets.
- Forward-slash archive paths and archive/source hashes are checked by the build. Keep the SHA-256/preflight sidecars with the local release record; upload only the ZIP.

## Listing

- Use PROJECT.md / FORM-ENTRIES.md for form values, SUMMARY.md for the summary and DESCRIPTION.md for the full public description.
- Use CHANGELOG.md for the current file's changelog. Enable comments or an actual support channel.
- Required external project dependencies: none. Optional companions are bundled; do not invent project links or IDs.
- Use the existing 400×400 avatar and real gameplay captures from SCREENSHOTS.md. Do not claim mock previews as screenshots.
- The description explicitly discloses XP warnings, guild addon messaging, optional Uber payment/reporting and ordinary data persistence limits.

## Validation and publication

- Run scripts/build-guild-release.ps1 and review its actual test/hash report.
- Record live results in LIVE-TEST.md, including protected actions, guild LFG, XP warnings and optional Uber. Offline tests are not a substitute.
- Wait for the actual Uber decision as requested. Confirm the reviewed version and resolve any changes before publishing this combined distribution.
- Select only the actual tested Forever game tag. Use Beta while validation remains incomplete.
- Fill actual author/source/support details, confirm name/assets and upload the ZIP through the publisher's account. Nothing is submitted automatically.
## New in the guild group finder

The group finder now has three dedicated pages: Dungeons, Battlegrounds and Arena partners. Battlegrounds distinguish casual/ranked planning and 10/15/40-player teams. Arena listings support 2v2, 3v3 and 5v5. Native bracket ratings and honor ranks are shown where available; remote figures are client reports, not independently certified ranks. Unsupported game modes remain planning categories rather than native matchmaking queues.

An active-addon directory is separate from the ready queue. Discovery begins enabled and can be switched off in My profile. Available members may receive deliberate leader invitations; only freshly READY, activity-matching players are considered by auto formation. Green flags identify volunteering leaders, and only the solo player or actual native leader's client controls invites.

The leader's group builder proposes correct roles and level ranges while optionally reducing estimated loot competition. It models level-dependent armor proficiency, healing/spell/strength/agility/defense intent and up to eight desired item IDs per member. Holy and Protection Paladins are not treated as identical loot profiles. Shared caster armor or exact matching desired items carry stronger penalties. Soft warnings count same-armor/likely competing party members; leaders may confirm an intentional duplicate. Local observed dungeon loot sources can be reviewed when the Loot journal has them. No complete Forever drop tables or guaranteed exclusive needs are claimed.

Dungeon teams use one tank, one healer and three DPS; flexible declared roles can fill gaps. PvP tank/healer targets can be customized. A leader-only carry toggle permits the below-range leader above the chosen entry floor, while every other selected player must meet the normal range. The entry floor is a planning setting, not verified native dungeon access.

Auto formation starts only after the leader queues and explicitly arms it. It sends one invitation at a time, waits for native group changes, and skips unanswered invitations after 25 seconds with a five-minute backoff. Combat skips invite ticks; native failures, lost leadership, leaving queue/guild or missing profiles stop formation. Pause is always available. It does not enter Blizzard activity queues or bypass group/raid permissions.

The new Discord lounge displays public-channel snapshots from a configured trusted in-game officer. The supplied invite identifies Tranquility Server #general. Members without Discord can read imported snapshots and queue replies, but replies are not marked Posted until the optional existing bot confirms an actual send and the officer imports its acknowledgement. WoW cannot directly connect to Discord; the relay uses explicit text handoff, not a live feed. The bot's local credentials/intents are not yet configured. Core/LFG use does not require the external companion. See DISCORD-MIRROR-SETUP.md for the owner setup and limits.