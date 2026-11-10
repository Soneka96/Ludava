import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

import '../../../../support/trainer_state_fixture.dart';

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

  group('Class TrainerGameHeader connection behavior', () {
    testWidgets('Class TrainerGameHeader renders one refresh action', (
      tester,
    ) async {
      final store = sl<Store<AppState>>();
      await tester.pumpWidget(
        StoreProvider<AppState>(
          store: store,
          child: MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: const Scaffold(body: TrainerGameHeader()),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(
        find.byTooltip('Refresh values or rediscover RPCS3'),
        findsOneWidget,
      );
      expect(find.text('Connect to RPCS3'), findsOneWidget);

      await tester.tap(find.byTooltip('Refresh values or rediscover RPCS3'));

      expect(capability.connectCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerGameHeader rebuilds readiness from snapshots', (
      tester,
    ) async {
      final store = sl<Store<AppState>>();
      store.dispatch(TrainerSessionChangedAction(trainerStateFixtureSession()));
      await tester.pumpWidget(
        StoreProvider<AppState>(
          store: store,
          child: MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: const Scaffold(body: TrainerGameHeader()),
          ),
        ),
      );
      expect(find.text('Ready'), findsOneWidget);

      store.dispatch(
        TrainerSessionChangedAction(
          trainerStateFixtureSession(
            detectionStatus: GameDetectionStatus.unsupportedGame,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unsupported'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  int connectCalls = 0;

  @override
  TrainerSessionState get state => TrainerSessionState();

  @override
  Stream<TrainerSessionState> get stateChanges => const Stream.empty();

  @override
  void connect() => connectCalls++;

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
