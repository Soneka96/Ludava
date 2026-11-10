import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

import '../../support/mock_trainer_sdk_capability.dart';

Color _stateOverlayColor(Color color, double opacity) => Color.fromARGB(
  (opacity * 255).round(),
  (color.r * 255).round().clamp(0, 255).toInt(),
  (color.g * 255).round().clamp(0, 255).toInt(),
  (color.b * 255).round().clamp(0, 255).toInt(),
);

void main() {
  group('Method LudavaThemeFactory.build() behaves correctly', () {
    test(
      'Method LudavaThemeFactory.build() maps semantic roles to Material',
      () {
        final colors = GraphiteTealTheme.colors;
        final theme = LudavaThemeFactory.build(
          colors: colors,
          style: LudavaStylePresets.comfortable,
          brightness: GraphiteTealTheme.brightness,
        );
        final scheme = theme.colorScheme;

        expect(theme.brightness, Brightness.dark);
        expect(theme.scaffoldBackgroundColor, colors.canvas);
        expect(theme.extension<LudavaThemeTokens>(), same(colors));
        expect(scheme.brightness, GraphiteTealTheme.brightness);
        expect(scheme.primary, colors.accent);
        expect(scheme.onPrimary, colors.onAccent);
        expect(scheme.primaryContainer, colors.surfaceElevated);
        expect(scheme.onPrimaryContainer, colors.textPrimary);
        expect(scheme.primaryFixed, colors.surfaceElevated);
        expect(scheme.primaryFixedDim, colors.surface);
        expect(scheme.onPrimaryFixed, colors.textPrimary);
        expect(scheme.onPrimaryFixedVariant, colors.textSecondary);
        expect(scheme.secondary, colors.accent);
        expect(scheme.onSecondary, colors.onAccent);
        expect(scheme.secondaryContainer, colors.surfaceElevated);
        expect(scheme.onSecondaryContainer, colors.textPrimary);
        expect(scheme.secondaryFixed, colors.surfaceElevated);
        expect(scheme.secondaryFixedDim, colors.surface);
        expect(scheme.onSecondaryFixed, colors.textPrimary);
        expect(scheme.onSecondaryFixedVariant, colors.textSecondary);
        expect(scheme.tertiary, colors.information);
        expect(scheme.onTertiary, colors.canvas);
        expect(scheme.tertiaryContainer, colors.surfaceElevated);
        expect(scheme.onTertiaryContainer, colors.textPrimary);
        expect(scheme.tertiaryFixed, colors.surfaceElevated);
        expect(scheme.tertiaryFixedDim, colors.surface);
        expect(scheme.onTertiaryFixed, colors.textPrimary);
        expect(scheme.onTertiaryFixedVariant, colors.textSecondary);
        expect(scheme.error, colors.error);
        expect(scheme.onError, colors.canvas);
        expect(scheme.errorContainer, colors.surfacePressed);
        expect(scheme.onErrorContainer, colors.textPrimary);
        expect(scheme.surface, colors.surface);
        expect(scheme.onSurface, colors.textPrimary);
        expect(scheme.surfaceDim, colors.canvas);
        expect(scheme.surfaceBright, colors.borderStrong);
        expect(scheme.surfaceContainerLowest, colors.canvas);
        expect(scheme.surfaceContainerLow, colors.surface);
        expect(scheme.surfaceContainer, colors.surface);
        expect(scheme.surfaceContainerHigh, colors.surfaceElevated);
        expect(scheme.surfaceContainerHighest, colors.surfacePressed);
        expect(scheme.onSurfaceVariant, colors.textSecondary);
        expect(scheme.outline, colors.borderDefault);
        expect(scheme.outlineVariant, colors.borderSubtle);
        expect(scheme.shadow, colors.canvas);
        expect(scheme.scrim, colors.canvas.withValues(alpha: 0.32));
        expect(scheme.inverseSurface, colors.textPrimary);
        expect(scheme.onInverseSurface, colors.canvas);
        expect(scheme.inversePrimary, colors.accent);
        expect(scheme.surfaceTint, colors.accent);
      },
    );

    test('Method LudavaThemeFactory.build() uses its declared brightness without seed colors', () {
      final colors = GraphiteTealTheme.colors.copyWith(accent: Colors.purple);
      final theme = LudavaThemeFactory.build(
        colors: colors,
        style: LudavaStylePresets.comfortable,
        brightness: Brightness.light,
      );

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, Colors.purple);
    });

    test(
      'Method LudavaThemeFactory.build() uses Comfortable control styles',
      () {
        final colors = GraphiteTealTheme.colors;
        final theme = LudavaThemeFactory.build(
          colors: colors,
          style: LudavaStylePresets.comfortable,
          brightness: GraphiteTealTheme.brightness,
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
        final focusedBorder = input.focusedBorder! as OutlineInputBorder;
        final focusedErrorBorder =
            input.focusedErrorBorder! as OutlineInputBorder;
        expect(
          focusedBorder.borderRadius,
          BorderRadius.circular(style.controlRadius),
        );
        expect(focusedBorder.borderSide.width, style.inputFocusedBorderWidth);
        expect(focusedBorder.borderSide.color, colors.focus);
        expect(
          focusedErrorBorder.borderSide.width,
          style.inputFocusedBorderWidth,
        );
        expect(focusedErrorBorder.borderSide.color, colors.error);
        expect(
          (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(style.surfaceRadius),
        );
      },
    );

    test('Method LudavaThemeFactory.build() centralizes text and icon interaction states', () {
      final colors = GraphiteTealTheme.colors;
      final theme = LudavaThemeFactory.build(
        colors: colors,
        style: LudavaStylePresets.comfortable,
        brightness: GraphiteTealTheme.brightness,
      );
      final textButton = theme.textButtonTheme.style!;
      final iconButton = theme.iconButtonTheme.style!;

      expect(
        textButton.foregroundColor!.resolve({WidgetState.disabled}),
        colors.textDisabled,
      );
      expect(
        textButton.overlayColor!.resolve({WidgetState.hovered}),
        _stateOverlayColor(colors.accent, 0.08),
      );
      expect(
        textButton.overlayColor!.resolve({WidgetState.focused}),
        _stateOverlayColor(colors.accent, 0.1),
      );
      expect(
        iconButton.foregroundColor!.resolve({WidgetState.disabled}),
        colors.textDisabled,
      );
      expect(
        iconButton.overlayColor!.resolve({WidgetState.hovered}),
        colors.surfaceHover.withValues(alpha: 0.08),
      );
      expect(
        iconButton.overlayColor!.resolve({WidgetState.focused}),
        colors.focus.withValues(alpha: 0.12),
      );
    });

    testWidgets(
      'Method LudavaThemeFactory.build() styles Ludava and Material widgets from alternate colors',
      (tester) async {
        sl.pushNewScope();
        final capability = MockTrainerSdkCapability();
        when(() => capability.state).thenReturn(TrainerSessionState());
        initDependencies(trainerSdkCapability: capability);
        addTearDown(() async {
          await sl.popScope();
        });
        final colors = GraphiteTealTheme.colors.copyWith(
          surface: Colors.deepPurple,
          accent: Colors.lime,
          onAccent: Colors.black,
          focus: Colors.orange,
        );
        final theme = LudavaThemeFactory.build(
          colors: colors,
          style: LudavaStylePresets.comfortable,
          brightness: GraphiteTealTheme.brightness,
        );
        final maximizeState = ValueNotifier(false);
        addTearDown(maximizeState.dispose);

        await tester.pumpWidget(
          StoreProvider<AppState>(
            store: sl<Store<AppState>>(),
            child: MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Column(
                  children: [
                    LudavaWindowTitleBar(
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

