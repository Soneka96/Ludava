# Task 08 — Optimistic commit on intentional field exit

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 03, Task 05, Task 06, Task 07.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Commit the final valid draft on genuine field blur; optional Enter also commits but is never mandatory. No typing debounce or writes during pauses.
- Show requested value instantly while SDK verifies. On successful write show nothing; on latest applicable failure restore same-session confirmed value and show header error.
- Switching field A to B commits A and focuses B immediately while writes serialize in the background; old results cannot wipe B or later A edits.
- Define empty/invalid/unchanged value behavior without extra controls or layout changes.

## Acceptance criteria

- Typing, pausing and undo/redo do not write; intentional edit exit produces at most one valid write.
- Failed latest write produces a header error and safe display rollback, never a compensating memory write.
- New edit or game-session change cannot be overwritten by old write result.

## Verification ownership

- Editor-owned tests cover commit/invalid/unchanged/focus and rollback with mocked callbacks.
- Coordinator and focused integration tests own races, SDK reentrancy and field/session identity.

## Explicit exclusions

- Per-field pending/success indicators, extra dialogs or timers.
- Relaxing SDK validation.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
