import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header_connector.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Class TrainerGameHeaderConnector connection behavior', () {
    testWidgets('Class TrainerGameHeaderConnector renders one refresh action', (
      tester,
    ) async {
      final actions = <Object>[];
      final store = Store<AppState>(
        (state, action) {
          actions.add(action);
          return appReducer(state, action);
        },
        initialState: AppState(
          trainer: TrainerState(session: trainerStateFixtureSession()),
        ),
      );
      await tester.pumpWidget(
        StoreProvider<AppState>(
          store: store,
          child: MaterialApp(
            theme: LudavaTheme.graphiteAndTeal,
            home: const Scaffold(body: TrainerGameHeaderConnector()),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(
        find.byTooltip('Refresh values or rediscover RPCS3'),
        findsOneWidget,
      );
      expect(find.text('Synthetic Game'), findsOneWidget);

      await tester.tap(find.byTooltip('Refresh values or rediscover RPCS3'));

      expect(actions, hasLength(1));
      expect(actions.single, isA<RefreshTrainerAction>());
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerGameHeaderConnector rebuilds readiness from snapshots',
      (tester) async {
        final store = Store<AppState>(
          appReducer,
          initialState: AppState(
            trainer: TrainerState(session: trainerStateFixtureSession()),
          ),
        );
        await tester.pumpWidget(
          StoreProvider<AppState>(
            store: store,
            child: MaterialApp(
              theme: LudavaTheme.graphiteAndTeal,
              home: const Scaffold(body: TrainerGameHeaderConnector()),
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
      },
    );
  });
}
