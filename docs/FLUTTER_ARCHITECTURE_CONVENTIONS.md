# Flutter architecture conventions

## 1. Scope and SDK authority

- **MUST** treat these rules as the approved future Redux contract for `apps/ludava_app`; this document does not authorize implementation.
- **MUST** keep the checked-in `TrainerController` as the current architecture until the separately approved migration replaces it.
- **MUST** remove `TrainerController` as the Flutter state owner when the Redux migration is implemented; **MUST NOT** retain a second permanent state-management system or compatibility controller.
- **MUST** keep RPCS3 discovery, process identity, detection, memory access, read/write authorization, verification, and `GameWriteResult` authoritative in the SDK.
- **MUST** store the complete `TrainerSessionState` snapshot directly in Redux and keep `editingFieldId` as the only trainer-specific Redux UI state.
- **MUST NOT** duplicate SDK-owned fields or policy in `TrainerState`.
- **MUST** reuse SDK types instead of creating equivalent Flutter models.
- **MUST NOT** change the SDK to make `TrainerSessionState` structurally equatable or add deep snapshot equality solely for Redux.
- **MUST NOT** implement Redux or GetIt in `ludava_sdk` or the Nocterm TUI.

## 2. Dependency injection

- **MUST** use GetIt only inside `apps/ludava_app`.
- **MUST** use one root `injection_container.dart` to register shared app services and initialize per-feature containers in dependency order.
- **MUST** place trainer-specific registrations in `features/trainer/trainer.injection_container.dart`.
- **MUST** place the Flutter SDK capability interface and adapter under the trainer feature's `services/` directory.
- **MUST** register exactly one `TrainerSdkCapability` singleton.
- **MUST NOT** register the underlying `LudavaSdk` separately from `TrainerSdkCapability`.
- **MUST** eagerly construct and register exactly one `Store<AppState>` singleton in the root composition.
- **MUST** pass the initial `AppState` explicitly to `CreateStore`; `CreateStore` **MUST NOT** resolve initial SDK state through GetIt.
- **MUST** construct reducers and middleware directly and wire them into `CreateStore`.
- **MUST NOT** register reducers or middleware in GetIt.
- **MUST** use the same store for `StoreProvider`, ViewModel factories, and lifecycle dispatches.
- **MUST** register each ViewModel with GetIt `registerFactoryParam` using only `Store<AppState>` as its runtime parameter.
- **MUST** give each ViewModel a `.fromStore(Store<AppState> store)` constructor that receives only the store.
- **MUST** have `LudavaApp` resolve app services from GetIt after migration.
- **MUST** remove obsolete controller and SDK constructor overrides from `LudavaApp` during migration.
- **MAY** resolve a genuinely needed service through `sl` inside a final ViewModel callback.
- **MUST NOT** make a ViewModel callback perform a direct SDK operation except through the synchronous write bridge in §7.
- **MUST NOT** add repository, datasource, or use-case wrappers around SDK operations without an application-owned responsibility such as preferences or backend access.
- **MUST** pass ordinary callbacks from `LudavaApp` to native-window buttons.
- **MUST NOT** let native-window buttons resolve GetIt or dispatch Redux actions themselves.

## 3. Redux store, states, actions and reducers

- **MUST** keep `AppState` and feature state immutable.
- **MUST** use `Equatable` with explicit `props` for `AppState`, feature states, and ViewModels.
- **MUST** use `combineReducers` and `TypedReducer` to compose reducers.
- **MUST** keep reducers pure: reducers **MUST NOT** resolve GetIt, call the SDK, perform I/O, or call widgets.
- **MUST** return the original state object for a genuine no-op transition.
- **MUST** reconcile each SDK snapshot and any edit invalidation atomically.
- **MUST** ignore an SDK snapshot when it is the identical object already held in state.
- **MUST** retain an active edit only while the selected process ID and process start time remain the same.
- **MUST** retain an active edit only while detection status and confidence remain the same.
- **MUST** retain an active edit only while profile ID, executable hash, and memory base remain the same.
- **MUST** retain an active edit only while its field exists and the SDK reports a valid write target.
- **MUST** preserve the failed-read/write-result exception: a failed read for the edited field alone does not invalidate its draft when `lastWriteResult.fieldId` identifies that field.
- **MUST** invalidate editing when any other session-safety condition becomes stale or invalid.
- **MUST NOT** weaken existing process, game, session, or write-target safety checks or duplicate SDK write authorization in Flutter.
- **MUST** keep SDK-owned errors in `TrainerSessionState` and have selectors read them from that snapshot.
- **MUST** use plain typed immutable actions whose names end in `Action`.
- **MUST** keep action payloads minimal.
- **MUST** make `BeginEditingAction` carry only `fieldId`; its reducer resolves the field from the authoritative session.
- **MUST** place global `InitializeAppAction` and `ShutdownRequestedAction` in `shared/state/app.actions.dart`.
- **MUST** place trainer actions inside the trainer feature.
- **MAY** give an action a reducer, middleware handler, both when each has a responsibility, or neither.
- **MUST NOT** require every action to have a reducer and middleware handler.
- **MUST NOT** add intermediate or forwarding actions when the SDK snapshot already expresses the result.
- **MUST NOT** make actions `Equatable`; the mutable cleanup collection on `ShutdownRequestedAction` is the approved exception to immutable action payloads.

