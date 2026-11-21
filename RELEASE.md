# Tranquility Guild Toolkit — release form

Prepared November 20, 2026. Current package **1.0.0-beta.14**. Files are prepared locally; no submission, approval, remote workflow run or live-client certification is claimed.

## Project fields

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Project name | Tranquility Guild Toolkit |
| Proposed slug | tranquility-guild-toolkit (use the existing project's slug when updating) |
| Summary | A modular guild dashboard for recruitment, groups, loot, auctions, summons and flight guidance. |
| Class | Addons |
| Main / additional categories | Guild; Chat & Communication; Auction & Economy; Map & Minimap — select matching labels available in the form |
| License | MIT, matching bundled source LICENSE notices; retain third-party asset notices |
| Logo/avatar | Select an original project PNG (minimum 400×400); no project avatar has been selected by this preparation. |
| Allow comments | Enabled |
| Listing visibility | Public; do not enable experimental/unlisted unless deliberately desired |
| Description format | Markdown; paste the description below |
| Author / members | Your actual CurseForge publishing account and actual contributors |
| Project ID | Use this addon's assigned numeric CurseForge ID; not available from local source |
| Source URL | https://github.com/BifrostTitan/Tranquility-Guild-Toolkit |
| Issues / wiki | Use actual published URLs; otherwise leave blank and use CurseForge comments |
| Donation / social links | Optional; leave blank unless you supply real links |
| Screenshots | Add real addon screenshots; no new screenshots are included in this handoff |

## Description — copy/paste

Open a compact dashboard with left-side navigation for guild information, recruitment, loot, auction research, member tools and services. The bundle includes separate guild modules, Tranquility Guild LFG, Uber, Looking For Profession Finder, Flight Path Finder and public World Navigation. Modules can be enabled separately; guild-only features retain their guild access rules. Recruitment messages are optional, and native game permissions still apply to invitations and services. Recorded guild activity reflects events observed by participating addons, not a complete server history. Flight guidance draws paths only. No private Titans toolkit, combat farming, external executables or automated travel is included.

Built for **Forever WoW 1.60.1 / Interface 16001**. Open `/tranq`. Other Retail/Classic clients are not certified by this release. Native game restrictions and unavailable APIs still apply.

## File upload fields

| Field | Value |
| --- | --- |
| Upload file | `Tranquility-Guild-Toolkit-1.0.0-beta.14.zip` — upload this ZIP alone |
| Display name | Tranquility Guild Toolkit 1.0.0-beta.14 |
| Release type | Beta |
| Release options | Release after moderation approval, or choose manual scheduling in your account |
| Supported client / version | Forever WoW 1.60.1, Interface 16001. Select its actual supported entry if offered; do not relabel it as another client. Confirm with CurseForge support if this client is not listed. |
| Related projects | No external required downloads: included modules resolve their dependencies inside this ZIP. |
| SHA-256 | `10cacf94d69059bd0edd8a6cfeeb2252f2f720831d6efc51bfd42ec0b1e248f7` |
| ZIP root addon folders (18) | `Tranquility`, `Tranquility_Auctions`, `Tranquility_DB`, `Tranquility_Dungeon`, `Tranquility_Gear`, `Tranquility_Info`, `Tranquility_LFP`, `Tranquility_Loot`, `Tranquility_Phases`, `Tranquility_PvP`, `Tranquility_Recruitment`, `Tranquility_Regions`, `Tranquility_Summons`, `Uber`, `FlightPathFinder`, `LookingForProfession`, `TranquilityLFG`, `WorldNavigation` |

### Changelog — copy/paste

Current dashboard and public companion modules assembled with matching toolkit version metadata. Private automation and development material excluded.

Packaging verified direct addon-root layout, manifest-declared files, matching generic/Camelot manifests, ZIP decompression/CRC and SHA-256. No gameplay or test suites were run for this packaging pass. Runtime limits are described above and in bundled READMEs.

## GitHub commit packaging

The repository's `.github/workflows/release.yml` builds an artifact on pushes. In GitHub Settings → Secrets and variables → Actions, set secret `CF_API_TOKEN`, variable `CF_PROJECT_ID`, and variable `CF_GAME_VERSION_IDS` with real supported numeric version IDs. No account tokens are stored in this document. Default-branch commits upload Alpha files when configured; a tag `v1.0.0-beta.14` uploads this Beta version. Generated ZIPs remain local build artifacts; commit source/configuration instead. Do not use duplicate CurseForge webhooks and Actions upload for the same commit.

Remote publication/configuration has not been performed. Missing logo, project ID, real supported-version selection or unpublished source URLs are author/account fields to complete before submitting. Private toolkit/helpers/recorders and private development reports are excluded.

## Official field references

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Submission fields, original logo and project links](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)
- [Upload API](https://support.curseforge.com/support/solutions/articles/9000197321)
