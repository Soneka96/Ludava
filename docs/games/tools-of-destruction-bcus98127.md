# Ratchet & Clank Future: Tools of Destruction — PS3 (BCUS98127)

## Profile and mapping

| Property | Observed value |
| --- | --- |
| Ludava profile | `tools-of-destruction-bcus98127` |
| Title ID | `BCUS98127` |
| Game version | `APP_VER=01.00`, disc `VERSION=02.00` |
| RPCS3 build | `0.0.43-20573` |
| Executable | `EBOOT.BIN` |
| PPU hash | `PPU-c14042df6304d3e420a9917e6f8e5fc05cc38b4c` |
| Observed session guest base | `0x300000000` |
| Bolts guest offset | `0x101EFF3C` |
| Raritanium guest offset | `0x101EFF40` |
| Derived Bolts host address | `0x3101EFF3C` |
| Derived Raritanium host address | `0x3101EFF40` |
| Representation | Big-endian unsigned 32-bit |

The guest offset is derived from the observed host address and session base:
`0x3101EFF3C - 0x300000000 = 0x101EFF3C`. The profile stores the guest offset;
Ludava resolves the current RPCS3 session base at runtime.

## Live field evidence

- Visible bolts changed from **2,735** to **2,745**. A read-only differential
  snapshot identified `0x101EFF3C` as the matching aligned 32-bit value.
- A second normal change from **2,745** to **2,793** matched the same address.
- The value at that address read back as **2,793**. A live process-memory test
  changed it to **3,793**; the value remained after 500 ms, and the owner
  confirmed that the HUD showed **3,793**.
- The test changed RPCS3 process memory. No save file was edited directly.
- On 2026-11-08, a read-only Ludava diagnostic read returned **14,056** while
  the current RPCS3 PPU hash matched this profile.

## Raritanium field evidence

- The owner reported **240** Raritanium. A normal gameplay change to **264**
  produced two matching aligned big-endian 32-bit candidates:
  `0x101EFF40` and `0x102A0338`.
- A second normal gameplay change from **264** to **214** matched both
  candidates again. Complete reads returned **214** at both addresses.
- The owner-directed test set `0x101EFF40` to **215** (+1) and `0x102A0338` to
  **216** (+2). Both values remained after 500 ms; the owner confirmed the HUD
  showed **215**, identifying `0x101EFF40` as the Raritanium field for this
  session. The behavior of `0x102A0338` beyond this test remains unknown.
- The candidate test changed RPCS3 process memory only; no save file was edited
  directly.
- On 2026-11-08, read-only Ludava diagnostic and packaged-executable reads
  returned **755**, then **393**, then **618** as gameplay changed. Each read
  reported that the current RPCS3 PPU hash matched this profile. These values
  were not paired with new HUD captures; the owner had already confirmed the
  same field on the HUD during the candidate test above.
- Raritanium reads are `verified` for this observed executable and session.
  Ludava has not performed a Raritanium write, so the field remains
  `researchConfirmed` for writes.

The bolt test supports `researchConfirmed` write evidence for the matching
executable hash and field. The Ludava read matched the current PPU hash and
verifies Bolts reads for the observed session, although that current value was
not paired with a captured HUD count. Ludava has not performed a Bolts write
attempt, so its write status remains `researchConfirmed`.

## Limits

The evidence covers the recorded BCUS98127 executable and RPCS3 session. It
does not establish compatibility with another region, game update, or PPU
hash. No RPCS3 restart reproduction has been recorded. Automatic selection
requires the current title ID, executable name, and exact PPU hash; writes
continue to require Ludava's current-process, session-base, bounds, preliminary
read, complete-transfer, and read-back checks.
