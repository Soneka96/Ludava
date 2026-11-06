import 'dart:async';

import 'package:ludava/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/game_catalog/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_catalog/domain/profiles/rc3_collection_profile.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/trainer/application/trainer_session_controller.dart';
import 'package:ludava/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class TrainerSessionController construction', () {
    test(
      'Class TrainerSessionController initializes without a selected process',
      () {
        final fixture = _SessionFixture();

        expect(fixture.controller.state.processIds, isEmpty);
        expect(fixture.controller.state.selectedProcessId, isNull);
        expect(fixture.controller.state.detection, isNull);
        expect(fixture.detectCalls, 0);
      },
    );
  });

  group('Property state behaves correctly', () {
    test('Property state returns the latest immutable session snapshot', () {
      final fixture = _SessionFixture()..controller.connect();
      final state = fixture.controller.state;

      expect(state.selectedProcessId, 42);
      expect(state.profile?.id, fixture.profile.id);
      expect(() => state.readResults.clear(), throwsUnsupportedError);
    });
  });

  group('Property stateChanges behaves correctly', () {
    test(
      'Property stateChanges emits the current snapshot and later transitions',
      () async {
        final fixture = _SessionFixture();
        final firstSubscriber = <Object>[];
        final secondSubscriber = <Object>[];
        final first = fixture.controller.stateChanges.listen(
          firstSubscriber.add,
        );
        final second = fixture.controller.stateChanges.listen(
          secondSubscriber.add,
        );
        await Future<void>.delayed(Duration.zero);

        expect(firstSubscriber.single, same(fixture.controller.state));
        expect(secondSubscriber.single, same(fixture.controller.state));

        fixture.controller.connect();
        await Future<void>.delayed(Duration.zero);
        expect(firstSubscriber.last, same(fixture.controller.state));
        expect(secondSubscriber.last, same(fixture.controller.state));

        final lateSubscriber = <Object>[];
        final late = fixture.controller.stateChanges.listen(lateSubscriber.add);
        await Future<void>.delayed(Duration.zero);
        expect(lateSubscriber.single, same(fixture.controller.state));

        await first.cancel();
        final firstCount = firstSubscriber.length;
        fixture.controller.refresh();
        await Future<void>.delayed(Duration.zero);

        expect(firstSubscriber, hasLength(firstCount));
        expect(secondSubscriber.length, greaterThan(firstCount));
        expect(secondSubscriber.last, same(fixture.controller.state));
        await late.cancel();
        await second.cancel();
      },
    );

    test(
      'Property stateChanges publishes successful and failed write results',
      () async {
        final fixture = _SessionFixture()..controller.connect();
        final snapshots = <TrainerSessionState>[];
        final subscription = fixture.controller.stateChanges.listen(
          snapshots.add,
        );
        await Future<void>.delayed(Duration.zero);

        fixture.controller.writeField('bolts', 101);
        fixture.writeResult = GameWriteResult(
          status: GameWriteStatus.readBackMismatch,
          fieldId: 'bolts',
          requestedValue: 102,
          readBackValue: 103,
        );
        fixture.controller.writeField('bolts', 102);
        await Future<void>.delayed(Duration.zero);

        expect(
          snapshots.any(
            (snapshot) => snapshot.readResults['bolts']?.value == 101,
          ),
          isTrue,
        );
        expect(
          snapshots.last.lastWriteResult?.status,
          GameWriteStatus.readBackMismatch,
        );
        expect(snapshots.last.readResults, isEmpty);
        await subscription.cancel();
      },
    );
  });

  group('Method dispose() behaves correctly', () {
    test('Method dispose() closes state observation', () async {
      final fixture = _SessionFixture();
      var completed = false;
      fixture.controller.stateChanges.listen(
        (_) {},
        onDone: () => completed = true,
      );

      await fixture.controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(completed, isTrue);
      await expectLater(fixture.controller.stateChanges, emitsDone);
    });
  });

  group('Method connect() behaves correctly', () {
    test('Method connect() reports when RPCS3 is absent', () {
      final fixture = _SessionFixture()..processIds = [];

      fixture.controller.connect();

      expect(fixture.controller.state.processIds, isEmpty);
      expect(fixture.controller.state.selectedProcessId, isNull);
      expect(fixture.metadataReads, 0);
    });

    test(
      'Method connect() waits for a choice when multiple processes exist',
      () {
        final fixture = _SessionFixture()..processIds = [42, 43];

        fixture.controller.connect();

        expect(fixture.controller.state.processIds, [42, 43]);
        expect(fixture.controller.state.selectedProcessId, isNull);
        expect(fixture.metadataReads, 0);
      },
    );

    test('Method connect() selects and reads a single supported process', () {
      final fixture = _SessionFixture();

      fixture.controller.connect();

      expect(fixture.controller.state.selectedProcessId, 42);
      expect(fixture.controller.state.profile?.id, fixture.profile.id);
      expect(fixture.controller.state.readResults['bolts']?.value, 100);
    });

    test('Method connect() reports process discovery failures', () {
      final fixture = _SessionFixture()..discoveryError = StateError('denied');

      fixture.controller.connect();

      expect(fixture.controller.state.errorMessage, contains('denied'));
      expect(fixture.controller.state.selectedProcessId, isNull);
    });
  });

  group('Method selectProcess() behaves correctly', () {
    test(
      'Method selectProcess() rejects a process not in the latest listing',
      () {
        final fixture = _SessionFixture()..controller.connect();

        expect(fixture.controller.selectProcess(99), isFalse);
        expect(fixture.metadataReads, 2);
      },
    );

    test(
      'Method selectProcess() leaves unresolved identity without field reads',
      () {
        final fixture =
            _SessionFixture()
              ..detectionStatus = GameDetectionStatus.ambiguous
              ..controller.connect();

        expect(fixture.controller.state.profile, isNull);
        expect(fixture.readCalls, 0);
        expect(fixture.controller.state.memoryBase, isNull);
      },
    );

    test(
      'Method selectProcess() leaves unsupported games without field reads',
      () {
        final fixture =
            _SessionFixture()
              ..detectionStatus = GameDetectionStatus.unsupportedGame
              ..controller.connect();

        expect(fixture.controller.state.profile, isNull);
        expect(fixture.readCalls, 0);
        expect(fixture.controller.state.memoryBase, isNull);
      },
    );

    test('Method selectProcess() supports each Collection game profile', () {
      final profiles = [
        Rc1CollectionProfile.profile,
        Rc2CollectionProfile.profile,
        Rc3CollectionProfile.profile,
      ];

      for (final profile in profiles) {
        final fixture = _SessionFixture()..profile = profile;
        fixture.controller.connect();

        expect(fixture.controller.state.profile?.id, profile.id);
        expect(
          fixture.controller.state.readResults['bolts']?.succeeded,
          isTrue,
        );
      }
    });

    test('Method selectProcess() does not read when no game is active', () {
      final fixture =
          _SessionFixture()
            ..detectionStatus = GameDetectionStatus.noActiveGame
            ..controller.connect();

      expect(fixture.controller.state.profile, isNull);
      expect(fixture.readCalls, 0);
      expect(fixture.controller.state.memoryBase, isNull);
    });

    test('Method selectProcess() reads the detected profile fields', () {
      final fixture = _SessionFixture()..processIds = [42, 43];
      fixture.controller.connect();

      expect(fixture.controller.selectProcess(43), isTrue);
      expect(fixture.controller.state.selectedProcessId, 43);
      expect(fixture.controller.state.detection?.processId, 43);
      expect(fixture.controller.state.readResults['bolts']?.value, 100);
    });

    test(
      'Method selectProcess() rejects detection tied to another process',
      () {
        final fixture =
            _SessionFixture()
              ..processIds = [42, 43]
              ..detectionProcessId = 99
              ..controller.connect();

        expect(fixture.controller.selectProcess(43), isFalse);
        expect(fixture.controller.state.profile, isNull);
        expect(fixture.readCalls, 0);
      },
    );

    test('Method selectProcess() reports metadata failures', () {
      final fixture =
          _SessionFixture()
            ..processIds = [42, 43]
            ..metadataError = StateError('metadata unavailable')
            ..controller.connect();

      expect(fixture.controller.selectProcess(43), isFalse);
      expect(
        fixture.controller.state.errorMessage,
        contains('metadata unavailable'),
      );
      expect(fixture.readCalls, 0);
    });

    test('Method selectProcess() reports base resolution failures', () {
      final fixture =
          _SessionFixture()
            ..processIds = [42, 43]
            ..baseError = StateError('base unavailable')
            ..controller.connect();

      expect(fixture.controller.selectProcess(43), isFalse);
      expect(
        fixture.controller.state.errorMessage,
        contains('base unavailable'),
      );
      expect(fixture.readCalls, 0);
    });
  });

  group('Method selectManualProfile() behaves correctly', () {
    test('Method selectManualProfile() allows read-only inspection', () {
      final fixture = _SessionFixture()..controller.connect();

      expect(fixture.controller.selectManualProfile(fixture.profile), isTrue);
      expect(
        fixture.controller.state.detection?.confidence,
        GameIdentityConfidence.manuallySelected,
      );
      expect(fixture.controller.state.readResults['bolts']?.value, 100);
      expect(
        fixture.controller.writeField('bolts', 101).status,
        GameWriteStatus.unsupportedProfile,
      );
      expect(fixture.writeCalls, 0);
    });

    test(
      'Method selectManualProfile() rejects selection without a process',
      () {
        final fixture = _SessionFixture();

        expect(
          fixture.controller.selectManualProfile(fixture.profile),
          isFalse,
        );
        expect(fixture.readCalls, 0);
      },
    );

    test('Method selectManualProfile() reports an unavailable base', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.memoryBase = null;

      expect(fixture.controller.selectManualProfile(fixture.profile), isTrue);
      expect(fixture.controller.state.memoryBase, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
      expect(
        fixture.controller.state.errorMessage,
        contains('base is unavailable'),
      );
    });

    test('Method selectManualProfile() reports read exceptions', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.readError = StateError('read adapter failed');

      expect(fixture.controller.selectManualProfile(fixture.profile), isTrue);
      expect(fixture.controller.state.readResults['bolts']?.value, isNull);
      expect(
        fixture.controller.state.errorMessage,
        contains('read adapter failed'),
      );
    });

    test('Method selectManualProfile() reports base resolution failures', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.baseError = StateError('base adapter failed');

      expect(fixture.controller.selectManualProfile(fixture.profile), isFalse);
      expect(
        fixture.controller.state.errorMessage,
        contains('base adapter failed'),
      );
    });
  });

  group('Method refresh() behaves correctly', () {
    test('Method refresh() leaves an unselected session unchanged', () {
      final fixture = _SessionFixture();

      fixture.controller.refresh();

      expect(fixture.metadataReads, 0);
      expect(fixture.detectCalls, 0);
      expect(fixture.controller.state.readResults, isEmpty);
    });

    test(
      'Method refresh() keeps confirmed identity in every same-session snapshot',
      () async {
        final fixture = _SessionFixture()..controller.connect();
        final snapshots = <TrainerSessionState>[];
        final subscription = fixture.controller.stateChanges.listen(
          snapshots.add,
        );
        await Future<void>.delayed(Duration.zero);
        snapshots.clear();

        fixture.controller.refresh();

        expect(snapshots, isNotEmpty);
        expect(
          snapshots.every(
            (snapshot) => snapshot.profile?.id == 'rc2-collection',
          ),
          isTrue,
        );
        expect(fixture.controller.state.readResults['bolts']?.value, 100);

        await subscription.cancel();
      },
    );

    test('Method refresh() clears unavailable values after a failed read', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.readStatus = GameReadStatus.readFailed;

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults['bolts']?.value, isNull);
      expect(
        fixture.controller.state.readResults['bolts']?.status,
        GameReadStatus.readFailed,
      );
    });

    test('Method refresh() invalidates values when the process exits', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.processIds = [];

      fixture.controller.refresh();

      expect(fixture.controller.state.selectedProcessId, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
      expect(
        fixture.controller.state.detection?.status,
        GameDetectionStatus.rpcs3NotRunning,
      );
    });

    test('Method refresh() updates identity after a game switch', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.profile = _profile(id: 'rc3-collection');

      fixture.controller.refresh();

      expect(fixture.controller.state.profile?.id, 'rc3-collection');
      expect(fixture.controller.state.readResults['bolts']?.value, 100);
    });

    test('Method refresh() clears values when the session restarts', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.startedAtUtc = DateTime.utc(2026, 11, 6, 11);

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults, isEmpty);
      expect(fixture.controller.state.profile, isNull);
      expect(fixture.controller.state.memoryBase, isNull);
      expect(
        fixture.controller.state.errorMessage,
        contains('session changed'),
      );
      expect(
        fixture.controller.writeField('bolts', 101).status,
        GameWriteStatus.unsupportedField,
      );
      expect(fixture.writeCalls, 0);
    });

    test('Method refresh() clears values when game detection fails', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.detectionError = StateError('log unavailable');

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults, isEmpty);
      expect(
        fixture.controller.state.errorMessage,
        contains('log unavailable'),
      );
    });

    test(
      'Method refresh() reports discovery failures and clears stale values',
      () {
        final fixture = _SessionFixture()..controller.connect();
        fixture.discoveryError = StateError('process listing failed');

        fixture.controller.refresh();

        expect(fixture.controller.state.readResults, isEmpty);
        expect(fixture.controller.state.profile, isNull);
        expect(fixture.controller.state.memoryBase, isNull);
        expect(
          fixture.controller.state.errorMessage,
          contains('process listing failed'),
        );
        expect(
          fixture.controller.writeField('bolts', 101).status,
          GameWriteStatus.unsupportedField,
        );
        expect(fixture.writeCalls, 0);
      },
    );

    test(
      'Method refresh() reports metadata failures and clears stale values',
      () {
        final fixture = _SessionFixture()..controller.connect();
        fixture.metadataError = StateError('metadata read failed');

        fixture.controller.refresh();

        expect(fixture.controller.state.readResults, isEmpty);
        expect(
          fixture.controller.state.errorMessage,
          contains('metadata read failed'),
        );
      },
    );

    test('Method refresh() reports base failures and clears stale values', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.baseError = StateError('base resolution failed');

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults, isEmpty);
      expect(
        fixture.controller.state.errorMessage,
        contains('base resolution failed'),
      );
    });

    test('Method refresh() reports an unavailable current base', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.memoryBase = null;

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults, isEmpty);
      expect(
        fixture.controller.state.errorMessage,
        contains('base is unavailable'),
      );
    });

    test('Method refresh() rejects identity evidence for another process', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.detectionProcessId = 99;

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults, isEmpty);
      expect(
        fixture.controller.state.errorMessage,
        contains('another process'),
      );
    });

    test('Method refresh() reports thrown field reads', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.readError = StateError('native read failed');

      fixture.controller.refresh();

      expect(fixture.controller.state.readResults['bolts']?.value, isNull);
      expect(
        fixture.controller.state.errorMessage,
        contains('native read failed'),
      );
    });

    test(
      'Method refresh() continues reading approved fields after one field throws',
      () {
        final fixture =
            _SessionFixture()
              ..profile = _profile(twoFields: true)
              ..controller.connect()
              ..readErrorFieldId = 'bolts'
              ..readError = StateError('bolts read failed');

        fixture.controller.refresh();

        expect(
          fixture.controller.state.readResults['bolts']?.status,
          GameReadStatus.readFailed,
        );
        expect(fixture.controller.state.readResults['weapons']?.value, 7);
        expect(
          fixture.controller.state.errorMessage,
          contains('bolts read failed'),
        );
      },
    );

    test('Method refresh() skips fields that are not approved for reading', () {
      final fixture =
          _SessionFixture()
            ..profile = _profile(withUnreadableField: true)
            ..controller.connect();

      expect(fixture.readCalls, 1);
      expect(fixture.controller.state.readResults.keys, ['bolts']);
    });
  });

  group('Method redetect() behaves correctly', () {
    test(
      'Method redetect() reruns detection and clears old field values first',
      () {
        final fixture = _SessionFixture()..controller.connect();
        final initialDetectionCalls = fixture.detectCalls;

        fixture.controller.redetect();

        expect(fixture.detectCalls, greaterThan(initialDetectionCalls));
        expect(fixture.controller.state.readResults['bolts']?.value, 100);
      },
    );
  });

  group('Method writeField() behaves correctly', () {
    test('Method writeField() writes once and exposes the verified value', () {
      final fixture = _SessionFixture()..controller.connect();

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.succeeded, isTrue);
      expect(fixture.writeCalls, 1);
      expect(fixture.lastConfirmed, isTrue);
      expect(fixture.controller.state.readResults['bolts']?.value, 101);
    });

    test('Method writeField() does not write an unchanged value', () {
      final fixture = _SessionFixture()..controller.connect();

      final result = fixture.controller.writeField('bolts', 100);

      expect(result.status, GameWriteStatus.none);
      expect(fixture.writeCalls, 0);
    });

    test('Method writeField() rejects values outside the field bounds', () {
      final fixture = _SessionFixture()..controller.connect();

      final result = fixture.controller.writeField('bolts', 1000001);

      expect(result.status, GameWriteStatus.invalidValue);
      expect(fixture.writeCalls, 0);
      expect(fixture.controller.state.profile?.id, fixture.profile.id);
      expect(fixture.controller.state.readResults['bolts']?.value, 100);
    });

    test('Method writeField() rejects a value below the field bounds', () {
      final fixture = _SessionFixture()..controller.connect();

      final result = fixture.controller.writeField('bolts', -1);

      expect(result.status, GameWriteStatus.invalidValue);
      expect(fixture.writeCalls, 0);
    });

    test('Method writeField() rejects a missing field before writing', () {
      final fixture = _SessionFixture()..controller.connect();

      final result = fixture.controller.writeField('health', 101);

      expect(result.status, GameWriteStatus.unsupportedField);
      expect(fixture.writeCalls, 0);
      expect(fixture.controller.state.readResults['bolts']?.value, 100);
    });

    test('Method writeField() rejects a read-only field before writing', () {
      final fixture =
          _SessionFixture()
            ..profile = _profile(fieldWriteEnabled: false)
            ..controller.connect();

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.status, GameWriteStatus.unsupportedField);
      expect(fixture.writeCalls, 0);
    });

    test('Method writeField() rejects a profile not approved for writing', () {
      final fixture =
          _SessionFixture()
            ..profile = _profile(writeEnabled: false, fieldWriteEnabled: true)
            ..controller.connect();

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.status, GameWriteStatus.unsupportedProfile);
      expect(fixture.writeCalls, 0);
    });

    test('Method writeField() rejects a missing identity before writing', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.detectionStatus = GameDetectionStatus.ambiguous;

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.status, GameWriteStatus.unsupportedProfile);
      expect(fixture.writeCalls, 0);
    });

    test('Method writeField() blocks when live detection throws', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.detectionError = StateError('identity read failed');

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.status, GameWriteStatus.unsupportedProfile);
      expect(result.succeeded, isFalse);
      expect(fixture.writeCalls, 0);
      expect(fixture.controller.state.profile, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
    });

    test('Method writeField() blocks a stale process session', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.startedAtUtc = DateTime.utc(2026, 11, 6, 11);

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.succeeded, isFalse);
      expect(fixture.writeCalls, 0);
      expect(
        fixture.controller.state.errorMessage,
        contains('session changed'),
      );
      expect(fixture.controller.state.profile, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
    });

    test('Method writeField() blocks a process that has exited', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.processIds = [];

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.succeeded, isFalse);
      expect(fixture.writeCalls, 0);
      expect(fixture.controller.state.profile, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
    });

    test('Method writeField() blocks a changed game', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.profile = _profile(id: 'rc3-collection');

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.succeeded, isFalse);
      expect(fixture.writeCalls, 0);
      expect(fixture.controller.state.profile, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
    });

    test(
      'Method writeField() blocks an executable hash change with the same profile id',
      () {
        final fixture = _SessionFixture()..controller.connect();
        fixture.profile = _profile(executableHash: 'different-hash');

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.succeeded, isFalse);
        expect(fixture.writeCalls, 0);
        expect(fixture.controller.state.profile, isNull);
        expect(fixture.controller.state.readResults, isEmpty);
      },
    );

    test('Method writeField() blocks a changed memory base', () {
      final fixture = _SessionFixture()..controller.connect();
      fixture.memoryBase = 0x400000000;

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.succeeded, isFalse);
      expect(fixture.writeCalls, 0);
      expect(fixture.controller.state.profile, isNull);
      expect(fixture.controller.state.readResults, isEmpty);
    });

    test(
      'Method writeField() blocks when the current memory base is unavailable',
      () {
        final fixture = _SessionFixture()..controller.connect();
        fixture.memoryBase = null;
        fixture.controller.refresh();

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.succeeded, isFalse);
        expect(fixture.writeCalls, 0);
      },
    );

    test(
      'Method writeField() surfaces preliminary read failure without success',
      () {
        final fixture =
            _SessionFixture()
              ..profile = _profile(twoFields: true)
              ..controller.connect()
              ..writeResult = const GameWriteResult(
                status: GameWriteStatus.preliminaryReadFailed,
                fieldId: 'bolts',
                requestedValue: 101,
              );

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.status, GameWriteStatus.preliminaryReadFailed);
        expect(result.succeeded, isFalse);
        expect(fixture.writeCalls, 1);
        expect(
          fixture.controller.state.readResults.containsKey('bolts'),
          isFalse,
        );
        expect(fixture.controller.state.readResults['weapons']?.value, 7);
      },
    );

    test(
      'Method writeField() surfaces partial native writes without success',
      () {
        final fixture =
            _SessionFixture()
              ..profile = _profile(twoFields: true)
              ..controller.connect()
              ..writeResult = const GameWriteResult(
                status: GameWriteStatus.incompleteWrite,
                fieldId: 'bolts',
                requestedValue: 101,
              );

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.status, GameWriteStatus.incompleteWrite);
        expect(result.succeeded, isFalse);
        expect(
          fixture.controller.state.readResults.containsKey('bolts'),
          isFalse,
        );
        expect(fixture.controller.state.readResults['weapons']?.value, 7);
      },
    );

    test(
      'Method writeField() removes only the attempted field after a native write failure',
      () {
        final fixture =
            _SessionFixture()
              ..profile = _profile(twoFields: true)
              ..controller.connect()
              ..writeResult = const GameWriteResult(
                status: GameWriteStatus.writeFailed,
                fieldId: 'bolts',
                requestedValue: 101,
              );

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.succeeded, isFalse);
        expect(fixture.controller.state.lastWriteResult?.succeeded, isFalse);
        expect(
          fixture.controller.state.readResults.containsKey('bolts'),
          isFalse,
        );
        expect(fixture.controller.state.readResults['weapons']?.value, 7);
        expect(fixture.controller.state.profile?.id, fixture.profile.id);
      },
    );

    test(
      'Method writeField() removes only the attempted field after a read-back failure',
      () {
        final fixture =
            _SessionFixture()
              ..profile = _profile(twoFields: true)
              ..controller.connect()
              ..writeResult = const GameWriteResult(
                status: GameWriteStatus.readBackFailed,
                fieldId: 'bolts',
                requestedValue: 101,
              );

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.succeeded, isFalse);
        expect(fixture.controller.state.lastWriteResult?.succeeded, isFalse);
        expect(
          fixture.controller.state.readResults.containsKey('bolts'),
          isFalse,
        );
        expect(fixture.controller.state.readResults['weapons']?.value, 7);
        expect(fixture.controller.state.profile?.id, fixture.profile.id);
      },
    );

    test(
      'Method writeField() surfaces a read-back mismatch without success',
      () {
        final fixture =
            _SessionFixture()
              ..profile = _profile(twoFields: true)
              ..controller.connect()
              ..writeResult = const GameWriteResult(
                status: GameWriteStatus.readBackMismatch,
                fieldId: 'bolts',
                requestedValue: 101,
                readBackValue: 99,
              );

        final result = fixture.controller.writeField('bolts', 101);

        expect(result.succeeded, isFalse);
        expect(result.readBackValue, 99);
        expect(
          fixture.controller.state.readResults.containsKey('bolts'),
          isFalse,
        );
        expect(fixture.controller.state.readResults['weapons']?.value, 7);
      },
    );

    test('Method writeField() reports writer exceptions without success', () {
      final fixture =
          _SessionFixture()
            ..profile = _profile(twoFields: true)
            ..controller.connect();
      fixture.writeError = StateError('writer failed');

      final result = fixture.controller.writeField('bolts', 101);

      expect(result.status, GameWriteStatus.writeFailed);
      expect(result.succeeded, isFalse);
      expect(fixture.controller.state.errorMessage, contains('writer failed'));
      expect(fixture.controller.state.profile?.id, fixture.profile.id);
      expect(
        fixture.controller.state.readResults.containsKey('bolts'),
        isFalse,
      );
      expect(fixture.controller.state.readResults['weapons']?.value, 7);
    });
  });
}

