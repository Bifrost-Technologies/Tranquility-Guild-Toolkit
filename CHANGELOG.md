# 1.0.0-beta.4

- Expanded TranquilityLFG to dedicated Dungeon, Battleground and Arena pages, casual/ranked categories, 10/15/40-person battleground planning and 2v2/3v3/5v5 arena partner listings.
- Added bracket-specific native ratings/honor-rank observations where available; unavailable values stay unknown and peer reports are labeled as reports.
- Added an opt-out active-addon directory, separate from the ready queue, so available guildmates can receive deliberate leader invites without queueing.
- Added green leader flags, flexible roles, armor/stat loot intent and exact item wishlists.
- Added a leader-armed group builder that balances roles/levels and estimated loot overlap, with configurable diversity, PvP role targets and leader-only carry mode.
- Added paced automatic invitation attempts for ready matches, one pending invite at a time, explicit pause, timeout backoff and stops on native failure or loss of leadership.
- Added a Discord lounge using trusted-officer public-channel snapshots, queued replies and actual-post acknowledgements from the existing optional bot companion. It is not a live external socket in WoW.
- Identified the supplied public Tranquility Server #general target; bot credentials/intents still require local owner setup before capture/posting.
- Refreshed submission materials and included TranquilityLFG 0.2.0-beta.1 with optional Uber 0.4.0-beta.1. Publication remains on hold pending the author's Uber review outcome and live checks.

# 1.0.0-beta.3

- Added rate-limited dungeon XP warnings with /tranqxp on and /tranqxp off controls, separate from clicked party summaries.
- Added home-panel access to the standalone TranquilityLFG guild activity board for dungeon and PvP planning.
- Added optional Uber entry points from Home and Summons; the bundled Uber service remains separately enableable and its approval is pending.
- Bundled TranquilityLFG 0.1.0-beta.1 and Uber 0.4.0-beta.1 alongside the eleven toolkit folders.
- Refreshed listing, form entries, feature guide, FAQ, Discord messages, screenshot checklist and release documentation to describe the actual package and messaging/data behavior.
- Packaged explicit addon paths and source/hash checks. No required external library or desktop application.

This toolkit candidate targets Forever Interface 16001. Core/module contract tests pass; live-client and optional companion checks remain in the acceptance record. Hold publication while the author awaits the separate Uber submission outcome.

# 1.0.0-beta.2

- Tightened restricted-data handling for guild status, summons, inspections and auction results.
- Paused dungeon monitoring on unavailable client reads instead of retaining stale assessments.
- Prevented old inspect timeouts from cancelling newer requests for the same target.
- Refreshed public-facing help and documentation and added distribution content checks.
- Prepared the upload in a dedicated folder containing only shareable materials.

# 1.0.0-beta.1

Initial public Tranquility Guild Toolkit beta.

- Added a shared `/tranq` menu, minimap launcher and in-game help.
- Split recruitment, auctions, loot, dungeon stats, summons, region samples,
  gear, phase hints, reference data and help into ten optional addons.
- Added manual recruitment commands, personalized greeting text and explicit
  contacted/ignored history. No bulk invitations or automated whispers.
- Added manual price sampling, daily-low history, ignore controls and journal
  source lookup. Auction prices remain research hints.
- Preserved passive loot/roll observations, opt-in local dungeon pressure
  stats, per-click party summaries and one-click-per-ritual summons.
- Added separate local SavedVariables and module data-deletion controls.
- Packaged readable addon code, documentation and MIT notices.

Target: Forever 1.60.1, Interface 16001. Offline contract checks pass; live
client smoke tests and CurseForge moderation remain required. Do not label
this beta as a stable release solely because offline checks pass.
