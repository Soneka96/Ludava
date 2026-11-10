import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';

void main() {
  group('Class SdkOperationGate construction', () {
    test('Class SdkOperationGate starts open', () {
      expect(SdkOperationGate().isOpen, isTrue);
    });
  });

  group('Method close() behaves correctly', () {
    test('Method close() closes the gate permanently and idempotently', () {
      final gate = SdkOperationGate();

      gate.close();
      gate.close();

      expect(gate.isOpen, isFalse);
    });
  });
}
