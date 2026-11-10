import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/trainer/presentation/nocterm/trainer_session_component.dart';
import 'package:nocterm/nocterm_test.dart'
    show LogicalKey, containsText, testNocterm;
import 'package:nocterm/nocterm.dart' show SizedBox;
import 'package:test/test.dart';

TrainerSessionComponent _app(
  _SessionFixture fixture, {
  void Function()? onQuit,
}) => TrainerSessionComponent(
  sessionController: fixture.controller,
  onQuit: onQuit ?? () {},
);

class _SessionFixture {
  List<int> processIds = [42];
  GameProfile profile = _profile();
  DateTime startedAtUtc = DateTime.utc(2026, 11, 6, 10);
  int memoryBase = 0x300000000;
  int readCalls = 0;
  int detectCalls = 0;
  int writeCalls = 0;
  bool? lastConfirmed;
  bool failMetadata = false;
  GameReadStatus readStatus = GameReadStatus.success;
  GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame;
  String evidenceDescription = 'Synthetic session evidence.';

  late final TrainerSessionController controller = TrainerSessionController(
    discoverProcessIds: () => processIds,
    readProcessMetadata: (_) {
      if (failMetadata) throw StateError('Test metadata failure.');
      return Rpcs3ProcessMetadata(
        executablePath: r'C:\RPCS3\rpcs3.exe',
        startedAtUtc: startedAtUtc,
      );
    },
    resolveMemoryBaseCandidate:
        (_) => Rpcs3MemoryBaseCandidate(
          memoryBase: memoryBase,
          logPath: r'C:\RPCS3\log\RPCS3.log',
        ),
    detectGame: (processId, _) {
      detectCalls++;
      return GameDetectionResult(
        status: detectionStatus,
        processId: processId,
        titleId: profile.buildId,
        gameTitle: profile.gameName,
        executable: profile.executable,
        executableHash: profile.executableHash,
        confidence:
            detectionStatus == GameDetectionStatus.supportedGame
                ? GameIdentityConfidence.confirmed
                : GameIdentityConfidence.none,
        profile:
            detectionStatus == GameDetectionStatus.supportedGame
                ? profile
                : null,
        evidenceDescription: evidenceDescription,
      );
    },
    readField: (processId, selectedProfile, memoryBase, fieldId) {
      readCalls++;
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
    writeField: (
      processId,
      selectedProfile,
      memoryBase,
      fieldId,
      value,
      confirmed,
    ) {
      writeCalls++;
      lastConfirmed = confirmed;
      return GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: fieldId,
        requestedValue: value,
        readBackValue: value,
      );
    },
  );
}

GameProfile _profile({
  String id = 'synthetic-profile',
  String executableHash = 'measured-hash',
  bool twoFields = false,
  bool profileWritable = true,
}) => GameProfile(
  id: id,
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
  executableHash: executableHash,
  readStatus: VerificationStatus.verified,
  writeStatus:
      profileWritable
          ? VerificationStatus.researchConfirmed
          : VerificationStatus.none,
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus: VerificationStatus.researchConfirmed,
      minimumValue: 0,
      maximumValue: 0xffffffff,
    ),
    if (twoFields)
      'weapons': GameField(
        id: 'weapons',
        name: 'Weapons',
        guestOffset: 0x2000,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.verified,
        writeStatus: VerificationStatus.researchConfirmed,
        minimumValue: 0,
        maximumValue: 0xffffffff,
      ),
  },
);

