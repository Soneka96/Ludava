# MVP — RC2 bolt trainer

**Current status:** the interactive Windows CLI discovers RPCS3 processes, offers fresh log-derived or manual memory-base choices, and reads or writes RC2 Collection bolts using owner-confirmed research. On November 5, 2026, the owner successfully read bolts in a live session (observing `0` during startup and `110` in gameplay) and wrote `120`, which Ludava displayed and the owner screenshot showed on the HUD. Exact Windows/RPCS3 versions and executable fingerprint were not supplied, so compatibility across builds is not established. Process discovery and log matching do not identify the active game/build.

## Objective

Read and deliberately modify the bolt value for Ratchet & Clank 2 inside the PS3 Collection (`BCUS98282`) running in RPCS3 on 64-bit Windows.

## First user-visible capability

- Select the intended RPCS3 process when multiple instances exist, choose the `rc2-collection` profile, and explicitly confirm a candidate or manual session guest memory base.
- Read exactly four bytes and decode them as an unsigned big-endian 32-bit value.
- Keep the guest offset `0x01329E80` in the RC2 profile; the observed research-session base was `0x300000000`.
- Allow a write only for the research-confirmed bolt field, a value from 0 through 4294967295, and an explicit `--confirm-write` request.
- Require native success and exactly four bytes written, then read back the value. Report write success only when the read-back matches.
- Display the selected process/profile/base and explain that Ludava cannot identify the active game/build.
- Close process handles after operations. The interactive refresh action runs a new read; the diagnostic CLI can be repeated to refresh too.

Automated tests cover the codec, address mapping, preliminary read-before-write policy, CLI wiring, native errors, partial transfers, read-back, and handle lifecycle through controlled fakes and local test memory. They do not test against RPCS3.

The Windows x64 executable can be built with `tool/build_windows.ps1` and transferred to a ROG Ally without installing Dart or Flutter there. See [WINDOWS_BUILD.md](WINDOWS_BUILD.md).

## Out of scope

Other game fields such as health, inventory, weapons, unlock states, teleportation, repeated/frozen writes, a large Flutter UI, plugins, cloud services, and additional memory backends.

## Validation gates

### Gate A — Ludava live reads

- **Owner-tested:** the session read returned `0` during startup and `110` once gameplay was active, using observed guest base `0x300000000`.
- Exact Windows/RPCS3 versions and executable fingerprint were not supplied. Capture those details before making an exact-build or cross-build compatibility claim.
- A zero read is a valid value but does not prove gameplay is active.

### Gate B — Ludava live write

- **Owner-tested:** the owner requested `120`; Ludava reported success and displayed `120`, and the owner-provided screenshot showed `120` on the HUD.
- The complete build-verification details were not supplied. Verify the current session base and use a test save before future writes; a read-back alone does not identify the active game/build.
- Record additional runtime/build details and recovery steps if seeking reproducible exact-build compatibility.

The write path is enabled based on the owner's confirmed RatchetHax research. The owner has also validated a live Ludava write in one tested environment; this does not establish compatibility with every RPCS3 version or game build.

### Gate C — minimal Flutter desktop interface

- Show process/profile status, selected field, value, and meaningful errors.
- Preserve the explicit process/profile selection and write/read-back behavior.
- Test the Windows build and real-game scenario.

The MVP is complete only after reproducible exact-build evidence and the minimal desktop interface pass their gates. Partial milestones must state their evidence limits clearly.
