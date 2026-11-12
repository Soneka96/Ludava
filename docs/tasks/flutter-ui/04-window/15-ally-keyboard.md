# Task 15 — ROG Ally touch keyboard and reliable blur

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 06, Task 08, Task 14.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Test real Windows touch keyboard activation and distinguish OS window deactivation from intentional field blur; keyboard opening must not commit accidentally.
- Keep focused field accessible above keyboard, repositioning and restoring native window if needed without altering field layout or permanently saving the transient position.
- Verify touch selection, second-tap caret, backspace, paste, undo, outside-tap commit and switching fields on the Ally.
- Retain mouse/keyboard workflows with no required Escape, Enter or controller-specific mapping.

## Acceptance criteria

- All edits can be completed by touch with the Windows keyboard, with no hidden confirmation button.
- Keyboard appears without accidental writes or lost draft, and active input remains visible.
- Window restores safely within screen bounds after keyboard dismissal.

## Verification ownership

- Editor widget tests own focus/callback behavior.
- Real Windows/ROG Ally manual integration is required; do not claim hardware validation from mocks.

## Explicit exclusions

- New virtual keyboard overlay rendered by Flutter.
- Alternative per-handheld screen layouts.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
