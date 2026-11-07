import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_card.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerFieldCard presentation behavior', () {
    testWidgets('Class TrainerFieldCard shows name, value, access, and edit', (
      tester,
    ) async {
      var editCalls = 0;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            child: TrainerFieldCard(
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
      expect(find.text('Current value'), findsOneWidget);
      expect(find.text('4,294,967,295'), findsOneWidget);
      expect(find.text('Writable'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Edit'));
      expect(editCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldCard hides edit for a read-only field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            child: TrainerFieldCard(
              field: _field(writeStatus: VerificationStatus.none),
              readResult: _read(12),
              canRead: true,
              canWrite: false,
              isEditing: false,
              onEdit: () {},
            ),
          ),
        ),
      );

      expect(find.text('Read-only'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Edit'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: Center(child: child)),
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
