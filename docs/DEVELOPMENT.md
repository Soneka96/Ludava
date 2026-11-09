# Development policy — personal project

This document owns development workflow and practical contributor-free project policy. Cross-package architecture, source/type conventions, safety invariants, and shared testing rules are authoritative in [ARCHITECTURE.md](ARCHITECTURE.md). Flutter Redux specifics are in [FLUTTER_ARCHITECTURE_CONVENTIONS.md](FLUTTER_ARCHITECTURE_CONVENTIONS.md).

Ludava is a personal project maintained solely by Soneka96. The owner does not solicit or accept external source contributions, unsolicited patches, feature implementations, or third-party pull requests.

Public visibility is for reading and learning; it is not an open-source license or an invitation to contribute. Copying protected code, distributing modifications, or incorporating Ludava into another product requires separate permission unless applicable law or GitHub platform rights allow it. See [LICENSE](../LICENSE). Commercial or other reuse permission may be requested from the owner and considered under a separate written agreement. No fixed fee is set, and payment alone grants no rights.

## Development workflow

- Keep each branch and pull request focused on one task. Record the problem, evidence, scope, verification, and limitations in the task or PR.
- Test behavior at its owner and use fakes or mocks at external boundaries. Keep integrations few and focused on important seams.
- Do not claim a game/build is compatible without reproducible live-game validation. Automated tests and plausible values are not compatibility evidence.
- Enable writes only for profile fields with research-confirmed or verified evidence. Keep Ludava live-runtime validation distinct from external research; process discovery and manual profile selection alone do not identify a live game/build.
- Prefer incremental changes with clear responsibilities. Cross-package architecture is owned by [ARCHITECTURE.md](ARCHITECTURE.md); future Flutter Redux architecture is owned by [FLUTTER_ARCHITECTURE_CONVENTIONS.md](FLUTTER_ARCHITECTURE_CONVENTIONS.md).

## Researching game fields

Check existing trainer references before adding a game or field, including Cheat Engine tables, community sources, emulator cheat tools, and original research. In that game's `docs/games/` record, capture sources, versions, observed address and guest-offset derivation, value representation/endianness, and what was actually tested.

- An address copied from a third party without live corroboration remains a candidate; it does not enable writes.
- Documented external live testing of the matching build and field can qualify as `researchConfirmed` when it includes source, observed behavior, address derivation, representation, and limitations. It does not claim Ludava itself was tested.
- Reserve `verified` for corresponding recorded live Ludava results. Preserve uncertainty across builds.
- Regardless of research status, writes retain current process/session, executable hash, guest base, bounds, preliminary read, complete transfer, and matching read-back checks. See [game memory](features/game-memory.md).
- Research and test on the development machine where practical. Use the ROG Ally for final interactive testing; do not require lengthy handheld commands or add data-collection tooling when local evidence is available.
- Reuse generic engine tests. Add focused mapping coverage and a proportionate smoke test where useful; do not require repeated approval ceremonies for each field.

## Source and test practices

