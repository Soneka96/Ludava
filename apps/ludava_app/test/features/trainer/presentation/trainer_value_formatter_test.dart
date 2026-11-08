import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_value_formatter.dart';

void main() {
  group('Method TrainerValueFormatter.format behaves correctly', () {
    test('Method TrainerValueFormatter.format groups exact integer values', () {
      expect(TrainerValueFormatter.format(null), 'Unavailable');
      expect(TrainerValueFormatter.format(0), '0');
      expect(TrainerValueFormatter.format(4294967295), '4,294,967,295');
      expect(
        TrainerValueFormatter.format(9223372036854775807),
        '9,223,372,036,854,775,807',
      );
      expect(TrainerValueFormatter.format(-1234567), '-1,234,567');
    });
  });
}
