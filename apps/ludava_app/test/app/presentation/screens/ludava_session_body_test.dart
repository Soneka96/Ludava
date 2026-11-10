import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/app/presentation/screens/ludava_session_body.dart';
import 'package:ludava_app/app/presentation/state/ludava_session_body_view_model.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

class _MockLudavaSessionBodyViewModel extends Mock
    implements LudavaSessionBodyViewModel {}

class _MockTrainerFieldsViewModel extends Mock
    implements TrainerFieldsViewModel {}

_MockLudavaSessionBodyViewModel _viewModel({
  bool isReady = false,
  List<int> processIds = const [],
  int? selectedProcessId,
  GameDetectionResult? detection,
  bool hasMemoryBase = false,
  String? errorMessage,
  ValueChanged<int>? onSelectProcess,
}) {
  final viewModel = _MockLudavaSessionBodyViewModel();
  when(() => viewModel.isReady).thenReturn(isReady);
  when(() => viewModel.processIds).thenReturn(processIds);
  when(() => viewModel.selectedProcessId).thenReturn(selectedProcessId);
  when(() => viewModel.detection).thenReturn(detection);
  when(() => viewModel.hasMemoryBase).thenReturn(hasMemoryBase);
  when(() => viewModel.errorMessage).thenReturn(errorMessage);
  when(() => viewModel.onSelectProcess).thenReturn(onSelectProcess ?? (_) {});
  return viewModel;
}

Widget _wrap(Store<AppState> store, {Key? key}) => StoreProvider<AppState>(
  key: key,
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: LudavaSessionBody()),
  ),
);

void main() {
  late Store<AppState> store;
  late _MockLudavaSessionBodyViewModel viewModel;
  late _MockTrainerFieldsViewModel fieldsViewModel;

  setUp(() {
    sl.pushNewScope();
    store = Store<AppState>(
      (state, action) => state,
      initialState: AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      ),
    );
    fieldsViewModel = _MockTrainerFieldsViewModel();
    when(() => fieldsViewModel.hasProfile).thenReturn(false);
    sl.registerFactoryParam<LudavaSessionBodyViewModel, Store<AppState>, void>(
      (store, _) => viewModel,
    );
    sl.registerFactoryParam<TrainerFieldsViewModel, Store<AppState>, void>(
      (store, _) => fieldsViewModel,
    );
  });

  tearDown(() async => sl.popScope());

  group('Class LudavaSessionBody composition behavior', () {
    testWidgets(
      'Class LudavaSessionBody forwards connection state and selection callback',
      (tester) async {
        final detection = GameDetectionResult(
          status: GameDetectionStatus.ambiguous,
          processId: 43,
          gameTitle: 'Synthetic title',
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'Synthetic process evidence.',
        );
        const errorMessage = 'Synthetic process metadata error.';
        final selected = <int>[];
        viewModel = _viewModel(
          processIds: const [42, 43],
          selectedProcessId: 43,
          detection: detection,
          hasMemoryBase: true,
          errorMessage: errorMessage,
          onSelectProcess: selected.add,
        );
        await tester.pumpWidget(_wrap(store));

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanel), findsNothing);
        final connection = tester.widget<SessionConnectionBody>(
          find.byType(SessionConnectionBody),
        );
        expect(connection.processIds, const [42, 43]);
        expect(connection.selectedProcessId, 43);
        expect(connection.detection, same(detection));
        expect(connection.hasMemoryBase, isTrue);
        expect(connection.errorMessage, errorMessage);
        connection.onSelectProcess(43);
        expect(selected, [43]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaSessionBody composes ready fields and keeps feedback height stable',
      (tester) async {
        const errorMessage =
            'A long synthetic session failure that should remain discoverable '
            'without changing the fixed feedback region height.';
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          double? heightWithoutError;
          for (final message in <String?>[null, errorMessage]) {
            viewModel = _viewModel(isReady: true, errorMessage: message);
            await tester.pumpWidget(
              _wrap(store, key: ValueKey('$size-$message')),
            );

            expect(find.byType(SessionConnectionBody), findsNothing);
            expect(find.byType(TrainerFieldsPanel), findsOneWidget);
            final feedbackRegion = find.byKey(
              const ValueKey('session-feedback-region'),
            );
            final feedbackHeight = tester.getSize(feedbackRegion).height;
            expect(feedbackHeight, LudavaDimensions.sessionFeedbackHeight);
            if (message == null) {
              heightWithoutError = feedbackHeight;
              expect(find.byTooltip(errorMessage), findsNothing);
            } else {
              expect(feedbackHeight, heightWithoutError);
              expect(find.byTooltip(errorMessage), findsOneWidget);
              final feedbackText = tester.widget<Text>(find.text(errorMessage));
              expect(feedbackText.maxLines, 1);
              expect(feedbackText.overflow, TextOverflow.ellipsis);
              expect(
                feedbackText.style?.color,
                LudavaTheme.graphiteAndTeal.colorScheme.error,
              );
            }
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });
}
