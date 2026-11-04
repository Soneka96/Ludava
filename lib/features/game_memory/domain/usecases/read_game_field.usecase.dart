import 'dart:typed_data';

import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/repositories/Igame_memory.repository.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava/features/game_memory/domain/utils/address_resolver.dart';
import 'package:ludava/features/game_memory/domain/utils/value_decoder.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Reads one eligible [GameField] from its [GameProfile].
class ReadGameFieldUseCase {
  /// Creates the use case with its memory repository.
  ReadGameFieldUseCase(this._repository);

  final IGameMemoryRepository _repository;

  /// Resolves, reads, validates, and decodes [params].
  GameReadResult execute(ReadGameFieldParams params) {
    if (!params.profile.canRead) {
      return const GameReadResult(status: GameReadStatus.unsupportedProfile);
    }
    final field = params.profile.findField(params.fieldId);
    if (field == null || !field.canRead) {
      return GameReadResult(
        status: GameReadStatus.unsupportedField,
        fieldId: params.fieldId,
      );
    }
    final byteLength = field.valueType.byteLength;
    if (byteLength == null) {
      return GameReadResult(
        status: GameReadStatus.invalidReadResult,
        fieldId: field.id,
      );
    }

    late final int address;
    try {
      address = AddressResolver.resolve(
        memoryBase: params.memoryBase,
        guestOffset: field.guestOffset,
        byteLength: byteLength,
      );
    } on ArgumentError {
      return GameReadResult(
        status: GameReadStatus.invalidMapping,
        fieldId: field.id,
      );
    }

    final read = _repository.read(address, byteLength);
    return _resultForRead(field, read, byteLength);
  }

  GameReadResult _resultForRead(
    GameField field,
    MemoryReadResult read,
    int byteLength,
  ) {
    switch (read.status) {
      case MemoryReadStatus.complete:
        if (!read.isComplete || read.bytes.length != byteLength) {
          return GameReadResult(
            status: GameReadStatus.invalidReadResult,
            fieldId: field.id,
          );
        }
        try {
          return GameReadResult(
            status: GameReadStatus.success,
            fieldId: field.id,
            value: ValueDecoder.decodeUnsigned32(
              Uint8List.fromList(read.bytes),
              field.byteOrder,
            ),
          );
        } on ArgumentError {
          return GameReadResult(
            status: GameReadStatus.invalidReadResult,
            fieldId: field.id,
          );
        }
      case MemoryReadStatus.nativeFailure:
        return GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: field.id,
          errorCode: read.errorCode,
        );
      case MemoryReadStatus.partial:
        return GameReadResult(
          status: GameReadStatus.incompleteRead,
          fieldId: field.id,
        );
      case MemoryReadStatus.invalidAddress:
        return GameReadResult(
          status: GameReadStatus.invalidMapping,
          fieldId: field.id,
        );
      case MemoryReadStatus.none ||
            MemoryReadStatus.invalidRequest ||
            MemoryReadStatus.invalidByteCount:
        return GameReadResult(
          status: GameReadStatus.invalidReadResult,
          fieldId: field.id,
        );
    }
  }
}
