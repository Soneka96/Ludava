import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/features/connection/presentation/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class LudavaShell composition behavior', () {
    testWidgets(
      'Class LudavaShell composes connection guidance and window actions',
      (tester) async {
        var minimizeCalls = 0;
        var maximizeCalls = 0;
        var closeCalls = 0;

        await tester.pumpWidget(
          _wrap(
            LudavaShell(
              session: TrainerSessionState(),
              editingFieldId: null,
              onEditField: (_) {},
              onApplyField: _failedWrite,
              onCancelEditing: () {},
              onMinimize: () => minimizeCalls++,
              onToggleMaximize: () => maximizeCalls++,
              onClose: () => closeCalls++,
              onRefresh: () {},
              onRedetect: () {},
              onSelectProcess: (_) {},
            ),
          ),
        );

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanel), findsNothing);
        expect(find.text('Connect to RPCS3'), findsOneWidget);
        await tester.tap(find.byTooltip('Minimize window'));
        await tester.tap(find.byTooltip('Maximize or restore window'));
        await tester.tap(find.byTooltip('Close window'));

        expect(minimizeCalls, 1);
        expect(maximizeCalls, 1);
        expect(closeCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class LudavaShell renders SDK profile fields when ready', (
      tester,
    ) async {
      final profile = GameProfileCatalog.profiles.first;
      final field = profile.fields.values.first;
      final session = TrainerSessionState(
        processIds: const [42],
        selectedProcessId: 42,
        detection: GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          processId: 42,
          profile: profile,
          confidence: GameIdentityConfidence.confirmed,
          evidenceDescription: 'Test game identity.',
        ),
        memoryBase: 0x1000,
      );

      await tester.pumpWidget(
        _wrap(
          LudavaShell(
            session: session,
            editingFieldId: null,
            onEditField: (_) {},
            onApplyField: _failedWrite,
            onCancelEditing: () {},
            onMinimize: () {},
            onToggleMaximize: () {},
            onClose: () {},
            onRefresh: () {},
            onRedetect: () {},
            onSelectProcess: (_) {},
          ),
        ),
      );

      expect(find.byType(TrainerFieldsPanel), findsOneWidget);
      expect(find.byType(SessionConnectionBody), findsNothing);
      expect(find.text(profile.gameName), findsOneWidget);
      expect(find.text(field.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _wrap(Widget child) =>
    MaterialApp(theme: LudavaTheme.graphiteAndTeal, home: child);

GameWriteResult _failedWrite(String fieldId, int value) => GameWriteResult(
  status: GameWriteStatus.writeFailed,
  fieldId: fieldId,
  requestedValue: value,
);
