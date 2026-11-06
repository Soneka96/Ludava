import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Formats game-memory outcomes for terminal display.
abstract final class GameMemoryOutput {
  /// Formats [result] for [profile], disclosing whether runtime identity matched.
  ///
  /// Set [identityConfirmed] only when current-session identity matched the
  /// selected profile.
  static String readResult(
    GameProfile profile,
    GameReadResult result, {
    bool identityConfirmed = false,
  }) {
    final lines = [
      'Game: ${profile.gameName} (${profile.id})',
      'Build: ${profile.buildId}',
      'Profile status: ${profile.readStatus.name}',
      _runtimeIdentityNote(identityConfirmed),
    ];
    switch (result.status) {
      case GameReadStatus.success:
        if (!result.succeeded) {
          lines.add('Status: invalid read result');
        } else {
          lines.add('Status: read complete');
          lines.add('Field: ${result.fieldId}');
          lines.add('Value: ${result.value}');
        }
      case GameReadStatus.none:
        lines.add('Status: no read attempted');
      case GameReadStatus.unsupportedProfile:
        lines.add('Status: profile is not approved for reading');
      case GameReadStatus.unsupportedField:
        lines.add('Status: field is not approved for reading');
      case GameReadStatus.invalidMapping:
        lines.add('Status: invalid memory mapping');
      case GameReadStatus.readFailed:
        lines.add('Status: native memory read failed');
      case GameReadStatus.incompleteRead:
        lines.add('Status: incomplete memory read');
      case GameReadStatus.invalidReadResult:
        lines.add('Status: invalid memory read result');
    }
    if (result.errorCode != null) {
      lines.add('Windows error: ${result.errorCode}');
    }
    return lines.join('\n');
  }

  /// Formats [result] for [profile], disclosing whether runtime identity matched.
  ///
  /// Set [identityConfirmed] only when current-session identity matched the
  /// selected profile.
  static String writeResult(
    GameProfile profile,
    GameWriteResult result, {
    bool identityConfirmed = false,
  }) {
    final lines = [
      'Game: ${profile.gameName} (${profile.id})',
      'Build: ${profile.buildId}',
      'Profile status: ${profile.writeStatus.name}',
      _runtimeIdentityNote(identityConfirmed),
    ];
    switch (result.status) {
      case GameWriteStatus.success:
        lines.add(
          result.succeeded
              ? 'Status: write and read-back complete'
              : 'Status: invalid write result',
        );
      case GameWriteStatus.none:
        lines.add('Status: no write attempted');
      case GameWriteStatus.unsupportedProfile:
        lines.add('Status: profile is not approved for writing');
      case GameWriteStatus.confirmationRequired:
        lines.add('Status: explicit write confirmation is required');
      case GameWriteStatus.unsupportedField:
        lines.add('Status: field is not approved for writing');
      case GameWriteStatus.invalidValue:
        lines.add('Status: value is outside the field range');
      case GameWriteStatus.invalidMapping:
        lines.add('Status: invalid memory mapping');
      case GameWriteStatus.preliminaryReadFailed:
        lines.add('Status: preliminary memory read failed');
      case GameWriteStatus.writeFailed:
        lines.add('Status: native memory write failed');
      case GameWriteStatus.incompleteWrite:
        lines.add('Status: incomplete memory write');
      case GameWriteStatus.readBackFailed:
        lines.add('Status: write read-back failed');
      case GameWriteStatus.readBackMismatch:
        lines.add('Status: read-back did not match the requested value');
      case GameWriteStatus.invalidWriteResult:
        lines.add('Status: invalid memory write result');
    }
    if (result.fieldId != null) lines.add('Field: ${result.fieldId}');
    if (result.requestedValue != null) {
      lines.add('Requested value: ${result.requestedValue}');
    }
    if (result.readBackValue != null) {
      lines.add('Read-back value: ${result.readBackValue}');
    }
    if (result.errorCode != null) {
      lines.add('Windows error: ${result.errorCode}');
    }
    return lines.join('\n');
  }

  static String _runtimeIdentityNote(bool identityConfirmed) =>
      identityConfirmed
          ? 'Runtime identity: the current RPCS3 PPU hash matches this profile.'
          : 'Runtime identity: profile selection is manual or unverified.';
}
