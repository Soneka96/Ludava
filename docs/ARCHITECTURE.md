# Architecture and testing strategy

This document defines the target architecture for new and materially changed code. Ludava uses feature-first organization with Clean Architecture boundaries inside a feature. Add folders when a responsibility exists; do not scaffold empty layers.

## Feature ownership

The first capability is `game_memory`: reading and writing selected game values through profiles. A game or build is profile data, not a separate feature. Adding a game should add its researched profile and fields with their actual evidence status; it should reuse the same reader and writer use cases. `researchConfirmed` means owner-confirmed external research supports an operation; it does not mean Ludava was tested against a live game session.

Keep game-specific offsets, value types, endianness, write bounds, and evidence status in that game's profile. Do not put game-specific offsets in the process adapter or duplicate generic memory logic for every game. Only fields marked `researchConfirmed` or `verified` can be written, and every write requires explicit confirmation and matching read-back.

## Layers and dependency direction

```text
lib/features/game_memory/
  domain/
    entities/       # game profile, field/value definitions, operation results
    profiles/       # one game/build profile definition per file
    repositories/   # contracts needed by domain use cases
    usecases/       # one domain operation/policy per use case
      params/        # separate parameter objects when a use case needs them
  data/
    datasources/    # operating-system and external I/O
    models/         # data-layer shapes mapped to/from domain entities
    repositories/   # implementations of domain repository contracts
  application/      # workflows coordinating multiple use cases; add when needed
  presentation/
    cli/            # command parsing and terminal output
    # a future UI belongs here
lib/shared/constants/
  enums.dart        # every app enum
  app_constants.dart # grouped cross-cutting business constants
  # layout_constants.dart only when UI sizing constants exist
```

Only create a layer or subfolder when it contains a real responsibility. In particular, a simple operation belongs in its use case; `application/` is for workflows that coordinate several operations.

Dependencies point inward:

```text
presentation → application/domain
application  → domain
data         → domain
target bin/ludava.dart → bin/ludava_cli.dart
target bin/ludava_cli.dart → presentation + concrete data wiring
features     → shared/constants
```

Use cases express one domain operation or policy. Application workflows are added only when a larger task must coordinate multiple use cases or manage an application-level sequence. Domain code must not import CLI, Flutter, Windows FFI, or data-layer code; it may use `shared/constants`. Shared constants must not import feature code. Repository contracts belong in `domain/repositories`; their implementations belong in `data/repositories`. Data sources perform I/O and return data-layer results. Repositories translate those results into the domain contract. Keep a repository only when it provides a real boundary, translation, coordination, alternate implementation, or useful test seam; do not add pass-through wrappers just to fill the folder tree.

The executable entry point `bin/ludava.dart` delegates to `bin/ludava_cli.dart`, which is the composition root and may construct concrete data implementations. Domain code must not perform that wiring.

## Files, classes, and methods

- Put each public class, entity, model, use case, repository, and data source in its own file. Name the file after its primary type and add a role suffix where it clarifies the type, such as `.entity.dart`, `.model.dart`, `.usecase.dart`, `.repository.dart`, or `.datasource.dart`.
- Order class members consistently: public fields/properties first; constructors next (primary/unnamed, then named, then factory); private fields next; public methods/getters/setters next; private methods/getters last. Keep static constants before ordinary fields within their visibility group. Constructor-initialized public data stays above the constructor; private dependencies/state stay below it.
- Keep small non-enum declarations with their owning concept when that keeps the file focused; give a type its own file when it has independent meaning or behavior. Enums follow the central-file rule below.
- Methods belong to the class that owns the behavior. Put stateless calculations in a focused utility class in the owning feature; do not add orphan top-level helper methods or generic `utils`/`services` dumping grounds.
- `main()` is the executable entry point and is the intentional top-level function exception; keep it limited to handing off to the CLI command.
- Keep profile definitions in separate files by game and build. A profile catalog may register them, but the memory-reading flow remains shared.
- Name tests after the production file and mirror its path under `test/`, with `_test.dart` appended.

## Enums, constants, and type aliases

