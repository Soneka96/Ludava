import 'package:ludava/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/trainer/application/trainer_session_controller.dart';
import 'package:ludava/features/trainer/presentation/nocterm/trainer_session_component.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:nocterm/nocterm_test.dart'
    show LogicalKey, containsText, testNocterm;
import 'package:test/test.dart';

void main() {
  group('Class TrainerSessionComponent session behavior', () {
    test(
      'Class TrainerSessionComponent connects one process and shows its field value',
      () async {
        await testNocterm('single RPCS3 process', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          expect(tester.terminalState, containsText('CONNECTED'));
          expect(tester.terminalState, containsText('Ratchet & Clank 2'));
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
          await tester.sendEnter();

          expect(fixture.controller.state.selectedProcessId, 43);
          expect(tester.terminalState, containsText('CONNECTED'));
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
            containsText('Start a supported Collection game'),
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
      'Class TrainerSessionComponent preserves selection when cancelling an editor',
      () async {
        await testNocterm('cancel and return to selected field', (
          tester,
        ) async {
          final fixture =
              _SessionFixture()..profile = _profile(twoFields: true);
          await tester.pumpComponent(_app(fixture));

          await tester.sendKey(LogicalKey.digit2);
          await tester.sendEnter();
          expect(tester.terminalState, containsText('EDIT WEAPONS'));
          await tester.sendEscape();
          expect(fixture.writeCalls, 0);

          await tester.sendEnter();

          expect(tester.terminalState, containsText('EDIT WEAPONS'));
          expect(fixture.writeCalls, 0);
        });
      },
    );

    test(
      'Class TrainerSessionComponent applies once and shows verified read-back',
      () async {
        await testNocterm('apply from the editor', (tester) async {
          final fixture = _SessionFixture();
          await tester.pumpComponent(_app(fixture));

          await tester.sendEnter();
          await tester.enterText('5');
          await tester.sendEnter();

          expect(fixture.writeCalls, 1);
          expect(fixture.lastConfirmed, isTrue);
          expect(tester.terminalState, containsText('Verified value: 1,005'));
          await tester.sendEnter();
          expect(fixture.writeCalls, 1);
          await tester.sendEscape();

          expect(tester.terminalState, containsText('1,005'));
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
  int readCalls = 0;
  int detectCalls = 0;
  int writeCalls = 0;
  bool? lastConfirmed;
  GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame;

  late final TrainerSessionController controller = TrainerSessionController(
    discoverProcessIds: () => processIds,
    readProcessMetadata:
        (_) => Rpcs3ProcessMetadata(
          executablePath: r'C:\RPCS3\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026, 11, 6, 10),
        ),
    resolveMemoryBaseCandidate:
        (_) => const Rpcs3MemoryBaseCandidate(
          memoryBase: 0x300000000,
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
        evidenceDescription: 'Synthetic session evidence.',
      );
    },
    readField: (processId, selectedProfile, memoryBase, fieldId) {
      readCalls++;
      return GameReadResult(
        status: GameReadStatus.success,
        fieldId: fieldId,
        value: fieldId == 'weapons' ? 7 : 100,
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

GameProfile _profile({bool twoFields = false}) => GameProfile(
  id: 'rc2-collection',
  gameName: 'Ratchet & Clank 2',
  buildId: 'BCUS98282',
  executable: 'RC2.ppu.self',
  executableHash: 'measured-hash',
  readStatus: VerificationStatus.verified,
  writeStatus: VerificationStatus.researchConfirmed,
  fields: {
    'bolts': GameField(
      id: 'bolts',
      name: 'Bolts',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.verified,
      writeStatus: VerificationStatus.researchConfirmed,
      minimumValue: 0,
      maximumValue: GameMemoryConstants.maxUnsigned32,
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
