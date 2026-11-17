# Ratchet & Clank: Into the Nexus (BCUS99245)

| Property | Observed value |
| --- | --- |
| Ludava profile | `into-the-nexus-bcus99245` |
| PS3 title ID | `BCUS99245` |
| Game version | `APP_VER=01.00`, `VERSION=01.00` |
| RPCS3 build | `0.0.43-20607` |
| Executable | `EBOOT.BIN` |
| PPU hash | `PPU-8cb9b75e489362559db2d8a2c65cd93ebe2e4037` |
| Observed guest base | `0x300000000` |
| Bolts guest offset | `0x4AEFBC3C` |
| Observed Bolts host address | `0x34AEFBC3C` |
| Raritanium guest offset | `0x4127B8A0` |
| Observed Raritanium host address | `0x34127B8A0` |
| Representation | Big-endian unsigned 32-bit |

On 2026-11-17, the active game log supplied the executable identity, game version, and guest base.

The initial scan tracked `13 → 15 → 30 → 35`. A three-address write experiment produced an owner-confirmed HUD value of `10,035`, but the location that held it (`0x4ADDBCBC`) was reused during play. A field in the `IGSD` save-state structure tracked `20,658 → 20,759 → 21,295` through a checkpoint reload. Ludava wrote `21,395` to that copy and read it back. The HUD stayed unchanged, and the next pickup brought both the copy and the HUD to `21,309`. That copy is excluded from the trainer mapping.

The battle arena scan located live Bolts at host address `0x34AEFBC3C`. Subtracting the observed guest base `0x300000000` gives the profile's guest offset, `0x4AEFBC3C`.

The live object tracked `20,658 → 20,759 → 21,295 → 21,309`. An owner-authorized write changed only that object from `21,309` to `21,409`. Immediate and delayed reads returned `21,409`, and the owner confirmed `21,409` on the HUD. The profile grants `researchConfirmed` write permission based on that experiment.

The Raritanium scan narrowed `3 → 4 → 3 → 2` to a single aligned address in the `IGSD` save-state structure. Subtracting the guest base `0x300000000` from its host address `0x34127B8A0` gives guest offset `0x4127B8A0`. An owner-authorized write changed `2` to `3`. Immediate and delayed reads returned `3`, and the owner confirmed `3` on the HUD. Ludava matched the running game's PPU hash and read `3` through the registered field. The profile grants `researchConfirmed` write permission based on the HUD-confirmed experiment.

The fixed offsets were observed in one running session. The executable hash identifies the build. The addresses may be reused after a level change or an emulator restart. Confirm that the trainer matches the HUD before editing after either transition. Save persistence has not been tested.
