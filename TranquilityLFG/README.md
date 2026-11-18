# Tranquility Guild LFG

Version **0.2.0-beta.1**, Forever Interface 16001. Open **/tqlfg** or use the guild toolkit's Guild LFG button. Members of the guild named Tranquility use the same addon for dungeon teams, battleground planning, arena partners and a public-Discord snapshot lounge.

## Three activity pages

- **Dungeons:** five-person groups; choose up to five matching activities, role, notes and readiness.
- **Battlegrounds:** casual or ranked planning, 10v10/15v15/40v40 team sizes, native bracket ratings where available and configurable healer/tank targets.
- **Arena partners:** 2v2, 3v3 and 5v5 with matching team sizes, casual/skirmish or ranked category and bracket-specific rating displays.

This coordinates players, not Blizzard matchmaking. It does not enter a native dungeon/BG/arena queue or enable unavailable game modes. Ranks/ratings are read from the player's native APIs when available, then reported by their addon; remote values are not independently certified. Unavailable stays unavailable. Honor rank is separate from rated bracket rating.

## Available is different from ready

Loading the addon makes participating Tranquility members discoverable by default, even without queueing. **Who has LFG active?** shows that directory; it is not a native WHO search and sends no automatic WHO request. Available members can receive deliberate leader invitations through the day without promising immediate readiness. **My profile → Discoverable** turns it off and leaves the ready queue.

**Queue · ready now** says you are prepared for that activity now. Automatic formation only selects fresh ready listings matching the leader's queued activity/category/bracket; it never automatically selects passive directory members. Profiles expire after 150 seconds, ready listings after 120 seconds without renewal. Reload begins unqueued and auto formation off. Discovery/profile preferences persist.

## Leader flag and automatic formation

Volunteer under **My profile → Leader**. The green flag shows a potential leader, not control over anyone else's client. Only a solo player or the actual native party leader can initiate invites, and only that leader's own client runs the builder. Losing leadership, leaving the queue or guild, a blocked invite, missing party profiles or insufficient candidates stops formation.

Choose your activity, queue, open **Group builder**, apply level/role/rating filters and build a proposal. Inspect the chosen names and roles, then click **Start auto formation**. Native invitation attempts are paced, with one pending invitation at a time and at least three seconds between attempts. Group roster changes confirm joining; an attempted invite does not mean accepted. A 25-second timeout skips that candidate for five minutes. Combat skips invitation ticks and resumes after combat if formation is still active. Native failures are not bypassed or repeatedly retried. Use **Pause formation** or leave the ready queue to stop.

Dungeon composition is **1 tank, 1 healer, 3 DPS**, with flexible class roles assigned where declared. PvP tank/healer targets can be set, including zero, or left at auto. Large battleground groups may require normal raid conversion/confirmation; the addon does not silently convert the group. It never changes another member's talents, loot rules or role consent.

## Loot diversity

The optional diversity toggle scores armor proficiency **at the player's level**, declared loot/stat intent, assigned role and exact desired item IDs. Warriors/Paladins and Hunters/Shamans change armor tier at level 40 in this model; Druids/Rogues and cloth classes retain their respective tiers.

Three cloth caster DPS get a stronger overlap penalty than a Holy Paladin and Protection Paladin. Healer, spell DPS, strength, agility and defense intents are distinguished. Shared weapons/jewelry or explicit matching wishlist items can still cause competition across armor types. Low-score teams are proposals, not a guarantee that every drop has a unique owner. Off-spec needs, actual equipped gear and incomplete drop information can differ from the profile.

Leaders can deliberately invite duplicate armor/stat users. A soft advisory counts existing same-armor users and likely shared needs, then **Confirm invite** proceeds. No member is kicked or barred solely for armor. Turn diversity off for ordinary composition without this optimization.

In **My profile**, select a primary role or all supported class roles, cycle loot intent, and share up to eight desired item IDs. **Review observed dungeon loot** reads matching local Tranquility Loot journal sources when that module has observed them. It does not invent a complete Forever drop table; use real item wishlists and verify availability. Missing observations remain unknown.

## Leader carry mode

The leader chooses a normal minimum/maximum and an entry floor, then enables **Carry run: only I am the lower-level member**. The volunteering leader must actually be below the normal minimum and at/above the chosen entry floor. Every other selected member must satisfy the normal range. Example: a level-12 leader can request level-18–24 helpers for Deadmines with an entry floor of 10. A level-20 leader cannot use that toggle to bring some other level-12 player automatically.

These are leader planning filters, not verification of dungeon unlocks, quests, native entry rules or XP awards. Set them to the actual activity/client rules. Normal runs reject an underlevel leader from automatic composition too.

## Discord lounge and existing bot companion

The public invite is **https://discord.gg/CMjbSRYt6**. The supplied configuration identifies **Tranquility Server**, guild ID **1570745250148909216**, **#general**, channel ID **1570745250958282803**.

WoW addons cannot call Discord HTTP APIs or open a socket. This lounge therefore uses a trusted in-game officer and the existing external Discord bot's **explicit snapshot/reply handoff**. It is not a direct live chat connection. The toolkit/LFG features do not require the bot.

1. Configure the bot locally with its own credentials and Message Content intent. No bot token goes into the addon or addon ZIP. Mirror capture is disabled until explicitly enabled.
2. The bot validates public text-channel access in the Tranquility server and writes a bounded plain-text snapshot. It excludes bot replies and never captures DMs/private channels for this mirror.
3. Each member configures the exact trusted officer character and allowed aliases (start with `general`) in the lounge. Unknown relays/channels are rejected.
4. The officer pastes/imports the bot snapshot. It is replicated through guild addon messages and shown with source/channel/author/time. Snapshot messages are bounded/truncated, not a promise of live edits/deletion sync.
5. A member can queue a reply inside WoW. It is **not yet posted to Discord**. The officer exports pending replies into the bot's approved local file and explicitly runs its post-replies command.
6. Only a successful Discord send returns a message ID acknowledgement. The officer imports those acknowledgements to mark the matching WoW replies Posted. Ambiguous sends require review instead of automatic resending.

No credentials, executable bridge, socket code or third-party Lua library is bundled in this addon. Optional bot source/setup is kept outside the public addon ZIP. Local bot credentials are not configured in the supplied environment; public invite metadata is not bot authorization. See the toolkit submission's Discord setup guide.

## Data and limits

Guild addon messages contain character names, reported class/level/roles, readiness, leader preference, armor/stat intent, desired item IDs, bracket rating/honor rank and activity notes. No private whispers or keystrokes are read. Discovery can be disabled; do not put sensitive information in shared fields.

Up to 250 profiles/listings, 50 queued outgoing packets and one guild packet per second. LFG state packets have priority over Discord snapshots. The builder considers a bounded role/class-diverse candidate shortlist and beam search rather than an unbounded combination search. It favors low estimated competition, not a provably optimal exhaustive result.

Discord retains up to 120 snapshot messages and 100 reply records locally. Names and timestamps identify reported senders; remote addons and relay officers can modify reports, so this is not independent identity/rank certification. Saved preferences/snapshots use normal logout/reload persistence, with normal crash-loss limits. Native party permissions, combat and available APIs apply.

Beta: simulated tests exercise protocol, formation and GUI initialization. Live native invitation, rank API, multiplayer, actual loot-source data and Discord handoff tests remain required. MIT; see LICENSE.