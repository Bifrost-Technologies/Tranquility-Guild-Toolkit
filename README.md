# Tranquility Guild Toolkit

A modular guild toolkit for World of Warcraft: Forever: private group finding, manual recruitment preparation, loot notes, auction research, dungeon information and a party summons checklist.

Current toolkit: **1.0.0-beta.4**, targeting **Interface 16001**. Bundled companions: **TranquilityLFG 0.2.0-beta.1** and optional **Uber 0.4.0-beta.1**. Open **`/tranq`** or **`/tq`**. The author is awaiting the separate Uber submission outcome before publication; this source snapshot does not claim platform approval.

## Features

- Eleven toolkit folders: shared core plus ten independently enableable features.
- Dedicated Dungeon, Battleground and Arena group-finder pages, casual/ranked planning and available bracket ratings.
- An opt-out active-member directory, separate from the ready queue, with green leader flags.
- Leader-armed, paced formation using roles, level ranges, armor/stat intent and desired item IDs; soft loot warnings and leader-only carry mode.
- Observed loot/source journal, asking-price research, target equipment information, manual WHO samples and phase hints.
- A physical-click summons checklist; optional Uber opens its separate booking/service interface.
- A Discord lounge for trusted-officer public-channel snapshots and acknowledged reply handoff. It is not a direct live Discord connection.

Dungeon XP warnings are a separate automatic, rate-limited party-message feature. `/tranqxp off` disables them for the session. Recruitment remains per-player/manual. LFG formation sends native invitation attempts only when the leader explicitly arms it; it does not enter Blizzard matchmaking or bypass native restrictions.

## Install

Use the named toolkit ZIP from a release. Extract its **13 addon folders** directly into `Interface/AddOns`, with no enclosing toolkit folder. Keep `Tranquility` enabled for its ten modules; `TranquilityLFG` and `Uber` are separately enableable companions. Restart after a fresh install. Use `/tqlfg` for group finding and `/uber` for the optional service interface.

From a source checkout, copy the eleven `guild/Tranquility*` addon folders plus the root `TranquilityLFG/` and optional `Uber/` folders. Do not install this entire repository as one addon folder.

## Source layout

| Path | Purpose |
|---|---|
| guild/ | Eleven toolkit runtime folders, source license and player documentation |
| TranquilityLFG/ | Standalone guild group finder and Discord snapshot panel |
| Uber/ | Bundled, separately versioned optional Uber source |
| curseforge/ | Detailed listing, form entries, FAQ, screenshot list and release checks |
| docs/uber/ | Documentation/assets needed to build the bundled Uber independently |
| tests/ | Public toolkit, LFG and bundled-Uber simulations |
| scripts/ | Build, author-material generation and ZIP verification |
| Build.ps1 | Toolkit build entry point |

The Uber copy is bundled to match the current distribution; it is not a Git submodule or a required external download. Keep it aligned with the separate Uber repository intentionally, preserving its own version, license and changelog. Updating one repository does not automatically update the other.

## Build and verify

Use Windows PowerShell and a Lua 5.1+ compatible runner or LuaJIT/Fengari. Node.js is needed for Fengari and standalone ZIP verification. From this repository root:

```powershell
.\Build.ps1
.\Build.ps1 -LuaRunner 'C:\path\to\lua.exe'
```

The toolkit build runs module-contract and current LFG suites, checks source/manifest/package scope, verifies archive hashes, and writes the installable ZIP plus author handoff under `share/Tranquility/` and `submission/Tranquility/`. Generated output is ignored by Git. The build does not install into WoW or publish anywhere.

Optional standalone companion checks:

```powershell
.\scripts\build-lfg-release.ps1
.\scripts\build-uber-release.ps1
```

Simulated checks do not replace real-client protected-action, party, rank, mailbox, networking and UI validation. See [the live checklist](curseforge/LIVE-TEST.md).

## Discord integration

The optional external bot is deliberately excluded from this public addon repository, along with all credentials and local data. Normal guild LFG does not require it. The in-game panel consumes explicit public-channel snapshots from a trusted officer and queues replies until actual bot-post acknowledgement. See [Discord setup](curseforge/DISCORD-MIRROR-SETUP.md) for the handoff and limits. Bot credentials/intents must be configured locally by the owner; none are supplied here.

## Publishing and support

[HOW-TO-GITHUB.md](HOW-TO-GITHUB.md) covers GitHub Desktop. [RELEASE.md](RELEASE.md) identifies release assets and submission materials. [The detailed description](curseforge/DESCRIPTION.md) and [form entries](curseforge/FORM-ENTRIES.md) are ready for author review. Nothing is initialized, committed or pushed automatically.

For issues, include the toolkit/companion version, exact client build, enabled modules, steps and full Lua error with private details removed. See [CONTRIBUTING.md](CONTRIBUTING.md). Persistent records use local SavedVariables and documented in-game sharing, not a required cloud account.

MIT License. Independent community project, not endorsed by Blizzard or CurseForge. Normal game/API rules apply; native unavailable ranks, loot sources and observations stay unknown.


## Source-only tracking

Only Lua, required .toc manifests, Markdown, licenses, source build/verification scripts and Git/editor metadata are included. Images, archives, generated releases, local settings and credentials are ignored. WoW loads Lua directly; no C++ compilation is required. Run Build.ps1 to validate and package in one step. Submission artwork is optional for the build; supply it locally at curseforge/avatar.png when needed, without committing it.


## Current security release

Tranquility Toolkit 1.0.0-beta.7 uses a character-bound membership vault, native Dedicated Member-or-higher access checks, profession jobs, player contracts and officer-reviewed payroll/watchdog records. Its bundled LFG is 0.3.0-beta.1; optional Uber is 0.5.0-beta.1 with completed-order star-only feedback. The Discord bot is a separate private guild service and is excluded from these repositories. Run `./scripts/check-public-source.ps1 -Repository .` to check ignore rules and source credential signatures. No game-folder writes, commits, pushes or uploads are performed by Build.ps1.
