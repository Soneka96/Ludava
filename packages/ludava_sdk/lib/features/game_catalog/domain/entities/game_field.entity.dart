import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Describes one named value that a [GameProfile] can read or write.
class GameField {
  /// Stable identifier used to select the field.
  final String id;

  /// Human-readable field name.
  final String name;

  /// Game-relative address of the value.
  final int guestOffset;

  /// Binary representation selected from [MemoryValueType].
  final MemoryValueType valueType;

  /// Byte order selected from [ByteOrder].
  final ByteOrder byteOrder;

  /// Lowest value allowed for a write, when bounded.
  final int? minimumValue;

  /// Highest value allowed for a write, when bounded.
  final int? maximumValue;

  GameField._({
    required this.id,
    required this.name,
    required this.guestOffset,
    required this.valueType,
    required this.byteOrder,
    required this.minimumValue,
    required this.maximumValue,
  });

  /// Creates a field with its address, encoding, and optional write bounds.
  ///
  /// Bounds must fit in an unsigned 32-bit value and, when both are supplied,
  /// [minimumValue] must not exceed [maximumValue].
  factory GameField({
    required String id,
    required String name,
    required int guestOffset,
    required MemoryValueType valueType,
    required ByteOrder byteOrder,
    int? minimumValue,
    int? maximumValue,
  }) {
    _validateBounds(minimumValue, maximumValue);
    return GameField._(
      id: id,
      name: name,
      guestOffset: guestOffset,
      valueType: valueType,
      byteOrder: byteOrder,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
    );
  }

  static void _validateBounds(int? minimumValue, int? maximumValue) {
    if (minimumValue != null &&
        (minimumValue < 0 ||
            minimumValue > GameMemoryConstants.maxUnsigned32)) {
      throw ArgumentError.value(
        minimumValue,
        'minimumValue',
        'must fit an unsigned 32-bit value',
      );
    }
    if (maximumValue != null &&
        (maximumValue < 0 ||
            maximumValue > GameMemoryConstants.maxUnsigned32)) {
      throw ArgumentError.value(
        maximumValue,
        'maximumValue',
        'must fit an unsigned 32-bit value',
      );
    }
    if (minimumValue != null &&
        maximumValue != null &&
        minimumValue > maximumValue) {
      throw ArgumentError.value(
        maximumValue,
        'maximumValue',
        'must not be less than minimumValue',
      );
    }
  }
}
