## Updated vault onboarding (beta.6)

The vault can be closed with X/Escape. Its first double-click reveal is saved, so subsequent visits show the Discord invite and code form directly. Closing does not unlock anything, and routine roster updates do not reopen a dismissed vault. Use `/tranq` to reopen it.

Join https://discord.gg/CMjbSRYt6 and use the bot initiation command with your character name. The temporary shared code is **3781**. It is an onboarding reminder rather than proof of Discord membership or a secret: the Lua source remains readable. Only a native Tranquility guild member may submit it. An online admitted officer with native promotion permissions receives the request and attempts to assign Dedicated Member. If the API/permissions require manual action, the officer uses normal guild controls. The toolkit remains locked until the native rank and authenticated officer approval are observed. A known code never admits an outsider or suspended member.

The earlier character-bound, expiring officer-issued challenge flow remains supported. The private bot still needs local credentials and Discord role configuration; no account is created or token published by the addon.

# Membership, jobs and security

## Who can open the toolkit

A remembered vault unlock is bound to the native character GUID. Demotion, leaving the guild or a toolkit suspension revokes it. Native rank alone cannot reveal the toolkit: first complete the in-game four-digit vault challenge. The six-slot field appears only after double-clicking the sealed door and watching the inscription fade in. The native Guild Master has a one-time, locally displayed bootstrap PIN so an officer can initialize verification.

Only native Tranquility guild members with the exact **Dedicated Member** rank or a higher native rank can use the toolkit and guild LFG. Member is the entry rank; Member, lower ranks and outsiders see only:

> you are not a dedicated member of Tranquility. Please join our guild & discord to access Tranquility Guild Toolkit! Ty

Rank data comes from WoW, not a rank asserted in an addon packet. Unknown guild/rank information fails closed until the roster updates. Rank revocation hides toolkit panels and stops observed module work. The public standalone Uber service remains a separate addon for its public customers.

The native Guild Master is initially the only job administrator. The Guild Master can configure additional **exact native rank names** in the five-rank policy panel. No client-side addon can prevent someone modifying their own Lua; actual bank withdrawals, repairs and guild permissions must be restricted using WoW's server-enforced guild controls. Use deposit-only tabs for workers where appropriate.

## Discord verification

The separate, optional private Discord companion generates a random, expiring code and DMs it to the member. An officer imports the request into the verification panel. The officer selects Send in-game vault code. The matching native character receives a four-digit code by native addon whisper plus an in-game whisper, then enters it into the revealed vault. Incorrect codes never unlock; the native sender and imported request bind the proof to the character. An officer reviews and requests native promotion; where the client cannot assign the rank, use WoW's normal roster controls. Only an observed native Dedicated Member-or-higher rank produces confirmation for the bot to grant its Discord role.

This version uses an explicit officer-controlled file handoff. WoW does not connect directly to Discord, read arbitrary files during play, receive HTTP callbacks, or promote guild characters while no authorized player is online. Native guild repair allowances must be configured for Dedicated Member in-game. The bot never receives your WoW password.

The author has a separate Discord verification setup setup guide. Bot credentials, Discord account links and bot runtime data are intentionally excluded from these public source repositories and addon archives.

## Open the board

Use `/tranq jobs` or the Tradesman & guild jobs home button. All guild jobs support an item ID, quantity, destination bank tab, deadline, reward and profession/service category. Administrators post and review guild-funded jobs. Claims are assigned by the posting officer while online; wait for confirmation before producing goods. New guild LFG installations require the Tranquility core and its vault approval. A delivery report is a request for review, never proof of delivery or an automatic payment.

Categories include Alchemy, Blacksmithing, Armorsmithing, Weaponsmithing, Leatherworking, Tailoring, Enchanting, Engineering, Mining, Herbalism, Skinning, Cooking, First Aid, Fishing, Jewelcrafting, Inscription, Archaeology, Mercenary, Dungeon escort, PvP defense, Scouting, Loot Goblin and Custom. Expansion-specific professions are planning labels only; they do not grant unsupported skills or recipes.

## Payroll and job roles

