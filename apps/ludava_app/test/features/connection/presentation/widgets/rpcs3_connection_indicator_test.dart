import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_indicator.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

class _MockConnectionIndicatorViewModel extends Mock
    implements Rpcs3ConnectionIndicatorViewModel {}

Widget _wrap(Store<AppState> store, {Key? key}) => StoreProvider<AppState>(
  key: key,
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: Rpcs3ConnectionIndicator()),
  ),
);

void main() {
  late _MockConnectionIndicatorViewModel viewModel;

  setUp(() {
    sl.pushNewScope();
    sl.registerFactoryParam<
      Rpcs3ConnectionIndicatorViewModel,
      Store<AppState>,
      void
    >((store, _) => viewModel);
  });

  tearDown(() async => sl.popScope());

  group('Class Rpcs3ConnectionIndicator presentation behavior', () {
    testWidgets('Class Rpcs3ConnectionIndicator shows process status and semantics', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      addTearDown(semanticsHandle.dispose);
      final tokens = LudavaTheme.graphiteAndTeal
          .extension<LudavaThemeTokens>()!;
      final store = Store<AppState>(
        (state, action) => state,
        initialState: AppState(
          trainer: TrainerState(session: TrainerSessionState()),
        ),
      );
      final cases = <(List<int>, int?, String, Color)>[
        (const [], null, 'RPCS3 not detected', tokens.textMuted),
        (
          const [42],
          null,
          'RPCS3 detected · awaiting process selection',
          tokens.warning,
        ),
        (
          const [42, 84],
          null,
          'RPCS3 detected · select one of 2 processes',
          tokens.warning,
        ),
        (
          const [42],
          42,
          'RPCS3 connected · process 42',
          tokens.success,
        ),
        (
          const [84],
          42,
          'RPCS3 detected · awaiting process selection',
          tokens.warning,
        ),
      ];

      for (var index = 0; index < cases.length; index++) {
        final (ids, selectedId, message, color) = cases[index];
        viewModel = _MockConnectionIndicatorViewModel();
        when(() => viewModel.processIds).thenReturn(ids);
        when(() => viewModel.selectedProcessId).thenReturn(selectedId);
        await tester.pumpWidget(_wrap(store, key: ValueKey(index)));

        expect(
          tester.widgetList<Tooltip>(find.byType(Tooltip)).single.message,
          message,
        );
        expect(find.bySemanticsLabel(message), findsOneWidget);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.circle_rounded)).color,
          color,
        );
        expect(tester.widget<Text>(find.text('RPCS3')).style?.color, color);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
