import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_status.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

GameProfile _profile() => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
  readStatus: VerificationStatus.experimental,
);

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

TrainerSessionState _session({
  required GameDetectionStatus status,
  GameProfile? profile,
  int? memoryBase,
}) => TrainerSessionState(
  processIds: const [42],
  selectedProcessId: 42,
  detection: GameDetectionResult(
    status: status,
    processId: 42,
    profile: profile,
    confidence: status == GameDetectionStatus.supportedGame
        ? GameIdentityConfidence.confirmed
        : GameIdentityConfidence.none,
    evidenceDescription: 'Test detection evidence.',
  ),
  memoryBase: memoryBase,
);

void main() {
  group('Class TrainerGameStatus readiness behavior', () {
    testWidgets('Class TrainerGameStatus marks a ready game as successful', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerGameStatus(
            session: _session(
              status: GameDetectionStatus.supportedGame,
              profile: _profile(),
              memoryBase: 0x1000,
            ),
          ),
        ),
      );

      expect(find.text('Ready'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Ready')).style?.color,
        LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.success,
      );
      final badge = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Ready'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((badge.decoration as ShapeDecoration).shape, isA<StadiumBorder>());
    });

    testWidgets('Class TrainerGameStatus separates unsupported from failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerGameStatus(
            session: _session(status: GameDetectionStatus.unsupportedGame),
          ),
        ),
      );
      expect(find.text('Unsupported'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Unsupported')).style?.color,
        LudavaTheme.graphiteAndTeal.extension<LudavaThemeTokens>()!.warning,
      );

      await tester.pumpWidget(
        _wrap(
          TrainerGameStatus(
            session: _session(status: GameDetectionStatus.failed),
          ),
        ),
      );
      expect(find.text('Detection failed'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Detection failed')).style?.color,
        LudavaTheme.graphiteAndTeal.colorScheme.error,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