## 4. Middleware and SDK observation

- **MUST** implement Redux middleware with `MiddlewareClass<AppState>`.
- **MUST** resolve the SDK capability through `sl` in middleware.
- **MUST** call `next(action)` before handling an action, following the owner's next-first convention.
- **MUST** use `switch (action)` for intercepted actions.
- **MUST** route each intercepted action to one dedicated private handler whose name removes `Action` and lower-camel-cases the remainder; for example, `RefreshTrainerAction` routes to `_refreshTrainer()` and `SelectProcessAction` routes to `_selectProcess()`.
- **MUST NOT** put substantial work inside switch cases or merge unrelated actions into generic handlers.
- **MUST NOT** handle actions for which the middleware has no responsibility.
- **MUST** preserve both refresh paths: discovery/connect when no process is selected, and SDK refresh when one is selected.
- **MUST** use the typed process-selection action for process selection.
- **MUST** catch and report unexpected SDK command exceptions at the middleware operation boundary.
- **MUST** make `TrainerMiddleware` the sole owner of SDK session observation.
- **MUST** subscribe to the SDK session stream before connecting or beginning discovery in response to `InitializeAppAction`.
- **MUST** dispatch authoritative session updates from the SDK stream.
- **MUST NOT** manually dispatch duplicate session snapshots after SDK commands.
- **MUST** report unexpected stream errors without reconnecting or inventing session data.
- **MUST** ignore late SDK updates after terminal shutdown begins.
- **MUST NOT** reopen the SDK operation guard after shutdown begins.
- **MUST NOT** introduce a generic action registry, command bus, second SDK runtime, or mandatory pass-through SDK layers.

## 5. Selectors and ViewModels

- **MUST** start with one trainer feature-level selector class, such as `TrainerSelectors`.
- **MUST** keep state selection, filtering, and derived presentation calculations in pure selectors.
- **MUST NOT** resolve GetIt, call SDK commands, or perform I/O in selectors.
- **MUST NOT** add a selector framework or memoization without a demonstrated requirement.
- **MUST** give each widget that directly consumes Redux its own `StoreConnector` and widget-specific ViewModel.
- **MUST** keep the `StoreConnector` inside the connected widget and set `distinct: true`.
- **MUST** include presentation-relevant state values in each ViewModel's `Equatable.props`.
- **MUST NOT** include callback identity in ViewModel equality.
- **MUST** expose only final presentation properties and final callback fields from a ViewModel.
- **MUST NOT** add operation methods, filtering, business rules, subscriptions, or SDK calls to ViewModels.
- **MUST NOT** create one general ViewModel for unrelated widgets.
- **MUST NOT** use any ViewModel constructor or factory argument other than `Store<AppState>`.

## 6. Generic widgets and presentation

- **MUST** keep generic presentation widgets independent of Redux, GetIt, and SDK services.
- **MUST** pass ordinary typed properties and callbacks into generic presentation widgets.
- **MUST** use one connected field-list widget with generic presentational field rows.
- **MUST** key dynamic field rows by stable field ID.
- **MUST** keep numeric drafts, text controllers, cursor selection, focus, and keyboard interaction local to the inline editor.
- **MUST NOT** create separate Redux ViewModels for generated field rows.
- **MUST NOT** define private visual `Widget` subclasses or private visual widget-builder methods.

## 7. Synchronous writes and editing

