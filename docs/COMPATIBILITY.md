# Compatibility and verification matrix

**Ludava RC2 read: owner-tested live. Ludava RC2 write: implemented, not yet owner-tested live.** The bolt mapping has owner-confirmed read/write research in RatchetHax, and the owner reports a successful Ludava read against RPCS3 on November 5, 2026, using PID `20992` and guest base `0x300000000`. The displayed bolt count and executable fingerprint were not supplied, so this does not complete the formal two-value read-verification gate. The CLI requires the user to select the process, profile, and guest base manually and does not prove the active game identity.

| Game/edition | Identifier | Environment | Capability | Status |
| --- | --- | --- | --- | --- |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / 64-bit Windows | `bolts` read | Implemented; owner reports successful live RC2 read on 2026-11-05; formal two-value verification pending |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / 64-bit Windows | `bolts` write | Implemented with explicit confirmation and read-back; Ludava live write not yet reported |
| Ratchet & Clank 2 — standalone PS3 | `NPUA80644` | RPCS3 / Windows | Read/write bolts | Not supported by this Collection profile |

## RC2 Collection mapping

- Collection title ID: `BCUS98282`; RC2 executable: `RC2.ppu.self`; inner app ID: `NPUA80644`.
- Guest bolt offset: `0x01329E80`; type: unsigned 32-bit; byte order: big-endian.
- Research-session guest base: `0x300000000`; observed host address: `0x301329E80`.
- The guest base may differ between sessions. Check the current RPCS3 log and supply the session's base explicitly.
- The owner-confirmed research recorded ordinary HUD changes from 244012 to 244016 and a targeted write/read-back/HUD change from 243866 to 244866.
- These research observations do not establish that Ludava's independent Dart implementation works with every RPCS3 build or Collection revision.
- No other RC2 field is included or supported. Do not apply the Collection offset to standalone RC2.

## Evidence vocabulary

- **Unverified in Ludava:** Ludava has not reproduced the behavior in a live game session.
- **Research-confirmed:** owner-confirmed external research supports the mapping/operation; this can enable a deliberately selected profile but is not a Ludava compatibility claim.
- **Read verified in Ludava:** exact game/runtime recorded and two distinct live values match Ludava reads.
- **Write verified in Ludava:** read verification is complete, then a full write/read-back and in-game outcome are recorded.
- **Unsupported:** no matching researched profile/field is available, or evidence rules it out.

A process ID, selected profile, successful native API call, automated test, or plausible value does not establish active game identity or Ludava compatibility.

## Evidence still needed for Ludava

- Date, Windows version, RPCS3 version, game identity, and session guest base.
- Two distinct HUD values that match completed Ludava reads.
- A deliberate bolt write with complete byte count, matching read-back, and matching in-game result.
- Relevant failures, limitations, and reproducible steps.

Avoid exposing personal local paths, save data, or incidental private information in public logs.
