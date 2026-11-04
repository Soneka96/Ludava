import 'dart:typed_data';

import 'package:ludava/src/bolt_service.dart';
import 'package:ludava/src/game_profile.dart';
import 'package:ludava/src/memory_reader.dart';
import 'package:test/test.dart';

class FakeMemoryReader implements MemoryReader {
  FakeMemoryReader(this.result);

  final MemoryReadResult result;
  int calls = 0;
  int? address;
  int? byteCount;

  @override
  MemoryReadResult read(int address, int byteCount) {
    calls++;
    this.address = address;
    this.byteCount = byteCount;
    return result;
  }
}

MemoryReadResult completeRead(List<int> bytes) => MemoryReadResult(
      status: MemoryReadStatus.complete,
      bytes: Uint8List.fromList(bytes),
      bytesRead: bytes.length,
      requestedBytes: bytes.length,
    );

void main() {
  group('BoltService.readBolts', () {
    test('resolves the address and decodes a successful value', () {
      final reader = FakeMemoryReader(completeRead([0, 0, 0, 42]));
      final service = BoltService(reader);

      final result = service.readBolts(
        profile: rc2CollectionExperimentalProfile,
        memoryBase: 0x300000000,
      );

      expect(result.status, BoltReadStatus.success);
      expect(result.boltCount, 42);
      expect(reader.address, 0x301329e80);
      expect(reader.byteCount, 4);
      expect(reader.calls, 1);
    });

    test('preserves a successfully read zero bolt count', () {
      final reader = FakeMemoryReader(completeRead([0, 0, 0, 0]));
      final result = BoltService(reader).readBolts(
        profile: rc2CollectionExperimentalProfile,
        memoryBase: 0x300000000,
      );

      expect(result.succeeded, isTrue);
      expect(result.boltCount, 0);
    });

    test('does not read a profile marked unsupported', () {
      const profile = GameProfile(
        gameName: 'Unknown game',
        collectionTitleId: 'UNKNOWN',
        activeSubgame: 'Unknown',
        executable: 'unknown.self',
        reportedInternalAppId: 'UNKNOWN',
        boltGuestOffset: 0,
        boltType: MemoryValueType.unsigned32,
        boltEndian: Endian.big,
        compatibility: CompatibilityStatus.unsupported,
      );
      final reader = FakeMemoryReader(completeRead([0, 0, 0, 42]));

      final result =
          BoltService(reader).readBolts(profile: profile, memoryBase: 0);

      expect(result.status, BoltReadStatus.unsupportedProfile);
      expect(result.boltCount, isNull);
      expect(reader.calls, 0);
    });

    test('rejects invalid mappings before reading', () {
      final reader = FakeMemoryReader(completeRead([0, 0, 0, 42]));

      final result = BoltService(reader).readBolts(
        profile: rc2CollectionExperimentalProfile,
        memoryBase: -1,
      );

      expect(result.status, BoltReadStatus.invalidMapping);
      expect(result.boltCount, isNull);
      expect(reader.calls, 0);
    });

    test('preserves native read failure and does not return a value', () {
      final reader = FakeMemoryReader(
        MemoryReadResult(
          status: MemoryReadStatus.nativeFailure,
          bytes: Uint8List(0),
          bytesRead: 0,
          requestedBytes: 4,
          errorCode: 299,
        ),
      );

      final result = BoltService(reader).readBolts(
        profile: rc2CollectionExperimentalProfile,
        memoryBase: 0x300000000,
      );

      expect(result.status, BoltReadStatus.readFailed);
      expect(result.errorCode, 299);
      expect(result.boltCount, isNull);
    });

    test('represents a partial read without decoding it', () {
      final reader = FakeMemoryReader(
        MemoryReadResult(
          status: MemoryReadStatus.partial,
          bytes: Uint8List(2),
          bytesRead: 2,
          requestedBytes: 4,
        ),
      );

      final result = BoltService(reader).readBolts(
        profile: rc2CollectionExperimentalProfile,
        memoryBase: 0x300000000,
      );

      expect(result.status, BoltReadStatus.incompleteRead);
      expect(result.boltCount, isNull);
    });

    test('rejects an inconsistent complete result', () {
      final reader = FakeMemoryReader(
        MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: Uint8List(3),
          bytesRead: 3,
          requestedBytes: 4,
        ),
      );

      final result = BoltService(reader).readBolts(
        profile: rc2CollectionExperimentalProfile,
        memoryBase: 0x300000000,
      );

      expect(result.status, BoltReadStatus.invalidReadResult);
      expect(result.boltCount, isNull);
    });

    for (final readStatus in [
      MemoryReadStatus.invalidAddress,
      MemoryReadStatus.invalidRequest,
      MemoryReadStatus.invalidByteCount,
    ]) {
      test('rejects reader status $readStatus without a value', () {
        final reader = FakeMemoryReader(
          MemoryReadResult(
            status: readStatus,
            bytes: Uint8List(0),
            bytesRead: 0,
            requestedBytes: 4,
          ),
        );

        final result = BoltService(reader).readBolts(
          profile: rc2CollectionExperimentalProfile,
          memoryBase: 0x300000000,
        );

        expect(result.status, BoltReadStatus.invalidReadResult);
        expect(result.boltCount, isNull);
      });
    }
  });
}