- **MUST** preserve synchronous `GameWriteResult` handling.
- **MUST** route writes through one small guarded bridge using the same registered SDK capability as middleware.
- **MUST** expose the bridge through the appropriate widget-specific ViewModel's final callback.
- **MUST** check the terminal SDK operation guard before calling the SDK.
- **MUST** return synchronously without calling the SDK when the guard is closed, using the SDK-defined unsuccessful sentinel:

  ```dart
  GameWriteResult(
    status: GameWriteStatus.none,
    fieldId: fieldId,
    requestedValue: value,
  )
  ```

- **MUST NOT** invent SDK result constructors, enum values, statuses, or successful results.
- **MUST NOT** call the SDK after the operation guard closes.
- **MUST NOT** turn writes into fire-and-forget Redux actions or infer success from dispatch.
- **MUST NOT** dispatch cancellation from the write bridge.
- **MUST** invoke `InlineValueEditor.onApplied` only after a successful write or its existing unchanged-value behavior.
- **MUST** let the `onApplied` callback dispatch the editing-cancellation action for the reducer to apply.
- **MUST** retain a valid draft and display SDK feedback after a failed write.
- **MUST** preserve unchanged-value behavior and synchronous SDK stream reentrancy during writes.
- **MUST NOT** repeat the SDK's complete write-validation matrix in Flutter.

## 8. Initialization and shutdown
- **MUST** configure native-window lifecycle handling before dispatching `InitializeAppAction`.
- **MUST** initialize middleware through `InitializeAppAction` and subscribe before connection or discovery.
- **MUST** make initialization idempotent and prevent initialization from restarting the SDK after shutdown begins.
- **MUST NOT** initialize middleware through direct application-to-middleware lifecycle calls.
- **MUST** close the shared one-way SDK operation guard immediately before dispatching global `ShutdownRequestedAction`.
- **MUST NOT** globally disable Redux dispatch during shutdown.
- **MUST** let only middleware that owns cleanup register its cleanup future on `ShutdownRequestedAction` during synchronous dispatch.
- **MUST** expose one mutable cleanup-future collection on `ShutdownRequestedAction` for those registrations; **MUST NOT** add a middleware registry, generic event bus, or second shutdown coordinator.
- **MUST** preserve next-first middleware behavior while registering shutdown cleanup.
- **MUST** catch a synchronous cleanup invocation failure and add it to the cleanup collection as a failed future so other middleware can participate.
- **MUST** catch a synchronous cleanup registration failure and add it to the cleanup collection as a failed future so other middleware can participate.
- **MUST** await every registered cleanup operation even when one fails.
- **MUST** report each cleanup failure without hiding failures from other operations.
- **MUST** attempt SDK disposal exactly once after middleware cleanup settles and await its completion before native-window close.
- **MUST** report SDK disposal errors through the existing close-failure handling.
- **MUST** preserve overlapping-close coalescing, native-close veto handling, close-failure UI, and retry behavior.
- **MUST NOT** repeat SDK cleanup or recreate resources when a native-close retry occurs.
- **MUST** keep the store alive until application teardown, including when native close fails and the UI remains mounted.
- **MUST** make application tree-disposal fallback close the operation guard and dispatch `ShutdownRequestedAction` if shutdown has not started.
- **MUST** have tree-disposal fallback await the same registered middleware cleanup before awaiting the same terminal SDK-disposal future used by native close.
- **MUST NOT** race SDK disposal against active middleware observation.
- **MUST NOT** dispose the SDK through GetIt or rely on widget disposal as the primary shutdown path.
- **MUST NOT** allow an SDK restart after shutdown begins.
- **MUST** keep native-window lifecycle state in `LudavaApp`; window buttons receive callbacks from the close coordinator and preserve minimize, maximize, and restore behavior.
- **MUST** stop new middleware subscriptions and begin cancellation only once when shutdown starts.

## 9. Testing conventions

