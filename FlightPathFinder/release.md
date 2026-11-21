# Flight Path Finder — release form

Prepared November 20, 2026. Current package **1.1.3-beta.2**. Files are prepared locally; no submission, approval, remote workflow run or live-client certification is claimed.

## Project fields

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Project name | Flight Path Finder |
| Proposed slug | flightpathfinder (use the existing project's slug when updating) |
| Summary | Find faction-appropriate flight masters and follow road-preferred map and minimap guidance. |
| Class | Addons |
| Main / additional categories | Map & Minimap; Travel — select matching labels available in the form |
| License | MIT, matching bundled source LICENSE notices; retain third-party asset notices |
| Logo/avatar | Select an original project PNG (minimum 400×400); no project avatar has been selected by this preparation. |
| Allow comments | Enabled |
| Listing visibility | Public; do not enable experimental/unlisted unless deliberately desired |
| Description format | Markdown; paste the description below |
| Author / members | Your actual CurseForge publishing account and actual contributors |
| Project ID | Use this addon's assigned numeric CurseForge ID; not available from local source |
| Source URL | Not configured/published locally; fill this after publishing the repository. |
| Issues / wiki | Use actual published URLs; otherwise leave blank and use CurseForge comments |
| Donation / social links | Optional; leave blank unless you supply real links |
| Screenshots | Add real addon screenshots; no new screenshots are included in this handoff |

## Description — copy/paste

Browse flight masters by location, show native blue/yellow flight icons, and toggle markers and path guidance independently from the minimap menu. Alliance and Horde nodes use native client data. Learned status is confirmed only by available taxi data. Bundled World Navigation generates road-preferred 2D image-weight routes, with world-map/minimap lines, a direction compass and an optional wisp guide. These are visual directions: no movement helper or automatic travel is included. Image weights cannot guarantee cliffs, collision, safe passage or exact ground height. Missing native map alignment or routing coverage is reported. Speak to a flight master in game to learn a flight path.

Built for **Forever WoW 1.60.1 / Interface 16001**. Open `/fpf`. Other Retail/Classic clients are not certified by this release. Native game restrictions and unavailable APIs still apply.

## File upload fields

| Field | Value |
| --- | --- |
| Upload file | `FlightPathFinder-1.1.3-beta.2.zip` — upload this ZIP alone |
| Display name | Flight Path Finder 1.1.3-beta.2 |
| Release type | Beta |
| Release options | Release after moderation approval, or choose manual scheduling in your account |
| Supported client / version | Forever WoW 1.60.1, Interface 16001. Select its actual supported entry if offered; do not relabel it as another client. Confirm with CurseForge support if this client is not listed. |
| Related projects | None; public WorldNavigation is included. |
| SHA-256 | `c8cc6c14099ffddd25bbb465eb0a2d951fd27ad174b4f8a51cb834dc8ae0e8e9` |
| ZIP root addon folders (2) | `FlightPathFinder`, `WorldNavigation` |

### Changelog — copy/paste

Current route drawing and guidance modules packaged with image-weight navigation. Refreshed documentation removes obsolete private-navigation and route-recording instructions.

Packaging verified direct addon-root layout, manifest-declared files, matching generic/Camelot manifests, ZIP decompression/CRC and SHA-256. No gameplay or test suites were run for this packaging pass. Runtime limits are described above and in bundled READMEs.

## GitHub commit packaging

The repository's `.github/workflows/release.yml` builds an artifact on pushes. In GitHub Settings → Secrets and variables → Actions, set secret `CF_API_TOKEN`, variable `CF_PROJECT_ID`, and variable `CF_GAME_VERSION_IDS` with real supported numeric version IDs. No account tokens are stored in this document. Default-branch commits upload Alpha files when configured; a tag `v1.1.3-beta.2` uploads this Beta version. Generated ZIPs remain local build artifacts; commit source/configuration instead. Do not use duplicate CurseForge webhooks and Actions upload for the same commit.

Remote publication/configuration has not been performed. Missing logo, project ID, real supported-version selection or unpublished source URLs are author/account fields to complete before submitting. Private toolkit/helpers/recorders and private development reports are excluded.

## Official field references

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Submission fields, original logo and project links](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)
- [Upload API](https://support.curseforge.com/support/solutions/articles/9000197321)
