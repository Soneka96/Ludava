# Development policy — personal project

Ludava is a **personal project maintained solely by Soneka96**. The owner does not solicit or accept external source-code contributions, unsolicited patches, feature implementations, or third-party pull requests.

Public visibility is intended to let anyone **read, study, and learn from** Ludava. People are welcome to write their own original implementations of ideas they learn. Public visibility is **not** an invitation to contribute or an open-source grant to reuse protected source code. Copying protected code, distributing modifications, or incorporating Ludava into another product requires separate permission unless applicable law or GitHub platform rights allow the activity. See [LICENSE](../LICENSE).

Commercial or other code-reuse permission may be requested from the repository owner and considered case by case, under a separate written agreement. No fixed fee has been set. Sending money does not automatically grant usage rights.

## Internal development workflow

The project's own development work follows these rules:

1. One focused task per development branch and pull request.
2. Each task records problem, evidence, implementation scope, test results and limitations.
3. Test behavior where it belongs using fake or mocked dependencies; exercise a small set of important integrations.
4. Do not label a game/build compatible without reproducible real-game validation.
5. Enable writes only for fields whose profile records research-confirmed or verified evidence. Keep Ludava's live-runtime validation status distinct from external research; process discovery or manual profile selection alone does not identify the active game/build.
6. Prefer simple, well-separated responsibilities and incremental refactors.

## Research-first game field workflow

When adding a game or field, **check existing trainer references first** (including Cheat Engine tables, community references, emulator cheat tools, and original research). Record sources, versions, observed address and guest-offset derivation, value type/endianness, and what was actually tested in that game's document under `docs/games/`. Treat external source code and license restrictions separately: use independently corroborated facts; do not copy GPL implementation into Ludava.

An **address copied from a third party without live corroboration remains a candidate**, not automatically write-enabled. Documented external live testing of a matching build and field, with behavioral evidence, can qualify as `researchConfirmed` and permit existing guarded writes **without a redundant full Ludava manual research ceremony**. This does not justify marking Ludava live compatibility `verified` or bypassing current-process, executable hash, guest base, bounds, preliminary-read, complete-write and read-back checks. Reserve `verified` for recorded corresponding Ludava runtime results. Preserve uncertainty when builds differ.

Research and test values on the development machine where practical; the ROG Ally need only be a final interactive testing device. Do not require lengthy handheld terminal commands, or new diagnostic UI/tooling solely to collect data already available locally. Reuse generic engine tests; add focused mapping tests and one proportionate smoke test where possible. No compulsory repeated approval sequence per field.

## Surgical documentation updates

Update **only the document that owns a changed fact**. Feature mechanism changes belong under `docs/features/`; one game's memory address or build finding belongs in its `docs/games/<profile>.md`; build instructions belong in `docs/guides/`; future priorities belong in `ROADMAP.md`. Never update unrelated files to synchronize status summaries. Keep the roadmap a concise list of meaningful future initiatives (goal, scope, done condition); remove completed initiatives instead of retaining a PR/test history.

## Source and test conventions

These conventions apply to new code and files materially changed by a task:

