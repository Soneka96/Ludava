# Game memory operations

The SDK's `game_memory` feature owns generic address resolution, encoding/decoding, native memory access, complete-transfer checks, preliminary reads, read-back and process-handle cleanup. It does not contain game-specific offsets or RPCS3 detection policy. Per-game offsets, value types, endianness, bounds, and verification statuses are profile data in `game_catalog`; their research evidence belongs under `docs/games/`.

## Read and write contracts

A read uses the resolved current-session base plus the selected profile field's guest offset and decodes the field using its declared representation. A failed/partial read is **not** a valid zero. The frontend should clear stale values on failed refreshes.

A write requires a deliberate user action; matching selected process/session, executable identity and base; writable **profile and field** evidence status; valid type and range; a complete preliminary read; a complete native write; and a matching read-back. The TUI applies deliberate edits on Enter; diagnostic CLI writes require `--confirm-write`. SDK safeguards remain mandatory regardless of how a memory address was researched. See [game detection](game-detection.md) for current identity rules.

A successful native call, plausible read, or matching read-back alone does not prove compatibility with a game build.

## Research and status interpretation

- **Candidate/experimental:** an address found in a trainer, a table or a scan without adequate corroborating live behavior. Record provenance and assumptions; do not imply it is verified or enable writes from an untested address.
- **Research-confirmed:** documented, credible **external live testing** of the matching game/build and field, including source, observed behavior, address derivation, representation and limits. This evidence can qualify for existing guarded writes without repeating the external research in Ludava; it is **not** a claim that Ludava itself was tested.
- **Verified:** corresponding recorded live Ludava read/write results, scoped to the observed game/runtime/build and capability. Do not infer other builds or new features.

The actual `VerificationStatus` enum and SDK policy are authoritative for what is allowed. A profile/field must meet the current identity and session requirements regardless of evidence label. Test the reusable memory engine and codecs generically once; add focused mapping tests when registering a researched game field. Do not create a new memory engine for every game.
