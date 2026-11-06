import 'package:ludava_tui/shared/constants/layout_constants.dart';
import 'package:test/test.dart';

void main() {
  group('Property minimumMenuWidth behaves correctly', () {
    test('Property minimumMenuWidth returns the minimum readable width', () {
      expect(NoctermLayoutConstants.minimumMenuWidth, 48);
    });
  });

  group('Property fixedMenuRows behaves correctly', () {
    test('Property fixedMenuRows returns the fixed menu row count', () {
      expect(NoctermLayoutConstants.fixedMenuRows, 11);
    });
  });

  group('Property fixedEditorRows behaves correctly', () {
    test('Property fixedEditorRows returns the fixed editor row count', () {
      expect(NoctermLayoutConstants.fixedEditorRows, 11);
    });
  });

  group('Property separatorWidth behaves correctly', () {
    test('Property separatorWidth returns the separator width', () {
      expect(NoctermLayoutConstants.separatorWidth, 40);
    });
  });
}
