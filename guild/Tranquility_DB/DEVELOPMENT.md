# Tranquility_DB — development must read

Updated 2026-11-21. This is an engineering handoff, not proof of native acceptance.

Static optional Classic reference routes and drop hints. Database.lua data are not realm-certified loot tables or navigation coverage. Keep native observations separate from reference entries and label uncertain sources. No SavedVariables or automatic scans should be invented for this data-only module. Validate schema and consumers when changing IDs/coordinates.

## Manifest snapshot (2026-11-21)

Primary: Tranquility_DB.toc; compare Tranquility_DB_Camelot.toc. Header values and file lists below are a source snapshot; the current TOC wins after a later change.

```text
## Interface: 16001
## Version: 1.0.0-beta.15
## Dependencies: Tranquility
```

Runtime load order:

- Database.lua

## Development rules

Read this guide and the TOC before editing. Treat declared load order, saved-data structure, public/private boundaries and native API restrictions as contracts. Preserve explicit user settings; validate malformed saved data without wiping unrelated history. Never decode secret values or treat unavailable data as success. Do not register restricted raw combat-log events through pcall. Ordinary dashboards must remain closeable in combat; protected descendants stay in separate windows.

An input send, announcement, queued request or local receipt is not proof of native delivery, acceptance or completion. State claims must match their evidence. Bound peer caches, incoming payloads, work queues and retry loops; retain cancellation/request identity for asynchronous work. Add a regression check for a real failure, not a test that merely repeats the implementation.

Source changes are local until explicitly approved for GitHub/CurseForge publication. Keep install ZIPs manifest-driven, verify contents/CRC/hash and compare both client TOCs. Never package private companions or the whole checkout into a public release. Native gameplay and independent-client validation remain separate from offline simulations.

When learning a failure or changing behavior, update this guide with environment, symptom, evidence, fix, affected symbols/tests and remaining validation. User instructions supersede historical design notes.

## Stable push releases — 2026-11-22 (supersedes tag-only guidance)

Owner requests stable public releases on default-branch pushes. Plain X.Y.Z TOC versions now produce CurseForge release and GitHub non-prerelease/latest downloads on default-branch pushes as well as matching version tags. Explicit beta/alpha versions retain their prerelease channels. Feature branches only build artifacts; existing publication gates remain. Branch ZIP/tag labels retain commit hashes to distinguish pushes. Increment the TOC version for subsequent user-facing updates. Both client TOCs must match. Local edits do not publish/promote old remote files; no push/upload was performed. Moderation, compatible game-version metadata and addon-manager matching still affect update availability. Stable channel classification is not proof that pending native acceptance checks passed.
