# Ratchet & Clank Future: A Crack in Time — US PS3 (BCUS98124)

## Profile and mapping

| Property | Recorded value |
| --- | --- |
| Ludava profile | `a-crack-in-time-bcus98124` |
| Title ID | `BCUS98124` |
| Disc version | `01.00` (installed PARAM.SFO) |
| Executable | `EBOOT.BIN` |
| PPU hash | `PPU-0997e35d2b6738f5cecfda1d76380acca0828365` |
| Field | Bolts |
| Guest offset | `0x00E24E68` |
| Observed session guest base | `0x300000000` |
| Observed host address | `0x300E24E68` |
| Representation | Big-endian unsigned 32-bit |

The PPU hash is listed for `BCUS98124` version `01.00` in the [RPCS3 community patch database](https://code.fizz.buzz/talexander/machine_setup/src/commit/edfafd101718cf8f7c1817dcd7106eee0f45b1b7/nix/configuration/roles/rpcs3/files/patch.yml). The active log hash was not copied during this research; the profile matches only this exact identity and fails closed on a mismatch.

The guest offset is derived from the observed address and session base:
`0x300E24E68 - 0x300000000 = 0x00E24E68`. Ludava resolves the current session base at runtime.

## Research evidence

- The owner reported **97** Bolts in a fresh `BCUS98124` session after restarting the game.
- A read-only aligned big-endian `uint32` scan of committed RPCS3 guest memory found 21 addresses containing `97`.
- After the owner reported **105**, reads of those 21 candidates showed that only `0x00E24E68` changed to `105`; the other candidates remained at `97`. The raw values were `00 00 00 61` and `00 00 00 69`.
- A RatchetHax reference exists for the PAL `BCES00748` release at guest offset `0x00E24F68`, but its corresponding US candidate read zero in this `BCUS98124` session. The PAL address is not used in this profile: [RatchetHax A Crack in Time profile](https://github.com/ParadoxEpoch/RatchetHax/blob/main/games/rcacit_ps3_bces00748.js).
- The owner confirmed that Ludava's live Bolts read and guarded write worked for this profile.
- The requested write value, Ludava read-back, and resulting HUD value were not provided, so those numbers are not recorded here.

## Capability status and limits

- Bolts reads and writes are `verified` for the owner-confirmed Ludava session. The active log hash was not copied into this record; the profile uses the hash listed for `BCUS98124` version `01.00` in the patch database.
- Ludava's current process/session identity, PPU hash, guest base, bounds, preliminary read, complete transfer, and matching read-back safeguards remain required.
- Evidence covers the observed US `BCUS98124` session and version only. Other regions, updates, or RPCS3 builds are not implied.
