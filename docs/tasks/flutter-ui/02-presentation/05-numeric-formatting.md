# Task 05 — Live commas, caret accuracy, paste and undo/redo

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 01.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Adapt existing trainer_value_formatter.dart or a focused TextInputFormatter to group integer digits live (e.g. 1000 becomes 1,000).
- Preserve logical caret location, selection, composing text, insertion/deletion around separators, paste and text-edit history; avoid controller rewrites that break IMEs.
- Accept digits-only input where applicable and parse integer text without treating empty, unparseable, or non-representable text as a value. Never fabricate a write of zero for an invalid or empty draft.
- Keep text formatting and parsing separate from SDK field-range policy; the SDK evaluates permitted ranges when a write is submitted.

## Acceptance criteria

- Middle edits, Backspace adjacent to commas, selection replacement and pasted formatted values behave predictably.
- Ctrl+Z and Ctrl+Y/Ctrl+Shift+Z preserve natural editing history; no cursor jump.
- Always-formatted visible integer display, with no unintended SDK writes.

## Verification ownership

- Pure formatter tests own digit filtering, parsing, grouping, offset/selection/composition, paste and undo/redo regressions. They do not duplicate the SDK's write-range policy.
- Focused input tests verify integration without retesting the framework.

## Explicit exclusions

- Commit trigger or SDK writing.
- A global arbitrary numeric maximum.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
