import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

import '../../../../support/trainer_state_fixture.dart';

import '../../../../support/mock_trainer_sdk_capability.dart';


Widget _wrap(Store<AppState> store) => StoreProvider<AppState>(
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: TrainerGameHeader()),
  ),
);


void main() {
  const refreshLabel = 'Refresh values or rediscover RPCS3';
  late MockTrainerSdkCapability capability;

  setUp(() {
    sl.pushNewScope();
    capability = MockTrainerSdkCapability();
    when(() => capability.state).thenReturn(TrainerSessionState());
    initDependencies(trainerSdkCapability: capability);
  });

  tearDown(() async {
    await sl.popScope();
  });

  group('Class TrainerGameHeader connected behavior', () {
    testWidgets(
      'Class TrainerGameHeader exposes one accessible refresh action',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        final store = sl<Store<AppState>>();
        await tester.pumpWidget(_wrap(store));

        final refresh = find.byTooltip(refreshLabel);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(refresh, findsOneWidget);
        expect(find.text('Connect to RPCS3'), findsOneWidget);
        expect(
          tester.getSize(find.byType(IconButton)).width,
          greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
        );
        expect(
          tester.getSize(find.byType(IconButton)).height,
          greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
        );

        final semanticButton = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == refreshLabel,
        );
        expect(semanticButton, findsOneWidget);
        final semantics = tester.getSemantics(semanticButton);
        expect(semantics.label, refreshLabel);
        expect(semantics.flagsCollection.isButton, isTrue);
        expect(find.text('Re-detect'), findsNothing);

        await tester.tap(refresh);

        verify(() => capability.connect()).called(1);
        verifyNever(() => capability.refresh());
        expect(tester.takeException(), isNull);
        semanticsHandle.dispose();
      },
    );

    testWidgets(
      'Class TrainerGameHeader keeps title and refresh at minimum width',
      (tester) async {
        const longTitle =
            'A Very Long Synthetic Game Title That Must Stay Inside the Header';
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final store = sl<Store<AppState>>();
        store.dispatch(
          TrainerSessionChangedAction(
            trainerStateFixtureSession(gameName: longTitle),
          ),
        );
        await tester.pumpWidget(_wrap(store));

        final title = tester.widget<Text>(find.text(longTitle));
        final titleRect = tester.getRect(find.text(longTitle));
        final refreshRect = tester.getRect(find.byTooltip(refreshLabel));
        expect(title.maxLines, 1);
        expect(title.overflow, TextOverflow.ellipsis);
        expect(titleRect.left, greaterThanOrEqualTo(0));
        expect(
          titleRect.right,
          lessThanOrEqualTo(LudavaDimensions.minimumWindowWidth),
        );
        expect(refreshRect.left, greaterThanOrEqualTo(0));
        expect(
          refreshRect.right,
          lessThanOrEqualTo(LudavaDimensions.minimumWindowWidth),
        );
        expect(find.text(longTitle), findsOneWidget);

        expect(
          find.byTooltip(
            '$longTitle\nBuild ID: test-build\nRPCS3 process ID: 42',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Build ID'), findsNothing);
        expect(find.textContaining('RPCS3 process ID'), findsNothing);
        expect(find.text('Re-detect'), findsNothing);
        expect(find.byTooltip(refreshLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerGameHeader updates readiness from SDK snapshots',
      (tester) async {
        final store = sl<Store<AppState>>();
        store.dispatch(
          TrainerSessionChangedAction(trainerStateFixtureSession()),
        );
        await tester.pumpWidget(_wrap(store));
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

    testWidgets('Class TrainerGameHeader refreshes a selected SDK session', (
      tester,
    ) async {
      final store = sl<Store<AppState>>();
      store.dispatch(TrainerSessionChangedAction(trainerStateFixtureSession()));
      await tester.pumpWidget(_wrap(store));

      await tester.tap(find.byTooltip(refreshLabel));

      verifyNever(() => capability.connect());
      verify(() => capability.refresh()).called(1);
      expect(tester.takeException(), isNull);
    });
  });
}
