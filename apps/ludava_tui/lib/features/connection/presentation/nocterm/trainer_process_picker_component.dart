import 'package:ludava_tui/shared/constants/layout_constants.dart';
import 'package:nocterm/nocterm.dart';

/// Presents RPCS3 processes and routes the user's selection.
class TrainerProcessPickerComponent extends StatefulComponent {
  /// Process identifiers available for selection.
  final List<int> processIds;

  /// Selects the requested RPCS3 process.
  final void Function(int processId) onSelectProcess;

  /// Retries process discovery when requested.
  final void Function() onRefresh;

  /// Re-detects the active game when requested.
  final void Function() onRedetect;

  /// Requests safe terminal shutdown.
  final void Function() onQuit;

  /// Creates a picker for [processIds].
  const TrainerProcessPickerComponent({
    required this.processIds,
    required this.onSelectProcess,
    required this.onRefresh,
    required this.onRedetect,
    required this.onQuit,
    super.key,
  });

  /// Creates the state that owns the active process-row selection.
  @override
  State<TrainerProcessPickerComponent> createState() =>
      _TrainerProcessPickerState();
}

class _TrainerProcessPickerState extends State<TrainerProcessPickerComponent> {
  int _selectedIndex = 0;

  /// Preserves the selected process across reordering and resets if it exits.
  @override
  void didUpdateComponent(
    covariant TrainerProcessPickerComponent oldComponent,
  ) {
    final previousSelection =
        _selectedIndex < oldComponent.processIds.length
            ? oldComponent.processIds[_selectedIndex]
            : null;
    if (previousSelection != null) {
      final updatedIndex = component.processIds.indexOf(previousSelection);
      if (updatedIndex >= 0) {
        _selectedIndex = updatedIndex;
        return;
      }
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= component.processIds.length) {
      _selectedIndex =
          component.processIds.isEmpty ? 0 : component.processIds.length - 1;
    }
  }

  /// Renders process choices and their keyboard hints.
  @override
  Component build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final processIds = component.processIds;
      final requiredHeight =
          NoctermLayoutConstants.fixedMenuRows + processIds.length;
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
              const Text(
                'LUDAVA',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              const Text('Select an RPCS3 process'),
              const SizedBox(height: 1),
              ...processIds.indexed.map(
                (entry) => Text(
                  '${entry.$1 == _selectedIndex ? '❯' : ' '} '
                  '${entry.$1 + 1}. PID ${entry.$2}',
                  style: TextStyle(
                    color: entry.$1 == _selectedIndex ? Colors.green : null,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              const Text('↑↓ Navigate   1–9 Select   Enter Select'),
              const Text('R Refresh     G Re-detect  Q Quit'),
            ],
          ),
        ),
      );
    },
  );

  /// Handles process navigation, selection, refresh, and quit actions.
  bool _handleKeyEvent(KeyboardEvent event) {
    final processIds = component.processIds;
    if (event.logicalKey == LogicalKey.arrowUp) {
      _moveSelection(-1, processIds.length);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowDown) {
      _moveSelection(1, processIds.length);
      return true;
    }
    final digit = _digitFor(event.logicalKey);
    if (digit != null && digit <= processIds.length) {
      component.onSelectProcess(processIds[digit - 1]);
      return true;
    }
    if (event.logicalKey == LogicalKey.enter && processIds.isNotEmpty) {
      component.onSelectProcess(processIds[_selectedIndex]);
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

  /// Moves the selected process row by [delta] within [processCount].
  void _moveSelection(int delta, int processCount) {
    if (processCount == 0) return;
    setState(
      () =>
          _selectedIndex = (_selectedIndex + delta).clamp(0, processCount - 1),
    );
  }

  /// Maps a number row key to its one-based process index.
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

  /// Recognizes a letter shortcut from its key or typed character.
  bool _matchesLetter(KeyboardEvent event, String letter, LogicalKey key) =>
      event.logicalKey == key || event.character?.toLowerCase() == letter;
}
