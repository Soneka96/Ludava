import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_controller.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class TrainerController session behavior', () {
    test(
      'Class TrainerController observes startup discovery and refresh choice',
      () async {
        final fixture = _TrainerSdkFixture()..processIds = [42, 43];
        final controller = TrainerController(sdk: fixture.sdk);
        await _settleController();
        var notifications = 0;
        controller.addListener(() => notifications++);

        expect(fixture.discoveryCalls, 1);
        expect(controller.session.processIds, [42, 43]);
        expect(controller.session.selectedProcessId, isNull);

        fixture.processIds = [42];
        controller.refresh();
        await _settleController();
        expect(fixture.discoveryCalls, 3);
        expect(controller.session.selectedProcessId, 42);
        expect(notifications, greaterThan(0));

        final discoveries = fixture.discoveryCalls;
        controller.refresh();
        await _settleController();
        expect(fixture.discoveryCalls, discoveries + 1);

        await controller.dispose();
      },
    );

    test('Class TrainerController selects a process through the SDK', () async {
      final fixture = _TrainerSdkFixture()..processIds = [42, 43];
      final controller = TrainerController(sdk: fixture.sdk);
      await _settleController();

      expect(controller.session.selectedProcessId, isNull);
      expect(controller.selectProcess(43), isTrue);
      await _settleController();

      expect(controller.session.selectedProcessId, 43);
      expect(fixture.metadataProcessIds, isNotEmpty);
      expect(fixture.metadataProcessIds.every((id) => id == 43), isTrue);
      expect(controller.selectProcess(99), isFalse);
      await controller.dispose();
    });

    test(
      'Class TrainerController preserves editing across a routine refresh',
      () async {
        final fixture = _TrainerSdkFixture();
        final controller = TrainerController(sdk: fixture.sdk);
        await _settleController();
        final field = controller.session.profile!.findField('bolts')!;

        expect(controller.editField(field), isTrue);
        expect(controller.editingFieldId, 'bolts');
        controller.refresh();
        await _settleController();

        expect(controller.editingFieldId, 'bolts');
        await controller.dispose();
      },
    );

    test(
      'Class TrainerController cancels editing when its target changes',
      () async {
        final fixture = _TrainerSdkFixture();
        final controller = TrainerController(sdk: fixture.sdk);
        await _settleController();
        expect(
          controller.editField(controller.session.profile!.findField('bolts')!),
          isTrue,
        );

        fixture.processIds = [43];
        controller.refresh();
        await _settleController();

        expect(controller.session.selectedProcessId, isNull);
        expect(controller.editingFieldId, isNull);
        await controller.dispose();
      },
    );

    test(
      'Class TrainerController cancels editing when the field read fails',
      () async {
        final fixture = _TrainerSdkFixture();
        final controller = TrainerController(sdk: fixture.sdk);
        await _settleController();
        expect(
          controller.editField(controller.session.profile!.findField('bolts')!),
          isTrue,
        );

        fixture.readSucceeds = false;
        controller.refresh();
        await _settleController();

        expect(controller.editingFieldId, isNull);
        await controller.dispose();
      },
    );

    test(
      'Class TrainerController cancels editing when target identity changes',
      () async {
        for (final targetChange in [
          'process restart',
          'game',
          'hash',
          'base',
        ]) {
          final fixture = _TrainerSdkFixture();
          final controller = TrainerController(sdk: fixture.sdk);
          await _settleController();
          expect(
            controller.editField(
              controller.session.profile!.findField('bolts')!,
            ),
            isTrue,
          );

          switch (targetChange) {
            case 'process restart':
              fixture.processStartedAt = DateTime.utc(2026, 11, 7, 10);
              break;
            case 'game':
              fixture.profile = _testProfile(
                id: 'controller-test-game-2',
                hash: fixture.detectedHash,
              );
              break;
            case 'hash':
              fixture.detectedHash = 'changed-hash';
              break;
            case 'base':
              fixture.memoryBase = 0x200000;
              break;
          }
          controller.refresh();
          await _settleController();

          expect(controller.editingFieldId, isNull, reason: targetChange);
          await controller.dispose();
        }
      },
    );

    test('Class TrainerController cancels an edit without writing', () async {
      final fixture = _TrainerSdkFixture();
      final controller = TrainerController(sdk: fixture.sdk);
      await _settleController();
      expect(
        controller.editField(controller.session.profile!.findField('bolts')!),
        isTrue,
      );

      controller.cancelEditing();

      expect(controller.editingFieldId, isNull);
      expect(fixture.writeCalls, 0);
      expect(fixture.readValue, 17);
      await controller.dispose();
    });
  });

  group('Method TrainerController.writeField() behaves correctly', () {
    test('Method TrainerController.writeField() closes editing after verified success', () async {
      final fixture = _TrainerSdkFixture();
      final controller = TrainerController(sdk: fixture.sdk);
      await _settleController();
      final field = controller.session.profile!.findField('bolts')!;
      expect(controller.editField(field), isTrue);

      final result = controller.writeField('bolts', 42);
      await _settleController();

      expect(result.succeeded, isTrue);
      expect(result.readBackValue, 42);
      expect(controller.editingFieldId, isNull);
      expect(controller.session.readResults['bolts']?.value, 42);
      await controller.dispose();
    });

    test('Method TrainerController.writeField() retains editing after a target-valid failure', () async {
      final fixture = _TrainerSdkFixture()..writeSucceeds = false;
      final controller = TrainerController(sdk: fixture.sdk);
      await _settleController();
      expect(
        controller.editField(controller.session.profile!.findField('bolts')!),
        isTrue,
      );

      final result = controller.writeField('bolts', 42);
      await _settleController();

      expect(result.status, GameWriteStatus.writeFailed);
      expect(controller.editingFieldId, 'bolts');
      await controller.dispose();
    });

    test('Method TrainerController.writeField() cancels a draft after stale-session rejection', () async {
      final fixture = _TrainerSdkFixture();
      final controller = TrainerController(sdk: fixture.sdk);
      await _settleController();
      expect(
        controller.editField(controller.session.profile!.findField('bolts')!),
        isTrue,
      );
      fixture.detectedHash = 'changed-hash';

      final result = controller.writeField('bolts', 42);
      await _settleController();

      expect(result.status, GameWriteStatus.unsupportedProfile);
      expect(controller.session.selectedProcessId, isNull);
      expect(controller.editingFieldId, isNull);
      await controller.dispose();
    });
  });

  group('Method TrainerController.dispose() behaves correctly', () {
    test('Method TrainerController.dispose() shares cleanup and rejects later operations', () async {
      final fixture = _TrainerSdkFixture();
      final controller = TrainerController(sdk: fixture.sdk);
      await _settleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final firstDisposal = controller.dispose();
      final repeatedDisposal = controller.dispose();
      await Future.wait([firstDisposal, repeatedDisposal]);
      final notificationsAfterDisposal = notifications;
      fixture.processIds = [42, 43];

      expect(identical(firstDisposal, repeatedDisposal), isTrue);
      expect(controller.refresh, throwsStateError);
      expect(notifications, notificationsAfterDisposal);
      expect(fixture.sdk.session.connect, throwsStateError);
    });

    test('Method TrainerController.dispose() cancels observation before SDK shutdown finishes', () async {
      final fixture = _TrainerSdkFixture();
      final delayedSdk = _DelayedDisposalSdk(fixture.sdk);
      final controller = TrainerController(sdk: delayedSdk);
      await _settleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final disposal = controller.dispose();
      await _settleController();
      fixture.processIds = [42, 43];
      fixture.sdk.session.connect();
      await _settleController();

      expect(notifications, 0);
      delayedSdk.finishDisposal();
      await disposal;
      expect(notifications, 0);
    });
  });
}

