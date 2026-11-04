# Development policy — personal project

Ludava is a **personal project maintained solely by Soneka96**. The owner does not solicit or accept external source-code contributions, unsolicited patches, feature implementations, or third-party pull requests.

Public visibility is intended to let anyone **read, study, and learn from** Ludava. People are welcome to write their own original implementations of ideas they learn. Public visibility is **not** an invitation to contribute or an open-source grant to reuse protected source code. Copying protected code, distributing modifications, or incorporating Ludava into another product requires separate permission unless applicable law or GitHub platform rights allow the activity. See [LICENSE](../LICENSE).

Commercial or other code-reuse permission may be requested from the repository owner and considered case by case, under a separate written agreement. No fixed fee has been set. Sending money does not automatically grant usage rights.

## Internal development workflow

The project's own development work follows these rules:

1. One focused task per development branch and pull request.
2. Each task records problem, evidence, implementation scope, test results and limitations.
3. Test behavior where it belongs using fake or mocked dependencies; exercise a small set of important integrations.
4. Do not label a game/build compatible without reproducible real-game validation.
5. No unverified memory writes. Unknown builds remain unsupported.
6. Prefer simple, well-separated responsibilities and incremental refactors.

## Source and test conventions

These conventions apply to new code and files materially changed by a task:

1. Organize code under the feature that owns the capability, then by the layer that owns each responsibility. Follow [`ARCHITECTURE.md`](ARCHITECTURE.md); do not create empty layers or a new game feature when a new game profile can reuse an existing capability.
2. Give each public class its own focused file and put behavior on the class that owns it. The intentional grouping exceptions are all app enums in `lib/shared/constants/enums.dart` and constants classes grouped by kind in `lib/shared/constants/`.
3. Order class members as public fields, primary/unnamed constructor, named constructors, factory constructors, private fields, public methods/getters, then private methods/getters. Put static constants before ordinary fields within their visibility group.
4. Document public classes, methods, and properties with concise Dart `///` comments. Link code references as `[Type]`, `[Type.member]`, or an in-scope `[parameter]` so IDE hovers can navigate. Documentation-only references do not add runtime coupling.
5. Put every handwritten enum in `lib/shared/constants/enums.dart`, with `none` first as the unset/error sentinel and a doc comment on the enum and each member. Put cross-cutting business constants in feature- or concern-specific classes inside `app_constants.dart`; keep UI sizing in `layout_constants.dart` if a UI needs it. Keep platform/API implementation constants with their owning class. Do not create empty constants files.
6. Do not add handwritten `typedef`s, including function aliases or record aliases. Use named classes for data and class/interface collaborators for behavior. Keep typedefs only when generated code or a Dart/native/framework interop API requires them, and document the reason.
7. Mirror each production file's path under `test/` and append `_test.dart`. For example, `read_game_field.usecase.dart` maps to `read_game_field.usecase_test.dart`.
8. Group unit tests by public method: `Method methodName() behaves correctly`. Name each test `Method methodName() <outcome>` and add `when <condition>` when the condition is not already clear from the outcome. Use an outcome that says what the method returns, preserves, rejects, or throws.
9. Group behavior-bearing getters as `Property propertyName behaves correctly`; name scenarios `Property propertyName <outcome>` and add `when <condition>` when it clarifies the case. Do not add parentheses to property names.
10. Test through public behavior. Use fakes at memory/repository boundaries and injected native API fakes for Windows calls. Never access a live game from an automated test.
11. Keep one top-level group per method and no nested groups. Test failure and boundary paths, including that a dependency is not called when a precondition rejects the operation.
12. Test names and comments describe behavior and contracts. Keep implementation details in the code, not duplicated as prose.

Behaviorless type declarations do not need artificial tests. Every class with behavior does; see the test strategy in [`ARCHITECTURE.md`](ARCHITECTURE.md).

These rules are internal quality standards; they are **not** contributor instructions or an invitation to submit changes.

## Third-party research and licensing

Ludava is intended as an independently implemented project. Historical research may be cited, but do not copy or mechanically translate copyright-protected source or curated data without checking its terms and obtaining any necessary permission. Credits and licensing requirements of third-party materials remain applicable.