void main() {
  group('Class TrainerSessionComponent session behavior', () {
    test(
      'Class TrainerSessionComponent connects one process and shows its field value',
      () async {
        await testNocterm('single RPCS3 process', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          expect(tester.terminalState, containsText('CONNECTED'));
          expect(tester.terminalState, containsText('Synthetic game'));
          expect(tester.terminalState, containsText('100'));
          expect(fixture.controller.state.selectedProcessId, 42);
        });
      },
    );

    test(
      'Class TrainerSessionComponent asks which process to use when several exist',
      () async {
        await testNocterm('multiple RPCS3 processes', (tester) async {
          final fixture = _SessionFixture()..processIds = [42, 43];
          await tester.pumpComponent(_app(fixture));

          expect(tester.terminalState, containsText('Select an RPCS3 process'));
          expect(tester.terminalState, containsText('PID 42'));
          expect(tester.terminalState, containsText('PID 43'));
          await tester.sendArrowDown();
          expect(tester.terminalState, containsText('❯ 2. PID 43'));
          await tester.sendEnter();

          expect(fixture.controller.state.selectedProcessId, 43);
          expect(tester.terminalState, containsText('CONNECTED'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent stops observing after disposal',
      () async {
        await testNocterm('session observer cleanup', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          await tester.pumpComponent(const SizedBox());
          fixture.detectionStatus = GameDetectionStatus.unsupportedGame;
          fixture.controller.refresh();

          expect(
            fixture.controller.state.detection?.status,
            GameDetectionStatus.unsupportedGame,
          );
          expect(
            tester.terminalState,
            isNot(containsText('This game is not supported')),
          );
        });
      },
    );

    test(
      'Class TrainerSessionComponent refreshes and re-detects from menu shortcuts',
      () async {
        await testNocterm('refresh and re-detect', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          final initialReads = fixture.readCalls;
          final initialDetections = fixture.detectCalls;

          await tester.sendKey(LogicalKey.keyR);
          expect(fixture.readCalls, greaterThan(initialReads));
          await tester.sendKey(LogicalKey.keyG);

          expect(fixture.detectCalls, greaterThan(initialDetections));
          expect(tester.terminalState, containsText('100'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent preserves the selected row on same-session refresh',
      () async {
        await testNocterm('preserve selected field after Refresh', (
          tester,
        ) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));
          await tester.sendArrowDown();
          expect(tester.terminalState, containsText('❯ 2. Weapons'));

          final initialReads = fixture.readCalls;
          await tester.sendKey(LogicalKey.keyR);

          expect(fixture.readCalls, greaterThan(initialReads));
          expect(tester.terminalState, containsText('❯ 2. Weapons'));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent displays session errors from the SDK state',
      () async {
        await testNocterm('session error feedback', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          fixture.failMetadata = true;

          await tester.sendKey(LogicalKey.keyR);

          expect(tester.terminalState, containsText('Test metadata failure.'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent closes editing when the current profile becomes read-only',
      () async {
        await testNocterm('profile permission changes during refresh', (
          tester,
        ) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT CREDITS'));

          fixture.profile = _profile(twoFields: true, profileWritable: false);
          fixture.controller.refresh();
          await tester.pump();

          expect(tester.terminalState, isNot(containsText('EDIT CREDITS')));
          expect(
            tester.terminalState,
            containsText('Selected field is read-only'),
          );
          await tester.sendKey(LogicalKey.digit1);
          await tester.sendEnter();
          expect(tester.terminalState, isNot(containsText('EDIT CREDITS')));
          expect(fixture.writeCalls, 0);

          final readCalls = fixture.readCalls;
          await tester.sendKey(LogicalKey.keyR);
          expect(fixture.readCalls, greaterThan(readCalls));

          fixture.profile = _profile(twoFields: true);
          fixture.controller.refresh();
          await tester.pump();
          expect(tester.terminalState, containsText('1–9 Edit'));
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT CREDITS'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent closes stale editing state when refresh loses the field value',
      () async {
        await testNocterm('field becomes unavailable during refresh', (
          tester,
        ) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT CREDITS'));

          fixture.readStatus = GameReadStatus.readFailed;
          fixture.controller.refresh();
          await tester.pump();

          expect(tester.terminalState, containsText('Unavailable'));
          expect(tester.terminalState, isNot(containsText('EDIT CREDITS')));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent clears the old session on process restart until re-detection',
      () async {
        await testNocterm('process restarts during refresh', (tester) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));
          await tester.sendArrowDown();
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT WEAPONS'));

          fixture.startedAtUtc = DateTime.utc(2026, 11, 6, 11);
          fixture.controller.refresh();
          await tester.pump();

          expect(fixture.controller.state.profile, isNull);
          expect(fixture.controller.state.memoryBase, isNull);
          expect(fixture.controller.state.readResults, isEmpty);
          expect(tester.terminalState, isNot(containsText('EDIT WEAPONS')));
          expect(tester.terminalState, isNot(containsText('Weapons')));
          expect(tester.terminalState, containsText('session changed'));

          await tester.sendKey(LogicalKey.keyG);

          expect(fixture.controller.state.profile?.id, 'synthetic-profile');
          expect(fixture.controller.state.readResults['credits']?.value, 100);
          expect(tester.terminalState, containsText('Synthetic game'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent resets selection and closes the editor when the detected game changes',
      () async {
        await testNocterm('game changes during refresh', (tester) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));
          await tester.sendArrowDown();
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT WEAPONS'));

          fixture.profile = _profile(id: 'synthetic-profile-next');
          fixture.controller.refresh();
          await tester.pump();

          expect(
            fixture.controller.state.profile?.id,
            'synthetic-profile-next',
          );
          expect(
            tester.terminalState,
            containsText('Synthetic game · PS3 SYNTHETIC'),
          );
          expect(tester.terminalState, isNot(containsText('EDIT WEAPONS')));
          expect(tester.terminalState, containsText('❯ 1. Credits'));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent lets the user retry discovery when RPCS3 starts',
      () async {
        await testNocterm('RPCS3 starts later', (tester) async {
          final fixture = _SessionFixture()..processIds = [];
          await tester.pumpComponent(_app(fixture));
          expect(tester.terminalState, containsText('RPCS3 was not found'));
          fixture.processIds = [42];

          await tester.sendKey(LogicalKey.keyR);

          expect(fixture.controller.state.selectedProcessId, 42);
          expect(tester.terminalState, containsText('CONNECTED'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent explains inactive and unsupported games',
      () async {
        await testNocterm('game status feedback', (tester) async {
          final fixture =
              _SessionFixture()
                ..detectionStatus = GameDetectionStatus.noActiveGame;
          await tester.pumpComponent(_app(fixture));
          expect(
            tester.terminalState,
            containsText('Start a supported game in RPCS3'),
          );

          fixture.detectionStatus = GameDetectionStatus.unsupportedGame;
          await tester.sendKey(LogicalKey.keyG);

          expect(
            tester.terminalState,
            containsText('This game is not supported'),
          );
        });
      },
    );

    test(
      'Class TrainerSessionComponent explains ambiguous and failed detection',
      () async {
        await testNocterm('ambiguous and failed detection', (tester) async {
          final fixture =
              _SessionFixture()
                ..detectionStatus = GameDetectionStatus.ambiguous;
          await tester.pumpComponent(_app(fixture));

          expect(
            tester.terminalState,
            containsText('Could not verify the active game'),
          );
          final initialDetectionCount = fixture.detectCalls;
          fixture.detectionStatus = GameDetectionStatus.failed;
          await tester.sendKey(LogicalKey.keyG);

          expect(fixture.detectCalls, greaterThan(initialDetectionCount));
          expect(
            tester.terminalState,
            containsText('Synthetic session evidence'),
          );
          fixture.evidenceDescription = '';
          await tester.sendKey(LogicalKey.keyG);
          expect(tester.terminalState, containsText('Game detection failed'));
        });
      },
    );

    test(
      'Class TrainerSessionComponent preserves menu selection and editor key ownership',
      () async {
        await testNocterm('menu and editor digit ownership', (tester) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));

          await tester.sendArrowDown();
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT WEAPONS'));
          await tester.enterText('2');
          expect(tester.terminalState, containsText('72'));
          await tester.sendEscape();
          await tester.sendEnter();

          expect(tester.terminalState, containsText('EDIT WEAPONS'));
          expect(tester.terminalState, containsText('Current value: 7'));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent closes after applying and shows read-back',
      () async {
        await testNocterm('apply from the editor', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          await tester.sendEnter();
          await tester.enterText('5');
          await tester.sendEnter();

          expect(fixture.writeCalls, 1);
          expect(fixture.lastConfirmed, isTrue);
          expect(
            tester.terminalState,
            containsText('Credits updated to 1,005'),
          );
          expect(tester.terminalState, isNot(containsText('EDIT CREDITS')));
          expect(fixture.writeCalls, 1);
        });
      },
    );

    test(
      'Class TrainerSessionComponent invalidates the editor when the process session changes before apply',
      () async {
        await testNocterm('process session changes before apply', (
          tester,
        ) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));
          await tester.sendEnter();
          await tester.enterText('1');
          fixture.startedAtUtc = DateTime.utc(2026, 11, 6, 11);

          await tester.sendEnter();

          expect(fixture.writeCalls, 0);
          expect(fixture.controller.state.profile, isNull);
          expect(fixture.controller.state.readResults, isEmpty);
          expect(tester.terminalState, containsText('session changed'));
          expect(tester.terminalState, isNot(containsText('EDIT CREDITS')));
        });
      },
    );

    test(
      'Class TrainerSessionComponent quits through the supplied shutdown action',
      () async {
        await testNocterm('quit action', (tester) async {
          final fixture = _SessionFixture();
          var quitCount = 0;
          await tester.pumpComponent(_app(fixture, onQuit: () => quitCount++));

          await tester.sendKey(LogicalKey.keyQ);

          expect(quitCount, 1);
        });
      },
    );
  });
}