| Role | Daily payroll policy | Review basis |
| --- | --- | --- |
| Guide | 1g | Quest/dungeon help; optional player-funded help offers |
| Summoner | 5g | More than one corroborated summon per UTC day on the observing provider client; show total and guild recipients |
| Professions | 5–15g | Officer-reviewed supply and demand; e.g. herbs 5g, fishing 12g, weapons 15g |
| Mercenaries | 5g | Reviewed guard, escort or PvP work, plus separate contract rewards |
| Loot Goblin | 5–25g | Reviewed dungeon activity and deposited loot/value, plus retrieval orders |

Use Officer payroll / job roles to assign/remove roles and approve one daily award per character/role in that officer's local ledger. Job roles can be separate from native guild ranks. The separate five-native-rank policy panel sets reviewed **guild order** payout caps; it does not rewrite native bank limits. Payroll approvals do not transfer gold. Officers must coordinate their ledgers and inspect native bank records before payment; separate offline officers cannot share a guaranteed atomic payment ledger. UTC-day accounting is distinct from WoW's bank reset schedule.

The Summoner policy blocks a payroll approval without enough retained, corroborated local delivery evidence. It never automatically demotes someone because an observer was offline or logs are incomplete. For a different provider, inspect that provider's retained Uber evidence and review its native rank manually. Dungeon-run counts and profession market demand are reviewed by officers; this build does not fabricate complete automatic run histories or market forecasts.

## Player help and mercenary contracts

Every admitted member can post a player-funded Guide or Mercenary offer with a free or paid price and location/objective text. Guide offers accept one helper; mercenary contracts support up to 40 accepted participants, each earning the posted reward. The posting requester must be online to assign claims. Accepting requires the relevant assigned job role (or the matching native rank).

Examples: quest help, dungeon escorts, guarding a summoning circle, or clearing a contested dungeon entrance. The requester reviews each participant separately, approves their work and explicitly records each manual payment. A participant's “Report complete” never pays them or proves the objective. Close the offer to stop new claims. Post only rewards you can afford; there is no escrow or automatic distribution.

## Bank watchdog

An authorized officer must open an accessible bank log and explicitly inspect the selected job's tab. The first log read establishes a baseline. Subsequent observed deposits are attributed to assigned item/quantity/tab jobs; one deposit cannot satisfy multiple jobs. Repeated identical log snapshots are not double-credited. Matching withdrawals or movements, including after payout, flag the job for review.

Logs are limited and have no dependable addon-visible global transaction ID. Repeated indistinguishable entries, log rollover, inaccessible tabs, offline periods and other officers' legitimate moves can leave gaps or ambiguity. Such observations are review evidence, not server-certified delivery or proof of fraud. The watchdog does not run as an external 24/7 service. It never automatically bans or transfers money. After investigation an authorized officer can suspend/restore toolkit access; native guild removal or bank restrictions remain manual server controls.

Audit retention is bounded: 2,000 audit events, 100 evidence entries per job, 200 guild jobs and 100 player contracts per client. Do not treat this as a permanent accounting database. Preserve SavedVariables backups and coordinate completed-order retention before capacity is reached.

## Loot buyback

In an administrator's guild order form select **Loot Goblin**, enter quantity and item ID, then press Enter in the item ID field. A fresh (15 minutes) observed AH snapshot and loaded uncommon/rare/epic item data can fill the reward at twice the per-unit observed asking price times quantity. Check it before posting. Asking prices are not guaranteed sale prices. No auction API or fresh data means no invented quote. You can still manually enter a reviewed price.

## Uber quality and feedback

Native-confirmed Tranquility providers have gold names in the Uber roster. This confirmation is available from a matching native party/self unit or your native Tranquility roster; unknown remote membership is not invented. Right-click a provider → Rate completed service to submit 1–5 stars after a corroborated order. One review per order; no comments and no pre-populated five-star ratings. Aggregates are provider-reported client records, not tamper-proof independent reviews.

## Status and data privacy

Officers can copy a bank / LFG status line for the private Discord companion. Bank value is available only from an open accessible bank; the LFG figure counts fresh ready leader profiles. The bot presence explicitly calls it a snapshot, expires it after 15 minutes, and shows unavailable when missing. It is not a continuous live bank connection.

Local SavedVariables contain character identities, job assignments, audit records and verification links. Bot data contains Discord account IDs and expiring verification challenges. Keep both private and disclose guild data use to members. Public archives contain readable source and documentation, not tokens, bot configuration, account data or executable companions.
