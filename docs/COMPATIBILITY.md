# Compatibility and verification matrix

**Ludava RC2 reading and writing were tested successfully by the owner in a live RPCS3 session on November 5, 2026.** With the game closed, the initial read failed. During game startup, a later read returned `0`; once gameplay was active, a read returned `110`. The owner requested a write to `120`; Ludava reported success and displayed `120`, and the owner-provided screenshot showed `120` on the game's HUD. A valid `0` read does not by itself prove gameplay is active.

The observed guest memory base was `0x300000000`. The exact Windows and RPCS3 versions and executable fingerprint for the earlier read/write session were not recorded. That evidence is limited to the owner's tested environment; compatibility across RPCS3 versions or game builds is not established. A separate runtime log experiment on November 5, 2026 measured the Collection PPU hashes and lifecycle behavior described below. At the time these notes were first written, the new detector had not yet been validated end-to-end. A later owner confirmation is recorded below.

## RPCS3 identity evidence (2026-11-05)

The owner switched between the Collection menu and RC1, RC2, and RC3 while RPCS3 remained open. The log recorded distinct main PPU hashes for the Collection `EBOOT.BIN` and each subgame, the RC executable paths during exit-spawn, return to the Collection executable, and a final process-finished event after stopping RC3. These events were read from the candidate log while RPCS3 was running.

The process window reported RPCS3 `0.0.43-20565-eee3f0f7`. The RPCS3 executable SHA-256 was `947681A2A2DEFBCD055D9AC4944ACDAFC7BCFEA0DBA8B43673E723C4FD3A3CEB`. After restarting RPCS3, a new PID and fresh log had no prior identity; the subsequent RC2 boot recorded the same RC2 hash and base. The guest base `0x300000000` was observed for each boot in both sessions. Exact hashes and the event sequence are in [GAME_DETECTION.md](GAME_DETECTION.md).

The final compiled Ludava CLI was subsequently run against the restarted RC2 session. It automatically matched RC2, resolved the current base, and displayed a bolt read of `0`. That value alone does not prove gameplay was active. This records the specific RC2 smoke test at that point; later owner confirmation is summarized below. Unsupported games, concurrent processes sharing a log directory, other RPCS3 builds, and the game-to-device mapping for Windows laptop and ROG Ally tests remain unverified.

| Game/edition | Identifier | Environment | Capability | Status |
| --- | --- | --- | --- | --- |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / Windows | `bolts` read | Owner-tested live on 2026-11-05; observed `0` during startup and `110` in gameplay; exact runtime/build details unavailable |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / Windows | `bolts` write | Owner-tested live on 2026-11-05; requested `120`, Ludava displayed `120`, and the owner screenshot showed `120` on the HUD; cross-build compatibility not established |
| Ratchet & Clank 2 — standalone PS3 | `NPUA80644` | RPCS3 / Windows | Read/write bolts | Not supported by this Collection profile |
| Ratchet: Deadlocked — standalone PS3 | `NPUA80646` | RPCS3 `0.0.43-20567-6a59542f`, game `01.00/01.01` | Bolts read | Two distinct Ludava reads (`1,785`, `4,903`) matched owner-provided HUD screenshots in the same session; read-verified for this build only |
| Ratchet: Deadlocked — standalone PS3 | `NPUA80646` | Same observed session | Bolts write | Owner-authorized test changed `6,278` to `6,279`; write/read-back, refresh, and post-write HUD all showed `6,279`; write-verified for this build only |
| Ratchet: Deadlocked — standalone PS3 | `NPUA80646` | Same observed identity session | Automatic detection | Title ID, executable basename, and PPU hash are registered; fake-based detection tests pass; the live Nocterm trainer session is untested |
| Ratchet & Clank 1 — PS3 Collection | `BCUS98282`, observed save namespace `NPUA80643` | RPCS3 / Windows | `bolts` read/write | Owner-tested live on 2026-11-05: gameplay read `22`, requested write `12,312`, Ludava read-back and owner screenshot HUD showed `12,312` |
| Ratchet & Clank 3 — PS3 Collection | `BCUS98282`, observed save namespace `NPUA80645` | RPCS3 / Windows | `bolts` read/write | Owner-tested live on 2026-11-05: gameplay read `248`, requested write `1,312,312`, Ludava read-back and owner screenshot HUD showed `1,312,312` |
| RC1, RC2, and RC3 — PS3 Collection | `BCUS98282` | Windows laptop and ROG Ally; per-game device mapping unavailable | Automatic detection and trainer operation | Owner-confirmed later; exact RPCS3/Windows build and device pairing not recorded; no cross-build claim |

## Later owner confirmation

The owner later confirmed successful automatic detection and trainer operation
across RC1, RC2, and RC3 during testing on a Windows laptop and a ROG Ally. The
available notes do not identify which games were tested on which device or the
exact Windows/RPCS3 build for that confirmation. This supports the reported
behavior in the owner's tested environments; it does not establish that every
game was tested on both devices or that all RPCS3 builds are compatible.

## Live RC1 and RC3 verification (2026-11-05)

The owner tested both new Ludava profiles in RPCS3 and supplied terminal output and gameplay screenshots. The screenshots display RPCS3 `0.0.43-20565` and the Collection title ID `BCUS98282`. The selected process ID was `20992` and the session memory base was `0x300000000` in the terminal report. These write/read observations predate the separate PPU fingerprint experiment and do not independently link those hashes to that memory session.

