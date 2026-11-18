# Tranquility release how-to

Current prepared toolkit: **1.0.0-beta.4**. Bundled TranquilityLFG: **0.2.0-beta.1**. Bundled optional Uber: **0.4.0-beta.1**. The author is waiting for Uber's separate review outcome before publishing the combined toolkit.

1. For a toolkit version change, update both TOCs in all eleven `guild/Tranquility*` folders and `guild/Tranquility/Core.lua`. Keep generic/Camelot files matched. Companion versions remain independently managed.
2. Update `guild/Tranquility/CHANGELOG.md`, the root changelog, player guides and `curseforge/` author materials. Keep `curseforge/CHANGELOG.md` synchronized too.
3. If updating bundled Uber, bring its reviewed runtime files/license/changelog from the separate Uber repository deliberately. Validate the exact version you intend to distribute; another file's approval is not automatic approval for this bundle.
4. Run `Build.ps1`. Review toolkit/module and LFG PASS results, source/manifest audits, installable-root counts and per-file hashes. Run standalone companion builds if those sources changed.
5. Complete affected live checks in `curseforge/LIVE-TEST.md`. Test native invitation permissions, rank availability, role/loot/carry filters, queue/discovery distinctions, optional Discord handoff and addon coexistence. Never include actual account data or bot credentials as fixtures.
6. In GitHub Desktop, inspect the source diff, commit and push. Do not commit generated ZIPs or author handoff copies.
7. Create a GitHub Release for that reviewed commit/tag. Attach `share/Tranquility/Tranquility-Guild-Toolkit-<version>.zip` and checksum. The install archive contains 13 direct addon roots. Do not install the repository/source archive as one addon.
8. Use `submission/Tranquility/START-HERE.md` and the generated author folder for CurseForge forms. Upload the named ZIP alone to the existing project, selecting only the supported tested game flavor and appropriate Beta/Release type.

The optional Discord bot is not part of this public repository/package. Its owner-managed setup is documented, but no credentials or automatic deployment are supplied. No GitHub push, tag, release or CurseForge upload is performed by these scripts.
