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

Use one top-level group per public method or independently tested property, constructor, or component behavior. Name the group and its scenarios by the subject under test:

| Subject | Group | Scenario |
| --- | --- | --- |
| Method | `Method methodName() behaves correctly` | `Method methodName() <outcome>` |
| Property | `Property propertyName behaves correctly` | `Property propertyName <outcome>` |
| Constructor | `Class TypeName construction` | `Class TypeName initializes <observable result>` |
| UI component (Nocterm or Flutter) | `Class ComponentName <observable area> behavior` | `Class ComponentName <observable outcome>` |

- Use observable outcomes such as `returns`, `preserves`, `rejects`, and `throws`; add `when <condition>` when the condition is not already clear. Property names have no parentheses. Assert component output, interactions, and callbacks/actions through public interfaces.
- Do not use nested test groups. Test negative and boundary cases for safety checks, and pair a test expecting a collaborator call with a test showing it is not called when a precondition fails.
- Use Dart/Flutter's source-to-test mapping for focused tests: `<package>/lib/<relative-path>/file.dart` → `<package>/test/<relative-path>/file_test.dart`. Preserve IDE **Go to Test** navigation; do not require tests for every class or game profile.
- SDK tests must run without Nocterm or interactive stdin; TUI tests use SDK fakes at the package boundary. Workspace CI must analyze and test each package explicitly rather than assuming root commands discover every workspace package.

## Nocterm input tests

- Test raw terminal sequences at the input boundary when decoding affects visible behavior, including fragmented/coalesced input. Test component output and dispatched actions through public APIs. Cover cancellation-without-write, unavailable-values-not-zero, and invalid-input-not-written.

## Flutter widget and presentation tests

- **Widget behavior:** Test meaningful widgets at their responsibility. Cover startup and connection, SDK-provided values and permissions, explicit editing and cancellation, successful and failed writes, stale-session invalidation, process selection, semantics, and keyboard focus. Preserve dynamic fields, including profiles with multiple fields.
- **Test ownership:** SDK tests own write eligibility, validation, revalidation, and verified read-back. Theme tests own semantic mappings and central styles; widget tests own component-specific style overrides. Prefer behavioral assertions over pixel-perfect goldens unless a stable golden adds clear value.
- **Themes and layout:** Cover semantic colors in application widgets and standard Material controls, style presets, initial/minimum window sizes, compact widths, overflow, long titles and values, and scrolling. Test normal, editing, and error states at both 520 × 360 and 480 × 340 logical pixels; assert stable row geometry and no overflow.
- **Native window:** Inject only the native actions needed for widget-test seams. Verify actual dragging, resizing, minimize/maximize/restore, and DPI behavior in Windows integration tests.

- Flutter tests that need GetIt use isolated scopes. See [Flutter Redux test ownership](FLUTTER_ARCHITECTURE_CONVENTIONS.md#migration-test-ownership) for reducer, middleware, selector, ViewModel, bridge, DI, and native-close responsibility splits.
