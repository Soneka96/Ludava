import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';

void main() {
  group('Property LudavaSpacing scale behaves correctly', () {
    test('Property LudavaSpacing scale uses four-pixel increments', () {
      expect(LudavaSpacing.xs, 4);
      expect(LudavaSpacing.sm, 8);
      expect(LudavaSpacing.md, 12);
      expect(LudavaSpacing.lg, 16);
      expect(LudavaSpacing.xl, 24);
      expect(LudavaSpacing.xxl, 32);
    });
  });

  group('Property LudavaDimensions behaves correctly', () {
    test('Property LudavaDimensions exposes window and control sizes', () {
      expect(LudavaDimensions.initialWindowSize, const Size(1180, 760));
      expect(LudavaDimensions.minimumWindowSize, const Size(720, 560));
      expect(LudavaDimensions.minimumInteractiveTarget, 48);
      expect(LudavaDimensions.maximumContentWidth, 1440);
      expect(LudavaDimensions.titleBarHeight, 48);
      expect(LudavaDimensions.windowControlWidth, 48);
      expect(LudavaDimensions.windowResizeHandleSize, 8);
      expect(LudavaDimensions.iconSmall, 20);
      expect(LudavaDimensions.iconMedium, 24);
    });
  });

  group('Property LudavaBreakpoints behaves correctly', () {
    test('Property LudavaBreakpoints exposes current layout thresholds', () {
      expect(LudavaBreakpoints.fieldCards, 920);
      expect(LudavaBreakpoints.trainerHeaderWide, 960);
    });
  });

  group('Property ConnectionDimensions behaves correctly', () {
    test(
      'Property ConnectionDimensions exposes readable process dimensions',
      () {
        expect(ConnectionDimensions.contentMaxWidth, 560);
        expect(ConnectionDimensions.processSeparatorExtent, 1);
      },
    );
  });
}