- **MUST** test meaningful behavior at its owning Redux layer and preserve the responsibilities currently covered by `TrainerController` tests.
- **MUST** replace obsolete `TrainerController` tests with equivalent reducer, middleware, write-bridge, lifecycle, selector/ViewModel, DI, or widget tests owned by the migrated behavior.
- **MUST NOT** retain tests that only target a deleted `TrainerController` class.
- **MUST NOT** remove behavioral coverage to simplify migration.
- **MUST** test pure reducers and selectors without GetIt.
- **MUST** mock SDK dependencies in Flutter tests and use isolated GetIt scopes when injection is required.
- **MUST NOT** repeat the SDK's full write-validation matrix in Flutter tests.
- **MUST** mirror production paths under `apps/ludava_app/test/` and name tests after their production files.
- **MUST NOT** add tests for behaviorless classes solely to increase coverage.
- **MUST** cover reducer no-op identity, eligibility, snapshot replacement, same-session draft preservation, failed-read exception, and invalidation for each session-safety condition.
- **MUST** cover middleware action routing, refresh and process-selection behavior, stream projection, subscribe-before-connect ordering, idempotent initialization, command/stream error reporting, and terminal guards.
- **MUST** cover lifecycle startup idempotence, cleanup collection and failures, exactly-once disposal, native veto, close failure and retry, overlapping close requests, tree-disposal fallback, and store lifetime.
- **MUST** cover synchronous write result propagation, failure, shutdown rejection, and reentrant SDK events.
- **MUST** cover selector-derived values, ViewModel callback dispatch and equality, and connected-widget behavior.
- **MUST** cover inline editing, local draft and focus, keyboard behavior, fixed geometry, stable dynamic field lists, and shutdown interaction.
- **MUST** cover root/feature registrations, eager store identity, the single SDK capability, isolated GetIt scopes, and lifetime ownership.
- **MUST** run the documented Flutter analyze and test commands in [`DEVELOPMENT.md`](DEVELOPMENT.md) for the implementation migration.

## 10. File organization

- **MUST** keep the Redux store and global actions/state/reducer under `shared/state/`.
- **MUST** keep trainer Redux state, actions, reducer, middleware, selectors, and ViewModels inside the trainer feature.
- **MUST** use this organization as a baseline, not as a reason to create empty directories or speculative layers:

  ```text
  apps/ludava_app/lib/
  ├── injection_container.dart
  ├── shared/state/
  │   ├── app.actions.dart
  │   ├── app.state.dart
  │   ├── app.reducer.dart
  │   └── create_store.dart
  └── features/trainer/
      ├── trainer.injection_container.dart
      ├── services/
      └── presentation/state/
          ├── trainer.state.dart
          ├── trainer.actions.dart
          ├── trainer.reducer.dart
          ├── trainer.middleware.dart
          ├── trainer.selectors.dart
          └── viewmodels/
  ```

- **MAY** use the owner starter's root/feature DI, store, Redux state, reducer, selector, and ViewModel organization as a reference: [root container](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/injection_container.dart), [feature container](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/features/github_explorer/github_explorer.injection_container.dart), [store construction](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/shared/state/create_store.dart), and [GitHub Explorer state](https://github.com/Soneka96/flutter-clean-architecture-starter/tree/main/lib/features/github_explorer/presentation/state).
- **MAY** use [DovahLink's store and composition](https://github.com/Soneka96/DovahLink/tree/main/app/lib/shared/state) and [SDK observation middleware](https://github.com/Soneka96/DovahLink/blob/main/app/lib/features/live_state/presentation/state/live_state.middleware.dart) as lifecycle references.
- **MAY** use [WorthLoop's feature middleware](https://github.com/Soneka96/worthloop/tree/main/lib/features/products/presentation/state) as a middleware organization reference.
- **MUST** follow Ludava's explicit rules whenever a reference project differs from an approved decision.
- **MUST** keep the migration focused on existing app responsibilities and preserve SDK and Nocterm independence.

## 11. Migration acceptance checklist

- **MUST** preserve exactly one Refresh button and current process discovery and selection behavior.
- **MUST** preserve fixed 48-pixel field rows with no layout shifts.
- **MUST** preserve inline numeric editing, Enter/check apply, and Escape/cross cancel.
- **MUST** preserve editor focus, cursor, and keyboard behavior without unnecessary focus changes.
- **MUST** preserve SDK-authoritative field values, failed-write feedback, valid draft retention, and successful read-back display.
- **MUST** preserve same-session draft state and invalidate stale-session drafts.
- **MUST** preserve existing native-window controls, Graphite and Teal visual conventions, strict SDK disposal, and native-close retry behavior.
- **MUST** use the existing central shell interaction boundary and shutdown overlay to disable user interaction after shutdown starts.
- **MUST NOT** change runtime behavior, SDK behavior, TUI behavior, dependencies, Flutter widgets, or production code as part of this documentation contract.
- **MUST** wait for separate owner approval before beginning the Redux implementation PR.
