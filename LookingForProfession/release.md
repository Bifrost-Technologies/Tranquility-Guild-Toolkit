# Looking For Profession Finder — release form

Prepared November 20, 2026. Current package **0.1.0-beta.3**. Files are prepared locally; no submission, approval, remote workflow run or live-client certification is claimed.

## Project fields

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Project name | Looking For Profession Finder |
| Proposed slug | lookingforprofession (use the existing project's slug when updating) |
| Summary | Find potential crafters in your guild or selected cities and keep confirmed profession notes. |
| Class | Addons |
| Main / additional categories | Professions; Chat & Communication — select matching labels available in the form |
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

Switch between Guild only and Public cities. Import online guild-roster or manually requested WHO results, filter cities and levels, and keep per-character profession notes after asking the player. The addon does not inspect or scrape another player's professions. Scan your open profession window to index visible recipes and cached item-use levels; item level does not prove crafter level or recipe ownership. Public WHO searches and messages remain player initiated. An optional Tranquility bridge is included; the finder works on its own.

Built for **Forever WoW 1.60.1 / Interface 16001**. Open `/lfp`. Other Retail/Classic clients are not certified by this release. Native game restrictions and unavailable APIs still apply.

## File upload fields

| Field | Value |
| --- | --- |
| Upload file | `LookingForProfession-0.1.0-beta.3.zip` — upload this ZIP alone |
| Display name | Looking For Profession Finder 0.1.0-beta.3 |
| Release type | Beta |
| Release options | Release after moderation approval, or choose manual scheduling in your account |
| Supported client / version | Forever WoW 1.60.1, Interface 16001. Select its actual supported entry if offered; do not relabel it as another client. Confirm with CurseForge support if this client is not listed. |
| Related projects | None for the finder. Bundled Tranquility_LFP bridge additionally requires Tranquility; leave that bridge disabled without the guild toolkit. |
| SHA-256 | `6ea3ac9c224d5bdd09b2ae062b9b36eb75df416840bb687fd1a035ce35fbc9dc` |
| ZIP root addon folders (2) | `LookingForProfession`, `Tranquility_LFP` |

### Changelog — copy/paste

Current guild/public-city search and recipe-index source packaged. Optional guild bridge retained; no private Titans bridge included.

Packaging verified direct addon-root layout, manifest-declared files, matching generic/Camelot manifests, ZIP decompression/CRC and SHA-256. No gameplay or test suites were run for this packaging pass. Runtime limits are described above and in bundled READMEs.

## GitHub commit packaging

The repository's `.github/workflows/release.yml` builds an artifact on pushes. In GitHub Settings → Secrets and variables → Actions, set secret `CF_API_TOKEN`, variable `CF_PROJECT_ID`, and variable `CF_GAME_VERSION_IDS` with real supported numeric version IDs. No account tokens are stored in this document. Default-branch commits upload Alpha files when configured; a tag `v0.1.0-beta.3` uploads this Beta version. Generated ZIPs remain local build artifacts; commit source/configuration instead. Do not use duplicate CurseForge webhooks and Actions upload for the same commit.

Remote publication/configuration has not been performed. Missing logo, project ID, real supported-version selection or unpublished source URLs are author/account fields to complete before submitting. Private toolkit/helpers/recorders and private development reports are excluded.

## Official field references

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Submission fields, original logo and project links](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)
- [Upload API](https://support.curseforge.com/support/solutions/articles/9000197321)
