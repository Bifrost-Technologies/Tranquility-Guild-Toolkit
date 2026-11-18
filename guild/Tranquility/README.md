# Tranquility Guild Toolkit

An optional, modular guild toolkit for World of Warcraft: Forever 1.60.1
(Interface 16001). This build is a beta submission candidate. Other client
flavors are not declared supported.

Extract every Tranquility folder directly into `Interface/AddOns`, or install
the suite from its CurseForge project once available. Keep **Tranquility**
enabled; each **Tranquility:** feature is independently disableable in the
character-selection AddOns menu. Reload after changing enabled modules.

Open with **/tranq**, **/tq**, or the **TQ** button beside the minimap.
Use **Help and settings** for a complete walkthrough, local data removal and
diagnostics. Panels are movable and close with Escape.

| Addon | Purpose |
| --- | --- |
| Tranquility | Shared menu, launcher, UI and public WHO result reader |
| Tranquility_Recruitment | Guildless WHO browser, per-person invite/greeting text and skip history |
| Tranquility_Auctions | Manually sampled asking prices, daily-low baselines and ignore list |
| Tranquility_Loot | Dungeon/open-world loot and group-roll source observations |
| Tranquility_Dungeon | Local tank/healer pressure stats and a party report button |
| Tranquility_Summons | Zone-aware party checklist and one-click-per-ritual secure spell button |
| Tranquility_Regions | Manual WHO zone samples and population hints |
| Tranquility_Gear | Target inspection, rarity score and average item level |
| Tranquility_Phases | Regional channel observations and peer comparisons |
| Tranquility_DB | Optional Classic gathering/drop reference routes |
| Tranquility_Info | Help, settings, diagnostics and local data controls |

Recruitment: prepare a WHO command, copy it into Blizzard chat and run it
yourself. Import results, select a player, then copy the prepared invite or
personalized greeting and send it yourself. Explicitly mark contacted or
ignored players to skip them later. A prepared command is not a confirmed
invite. Only explicitly empty guild fields qualify as guildless.

Auction comparisons require at least three previous days of observations.
High asking prices are research hints, not evidence of sales or profit.
WHO results can be capped or stale; counts represent returned rows. Channel
numbers are phase hints, not verified world-layer IDs. Gear scores describe
equipment, not gold balances or player skill. Restricted data stays unknown.

The suite is free, readable Lua. It requires no desktop helper, service,
account, bot, external download or extra library. No external telemetry. Enabled Dungeon XP warnings can send rate-limited party messages. WHO searches and recruitment commands are entered manually;
each summon requires a physical click. Dungeon broadcasting is opt-in per
click and rate limited. Dungeon statistics stop when their panel closes; XP warnings remain enabled until /tranqxp off or the module is disabled.

Persistent data is local to SavedVariables. Recruitment stores contacted and
ignored names by realm. Loot records item/source observations. Auctions save
price history by realm and faction. Phase comparisons save peer details you
enter. Gear and dungeon snapshots are session-only. Logout or a manual
Blizzard `/reload` saves data. Help provides per-module deletion controls.
Disabling a module stops its observation code from loading.

For bug reports, include client version/build, addon version, enabled modules,
steps to reproduce, and the full Lua error. Remove private character details
before sharing diagnostics. The publisher should enable CurseForge comments
or an issue tracker for support.

MIT licensed. This package contains no third-party Lua libraries or bundled
game artwork. It is not affiliated with or endorsed by Blizzard or CurseForge.

Dungeon XP warnings: enabled while the Dungeon module is loaded. In party dungeons, targeted enemies and visible nameplates are checked against party levels. A member more than 12 levels above an observed enemy triggers a concise party warning naming that member. Unknown levels are skipped. Warnings are limited to one per 120 seconds and the same player/enemy-level combination is not repeated until the roster or area changes. `/tranqxp off` disables warnings for the session; `/tranqxp on` enables them. This predicts kill XP under the November 14/15 rule; it does not measure XP or claim every enemy in the dungeon is affected. Quest XP is not assessed.
Rule source: https://us.forums.blizzard.com/en/wow/t/player-level-dungeon-xp-adjustment-november-14/2416343/1


Current toolkit: 1.0.0-beta.4. The distribution contains the eleven toolkit folders plus optional standalone TranquilityLFG and Uber 0.4.0-beta.1. The home panel opens those companions when enabled. /tqlfg is restricted to Tranquility guild members and exchanges listings through guild addon messages. Uber has separate native-mail pricing, location-sharing and delivery-evidence behavior documented in its README. It is not required by the core; its separate public approval is pending. This package therefore includes both local records and explicit in-game data sharing, not a promise that every feature stays on one client.


TranquilityLFG 0.2.0-beta.1 adds separate Dungeon/Battleground/Arena pages, casual/ranked planning, bracket ratings when available, an opt-out active-addon directory, green leader flags, role/level/loot-aware proposals and explicitly armed paced formation. Carry mode allows only the lower-level leader. The Discord lounge uses trusted public-channel snapshots and explicit reply handoff to the optional bot; it is not a live external connection. The bot's owner credentials are not configured. No external companion is required for normal LFG.
