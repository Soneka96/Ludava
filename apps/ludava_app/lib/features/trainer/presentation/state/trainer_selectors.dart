import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Selects pure trainer presentation values from Redux state.
abstract final class TrainerSelectors {
  /// Returns fields from the current SDK profile in profile order.
  static List<GameField> fields(AppState state) =>
      state.trainer.session.profile?.fields.values.toList(growable: false) ??
      const <GameField>[];

  /// Returns whether the current SDK snapshot allows [field] to be edited.
  static bool canEdit(AppState state, GameField field) =>
      TrainerWriteEligibility.isWriteEligible(state.trainer.session, field);

  /// Returns the field currently being edited, if it still exists.
  static GameField? editingField(AppState state) {
    final fieldId = state.trainer.editingFieldId;
    return fieldId == null
        ? null
        : state.trainer.session.profile?.findField(fieldId);
  }
}