/// Builds the controller test profile with a replaceable identity hash.
GameProfile _testProfile({
  String id = 'controller-test',
  required String hash,
}) => GameProfile(
  id: id,
  gameName: 'Controller test',
  buildId: 'CTRL00001',
  executable: 'controller-test.self',
  executableHash: hash,
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.verified,
  fields: {
    'bolts': GameField(
      id: 'bolts',
      name: 'Bolts',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus: VerificationStatus.verified,
      minimumValue: 0,
      maximumValue: 0xffffffff,
    ),
  },
);

/// Completes asynchronous state notifications before controller assertions.
Future<void> _settleController() => Future<void>.delayed(Duration.zero);

/// Supplies deterministic process, detection, and memory dependencies to tests.
class _TrainerSdkFixture {
  final List<int> metadataProcessIds = [];
  List<int> processIds = [42];
  int discoveryCalls = 0;
  bool readSucceeds = true;
  bool writeSucceeds = true;
  int _value = 17;
  String detectedHash = 'controller-test-hash';
  DateTime processStartedAt = DateTime.utc(2026, 11, 6, 10);
  int memoryBase = 0x100000;
  int writeCalls = 0;
  GameProfile profile = _testProfile(hash: 'controller-test-hash');

  /// Current integer represented by the fake process memory.
  int get readValue => _value;

