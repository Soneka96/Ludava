# Ratchet & Clank Future: Quest for Booty — PS3 (BCES00301)

## Profile and mapping

| Property | Recorded value |
| --- | --- |
| Ludava profile | `quest-for-booty-bces00301` |
| Title ID | `BCES00301` |
| Executable | `EBOOT.BIN` |
| PPU hash | `PPU-f07f7086588a4ea86a28bd768f0cbe710f5b813b` |
| Field | Bolts |
| Guest offset | `0x009CEAE4` |
| Observed session guest base | `0x300000000` |
| Observed host address | `0x3009CEAE4` |
| Representation | Big-endian unsigned 32-bit |

The PPU hash is listed for `BCES00301` in the [RPCS3 community patch database](https://code.fizz.buzz/talexander/machine_setup/src/commit/edfafd101718cf8f7c1817dcd7106eee0f45b1b7/nix/configuration/roles/rpcs3/files/patch.yml). The active device log hash has not yet been independently captured; automatic profile matching is limited to this hash and must fail closed on a mismatch.

The guest offset is derived from the observed address and base:
`0x3009CEAE4 - 0x300000000 = 0x009CEAE4`. Ludava resolves the current session base at runtime.

## Research evidence

- A published NetCheat reference for the North American `NPUA80145` release lists a Max Bolts value at `0x009CEAE4` (`uint32`): [GameHacking forum reference](https://forum.gamehacking.org/forum/video-game-hacking-and-development/hacker-threads/14196-azagthoth-cmp-ps2-codes/page6). This is a candidate source from a different region, not proof on its own.
- On 2026-11-10, the owner reported HUD counts of **2,361** and then **2,364** during the active `BCES00301` RPCS3 session.
- A read-only process probe read `0x3009CEAE4` as **2,361** and then **2,364**, matching both reported HUD values. The raw bytes (`00 00 09 39` and `00 00 09 3C`) support big-endian unsigned 32-bit representation.
- The owner then reported that Ludava's live Bolts read and guarded write test worked in the active `BCES00301` session and approved the profile.
- The requested write value, Ludava read-back, and resulting HUD value were not supplied, so those numbers are not recorded here.

## Capability status and limits

- Bolts reads and writes are `verified` for the owner-confirmed Ludava session. The raw local PPU hash was not copied into this record; the profile uses the hash listed for `BCES00301` in the community patch database.
- Ludava's current process/session identity, PPU hash, guest base, range, preliminary read, complete transfer, and matching read-back safeguards remain required.
- Evidence covers the observed PAL title ID and the accepted session only. Other regions, game updates, and RPCS3 builds are not implied.
