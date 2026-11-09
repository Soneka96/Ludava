# Development policy — personal project

This document owns development workflow, Dart source conventions, frontend presentation style, and workspace tooling. Package boundaries and SDK safety contracts live in [architecture](ARCHITECTURE.md), test rules in [testing](TESTING.md), documentation governance in [documentation](DOCUMENTATION.md), and future Flutter Redux specifics in [Flutter conventions](FLUTTER_ARCHITECTURE_CONVENTIONS.md).

Ludava is a personal project maintained solely by Soneka96. The owner does not solicit or accept external source contributions, unsolicited patches, feature implementations, or third-party pull requests.

Public visibility is for reading and learning; it is not an open-source license or an invitation to contribute. Copying protected code, distributing modifications, or incorporating Ludava into another product requires separate permission unless applicable law or GitHub platform rights allow it. See [LICENSE](../LICENSE). Commercial or other reuse permission may be requested from the owner and considered under a separate written agreement. No fixed fee is set, and payment alone grants no rights.

## Development workflow

- Keep each branch and pull request focused on one task. Record the problem, evidence, scope, verification, and limitations in the task or PR.
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

## Dart source conventions

### Files, classes, and methods

- Put each public class, entity, model, use case, repository, and data source in its own file. Name the file after its primary type and add a role suffix where it clarifies the type, such as `.entity.dart`, `.model.dart`, `.usecase.dart`, `.repository.dart`, or `.datasource.dart`.
- Order class members consistently: public fields/properties first; constructors next (primary/unnamed, then named, then factory); private fields next; public methods/getters/setters next; private methods/getters last. Keep static constants before ordinary fields within their visibility group. Constructor-initialized public data stays above the constructor; private dependencies/state stay below it.
- Keep small non-enum declarations with their owning concept when that keeps the file focused; give a type its own file when it has independent meaning or behavior. Enums follow the central-file rule below.
- Methods belong to the class that owns the behavior. Put stateless calculations in a focused utility class in the owning feature; do not add orphan top-level helper methods or generic `utils`/`services` dumping grounds.
- Keep each package's `main()` minimal: perform only essential entry-point initialization, then delegate to its application bootstrap or command runner. Keep business logic, feature orchestration, and incidental setup in their owning components; `main()` is not a general configuration or initialization container.
- Keep profile definitions in separate files by game and build. A profile catalog may register them, but the memory-reading flow remains shared.

### Enums, constants, and type aliases

- Put handwritten SDK and cross-package enums in `packages/ludava_sdk/lib/shared/constants/enums.dart`. Frontend-only enums stay with their frontend. Keep enum behavior in the enum declaration itself; use enhanced enums for labels, parsing, and other enum-owned behavior rather than separate extensions.
- Put `none` first in every handwritten enum, including frontend-local enums. Treat it as an invalid or unset sentinel, never as a valid selected state or implicit success. Handle an encountered `none` explicitly with an appropriate warning, error, or safe rejection; do not invent a meaningful transition solely for the sentinel. Give the enum and each member a concise `///` comment.
- Put SDK business constants in `packages/ludava_sdk/lib/shared/constants/app_constants.dart`, grouped into one `abstract final class` per feature or concern. Do not use bare top-level magic constants or one flat catch-all constants class.
- Keep layout and widget sizing constants in the owning frontend, such as `apps/ludava_tui/lib/shared/constants/layout_constants.dart`; do not mix presentation sizing into SDK business constants. Create a constants file only when there are constants of that kind to own.
- Keep platform/API implementation details such as Windows access flags beside the adapter that owns them, as private `static const` members. Do not move implementation-only values into shared application constants.
- Do not add handwritten `typedef`s, including function aliases or aliases for record-shaped results. Use a named class with fields for data and an owning class/interface for behavior or injected callbacks. Generated/third-party declarations are exempt. Keep a typedef only where Dart or a native/framework interop API requires it, and document why at the declaration.
- Central enum and constants files are deliberate grouping exceptions to the one-class-per-file rule within the owning package: SDK enums share `enums.dart`; each constants class is grouped in the file for its constant kind.

### Dart documentation

- Add concise `///` documentation to every public class, method, and property, and to every public or private method. Explain the contract, constraints, or non-obvious reason; do not narrate an obvious implementation.
- Link code symbols using Dart doc references: `[GameProfile]`, `[GameProfile.canRead]`, and, in the scope where it is declared, `[profile]`. Use fully qualified class-member references for members outside their scope.
- Import symbols to resolve Dart documentation references when needed for IDE navigation. Documentation-only imports are permitted when the target is already an allowed, declared package dependency; they do not justify new dependencies or executable cross-package access. Boundary checks must distinguish documentation-only imports from executable usage (see [package ownership](ARCHITECTURE.md#dart-workspace-and-package-ownership)).
- Use `[Class]` and `[Class.member]` rather than plain-text names when referring to code. Keep comments aligned with what the symbol guarantees, especially compatibility and memory-write safety.

## Frontend interaction conventions

### Nocterm

- Keep Nocterm components focused on rendering and explicit actions; process discovery, identity detection, and memory operations remain in SDK application/data layers. The root owns screen selection, navigation, and subscription cleanup.
- Handle keys in the focused screen or editor. Scope number shortcuts to their screen; editing keys do not also trigger menu actions. Escape cancels without applying or leaking terminal protocol bytes into text. Preserve cursor, selection, and focus across edits and navigation.
- Windows input comes from the Win32 console adapter, which translates complete console key records to bytes. Do not negotiate Kitty or `modifyOtherKeys`: this backend does not consume those protocols. Forward input chunks; do not infer key boundaries with an Escape timeout. Negotiate only when a backend reads the matching terminal protocol.

For terminal input and component tests, see [testing conventions](TESTING.md#nocterm-input-tests).

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

For widget, theme, layout, focus, and native-window test requirements, see [Flutter widget testing conventions](TESTING.md#flutter-widget-and-presentation-tests).

The approved Redux migration's architectural contract is in [Flutter conventions](FLUTTER_ARCHITECTURE_CONVENTIONS.md); its temporary acceptance criteria live in its implementation PR or plan.

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

## Third-party research and licensing

Ludava is independently implemented. Research may be cited, but do not copy or mechanically translate protected source or curated data without checking terms and obtaining necessary permission. Preserve applicable credits and third-party licenses. Historical research may be reused as evidence when independently corroborated; do not copy GPL implementation into Ludava.
