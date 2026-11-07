import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerGameIdentity presentation behavior', () {
    testWidgets('Class TrainerGameIdentity shows build and process context', (
      tester,
    ) async {
      final profile = GameProfileCatalog.profiles.first;
      final session = _session(
        status: GameDetectionStatus.supportedGame,
        processId: 321,
        profile: profile,
      );

      await tester.pumpWidget(_wrap(TrainerGameIdentity(session: session)));

      expect(find.text(profile.gameName), findsOneWidget);
      expect(
        find.text('${profile.buildId} · RPCS3 process · PID 321'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Class TrainerGameIdentity wraps long titles without truncation',
      (tester) async {
        const title =
            'An Unsupported Game Name That Remains Discoverable at Narrow Widths';
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 260,
              child: TrainerGameIdentity(
                session: _session(
                  status: GameDetectionStatus.unsupportedGame,
                  processId: 321,
                  title: title,
                ),
              ),
            ),
          ),
        );

        final titleWidget = tester.widget<Text>(find.text(title));
        expect(titleWidget.maxLines, isNull);
        expect(titleWidget.overflow, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

TrainerSessionState _session({
  required GameDetectionStatus status,
  required int processId,
  GameProfile? profile,
  String? title,
}) => TrainerSessionState(
  processIds: [processId],
  selectedProcessId: processId,
  detection: GameDetectionResult(
    status: status,
    processId: processId,
    profile: profile,
    gameTitle: title,
    confidence: status == GameDetectionStatus.supportedGame
        ? GameIdentityConfidence.confirmed
        : GameIdentityConfidence.none,
    evidenceDescription: 'Test detection evidence.',
  ),
);
