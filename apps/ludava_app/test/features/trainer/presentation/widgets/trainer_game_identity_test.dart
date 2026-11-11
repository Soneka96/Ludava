import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_game_identity.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

GameProfile _profile() => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
);

/// Builds the identity snapshot for the requested detection state.
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

/// Builds the identity widget under the shipped theme.
Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

Widget _identity(TrainerSessionState session) => TrainerGameIdentity(
  profile: session.profile,
  detectedTitle: session.detection?.gameTitle,
  processIds: session.processIds,
  selectedProcessId: session.selectedProcessId,
);

void main() {
  group('Class TrainerGameIdentity presentation behavior', () {
    testWidgets(
      'Class TrainerGameIdentity hides build and PID details in its tooltip',
      (tester) async {
        final profile = _profile();
        final session = _session(
          status: GameDetectionStatus.supportedGame,
          processId: 321,
          profile: profile,
        );

        await tester.pumpWidget(_wrap(_identity(session)));

        expect(find.text(profile.gameName), findsOneWidget);
        expect(
          find.byTooltip(
            '${profile.gameName}\nBuild ID: ${profile.buildId}\n'
            'RPCS3 process ID: 321',
          ),
          findsOneWidget,
        );
        expect(find.text(profile.buildId), findsNothing);
        expect(find.text('RPCS3 process · PID 321'), findsNothing);
      },
    );

    testWidgets(
      'Class TrainerGameIdentity truncates a long title while retaining its tooltip',
      (tester) async {
        const title =
            'An Unsupported Game Name That Remains Discoverable at Narrow Widths';
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 260,
              child: _identity(
                _session(
                  status: GameDetectionStatus.unsupportedGame,
                  processId: 321,
                  title: title,
                ),
              ),
            ),
          ),
        );

        final titleWidget = tester.widget<Text>(find.text(title));
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.overflow, TextOverflow.ellipsis);
        expect(find.byTooltip('$title\nRPCS3 process ID: 321'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
