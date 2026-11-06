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

## Source and test conventions

These conventions apply to new code and files materially changed by a task:

1. Organize code under the feature that owns the capability, then by the layer that owns each responsibility. Profiles belong in `game_catalog`; RPCS3 process/session and raw log adapters belong in `rpcs3_connection`; identity policy belongs in `game_detection`; generic memory operations belong in `game_memory`; user workflows and terminal presentation belong in `trainer`. Follow [`ARCHITECTURE.md`](ARCHITECTURE.md); do not create empty layers or a new game feature when a new game profile can reuse an existing capability.
2. Give each public class its own focused file and put behavior on the class that owns it. The intentional grouping exceptions are all app enums in `lib/shared/constants/enums.dart` and constants classes grouped by kind in `lib/shared/constants/`.
3. Order class members as public fields, primary/unnamed constructor, named constructors, factory constructors, private fields, public methods/getters, then private methods/getters. Put static constants before ordinary fields within their visibility group.
4. Document every public and private class method and getter with concise Dart `///` comments. Public classes and properties also require documentation. Explain contracts, constraints, or non-obvious reasons; do not narrate an obvious implementation. Link code references as `[Type]`, `[Type.member]`, or an in-scope `[parameter]` so IDE hovers can navigate. Documentation-only references do not add runtime coupling.
5. Put every handwritten enum in `lib/shared/constants/enums.dart`, with `none` first as the unset/error sentinel and a doc comment on the enum and each member. Put cross-cutting business constants in feature- or concern-specific classes inside `app_constants.dart`; keep UI sizing in `layout_constants.dart` if a UI needs it. Keep platform/API implementation constants with their owning class. Do not create empty constants files.
6. Do not add handwritten `typedef`s, including function aliases or record aliases. Use named classes for data and class/interface collaborators for behavior. Keep typedefs only when generated code or a Dart/native/framework interop API requires them, and document the reason.
7. Mirror each production file's path under `test/` and append `_test.dart`. For example, `lib/features/game_memory/domain/usecases/read_game_field.usecase.dart` maps to `test/features/game_memory/domain/usecases/read_game_field.usecase_test.dart`. Windows runtime seams stay under `test/integration/features/<owning-feature>/`.
8. Group unit tests by public method: `Method methodName() behaves correctly`. Name each test `Method methodName() <outcome>` and add `when <condition>` when the condition is not already clear from the outcome. Use an outcome that says what the method returns, preserves, rejects, or throws.
9. Group behavior-bearing getters as `Property propertyName behaves correctly`; name scenarios `Property propertyName <outcome>` and add `when <condition>` when it clarifies the case. Do not add parentheses to property names.
10. Test through public behavior. Use fakes at memory/repository boundaries and injected native API fakes for Windows calls. Never access a live game from an automated test.
11. Keep one top-level group per method and no nested groups. Test failure and boundary paths, including that a dependency is not called when a precondition rejects the operation.
12. Test names and comments describe behavior and contracts. Keep implementation details in the code, not duplicated as prose.

## Application state and dependency injection

The application controller owns authoritative trainer-session state and publishes immutable snapshots through a UI-toolkit-independent Dart observation API. Subscribers must have a defined way to obtain current state, receive changes after transitions, and stop receiving updates after deterministic cleanup. A state snapshot must not expose mutable collections.

Presentation may own temporary interaction state such as focus, selected rows, cursor/selection, and unsaved text. It must not keep a second copy of process identity, profile, memory base, or verified field values. Clear or re-evaluate interaction state when its session becomes obsolete. Application services and replaceable boundaries are passed explicitly through constructors from the composition root. Do not use a global service locator or introduce a state-management framework without a demonstrated need. See [`ARCHITECTURE.md`](ARCHITECTURE.md) for ownership and dependency direction.

## Terminal interaction and component tests

Nocterm components render state and dispatch explicit actions; process discovery, identity detection, and memory operations stay in the application/data layers. Keep the root component responsible for screen selection, navigation, and subscription cleanup. Give screens and reusable components a focused rendering or interaction responsibility; do not create wrappers that add no behavior or layout ownership.

Handle keyboard input in the focused screen or editor. Number shortcuts act only in the screen that owns them, and editing keys must not also trigger menu actions. Escape cancels editing without applying a value or leaking terminal protocol bytes into text. Keep cursor, selection, and focus behavior stable when editing and when returning to a screen.

Test Nocterm behavior through public component and input APIs where possible. Cover raw terminal sequences at the input boundary, including fragmented and coalesced chunks, when protocol decoding affects user-visible behavior; do not import unsupported package internals into production code. Component tests should assert visible output and dispatched actions, including negative cases such as cancellation not writing, unavailable values not becoming zero, and invalid input not reaching a writer. Keep each behavior test at the component or adapter that owns it and follow the test naming and path rules above.

For a stateful or rendering Nocterm component whose behavior is exercised by pumping the public component tree and sending input, with no single public method as the test entry point, use one top-level group named `Class ComponentName <observable area> behavior` and scenarios named `Class ComponentName <observable outcome>`. Keep these tests at the component's mirrored test path, assert displayed state or dispatched actions, and do not nest groups. This exception applies only to component-tree behavior tests; adapter, controller, and property tests continue to use the method/property naming above.

## Keeping conventions authoritative

Treat `docs/ARCHITECTURE.md` and this document as the repository source of truth for engineering conventions. When a task establishes a durable rule, update the appropriate document before applying it in implementation, and cross-link shared guidance rather than copying competing versions. Keep the README as an entry point to these conventions, not a second policy source.

Behaviorless type declarations do not need artificial tests. Every class with behavior does; see the test strategy in [`ARCHITECTURE.md`](ARCHITECTURE.md).

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
