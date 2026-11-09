# Ludava

> A personal Windows trainer for supported RPCS3 games, powered by a reusable Dart SDK.

Ludava includes a Nocterm frontend and a Flutter Windows desktop app. Game and build compatibility is documented with the [game research records](docs/games/collection.md); source profiles define the actual supported fields.

Windows CI validates formatting, package boundaries, SDK/TUI/Flutter tests, both portable ZIPs, and relocated launch behavior. Each successful run publishes downloadable ZIP artifacts. See [GitHub Actions](https://github.com/Soneka96/Ludava/actions) for current results and downloads.

## Start here

Launch the Nocterm trainer in a Windows terminal:

```powershell
dart run bin/ludava.dart
```

This root command remains as a compatibility entry point. To run the TUI
package's own entry point, change to `apps/ludava_tui` and run
`dart run bin/ludava.dart` there.

For the graphical desktop app and portable Windows downloads, see the [Windows build and ROG Ally guide](docs/guides/windows-build.md).

Before running the TUI from source on Windows, run `.\tool\build_windows.ps1` to create the native process-discovery library used by `dart run`.

In the TUI, press **1–9** to open a field, use **↑/↓** to move and **Enter** to edit. In the editor, **Enter** applies a value and **Escape** cancels. Use **R** to refresh, **G** to re-detect, and **Q** to quit.

Ludava discovers RPCS3 automatically and lets you choose a process when several are running. It resolves game identity and session memory base from current evidence, without a normal-user address prompt.

Ludava verifies fresh RPCS3 executable and session evidence before selecting a profile or writing memory. Unsupported, stopped, or ambiguous sessions remain unresolved. The generic rules are described in [game detection](docs/features/game-detection.md) and [game memory](docs/features/game-memory.md).

## Diagnostics (optional)

For development and troubleshooting, use the [diagnostic CLI guide](docs/guides/diagnostics.md). The terminal commands are not required for ordinary trainer use.

## Portable Windows distributions

Build both Windows x64 packages from the repository root:

```powershell
.\tool\package_windows.ps1
```

This produces:

- `build\distributions\Ludava-Desktop-Windows-x64.zip`, containing `Ludava.exe` and the complete Flutter runtime bundle.
- `build\distributions\Ludava-TUI-Windows-x64.zip`, containing `Ludava-TUI.exe` and the native process-discovery DLL.

Copy either ZIP to the ROG Ally and extract it into its own folder. Dart and Flutter are not required on the Ally. See [Windows build and ROG Ally setup](docs/guides/windows-build.md) for transfer details and the physical-device acceptance checklist.

## Development

The Dart workspace contains a reusable SDK (`packages/ludava_sdk`), the Nocterm terminal frontend (`apps/ludava_tui`), and a Flutter Windows frontend (`apps/ludava_app`). Both frontends use the SDK rather than implementing separate memory engines. See [architecture](docs/ARCHITECTURE.md) and [development conventions](docs/DEVELOPMENT.md) for package responsibilities, testing and workspace setup.

## Documentation

- [Architecture and workspace](docs/ARCHITECTURE.md)
- [Approved future Flutter Redux conventions](docs/FLUTTER_ARCHITECTURE_CONVENTIONS.md) (the checked-in app currently uses `TrainerController`)
- [Development and research conventions](docs/DEVELOPMENT.md)
- [Feature behavior](docs/features/game-detection.md)
- [Game research and compatibility](docs/games/collection.md)
- [Windows build and setup guide](docs/guides/windows-build.md)
- [Optional diagnostic commands](docs/guides/diagnostics.md)
- [Future initiatives](docs/ROADMAP.md)

## Engineering conventions

Use [AGENTS.md](AGENTS.md) as the short navigation map for coding agents. The authoritative rules live in [architecture](docs/ARCHITECTURE.md), [development practices](docs/DEVELOPMENT.md), and [future Flutter Redux conventions](docs/FLUTTER_ARCHITECTURE_CONVENTIONS.md). Feature behavior, build guides, and game evidence remain in their linked documents above.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.
