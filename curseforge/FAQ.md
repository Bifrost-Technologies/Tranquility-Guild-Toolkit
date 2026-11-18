# Tranquility — FAQ and support copy

## Who is this for?

Guild members who want a shared menu for group planning, loot notes, auction research, recruitment preparation and party helpers. Most toolkit panels are local tools. The private TranquilityLFG board specifically requires membership in the guild named Tranquility and the addon enabled on each participating member.

## Do I need all 13 folders enabled?

No. Keep Tranquility enabled for its ten feature modules, then disable whichever optional modules you do not use. TranquilityLFG and Uber are standalone companions and can be disabled separately. Disabling Uber does not disable the core, loot journal, auction research or basic summons checklist.

## Are there required third-party dependencies?

No external project download, library, service account or desktop program is required. Toolkit modules depend on the core that is included in the same ZIP. Leave required CurseForge Related Projects empty for the current distribution.

## Is Uber already approved?

The author is awaiting its separate submission result. This preparation does not claim approval. The current toolkit bundle includes Uber 0.4.0-beta.1. Check the actual reviewed file/version before publishing a combined bundle. Its pricing, mail and evidence features are documented separately.

## Does LFG send guild-chat advertisements or enter matchmaking?

Listings use the guild addon channel, not visible guild-chat advertisements. The board coordinates plans among guildmates. It does not enter Blizzard matchmaking or make an unsupported arena/rated mode available. Manual invitations require your click; the leader can also explicitly arm paced formation using ready matches, subject to normal game permissions.

## Does recruitment automatically invite or whisper people?

No. You run the native WHO query, import results, select a person, and copy/submit the prepared command yourself. Contacted/ignored histories record deliberate actions. Unknown guild data is never considered confirmed guildless.

## Why did the addon post an XP warning?

The Dungeon module's XP warnings begin enabled when loaded. They check available party/enemy levels in party dungeons and may send a rate-limited warning. Use /tranqxp off to disable them for the session or disable the Dungeon module. /tranqxp on re-enables them. They are separate from the clicked dungeon-summary report. Predictions concern observed enemies, not measured XP or every mob in the instance.

## Does a loot journal entry prove I received an item?

No. Seen, roll-offered and received observations are distinct. Unknown sources stay unknown. It is not a complete loot table or drop-rate measurement.

## Are auction opportunities guaranteed profit?

No. Asking prices and daily-low samples do not prove completed sales, demand or a buyer. Historical comparisons need at least three prior sample days. The addon does not buy, sell or repeatedly search auctions automatically.

## Does the basic summons panel verify delivery?

It manages a physical-click party checklist, not an independent payment or delivery certificate. Optional Uber has separate cast/party/customer-arrival observations, with documented limits. One cast alone is not proof of a successful purchase.

## Where is data stored and who sees it?

Persistent records use normal local SavedVariables. Guild LFG shares listings with participating guildmates; clicked summaries and enabled XP warnings use party chat. Optional Uber sends its service/location/evidence records to participating clients and creator. There is no required external cloud backend. Avoid sensitive notes and remove private names from public bug reports.

## Does it work on Retail or other Classic flavors?

This candidate targets Forever / Interface 16001 only. Other flavors are not claimed as supported. Record your exact client build when reporting problems.

## What should I include in a bug report?

Toolkit version, the relevant companion version if applicable, exact game build, enabled modules, steps to reproduce, expected/actual behavior and full Lua error. Remove private character/account details. Use the project's comments or the actual support link published by the owner.

## Can I turn off a feature without deleting my history?

Disable the module in the native AddOns menu. Help and settings offers separate local data controls. Back up SavedVariables before deleting data; a module being disabled is different from erasing its saved history.
## New in the guild group finder

The group finder now has three dedicated pages: Dungeons, Battlegrounds and Arena partners. Battlegrounds distinguish casual/ranked planning and 10/15/40-player teams. Arena listings support 2v2, 3v3 and 5v5. Native bracket ratings and honor ranks are shown where available; remote figures are client reports, not independently certified ranks. Unsupported game modes remain planning categories rather than native matchmaking queues.

An active-addon directory is separate from the ready queue. Discovery begins enabled and can be switched off in My profile. Available members may receive deliberate leader invitations; only freshly READY, activity-matching players are considered by auto formation. Green flags identify volunteering leaders, and only the solo player or actual native leader's client controls invites.

The leader's group builder proposes correct roles and level ranges while optionally reducing estimated loot competition. It models level-dependent armor proficiency, healing/spell/strength/agility/defense intent and up to eight desired item IDs per member. Holy and Protection Paladins are not treated as identical loot profiles. Shared caster armor or exact matching desired items carry stronger penalties. Soft warnings count same-armor/likely competing party members; leaders may confirm an intentional duplicate. Local observed dungeon loot sources can be reviewed when the Loot journal has them. No complete Forever drop tables or guaranteed exclusive needs are claimed.

Dungeon teams use one tank, one healer and three DPS; flexible declared roles can fill gaps. PvP tank/healer targets can be customized. A leader-only carry toggle permits the below-range leader above the chosen entry floor, while every other selected player must meet the normal range. The entry floor is a planning setting, not verified native dungeon access.

Auto formation starts only after the leader queues and explicitly arms it. It sends one invitation at a time, waits for native group changes, and skips unanswered invitations after 25 seconds with a five-minute backoff. Combat skips invite ticks; native failures, lost leadership, leaving queue/guild or missing profiles stop formation. Pause is always available. It does not enter Blizzard activity queues or bypass group/raid permissions.

The new Discord lounge displays public-channel snapshots from a configured trusted in-game officer. The supplied invite identifies Tranquility Server #general. Members without Discord can read imported snapshots and queue replies, but replies are not marked Posted until the optional existing bot confirms an actual send and the officer imports its acknowledgement. WoW cannot directly connect to Discord; the relay uses explicit text handoff, not a live feed. The bot's local credentials/intents are not yet configured. Core/LFG use does not require the external companion. See DISCORD-MIRROR-SETUP.md for the owner setup and limits.