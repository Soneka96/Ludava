import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_controller.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_sdk_capability.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

TrainerSessionState _eligibleState({
  int processId = 42,
  DateTime? startedAtUtc,
  String profileId = 'controller-test',
  String executableHash = 'controller-test-hash',
  int memoryBase = 0x100000,
  int readValue = 17,
  bool readSucceeds = true,
  GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  GameWriteResult? lastWriteResult,
}) {
  final profile = detectionStatus == GameDetectionStatus.supportedGame
      ? _testProfile(id: profileId, hash: executableHash)
      : null;
  final metadata = Rpcs3ProcessMetadata(
    executablePath: r'C:\RPCS3\rpcs3.exe',
    startedAtUtc: startedAtUtc ?? DateTime.utc(2026, 11, 6, 10),
  );
  return TrainerSessionState(
    processIds: [processId],
    selectedProcessId: processId,
    processMetadata: metadata,
    detection: GameDetectionResult(
      status: detectionStatus,
      processId: processId,
      titleId: profile?.buildId,
      gameTitle: profile?.gameName,
      executable: profile?.executable,
      executableHash: executableHash,
      confidence: confidence,
      profile: profile,
      evidenceDescription: 'Synthetic controller state.',
    ),
    memoryBase: memoryBase,
    readResults: {
      'credits': readSucceeds
          ? GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: readValue,
            )
          : const GameReadResult(
              status: GameReadStatus.readFailed,
              fieldId: 'credits',
              errorCode: 5,
            ),
    },
    lastWriteResult: lastWriteResult,
  );
}