class _SessionFixture {
  List<int> processIds = [42];
  DateTime startedAtUtc = DateTime.utc(2026, 11, 6, 10);
  int? memoryBase = 0x300000000;
  GameProfile profile = _profile();
  GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame;
  GameReadStatus readStatus = GameReadStatus.success;
  GameWriteResult? writeResult;
  Object? discoveryError;
  Object? metadataError;
  Object? baseError;
  Object? detectionError;
  Object? readError;
  String? readErrorFieldId;
  Object? writeError;
  int? detectionProcessId;
  int metadataReads = 0;
  int detectCalls = 0;
  int readCalls = 0;
  int writeCalls = 0;
  bool? lastConfirmed;
  late final TrainerSessionController controller = TrainerSessionController(
    discoverProcessIds: () {
      if (discoveryError case final error?) throw error;
      return processIds;
    },
    readProcessMetadata: (processId) {
      metadataReads++;
      if (metadataError case final error?) throw error;
      return _metadata(startedAtUtc);
    },
    resolveMemoryBaseCandidate: (_) {
      if (baseError case final error?) throw error;
      final currentBase = memoryBase;
      return currentBase == null
          ? null
          : Rpcs3MemoryBaseCandidate(
            memoryBase: currentBase,
            logPath: r'C:\RPCS3\log\RPCS3.log',
          );
    },
    detectGame: (processId, _) {
      detectCalls++;
      if (detectionError case final error?) throw error;
      return _detection(
        detectionProcessId ?? processId,
        profile,
        detectionStatus,
      );
    },
    readField: (processId, selectedProfile, base, fieldId) {
      readCalls++;
      if (readError case final error?
          when readErrorFieldId == null || readErrorFieldId == fieldId) {
        throw error;
      }
      return GameReadResult(
        status: readStatus,
        fieldId: fieldId,
        value:
            readStatus == GameReadStatus.success
                ? fieldId == 'weapons'
                    ? 7
                    : 100
                : null,
      );
    },
    writeField: (processId, selectedProfile, base, fieldId, value, confirmed) {
      writeCalls++;
      lastConfirmed = confirmed;
      if (writeError case final error?) throw error;
      return writeResult ??
          GameWriteResult(
            status: GameWriteStatus.success,
            fieldId: fieldId,
            requestedValue: value,
            readBackValue: value,
          );
    },
  );
}

