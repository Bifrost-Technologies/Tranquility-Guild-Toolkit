# Tranquility — author handoff

Current candidate: **Tranquility Guild Toolkit 1.0.0-beta.4** for Forever / Interface 16001. Publication is on hold while the author awaits the separate Uber submission result. This folder prepares materials; it does not submit anything.

| Need | File |
|---|---|
| Complete form values and dependency answer | FORM-ENTRIES.md or PROJECT.md |
| Recommended summary and alternatives | SUMMARY.md |
| Detailed public project description | DESCRIPTION.md |
| Current file changelog | CHANGELOG.md |
| Ready-to-post guild announcement | DISCORD-README.md |
| Discord messages split below 2,000 characters | discord-posts/Post-01.txt onward |
| Answers for comments/support | FAQ.md |
| Real gameplay capture list and captions | SCREENSHOTS.md |
| Original 400×400 project logo | avatar.png |
| Local/client and release checks | LIVE-TEST.md, RELEASE-CHECKS.md, POLICY-REVIEW.md |
| Upload | Tranquility-Guild-Toolkit-1.0.0-beta.4.zip only |

The ZIP contains 13 installable addon folders: the core, ten feature modules, TranquilityLFG and optional Uber 0.4.0-beta.1. No external required dependency download is needed. Keep the core enabled for toolkit modules. The optional Uber approval/version must be checked before publishing this combined distribution; approval of a separate file does not automatically cover the bundle.

The docs disclose automatic Dungeon XP warnings and how to disable them, quiet guild-addon LFG messaging, optional Uber service/payment reporting, local storage and explicit in-game sharing. They do not promise that every feature is silent or that all information remains on one client.

Use the actual publisher account, tested game tag and real source/support links. Add your own in-game images. Keep this author folder outside the upload ZIP; upload the addon ZIP alone. SHA-256/preflight files are local validation records, not additional required addon downloads.

## New in the guild group finder

The group finder now has three dedicated pages: Dungeons, Battlegrounds and Arena partners. Battlegrounds distinguish casual/ranked planning and 10/15/40-player teams. Arena listings support 2v2, 3v3 and 5v5. Native bracket ratings and honor ranks are shown where available; remote figures are client reports, not independently certified ranks. Unsupported game modes remain planning categories rather than native matchmaking queues.

An active-addon directory is separate from the ready queue. Discovery begins enabled and can be switched off in My profile. Available members may receive deliberate leader invitations; only freshly READY, activity-matching players are considered by auto formation. Green flags identify volunteering leaders, and only the solo player or actual native leader's client controls invites.

The leader's group builder proposes correct roles and level ranges while optionally reducing estimated loot competition. It models level-dependent armor proficiency, healing/spell/strength/agility/defense intent and up to eight desired item IDs per member. Holy and Protection Paladins are not treated as identical loot profiles. Shared caster armor or exact matching desired items carry stronger penalties. Soft warnings count same-armor/likely competing party members; leaders may confirm an intentional duplicate. Local observed dungeon loot sources can be reviewed when the Loot journal has them. No complete Forever drop tables or guaranteed exclusive needs are claimed.

Dungeon teams use one tank, one healer and three DPS; flexible declared roles can fill gaps. PvP tank/healer targets can be customized. A leader-only carry toggle permits the below-range leader above the chosen entry floor, while every other selected player must meet the normal range. The entry floor is a planning setting, not verified native dungeon access.

Auto formation starts only after the leader queues and explicitly arms it. It sends one invitation at a time, waits for native group changes, and skips unanswered invitations after 25 seconds with a five-minute backoff. Combat skips invite ticks; native failures, lost leadership, leaving queue/guild or missing profiles stop formation. Pause is always available. It does not enter Blizzard activity queues or bypass group/raid permissions.

The new Discord lounge displays public-channel snapshots from a configured trusted in-game officer. The supplied invite identifies Tranquility Server #general. Members without Discord can read imported snapshots and queue replies, but replies are not marked Posted until the optional existing bot confirms an actual send and the officer imports its acknowledgement. WoW cannot directly connect to Discord; the relay uses explicit text handoff, not a live feed. The bot's local credentials/intents are not yet configured. Core/LFG use does not require the external companion. See DISCORD-MIRROR-SETUP.md for the owner setup and limits.