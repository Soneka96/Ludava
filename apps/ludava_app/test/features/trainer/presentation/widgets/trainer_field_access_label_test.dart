import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_access_label.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';

void main() {
  group('Class TrainerFieldAccessLabel presentation behavior', () {
    testWidgets('Class TrainerFieldAccessLabel shows writable text and icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TrainerFieldAccessLabel(canRead: true, canWrite: true)),
      );

      expect(find.text('Writable'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('Class TrainerFieldAccessLabel distinguishes read states', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TrainerFieldAccessLabel(canRead: true, canWrite: false)),
      );
      expect(find.text('Read-only'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.pumpWidget(
        _wrap(const TrainerFieldAccessLabel(canRead: false, canWrite: false)),
      );
      expect(find.text('Not readable'), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(
  theme: LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);
