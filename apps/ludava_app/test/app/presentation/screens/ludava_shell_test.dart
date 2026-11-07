import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
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
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

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
              isMaximized: maximizeState,
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
        expect(find.text('RPCS3'), findsOneWidget);
        await tester.tap(find.byTooltip('Minimize window'));
        await tester.tap(find.byTooltip('Maximize window'));
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
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);
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
            isMaximized: maximizeState,
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

    testWidgets('Class LudavaShell supports process choice at minimum size', (
      tester,
    ) async {
      tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);
      int? selectedProcessId;

      await tester.pumpWidget(
        _wrap(
          LudavaShell(
            session: TrainerSessionState(processIds: const [10, 20, 30]),
            editingFieldId: null,
            onEditField: (_) {},
            onApplyField: _failedWrite,
            onCancelEditing: () {},
            onMinimize: () {},
            onToggleMaximize: () {},
            isMaximized: maximizeState,
            onClose: () {},
            onRefresh: () {},
            onRedetect: () {},
            onSelectProcess: (processId) => selectedProcessId = processId,
          ),
        ),
      );

      expect(find.text('Available RPCS3 processes'), findsOneWidget);
      final firstProcess = find.text('Process ID 10');
      expect(firstProcess, findsOneWidget);
      await tester.ensureVisible(firstProcess);
      await tester.pumpAndSettle();
      await tester.tap(firstProcess);

      expect(selectedProcessId, 10);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class LudavaShell displays a connection error at minimum size', (
      tester,
    ) async {
      tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);
      const message =
          'RPCS3 could not refresh this session because its process metadata is temporarily unavailable.';

      await tester.pumpWidget(
        _wrap(
          LudavaShell(
            session: TrainerSessionState(errorMessage: message),
            editingFieldId: null,
            onEditField: (_) {},
            onApplyField: _failedWrite,
            onCancelEditing: () {},
            onMinimize: () {},
            onToggleMaximize: () {},
            isMaximized: maximizeState,
            onClose: () {},
            onRefresh: () {},
            onRedetect: () {},
            onSelectProcess: (_) {},
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class LudavaShell keeps an expanded trainer usable at minimum size',
      (tester) async {
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);
        final profile = GameProfileCatalog.profiles.first;
        final field = profile.fields.values.first;

        await tester.pumpWidget(
          _wrap(
            LudavaShell(
              session: TrainerSessionState(
                processIds: const [42],
                selectedProcessId: 42,
                detection: GameDetectionResult(
                  status: GameDetectionStatus.supportedGame,
                  processId: 42,
                  profile: profile,
                  confidence: GameIdentityConfidence.confirmed,
                  evidenceDescription: 'Confirmed test profile.',
                ),
                memoryBase: 0x1000,
                readResults: {
                  field.id: GameReadResult(
                    status: GameReadStatus.success,
                    fieldId: field.id,
                    value: 17,
                  ),
                },
              ),
              editingFieldId: field.id,
              onEditField: (_) {},
              onApplyField: _failedWrite,
              onCancelEditing: () {},
              onMinimize: () {},
              onToggleMaximize: () {},
              isMaximized: maximizeState,
              onClose: () {},
              onRefresh: () {},
              onRedetect: () {},
              onSelectProcess: (_) {},
            ),
          ),
        );

        final input = find.byKey(ValueKey('inline-editor-input-${field.id}'));
        expect(find.byType(TrainerFieldsPanel), findsOneWidget);
        expect(input, findsOneWidget);
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Apply'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Widget _wrap(Widget child) =>
    MaterialApp(theme: LudavaTheme.graphiteAndTeal, home: child);

GameWriteResult _failedWrite(String fieldId, int value) => GameWriteResult(
  status: GameWriteStatus.writeFailed,
  fieldId: fieldId,
  requestedValue: value,
);
