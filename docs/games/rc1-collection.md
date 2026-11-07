# Ratchet & Clank 1 — PS3 Collection

## Profile and mapping

| Property | Recorded value |
| --- | --- |
| Ludava profile | `rc1-collection` |
| Outer Collection title ID | `BCUS98282` |
| Observed save namespace | `NPUA80643` |
| Executable | `RC1.ppu.self` |
| PPU hash | `PPU-3de6ba9344eb2079d5afda4552e831826af4bd09` |
| Bolts guest offset | `0x009BC3A0` |
| Data representation | Big-endian unsigned 32-bit |
| Research host address | `0x3009BC3A0`, using observed base `0x300000000` |

The recorded hash, Collection build, shared title ID and lifecycle evidence are explained in [Collection research](collection.md). A save namespace does not prove the active executable. Resolve the memory base from the **current RPCS3 session**, not the research host address.

## Evidence

- Owner-confirmed RatchetHax research followed natural HUD Bolts changes `5155 → 5105 → 5055` and a write to `105055` confirmed on the HUD.
- On 2026-11-05, Ludava read **22** Bolts and wrote **12,312**. Ludava read-back and the owner's gameplay screenshot showed **12,312**.
- The live write observation predates the separate PPU-hash experiment and cannot independently be assigned that experiment's precise executable fingerprint. The screenshot showed RPCS3 `0.0.43-20565`, but the full runtime fingerprint for the write session was not captured.
- Only Bolts is researched here; this Collection mapping must not be applied to a standalone release or another build without evidence.

External research: [RatchetHax RC1 investigation](https://github.com/Soneka96/RatchetHax/blob/main/docs/rc1-collection-investigation.md). Original RatchetHax is GPL-3.0; Ludava's implementation remains independent.