/// Builds the minimal SDK profile needed to exercise controller eligibility.
GameProfile _testProfile({
  String id = 'controller-test',
  String hash = 'controller-test-hash',
}) => GameProfile(
  id: id,
  gameName: 'Controller test',
  buildId: 'CTRL00001',
  executable: 'controller-test.self',
  executableHash: hash,
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.verified,
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
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

/// Supplies observable SDK state and records calls made by the controller.
class _FakeTrainerSdk implements TrainerSdkCapability {
  /// Creates a controllable session capability with optional disposal delay.
  _FakeTrainerSdk({
    required TrainerSessionState initialState,
    List<TrainerSessionState> connectStates = const [],
    this.writeResult = const GameWriteResult(
      status: GameWriteStatus.writeFailed,
    ),
    this.writeState,
    Completer<void>? disposalGate,
  }) : _state = initialState,
       _connectStates = [...connectStates],
       _disposalGate = disposalGate ?? (Completer<void>()..complete());

  final StreamController<TrainerSessionState> _stateChanges =
      StreamController<TrainerSessionState>.broadcast(sync: true);
  final List<TrainerSessionState> _connectStates;
  final Completer<void> _disposalGate;
  TrainerSessionState _state;
  Future<void>? _disposal;
  bool isDisposed = false;
  int connectCalls = 0;
  int refreshCalls = 0;
  int writeCalls = 0;
  int disposeCalls = 0;
  final List<int> selectedProcessIds = [];
  final GameWriteResult writeResult;
  final TrainerSessionState? writeState;

  /// Returns the state currently represented by the fake SDK capability.
  @override
  TrainerSessionState get state => _state;

  /// Emits the current state followed by controlled changes.
  @override
  Stream<TrainerSessionState> get stateChanges =>
      Stream<TrainerSessionState>.multi((subscriber) {
        final subscription = _stateChanges.stream.listen(
          subscriber.addSync,
          onError: subscriber.addErrorSync,
          onDone: subscriber.close,
        );
        subscriber.addSync(_state);
        subscriber.onCancel = subscription.cancel;
      }, isBroadcast: true);

  /// Records discovery and publishes the next configured snapshot.
  @override
  void connect() {
    connectCalls++;
    if (_connectStates.isNotEmpty) publish(_connectStates.removeAt(0));
  }

  /// Records a selected-session refresh and republishes its current snapshot.
  @override
  void refresh() {
    refreshCalls++;
    publish(_state);
  }

  /// Records process selection and reports whether it matches current state.
  @override
  bool selectProcess(int processId) {
    selectedProcessIds.add(processId);
    return _state.processIds.contains(processId);
  }

  /// Returns the configured write result and publishes its resulting state.
  @override
  GameWriteResult writeField(String fieldId, int value) {
    writeCalls++;
    final result = writeResult;
    if (writeState != null) {
      publish(writeState!);
    } else {
      final readResults = Map<String, GameReadResult>.of(_state.readResults);
      if (result.succeeded && result.fieldId == fieldId) {
        readResults[fieldId] = GameReadResult(
          status: GameReadStatus.success,
          fieldId: fieldId,
          value: result.readBackValue,
        );
      }
      publish(
        TrainerSessionState(
          processIds: _state.processIds,
          selectedProcessId: _state.selectedProcessId,
          processMetadata: _state.processMetadata,
          detection: _state.detection,
          memoryBase: _state.memoryBase,
          readResults: readResults,
          lastWriteResult: result,
          errorMessage: _state.errorMessage,
        ),
      );
    }
    return result;
  }

  /// Awaits the test-controlled gate before finishing SDK disposal.
  @override
  Future<void> dispose() => _disposal ??= _finishDisposal();

  /// Emits [state] to the controller and updates the fake's current snapshot.
  void publish(TrainerSessionState state) {
    _state = state;
    _stateChanges.add(state);
  }

  /// Completes pending disposal and closes the state stream.
  Future<void> _finishDisposal() async {
    disposeCalls++;
    await _disposalGate.future;
    isDisposed = true;
    await _stateChanges.close();
  }
}

void main() {
  group('Class TrainerController session behavior', () {
    test(
      'Class TrainerController observes its initial capability state',
      () async {
        final sdk = _FakeTrainerSdk(initialState: _eligibleState());
        final controller = TrainerController(capability: sdk);

        expect(controller.session, same(sdk.state));
        expect(sdk.connectCalls, 1);
        await controller.dispose();
      },
    );

    test('Class TrainerController propagates updates and chooses refresh operation', () async {
      final sdk = _FakeTrainerSdk(
        initialState: TrainerSessionState(),
        connectStates: [
          TrainerSessionState(processIds: [42, 43]),
          _eligibleState(),
        ],
      );
      final controller = TrainerController(capability: sdk);
      await _settleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(controller.session.processIds, [42, 43]);
      controller.refresh();
      await _settleController();

      expect(sdk.connectCalls, 2);
      expect(controller.session.selectedProcessId, 42);
      expect(notifications, greaterThan(0));

      controller.refresh();

      expect(sdk.refreshCalls, 1);
      expect(sdk.connectCalls, 2);
      await controller.dispose();
    });

    test(
      'Class TrainerController selects a process through its capability',
      () async {
        final sdk = _FakeTrainerSdk(
          initialState: _eligibleState(processId: 43),
        );
        final controller = TrainerController(capability: sdk);

        expect(controller.selectProcess(43), isTrue);
        expect(sdk.selectedProcessIds, [43]);
        expect(controller.selectProcess(99), isFalse);
        await controller.dispose();
      },
    );

    test(
      'Class TrainerController preserves editing across a same-session refresh',
      () async {
        final sdk = _FakeTrainerSdk(initialState: _eligibleState());
        final controller = TrainerController(capability: sdk);
        final field = controller.session.profile!.findField('credits')!;

        expect(controller.editField(field), isTrue);
        sdk.publish(_eligibleState(readValue: 18));
        await _settleController();

        expect(controller.editingFieldId, 'credits');
        expect(controller.session.readResults['credits']?.value, 18);
        await controller.dispose();
      },
    );

    test(
      'Class TrainerController cancels editing when the write target changes',
      () async {
        final initialState = _eligibleState();
        final changedStates = [
          _eligibleState(processId: 43),
          _eligibleState(startedAtUtc: DateTime.utc(2026, 11, 7, 10)),
          _eligibleState(profileId: 'controller-test-game-2'),
          _eligibleState(executableHash: 'changed-hash'),
          _eligibleState(memoryBase: 0x200000),
          _eligibleState(confidence: GameIdentityConfidence.manuallySelected),
          _eligibleState(detectionStatus: GameDetectionStatus.unsupportedGame),
        ];

        for (final changedState in changedStates) {
          final sdk = _FakeTrainerSdk(initialState: initialState);
          final controller = TrainerController(capability: sdk);
          final field = controller.session.profile!.findField('credits')!;
          expect(controller.editField(field), isTrue);

          sdk.publish(changedState);
          await _settleController();

          expect(controller.editingFieldId, isNull);
          await controller.dispose();
        }
      },
    );

    test(
      'Class TrainerController cancels editing when the current read fails',
      () async {
        final sdk = _FakeTrainerSdk(initialState: _eligibleState());
        final controller = TrainerController(capability: sdk);
        expect(
          controller.editField(
            controller.session.profile!.findField('credits')!,
          ),
          isTrue,
        );

        sdk.publish(_eligibleState(readSucceeds: false));
        await _settleController();

        expect(controller.editingFieldId, isNull);
        await controller.dispose();
      },
    );

    test('Class TrainerController refuses an ineligible field', () async {
      final sdk = _FakeTrainerSdk(initialState: TrainerSessionState());
      final controller = TrainerController(capability: sdk);

      expect(controller.editField(_testProfile().fields['credits']!), isFalse);
      expect(controller.editingFieldId, isNull);
      await controller.dispose();
    });

    test('Class TrainerController cancels editing without writing', () async {
      final sdk = _FakeTrainerSdk(initialState: _eligibleState());
      final controller = TrainerController(capability: sdk);
      expect(
        controller.editField(controller.session.profile!.findField('credits')!),
        isTrue,
      );

      controller.cancelEditing();

      expect(controller.editingFieldId, isNull);
      expect(sdk.writeCalls, 0);
      await controller.dispose();
    });
  });

  group('Method TrainerController.writeField() behaves correctly', () {
    test(
      'Method TrainerController.writeField() closes editing after SDK success',
      () async {
        final sdk = _FakeTrainerSdk(
          initialState: _eligibleState(),
          writeResult: const GameWriteResult(
            status: GameWriteStatus.success,
            fieldId: 'credits',
            requestedValue: 42,
            readBackValue: 42,
          ),
        );
        final controller = TrainerController(capability: sdk);
        expect(
          controller.editField(
            controller.session.profile!.findField('credits')!,
          ),
          isTrue,
        );

        final result = controller.writeField('credits', 42);
        await _settleController();

        expect(result.succeeded, isTrue);
        expect(controller.editingFieldId, isNull);
        expect(controller.session.readResults['credits']?.value, 42);
        await controller.dispose();
      },
    );

    test('Method TrainerController.writeField() preserves editing after a valid-target failure', () async {
      final sdk = _FakeTrainerSdk(
        initialState: _eligibleState(),
        writeResult: const GameWriteResult(
          status: GameWriteStatus.writeFailed,
          fieldId: 'credits',
          requestedValue: 42,
          errorCode: 5,
        ),
        writeState: _eligibleState(
          readSucceeds: false,
          lastWriteResult: const GameWriteResult(
            status: GameWriteStatus.writeFailed,
            fieldId: 'credits',
            requestedValue: 42,
            errorCode: 5,
          ),
        ),
      );
      final controller = TrainerController(capability: sdk);
      expect(
        controller.editField(controller.session.profile!.findField('credits')!),
        isTrue,
      );

      final result = controller.writeField('credits', 42);
      await _settleController();

      expect(result.status, GameWriteStatus.writeFailed);
      expect(controller.editingFieldId, 'credits');
      await controller.dispose();
    });

    test('Method TrainerController.writeField() cancels editing after stale-session rejection', () async {
      final sdk = _FakeTrainerSdk(
        initialState: _eligibleState(),
        writeResult: const GameWriteResult(
          status: GameWriteStatus.unsupportedProfile,
          fieldId: 'credits',
          requestedValue: 42,
        ),
        writeState: TrainerSessionState(),
      );
      final controller = TrainerController(capability: sdk);
      expect(
        controller.editField(controller.session.profile!.findField('credits')!),
        isTrue,
      );

      final result = controller.writeField('credits', 42);
      await _settleController();

      expect(result.status, GameWriteStatus.unsupportedProfile);
      expect(controller.session.selectedProcessId, isNull);
      expect(controller.editingFieldId, isNull);
      await controller.dispose();
    });
  });

  group('Method TrainerController.dispose() behaves correctly', () {
    test('Method TrainerController.dispose() shares cleanup and rejects later operations', () async {
      final sdk = _FakeTrainerSdk(initialState: _eligibleState());
      final controller = TrainerController(capability: sdk);
      await _settleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final firstDisposal = controller.dispose();
      final repeatedDisposal = controller.dispose();
      await Future.wait([firstDisposal, repeatedDisposal]);
      final notificationsAfterDisposal = notifications;

      expect(identical(firstDisposal, repeatedDisposal), isTrue);
      expect(controller.refresh, throwsStateError);
      expect(() => controller.selectProcess(43), throwsStateError);
      expect(() => controller.writeField('credits', 42), throwsStateError);
      expect(notifications, notificationsAfterDisposal);
      expect(sdk.disposeCalls, 1);
    });

    test('Method TrainerController.dispose() cancels observation while SDK cleanup is pending', () async {
      final disposalGate = Completer<void>();
      final sdk = _FakeTrainerSdk(
        initialState: _eligibleState(),
        disposalGate: disposalGate,
      );
      final controller = TrainerController(capability: sdk);
      await _settleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final disposal = controller.dispose();
      await _settleController();
      sdk.publish(_eligibleState(processId: 43));
      await _settleController();

      expect(notifications, 0);
      expect(sdk.isDisposed, isFalse);
      disposalGate.complete();
      await disposal;

      expect(sdk.isDisposed, isTrue);
      expect(notifications, 0);
    });
  });

  test(
    'Flow TrainerController receives the public SDK session state',
    () async {
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => [42, 43],
        readProcessMetadata: (processId) => Rpcs3ProcessMetadata(
          executablePath: r'C:\RPCS3\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026, 11, 6, 10),
        ),
        detectGame: (processId, _) => GameDetectionResult(
          status: GameDetectionStatus.unsupportedGame,
          processId: processId,
          executable: 'unknown.self',
          confidence: GameIdentityConfidence.uncertain,
          evidenceDescription: 'Synthetic integration evidence.',
        ),
      );
      final controller = TrainerController(sdk: sdk);
      await _settleController();

      expect(controller.session.processIds, [42, 43]);
      expect(controller.session.selectedProcessId, isNull);
      expect(controller.selectProcess(42), isTrue);
      expect(controller.session.selectedProcessId, 42);
      expect(
        controller.writeField('credits', 42).status,
        GameWriteStatus.unsupportedField,
      );
      controller.refresh();
      await _settleController();
      expect(controller.session.selectedProcessId, 42);

      await controller.dispose();
    },
  );
}

/// Builds a state snapshot with an optionally modified write target.
