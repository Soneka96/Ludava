# Architecture and SDK contracts

This document defines package and feature ownership, dependency direction, SDK contracts, and safety invariants for new and materially changed code. Ludava uses feature-first organization with Clean Architecture boundaries inside a feature. Add folders when a responsibility exists; do not scaffold empty layers. Source style lives in [development](DEVELOPMENT.md#dart-source-conventions), testing rules in [testing](TESTING.md), and documentation governance in [documentation](DOCUMENTATION.md).

## Feature ownership

Ludava separates the game catalog, RPCS3 connection, game detection, game memory, shared trainer application behavior, and frontend presentation. A game or build is profile data in `game_catalog`, not a separate feature. Adding a supported game adds its researched profile and fields with their actual evidence status; it reuses the existing detection and read/write workflows. `researchConfirmed` records owner-confirmed external research and remains distinct from evidence that Ludava was tested in a live game session.

Keep game-specific offsets, value types, endianness, write bounds, and evidence status in that game's profile. Do not put game-specific offsets in the process adapter or duplicate generic memory logic for every game. Only fields marked `researchConfirmed` or `verified` can be written, and every write requires a deliberate user action and matching read-back. The interactive TUI applies on Enter; diagnostic writes require `--confirm-write`.

| Feature | Owns |
| --- | --- |
| `game_catalog` | `GameProfile`, `GameField`, profile registration, and per-game profile definitions. |
| `rpcs3_connection` | RPCS3 process discovery and metadata, raw RPCS3 log reading, and session memory-base resolution. |
| `game_detection` | Semantic interpretation of current-session log events, detection outcomes, and profile matching. |
| `game_memory` | Generic address resolution, value encoding/decoding, checked reads and writes, and memory safety policy. |
| `trainer` | Shared trainer workflows, state, and current write-target revalidation. |

The raw Windows RPCS3 log reader belongs to `rpcs3_connection`. Parsing PPU loads and process-finished events into identity evidence, then deciding whether that evidence selects a supported profile, belongs to `game_detection`.

### Game identity and evidence ownership

Game/build profiles are data in `game_catalog`; current identity uses the registered title ID, executable name and measured PPU hash, evaluated with fresh lifecycle evidence. External live research can qualify for `researchConfirmed` under the [development workflow](DEVELOPMENT.md#researching-game-fields); an untested address cannot enable writes by itself. See [game detection](features/game-detection.md), [game memory](features/game-memory.md), and per-game research in [`games/`](games/collection.md).

`game_memory` owns the shared process-memory operation that opens a process handle, executes the generic field read or guarded write use case, records operation and cleanup failures separately, and closes the handle. Trainer-session and diagnostic services share this operation while keeping their distinct identity and authorization policies. `game_detection` owns the RPCS3 evidence workflow and profile decision; session and diagnostic services request detection through that feature capability.

## Directory ownership and composition rules

These rules are permanent admission criteria for new and materially changed code. Existing legacy paths that conflict with them are migration work, not precedent. Each significant directory must have a named feature, architectural layer, narrowly scoped shared concern, or narrowly scoped runtime/composition responsibility. Document its purpose and what belongs there; do not add a directory only to give a class a home or create unnecessary one-file directories.

Names such as `app`, `common`, `shared`, `services`, `helpers`, `utils`, `runtime`, and `composition` are not blanket-forbidden, but none may be an unrestricted container. `shared` means reused within a defined scope. `runtime` owns assembly and lifetime, not business logic. Remove or reorganize directories without a coherent responsibility.

Trainer session coordination, diagnostic workflows, validation policies, and their structured request/result models belong to the trainer feature's application layer. Do not put unrelated application workflows under the SDK root. Feature-first Clean Architecture ownership remains in force.

SDK composition may construct dependencies, connect adapters to use cases, create feature application services, own resources, and coordinate startup/disposal. It must not implement game detection, memory-write policy, value decoding, session transitions, or duplicate application workflows.

Nocterm and Flutter frontends consume public typed SDK contracts. They do not assemble native memory adapters, construct internal repositories/use cases, duplicate detection or write authorization, or parse formatted SDK output to recover business data. Presentation owns input, rendering, navigation, and user-facing messages. Nocterm is the sole supported interactive terminal; explicit diagnostic commands remain. Remove the obsolete text menu and its menu-only logic and tests. Keep a compatibility exception only for a documented, supported use case.

Prefer small typed capabilities over redundant abstractions. The approved Flutter Redux migration may use GetIt inside `apps/ludava_app` for root and feature dependency registration as defined in [`FLUTTER_ARCHITECTURE_CONVENTIONS.md`](FLUTTER_ARCHITECTURE_CONVENTIONS.md); the SDK and TUI do not use a service locator or Redux. Do not add a command bus, generic action registry, unnecessary factory, behaviorless base class, or interface without a meaningful replacement/testing purpose.

The SDK runtime is the primary public object for one engine instance. It owns SDK capabilities and their lifetimes; feature application services own behavior; the trainer session controller owns authoritative game/session state. Immutable snapshots contain application facts, never service instances, native handles, or dependency containers. The runtime is neither the state object nor a generic dependency registry. Frontends observe session state and invoke operations through typed runtime capabilities.

## Layers and dependency direction

```text
packages/ludava_sdk/lib/runtime/                     # SDK capability assembly and resource lifetime
packages/ludava_sdk/lib/features/game_catalog/       # profiles and fields
packages/ludava_sdk/lib/features/rpcs3_connection/   # process, log, native, and base adapters
packages/ludava_sdk/lib/features/game_detection/     # identity events and profile matching
packages/ludava_sdk/lib/features/game_memory/        # generic memory operations and Windows adapter
packages/ludava_sdk/lib/features/trainer/            # UI-independent workflows and state
packages/ludava_sdk/lib/shared/                      # SDK-owned shared declarations
apps/ludava_tui/lib/features/                        # feature-first Nocterm and CLI presentation
apps/ludava_tui/lib/shared/                          # TUI-local shared components
apps/ludava_app/lib/features/                        # feature-first Flutter presentation
apps/ludava_app/lib/shared/                          # Flutter-local design system and shared UI
```

Only create a layer or subfolder when it contains a real responsibility. In particular, a simple operation belongs in its use case; an application workflow is for coordination across multiple operations. Do not create empty `domain/`, `data/`, `application/`, or `presentation/` folders for symmetry.

Feature dependencies remain acyclic:

```text
game_detection → game_catalog + rpcs3_connection
game_memory    → game_catalog
trainer        → game_detection + game_catalog + rpcs3_connection + game_memory
SDK runtime    → trainer application services + concrete SDK feature data sources
TUI            → SDK public API
Flutter app    → SDK public API
```

`game_catalog` is independent of detection and memory, so those features can share profile data without depending on each other. `rpcs3_connection` does not import `game_detection`; the detection feature consumes its process/session entities and raw log adapter. The generic memory feature does not import RPCS3 or trainer code. No SDK feature imports the SDK runtime, and no feature outside `trainer` imports trainer code. Frontends use declared SDK package dependencies rather than relative paths across package boundaries.

Domain code must not import CLI, Flutter, Windows FFI, or concrete data sources. Data adapters perform I/O; cross-feature dependencies follow the acyclic graph above. The SDK runtime constructs concrete sources and feature application services, and owns their resource lifetime. It contains no business policy. Frontend entry points remain thin adapters that delegate to their package's command or application runner.

## Dart workspace and package ownership

The approved repository structure is one Dart workspace containing independently organized packages and applications:

```text
packages/ludava_sdk/
apps/ludava_tui/
apps/ludava_app/
```

`ludava_sdk` owns the reusable trainer engine: RPCS3 integration, process discovery, game detection and profiles, memory operations, session validation, field constraints, structured results, reactive state, and UI-independent application operations. Windows-specific native source and integration belong to the SDK. The SDK must not depend on Flutter or Nocterm, and it must be independently analyzable and testable without initializing a terminal.

`ludava_tui` owns Nocterm, terminal input and rendering, navigation, focus, editor interaction state, TUI components, diagnostic CLI presentation, and its executable packaging. `ludava_app` owns Flutter, desktop windows, widgets, navigation, layout, themes, GUI interaction state, and its executable packaging. Both depend on `ludava_sdk`; the two frontends must not depend on each other. Flutter remains a presentation layer and consumes only the SDK's public API.

The repository root owns workspace configuration, shared dependency resolution, top-level documentation, and build/CI orchestration. Each package owns its `lib/`, `test/`, package dependencies, and package-specific integration tests. Keep one workspace lockfile and do not commit generated package configuration directories.

The allowed dependency direction is:

```text
ludava_tui → ludava_sdk ← ludava_app
```

No production or test import may point from the SDK to a frontend, from one frontend to the other, or across package boundaries using relative paths. The Nocterm TUI calls typed SDK operations directly. Flutter's approved action/middleware boundary and synchronous write exception are defined in [`FLUTTER_ARCHITECTURE_CONVENTIONS.md`](FLUTTER_ARCHITECTURE_CONVENTIONS.md). Frontends do not duplicate engine behavior or add generic dispatchers.

Within each frontend, organize screens and components by the user-facing feature they implement. Keep shared application operations and authoritative trainer state in the SDK; keep temporary selection, focus, cursor, and unsaved editor text in the owning frontend. A Nocterm key handler calls the typed SDK operation directly. Flutter follows its linked Redux conventions. Do not route ordinary TUI operations through a generic dispatcher.

## Adding capability

- **Supported game or build:** add a profile definition and register it in `game_catalog`. Preserve the source and evidence status for each field. Do not create a per-game memory engine.
- **Game identity evidence:** parse RPCS3 log syntax in `game_detection/data`; update detection policy in `game_detection`. Keep raw file reading and process/session ownership in `rpcs3_connection`.
- **Trainer field:** add the researched field to its game profile. Reuse the generic address, read, and write use cases in `game_memory`; add focused profile and operation tests.
- **Emulator integration:** add process/log/session adapters under a dedicated connection feature. Keep emulator-specific process and log details out of `game_memory`.
- **Frontends:** keep shared operations in the SDK boundary. The TUI calls typed SDK operations from its feature-organized presentation; approved Flutter Redux controls dispatch actions for middleware, with the synchronous write bridge as the direct-operation callback exception. Do not call Windows adapters directly from widgets or terminal components.

## Trainer state and presentation boundaries

The trainer application layer owns the one authoritative `TrainerSessionState`. Publish immutable snapshots through a Dart-native observation contract so Nocterm, diagnostic flows, and Flutter can consume the same application behavior without importing a UI toolkit. Define how a new subscriber obtains the current snapshot, notify subscribers after every state transition, and provide deterministic cleanup for subscriptions and the publisher. Published collections must not be mutable through a snapshot.

Keep only transient interaction state in presentation: for example, the selected row, an unsaved editor buffer, cursor position, and focus. Do not copy process identity, detected profile, memory base, or verified field values into a second presentation model. When the authoritative session changes, clear or re-evaluate presentation state tied to the previous process, game, profile, or memory base. Revalidate identity and memory evidence before every write; a presentation snapshot never grants write authority.

The TUI's root Nocterm component observes SDK state, chooses the active screen, coordinates navigation, and cleans up its subscription. Connection, trainer, and editor screens render their own flows and call typed SDK operations; they do not open native process handles or duplicate application workflows. Extract reusable components when they own a meaningful rendering or interaction responsibility, not just to wrap a single text element. Keep Nocterm-specific types under the owning feature in `apps/ludava_tui/lib/`; the SDK controller and state contract remain reusable by another UI.

The checked-in Flutter MVP currently uses a composition-root-owned `TrainerController` for session observation, commands, and the active edit ID. The approved Redux migration will replace those Flutter presentation-state responsibilities with one Redux store, feature state, middleware, selectors, and widget-specific ViewModels; it does not change SDK authority or the TUI. Until that migration is implemented and approved, the checked-in controller remains the current behavior. The binding migration contract is in [`FLUTTER_ARCHITECTURE_CONVENTIONS.md`](FLUTTER_ARCHITECTURE_CONVENTIONS.md).

The approved Flutter migration's GetIt/Redux composition, action and middleware flow, widget-specific ViewModels, synchronous write bridge, and native-window shutdown are defined in [`FLUTTER_ARCHITECTURE_CONVENTIONS.md`](FLUTTER_ARCHITECTURE_CONVENTIONS.md). That document is the single home for the future Flutter contract; implementation still requires separate owner approval. Migration-specific visual and interaction acceptance belongs with its implementation task.

Flutter and Nocterm consume SDK-owned write eligibility and valid-target capabilities. They are presentation guidance only: the SDK revalidates process identity, executable hash, session memory base, approval, bounds, complete transfer, and matching read-back for every write. See [game-memory safeguards](features/game-memory.md).

The diagnostics feature follows the same boundary: the TUI owns command syntax, argument parsing, human-readable output, and CLI exit codes. The SDK owns reusable diagnostic operation orchestration, including process discovery, identity and memory-base evaluation, memory access, and structured result classifications. Preserve the read policy: a manually selected profile may be read without matching current identity when the request does not require current identity, and the SDK must classify that result as unverified. A request that requires current identity must fail when identity does not match. Writes always require matching current process identity and memory base, explicit confirmation, and the existing complete read/write/read-back checks. TUI command runners must call typed SDK operations; they must not construct memory repositories or use cases, open native process-memory adapters, or decide diagnostic write authorization. Keep message formatting in the TUI and operation status in typed SDK results rather than parsing SDK error strings.

Construct application services and presentation dependencies at their composition roots. Prefer small behavior-owning interfaces for replaceable boundaries. SDK and TUI code do not use a global service locator or Redux. The approved future Flutter Redux migration uses GetIt only inside `apps/ludava_app` for root/feature dependencies and the eager store singleton; reducers and middleware are directly wired into `CreateStore`. See [`FLUTTER_ARCHITECTURE_CONVENTIONS.md`](FLUTTER_ARCHITECTURE_CONVENTIONS.md) for the complete contract and [`DEVELOPMENT.md`](DEVELOPMENT.md) for source, keyboard, and component testing conventions.

## Safety invariants

These SDK safety requirements are enforced by responsibility-focused tests under [testing conventions](TESTING.md#sdk-safety-and-native-integration).

1. Only an explicitly selected profile and a field with `researchConfirmed` or `verified` write evidence can be written; report when Ludava has not checked the live runtime identity.
2. Preserve 64-bit host addresses and validate the complete requested memory range.
3. Require native success and the exact byte count before decoding or reporting a value.
4. A failed read is never reported as numeric zero.
5. A write requires a research-confirmed or verified field, a valid value range, a deliberate user action, a complete native transfer, and a matching read-back. The TUI uses Enter to apply; diagnostic commands require `--confirm-write`. Live-game validation is required before claiming Ludava compatibility.
6. Surface process and native errors; do not silently retry writes.

## Compatibility evidence

Compatibility is recorded per exact game/build and capability. Keep experimental, read-verified, write-verified, and unsupported states distinct. A process ID, selected profile, passing unit test, or plausible value is not proof of game identity or compatibility. See [per-game evidence](games/collection.md) for the evidence required to change a status.

## SDK runtime API

`LudavaSdk` is the public object for one engine instance. `LudavaSdk.create()` assembles the SDK's feature services and exposes typed `session` and `diagnostics` capabilities. It owns both capabilities and their lifetime; it does not hold trainer state itself or provide a general dependency registry. The runtime constructs the game-detection workflow and one shared process-memory operation capability, then passes them into the owning trainer and diagnostic services. Those feature services execute detection and memory operations.

`TrainerSessionController` owns the authoritative mutable session lifecycle and publishes immutable `TrainerSessionState` snapshots. A snapshot contains application facts such as process identity, profile, memory base, field reads, and write results. The `DiagnosticGameMemoryService` is a trainer application service: it coordinates diagnostic operations and returns structured `DiagnosticGameMemoryResult` values. The TUI owns command parsing, display formatting, and exit codes. Nocterm and diagnostic commands use the same SDK runtime capabilities.

Disposal is terminal and begins synchronously. `LudavaSdk.dispose()` marks both capabilities unavailable before awaiting cleanup; repeated or concurrent calls share the same completion. Calls through a retained session or diagnostics reference throw `StateError` as soon as disposal starts, before process discovery, metadata lookup, game detection, or memory access. Session state remains readable as the last immutable snapshot. Existing `stateChanges` subscriptions close, new subscriptions complete without emitting a snapshot, and no later state transition is published. A disposed capability cannot authorize a native read or write. Independently created SDK runtimes have independent lifetimes.

```dart
final sdk = LudavaSdk.create();
try {
  sdk.session.connect();
  final state = sdk.session.state;
  // Build request from the selected process and its current session base.
  final result = sdk.diagnostics.execute(request);
} finally {
  await sdk.dispose();
}
```

Here, `request` is a `DiagnosticGameMemoryRequest` prepared by the caller from the selected profile, process, and current session memory base. The diagnostic result reports identity, memory, operation, and cleanup status as typed data. Presentation code formats that result; it does not infer business facts from formatted output. Do not reintroduce the former `LudavaTrainerFactory` or place feature behavior in the runtime.

## Current implementation

The checked-in Dart workspace contains `packages/ludava_sdk`, `apps/ludava_tui`, and `apps/ludava_app`. Its high-level source ownership is:

```text
Ludava/
├── packages/ludava_sdk/
│   ├── lib/ludava_sdk.dart                 # Public SDK API
│   ├── lib/runtime/ludava_sdk.dart         # Capability assembly and lifecycle
│   ├── lib/features/
│   │   ├── game_catalog/                    # Profiles and fields
│   │   ├── game_detection/                  # Identity evidence and matching
│   │   ├── game_memory/                     # Generic reads, writes, Windows memory
│   │   ├── rpcs3_connection/                # RPCS3 process, log, and native adapters
│   │   └── trainer/                         # Session state and application workflows
│   │       └── application/diagnostics/     # Typed diagnostic orchestration
│   ├── lib/shared/                          # Scoped SDK declarations
│   └── test/                                # Mirrored SDK tests and integrations
├── apps/ludava_tui/
│   ├── bin/                                 # TUI package entry points
│   ├── lib/app/                             # CLI composition and command runner
│   ├── lib/features/                        # Connection, trainer, editor, diagnostics UI
│   ├── lib/shared/                          # TUI-local constants and terminal backend
│   └── test/                                # Mirrored TUI tests
├── apps/ludava_app/
│   ├── lib/main.dart                        # Flutter application entry point
│   ├── lib/app/                             # SDK runtime ownership and app root
│   ├── lib/features/                        # Feature-first Flutter presentation
│   ├── lib/shared/                          # Flutter-local design system and shared UI
│   ├── test/                                # Flutter widget and unit tests
│   └── windows/                             # Native Flutter Windows runner
├── bin/                                     # Root compatibility entry points
├── lib/app/ludava_cli.dart                  # Root compatibility export
├── test/                                    # Root compatibility tests
├── docs/
└── tool/                                    # Build and boundary checks
```

The SDK has no root `lib/app/`. The TUI has no interactive text menu; it owns Nocterm presentation and the explicit diagnostic CLI. The Flutter app owns the desktop entry point and presentation lifecycle while consuming the public SDK API. Root `bin/`, `lib/`, and `test/` are compatibility surfaces, not another trainer implementation.

The SDK's `game_memory` feature contains generic read/write use cases, Windows process-memory access, and shared process-handle operation ownership. `rpcs3_connection` contains Tool Help process discovery, process metadata, raw RPCS3 log access, and memory-base resolution. `game_detection` contains ordered identity events, detection outcomes, and profile matching. Automatic matching requires the current title ID, measured PPU hash, and executable name; a shared title ID alone cannot distinguish embedded games.

The `game_detection` log data source preserves ordered PPU-load and process-finished events in addition to historical title, serial, and path values. The feature workflow evaluates fresh logs for the selected process and refuses automatic matching when multiple RPCS3 processes share a log directory, multiple fresh logs conflict, or evidence is incomplete. A stop event or the outer collection/menu executable cannot select a subgame profile. Memory-base resolution requires agreement across fresh candidate logs and runs after game detection. Automatic reads and writes recheck process session, identity, and base; failed refresh reads clear the displayed value. The SDK runtime constructs the workflow and passes its typed operation into the session and diagnostics; detection runs only when those feature services request it. The Nocterm TUI does not poll continuously. Diagnostic reads may specify a profile without current identity evidence and remain labeled unverified.

The TUI command runner exposes an asynchronous lifecycle that awaits `LudavaSdk.dispose()` after diagnostics, interactive shutdown, startup failure, and nonterminal exits. Do not add a synchronous command path that starts asynchronous SDK disposal without awaiting it.

The current game/build evidence is owned by the [game records](games/collection.md); generic active-game handling is documented in [game detection](features/game-detection.md), and guarded memory writes are documented in [game memory](features/game-memory.md).
