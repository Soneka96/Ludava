import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_event.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_snapshot.entity.dart';
import 'package:test/test.dart';

Rpcs3GameIdentityLogSnapshot _snapshot({
  List<String> titles = const ['Synthetic Collection'],
  List<String> serials = const ['TEST00001'],
  List<String> bootPaths = const [],
  List<Rpcs3GameIdentityLogEvent> events = const [],
}) => Rpcs3GameIdentityLogSnapshot(
  titles: titles,
  serials: serials,
  bootPaths: bootPaths,
  events: events,
  logPath: r'C:\RPCS3\log\RPCS3.log',
  logModifiedAtUtc: DateTime.utc(2026, 11, 5, 12),
  processStartedAtUtc: DateTime.utc(2026, 11, 5, 11),
);

void main() {
  group('Class Rpcs3GameIdentityLogSnapshot construction', () {
    test(
      'Class Rpcs3GameIdentityLogSnapshot takes immutable list snapshots',
      () {
        final titles = ['Synthetic Collection'];
        final serials = ['TEST00001'];
        final bootPaths = [r'D:\Games\EBOOT.BIN'];
        final events = [
          const Rpcs3GameIdentityLogEvent(
            executable: 'BETA.self',
            executableHash: 'PPU-measured-hash',
          ),
        ];
        final snapshot = Rpcs3GameIdentityLogSnapshot(
          titles: titles,
          serials: serials,
          bootPaths: bootPaths,
          events: events,
          logPath: r'C:\RPCS3\log\RPCS3.log',
          logModifiedAtUtc: DateTime.utc(2026, 11, 5, 12),
          processStartedAtUtc: DateTime.utc(2026, 11, 5, 11),
        );
        titles.add('Another game');
        serials.add('TEST00002');
        bootPaths.add(r'D:\Other\EBOOT.BIN');
        events.add(const Rpcs3GameIdentityLogEvent(processFinished: true));

        expect(snapshot.titles, ['Synthetic Collection']);
        expect(snapshot.serials, ['TEST00001']);
        expect(snapshot.bootPaths, [r'D:\Games\EBOOT.BIN']);
        expect(snapshot.events, hasLength(1));
        expect(snapshot.events.single.executableHash, 'PPU-measured-hash');
        expect(
          () => snapshot.titles.add('Another game'),
          throwsUnsupportedError,
        );
        expect(() => snapshot.serials.add('TEST00002'), throwsUnsupportedError);
        expect(
          () => snapshot.bootPaths.add(r'D:\Other\EBOOT.BIN'),
          throwsUnsupportedError,
        );
        expect(
          () => snapshot.events.add(
            const Rpcs3GameIdentityLogEvent(processFinished: true),
          ),
          throwsUnsupportedError,
        );
      },
    );
  });

  group('Property latestEvent behaves correctly', () {
    test('Property latestEvent returns the last lifecycle observation', () {
      const stopEvent = Rpcs3GameIdentityLogEvent(processFinished: true);
      final snapshot = _snapshot(
        events: const [
          Rpcs3GameIdentityLogEvent(executableHash: 'PPU-first'),
          stopEvent,
        ],
      );

      expect(snapshot.latestEvent, same(stopEvent));
      expect(snapshot.latestEvent?.processFinished, isTrue);
    });

    test(
      'Property latestEvent returns null without lifecycle observations',
      () {
        expect(_snapshot(events: const []).latestEvent, isNull);
      },
    );
  });

  group('Property hasConflictingIdentity behaves correctly', () {
    test(
      'Property hasConflictingIdentity returns false without identity values',
      () {
        expect(
          _snapshot(titles: const [], serials: const []).hasConflictingIdentity,
          isFalse,
        );
      },
    );

    test('Property hasConflictingIdentity returns false for one identity', () {
      expect(
        _snapshot(titles: ['Synthetic Collection']).hasConflictingIdentity,
        isFalse,
      );
    });

    test(
      'Property hasConflictingIdentity returns true for multiple titles',
      () {
        expect(
          _snapshot(titles: ['First', 'Second']).hasConflictingIdentity,
          isTrue,
        );
      },
    );

    test(
      'Property hasConflictingIdentity returns true for multiple serials',
      () {
        expect(
          _snapshot(serials: ['TEST00001', 'TEST00002']).hasConflictingIdentity,
          isTrue,
        );
      },
    );

    test(
      'Property hasConflictingIdentity returns true for multiple boot paths',
      () {
        expect(
          _snapshot(
            bootPaths: const [r'D:\First\EBOOT.BIN', r'D:\Second\EBOOT.BIN'],
          ).hasConflictingIdentity,
          isTrue,
        );
      },
    );

    test(
      'Property hasConflictingIdentity returns true for conflicting titles and serials',
      () {
        expect(
          _snapshot(
            titles: ['First', 'Second'],
            serials: ['TEST00001', 'TEST00002'],
          ).hasConflictingIdentity,
          isTrue,
        );
      },
    );
  });
}
