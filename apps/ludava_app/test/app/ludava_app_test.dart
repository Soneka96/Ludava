import 'dart:ffi' as ffi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_app.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/features/game_header/presentation/trainer_game_header.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  group('Class LudavaApp lifecycle behavior', () {
    testWidgets('Class LudavaApp renders the missing RPCS3 state', (
      tester,
    ) async {
      var discoveryCalls = 0;
      final sdk = _createSdk(() {
        discoveryCalls++;
        return const [];
      });

      await tester.pumpWidget(_app(sdk: sdk));

      expect(find.text('Connect to RPCS3'), findsOneWidget);
      expect(find.byType(DragToResizeArea), findsOneWidget);
      expect(
        find.text('RPCS3 was not found. Start RPCS3, then select Refresh.'),
        findsOneWidget,
      );
      expect(discoveryCalls, 1);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });

    testWidgets('Class LudavaApp renders the latest process snapshot', (
      tester,
    ) async {
      var processIds = <int>[];
      final sdk = _createSdk(() => processIds);

      await tester.pumpWidget(_app(sdk: sdk));
      expect(
        find.text('RPCS3 was not found. Start RPCS3, then select Refresh.'),
        findsOneWidget,
      );

      processIds = [120, 240];
      sdk.session.connect();
      await tester.pump();

      expect(find.text('Available RPCS3 processes'), findsOneWidget);
      expect(find.text('Choose process'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await expectLater(sdk.session.stateChanges, emitsDone);
    });

    testWidgets(
      'Class LudavaApp selects an RPCS3 process and refreshes state',
      (tester) async {
        var discoveryCalls = 0;
        final metadata = Rpcs3ProcessMetadata(
          executablePath: r'C:\Games\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026),
        );
        final sdk = LudavaSdk.create(
          isWindows: false,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [120, 240];
          },
          readProcessMetadata: (_) => metadata,
          resolveMemoryBaseCandidate: (_) => null,
          detectGame: (processId, _) => GameDetectionResult(
            status: GameDetectionStatus.noActiveGame,
            processId: processId,
            confidence: GameIdentityConfidence.none,
            evidenceDescription: 'No game is active.',
          ),
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        expect(find.text('Process ID 120'), findsOneWidget);
        expect(find.text('Process ID 240'), findsOneWidget);

        await tester.tap(find.text('Process ID 240'));
        await tester.pump();
        expect(find.text('RPCS3 process · PID 240'), findsOneWidget);
        expect(find.text('No game'), findsOneWidget);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();
        expect(discoveryCalls, 2);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Re-detect'));
        await tester.pump();
        expect(discoveryCalls, 3);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp reports a process that disappears before selection',
      (tester) async {
        final sdk = LudavaSdk.create(
          isWindows: false,
          discoverProcessIds: () => const [120, 240],
          readProcessMetadata: (_) =>
              throw StateError('This RPCS3 process is no longer available.'),
          resolveMemoryBaseCandidate: (_) => null,
          detectGame: (_, _) => throw StateError('Detection is not reached.'),
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.text('Process ID 240'));
        await tester.pump();

        expect(find.text('Attention'), findsOneWidget);
        expect(
          find.text('Bad state: This RPCS3 process is no longer available.'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp clears the selected PID after it exits', (
      tester,
    ) async {
      var processIsRunning = true;
      final metadata = Rpcs3ProcessMetadata(
        executablePath: r'C:\Games\rpcs3.exe',
        startedAtUtc: DateTime.utc(2026),
      );
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => processIsRunning ? const [120] : const [],
        readProcessMetadata: (_) => metadata,
        resolveMemoryBaseCandidate: (_) => null,
        detectGame: (processId, _) => GameDetectionResult(
          status: GameDetectionStatus.noActiveGame,
          processId: processId,
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'No game is active.',
        ),
      );

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();
      expect(find.text('RPCS3 process · PID 120'), findsOneWidget);
      processIsRunning = false;
      await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
      await tester.pump();

      expect(find.text('Attention'), findsOneWidget);
      expect(find.text('RPCS3 process · PID 120'), findsNothing);
      expect(find.text('RPCS3 is no longer running.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'Class LudavaApp invalidates state when an RPCS3 PID is reused',
      (tester) async {
        var startedAt = DateTime.utc(2026);
        final sdk = LudavaSdk.create(
          isWindows: false,
          discoverProcessIds: () => const [120],
          readProcessMetadata: (_) => Rpcs3ProcessMetadata(
            executablePath: r'C:\Games\rpcs3.exe',
            startedAtUtc: startedAt,
          ),
          resolveMemoryBaseCandidate: (_) => null,
          detectGame: (processId, _) => GameDetectionResult(
            status: GameDetectionStatus.noActiveGame,
            processId: processId,
            confidence: GameIdentityConfidence.none,
            evidenceDescription: 'No game is active.',
          ),
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        expect(find.text('No game'), findsOneWidget);
        startedAt = DateTime.utc(2026, 1, 2);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(find.text('Attention'), findsOneWidget);
        expect(
          find.text('The RPCS3 session changed. Re-detect the game.'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp clears detection after selected discovery fails',
      (tester) async {
        var discoveryFails = false;
        final metadata = Rpcs3ProcessMetadata(
          executablePath: r'C:\Games\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026),
        );
        final sdk = LudavaSdk.create(
          isWindows: false,
          discoverProcessIds: () {
            if (discoveryFails) throw StateError('RPCS3 discovery failed.');
            return const [120];
          },
          readProcessMetadata: (_) => metadata,
          resolveMemoryBaseCandidate: (_) => null,
          detectGame: (processId, _) => GameDetectionResult(
            status: GameDetectionStatus.noActiveGame,
            processId: processId,
            confidence: GameIdentityConfidence.none,
            evidenceDescription: 'No game is active.',
          ),
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        expect(find.text('No game'), findsOneWidget);
        discoveryFails = true;
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(find.text('Attention'), findsOneWidget);
        expect(find.text('Bad state: RPCS3 discovery failed.'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp reconnects for unselected refresh actions', (
      tester,
    ) async {
      var discoveryCalls = 0;
      final sdk = _createSdk(() {
        discoveryCalls++;
        return const [];
      });

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
      await tester.pump();
      expect(discoveryCalls, 2);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Re-detect'));
      await tester.pump();

      expect(discoveryCalls, 3);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'Class LudavaApp renders at the supported minimum window size',
      (tester) async {
        tester.view.physicalSize = const Size(720, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final sdk = _createSdk(() => const []);

        await tester.pumpWidget(_app(sdk: sdk));

        expect(find.text('Connect to RPCS3'), findsOneWidget);
        expect(
          find.text('RPCS3 was not found. Start RPCS3, then select Refresh.'),
          findsOneWidget,
        );
        expect(find.byTooltip('Minimize window'), findsOneWidget);
        expect(find.byTooltip('Maximize or restore window'), findsOneWidget);
        expect(find.byTooltip('Close window'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp caps content width on a wide viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sdk = _createSdk(() => const []);

      await tester.pumpWidget(_app(sdk: sdk));

      expect(
        tester.getSize(find.byType(TrainerGameHeader)).width,
        LudavaDimensions.maximumContentWidth,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('ludava-titlebar-surface')))
            .width,
        1800,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Class LudavaApp accepts an alternate test theme', (
      tester,
    ) async {
      final sdk = _createSdk(() => const []);
      final alternateTheme = ThemeData.light().copyWith(
        extensions: [GraphiteTealTheme.tokens.copyWith(surface: Colors.amber)],
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.purple),
        ),
      );

      await tester.pumpWidget(_app(sdk: sdk, theme: alternateTheme));

      final heading = tester.widget<Text>(find.text('Connect to RPCS3'));
      expect(heading.style?.color, Colors.purple);
      final titleBar = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ludava-titlebar-surface')),
      );
      expect((titleBar.decoration as BoxDecoration).color, Colors.amber);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Class LudavaApp wires title-bar actions to its window owner', (
      tester,
    ) async {
      final sdk = _createSdk(() => const []);
      final window = _RecordingWindowController();

      await tester.pumpWidget(_app(sdk: sdk, windowController: window));
      await tester.tap(find.byTooltip('Minimize window'));
      await tester.tap(find.byTooltip('Maximize or restore window'));
      await tester.tap(find.byTooltip('Close window'));

      expect(window.configureCalls, 1);
      expect(window.minimizeCalls, 1);
      expect(window.maximizeCalls, 1);
      expect(window.closeCalls, 1);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Class LudavaApp selects the single discovered process', (
      tester,
    ) async {
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => const [120],
        readProcessMetadata: (_) => Rpcs3ProcessMetadata(
          executablePath: r'C:\Games\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026),
        ),
        resolveMemoryBaseCandidate: (_) => null,
        detectGame: (processId, _) => GameDetectionResult(
          status: GameDetectionStatus.noActiveGame,
          processId: processId,
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'No game is active.',
        ),
      );

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();

      expect(find.text('RPCS3 process · PID 120'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });

    testWidgets('Class LudavaApp renders fields from the detected profile', (
      tester,
    ) async {
      final profile = GameProfileCatalog.profiles.first;
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => const [321],
        readProcessMetadata: (_) => Rpcs3ProcessMetadata(
          executablePath: r'C:\Games\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026),
        ),
        resolveMemoryBaseCandidate: (_) => null,
        detectGame: (processId, _) => GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          processId: processId,
          profile: profile,
          confidence: GameIdentityConfidence.confirmed,
          evidenceDescription: 'Confirmed test profile.',
        ),
      );

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();

      expect(find.text(profile.gameName), findsOneWidget);
      expect(find.text('Bolts'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'Class LudavaApp does not write while opening or cancelling an edit',
      (tester) async {
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(memory);

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();

        expect(_editorText(tester), '17');
        expect(memory.writeCalls, 0);
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );
        expect(memory.writeCalls, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(memory.writeCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp applies a value through the SDK and read-back',
      (tester) async {
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(memory);

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        expect(find.text('17'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );
        expect(memory.writeCalls, 0);

        await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
        await tester.pump();

        expect(memory.writeCalls, 1);
        expect(find.text('Applied and verified: 42'), findsOneWidget);
        expect(find.text('42'), findsAtLeastNWidgets(1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp reports failed writes without success', (
      tester,
    ) async {
      final memory = _FakeMemoryApi(writeSucceeds: false);
      final sdk = _createWritableSdk(memory);

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Edit'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('inline-editor-input-bolts')),
        '42',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pump();

      expect(memory.writeCalls, 1);
      expect(
        find.text('The write failed with system error 5.'),
        findsOneWidget,
      );
      expect(find.text('Applied and verified: 42'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'Class LudavaApp discards the draft when the target disconnects',
      (tester) async {
        var processIsRunning = true;
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(
          memory,
          discoverProcessIds: () => processIsRunning ? const [321] : const [],
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );

        processIsRunning = false;
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(find.text('RPCS3 process · PID 321'), findsNothing);
        expect(memory.writeCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp discards the draft after the RPCS3 process restarts',
      (tester) async {
        var startedAt = DateTime.utc(2026);
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(
          memory,
          processStartedAt: () => startedAt,
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );

        startedAt = DateTime.utc(2026, 1, 2);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(
          find.text('The RPCS3 session changed. Re-detect the game.'),
          findsOneWidget,
        );
        expect(memory.writeCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp discards the draft after the memory base changes',
      (tester) async {
        var memoryBase = 0x100000;
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(memory, memoryBase: () => memoryBase);

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );

        memoryBase = 0x200000;
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(memory.writeCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp discards the draft after executable identity changes',
      (tester) async {
        var executableHash = GameProfileCatalog.profiles.first.executableHash;
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(
          memory,
          executableHash: () => executableHash,
        );

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );

        executableHash = 'PPU-changed-executable-hash';
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(memory.writeCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp does not restore a stale draft when write permission returns',
      (tester) async {
        final writableProfile = GameProfileCatalog.find('rc1-collection')!;
        final readOnlyProfile = GameProfile(
          id: writableProfile.id,
          gameName: writableProfile.gameName,
          buildId: writableProfile.buildId,
          executable: writableProfile.executable,
          executableHash: writableProfile.executableHash,
          readStatus: writableProfile.readStatus,
          writeStatus: VerificationStatus.none,
          fields: writableProfile.fields,
        );
        var currentProfile = writableProfile;
        final memory = _FakeMemoryApi(writeSucceeds: true);
        final sdk = _createWritableSdk(memory, profile: () => currentProfile);

        await tester.pumpWidget(_app(sdk: sdk));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'Edit'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          '42',
        );

        currentProfile = readOnlyProfile;
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(find.text('Read-only'), findsOneWidget);

        currentProfile = writableProfile;
        await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('inline-editor-input-bolts')),
          findsNothing,
        );
        expect(memory.writeCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp displays SDK connection errors', (
      tester,
    ) async {
      final sdk = _createSdk(
        () => throw StateError('Process discovery failed.'),
      );

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();

      expect(
        sdk.session.state.errorMessage,
        'Bad state: Process discovery failed.',
      );
      expect(find.text('Bad state: Process discovery failed.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });
  });
}

LudavaSdk _createSdk(List<int> Function() discoverProcessIds) =>
    LudavaSdk.create(
      isWindows: false,
      discoverProcessIds: discoverProcessIds,
      readProcessMetadata: (_) => throw StateError('Not used by these tests.'),
      resolveMemoryBaseCandidate: (_) => null,
      detectGame: (_, _) => throw StateError('Not used by these tests.'),
    );

/// Creates an SDK runtime whose guarded memory operations use [memory].
LudavaSdk _createWritableSdk(
  _FakeMemoryApi memory, {
  List<int> Function()? discoverProcessIds,
  DateTime Function()? processStartedAt,
  int Function()? memoryBase,
  String? Function()? executableHash,
  GameProfile Function()? profile,
}) {
  final initialProfile = GameProfileCatalog.find('rc1-collection')!;
  return LudavaSdk.create(
    api: memory.api,
    isWindows: true,
    pointerSize: 8,
    discoverProcessIds: discoverProcessIds ?? (() => const [321]),
    readProcessMetadata: (_) => Rpcs3ProcessMetadata(
      executablePath: r'C:\Games\rpcs3.exe',
      startedAtUtc: processStartedAt?.call() ?? DateTime.utc(2026),
    ),
    resolveMemoryBaseCandidate: (_) => Rpcs3MemoryBaseCandidate(
      memoryBase: memoryBase?.call() ?? 0x100000,
      logPath: 'test.log',
    ),
    detectGame: (processId, _) {
      final detectedProfile = profile?.call() ?? initialProfile;
      return GameDetectionResult(
        status: GameDetectionStatus.supportedGame,
        processId: processId,
        titleId: detectedProfile.buildId,
        gameTitle: detectedProfile.gameName,
        executable: detectedProfile.executable,
        executableHash:
            executableHash?.call() ?? detectedProfile.executableHash,
        confidence: GameIdentityConfidence.confirmed,
        profile: detectedProfile,
        evidenceDescription: 'Confirmed test profile.',
      );
    },
  );
}

/// Reads and writes one test integer through the SDK's native API seam.
class _FakeMemoryApi {
  /// Whether fake native writes succeed completely.
  final bool writeSucceeds;

  /// Current fake field bytes, represented as a big-endian unsigned integer.
  final List<int> bytes = [0, 0, 0, 17];

  /// Number of fake native write calls.
  int writeCalls = 0;

  /// Creates a fake memory API with the chosen write result.
  _FakeMemoryApi({required this.writeSucceeds});

  /// Exposes native process functions through the SDK's supported adapter.
  WindowsMemoryApi get api => WindowsMemoryApi(
    openProcess: (_, _, _) => ffi.Pointer<ffi.Void>.fromAddress(0x1234),
    readProcessMemory: (handle, address, buffer, byteCount, transferred) {
      for (var index = 0; index < byteCount; index++) {
        buffer[index] = bytes[index];
      }
      transferred.value = byteCount;
      return 1;
    },
    writeProcessMemory: (handle, address, buffer, byteCount, transferred) {
      writeCalls++;
      if (!writeSucceeds) {
        transferred.value = 0;
        return 0;
      }
      bytes
        ..clear()
        ..addAll(buffer.asTypedList(byteCount));
      transferred.value = byteCount;
      return 1;
    },
    closeHandle: (_) => 1,
    getLastError: () => 5,
    getCurrentProcessId: () => 999,
  );
}

/// Creates an app with a window adapter that never calls native code.
LudavaApp _app({
  required LudavaSdk sdk,
  LudavaWindowController? windowController,
  ThemeData? theme,
}) => LudavaApp(
  sdk: sdk,
  windowController:
      windowController ?? LudavaWindowController(currentWindow: () => null),
  theme: theme,
);

/// Returns the numeric input text shown by the active editor.
String _editorText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const ValueKey('inline-editor-input-bolts')))
    .controller!
    .text;

/// Records window controller calls from the app shell tests.
class _RecordingWindowController extends LudavaWindowController {
  /// Creates a recorder without a native window.
  _RecordingWindowController() : super(currentWindow: () => null);

  int configureCalls = 0;
  int minimizeCalls = 0;
  int maximizeCalls = 0;
  int closeCalls = 0;

  /// Records the app startup window configuration request.
  @override
  void configure() => configureCalls++;

  /// Records the app's minimize action.
  @override
  void minimize() => minimizeCalls++;

  /// Records the app's maximize toggle action.
  @override
  void toggleMaximize() => maximizeCalls++;

  /// Records the app's close action.
  @override
  void close() => closeCalls++;
}
