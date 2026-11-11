# Task 05 — Live commas, caret accuracy, paste and undo/redo

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 01.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Adapt existing trainer_value_formatter.dart or a focused TextInputFormatter to group integer digits live (e.g. 1000 becomes 1,000).
- Preserve logical caret location, selection, composing text, insertion/deletion around separators, paste and text-edit history; avoid controller rewrites that break IMEs.
- Parse ungrouped integer values, validate type/range against field definition, and prevent empty or invalid drafts from becoming a write of zero.

## Acceptance criteria

- Middle edits, Backspace adjacent to commas, selection replacement and pasted formatted values behave predictably.
- Ctrl+Z and Ctrl+Y/Ctrl+Shift+Z preserve natural editing history; no cursor jump.
- Always-formatted visible integer display, with no unintended SDK writes.

## Verification ownership

- Pure formatter tests own offset/selection/composition, paste, range and undo-specific regressions.
- Focused input tests verify integration without retesting the framework.

## Explicit exclusions

- Commit trigger or SDK writing.
- A global arbitrary numeric maximum.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
