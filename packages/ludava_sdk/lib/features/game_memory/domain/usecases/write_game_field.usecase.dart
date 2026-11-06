import 'dart:typed_data';

import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_write_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/repositories/Igame_memory.repository.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/utils/address_resolver.dart';
import 'package:ludava_sdk/features/game_memory/domain/utils/value_decoder.dart';
import 'package:ludava_sdk/features/game_memory/domain/utils/value_encoder.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Writes one eligible [GameField] and requires matching read-back evidence.
class WriteGameFieldUseCase {
  /// Creates the use case with its memory repository.
  WriteGameFieldUseCase(this._repository);

  final IGameMemoryRepository _repository;

  /// Validates [params], reads the field, writes the value, and verifies it.
  GameWriteResult execute(WriteGameFieldParams params) {
    if (!params.profile.canWrite) {
      return GameWriteResult(
        status: GameWriteStatus.unsupportedProfile,
        fieldId: params.fieldId,
        requestedValue: params.value,
      );
    }
    final field = params.profile.findField(params.fieldId);
    if (field == null || !field.canWrite) {
      return GameWriteResult(
        status: GameWriteStatus.unsupportedField,
        fieldId: params.fieldId,
        requestedValue: params.value,
      );
    }
    if (!_isAllowedValue(field, params.value)) {
      return GameWriteResult(
        status: GameWriteStatus.invalidValue,
        fieldId: field.id,
        requestedValue: params.value,
      );
    }

    final byteLength = field.valueType.byteLength;
    if (byteLength == null) {
      return _failure(GameWriteStatus.invalidValue, field.id, params.value);
    }
    late final int address;
    try {
      address = AddressResolver.resolve(
        memoryBase: params.memoryBase,
        guestOffset: field.guestOffset,
        byteLength: byteLength,
      );
    } on ArgumentError {
      return _failure(GameWriteStatus.invalidMapping, field.id, params.value);
    }

    if (!params.confirmed) {
      return GameWriteResult(
        status: GameWriteStatus.confirmationRequired,
        fieldId: field.id,
        requestedValue: params.value,
      );
    }

    final preliminaryRead = _repository.read(address, byteLength);
    if (preliminaryRead.status != MemoryReadStatus.complete ||
        !preliminaryRead.isComplete ||
        preliminaryRead.bytes.length != byteLength ||
        preliminaryRead.bytes.any((byte) => byte < 0 || byte > 0xff)) {
      return GameWriteResult(
        status: GameWriteStatus.preliminaryReadFailed,
        fieldId: field.id,
        requestedValue: params.value,
        errorCode: preliminaryRead.errorCode,
      );
    }

    late final int currentValue;
    try {
      currentValue = ValueDecoder.decodeUnsigned32(
        Uint8List.fromList(preliminaryRead.bytes),
        field.byteOrder,
      );
    } on ArgumentError {
      return _failure(
        GameWriteStatus.preliminaryReadFailed,
        field.id,
        params.value,
      );
    }
    if (!_isAllowedValue(field, currentValue)) {
      return _failure(
        GameWriteStatus.preliminaryReadFailed,
        field.id,
        params.value,
      );
    }

    late final List<int> bytes;
    try {
      bytes = ValueEncoder.encodeUnsigned32(params.value, field.byteOrder);
    } on ArgumentError {
      return _failure(GameWriteStatus.invalidValue, field.id, params.value);
    }

    final write = _repository.write(address, bytes);
    final writeFailure = _writeFailure(write, field.id, params.value);
    if (writeFailure != null) return writeFailure;

    final readBack = _repository.read(address, byteLength);
    if (readBack.status == MemoryReadStatus.nativeFailure ||
        readBack.status == MemoryReadStatus.partial ||
        readBack.status == MemoryReadStatus.invalidAddress) {
      return GameWriteResult(
        status: GameWriteStatus.readBackFailed,
        fieldId: field.id,
        requestedValue: params.value,
        errorCode: readBack.errorCode,
      );
    }
    if (!readBack.isComplete || readBack.bytes.length != byteLength) {
      return _failure(
        GameWriteStatus.invalidWriteResult,
        field.id,
        params.value,
      );
    }

    late final int actualValue;
    try {
      actualValue = ValueDecoder.decodeUnsigned32(
        Uint8List.fromList(readBack.bytes),
        field.byteOrder,
      );
    } on ArgumentError {
      return _failure(
        GameWriteStatus.invalidWriteResult,
        field.id,
        params.value,
      );
    }
    if (actualValue != params.value) {
      return GameWriteResult(
        status: GameWriteStatus.readBackMismatch,
        fieldId: field.id,
        requestedValue: params.value,
        readBackValue: actualValue,
      );
    }
    return GameWriteResult(
      status: GameWriteStatus.success,
      fieldId: field.id,
      requestedValue: params.value,
      readBackValue: actualValue,
    );
  }

  bool _isAllowedValue(GameField field, int value) =>
      field.minimumValue != null &&
      field.maximumValue != null &&
      value >= field.minimumValue! &&
      value <= field.maximumValue!;

  GameWriteResult? _writeFailure(
    MemoryWriteResult write,
    String fieldId,
    int value,
  ) {
    if (write.status == MemoryWriteStatus.complete) {
      return write.isComplete
          ? null
          : _failure(GameWriteStatus.invalidWriteResult, fieldId, value);
    }
    final status = switch (write.status) {
      MemoryWriteStatus.nativeFailure => GameWriteStatus.writeFailed,
      MemoryWriteStatus.partial => GameWriteStatus.incompleteWrite,
      MemoryWriteStatus.invalidAddress => GameWriteStatus.invalidMapping,
      MemoryWriteStatus.none ||
      MemoryWriteStatus.invalidRequest ||
      MemoryWriteStatus.invalidByteCount => GameWriteStatus.invalidWriteResult,
      MemoryWriteStatus.complete => GameWriteStatus.invalidWriteResult,
    };
    return GameWriteResult(
      status: status,
      fieldId: fieldId,
      requestedValue: value,
      errorCode: write.errorCode,
    );
  }

  GameWriteResult _failure(GameWriteStatus status, String fieldId, int value) =>
      GameWriteResult(status: status, fieldId: fieldId, requestedValue: value);
}
