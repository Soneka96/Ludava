import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/trainer/presentation/nocterm/trainer_menu_component.dart';
import 'package:nocterm/nocterm.dart'
    show BuildContext, Component, Size, State, StatefulComponent;
import 'package:nocterm/nocterm_test.dart'
    show LogicalKey, containsText, testNocterm;
import 'package:test/test.dart';

TrainerMenuComponent _menu(
  TrainerSessionState session, {
  void Function(GameField field)? onOpenField,
  void Function()? onRefresh,
  void Function()? onRedetect,
  void Function()? onQuit,
  void Function(int selection)? onSelectionChanged,
  int initialSelection = 0,
}) => TrainerMenuComponent(
  session: session,
  onOpenField: onOpenField ?? (_) {},
  onRefresh: onRefresh ?? () {},
  onRedetect: onRedetect ?? () {},
  onQuit: onQuit ?? () {},
  initialSelection: initialSelection,
  onSelectionChanged: onSelectionChanged,
);

TrainerSessionState _session({
  GameProfile? profile,
  Map<String, GameReadResult> reads = const {
    'credits': GameReadResult(
      status: GameReadStatus.success,
      fieldId: 'credits',
      value: 244866,
    ),
    'weapons': GameReadResult(
      status: GameReadStatus.success,
      fieldId: 'weapons',
      value: 7,
    ),
  },
}) {
  final selectedProfile = profile ?? _profile();
  return TrainerSessionState(
    processIds: const [42],
    selectedProcessId: 42,
    processMetadata: Rpcs3ProcessMetadata(
      executablePath: r'C:\RPCS3\rpcs3.exe',
      startedAtUtc: DateTime.utc(2026),
    ),
    memoryBase: 0x300000000,
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: 42,
      gameTitle: selectedProfile.gameName,
      confidence: GameIdentityConfidence.confirmed,
      profile: selectedProfile,
      evidenceDescription: 'Synthetic menu fixture.',
    ),
    readResults: reads,
  );
}

GameProfile _profile({
  String id = 'synthetic-profile',
  bool profileReadable = true,
  bool readableFields = true,
  bool includeWeapons = true,
  bool includeFields = true,
}) => GameProfile(
  id: id,
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
  readStatus:
      profileReadable ? VerificationStatus.verified : VerificationStatus.none,
  writeStatus: VerificationStatus.researchConfirmed,
  fields: {
    if (includeFields)
      'credits': GameField(
        id: 'credits',
        name: 'Credits',
        guestOffset: 0x1000,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus:
            readableFields
                ? VerificationStatus.verified
                : VerificationStatus.none,
        writeStatus: VerificationStatus.researchConfirmed,
        minimumValue: 0,
        maximumValue: 0xffffffff,
      ),
    if (includeFields && includeWeapons)
      'weapons': GameField(
        id: 'weapons',
        name: 'Weapons',
        guestOffset: 0x2000,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus:
            readableFields
                ? VerificationStatus.verified
                : VerificationStatus.none,
        writeStatus: VerificationStatus.researchConfirmed,
        minimumValue: 0,
        maximumValue: 0xffffffff,
      ),
    if (includeFields)
      'secret': GameField(
        id: 'secret',
        name: 'Secret',
        guestOffset: 0x3000,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.none,
      ),
  },
);

class _MenuHost extends StatefulComponent {
  const _MenuHost({
    required this.session,
    required this.onSelectionChanged,
    required this.onOpenField,
  });

  final TrainerSessionState session;
  final void Function(int selection) onSelectionChanged;
  final void Function(GameField field) onOpenField;

  @override
  State<_MenuHost> createState() => _MenuHostState();
}

class _MenuHostState extends State<_MenuHost> {
  late TrainerSessionState _session = component.session;

  void updateSession(TrainerSessionState session) {
    setState(() => _session = session);
  }

  @override
  Component build(BuildContext context) => _menu(
    _session,
    onSelectionChanged: component.onSelectionChanged,
    onOpenField: component.onOpenField,
  );
}

