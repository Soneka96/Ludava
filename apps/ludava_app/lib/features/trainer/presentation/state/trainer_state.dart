import 'package:equatable/equatable.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Holds the authoritative SDK snapshot and the active field edit ID.
class TrainerState extends Equatable {
  /// Latest session snapshot published by the SDK.
  final TrainerSessionState session;

  /// ID of the field being edited, or `null` when no edit is active.
  final String? editingFieldId;

  /// State values used by Equatable while retaining SDK snapshot identity.
  @override
  List<Object?> get props => [session, editingFieldId];

  /// Creates trainer state from the initial SDK [session] snapshot.
  const TrainerState({required this.session, this.editingFieldId});

  /// Returns state with [session] and the requested [editingFieldId].
  TrainerState copyWith({
    TrainerSessionState? session,
    String? editingFieldId,
    bool clearEditingField = false,
  }) => TrainerState(
    session: session ?? this.session,
    editingFieldId: clearEditingField
        ? null
        : editingFieldId ?? this.editingFieldId,
  );
}
