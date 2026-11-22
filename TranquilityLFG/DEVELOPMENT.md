# Legacy Tranquility LFG — development must read

Updated 2026-11-21. This is an engineering handoff, not proof of native acceptance.

Guild-only legacy planner, prefix TQLFG1. LFG.lua owns entries/queues and native guild sender identity; Profiles/Builder/Mirror/Interface have separate state and export/UI responsibilities. Preserve owner authority, input bounds, stale-entry expiry, opt-outs/manual native actions and optional dependency startup.

This addon is not WoW's native LFG queue browser and must not claim all active server groups. EnhancedLFG is a separate new native-window companion. Do not rename this folder, SavedVariables, prefix or published project to Enhanced LFG without a deliberate migration/release decision. The guild toolkit still bundles this legacy addon; new EnhancedLFG sends no competing listing announcements.

Tests: lfg and lfg-advanced plus guild configuration tests. Native guild transport, party formation, manual invites and coexistence remain game acceptance checks.

## Manifest snapshot (2026-11-21)

Primary: TranquilityLFG.toc; compare TranquilityLFG_Camelot.toc. Header values and file lists below are a source snapshot; the current TOC wins after a later change.

```text
## Interface: 16001
## Dependencies: Tranquility
## Version: 0.3.0-beta.2
## SavedVariables: TranquilityLFGDB
```

Runtime load order:

- Access.lua
- Vault.lua
- LFG.lua
- Profiles.lua
- Builder.lua
- Mirror.lua
- Interface.lua

## Development rules

Read this guide and the TOC before editing. Treat declared load order, saved-data structure, public/private boundaries and native API restrictions as contracts. Preserve explicit user settings; validate malformed saved data without wiping unrelated history. Never decode secret values or treat unavailable data as success. Do not register restricted raw combat-log events through pcall. Ordinary dashboards must remain closeable in combat; protected descendants stay in separate windows.

An input send, announcement, queued request or local receipt is not proof of native delivery, acceptance or completion. State claims must match their evidence. Bound peer caches, incoming payloads, work queues and retry loops; retain cancellation/request identity for asynchronous work. Add a regression check for a real failure, not a test that merely repeats the implementation.

Source changes are local until explicitly approved for GitHub/CurseForge publication. Keep install ZIPs manifest-driven, verify contents/CRC/hash and compare both client TOCs. Never package private companions or the whole checkout into a public release. Native gameplay and independent-client validation remain separate from offline simulations.

When learning a failure or changing behavior, update this guide with environment, symptom, evidence, fix, affected symbols/tests and remaining validation. User instructions supersede historical design notes.

## Stable push releases — 2026-11-22 (supersedes tag-only guidance)

Owner requests stable public releases on default-branch pushes. Plain X.Y.Z TOC versions now produce CurseForge release and GitHub non-prerelease/latest downloads on default-branch pushes as well as matching version tags. Explicit beta/alpha versions retain their prerelease channels. Feature branches only build artifacts; existing publication gates remain. Branch ZIP/tag labels retain commit hashes to distinguish pushes. Increment the TOC version for subsequent user-facing updates. Both client TOCs must match. Local edits do not publish/promote old remote files; no push/upload was performed. Moderation, compatible game-version metadata and addon-manager matching still affect update availability. Stable channel classification is not proof that pending native acceptance checks passed.
