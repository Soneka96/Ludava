# Ratchet & Clank Collection — shared research

This document owns evidence shared by the **PS3 Collection** games. Individual field mappings, read/write observations, and game-specific limitations belong to [RC1](rc1-collection.md), [RC2](rc2-collection.md), or [RC3](rc3-collection.md).

## Game and executable identity

- Outer Collection title ID: `BCUS98282`. **It does not identify which embedded game is active.**
- Measured RPCS3 build: `0.0.43-20565-eee3f0f7`.
- Observed RPCS3 executable SHA-256: `947681A2A2DEFBCD055D9AC4944ACDAFC7BCFEA0DBA8B43673E723C4FD3A3CEB`.

| Loaded executable | Meaning in the observed session | PPU hash |
| --- | --- | --- |
| `EBOOT.BIN` | Collection menu; no RC trainer | `PPU-673b1ce1b01ce7f42f1787a479f9b83854fa26f5` |
| `RC1.ppu.self` | Ratchet & Clank 1 | `PPU-3de6ba9344eb2079d5afda4552e831826af4bd09` |
| `RC2.ppu.self` | Ratchet & Clank 2 | `PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9` |
| `RC3.ppu.self` | Ratchet & Clank 3 | `PPU-56a8d02d516d82e5c1d39a4f7b3c9f83e350ab61` |

## Observed lifecycle

On 2026-11-05 the owner switched between the Collection menu and RC1, RC2, and RC3 without closing RPCS3. The fresh log showed distinct executable loads and PPU hashes, `Process finished` events on transitions, the Collection `EBOOT.BIN` hash on menu returns, and a final process-finished event after stopping RC3. A new RPCS3 process had a fresh log without prior identity; RC2 subsequently reproduced its measured hash.

The observed guest base was `0x300000000` in the two recorded process sessions. **This is an observation, not a universal base address.** Ludava resolves the current session base dynamically.

The owner subsequently confirmed working automatic detection and trainer operation across RC1, RC2, and RC3 on a Windows laptop and a ROG Ally. The exact game-to-device pairing and emulator build for that later confirmation were not recorded. The earlier compiled CLI RC2 smoke test automatically selected the profile and base and read `0`; a zero read does not by itself establish that gameplay was active.

## Evidence boundaries

Measurements above describe the recorded RPCS3 environment; no cross-build, cross-region, or standalone-release compatibility is implied. Unsupported-game and concurrent-RPCS3-instance behavior has not been verified live; when process/log ownership or current identity is ambiguous, Ludava must remain unresolved. See [game-detection behavior](../features/game-detection.md) for the generic algorithm and safety policy.

Source of the original RC2/RC1/RC3 memory research: [owner's RatchetHax investigation](https://github.com/Soneka96/RatchetHax/pull/1) and [RatchetHax](https://github.com/ParadoxEpoch/RatchetHax) (GPL-3.0). Ludava's implementation is independent; factual address observations are not copied source code.
