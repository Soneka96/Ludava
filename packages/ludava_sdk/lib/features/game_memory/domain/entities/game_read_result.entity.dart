import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Contains the outcome of reading one selected [GameField].
class GameReadResult {
  /// Final status of the attempted read from [GameReadStatus].
  final GameReadStatus status;

  /// Identifier of the selected field, if one was resolved.
  final String? fieldId;

  /// Decoded value using the selected field's [GameField.valueType].
  final int? value;

  /// Native error code when the process API reports one.
  final int? errorCode;

  /// Creates a read result with an optional decoded value or native error.
  const GameReadResult({
    required this.status,
    this.fieldId,
    this.value,
    this.errorCode,
  });

  /// Whether a successful status includes its field identifier and value.
  bool get succeeded =>
      status == GameReadStatus.success &&
      fieldId?.isNotEmpty == true &&
      value != null;
}
