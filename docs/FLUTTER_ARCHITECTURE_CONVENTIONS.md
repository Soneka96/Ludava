# Flutter architecture conventions

This document defines the approved future Redux architecture for
`apps/ludava_app`. It is the authoritative Flutter-specific contract, not
authorization to implement the migration. The checked-in app currently uses
`TrainerController`; Redux is future implementation until its separate
migration is approved and lands. The Nocterm TUI and SDK remain independent of
Flutter, Redux, and GetIt.

Repository-wide ownership, style, and testing rules remain in
[`ARCHITECTURE.md`](ARCHITECTURE.md) and [`DEVELOPMENT.md`](DEVELOPMENT.md).
This document owns the Flutter Redux decisions below.

## 1. Scope and SDK authority

The migration replaces Flutter's `TrainerController` completely. Do not keep a
second state-management system or permanent compatibility controller. The
current controller is evidence of existing behavior and safety rules; it is
not the target architecture. Preserve the existing UI, SDK behavior, and
native-window behavior during migration.

The SDK remains authoritative for RPCS3 discovery, process identity and start
time, detection and confidence, profile and executable hash, memory base,
fields, reads, write eligibility, guarded writes, verification, and
`GameWriteResult`. Reuse SDK types. Do not duplicate these facts or policies in
Flutter, modify the SDK to make `TrainerSessionState` structurally equatable,
or add pass-through repositories, datasources, or use cases around SDK calls.
Add an application-owned layer only when it owns meaningful behavior such as
preferences, persistence, or a future backend.

`TrainerState` holds the complete current `TrainerSessionState` snapshot and
`editingFieldId`. It does not copy SDK-owned facts. The numeric draft, text
controller, cursor, and focus stay local to the editor.

## 2. GetIt and application composition

Use GetIt only in `apps/ludava_app`. The root `injection_container.dart`
registers shared app services, then initializes per-feature containers such as
`features/trainer/trainer.injection_container.dart` in dependency order. Put
the Flutter SDK capability interface and adapter under the trainer feature's
`services/` directory. Register exactly one `TrainerSdkCapability`; do not
also expose or register the underlying `LudavaSdk` independently.

Register exactly one eagerly constructed `Store<AppState>` singleton in
GetIt. Pass its initial `AppState` explicitly to `CreateStore`; that factory
must not resolve SDK state through GetIt. Construct reducers and middleware
directly and wire them into `CreateStore`; reducers and middleware are not
GetIt registrations. Middleware resolves its SDK service through `sl` and
uses it directly. Do not create a command bus or inject pass-through layers.

Register each ViewModel as a GetIt `registerFactoryParam` whose parameter is
only `Store<AppState>`. Its `.fromStore(Store<AppState> store)` constructor
receives only that store. The `LudavaApp` composition root resolves app
services from GetIt; remove obsolete controller and SDK constructor overrides
when implementing the migration, while retaining mocked testability through
isolated GetIt scopes. Native-window buttons receive ordinary callbacks from
`LudavaApp`; they do not resolve GetIt or dispatch Redux actions themselves.

Reducers and selectors never access GetIt. Generic widgets do not access
Redux, GetIt, or SDK services. The only service lookup allowed in a ViewModel
is a final callback for the synchronous write bridge described in §6; it must
not issue ordinary SDK commands.

Use the smallest layer that owns a real responsibility. The owner starter's
root and feature containers, store, GitHub Explorer state/reducer/middleware/
selectors/ViewModel, DovahLink's store and SDK-observation lifecycle, and
WorthLoop's feature middleware are conventions references. Reuse their
relevant patterns without importing unrelated persistence, navigation, or
feature architecture:

