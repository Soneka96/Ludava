# Task 06 — Permanent numeric input and focus lifecycle

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 04, Task 05.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Replace separate view/edit widgets and inline Apply/Cancel with one stable TextField and locally owned controller, focus and draft.
- Select whole value on first focus where practical; allow precise second-click caret and mouse/touch selection.
- Define true field blur versus Windows activation/virtual keyboard focus; editing transitions must not destroy a draft or shift geometry.
- Keep Redux editing identity and SDK session invalidation rules; subsequent polling task pauses on edit focus.

## Acceptance criteria

- No pencil, Apply/Cancel, check/cross, or alternate edit layout.
- Row dimensions and caret remain stable through focus/refresh events.
- Switching fields or tapping outside ends the correct edit; Enter/Escape are never required.

## Verification ownership

- Editor-owned widget tests cover focus, selection, typed draft, invalidation and layout.
- Connected parents use exclusive mocked ViewModels; no ordinary widget tests with real middleware/SDK.

## Explicit exclusions

- Submitting writes (task 8).
- OS keyboard placement (task 15).

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