- Follow [ARCHITECTURE.md](ARCHITECTURE.md#files-classes-and-methods) for file/member layout, enum/constants/type-alias and Dart documentation rules; follow its [testing strategy](ARCHITECTURE.md#testing) for test ownership, paths, names, fixtures, isolation, safety cases, and integration coverage.
- Flutter tests that need GetIt use isolated scopes. The Redux migration's layer-specific coverage is defined in [Flutter conventions](FLUTTER_ARCHITECTURE_CONVENTIONS.md#migration-test-ownership).

For methodless Nocterm component-tree tests driven through public pumping/input APIs, use one top-level group `Class ComponentName <observable area> behavior`; scenarios use `Class ComponentName <observable outcome>`. Keep these tests mirrored and assert visible output or dispatched actions. This naming exception applies only to component-tree behavior; adapters, controllers, and properties follow the usual method/property names in [ARCHITECTURE.md](ARCHITECTURE.md#testing).

## Frontend interaction conventions

### Nocterm

- Keep Nocterm components focused on rendering and explicit actions; process discovery, identity detection, and memory operations remain in SDK application/data layers. The root owns screen selection, navigation, and subscription cleanup.
- Handle keys in the focused screen or editor. Scope number shortcuts to their screen; editing keys do not also trigger menu actions. Escape cancels without applying or leaking terminal protocol bytes into text. Preserve cursor, selection, and focus across edits and navigation.
- Windows input comes from the Win32 console adapter, which translates complete console key records to bytes. Do not negotiate Kitty or `modifyOtherKeys`: this backend does not consume those protocols. Forward input chunks; do not infer key boundaries with an Escape timeout. Negotiate only when a backend reads the matching terminal protocol.
- Test raw terminal sequences at the input boundary when decoding affects visible behavior, including fragmented/coalesced input. Test component output and dispatched actions through public APIs. Cover cancellation-without-write, unavailable-values-not-zero, and invalid-input-not-written.

### Flutter presentation and design system

The Flutter app is a compact Windows utility that consumes public SDK capabilities. Widgets do not import SDK internals, open process handles, duplicate detection/decoding, or decide write authorization. Keep game fields dynamic and SDK-driven; use a scrollable vertical field list with one horizontal row per numeric field. Keep rows stable through edit, hover, validation, and write feedback; constrain long names/values, and keep keyboard focus, mouse/touch targets, and Windows touch keyboard usable.

Organize feature UI under `presentation/`: `screens/` owns substantial compositions (including panels and headers), and `widgets/` owns meaningful supporting components. Folder placement does not require a `Screen` suffix. Give each meaningful widget a focused file; compose named widget classes instead of hiding components in private `Widget` subclasses or private widget-returning builders. Private `State` classes and non-UI helpers are fine. Extract meaningful behavior, not every `Row` or `Padding`; avoid behaviorless wrappers. Keep shared UI under `shared/widgets/` only when multiple features use it. Add directories only for real responsibilities.

Theme responsibilities stay separate:

| Owner | Responsibility |
| --- | --- |
| `shared/theme/ludava_colors.dart` | Concrete palette colors named by identity; no semantic widget roles or layout. |
| `shared/theme/ludava_theme_tokens.dart` | The 19 typed semantic visual roles (for example `surface`, `textPrimary`, `borderSubtle`, `success`, `warning`) with one authoritative value per role. Widgets use theme tokens, not raw `LudavaColors`. |
| `shared/theme/themes/` | One raw-palette-to-token mapping and brightness per theme. Production ships dark Graphite & Teal; the factory supports brightness for future definitions. No separate `ThemeData` or widget-specific roles here. |
| `shared/theme/ludava_theme_factory.dart` | One builder for `ThemeData`, explicit Material 3 `ColorScheme` mapping, and component styles from tokens, brightness, and preset. Do not use seed-generated or competing semantic colors. The `LudavaTheme` entry point exposes the stable theme without rebuilding it on every app rebuild. |
| `shared/theme/ludava_style_presets.dart` | The single production Comfortable preset: typography, numeric text, shapes, buttons, inputs, and other shared component styling. No runtime registry, selector UI, persistence, or styling framework. |
| `shared/constants/ludava_constants.dart` | Documented shared spacing and window/layout/breakpoint values grouped by concern. Reuse equivalent measurements; do not create a token for every occurrence. |
| Component | A genuinely independent local implementation detail. |

Test meaningful widgets in their own files and at their responsibility. SDK tests own write eligibility, validation, revalidation, and verified read-back. Theme tests own semantic mappings and central styles; component tests own explicit style overrides. Prefer behavior assertions over pixel goldens unless a stable golden adds clear value. Test startup/connection, SDK-driven values and permissions, editing/cancel, success/failure, and stale-session invalidation. Cover semantic colors in app and Material controls, style presets, initial/minimum window sizes, compact widths, overflow, long titles/values, scrolling, process selection, semantics, and focus. Test dynamic fields, including profiles with multiple fields. Exercise normal/edit/error layouts at 520×360 and 480×340 logical pixels for stable row geometry and no overflow. Inject only native window actions that need a widget-test seam; test actual dragging, resizing, minimize/maximize/restore, and DPI on Windows.

The approved Redux migration's detailed state, write, lifecycle, and test contracts are in [FLUTTER_ARCHITECTURE_CONVENTIONS.md](FLUTTER_ARCHITECTURE_CONVENTIONS.md). Its task-specific visual acceptance criteria live in the migration PR/plan, not these permanent conventions.

## Documentation ownership and upkeep

- Keep one authoritative home per rule or fact; link to it elsewhere. `ARCHITECTURE.md` owns package/feature architecture; this document owns development, source/test, and documentation practices; Flutter conventions own future Redux specifics; `features/` describe behavior; `guides/` own operating/build instructions; `games/` own research; `ROADMAP.md` owns future initiatives.
- Keep README as an introduction and navigation entrypoint. Do not maintain competing convention summaries there.
- Update docs when behavior, public interfaces, supported games, research conclusions, architecture, or instructions change. Do not update them just to record commits, tests, or CI runs. Keep meaningful historical observations; remove duplicated or volatile status metadata.
- Make additions self-contained. Keep each game's research in its game record and shared Collection evidence in `games/collection.md`; do not maintain a hand-written game index. General architecture may explain evidence rules but does not duplicate hashes or addresses.
- Keep `ROADMAP.md` to meaningful future initiatives with a goal, scope, and done condition. Remove completed initiatives instead of retaining PR or test history.
- Update only the document that owns a changed fact: feature mechanisms in `features/`, game/build findings in `games/`, build instructions in `guides/`, and future work in the roadmap. Do not edit unrelated files just to synchronize status summaries.
- GitHub Actions is authoritative for current CI status. Permanent docs may describe validation categories and link to [Actions](https://github.com/Soneka96/Ludava/actions), but do not freeze run numbers or changing counts. PRs may record run-specific evidence.
- Record durable rules in their owning docs before implementation. When changing a rule, update its authority and linked references rather than copying competing versions.

## Workspace development and CI

- The root owns Dart Pub Workspace membership, the shared lockfile, top-level docs, and build/CI orchestration. Packages own manifests, sources, tests, and dependencies. Do not add package lockfiles or commit generated `.dart_tool/` directories.
- Use declared SDK package dependencies, never relative paths across package boundaries. Run analysis and tests explicitly for each package; root commands are not assumed to discover workspace members. Keep root compatibility-entry-point tests in CI.
- SDK and TUI require Dart `>=3.7.0 <4.0.0`; Flutter requires Dart 3.13+ and Flutter 3.47+. Because Pub resolves the whole workspace, development machines need Flutter 3.47+ on `PATH`. CI uses Flutter's bundled Dart SDK.
- From the root, run `dart pub get` and `dart analyze`; on Dart 3.13+, also run `dart pub workspace list`. Then run `dart analyze` and `dart test` in `packages/ludava_sdk` and `apps/ludava_tui`, `flutter analyze` and `flutter test` in `apps/ludava_app`, and root `dart test` for compatibility entry points.
- Create and validate portable Windows packages with `tool/package_windows.ps1`. It produces `build/distributions/Ludava-Desktop-Windows-x64.zip` (`Ludava.exe`) and `build/distributions/Ludava-TUI-Windows-x64.zip` (`Ludava-TUI.exe`), extracts and launches each, and may run outside the repository root. Lower-level builders are `tool/build_windows.ps1` (TUI) and `tool/build_flutter_windows.ps1` (Flutter).
- Keep the TUI archive's companion `ludava_process_discovery.dll`; the desktop archive includes Flutter runtime resources, `cnativeapi.dll`, the same SDK-owned library, and app-local Visual C++ runtime DLLs. Preserve same-directory loading and Windows x64. CI extracts relocated archives, verifies launches, and uploads them. See the [Windows build guide](guides/windows-build.md) for transfer and manual acceptance.
- `tool/check_workspace_boundaries.ps1` enforces package boundaries, public SDK entry points, removed legacy paths, and cross-package imports; `tool/test_workspace_boundaries.ps1` tests the checker. Review directory purpose and duplicated policy against [ARCHITECTURE.md](ARCHITECTURE.md), which cannot be fully enforced mechanically.
- CI formatting checks only Dart files added or changed from the PR base (`main` on branch pushes; previous commit on `main`). It resolves a missing comparison base or fails; it does not treat Git errors as an empty file list. Renames use the new path, deletions are skipped, paths with spaces are safe, and the check is read-only. Format a historical Dart file when materially changing it; do not pull unrelated findings into a task.
- These are internal engineering standards, not contributor instructions.

## Windows last-error capture

For Tool Help calls that report failure through `GetLastError`, the `rpcs3_connection` native wrapper invokes the Win32 operation, reads `GetLastError` immediately, and returns both through its output parameter. Dart must not call `GetLastError` later: the FFI transition can lose the thread-local value. The build script compiles this wrapper to `build/ludava_process_discovery.dll`; keep it limited to process discovery.

## Third-party research and licensing

Ludava is independently implemented. Research may be cited, but do not copy or mechanically translate protected source or curated data without checking terms and obtaining necessary permission. Preserve applicable credits and third-party licenses. Historical research may be reused as evidence when independently corroborated; do not copy GPL implementation into Ludava.
