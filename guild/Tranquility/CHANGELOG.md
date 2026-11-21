## 1.0.0-beta.15

Replace standalone integrations with copyable CurseForge download pages; exclude standalone addon distributions from the guild install ZIP. Keep protected controls out of the dashboard hierarchy so ordinary navigation/closing remains available in combat. Repair guild work settings and stop reporting unsent claims/deliveries when the queue is full. Existing guild LFG remains bundled. Automated module/security/runtime regressions pass; live combat UI testing is pending.

## 1.0.0-beta.14

Current dashboard and public companion modules assembled with matching toolkit version metadata. Private automation and development material excluded.

Private executables/automation excluded. Packaging-only review; no new gameplay or test suites. Client: Forever WoW 1.60.1 / Interface 16001.

## 1.0.0-beta.12

Updated bundled public navigation, Uber and profession modules with the source-audit corrections. Source/syntax review only; no behavioral/live tests run.

# 1.0.0-beta.10

- Bundled standalone Flight Path Finder 0.1.0-beta.1 with large Alliance/neutral flight-node map pins and native coordinate directory.
- Added home launcher and /tranq flights shortcut; the same independent addon remains usable without guild membership.
- Native client data replaces a stale static flight-point list; learned status stays character-specific when reported by the client.

# 1.0.0-beta.9

- Moved reconnaissance into independently disableable Tranquility: PvP (core dependency).
- Added Radar, Heatmap, Danger alerts and Settings pages, with configurable nearby concentration warnings and optional sound.
- Alerts consider distance, observed count and age; leaving the area or disabling PvP clears warnings. No complete layer enumeration, hidden unit data or through-wall models.

# 1.0.0-beta.8

- Added opt-in world-defense scouting and guild-shared world-map heat circles with 20-second expiry.
- Prefer public native unit/world coordinates with player-based axis calibration; use clearly labeled scout proximity only when enabled and precise positioning is unavailable.
- Added friendly filtering, conservative anonymous density counts, replay/bounds/rank guards and bounded map pin pools. No restricted-value bypass or automated combat.

# 1.0.0-beta.7

- Bundled Uber 0.5.0-beta.1: observed network statistics, disclosed public opt-out/private creator census, active-session joining and native leading-warlock raid conversion.
- Added bounded background traffic with booking/receipt priority and freshness/capacity checks.

# 1.0.0-beta.6

- Vault now closes with X or Escape and respects dismissal during login/roster updates.
- Double-click reveal is remembered permanently; the inscription fades into Discord instructions and a copyable invite.
- Added temporary shared Discord initiation code for existing guild members, with an online authorized officer requesting native Dedicated Member promotion. Outsiders and suspended members stay denied.
- Kept character-bound challenges and native rank confirmation; no simulated guild promotions.

# 1.0.0-beta.5

- Added native Dedicated Member-or-higher access gate and locked recruit verification path.
- Added officer-reviewed profession jobs, observed bank evidence, duplicate protection and withdrawal flags.
- Added player Guide offers, multi-participant mercenary contracts, five job roles and bounded daily award records.
- Added expiring Discord character verification handoff and optional bank/LFG status snapshots; bot credentials remain private and separately configured.
- Bundled TranquilityLFG 0.3.0-beta.1 and Uber 0.4.0-beta.2 with native-confirmed gold guild names and completed-order star-only feedback.
- No automatic gold transfers, invented delivery proof, fabricated reviews or automatic guild bans.

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

## 1.0.0-beta.11

- Added a scrollable Automatic features section directly to the main menu, with saved settings, dependency hints and unavailable-module states.
- Included the missing local NPC/player nameplate enhancement renderer in the guild toolkit, with independent effect switches and guild-access checks.
- Linked existing PvP scouting/alert and Flight Path Finder settings to the main menu.
- Added a passive loot-journal recording switch that preserves existing history.
- Fixed restoring an already-created minimap launcher after hiding it.
- Added behavioral tests for immediate effects, persistence, optional-module absence, guild access and combat-safe game settings.
