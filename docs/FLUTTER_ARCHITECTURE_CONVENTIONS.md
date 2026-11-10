# Flutter architecture conventions

These rules define the approved Redux architecture implemented in `apps/ludava_app`. Cross-package boundaries are in [architecture](ARCHITECTURE.md), source practices in [development](DEVELOPMENT.md), and shared test practices in [testing](TESTING.md).

## SDK authority and Redux state

- Keep RPCS3 discovery, process/session identity, detection, memory access, write eligibility, verification, and `GameWriteResult` authoritative in the SDK. Flutter capabilities may present eligibility, but the SDK revalidates every read and write.
- Reuse SDK types. Redux stores the complete immutable `TrainerSessionState` snapshot as one value and only `editingFieldId` as trainer-specific UI state. Do not duplicate SDK facts, errors, or policy, reshape SDK types for Redux, or add deep snapshot equality solely for Redux.
- Keep Redux and GetIt inside `apps/ludava_app`; neither belongs in the SDK or Nocterm. Redux is the Flutter presentation-state owner; do not add a parallel controller or compatibility state system.
- Keep numeric drafts, text controllers, cursor selection, focus, and keyboard interaction local to the inline editor.

## Composition and dependency registration

- Use one root `injection_container.dart` to register app dependencies and initialize feature containers in dependency order. Put trainer registrations and the `TrainerSdkCapability` interface/adapter in the trainer feature (`trainer.injection_container.dart`, `services/`).
- Register exactly one `TrainerSdkCapability` singleton; do not separately register its underlying `LudavaSdk`.
- During GetIt composition, read the registered SDK capability's current `TrainerSessionState` snapshot exactly once, and use it to build the initial `AppState` passed explicitly to `CreateStore`. Do not subscribe to SDK state or dispatch initialization snapshots while constructing the store.
- Eagerly construct exactly one `Store<AppState>` singleton at the root; build reducers and middleware directly into it rather than registering them in GetIt.
- Use that same store for `StoreProvider`, ViewModel factories, and lifecycle dispatch. Register each ViewModel with `registerFactoryParam`; its only runtime parameter and its `.fromStore` constructor argument are `Store<AppState>`.
- `LudavaApp` resolves app services from GetIt and owns native window lifecycle; it does not accept trainer-controller or SDK overrides.
- Pass ordinary callbacks from `LudavaApp` to native window buttons; buttons do not resolve GetIt or dispatch Redux actions.
- ViewModels obtain Redux-derived presentation data exclusively through selectors in `.fromStore` and expose the selected results as final fields. Never expose `Store<AppState>`, `AppState`, `TrainerState`, or an entire `TrainerSessionState` to widgets. Provide final typed callbacks for Redux dispatch; a callback may resolve a genuinely needed app service but must not call the SDK directly except through the synchronous write bridge below. Do not wrap SDK operations in repositories, data sources, or use cases without a real application-owned responsibility.

## State, actions, and reducers

- Keep `AppState` and feature state immutable; use `Equatable` with explicit `props` for states and ViewModels. Compose pure reducers with `combineReducers` and `TypedReducer`.
- Reducers perform no lookup, SDK call, I/O, or widget work. Return the original object for a genuine no-op. Reconcile an SDK snapshot and any edit invalidation atomically; ignore the identical snapshot object already held.
- Keep an active edit only while all of these still match the authoritative session: process ID and start time; detection status and confidence; profile ID, executable hash, and memory base; field existence; and SDK write-target eligibility.
- Preserve the failed-read exception: a failed read for the edited field alone does not clear its draft when `lastWriteResult.fieldId` identifies that field. Any other stale or invalid safety condition cancels editing.
- Use plain, typed, minimal actions ending in `Action`, with `final` fields and `const` constructors where applicable; do not use `Equatable` for actions. `BeginEditingAction` carries only `fieldId`; its reducer resolves the field from the SDK snapshot. Put global `InitializeAppAction` and `ShutdownRequestedAction` in `shared/state/app.actions.dart`, and trainer actions in the trainer feature.
- An action may be handled by a reducer, middleware, both when each has work, or neither. Do not require pass-through handling or add forwarding actions when an SDK snapshot already represents the result. The sole approved mutable action payload is `ShutdownRequestedAction`'s cleanup-future collection.

## Middleware and observation

- Implement middleware as `MiddlewareClass<AppState>`, resolve the capability through `sl`, and call `next(action)` before handling it.
- Use `switch (action)` to route only owned actions to dedicated private handlers (`RefreshTrainerAction` → `_refreshTrainer()`). Keep substantive work in those handlers; do not combine unrelated actions into generic handlers.
- Preserve both refresh paths: discover/connect when no process is selected, and refresh the SDK session when one is selected. Use the typed process-selection action.
- `TrainerMiddleware` is the sole owner of SDK session observation. On `InitializeAppAction`, subscribe before connecting or discovering, then dispatch authoritative SDK snapshots. Do not dispatch duplicate snapshots after commands.
- Catch and report unexpected command exceptions at the operation boundary. Report stream errors without reconnecting or inventing state. Ignore late SDK updates after shutdown starts; never reopen the SDK operation guard.
- Do not add an action registry, command bus, second SDK runtime, or mandatory pass-through layer.

