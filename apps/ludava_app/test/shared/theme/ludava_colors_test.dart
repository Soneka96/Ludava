import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_colors.dart';

void main() {
  group('Class LudavaColors palette behavior', () {
    test('Class LudavaColors exposes raw palette colors', () {
      expect(LudavaColors.graphite950, const Color(0xFF11191B));
      expect(LudavaColors.graphite900, const Color(0xFF192326));
      expect(LudavaColors.graphite800, const Color(0xFF233135));
      expect(LudavaColors.graphite750, const Color(0xFF2D3B3E));
      expect(LudavaColors.graphite700, const Color(0xFF36474B));
      expect(LudavaColors.neutral100, const Color(0xFFE5EFED));
      expect(LudavaColors.neutral300, const Color(0xFFBBC8C5));
      expect(LudavaColors.neutral500, const Color(0xFF879A96));
      expect(LudavaColors.neutral650, const Color(0xFF657773));
      expect(LudavaColors.teal400, const Color(0xFF5FD4BF));
      expect(LudavaColors.green400, const Color(0xFF83D5A0));
      expect(LudavaColors.amber400, const Color(0xFFF0C875));
      expect(LudavaColors.red400, const Color(0xFFFF918B));
      expect(LudavaColors.blue400, const Color(0xFF79B8FF));
    });
  });
}
