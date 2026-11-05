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

## Ludava implementation status

Ludava stores this one bolt field in its RC2 Collection profile with `researchConfirmed` write eligibility. The CLI requires explicit process, profile, and guest-base selection. It does not identify the active executable/build automatically. Writes require an explicit request and confirmation, a valid unsigned 32-bit value, complete native transfer, and matching read-back.

Automated tests cover the new implementation using fakes and controlled local memory. No live RPCS3 test of Ludava has been performed. Do not describe Ludava as runtime-compatible until its own live read and write evidence is recorded.

## Sources and licensing

- [Original RatchetHax](https://github.com/ParadoxEpoch/RatchetHax) — GPLv3.
- [RatchetHax working fork](https://github.com/Soneka96/RatchetHax).
- [RatchetHax PR #1: RC2 Collection investigation](https://github.com/Soneka96/RatchetHax/pull/1) — merged; contains the investigation and validation report.

## Next live-validation work

1. Record the exact Windows version, RPCS3 version, game/session identity, and guest base.
2. Match two distinct normal in-game bolt counts against Ludava reads.
3. With a suitable test save, perform one deliberate Ludava write and record the requested value, exact transfer result, read-back, and HUD outcome.
4. Record recovery steps and limitations in `COMPATIBILITY.md`.

Do not add health, multiplier, planet, equipped-item, weapon, gadget, or unlock fields without separate evidence. Keep snapshots and logs local unless they are deliberately scrubbed and shared.
