# Flutter architecture conventions

This document is the implementation contract for the approved Flutter Redux
migration. It defines responsibilities and compatibility requirements for
`apps/ludava_app`; it does not authorize implementing Redux before the owner
approves this documentation. The current app still uses `TrainerController`.
Until a separately approved implementation changes it, that is the checked-in
behavior.

The repository-wide feature boundaries, SDK safety rules, Dart style and test
ownership remain defined by [architecture](ARCHITECTURE.md) and
[development](DEVELOPMENT.md). This document owns their Flutter Redux details.

## 1. Scope and migration boundary

Ludava is a compact Windows trainer, not a general-purpose dashboard. The
migration replaces only the Flutter `TrainerController` presentation-state and
command orchestration responsibilities with Redux state, middleware,
selectors, and widget-specific ViewModels. It preserves the existing widgets,
layouts, user interaction, SDK behavior, and native-window lifecycle.

The Nocterm TUI is outside this migration. Do not edit it, add Redux to it, or
move its behavior into the Flutter app. Do not add empty feature layers,
frameworks, generic dispatchers, or helpers without a concrete responsibility.

The binding choices here intentionally supersede the older Flutter-specific
statements in `ARCHITECTURE.md` and `DEVELOPMENT.md` that prohibit Redux or put
Flutter trainer editing state in `TrainerController`. Those statements are
updated to describe the approved migration. This exception does not change the
SDK authority or the TUI architecture.

## 2. SDK and Flutter responsibilities

`ludava_sdk` remains the only authority for:

- RPCS3 discovery, process identity and process metadata.
- Game detection, executable hashes, game profiles and supported fields.
- Memory-base resolution, reads, read outcomes and write results.
- Write eligibility policy, live-target revalidation, guarded write execution,
  verification and read-back.
- The complete authoritative `TrainerSessionState` snapshot.

Flutter renders SDK facts, owns transient UI interaction state, and sends user
intent to the SDK through its public typed capability. Flutter must not
recreate detection, profile matching, memory access, write authorization,
validation policy, or SDK workflows. Widgets and Redux code must not import SDK
implementation files, open native process handles, or parse formatted SDK
messages to recover business facts.

Redux is presentation state. Store the complete immutable SDK
`TrainerSessionState` as one value. Do not copy its process IDs, selected
process, game, detection, hash, memory base, field values, read outcomes, or
write results into parallel Redux fields. Keep only Flutter-owned state that
Redux needs, currently the ID of the field being edited. Keep the numeric text
draft, selection, cursor, and focus local to the input widget.

## 3. Dependency registration and injection

Use GetIt only in `apps/ludava_app` as the approved Flutter composition
mechanism. Keep SDK and TUI construction rules in their own packages. The
Flutter root container, `lib/injection_container.dart`, initializes shared
application dependencies and then calls feature registration functions such
as `features/trainer/trainer.injection_container.dart`. Register dependencies
in dependency order. A feature container registers that feature's concrete
dependencies and widget-specific ViewModel factories; it does not register
Redux reducers or middleware.

Register one app-lifetime SDK capability/service instance and inject that same
instance into `TrainerMiddleware` and the synchronous write bridge. No second
SDK runtime may be created for a widget, connector, or write path. Prefer
constructor injection for middleware collaborators and other behavior-owning
objects. Use GetIt resolution only at the composition boundary or where the
owner's established middleware convention requires it; do not resolve
dependencies from reducers, selectors, widgets, or ViewModels.

`Store<AppState>` is constructed and owned by application composition, not
registered as a global GetIt singleton. `CreateStore` receives the root
reducer, initial state, and middleware list. Keep the middleware instance in
the app-lifetime composition so the same instance can be initialized and shut
down. Reducers and middleware are not GetIt registrations. Register a
widget-specific ViewModel with `registerFactoryParam` when it needs a `Store`
parameter, then create it through `fromStore(store)`.

### Use the smallest layer that owns the behavior

- A **service** owns a real operation or coordination responsibility. The
  Flutter-facing SDK capability is the boundary for trainer operations.
- A **repository** owns a meaningful persistence or data-source policy seam.
  Do not add one around an SDK method just to match a template.
