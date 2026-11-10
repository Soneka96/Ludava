import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/app/presentation/state/ludava_session_body_view_model.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';

/// Selects connection guidance or trainer fields from the Redux session.
class LudavaSessionBody extends StatelessWidget {
  /// Creates the connected app session body.
  const LudavaSessionBody({super.key});

  /// Renders connection guidance or SDK-driven trainer fields.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, LudavaSessionBodyViewModel>(
        distinct: true,
        converter: (store) => sl<LudavaSessionBodyViewModel>(param1: store),
        builder: (context, viewModel) {
          if (!viewModel.isReady) {
            return SessionConnectionBody(
              processIds: viewModel.processIds,
              selectedProcessId: viewModel.selectedProcessId,
              detection: viewModel.detection,
              hasMemoryBase: viewModel.hasMemoryBase,
              errorMessage: viewModel.errorMessage,
              onSelectProcess: viewModel.onSelectProcess,
            );
          }

          final errorMessage = viewModel.errorMessage;
          final theme = Theme.of(context);
          return Column(
            children: [
              SizedBox(
                key: const ValueKey('session-feedback-region'),
                height: LudavaDimensions.sessionFeedbackHeight,
                child: errorMessage == null
                    ? null
                    : Tooltip(
                        message: errorMessage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LudavaSpacing.lg,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              errorMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const Expanded(child: TrainerFieldsPanel()),
            ],
          );
        },
      );
}
