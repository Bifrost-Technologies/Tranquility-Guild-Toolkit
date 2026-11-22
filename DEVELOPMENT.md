# Tranquility Guild Toolkit repository — must read

## Scope and package ownership

Public modular guild toolkit: 12 guild folders plus legacy TranquilityLFG. release.json explicitly excludes Uber, FlightPathFinder, WorldNavigation, LookingForProfession and Tranquility_LFP. Keep standalone splash/download pages with copyable CurseForge links. Do not embed or start those standalone addons from the public dashboard.

Core namespaces/registration, Access/Vault, shared WHO, work/verification/contracts, settings and dashboard live in guild/Tranquility. Optional modules depend on core; disabled modules must not break startup. Consult the per-module DEVELOPMENT.md before changes.

Protected descendants must be detected BEFORE dashboard reparenting. Keep secure panels separate; ordinary pages can navigate/close in combat. Construction of secure Summons waits for an allowed context. A blanket combat UI lock was a confirmed bad design and must not return.

WorkBoard claims/submissions require actual queue acceptance before showing a pending/sent receipt. Authority and verification use native sender identity; a claimed payload owner is not authentication. Validate saved work/security containers. Preserve bounded queues, request IDs, cancellation and explicit user intent. Do not expose private recruitment/combat automation through a public module.

## Validation

Test every optional-module configuration, shared broker ownership, guild/security/vault/defense/work/control suites, queue saturation, malformed settings and protected descendant isolation. Inspect ZIP top-level folders; source-only stale standalone folders must not leak through packaging. Native combat X/Escape, secure summons, mailbox/network and actual API availability remain separate acceptance checks.

Read each affected addon folder's DEVELOPMENT.md and its TOC. release.json is the packaging source of truth. Development documentation belongs in source review even when install ZIPs omit it.

## Development rules

Read this guide and the TOC before editing. Treat declared load order, saved-data structure, public/private boundaries and native API restrictions as contracts. Preserve explicit user settings; validate malformed saved data without wiping unrelated history. Never decode secret values or treat unavailable data as success. Do not register restricted raw combat-log events through pcall. Ordinary dashboards must remain closeable in combat; protected descendants stay in separate windows.

An input send, announcement, queued request or local receipt is not proof of native delivery, acceptance or completion. State claims must match their evidence. Bound peer caches, incoming payloads, work queues and retry loops; retain cancellation/request identity for asynchronous work. Add a regression check for a real failure, not a test that merely repeats the implementation.

Source changes are local until explicitly approved for GitHub/CurseForge publication. Keep install ZIPs manifest-driven, verify contents/CRC/hash and compare both client TOCs. Never package private companions or the whole checkout into a public release. Native gameplay and independent-client validation remain separate from offline simulations.

When learning a failure or changing behavior, update this guide with environment, symptom, evidence, fix, affected symbols/tests and remaining validation. User instructions supersede historical design notes.

## Stable push releases — 2026-11-22 (supersedes tag-only guidance)

Owner requests stable public releases on default-branch pushes. Plain X.Y.Z TOC versions now produce CurseForge release and GitHub non-prerelease/latest downloads on default-branch pushes as well as matching version tags. Explicit beta/alpha versions retain their prerelease channels. Feature branches only build artifacts; existing publication gates remain. Branch ZIP/tag labels retain commit hashes to distinguish pushes. Increment the TOC version for subsequent user-facing updates. Both client TOCs must match. Local edits do not publish/promote old remote files; no push/upload was performed. Moderation, compatible game-version metadata and addon-manager matching still affect update availability. Stable channel classification is not proof that pending native acceptance checks passed.
