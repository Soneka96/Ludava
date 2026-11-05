# RPCS3 game detection

## Current behavior

Ludava resolves the current Collection executable from the latest ordered PPU load and process-finished events in one fresh RPCS3 log. Automatic profile matching requires the shared title ID `BCUS98282`, the executable filename, and one measured PPU hash. Historical titles and hashes are not treated as current identity after a later stop, menu boot, pending executable load, or process restart.

The interactive CLI checks game identity before the guest memory base. A fresh, unique base is used without asking the user to confirm it. If the game or base cannot be established, Ludava does not load a trainer. Manual profile selection remains available for read-only inspection and is labeled unverified.

Automatic refresh reads and writes check that the selected RPCS3 process and start time remain the same, the current PPU hash still matches the selected profile, and the guest base still matches the current session log. A failed read check clears the displayed value. Writes also use the existing preliminary read, explicit confirmation, complete native write, and matching read-back checks. The CLI does not poll in the background; **Re-detect game**, refresh, and a requested write trigger fresh checks.

## Measured PPU identities

The following fingerprints were captured from the RPCS3 process log while the owner switched games. The RPCS3 window showed build `0.0.43-20565-eee3f0f7`; the executable SHA-256 was `947681A2A2DEFBCD055D9AC4944ACDAFC7BCFEA0DBA8B43673E723C4FD3A3CEB`.

| Logged executable | Meaning in the tested Collection | PPU hash |
| --- | --- | --- |
| `EBOOT.BIN` | Collection menu; no trainer profile | `PPU-673b1ce1b01ce7f42f1787a479f9b83854fa26f5` |
| `RC1.ppu.self` | Ratchet & Clank 1 | `PPU-3de6ba9344eb2079d5afda4552e831826af4bd09` |
| `RC2.ppu.self` | Ratchet & Clank 2 | `PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9` |
| `RC3.ppu.self` | Ratchet & Clank 3 | `PPU-56a8d02d516d82e5c1d39a4f7b3c9f83e350ab61` |

All three embedded games retained the outer title ID `BCUS98282`. RPCS3 logged `Process finished -> <RCx.ppu.self>` during subgame transitions, then logged the new executable path and hash. Returning to the Collection menu logged a normal process finish followed by the `EBOOT.BIN` hash. Stopping RC3 while leaving RPCS3 open ended with a process-finished event and no later PPU load.

These hashes were measured in the stated RPCS3 environment. Unknown or incomplete hashes remain unresolved, including when the outer title ID matches the Collection. No identity is inferred from save paths, bolt values, or window titles.

## Guest memory base

RPCS3 logs `vm::g_base_addr` at runtime. The tested Collection boots recorded `0x300000000` in both observed RPCS3 process sessions. Ludava still reads the current session’s log instead of using that value as a constant. It accepts a base only when all readable fresh candidate logs agree; missing, unreadable, malformed, or conflicting candidates do not authorize a trainer or a write.

## Process and evidence limits

The log is selected from the RPCS3 executable directory and must be at least as new as the selected process start time. If multiple RPCS3 processes share that log directory, or multiple fresh logs make ownership unclear, automatic detection stays unresolved. Restarting RPCS3 produced a new PID and fresh log with no old game identity; the first game boot then supplied that session’s hash and base.

The owner-run log experiment establishes RPCS3’s observed hashes and transitions for this environment. The final compiled Ludava CLI was live-smoke-tested with RC2: it selected the profile and base automatically and displayed a bolt read of `0`. A zero read does not prove gameplay was active, and live Ludava detection runs for RC1 and RC3 remain pending. Automated tests cover parsing, ambiguity, stop and restart invalidation, and write guards, but they are not live-game compatibility tests. Unsupported-game and multiple-process behavior has not been exercised live; those cases fail closed and are covered by deterministic tests.