## Selectors, ViewModels, and widgets

- Selectors are the sole path for reading or deriving Redux state for presentation. Start with one trainer-level selector class. Keep selectors pure: select fields, read/write results, edit eligibility, and other derived values without GetIt, dispatch, I/O, widget logic, a selector framework, or premature memoization. Selectors may group related selected values into Dart records when useful, but must not require presentation-only entities or wrappers.
- Each widget that independently consumes Redux owns exactly one dedicated ViewModel used exclusively by that widget. The widget contains its own `StoreConnector<AppState, ViewModel>`; do not introduce connector-only widgets, share ViewModels between widgets, or pass one widget's ViewModel to another. Widgets without independent Redux responsibilities do not need ViewModels.
- A connected widget may receive the store inside its `StoreConnector` converter solely to pass it to its GetIt-registered ViewModel factory. Its builder consumes only ViewModel fields and invokes ViewModel callbacks for Redux actions. Otherwise, widgets must not read `store.state`, invoke selectors, dispatch Redux actions, or resolve Redux/SDK services through GetIt. The connector's `AppState` generic parameter is wiring, not permission to expose state.
- ViewModels expose selector results needed by their owning widget, not whole Redux state or unrelated data. Reuse SDK types such as `GameField` and `GameReadResult` where helpful. Do not create UI entities, duplicate SDK models, or add records and wrappers just to transport values. Simple display formatting belongs in the widget or a focused reusable utility. ViewModels expose final callbacks, not operation methods, policy, filtering, or subscriptions.
- Use `StoreConnector(distinct: true)` and include every presentation-relevant ViewModel field in `Equatable.props` while excluding callback identity. Do not include unrelated Redux state merely to simplify access or equality.
- Presentation children are optional, not a mandatory layer. Extract them only for meaningful visual responsibilities, and pass ordinary values, SDK objects, and callbacks, never the parent's ViewModel. A child that independently consumes Redux instead owns its own ViewModel and `StoreConnector`. Keep one connected field-list widget with generic presentational rows keyed by stable field ID; rows do not need ViewModels merely for display.
- Keep meaningful visual components in named `Widget` classes in focused files. Do not hide them in private visual subclasses or private widget-returning builders. Do not create wrappers or layers without a responsibility.

## Synchronous write bridge

- Preserve synchronous `GameWriteResult` handling through one small bridge using the same registered capability as middleware. Expose it as a final callback on the appropriate ViewModel and check the shared one-way SDK operation guard before the call.
- If the guard is closed, return synchronously without calling the SDK, using its defined unsuccessful sentinel:

  ```dart
  GameWriteResult(
    status: GameWriteStatus.none,
    fieldId: fieldId,
    requestedValue: value,
  )
  ```

- Never invent SDK result constructors, statuses, or success; do not call the SDK after the guard closes, convert writes to fire-and-forget actions, infer success from dispatch, or dispatch cancellation from the bridge.
- `InlineValueEditor.onApplied` runs only after a successful write or existing unchanged-value behavior; it dispatches the edit-cancellation action for the reducer. Failed writes retain a valid draft and show SDK feedback. Preserve unchanged-value behavior and synchronous stream reentrancy. Flutter does not repeat the SDK's full write-validation matrix.

The SDK remains responsible for current process/session identity, executable hash, profile and field evidence, memory base, user approval, type/range, complete preliminary read, complete native transfer, and matching read-back. Failed/partial reads are not zero. Unsupported, stale, ambiguous, or unverified targets fail closed according to the [game detection](features/game-detection.md) and [game memory](features/game-memory.md) contracts.

## Initialization and native shutdown

