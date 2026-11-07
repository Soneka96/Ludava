# Roadmap

Milestones describe verified outcomes, not completed code alone. The sequence below follows project dependencies from the evidence foundation through the future frontend. Historical evidence and each milestone's completion state are preserved.

## Current workspace status

The owner-approved Dart workspace contains `packages/ludava_sdk` and `apps/ludava_tui`. The SDK exposes the lifecycle-owned `LudavaSdk` runtime; the TUI consumes its public capabilities. The legacy interactive text menu is removed, while Nocterm and explicit diagnostic commands remain. `apps/ludava_app` is a future Flutter application and is not part of the current workspace. See [ARCHITECTURE.md](ARCHITECTURE.md) for the actual directory structure and ownership.

The final focused SDK cleanup gives `game_memory` ownership of shared field execution, keeps detection execution in `game_detection`, and makes disposal terminal across retained SDK capabilities. The TUI awaits SDK cleanup on every command path. Local checks are recorded for the current checkout; GitHub Actions and real Windows acceptance remain separate PR #7 merge gates. Keep PR #7 as a draft until both gates pass. Existing live-game observations and their compatibility limits are documented in [COMPATIBILITY.md](COMPATIBILITY.md); the structural cleanup does not change those claims.

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

## M3 — Incremental game and field expansion

- [x] Add RC1 and RC3 Collection bolt-only profiles from owner-confirmed RatchetHax research.
- [x] Owner-tested RC1 and RC3 Ludava bolt reads and writes with matching in-game HUD screenshots on 2026-11-05, using session base `0x300000000`; their PPU hashes were later measured in a separate runtime session.
- [x] Reuse the generic reader/writer instead of creating duplicate game features.
- [ ] Reevaluate architecture only when a new capability creates a real boundary.

**Not planned now:** a large dashboard, plugin framework, cloud services, additional emulator backends, or unverified feature tables.

## M4 — RPCS3 game detection

- [x] Add domain detection outcomes, confidence, evidence, and profile-driven field exposure.
- [x] Preserve RPCS3 log title/serial/path observations without treating history as active identity.
- [x] Add explicit CLI re-detection, manual fallback labeling, and field-state invalidation.
- [x] Measure Collection EBOOT and RC1/RC2/RC3 PPU hashes, game transitions, stop events, and a fresh process restart in RPCS3 `0.0.43-20565-eee3f0f7`.
- [x] Add measured RC1/RC2/RC3 PPU hashes to profile matching and parse ordered current-session lifecycle events.
- [x] Resolve a unique fresh guest base after identity and revalidate process, profile, hash, and base before writes.
- [ ] Capture a live unsupported-game case and simultaneous RPCS3 instances; these remain unresolved by default.
- [x] Owner later confirmed automatic detection and trainer operation across RC1, RC2, and RC3 during testing on a Windows laptop and a ROG Ally. The available notes do not map each game to each device or identify the exact RPCS3 build.

**Current limit:** executable hashes were measured in one RPCS3 build and the log lifecycle was observed in one-process sessions. The final compiled CLI was live-smoke-tested with RC2; the later owner confirmation covers all three embedded games, but does not include a per-device game matrix or exact runtime build. Other RPCS3 builds, unsupported titles, and concurrent processes that share logs remain unverified. See [game-detection investigation](GAME_DETECTION.md).

## M5 — SDK and TUI workspace extraction

- [x] Document the approved ownership and runtime conventions before implementation.
- [x] Establish `packages/ludava_sdk` as the reusable engine and `apps/ludava_tui` as its Nocterm/diagnostic frontend.
- [x] Move diagnostic application workflows into the trainer feature and add the lifecycle-owned `LudavaSdk` runtime.
- [x] Make the TUI consume public SDK capabilities and remove the legacy text-based interactive menu.
- [x] Move shared process-memory handle management and field execution into `game_memory`; keep trainer and diagnostic authorization policies in their owning services.
- [x] Assemble the feature-owned detection workflow in the SDK runtime without executing detection there.
- [x] Reject operations through retained session and diagnostic capabilities once disposal starts, and await TUI cleanup.
- [x] Keep root commands as thin compatibility entry points; add workspace boundary checks and fixture tests.
- [x] Verify local package analysis and tests, root compatibility tests, workspace boundaries, Windows build, and relocated executable help in the current checkout.
- [ ] Confirm GitHub Actions on PR #7; it must run SDK, TUI, root compatibility, boundary, formatting, Windows build, and relocated native-discovery checks.
- [ ] Record real Windows acceptance, including physical keyboard behavior and live RPCS3 checks for RC1, RC2, and RC3.

**Exit:** local workspace checks pass, GitHub Actions passes, and real Windows acceptance is recorded. Do not merge PR #7 while either remote CI or required Windows acceptance remains unverified.

## M6 — Minimal Flutter desktop interface

- [ ] Show process/build status, selected field, value, and meaningful errors.
- [ ] Enable edits only for a verified writable build and field.
- [ ] Test the Windows build and the real-game scenario.

**Exit:** a usable first release with accurate compatibility status.

## M7 — Ratchet: Deadlocked standalone PS3 (research stage)

The `deadlocked-ps3` catalog profile records one observed `NPUA80646` RPCS3 identity and two distinct Ludava Bolts reads (`1,785`, `4,903`) that matched owner-provided HUD screenshots in the same session. An owner-authorized write/read-back test from `6,278` to `6,279` also matched a post-write HUD screenshot. Read and write verification apply to this build/session only.

- [x] Inspect the RatchetHax address reference and derive candidate guest offset `0x009C32E8`.
- [x] Observe one RPCS3 session's context and identity: build `0.0.43-20567-6a59542f`, game version `01.00/01.01`, title ID `NPUA80646`, executable `EBOOT.BIN`, and PPU hash `PPU-c44d700265e50dfe49054c1703f8fea668cc33b9`. Automatic matching uses only title ID, executable, and PPU hash.
- [x] Run the SDK (404), TUI (185), and root compatibility (5) test suites, analysis for all three packages, changed-file formatting, and workspace boundary checks.
- [x] Pass GitHub Actions Windows x64 verification (run 16), including the project Windows build, all suites, and packaged help; a rerun for the final write-status promotion is pending.
- [ ] Run `tool/build_windows.ps1` locally; LLVM Clang is unavailable. A manually compiled Windows AOT executable and native discovery shim passed help and discovery checks.
- [x] Match two distinct live Bolts values with Ludava reads in the same identified session.
- [ ] Verify automatic Nocterm trainer detection and process/session restart behavior live.
- [x] Obtain explicit owner approval and complete one guarded write/read-back validation (`6,278` → `6,279`).
- [x] Confirm the post-write Bolts HUD value (`6,279`) for the owner-authorized validation write.

See [COMPATIBILITY.md](COMPATIBILITY.md) and [DEADLOCKED_PS3_RESEARCH.md](DEADLOCKED_PS3_RESEARCH.md). No support claim is made for other game versions, regions, RPCS3 builds, or devices.
