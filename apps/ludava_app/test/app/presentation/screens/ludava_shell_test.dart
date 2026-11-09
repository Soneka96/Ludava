import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/app/presentation/screens/ludava_session_body.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_shutdown_overlay.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

GameField _field() => GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0x1000,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.researchConfirmed,
  minimumValue: 0,
  maximumValue: 0xffffffff,
);

Widget _wrap(Widget child, {ThemeData? theme}) =>
    MaterialApp(theme: theme ?? LudavaTheme.graphiteAndTeal, home: child);

GameWriteResult _failedWrite(String fieldId, int value) => GameWriteResult(
  status: GameWriteStatus.writeFailed,
  fieldId: fieldId,
  requestedValue: value,
);

void main() {
  group('Class LudavaShell composition behavior', () {
    testWidgets('Class LudavaShell caps centered content on wide windows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
            onMinimize: () {},
            onToggleMaximize: () {},
            isMaximized: maximizeState,
            onClose: () {},
            onRefresh: () {},
            onSelectProcess: (_) {},
          ),
        ),
      );

      final header = tester.getRect(find.byType(TrainerGameHeader));
      expect(header.width, LudavaDimensions.maximumContentWidth);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class LudavaShell composes its session body and window actions',
      (tester) async {
        final session = TrainerSessionState();
        final field = _field();
        var selectedProcessId = 0;
        GameField? editedField;
        String? appliedFieldId;
        int? appliedValue;
        var cancelCalls = 0;
        var minimizeCalls = 0;
        var maximizeCalls = 0;
        var closeCalls = 0;
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

        await tester.pumpWidget(
          _wrap(
            LudavaShell(
              session: session,
              editingFieldId: field.id,
              onEditField: (value) => editedField = value,
              onApplyField: (fieldId, value) {
                appliedFieldId = fieldId;
                appliedValue = value;
                return _failedWrite(fieldId, value);
              },
              onCancelEditing: () => cancelCalls++,
              onMinimize: () => minimizeCalls++,
              onToggleMaximize: () => maximizeCalls++,
              isMaximized: maximizeState,
              onClose: () => closeCalls++,
              onRefresh: () {},
              onSelectProcess: (processId) => selectedProcessId = processId,
            ),
          ),
        );

        final body = tester.widget<LudavaSessionBody>(
          find.byType(LudavaSessionBody),
        );
        expect(body.session, same(session));
        expect(body.editingFieldId, field.id);
        body.onSelectProcess(42);
        body.onEditField(field);
        expect(
          body.onApplyField(field.id, 99).status,
          GameWriteStatus.writeFailed,
        );
        body.onCancelEditing();
        expect(selectedProcessId, 42);
        expect(editedField, same(field));
        expect(appliedFieldId, field.id);
        expect(appliedValue, 99);
        expect(cancelCalls, 1);

        expect(find.byType(LudavaSessionBody), findsOneWidget);
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
    testWidgets(
      'Class LudavaShell fills and blocks interaction with shutdown overlay',
      (tester) async {
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);
        var refreshCalls = 0;

        Widget buildShell({bool isClosing = false}) => _wrap(
          LudavaShell(
            session: TrainerSessionState(),
            editingFieldId: null,
            onEditField: (_) {},
            onApplyField: _failedWrite,
            onCancelEditing: () {},
            onMinimize: () {},
            onToggleMaximize: () {},
            isMaximized: maximizeState,
            onClose: () {},
            isClosing: isClosing,
            onRefresh: () => refreshCalls++,
            onSelectProcess: (_) {},
          ),
        );

        await tester.pumpWidget(buildShell(isClosing: true));
        expect(find.byType(LudavaShutdownOverlay), findsOneWidget);
        expect(
          tester.getRect(find.byType(LudavaShutdownOverlay)),
          Offset.zero & LudavaDimensions.minimumWindowSize,
        );
        await tester.tap(
          find.byTooltip('Refresh values or rediscover RPCS3'),
          warnIfMissed: false,
        );
        expect(refreshCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

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
            onSelectProcess: (_) {},
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
