import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/state/app.actions.dart';

void main() {
  group('Class InitializeAppAction construction', () {
    test('Class InitializeAppAction creates an initialization request', () {
      expect(const InitializeAppAction(), isA<InitializeAppAction>());
    });
  });

  group('Method addCleanup() behaves correctly', () {
    test(
      'Method addCleanup() waits for every cleanup and reports all errors',
      () async {
        final first = Completer<void>();
        final second = Completer<void>();
        final action = ShutdownRequestedAction()
          ..addCleanup(first.future)
          ..addCleanup(second.future);
        var finished = false;
        final wait = action.waitForCleanup().whenComplete(
          () => finished = true,
        );

        first.completeError(StateError('first cleanup failed'));
        await Future<void>.delayed(Duration.zero);
        expect(finished, isFalse);
        second.completeError(StateError('second cleanup failed'));

        await expectLater(
          wait,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('first cleanup failed'),
                contains('second cleanup failed'),
              ),
            ),
          ),
        );
        expect(finished, isTrue);
      },
    );
  });

  group('Method waitForCleanup() behaves correctly', () {
    test('Method waitForCleanup() completes when cleanup succeeds', () async {
      final action = ShutdownRequestedAction()
        ..addCleanup(Future<void>.value());

      await expectLater(action.waitForCleanup(), completes);
    });
  });
}
