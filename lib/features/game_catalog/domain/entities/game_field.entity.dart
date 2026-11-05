import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';

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

  /// Evidence status for reading this field from [VerificationStatus].
  final VerificationStatus readStatus;

  /// Evidence status for writing this field from [VerificationStatus].
  final VerificationStatus writeStatus;

  /// Lowest value allowed for a verified write, when bounded.
  final int? minimumValue;

  /// Highest value allowed for a verified write, when bounded.
  final int? maximumValue;

  GameField._({
    required this.id,
    required this.name,
    required this.guestOffset,
    required this.valueType,
    required this.byteOrder,
    required this.readStatus,
    required this.writeStatus,
    required this.minimumValue,
    required this.maximumValue,
  });

  /// Creates a field with its address, encoding, evidence status, and bounds.
  ///
  /// Bounds must fit in an unsigned 32-bit value and, when both are supplied,
  /// [minimumValue] must not exceed [maximumValue].
  factory GameField({
    required String id,
    required String name,
    required int guestOffset,
    required MemoryValueType valueType,
    required ByteOrder byteOrder,
    required VerificationStatus readStatus,
    VerificationStatus writeStatus = VerificationStatus.none,
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
      readStatus: readStatus,
      writeStatus: writeStatus,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
    );
  }

  /// Whether recorded evidence permits reading this field.
  bool get canRead =>
      readStatus == VerificationStatus.experimental ||
      readStatus == VerificationStatus.verified;

  /// Whether recorded evidence permits writing this field.
  bool get canWrite =>
      writeStatus == VerificationStatus.researchConfirmed ||
      writeStatus == VerificationStatus.verified;

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
