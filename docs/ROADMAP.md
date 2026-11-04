# Roadmap

Milestones describe verified outcomes, not completed code alone.

## M0 — Project and documentation foundation

- [x] Choose project name: Ludava.
- [x] Initialize the repository with project scope, architecture, and safety documentation.
- [x] State proprietary ownership and the no-external-contributions policy.
- [ ] Decide whether to change the currently public repository visibility before implementation or distribution.
- [x] Review RatchetHax PR #1 and record its validation limits.

**Exit:** evidence-backed scope for one read-only field in one investigated game build.

## M1 — Profile-driven read foundation

- [x] Define a generic `game_memory` feature with game/build profiles and named fields.
- [x] Implement shared read, address-resolution, decoding, and Windows process-memory layers.
- [x] Add profile-selecting CLI reads and deterministic fake-based tests.
- [ ] Identify the exact active game/build and RPCS3 version; a PID and selected profile do not prove identity.
- [ ] Match two distinct real in-game values against successful Ludava reads.

**Exit:** repeatable read evidence for one exact build, recorded with enough detail to reproduce it.

## M2 — One guarded edit

- [x] Implement a write use case that checks profile and field status, active-build verification, confirmation, value bounds, complete transfer, and read-back.
- [ ] Implement active-game/build identification from reliable process/game evidence.
- [ ] Verify the exact build and field for writing, then enable the CLI write path.
- [ ] Verify one deliberate edit in-game with a backed-up save and document recovery steps.

**Current limit:** the CLI rejects every write request because active-build identification is not implemented.

**Exit:** one edit is validated end to end without enabling unknown or unverified fields.

## M3 — Minimal Flutter desktop interface

- [ ] Show process/build status, selected field, value, and meaningful errors.
- [ ] Enable edits only for a verified writable build and field.
- [ ] Test the Windows build and the real-game scenario.

**Exit:** a usable first release with accurate compatibility status.

## M4 — Incremental expansion

- [ ] Add each game/build as profile data after its mapping and evidence are recorded.
- [ ] Reuse the generic reader/writer instead of creating duplicate game features.
- [ ] Reevaluate architecture only when a new capability creates a real boundary.

**Not planned now:** a large dashboard, plugin framework, cloud services, additional emulator backends, or unverified feature tables.
