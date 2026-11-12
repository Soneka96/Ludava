import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

Widget _wrap(Widget child, {double width = 240, ThemeData? theme}) =>
    MaterialApp(
      theme: theme ?? LudavaTheme.graphiteAndTeal,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  group('Class TrainerFieldValue presentation behavior', () {
    testWidgets('Class TrainerFieldValue formats the maximum unsigned value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TrainerFieldValue(
            fieldId: 'credits',
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 4294967295,
            ),
          ),
        ),
      );

      expect(find.text('4,294,967,295'), findsOneWidget);
      final value = tester.widget<Text>(find.text('4,294,967,295'));
      expect(value.style?.fontSize, 14);
      expect(
        value.style?.fontSize,
        LudavaTheme.graphiteAndTeal.textTheme.titleSmall?.fontSize,
      );
      expect(value.style?.fontWeight, FontWeight.w600);
      expect(
        value.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldValue uses typography from an alternate supplied theme',
      (tester) async {
        final alternateTheme = LudavaTheme.graphiteAndTeal.copyWith(
          textTheme: LudavaTheme.graphiteAndTeal.textTheme.copyWith(
            titleSmall: LudavaTheme.graphiteAndTeal.textTheme.titleSmall
                ?.copyWith(fontSize: 19),
          ),
        );
        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              fieldId: 'credits',
              readResult: GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'credits',
                value: 42,
              ),
            ),
            theme: alternateTheme,
          ),
        );

        expect(find.text('42'), findsOneWidget);
        final value = tester.widget<Text>(find.text('42'));
        expect(value.style?.fontSize, 19);
        expect(value.style?.fontSize, isNot(14));
        expect(
          value.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerFieldValue scales down the maximum value in narrow rows',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TrainerFieldValue(
              fieldId: 'credits',
              readResult: const GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'credits',
                value: 4294967295,
              ),
            ),
            width: 80,
          ),
        );

        expect(find.text('4,294,967,295'), findsOneWidget);
        expect(
          tester.getRect(find.text('4,294,967,295')).width,
          lessThanOrEqualTo(80),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerFieldValue distinguishes unavailable and failed reads',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const TrainerFieldValue(fieldId: 'credits', readResult: null)),
        );
        expect(find.text('Unavailable'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              fieldId: 'credits',
              readResult: GameReadResult(
                status: GameReadStatus.readFailed,
                fieldId: 'credits',
              ),
            ),
          ),
        );
        expect(find.text('Read failed'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              fieldId: 'credits',
              readResult: GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'credits',
                value: 17,
              ),
            ),
          ),
        );
        expect(find.text('17'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            const TrainerFieldValue(
              fieldId: 'credits',
              readResult: GameReadResult(
                status: GameReadStatus.success,
                fieldId: 'scrap',
                value: 99,
              ),
            ),
          ),
        );
        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.text('99'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
