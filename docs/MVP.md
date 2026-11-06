# MVP — RC2 bolt trainer

**Current status:** the default Nocterm TUI discovers RPCS3, matches RC1/RC2/RC3 from measured PPU hashes and ordered lifecycle events, and resolves a unique guest base from the selected process session log. Unknown, incomplete, stale, stopped, or ambiguous identity is not allowed to authorize a write. The owner measured the four Collection PPU hashes in RPCS3 `0.0.43-20565-eee3f0f7`; the final compiled CLI automatically matched the RC2 session and base, then displayed a bolt read of `0` (not proof gameplay was active). The owner later confirmed automatic detection and trainer operation across RC1, RC2, and RC3 during Windows laptop and ROG Ally testing. The available notes do not map each game to each device or identify the exact RPCS3 build for that confirmation; compatibility with other builds remains unverified.

## Objective

Read and deliberately modify the bolt value for Ratchet & Clank 2 inside the PS3 Collection (`BCUS98282`) running in RPCS3 on 64-bit Windows.

## First user-visible capability

- Discover one RPCS3 process automatically; allow choosing when multiple instances run, while leaving identity unresolved if their logs cannot be distinguished.
- Match a supported embedded game from the shared title ID, measured PPU hash, and executable name. The Collection menu, stopped game, and unknown hashes do not select an RC profile.
- Resolve the unique current guest base from the selected process session without a normal-user confirmation prompt; do not use `0x300000000` as a constant.
- Read exactly four bytes and decode them as an unsigned big-endian 32-bit value.
- Keep the guest offset `0x01329E80` in the RC2 profile; the observed research-session base was `0x300000000`.
- Allow a TUI write only for the research-confirmed bolt field and a value from 0 through 4294967295 after a deliberate Enter action. Diagnostic writes require `--confirm-write`.
- Require native success and exactly four bytes written, then read back the value. Report write success only when the read-back matches.
- Display the current process, detected profile, base, field values, and meaningful errors. Do not load fields when identity is unresolved.
- Revalidate process session, PPU identity, and base immediately before a write; preserve complete preliminary reads, complete transfer checks, and matching read-back.
- Close process handles after operations. Press **R** to refresh and **G** to re-detect; diagnostic reads can be repeated to refresh too.

Automated tests cover the codec, address mapping, preliminary read-before-write policy, CLI wiring, native errors, partial transfers, read-back, and handle lifecycle through controlled fakes and local test memory. They do not test against RPCS3.

The Windows x64 executable can be built with `tool/build_windows.ps1` and transferred to a ROG Ally without installing Dart or Flutter there. See [WINDOWS_BUILD.md](WINDOWS_BUILD.md).

## Out of scope

Other game fields such as health, inventory, weapons, unlock states, teleportation, repeated/frozen writes, a large Flutter UI, plugins, cloud services, and additional memory backends.

## Validation gates

### Gate A — Ludava live reads

- **Owner-tested:** the session read returned `0` during startup and `110` once gameplay was active, using observed guest base `0x300000000`.
- The PPU hashes and lifecycle were measured in RPCS3 `0.0.43-20565-eee3f0f7`; the exact Windows version and executable fingerprint for the earlier write session were not recorded. The updated Ludava detector has not yet been tested live end-to-end.
- A zero read is a valid value but does not prove gameplay is active.

### Gate B — Ludava live write

- **Owner-tested:** the owner requested `120`; Ludava reported success and displayed `120`, and the owner-provided screenshot showed `120` on the HUD.
- The complete build-verification details for this earlier write session were not supplied. The updated CLI rechecks identity and base before writes; use a test save for future live validation. A read-back alone does not identify the active game/build.
- Record additional runtime/build details and recovery steps if seeking reproducible exact-build compatibility.

The write path is enabled based on the owner's confirmed RatchetHax research. The owner has also validated a live Ludava write in one tested environment; this does not establish compatibility with every RPCS3 version or game build.

### Gate C — minimal Flutter desktop interface

- Show process/profile status, selected field, value, and meaningful errors.
- Preserve the explicit process/profile selection and write/read-back behavior.
- Test the Windows build and real-game scenario.

The MVP is complete only after reproducible exact-build evidence and the minimal desktop interface pass their gates. Partial milestones must state their evidence limits clearly.
