import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
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

  group('Class Rpcs3ConnectionIndicator connection behavior', () {
    testWidgets('Class Rpcs3ConnectionIndicator reflects Redux process state', (
      tester,
    ) async {
      await tester.pumpWidget(
        StoreProvider<AppState>(
          store: sl<Store<AppState>>(),
          child: MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: const Scaffold(body: Rpcs3ConnectionIndicator()),
          ),
        ),
      );
      expect(find.byTooltip('RPCS3 not detected'), findsOneWidget);

      sl<Store<AppState>>().dispatch(
        TrainerSessionChangedAction(TrainerSessionState(processIds: [42])),
      );
      await tester.pump();

      expect(
        find.byTooltip('RPCS3 detected · awaiting process selection'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class Rpcs3ConnectionIndicator renders the selected process from its ViewModel',
      (tester) async {
        final store = sl<Store<AppState>>();
        await tester.pumpWidget(
          StoreProvider<AppState>(
            store: store,
            child: MaterialApp(
              theme: LudavaTheme.graphiteAndTeal,
              home: const Scaffold(body: Rpcs3ConnectionIndicator()),
            ),
          ),
        );

        store.dispatch(
          TrainerSessionChangedAction(
            TrainerSessionState(processIds: [42], selectedProcessId: 42),
          ),
        );
        await tester.pump();
        expect(find.byTooltip('RPCS3 connected · process 42'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );
  });
}

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
