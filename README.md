# Ludava

> A Windows trainer for supported RPCS3 games, powered by a reusable Dart SDK.

Ludava currently uses a Nocterm terminal interface. Game and build compatibility is documented with the [game research records](docs/games/collection.md); source profiles define the actual supported fields.

The Windows CI workflow validates formatting, analysis and test suites, workspace boundaries, and executable packaging. See [GitHub Actions](https://github.com/Soneka96/Ludava/actions) for current results.

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

Press **1–9** to open the corresponding field directly. Use **↑/↓** to move
through fields and **Enter** to open the selected field. In the editor,
**Enter** applies a changed, valid value and shows the verified read-back;
**Escape** cancels without writing. Use **R** to refresh, **G** to re-detect
the game, and **Q** to quit. The editor starts with the current value ungrouped
and its cursor at the end.

Ludava selects a single running RPCS3 process automatically. If multiple processes are found, choose one with **↑/↓**, **1–9**, and **Enter**. For the measured Collection build, it identifies the current embedded game from the latest PPU load and stop events in a fresh process log. When identity is confirmed, it uses one unique guest memory base from that process session's log without asking you to confirm it. Ludava does not hardcode `0x300000000`.

Ludava verifies fresh RPCS3 executable and session evidence before selecting a profile or writing memory. Unsupported, stopped, or ambiguous sessions remain unresolved. The generic rules are described in [game detection](docs/features/game-detection.md) and [game memory](docs/features/game-memory.md).

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

Memory writes remain guarded by current-session identity, a preliminary read, complete transfer and matching read-back. See [game memory](docs/features/game-memory.md) for the full contract.

## Portable Windows build

Build the Windows x64 executable and its native process-discovery library with:

```powershell
.\tool\build_windows.ps1
```

Copy `build\Ludava.exe` and `build\ludava_process_discovery.dll` to the ROG
Ally, keeping them in the same directory. Dart and Flutter are not required on
the Ally. See [Windows build and ROG Ally setup](docs/guides/windows-build.md) for the
build and transfer steps.

## Dart workspace

The repository contains two workspace packages:

- `packages/ludava_sdk` owns the reusable trainer engine, profiles, RPCS3 integration, memory safety, native process-discovery source, and the `LudavaSdk` runtime.
- `apps/ludava_tui` owns the Nocterm interface, diagnostic command syntax and output, and Windows executable packaging. It consumes typed SDK capabilities without constructing SDK memory or detection internals.

Nocterm is the only interactive terminal interface. Diagnostic `read`,
`write`, and `--help` commands remain available; the old text-based menu has
been removed. Root `bin/` commands remain compatibility wrappers. The future
Flutter application will be added as `apps/ludava_app` in a later project; it
is not part of this workspace yet. See [Architecture and testing](docs/ARCHITECTURE.md)
for the runtime API and package ownership.

The SDK runtime assembles and owns its session and diagnostics capabilities.
Their feature services perform detection and memory operations. Disposal is
terminal: retained capability references reject further operations, while the
last immutable session snapshot remains readable. See the architecture guide
for the lifecycle and stream contract.

Pub workspaces require Dart 3.6 or newer, while `dart pub workspace list` was
added in Dart 3.13. Ludava's declared minimum is Dart 3.7, so the workspace
works throughout the supported range but the listing command does not run on
every supported SDK. See the official [Pub workspace guide](https://dart.dev/tools/pub/workspaces)
and [Dart changelog](https://dart.dev/changelog) for these tool-version details.

Resolve the shared workspace from the repository root. On Dart 3.13 or newer,
the listing command also reports its members:

```powershell
dart pub get
dart analyze
```

On Dart 3.13 or newer, also run `dart pub workspace list`. On Dart 3.7 through
3.12, inspect the root `workspace` entry and each member's
`resolution: workspace` setting instead.

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

## Documentation

- [Architecture and workspace](docs/ARCHITECTURE.md)
- [Development and research conventions](docs/DEVELOPMENT.md)
- [Feature behavior](docs/features/game-detection.md)
- [Game research and compatibility](docs/games/collection.md)
- [Windows build and setup guide](docs/guides/windows-build.md)
- [Future initiatives](docs/ROADMAP.md)

## Engineering principles

1. Add abstractions only for a real boundary or requirement.
2. Keep catalog data, RPCS3 integration, game detection, generic memory access, and trainer presentation in their owning features.
3. Test each behavior at its owner, using fakes for process-memory boundaries.
4. A failed read is never a zero; fields without write-enabling research stay disabled.
5. Automated tests and plausible values do not prove game/build compatibility.
6. Keep work incremental and report limitations honestly.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.
