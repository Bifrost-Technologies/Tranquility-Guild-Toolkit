# Tranquility 1.0.0-beta.10 — submission review record

Prepared November 17, 2026. Scope: current 13-folder distribution and its listing materials. This records preparation and known remaining checks, not platform approval.

## What the package includes

Eleven Tranquility folders, TranquilityLFG and optional Uber 0.5.0-beta.1. Toolkit modules depend on the bundled core. No required external project/library download, executable helper, credentials, personal SavedVariables or mock screenshots enter the ZIP. All addon source is readable Lua with MIT notices. Native game textures are referenced by path rather than redistributed as artwork.

## Runtime statements the listing must preserve

- Recruitment prepares per-person text. Native WHO queries and recruitment submission remain manual; no background recruitment loop is included.
- Auction research uses manually searched/entered observations. There are no automatic purchases, sales or repeated scans.
- Basic party summons requires physical clicks and normal spell/helpers/reagent permissions.
- Dungeon summaries require clicks, while the separate XP-warning feature can automatically send rate-limited party warnings. It begins enabled with the Dungeon module and /tranqxp off disables it for the session.
- TranquilityLFG exchanges guild-only addon packets, renews/expiring listings and uses clicked invitations or explicitly leader-armed, paced formation. It coordinates plans rather than entering Blizzard matchmaking.
- Optional Uber exchanges provider/customer/admin records, supports native-mail drafts and includes service commissions. Its documentation must accompany any bundle containing it; approval and policy review are pending separately.
- Local SavedVariables store records, but LFG, clicked reports, XP warnings and Uber share their documented data in game. Do not claim that all data remains on one client or that no messages occur automatically.
- Unavailable/restricted data stays unknown. No protected-action or secret-value bypass is included. Source/package checks do not establish real-client API acceptance or absence of taint.

## Listing and assets

Use the detailed DESCRIPTION.md, one-sentence SUMMARY.md entry and actual version/tag. The avatar is the existing original 400×400 PNG. Use real screenshots; label generated branding/mock layouts appropriately if shown. Keep comments or an actual support channel enabled. Supply only real source/support URLs and assigned project IDs. No external file-download links belong in the public description.

## Release decision

The author is waiting for the Uber result before publishing Tranquility. Confirm what exact Uber version was reviewed and resolve any requested changes; an approval for another project/file does not automatically approve this bundle. Keep Beta until live tests are recorded. The commission-service model remains a distinct policy question, not an archive-layout issue.

Check native summon clicks/combat lockdown, available XP-warning APIs, WHO imports, auctions, inspection, private LFG delivery/permissions, data controls and UI scales on the supported build. Record actual observations in LIVE-TEST.md. Do not turn a simulated test pass into a claim of complete live compatibility.

References reviewed:

- https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies
- https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips
- https://support.curseforge.com/support/solutions/articles/9000209856
- https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1
## New in the guild group finder

The group finder now has three dedicated pages: Dungeons, Battlegrounds and Arena partners. Battlegrounds distinguish casual/ranked planning and 10/15/40-player teams. Arena listings support 2v2, 3v3 and 5v5. Native bracket ratings and honor ranks are shown where available; remote figures are client reports, not independently certified ranks. Unsupported game modes remain planning categories rather than native matchmaking queues.

An active-addon directory is separate from the ready queue. Discovery begins enabled and can be switched off in My profile. Available members may receive deliberate leader invitations; only freshly READY, activity-matching players are considered by auto formation. Green flags identify volunteering leaders, and only the solo player or actual native leader's client controls invites.

The leader's group builder proposes correct roles and level ranges while optionally reducing estimated loot competition. It models level-dependent armor proficiency, healing/spell/strength/agility/defense intent and up to eight desired item IDs per member. Holy and Protection Paladins are not treated as identical loot profiles. Shared caster armor or exact matching desired items carry stronger penalties. Soft warnings count same-armor/likely competing party members; leaders may confirm an intentional duplicate. Local observed dungeon loot sources can be reviewed when the Loot journal has them. No complete Forever drop tables or guaranteed exclusive needs are claimed.

Dungeon teams use one tank, one healer and three DPS; flexible declared roles can fill gaps. PvP tank/healer targets can be customized. A leader-only carry toggle permits the below-range leader above the chosen entry floor, while every other selected player must meet the normal range. The entry floor is a planning setting, not verified native dungeon access.

Auto formation starts only after the leader queues and explicitly arms it. It sends one invitation at a time, waits for native group changes, and skips unanswered invitations after 25 seconds with a five-minute backoff. Combat skips invite ticks; native failures, lost leadership, leaving queue/guild or missing profiles stop formation. Pause is always available. It does not enter Blizzard activity queues or bypass group/raid permissions.

The new Discord lounge displays public-channel snapshots from a configured trusted in-game officer. The supplied invite identifies Tranquility Server #general. Members without Discord can read imported snapshots and queue replies, but replies are not marked Posted until the optional existing bot confirms an actual send and the officer imports its acknowledgement. WoW cannot directly connect to Discord; the relay uses explicit text handoff, not a live feed. The bot's local credentials/intents are not yet configured. Core/LFG use does not require the external companion. See DISCORD-MIRROR-SETUP.md for the owner setup and limits.

## November 17 security update

Rechecked [CurseForge moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies) and [Blizzard UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1). The vault hides UI until free guild membership verification; it does not encrypt or obfuscate source, charge for addon access, or ship another franchise’s images/music. No real-money fees or addon-development donation requests are added. Publish accurate functional descriptions and use real in-game screenshots; label any design/mock previews. Exclude the private bot, credentials, player histories and external executable helpers from the public addon archive.

Local archive checks are not a CurseForge acceptance verdict. Guild-only rank/Discord onboarding requirements must be disclosed, and moderator questions about the project should be answered with the actual code/workflow. Select only the client version actually tested; the current 16001 manifest is not evidence of Retail compatibility. Do not change the client tag just to pass an upload.
