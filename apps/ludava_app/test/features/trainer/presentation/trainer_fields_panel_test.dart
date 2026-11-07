import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_fields_panel.dart';
import 'package:ludava_app/shared/layout/ludava_breakpoints.dart';
import 'package:ludava_app/shared/layout/ludava_spacing.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerFieldsPanel adaptive presentation behavior', () {
    testWidgets('Class TrainerFieldsPanel renders cards at desktop width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1180, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_session(value: 0)));

      expect(
        find.byKey(const ValueKey('trainer-field-card-bolts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trainer-field-row-bolts')),
        findsNothing,
      );
      expect(find.text('Bolts'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Writable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel uses semantic surface roles in cards',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_session(value: 0)));
        final tokens = LudavaTheme.graphiteAndTeal
            .extension<LudavaThemeTokens>()!;
        final field = tester.widget<Container>(
          find.byKey(const ValueKey('trainer-field-bolts')),
        );
        final decoration = field.decoration! as BoxDecoration;

        expect(field.padding, const EdgeInsets.all(LudavaSpacing.lg));
        expect(decoration.color, tokens.surfaceElevated);
        expect((decoration.border! as Border).top.color, tokens.borderSubtle);
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel renders compact rows at narrow width',
      (tester) async {
        tester.view.physicalSize = const Size(720, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_session(value: 0)));

        expect(
          find.byKey(const ValueKey('trainer-field-row-bolts')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('trainer-field-card-bolts')),
          findsNothing,
        );
        expect(find.text('Bolts'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('Writable'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerFieldsPanel exposes Edit in both layouts', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? editedFieldId;

      for (final width in const [720.0, 1180.0]) {
        tester.view.physicalSize = Size(width, 560);
        await tester.pumpWidget(
          _wrap(
            _session(value: 17),
            onEditField: (field) => editedFieldId = field.id,
          ),
        );

        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        expect(editedFieldId, 'bolts');
      }
    });

    testWidgets(
      'Class TrainerFieldsPanel expands the same editor in both layouts',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final width in const [720.0, 1180.0]) {
          tester.view.physicalSize = Size(width, 560);
          await tester.pumpWidget(
            _wrap(_session(value: 17), editingFieldId: 'bolts'),
          );

          expect(
            find.byKey(const ValueKey('inline-editor-input-bolts')),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel hides an editor when permission is lost',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_session(value: 17), editingFieldId: 'bolts'),
        );
        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _wrap(
            _session(value: 17, profileWriteStatus: VerificationStatus.none),
            editingFieldId: 'bolts',
          ),
        );

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel preserves a draft when layout changes',
      (tester) async {
        tester.view.physicalSize = const Size(720, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var writeCalls = 0;
        final state = _session(value: 17);

        Widget panel() => _wrap(
          state,
          editingFieldId: 'bolts',
          onApplyField: (fieldId, value) {
            writeCalls++;
            return GameWriteResult(
              status: GameWriteStatus.success,
              fieldId: fieldId,
              requestedValue: value,
              readBackValue: value,
            );
          },
        );

        await tester.pumpWidget(panel());
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );
        await tester.pump();

        tester.view.physicalSize = const Size(1180, 560);
        await tester.pumpWidget(panel());

        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('inline-editor-input-bolts')),
              )
              .controller!
              .text,
          '42',
        );
        expect(writeCalls, 0);
      },
    );

    testWidgets('Class TrainerFieldsPanel switches at the shared breakpoint', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      tester.view.physicalSize = Size(LudavaBreakpoints.fieldCards, 560);
      await tester.pumpWidget(_wrap(_session(value: 0)));
      expect(
        find.byKey(const ValueKey('trainer-field-card-bolts')),
        findsOneWidget,
      );

      tester.view.physicalSize = Size(LudavaBreakpoints.fieldCards - 1, 560);
      await tester.pumpWidget(_wrap(_session(value: 0)));
      expect(
        find.byKey(const ValueKey('trainer-field-row-bolts')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel preserves the maximum unsigned value',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final width in const [720.0, 1180.0]) {
          tester.view.physicalSize = Size(width, 560);
          await tester.pumpWidget(_wrap(_session(value: 4294967295)));

          expect(find.text('4,294,967,295'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel distinguishes a failed read from zero',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final width in const [720.0, 1180.0]) {
          tester.view.physicalSize = Size(width, 560);
          await tester.pumpWidget(
            _wrap(
              _session(
                readResult: const GameReadResult(
                  status: GameReadStatus.readFailed,
                  fieldId: 'bolts',
                ),
              ),
            ),
          );

          expect(find.text('Read failed'), findsOneWidget);
          expect(find.text('0'), findsNothing);
          expect(find.text('Writable'), findsNothing);

          await tester.pumpWidget(
            _wrap(
              _session(
                fieldReadStatus: VerificationStatus.none,
                readResult: const GameReadResult(
                  status: GameReadStatus.none,
                  fieldId: 'bolts',
                ),
              ),
            ),
          );
          expect(find.text('Unavailable'), findsOneWidget);
          expect(find.text('0'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('Class TrainerFieldsPanel handles a missing read result', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final width in const [720.0, 1180.0]) {
        tester.view.physicalSize = Size(width, 560);
        await tester.pumpWidget(
          _wrap(_session(value: null, includeBoltsRead: false)),
        );

        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.text('0'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'Class TrainerFieldsPanel requires profile and field write approval',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final width in const [720.0, 1180.0]) {
          tester.view.physicalSize = Size(width, 560);
          final deniedWriteStates = [
            _session(
              value: 25,
              profileWriteStatus: VerificationStatus.none,
              fieldWriteStatus: VerificationStatus.verified,
            ),
            _session(
              value: 25,
              profileWriteStatus: VerificationStatus.verified,
              fieldWriteStatus: VerificationStatus.none,
            ),
            _session(
              value: 25,
              profileWriteStatus: VerificationStatus.verified,
              fieldWriteStatus: VerificationStatus.verified,
              confidence: GameIdentityConfidence.manuallySelected,
            ),
            _session(value: 25, hasProcess: false),
            _session(value: 25, hasMemoryBase: false),
            _session(value: 25, omitMinimum: true),
            _session(value: 25, omitMaximum: true),
          ];
          for (final state in deniedWriteStates) {
            await tester.pumpWidget(_wrap(state));
            expect(find.text('Read-only'), findsOneWidget);
          }

          for (final state in [
            _session(value: 25, profileReadStatus: VerificationStatus.none),
            _session(value: 25, fieldReadStatus: VerificationStatus.none),
          ]) {
            await tester.pumpWidget(_wrap(state));
            expect(find.text('Unavailable'), findsOneWidget);
            expect(find.text('Not readable'), findsOneWidget);
            expect(find.text('25'), findsNothing);
            expect(find.text('Read-only'), findsNothing);
          }
        }
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel renders each profile field in both layouts',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final width in const [720.0, 1180.0]) {
          tester.view.physicalSize = Size(width, 560);
          await tester.pumpWidget(
            _wrap(_session(value: 25, includeSecondField: true)),
          );

          expect(find.text('Bolts'), findsOneWidget);
          expect(find.text('Scrap'), findsOneWidget);
          expect(find.text('25'), findsOneWidget);
          expect(find.text('7'), findsOneWidget);
        }
      },
    );

    testWidgets('Class TrainerFieldsPanel handles profiles without fields', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_session(value: null, emptyProfile: true)));

      expect(
        find.text('No trainer fields are available for this profile.'),
        findsOneWidget,
      );
    });

    testWidgets('Class TrainerFieldsPanel renders nothing without a profile', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(TrainerSessionState()));

      expect(find.text('Bolts'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _wrap(
  TrainerSessionState session, {
  String? editingFieldId,
  ValueChanged<GameField>? onEditField,
  GameWriteResult Function(String fieldId, int value)? onApplyField,
  VoidCallback? onCancelEditing,
}) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(
    body: TrainerFieldsPanel(
      session: session,
      editingFieldId: editingFieldId,
      onEditField: onEditField ?? (_) {},
      onApplyField:
          onApplyField ??
          ((fieldId, value) => GameWriteResult(
            status: GameWriteStatus.none,
            fieldId: fieldId,
            requestedValue: value,
          )),
      onCancelEditing: onCancelEditing ?? () {},
    ),
  ),
);

TrainerSessionState _session({
  int? value,
  GameReadResult? readResult,
  VerificationStatus profileReadStatus = VerificationStatus.verified,
  VerificationStatus profileWriteStatus = VerificationStatus.verified,
  VerificationStatus fieldReadStatus = VerificationStatus.verified,
  VerificationStatus fieldWriteStatus = VerificationStatus.verified,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  bool hasProcess = true,
  bool hasMemoryBase = true,
  bool omitMinimum = false,
  bool omitMaximum = false,
  bool includeSecondField = false,
  bool emptyProfile = false,
  bool includeBoltsRead = true,
}) {
  final field = GameField(
    id: 'bolts',
    name: 'Bolts',
    guestOffset: 0,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
    readStatus: fieldReadStatus,
    writeStatus: fieldWriteStatus,
    minimumValue: omitMinimum ? null : 0,
    maximumValue: omitMaximum ? null : 4294967295,
  );
  final fields = <String, GameField>{if (!emptyProfile) 'bolts': field};
  if (includeSecondField) {
    fields['scrap'] = GameField(
      id: 'scrap',
      name: 'Scrap',
      guestOffset: 4,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      minimumValue: 0,
      maximumValue: 100,
    );
  }
  final profile = GameProfile(
    id: 'test-game',
    gameName: 'Test game',
    buildId: 'TEST',
    executable: 'test.self',
    readStatus: profileReadStatus,
    writeStatus: profileWriteStatus,
    fields: fields,
  );
  final readResults = <String, GameReadResult>{};
  if (includeBoltsRead && !emptyProfile) {
    readResults['bolts'] =
        readResult ??
        GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'bolts',
          value: value,
        );
  }
  if (includeSecondField) {
    readResults['scrap'] = const GameReadResult(
      status: GameReadStatus.success,
      fieldId: 'scrap',
      value: 7,
    );
  }
  return TrainerSessionState(
    processIds: hasProcess ? const [123] : const [],
    selectedProcessId: hasProcess ? 123 : null,
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: hasProcess ? 123 : null,
      profile: profile,
      confidence: confidence,
      evidenceDescription: 'Test identity evidence.',
    ),
    memoryBase: hasMemoryBase ? 0x1000 : null,
    readResults: readResults,
  );
}
