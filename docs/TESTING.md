# Testing conventions

These rules apply across the SDK, Nocterm TUI, Flutter app, and Windows integration boundaries. Feature ownership and safety contracts live in [architecture](ARCHITECTURE.md); commands and CI setup live in [development](DEVELOPMENT.md#workspace-development-and-ci). Follow [Flutter Redux test ownership](FLUTTER_ARCHITECTURE_CONVENTIONS.md#migration-test-ownership) when implementing that approved architecture.

## Responsibility and integration

- Give each behavior one primary test owner: that component, class, or layer tests its behavior thoroughly. A consumer tests only its own contract and must not repeat the owner's full behavior suite. Before keeping a consumer test that exercises a dependency, answer: “What specific bug would this catch that the owner's tests would not?” If there is no defensible answer, remove or narrow the test.
- Isolate consumer tests at existing dependency-injection boundaries with fakes, controlled results, and recorded callbacks. Flutter composition tests may render real child widgets and inspect their presence, public properties, callback forwarding, and parent-owned geometry; do not add fake-widget frameworks or production factories solely to replace visual children. Do not retest a child's validation, parsing, error formatting, state machine, or SDK policy through its parent.
- Integration tests must establish a distinct integration contract, such as callback wiring, notification propagation, resource ownership, focus handoff, or lifecycle ordering. The same failure stimulus may appear at multiple layers only when each assertion protects a different owner responsibility; for example, rejecting a partial write, closing its native handle, invalidating session state, and showing a UI failure are separate contracts.
- Keep policy matrices at their policy owner. The SDK owns generic write eligibility, identity, bounds, and memory safety decisions; frontends test representative approved/denied presentation and their response to changing eligibility, not every SDK condition again.
- Test behavior at its owner: SDK tests own SDK behavior, TUI tests own terminal behavior, and Flutter tests own widget behavior. Parent widget tests own composition and wiring; they do not repeat a child's focused behavior tests. Integration tests cover important dependency boundaries and orchestration risks, not every unit-test condition again.

## Data, fixtures, and isolation

- Generic behavior tests use synthetic `GameProfile` and `GameField` values. Frontend tests use synthetic profiles and session snapshots. They must not depend on current production game names, IDs, hashes, offsets, registration order, or a shared mutable catalog. The shared catalog-integrity suite and focused integration tests may use the production catalog for those specific responsibilities.
- Do not require a test file for each game or mirror ordinary game-profile tests across the SDK and frontends. One shared, data-driven catalog suite validates every registered profile against structural invariants without a hardcoded profile list or count. Keep exceptional game-specific tests only for unique behavior, regressions, or special mappings. Record game research and live-game evidence in `docs/games/`; passing automated tests does not establish game/build compatibility.
- Tests prove observable behavior, a contract, invariant, failure mode, or regression. Do not add tests only to restate constructor assignments, raw palette values, static configuration, ordinary per-game data, child behavior already covered at its owner, or private implementation details. Preserve meaningful immutability, validation, semantic theme, layout, accessibility, and safety contracts.
- Keep helpers and fixture classes local to a test file by default and declare them above `main()`. Use small setup/build functions with useful defaults and optional named overrides. Put helpers in package-local `test/support/` only when multiple files in that package genuinely share them. Do not add universal fixture frameworks, test service locators, cross-package test support, or unnecessary dependency containers.
- Keep tests independently maintainable: ordinary profile-data changes must not require generic SDK, TUI, or Flutter behavior-test changes; tests must not leak mutable state or rely on execution order.

## SDK safety and native integration

- Preserve distinct safety and lifecycle cases. Do not combine different rejected preconditions merely to shorten a suite. Cover unverified profiles, unsupported/read-only fields, missing confirmation, stale or incorrect process identity and PPU hash, process termination/change, memory-base changes, invalid values/ranges, address overflow, incomplete transfers, native and preliminary-read failures, read-back mismatch, cleanup failure, rejected dependency calls, and correct disposal. Never weaken write protection to simplify tests.
- Use fakes for deterministic memory boundaries and test the Windows adapter through an injected native API; unit tests must not read or write a live game's memory. Keep a small number of Windows integration tests for important native seams.
- Keep tests for root compatibility entry points and run those checks in workspace CI alongside the SDK and TUI suites.

## Naming and placement

- Use one top-level group per public method, named `Method methodName() behaves correctly`. Name each scenario `Method methodName() <outcome>` and add `when <condition>` when the condition is not already clear from the outcome. Use clear outcomes such as `returns`, `preserves`, `rejects`, and `throws`.
- Group behavior-bearing getters as `Property propertyName behaves correctly`; name scenarios `Property propertyName <outcome>` and add `when <condition>` when it clarifies the case. Do not add parentheses to property names.
- For entity/model construction tests, use `Class TypeName construction` and `Class TypeName initializes ...`. Keep each test name specific about the input and expected result.
- Do not use nested test groups. Cover negative and boundary cases for every safety check, and pair a test that expects a collaborator call with a test proving it is not called when the precondition fails.
- Mirror a focused test's path under its owning package when that path clarifies responsibility. Mirroring governs where a dedicated test belongs; it does not require a test for every production class or every profile. SDK tests must run without Nocterm or interactive stdin; TUI tests should use SDK fakes at the package boundary. Workspace CI must explicitly analyze and run each package suite rather than assuming a root test command discovers every workspace package.

- Name a focused test after its production file and mirror its path under the owning package's `test/`, with `_test.dart` appended, when that path clarifies responsibility. This does not require a test for every production class.

For methodless Nocterm component-tree tests driven through public pumping/input APIs, use one top-level group `Class ComponentName <observable area> behavior`; scenarios use `Class ComponentName <observable outcome>`. Keep these tests mirrored and assert visible output or dispatched actions. This naming exception applies only to component-tree behavior; adapters, controllers, and properties follow the usual method/property names in the naming rules above.

## Nocterm input tests

- Test raw terminal sequences at the input boundary when decoding affects visible behavior, including fragmented/coalesced input. Test component output and dispatched actions through public APIs. Cover cancellation-without-write, unavailable-values-not-zero, and invalid-input-not-written.

## Flutter widget and presentation tests

Test meaningful widgets in their own files and at their responsibility. SDK tests own write eligibility, validation, revalidation, and verified read-back. Theme tests own semantic mappings and central styles; component tests own explicit style overrides. Prefer behavior assertions over pixel goldens unless a stable golden adds clear value. Test startup/connection, SDK-driven values and permissions, editing/cancel, success/failure, and stale-session invalidation. Cover semantic colors in app and Material controls, style presets, initial/minimum window sizes, compact widths, overflow, long titles/values, scrolling, process selection, semantics, and focus. Test dynamic fields, including profiles with multiple fields. Exercise normal/edit/error layouts at 520×360 and 480×340 logical pixels for stable row geometry and no overflow. Inject only native window actions that need a widget-test seam; test actual dragging, resizing, minimize/maximize/restore, and DPI on Windows.

- Flutter tests that need GetIt use isolated scopes. See [Flutter Redux test ownership](FLUTTER_ARCHITECTURE_CONVENTIONS.md#migration-test-ownership) for reducer, middleware, selector, ViewModel, bridge, DI, and native-close responsibility splits.
