import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app.actions.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

/// Opens the credits editor after its SDK target has been made eligible.
Future<void> _openCreditsEditor(
  WidgetTester tester,
  Store<AppState> store,
) async {
  await tester.tap(find.byTooltip('Edit Credits'));
  await tester.pump();
  expect(store.state.trainer.editingFieldId, 'credits');
}

/// Awaits observation cleanup after a panel integration test.
Future<void> _shutdownStore(Store<AppState> store) async {
  final action = ShutdownRequestedAction();
  store.dispatch(action);
  await action.waitForCleanup();
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  final StreamController<TrainerSessionState> _changes =
      StreamController<TrainerSessionState>.broadcast(sync: true);
  TrainerSessionState stateForTest = TrainerSessionState();
  TrainerSessionState? sessionDuringWrite;
  GameWriteResult? writeResult;
  int writeCalls = 0;

  @override
  TrainerSessionState get state => stateForTest;

  @override
  Stream<TrainerSessionState> get stateChanges =>
      _ControlledStateStream(_changes.stream);

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => false;

  @override
  GameWriteResult writeField(String fieldId, int value) {
    writeCalls++;
    final session = sessionDuringWrite;
    if (session != null) {
      stateForTest = session;
      _changes.add(session);
    }
    return writeResult ??
        GameWriteResult(
          status: GameWriteStatus.none,
          fieldId: fieldId,
          requestedValue: value,
        );
  }

  @override
  Future<void> dispose() => _changes.close();
}

class _ControlledStateStream extends Stream<TrainerSessionState> {
  _ControlledStateStream(this._source);

  final Stream<TrainerSessionState> _source;

