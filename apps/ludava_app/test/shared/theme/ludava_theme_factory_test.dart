import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Method LudavaThemeFactory.build() behaves correctly', () {
    test(
      'Method LudavaThemeFactory.build() maps semantic roles to Material',
      () {
        final colors = GraphiteTealTheme.colors;
        final theme = LudavaThemeFactory.build(
          colors: colors,
          style: LudavaStylePresets.comfortable,
        );
        final scheme = theme.colorScheme;

        expect(theme.brightness, Brightness.dark);
        expect(theme.scaffoldBackgroundColor, colors.canvas);
        expect(theme.extension<LudavaThemeTokens>(), same(colors));
        expect(scheme.primary, colors.accent);
        expect(scheme.onPrimary, colors.onAccent);
        expect(scheme.secondary, colors.accent);
        expect(scheme.tertiary, colors.information);
        expect(scheme.error, colors.error);
        expect(scheme.surface, colors.surface);
        expect(scheme.onSurface, colors.textPrimary);
        expect(scheme.outline, colors.borderDefault);
        expect(scheme.outlineVariant, colors.borderSubtle);
        expect(scheme.surfaceContainerHighest, colors.surfacePressed);
      },
    );

    test(
      'Method LudavaThemeFactory.build() uses Comfortable control styles',
      () {
        final theme = LudavaThemeFactory.build(
          colors: GraphiteTealTheme.colors,
          style: LudavaStylePresets.comfortable,
        );
        final style = LudavaStylePresets.comfortable;
        final filled = theme.filledButtonTheme.style!;
        final outlined = theme.outlinedButtonTheme.style!;
        final input = theme.inputDecorationTheme;
        final shape = filled.shape!.resolve({})! as RoundedRectangleBorder;

        expect(
          theme.textTheme.titleSmall?.fontSize,
          style.textTheme.titleSmall?.fontSize,
        );
        expect(filled.minimumSize!.resolve({}), style.buttonMinimumSize);
        expect(outlined.padding!.resolve({}), style.buttonPadding);
        expect(shape.borderRadius, BorderRadius.circular(style.controlRadius));
        expect(input.contentPadding, style.inputPadding);
        expect(
          (input.focusedBorder! as OutlineInputBorder).borderRadius,
          BorderRadius.circular(style.controlRadius),
        );
        expect(
          (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(style.surfaceRadius),
        );
      },
    );

    testWidgets(
      'Method LudavaThemeFactory.build() styles Ludava and Material widgets from alternate colors',
      (tester) async {
        final colors = GraphiteTealTheme.colors.copyWith(
          surface: Colors.deepPurple,
          accent: Colors.lime,
          onAccent: Colors.black,
          focus: Colors.orange,
        );
        final theme = LudavaThemeFactory.build(
          colors: colors,
          style: LudavaStylePresets.comfortable,
        );
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  LudavaWindowTitleBar(
                    session: TrainerSessionState(),
                    isMaximized: maximizeState,
                    onMinimize: () {},
                    onToggleMaximize: () {},
                    onClose: () {},
                  ),
                  FilledButton(onPressed: () {}, child: const Text('Apply')),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Value'),
                  ),
                ],
              ),
            ),
          ),
        );

        final titleBar = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('ludava-titlebar-surface')),
        );
        expect((titleBar.decoration as BoxDecoration).color, colors.surface);
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          colors.accent,
        );
        final buttonMaterial = tester.widget<Material>(
          find
              .ancestor(of: find.text('Apply'), matching: find.byType(Material))
              .first,
        );
        expect(buttonMaterial.color, colors.accent);

        final input = tester.widget<InputDecorator>(
          find.descendant(
            of: find.byType(TextField),
            matching: find.byType(InputDecorator),
          ),
        );
        expect(
          (input.decoration.focusedBorder! as OutlineInputBorder)
              .borderSide
              .color,
          colors.focus,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
