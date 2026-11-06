# Ludava

> A Windows game-memory trainer with a keyboard-driven Nocterm interface for the PS3 Collection.

**Status:** The owner tested bolt reading and writing in Ludava for all three Collection games on November 5, 2026. A separate live RPCS3 log experiment measured distinct PPU hashes for the Collection menu and RC1/RC2/RC3 on RPCS3 `0.0.43-20565-eee3f0f7`. The final compiled CLI was live-smoke-tested with RC2: it matched the profile, resolved the session base, and read `0` (which does not prove gameplay was active). The owner later confirmed automatic detection and trainer operation across RC1, RC2, and RC3 during testing on a Windows laptop and a ROG Ally. The records do not map each game to each device or identify the exact RPCS3 build for that later confirmation; compatibility with other builds remains unverified.

## Start here

Launch the Nocterm trainer in a Windows terminal:

```powershell
dart run bin/ludava.dart
```

This root command remains as a compatibility entry point. To run the TUI
package's own entry point, change to `apps/ludava_tui` and run
`dart run bin/ludava.dart` there.

Run `.\tool\build_windows.ps1` first to create the native process-discovery
library used by `dart run` and the compiled executable.

Use **↑/↓** to move through fields, **1–9** to select one, and **Enter** to
open its value editor. In the editor, **Enter** applies a changed, valid value
and shows the verified read-back; **Escape** cancels without writing. Use **R**
to refresh, **G** to re-detect the game, and **Q** to quit. The editor starts
with the current value ungrouped and its cursor at the end.

Ludava selects a single running RPCS3 process automatically. If multiple processes are found, choose one with **↑/↓**, **1–9**, and **Enter**. For the measured Collection build, it identifies the current embedded game from the latest PPU load and stop events in a fresh process log. When identity is confirmed, it uses one unique guest memory base from that process session's log without asking you to confirm it. Ludava does not hardcode `0x300000000`.

The shared Collection title ID `BCUS98282` cannot distinguish RC1, RC2, and RC3 by itself. Ludava also matches the executable filename and measured PPU hash. A stop, menu executable, unknown hash, conflicting log, or unclear process ownership leaves the game unresolved and does not load a trainer. Automatic refresh reads and writes require a fresh matching process session, PPU hash, profile, and base; a stale read clears the displayed value, and writes also require a complete preliminary read and matching read-back. Interactive writes apply directly after Enter without an extra confirmation dialog; diagnostic writes still require `--confirm-write`.

Start a supported Collection game, then launch Ludava. When the identity is confirmed, the trainer opens the matching profile. Press **G** to clear displayed values and check identity again. A detected unsupported title has no trainer profile.

If bolts are unavailable, start the selected Collection game in RPCS3 and press **R**. If the game is already running, check the on-screen status for identity or memory-base errors.

Each Collection profile stores a separate big-endian unsigned 32-bit bolt offset: RC1 `0x009BC3A0`, RC2 `0x01329E80`, RC3 `0x00C1EDAC`. These offsets are not interchangeable with the standalone PS3 game profiles.

## Diagnostic commands

The explicit commands below are for troubleshooting. Reads may use a manually selected profile and are labeled unverified unless current identity evidence matches. A write is rejected unless the current RPCS3 process, PPU identity, and session memory base match the selected profile and arguments. The examples below use RC2.

Read the current bolt count:

```powershell
dart run bin/ludava.dart read --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0x300000000
```

Repeat the `read` command to refresh the value. Each command opens the selected process for that operation and closes its handle before exiting.

Write an unsigned 32-bit bolt value explicitly with `--value` and `--confirm-write`:

```powershell
dart run bin/ludava.dart write --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0x300000000 --value 244866 --confirm-write
```