  @override
  StreamSubscription<TrainerSessionState> listen(
    void Function(TrainerSessionState event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _ControlledStateSubscription(
    _source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
  );
}

class _ControlledStateSubscription
    implements StreamSubscription<TrainerSessionState> {
  _ControlledStateSubscription(this._subscription);

  final StreamSubscription<TrainerSessionState> _subscription;

  @override
  Future<void> cancel() {
    unawaited(_subscription.cancel().catchError((Object _) {}));
    return Future<void>.value();
  }

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  void onData(void Function(TrainerSessionState event)? handleData) =>
      _subscription.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => _subscription.onDone(handleDone);

  @override
  void onError(Function? handleError) => _subscription.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => _subscription.pause(resumeSignal);

  @override
  void resume() => _subscription.resume();

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _subscription.asFuture<E>(futureValue);
}

void main() {
  late _FakeTrainerSdkCapability capability;

  setUp(() {
    sl.pushNewScope();
    capability = _FakeTrainerSdkCapability();
    initDependencies(trainerSdkCapability: capability);
  });

  tearDown(() async {
    await sl.popScope();
    await capability.dispose();
  });

  Store<AppState> store() => sl<Store<AppState>>();

  Widget wrap() => StoreProvider<AppState>(
    store: store(),
    child: MaterialApp(
      theme: LudavaTheme.graphiteAndTeal,
      home: const Scaffold(body: TrainerFieldsPanel()),
    ),
  );

  group('Class TrainerFieldsPanel dynamic field behavior', () {
    testWidgets('Class TrainerFieldsPanel renders stable profile rows', (
      tester,
    ) async {
      final session = trainerStateFixtureSession(
        additionalFieldIds: ['scrap'],
        readResult: const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 0,
        ),
      );
      store().dispatch(TrainerSessionChangedAction(session));

      await tester.pumpWidget(wrap());

      final creditsRow = find.byKey(const ValueKey('credits'));
      final scrapRow = find.byKey(const ValueKey('scrap'));
      expect(find.byType(ListView), findsOneWidget);
      expect(creditsRow, findsOneWidget);
      expect(scrapRow, findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(
        tester.getTopLeft(scrapRow).dy,
        greaterThan(tester.getTopLeft(creditsRow).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldsPanel scrolls all dynamic fields', (
      tester,
    ) async {
      final fieldIds = List<String>.generate(12, (index) => 'part-$index');
      store().dispatch(
        TrainerSessionChangedAction(
          trainerStateFixtureSession(additionalFieldIds: fieldIds),
        ),
      );
      tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      final lastField = find.byKey(const ValueKey('part-11'));
      expect(lastField, findsOneWidget);
      await tester.ensureVisible(lastField);
      await tester.pumpAndSettle();
      expect(tester.getRect(lastField).bottom, lessThanOrEqualTo(340));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel preserves row geometry across states',
      (tester) async {
        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          final session = trainerStateFixtureSession(
            additionalFieldIds: ['scrap'],
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 17,
            ),
          );
          store().dispatch(const CancelEditingAction());
          store().dispatch(TrainerSessionChangedAction(session));
          await tester.pumpWidget(wrap());
          final rowFinder = find.byKey(const ValueKey('credits'));
          final siblingRowFinder = find.byKey(const ValueKey('scrap'));
          final normalRow = tester.getRect(rowFinder);
          final normalSiblingRow = tester.getRect(siblingRowFinder);
          expect(normalRow.height, LudavaDimensions.minimumInteractiveTarget);
          expect(
            normalSiblingRow.height,
            LudavaDimensions.minimumInteractiveTarget,
          );

          store().dispatch(const BeginEditingAction('credits'));
          await tester.pump();
          await tester.pump();
          expect(find.byType(InlineValueEditor), findsOneWidget);
          expect(tester.getRect(rowFinder), normalRow);
          expect(tester.getRect(siblingRowFinder), normalSiblingRow);

          store().dispatch(
            TrainerSessionChangedAction(
              trainerStateFixtureSession(
                additionalFieldIds: ['scrap'],
                readResult: const GameReadResult(
                  status: GameReadStatus.success,
                  fieldId: 'credits',
                  value: 17,
                ),
                lastWriteResult: const GameWriteResult(
                  status: GameWriteStatus.writeFailed,
                  fieldId: 'credits',
                  requestedValue: 42,
                ),
              ),
            ),
          );
          await tester.pump();

          expect(find.byTooltip('The write failed.'), findsOneWidget);
          expect(tester.getRect(rowFinder), normalRow);
          expect(tester.getRect(siblingRowFinder), normalSiblingRow);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel rejects denied edits and empty profiles',
      (tester) async {
        final denied = trainerStateFixtureSession(
          fieldWriteStatus: VerificationStatus.none,
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 17,
          ),
        );
        store().dispatch(TrainerSessionChangedAction(denied));
        await tester.pumpWidget(wrap());
        expect(find.byTooltip('Edit Credits'), findsNothing);

        store().dispatch(
          TrainerSessionChangedAction(
            trainerStateFixtureSession(emptyProfile: true),
          ),
        );
        await tester.pump();
        expect(
          find.text('No trainer fields are available for this profile.'),
          findsOneWidget,
        );

        store().dispatch(TrainerSessionChangedAction(TrainerSessionState()));
        await tester.pump();
        expect(find.text('Credits'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel preserves the draft through a reentrant retryable failure',
      (tester) async {
        final session = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 17,
          ),
        );
        capability.stateForTest = session;
        store().dispatch(TrainerSessionChangedAction(session));
        await tester.pumpWidget(wrap());
        store().dispatch(const InitializeAppAction());
        await tester.pump();
        await _openCreditsEditor(tester, store());
        final input = find.byKey(const ValueKey('inline-editor-input-credits'));
        await tester.enterText(input, '42');
        await tester.pump();

        final failure = const GameWriteResult(
          status: GameWriteStatus.writeFailed,
          fieldId: 'credits',
          requestedValue: 42,
          errorCode: 5,
        );
        capability
          ..writeResult = failure
          ..sessionDuringWrite = trainerStateFixtureSession(
            readResult: const GameReadResult(
              status: GameReadStatus.readFailed,
              fieldId: 'credits',
              errorCode: 5,
            ),
            lastWriteResult: failure,
          );

        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();
        await tester.pump();

        expect(capability.writeCalls, 1);
        expect(store().state.trainer.editingFieldId, 'credits');
        expect(tester.widget<TextField>(input).controller!.text, '42');
        expect(
          find.byTooltip('The write failed with system error 5.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await _shutdownStore(store());
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel removes an editor after a reentrant stale failure',
      (tester) async {
        final session = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 17,
          ),
        );
        capability.stateForTest = session;
        store().dispatch(TrainerSessionChangedAction(session));
        await tester.pumpWidget(wrap());
        store().dispatch(const InitializeAppAction());
        await tester.pump();
        await _openCreditsEditor(tester, store());
        final input = find.byKey(const ValueKey('inline-editor-input-credits'));
        await tester.enterText(input, '42');
        await tester.pump();

        final failure = const GameWriteResult(
          status: GameWriteStatus.readBackFailed,
          fieldId: 'credits',
          requestedValue: 42,
        );
        capability
          ..writeResult = failure
          ..sessionDuringWrite = trainerStateFixtureSession(
            memoryBase: 0x2000,
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 17,
            ),
            lastWriteResult: failure,
          );

        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();
        await tester.pump();

        expect(capability.writeCalls, 1);
        expect(store().state.trainer.session.memoryBase, 0x2000);
        expect(store().state.trainer.editingFieldId, isNull);
        expect(
          find.byKey(const ValueKey('inline-editor-input-credits')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await _shutdownStore(store());
      },
    );
  });
}
