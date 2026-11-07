# Ratchet & Clank 3 — PS3 Collection

## Profile and mapping

| Property | Recorded value |
| --- | --- |
| Ludava profile | `rc3-collection` |
| Outer Collection title ID | `BCUS98282` |
| Observed save namespace | `NPUA80645` |
| Executable | `RC3.ppu.self` |
| PPU hash | `PPU-56a8d02d516d82e5c1d39a4f7b3c9f83e350ab61` |
| Bolts guest offset | `0x00C1EDAC` |
| Data representation | Big-endian unsigned 32-bit |
| Research host address | `0x300C1EDAC`, using observed base `0x300000000` |

The shared game/title/build and lifecycle observations are in [Collection research](collection.md). The save namespace is historical context, not proof of current active game identity. The guest base is session-dependent.

## Evidence

- Owner-confirmed RatchetHax research tracked a natural HUD change **753 → 755**, followed by a write to **1755** confirmed on the HUD.
- On 2026-11-05 Ludava read **248** Bolts, then wrote **1,312,312**. The Ludava read-back and supplied gameplay screenshot showed **1,312,312**.
- The HUD also displayed a separate **+20** reward notification; its timing relative to the displayed balance was not established.
- The screenshot showed RPCS3 `0.0.43-20565` and the Collection title ID, but these read/write observations occurred before the separate PPU-hash experiment; their exact fingerprint was not measured in the same session.
- Evidence covers Bolts in the tested environment only. The mapping is not established for standalone releases or other game/runtime builds.

External research: [RatchetHax RC3 investigation](https://github.com/Soneka96/RatchetHax/blob/main/docs/rc3-collection-investigation.md). RatchetHax is GPL-3.0; Ludava's code is independently implemented.
