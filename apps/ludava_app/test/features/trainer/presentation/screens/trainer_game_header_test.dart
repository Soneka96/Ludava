import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

import '../../../../support/trainer_state_fixture.dart';

class _MockTrainerGameHeaderViewModel extends Mock
    implements TrainerGameHeaderViewModel {}

_MockTrainerGameHeaderViewModel _viewModel({
  GameProfile? profile,
  String? detectedTitle,
  List<int> processIds = const [],
  int? selectedProcessId,
  GameDetectionStatus? detectionStatus,
  bool hasMemoryBase = false,
  String? errorMessage,
  VoidCallback? onRefresh,
}) {
  final viewModel = _MockTrainerGameHeaderViewModel();
  when(() => viewModel.profile).thenReturn(profile);
  when(() => viewModel.detectedTitle).thenReturn(detectedTitle);
  when(() => viewModel.processIds).thenReturn(processIds);
  when(() => viewModel.selectedProcessId).thenReturn(selectedProcessId);
  when(() => viewModel.detectionStatus).thenReturn(detectionStatus);
  when(() => viewModel.hasMemoryBase).thenReturn(hasMemoryBase);
  when(() => viewModel.errorMessage).thenReturn(errorMessage);
  when(() => viewModel.onRefresh).thenReturn(onRefresh ?? () {});
  return viewModel;
}

Widget _wrap(Store<AppState> store) => StoreProvider<AppState>(
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: TrainerGameHeader()),
  ),
);

void main() {
  const refreshLabel = 'Refresh values or rediscover RPCS3';
  late _MockTrainerGameHeaderViewModel viewModel;
  late Store<AppState> store;

  setUp(() {
    sl.pushNewScope();
    store = Store<AppState>(
      (state, action) => state,
      initialState: AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      ),
    );
    sl.registerFactoryParam<TrainerGameHeaderViewModel, Store<AppState>, void>(
      (store, _) => viewModel,
    );
  });

  tearDown(() async => sl.popScope());

  group('Class TrainerGameHeader presentation behavior', () {
    testWidgets(
      'Class TrainerGameHeader exposes one accessible refresh callback',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          var refreshCalls = 0;
          viewModel = _viewModel(onRefresh: () => refreshCalls++);
          await tester.pumpWidget(_wrap(store));

          final refresh = find.byTooltip(refreshLabel);
          expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
          expect(find.byType(IconButton), findsOneWidget);
          expect(refresh, findsOneWidget);
          expect(find.text('Connect to RPCS3'), findsOneWidget);
          expect(
            tester.getSize(find.byType(IconButton)).width,
            greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
          );
          expect(
            tester.getSize(find.byType(IconButton)).height,
            greaterThanOrEqualTo(LudavaDimensions.minimumInteractiveTarget),
          );
          final semantics = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == refreshLabel,
          );
          expect(semantics, findsOneWidget);
          expect(
            tester.getSemantics(semantics).flagsCollection.isButton,
            isTrue,
          );
          expect(find.text('Re-detect'), findsNothing);

          await tester.tap(refresh);

          expect(refreshCalls, 1);
          expect(tester.takeException(), isNull);
        } finally {
          semanticsHandle.dispose();
        }
      },
    );

    testWidgets(
      'Class TrainerGameHeader keeps long game identity and refresh in minimum width',
      (tester) async {
        const longTitle =
            'A Very Long Synthetic Game Title That Must Stay Inside the Header';
        tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        viewModel = _viewModel(
          profile: trainerStateFixtureSession(gameName: longTitle).profile,
          processIds: const [42],
          selectedProcessId: 42,
          detectionStatus: GameDetectionStatus.supportedGame,
          hasMemoryBase: true,
        );
        await tester.pumpWidget(_wrap(store));

        final title = tester.widget<Text>(find.text(longTitle));
        final titleRect = tester.getRect(find.text(longTitle));
        final refreshRect = tester.getRect(find.byTooltip(refreshLabel));
        expect(title.maxLines, 1);
        expect(title.overflow, TextOverflow.ellipsis);
        expect(titleRect.left, greaterThanOrEqualTo(0));
        expect(
          titleRect.right,
          lessThanOrEqualTo(LudavaDimensions.minimumWindowWidth),
        );
        expect(refreshRect.left, greaterThanOrEqualTo(0));
        expect(
          refreshRect.right,
          lessThanOrEqualTo(LudavaDimensions.minimumWindowWidth),
        );
        expect(
          find.byTooltip(
            '$longTitle\nBuild ID: test-build\nRPCS3 process ID: 42',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Build ID'), findsNothing);
        expect(find.textContaining('RPCS3 process ID'), findsNothing);
        expect(find.byTooltip(refreshLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerGameHeader treats a stale process as unselected',
      (tester) async {
        viewModel = _viewModel(
          processIds: const [84],
          selectedProcessId: 42,
          detectionStatus: GameDetectionStatus.supportedGame,
          hasMemoryBase: true,
        );
        await tester.pumpWidget(_wrap(store));

        expect(find.text('RPCS3 detected'), findsOneWidget);
        expect(
          find.byTooltip('RPCS3 detected\nAvailable process IDs: 84'),
          findsOneWidget,
        );
        expect(find.text('Choose process'), findsOneWidget);
        expect(find.text('Ready'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class TrainerGameHeader shows the attention state for SDK errors',
      (tester) async {
        viewModel = _viewModel(
          processIds: const [42],
          selectedProcessId: 42,
          detectionStatus: GameDetectionStatus.supportedGame,
          hasMemoryBase: true,
          errorMessage: 'The session refresh failed.',
        );
        await tester.pumpWidget(_wrap(store));

        expect(find.text('Attention'), findsOneWidget);
        expect(find.text('Ready'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
