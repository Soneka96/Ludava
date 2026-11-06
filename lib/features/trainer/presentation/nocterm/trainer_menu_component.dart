import 'package:ludava/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava/features/trainer/presentation/nocterm/layout_constants.dart';
import 'package:nocterm/nocterm.dart';

/// Displays profile fields and keyboard actions for an active trainer session.
class TrainerMenuComponent extends StatefulComponent {
  /// Session data used to render the current game and available field values.
  final TrainerSessionState session;

  /// Opens the selected [GameField] editor.
  final void Function(GameField field) onOpenField;

  /// Refreshes all readable values for the current game.
  final void Function() onRefresh;

  /// Re-detects the current RPCS3 game identity.
  final void Function() onRedetect;

  /// Requests that the terminal application exit.
  final void Function() onQuit;

  /// Initial zero-based field selection restored by the owning application.
  final int initialSelection;

  /// Receives selection changes so the owner can restore selection later.
  final void Function(int selection)? onSelectionChanged;

  /// Creates the menu with the current session snapshot and user actions.
  const TrainerMenuComponent({
    required this.session,
    required this.onOpenField,
    required this.onRefresh,
    required this.onRedetect,
    required this.onQuit,
    this.initialSelection = 0,
    this.onSelectionChanged,
    super.key,
  });

  @override
  State<TrainerMenuComponent> createState() => _TrainerMenuState();
}

class _TrainerMenuState extends State<TrainerMenuComponent> {
  int _selectedIndex = 0;

  @override
  void initState() {
    final fields = _readableFields(component.session.profile);
    _selectedIndex =
        fields.isEmpty
            ? 0
            : component.initialSelection.clamp(0, fields.length - 1);
    if (_selectedIndex != component.initialSelection) {
      component.onSelectionChanged?.call(_selectedIndex);
    }
  }

  @override
  void didUpdateComponent(covariant TrainerMenuComponent oldComponent) {
    if (oldComponent.session.profile?.id != component.session.profile?.id) {
      _selectedIndex = 0;
      component.onSelectionChanged?.call(0);
      return;
    }
    final fields = _readableFields(component.session.profile);
    if (_selectedIndex >= fields.length) {
      _selectedIndex = fields.isEmpty ? 0 : fields.length - 1;
      component.onSelectionChanged?.call(_selectedIndex);
    }
  }

  @override
  Component build(BuildContext context) {
    final fields = _readableFields(component.session.profile);
    final selectedIndex =
        fields.isEmpty ? 0 : _selectedIndex.clamp(0, fields.length - 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final requiredHeight =
            NoctermLayoutConstants.fixedMenuRows + fields.length;
        if (constraints.maxWidth < NoctermLayoutConstants.minimumMenuWidth ||
            constraints.maxHeight < requiredHeight) {
          return const Center(
            child: Text(
              'Terminal too small. Enlarge the window to use Ludava.',
              style: TextStyle(color: Colors.yellow),
            ),
          );
        }
        return Focusable(
          focused: true,
          onKeyEvent: _handleKeyEvent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'LUDAVA',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      component.session.selectedProcessId == null
                          ? '● DISCONNECTED'
                          : '● CONNECTED',
                      style: TextStyle(
                        color:
                            component.session.selectedProcessId == null
                                ? Colors.yellow
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(_gameTitle(component.session)),
                const SizedBox(height: 1),
                _separator(),
                ...fields.indexed.map(
                  (entry) => _fieldRow(
                    entry.$1,
                    entry.$2,
                    selected: entry.$1 == selectedIndex,
                    readResult: component.session.readResults[entry.$2.id],
                  ),
                ),
                const SizedBox(height: 1),
                _separator(),
                const Text('↑↓ Navigate   1–9 Select   Enter Open'),
                const Text('R Refresh     G Re-detect  Q Quit'),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    final fields = _readableFields(component.session.profile);
    final key = event.logicalKey;
    if (key == LogicalKey.arrowUp) {
      _moveSelection(-1, fields.length);
      return true;
    }
    if (key == LogicalKey.arrowDown) {
      _moveSelection(1, fields.length);
      return true;
    }
    final digit = _digitFor(key);
    if (digit != null && digit > 0 && digit <= fields.length && digit <= 9) {
      _setSelection(digit - 1);
      return true;
    }
    if (key == LogicalKey.enter && fields.isNotEmpty) {
      component.onOpenField(fields[_selectedIndex.clamp(0, fields.length - 1)]);
      return true;
    }
    if (_matchesLetter(event, 'r', LogicalKey.keyR)) {
      component.onRefresh();
      return true;
    }
    if (_matchesLetter(event, 'g', LogicalKey.keyG)) {
      component.onRedetect();
      return true;
    }
    if (_matchesLetter(event, 'q', LogicalKey.keyQ)) {
      component.onQuit();
      return true;
    }
    return false;
  }

  void _moveSelection(int delta, int fieldCount) {
    if (fieldCount == 0) return;
    _setSelection((_selectedIndex + delta).clamp(0, fieldCount - 1));
  }

  void _setSelection(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    component.onSelectionChanged?.call(index);
  }

  List<GameField> _readableFields(GameProfile? profile) {
    if (profile == null || !profile.canRead) return const [];
    return profile.fields.values.where((field) => field.canRead).toList();
  }

  Component _fieldRow(
    int index,
    GameField field, {
    required bool selected,
    required GameReadResult? readResult,
  }) {
    final value =
        readResult?.succeeded == true
            ? _formatNumber(readResult!.value!)
            : 'Unavailable';
    return Row(
      children: [
        Text(selected ? '❯ ' : '  '),
        Text('${index + 1}. ${field.name}'),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: selected ? Colors.green : null,
            fontWeight: selected ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Component _separator() => Text(
    '─' * NoctermLayoutConstants.separatorWidth,
    style: const TextStyle(color: Colors.blue),
  );

  String _gameTitle(TrainerSessionState session) {
    final profile = session.profile;
    if (profile != null) return '${profile.gameName} · PS3 Collection';
    return session.detection?.gameTitle ?? 'No active game detected';
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(digits[index]);
    }
    return formatted.toString();
  }

  int? _digitFor(LogicalKey key) => switch (key) {
    LogicalKey.digit1 => 1,
    LogicalKey.digit2 => 2,
    LogicalKey.digit3 => 3,
    LogicalKey.digit4 => 4,
    LogicalKey.digit5 => 5,
    LogicalKey.digit6 => 6,
    LogicalKey.digit7 => 7,
    LogicalKey.digit8 => 8,
    LogicalKey.digit9 => 9,
    _ => null,
  };

  bool _matchesLetter(KeyboardEvent event, String letter, LogicalKey key) =>
      event.logicalKey == key || event.character?.toLowerCase() == letter;
}