- **RC1:** Ludava read `22` bolts in the running game. The owner set `12,312`; Ludava reported matching read-back and the HUD screenshot displayed `12312`.
- **RC3:** Ludava read `248` bolts. The owner set `1,312,312`; Ludava reported matching read-back and the HUD screenshot displayed `1312312`. A separate `+20` game reward appeared in the HUD; whether that bonus had already been reflected in the displayed balance was not independently established.
- The compiled Windows EXE was not demonstrated for that branch.
- These are successful live read/write observations for the owner's configuration, not proof of general cross-build compatibility or of the updated Ludava detector.

## RC2 Collection mapping

- Collection title ID: `BCUS98282`; RC2 executable: `RC2.ppu.self`; inner app ID: `NPUA80644`.
- Guest bolt offset: `0x01329E80`; type: unsigned 32-bit; byte order: big-endian.
- Research-session guest base: `0x300000000`; observed host address: `0x301329E80`.
- The guest base may differ between sessions. Ludava now checks fresh logs for a unique, agreeing base only after current game identity is established. Missing, unreadable, or conflicting candidates do not authorize automatic writes.
- The owner-confirmed research recorded ordinary HUD changes from 244012 to 244016 and a targeted write/read-back/HUD change from 243866 to 244866.
- These research observations do not establish that Ludava's independent Dart implementation works with every RPCS3 build or Collection revision.
- No other RC2 field is included or supported. Do not apply the Collection offset to standalone RC2.
- Ratchet & Clank 1: bolt guest offset `0x009BC3A0` (`0x3009BC3A0` with observed research base `0x300000000`). RatchetHax tracked HUD `5155 → 5105 → 5055` and confirmed a write to `105055` on the HUD; Ludava live RC1 write to `12,312` was confirmed on the HUD on 2026-11-05.
- Ratchet & Clank 3: bolt guest offset `0x00C1EDAC` (`0x300C1EDAC` with observed research base `0x300000000`). RatchetHax tracked HUD `753 → 755` and confirmed a write to `1755` on the HUD; Ludava live RC3 write to `1,312,312` was confirmed on the HUD on 2026-11-05.
- Both profiles store one big-endian unsigned 32-bit `bolts` field only. The separate runtime log experiment measured their active PPU SELF names and hashes in RPCS3 `0.0.43-20565-eee3f0f7`; this does not establish compatibility with other builds. The Collection's outer title ID remains shared, so identity requires the current PPU hash as well.

## Evidence vocabulary

- **Owner-tested live:** the owner observed the behavior in a live session; this does not establish compatibility with other builds or versions.
- **Unverified in Ludava:** no live-session evidence is recorded for the specific game/build and capability.
- **Research-confirmed:** owner-confirmed external research supports the mapping/operation; this can enable a deliberately selected profile but is not a Ludava compatibility claim.
- **Read verified in Ludava:** exact game/runtime recorded and two distinct live values match Ludava reads.
- **Write verified in Ludava:** read verification is complete, then a full write/read-back and in-game outcome are recorded.
- **Unsupported:** no matching researched profile/field is available, or evidence rules it out.

A process ID, selected profile, successful native API call, automated test, or plausible value does not establish active game identity or Ludava compatibility.

## Evidence still needed for Ludava

- Exact Windows and RPCS3 build details were not captured for the earlier owner-tested write session.
- Test an unsupported game and simultaneous RPCS3 processes; automatic matching should remain unresolved if identity or log ownership is uncertain.
- The owner-observed closed-game failure, startup zero, gameplay value `110`, and write-to-`120` HUD result are recorded above; they are not evidence of cross-build compatibility.
- The later owner confirmation does not include an exact game-to-device matrix or precise Windows/RPCS3 build details.
- Repeatable evidence on another runtime/build is needed before making broader compatibility claims.

## Ratchet: Deadlocked — standalone PS3 (NPUA80646)

The current RPCS3 log provided fresh identity observations for one Deadlocked session on 2026-11-06: RPCS3 `0.0.43-20567-6a59542f`, game `APP_VER=01.00 VERSION=01.01`, executable `EBOOT.BIN`, PPU hash `PPU-c44d700265e50dfe49054c1703f8fea668cc33b9`, and session guest base `0x300000000`. The title ID was `NPUA80646`. This establishes observed session identity metadata only; it does not validate the Bolts mapping.

The RatchetHax reference supplies a big-endian unsigned 32-bit Bolts mapping at guest offset `0x009C32E8`. Two distinct Ludava diagnostic reads (`1,785` and `4,903`) matched the corresponding owner-provided gameplay HUD screenshots in the same RPCS3 session. An owner-authorized write from `6,278` to `6,279` returned a complete matching read-back, a subsequent refresh read remained `6,279`, and the post-write gameplay HUD screenshot showed `6,279`. Read and write verification are established for this build/session only. Live Nocterm trainer detection, restart handling, and compatibility beyond this observed build remain **UNVERIFIED**. Full provenance and session-scoped evidence are recorded in [the Deadlocked research note](DEADLOCKED_PS3_RESEARCH.md).

Avoid exposing personal local paths, save data, or incidental private information in public logs.
