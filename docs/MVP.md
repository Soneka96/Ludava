# MVP — RC2 bolt trainer

**Current status:** the profile-driven Windows CLI can read and write RC2 Collection bolts using owner-confirmed research. Ludava has not yet been tested against a live RPCS3 session, and it does not identify the active game/build automatically.

## Objective

Read and deliberately modify the bolt value for Ratchet & Clank 2 inside the PS3 Collection (`BCUS98282`) running in RPCS3 on 64-bit Windows.

## First user-visible capability

- Select the intended RPCS3 process, `rc2-collection` profile, and session guest memory base explicitly.
- Read exactly four bytes and decode them as an unsigned big-endian 32-bit value.
- Keep the guest offset `0x01329E80` in the RC2 profile; the observed research-session base was `0x300000000`.
- Allow a write only for the research-confirmed bolt field, a value from 0 through 4294967295, and an explicit `--confirm-write` request.
- Require native success and exactly four bytes written, then read back the value. Report write success only when the read-back matches.
- Display that process/profile/base selection is manual and that Ludava has not validated the live game session.
- Close the process handle at the end of each CLI command. Run `read` again to refresh the value.

Automated tests cover the codec, address mapping, domain write flow, CLI wiring, native errors, partial transfers, read-back, and handle lifecycle through controlled fakes and local test memory. They do not test against RPCS3.

## Out of scope

Other game fields such as health, inventory, weapons, unlock states, teleportation, repeated/frozen writes, a large Flutter UI, plugins, cloud services, and additional memory backends.

## Validation gates

### Gate A — Ludava live reads

- Record the exact game setup, RPCS3 version, and session base.
- Match two distinct normal in-game bolt values against Ludava reads.

### Gate B — Ludava live write

- Use a suitable test save and record the current bolt value.
- Make one deliberate write, confirm full transfer and matching read-back, and confirm the in-game value.
- Record the result and recovery steps in `COMPATIBILITY.md`.

The write path is enabled based on the owner's confirmed RatchetHax research. These Ludava live checks are still required before claiming Ludava runtime compatibility.

### Gate C — minimal Flutter desktop interface

- Show process/profile status, selected field, value, and meaningful errors.
- Preserve the explicit process/profile selection and write/read-back behavior.
- Test the Windows build and real-game scenario.

The MVP is complete only after live RC2 validation and the minimal desktop interface pass their gates. Partial milestones must state their evidence limits clearly.
