import 'package:ludava_sdk/features/trainer/application/trainer_write_validation_result.dart';
import 'package:test/test.dart';

void main() {
  group('Class TrainerWriteValidationResult construction', () {
    test('Class TrainerWriteValidationResult stores validation outcome', () {
      const result = TrainerWriteValidationResult(
        isAuthorized: false,
        processUnavailable: true,
        rejectionMessage: 'RPCS3 stopped.',
      );

      expect(result.isAuthorized, isFalse);
      expect(result.processUnavailable, isTrue);
      expect(result.processSessionChanged, isFalse);
      expect(result.rejectionMessage, 'RPCS3 stopped.');
    });
  });
}
