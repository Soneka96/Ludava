import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/usecases/read_game_field.usecase.dart';

/// Parameters for [ReadGameFieldUseCase].
class ReadGameFieldParams {
  /// Profile that declares the selected field.
  final GameProfile profile;

  /// Stable identifier of the selected field.
  final String fieldId;

  /// Session-specific base used to resolve the field address.
  final int memoryBase;

  /// Creates parameters for one profile-field read.
  const ReadGameFieldParams({
    required this.profile,
    required this.fieldId,
    required this.memoryBase,
  });
}
