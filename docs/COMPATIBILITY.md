# Compatibility and verification matrix

**Ludava RC2 reading and writing were tested successfully by the owner in a live RPCS3 session on November 5, 2026.** With the game closed, the initial read failed. During game startup, a later read returned `0`; once gameplay was active, a read returned `110`. The owner requested a write to `120`; Ludava reported success and displayed `120`, and the owner-provided screenshot showed `120` on the game's HUD. A valid `0` read does not by itself prove gameplay is active.

The observed guest memory base was `0x300000000`. The exact Windows and RPCS3 versions, executable fingerprint, and complete build-verification details were not supplied. This evidence records successful live RC2 read/write behavior in the owner's tested environment; compatibility across RPCS3 versions or game builds is not established. Ludava discovers RPCS3 processes, but the user selects the profile and confirms a log candidate or manual memory base. Process discovery and log matching do not identify the active game/build.

| Game/edition | Identifier | Environment | Capability | Status |
| --- | --- | --- | --- | --- |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / Windows | `bolts` read | Owner-tested live on 2026-11-05; observed `0` during startup and `110` in gameplay; exact runtime/build details unavailable |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / Windows | `bolts` write | Owner-tested live on 2026-11-05; requested `120`, Ludava displayed `120`, and the owner screenshot showed `120` on the HUD; cross-build compatibility not established |
| Ratchet & Clank 2 — standalone PS3 | `NPUA80644` | RPCS3 / Windows | Read/write bolts | Not supported by this Collection profile |
| Ratchet & Clank 1 — PS3 Collection | `BCUS98282`, observed save namespace `NPUA80643` | RPCS3 / Windows | `bolts` read/write | Owner-tested live on 2026-11-05: gameplay read `22`, requested write `12,312`, Ludava read-back and owner screenshot HUD showed `12,312` |
| Ratchet & Clank 3 — PS3 Collection | `BCUS98282`, observed save namespace `NPUA80645` | RPCS3 / Windows | `bolts` read/write | Owner-tested live on 2026-11-05: gameplay read `248`, requested write `1,312,312`, Ludava read-back and owner screenshot HUD showed `1,312,312` |

## Live RC1 and RC3 verification (2026-11-05)

The owner tested both new Ludava profiles in RPCS3 and supplied terminal output and gameplay screenshots. The screenshots display RPCS3 `0.0.43-20565` and the Collection title ID `BCUS98282`. The selected process ID was `20992` and the session memory base was `0x300000000` in the terminal report. Exact game executable fingerprints, complete RPCS3 build identifier and Windows version remain unrecorded.

- **RC1:** Ludava read `22` bolts in the running game. The owner set `12,312`; Ludava reported matching read-back and the HUD screenshot displayed `12312`.
- **RC3:** Ludava read `248` bolts. The owner set `1,312,312`; Ludava reported matching read-back and the HUD screenshot displayed `1312312`. A separate `+20` game reward appeared in the HUD; whether that bonus had already been reflected in the displayed balance was not independently established.
- The owner ran `dart pub get` successfully, `dart analyze` with no issues and `dart test` with **254 tests passed**. The compiled Windows EXE was not demonstrated for this branch.
- These are successful live read/write observations for the owner's configuration, not proof of general cross-build compatibility or automatic identification of the active embedded game.

## RC2 Collection mapping

- Collection title ID: `BCUS98282`; RC2 executable: `RC2.ppu.self`; inner app ID: `NPUA80644`.
- Guest bolt offset: `0x01329E80`; type: unsigned 32-bit; byte order: big-endian.
- Research-session guest base: `0x300000000`; observed host address: `0x301329E80`.
- The guest base may differ between sessions. Ludava checks fresh logs beside the selected executable for a candidate and asks the user to confirm it. A stale log is ignored; a missing or ambiguous value leads to the research-tested suggestion or manual entry. The selected candidate is not proof that the log belongs to that process.
- The owner-confirmed research recorded ordinary HUD changes from 244012 to 244016 and a targeted write/read-back/HUD change from 243866 to 244866.
- These research observations do not establish that Ludava's independent Dart implementation works with every RPCS3 build or Collection revision.
- No other RC2 field is included or supported. Do not apply the Collection offset to standalone RC2.
- Ratchet & Clank 1: bolt guest offset `0x009BC3A0` (`0x3009BC3A0` with observed research base `0x300000000`). RatchetHax tracked HUD `5155 → 5105 → 5055` and confirmed a write to `105055` on the HUD; Ludava live RC1 write to `12,312` was confirmed on the HUD on 2026-11-05.
- Ratchet & Clank 3: bolt guest offset `0x00C1EDAC` (`0x300C1EDAC` with observed research base `0x300000000`). RatchetHax tracked HUD `753 → 755` and confirmed a write to `1755` on the HUD; Ludava live RC3 write to `1,312,312` was confirmed on the HUD on 2026-11-05.
- Both profiles store one big-endian unsigned 32-bit `bolts` field only; their active PPU SELF filenames/builds were not established in the research. The Collection's outer title ID is shared, so the selected profile must match the active embedded game. Neither the profile nor a plausible numeric read proves that match.

## Evidence vocabulary

- **Owner-tested live:** the owner observed the behavior in a live session; this does not establish compatibility with other builds or versions.
- **Unverified in Ludava:** Ludava has not reproduced the behavior in a live game session.
- **Research-confirmed:** owner-confirmed external research supports the mapping/operation; this can enable a deliberately selected profile but is not a Ludava compatibility claim.
- **Read verified in Ludava:** exact game/runtime recorded and two distinct live values match Ludava reads.
- **Write verified in Ludava:** read verification is complete, then a full write/read-back and in-game outcome are recorded.
- **Unsupported:** no matching researched profile/field is available, or evidence rules it out.

A process ID, selected profile, successful native API call, automated test, or plausible value does not establish active game identity or Ludava compatibility.

## Evidence still needed for Ludava

- Exact Windows and RPCS3 versions, executable fingerprint, and other build details were not captured for the owner-tested session.
- The owner-observed closed-game failure, startup zero, gameplay value `110`, and write-to-`120` HUD result are recorded above; they are not evidence of cross-build compatibility.
- A ROG Ally device test has not been performed.
- Repeatable evidence on another runtime/build is needed before making broader compatibility claims.

Avoid exposing personal local paths, save data, or incidental private information in public logs.
