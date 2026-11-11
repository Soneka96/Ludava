import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

GameField _field() => GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  minimumValue: 0,
  maximumValue: 4294967295,
);

GameReadResult _read(int value) => GameReadResult(
  status: GameReadStatus.success,
  fieldId: 'credits',
  value: value,
);

/// Returns a successful fake write with a matching read-back value.
GameWriteResult _success(int value) => GameWriteResult(
  status: GameWriteStatus.success,
  fieldId: 'credits',
  requestedValue: value,
  readBackValue: value,
);

void main() {
  group('Class TrainerFieldRow presentation behavior', () {
    testWidgets(
      'Class TrainerFieldRow shows one horizontal field row and Edit icon',
      (tester) async {
        var editCalls = 0;
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: LudavaDimensions.minimumWindowWidth,
              child: TrainerFieldRow(
                field: _field(),
                readResult: _read(4294967295),
                currentValue: 4294967295,
                writeResult: null,
                canWrite: true,
                isEditing: false,
                onEdit: () => editCalls++,
                onApply: _success,
                onCancel: () {},
                onApplied: () {},
              ),
            ),
          ),
        );

        expect(find.text('Credits'), findsOneWidget);
        expect(find.text('Writable'), findsNothing);
        expect(find.text('4,294,967,295'), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('trainer-field-row-credits')))
              .height,
          LudavaDimensions.minimumInteractiveTarget,
        );
        final row = tester.getRect(
          find.byKey(const ValueKey('trainer-field-row-credits')),
        );
        expect(tester.getRect(find.text('Credits')).center.dy, row.center.dy);
        expect(
          tester.getRect(find.text('4,294,967,295')).center.dy,
          row.center.dy,
        );
        expect(
          tester.getRect(find.byTooltip('Edit Credits')).center.dy,
          row.center.dy,
        );
        await tester.tap(find.byTooltip('Edit Credits'));
        expect(editCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerFieldRow keeps unavailable values explicit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: LudavaDimensions.minimumWindowWidth,
            child: TrainerFieldRow(
              field: _field(),
              readResult: null,
              currentValue: null,
              writeResult: null,
              canWrite: false,
              isEditing: false,
              onEdit: () {},
              onApply: _success,
              onCancel: () {},
              onApplied: () {},
            ),
          ),
        ),
      );

      expect(find.text('Credits'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Read-only'), findsNothing);
      expect(find.byTooltip('Edit Credits'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldRow hides Edit while its editor is open', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: LudavaDimensions.minimumWindowWidth,
            child: TrainerFieldRow(
              field: _field(),
              readResult: _read(42),
              currentValue: 42,
              writeResult: null,
              canWrite: true,
              isEditing: true,
              onEdit: () {},
              onApply: _success,
              onCancel: () {},
              onApplied: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Edit Credits'), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('trainer-field-row-credits')))
            .height,
        LudavaDimensions.minimumInteractiveTarget,
      );
      expect(find.text('4,294,967,295'), findsNothing);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets(
      'Class TrainerFieldRow and its value follow alternate semantic colors',
      (tester) async {
        final colors = GraphiteTealTheme.colors.copyWith(
          textPrimary: Colors.lime,
          textMuted: Colors.orange,
        );
        final theme = LudavaThemeFactory.build(
          colors: colors,
          style: LudavaStylePresets.comfortable,
          brightness: GraphiteTealTheme.brightness,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SizedBox(
                width: LudavaDimensions.minimumWindowWidth,
                child: TrainerFieldRow(
                  field: _field(),
                  readResult: _read(42),
                  currentValue: 42,
                  writeResult: null,
                  canWrite: false,
                  isEditing: false,
                  onEdit: () {},
                  onApply: _success,
                  onCancel: () {},
                  onApplied: () {},
                ),
              ),
            ),
          ),
        );

        expect(
          tester.widget<Text>(find.text('Credits')).style?.color,
          colors.textPrimary,
        );
        expect(
          tester.widget<Text>(find.text('42')).style?.color,
          colors.textPrimary,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
