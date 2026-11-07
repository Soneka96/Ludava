import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  group('Class LudavaWindowTitleBar interaction behavior', () {
    testWidgets('Class LudavaWindowTitleBar uses the supplied theme', (
      tester,
    ) async {
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);
      final tokens = GraphiteTealTheme.colors.copyWith(
        surface: const Color(0xFF112233),
        borderSubtle: const Color(0xFF334455),
      );
      final theme = ThemeData.dark().copyWith(extensions: [tokens]);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: LudavaWindowTitleBar(
              session: TrainerSessionState(),
              isMaximized: maximizeState,
              onMinimize: () {},
              onToggleMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ludava-titlebar-surface')),
      );
      expect((surface.decoration as BoxDecoration).color, tokens.surface);
      expect(
        ((surface.decoration as BoxDecoration).border! as Border).bottom.color,
        tokens.borderSubtle,
      );
      final mark = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ludava-titlebar-mark')),
      );
      expect(
        (mark.decoration as BoxDecoration).color,
        theme.colorScheme.secondary,
      );
      expect(find.text('Ludava'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Ludava')).style?.fontWeight,
        theme.textTheme.titleSmall?.fontWeight,
      );
      expect(find.text('RPCS3 Disconnected'), findsOneWidget);
      expect(find.byType(DragToMoveArea), findsOneWidget);
      expect(find.byTooltip('Minimize window'), findsOneWidget);
      expect(find.byTooltip('Maximize window'), findsOneWidget);
      expect(find.byTooltip('Close window'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('ludava-titlebar-surface')))
            .height,
        LudavaDimensions.titleBarHeight,
      );
      expect(
        tester.getSize(find.byTooltip('Minimize window')).width,
        LudavaDimensions.minimumInteractiveTarget,
      );
      expect(
        tester.getSize(find.byTooltip('Maximize window')).width,
        LudavaDimensions.minimumInteractiveTarget,
      );
      expect(
        tester.getSize(find.byTooltip('Close window')).width,
        LudavaDimensions.minimumInteractiveTarget,
      );

      final controls = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(
        controls.map((control) => control.tooltip),
        contains('Minimize window'),
      );
      expect(
        controls.map((control) => control.tooltip),
        contains('Maximize window'),
      );
      expect(
        controls.map((control) => control.tooltip),
        contains('Close window'),
      );

      maximizeState.value = true;
      await tester.pump();
      expect(find.byTooltip('Restore window'), findsOneWidget);
      expect(find.byIcon(Icons.filter_none_rounded), findsOneWidget);
    });

    testWidgets('Class LudavaWindowTitleBar fits narrow and wide widths', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 120);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: LudavaTheme.graphiteAndTeal,
          home: Scaffold(
            body: LudavaWindowTitleBar(
              session: TrainerSessionState(),
              isMaximized: maximizeState,
              onMinimize: () {},
              onToggleMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ludava'), findsOneWidget);

      tester.view.physicalSize = const Size(1180, 120);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Ludava'), findsOneWidget);
    });

    testWidgets('Class LudavaWindowTitleBar invokes each window action', (
      tester,
    ) async {
      var minimizeCount = 0;
      var maximizeCount = 0;
      var closeCount = 0;
      final maximizeState = ValueNotifier(false);
      addTearDown(maximizeState.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: LudavaTheme.graphiteAndTeal,
          home: Scaffold(
            body: LudavaWindowTitleBar(
              session: TrainerSessionState(processIds: const [10]),
              isMaximized: maximizeState,
              onMinimize: () => minimizeCount++,
              onToggleMaximize: () => maximizeCount++,
              onClose: () => closeCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Minimize window'));
      await tester.tap(find.byTooltip('Maximize window'));
      await tester.tap(find.byTooltip('Close window'));

      expect(find.text('RPCS3 Connected'), findsOneWidget);
      expect(minimizeCount, 1);
      expect(maximizeCount, 1);
      expect(closeCount, 1);
    });
  });
}