1. Organize code under the package and feature that own the capability, then by the layer that owns each responsibility. The SDK owns `game_catalog`, `rpcs3_connection`, `game_detection`, `game_memory`, and shared trainer application behavior. The TUI owns Nocterm presentation, navigation, editor interaction state, and diagnostic CLI presentation. The Flutter app owns its GUI presentation, window, navigation, theme, layout, and temporary interaction state. Follow [`ARCHITECTURE.md`](ARCHITECTURE.md); do not create empty layers or a new game feature when a new game profile can reuse an existing capability.
2. Give each public class its own focused file and put behavior on the class that owns it. Centralize SDK enums and constants under `packages/ludava_sdk/lib/shared/constants/`; frontend-only declarations stay in the owning frontend. The intentional SDK grouping exceptions are enums in `enums.dart` and constants classes grouped by kind in `app_constants.dart` or `layout_constants.dart` when those files contain relevant declarations.
3. Order class members as public fields, primary/unnamed constructor, named constructors, factory constructors, private fields, public methods/getters, then private methods/getters. Put static constants before ordinary fields within their visibility group.
4. Document every public and private class method and getter with concise Dart `///` comments. Public classes and properties also require documentation. Explain contracts, constraints, or non-obvious reasons; do not narrate an obvious implementation. Link code references as `[Type]`, `[Type.member]`, or an in-scope `[parameter]` so IDE hovers can navigate. Documentation-only references do not add runtime coupling.
5. Put every handwritten SDK enum in `packages/ludava_sdk/lib/shared/constants/enums.dart`, with `none` first as the unset/error sentinel and a doc comment on the enum and each member. Put cross-cutting SDK business constants in feature- or concern-specific classes inside the SDK's `app_constants.dart`; keep frontend sizing in the owning frontend's `layout_constants.dart` if a UI needs it. Keep platform/API implementation constants with their owning class. Do not create empty constants files.
6. Do not add handwritten `typedef`s, including function aliases or record aliases. Use named classes for data and class/interface collaborators for behavior. Keep typedefs only when generated code or a Dart/native/framework interop API requires them, and document the reason.
7. Mirror each production file's path under `test/` in the same package and append `_test.dart`. For example, `packages/ludava_sdk/lib/features/game_memory/domain/usecases/read_game_field.usecase.dart` maps to `packages/ludava_sdk/test/features/game_memory/domain/usecases/read_game_field.usecase_test.dart`. Windows runtime seams stay under the owning package's `test/integration/features/<owning-feature>/`.
8. Group unit tests by public method: `Method methodName() behaves correctly`. Name each test `Method methodName() <outcome>` and add `when <condition>` when the condition is not already clear from the outcome. Use an outcome that says what the method returns, preserves, rejects, or throws.
9. Group behavior-bearing getters as `Property propertyName behaves correctly`; name scenarios `Property propertyName <outcome>` and add `when <condition>` when it clarifies the case. Do not add parentheses to property names.
10. Test through public behavior. Use fakes at memory/repository boundaries and injected native API fakes for Windows calls. Never access a live game from an automated test.
11. Keep one top-level group per method and no nested groups. Test failure and boundary paths, including that a dependency is not called when a precondition rejects the operation.
12. Test names and comments describe behavior and contracts. Keep implementation details in the code, not duplicated as prose.

## Application state and dependency injection

