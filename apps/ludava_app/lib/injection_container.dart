import 'package:get_it/get_it.dart';
import 'package:ludava_app/app/presentation/state/ludava_session_body_view_model.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_middleware.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/trainer.injection_container.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:redux/redux.dart';

/// GetIt instance used by Flutter app composition and feature containers.
final GetIt sl = GetIt.instance;

/// Registers app-wide dependencies in their required composition order.
void initDependencies({TrainerSdkCapability? trainerSdkCapability}) {
  initTrainerDependencies(capability: trainerSdkCapability);
  final initialSession = sl<TrainerSdkCapability>().state;
  sl.registerSingleton<Store<AppState>>(
    Store<AppState>(
      appReducer,
      initialState: AppState(trainer: TrainerState(session: initialSession)),
      middleware: [TrainerMiddleware().call],
    ),
  );
  sl.registerFactoryParam<TrainerFieldsViewModel, Store<AppState>, void>(
    (store, _) => TrainerFieldsViewModel.fromStore(store),
  );
  sl.registerFactoryParam<TrainerGameHeaderViewModel, Store<AppState>, void>(
    (store, _) => TrainerGameHeaderViewModel.fromStore(store),
  );
  sl.registerFactoryParam<LudavaSessionBodyViewModel, Store<AppState>, void>(
    (store, _) => LudavaSessionBodyViewModel.fromStore(store),
  );
  sl.registerFactoryParam<
    Rpcs3ConnectionIndicatorViewModel,
    Store<AppState>,
    void
  >((store, _) => Rpcs3ConnectionIndicatorViewModel.fromStore(store));
}
