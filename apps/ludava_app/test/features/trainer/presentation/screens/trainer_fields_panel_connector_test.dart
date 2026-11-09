import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel_connector.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

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

  group('Class TrainerFieldsPanelConnector dynamic fields behavior', () {
    testWidgets(
      'Class TrainerFieldsPanelConnector preserves stable field keys',
      (tester) async {
        final initialSession = trainerStateFixtureSession(
          additionalFieldIds: ['scrap'],
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );
        final store = sl<Store<AppState>>();
        store.dispatch(TrainerSessionChangedAction(initialSession));

        await tester.pumpWidget(_wrap(store));
        expect(find.byKey(const ValueKey('credits')), findsOneWidget);
        expect(find.byKey(const ValueKey('scrap')), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('Unavailable'), findsOneWidget);

        final updatedSession = trainerStateFixtureSession(
          additionalFieldIds: ['scrap'],
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 31,
          ),
        );
        store.dispatch(TrainerSessionChangedAction(updatedSession));
        await tester.pump();

        expect(find.byKey(const ValueKey('credits')), findsOneWidget);
        expect(find.text('31'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerFieldsPanelConnector dispatches an eligible edit',
      (tester) async {
        final session = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );
        final store = sl<Store<AppState>>();
        store.dispatch(TrainerSessionChangedAction(session));

        await tester.pumpWidget(_wrap(store));
        await tester.tap(find.byTooltip('Edit Credits'));
        await tester.pump();

        expect(store.state.trainer.editingFieldId, 'credits');
        expect(
          find.byKey(const ValueKey('inline-editor-input-credits')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerFieldsPanelConnector routes write results to the matching row',
      (tester) async {
        final initialSession = trainerStateFixtureSession(
          additionalFieldIds: ['scrap'],
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );
        final store = sl<Store<AppState>>();
        store.dispatch(TrainerSessionChangedAction(initialSession));
        await tester.pumpWidget(_wrap(store));

        store.dispatch(const BeginEditingAction('credits'));
        store.dispatch(
          TrainerSessionChangedAction(
            trainerStateFixtureSession(
              additionalFieldIds: ['scrap'],
              readResult: const GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'credits',
                value: 25,
              ),
              lastWriteResult: const GameWriteResult(
                status: GameWriteStatus.writeFailed,
                fieldId: 'credits',
                requestedValue: 31,
              ),
            ),
          ),
        );
        await tester.pump();

        final creditsRow = tester.widget<TrainerFieldRow>(
          find.byKey(const ValueKey('credits')),
        );
        final scrapRow = tester.widget<TrainerFieldRow>(
          find.byKey(const ValueKey('scrap')),
        );
        expect(creditsRow.writeResult?.fieldId, 'credits');
        expect(scrapRow.writeResult, isNull);
      },
    );
  });
}

Widget _wrap(Store<AppState> store) => StoreProvider<AppState>(
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: TrainerFieldsPanelConnector()),
  ),
);

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  @override
  TrainerSessionState get state => TrainerSessionState();

  @override
  Stream<TrainerSessionState> get stateChanges => const Stream.empty();

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => false;

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);

  @override
  Future<void> dispose() async {}
}
