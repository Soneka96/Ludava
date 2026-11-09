import 'package:get_it/get_it.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
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
    ),
  );
}
