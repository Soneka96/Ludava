import 'package:ludava/features/game_memory/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Property usage behaves correctly', () {
    test('Property usage reports live RC2 evidence and its limits', () {
      expect(
        DiagnosticArgumentParser.usage,
        contains('The owner tested RC2 bolt reading and writing'),
      );
      expect(
        DiagnosticArgumentParser.usage,
        contains('Compatibility across RPCS3 versions and game builds'),
      );
      expect(
        DiagnosticArgumentParser.usage,
        isNot(contains('remain unverified against a live')),
      );
    });
  });

  group('Method parse() behaves correctly', () {
    test(
      'Method parse() returns read arguments when all options are valid',
      () {
        final arguments = DiagnosticArgumentParser.parse([
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ]);

        expect(arguments.action, GameMemoryAction.read);
        expect(arguments.gameId, 'rc2-collection');
        expect(arguments.fieldId, 'bolts');
        expect(arguments.processId, 42);
        expect(arguments.memoryBase, 0x300000000);
        expect(arguments.value, isNull);
        expect(arguments.confirmed, isFalse);
      },
    );

    test('Method parse() returns explicitly confirmed write arguments', () {
      final arguments = DiagnosticArgumentParser.parse([
        'write',
        '--memory-base',
        '0x300000000',
        '--pid',
        '42',
        '--field',
        'bolts',
        '--game',
        'rc2-collection',
        '--value',
        '55',
        '--confirm-write',
      ]);

      expect(arguments.action, GameMemoryAction.write);
      expect(arguments.value, 55);
      expect(arguments.confirmed, isTrue);
    });

    test('Method parse() rejects missing, duplicate, and unknown options', () {
      for (final arguments in <List<String>>[
        [],
        ['read'],
        [
          'read',
          '--game',
          'rc2-collection',
          '--game',
          'other',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ],
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
          '--other',
          '1',
        ],
      ]) {
        expect(
          () => DiagnosticArgumentParser.parse(arguments),
          throwsFormatException,
          reason: '$arguments should be rejected',
        );
      }
    });

    test('Method parse() rejects repeated write options', () {
      for (final writeOptions in [
        ['--value', '4', '--value', '5', '--confirm-write'],
        ['--value', '4', '--confirm-write', '--confirm-write'],
      ]) {
        expect(
          () => DiagnosticArgumentParser.parse([
            'write',
            '--game',
            'rc2-collection',
            '--field',
            'bolts',
            '--pid',
            '42',
            '--memory-base',
            '0x1',
            ...writeOptions,
          ]),
          throwsFormatException,
        );
      }
    });

    test('Method parse() rejects empty game and field identifiers', () {
      final validOptions = [
        '--game',
        'rc2-collection',
        '--field',
        'bolts',
        '--pid',
        '42',
        '--memory-base',
        '0x1',
      ];

      for (final invalidOptions in [
        ['--game', ' '],
        ['--field', ''],
      ]) {
        final option = invalidOptions.first;
        final options = List<String>.from(validOptions);
        final optionIndex = options.indexOf(option);
        options[optionIndex + 1] = invalidOptions.last;

        expect(
          () => DiagnosticArgumentParser.parse(['read', ...options]),
          throwsFormatException,
        );
      }
    });

    test('Method parse() rejects malformed pid base and values', () {
      final common = ['read', '--game', 'rc2-collection', '--field', 'bolts'];
      for (final options in [
        ['--pid', '0', '--memory-base', '0x1'],
        ['--pid', '4294967296', '--memory-base', '0x1'],
        ['--pid', '42', '--memory-base', '300000000'],
        ['--pid', '42', '--memory-base', '0x8000000000000000'],
      ]) {
        expect(
          () => DiagnosticArgumentParser.parse([...common, ...options]),
          throwsFormatException,
        );
      }
      expect(
        () => DiagnosticArgumentParser.parse([
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
          '--value',
          'not-an-integer',
          '--confirm-write',
        ]),
        throwsFormatException,
      );
    });

    test(
      'Method parse() requires confirmation for writes and forbids it for reads',
      () {
        expect(
          () => DiagnosticArgumentParser.parse([
            'write',
            '--game',
            'rc2-collection',
            '--field',
            'bolts',
            '--pid',
            '42',
            '--memory-base',
            '0x1',
            '--value',
            '1',
          ]),
          throwsFormatException,
        );
        expect(
          () => DiagnosticArgumentParser.parse([
            'read',
            '--game',
            'rc2-collection',
            '--field',
            'bolts',
            '--pid',
            '42',
            '--memory-base',
            '0x1',
            '--confirm-write',
          ]),
          throwsFormatException,
        );
      },
    );

    test('Method parse() throws when a confirmed write has no value', () {
      expect(
        () => DiagnosticArgumentParser.parse([
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
          '--confirm-write',
        ]),
        throwsFormatException,
      );
    });

    test('Method parse() throws when a read command includes a value', () {
      expect(
        () => DiagnosticArgumentParser.parse([
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
          '--value',
          '42',
        ]),
        throwsFormatException,
      );
    });
  });

  group('Method parseMemoryBase() behaves correctly', () {
    test('Method parseMemoryBase() returns a 64-bit hexadecimal base', () {
      expect(
        DiagnosticArgumentParser.parseMemoryBase('0x300000000'),
        0x300000000,
      );
      expect(DiagnosticArgumentParser.parseMemoryBase('0X1'), 1);
    });

    test(
      'Method parseMemoryBase() rejects malformed and overflowing bases',
      () {
        for (final value in ['300000000', '0x', '0x-1', '0x8000000000000000']) {
          expect(
            () => DiagnosticArgumentParser.parseMemoryBase(value),
            throwsFormatException,
          );
        }
      },
    );
  });
}