The application controller owns authoritative trainer-session state and publishes immutable snapshots through a UI-toolkit-independent Dart observation API. Subscribers must have a defined way to obtain current state, receive changes after transitions, and stop receiving updates after deterministic cleanup. A state snapshot must not expose mutable collections. Disposal tests retain capability references, verify later operations throw before collaborators run, and verify subscriptions close without later state events; see [`ARCHITECTURE.md`](ARCHITECTURE.md#sdk-runtime-api) for the contract.

Presentation may own temporary interaction state such as focus, selected rows, cursor/selection, and unsaved text. It must not keep a second copy of process identity, profile, memory base, or verified field values. Clear or re-evaluate interaction state when its session becomes obsolete. Application services and replaceable boundaries are passed explicitly through constructors from the composition root. Do not use a global service locator or introduce a state-management framework without a demonstrated need. See [`ARCHITECTURE.md`](ARCHITECTURE.md) for ownership and dependency direction.

## Terminal interaction and component tests

Nocterm components render state and dispatch explicit actions; process discovery, identity detection, and memory operations stay in the application/data layers. Keep the root component responsible for screen selection, navigation, and subscription cleanup. Give screens and reusable components a focused rendering or interaction responsibility; do not create wrappers that add no behavior or layout ownership.

Handle keyboard input in the focused screen or editor. Number shortcuts act only in the screen that owns them, and editing keys must not also trigger menu actions. Escape cancels editing without applying a value or leaking terminal protocol bytes into text. Keep cursor, selection, and focus behavior stable when editing and when returning to a screen.

On Windows, Nocterm receives keys from the Win32 console input adapter, which translates console key records into complete byte sequences. Do not negotiate Kitty keyboard or `modifyOtherKeys` input modes for this backend: the terminal would encode keys using a protocol that the native console adapter does not consume. Forward its key-event chunks directly; do not infer Windows key boundaries with an Escape timeout. Protocol negotiation is appropriate only for a backend that reads the matching terminal protocol.

Test Nocterm behavior through public component and input APIs where possible. Cover raw terminal sequences at the input boundary, including fragmented and coalesced chunks, when protocol decoding affects user-visible behavior; do not import unsupported package internals into production code. Component tests should assert visible output and dispatched actions, including negative cases such as cancellation not writing, unavailable values not becoming zero, and invalid input not reaching a writer. Keep each behavior test at the component or adapter that owns it and follow the test naming and path rules above.

For a stateful or rendering Nocterm component whose behavior is exercised by pumping the public component tree and sending input, with no single public method as the test entry point, use one top-level group named `Class ComponentName <observable area> behavior` and scenarios named `Class ComponentName <observable outcome>`. Keep these tests at the component's mirrored test path, assert displayed state or dispatched actions, and do not nest groups. This exception applies only to component-tree behavior tests; adapter, controller, and property tests continue to use the method/property naming above.

## Flutter presentation and design system

The Flutter app consumes the public `ludava_sdk` API. Widgets do not import SDK implementation files, open native process handles, duplicate game detection or field decoding, or decide write authorization. Use `ThemeData`, `ColorScheme`, `TextTheme`, and typed `ThemeExtension` tokens for semantic styling. Keep reusable visual tokens separate from layout dimensions; own breakpoints, spacing, sizing, and minimum content dimensions in Flutter-local layout constants. A widget should be styleable through its supplied theme, including a test-only alternate theme, without changing its implementation.

Organize widgets by feature and compose focused pieces. Keep shared UI in the Flutter app only when multiple features use it. Read game fields and capabilities from the SDK profile; do not hardcode per-game field UI. Use responsive components for alternate layouts instead of separate business logic for cards and compact rows. Avoid fixed card heights that can clip dynamic names, values, errors, or editor controls. Keep keyboard focus, mouse actions, touch targets, and Windows touch-keyboard input usable.

Test important Flutter behavior with deterministic SDK dependencies and widget tests. Cover startup and connection states, SDK-driven field values and permission combinations, explicit inline edit/cancel behavior, failed and confirmed writes, and stale-session invalidation. Test token completeness, alternate-theme substitution, standard control styling, representative narrow and wide constraints, large values, semantics, and keyboard focus. Inject only native window actions that need a widget-test seam; verify real window dragging, resizing, minimize/maximize/restore, and DPI behavior on Windows separately. Prefer behavior assertions over pixel-perfect goldens unless a stable golden gives clear value.

## Keeping conventions authoritative

Treat `docs/ARCHITECTURE.md` and this document as the repository source of truth for engineering conventions. When a task establishes a durable rule, update the appropriate document before applying it in implementation, and cross-link shared guidance rather than copying competing versions. Keep the README as an entry point to these conventions, not a second policy source.

## Low-maintenance documentation

Document stable knowledge: how the system works, why decisions exist, how to build and use Ludava, where responsibilities belong, technical limits, and reproducible research. Update documentation when functionality, public interfaces, supported games, research conclusions, architectural rules, or instructions change; do not edit it just because a commit, test run, or CI run occurred.

Give each fact one authoritative home and link to it elsewhere. `ARCHITECTURE.md` owns architecture rules, this document owns development and documentation conventions, `guides/windows-build.md` owns Windows build instructions, `ROADMAP.md` owns future initiatives, and `games/` records own detailed game evidence; `features/` explains feature behavior. The README introduces Ludava and links to deeper documentation. Game-specific research belongs in one document per game under `docs/games/`; shared Collection evidence belongs in `docs/games/collection.md`. General architecture may explain detection without repeating game hashes or memory addresses. Keep future additions self-contained; avoid hand-maintained game indexes.

GitHub Actions is authoritative for current CI results. Permanent documentation must not repeat changing run numbers, automated test counts, or pass/fail status; link to [GitHub Actions](https://github.com/Soneka96/Ludava/actions) instead and describe the validation categories the workflow covers. PR descriptions may preserve run-specific results as historical records. Keep meaningful historical research observations, such as recorded gameplay values and exact RPCS3 builds; remove only duplicated, volatile status metadata.

The permanent structural rules are defined in [`ARCHITECTURE.md`](ARCHITECTURE.md#directory-ownership-and-composition-rules). Apply this checklist when adding or moving code:

1. Give every significant directory a clear owner, purpose, and admission criteria.
2. Do not use `app`, `shared`, `runtime`, or similar names as miscellaneous containers.
3. Keep trainer workflows, diagnostics, validation, and request/result models in the trainer application feature.
4. Limit SDK composition to assembly and resource lifetime; keep business behavior in its feature.
5. Make frontends use typed public SDK capabilities instead of constructing engine internals or duplicating policy.
6. Keep Nocterm as the only interactive terminal and retain explicit diagnostic commands; remove the old text menu.
7. Add abstractions only for a concrete responsibility or replaceable/testable boundary.
8. Document accepted durable conventions before implementation, and commit the convention change first.
9. Keep SDK runtime capabilities/lifetimes, feature behavior, controller-owned session state, and immutable state snapshots as separate responsibilities.

Behaviorless type declarations do not need artificial tests. Every class with behavior does; see the test strategy in [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Workspace development

The repository root owns Dart Pub Workspace membership, the shared lockfile, top-level documentation, and build/CI orchestration. Do not add package-local lockfiles or commit generated `.dart_tool/` directories. Each package owns its manifest, production sources, tests, and dependencies. Use `ludava_sdk` from frontends through declared package dependencies; do not use relative paths across package boundaries. Run analysis and tests for each package explicitly because root commands are not assumed to discover all workspace members. Preserve tests for any root compatibility entry points and run those tests in workspace CI too.

Windows CI runs `tool/test_workspace_boundaries.ps1` and `tool/check_workspace_boundaries.ps1`. The checker enforces declared package boundaries, public SDK entry-point use, removed legacy paths, and cross-package imports. It cannot decide whether a directory has a coherent feature responsibility or whether code duplicates business policy; review those against [`ARCHITECTURE.md`](ARCHITECTURE.md).

Pub workspaces were introduced in Dart 3.6; `dart pub workspace list` was added in Dart 3.13. The workspace package manifests declare Dart `>=3.7.0 <4.0.0`, so workspace resolution works across the supported range but the listing command requires Dart 3.13 or newer. See the official [Pub workspace guide](https://dart.dev/tools/pub/workspaces) and [Dart changelog](https://dart.dev/changelog). With Dart 3.7 through 3.12, run `dart pub get` and inspect the root `workspace` entries and each member's `resolution: workspace` field instead of using the listing command.

From the repository root, run `dart pub get` and `dart analyze`; on Dart 3.13 or newer, also run `dart pub workspace list`. Then run `dart analyze` and `dart test` from each of `packages/ludava_sdk` and `apps/ludava_tui`. Run `dart test` at the repository root for compatibility entry points. The Windows release build is `tool/build_windows.ps1`; it can be invoked from outside the repository root.

## Dart formatting in CI

The Windows CI formatting check must inspect only Dart files added or changed relative to the pull request's target base. Branch pushes compare with `main`; pushes to `main` compare with the previous commit. The comparison base must be available; the checker fetches a missing branch base and fails if Git cannot resolve or compare it, rather than treating an error as an empty file list. Renames are checked at their new path, deleted files are ignored, and paths containing spaces must be handled safely. The formatter check is read-only: it reports unformatted changed files without rewriting them. A historical Dart file must be formatted when the task materially changes it, while unrelated historical formatting findings are not pulled into the change.

The SDK owns the native process-discovery source and its reusable integration boundary. The TUI build tooling packages the SDK integration into `Ludava.exe` and the companion DLL. The Flutter build packages the full Windows release output and places the same SDK-owned `ludava_process_discovery.dll` beside the Flutter executable. Keep the existing TUI executable and DLL names, same-directory loading, Windows x64 target, and current safety behavior stable when changing build paths. Keep build commands reproducible and do not treat the Flutter executable alone as a portable application bundle.

These rules are internal quality standards; they are **not** contributor instructions or an invitation to submit changes.

## Windows last-error capture

For Tool Help calls that report errors through `GetLastError`, the
`rpcs3_connection` adapter calls a small native wrapper. The wrapper invokes the
Win32 operation, reads `GetLastError` immediately on failure, and returns both
values together through its output parameter. Dart must not make a later,
separate `GetLastError` call: the Dart FFI transition can lose the thread-local
value. The build script compiles the wrapper as
`build/ludava_process_discovery.dll`; keep this native code limited to the
process-discovery boundary.

## Third-party research and licensing

Ludava is intended as an independently implemented project. Historical research may be cited, but do not copy or mechanically translate copyright-protected source or curated data without checking its terms and obtaining any necessary permission. Credits and licensing requirements of third-party materials remain applicable.
