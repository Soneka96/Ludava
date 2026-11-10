import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

class _MockTrainerFieldsViewModel extends Mock
    implements TrainerFieldsViewModel {}

({
  GameField field,
  GameReadResult? readResult,
  GameWriteResult? writeResult,
  bool canRead,
  bool canWrite,
  bool isEditing,
})
_row(
  String id, {
  String? name,
  GameReadResult? readResult,
  GameWriteResult? writeResult,
  bool canRead = true,
  bool canWrite = true,
  bool isEditing = false,
}) => (
  field: GameField(
    id: id,
    name: name ?? id,
    guestOffset: 0x100,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.little,
    readStatus: VerificationStatus.verified,
    writeStatus: VerificationStatus.researchConfirmed,
    minimumValue: 0,
    maximumValue: 100000,
  ),
  readResult: readResult,
  writeResult: writeResult,
  canRead: canRead,
  canWrite: canWrite,
  isEditing: isEditing,
);

_MockTrainerFieldsViewModel _viewModel({
  List<
        ({
          GameField field,
          GameReadResult? readResult,
          GameWriteResult? writeResult,
          bool canRead,
          bool canWrite,
          bool isEditing,
        })
      >
      fields =
      const [],
  bool hasProfile = true,
  ValueChanged<String>? onEditField,
  GameWriteResult Function(String fieldId, int value)? onApplyField,
  VoidCallback? onCancelEditing,
}) {
  final viewModel = _MockTrainerFieldsViewModel();
  when(() => viewModel.fields).thenReturn(fields);
  when(() => viewModel.hasProfile).thenReturn(hasProfile);
  when(() => viewModel.onEditField).thenReturn(onEditField ?? (_) {});
  when(() => viewModel.onApplyField).thenReturn(
    onApplyField ??
        (_, value) => GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: value,
          readBackValue: value,
        ),
  );
  when(() => viewModel.onCancelEditing).thenReturn(onCancelEditing ?? () {});
  when(() => viewModel.props).thenReturn([fields, hasProfile, Object()]);
  return viewModel;
}

Widget _wrap(Store<AppState> store, {Key? key}) => StoreProvider<AppState>(
  key: key,
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: TrainerFieldsPanel()),
  ),
);