void main() {
  group('Class TrainerMenuComponent keyboard behavior', () {
    test(
      'Class TrainerMenuComponent renders the game and readable values',
      () async {
        await testNocterm('profile-driven menu', (tester) async {
          await tester.pumpComponent(_menu(_session()));
          final screen = tester.terminalState;

          expect(screen, containsText('LUDAVA'));
          expect(screen, containsText('CONNECTED'));
          expect(screen, containsText('Synthetic game · PS3 SYNTHETIC'));
          expect(screen, containsText('Credits'));
          expect(screen, containsText('1. Credits'));
          expect(screen, containsText('Weapons'));
          expect(screen, containsText('2. Weapons'));
          expect(screen, isNot(containsText('Secret')));
        });
      },
    );

    test(
      'Class TrainerMenuComponent displays dynamic fields and opens the selected row',
      () async {
        await testNocterm('synthetic multi-field profile', (tester) async {
          final openedFields = <GameField>[];
          await tester.pumpComponent(
            _menu(
              _session(
                profile: _profile(),
                reads: {
                  'credits': const GameReadResult(
                    status: GameReadStatus.success,
                    fieldId: 'credits',
                    value: 3793,
                  ),
                  'weapons': const GameReadResult(
                    status: GameReadStatus.success,
                    fieldId: 'weapons',
                    value: 215,
                  ),
                },
              ),
              onOpenField: openedFields.add,
            ),
          );

          expect(tester.terminalState, containsText('1. Credits'));
          expect(tester.terminalState, containsText('2. Weapons'));
          await tester.sendArrowDown();
          await tester.sendEnter();

          expect(openedFields.map((field) => field.id), ['weapons']);
        });
      },
    );

    test(
      'Class TrainerMenuComponent changes edit behavior by field write status',
      () async {
        await testNocterm('mixed field write status', (tester) async {
          final openedFields = <GameField>[];
          final profile = GameProfile(
            id: 'mixed-test',
            gameName: 'Mixed test game',
            buildId: 'MIXED',
            executable: 'mixed.self',
            readStatus: VerificationStatus.verified,
            writeStatus: VerificationStatus.researchConfirmed,
            fields: {
              'credits': GameField(
                id: 'credits',
                name: 'Credits',
                guestOffset: 0x1000,
                valueType: MemoryValueType.unsigned32,
                byteOrder: ByteOrder.big,
                readStatus: VerificationStatus.verified,
              ),
              'weapons': GameField(
                id: 'weapons',
                name: 'Weapons',
                guestOffset: 0x2000,
                valueType: MemoryValueType.unsigned32,
                byteOrder: ByteOrder.big,
                readStatus: VerificationStatus.verified,
                writeStatus: VerificationStatus.researchConfirmed,
                minimumValue: 0,
                maximumValue: 100,
              ),
            },
          );

          await tester.pumpComponent(
            _menu(_session(profile: profile), onOpenField: openedFields.add),
          );

          expect(
            tester.terminalState,
            containsText('Selected field is read-only'),
          );
          await tester.sendEnter();
          await tester.sendKey(LogicalKey.digit1);
          expect(openedFields, isEmpty);

          await tester.sendArrowDown();
          expect(tester.terminalState, containsText('1–9 Edit'));
          await tester.sendEnter();
          expect(openedFields.map((field) => field.id), ['weapons']);

          await tester.sendKey(LogicalKey.digit1);
          expect(openedFields.map((field) => field.id), ['weapons']);
        });
      },
    );

    test(
      'Class TrainerMenuComponent moves selection with arrow keys',
      () async {
        await testNocterm('arrow navigation', (tester) async {
          final selections = <int>[];
          await tester.pumpComponent(
            _menu(_session(), onSelectionChanged: selections.add),
          );

          await tester.sendArrowDown();

          expect(selections, [1]);
        });
      },
    );

    test(
      'Class TrainerMenuComponent keeps arrow selection within field bounds',
      () async {
        await testNocterm('arrow selection boundaries', (tester) async {
          final selections = <int>[];
          GameField? openedField;
          await tester.pumpComponent(
            _menu(
              _session(),
              onSelectionChanged: selections.add,
              onOpenField: (field) => openedField = field,
            ),
          );

          await tester.sendArrowUp();
          expect(selections, isEmpty);
          await tester.sendArrowDown();
          await tester.sendArrowDown();
          expect(selections, [1]);
          await tester.sendEnter();

          expect(openedField?.id, 'weapons');
        });
      },
    );

    test(
      'Class TrainerMenuComponent opens the requested field directly by number',
      () async {
        await testNocterm('direct number shortcut', (tester) async {
          GameField? openedField;
          final selections = <int>[];
          await tester.pumpComponent(
            _menu(
              _session(),
              onOpenField: (field) => openedField = field,
              onSelectionChanged: selections.add,
            ),
          );

          await tester.sendKey(LogicalKey.digit2);

          expect(openedField?.id, 'weapons');
          expect(selections, [1]);
        });
      },
    );

    test(
      'Class TrainerMenuComponent ignores number shortcuts outside the readable field range',
      () async {
        await testNocterm('number shortcut bounds', (tester) async {
          GameField? openedField;
          final selections = <int>[];
          await tester.pumpComponent(
            _menu(
              _session(),
              onOpenField: (field) => openedField = field,
              onSelectionChanged: selections.add,
            ),
          );

          await tester.sendKey(LogicalKey.digit3);

          expect(openedField, isNull);
          expect(selections, isEmpty);
        });
      },
    );

    test(
      'Class TrainerMenuComponent preserves selection after session updates',
      () async {
        await testNocterm('preserve selection across editor return', (
          tester,
        ) async {
          GameField? openedField;
          final selections = <int>[];
          final initial = _menu(
            _session(),
            onOpenField: (field) => openedField = field,
            onSelectionChanged: selections.add,
          );
          await tester.pumpComponent(initial);
          await tester.sendArrowDown();
          await tester.pumpComponent(
            _menu(
              _session(
                reads: {
                  'credits': const GameReadResult(
                    status: GameReadStatus.success,
                    fieldId: 'credits',
                    value: 244866,
                  ),
                  'weapons': const GameReadResult(
                    status: GameReadStatus.success,
                    fieldId: 'weapons',
                    value: 8,
                  ),
                },
              ),
              onOpenField: (field) => openedField = field,
              initialSelection: selections.single,
            ),
          );
          await tester.sendEnter();

          expect(openedField?.id, 'weapons');
        });
      },
    );

    test(
      'Class TrainerMenuComponent clamps selection when fields shrink or disappear',
      () async {
        await testNocterm('field list changes', (tester) async {
          final selections = <int>[];
          final openedFields = <GameField>[];
          await tester.pumpComponent(
            _MenuHost(
              session: _session(),
              onSelectionChanged: selections.add,
              onOpenField: openedFields.add,
            ),
          );
          await tester.sendArrowDown();
          expect(selections, [1]);

          tester.findState<_MenuHostState>().updateSession(
            _session(profile: _profile(includeWeapons: false)),
          );
          await tester.pump();
          expect(selections.last, 0);
          await tester.sendEnter();
          expect(openedFields.last.id, 'credits');

          tester.findState<_MenuHostState>().updateSession(
            _session(profile: _profile(includeFields: false)),
          );
          await tester.pump();
          expect(selections.last, 0);
          await tester.sendEnter();

          expect(openedFields, hasLength(1));
        });
      },
    );

    test(
      'Class TrainerMenuComponent resets selection after changing games',
      () async {
        await testNocterm('reset selection for new game', (tester) async {
          GameField? openedField;
          await tester.pumpComponent(
            _menu(_session(), onOpenField: (field) => openedField = field),
          );
          await tester.sendArrowDown();
          await tester.pumpComponent(
            _menu(
              _session(profile: _profile(id: 'synthetic-profile-next')),
              onOpenField: (field) => openedField = field,
            ),
          );
          await tester.sendEnter();

          expect(openedField?.id, 'credits');
        });
      },
    );

    test(
      'Class TrainerMenuComponent clamps restored selections to available fields',
      () async {
        await testNocterm('restored selection bounds', (tester) async {
          final selections = <int>[];
          GameField? openedField;
          await tester.pumpComponent(
            _menu(
              _session(),
              initialSelection: -1,
              onSelectionChanged: selections.add,
              onOpenField: (field) => openedField = field,
            ),
          );
          expect(selections, [0]);
          await tester.sendEnter();
          expect(openedField?.id, 'credits');

          await tester.pumpComponent(
            _menu(
              _session(),
              initialSelection: 99,
              onSelectionChanged: selections.add,
              onOpenField: (field) => openedField = field,
            ),
          );
          expect(selections.last, 1);
          await tester.sendEnter();

          expect(openedField?.id, 'weapons');
        });
      },
    );

    test(
      'Class TrainerMenuComponent handles refresh, re-detect, and quit keys',
      () async {
        await testNocterm('menu actions', (tester) async {
          var refreshCount = 0;
          var redetectCount = 0;
          var quitCount = 0;
          await tester.pumpComponent(
            _menu(
              _session(),
              onRefresh: () => refreshCount++,
              onRedetect: () => redetectCount++,
              onQuit: () => quitCount++,
            ),
          );

          await tester.sendKey(LogicalKey.keyR);
          await tester.sendKey(LogicalKey.keyG);
          await tester.sendKey(LogicalKey.keyQ);

          expect(refreshCount, 1);
          expect(redetectCount, 1);
          expect(quitCount, 1);
        });
      },
    );

    test(
      'Class TrainerMenuComponent handles uppercase character shortcuts',
      () async {
        await testNocterm('character shortcuts', (tester) async {
          var refreshCount = 0;
          var redetectCount = 0;
          var quitCount = 0;
          await tester.pumpComponent(
            _menu(
              _session(),
              onRefresh: () => refreshCount++,
              onRedetect: () => redetectCount++,
              onQuit: () => quitCount++,
            ),
          );

          await tester.enterText('RGQ');

          expect(refreshCount, 1);
          expect(redetectCount, 1);
          expect(quitCount, 1);
        });
      },
    );

    test(
      'Class TrainerMenuComponent omits fields from unreadable profiles',
      () async {
        await testNocterm('unreadable profile', (tester) async {
          await tester.pumpComponent(
            _menu(_session(profile: _profile(profileReadable: false))),
          );

          expect(tester.terminalState, isNot(containsText('Credits')));
          expect(
            tester.terminalState,
            containsText('Synthetic game · PS3 SYNTHETIC'),
          );
        });
      },
    );

    test(
      'Class TrainerMenuComponent ignores navigation when no fields are readable',
      () async {
        await testNocterm('no readable fields', (tester) async {
          final openedFields = <GameField>[];
          final selections = <int>[];
          await tester.pumpComponent(
            _menu(
              _session(profile: _profile(readableFields: false)),
              onOpenField: openedFields.add,
              onSelectionChanged: selections.add,
            ),
          );

          await tester.sendArrowUp();
          await tester.sendArrowDown();
          await tester.sendKey(LogicalKey.digit1);
          await tester.sendEnter();

          expect(openedFields, isEmpty);
          expect(selections, isEmpty);
          expect(tester.terminalState, isNot(containsText('Credits')));
        });
      },
    );

    test(
      'Class TrainerMenuComponent does not open a field when no profile is selected',
      () async {
        await testNocterm('no selected profile', (tester) async {
          final openedFields = <GameField>[];
          await tester.pumpComponent(
            _menu(TrainerSessionState(), onOpenField: openedFields.add),
          );

          await tester.sendKey(LogicalKey.digit1);
          await tester.sendEnter();

          expect(openedFields, isEmpty);
          expect(tester.terminalState, containsText('No readable fields'));
        });
      },
    );

    test(
      'Class TrainerMenuComponent shows a helpful message when too small',
      () async {
        await testNocterm('small terminal message', (tester) async {
          await tester.pumpComponent(_menu(_session()));

          expect(
            tester.terminalState,
            containsText('Terminal too small. Enlarge'),
          );
          expect(
            tester.terminalState,
            containsText('the window to use Ludava.'),
          );
        }, size: const Size(30, 5));
      },
    );

    test(
      'Class TrainerMenuComponent handles a narrow terminal independently',
      () async {
        await testNocterm('narrow terminal', (tester) async {
          await tester.pumpComponent(_menu(_session()));

          expect(tester.terminalState, containsText('Terminal too small'));
        }, size: const Size(30, 24));
      },
    );

    test(
      'Class TrainerMenuComponent handles a short terminal independently',
      () async {
        await testNocterm('short terminal', (tester) async {
          await tester.pumpComponent(_menu(_session()));

          expect(tester.terminalState, containsText('Terminal too small'));
        }, size: const Size(80, 5));
      },
    );

    test(
      'Class TrainerMenuComponent renders at exact minimum terminal dimensions',
      () async {
        await testNocterm('minimum terminal dimensions', (tester) async {
          await tester.pumpComponent(_menu(_session()));

          expect(tester.terminalState, containsText('LUDAVA'));
          expect(
            tester.terminalState,
            isNot(containsText('Terminal too small')),
          );
        }, size: const Size(48, 13));
      },
    );
  });
}
