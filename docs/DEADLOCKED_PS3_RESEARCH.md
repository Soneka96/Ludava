# Ratchet: Deadlocked PS3 (NPUA80646) research

**Research reviewed:** 2026-11-06  
**Evidence status:** runtime identity observed in one RPCS3 session; one live Bolts value matches a supplied HUD screenshot, with a second distinct value still required for read verification.

## External candidate

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
- A second invocation of the diagnostic read also returned **1,785** while the HUD screenshot still showed that count. These are repeated reads of one value, not two distinct gameplay values.
- Second distinct HUD value and Ludava read: **NOT PERFORMED**.
- Whether the mapping tracks a natural gameplay change: **UNVERIFIED**.
- The diagnostic operation's current-session PPU identity check matched the profile. The automatic Nocterm trainer session was not exercised.
- SDK: **403 tests passed**, including the fresh AOT process-discovery integration test; TUI: **185 tests passed**; root compatibility: **5 tests passed**. Analysis passed in all three packages. Changed-file formatting and workspace boundary checks passed.
- GitHub Actions Windows x64 verification run 15: **PASS**, including changed-file formatting, all analyses and suites, the project build, and packaged help.
- The official Windows build script is **BLOCKED locally** because LLVM Clang is unavailable. A Windows AOT executable and the existing native shim were built manually with the available Visual Studio toolchain; executable help and the diagnostic read passed.

## Write verification

- Attempted: **No**.
- Owner authorization for a live write test: **Not requested or recorded**.
- Read-back and HUD outcome: **NOT APPLICABLE**.
- Production write status: **DISABLED** (`VerificationStatus.none`).

## Limitations

Only one RPCS3 build and one game version have observed identity evidence. The HUD screenshot and two reads agree at `1,785`, but the same value was observed each time. The external address remains a candidate until a second distinct in-game Bolts value matches a Ludava read. No live write is permitted until read verification and explicit owner approval for a deliberate write-validation test are established. No compatibility claim is made for other regions, updates, RPCS3 builds, or devices.