  /// Creates an SDK runtime with in-memory process and memory collaborators.
  late final LudavaSdk sdk = LudavaSdk.create(
    api: _memoryApi,
    isWindows: true,
    pointerSize: 8,
    discoverProcessIds: () {
      discoveryCalls++;
      return processIds;
    },
    readProcessMetadata: (processId) {
      metadataProcessIds.add(processId);
      return Rpcs3ProcessMetadata(
        executablePath: r'C:\RPCS3\rpcs3.exe',
        startedAtUtc: processStartedAt,
      );
    },
    resolveMemoryBaseCandidate: (_) => Rpcs3MemoryBaseCandidate(
      memoryBase: memoryBase,
      logPath: r'C:\RPCS3\RPCS3.log',
    ),
    detectGame: (processId, _) => GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: processId,
      titleId: profile.buildId,
      gameTitle: profile.gameName,
      executable: profile.executable,
      executableHash: detectedHash,
      confidence: GameIdentityConfidence.confirmed,
      profile: profile,
      evidenceDescription: 'Synthetic controller test evidence.',
    ),
  );

  /// Implements complete fake reads and writes through the SDK's memory seam.
  WindowsMemoryApi get _memoryApi => WindowsMemoryApi(
    openProcess: (_, _, _) => ffi.Pointer<ffi.Void>.fromAddress(0x1234),
    readProcessMemory: (_, _, buffer, byteCount, transferred) {
      if (!readSucceeds) {
        transferred.value = 0;
        return 0;
      }
      for (var index = 0; index < byteCount; index++) {
        buffer[index] = (_value >> ((byteCount - index - 1) * 8)) & 0xff;
      }
      transferred.value = byteCount;
      return 1;
    },
    writeProcessMemory: (_, _, buffer, byteCount, transferred) {
      writeCalls++;
      if (!writeSucceeds) {
        transferred.value = 0;
        return 0;
      }
      _value = 0;
      for (var index = 0; index < byteCount; index++) {
        _value = (_value << 8) | buffer[index];
      }
      transferred.value = byteCount;
      return 1;
    },
    closeHandle: (_) => 1,
    getLastError: () => 5,
    getCurrentProcessId: () => 999,
  );
}

/// Delays disposal while exposing an active delegate session to the controller.
class _DelayedDisposalSdk extends LudavaSdk {
  /// Creates a wrapper around [delegate] with a test-controlled dispose gate.
  _DelayedDisposalSdk(this._delegate)
    : super.create(
        isWindows: false,
        discoverProcessIds: () => const [],
        readProcessMetadata: (_) => throw StateError('Unused test runtime.'),
        resolveMemoryBaseCandidate: (_) => null,
        detectGame: (_, _) => throw StateError('Unused test runtime.'),
      );

  final LudavaSdk _delegate;
  final Completer<void> _disposalGate = Completer<void>();

  /// Uses the active delegate session as the controller's observable source.
  @override
  TrainerSessionController get session => _delegate.session;

  /// Waits for the gate before shutting down the delegate runtime.
  @override
  Future<void> dispose() async {
    await _disposalGate.future;
    await _delegate.dispose();
  }

  /// Releases the test barrier for the pending disposal operation.
  void finishDisposal() => _disposalGate.complete();
}