void main() {
  late Store<AppState> store;
  late _MockTrainerFieldsViewModel viewModel;

  setUp(() {
    sl.pushNewScope();
    store = Store<AppState>(
      (state, action) => state,
      initialState: AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      ),
    );
    sl.registerFactoryParam<TrainerFieldsViewModel, Store<AppState>, void>(
      (store, _) => viewModel,
    );
  });

  tearDown(() async => sl.popScope());

  group('Class TrainerFieldsPanel presentation behavior', () {
    testWidgets('Class TrainerFieldsPanel renders dynamic field rows', (
      tester,
    ) async {
      viewModel = _viewModel(
        fields: [
          _row(
            'credits',
            name: 'Credits',
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 0,
            ),
          ),
          _row('scrap', name: 'Scrap'),
        ],
      );

      await tester.pumpWidget(_wrap(store));

      final creditsRow = find.byKey(const ValueKey('credits'));
      final scrapRow = find.byKey(const ValueKey('scrap'));
      expect(find.byType(ListView), findsOneWidget);
      expect(creditsRow, findsOneWidget);
      expect(scrapRow, findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(
        tester.getTopLeft(scrapRow).dy,
        greaterThan(tester.getTopLeft(creditsRow).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class TrainerFieldsPanel scrolls all dynamic fields', (
      tester,
    ) async {
      viewModel = _viewModel(
        fields: List.generate(
          12,
          (index) => _row('part-$index', name: 'Part $index'),
        ),
      );
      tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(store));
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      final lastField = find.byKey(const ValueKey('part-11'));
      expect(lastField, findsOneWidget);
      await tester.ensureVisible(lastField);
      await tester.pumpAndSettle();
      expect(tester.getRect(lastField).bottom, lessThanOrEqualTo(340));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class TrainerFieldsPanel preserves row geometry while editing',
      (tester) async {
        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          final rows = [_row('credits'), _row('scrap')];
          viewModel = _viewModel(fields: rows);
          await tester.pumpWidget(_wrap(store, key: ValueKey('normal-$size')));

          final row = find.byKey(const ValueKey('credits'));
          final siblingRow = find.byKey(const ValueKey('scrap'));
          final normalRow = tester.getRect(row);
          final normalSiblingRow = tester.getRect(siblingRow);
          expect(normalRow.height, LudavaDimensions.minimumInteractiveTarget);
          expect(
            normalSiblingRow.height,
            LudavaDimensions.minimumInteractiveTarget,
          );

          viewModel = _viewModel(
            fields: [_row('credits', isEditing: true), _row('scrap')],
          );
          await tester.pumpWidget(_wrap(store, key: ValueKey('editing-$size')));

          expect(find.byType(InlineValueEditor), findsOneWidget);
          expect(tester.getRect(row), normalRow);
          expect(tester.getRect(siblingRow), normalSiblingRow);
          expect(tester.takeException(), isNull);
        }
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );

    testWidgets(
      'Class TrainerFieldsPanel closes editing when eligibility is removed',
      (tester) async {
        viewModel = _viewModel(fields: [_row('credits', isEditing: true)]);
        await tester.pumpWidget(_wrap(store));

        expect(find.byType(InlineValueEditor), findsOneWidget);

        viewModel = _viewModel(fields: [_row('credits', canWrite: false)]);
        final updatedStore = Store<AppState>(
          (state, action) => state,
          initialState: AppState(
            trainer: TrainerState(session: TrainerSessionState()),
          ),
        );
        await tester.pumpWidget(_wrap(updatedStore));

        expect(find.byType(InlineValueEditor), findsNothing);
        expect(find.byTooltip('Edit credits'), findsNothing);

        viewModel = _viewModel(fields: const []);
        await tester.pumpWidget(_wrap(store, key: const ValueKey('empty')));
        expect(
          find.text('No trainer fields are available for this profile.'),
          findsOneWidget,
        );

        viewModel = _viewModel(hasProfile: false);
        await tester.pumpWidget(
          _wrap(store, key: const ValueKey('no-profile')),
        );
        expect(find.text('credits'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class TrainerFieldsPanel forwards edit and apply callbacks', (
      tester,
    ) async {
      final edits = <String>[];
      final applications = <(String, int)>[];
      var applied = 0;
      viewModel = _viewModel(
        fields: [
          _row(
            'credits',
            name: 'Credits',
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 17,
            ),
          ),
        ],
        onEditField: edits.add,
        onApplyField: (fieldId, value) {
          applications.add((fieldId, value));
          return GameWriteResult(
            status: GameWriteStatus.success,
            fieldId: fieldId,
            requestedValue: value,
            readBackValue: value,
          );
        },
        onCancelEditing: () => applied++,
      );
      await tester.pumpWidget(_wrap(store));

      await tester.tap(find.byTooltip('Edit Credits'));
      expect(edits, ['credits']);

      viewModel = _viewModel(
        fields: [
          _row(
            'credits',
            name: 'Credits',
            isEditing: true,
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 17,
            ),
          ),
        ],
        onApplyField: (fieldId, value) {
          applications.add((fieldId, value));
          return GameWriteResult(
            status: GameWriteStatus.success,
            fieldId: fieldId,
            requestedValue: value,
            readBackValue: value,
          );
        },
        onCancelEditing: () => applied++,
      );
      await tester.pumpWidget(_wrap(store, key: const ValueKey('editing')));
      await tester.enterText(
        find.byKey(const ValueKey('inline-editor-input-credits')),
        '42',
      );
      await tester.tap(find.byTooltip('Apply Credits'));
      await tester.pump();

      expect(applications, [('credits', 42)]);
      expect(applied, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