- A **datasource** owns external I/O. Flutter must not create datasources for
  RPCS3, game detection, or process memory; those remain in the SDK.
- A **use case** owns a distinct application operation or policy in its owning
  package. Do not mirror SDK use cases in Flutter or create pass-through use
  cases that add no behavior.

The starter's root/feature containers show how GetIt registration is split by
composition and feature. Its Github Explorer middleware, selectors and
`fromStore` ViewModel show the Redux pattern. WorthLoop follows the same
feature-first state organization. DovahLink's explicit store middleware list
and asynchronous shutdown coordination are useful lifecycle references.
Ludava deliberately adapts these patterns: its middleware owns a single SDK
session observation and must meet the stricter close and write guarantees in
this document. These references are examples, not permission to copy unrelated
database, navigation, or background-work architecture:

- [Flutter Clean Architecture Starter](https://github.com/Soneka96/flutter-clean-architecture-starter/tree/main/lib/shared/state)
- [Starter Github Explorer state](https://github.com/Soneka96/flutter-clean-architecture-starter/tree/main/lib/features/github_explorer/presentation/state)
- [DovahLink state and lifecycle](https://github.com/Soneka96/DovahLink/tree/main/app/lib/shared/state)
- [WorthLoop products state](https://github.com/Soneka96/worthloop/tree/main/lib/features/products/presentation/state)

## 4. Store construction and ownership

Create one `Store<AppState>` for the application lifetime through a focused
`CreateStore` class in `lib/shared/state/create_store.dart`. Pass the root
reducer directly, use `distinct: true`, and pass the initial state and
middleware explicitly. Do not add logging, thunk, persistence, or other Redux
middleware without an approved requirement.

The store starts with the current SDK snapshot, not an independently invented
copy or a later widget callback. Keep the startup order explicit:

1. Initialize Flutter bindings and dependency registration.
2. Obtain the single registered SDK capability and current session snapshot.
3. Construct one store with the root reducer, initial snapshot, and
   `TrainerMiddleware`.
4. Initialize SDK observation on that middleware.
5. Start SDK connection/discovery only after the subscription is active.
6. Render the app with the store available through `StoreProvider<AppState>`.

This order prevents missing a synchronous initial SDK state emission. Keep the
initial SDK connection out of widget `build()` and connector construction.
`CreateStore` may accept supplied initial state and middleware in the same
spirit as the owner's DovahLink store factory.

The application composition root owns the store, SDK capability, middleware,
write bridge, and their lifetimes. A route or widget does not create or dispose
them. Feature reducers are combined by `app.reducer.dart`; feature state is
nested under `AppState`.

## 5. State and action conventions

Use immutable, typed feature state. The trainer state contains:

- The latest complete `TrainerSessionState` from the SDK.
- `editingFieldId`, or `null` when no field is being edited.

Do not add duplicate flags or fields that can be selected from the SDK
snapshot. Do not put widget text controllers, unsaved input, services,
subscriptions, GetIt, native handles, or callbacks in Redux state.

Use explicit typed actions named with the `Action` suffix, such as
`RefreshTrainerAction`, `SelectProcessAction`, `TrainerSessionUpdatedAction`,
`BeginEditingAction`, and `CancelEditingAction`. Actions carry intent or the
minimum data needed to express it. Do not use string event names, anonymous
maps, generic action envelopes, or actions that only forward another action.

Do not create request/success/failure actions for synchronous SDK commands
when the next authoritative session snapshot already expresses the result.
Dispatching a command action is not proof that the SDK operation succeeded.
An action may be handled by a reducer, middleware, both when each has a real
responsibility, or neither. Do not force actions through either layer.

## 6. Middleware and side effects

`TrainerMiddleware` owns SDK commands triggered by Redux actions and the one
SDK session-state subscription. For each action it handles, use a `switch` and
call one dedicated private handler. Name the handler by removing `Action` and
converting the remaining action name to lower camel case:

| Action | Handler |
| --- | --- |
| `RefreshTrainerAction` | `_refreshTrainer()` |
| `SelectProcessAction` | `_selectProcess()` |
| `GetSettingsAction` | `_getSettings()` |
| `SavePreferencesAction` | `_savePreferences()` |

The last two rows illustrate the general naming rule; they are not a decision
to add settings actions to Ludava. Do not put action behavior in the switch
case, merge unrelated actions into a generic handler, or add a handler for an
action the middleware does not intercept.

Follow the owner's `next(action)`-first convention. This means a reducer sees
an action before middleware performs its side effect. If both layers handle
one action, document and test that order. SDK stream events can be synchronous
and reentrant: a command may publish a session snapshot that dispatches
`TrainerSessionUpdatedAction` while the original handler is still running.
Reducers must make this ordering safe; middleware must not infer success from
the original command dispatch.

Pseudocode using Dart 3 switch syntax; the middleware class, constructor, and
typed action declarations are omitted. It shows the required routing and
refresh behavior:

```dart
void call(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  switch (action) {
    case RefreshTrainerAction():
      _refreshTrainer(store);
    case SelectProcessAction(:final processId):
      _selectProcess(store, processId);
  }
}

void _refreshTrainer(Store<AppState> store) {
  if (_isShuttingDown) return;
  if (store.state.trainer.session.selectedProcessId == null) {
    _sdk.connect();
  } else {
    _sdk.refresh();
  }
}

void _selectProcess(Store<AppState> store, int processId) {
  if (_isShuttingDown) return;
  _sdk.selectProcess(processId);
}
```

The action constructors and middleware constructor are omitted from this
routing example; the method bodies show the required policy. SDK commands use
the actual synchronous API contract. Do not add `async` wrappers around
synchronous SDK commands.

### SDK observation and middleware lifetime

Subscribe before the first connection/discovery call. Middleware initialization
must be safe to call repeatedly without creating another active subscription.
Forward each authoritative SDK snapshot with a typed
`TrainerSessionUpdatedAction`. Handle stream errors through the app's normal
error-reporting path and do not manufacture a successful session. On shutdown,
mark observation terminal before awaiting cancellation, reject new setup, stop
dispatching snapshots, and share one cleanup future across repeated calls.
Middleware cancellation is an app lifecycle operation, not a fabricated UI
action. The middleware must never dispose the SDK.

The subscription is app-lifetime and belongs to the store's middleware, not a
screen or `StoreConnector`. A route change must not drop state observation.

## 7. Reducers and session safety

Reducers implement deterministic, pure state transitions. They do not call
the SDK, perform I/O, access GetIt, mutate prior state, or make widget calls.
Each feature reducer changes only its feature state. Return the identical
state object when the action makes no meaningful change; the root reducer
returns the existing `AppState` when every feature slice is unchanged.

The reducer handles editing state transitions: begin an eligible edit, cancel
editing, reconcile SDK snapshots, and clear edits that no longer target the
same valid session. Beginning an edit must use the SDK's
`TrainerWriteEligibility.isWriteEligible` policy. Do not write a second
eligibility policy in Flutter. Selectors may expose that policy's presentation
result; only the SDK authorizes and revalidates a write.

When reconciling `TrainerSessionUpdatedAction`, compare the old and new session
using the existing controller's safety contract. An edit must not survive a
change in any of these:

- Selected process ID or process start time.
- Detection status or confidence.
- Selected profile ID or detected executable hash.
- Session memory base.
- Existence of the edited field in the current profile.
- SDK-approved current write target for the field.
- A failed read for that field, subject to the write-result exception below.

Apply the new SDK snapshot and any edit invalidation atomically in the same
reducer transition. Preserve an edit across an ordinary value refresh when it
is still the same valid target. Preserve the current special case for a read
failure when `lastWriteResult.fieldId` identifies the editing field: that
failure can be feedback from the attempted write, so it must not alone discard
the draft. A changed or invalid target still closes the editor. Do not weaken
these comparisons or let a presentation snapshot grant write authority.

The SDK remains responsible for authoritative checks before every write,
including process identity, process start time, detection confidence, profile
and executable identity, memory base, field approval and bounds, and guarded
read/write/read-back behavior.

## 8. Selectors

Selectors are pure functions from `AppState` to values needed for
presentation. They own selection, filtering, and derived presentation facts,
for example:

- Whether a process is selected and the connection label to display.
- Detected game display name and relevant status/error message.
- Visible profile fields and an individual field's current display value.
- Whether the SDK says a field is eligible to offer for editing.
- The current `editingFieldId`.

Do not duplicate selector calculations in ViewModels. Selectors do not resolve
GetIt services, call the SDK, or perform I/O. Keep selectors simple; do not
add caching or a selector framework without measured need.

## 9. Widget-specific ViewModels and connectors

Create a ViewModel only for a widget that directly consumes Redux. A screen,
panel, or status component may have its own ViewModel when it needs independent
state. Do not build one global trainer ViewModel and pass it through the whole
tree. Do not connect generic widgets just because an ancestor uses Redux.

Follow the owner's `fromStore(store)` factory pattern. A ViewModel is a thin
connection between selectors, action-dispatch callbacks, and the specific
widget's presentation properties. Use
`StoreConnector<AppState, WidgetSpecificViewModel>` with `distinct: true` for
Redux-aware widgets. Compare relevant presentation values for equality; do
not make callback identity determine whether a widget updates. Do not pass the
whole SDK snapshot to a widget that only needs a title or connection status.

ViewModels do not invoke SDK operations directly, call repositories, perform
substantial filtering, contain business rules, or manage subscriptions. The
synchronous write bridge described below is the explicit command exception;
keep its callback outside the generic editor and pass the typed function down
as ordinary widget data.

## 10. Generic widgets

Reusable widgets accept ordinary typed properties and callbacks. They do not
import Redux, resolve the SDK, or become store-aware because their parent is
connected. Avoid pass-through ViewModels and unnecessary connectors. Extract a
widget when it owns a meaningful visual or interaction responsibility, not
because each Redux field needs a separate class.

Follow the existing Flutter production widget rules in
[`DEVELOPMENT.md`](DEVELOPMENT.md#flutter-presentation-and-design-system):
meaningful visual components are public named widgets in focused files;
private visual widget classes and private widget-building methods are
prohibited. Private `State<T>` classes remain allowed.

## 11. Synchronous write bridge

The inline editor's apply callback remains synchronous and returns the real
`GameWriteResult`. Do not replace it with fire-and-forget Redux dispatch. A
small app-owned bridge invokes the existing guarded SDK write on the same
capability instance used by `TrainerMiddleware`. The bridge:

- Returns the SDK's actual result immediately and preserves SDK read-back
  verification.
- Checks the app's terminal shutdown gate before calling the SDK.
- Does not invent success from an action dispatch or retry the write.
- Is supplied through the composed trainer panel to the editor as its existing
  typed callback; a generic widget never resolves the SDK.

The SDK may publish a session snapshot synchronously during the write. Redux
must reconcile that update without losing a failed edit draft. A successful
write closes editing only after the SDK result confirms success; a failed
write retains editing and displays the SDK failure. Use the authoritative
snapshot's write result to transition editing once. Do not add a second write
attempt, dispatch a duplicate cancellation, or close the editor on an
unconfirmed result. If the session becomes stale, the reducer invalidates the
edit as part of its session reconciliation.

## 12. Application startup and native shutdown

Flutter composition owns startup and shutdown. Do not assign SDK teardown to a
widget's ordinary `dispose()` or a GetIt disposal callback.

At startup, complete registration, construct the SDK service and one Redux
store with the SDK's current snapshot, initialize middleware observation,
then connect/discover and render the app with the store. Do not connect before
the listener is established or from `build()`.

The existing Windows close coordinator's guarantees remain binding. On a
title-bar or native close request, the app must:

1. Coalesce overlapping close requests into one close operation and disable
   user actions immediately.
2. Await `TrainerMiddleware` subscription cancellation.
3. Start SDK disposal exactly once and await completion before native close.
4. Await disposal to completion and report any disposal error through the
   Flutter error-reporting path; never swallow or convert that error into a
   successful cleanup result.
5. After cleanup has settled, preserve the current close policy: if the native
   close request was cancelled, attempt native close even when disposal
   reported an error. Report the disposal error independently; do not claim
   disposal succeeded. If native close is rejected or fails, keep the app in
   its terminal, disabled state and expose the existing retry flow without
   reconnecting or recreating SDK resources.
6. Share the terminal SDK disposal future between the native close path,
   repeated requests, retry path, and fallback cleanup after tree removal.

Preserve the current treatment for a native close event whose cancellation
request could not be accepted. Keep the native-close failure visible and
retryable; do not falsely continue as if the event had been vetoed. Do not add
an independent GetIt disposer that could dispose the SDK twice. The app owns
window interception and the coordinator; the window controller owns native
window event observation and close requests, not Redux state.

## 13. Presentation and visual behavior

This migration is architectural; it does not redesign the product. Preserve the
compact trainer layout, Graphite and Teal theme tokens, current window
controls, process-selection behavior, and exactly one Refresh action. Preserve
the field rows' fixed 48 logical-pixel height in normal and editing states.
Editing, focus, hover, validation, and write feedback must not shift rows or
resize the window. Keep inline numeric editing, Enter/check to apply,
Escape/cross to cancel, current focus behavior, and failure feedback within
the row's existing geometry.

The SDK profile supplies the visible fields. Do not hardcode game fields or
add a second “re-detect” button. Use existing theme tokens and layout
conventions; do not introduce theme or layout systems as part of Redux wiring.
Keep screens, panels, headers, and support widgets in their existing feature
presentation directories. Add no Redux wrapper widgets that do not own a real
presentation responsibility.

## 14. Testing responsibilities

Follow the responsibility-focused test strategy in
[`ARCHITECTURE.md`](ARCHITECTURE.md#testing). Keep tests at the behavior owner,
use mocked `TrainerSdkCapability` dependencies, and avoid RPCS3 or
Windows-native infrastructure when mocks can prove the Flutter responsibility.

- **Reducers:** initial state; begin/cancel editing; SDK eligibility; snapshot
  replacement; no-op identity; preservation across same-session value
  updates; process, game, profile, hash, base, field, and failed-read
  invalidation; the write-result failed-read exception.
- **Middleware:** action routing; refresh chooses connect/discovery when no
  process is selected and selected-session refresh otherwise; process
  selection; authoritative snapshot dispatch; subscribe-before-connect
  ordering; single subscription; stream errors; idempotent cancellation; no
  dispatch or SDK operation after shutdown starts.
- **Injection and store composition:** root and feature registration order;
  store initial SDK snapshot; one shared SDK capability instance; explicit
  test overrides or isolated GetIt scope; no middleware registration and no
  double disposal.
- **Selectors and ViewModels:** correct presentation values; callbacks dispatch
  expected actions; widget-specific equality; connector distinctness; no
  duplicate selector logic.
- **Widgets and write bridge:** generic widgets work without Redux; editor
  drafts remain local; same-session refresh preserves a draft; stale sessions
  close it; failed writes retain editing and feedback; successful writes close
  only after confirmation; no duplicate attempt; fixed row geometry and focus
  behavior remain intact.
- **Lifecycle:** retain and adapt the existing native-close tests for
  overlapping requests, middleware cancellation, disposal failure, native
  close failure/retry, terminal SDK protection, and shared cleanup future.

Mirror source paths under `apps/ludava_app/test/` and name tests after the
production file. Do not remove existing tests to ease migration. Avoid
retesting SDK write authorization policy in Flutter; the SDK owns that matrix.

## 15. File organization and naming

Use feature-first organization and current Ludava Dart naming. The baseline
Redux files are:

```text
apps/ludava_app/lib/
├── injection_container.dart
├── shared/state/
│   ├── app.state.dart
│   ├── app.reducer.dart
│   └── create_store.dart
└── features/trainer/
    ├── trainer.injection_container.dart
    └── presentation/state/
        ├── trainer.state.dart
        ├── trainer.actions.dart
        ├── trainer.reducer.dart
        ├── trainer.middleware.dart
        ├── trainer.selectors.dart
        └── viewmodels/
```

Treat these as a baseline, not permission to rename unrelated files or create
empty directories. Put each meaningful state concern in the trainer feature;
put root composition in `shared/state` or the root container according to its
actual responsibility. Keep each file focused and use `.state.dart`,
`.actions.dart`, `.reducer.dart`, `.middleware.dart`, `.selectors.dart`, and
`.injection_container.dart` suffixes. Name ViewModels for their connected
widget, for example `ludava_shell.viewmodel.dart` or
`trainer_game_status.viewmodel.dart`.

## 16. Prohibited patterns

- Reimplementing SDK discovery, detection, identity, memory, read, write, or
  authorization policy in Flutter.
- Copying SDK snapshot facts into separate Redux fields.
- Registering reducers, middleware, or the store in GetIt.
- Creating duplicate SDK service/runtime instances.
- Middleware side effects inside switch cases instead of dedicated named
  handlers, or generic handlers that merge unrelated actions.
- Side effects, service lookup, mutation, or I/O in reducers and selectors.
- Redux-aware generic inputs, pass-through ViewModels, or one ViewModel for the
  entire trainer tree.
- Replacing the synchronous `GameWriteResult` bridge with fire-and-forget
  dispatch, guessing success, retrying writes, or closing an edit on failure.
- Widget-owned SDK subscription or disposal, double disposal callbacks, or
  reconnecting after shutdown starts.
- Private visual widget classes, hidden substantial widget builder methods,
  empty architecture layers, generic frameworks, and unrelated UI redesign.
- Changes to the Nocterm TUI or SDK authority/validation rules in this Flutter
  conventions migration.

## 17. Implementation acceptance criteria

The Redux implementation is ready for review only when all of these are true:

1. One app store starts from the SDK's current full session snapshot.
2. One shared SDK capability instance serves middleware and the write bridge.
3. Middleware observes SDK state before initial connect and owns an idempotently
   cancellable subscription; reducers/middleware are not GetIt registrations.
4. Middleware uses next-first switch routing and one private handler per
   intercepted action, with the specified names.
5. Reducers are pure and atomically preserve or invalidate edits using the
   existing session checks and write-result exception.
6. Selectors own derived presentation values; ViewModels remain thin,
   widget-specific `fromStore` adapters with `distinct: true` connectors.
7. Generic widgets remain independent of Redux and SDK service lookup.
8. The editor still receives a synchronous `GameWriteResult`; failed writes
   preserve draft and editing, confirmed success closes once, and stale target
   invalidation remains immediate.
9. Startup subscribes before connecting. Close requests disable interaction,
   await subscription cancellation and one SDK disposal, then attempt native
   close; failure/retry does not recreate SDK resources.
10. Existing UI, interaction, layout, theme, process-selection, Refresh, and
    window-control behavior is unchanged.
11. Responsibility-focused tests cover the behaviors in §14, existing tests
    remain, and the Flutter app's documented analyze/test commands pass.
12. The complete diff contains only approved Flutter migration code and its
    focused tests; the Nocterm TUI and SDK policy are unchanged.

## 18. Future migration checklist

Before implementation, keep this conventions document approved and use the
latest `main`. During the migration:

- [ ] Add only the Redux/GetIt dependencies and registrations needed for the
      documented design.
- [ ] Introduce root state/reducer/store and trainer state/actions/reducer/
      middleware/selectors in the documented locations.
- [ ] Wire the single SDK instance, initial snapshot, middleware observation,
      and initial connection in the required order.
- [ ] Replace `TrainerController` presentation responsibilities without
      changing SDK contracts, widgets, or application behavior.
- [ ] Add widget-specific ViewModels/connectors only where widgets consume
      Redux; keep editor draft local.
- [ ] Keep the synchronous write callback on the shared SDK capability and
      test reentrant SDK snapshot delivery.
- [ ] Adapt app shutdown to await middleware cancellation and SDK disposal
      before native close, retaining failure and retry behavior.
- [ ] Add/update tests by responsibility and retain current controller,
      editor, composition, and native-window coverage where still applicable.
- [ ] Run the documented Flutter analyze/test checks and review the complete
      diff for scope, session-safety, and UI regressions.
- [ ] Do not change the Nocterm TUI or SDK authority/validation rules.

The conventions are the prerequisite for implementation, not approval to
implement. Wait for the owner to approve this documentation before beginning
the Redux migration.
