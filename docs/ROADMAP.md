# Roadmap

Milestones describe verified outcomes, not completed code alone.

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
- [ ] Identify the exact active game/build and RPCS3 version; a PID and selected profile do not prove identity.
- [ ] Match two distinct real in-game values against successful Ludava reads.

**Exit:** repeatable read evidence for one exact build, recorded with enough detail to reproduce it.

## M2 — One guarded edit

- [x] Implement the write use case with profile/field status, explicit confirmation, value bounds, complete transfer, and read-back checks.
- [x] Enable RC2 bolt writes from the explicitly selected research-confirmed profile; report that Ludava does not identify the active build.
- [ ] Validate Ludava reads against two live in-game bolt counts and record the exact RPCS3 session.
- [x] Owner-tested a deliberate live edit on 2026-11-05: requested `120`, Ludava displayed `120`, and the owner screenshot showed `120` on the HUD.
- [ ] Record exact runtime/build details and recovery steps before making an exact-build compatibility claim.

**Current limit:** The owner tested live RC2 reading and writing on November 5, 2026. The startup read returned `0` and gameplay read returned `110`; the write to `120` appeared in Ludava and on the game's HUD screenshot. Exact Windows/RPCS3 versions and executable fingerprint were not supplied. The user still selects the process, profile, and session base, and cross-build compatibility is not established.

**Exit:** one Ludava edit is validated end to end, with its runtime assumptions documented and unknown fields still disabled.

## M3 — Minimal Flutter desktop interface

- [ ] Show process/build status, selected field, value, and meaningful errors.
- [ ] Enable edits only for a verified writable build and field.
- [ ] Test the Windows build and the real-game scenario.

**Exit:** a usable first release with accurate compatibility status.

## M4 — Incremental expansion

- [x] Add RC1 and RC3 Collection bolt-only profiles from owner-confirmed RatchetHax research.
- [x] Owner-tested RC1 and RC3 Ludava bolt reads and writes with matching in-game HUD screenshots on 2026-11-05, using session base `0x300000000` (exact executable fingerprints still pending).
- [ ] Reuse the generic reader/writer instead of creating duplicate game features.
- [ ] Reevaluate architecture only when a new capability creates a real boundary.

**Not planned now:** a large dashboard, plugin framework, cloud services, additional emulator backends, or unverified feature tables.

## M5 — RPCS3 game-detection foundation

- [x] Add domain detection outcomes, confidence, evidence, and profile-driven field exposure.
- [x] Preserve RPCS3 log title/serial/path observations without treating history as active identity.
- [x] Add explicit CLI re-detection, manual fallback labeling, and field-state invalidation.
- [ ] Capture process-specific RPCS3 runtime evidence for no-game, RC1, RC2, RC3, game exit/switch, restart, unsupported titles, and multiple instances.
- [ ] Add exact current-session identity keys for profiles only after those keys are established.
- [ ] Reproduce live detection on RPCS3 before claiming automatic Collection subgame selection.

**Current limit:** the built-in log reader does not confidently identify an active Collection subgame. The shared `BCUS98282` title ID remains ambiguous; RC1/RC3 executable identities are not established. The CLI uses manual selection for current built-in evidence and never infers a game from a bolt value or save namespace. See [game-detection investigation](GAME_DETECTION.md).
