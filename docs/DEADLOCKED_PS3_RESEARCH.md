# Ratchet: Deadlocked PS3 (NPUA80646) research

**Research reviewed:** 2026-11-06  
**Evidence status:** runtime identity observed in one RPCS3 session; Bolts mapping is an external candidate and remains unverified in Ludava.

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

- First HUD Bolts value: **UNKNOWN**.
- First Ludava read: **NOT PERFORMED**; Dart was unavailable in the inspection shell.
- Second distinct HUD value and Ludava read: **NOT PERFORMED**.
- Whether the mapping changes with gameplay: **UNVERIFIED**.
- Automatic detection through Ludava: **NOT TESTED** against this live session.
- Deterministic profile, detection, address-resolution, read, write-safety, and TUI tests: **AUTHORED, NOT RUN** because Dart is unavailable in the current environment.
- Workspace analysis, formatting, boundary checks, and Windows build: **UNVERIFIED**; see the PR check results and current environment limitations.

## Write verification

- Attempted: **No**.
- Owner authorization for a live write test: **Not requested or recorded**.
- Read-back and HUD outcome: **NOT APPLICABLE**.
- Production write status: **DISABLED** (`VerificationStatus.none`).

## Limitations

Only one RPCS3 build and one game version have observed identity evidence. The external address remains a candidate until at least two distinct in-game Bolts values match Ludava reads. No live write is permitted until identity, read verification, and explicit owner approval for a deliberate write-validation test are established. No compatibility claim is made for other regions, updates, RPCS3 builds, or devices.
