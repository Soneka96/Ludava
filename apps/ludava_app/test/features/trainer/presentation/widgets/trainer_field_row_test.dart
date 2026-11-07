import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerFieldRow presentation behavior', () {
    testWidgets('Class TrainerFieldRow shows equivalent field data and edit', (
      tester,
    ) async {
      var editCalls = 0;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: LudavaDimensions.minimumWindowWidth,
            child: TrainerFieldRow(
              field: _field(),
              readResult: _read(4294967295),
              canRead: true,
              canWrite: true,
              isEditing: false,
              onEdit: () => editCalls++,
            ),
          ),
        ),
      );

      expect(find.text('Bolts'), findsOneWidget);
      expect(find.text('Writable'), findsOneWidget);
      expect(find.text('4,294,967,295'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Edit'));
      expect(editCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldRow keeps unavailable values explicit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: LudavaDimensions.minimumWindowWidth,
            child: TrainerFieldRow(
              field: _field(writeStatus: VerificationStatus.none),
              readResult: null,
              canRead: true,
              canWrite: false,
              isEditing: false,
              onEdit: () {},
            ),
          ),
        ),
      );

      expect(find.text('Bolts'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Read-only'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);
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
              canRead: true,
              canWrite: true,
              isEditing: true,
              onEdit: () {},
            ),
          ),
        ),
      );

      expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);
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
                  canRead: true,
                  canWrite: false,
                  isEditing: false,
                  onEdit: () {},
                ),
              ),
            ),
          ),
        );

        expect(
          tester.widget<Text>(find.text('Bolts')).style?.color,
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

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

GameField _field({
  VerificationStatus writeStatus = VerificationStatus.verified,
}) => GameField(
  id: 'bolts',
  name: 'Bolts',
  guestOffset: 0,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  readStatus: VerificationStatus.verified,
  writeStatus: writeStatus,
  minimumValue: 0,
  maximumValue: 4294967295,
);

GameReadResult _read(int value) => GameReadResult(
  status: GameReadStatus.success,
  fieldId: 'bolts',
  value: value,
);
