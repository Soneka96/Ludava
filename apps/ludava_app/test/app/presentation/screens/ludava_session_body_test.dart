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
  when(
    () => viewModel.onSelectProcess,
  ).thenReturn(onSelectProcess ?? (_) {});
  return viewModel;
}

Widget _wrap(Store<AppState> store) => StoreProvider<AppState>(
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: LudavaSessionBody()),
  ),
);

void main() {
  late Store<AppState> store;
  late _MockLudavaSessionBodyViewModel viewModel;

  setUp(() {
    sl.pushNewScope();
    store = Store<AppState>(
      (state, action) => state,
      initialState: AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      ),
    );
    sl.registerFactoryParam<LudavaSessionBodyViewModel, Store<AppState>, void>(
      (store, _) => viewModel,
    );
    sl.registerFactoryParam<TrainerFieldsViewModel, Store<AppState>, void>(
      (store, _) => TrainerFieldsViewModel.fromStore(store),
    );
  });

  tearDown(() async => sl.popScope());

  group('Class LudavaSessionBody composition behavior', () {
    testWidgets(
      'Class LudavaSessionBody forwards connection state and selection callback',
      (tester) async {
        final selected = <int>[];
        viewModel = _viewModel(
          processIds: const [42, 43],
          onSelectProcess: selected.add,
        );
        await tester.pumpWidget(_wrap(store));

        expect(find.byType(SessionConnectionBody), findsOneWidget);
        expect(find.byType(TrainerFieldsPanel), findsNothing);
        final connection = tester.widget<SessionConnectionBody>(
          find.byType(SessionConnectionBody),
        );
        expect(connection.processIds, const [42, 43]);
        connection.onSelectProcess(43);
        expect(selected, [43]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaSessionBody composes trainer fields and fixed feedback when ready',
      (tester) async {
        const errorMessage = 'Synthetic session failure';
        viewModel = _viewModel(isReady: true, errorMessage: errorMessage);
        await tester.pumpWidget(_wrap(store));

        expect(find.byType(SessionConnectionBody), findsNothing);
        expect(find.byType(TrainerFieldsPanel), findsOneWidget);
        expect(
          tester.getSize(
            find.byKey(const ValueKey('session-feedback-region')),
          ).height,
          LudavaDimensions.sessionFeedbackHeight,
        );
        expect(find.byTooltip(errorMessage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
