# Compatibility and verification matrix

**Ludava RC2 reading and writing were tested successfully by the owner in a live RPCS3 session on November 5, 2026.** With the game closed, the initial read failed. During game startup, a later read returned `0`; once gameplay was active, a read returned `110`. The owner requested a write to `120`; Ludava reported success and displayed `120`, and the owner-provided screenshot showed `120` on the game's HUD. A valid `0` read does not by itself prove gameplay is active.

The observed guest memory base was `0x300000000`. The exact Windows and RPCS3 versions, executable fingerprint, and complete build-verification details were not supplied. This evidence records successful live RC2 read/write behavior in the owner's tested environment; compatibility across RPCS3 versions or game builds is not established. Ludava discovers RPCS3 processes, but the user selects the profile and confirms a log candidate or manual memory base. Process discovery and log matching do not identify the active game/build.

| Game/edition | Identifier | Environment | Capability | Status |
| --- | --- | --- | --- | --- |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / Windows | `bolts` read | Owner-tested live on 2026-11-05; observed `0` during startup and `110` in gameplay; exact runtime/build details unavailable |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282`, inner app `NPUA80644` | RPCS3 / Windows | `bolts` write | Owner-tested live on 2026-11-05; requested `120`, Ludava displayed `120`, and the owner screenshot showed `120` on the HUD; cross-build compatibility not established |
| Ratchet & Clank 2 — standalone PS3 | `NPUA80644` | RPCS3 / Windows | Read/write bolts | Not supported by this Collection profile |

## RC2 Collection mapping

- Collection title ID: `BCUS98282`; RC2 executable: `RC2.ppu.self`; inner app ID: `NPUA80644`.
- Guest bolt offset: `0x01329E80`; type: unsigned 32-bit; byte order: big-endian.
- Research-session guest base: `0x300000000`; observed host address: `0x301329E80`.
- The guest base may differ between sessions. Ludava checks fresh logs beside the selected executable for a candidate and asks the user to confirm it. A stale log is ignored; a missing or ambiguous value leads to the research-tested suggestion or manual entry. The selected candidate is not proof that the log belongs to that process.
- The owner-confirmed research recorded ordinary HUD changes from 244012 to 244016 and a targeted write/read-back/HUD change from 243866 to 244866.
- These research observations do not establish that Ludava's independent Dart implementation works with every RPCS3 build or Collection revision.
- No other RC2 field is included or supported. Do not apply the Collection offset to standalone RC2.
- Ratchet & Clank 1 and Ratchet & Clank 3 support have not been implemented in Ludava.

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
