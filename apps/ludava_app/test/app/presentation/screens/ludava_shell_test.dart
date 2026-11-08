import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

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

    testWidgets(
      'Class LudavaShell shows memory-base guidance for a supported game',
      (tester) async {
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);
        final profile = GameProfileCatalog.profiles.first;
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
              onSelectProcess: (_) {},
            ),
          ),
        );

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanel), findsNothing);
        expect(
          find.text(
            'The game was detected, but its session memory base is unavailable.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaShell shows SDK errors alongside supported fields',
      (tester) async {
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);
        final profile = GameProfileCatalog.profiles.first;
        final field = profile.fields.values.first;
        const message = 'The SDK could not refresh the current game session.';

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
                  evidenceDescription: 'Test game identity.',
                ),
                memoryBase: 0x1000,
                readResults: {
                  field.id: GameReadResult(
                    status: GameReadStatus.success,
                    fieldId: field.id,
                    value: 17,
                  ),
                },
                errorMessage: message,
              ),
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

        expect(find.byType(TrainerFieldsPanel), findsOneWidget);
        expect(find.byType(SessionConnectionBody), findsNothing);
        expect(find.text(message), findsOneWidget);
        expect(find.text(field.name), findsOneWidget);
        expect(find.text('17'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaShell keeps field rows fixed while SDK feedback changes at compact sizes',
      (tester) async {
        const message = 'The SDK could not refresh the current game session.';
        final profile = GameProfileCatalog.profiles.first;
        final field = profile.fields.values.first;
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

        Widget buildShell(String? errorMessage) => _wrap(
          LudavaShell(
            session: TrainerSessionState(
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
              readResults: {
                field.id: GameReadResult(
                  status: GameReadStatus.success,
                  fieldId: field.id,
                  value: 17,
                ),
              },
              errorMessage: errorMessage,
            ),
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
        );

        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;

          await tester.pumpWidget(buildShell(null));
          final before = _fieldRowRects(tester, profile);

          await tester.pumpWidget(buildShell(message));
          expect(_fieldRowRects(tester, profile), before);
          expect(find.byTooltip(message), findsOneWidget);

          await tester.pumpWidget(buildShell(null));
          expect(_fieldRowRects(tester, profile), before);
          expect(find.byTooltip(message), findsNothing);
          expect(
            find.byType(TrainerFieldRow),
            findsNWidgets(profile.fields.length),
          );
          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );

    testWidgets(
      'Class LudavaShell overlays closing and failure states at compact sizes',
      (tester) async {
        final profile = GameProfileCatalog.profiles.first;
        final field = profile.fields.values.first;
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);
        final alternateTheme = LudavaThemeFactory.build(
          colors: GraphiteTealTheme.colors.copyWith(canvas: Colors.purple),
          style: LudavaStylePresets.comfortable,
          brightness: GraphiteTealTheme.brightness,
        );
        final expectedScrim = alternateTheme.colorScheme.scrim.withValues(
          alpha: 0.72,
        );
        var refreshCalls = 0;

        Widget buildShell({bool isClosing = false, String? closeFailure}) =>
            _wrap(
              LudavaShell(
                session: TrainerSessionState(
                  processIds: const [42],
                  selectedProcessId: 42,
                  processMetadata: Rpcs3ProcessMetadata(
                    executablePath: r'C:\RPCS3\rpcs3.exe',
                    startedAtUtc: DateTime.utc(2026),
                  ),
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
                isClosing: isClosing,
                closeFailure: closeFailure,
                onRefresh: () => refreshCalls++,
                onSelectProcess: (_) {},
              ),
              theme: alternateTheme,
            );

        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(buildShell());
          final rows = _fieldRowRects(tester, profile);

          await tester.pumpWidget(buildShell(isClosing: true));
          expect(find.text('Closing Ludava…'), findsOneWidget);
          expect(find.text('Finishing cleanup'), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) => widget is ColoredBox && widget.color == expectedScrim,
            ),
            findsOneWidget,
          );
          expect(_fieldRowRects(tester, profile), rows);
          expect(
            tester.getRect(find.text('Closing Ludava…')).bottom,
            lessThan(size.height),
          );
          await tester.tap(
            find.byTooltip('Refresh values or rediscover RPCS3'),
            warnIfMissed: false,
          );
          expect(refreshCalls, 0);

          await tester.pumpWidget(
            buildShell(
              closeFailure: 'The native window rejected the close request.',
            ),
          );
          expect(find.text('Retry close'), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) => widget is ColoredBox && widget.color == expectedScrim,
            ),
            findsOneWidget,
          );
          expect(_fieldRowRects(tester, profile), rows);
          final retry = tester.getRect(find.text('Retry close'));
          expect(retry.left, greaterThanOrEqualTo(0));
          expect(retry.top, greaterThanOrEqualTo(0));
          expect(retry.right, lessThanOrEqualTo(size.width));
          expect(retry.bottom, lessThanOrEqualTo(size.height));
          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );

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
                processMetadata: Rpcs3ProcessMetadata(
                  executablePath: r'C:\RPCS3\rpcs3.exe',
                  startedAtUtc: DateTime.utc(2026),
                ),
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
              onSelectProcess: (_) {},
            ),
          ),
        );

        final input = find.byKey(ValueKey('inline-editor-input-${field.id}'));
        expect(find.byType(TrainerFieldsPanel), findsOneWidget);
        expect(input, findsOneWidget);
        await tester.ensureVisible(find.byTooltip('Apply Bolts'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

List<Rect> _fieldRowRects(WidgetTester tester, GameProfile profile) => profile
    .fields
    .keys
    .map(
      (fieldId) =>
          tester.getRect(find.byKey(ValueKey('trainer-field-row-$fieldId'))),
    )
    .toList(growable: false);

Widget _wrap(Widget child, {ThemeData? theme}) =>
    MaterialApp(theme: theme ?? LudavaTheme.graphiteAndTeal, home: child);

GameWriteResult _failedWrite(String fieldId, int value) => GameWriteResult(
  status: GameWriteStatus.writeFailed,
  fieldId: fieldId,
  requestedValue: value,
);
