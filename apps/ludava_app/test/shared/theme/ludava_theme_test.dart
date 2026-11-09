import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';

void main() {
  group('Property LudavaTheme.graphiteAndTeal behaves correctly', () {
    test('Property LudavaTheme.graphiteAndTeal exposes cached theme data', () {
      final theme = LudavaTheme.graphiteAndTeal;

      expect(identical(theme, LudavaTheme.graphiteAndTeal), isTrue);
      expect(
        theme.extension<LudavaThemeTokens>(),
        same(GraphiteTealTheme.colors),
      );
      expect(theme.brightness, GraphiteTealTheme.brightness);
    });
  });
}