- Put every handwritten app enum in `lib/shared/constants/enums.dart`, including enums used by only one feature. Keep enum behavior in the enum declaration itself; use enhanced enums for labels, parsing, and other enum-owned behavior rather than separate extensions.
- Put `none` first in every enum as the unset/error sentinel; it is not a real selected game value or a default compatibility claim. Give the enum and each member a concise `///` comment.
- Put cross-cutting business constants in `lib/shared/constants/app_constants.dart`, grouped into one `abstract final class` per feature or concern. Do not use bare top-level magic constants or one flat catch-all constants class.
- Keep layout and widget sizing constants in `layout_constants.dart` if a UI introduces them; do not mix presentation sizing into business constants. Create a constants file only when there are constants of that kind to own.
- Keep platform/API implementation details such as Windows access flags beside the adapter that owns them, as private `static const` members. Do not move implementation-only values into shared application constants.
- Do not add handwritten `typedef`s, including function aliases or aliases for record-shaped results. Use a named class with fields for data and an owning class/interface for behavior or injected callbacks. Generated/third-party declarations are exempt. Keep a typedef only where Dart or a native/framework interop API requires it, and document why at the declaration.
- The central enum and constants files are deliberate grouping exceptions to the one-class-per-file rule: enums share `enums.dart`; each constants class is grouped in the file for its constant kind.

## Dart documentation

- Add concise `///` documentation to every public class, method, and property. Explain the contract, constraints, or non-obvious reason; do not narrate an obvious implementation.
- Link code symbols using Dart doc references: `[GameProfile]`, `[GameProfile.canRead]`, and, in the scope where it is declared, `[profile]`. Use fully qualified class-member references for members outside their scope.
- Import a referenced symbol when needed for IDE completion and navigation. An import used only in a doc comment creates no runtime dependency; it must not be used by executable code. Architecture checks judge dependency direction from executable imports and usage, while allowing imports that exist only to resolve doc links.
- Use `[Class]` and `[Class.member]` rather than plain-text names when referring to code. Keep comments aligned with what the symbol guarantees, especially compatibility and memory-write safety.

## Testing

- Test behavior at its owner. Use fakes for deterministic memory boundaries and test the Windows adapter through an injected native API; unit tests must not read or write a live game's memory.
- Test pure value/codec/address behavior directly. Test use cases with fake repository contracts, repositories with fake data sources, and data sources with fake native APIs.
- Add a small number of integration tests for important seams. Passing automated tests does not establish game/build compatibility; that requires recorded live-game evidence in `docs/COMPATIBILITY.md`.
- Use one top-level group per public method, named `Method methodName() behaves correctly`. Name each scenario `Method methodName() <outcome>` and add `when <condition>` when the condition is not already clear from the outcome. Use clear outcomes such as `returns`, `preserves`, `rejects`, and `throws`.
- Group behavior-bearing getters as `Property propertyName behaves correctly`; name scenarios `Property propertyName <outcome>` and add `when <condition>` when it clarifies the case. Do not add parentheses to property names.
- For entity/model construction tests, use `Class TypeName construction` and `Class TypeName initializes ...`. Keep each test name specific about the input and expected result.
- Do not use nested test groups. Cover negative and boundary cases for every safety check, and pair a test that expects a collaborator call with a test proving it is not called when the precondition fails.
- Keep test files at the same relative path as production files, for example `lib/features/game_memory/domain/usecases/read_game_field.usecase.dart` maps to `test/features/game_memory/domain/usecases/read_game_field.usecase_test.dart`.

## Safety invariants

1. Only an explicitly selected profile and a field with `researchConfirmed` or `verified` write evidence can be written; report when Ludava has not checked the live runtime identity.
2. Preserve 64-bit host addresses and validate the complete requested memory range.
3. Require native success and the exact byte count before decoding or reporting a value.
4. A failed read is never reported as numeric zero.
5. A write requires a research-confirmed or verified field, a valid value range, a deliberate request, a complete native transfer, and a matching read-back. Live-game validation is required before claiming Ludava compatibility.
6. Surface process and native errors; do not silently retry writes.

## Compatibility evidence

Compatibility is recorded per exact game/build and capability. Keep experimental, read-verified, write-verified, and unsupported states distinct. A process ID, selected profile, passing unit test, or plausible value is not proof of game identity or compatibility. See [COMPATIBILITY.md](COMPATIBILITY.md) for the evidence required to change a status.

## Current implementation

The implementation uses `lib/features/game_memory` with generic read/write use cases, a profile catalog, and a Windows process-memory data source. The RC2 bolt field has research-confirmed read/write eligibility. The CLI requires manual process/profile/base selection and explicit write confirmation, then checks the complete native transfer and matching read-back. Ludava has not been run against a live RPCS3 session, and no build is identified automatically.
