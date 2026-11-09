import 'package:equatable/equatable.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';

/// Contains the immutable Redux state owned by the Flutter application.
class AppState extends Equatable {
  /// Trainer session and transient edit state.
  final TrainerState trainer;

  /// State values used by Equatable without comparing SDK snapshot contents.
  @override
  List<Object?> get props => [trainer];

  /// Creates application state from the initial [trainer] state.
  const AppState({required this.trainer});
}
