import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/usecases/write_game_field.usecase.dart';

/// Parameters for [WriteGameFieldUseCase].
class WriteGameFieldParams {
  /// Profile that declares the selected field.
  final GameProfile profile;

  /// Stable identifier of the selected field.
  final String fieldId;

  /// Session-specific base used to resolve the field address.
  final int memoryBase;

  /// Value requested for the selected field.
  final int value;

  /// Whether the user explicitly confirmed this write request.
  final bool confirmed;

  /// Creates parameters for one profile-field write.
  const WriteGameFieldParams({
    required this.profile,
    required this.fieldId,
    required this.memoryBase,
    required this.value,
    required this.confirmed,
  });
}