- [Flutter Clean Architecture Starter: root and feature containers](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/injection_container.dart)
- [Starter: GitHub Explorer feature container](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/features/github_explorer/github_explorer.injection_container.dart)
- [Starter: `create_store.dart`](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/shared/state/create_store.dart), [`app.state.dart`](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/shared/state/app.state.dart), and [`app.reducer.dart`](https://github.com/Soneka96/flutter-clean-architecture-starter/blob/main/lib/shared/state/app.reducer.dart)
- [Starter: GitHub Explorer state](https://github.com/Soneka96/flutter-clean-architecture-starter/tree/main/lib/features/github_explorer/presentation/state)
- [DovahLink: store and composition](https://github.com/Soneka96/DovahLink/tree/main/app/lib/shared/state)
- [DovahLink: SDK observation middleware](https://github.com/Soneka96/DovahLink/blob/main/app/lib/features/live_state/presentation/state/live_state.middleware.dart)
- [WorthLoop: product feature middleware](https://github.com/Soneka96/worthloop/tree/main/lib/features/products/presentation/state)

## 3. Store, state, actions, and reducers

Create one eager `Store<AppState>` for the app lifetime. `CreateStore` receives
the explicit initial state, root reducer, and middleware list; use
`distinct: true`. Combine feature reducers with `combineReducers` and
`TypedReducer`. Do not add Redux middleware or frameworks without an approved
responsibility.

`AppState`, feature states, and ViewModels extend `Equatable` and define
explicit `props`. Actions are plain typed immutable classes, not `Equatable`.
The mutable cleanup collection on `ShutdownRequestedAction` is the deliberate
exception. Use `shared/state/app.actions.dart` for global
`InitializeAppAction` and `ShutdownRequestedAction`; trainer actions belong to
the trainer feature. `BeginEditingAction` carries only `fieldId`; the reducer
resolves the field from the authoritative session.

SDK-owned errors remain in the SDK snapshot and selectors read them there;
do not copy them into Redux fields. `TrainerSessionState` is not structurally
equatable, so use the SDK's object identity contract rather than changing the
SDK or adding deep snapshot comparison.

An action may be handled by middleware, a reducer, both where each has a real
responsibility, or neither. Do not add artificial forwarding or
request/success/failure actions when an authoritative SDK snapshot already
expresses the result.

Reducers are pure immutable transitions: no GetIt, SDK commands, I/O, or
widget calls. Reconcile a session snapshot and any edit invalidation
atomically. Return the original feature or root state object for a no-op.
Ignore identical SDK snapshot objects; do not deep-compare snapshots solely
for Redux equality.

Beginning an edit uses the SDK's existing write-eligibility rule. When a new
snapshot arrives, retain the edit only if the selected process ID and start
time, detection status and confidence, selected profile, executable hash, and
memory base still match, the field still exists, and the SDK still reports a
valid write target. Preserve the existing failed-read/write-result exception:
a failed read for the edited field does not alone discard its draft when
`lastWriteResult.fieldId` identifies that field. Any stale or invalid target
still invalidates editing. Do not weaken these checks or duplicate SDK write
authorization in Flutter.

## 4. Middleware and SDK observation

Middleware owns SDK commands and SDK session observation. For each intercepted
action, use `switch (action)` with exactly one dedicated private handler named
by dropping `Action` and lower-camel-casing the rest, for example
`RefreshTrainerAction` → `_refreshTrainer()`. Keep substantive work out of
switch cases. Do not merge unrelated actions into generic handlers. Follow
the owner's next-first middleware convention. Each layer handles an action
only for its own responsibility.

Trainer refresh preserves both current paths: with no selected process, call
SDK discovery/connect; with a selected process, call SDK refresh. Process
selection uses its typed action. Catch and report unexpected SDK command
exceptions at the middleware operation boundary. Do not manually dispatch
session updates after SDK commands.

`TrainerMiddleware` is the sole owner of SDK session observation. On
`InitializeAppAction`, subscribe before connecting or starting discovery;
initialization is idempotent. After the initial snapshot, stream events are
the only source of authoritative session updates. Ignore identical snapshot
objects. Report unexpected stream errors without reconnecting or inventing
session data. Ignore events after terminal shutdown begins, and never reopen
the operation guard.

Use one shared, one-way SDK operation guard. Close it immediately before
shutdown dispatch; it blocks SDK operations once shutdown begins. It does not
block Redux dispatch globally. Disable user interaction through the existing
central shell boundary and preserve its current shutdown overlay.

The adapter and its placement in `services/` are the only Flutter SDK
integration boundary. Do not add a second runtime, command bus, or mandatory
SDK repository/use-case/datasource wrappers.

## 5. Selectors, ViewModels, and widget connections

Use one feature-level selector class, such as `TrainerSelectors`, until a
meaningful reason to split it arises. Selectors own state selection,
filtering, and derived presentation calculations. They are pure and do not
resolve GetIt, call SDK commands, or perform I/O.

Every widget that directly consumes Redux owns its `StoreConnector` and a
widget-specific ViewModel. Use `distinct: true`. A ViewModel is `Equatable`
with explicit `props`, final presentation properties, and final callback
fields. Its equality includes the presentation values relevant to that widget
so unchanged views do not rebuild; callback identity does not determine
equality. Keep it thin: no operation methods, complex filtering, business
rules, subscriptions, or SDK calls. Its `.fromStore(store)` receives only
`Store<AppState>`; factory registration is in §2. The synchronous write
callback is its only permitted service-resolving callback.

Generic presentation widgets receive ordinary typed properties and callbacks;
they do not need a ViewModel or connector. Use one connected field-list widget
and ordinary presentational rows, not a ViewModel per row. Preserve dynamic
row identity with stable field-ID keys. Keep the numeric draft and focus local
to the editor.

## 6. Synchronous writes and editing safety

The write bridge calls the same registered SDK capability used by middleware,
checks the terminal operation guard, and synchronously returns the real
`GameWriteResult`. A widget-specific ViewModel may expose a final `onApply`
callback that resolves this bridge through GetIt. The generic inline editor
does not import Redux or GetIt and does not execute ordinary SDK commands.

The editor invokes `onApplied` only after a successful synchronous result, or
for its existing unchanged-value behavior. That callback dispatches editing
cancellation; the reducer applies it. The bridge does not dispatch
cancellation. A failed result keeps the draft and displays SDK feedback. A
stale session remains an independent reducer invalidation rule. Preserve
synchronous SDK stream reentrancy and the special failed-read/write-result
draft-preservation behavior in §3. Do not guess success, retry a write, or
repeat the SDK's write-validation matrix in Flutter.

## 7. Initialization, shutdown, and native-window lifetime

The application owns initialization, native-window shutdown, and store
lifetime. Native-window lifecycle state remains in `LudavaApp`, not Redux.
`LudavaApp` first resolves its services and obtains the current SDK snapshot.
Construct and eagerly register the one store using that explicit snapshot.
Configure native-window lifecycle handling, then dispatch
`InitializeAppAction`. Relevant middleware subscribes before connection/
discovery begins. Initialization is idempotent and must not reconnect after
shutdown starts.

Shutdown uses the global `ShutdownRequestedAction`, intercepted only by
middleware that owns cleanup. During synchronous dispatch, each participant
registers its cleanup future on the action. This is the explicit cleanup
collection mechanism; do not add a middleware registry, command bus, or direct
application-to-middleware shutdown calls. Each middleware prevents duplicate
cancellation and new subscriptions after shutdown starts. The application
awaits the collected futures as a group, without depending on middleware
registration or execution order. After dispatch,
await every registered cleanup even if another fails, and report every
failure without hiding other cleanup errors.

After cleanup settles, attempt SDK disposal exactly once, await it, and report
its errors while preserving the existing native-close error handling and
sequence. Keep the Redux store alive until application teardown, including
when native close fails and the Flutter UI stays mounted. Preserve the
existing central interaction boundary, focus and geometry behavior, close
veto handling, visible retry path, and terminal state after close failure.
Tree-disposal fallback shares the terminal disposal future. Retries do not
repeat SDK cleanup or recreate resources. Native-window buttons use callbacks
from `LudavaApp`; they do not bypass the close coordinator. Preserve native
minimize, maximize, and restore behavior.

The migration must preserve exactly one Refresh button; current process
selection; Graphite and Teal theme conventions; fixed-height 48-pixel field
rows; local numeric drafts; Enter/check apply; Escape/cross cancel; success
verification and failed-write feedback; and no layout shifts or unnecessary
focus changes. Keep Nocterm and SDK behavior independent.

## 8. Testing and migration acceptance

Tests belong to meaningful behavior owners. Do not add tests for behaviorless
types or remove existing tests to reduce migration work. Pure reducer and
selector tests do not use GetIt. Tests that require GetIt use isolated scopes.
Use mocked `TrainerSdkCapability` dependencies for Flutter responsibilities;
do not repeat SDK-owned write-validation tests.

- **Reducers:** pure actions, equality and no-op identity, eligibility,
  snapshot replacement, same-session edit preservation, failed-read exception,
  and invalidation for every session-safety condition.
- **Middleware:** action routing, refresh path, process selection, stream
  projection, subscribe-before-connect, idempotent initialization, stream and
  command error reporting, and terminal operation guards.
- **Lifecycle:** startup idempotence; cleanup collection; awaiting all cleanup
  and reporting all failures; exactly-once SDK disposal; native veto; close
  failure and retry; overlapping-close coalescing; tree-disposal fallback
  sharing the terminal disposal future; and store lifetime.
- **Synchronous write bridge:** real result propagation, failure handling,
  shutdown rejection, and reentrant SDK events.
- **Selectors and ViewModels:** derived values, callback dispatch,
  `Equatable.props`, and widget-level connector behavior.
- **Widgets:** inline editing, local draft and focus, keyboard behavior, fixed
  geometry, stable dynamic field lists, and existing shutdown interaction.
- **DI:** root and feature registrations, eager store identity, one SDK
  capability, isolated test scopes, and correct lifetime ownership.

Mirror production paths under `apps/ludava_app/test/` and name tests after
production files. The implementation PR must retain existing tests and pass
the documented Flutter analyze and test commands in [`DEVELOPMENT.md`](DEVELOPMENT.md).

The approved migration's baseline organization is:

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

Treat this as a baseline, not a reason to create empty directories or
speculative layers. Keep the migration focused on the existing app and
responsibilities above. Approval of this document is not approval to begin
implementation; wait for the separate owner approval after documentation
review.