GameProfile _profile({
  String id = 'rc2-collection',
  String executableHash = 'profile-hash',
  bool writeEnabled = true,
  bool fieldWriteEnabled = true,
  bool withUnreadableField = false,
  bool twoFields = false,
}) => GameProfile(
  id: id,
  gameName: 'Ratchet & Clank 2',
  buildId: 'BCUS98282',
  executable: 'RC2.ppu.self',
  executableHash: executableHash,
  readStatus: VerificationStatus.verified,
  writeStatus:
      writeEnabled
          ? VerificationStatus.researchConfirmed
          : VerificationStatus.none,
  fields: {
    'bolts': GameField(
      id: 'bolts',
      name: 'Bolts',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus:
          fieldWriteEnabled
              ? VerificationStatus.researchConfirmed
              : VerificationStatus.none,
      minimumValue: 0,
      maximumValue: 1000000,
    ),
    if (withUnreadableField)
      'secret': GameField(
        id: 'secret',
        name: 'Secret',
        guestOffset: 0x2000,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.none,
      ),
    if (twoFields)
      'weapons': GameField(
        id: 'weapons',
        name: 'Weapons',
        guestOffset: 0x2000,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.verified,
      ),
  },
);

Rpcs3ProcessMetadata _metadata(DateTime startedAtUtc) => Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: startedAtUtc,
);

GameDetectionResult _detection(
  int processId,
  GameProfile profile,
  GameDetectionStatus status,
) => GameDetectionResult(
  status: status,
  processId: processId,
  titleId: profile.buildId,
  gameTitle: profile.gameName,
  executable: profile.executable,
  executableHash: profile.executableHash,
  confidence:
      status == GameDetectionStatus.supportedGame
          ? GameIdentityConfidence.confirmed
          : GameIdentityConfidence.none,
  profile: status == GameDetectionStatus.supportedGame ? profile : null,
  evidenceDescription: 'Synthetic session evidence.',
);
