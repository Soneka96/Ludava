# Ratchet: Deadlocked — standalone PS3 (NPUA80646)

**Research reviewed:** 2026-11-06  
**Evidence status:** runtime identity, two distinct live Bolts reads, and an owner-authorized write/read-back/HUD outcome are verified for this one recorded build/session only.

## External candidate and mapping

The [RatchetHax Deadlocked PS3 address reference](https://github.com/ParadoxEpoch/RatchetHax/blob/main/games/rc4_ps3_npua80646.js) identifies its target as Ratchet & Clank Deadlocked (PS3), `NPUA80646`. The repository is GPL-3.0 licensed. Ludava records only the address fact below; no RatchetHax source, object structure, implementation, or comments were copied.

| Property | Candidate |
| --- | --- |
| Game | Ratchet: Deadlocked — standalone PS3 |
| Title ID | `NPUA80646` |
| Field | Bolts |
| Referenced host address | `0x3009C32E8` |
| Reference guest base | `0x300000000` |
| Derived guest offset | `0x009C32E8` |
| Representation | Unsigned 32-bit, big-endian |

Derivation: `0x3009C32E8 - 0x300000000 = 0x009C32E8`. The reference base is part of the external address derivation only. Ludava must resolve the current RPCS3 session base and add the guest offset through its existing address resolver.

## Live runtime identity observation

The following values were observed in the fresh RPCS3 log associated with the running process on 2026-11-06. The log was read without modifying the running session.

| Evidence | Observed value |
| --- | --- |
| RPCS3 build | `0.0.43-20567-6a59542f` |
| RPCS3 executable name | `rpcs3.exe` |
| Game title | `Ratchet: Deadlocked` |
| Title ID | `NPUA80646` |
| Game version | `APP_VER=01.00 VERSION=01.01` |
| Game executable basename | `EBOOT.BIN` |
| PPU executable hash | `PPU-c44d700265e50dfe49054c1703f8fea668cc33b9` |
| Session guest memory base | `0x300000000` |

The process identity, executable hash, and guest base were present in the observed log. No stop/relaunch lifecycle experiment was performed. This observation is not evidence that the address maps to Bolts or that another RPCS3/game build has the same identity or mapping.

## Ludava read verification

- First HUD Bolts value: **1,785**, visible in the owner-provided gameplay screenshot on 2026-11-07.
- First Ludava read: **1,785**, from a diagnostic read against the current `NPUA80646` RPCS3 session; the output reported the current PPU hash matched the profile.
- Second distinct HUD value: **4,903**, visible in the owner-provided gameplay screenshot on 2026-11-07.
- Second Ludava diagnostic read: **4,903**, after the HUD value changed; output again reported the current PPU hash matched the profile.
- Both distinct values matched in the same process session; live read behavior is verified for the recorded build/session.
- The diagnostic operation's current-session PPU identity check matched the profile. The automatic Nocterm trainer session was not exercised.
- A Windows AOT executable and the existing native shim were built manually with the available Visual Studio toolchain; executable help and the diagnostic read passed.

## Write verification

- Attempted: **Yes**, after explicit owner authorization on 2026-11-07.
- Requested test value: **6,279** after a preliminary read of **6,278**.
- Read-back: **6,279**; subsequent refresh read: **6,279**.
- HUD outcome: **6,279**, visible in the owner-provided post-write gameplay screenshot on 2026-11-07.
- Profile and field write status: `verified` for the recorded build/session.

## Live write attempt

- Authorization: **Owner explicitly authorized** a guarded Bolts write test on 2026-11-07 after read verification.
- Pre-write diagnostic read: **6,278**.
- Requested value: **6,279** (one-point increase).
- SDK result: **Write and read-back complete**, matching `6,279`.
- Subsequent diagnostic refresh: **6,279**.
- Post-write HUD outcome: **6,279**, matching the requested value and SDK read-back.
- Write verification status: **VERIFIED** for the recorded build/session; no cross-build claim is made.

## Limitations

Only one RPCS3 build and one game version have observed identity, read, and write evidence. The two HUD/read pairs (`1,785` and `4,903`) and the write/read-back/HUD outcome (`6,279`) support Bolts reading and writing for this build/session. No compatibility claim is made for other regions, updates, RPCS3 builds, or devices.

The generic active-game validation and guarded write rules are documented in [game detection](../features/game-detection.md) and [game memory](../features/game-memory.md). Do not infer another build's compatibility from this recorded session.
