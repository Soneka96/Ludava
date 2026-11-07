import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerFieldValue presentation behavior', () {
    testWidgets('Class TrainerFieldValue formats the maximum unsigned value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerFieldValue(
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'bolts',
              value: 4294967295,
            ),
            canRead: true,
            prominent: true,
          ),
        ),
      );

      expect(find.text('4,294,967,295'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldValue distinguishes unavailable and failed reads',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              readResult: null,
              canRead: true,
              prominent: false,
            ),
          ),
        );
        expect(find.text('Unavailable'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              readResult: GameReadResult(
                status: GameReadStatus.readFailed,
                fieldId: 'bolts',
              ),
              canRead: true,
              prominent: false,
            ),
          ),
        );
        expect(find.text('Read failed'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              readResult: GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'bolts',
                value: 17,
              ),
              canRead: false,
              prominent: false,
            ),
          ),
        );
        expect(find.text('Unavailable'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(
    body: Center(child: SizedBox(width: 240, child: child)),
  ),
);
