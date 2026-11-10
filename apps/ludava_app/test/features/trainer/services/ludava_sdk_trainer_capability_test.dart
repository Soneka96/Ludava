import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/services/ludava_sdk_trainer_capability.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Property state behaves correctly', () {
    test('Property state returns the SDK-owned current snapshot', () async {
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => const [],
      );
      final capability = LudavaSdkTrainerCapability(sdk);
      final initialState = capability.state;

      expect(capability.state, same(initialState));
      await capability.dispose();
    });
  });

  group('Property stateChanges behaves correctly', () {
    test(
      'Property stateChanges emits the initial and connected snapshots',
      () async {
        final sdk = LudavaSdk.create(
          isWindows: false,
          discoverProcessIds: () => const [],
        );
        final capability = LudavaSdkTrainerCapability(sdk);
        final initialState = capability.state;
        final snapshots = <TrainerSessionState>[];
        final firstSnapshot = Completer<void>();
        final subscription = capability.stateChanges.listen((snapshot) {
          snapshots.add(snapshot);
          if (!firstSnapshot.isCompleted) firstSnapshot.complete();
        });

        await firstSnapshot.future;
        capability.connect();
        await Future<void>.delayed(Duration.zero);

        expect(snapshots.first, same(initialState));
        expect(snapshots.length, 2);
        expect(snapshots.last, same(capability.state));
        expect(snapshots.last.processIds, isEmpty);
        await subscription.cancel();
        await capability.dispose();
      },
    );
  });

  group('Method selectProcess() behaves correctly', () {
    test(
      'Method selectProcess() forwards an unavailable process rejection',
      () async {
        final capability = LudavaSdkTrainerCapability(
          LudavaSdk.create(
            isWindows: false,
            discoverProcessIds: () => const [],
          ),
        );

        expect(capability.selectProcess(42), isFalse);
        await capability.dispose();
      },
    );
  });
}
