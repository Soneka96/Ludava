import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_status.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

GameProfile _profile() => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
  executableHash: 'PPU-synthetic-hash',
  readStatus: VerificationStatus.experimental,
);

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

/// Configures a widget test at the approved minimum desktop dimensions.
void _setMinimumWindowSize(WidgetTester tester) {
  tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Builds a session snapshot with the requested detection outcome.
TrainerSessionState _state({
  required GameDetectionStatus status,
  required int processId,
  GameProfile? profile,
  String? gameTitle,
  int? memoryBase,
}) => TrainerSessionState(
  processIds: [processId],
  selectedProcessId: processId,
  detection: GameDetectionResult(
    status: status,
    processId: processId,
    gameTitle: gameTitle,
    profile: profile,
    confidence: status == GameDetectionStatus.supportedGame
        ? GameIdentityConfidence.confirmed
        : GameIdentityConfidence.none,
    evidenceDescription: 'Test detection evidence.',
  ),
  memoryBase: memoryBase,
);

void main() {
  group('Class TrainerGameHeader session display behavior', () {
    testWidgets(
      'Class TrainerGameHeader renders one accessible refresh control with readiness',
      (tester) async {
        _setMinimumWindowSize(tester);
        final profile = _profile();
        final state = _state(
          status: GameDetectionStatus.supportedGame,
          processId: 321,
          profile: profile,
          memoryBase: 0x1000,
        );
        var refreshCount = 0;

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(session: state, onRefresh: () => refreshCount++),
          ),
        );

        expect(find.byType(TrainerGameIdentity), findsOneWidget);
        expect(find.byType(TrainerGameStatus), findsOneWidget);
        expect(find.text(profile.buildId), findsNothing);
        expect(find.text('RPCS3 process · PID 321'), findsNothing);
        expect(find.text('Refresh'), findsNothing);
        expect(find.text('Re-detect'), findsNothing);
        final refresh = find.byTooltip('Refresh values or rediscover RPCS3');
        expect(refresh, findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(
          tester.getSize(refresh).height,
          greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
        );
        final semantics = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel('Refresh values or rediscover RPCS3'),
          findsWidgets,
        );
        semantics.dispose();

        await tester.tap(refresh);
        expect(refreshCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerGameHeader keeps its refresh control visible beside a long title',
      (tester) async {
        const longTitle =
            'A Very Long Unsupported Game Title That Must Not Push Window Actions Off Screen';
        _setMinimumWindowSize(tester);

        await tester.pumpWidget(
          _wrap(
            TrainerGameHeader(
              session: _state(
                status: GameDetectionStatus.unsupportedGame,
                processId: 321,
                gameTitle: longTitle,
              ),
              onRefresh: () {},
            ),
          ),
        );

        expect(find.byType(TrainerGameIdentity), findsOneWidget);
        final refresh = tester.getRect(
          find.byTooltip('Refresh values or rediscover RPCS3'),
        );
        expect(refresh.right, lessThanOrEqualTo(480));
        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// Builds the header under the shipped semantic theme.
