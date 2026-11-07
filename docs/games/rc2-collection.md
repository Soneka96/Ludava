# Ratchet & Clank 2 — PS3 Collection

## Profile and mapping

| Property | Recorded value |
| --- | --- |
| Ludava profile | `rc2-collection` |
| Outer Collection title ID | `BCUS98282` |
| Inner app / save identifier | `NPUA80644` |
| Executable | `RC2.ppu.self` |
| PPU hash | `PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9` |
| Bolts guest offset | `0x01329E80` |
| Data representation | Big-endian unsigned 32-bit |
| Research host address | `0x301329E80`, using observed base `0x300000000` |

The measured hash and lifecycle apply to the [Collection](collection.md). Do not use this offset for standalone PS3 RC2 (`NPUA80644`); standalone support is not established. The observed base may vary between sessions and is resolved dynamically.

## External research evidence

In owner-confirmed RatchetHax research, a normal HUD change **244012 → 244016** tracked the field, followed by an owner-authorized write **243866 → 244866** with matching read-back and HUD. See [RatchetHax PR #1](https://github.com/Soneka96/RatchetHax/pull/1), which contains the RC2 investigation and validation report. These observations establish the candidate mapping in that research session, not universal emulator/build compatibility.

## Ludava live evidence (2026-11-05)

- With the game closed, the initial read failed. A subsequent read returned `0` during startup, then **110** during gameplay. Valid `0` alone is not evidence of active gameplay.
- The owner deliberately requested **120**; Ludava reported the write and a matching read-back, and the supplied HUD screenshot showed **120**.
- The observed session base was `0x300000000`. The exact Windows/RPCS3 version and executable fingerprint for that earlier write session were **not captured**.
- A **separate** runtime experiment measured the PPU hashes and transitions in RPCS3 `0.0.43-20565-eee3f0f7`. After a process restart, the compiled Ludava CLI automatically detected RC2, resolved its current base and read `0`; that smoke test did not establish gameplay activity.

The independent write observation and later identity experiment must not be presented as a single exactly fingerprinted session. The owner later confirmed the Collection games worked in the trainer, but cross-build compatibility and a full game/device matrix remain unverified. No non-Bolts field is researched in this record.

Research source: [owner's RatchetHax investigation](https://github.com/Soneka96/RatchetHax/pull/1), based on [RatchetHax](https://github.com/ParadoxEpoch/RatchetHax) (GPL-3.0). Ludava is an independent implementation.