The shared write operation rechecks current process/session identity and base, requires a complete valid read of the selected field, writes four big-endian bytes, checks the native result and byte count, and reads the field back. It reports success only when the read-back matches the requested value. The owner tested a write to `120`; Ludava displayed `120`, and the owner screenshot showed `120` on the game's HUD. The owner later confirmed automatic detection and trainer operation across RC1, RC2, and RC3 on a Windows laptop and a ROG Ally; the records do not identify the exact game/device pairing or RPCS3 build. RatchetHax research remains separate from Ludava's implementation.

## Portable Windows build

Build the Windows x64 executable and its native process-discovery library with:

```powershell
.\tool\build_windows.ps1
```

Copy `build\Ludava.exe` and `build\ludava_process_discovery.dll` to the ROG
Ally, keeping them in the same directory. Dart and Flutter are not required on
the Ally. See [Windows build and ROG Ally setup](docs/WINDOWS_BUILD.md) for the
build and transfer steps.

## Dart workspace

The repository contains two workspace packages:

- `packages/ludava_sdk` owns the reusable trainer engine, session state, profiles, RPCS3 integration, memory safety, and native process-discovery source.
- `apps/ludava_tui` owns the Nocterm interface, diagnostic CLI, and Windows executable packaging.

Both use the SDK's public API from `packages/ludava_sdk/lib/ludava_sdk.dart`.
The root `bin/` commands remain compatibility wrappers. The future Flutter
application will be added as `apps/ludava_app` in a later project; it is not
part of this workspace yet.

Resolve and inspect the shared workspace from the repository root:

```powershell
dart pub get
dart pub workspace list
dart analyze
```

Run the SDK checks from its package directory:

Start each package command block from the repository root in a new shell.

```powershell
Set-Location packages/ludava_sdk
dart analyze
dart test
```

Run the TUI checks from its package directory:

```powershell
Set-Location apps/ludava_tui
dart analyze
dart test
```

Run root compatibility entry-point tests from the repository root with
`dart test`. Workspace tests are run per package; root test commands do not
replace the SDK and TUI package suites.

## Architecture

Ludava separates `game_catalog`, `rpcs3_connection`, `game_detection`, `game_memory`, and `trainer`. Profiles are shared catalog data; detection owns identity policy, the connection feature owns RPCS3 process/log infrastructure, and memory access remains generic. See [Architecture and testing](docs/ARCHITECTURE.md) for package ownership, dependency rules, extension points, and test organization.

- [MVP scope and acceptance gates](docs/MVP.md)
- [Compatibility evidence matrix](docs/COMPATIBILITY.md)
- [RPCS3 game-detection investigation](docs/GAME_DETECTION.md)
- [Roadmap](docs/ROADMAP.md)
- [Windows build and ROG Ally setup](docs/WINDOWS_BUILD.md)
- [Research handoff](docs/RESEARCH_HANDOFF.md)
- [Development policy and conventions](docs/DEVELOPMENT.md)

Technical references: [Dart native interop](https://dart.dev/interop/c-interop), [Flutter Windows development](https://docs.flutter.dev/platform-integration/windows/setup).

## Engineering principles

1. Add abstractions only for a real boundary or requirement.
2. Keep catalog data, RPCS3 integration, game detection, generic memory access, and trainer presentation in their owning features.
3. Test each behavior at its owner, using fakes for process-memory boundaries.
4. A failed read is never a zero; fields without write-enabling research stay disabled.
5. Automated tests and plausible values do not prove game/build compatibility.
6. Keep work incremental and report limitations honestly.

## Repository status

The three Collection profiles store separate big-endian unsigned 32-bit bolt offsets and measured PPU hashes for RPCS3 `0.0.43-20565-eee3f0f7`. The owner observed guest base `0x300000000` in two process sessions; the base is resolved from the current log rather than treated as a constant. Later owner confirmation covers automatic detection and trainer operation across RC1, RC2, and RC3, with tests on a Windows laptop and a ROG Ally. Per-game device pairing and the exact runtime build were not recorded; compatibility with other RPCS3 builds remains unverified.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.