- Configure native-window lifecycle handling before dispatching `InitializeAppAction`. Initialize middleware through that action; subscribe before connection/discovery. Initialization is idempotent and cannot restart the SDK after shutdown begins. Do not call middleware lifecycle methods directly.
- On shutdown, close the shared one-way SDK operation guard immediately before dispatching global `ShutdownRequestedAction`. Keep Redux dispatch available; do not globally disable it.
- `ShutdownRequestedAction` exposes `addCleanup(Future<void>)` and `waitForCleanup()` as its explicit cleanup contract. Only middleware that owns cleanup registers its future synchronously through `addCleanup` during dispatch; preserve next-first middleware order. Convert synchronous cleanup invocation or registration failures into failed futures so other middleware can still register. `waitForCleanup()` must await every attempt and surface every failure without short-circuiting SDK disposal.
- After middleware cleanup settles, attempt SDK disposal exactly once and await it before allowing native close. Report disposal errors through close-failure handling. Do not race disposal with active observation, dispose the SDK through GetIt, or depend on widget disposal as the primary path.
- `LudavaApp` owns native-window lifecycle state. It coalesces overlapping close requests, honors native-close veto, shows close failure, and allows retry. A retry does not repeat cleanup or recreate resources. If native close fails, the app stays terminal and the store remains alive while the UI is mounted; disposed SDK resources are never reused.
- Tree-disposal cleanup is a fallback: if shutdown has not started, close the guard and dispatch the same shutdown action; then await the same registered middleware cleanup and terminal SDK-disposal future. Begin observation cancellation only once.
- During shutdown and after a failed native close, use an application-level `AbsorbPointer` plus `ExcludeFocus` around the trainer content to disable interaction without layout shifts. Preserve accessible shutdown status and keep the close-retry control reachable outside the blocked subtree; do not block global Redux dispatch.
- Window buttons receive callbacks from the close coordinator and keep minimize, maximize, and restore behavior.

## Migration test ownership

Follow the shared [testing conventions](TESTING.md) for naming, fixtures, safety cases, and isolation. Each behavior is tested by its current owner:

| Test area | Owns |
| --- | --- |
| Reducers | No-op identity, eligibility, snapshot replacement, same-session draft preservation, the failed-read exception, and stale-session invalidation. |
| Middleware | Action routing, refresh/process selection, stream projection, subscribe-before-connect, idempotent initialization, error reporting, and terminal guards. |
| Lifecycle | Startup idempotence, cleanup collection/failures, exactly-once disposal, native veto, close failure/retry, overlapping requests, tree-disposal fallback, shutdown interaction/focus gating, and store lifetime. |
| Write bridge | Synchronous results, failures, shutdown rejection, and reentrant SDK events. |
| Selectors/ViewModels | Nontrivial selection and projection of presentation data, exposed ViewModel values, and action callbacks. Test custom equality inputs only for a distinct Ludava regression risk, not Equatable itself. |
| Dependency injection | Root/feature registrations, exactly-once initial SDK snapshot read, eager store identity, one SDK capability, isolated GetIt scopes, and lifetime ownership. |
| Widgets | Ludava-owned rendering, interactions, editing, local draft/focus, keyboard behavior, fixed geometry, stable dynamic fields, accessibility, and shutdown interaction—not Flutter Redux's rebuild behavior. |

- Test reducers and selectors without GetIt. Use fake SDK capabilities and isolated GetIt scopes when those seams matter to the Ludava behavior under test; do not test framework registration or lookup mechanics for their own sake.
- Test each widget's own rendering, interaction, layout, and callback behavior with controlled ViewModel values where useful. Mocktail may isolate a ViewModel through its existing GetIt factory without generated mocks. A minimal `StoreProvider` may be supplied as connector plumbing; do not run actual reducers, middleware, or SDK session transitions solely to test static presentation. Mocking is optional, not a test requirement.
- Do not write tests to prove `StoreConnector(distinct: true)` suppresses rebuilds, that Equatable compares props, or that GetIt resolves registrations. Test our selector projections, action callback wiring, and selected equality inputs only when a specific Ludava regression warrants it. Do not replace removed dependency-behavior tests with equivalent mock tests or add test cases to preserve test counts.
- Preserve safety, write, editing, lifecycle, accessibility, and layout regression coverage at the component that owns each behavior; do not repeat SDK policy or a child's tests through a parent. Enforce boundaries through conventions, focused tests, and PR review rather than a new custom checker. Follow [shared testing conventions](TESTING.md#naming-and-placement) for test paths and behavior ownership. The migration must pass the [documented Flutter analysis and test commands](DEVELOPMENT.md#workspace-development-and-ci).

## Organization and references

Use this as a placement guide, not a required empty scaffold:

```text
apps/ludava_app/lib/
├── injection_container.dart
├── shared/state/                 # app state, actions, reducer, store creation
└── features/trainer/
    ├── trainer.injection_container.dart
    ├── services/                 # SDK capability
    └── presentation/state/       # trainer state/actions/reducer/middleware/selectors/ViewModels
```

Reference implementations can inform organization and lifecycle: [Flutter starter root container](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/injection_container.dart), [feature container](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/features/github_explorer/github_explorer.injection_container.dart), [store construction](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/shared/state/create_store.dart), [DovahLink store and SDK observation middleware](https://github.com/Soneka96/DovahLink/tree/main/app/lib/shared/state), and [WorthLoop feature middleware](https://github.com/Soneka96/worthloop/tree/main/lib/features/products/presentation/state). Ludava's approved rules take precedence over every reference. Keep Flutter state and UI work scoped to existing responsibilities; SDK and Nocterm remain independent.
