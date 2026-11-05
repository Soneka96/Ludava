# Research handoff: RatchetHax → Ludava

Ludava's implementation is independently written. RatchetHax supplies the research basis and remains GPLv3; no RatchetHax source has been copied or mechanically translated.

## Owner-confirmed RC2 Collection research

RatchetHax PR #1 is merged. Its RC2 Collection investigation records the following tested-session values:

- Collection title ID: `BCUS98282`.
- RC2 subgame executable: `RC2.ppu.self`; inner app ID: `NPUA80644`.
- Bolt guest offset: `0x01329E80`; unsigned 32-bit, big-endian.
- Observed guest base: `0x300000000`, translating to host address `0x301329E80`.
- Two snapshots tracked a normal HUD change from 244012 to 244016.
- A targeted owner-authorized write changed 243866 to 244866; read-back and the HUD matched.

These findings establish the bolt mapping for the tested research session. They do not validate Ludava's separate Dart implementation, every RPCS3 build, other Collection revisions, or any other game field. The memory base may vary by session.

## RC1 and RC3 Collection research

RatchetHax PR #1 also contains owner-confirmed, bolt-only research for the other two Collection games (`BCUS98282`):

| Embedded game | Bolt guest offset | Observed host address at base `0x300000000` | Value |
| --- | --- | --- | --- |
| Ratchet & Clank 1 | `0x009BC3A0` | `0x3009BC3A0` | big-endian unsigned 32-bit |
| Ratchet & Clank 3 | `0x00C1EDAC` | `0x300C1EDAC` | big-endian unsigned 32-bit |

RC1 research tracked normal HUD changes `5155 → 5105 → 5055` and a user-confirmed write to `105055`. RC3 tracked `753 → 755` and a user-confirmed HUD write to `1755`. Exact active PPU SELF names and independent restart reproduction remain unestablished. These observed fields are now implemented as independently written Ludava profiles; live testing of Ludava RC1 and RC3 reads/writes is still needed. Do not infer support for standalone versions or other game fields.

## Ludava implementation status

Ludava stores separate RC1, RC2 and RC3 Collection bolt fields in game-specific profiles with `researchConfirmed` write eligibility for their independently observed research offsets. The CLI requires explicit process, profile, and guest-base selection. It does not identify the active executable/build automatically. The shared write use case requires a complete preliminary read, an explicit request and confirmation, a valid unsigned 32-bit value, complete native transfer, and matching read-back.

Automated tests cover the implementation using fakes and controlled local memory. On November 5, 2026, the owner tested Ludava live with Ratchet & Clank 2 in the PS3 Collection under RPCS3. With the game closed, the initial read failed; a startup read returned `0`, and a gameplay read returned `110`. The owner requested a write to `120`; Ludava reported success and displayed `120`, and the owner screenshot showed `120` on the game's HUD. The observed guest base was `0x300000000`.

The exact Windows/RPCS3 versions, executable fingerprint, and complete build-verification data were not supplied. These are successful live read/write observations in the owner's tested environment, not evidence of compatibility with every RPCS3 version or game build. A successful read of `0` does not prove gameplay is active.

## Sources and licensing

- [Original RatchetHax](https://github.com/ParadoxEpoch/RatchetHax) — GPLv3.
- [RatchetHax working fork](https://github.com/Soneka96/RatchetHax).
- [RatchetHax PR #1: RC2 Collection investigation](https://github.com/Soneka96/RatchetHax/pull/1) — merged; contains the investigation and validation report.

## Next live-validation work

1. Capture the exact Windows version, RPCS3 version, executable fingerprint, and other build details for the owner-tested session if seeking an exact-build compatibility record.
2. Record further normal gameplay values separately from startup reads; the observed `0` does not independently establish that gameplay was active.
3. The owner-tested write to `120` and matching HUD screenshot are recorded above. For any future write session, verify the current guest base, use a suitable test save, and retain the native transfer/read-back details.
4. Record recovery steps and any new runtime limitations in `COMPATIBILITY.md`.

Do not add health, multiplier, planet, equipped-item, weapon, gadget, or unlock fields without separate evidence. Keep snapshots and logs local unless they are deliberately scrubbed and shared.
