import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_memory/data/process_game_memory_operations.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';
import 'package:test/test.dart';

import '../../../support/fake_windows_memory_api.dart';

final _profile = GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'TEST00001',
  executable: 'SYNTHETIC.self',
  executableHash: 'PPU-synthetic-hash',
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      minimumValue: 0,
      maximumValue: 0xffffffff,
    ),
  },
);

ProcessGameMemoryOperations _operations(FakeWindowsMemoryApi api) =>
    ProcessGameMemoryOperations(
      api: api.adapter,
      isWindows: true,
      pointerSize: 8,
    );

void main() {
  group('Method readField() behaves correctly', () {
    test('Method readField() reads and closes a process handle', () {
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 61];
      final result = _operations(api).readField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
      );

      expect(result.readResult?.status, GameReadStatus.success);
      expect(result.readResult?.value, 61);
      expect(result.operationError, isNull);
      expect(result.cleanupError, isNull);
      expect(api.requestedAccess, 0x0010);
      expect(api.openCalls, 1);
      expect(api.readCalls, 1);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method readField() closes the handle when the read fails', () {
      final api = FakeWindowsMemoryApi()..readReturnValue = 0;

      final result = _operations(api).readField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
      );

      expect(result.readResult?.status, GameReadStatus.readFailed);
      expect(result.readResult?.value, isNull);
      expect(api.readCalls, 1);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method readField() classifies a native open failure', () {
      final api = FakeWindowsMemoryApi(handleAddress: 0);

      final result = _operations(api).readField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
      );

      expect(result.operationError, isA<WindowsMemoryException>());
      expect(result.readResult, isNull);
      expect(api.openCalls, 1);
      expect(api.readCalls, 0);
      expect(api.closeCalls, 0);
    });

    test('Method readField() closes without reading an unsupported field', () {
      final api = FakeWindowsMemoryApi();

      final result = _operations(api).readField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'missing',
      );

      expect(result.readResult?.status, GameReadStatus.unsupportedField);
      expect(api.openCalls, 1);
      expect(api.readCalls, 0);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });
    test('Method readField() reports handle cleanup failures separately', () {
      final api = FakeWindowsMemoryApi()..closeReturnValue = 0;

      final result = _operations(api).readField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
      );

      expect(result.readResult?.succeeded, isTrue);
      expect(result.operationError, isNull);
      expect(result.cleanupError, isA<WindowsMemoryException>());
      expect(api.closeCalls, 1);
    });
  });

  group('Method writeField() behaves correctly', () {
    test(
      'Method writeField() performs one verified write and closes the handle',
      () {
        final api = FakeWindowsMemoryApi();

        final result = _operations(api).writeField(
          processId: 42,
          profile: _profile,
          memoryBase: 0x300000000,
          fieldId: 'credits',
          value: 0x01020304,
          confirmed: true,
        );

        expect(result.writeResult?.status, GameWriteStatus.success);
        expect(result.writeResult?.readBackValue, 0x01020304);
        expect(result.operationError, isNull);
        expect(result.cleanupError, isNull);
        expect(api.requestedAccess, 0x0038);
        expect(api.openCalls, 1);
        expect(api.readCalls, 2);
        expect(api.writeCalls, 1);
        expect(api.closeCalls, 1);
      },
    );

    test('Method writeField() reports a partial native transfer', () {
      final api = FakeWindowsMemoryApi()..reportedWriteBytes = 2;

      final result = _operations(api).writeField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
        value: 0x01020304,
        confirmed: true,
      );

      expect(result.writeResult?.status, GameWriteStatus.incompleteWrite);
      expect(api.readCalls, 1);
      expect(api.writeCalls, 1);
      expect(api.closeCalls, 1);
    });

    test(
      'Method writeField() does not write after a failed preliminary read',
      () {
        final api = FakeWindowsMemoryApi()..readReturnValue = 0;

        final result = _operations(api).writeField(
          processId: 42,
          profile: _profile,
          memoryBase: 0x300000000,
          fieldId: 'credits',
          value: 61,
          confirmed: true,
        );

        expect(
          result.writeResult?.status,
          GameWriteStatus.preliminaryReadFailed,
        );
        expect(api.readCalls, 1);
        expect(api.writeCalls, 0);
        expect(api.closeCalls, 1);
      },
    );

    test('Method writeField() classifies a native open failure', () {
      final api = FakeWindowsMemoryApi(handleAddress: 0);

      final result = _operations(api).writeField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
        value: 61,
        confirmed: true,
      );

      expect(result.operationError, isA<WindowsMemoryException>());
      expect(result.writeResult, isNull);
      expect(api.openCalls, 1);
      expect(api.readCalls, 0);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 0);
    });

    test('Method writeField() reports mismatched read-back', () {
      final api = FakeWindowsMemoryApi();

      final result = _operations(api).writeField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'credits',
        value: 0x01020305,
        confirmed: true,
      );

      expect(result.writeResult?.status, GameWriteStatus.readBackMismatch);
      expect(result.writeResult?.readBackValue, 0x01020304);
      expect(api.readCalls, 2);
      expect(api.writeCalls, 1);
      expect(api.closeCalls, 1);
    });

    test('Method writeField() does not write when field policy rejects it', () {
      final api = FakeWindowsMemoryApi();

      final result = _operations(api).writeField(
        processId: 42,
        profile: _profile,
        memoryBase: 0x300000000,
        fieldId: 'missing',
        value: 61,
        confirmed: true,
      );

      expect(result.writeResult?.status, GameWriteStatus.unsupportedField);
      expect(api.openCalls, 1);
      expect(api.readCalls, 0);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });
  });
}
