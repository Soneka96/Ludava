# Flutter Windows compact trainer — implementation tasks

**Priority gate:** Finish and merge the existing [production verification-status removal](../../ROADMAP.md) first. Only then begin task 01 here. Tasks are planned scopes, not completed PR numbers or validated Windows behavior.

## Approved interaction contract

- Native Windows caption `Ludava — Game Name`, dynamically updated on supported-game changes; native minimize/close, maximize disabled; no repeated title inside the Flutter content.
- Compact Graphite & Teal trainer for 1–5 numeric fields. Single fixed-height connectivity/error/Refresh header. Left labels; permanent right-aligned numeric inputs. No extra screens, field cards, pencil, Apply/Cancel, plus/minus, sliders, success indicators or error row.
- Always-formatted comma-grouped integer text, correct caret/selection/IME, paste and undo/redo. Typing is immediate and local; automatically **commit on intentional field blur**, with optional Enter, not idle debounce. Do not require Escape/Enter.
- SDK-confirmed state remains separate from the optimistic visible value. Writes are guarded and serialized by session/field/revision. Success is silent; latest applicable failure restores the same-session confirmed value and uses the existing fixed header status. Never overwrite a newer edit with an older result.
- **Flutter only:** fast automatic value reads pause for editing/conflicting writes; slower game identity checks continue during editing; SDK always independently validates every write; relevant failure triggers identity recheck. Nocterm keeps its current manual workflow.
- Keep one meaningful Refresh button as real coalesced fresh sync/recovery; no overlapping SDK operations, no draft interruption.
- Window uses field-count natural size and user-controlled proportional client-area scale, remembered position/scale, DPI-aware usable-monitor clamping, and touch keyboard avoidance. Caption is Windows-owned. Open small then expand, animate meaningful game changes, and close only after safe shutdown.

## Ordered PR-sized tasks

| # | Group | Task | Dependencies |
| --- | --- | --- | --- |
| 01 | Conventions | [Reconcile Flutter UX conventions](01-foundation/01-ux-contract.md) | Prior cleanup |
| 02 | Visual structure | [Native Windows caption and dynamic game title](02-presentation/02-native-title.md) | 01 |
| 03 | Visual structure | [One fixed-height status and Refresh header](02-presentation/03-header.md) | 01, 02 |
| 04 | Visual structure | [Compact and stable 1–5-field layout](02-presentation/04-compact-layout.md) | 01, 03 |
| 05 | Visual structure | [Live commas, caret accuracy, paste and undo/redo](02-presentation/05-numeric-formatting.md) | 01 |
| 06 | Editing and synchronization | [Permanent numeric input and focus lifecycle](03-interaction/06-permanent-editor.md) | 04, 05 |
| 07 | Editing and synchronization | [Serialized, revision-safe nonblocking writes](03-interaction/07-safe-write-coordination.md) | 01 |
| 08 | Editing and synchronization | [Optimistic commit on intentional field exit](03-interaction/08-blur-commit.md) | 03, 05, 06, 07 |
| 09 | Editing and synchronization | [Fast Flutter-only value refresh and edit pause](03-interaction/09-auto-value-refresh.md) | 06, 07, 08 |
| 10 | Editing and synchronization | [Slower game identity checks and failure recheck](03-interaction/10-game-monitor.md) | 07, 09 |
| 11 | Editing and synchronization | [Refresh as a meaningful recovery and reassurance action](03-interaction/11-manual-refresh.md) | 03, 09, 10 |
| 12 | Native Windows and Ally | [Natural Windows size from 1–5 fields](04-window/12-natural-sizing.md) | 02, 03, 04 |
| 13 | Native Windows and Ally | [Native proportional resizing and DPI-aware content scale](04-window/13-proportional-scaling.md) | 12 |
| 14 | Native Windows and Ally | [Persist scale/position and keep window on-screen](04-window/14-placement-bounds.md) | 12, 13 |
| 15 | Native Windows and Ally | [ROG Ally touch keyboard and reliable blur](04-window/15-ally-keyboard.md) | 06, 08, 14 |
| 16 | Native Windows and Ally | [Loading, game-change and safe-close transitions](04-window/16-animations.md) | 02, 12, 14, 15 |

Task 01 is a documentation-only convention reconciliation. Later tasks should use one branch/PR per responsibility after dependencies merge. Independent tasks can be sequenced pragmatically; do not artificially create one giant UI PR.

## Shared implementation and testing rules

- The SDK owns detection evidence, game/session identity, guarded reads and writes, range/guest-base checks, read-back verification and runtime results. Removing static VerificationStatus/readStatus/writeStatus does not remove safety or runtime GameReadStatus/GameWriteStatus.
- Use existing Redux + GetIt, selectors, feature middleware and exclusive per-connected-widget ViewModels. Only local editor text/focus/selection belongs in the widget. No second SDK, parallel state framework, direct widget memory I/O or speculative wrapper layers.
- Tests own their behavior at the relevant layer. Ordinary connected-widget tests must Mocktail-mock the exclusive ViewModel; integration of SDK/Redux event flows lives in explicit integration tests. Verify forbidden calls and preserve safety regressions.
- Finish each task with formatting, analysis, relevant tests and Windows CI as appropriate; don't claim actual native/ROG Ally/RPCS3 functionality without live tests. Owner approval of real read and guarded write remains required.
- Measure rather than pre-decide polling frequencies, Windows resizing API, native offload mechanism, initial pixel sizes, default scale and animation durations.

## Authoritative references

- [Roadmap](../../ROADMAP.md) — initiative ordering and exit criteria.
- [Architecture](../../ARCHITECTURE.md) — SDK boundaries and safety.
- [Development](../../DEVELOPMENT.md) — workflows and visual conventions.
- [Testing](../../TESTING.md) — ownership and mocking.
- [Flutter Redux conventions](../../FLUTTER_ARCHITECTURE_CONVENTIONS.md) — Redux/GetIt contracts.
- [Documentation governance](../../DOCUMENTATION.md) — permanent convention ownership.

## Initiative exit criteria

The native compact Flutter window supports 1–5 stable editable fields, accurate formatting and undo, safe blur-commit optimistic writes, failure feedback without layout changes, nonconflicting auto-refresh, changing game title/fields, genuine meaningful Refresh, proportional Windows bounds and Ally keyboard behavior. The owner successfully reads and writes an approved field through Flutter in a live RPCS3 session without terminal commands.
