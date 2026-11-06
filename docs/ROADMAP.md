# Roadmap

Milestones describe verified outcomes, not completed code alone.

## Long-term workspace decision

The owner has chosen one Dart workspace in this Git repository with three separately organized projects: `packages/ludava_sdk`, `apps/ludava_tui`, and `apps/ludava_app`. The SDK will hold the reusable trainer engine; the Nocterm TUI and Flutter desktop app will be independent frontends over that SDK. See [ARCHITECTURE.md](ARCHITECTURE.md) for ownership and dependency boundaries.

This decision does not authorize migrating the current repository as part of PR #6. Keep the present layout until a dedicated migration is planned and verified.

## M0 — Project and documentation foundation

- [x] Choose project name: Ludava.
- [x] Initialize the repository with project scope, architecture, and safety documentation.
- [x] State proprietary ownership and the no-external-contributions policy.
- [ ] Decide whether to change the currently public repository visibility before implementation or distribution.
- [x] Review merged RatchetHax PR #1 and record its owner-confirmed RC2 bolt findings and limits.

**Exit:** evidence-backed scope for one read-only field in one investigated game build.

## M1 — Profile-driven read foundation

- [x] Define a generic `game_memory` feature with game/build profiles and named fields.
- [x] Implement shared read, address-resolution, decoding, and Windows process-memory layers.
- [x] Add profile-selecting CLI reads and deterministic fake-based tests.
- [x] Measure the active Collection PPU identity hashes on RPCS3 `0.0.43-20565-eee3f0f7`; broader build compatibility remains unknown.
- [ ] Match two distinct real in-game values against successful Ludava reads.

**Exit:** repeatable read evidence for one exact build, recorded with enough detail to reproduce it.

## M2 — One guarded edit

- [x] Implement the write use case with profile/field status, explicit confirmation, value bounds, complete transfer, and read-back checks.
- [x] Enable RC2 bolt writes from the explicitly selected research-confirmed profile; report that Ludava does not identify the active build.
- [ ] Validate Ludava reads against two live in-game bolt counts and record the exact RPCS3 session.
- [x] Owner-tested a deliberate live edit on 2026-11-05: requested `120`, Ludava displayed `120`, and the owner screenshot showed `120` on the HUD.
- [ ] Record exact runtime/build details and recovery steps before making an exact-build compatibility claim.

**Validation record:** The owner tested live RC2 reading and writing on November 5, 2026. The startup read returned `0` and gameplay read returned `110`; the write to `120` appeared in Ludava and on the game's HUD screenshot. Exact runtime details for that write session were not supplied. The later PPU hash experiment measures identity on RPCS3 `0.0.43-20565-eee3f0f7`; broader compatibility remains unverified.

**Exit:** one Ludava edit is validated end to end, with its runtime assumptions documented and unknown fields still disabled.

## M3 — Minimal Flutter desktop interface

- [ ] Show process/build status, selected field, value, and meaningful errors.
- [ ] Enable edits only for a verified writable build and field.
- [ ] Test the Windows build and the real-game scenario.

**Exit:** a usable first release with accurate compatibility status.

## M4 — Incremental expansion

- [x] Add RC1 and RC3 Collection bolt-only profiles from owner-confirmed RatchetHax research.
- [x] Owner-tested RC1 and RC3 Ludava bolt reads and writes with matching in-game HUD screenshots on 2026-11-05, using session base `0x300000000`; their PPU hashes were later measured in a separate runtime session.
- [ ] Reuse the generic reader/writer instead of creating duplicate game features.
- [ ] Reevaluate architecture only when a new capability creates a real boundary.

**Not planned now:** a large dashboard, plugin framework, cloud services, additional emulator backends, or unverified feature tables.

## M5 — RPCS3 game detection

- [x] Add domain detection outcomes, confidence, evidence, and profile-driven field exposure.
- [x] Preserve RPCS3 log title/serial/path observations without treating history as active identity.
- [x] Add explicit CLI re-detection, manual fallback labeling, and field-state invalidation.
- [x] Measure Collection EBOOT and RC1/RC2/RC3 PPU hashes, game transitions, stop events, and a fresh process restart in RPCS3 `0.0.43-20565-eee3f0f7`.
- [x] Add measured RC1/RC2/RC3 PPU hashes to profile matching and parse ordered current-session lifecycle events.
- [x] Resolve a unique fresh guest base after identity and revalidate process, profile, hash, and base before writes.
- [ ] Capture a live unsupported-game case and simultaneous RPCS3 instances; these remain unresolved by default.
- [x] Owner later confirmed automatic detection and trainer operation across RC1, RC2, and RC3 during testing on a Windows laptop and a ROG Ally. The available notes do not map each game to each device or identify the exact RPCS3 build.

**Current limit:** executable hashes were measured in one RPCS3 build and the log lifecycle was observed in one-process sessions. The final compiled CLI was live-smoke-tested with RC2; the later owner confirmation covers all three embedded games, but does not include a per-device game matrix or exact runtime build. Other RPCS3 builds, unsupported titles, and concurrent processes that share logs remain unverified. See [game-detection investigation](GAME_DETECTION.md).
